import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

function inspectBox(name, lx, ly, lw, lh) {
  console.log(`\n--- ${name} (logical ${lx}, ${ly}, ${lw}x${lh}) ---`);
  // convert to px (DPR 2)
  const px = Math.round(lx * 2);
  const py = Math.round(ly * 2);
  const pw = Math.round(lw * 2);
  const ph = Math.round(lh * 2);

  // find text pixels (dark pixels) in Figma vs Render
  let fDark = 0, rDark = 0;
  let fMinX = 999, fMaxX = 0, fMinY = 999, fMaxY = 0;
  let rMinX = 999, rMaxX = 0, rMinY = 999, rMaxY = 0;

  for (let y = py; y < py + ph; y++) {
    for (let x = px; x < px + pw; x++) {
      const fIdx = (y * figma.width + x) * 4;
      const rIdx = (y * render.width + x) * 4;
      if (figma.data[fIdx] < 120) {
        fDark++;
        if (x < fMinX) fMinX = x;
        if (x > fMaxX) fMaxX = x;
        if (y < fMinY) fMinY = y;
        if (y > fMaxY) fMaxY = y;
      }
      if (render.data[rIdx] < 120) {
        rDark++;
        if (x < rMinX) rMinX = x;
        if (x > rMaxX) rMaxX = x;
        if (y < rMinY) rMinY = y;
        if (y > rMaxY) rMaxY = y;
      }
    }
  }
  console.log('Figma dark pixels:', fDark, 'bounds:', fMinX/2, fMinY/2, fMaxX/2, fMaxY/2);
  console.log('Render dark pixels:', rDark, 'bounds:', rMinX/2, rMinY/2, rMaxX/2, rMaxY/2);
}

inspectBox('RLT Callout', 44, 455, 36, 22);
inspectBox('Active Zone', 250, 490, 105, 32);
inspectBox('7.2 Stepper', 225, 815, 70, 32);
inspectBox('Cold Pressure Tile', 44, 885, 147, 57);
inspectBox('Sidewall Tile', 199, 885, 147, 57);
