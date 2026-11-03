import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createCanvas } from '@napi-rs/canvas';
const __dirname=path.dirname(fileURLToPath(import.meta.url));
const pdfjs=await import('pdfjs-dist/legacy/build/pdf.mjs');
const data=new Uint8Array(fs.readFileSync(path.join(__dirname,'chromium.pdf')));
const doc=await pdfjs.getDocument({data,useSystemFonts:true}).promise;
for(const p of [17,18]){ const page=await doc.getPage(p); const v=page.getViewport({scale:2}); const c=createCanvas(v.width,v.height); await page.render({canvasContext:c.getContext('2d'),viewport:v}).promise; fs.writeFileSync(path.join(__dirname,'shots',`chromium-page-${String(p).padStart(2,'0')}.png`),c.toBuffer('image/png')); }
console.log('done',doc.numPages);
