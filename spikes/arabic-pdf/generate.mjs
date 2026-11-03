import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(__dirname, 'report.html');

const categories = [
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
  ['لا توجد مشكلة ملحوظة في هذا الفحص', 'No issue observed in this check', '', ''],
  ['يوصى بالانتباه', 'Attention recommended', 'Minor', 'مراقبة التآكل في الفحص القادم.'],
  ['تم اكتشاف عيب', 'Defect found', 'Moderate', 'يوصى بالإصلاح خلال 30 يوماً.'],
  ['لم يتم الفحص', 'Not checked', '', 'تعذر الوصول إلى النقطة بسبب غطاء المحرك.'],
  ['لا ينطبق', 'Not applicable', '', 'المركبة لا تحتوي على هذا النظام.'],
  ['تعذر التحقق', 'Could not verify', '', 'لم تتوفر أداة القياس المناسبة.'],
];

const arabicLong = `تم فحص المركبة في ورشة شريك معتمدة في دبي. يغطي هذا التقرير الحالة الظاهرة للمركبة في وقت الفحص وبضمن النطاق المحدد فقط. لا يمثل هذا التقرير ضماناً بأن المركبة خالية من العيوب، ولا يشكل شهادة فحص رسمية من هيئة الطرق والمواصلات أو أي جهة حكومية. قد تبقى عيوب خفية أو متقطعة غير ظاهرة أثناء الفحص. يجب على المشتري إجراء فحصه المستقل والتحقق من تاريخ المركبة قبل اتخاذ قرار الشراء.`;

const arabicLong2 = `لوحظ وجود خدوش سطحية على الجانب الأيسر من الصادم الأمامي، مع إعادة طلاء جزئية للوحة الرفرف الخلفي الأيمن. لا توجد علامات واضحة على إصلاح هيكلي أو لحام غير مصنعي. تم قياس سماكة الطلاء في عدة نقاط، وكانت القيم ضمن النطاق المتوقع مع اختلاف موضعي يستدعي الانتباه. يوصى بمراجعة سجل الحوادث الرسمي بشكل منفصل.`;

const rows = [];
let n = 0;
for (const [arCat, enCat] of categories) {
  for (let i = 1; i <= 12; i++) {
    n++;
    const r = results[(n - 1) % results.length];
    const arItem = `نقطة الفحص ${n} — ${arCat}`;
    const enItem = `Inspection point ${n} — ${enCat}`;
    const note = r[2] === 'Minor'
      ? 'تآكل طفيف في الحافة، لا يؤثر على الوظيفة حالياً.'
      : r[2] === 'Moderate'
        ? 'تم رصد عيب واضح ويتطلب متابعة. يوصى بمراجعة الفني المختص.'
        : r[3];
    rows.push(`<tr class="item"><td class="num">${n}</td><td><div class="ar">${arItem}</div><div class="en small">${enItem}</div></td><td><div class="ar">${r[0]}</div><div class="en small">${r[1]}</div></td><td>${r[2] || '—'}</td><td><div class="ar">${note || '—'}</div></td></tr>`);
  }
}

const photoCells = [];
for (let i = 1; i <= 20; i++) {
  const num = String(i).padStart(2, '0');
  photoCells.push(`<td class="photo"><img src="assets/photos/photo-${num}.jpg" alt="Evidence photo ${i}"><div class="caption"><span class="ar">صورة دليل ${i}</span> <span class="en">Evidence ${i}</span></div></td>`);
}
const photoRows = [];
for (let i = 0; i < photoCells.length; i += 4) {
  photoRows.push(`<tr>${photoCells.slice(i, i + 4).join('')}</tr>`);
}

