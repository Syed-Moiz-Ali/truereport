#!/usr/bin/env node
/**
 * Renders Markdown table fragments from tokens-aggregate.json.
 * Read-only helper; does not write the deliverable itself.
 *
 * Usage:
 *   node docs/ui/figma/tools/render-tables.js --in <aggregate.json> --out <fragment.md>
 */
'use strict';

const fs = require('fs');
const path = require('path');

const args = { in: path.join(__dirname, 'tokens-aggregate.json'), out: null };
for (let i = 2; i < process.argv.length; i += 1) {
  if (process.argv[i] === '--in') args.in = path.resolve(process.argv[++i]);
  else if (process.argv[i] === '--out') args.out = path.resolve(process.argv[++i]);
}
const j = JSON.parse(fs.readFileSync(args.in, 'utf8'));
const APP = { tech: 'Tech', workshop: 'Workshop', platform: 'Platform', public: 'Public' };
const apps = (x) => x.apps.map((a) => APP[a] || a).join(', ');
const roles = (r) => Object.entries(r || {}).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(' · ');
const lines = [];
const h = (s) => lines.push('', s);
const table = (head, rows) => {
  lines.push(`| ${head.join(' | ')} |`);
  lines.push(`| ${head.map(() => '---').join(' | ')} |`);
  for (const row of rows) lines.push(`| ${row.join(' | ')} |`);
};

const realColors = j.colors.all.filter((x) => !x.key.startsWith('GRADIENT:'));
const shared = realColors.filter((x) => x.appCount >= 2);
const appOnly = realColors.filter((x) => x.appCount === 1);

h('### COLOURS — SHARED (>=2 apps)');
table(['Hex', 'Fill count', 'Apps', 'Role split', 'Screens'], shared.map((x) => [x.key, x.count, apps(x), roles(x.roles), x.screenCount]));

h('### COLOURS — APP-SPECIFIC');
table(['App', 'Hex', 'Fill count', 'Role split', 'Screens'], appOnly.map((x) => [apps(x), x.key, x.count, roles(x.roles), x.screenCount]));

h('### FONTS');
table(['Family · style · weight', 'Count', 'Apps'], j.typography.fonts.map((x) => [x.key, x.count, apps(x)]));

h('### FONT SIZES');
table(['px', 'Count', 'Apps'], j.typography.sizes.map((x) => [x.key, x.count, apps(x)]));

h('### LINE HEIGHTS');
table(['px', 'Count', 'Apps'], j.typography.lineHeights.map((x) => [x.key, x.count, apps(x)]));

h('### TRACKING');
table(['px', 'Count', 'Apps'], j.typography.letterSpacings.map((x) => [x.key, x.count, apps(x)]));

h('### TYPE COMBOS — TOP 30');
table(['Family weight size/line-height ls', 'Count', 'Apps'], j.typography.combos.slice(0, 30).map((x) => [x.key, x.count, apps(x)]));

h('### RADII');
table(['px', 'Count', 'Apps', 'Screens'], j.radii.values.map((x) => [x.key, x.count, apps(x), x.screenCount]));

h('### CORNER OVERRIDES');
table(['Corners', 'Count', 'Apps'], j.radii.cornerOverrides.map((x) => [x.key, x.count, apps(x)]));

h('### ITEM SPACING — TOP 25');
table(['px', 'Count', 'Apps', 'Role split'], j.spacing.itemSpacing.slice(0, 25).map((x) => [x.key, x.count, apps(x), roles(x.roles)]));

h('### PADDING — TOP 25');
table(['px', 'Count', 'Apps', 'Role split'], j.spacing.padding.slice(0, 25).map((x) => [x.key, x.count, apps(x), roles(x.roles)]));

h('### GRID GAPS');
table(['px', 'Count', 'Apps'], j.spacing.gridGaps.map((x) => [x.key, x.count, apps(x)]));

h('### EFFECTS — TOP 25 EXACT');
table(['Type / offset / blur / spread / colour', 'Count', 'Apps'], j.effects.values.slice(0, 25).map((x) => [x.key, x.count, apps(x)]));

h('### EFFECT GEOMETRY — TOP 20');
table(['Type / offset / blur / spread', 'Count', 'Apps'], j.effects.geometry.slice(0, 20).map((x) => [x.key, x.count, apps(x)]));

h('### STROKE WEIGHT');
table(['Weight / align', 'Count', 'Apps'], j.strokes.map((x) => [x.key, x.count, apps(x)]));

h('### STROKE COLOURS');
table(['Hex', 'Count', 'Apps'], j.colors.stroke.map((x) => [x.key, x.count, apps(x)]));

h('### GRADIENT STOPS');
table(['Hex', 'Count', 'Apps'], j.colors.gradientStops.map((x) => [x.key, x.count, apps(x)]));

h('### ASSET ROLES');
table(['Role', 'Count', 'Apps', 'Screens'], j.assets.roles.map((x) => [x.key, x.count, apps(x), x.screenCount]));

h('### NODE TYPES');
table(['Type', 'Count'], Object.entries(j.nodeTypes));

h('### NAME PATTERNS');
table(['Pattern', 'Nodes', 'Apps', 'Types'], Object.entries(j.namePatterns).sort((a, b) => b[1].count - a[1].count).map(([k, v]) => [k, v.count, v.apps.map((a) => APP[a] || a).join(', '), roles(v.types)]));

const out = lines.join('\n');
if (args.out) {
  fs.writeFileSync(args.out, out, 'utf8');
  process.stderr.write(`Wrote ${args.out}\n`);
} else process.stdout.write(out);
