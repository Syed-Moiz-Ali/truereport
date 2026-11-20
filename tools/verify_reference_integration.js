const API = 'http://127.0.0.1:8080';

const ACCOUNTS = {
  platform_admin: 'platform@truereport.test',
  workshop_admin: 'admin.a@truereport.test',
  technician: 'tech.a@truereport.test',
};

const STATUS_TYPES = [
  'job',
  'review',
  'publication',
  'document',
  'sync',
  'evidence',
  'template',
];
const ENUMS = [
  'role',
  'severity',
  'result',
  'grade',
  'measurement-unit',
  'evidence-type',
];
const DROPDOWNS = [
  'ISSUE_TYPE',
  'LOCATION',
  'COMPONENT',
  'ACTION',
  'URGENCY',
  'REASON',
  'UNIT',
];

const CLIENT_TONES = new Set([
  'neutral',
  'info',
  'success',
  'warning',
  'danger',
  'critical',
  'accent',
  'primary',
]);

async function login(email) {
  const response = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'Truereport#Local123' }),
  });
  if (!response.ok) throw new Error(`login ${email} ${response.status}`);
  return (await response.json()).accessToken;
}

async function get(token, client, path) {
  const response = await fetch(`${API}${path}`, {
    headers: { Authorization: `Bearer ${token}`, 'X-Client': client },
  });
  const text = await response.text();
  return { status: response.status, etag: response.headers.get('etag'), body: text ? JSON.parse(text) : null };
}

(async () => {
  const tokens = {};
  const bundles = {};
  for (const [client, email] of Object.entries(ACCOUNTS)) {
    tokens[client] = await login(email);
    const bundle = await get(tokens[client], client, `/api/v1/i18n/ui-messages/${client}/bundle?lang=en`);
    bundles[client] = new Set(Object.keys(bundle.body.messages));
  }

  const problems = [];
  for (const client of ['workshop_admin', 'technician']) {
    for (const type of STATUS_TYPES) {
      const response = await get(tokens[client], client, `/api/v1/reference/statuses/${type}`);
      if (response.status !== 200) {
        problems.push(`${client} statuses/${type} -> ${response.status}`);
        continue;
      }
      for (const record of response.body) {
        if (!bundles[client].has(record.labelKey)) {
          problems.push(`${client} statuses/${type} ${record.code}: labelKey '${record.labelKey}' not in bundle`);
        }
        if (!CLIENT_TONES.has(record.tone)) {
          problems.push(`${client} statuses/${type} ${record.code}: unknown tone '${record.tone}'`);
        }
      }
    }
    for (const code of ENUMS) {
      const response = await get(tokens[client], client, `/api/v1/reference/enums/${code}`);
      if (response.status !== 200) {
        problems.push(`${client} enums/${code} -> ${response.status}`);
        continue;
      }
      for (const record of response.body) {
        if (!bundles[client].has(record.labelKey)) {
          problems.push(`${client} enums/${code} ${record.code}: labelKey '${record.labelKey}' not in bundle`);
        }
        if (!CLIENT_TONES.has(record.tone)) {
          problems.push(`${client} enums/${code} ${record.code}: unknown tone '${record.tone}'`);
        }
      }
    }
    for (const set of DROPDOWNS) {
      const response = await get(tokens[client], client, `/api/v1/reference/dropdowns/${set}`);
      if (response.status !== 200) {
        problems.push(`${client} dropdowns/${set} -> ${response.status}`);
        continue;
      }
      for (const value of response.body) {
        if (!value.labelKey && !value.label) {
          problems.push(`${client} dropdowns/${set} ${value.code}: neither labelKey nor label`);
        }
        if (value.labelKey && !bundles[client].has(value.labelKey)) {
          problems.push(`${client} dropdowns/${set} ${value.code}: labelKey '${value.labelKey}' not in bundle`);
        }
      }
    }
  }

  const etagProbe = await get(tokens.workshop_admin, 'workshop_admin', '/api/v1/reference/statuses/job');
  console.log(`statuses/job records: ${etagProbe.body.length}, etag: ${etagProbe.etag}`);
  console.log(`problems: ${problems.length}`);
  for (const problem of problems.slice(0, 40)) console.log(`  ${problem}`);
})();
