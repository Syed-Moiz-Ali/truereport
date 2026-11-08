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

const ids = ['1:8510', '1:8511', '1:8514', '1:8518', '1:8520', '1:8523', '1:8526', '1:8528', '1:8532', '1:8536'];
for (const id of ids) {
  const n = findById(root, id);
  if (n) {
    console.log(id, n.name, n.absoluteBoundingBox, 'fills:', JSON.stringify(n.fills), 'strokes:', JSON.stringify(n.strokes), 'effects:', JSON.stringify(n.effects), 'radius:', n.cornerRadius);
  }
}
