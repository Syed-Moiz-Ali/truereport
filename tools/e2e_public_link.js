const API = 'http://127.0.0.1:8080';
const REFERENCE = process.argv[2] || 'JOB-02F2ED6E';

async function call(token, path) {
  const response = await fetch(`${API}${path}`, {
    headers: { Authorization: `Bearer ${token}`, 'X-Client': 'workshop_admin' },
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${path} ${response.status} ${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : null;
}

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();
  const page = await call(token, '/api/v1/workshop/jobs?page=0&size=50&status=PUBLISHED');
  const rows = page.items ?? page.content ?? [];
  const job = rows.find((entry) => entry.reference === REFERENCE) ?? rows[0];
  const link = await call(token, `/api/v1/workshop/jobs/${job.id}/public-link`);
  console.log(JSON.stringify(link, null, 2));
})();
