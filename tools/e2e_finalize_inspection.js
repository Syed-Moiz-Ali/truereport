const API = 'http://127.0.0.1:8080';
const REFERENCE = process.argv[2] || 'JOB-02F2ED6E';

const SIGNATURE_PNG =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

async function call(token, method, path, body) {
  const response = await fetch(`${API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'X-Client': 'technician',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${path} -> ${response.status} ${text.slice(0, 800)}`);
  return text ? JSON.parse(text) : null;
}

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'tech.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();
  const jobs = await call(token, 'GET', '/api/v1/technician/jobs?page=0&size=20');
  const job = jobs.items.find((entry) => entry.reference === REFERENCE);
  if (!job) throw new Error(`job ${REFERENCE} not found`);

  const summary = await call(token, 'GET', `/api/v1/technician/jobs/${job.id}/summary`);
  console.log('before:', JSON.stringify(summary).slice(0, 300));

  const signature = await call(token, 'POST', `/api/v1/technician/jobs/${job.id}/signature`, {
    signerName: 'Technician A',
    deviceId: 'e2e-mcp',
    method: 'DRAWN',
    signatureBase64: SIGNATURE_PNG,
    mime: 'image/png',
  });
  console.log('signature:', JSON.stringify(signature).slice(0, 200));

  const complete = await call(token, 'POST', `/api/v1/technician/jobs/${job.id}/complete`, {
    clientRevision: 1,
  });
  console.log('complete:', JSON.stringify(complete).slice(0, 500));
})();
