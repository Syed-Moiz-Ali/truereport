import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

// Active Zone pill: x: 254.5*2 = 509 to 354*2 = 708, y: 491.5*2 = 983 to 520*2 = 1040
console.log('Comparing Active Zone pill:');
for (let y = 983; y < 1040; y += 4) {
  let fLine = '', rLine = '';
  for (let x = 509; x < 708; x += 8) {
    const fIdx = (y * figma.width + x) * 4;
    const rIdx = (y * render.width + x) * 4;
    fLine += figma.data[fIdx] < 128 ? '#' : (figma.data[fIdx] < 240 ? '.' : ' ');
    rLine += render.data[rIdx] < 128 ? '#' : (render.data[rIdx] < 240 ? '.' : ' ');
  }
  console.log(fLine, ' | ', rLine);
}
