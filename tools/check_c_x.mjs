import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

let fX = [], rX = [];
for (let x = 160; x < 200; x++) {
  const fIdx = (1810 * figma.width + x) * 4;
  const rIdx = (1810 * render.width + x) * 4;
  if (figma.data[fIdx] < 120) fX.push(x);
  if (render.data[rIdx] < 120) rX.push(x);
}
console.log('Figma first X:', fX[0], 'logical:', fX[0]/2);
console.log('Render first X:', rX[0], 'logical:', rX[0]/2);
