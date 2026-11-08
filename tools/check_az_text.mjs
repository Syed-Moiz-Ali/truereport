import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

// Search "Active Zone" text: x: 280*2 = 560 to 345*2 = 690, y: 490*2 = 980 to 515*2 = 1030
let fDark = [], rDark = [];
for (let y = 980; y < 1030; y++) {
  for (let x = 560; x < 690; x++) {
    const fIdx = (y * figma.width + x) * 4;
    const rIdx = (y * render.width + x) * 4;
    // text color is #1A1B1F (dark)
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

console.log('Figma text bounds:', fMinX, fMinY, fMaxX, fMaxY);
console.log('Render text bounds:', rMinX, rMinY, rMaxX, rMaxY);
