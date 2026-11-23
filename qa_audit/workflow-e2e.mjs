// Fresh, disposable end-to-end inspection workflow against the local dev stack.
// Proves (or disproves) that a newly published report carries its OWN snapshot.
import { readFileSync } from 'node:fs';

const BASE = process.env.QA_API || 'http://localhost:8080';
const PW = process.env.QA_PASSWORD;
if (!PW) { console.error('QA_PASSWORD is required (see TEST_LOGIN_CREDENTIALS.txt).'); process.exit(2); }
const stamp = Date.now().toString().slice(-8);
const log = [];
const step = (name, ok, detail) => {
  log.push({ name, ok, detail });
  console.log(`${ok === true ? 'PASS' : ok === 'blocked' ? 'BLOCKED' : 'FAIL'} ${name} :: ${typeof detail === 'string' ? detail : JSON.stringify(detail)}`);
};

async function http(method, path, { token, body, headers = {}, raw } = {}) {
  const h = { ...headers };
  if (token) h.Authorization = `Bearer ${token}`;
  let payload = raw;
  if (body !== undefined) { payload = JSON.stringify(body); h['Content-Type'] = 'application/json'; }
  else if (raw) { h['Content-Type'] = 'application/octet-stream'; }
  const res = await fetch(`${BASE}${path}`, { method, headers: h, body: payload });
  const text = await res.text();
  let json = null; try { json = JSON.parse(text); } catch {}
  return { status: res.status, json, text, headers: Object.fromEntries(res.headers) };
}

async function login(email, password = PW) {
  const r = await http('POST', '/api/v1/auth/login', { body: { email, password } });
  if (r.status !== 200) throw new Error(`login ${email} -> ${r.status} ${r.text}`);
  return r.json;
}

const admin = await login('admin.a@truereport.test');
const tech = await login('tech.a@truereport.test');
const H_A = admin.accessToken; const H_T = tech.accessToken;

// 1. template + technician fixtures
const templates = await http('GET', '/api/v1/workshop/template-versions/available', { token: H_A });
const template = (templates.json || []).filter((t) => t.itemCount > 0)
  .sort((a, b) => a.itemCount - b.itemCount)[0];
step('W1 published template available', templates.status === 200 && !!template, `${template?.nameEn} items=${template?.itemCount}`);

const staff = await http('GET', '/api/v1/workshop/staff', { token: H_A });
const technician = (staff.json || []).find((s) => s.role === 'TECHNICIAN');
step('W2 technician fixture available', !!technician, technician?.userId ?? 'none');

const dubaiNow = new Date(Date.now() + 4 * 3600_000).toISOString().slice(0, 19);
const plate = `QA-${stamp}`;
const payload = {
  templateVersionId: template.versionId,
  customerName: `QA Workflow ${stamp}`,
  customerPhone: '+971500000123',
  customerEmail: `qa.${stamp}@example.test`,
  vehicleVin: `JTMBY7AJ9${stamp.padStart(8, '0').slice(0, 8)}`,
  vehicleMake: 'Toyota', vehicleModel: 'Land Cruiser', vehicleYear: 2024,
  vehiclePlate: plate, odometerValue: 1000, odometerUnit: 'KM',
  transmission: 'AUTOMATIC', fuelType: 'PETROL', preferredLanguage: 'en',
  scheduledAt: dubaiNow, assignedTechnicianId: technician.userId, consentGranted: true,
};

// 2. create
const created = await http('POST', '/api/v1/workshop/jobs', {
  token: H_A, headers: { 'Idempotency-Key': `qa-wf-${stamp}` }, body: payload,
});
const job = created.json || {};
step('W3 create job', created.status === 201 && !!job.id, `${created.status} ${created.json?.detail ?? job.reference} ${job.status ?? ''} ${created.text.slice(0, 200)}`);

// idempotency: repeat with identical key
const replay = await http('POST', '/api/v1/workshop/jobs', {
  token: H_A, headers: { 'Idempotency-Key': `qa-wf-${stamp}` }, body: payload,
});
step('W4 duplicate create with same Idempotency-Key returns the same job', replay.status === 201 && replay.json?.id === job.id,
  `${replay.status} sameId=${replay.json?.id === job.id}`);

// 3. technician sees it
const queue = await http('GET', '/api/v1/technician/jobs?size=100', { token: H_T });
const inQueue = (queue.json?.items || []).some((j) => j.id === job.id);
step('W5 job appears in technician queue', queue.status === 200 && inQueue, `status=${queue.status} total=${queue.json?.total}`);

