import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

// Find the biggest cluster of diff pixels in the chassis area:
// Chassis card in 2x: x: 40 to 740, y: 488 to 1064
let minX = 9999, maxX = 0, minY = 9999, maxY = 0;
for (let y = 488; y < 1064; y++) {
  for (let x = 40; x < 740; x++) {
    const idx = (y * figma.width + x) * 4;
    const diff = Math.abs(figma.data[idx] - render.data[idx]) +
                 Math.abs(figma.data[idx+1] - render.data[idx+1]) +
                 Math.abs(figma.data[idx+2] - render.data[idx+2]);
    if (diff > 50) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
}
console.log('Chassis diff bounds in px:', minX, minY, maxX, maxY);
console.log('In logical coords:', minX/2, minY/2, maxX/2, maxY/2);

// Check what figma has at (minX, minY) vs what render has:
const fIdx = (minY * figma.width + minX) * 4;
const rIdx = (minY * render.width + minX) * 4;
console.log('At diff top-left:');
console.log('Figma:', figma.data[fIdx], figma.data[fIdx+1], figma.data[fIdx+2], figma.data[fIdx+3]);
console.log('Render:', render.data[rIdx], render.data[rIdx+1], render.data[rIdx+2], render.data[rIdx+3]);
