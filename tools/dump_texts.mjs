import fs from 'fs';

const json = JSON.parse(fs.readFileSync('docs/ui/figma-export/technision_figma/screens/13_12._Tire_Condition_Capture/12._Tire_Condition_Capture.json', 'utf8'));
const root = json.nodes['0'];

function collectTexts(node) {
  if (node.text) {
    const s = node.text.style || node.style || {};
    const bbox = node.absoluteBoundingBox ? 
      `[${Math.round((node.absoluteBoundingBox.x - root.absoluteBoundingBox.x) * 10) / 10}, ${Math.round((node.absoluteBoundingBox.y - root.absoluteBoundingBox.y) * 10) / 10}, ${Math.round(node.absoluteBoundingBox.width * 10) / 10}, ${Math.round(node.absoluteBoundingBox.height * 10) / 10}]` : '';
    const content = typeof node.text === 'string' ? node.text : (node.text.raw || node.text.characters || JSON.stringify(node.text));
    console.log(`${bbox} ${content} | style:`, JSON.stringify(s));
  }
  if (node.children) {
    for (const c of node.children) {
      collectTexts(c);
    }
  }
}

collectTexts(root);