// 4. vehicle photo (gate)
const photoBytes = readFileSync('tests/e2e/fixtures/vehicle-photo.png');
const crypto = await import('node:crypto');
const sha = crypto.createHash('sha256').update(photoBytes).digest('hex');
const init = await http('POST', `/api/v1/technician/jobs/${job.id}/vehicle-photo`, {
  token: H_T, body: { mime: 'image/png', bytes: photoBytes.length, sha256: sha, capturedAt: new Date().toISOString().slice(0, 19), captureSource: 'FILE', deviceId: null },
});
step('W6 vehicle photo init', init.status === 200 || init.status === 201, `${init.status} ${JSON.stringify(init.json).slice(0, 120)}`);
if (init.json?.id) {
  const up = await http('PUT', `/api/v1/technician/jobs/${job.id}/vehicle-photo/${init.json.id}/content`, { token: H_T, raw: photoBytes });
  step('W7 vehicle photo upload', up.status === 200 || up.status === 204, String(up.status));
  const done = await http('POST', `/api/v1/technician/jobs/${job.id}/vehicle-photo/${init.json.id}/complete`, { token: H_T });
  step('W8 vehicle photo complete', [200, 201].includes(done.status), `${done.status} ${done.json?.status ?? ''}`);
}

// 5. assess every item (evidence first: the seeded master rules require 1 photo + 1 video)
const photoJpeg = readFileSync('qa_audit/evidence/photo.jpg');
const fakeVideo = Buffer.concat([
  Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypmp42'), Buffer.from([0, 0, 0, 0]),
  Buffer.from('mp42isom'), Buffer.alloc(4096, 0),
]);

async function uploadEvidence(itemCode, type, baseBytes, mime, extra = {}) {
  // The API rejects the same content hash twice in one job, so append a unique
  // nonce (trailing bytes after the container payload) per item.
  const bytes = Buffer.concat([baseBytes, Buffer.from(`${itemCode}-${type}-${stamp}`)]);
  const digest = crypto.createHash('sha256').update(bytes).digest('hex');
  const init = await http('POST', `/api/v1/technician/jobs/${job.id}/items/${encodeURIComponent(itemCode)}/evidence/init`, {
    token: H_T, body: {
      type, mime, bytes: bytes.length, sha256: digest,
      capturedAt: new Date().toISOString().slice(0, 19), captureSource: 'FILE', deviceId: null,
      width: 1280, height: 720, durationMs: type === 'VIDEO' ? 15000 : null,
      captionEn: null, captionAr: null, posterBase64: null, ...extra,
    },
  });
  if (!init.json?.id) return `${init.status}:${init.text.slice(0, 100)}`;
  const put = await http('PUT', `/api/v1/technician/jobs/${job.id}/items/${encodeURIComponent(itemCode)}/evidence/${init.json.id}/content`, { token: H_T, raw: bytes });
  const done = await http('POST', `/api/v1/technician/jobs/${job.id}/items/${encodeURIComponent(itemCode)}/evidence/${init.json.id}/complete`, { token: H_T, body: { captionEn: null, captionAr: null, posterBase64: null } });
  return `${put.status}/${done.status}/${done.json?.status ?? done.json?.code ?? ''}`;
}

const checklist = await http('GET', `/api/v1/technician/jobs/${job.id}/checklist`, { token: H_T });
const items = checklist.json?.items || [];
step('W9 pinned checklist loaded', checklist.status === 200 && items.length > 0, `items=${items.length} pinned=${checklist.json?.pinned?.templateVersionNo}`);

const evidenceLog = [];
for (const item of items) {
  evidenceLog.push(`${item.itemCode}:photo=${await uploadEvidence(item.itemCode, 'PHOTO', photoJpeg, 'image/jpeg')}`);
  evidenceLog.push(`${item.itemCode}:video=${await uploadEvidence(item.itemCode, 'VIDEO', fakeVideo, 'video/mp4')}`);
}
step('W9b evidence photo+video uploaded per item', evidenceLog.every((l) => /200\/200\/VERIFIED/.test(l)),
  evidenceLog.join(' | ').slice(0, 500));

let assessed = 0; const failures = [];
for (const item of items) {
  const options = item.resultOptions || [];
  const pick = options.includes('NO_ISSUE_OBSERVED') ? 'NO_ISSUE_OBSERVED'
    : options.find((o) => /NO_ISSUE|PASS|OK/.test(o)) || options[0];
  const band = (item.scoreBands || []).find((b) => b.resultCode === pick);
  const r = await http('PUT', `/api/v1/technician/jobs/${job.id}/items/${encodeURIComponent(item.itemCode)}`, {
    token: H_T, body: {
      baseVersion: item.assessment?.version ?? 0,
      clientRevision: Date.now(),
      resultCode: pick,
      score: band?.defaultScore ?? null,
      severityCode: null, reasonCode: null,
      issueValues: [], measurements: [],
    },
  });
  if (r.status === 200) assessed++;
  else failures.push(`${item.itemCode}:${r.status}:${r.text.slice(0, 140)}`);
}
step('W10 assess every checklist item', assessed === items.length, `assessed=${assessed}/${items.length} ${failures.slice(0, 2).join(' | ')}`);

// 6. summary + signature
const beforeSign = await http('GET', `/api/v1/technician/jobs/${job.id}/summary`, { token: H_T });
step('W11 summary reports signature blocker before signing',
  beforeSign.status === 200 && (beforeSign.json?.blockers || []).some((b) => b.code === 'SIGNATURE_MISSING'),
  JSON.stringify(beforeSign.json?.blockers || []).slice(0, 200));

