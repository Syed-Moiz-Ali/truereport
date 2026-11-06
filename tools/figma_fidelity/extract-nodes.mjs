#!/usr/bin/env node
// Compact, relative-coordinate node dump for the technician Figma export.
// Usage: node tools/figma_fidelity/extract-nodes.mjs <screen.json> [out.json]
// Read-only helper for the F2-A.1 fidelity audit. No metric is estimated.

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..');
const input = process.argv[2];
const output = process.argv[3];

if (!input) {
  console.error('usage: extract-nodes.mjs <screen.json> [out.json]');
  process.exit(2);
}

const doc = JSON.parse(readFileSync(resolve(repo, input), 'utf8'));
const root = doc.nodes[0];
const originX = root.absoluteBoundingBox.x;
const originY = root.absoluteBoundingBox.y;

const round = (n) => Math.round(n * 100) / 100;

function fillHex(fill) {
  if (!fill) return null;
  if (fill.hex) return fill.hex;
  if (fill.color) {
    const c = fill.color;
    const to = (v) => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, '0');
    return `#${to(c.r)}${to(c.g)}${to(c.b)}${fill.opacity != null && fill.opacity < 1 ? to(fill.opacity) : ''}`.toUpperCase();
  }
  return fill.type ?? null;
}

function effectSummary(e) {
  if (!e) return null;
  const color = e.color ? fillHex(e.color) : null;
  return {
    type: e.type,
    radius: e.radius,
    offset: e.offset ? { x: round(e.offset.x), y: round(e.offset.y) } : undefined,
    spread: e.spread,
    color,
  };
}

function node(n, depth = 0) {
  const box = n.absoluteBoundingBox ?? {};
  const text = n.text?.characters;
  const effects = (n.effects ?? []).filter((e) => e.visible !== false).map(effectSummary);
  const fills = (n.fills ?? [])
    .filter((f) => f.visible !== false)
    .map(fillHex)
    .filter(Boolean);
  const strokes = (n.strokes ?? [])
    .filter((f) => f.visible !== false)
    .map(fillHex)
    .filter(Boolean);
  const out = {
    id: n.id,
    name: n.name,
    type: n.type,
    depth,
    box: {
      x: round((box.x ?? 0) - originX),
      y: round((box.y ?? 0) - originY),
      w: round(box.width ?? 0),
      h: round(box.height ?? 0),
    },
  };
  if (n.layoutMode && n.layoutMode !== 'NONE') {
    out.layout = {
      mode: n.layoutMode,
      gap: n.itemSpacing,
      pad: [n.paddingTop, n.paddingRight, n.paddingBottom, n.paddingLeft],
      primary: n.primaryAxisAlignItems,
      counter: n.counterAxisAlignItems,
    };
  }
  if (n.cornerRadius) out.radius = n.cornerRadius;
  if (n.topLeftRadius || n.topRightRadius || n.bottomLeftRadius || n.bottomRightRadius) {
    out.radii = [n.topLeftRadius, n.topRightRadius, n.bottomRightRadius, n.bottomLeftRadius];
  }
  if (fills.length) out.fills = fills;
  if (strokes.length) out.strokes = { colors: strokes, weight: n.strokeWeight };
  if (effects.length) out.effects = effects;
  if (n.opacity != null && n.opacity !== 1) out.opacity = n.opacity;
  if (text != null) {
    const t = n.text;
    const lh = t.lineHeight?.value;
    out.text = {
      characters: text,
      font: `${t.fontName?.family ?? ''} ${t.fontName?.style ?? ''}`.trim(),
      size: t.fontSize,
      weight: t.fontWeight,
      lineHeight: lh,
      letterSpacing: t.letterSpacing?.value,
      align: t.textAlignHorizontal,
    };
    if (t.textCase && t.textCase !== 'ORIGINAL') out.text.textCase = t.textCase;
  }
  if (n.children?.length) out.children = n.children.map((c) => node(c, depth + 1));
  return out;
}

const tree = {
  screen: {
    id: root.id,
    name: root.name,
    width: root.absoluteBoundingBox.width,
    height: root.absoluteBoundingBox.height,
  },
  source: input,
  root: node(root),
};

const json = JSON.stringify(tree, null, 2);

function flat(n, lines) {
  const b = n.box;
  const bits = [
    `${'  '.repeat(n.depth)}${n.id} ${n.type} "${n.name}"`,
    `@${b.x},${b.y} ${b.w}x${b.h}`,
  ];
  if (n.radius) bits.push(`r=${n.radius}`);
  if (n.radii) bits.push(`radii=${n.radii.join('/')}`);
  if (n.fills) bits.push(`fill=${n.fills.join(',')}`);
  if (n.strokes) bits.push(`stroke=${n.strokes.colors.join(',')}@${n.strokes.weight}`);
  if (n.effects) {
    bits.push(`fx=${n.effects.map((e) => `${e.type}(${e.radius ?? ''}${e.offset ? ` ${e.offset.x},${e.offset.y}` : ''}${e.spread ? ` s${e.spread}` : ''})`).join('+')}`);
  }
  if (n.layout) {
    bits.push(`layout=${n.layout.mode} gap=${n.layout.gap} pad=${n.layout.pad.join(',')}`);
  }
  if (n.text) {
    const t = n.text;
    bits.push(`text=${JSON.stringify(t.characters)} ${t.font} ${t.size}/${t.weight} lh=${t.lineHeight ?? '-'} ls=${t.letterSpacing ?? '-'} ${t.align}`);
  }
  lines.push(bits.join(' '));
  for (const c of n.children ?? []) flat(c, lines);
}

const lines = [];
flat(tree.root, lines);
const flatText = lines.join('\n') + '\n';

if (output) {
  writeFileSync(resolve(repo, output), json + '\n');
  const txt = output.replace(/\.json$/, '.txt');
  writeFileSync(resolve(repo, txt), flatText);
  console.log(`wrote ${output} and ${txt} (${tree.root.children?.length ?? 0} top-level children)`);
} else {
  console.log(json);
}
