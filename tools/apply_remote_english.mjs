// Post-process `flutter gen-l10n` output so every simple English getter reads
// the backend-provided English bundle (with the ARB literal as fallback).
// Run: node tools/apply_remote_english.mjs
import fs from 'node:fs';

const file = 'client/packages/l10n/lib/l10n/gen/app_localizations_en.dart';
let source = fs.readFileSync(file, 'utf8').replace(/\r/g, '');
if (!source.includes("import '../../src/remote_english.dart';")) {
  source = source.replace(
    "import 'app_localizations.dart';",
    "import 'app_localizations.dart';\nimport '../../src/remote_english.dart';",
  );
}

const lines = source.split('\n');
const out = [];
let count = 0;
for (let i = 0; i < lines.length; i += 1) {
  const single = lines[i].match(/^  String get (\w+) => (.*);$/);
  if (single) {
    if (single[2].startsWith('_r(')) {
      out.push(lines[i]);
      continue;
    }
    count += 1;
    out.push(`  String get ${single[1]} => _r('${single[1]}', ${single[2]});`);
    continue;
  }
  const multi = lines[i].match(/^  String get (\w+) =>$/);
  if (multi) {
    const body = [];
    i += 1;
    while (i < lines.length) {
      body.push(lines[i]);
      if (lines[i].trimEnd().endsWith(';')) break;
      i += 1;
    }
    const last = body.pop().replace(/;\s*$/, '');
    body.push(last);
    count += 1;
    out.push(`  String get ${multi[1]} => _r('${multi[1]}',`);
    out.push(body.join('\n'));
    out.push('  );');
    continue;
  }
  out.push(lines[i]);
}

let result = out.join('\n');
if (!result.includes('String _r(String key, String fallback)')) {
  const idx = result.lastIndexOf('}');
  result = result.slice(0, idx)
    + "\n  String _r(String key, String fallback) => remoteEnglish(key, fallback);\n"
    + result.slice(idx);
}
// Parameterized methods: wrap direct returns and pluralLogic `_temp0` returns.
const methodLines = result.split('\n');
let methods = 0;
for (let i = 0; i < methodLines.length; i += 1) {
  const header = methodLines[i].match(/^  String (\w+)\(([^)]*)\) \{$/);
  if (!header || header[1] === '_r') continue;
  const key = header[1];
  const params = header[2]
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part) => part.split(/\s+/).pop());
  const map = params.map((name) => `'${name}': ${name}`).join(', ');
  let j = i + 1;
  while (j < methodLines.length && methodLines[j] !== '  }') {
    const line = methodLines[j];
    if (line.trim().startsWith('return ') && !line.includes('remoteFormat(')) {
      if (line.trim() === "return '$_temp0';") {
        methodLines[j] = `    return remoteFormat('${key}', '\$_temp0', {${map}});`;
        methods += 1;
        break;
      }
      const simple = line.match(/^(\s*)return (.*);$/);
      if (simple) {
        methodLines[j] =
          `${simple[1]}return remoteFormat('${key}', ${simple[2]}, {${map}});`;
        methods += 1;
        break;
      }
    }
    j += 1;
  }
}
result = methodLines.join('\n');
fs.writeFileSync(file, result, 'utf8');
console.log(`remote-English getters: ${count}, plural wrappers: ${methods}`);