const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
const sig = await http('POST', `/api/v1/technician/jobs/${job.id}/signature`, {
  token: H_T, body: { signerName: 'QA Technician A', deviceId: 'qa-audit', method: 'DRAWN', signatureBase64: png, mime: 'image/png' },
});
step('W12 technician signature recorded', [200, 201].includes(sig.status), `${sig.status} hash=${sig.json?.signatureHash?.slice(0, 12)}`);

const summary = await http('GET', `/api/v1/technician/jobs/${job.id}/summary`, { token: H_T });
step('W13 summary has no blockers', summary.status === 200 && (summary.json?.blockers || []).length === 0,
  `assessed=${summary.json?.itemsAssessed}/${summary.json?.itemsTotal} score=${summary.json?.score} blockers=${JSON.stringify(summary.json?.blockers || []).slice(0, 160)}`);

// 7. complete
const complete = await http('POST', `/api/v1/technician/jobs/${job.id}/complete`, {
  token: H_T, headers: { 'Idempotency-Key': `qa-wf-complete-${stamp}` }, body: { clientRevision: Date.now() },
});
step('W14 complete inspection', [200, 201].includes(complete.status), `${complete.status} status=${complete.json?.status} blockers=${JSON.stringify(complete.json?.blockers || []).slice(0, 120)}`);

// 8. publish before approval must be rejected
const earlyPublish = await http('POST', `/api/v1/workshop/jobs/${job.id}/publish`, { token: H_A, body: { pdfDownloadEnabled: true } });
step('W15 publish before approval is rejected', earlyPublish.status === 409, `${earlyPublish.status} ${earlyPublish.json?.code ?? ''}`);

// 9. admin review + approve
const review = await http('GET', `/api/v1/workshop/jobs/${job.id}/review`, { token: H_A });
step('W16 admin review sees assessed findings', review.status === 200 && review.json?.itemsAssessed === items.length,
  `assessed=${review.json?.itemsAssessed}/${review.json?.itemsTotal} grade=${review.json?.grade}`);

const current = await http('GET', `/api/v1/workshop/jobs/${job.id}`, { token: H_A });
const approve = await http('POST', `/api/v1/workshop/jobs/${job.id}/approve`, {
  token: H_A, headers: { 'Idempotency-Key': `qa-wf-approve-${stamp}` },
  body: { version: current.json?.version, reason: 'QA audit approval' },
});
step('W17 admin approves the inspection', approve.status === 200 && approve.json?.status === 'APPROVED',
  `${approve.status} status=${approve.json?.status} version=${current.json?.version}`);

const approveAgain = await http('POST', `/api/v1/workshop/jobs/${job.id}/approve`, { token: H_A, body: { version: current.json?.version } });
step('W18 second approval is rejected', approveAgain.status === 409, `${approveAgain.status} ${approveAgain.json?.code ?? ''}`);

// 10. publish
const published = await http('POST', `/api/v1/workshop/jobs/${job.id}/publish`, {
  token: H_A, headers: { 'Idempotency-Key': `qa-wf-publish-${stamp}` }, body: { pdfDownloadEnabled: true },
});
step('W19 publish inspection', [200, 201].includes(published.status) && published.json?.status === 'ACTIVE',
  `${published.status} link=${published.json?.publicUrl ?? ''}`);

// 11. report snapshot must belong to this job
const report = await http('GET', `/api/v1/workshop/jobs/${job.id}/report`, { token: H_A });
const numberMatches = report.json?.content?.reportNumber === job.reference;
step('W20 report snapshot carries THIS job reference', report.status === 200 && numberMatches,
  `report.reportNumber=${report.json?.reportNumber} content.reportNumber=${report.json?.content?.reportNumber} expected=${job.reference}`);

// 12. public page must show this job only
if (published.json?.publicUrl) {
  const page = await fetch(published.json.publicUrl);
  const html = await page.text();
  const refs = [...new Set([...html.matchAll(/JOB-[A-Z0-9]+/g)].map((m) => m[0]))];
  const ownOnly = refs.length === 1 && refs[0] === job.reference;
  step('W21 public report identifies only this job', page.status === 200 && ownOnly,
    `status=${page.status} refs=${JSON.stringify(refs)}`);
  step('W22 public report does not leak customer PII', !html.includes(payload.customerName),
    `customerNamePresent=${html.includes(payload.customerName)}`);
}

// 13. stale-state checks
const afterPublish = await http('GET', `/api/v1/workshop/jobs/${job.id}`, { token: H_A });
const counts = await http('GET', '/api/v1/workshop/jobs/counts', { token: H_A });
step('W23 published job reflects PUBLISHED in list + counts',
  afterPublish.json?.status === 'PUBLISHED' && (counts.json?.published || 0) > 0,
  `status=${afterPublish.json?.status} publishedCount=${counts.json?.published}`);

console.log('\nRESULT_JSON ' + JSON.stringify({
  jobId: job.id, reference: job.reference, plate,
  steps: log, passed: log.filter((l) => l.ok === true).length, failed: log.filter((l) => l.ok === false).length,
}));
