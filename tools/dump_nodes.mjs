import fs from 'fs';

const json = JSON.parse(fs.readFileSync('docs/ui/figma-export/technision_figma/screens/13_12._Tire_Condition_Capture/12._Tire_Condition_Capture.json', 'utf8'));
const root = json.nodes['0'];

function walk(node, depth = 0) {
  const indent = '  '.repeat(depth);
  const bbox = node.absoluteBoundingBox ? 
    `[${Math.round((node.absoluteBoundingBox.x - root.absoluteBoundingBox.x) * 10) / 10}, ${Math.round((node.absoluteBoundingBox.y - root.absoluteBoundingBox.y) * 10) / 10}, ${Math.round(node.absoluteBoundingBox.width * 10) / 10}, ${Math.round(node.absoluteBoundingBox.height * 10) / 10}]` : '';
  const text = node.characters ? ` "${node.characters.replace(/\n/g, '\\n')}"` : '';
  const fill = node.fills && node.fills[0] && node.fills[0].color ? 
    ` fill:rgb(${Math.round(node.fills[0].color.r*255)},${Math.round(node.fills[0].color.g*255)},${Math.round(node.fills[0].color.b*255)})` : '';
  console.log(`${indent}${node.name} (${node.id}) ${node.type} ${bbox}${text}${fill}`);
  if (node.children) {
    for (const c of node.children) {
      walk(c, depth + 1);
    }
  }
}

walk(root);
