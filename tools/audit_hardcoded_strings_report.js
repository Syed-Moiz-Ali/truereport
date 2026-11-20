const fs = require('fs');
const rows = JSON.parse(fs.readFileSync('shots/hardcoded_strings.json', 'utf8'));

const noiseFile = /offline_store|offline_database|fonts\.dart|technician_intl\.dart|auth_repository|\.g\.dart/;
const noiseText = /^(SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|PRAGMA|BEGIN|COMMIT|DROP|WITH )/i;

const real = rows.filter(
  (row) => !noiseFile.test(row.file) && !noiseText.test(row.text),
);

const byFile = new Map();
for (const row of real) {
  if (!byFile.has(row.file)) byFile.set(row.file, []);
  byFile.get(row.file).push(row);
}

console.log(`filtered candidates: ${real.length} in ${byFile.size} files\n`);
for (const [file, hits] of [...byFile.entries()].sort((a, b) => b[1].length - a[1].length)) {
  console.log(`${String(hits.length).padStart(3)}  ${file.replace(/^client\//, '')}`);
  for (const hit of hits.slice(0, 6)) {
    console.log(`      ${hit.line}: ${hit.text.slice(0, 90)}`);
  }
}
