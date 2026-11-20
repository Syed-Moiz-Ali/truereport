// Verifies that every typed key constant used by Platform Admin is served in its bundle.
const fs = require('fs');
const path = require('path');

function parseKeys(file, constructor) {
  const text = fs.readFileSync(file, 'utf8');
  const re = new RegExp(
    `static const (\\w+) = UiMessageKey\\.${constructor}\\(\\s*'([^']+)',?\\s*\\)`,
    'g',
  );
  const map = new Map();
  for (const match of text.matchAll(re)) map.set(match[1], match[2]);
  return map;
}

const platform = parseKeys(
  'client/packages/l10n/lib/src/ui_messages/keys/platform_admin_keys.dart',
  'platformAdmin',
);
const common = parseKeys(
  'client/packages/l10n/lib/src/ui_messages/keys/common_keys.dart',
  'common',
);

const roots = ['client/apps/platform_admin_app/lib'];
const skip = /\/preview\/|\/test\/|\/tool\/|\/dashboard_directions_preview/;

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name).replace(/\\/g, '/');
    if (skip.test(p)) continue;
    if (entry.isDirectory()) walk(p, out);
    else if (entry.name.endsWith('.dart')) out.push(p);
  }
  return out;
}

(async () => {
  const response = await fetch(
    'http://127.0.0.1:8080/api/v1/i18n/ui-messages/platform_admin/bundle?lang=en&namespaces=platform_admin,common',
  );
  const bundle = await response.json();
  const served = new Set(Object.keys(bundle.messages));

  const problems = new Map();
  let used = 0;
  for (const dir of roots) {
    for (const file of walk(dir)) {
      const text = fs.readFileSync(file, 'utf8');
      for (const match of text.matchAll(/(PlatformAdminKeys|CommonKeys)\.(\w+)/g)) {
        const source = match[1] === 'PlatformAdminKeys' ? platform : common;
        const key = source.get(match[2]);
        const line = text.slice(0, match.index).split('\n').length;
        used += 1;
        if (!key) problems.set(`${file}:${line} ${match[0]} (constant missing)`, true);
        else if (!served.has(key)) problems.set(`${file}:${line} ${match[0]} -> '${key}' not served`, true);
      }
    }
  }

  console.log(
    `platform_admin: ${used} constant usages (${platform.size} platform keys, ${common.size} common keys), ${problems.size} problems, bundle ${served.size}`,
  );
  for (const problem of [...problems.keys()].slice(0, 40)) console.log(`   ${problem}`);
  process.exitCode = problems.size === 0 ? 0 : 1;
})();
