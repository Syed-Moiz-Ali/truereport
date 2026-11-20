const fs = require('fs');
const crypto = require('crypto');
const API = 'http://127.0.0.1:8080';
const JOB = '01a1f9f7-8acd-7f79-b887-6525e9b49f86';
const DIR = 'shots/e2e';

async function call(token, method, path, { json, raw } = {}) {
  const headers = { Authorization: `Bearer ${token}`, 'X-Client': 'technician' };
  let body;
  if (json !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(json);
  }
  if (raw !== undefined) {
    headers['Content-Type'] = 'application/octet-stream';
    body = raw;
  }
  const response = await fetch(`${API}${path}`, { method, headers, body });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${path} -> ${response.status} ${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : null;
}

async function upload(token, itemCode, type, file, mime, extra) {
  const bytes = fs.readFileSync(file);
  const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
  const init = await call(token, 'POST', `/api/v1/technician/jobs/${JOB}/items/${itemCode}/evidence/init`, {
    json: {
      type,
      mime,
      bytes: bytes.length,
      sha256,
      capturedAt: new Date().toISOString(),
      captureSource: 'FILE',
      deviceId: 'e2e-file',
      ...extra,
    },
  });
  await call(token, 'PUT', `/api/v1/technician/jobs/${JOB}/items/${itemCode}/evidence/${init.id}/content`, { raw: bytes });
  await call(token, 'POST', `/api/v1/technician/jobs/${JOB}/items/${itemCode}/evidence/${init.id}/complete`, { json: {} });
}

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'tech.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();

  const checklist = await call(token, 'GET', `/api/v1/technician/jobs/${JOB}/checklist`);
  const pending = checklist.items.filter((item) => !item.assessment);

  for (const item of pending) {
    const index = checklist.items.indexOf(item) + 1;
    const existing = await call(token, 'GET', `/api/v1/technician/jobs/${JOB}/items/${item.itemCode}/evidence`);
    if (!existing.some((row) => row.type === 'PHOTO')) {
      await upload(token, item.itemCode, 'PHOTO', `${DIR}/photo-${index}.jpg`, 'image/jpeg', { width: 800, height: 600 });
    }
    if (!existing.some((row) => row.type === 'VIDEO')) {
      await upload(token, item.itemCode, 'VIDEO', `${DIR}/video-${index}.mp4`, 'video/mp4', { durationMs: 20000 });
    }

    const bands = item.measurementBands ?? [];
    let measurements = null;
    if (bands.length > 0) {
      const band = bands.find((row) => row.resultCode === 'NO_ISSUE_OBSERVED') ?? bands[bands.length - 1];
      const value = Math.round((band.minValue + (band.maxValue - band.minValue) * 0.75) * 100) / 100;
      const required = item.multiPoint ? 2 : 1;
      const indexes = item.multiPointIndexes ?? [];
      measurements = Array.from({ length: required }, (_, i) => ({
        fieldCode: band.fieldCode,
        valueIndex: indexes[i] ?? null,
        numericValue: value,
        unitCode: band.unitCode,
      }));
    }

    const hasMeasurementField = (item.issueFields ?? []).some((field) => field.fieldCode === 'MEASUREMENT');
    const issueValues = hasMeasurementField && measurements
      ? [{ fieldCode: 'MEASUREMENT', valueIndex: measurements[0].valueIndex, numericValue: measurements[0].numericValue, unitCode: measurements[0].unitCode }]
      : null;

    const band = item.scoreBands.find((row) => row.resultCode === 'NO_ISSUE_OBSERVED');
    await call(token, 'PUT', `/api/v1/technician/jobs/${JOB}/items/${item.itemCode}`, {
      json: {
        resultCode: 'NO_ISSUE_OBSERVED',
        score: band?.defaultScore ?? 100,
        baseVersion: item.assessment?.version ?? null,
        measurements,
        issueValues,
      },
    });
    console.log(`${item.itemCode} completed (FILE evidence)`);
  }

  const summary = await call(token, 'GET', `/api/v1/technician/jobs/${JOB}/summary`);
  console.log('summary:', JSON.stringify(summary).slice(0, 400));
})();
