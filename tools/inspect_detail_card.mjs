import fs from 'fs';

const json = JSON.parse(fs.readFileSync('docs/ui/figma-export/technision_figma/screens/13_12._Tire_Condition_Capture/12._Tire_Condition_Capture.json', 'utf8'));
const root = json.nodes['0'];

function findById(node, id) {
  if (node.id === id) return node;
  for (const c of node.children || []) {
    const res = findById(c, id);
    if (res) return res;
  }
  return null;
}

const card = findById(root, '1:8536');
for (const c of card.children || []) {
  console.log('Child:', c.name, c.id, c.absoluteBoundingBox, 'padding:', c.paddingLeft, c.paddingTop, c.itemSpacing);
}
