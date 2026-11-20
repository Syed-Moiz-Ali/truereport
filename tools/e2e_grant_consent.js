const API = 'http://127.0.0.1:8080';
const REFERENCE = process.argv[2] || 'JOB-02F2ED6E';

async function call(token, method, path, body) {
  const response = await fetch(`${API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'X-Client': 'workshop_admin',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${path} -> ${response.status} ${text.slice(0, 600)}`);
  return text ? JSON.parse(text) : null;
}

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();

  const page = await call(token, 'GET', '/api/v1/workshop/jobs?page=0&size=50');
  const rows = page.items ?? page.content ?? [];
  const job = rows.find((entry) => entry.reference === REFERENCE);
  if (!job) throw new Error('job not found');
  console.log('job:', job.id, job.status, 'consent=', job.consentGranted, 'version=', job.version);

  const updated = await call(token, 'PUT', `/api/v1/workshop/jobs/${job.id}/consent`, {
    consentGranted: true,
    version: job.version,
    reason: 'E2E public report verification',
  });
  console.log('consent now:', updated.consentGranted, 'version:', updated.version);
})();
