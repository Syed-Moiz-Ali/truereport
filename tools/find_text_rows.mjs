import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

// Search between x: 160 to 360, y: 1770 to 1880
console.log('Finding text rows in Cold Pressure tile (x=170..360, y=1770..1880):');
for (let y = 1770; y < 1880; y += 2) {
  let fDark = 0, rDark = 0;
  for (let x = 160; x < 360; x++) {
    const fIdx = (y * figma.width + x) * 4;
    const rIdx = (y * render.width + x) * 4;
    if (figma.data[fIdx] < 120) fDark++;
    if (render.data[rIdx] < 120) rDark++;
  }
  if (fDark > 0 || rDark > 0) {
    console.log(`y=${y} (logical ${y/2}): Figma dark=${fDark}, Render dark=${rDark}`);
  }
}
