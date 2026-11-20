const fs = require('fs');

const source = fs.readFileSync(
  'server/src/main/java/com/truereport/reference/ReferenceTaxonomy.java',
  'utf8',
);
const pattern = /"([a-z][A-Za-z0-9]*(?:\.[A-Za-z0-9]+)+)"/g;
const keys = [...new Set([...source.matchAll(pattern)].map((m) => m[1]))];

const read = (p) =>
  JSON.parse(fs.readFileSync(`server/src/main/resources/i18n/${p}`, 'utf8'));
const common = read('common/en.json');
const workshop = read('workshop_admin/en.json');
const technician = read('technician/en.json');
const platform = read('platform_admin/en.json');
const all = new Set([
  ...Object.keys(common),
  ...Object.keys(workshop),
  ...Object.keys(technician),
  ...Object.keys(platform),
]);

const missing = keys.filter((key) => !all.has(key));
console.log(`dotted label keys used: ${keys.length}`);
console.log(`missing everywhere: ${missing.length}`);
for (const key of missing) console.log(`  ${key}`);
