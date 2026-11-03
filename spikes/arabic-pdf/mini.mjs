import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
const __dirname=path.dirname(fileURLToPath(import.meta.url));
const html='<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><body><p style="font-family:Arial">مرحبا بالعالم هذا نص عربي للاختبار</p><p style="font-family:NotoNaskh">مرحبا بالعالم هذا نص عربي للاختبار</p></body></html>';
fs.writeFileSync(path.join(__dirname,'tiny.html'),html);
const b=await chromium.launch(); const p=await b.newPage(); await p.goto('file:///'+path.join(__dirname,'tiny.html').replace(/\\/g,'/')); await p.pdf({path:path.join(__dirname,'tiny.pdf'),format:'A4'}); await b.close();
const pdfjs=await import('pdfjs-dist/legacy/build/pdf.mjs'); const data=new Uint8Array(fs.readFileSync(path.join(__dirname,'tiny.pdf'))); const doc=await pdfjs.getDocument({data,useSystemFonts:true}).promise; const page=await doc.getPage(1); const tc=await page.getTextContent(); console.log(tc.items.map(x=>x.str).join(' | '));