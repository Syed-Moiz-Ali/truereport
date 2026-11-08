import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

// Part Worn button: x: 199*2 = 398 to 346*2 = 692, y: 664*2 = 1328 to 757*2 = 1514
let fDark = [], rDark = [];
for (let y = 1328; y < 1514; y++) {
  for (let x = 398; x < 692; x++) {
    const fIdx = (y * figma.width + x) * 4;
    const rIdx = (y * render.width + x) * 4;
    if (figma.data[fIdx] < 60 && figma.data[fIdx+1] < 60) fDark.push({x: x/2, y: y/2});
    if (render.data[rIdx] < 60 && render.data[rIdx+1] < 60) rDark.push({x: x/2, y: y/2});
  }
}

const fMinX = Math.min(...fDark.map(p => p.x));
const fMaxX = Math.max(...fDark.map(p => p.x));
const fMinY = Math.min(...fDark.map(p => p.y));
const fMaxY = Math.max(...fDark.map(p => p.y));

const rMinX = Math.min(...rDark.map(p => p.x));
const rMaxX = Math.max(...rDark.map(p => p.x));
const rMinY = Math.min(...rDark.map(p => p.y));
const rMaxY = Math.max(...rDark.map(p => p.y));

console.log('Part Worn Figma text bounds:', fMinX, fMinY, fMaxX, fMaxY);
console.log('Part Worn Render text bounds:', rMinX, rMinY, rMaxX, rMaxY);
