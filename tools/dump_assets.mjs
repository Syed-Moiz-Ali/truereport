import fs from 'fs';

const json = JSON.parse(fs.readFileSync('docs/ui/figma-export/technision_figma/screens/13_12._Tire_Condition_Capture/12._Tire_Condition_Capture.json', 'utf8'));
const assets = json.assetIndex;
console.log('Asset mappings:');
for (const [key, val] of Object.entries(assets)) {
  console.log(key, val);
}
