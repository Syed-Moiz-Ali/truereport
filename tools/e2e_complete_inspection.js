const crypto = require('crypto');
const API = 'http://127.0.0.1:8080';
const REFERENCE = process.argv[2] || 'JOB-02F2ED6E';
const LIMIT = Number(process.argv[3] || '30');

const JPEG = Buffer.from(
  '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwcJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPDs0NDP/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==',
  'base64',
);
// Minimal ISO-BMFF ftyp box; the server stores bytes without transcoding.
const MP4 = Buffer.from(
  '00000018667479706d703432000000006d70343269736f6d',
  'hex',
);

const sha256 = (buffer) => crypto.createHash('sha256').update(buffer).digest('hex');

async function call(token, method, path, { json, raw, contentType } = {}) {
  const headers = { Authorization: `Bearer ${token}`, 'X-Client': 'technician' };
  let body;
  if (json !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(json);
  }
  if (raw !== undefined) {
    headers['Content-Type'] = contentType || 'application/octet-stream';
    body = raw;
  }
  const response = await fetch(`${API}${path}`, { method, headers, body });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${method} ${path} -> ${response.status} ${text.slice(0, 1500)}`);
  }
  return text ? JSON.parse(text) : null;
}

async function uploadEvidence(token, jobId, itemCode, type, bytes, mime) {
  // Unique trailing bytes keep the sha256 distinct per item (the server rejects
  // duplicate evidence hashes across the job).
  const unique = Buffer.concat([bytes, crypto.randomBytes(8)]);
  const init = await call(token, 'POST', `/api/v1/technician/jobs/${jobId}/items/${itemCode}/evidence/init`, {
    json: {
      type,
      mime,
      bytes: unique.length,
      sha256: sha256(unique),
      capturedAt: new Date().toISOString(),
      captureSource: 'CAMERA',
      deviceId: 'e2e-mcp',
      width: type === 'PHOTO' ? 1280 : null,
      height: type === 'PHOTO' ? 720 : null,
      durationMs: type === 'VIDEO' ? 20000 : null,
    },
  });
  await call(token, 'PUT', `/api/v1/technician/jobs/${jobId}/items/${itemCode}/evidence/${init.id}/content`, {
    raw: unique,
  });
  await call(token, 'POST', `/api/v1/technician/jobs/${jobId}/items/${itemCode}/evidence/${init.id}/complete`, {
    json: {},
  });
  return init.id;
}

(async () => {
  const loginResponse = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'tech.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await loginResponse.json();

  const jobs = await call(token, 'GET', '/api/v1/technician/jobs?page=0&size=20');
  const job = jobs.items.find((entry) => entry.reference === REFERENCE);
  if (!job) throw new Error(`job ${REFERENCE} not found`);

  const checklist = await call(token, 'GET', `/api/v1/technician/jobs/${job.id}/checklist`);
  const items = checklist.items.slice(0, LIMIT);
  console.log(`job ${REFERENCE} (${job.id}) items=${checklist.items.length} processing=${items.length}`);

  for (const item of items) {
    const existing = await call(
      token,
      'GET',
      `/api/v1/technician/jobs/${job.id}/items/${item.itemCode}/evidence`,
    );
    const photos = existing.filter((row) => row.type === 'PHOTO').length;
    const videos = existing.filter((row) => row.type === 'VIDEO').length;
    if (photos < 1) await uploadEvidence(token, job.id, item.itemCode, 'PHOTO', JPEG, 'image/jpeg');
    if (videos < 1) await uploadEvidence(token, job.id, item.itemCode, 'VIDEO', MP4, 'video/mp4');

    const bands = item.measurementBands ?? [];
    let measurements = null;
    if (bands.length > 0) {
      const band =
        bands.find((row) => row.resultCode === 'NO_ISSUE_OBSERVED') ??
        bands[bands.length - 1];
      const value = Math.round((band.minValue + (band.maxValue - band.minValue) * 0.75) * 100) / 100;
      const required = item.multiPoint ? 2 : 1;
      const indexes = item.multiPointIndexes ?? [];
      measurements = Array.from({ length: required }, (_, index) => ({
        fieldCode: band.fieldCode,
        valueIndex: indexes[index] ?? null,
        numericValue: value,
        unitCode: band.unitCode,
      }));
    }

    const fields = item.issueFields ?? [];
    const hasMeasurementField = fields.some((field) => field.fieldCode === 'MEASUREMENT');
    let issueValues = null;
    if (hasMeasurementField && measurements && measurements.length > 0) {
      issueValues = [
        {
          fieldCode: 'MEASUREMENT',
          valueIndex: measurements[0].valueIndex,
          numericValue: measurements[0].numericValue,
          unitCode: measurements[0].unitCode,
        },
      ];
    }

    const band = item.scoreBands.find((row) => row.resultCode === 'NO_ISSUE_OBSERVED');
    await call(token, 'PUT', `/api/v1/technician/jobs/${job.id}/items/${item.itemCode}`, {
      json: {
        resultCode: 'NO_ISSUE_OBSERVED',
        score: band?.defaultScore ?? 100,
        baseVersion: item.assessment?.version ?? null,
        measurements,
        issueValues,
      },
    });
    console.log(`  ${item.itemCode} ok`);
  }

  const summary = await call(token, 'GET', `/api/v1/technician/jobs/${job.id}/summary`);
  console.log('summary:', JSON.stringify(summary).slice(0, 500));
})();
