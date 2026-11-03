import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createCanvas } from '@napi-rs/canvas';
const __dirname=path.dirname(fileURLToPath(import.meta.url));
const pdfPath=path.join(__dirname, process.argv[2]);
const label=process.argv[3];
const pdfjs=await import('pdfjs-dist/legacy/build/pdf.mjs');
const data=new Uint8Array(fs.readFileSync(pdfPath));
const doc=await pdfjs.getDocument({data,useSystemFonts:true}).promise;
let text='';
for(let i=1;i<=doc.numPages;i++){const page=await doc.getPage(i);const tc=await page.getTextContent();text+=`\n===== PAGE ${i} =====\n`+tc.items.map(x=>x.str).join(' ');}
fs.writeFileSync(path.join(__dirname, label+'.txt'),text,'utf8');
const shots=path.join(__dirname,'shots'); fs.mkdirSync(shots,{recursive:true});
for(const p of [1,2,4,8,12,16,17,18].filter(n=>n<=doc.numPages)){const page=await doc.getPage(p);const v=page.getViewport({scale:2});const c=createCanvas(v.width,v.height);await page.render({canvasContext:c.getContext('2d'),viewport:v}).promise;fs.writeFileSync(path.join(shots,`${label}-page-${String(p).padStart(2,'0')}.png`),c.toBuffer('image/png'));}
console.log(JSON.stringify({pages:doc.numPages,bytes:fs.statSync(pdfPath).size,textChars:text.length},null,2));