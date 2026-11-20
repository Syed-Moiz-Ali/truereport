const fs = require('fs');

const tsv = fs.readFileSync('shots/option_keys.tsv', 'utf8').split(/\r?\n/).filter(Boolean);
const catalogPath = 'server/src/main/resources/i18n/common/en.json';
const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));

let added = 0;
let kept = 0;
const malformed = [];
const pattern = /^[a-z][A-Za-z0-9]*(\.[a-z][A-Za-z0-9]*)+$/;

for (const line of tsv) {
  const [key, label] = line.split('\t');
  if (!key || !label) continue;
  if (!pattern.test(key)) {
    malformed.push(key);
    continue;
  }
  if (Object.prototype.hasOwnProperty.call(catalog, key)) {
    kept += 1;
    continue;
  }
  catalog[key] = label;
  added += 1;
}

const sorted = Object.fromEntries(Object.keys(catalog).sort().map((key) => [key, catalog[key]]));
fs.writeFileSync(catalogPath, JSON.stringify(sorted, null, 2) + '\n', 'utf8');

console.log('option keys:', tsv.length, 'added:', added, 'already present:', kept, 'malformed:', malformed.length);
console.log('common/en.json total keys:', Object.keys(sorted).length);
if (malformed.length) console.log(malformed.slice(0, 5).join('\n'));
