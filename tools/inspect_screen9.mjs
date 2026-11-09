import fs from 'fs';

const data = JSON.parse(fs.readFileSync('docs/ui/figma-export/Workshop_admin_figma/screens/09_9._Completed_Report_Viewer/9._Completed_Report_Viewer.json', 'utf8'));

function dump(node, depth = 0) {
  if (!node) return;
  const indent = '  '.repeat(depth);
  const bb = node.absoluteBoundingBox;
  const bbox = bb ? `${(bb.x - 10496).toFixed(1)},${bb.y.toFixed(1)} ${bb.width.toFixed(1)}x${bb.height.toFixed(1)}` : 'no-bbox';
  const text = node.characters ? ` "${node.characters.substring(0, 40).replace(/\n/g, ' ')}"` : '';
  console.log(`${indent}- [${node.id}] ${node.name} (${node.type}) ${bbox}${text}`);
  if (depth < 6 && node.children) {
    for (const c of node.children) {
      dump(c, depth + 1);
    }
  }
}

function findNode(id, node) {
  if (node.id === id) return node;
  for (const c of node.children || []) {
    const f = findNode(id, c);
    if (f) return f;
  }
  return null;
}

const root = data.nodes[0];
console.log('=== Margin 1:2240 ===');
dump(findNode('1:2240', root));
console.log('=== Background+Shadow 1:2269 (depth 2) ===');
const card = findNode('1:2269', root);
console.log('- [1:2269] Card', card.absoluteBoundingBox);
for (const c of card.children || []) {
  dump(c, 1);
}
console.log('=== Footer 1:2454 ===');
dump(findNode('1:2454', root));
