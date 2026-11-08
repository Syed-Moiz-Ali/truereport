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

console.log('1:8489 (Progress bar container):', JSON.stringify({ fills: findById(root, '1:8489').fills, strokes: findById(root, '1:8489').strokes }));
console.log('1:8490 (Progress bar fill):', JSON.stringify({ fills: findById(root, '1:8490').fills }));
console.log('1:8547 (Verified pill):', JSON.stringify({ fills: findById(root, '1:8547').fills, children: findById(root, '1:8547').children }));
console.log('1:8498 (Ambient Grid):', JSON.stringify(findById(root, '1:8498')));
