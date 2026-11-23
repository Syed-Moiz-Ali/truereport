// Disposable job: UPDATE + CANCEL (soft delete) + stale-version conflict.
const B = 'http://localhost:8080';
const PW = process.env.QA_PASSWORD;
if (!PW) { console.error('QA_PASSWORD is required.'); process.exit(2); }
const REF = process.env.REF || 'JOB-5ED26BF9';
const out = [];
const log = (id, ok, detail) => { out.push({ id, ok, detail }); console.log(`${ok ? 'PASS' : 'FAIL'} ${id} :: ${JSON.stringify(detail)}`); };

const login = await fetch(`${B}/api/v1/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'admin.a@truereport.test', password: PW }) }).then((r) => r.json());
const H = { Authorization: `Bearer ${login.accessToken}`, 'Content-Type': 'application/json' };
const get = async (p) => { const r = await fetch(B + p, { headers: H }); return { status: r.status, json: await r.json().catch(() => null) }; };

const list = await get(`/api/v1/workshop/jobs?search=${REF}`);
const job = list.json.items[0];
log('R1 read disposable job', !!job, { ref: job?.reference, status: job?.status, version: job?.version });

const before = job.customerPhone;
const full = {
  customerName: job.customerName, customerPhone: '+971599999999', customerEmail: job.customerEmail,
  vehicleVin: job.vehicleVin, vehicleMake: job.vehicleMake, vehicleModel: job.vehicleModel,
  vehicleYear: job.vehicleYear, vehiclePlate: job.vehiclePlate, odometerValue: job.odometerValue,
  odometerUnit: job.odometerUnit, transmission: job.transmission, fuelType: job.fuelType,
  preferredLanguage: job.preferredLanguage, version: job.version,
};
const upd = await fetch(`${B}/api/v1/workshop/jobs/${job.id}`, {
  method: 'PUT', headers: H,
  body: JSON.stringify(full),
});
const updBody = await upd.json().catch(() => null);
log('U1 update customer phone', upd.status === 200 && updBody?.customerPhone === '+971599999999', { status: upd.status, phone: updBody?.customerPhone, version: updBody?.version });

const read = await get(`/api/v1/workshop/jobs/${job.id}`);
log('U2 update persists on re-read', read.json?.customerPhone === '+971599999999', { phone: read.json?.customerPhone });

const stale = await fetch(`${B}/api/v1/workshop/jobs/${job.id}`, {
  method: 'PUT', headers: H,
  body: JSON.stringify({ ...full, customerPhone: '+971588888888' }),
});
log('U3 stale version rejected', stale.status === 409, { status: stale.status, code: (await stale.json().catch(() => ({})))?.code });

const current = await get(`/api/v1/workshop/jobs/${job.id}`);
const cancel = await fetch(`${B}/api/v1/workshop/jobs/${job.id}/cancel`, {
  method: 'POST', headers: H,
  body: JSON.stringify({ reason: 'QA audit cleanup', version: current.json.version }),
});
const cancelBody = await cancel.json().catch(() => null);
log('D1 cancel (soft delete)', cancel.status === 200 && cancelBody?.status === 'CANCELLED', { status: cancel.status, jobStatus: cancelBody?.status });

const cancelAgain = await fetch(`${B}/api/v1/workshop/jobs/${job.id}/cancel`, {
  method: 'POST', headers: H,
  body: JSON.stringify({ reason: 'QA audit cleanup', version: cancelBody?.version ?? current.json.version }),
});
log('D2 repeat cancel rejected', cancelAgain.status === 409, { status: cancelAgain.status, code: (await cancelAgain.json().catch(() => ({})))?.code });

const after = await get(`/api/v1/workshop/jobs/${job.id}`);
log('D3 cancelled job still readable (soft delete)', after.status === 200 && after.json?.status === 'CANCELLED', { status: after.json?.status });

const updateCancelled = await fetch(`${B}/api/v1/workshop/jobs/${job.id}`, {
  method: 'PUT', headers: H,
  body: JSON.stringify({ customerPhone: '+971577777777', version: after.json?.version }),
});
log('D4 update after cancel rejected', updateCancelled.status === 409, { status: updateCancelled.status, code: (await updateCancelled.json().catch(() => ({})))?.code });

const counts = await get('/api/v1/workshop/jobs/counts');
log('D5 counts include the cancellation', (counts.json?.cancelled || 0) >= 32, { cancelled: counts.json?.cancelled, total: counts.json?.total });

console.log('\nRESULT_JSON ' + JSON.stringify({ ref: REF, jobId: job.id, before, out }));
