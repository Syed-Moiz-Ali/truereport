const fs = require('fs');
const path = require('path');

const roots = [
  'client/apps/platform_admin_app/lib',
  'client/apps/workshop_admin_app/lib',
  'client/apps/technician_app/lib',
  'client/packages/auth/lib',
  'client/packages/design_system/lib',
];

const skip = /\/preview\/|\/test\/|\/tool\/|\.g\.dart$/;
const nonUi = /^(https?:|\/[a-z]|[a-z_]+(\.[a-z_]+)+$|[a-z][A-Za-z0-9]*$|[0-9.,:%\-\/+ ]*$|#[0-9a-fA-F]{3,8}$)/;

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name).replace(/\\/g, '/');
    if (skip.test(p)) continue;
    if (entry.isDirectory()) walk(p, out);
    else if (entry.name.endsWith('.dart')) out.push(p);
  }
  return out;
}

const rows = [];
const literal = /(['"])((?:[^'"\\]|\\.)*)\1/g;

for (const root of roots) {
  for (const file of walk(root)) {
    const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
    lines.forEach((line, index) => {
      if (/l10n\.|AppLocalizations|PlatformAdminKeys|CommonKeys|UiMessageKey/.test(line)) return;
      if (/debugLabel|import |export |part of |assert\(|^\/\/|^\s*\/\//.test(line)) return;
      literal.lastIndex = 0;
      let match;
      while ((match = literal.exec(line))) {
        const text = match[2];
        if (text.length < 4) continue;
        if (!/[A-Za-z]/.test(text)) continue;
        if (!/ /.test(text)) continue;
        if (nonUi.test(text)) continue;
        if (/(package:|dart:|assets\/|\.png|\.json|\.dart)$/.test(text)) continue;
        rows.push({ file: file.replace(/\\/g, '/'), line: index + 1, text });
      }
    });
  }
}

const byFile = new Map();
for (const row of rows) {
  if (!byFile.has(row.file)) byFile.set(row.file, []);
  byFile.get(row.file).push(row);
}

console.log(`candidate strings: ${rows.length} in ${byFile.size} files`);
[...byFile.entries()]
  .sort((a, b) => b[1].length - a[1].length)
  .slice(0, 25)
  .forEach(([file, hits]) => {
    console.log(String(hits.length).padStart(4), file.replace(/^client\//, ''));
  });

fs.writeFileSync('shots/hardcoded_strings.json', JSON.stringify(rows, null, 2), 'utf8');
console.log('written shots/hardcoded_strings.json');