const html = `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<title>TrueReport Spike Report TR-2026-0001</title>
<style>
  @page { size: A4; margin: 16mm 13mm 20mm 13mm; }\n  @font-face { font-family: 'NotoNaskh'; src: url('assets/NotoNaskhArabic-Regular.ttf') format('truetype'); }
  * { box-sizing: border-box; }
  body { font-family: "NotoNaskh", Arial, "STSong", sans-serif; font-size: 9.2pt; line-height: 1.45; color: #17212b; margin: 0; }
  h1, h2, h3 { margin: 0 0 4mm 0; line-height: 1.2; }
  h1 { font-size: 24pt; color: #0b3b4a; }
  h2 { font-size: 15pt; color: #0b3b4a; border-bottom: 1px solid #b9d3d8; padding-bottom: 2mm; page-break-after: avoid; }
  h3 { font-size: 11.5pt; color: #173b45; page-break-after: avoid; }
  .cover { page-break-after: always; padding-top: 18mm; }
  .badge { display: inline-block; border: 1px solid #0b3b4a; border-radius: 3mm; padding: 2mm 4mm; font-weight: bold; margin-bottom: 8mm; }
  .meta { width: 100%; border-collapse: collapse; margin-top: 10mm; }
  .meta td { padding: 2.2mm 2mm; border-bottom: 1px solid #d9e5e8; vertical-align: top; }
  .meta td:first-child { width: 38mm; color: #4d6670; font-weight: bold; }
  .ar { direction: rtl; text-align: right; unicode-bidi: isolate; }
  .en { direction: ltr; text-align: left; unicode-bidi: isolate; }
  .small { font-size: 8pt; color: #4d6670; margin-top: 1mm; }
  .mixed { direction: rtl; text-align: right; unicode-bidi: isolate; }
  .ltr-run { direction: ltr; unicode-bidi: isolate; font-family: Arial, monospace; }
  .notice { background: #f4f8f8; border-right: 3mm solid #0b3b4a; padding: 4mm; margin: 5mm 0; }
  .notice p { margin: 0 0 2mm 0; }
  table.items { width: 100%; border-collapse: collapse; table-layout: fixed; }
  table.items thead { display: table-header-group; }
  table.items th { background: #0b3b4a; color: #fff; font-size: 8.2pt; padding: 2mm 1.6mm; text-align: right; }
  table.items td { border-bottom: 1px solid #cfdde0; padding: 2mm 1.6mm; vertical-align: top; }
  table.items tr.item { page-break-inside: avoid; }
  .num { width: 8mm; text-align: center; color: #4d6670; }
  .cat { margin-top: 7mm; }
  .photo-grid { width: 100%; border-collapse: separate; border-spacing: 2mm; table-layout: fixed; }
  .photo { width: 25%; vertical-align: top; padding: 0; }
  .photo img { width: 100%; height: 34mm; object-fit: cover; display: block; border: 0.3mm solid #cfdde0; }
  .caption { font-size: 7.2pt; color: #4d6670; margin-top: 1mm; }\n  .caption .ar, .caption .en { display: block; }
  .break { page-break-before: always; }
  .coverage { width: 100%; border-collapse: collapse; margin: 4mm 0; }
  .coverage td, .coverage th { border: 1px solid #cfdde0; padding: 2mm; text-align: center; }
  .coverage th { background: #eaf2f4; }
  .rtl-list { direction: rtl; padding-right: 5mm; }
  .rtl-list li { margin-bottom: 1.5mm; }
  .ltr-list { direction: ltr; padding-left: 5mm; }
  .ltr-list li { margin-bottom: 1.5mm; }
</style>
</head>
<body>
  <section class="cover">
    <div class="badge">تقرير فحص مركبة · Vehicle Inspection Report</div>
    <h1>تقرير فحص ثنائي اللغة<br><span class="en" style="font-size:15pt;color:#4d6670">Bilingual inspection report</span></h1>
    <table class="meta">
      <tr><td>رقم التقرير / Report ID</td><td><span class="ltr-run">TR-2026-0001</span></td></tr>
      <tr><td>إصدار التقرير / Report version</td><td><span class="ltr-run">v1</span></td></tr>
      <tr><td>تاريخ الفحص / Inspection date</td><td><span class="ltr-run">2026-11-03 14:30 GST</span></td></tr>
      <tr><td>الورشة / Workshop</td><td>ورشة دبي للفحص الفني — Dubai Technical Inspection Workshop</td></tr>
      <tr><td>الفني / Technician</td><td>سعيد الحربي — Saeed Al Harbi</td></tr>
      <tr><td>المركبة / Vehicle</td><td>تويوتا لاند كروزر 2022 — Toyota Land Cruiser 2022</td></tr>
      <tr><td>رقم الهيكل / VIN</td><td><span class="ltr-run">WUAZZZGY4NA901440</span></td></tr>
      <tr><td>العداد / Odometer</td><td><span class="ltr-run">82,902 km</span></td></tr>
    </table>
    <div class="notice">
      <p class="ar"><strong>ملاحظة مهمة:</strong> هذا التقرير يسجل حالة المركبة وقت الفحص وبضمن النطاق المحدد. وهو ليس ضماناً ولا شهادة فحص رسمية.</p>
      <p class="en"><strong>Important:</strong> This report records the vehicle at the time of inspection within the defined scope. It is not a warranty or an official inspection certificate.</p>
    </div>
  </section>

  <section>
    <h2>ملخص الفحص / Inspection summary</h2>
    <p class="ar">${arabicLong}</p>
    <p class="en">The vehicle was inspected at a partner workshop in Dubai. This report covers the visible condition at the time of inspection and within the stated scope only. It is not a guarantee that the vehicle has no faults and it is not an official Roads and Transport Authority or government inspection certificate. Hidden or intermittent faults may remain. The buyer should obtain an independent inspection and verify the vehicle history before deciding to purchase.</p>
    <table class="coverage">
      <tr><th>الفحوص المطبقة / Applicable</th><th>مكتملة / Completed</th><th>غير منطبقة / Not applicable</th><th>لم يتم فحصها / Not checked</th><th>تعذر التحقق / Could not verify</th></tr>
      <tr><td>120</td><td>113</td><td>3</td><td>2</td><td>2</td></tr>
    </table>
    <div class="notice">
      <p class="mixed"><strong>تغطية الفحص:</strong> تم إكمال <span class="ltr-run">113</span> من <span class="ltr-run">120</span> فحصاً منطبقاً. هذه نسبة تغطية وليست درجة حالة المركبة.</p>
      <p class="mixed"><strong>Inspection coverage:</strong> <span class="ltr-run">113</span> of <span class="ltr-run">120</span> applicable checks were completed. This is inspection coverage, not a vehicle condition score.</p>
    </div>
  </section>

  <section>
    <h2>بيانات مختلطة / Mixed-direction examples</h2>
    <p class="mixed">اسم العميل بالعربية: أحمد بن سعيد. الاسم بالروسية: <span class="ltr-run">Иван Петров</span>. الاسم بالصينية: <span class="ltr-run">张伟</span>.</p>
    <p class="mixed">رقم الهيكل <span class="ltr-run">WUAZZZGY4NA901440</span>، رقم اللوحة <span class="ltr-run">D 1429</span>، الهاتف <span class="ltr-run">+971 50 123 4567</span>، التاريخ <span class="ltr-run">2026-11-03</span>.</p>
    <p class="mixed">ملاحظة الفني: تم فحص الإطار الأمامي الأيسر عند <span class="ltr-run">32 PSI</span> وقراءة العداد <span class="ltr-run">82,902 km</span>، ثم تمت متابعة الفحص.</p>
    <p class="en">Mixed line: VIN <span class="ltr-run">WUAZZZGY4NA901440</span>, phone <span class="ltr-run">+971 50 123 4567</span>, date <span class="ltr-run">2026-11-03</span>, odometer <span class="ltr-run">82,902 km</span>, then an Arabic note: <span dir="rtl">تم فحص المركبة بالكامل</span>.</p>
    <p class="ar">${arabicLong2}</p>
    <h3>قائمة عربية / Arabic list</h3>
    <ul class="rtl-list">
      <li>تم فحص المصابيح الأمامية والخلفية.</li>
      <li>تم قياس عمق المداس في الإطارات الأربعة.</li>
      <li>تم التحقق من مستوى السوائل الظاهرة.</li>
    </ul>
    <h3>English list</h3>
    <ul class="ltr-list">
      <li>Front and rear lights checked.</li>
      <li>Tread depth measured on all four tyres.</li>
      <li>Visible fluid levels checked.</li>
    </ul>
  </section>

  <section class="break">
    <h2>تفاصيل الفحص / Inspection detail</h2>
    <p class="ar">فيما يلي <span class="ltr-run">120</span> نقطة فحص موزعة على <span class="ltr-run">10</span> فئات. الجدول مصمم لاختبار التفاف النص العربي والإنجليزي، وانتقال الصفوف بين الصفحات، وتكرار رأس الجدول.</p>
    <table class="items">
      <thead><tr><th>#</th><th>البند / Item</th><th>النتيجة / Result</th><th>الخطورة / Severity</th><th>ملاحظة / Note</th></tr></thead>
      <tbody>
        ${rows.map((r, i) => {
          const catIndex = Math.floor(i / 12);
          const isFirst = i % 12 === 0;
          return (isFirst ? `<tr><td colspan="5" class="cat"><h3>${categories[catIndex][0]} — ${categories[catIndex][1]}</h3></td></tr>` : '') + r;
        }).join('\n')}
      </tbody>
    </table>
  </section>

  <section class="break">
    <h2>معرض الأدلة / Evidence gallery</h2>
    <p class="ar">الصور التالية هي صور دليل للمركبة التي تم فحصها. الصور التوضيحية (guide images) لا تُعرض على أنها دليل على حالة هذه المركبة.</p>
    <table class="photo-grid">
      ${photoRows.join('\n')}
    </table>
  </section>

  <section class="break">
    <h2>الحدود وإخلاء المسؤولية / Limitations and disclaimer</h2>
    <p class="ar">الفحص بصري وغير تدخلي. لا يتم فك المكونات أو فتحها. لا يشمل التقرير تاريخ الخدمة أو الحوادث أو الاستدعاءات. قد تبقى عيوب خفية أو متقطعة غير مكتشفة. لا يتحمل معد التقرير مسؤولية الأعطال التي تحدث بعد الفحص.</p>
    <p class="en">The inspection is visual and non-invasive. Components are not dismantled or opened. The report does not include service history, accident history or recalls. Hidden or intermittent defects may remain undetected. The report author is not responsible for failures occurring after the inspection.</p>
    <p class="ar">هذا التقرير مخصص للعميل الذي طلب الفحص. يمكن مشاركته، لكن المعد لا يتحمل مسؤولية اعتماد أي طرف ثالث عليه. التقرير معلومة وليس ضماناً.</p>
    <p class="en">This report is prepared for the client who ordered the inspection. It may be shared, but the author accepts no responsibility if a third party relies on it. The report is information, not a warranty.</p>
    <p class="mixed"><strong>إصدار التقرير / Report version:</strong> <span class="ltr-run">v1</span> · <strong>تاريخ النشر / Published:</strong> <span class="ltr-run">2026-11-03</span> · <strong>المعرف / ID:</strong> <span class="ltr-run">TR-2026-0001</span></p>
  </section>
</body>
</html>`;

fs.writeFileSync(out, html, 'utf8');
console.log(`Wrote ${out} (${html.length} chars, ${rows.length} rows, ${photoCells.length} photos)`);

