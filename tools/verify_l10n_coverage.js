// Verifies that every l10n.<getter> used by an app resolves in that app's bundle.
const fs = require('fs');
const path = require('path');

const camel = (key) =>
  key
    .split(/[^A-Za-z0-9]+/)
    .filter(Boolean)
    .map((s, i) => (i ? s[0].toUpperCase() + s.slice(1) : s[0].toLowerCase() + s.slice(1)))
    .join('');

const schema = JSON.parse(
  fs.readFileSync('server/src/main/resources/i18n/schema.json', 'utf8'),
);
const byGetter = new Map();
for (const key of Object.keys(schema.keys)) byGetter.set(camel(key), key);

const roots = {
  workshop_admin: [
    'client/apps/workshop_admin_app/lib',
    'client/packages/auth/lib',
    'client/packages/design_system/lib',
  ],
  technician: [
    'client/apps/technician_app/lib',
    'client/packages/auth/lib',
    'client/packages/design_system/lib',
  ],
};

const skip = /\/preview\/|\/test\/|\/tool\/|\.g\.dart$/;

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name).replace(/\\/g, '/');
    if (skip.test(p)) continue;
    if (entry.isDirectory()) walk(p, out);
    else if (entry.name.endsWith('.dart')) out.push(p);
  }
  return out;
}

const usage = /l10n\.([a-zA-Z][A-Za-z0-9]*)/g;

(async () => {
  let failed = 0;
  for (const [client, dirs] of Object.entries(roots)) {
    const response = await fetch(
      `http://127.0.0.1:8080/api/v1/i18n/ui-messages/${client}/bundle?lang=en`,
    );
    const bundle = await response.json();
    const served = new Set(Object.keys(bundle.messages));
    const missing = new Map();
    let used = 0;

    for (const dir of dirs) {
      for (const file of walk(dir)) {
        const text = fs.readFileSync(file, 'utf8');
        for (const match of text.matchAll(usage)) {
          const getter = match[1];
          if (getter === 'dart') continue;
          const line = text.slice(0, match.index).split('\n').length;
          used += 1;
          const key = byGetter.get(getter);
          if (!key) {
            missing.set(`${file}:${line} l10n.${getter} (no schema key)`, true);
          } else if (!served.has(key)) {
            missing.set(`${file}:${line} l10n.${getter} -> '${key}' not in bundle`, true);
          }
        }
      }
    }

    console.log(
      `${client}: ${used} l10n usages, ${missing.size} unresolvable, bundle ${served.size} keys`,
    );
    for (const entry of [...missing.keys()].slice(0, 40)) {
      failed += 1;
      console.log(`   ${entry}`);
    }
  }
  process.exitCode = failed === 0 ? 0 : 1;
})();
