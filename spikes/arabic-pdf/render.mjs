import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
import { createCanvas } from '@napi-rs/canvas';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const htmlPath = path.join(__dirname, 'report.html');
const pdfPath = path.join(__dirname, 'chromium.pdf');
const shotsDir = path.join(__dirname, 'shots');
fs.mkdirSync(shotsDir, { recursive: true });

const started = performance.now();
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.goto('file:///' + htmlPath.replace(/\\/g, '/'), { waitUntil: 'load' });
await page.evaluate(async () => {
  await Promise.all(Array.from(document.images).map(img => img.complete ? Promise.resolve() : new Promise(r => { img.onload = r; img.onerror = r; })));
});
const loadMs = performance.now() - started;
const pdfStart = performance.now();
await page.pdf({
  path: pdfPath,
  format: 'A4',
  printBackground: true,
  preferCSSPageSize: true,
  displayHeaderFooter: true,
  margin: { top: '16mm', bottom: '20mm', left: '13mm', right: '13mm' },
  headerTemplate: '<div></div>',
  footerTemplate: '<div style="font-family:Arial,sans-serif;font-size:8px;color:#555;width:100%;padding:0 13mm;display:flex;justify-content:space-between;"><span>TR-2026-0001 · v1</span><span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span></div>'
});
const pdfMs = performance.now() - pdfStart;
await browser.close();

const pdfjs = await import('pdfjs-dist/legacy/build/pdf.mjs');
const data = new Uint8Array(fs.readFileSync(pdfPath));
const doc = await pdfjs.getDocument({ data, useSystemFonts: true }).promise;
let text = '';
for (let i = 1; i <= doc.numPages; i++) {
  const page = await doc.getPage(i);
  const tc = await page.getTextContent();
  text += `\n===== PAGE ${i} =====\n` + tc.items.map(x => x.str).join(' ');
}
fs.writeFileSync(path.join(__dirname, 'chromium.txt'), text, 'utf8');

// Render selected pages for visual review.
for (const p of [1, 2, 4, 8, 12, 16, 20].filter(n => n <= doc.numPages)) {
  const page = await doc.getPage(p);
  const viewport = page.getViewport({ scale: 2 });
  const canvas = createCanvas(viewport.width, viewport.height);
  const ctx = canvas.getContext('2d');
  await page.render({ canvasContext: ctx, viewport }).promise;
  fs.writeFileSync(path.join(shotsDir, `chromium-page-${String(p).padStart(2, '0')}.png`), canvas.toBuffer('image/png'));
}

const stat = fs.statSync(pdfPath);
console.log(JSON.stringify({
  engine: 'Chromium via Playwright (Node)',
  loadMs: Math.round(loadMs),
  pdfMs: Math.round(pdfMs),
  totalMs: Math.round(loadMs + pdfMs),
  pages: doc.numPages,
  bytes: stat.size,
  rssMb: Math.round(process.memoryUsage().rss / 1024 / 1024),
  textChars: text.length
}, null, 2));
