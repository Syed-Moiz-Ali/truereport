const API = 'http://127.0.0.1:8080';

async function call(token, path) {
  const response = await fetch(`${API}${path}`, {
    headers: { Authorization: `Bearer ${token}`, 'X-Client': 'technician' },
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${path} ${response.status} ${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : null;
}

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'tech.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();
  const jobs = await call(token, '/api/v1/technician/jobs?page=0&size=20');
  const job = jobs.items.find((entry) => entry.reference === 'JOB-02F2ED6E');
  const checklist = await call(token, `/api/v1/technician/jobs/${job.id}/checklist`);

  const withBands = checklist.items.filter((item) => (item.bands ?? []).length > 0);
  console.log('items with bands:', withBands.map((i) => `${i.itemCode}:${i.measurementUnit}`).join(', '));
  const brake = checklist.items.find((item) => item.itemCode === 'BRK-PAD-01');
  console.log('brake bands:', JSON.stringify(brake.bands).slice(0, 900));
  console.log('brake keys:', Object.keys(brake).join(', '));
  const assessed = checklist.items.filter((item) => item.assessment).map((item) => item.itemCode);
  console.log('assessed now:', assessed.length, assessed.join(','));
})();
