import fs from 'fs';
import { decodePng } from './figma_fidelity/lib/png.mjs';

const figma = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/figma.png'));
const render = decodePng(fs.readFileSync('docs/ui/figma/fidelity/f2b/tire-condition/figma-text/render.png'));

// Snapshot tile 1: x: 44*2 = 88 to 191*2 = 382, y: 885*2 = 1770 to 941.5*2 = 1883
console.log('Comparing Cold Pressure tile:');
// check icon at (56, 906.6) -> (112, 1813):
console.log('Icon pixel at (114, 1815):');
const idxF = (1815 * figma.width + 114) * 4;
const idxR = (1815 * render.width + 114) * 4;
console.log('Figma:', figma.data[idxF], figma.data[idxF+1], figma.data[idxF+2]);
console.log('Render:', render.data[idxR], render.data[idxR+1], render.data[idxR+2]);

// check text line 1: "Cold Pressure" at (84.7, 896) -> (169, 1792):
const idxF2 = (1792 * figma.width + 172) * 4;
const idxR2 = (1792 * render.width + 172) * 4;
console.log('Text line 1 at (172, 1792):');
console.log('Figma:', figma.data[idxF2], figma.data[idxF2+1], figma.data[idxF2+2]);
console.log('Render:', render.data[idxR2], render.data[idxR2+1], render.data[idxR2+2]);

// check text line 2: "34.5 PSI (Norm)" at (84.7, 913.5) -> (169, 1827):
const idxF3 = (1827 * figma.width + 172) * 4;
const idxR3 = (1827 * render.width + 172) * 4;
console.log('Text line 2 at (172, 1827):');
console.log('Figma:', figma.data[idxF3], figma.data[idxF3+1], figma.data[idxF3+2]);
console.log('Render:', render.data[idxR3], render.data[idxR3+1], render.data[idxR3+2]);
