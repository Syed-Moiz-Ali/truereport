const crypto = require('crypto');
const API = 'http://127.0.0.1:8080';

const MP4 = Buffer.from('00000018667479706d703432000000006d70343269736f6d', 'hex');

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

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'tech.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();

  const jobs = await call(token, 'GET', '/api/v1/technician/jobs?page=0&size=50');
  const job = jobs.items.find((entry) => entry.reference === 'JOB-EE3271A8');
  if (!job) throw new Error('job not found');

  const itemCode = 'ENG-OIL-01';
  const existing = await call(token, 'GET', `/api/v1/technician/jobs/${job.id}/items/${itemCode}/evidence`);
  if (existing.some((row) => row.type === 'VIDEO')) {
    console.log('video already present');
    return;
  }

  const bytes = Buffer.concat([MP4, crypto.randomBytes(8)]);
  const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
  const init = await call(token, 'POST', `/api/v1/technician/jobs/${job.id}/items/${itemCode}/evidence/init`, {
    json: {
      type: 'VIDEO',
      mime: 'video/mp4',
      bytes: bytes.length,
      sha256,
      capturedAt: new Date().toISOString(),
      captureSource: 'CAMERA',
      deviceId: 'e2e-mcp',
      durationMs: 20000,
    },
  });
  await call(token, 'PUT', `/api/v1/technician/jobs/${job.id}/items/${itemCode}/evidence/${init.id}/content`, { raw: bytes });
  await call(token, 'POST', `/api/v1/technician/jobs/${job.id}/items/${itemCode}/evidence/${init.id}/complete`, { json: {} });

  const after = await call(token, 'GET', `/api/v1/technician/jobs/${job.id}/items/${itemCode}/evidence`);
  console.log('evidence:', after.map((row) => `${row.type}:${row.status}`).join(', '));
})();
