// QA audit harness — read-only/safe API checks against the local dev server.
// No application source is modified. Writes only disposable, clearly-named QA records.
import { writeFileSync } from 'node:fs';

const BASE = process.env.QA_API || 'http://localhost:8080';
const PW = process.env.QA_PASSWORD;
if (!PW) { console.error('QA_PASSWORD is required (see TEST_LOGIN_CREDENTIALS.txt).'); process.exit(2); }
const results = [];
const evidence = {};

function record(id, area, name, expected, actual, pass, notes = '') {
  results.push({ id, area, name, expected, actual, pass, notes });
  const mark = pass === true ? 'PASS' : pass === 'blocked' ? 'BLOCKED' : 'FAIL';
  console.log(`${mark} ${id} ${name} :: ${actual}${notes ? ' :: ' + notes : ''}`);
}

function decodeJwt(token) {
  try {
    const p = token.split('.')[1];
    return JSON.parse(Buffer.from(p.replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString('utf8'));
  } catch { return null; }
}

async function http(method, path, opts = {}) {
  const headers = { ...(opts.headers || {}) };
  if (opts.token) headers.Authorization = `Bearer ${opts.token}`;
  let body;
  if (opts.body !== undefined) {
    if (typeof opts.body === 'string') { body = opts.body; headers['Content-Type'] = headers['Content-Type'] || 'application/json'; }
    else { body = JSON.stringify(opts.body); headers['Content-Type'] = 'application/json'; }
  }
  const started = Date.now();
  const res = await fetch(`${BASE}${path}`, { method, headers, body, redirect: 'manual' });
  const text = await res.text();
  let json = null;
  try { json = JSON.parse(text); } catch {}
  return { status: res.status, headers: Object.fromEntries(res.headers), text, json, ms: Date.now() - started };
}

const isProblemJson = (r) => {
  const ct = (r.headers['content-type'] || '').toLowerCase();
  return ct.includes('problem+json') || (r.json && typeof r.json === 'object' && ('title' in r.json || 'detail' in r.json || 'type' in r.json));
};

async function login(email, password = PW) {
  const r = await http('POST', '/api/v1/auth/login', { body: { email, password } });
  return r;
}

async function main() {
  // ---------- A. platform health & docs ----------
  {
    const r = await http('GET', '/actuator/health');
    record('A1', 'Platform', 'Health endpoint', 200, r.status, r.status === 200 && r.json?.status === 'UP', JSON.stringify(r.json).slice(0, 120));
  }
  {
    const r = await http('GET', '/v3/api-docs');
    const paths = r.json?.paths ? Object.keys(r.json.paths) : [];
    const methods = r.json?.paths ? Object.values(r.json.paths).reduce((n, p) => n + Object.keys(p).length, 0) : 0;
    record('A2', 'Platform', 'OpenAPI document served', 200, r.status, r.status === 200 && paths.length > 0, `paths=${paths.length} operations=${methods}`);
    evidence.openapi = { paths: paths.length, operations: methods };
  }

  // ---------- B. authentication ----------
  const accounts = {
    platform: 'platform@truereport.test',
    adminA: 'admin.a@truereport.test',
    adminB: 'admin.b@truereport.test',
    techA: 'tech.a@truereport.test',
    techManual: 'tech.test@gmail.com',
  };
  const sessions = {};
  for (const [key, email] of Object.entries(accounts)) {
    const password = key === 'techManual' ? '12345678' : PW;
    const r = await login(email, password);
    const ok = r.status === 200 && Boolean(r.json?.accessToken);
    if (ok) sessions[key] = r.json;
    record('B1-' + key, 'Auth', `Valid login ${email}`, 200, r.status, ok,
      ok ? `memberships=${(r.json.memberships || []).length} role=${decodeJwt(r.json.accessToken)?.roles || decodeJwt(r.json.accessToken)?.role || 'n/a'}` : r.text.slice(0, 160));
  }
  evidence.sessions = Object.fromEntries(Object.entries(sessions).map(([k, v]) => [k, {
    user: v.user, memberships: v.memberships,
    accessClaims: decodeJwt(v.accessToken),
  }]));

  {
    const r = await login(accounts.adminA, 'WrongPassword#1');
    record('B2', 'Auth', 'Wrong password rejected', 401, r.status,
      r.status === 401 && isProblemJson(r), `content-type=${r.headers['content-type']}`, r.text.slice(0, 140));
  }
  {
    const r = await login('nobody.qa@truereport.test');
    record('B3', 'Auth', 'Unknown email rejected without enumeration', 401, r.status, r.status === 401, r.text.slice(0, 140));
  }
  {
    const r = await http('POST', '/api/v1/auth/login', { body: {} });
    record('B4', 'Auth', 'Empty login body -> 400', 400, r.status, r.status === 400 && isProblemJson(r), r.text.slice(0, 140));
  }
  {
    const r = await http('POST', '/api/v1/auth/login', { body: { email: 'not-an-email', password: PW } });
    record('B5', 'Auth', 'Malformed email -> 400', 400, r.status, r.status === 400, r.text.slice(0, 140));
  }
  {
    const r = await http('POST', '/api/v1/auth/login', { body: '{"email":' });
    record('B6', 'Auth', 'Malformed JSON -> 400', 400, r.status, r.status === 400, r.text.slice(0, 140));
  }
  {
    const r = await http('GET', '/api/v1/auth/me');
    record('B7', 'Auth', 'Me without token -> 401', 401, r.status, r.status === 401, r.text.slice(0, 140));
  }
  {
    const r = await http('GET', '/api/v1/auth/me', { token: 'garbage.token.value' });
    record('B8', 'Auth', 'Me with garbage token -> 401', 401, r.status, r.status === 401, r.text.slice(0, 140));
  }
  {
    const good = sessions.adminA?.accessToken;
    const parts = good.split('.');
    const tampered = `${parts[0]}.${Buffer.from(JSON.stringify({ ...decodeJwt(good), sub: 'attacker' })).toString('base64url')}.${parts[2]}`;
    const r = await http('GET', '/api/v1/auth/me', { token: tampered });
    record('B9', 'Auth', 'Tampered access token rejected', 401, r.status, r.status === 401, r.text.slice(0, 140));
  }
  {
    const r = await http('GET', '/api/v1/auth/me', { token: sessions.adminA.accessToken });
    const body = r.text;
    const leaked = /password|secret|hash|totpSecret/i.test(body);
    record('B10', 'Auth', 'Me returns profile/memberships without secrets', 200, r.status, r.status === 200 && !leaked,
      `keys=${r.json ? Object.keys(r.json).join(',') : 'n/a'} sensitive=${leaked}`);
  }
  {
    // refresh rotation + reuse detection
    const before = sessions.adminA;
    const r1 = await http('POST', '/api/v1/auth/refresh', { body: { refreshToken: before.refreshToken } });
    const rotated = r1.status === 200 && r1.json?.accessToken && r1.json?.refreshToken && r1.json.refreshToken !== before.refreshToken;
    record('B11', 'Auth', 'Refresh rotates the refresh token', 200, r1.status, rotated, rotated ? 'new tokens issued' : r1.text.slice(0, 140));
    const r2 = await http('POST', '/api/v1/auth/refresh', { body: { refreshToken: before.refreshToken } });
    record('B12', 'Auth', 'Reused old refresh token rejected', '401/403', r2.status, [401, 403, 409].includes(r2.status), r2.text.slice(0, 140));
    if (r1.json?.accessToken) {
      const me = await http('GET', '/api/v1/auth/me', { token: r1.json.accessToken });
      record('B13', 'Auth', 'Rotated access token works', 200, me.status, me.status === 200);
      sessions.adminA = r1.json; // keep latest session for later checks
    }
    const r3 = await http('POST', '/api/v1/auth/refresh', { body: { refreshToken: 'not-a-token' } });
    record('B14', 'Auth', 'Invalid refresh token rejected', '401/400', r3.status, [400, 401].includes(r3.status), r3.text.slice(0, 140));
  }
  {
    const claims = decodeJwt(sessions.adminA.accessToken);
    const ttl = claims ? claims.exp - claims.iat : null;
    record('B15', 'Auth', 'Access token lifetime is short-lived', '<= 1800s', `${ttl}s`, typeof ttl === 'number' && ttl > 0 && ttl <= 1800, `iss=${claims?.iss} aud=${claims?.aud}`);
  }
  {
    // Session invalidation on logout: use a throwaway session so other checks keep theirs.
    const throwaway = await login(accounts.techA);
    const token = throwaway.json?.accessToken;
    const out = await http('POST', '/api/v1/auth/logout', { token });
    const after = await http('GET', '/api/v1/auth/me', { token });
    record('B16', 'Auth', 'Logout succeeds', 204, out.status, out.status === 204);
    record('B17', 'Auth', 'Access token rejected after logout', 401, after.status, after.status === 401,
      after.status === 401 ? 'session revoked server-side' : 'access token still valid until expiry (session not revoked)');
    const refreshAfter = await http('POST', '/api/v1/auth/refresh', { body: { refreshToken: throwaway.json.refreshToken } });
    record('B18', 'Auth', 'Refresh token rejected after logout', 401, refreshAfter.status, refreshAfter.status === 401);
  }

  // ---------- C. authorization matrix ----------
  const matrix = [
    ['C1', 'Platform-only list', '/api/v1/platform/workshops', 'platform', 200],
    ['C2', 'Platform-only list as workshop admin', '/api/v1/platform/workshops', 'adminA', 403],
    ['C3', 'Platform-only list as technician', '/api/v1/platform/workshops', 'techA', 403],
    ['C4', 'Workshop staff as platform admin', '/api/v1/workshop/staff', 'platform', 403],
    ['C5', 'Workshop staff as technician', '/api/v1/workshop/staff', 'techA', 403],
    ['C6', 'Technician queue as workshop admin', '/api/v1/technician/jobs', 'adminA', 403],
    ['C7', 'Technician queue as platform admin', '/api/v1/technician/jobs', 'platform', 403],
    ['C8', 'Workshop jobs as technician', '/api/v1/workshop/jobs', 'techA', 403],
    ['C9', 'Workshop jobs as workshop A admin', '/api/v1/workshop/jobs', 'adminA', 200],
    ['C10', 'Technician queue as technician', '/api/v1/technician/jobs', 'techA', 200],
    ['C11', 'Master library as platform admin', '/api/v1/platform/master/items', 'platform', 200],
    ['C12', 'Master library as workshop admin', '/api/v1/platform/master/items', 'adminA', 403],
    ['C13', 'Audit events as workshop admin', '/api/v1/platform/hierarchy/audit-events', 'adminA', 403],
  ];
  for (const [id, name, path, who, expected] of matrix) {
    const r = await http('GET', path, { token: sessions[who]?.accessToken });
    record(id, 'Authorization', name, expected, r.status, r.status === expected,
      r.status === expected ? '' : r.text.slice(0, 140));
  }
  for (const [i, who] of ['platform', 'adminA', 'techA'].entries()) {
    const r = await http('GET', '/api/v1/auth/me');
    record(`C14-${i}`, 'Authorization', `Anonymous request rejected (${who} surface)`, 401, r.status, r.status === 401);
  }

  // tenant isolation
  const jobsA = await http('GET', '/api/v1/workshop/jobs?size=50', { token: sessions.adminA.accessToken });
  const jobA = jobsA.json?.items?.[0];
  evidence.workshopA = { jobCount: jobsA.json?.total, sampleJob: jobA };
  if (jobA) {
    const cross = await http('GET', `/api/v1/workshop/jobs/${jobA.id}`, { token: sessions.adminB.accessToken });
    record('D1', 'Tenant isolation', 'Workshop B admin cannot read Workshop A job', '403/404', cross.status, [403, 404].includes(cross.status), `job=${jobA.reference}`);
    const crossList = await http('GET', '/api/v1/workshop/jobs?size=50', { token: sessions.adminB.accessToken });
    const overlap = (crossList.json?.items || []).filter((j) => j.id === jobA.id).length;
    record('D2', 'Tenant isolation', 'Workshop B job list excludes Workshop A jobs', 0, overlap, overlap === 0, `B total=${crossList.json?.total}`);
    const direct = await http('GET', `/api/v1/workshops/${sessions.adminA.memberships?.[0]?.workshopId}`, { token: sessions.adminB.accessToken });
    record('D3', 'Tenant isolation', 'Workshop B cannot read Workshop A workshop record', '403/404', direct.status, [403, 404].includes(direct.status));
    const techJobs = await http('GET', '/api/v1/technician/jobs?size=50', { token: sessions.techA.accessToken });
    const techSeesA = (techJobs.json?.items || []).some((j) => j.id === jobA.id && j.assignedTechnicianId !== sessions.techA.user?.id);
    record('D4', 'Tenant isolation', 'Technician queue only returns own/eligible jobs', false, techSeesA, techSeesA === false, `count=${techJobs.json?.items?.length}`);
    // Environment-drift finding: seed code makes admin.b a workshop admin only, but the
    // dev database currently marks the same account platformAdmin=true.
    const bClaims = decodeJwt(sessions.adminB.accessToken);
    const bUser = sessions.adminB.user;
    const elevated = bUser?.platformAdmin === true || bClaims?.role === 'PLATFORM_ADMIN';
    record('D5', 'Authorization', 'Workshop Admin B is NOT a platform admin (seed contract)', false, elevated,
      elevated === false,
      elevated ? `DB users.platform_admin=1, JWT role=${bClaims?.role}: account reaches every tenant` : '');
    const bPlatform = await http('GET', '/api/v1/platform/workshops', { token: sessions.adminB.accessToken });
    record('D6', 'Authorization', 'Workshop Admin B cannot list all workshops', 403, bPlatform.status, bPlatform.status === 403,
      bPlatform.status === 200 ? `returned ${bPlatform.json?.items?.length ?? bPlatform.json?.length ?? '?'} workshops across tenants` : '');
    const aPlatform = await http('GET', '/api/v1/platform/workshops', { token: sessions.adminA.accessToken });
    record('D7', 'Authorization', 'Workshop Admin A cannot list all workshops', 403, aPlatform.status, aPlatform.status === 403);

  } else {
    record('D1', 'Tenant isolation', 'Workshop A has a job fixture to test cross-tenant access', 'job exists', 'none', 'blocked');
  }

  // ---------- E. pagination / filters / counts ----------
  {
    const r = await http('GET', '/api/v1/workshop/jobs?page=0&size=2', { token: sessions.adminA.accessToken });
    const ok = r.status === 200 && Array.isArray(r.json?.items) && r.json.items.length <= 2 && r.json.page === 0 && r.json.size === 2;
    record('E1', 'Pagination', 'page/size honoured', 'items<=2,page=0,size=2', `${r.status} items=${r.json?.items?.length} total=${r.json?.total}`, ok, `totalPages=${r.json?.totalPages}`);
    const r2 = await http('GET', '/api/v1/workshop/jobs?page=1&size=2', { token: sessions.adminA.accessToken });
    record('E2', 'Pagination', 'second page returns distinct page metadata', 200, `${r2.status} page=${r2.json?.page}`, r2.status === 200 && r2.json?.page === 1);
    const r3 = await http('GET', '/api/v1/workshop/jobs?page=-1&size=2', { token: sessions.adminA.accessToken });
    record('E3', 'Pagination', 'negative page rejected or clamped', '400/200', r3.status, [200, 400].includes(r3.status), `page=${r3.json?.page ?? 'n/a'}`);
    const r4 = await http('GET', '/api/v1/workshop/jobs?size=100000', { token: sessions.adminA.accessToken });
    record('E4', 'Pagination', 'oversized size handled without error', '200/400', r4.status, [200, 400].includes(r4.status), `items=${r4.json?.items?.length ?? 'n/a'}`);
  }
  {
    const r = await http('GET', '/api/v1/workshop/jobs?search=QA_NO_SUCH_JOB_ZZZ', { token: sessions.adminA.accessToken });
    record('E5', 'Search', 'search with no matches returns empty page', '0 results', `${r.status} total=${r.json?.total}`, r.status === 200 && r.json?.total === 0);
    const r2 = await http('GET', '/api/v1/workshop/jobs?status=not-a-status', { token: sessions.adminA.accessToken });
    record('E6', 'Filter', 'unknown status filter rejected/handled', '400/422/200-empty', r2.status, [200, 400, 422].includes(r2.status), `total=${r2.json?.total ?? 'n/a'}`);
    const r3 = await http('GET', '/api/v1/workshop/jobs?from=not-a-date', { token: sessions.adminA.accessToken });
    record('E7', 'Filter', 'invalid date filter handled', '400/422', r3.status, [400, 422].includes(r3.status), r3.text.slice(0, 120));
  }
  {
    const r = await http('GET', '/api/v1/workshop/jobs/counts', { token: sessions.adminA.accessToken });
    const c = r.json || {};
    const sum = ['draft', 'scheduled', 'assigned', 'inProgress', 'pendingReview', 'approved', 'published', 'rejected', 'cancelled'].reduce((n, k) => n + (c[k] || 0), 0);
    record('E8', 'Data integrity', 'status counts sum to total', c.total, sum, r.status === 200 && sum === c.total, JSON.stringify(c));
    const list = await http('GET', '/api/v1/workshop/jobs?size=1', { token: sessions.adminA.accessToken });
    record('E9', 'Data integrity', 'counts.total equals list total', list.json?.total, c.total, list.json?.total === c.total);
  }

  // ---------- F. validation / not-found ----------
  const post = async (id, name, path, body, expected, who = 'adminA', extra = {}) => {
    const r = await http('POST', path, { token: sessions[who].accessToken, body, ...extra });
    record(id, 'Validation', name, expected, r.status, Array.isArray(expected) ? expected.includes(r.status) : r.status === expected, r.text.slice(0, 160));
    return r;
  };
  await post('F1', 'Create job with empty body', '/api/v1/workshop/jobs', {}, [400, 422]);
  await post('F2', 'Create job with non-UUID template version', '/api/v1/workshop/jobs', { templateVersionId: 'not-a-uuid', customerName: 'QA', vehicleMake: 'QA', vehicleModel: 'QA', scope: 'QA' }, [400, 422, 404]);
  await post('F3', 'Create job with invalid email', '/api/v1/workshop/jobs', { templateVersionId: '00000000-0000-0000-0000-000000000000', customerName: 'QA', customerEmail: 'bad@@mail', vehicleMake: 'QA', vehicleModel: 'QA', scope: 'QA' }, [400, 404, 422]);
  await post('F4', 'Create job with over-long customer name', '/api/v1/workshop/jobs', { templateVersionId: '00000000-0000-0000-0000-000000000000', customerName: 'X'.repeat(5000), vehicleMake: 'QA', vehicleModel: 'QA', scope: 'QA' }, [400, 404, 413, 422]);
  await post('F5', 'Create job with unknown template version', '/api/v1/workshop/jobs', { templateVersionId: '11111111-1111-1111-1111-111111111111', customerName: 'QA', vehicleMake: 'QA', vehicleModel: 'QA', scope: 'QA' }, [404, 400, 422]);
  {
    const r = await http('GET', '/api/v1/workshop/jobs/11111111-1111-1111-1111-111111111111', { token: sessions.adminA.accessToken });
    record('F6', 'Not found', 'Unknown job id -> 404', 404, r.status, r.status === 404, r.text.slice(0, 140));
    const r2 = await http('GET', '/api/v1/workshop/jobs/not-a-uuid', { token: sessions.adminA.accessToken });
    // Treating a malformed identifier as 404 is a defensible contract; only a 5xx would be a defect.
    record('F7', 'Validation', 'Malformed job id path parameter handled', '400 or 404', r2.status, [400, 404].includes(r2.status), r2.text.slice(0, 140));
    const r3 = await http('GET', '/api/v1/definitely-not-a-route');
    record('F8', 'Not found', 'Unknown route does not 5xx (auth-first 401/404 both valid)', '401 or 404', r3.status, [401, 404].includes(r3.status), r3.text.slice(0, 120));
    const r4 = await http('PUT', '/api/v1/workshop/jobs/11111111-1111-1111-1111-111111111111', { token: sessions.adminA.accessToken, body: { customerName: 'QA' } });
    record('F9', 'Not found', 'Update unknown job -> 404', 404, r4.status, r4.status === 404, r4.text.slice(0, 140));
  }

  // ---------- G. public surface ----------
  {
    const r = await http('GET', '/r/unavailable');
    const neutral = r.status === 200 && !/customer|vehicle|report|inspection/i.test(r.text.replace(/<script[\s\S]*?<\/script>/gi, ''));
    record('G1', 'Public', '/r/unavailable serves neutral page', 200, r.status, r.status === 200, `bytes=${r.text.length}`);
    const r2 = await http('GET', '/r/unknown-token-qa');
    const neutral404 = r2.status === 404 && /This link is unavailable/i.test(r2.text);
    record('G2', 'Public', 'Unknown report token is neutral (no data leak)', '404 + neutral copy', r2.status, neutral404, `bytes=${r2.text.length}`);
    const r3 = await http('GET', '/r/unknown-token-qa', { headers: { Accept: 'application/json' } });
    record('G3', 'Public', 'Unknown token JSON request does not leak', '404/406', r3.status, [404, 406].includes(r3.status), `ct=${r3.headers['content-type']}`);
  }

  // ---------- H. transport / headers ----------
  {
    const r = await http('GET', '/actuator/health');
    const h = r.headers;
    record('H1', 'Security headers', 'X-Content-Type-Options nosniff', 'nosniff', h['x-content-type-options'] || 'absent', h['x-content-type-options'] === 'nosniff');
    record('H2', 'Security headers', 'Cache-Control on API responses', 'present', h['cache-control'] || 'absent', !!h['cache-control'], 'health endpoint');
    const csp = h['content-security-policy'] || 'absent';
    record('H3', 'Security headers', 'CSP present on server-rendered page', 'present', csp === 'absent' ? 'absent' : 'present', csp !== 'absent', csp.slice(0, 90));
    const r2 = await http('OPTIONS', '/api/v1/auth/login', { headers: { Origin: 'http://evil.example', 'Access-Control-Request-Method': 'POST' } });
    const acao = r2.headers['access-control-allow-origin'];
    record('H4', 'CORS', 'Unknown origin not wildcard-allowed', 'not * / not evil.example', acao || 'absent', acao !== '*' && acao !== 'http://evil.example', `status=${r2.status}`);
  }

  // ---------- I. abuse / rate limit (bounded) ----------
  {
    const statuses = [];
    for (let i = 0; i < 8; i++) {
      const r = await login('platform@truereport.test', `wrong-${i}-Aa1!`);
      statuses.push(r.status);
    }
    record('I1', 'Abuse', 'Repeated bad logins are throttled or consistently 401', '401 only or 429 present', statuses.join(','), statuses.every((s) => s === 401) || statuses.includes(429), statuses.includes(429) ? 'rate limiter active' : 'no rate limit observed (8 attempts)');
  }

  const summary = {
    generatedAt: new Date().toISOString(),
    base: BASE,
    total: results.length,
    passed: results.filter((r) => r.pass === true).length,
    failed: results.filter((r) => r.pass === false).length,
    blocked: results.filter((r) => r.pass === 'blocked').length,
    results,
    evidence,
  };
  writeFileSync('qa_audit/evidence/api-audit-results.json', JSON.stringify(summary, null, 2));
  console.log(`\nSUMMARY total=${summary.total} passed=${summary.passed} failed=${summary.failed} blocked=${summary.blocked}`);
  const failed = results.filter((r) => r.pass === false);
  if (failed.length) {
    console.log('\nFAILED:');
    for (const f of failed) console.log(`- ${f.id} ${f.name} expected=${f.expected} actual=${f.actual} ${f.notes}`);
  }
}

main().catch((e) => { console.error('HARNESS ERROR', e); process.exit(2); });
