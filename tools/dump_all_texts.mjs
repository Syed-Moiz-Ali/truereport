import fs from 'fs';

const json = JSON.parse(fs.readFileSync('docs/ui/figma-export/technision_figma/screens/13_12._Tire_Condition_Capture/12._Tire_Condition_Capture.json', 'utf8'));
const root = json.nodes['0'];

function collect(node) {
  if (node.text) {
    const t = node.text;
    const s = t.fontName || {};
    const hex = (node.fills && node.fills[0] && node.fills[0].hex) || '';
    const bbox = node.absoluteBoundingBox ? 
      `[${Math.round((node.absoluteBoundingBox.x - root.absoluteBoundingBox.x) * 10) / 10}, ${Math.round((node.absoluteBoundingBox.y - root.absoluteBoundingBox.y) * 10) / 10}, ${Math.round(node.absoluteBoundingBox.width * 10) / 10}, ${Math.round(node.absoluteBoundingBox.height * 10) / 10}]` : '';
    const lh = t.lineHeight ? t.lineHeight.value : '';
    const ls = t.letterSpacing ? t.letterSpacing.value : '';
    console.log(`${bbox} "${t.characters.replace(/\n/g, '\\n')}" | size:${t.fontSize} wght:${t.fontWeight} lh:${lh} ls:${Math.round(ls*100)/100} color:${hex}`);
  }
  for (const c of node.children || []) collect(c);
}

collect(root);
