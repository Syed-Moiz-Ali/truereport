import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const cats = [
  ['هوية المركبة والاستلام', 'Vehicle identity and intake'],
  ['الهيكل الخارجي والطلاء', 'Exterior body panels and paint'],
  ['الزجاج والمرايا والإضاءة والمساحات', 'Glass, mirrors, lights and wipers'],
  ['الإطارات والعجلات والفرامل', 'Tyres, wheels and brakes'],
  ['المقصورة وسلامة الركاب', 'Interior and occupant safety'],
  ['المحرك والأنظمة الميكانيكية الظاهرة', 'Engine and visible mechanical systems'],
  ['ناقل الحركة ونظام الدفع', 'Transmission and drivetrain'],
  ['التوجيه والتعليق', 'Steering and suspension'],
  ['الأنظمة الكهربائية والتكييف', 'Electrical systems and air conditioning'],
  ['أسفل الهيكل والعادم واختبار الطريق', 'Underbody, exhaust and road test'],
];
const results = [
  ['لا توجد مشكلة ملحوظة في هذا الفحص', 'No issue observed in this check'],
  ['يوصى بالانتباه', 'Attention recommended'],
  ['تم اكتشاف عيب', 'Defect found'],
  ['لم يتم الفحص', 'Not checked'],
  ['لا ينطبق', 'Not applicable'],
  ['تعذر التحقق', 'Could not verify'],
];
let n = 0;
const rows = [];
for (let c = 0; c < cats.length; c++) {
  rows.push(`<tr class="cat"><td colspan="5"><h2>${cats[c][0]} — ${cats[c][1]}</h2></td></tr>`);
  for (let i = 0; i < 12; i++) {
    n++;
    const r = results[(n - 1) % results.length];
    rows.push(`<tr><td class="num">${n}</td><td><b class="ar">نقطة الفحص ${n}</b><div class="en small">Inspection point ${n}</div></td><td><div class="ar">${r[0]}</div><div class="en small">${r[1]}</div></td><td>${['Minor','Moderate','Major','Safety-critical'][(n-1)%4]}</td><td class="ar">${r[0].includes('لم يتم') ? 'تعذر الوصول إلى النقطة.' : r[0].includes('تعذر') ? 'لم تتوفر أداة القياس.' : '—'}</td></tr>`);
  }
}
const photos = [];
for (let i = 1; i <= 20; i++) {
  const num = String(i).padStart(2, '0');
  photos.push(`<figure><img src="assets/photos/photo-${num}.jpg" alt="Evidence ${i}"><figcaption>صورة دليل ${i} / Evidence ${i}</figcaption></figure>`);
}
const html = `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Vehicle inspection report</title>
<meta name="description" content="A vehicle inspection report is available at this link.">
<meta name="robots" content="noindex, nofollow">
<meta property="og:title" content="Vehicle inspection report">
<meta property="og:description" content="A vehicle inspection report is available at this link.">
<style>
  :root { --ink:#17212b; --muted:#4d6670; --brand:#0b3b4a; --line:#d5e3e6; --bg:#f7fafa; }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--bg); color:var(--ink); font:15px/1.55 Arial,"STSong",sans-serif; }
  main { max-width:980px; margin:0 auto; padding:16px; }
  header, section { background:#fff; border:1px solid var(--line); border-radius:12px; padding:16px; margin-bottom:12px; }
  h1 { font-size:26px; margin:0; color:var(--brand); }
  h2 { font-size:18px; margin:24px 0 8px; color:var(--brand); }
  .muted { color:var(--muted); }
  .ltr { direction:ltr; unicode-bidi:isolate; }
  .rtl { direction:rtl; text-align:right; unicode-bidi:isolate; }
  .grid { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:8px; }
  .card { border:1px solid var(--line); border-radius:8px; padding:12px; }
  table { width:100%; border-collapse:collapse; }
  th, td { border-bottom:1px solid var(--line); padding:8px; vertical-align:top; }
  th { background:var(--brand); color:#fff; text-align:right; }
  .num { width:48px; text-align:center; color:var(--muted); }
  .small { font-size:12px; color:var(--muted); }
  .photos { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:8px; }
  figure { margin:0; border:1px solid var(--line); border-radius:8px; overflow:hidden; background:#fff; }
  figure img { display:block; width:100%; height:150px; object-fit:cover; }
  figcaption { padding:6px 8px; font-size:12px; color:var(--muted); }
  @media (max-width:700px) { main { padding:8px; } header,section { padding:12px; } .photos { grid-template-columns:1fr; } }
</style>
</head>
<body data-report-ready="true">
<main>
<header>
  <h1>تقرير فحص مركبة</h1>
  <div class="muted">Vehicle inspection report</div>
  <p class="ltr">TR-2026-0001 · v1 · 2026-11-03 14:30 GST</p>
  <p>ورشة دبي للفحص الفني — Dubai Technical Inspection Workshop<br>تويوتا لاند كروزر 2022 — Toyota Land Cruiser 2022</p>
  <p class="ltr">VIN WUAZZZGY4NA901440 · 82,902 km</p>
</header>
<section>
  <h2>ملخص الفحص / Inspection summary</h2>
  <p class="rtl">تم فحص المركبة في ورشة شريك في دبي. يغطي هذا التقرير الحالة الظاهرة وقت الفحص وبضمن النطاق المحدد فقط. لا يمثل هذا التقرير ضماناً بأن المركبة خالية من العيوب، وليس شهادة فحص رسمية.</p>
  <p class="ltr">The vehicle was inspected at a partner workshop in Dubai. This report records the visible condition at the time of inspection within the defined scope. It is not a warranty or an official inspection certificate.</p>
  <div class="grid">
    <div class="card ltr"><b>Inspection coverage</b><br>113 of 120 applicable checks completed.</div>
    <div class="card rtl"><b>تغطية الفحص</b><br>تم إكمال 113 من 120 فحصاً منطبقاً.</div>
  </div>
</section>
<section>
  <h2>تفاصيل الفحص / Inspection detail</h2>
  <table>
    <thead><tr><th>#</th><th>البند / Item</th><th>النتيجة / Result</th><th>الخطورة / Severity</th><th>ملاحظة / Note</th></tr></thead>
    <tbody>${rows.join('\n')}</tbody>
  </table>
</section>
<section>
  <h2>معرض الأدلة / Evidence gallery</h2>
  <div class="photos">${photos.join('\n')}</div>
</section>
<section>
  <h2>الحدود / Limitations</h2>
  <p class="rtl">الفحص بصري وغير تدخلي. لا يتم فك المكونات أو فتحها. قد تبقى عيوب خفية أو متقطعة غير مكتشفة. التقرير معلومة وليس ضماناً.</p>
  <p class="ltr">The inspection is visual and non-invasive. Components are not dismantled or opened. Hidden or intermittent defects may remain. This report is information, not a warranty.</p>
</section>
</main>
</body>
</html>`;
fs.writeFileSync(path.join(__dirname, 'index.html'), html, 'utf8');
console.log('Wrote index.html', html.length, 'chars,', n, 'rows');
