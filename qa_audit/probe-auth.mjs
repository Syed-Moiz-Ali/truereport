const BASE = 'http://localhost:8080';
const PW = process.env.QA_PASSWORD;
if (!PW) { console.error('QA_PASSWORD is required.'); process.exit(2); }
const emails = {
  platform: 'platform@truereport.test',
  adminA: 'admin.a@truereport.test',
  adminB: 'admin.b@truereport.test',
  techA: 'tech.a@truereport.test',
  techManual: 'tech.test@gmail.com',
};
const out = {};
for (const [k, email] of Object.entries(emails)) {
  const res = await fetch(BASE + '/api/v1/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: k === 'techManual' ? '12345678' : PW }),
  });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch {}
  out[k] = { status: res.status, keys: json ? Object.keys(json) : null, json: json && { ...json, accessToken: json.accessToken ? '(token)' : json.access_token ? '(token_snake)' : undefined, refreshToken: json.refreshToken ? '(token)' : undefined }, raw: json ? undefined : text.slice(0, 200) };
}
// workshop A membership id and cross-tenant read
let a = null;
{
  const r = await fetch(BASE + '/api/v1/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: emails.adminA, password: PW }) });
  a = await r.json();
}
let b = null;
{
  const r = await fetch(BASE + '/api/v1/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: emails.adminB, password: PW }) });
  b = await r.json();
}
const wsA = a.memberships?.[0]?.workshopId;
const wsB = b.memberships?.[0]?.workshopId;
out.membershipIds = { wsA, wsB, aName: a.memberships?.[0]?.workshopName, bName: b.memberships?.[0]?.workshopName };
const tokenKey = a.accessToken ? 'accessToken' : 'access_token';
for (const [label, token, ws] of [['B-reads-A', b[tokenKey], wsA], ['B-reads-B', b[tokenKey], wsB], ['A-reads-B', a[tokenKey], wsB]]) {
  const r = await fetch(`${BASE}/api/v1/workshops/${ws}`, { headers: { Authorization: `Bearer ${token}` } });
  const t = await r.text();
  out[label] = { url: `${BASE}/api/v1/workshops/${ws}`, status: r.status, body: t.slice(0, 400) };
}
// technician manual account existence in API list
{
  const r = await fetch(BASE + '/api/v1/workshop/staff', { headers: { Authorization: `Bearer ${a[tokenKey]}` } });
  const t = await r.text();
  out.staff = { status: r.status, body: t.slice(0, 800) };
}
// public unknown token page text
{
  const r = await fetch(BASE + '/r/unknown-token-qa');
  out.public404 = { status: r.status, ct: r.headers.get('content-type'), text: (await r.text()).slice(0, 900) };
}
// roles claim
{
  const payload = JSON.parse(Buffer.from(a[tokenKey].split('.')[1], 'base64url').toString());
  out.claimsA = payload;
  const bp = JSON.parse(Buffer.from(b[tokenKey].split('.')[1], 'base64url').toString());
  out.claimsB = bp;
}
console.log(JSON.stringify(out, null, 2));
