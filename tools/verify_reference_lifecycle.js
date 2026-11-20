const API = 'http://127.0.0.1:8080';

async function login(email) {
  const response = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'Truereport#Local123' }),
  });
  return (await response.json()).accessToken;
}

function headers(token, client) {
  return {
    Authorization: `Bearer ${token}`,
    'X-Client': client,
    'Content-Type': 'application/json',
  };
}

async function call(token, client, method, path, body) {
  const response = await fetch(`${API}${path}`, {
    method,
    headers: headers(token, client),
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  return {
    status: response.status,
    etag: response.headers.get('etag'),
    body: text ? JSON.parse(text) : null,
  };
}

(async () => {
  const platform = await login('platform@truereport.test');
  const workshop = await login('admin.a@truereport.test');
  const technician = await login('tech.a@truereport.test');

  // 1. Clean up the demo status the backend agent published.
  const before = await call(platform, 'platform_admin', 'GET', '/api/v1/reference/statuses/job?includeDraft=true');
  const demo = before.body.find((row) => row.code === 'PHASE2_DEMO_1');
  if (demo) {
    const retired = await call(platform, 'platform_admin', 'POST', '/api/v1/reference/statuses/job/PHASE2_DEMO_1/retire');
    console.log(`cleanup PHASE2_DEMO_1 -> ${retired.status}`);
  } else {
    console.log('cleanup: demo status not found (already clean)');
  }

  // 2. Draft invisible to clients.
  const code = 'E2E_VERIFY_STATUS';
  await call(platform, 'platform_admin', 'POST', '/api/v1/reference/statuses/job', {
    code,
    labelKey: 'statusScheduled',
    tone: 'info',
    icon: 'circle',
    order: 210,
    selectable: true,
    visibleFor: ['platform_admin', 'workshop_admin', 'technician'],
    allowedNext: [],
  });
  const draftRead = await call(technician, 'technician', 'GET', '/api/v1/reference/statuses/job');
  console.log(`draft visible to technician: ${draftRead.body.some((row) => row.code === code)}`);

  // 3. Publish -> visible + ETag changes.
  const etagBefore = draftRead.etag;
  const published = await call(platform, 'platform_admin', 'POST', `/api/v1/reference/statuses/job/${code}/publish`);
  const afterPublish = await call(technician, 'technician', 'GET', '/api/v1/reference/statuses/job');
  console.log(`publish -> ${published.status}, visible: ${afterPublish.body.some((row) => row.code === code)}, etag changed: ${etagBefore !== afterPublish.etag}`);

  // 4. Non-platform write is rejected.
  const forbidden = await call(workshop, 'workshop_admin', 'POST', '/api/v1/reference/statuses/job', {
    code: 'SHOULD_FAIL',
    labelKey: 'statusScheduled',
  });
  console.log(`workshop write -> ${forbidden.status} ${forbidden.body?.code ?? ''}`);

  // 5. Unknown label key rejected.
  const unknownLabel = await call(platform, 'platform_admin', 'POST', '/api/v1/reference/statuses/job', {
    code: 'UNKNOWN_LABEL_TEST',
    labelKey: 'nope.notAKey',
    tone: 'info',
    order: 300,
    selectable: true,
    visibleFor: ['platform_admin'],
  });
  console.log(`unknown labelKey -> ${unknownLabel.status} ${unknownLabel.body?.code ?? ''}`);

  // 6. Retire the verification status and confirm it leaves the client list.
  const retired = await call(platform, 'platform_admin', 'POST', `/api/v1/reference/statuses/job/${code}/retire`);
  const afterRetire = await call(technician, 'technician', 'GET', '/api/v1/reference/statuses/job');
  console.log(`retire -> ${retired.status}, still visible: ${afterRetire.body.some((row) => row.code === code)}`);

  const finalList = await call(technician, 'technician', 'GET', '/api/v1/reference/statuses/job');
  console.log('job statuses now:', finalList.body.map((row) => row.code).join(','));
})();
