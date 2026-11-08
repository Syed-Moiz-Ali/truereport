import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

// Tile at px: 192, 1792, size: 64x64
console.log('Inspecting tile (192, 1792):');
let diffCount = 0;
for (let y = 1792; y < 1792 + 64; y++) {
  for (let x = 192; x < 192 + 64; x++) {
    const fIdx = (y * figma.width + x) * 4;
    const rIdx = (y * render.width + x) * 4;
    const diff = Math.abs(figma.data[fIdx] - render.data[rIdx]) +
                 Math.abs(figma.data[fIdx+1] - render.data[rIdx+1]) +
                 Math.abs(figma.data[fIdx+2] - render.data[rIdx+2]);
    if (diff > 30) diffCount++;
  }
}
console.log('Diff pixels in tile (192, 1792):', diffCount, 'out of', 64*64);

// Where are they in the tile?
for (let y = 1792; y < 1792 + 64; y += 4) {
  let line = '';
  for (let x = 192; x < 192 + 64; x += 2) {
    const fIdx = (y * figma.width + x) * 4;
    const rIdx = (y * render.width + x) * 4;
    const diff = Math.abs(figma.data[fIdx] - render.data[rIdx]) +
                 Math.abs(figma.data[fIdx+1] - render.data[rIdx+1]) +
                 Math.abs(figma.data[fIdx+2] - render.data[rIdx+2]);
    line += diff > 30 ? '#' : '.';
  }
  console.log(`y=${y} (L ${y/2}): ${line}`);
}
