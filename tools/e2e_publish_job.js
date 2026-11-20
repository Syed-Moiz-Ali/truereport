const API = 'http://127.0.0.1:8080';
const REFERENCE = process.argv[2] || 'JOB-EE3271A8';

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

  const page = await call(token, 'GET', '/api/v1/workshop/jobs?page=0&size=50&status=PENDING_REVIEW');
  let job = (page.body.items ?? []).find((row) => row.reference === REFERENCE);
  if (!job) {
    const all = await call(token, 'GET', '/api/v1/workshop/jobs?page=0&size=50');
    job = (all.body.items ?? []).find((row) => row.reference === REFERENCE);
  }
  if (!job) throw new Error(`job ${REFERENCE} not found`);
  console.log('job:', job.reference, job.status, 'consent=', job.consentGranted, 'version=', job.version);

  if (!job.consentGranted) {
    const consent = await call(token, 'PUT', `/api/v1/workshop/jobs/${job.id}/consent`, {
      consentGranted: true,
      version: job.version,
      reason: 'E2E verification',
    });
    console.log('consent ->', consent.status, consent.body?.consentGranted);
    job.version = consent.body?.version ?? job.version + 1;
  }

  const approve = await call(token, 'POST', `/api/v1/workshop/jobs/${job.id}/approve`, {
    reason: null,
    safetyCapReason: null,
    version: job.version,
  });
  console.log('approve ->', approve.status, approve.body?.status ?? approve.body?.code);

  const checklist = await call(token, 'GET', `/api/v1/workshop/jobs/${job.id}/publish-checklist`);
  console.log('publish checklist ->', checklist.status, JSON.stringify(checklist.body?.passed ?? checklist.body?.ready ?? null));

  const publish = await call(token, 'POST', `/api/v1/workshop/jobs/${job.id}/publish`, {});
  console.log('publish ->', publish.status, publish.body?.status ?? publish.body?.code);

  const link = await call(token, 'GET', `/api/v1/workshop/jobs/${job.id}/public-link`);
  console.log('public link ->', link.status, link.body?.publicUrl);
})();
