#!/usr/bin/env node
/*
 * Gate: no local status/enum -> label or tone maps in client code.
 *
 * Labels and tones belong to /api/v1/reference/*. A `case 'APPROVED':` that
 * returns fmt/l10n copy, a StatusTone/Color, or a hand-written label is a
 * failure. Code -> behaviour, icon or counts-field mappings are allowed by
 * adding `// gate-allow: behaviour` on the case or the line above it.
 *
 * Run from the repo root:
 *   node tools/gate_no_status_switch.js
 */
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const scanRoots = [
  'client/apps/platform_admin_app/lib',
  'client/apps/workshop_admin_app/lib',
  'client/apps/technician_app/lib',
  'client/packages/auth/lib',
  'client/packages/design_system/lib',
  'client/packages/reference_data/lib',
  'client/packages/domain/lib',
  'client/packages/core/lib',
  'client/packages/api_client/lib',
  'client/packages/offline_sync/lib',
];

const skipFile = /\/preview\/|\/test\/|\/tool\/|\/generated\/|\/l10n\/gen\/|\.g\.dart$/;
// The reference resolvers are the one legal place for code -> served label/tone.
const resolverFile =
  /(^|\/)(reference_status_lookup|reference_ui|reference_status|reference_widgets)\.dart$/;
// Error/failure code -> message copy is behaviour, not lifecycle status.
const errorCopyFile = /(^|\/)([^/]*(?:error|failure|failures)[^/]*)\.dart$/i;
// The technician item page is the item-contract picker surface.
const itemPickerFile = /technician_dynamic_item_page\.dart$/;

const CASE =
  /^\s*case\s+'([A-Z][A-Z0-9_]*)'(?:\s*\|\|\s*'([^']*)')?\s*:\s*(.*)$/;
const SWITCH_EXPR =
  /^\s*'([A-Z][A-Z0-9_]*)'(?:\s*\|\|\s*'([^']*)')?\s*=>\s*(.*)$/;
const LABEL =
  /(?:strings|uiStrings|remoteEnglish|l10n)\s*\.|AppLocalizations|StatusTone\.|WorkshopStatusTone\.|_PillTone\.|\bColor\s*\(|\bColors\.|\bFx\.|statusColors|\.forTone\s*\(|\bws\./;
const RETURN_STRING = /(?:return|=>)\s*(['"])([^'"]*)\1/;
const LABEL_STRING = /[A-Z]|\s/;

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    const rel = path.relative(repoRoot, full).replace(/\\/g, '/');
    if (skipFile.test(rel)) continue;
    if (entry.isDirectory()) walk(full, out);
    else if (entry.name.endsWith('.dart')) out.push(rel);
  }
  return out;
}

function isAllowed(lines, index) {
  for (let i = Math.max(0, index - 2); i <= index; i += 1) {
    if (/gate-allow:\s*behaviour/.test(lines[i] || '')) return true;
  }
  return false;
}

function bodyFor(lines, index, rest) {
  const body = [rest];
  for (let i = index + 1; i < lines.length && i <= index + 12; i += 1) {
    const line = lines[i];
    if (/^\s*(case\s+|default\s*:|})/.test(line)) break;
    body.push(line);
  }
  return body.join(' ');
}

const hits = [];
for (const root of scanRoots) {
  for (const rel of walk(path.join(repoRoot, root))) {
    if (resolverFile.test(rel)) continue;
    if (errorCopyFile.test(rel)) continue;
    if (itemPickerFile.test(rel)) continue;

    const lines = fs.readFileSync(path.join(repoRoot, rel), 'utf8').split(/\r?\n/);
    for (let i = 0; i < lines.length; i += 1) {
      const line = lines[i];
      const match = CASE.exec(line) || SWITCH_EXPR.exec(line);
      if (!match) continue;
      if (isAllowed(lines, i)) continue;

      const code = match[1];
      const rest = match[3] || '';
      const body = CASE.test(line) ? bodyFor(lines, i, rest) : rest;
      if (LABEL.test(body)) {
        hits.push({ file: rel, line: i + 1, code, kind: 'label/tone' });
        continue;
      }
      const stringReturn = RETURN_STRING.exec(body);
      if (stringReturn && LABEL_STRING.test(stringReturn[2])) {
        hits.push({ file: rel, line: i + 1, code, kind: 'string' });
      }
    }

    // status -> label/tone maps written as maps rather than switches.
    for (let i = 0; i < lines.length; i += 1) {
      const line = lines[i];
      if (!/[<{]String\s*,\s*(?:String|StatusTone|WorkshopStatusTone|Color)/.test(line)) {
        continue;
      }
      for (let j = i; j < lines.length && j <= i + 40; j += 1) {
        if (/}\s*;?\s*$/.test(lines[j]) && j > i) break;
        const entry = /^\s*'([A-Z][A-Z0-9_]*)'\s*:\s*(.+)$/.exec(lines[j]);
        if (!entry) continue;
        if (isAllowed(lines, j)) continue;
        if (LABEL.test(entry[2])) {
          hits.push({
            file: rel,
            line: j + 1,
            code: entry[1],
            kind: 'map',
          });
        }
      }
    }
  }
}

if (hits.length === 0) {
  process.exitCode = 0;
} else {
  for (const hit of hits) {
    console.log(
      `${hit.file}:${hit.line}  case '${hit.code}' -> ${hit.kind} (resolve through /reference/statuses|enums)`,
    );
  }
  console.log('');
  console.log(
    `local status/enum label-tone maps: ${hits.length}. Use the reference taxonomy; for behaviour add // gate-allow: behaviour.`,
  );
  process.exitCode = 1;
}
