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

const b1 = findById(root, '1:8554');
console.log('Button 1 (As New):', JSON.stringify({ fills: b1.fills, strokes: b1.strokes, radius: b1.cornerRadius, effects: b1.effects }));

const b2 = findById(root, '1:8563');
console.log('Button 2 (Part Worn):', JSON.stringify({ fills: b2.fills, strokes: b2.strokes, radius: b2.cornerRadius, effects: b2.effects }));
