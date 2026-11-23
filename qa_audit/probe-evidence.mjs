// Probe: can a photo+video evidence pair be stored and marked READY for one item?
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

const B = 'http://localhost:8080';
const PW = process.env.QA_PASSWORD;
if (!PW) { console.error('QA_PASSWORD is required.'); process.exit(2); }
const job = process.env.JOB || '01a20740-7ea8-7a2b-a7dd-e600df69545a';
const itemCode = process.env.ITEM || 'ENG-OIL-01';

const login = await fetch(B + '/api/v1/auth/login', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'tech.a@truereport.test', password: PW }),
}).then((r) => r.json());
const T = { Authorization: 'Bearer ' + login.accessToken };

// minimal MP4 (ftyp box) — server accepts mime video/mp4 if it does not decode
const video = Buffer.concat([
  Buffer.from([0, 0, 0, 0x18]),
  Buffer.from('ftypmp42'),
  Buffer.from([0, 0, 0, 0]),
  Buffer.from('mp42isom'),
  Buffer.alloc(1024, 0),
]);
const photo = readFileSync('qa_audit/evidence/photo.jpg');

async function upload(type, bytes, mime) {
  const sha256 = createHash('sha256').update(bytes).digest('hex');
  const init = await fetch(`${B}/api/v1/technician/jobs/${job}/items/${encodeURIComponent(itemCode)}/evidence/init`, {
    method: 'POST', headers: { ...T, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      type, mime, bytes: bytes.length, sha256,
      capturedAt: new Date().toISOString().slice(0, 19), captureSource: 'FILE',
      deviceId: null, width: type === 'PHOTO' ? 1280 : null, height: type === 'PHOTO' ? 720 : null,
      durationMs: type === 'VIDEO' ? 1000 : null, captionEn: null, captionAr: null, posterBase64: null,
    }),
  });
  const created = await init.json();
  console.log(type, 'init', init.status, JSON.stringify(created).slice(0, 200));
  if (!created.id) return null;
  const put = await fetch(`${B}/api/v1/technician/jobs/${job}/items/${encodeURIComponent(itemCode)}/evidence/${created.id}/content`, {
    method: 'PUT', headers: { ...T, 'Content-Type': 'application/octet-stream' }, body: bytes,
  });
  console.log(type, 'put', put.status, (await put.text()).slice(0, 120));
  const done = await fetch(`${B}/api/v1/technician/jobs/${job}/items/${encodeURIComponent(itemCode)}/evidence/${created.id}/complete`, {
    method: 'POST', headers: { ...T, 'Content-Type': 'application/json' },
    body: JSON.stringify({ captionEn: null, captionAr: null, posterBase64: null }),
  });
  console.log(type, 'complete', done.status, (await done.text()).slice(0, 300));
  return created.id;
}

await upload('PHOTO', photo, 'image/jpeg');
await upload('VIDEO', video, 'video/mp4');

const listed = await fetch(`${B}/api/v1/technician/jobs/${job}/items/${encodeURIComponent(itemCode)}/evidence`, { headers: T });
console.log('list', listed.status, JSON.stringify(await listed.json()).slice(0, 800));
