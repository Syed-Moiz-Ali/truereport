const API = 'http://127.0.0.1:8080';

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
  if (!response.ok) throw new Error(`${method} ${path} -> ${response.status} ${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : null;
}

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();

  const master = await call(token, 'GET', '/api/v1/workshop/master/items');
  const items = (master.items ?? master).slice(0, 3);
  console.log('master item sample keys:', Object.keys(items[0]).join(','));
  const selected = items.map((item, index) => ({
    masterItemVersionId: item.versionId ?? item.itemVersionId ?? item.id,
    sortOrder: index + 1,
  }));

  const existingId = process.argv[2];
  let templateId = existingId;

  if (!templateId) {
    const created = await call(token, 'POST', '/api/v1/workshop/templates', {
      name: 'E2E Quick Check',
      description: 'Three-item template used for the end-to-end verification.',
      serviceType: 'FULL_INSPECTION',
      vehicleType: 'ALL',
    });
    templateId = created.id;
    console.log('created template:', created.id, created.name, created.status);
  } else {
    console.log('reusing template:', templateId);
  }

  try {
    await call(token, 'POST', `/api/v1/workshop/templates/${templateId}/draft`);
  } catch (error) {
    if (!String(error).includes('409')) throw error;
    console.log('draft already exists, continuing');
  }

  const saved = await call(token, 'PUT', `/api/v1/workshop/templates/${templateId}/draft`, {
    name: 'E2E Quick Check',
    description: 'Three-item template used for the end-to-end verification.',
    serviceType: 'FULL_INSPECTION',
    vehicleType: 'ALL',
    items: selected,
  });
  console.log('draft items:', (saved.items ?? []).length, 'status:', saved.status);

  const published = await call(token, 'POST', `/api/v1/workshop/templates/${templateId}/publish`);
  console.log('published:', published.id, published.status, published.currentVersionNo ?? published.versionNo ?? '');
  console.log('TEMPLATE_ID=' + templateId);
})();
