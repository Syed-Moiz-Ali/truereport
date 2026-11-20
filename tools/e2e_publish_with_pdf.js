const API = 'http://127.0.0.1:8080';
const REFERENCE = 'JOB-EE3271A8';

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
  return { status: response.status, body: text ? JSON.parse(text) : null };
}

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();

  const page = await call(token, 'GET', '/api/v1/workshop/jobs?page=0&size=50');
  const job = (page.body.items ?? []).find((row) => row.reference === REFERENCE);
  if (!job) throw new Error('job not found');

  const unpublish = await call(token, 'POST', `/api/v1/workshop/jobs/${job.id}/unpublish`, {});
  console.log('unpublish ->', unpublish.status, unpublish.body?.status ?? unpublish.body?.code);

  const publish = await call(token, 'POST', `/api/v1/workshop/jobs/${job.id}/publish`, {
    pdfDownloadEnabled: true,
  });
  console.log('publish(pdf=true) ->', publish.status, publish.body?.status ?? publish.body?.code);

  const link = await call(token, 'GET', `/api/v1/workshop/jobs/${job.id}/public-link`);
  console.log('link ->', link.status, link.body?.publicUrl, 'pdfDownloadEnabled=', link.body?.pdfDownloadEnabled);
})();
