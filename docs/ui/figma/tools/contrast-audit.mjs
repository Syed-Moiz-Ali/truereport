#!/usr/bin/env node
/**
 * WCAG 2.2 contrast audit for the TrueReport Figma exports.
 *
 * Usage (from repository root):
 *   node docs/ui/figma/tools/contrast-audit.mjs --root=figma --out=%TEMP%/contrast-audit.json
 *   node docs/ui/figma/tools/contrast-audit.mjs --root=figma --format=summary
 *
 * Read-only: this script only reads the Figma JSON exports. It never writes into
 * the application or into the Figma folders. Use --out to persist the JSON in a
 * temporary location if desired.
 */

import fs from 'node:fs';
import path from 'node:path';

const APPS = [
  { key: 'technision_figma', label: 'Technician app (phone)', expected: 16 },
  { key: 'Workshop_admin_figma', label: 'Workshop admin (desktop)', expected: 12 },
  { key: 'platform_admin_figma', label: 'Platform admin (desktop)', expected: 10 },
  { key: 'public_report_figma', label: 'Public report (mobile + desktop)', expected: 7 },
];

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, ...v] = a.replace(/^--/, '').split('=');
    return [k, v.length ? v.join('=') : true];
  }),
);
const ROOT = args.root || 'figma';
const OUT = typeof args.out === 'string' ? args.out : null;

// ---------------------------------------------------------------------------
// Colour maths (WCAG 2.x / sRGB)
// ---------------------------------------------------------------------------

function parseHex(hex) {
  if (!hex || typeof hex !== 'string') return null;
  let h = hex.trim().replace(/^#/, '').toUpperCase();
  if (h.length === 3) h = h.split('').map((c) => c + c).join('');
  if (h.length === 6) h += 'FF';
  if (h.length !== 8 || !/^[0-9A-F]{8}$/.test(h)) return null;
  return {
    r: parseInt(h.slice(0, 2), 16) / 255,
    g: parseInt(h.slice(2, 4), 16) / 255,
    b: parseInt(h.slice(4, 6), 16) / 255,
    a: parseInt(h.slice(6, 8), 16) / 255,
    hex: '#' + h,
    rgbHex: '#' + h.slice(0, 6),
  };
}

function toHex(rgb) {
  const c = (v) => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, '0').toUpperCase();
  return '#' + c(rgb.r) + c(rgb.g) + c(rgb.b);
}

function blend(fg, bg, alpha) {
  return {
    r: fg.r * alpha + bg.r * (1 - alpha),
    g: fg.g * alpha + bg.g * (1 - alpha),
    b: fg.b * alpha + bg.b * (1 - alpha),
    a: 1,
  };
}

function channel(v) {
  return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
}

function luminance(rgb) {
  return 0.2126 * channel(rgb.r) + 0.7152 * channel(rgb.g) + 0.0722 * channel(rgb.b);
}

function contrast(a, b) {
  const l1 = luminance(a);
  const l2 = luminance(b);
  const [hi, lo] = l1 >= l2 ? [l1, l2] : [l2, l1];
  return (hi + 0.05) / (lo + 0.05);
}

const r2 = (n) => Math.round(n * 100) / 100;
const r3 = (n) => Math.round(n * 1000) / 1000;

function paintAlpha(p) {
  const c = parseHex(p.hex);
  if (!c) return p.opacity === undefined ? 1 : p.opacity;
  // The export writes translucent paint opacity into the 8th/9th hex digits.
  // Prefer that value; falling back to `p.opacity` avoids double-multiplying.
  if (c.hex.length === 9 && c.a < 1) return c.a;
  return p.opacity === undefined ? 1 : p.opacity;
}

function visiblePaints(node, key) {
  return ((node && node[key]) || []).filter((p) => p && p.visible !== false);
}

function hasBlur(node) {
  return ((node && node.effects) || []).some(
    (e) => e && e.visible !== false && (e.type === 'BACKGROUND_BLUR' || e.type === 'LAYER_BLUR'),
  );
}

function isSolidOpaque(p) {
  const c = parseHex(p && p.hex);
  return p && p.type === 'SOLID' && c && paintAlpha(p) >= 0.9995;
}

// ---------------------------------------------------------------------------
// Input enumeration
// ---------------------------------------------------------------------------

function enumerateScreens() {
  const out = [];
  for (const app of APPS) {
    const base = path.join(ROOT, app.key, 'screens');
    if (!fs.existsSync(base)) continue;
    for (const dir of fs.readdirSync(base)) {
      const d = path.join(base, dir);
      if (!fs.statSync(d).isDirectory()) continue;
      const file = fs.readdirSync(d).find((f) => f.endsWith('.json'));
      if (!file) continue;
      out.push({ app, appKey: app.key, appLabel: app.label, screenDir: dir, file: path.join(d, file) });
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Text-node audit
// ---------------------------------------------------------------------------

function requirement(fontSize, fontWeight) {
  const bold = Number(fontWeight) >= 700;
  const large = fontSize >= 24 || (fontSize >= 18.66 && bold);
  return { large, min: large ? 3 : 4.5 };
}

function ancestorChainVisible(ancestors) {
  return ancestors.every((a) => a.visible !== false);
}

function findBackground(ancestors) {
  // Walk from nearest ancestor outward. Stop at the first painted ancestor:
  // an opaque fill there hides everything outside it. Before using that fill,
  // however, check blur/opacity on every ancestor up to and including it,
  // because those effects change what the text is actually rendered over.
  for (let i = ancestors.length - 1; i >= 0; i--) {
    const a = ancestors[i];
    if (a.visible === false) continue;
    if (hasBlur(a)) {
      return { status: 'undetermined', bgNode: a, reason: 'ancestor has background/layer blur' };
    }
    if (a.opacity !== undefined && a.opacity < 0.9995) {
      return { status: 'undetermined', bgNode: a, reason: `ancestor opacity ${r3(a.opacity)}` };
    }
    const paints = visiblePaints(a, 'fills');
    if (paints.length === 0) continue;

    const solids = paints.filter((p) => p.type === 'SOLID');
    const firstNonSolid = paints.find((p) => p.type !== 'SOLID');
    const alpha = paints.length === 1 ? paintAlpha(paints[0]) : null;

    if (
      paints.length === 1 &&
      solids.length === 1 &&
      isSolidOpaque(paints[0]) &&
      (a.opacity === undefined || a.opacity >= 0.9995) &&
      !hasBlur(a)
    ) {
      const c = parseHex(paints[0].hex);
      return {
        status: 'determined',
        bg: c,
        bgHex: c.rgbHex,
        bgNode: a,
        reason: 'opaque ancestor fill',
      };
    }

    let reason = 'ancestor fill is not an opaque solid';
    if (firstNonSolid) reason = `ancestor fill is ${firstNonSolid.type.toLowerCase()}`;
    else if (paints.length > 1) reason = 'ancestor has multiple paints';
    else if (alpha !== null && alpha < 0.9995) {
      reason = `ancestor fill is translucent (alpha ${r3(alpha)})`;
    }
    if (a.opacity !== undefined && a.opacity < 0.9995) {
      reason = `ancestor opacity ${r3(a.opacity)}`;
    }
    if (hasBlur(a)) reason = 'ancestor has background/layer blur';
    return {
      status: 'undetermined',
      bgNode: a,
      reason,
      paints: paints.map((p) => ({ type: p.type, hex: p.hex, alpha: paintAlpha(p) })),
    };
  }
  return { status: 'undetermined', bgNode: null, reason: 'no ancestor with a fill' };
}

function auditTextNode(node, ancestors, screen) {
  if (!node.text || typeof node.text.characters !== 'string' || !node.text.characters.trim()) return null;
  const chars = node.text.characters.replace(/\s+/g, ' ').trim();
  const fontSize = typeof node.text.fontSize === 'number' ? node.text.fontSize : null;
  const fontWeight = typeof node.text.fontWeight === 'number' ? node.text.fontWeight : null;
  if (fontSize === null || fontWeight === null) {
    return {
      kind: 'undetermined',
      reason: 'mixed or missing font size / weight',
      screen,
      id: node.id,
      text: chars.slice(0, 80),
      fg: null,
      bg: null,
    };
  }

  const paint = visiblePaints(node, 'fills')[0];
  const fgColor = paint && parseHex(paint.hex);
  if (!paint || paint.type !== 'SOLID' || !fgColor) {
    return {
      kind: 'undetermined',
      reason: paint ? `text fill is ${paint.type.toLowerCase()}` : 'text node has no visible fill',
      screen,
      id: node.id,
      text: chars.slice(0, 80),
      fg: paint ? paint.hex : null,
      bg: null,
    };
  }

  const req = requirement(fontSize, fontWeight);
  const bgResult = findBackground(ancestors);
  const nodeOpacity = node.opacity === undefined ? 1 : node.opacity;
  const textAlpha = Math.min(1, paintAlpha(paint) * nodeOpacity);
  const ancestorAlpha = ancestors.reduce((p, a) => p * (a.opacity === undefined ? 1 : a.opacity), 1);

  const base = {
    kind: 'text',
    screen,
    id: node.id,
    text: chars.slice(0, 120),
    fontSize,
    fontWeight,
    large: req.large,
    min: req.min,
    fgHex: fgColor.rgbHex,
    fgRaw: paint.hex,
    textAlpha: r3(textAlpha),
    nodeOpacity: r3(nodeOpacity),
    ancestorOpacity: r3(ancestorAlpha),
    bgNode: bgResult.bgNode ? bgResult.bgNode.id : null,
  };

  if (bgResult.status === 'undetermined') {
    return {
      ...base,
      kind: 'undetermined',
      reason: bgResult.reason,
      bg: null,
      bgPaints: bgResult.paints || null,
      // An unscaled ratio is still useful evidence for triage, but it must
      // never be counted as a pass/fail.
      unscaledRatio: bgResult.paints && bgResult.paints[0] && bgResult.paints[0].hex
        ? r2(contrast(fgColor, parseHex(bgResult.paints[0].hex) || fgColor))
        : null,
    };
  }

  const bg = bgResult.bg;
  const fgEffective = textAlpha >= 0.9995 ? fgColor : blend(fgColor, bg, textAlpha);
  const ratio = contrast(fgEffective, bg);
  const unscaled = contrast(fgColor, bg);

  return {
    ...base,
    kind: 'text',
    bgHex: bgResult.bgHex,
    bg: bgResult.bgHex,
    ratio: r2(ratio),
    unscaledRatio: r2(unscaled),
    rawRatio: ratio,
    pass: ratio >= req.min,
    alphaAdjusted: textAlpha < 0.9995 || bgResult.bg.a < 0.9995,
  };
}

// ---------------------------------------------------------------------------
// Traversal
// ---------------------------------------------------------------------------

function traverse(node, ancestors, screen, ctx) {
  if (!node || node.visible === false) return;
  const screenLabel = screen.appLabel;

  if (node.type === 'TEXT') {
    const rec = auditTextNode(node, ancestors, screen);
    if (rec) ctx.text.push(rec);
  }

  // Stoke pairs (UI-component boundaries).
  const strokes = visiblePaints(node, 'strokes');
  if (strokes.length > 0 && (node.strokeWeight === undefined || node.strokeWeight > 0)) {
    const bg = findBackground(ancestors);
    for (const st of strokes) {
      if (st.type !== 'SOLID' || !parseHex(st.hex)) continue;
      const strokeC = parseHex(st.hex);
      const own = visiblePaints(node, 'fills')[0];
      const ownC = own && own.type === 'SOLID' ? parseHex(own.hex) : null;
      if (bg.status === 'determined') {
        ctx.strokes.push({
          screen,
          id: node.id,
          name: node.name || '',
          type: node.type,
          stroke: strokeC.rgbHex,
          against: 'parent background',
          bg: bg.bgHex,
          ratio: r2(contrast(strokeC, bg.bg)),
          rawRatio: contrast(strokeC, bg.bg),
          width: node.strokeWeight ?? 1,
          align: node.strokeAlign,
        });
      }
      if (ownC) {
        ctx.strokes.push({
          screen,
          id: node.id,
          name: node.name || '',
          type: node.type,
          stroke: strokeC.rgbHex,
          against: 'own fill',
          bg: ownC.rgbHex,
          ratio: r2(contrast(strokeC, ownC)),
          rawRatio: contrast(strokeC, ownC),
          width: node.strokeWeight ?? 1,
          align: node.strokeAlign,
        });
      }
    }
  }

  // Icon / vector fill against the nearest opaque ancestor fill.
  if (node.type === 'VECTOR') {
    const paint = visiblePaints(node, 'fills')[0];
    if (paint && paint.type === 'SOLID' && parseHex(paint.hex)) {
      const fg = parseHex(paint.hex);
      const bg = findBackground(ancestors);
      if (bg.status === 'determined') {
        ctx.vectors.push({
          screen,
          id: node.id,
          name: node.name || '',
          fg: fg.rgbHex,
          bg: bg.bgHex,
          ratio: r2(contrast(fg, bg.bg)),
          rawRatio: contrast(fg, bg.bg),
        });
      }
    }
  }

  // Container -> descendant-text pairs (buttons, badges, cards). This is
  // intentionally narrower than the text audit: it records the container fill
  // and each direct/indirect text fill so component fills can be compared.
  const containerFills = visiblePaints(node, 'fills').filter(
    (p) => p.type === 'SOLID' && parseHex(p.hex) && paintAlpha(p) >= 0.9995 && (node.opacity ?? 1) >= 0.9995,
  );
  if (containerFills.length === 1 && node.type !== 'TEXT') {
    const cf = parseHex(containerFills[0].hex);
    const texts = [];
    (function collect(n) {
      for (const c of n.children || []) {
        if (c.visible === false) continue;
        if (c.type === 'TEXT' && c.text && c.text.characters && c.text.characters.trim()) {
          const tp = visiblePaints(c, 'fills')[0];
          if (tp && tp.type === 'SOLID' && parseHex(tp.hex)) {
            const tCol = parseHex(tp.hex);
            texts.push({
              id: c.id,
              text: c.text.characters.replace(/\s+/g, ' ').trim().slice(0, 80),
              fg: tCol.rgbHex,
              ratio: r2(contrast(tCol, cf)),
              fontSize: c.text.fontSize,
              fontWeight: c.text.fontWeight,
            });
          }
        }
        collect(c);
      }
    })(node);
    if (texts.length) {
      ctx.containers.push({
        screen,
        id: node.id,
        name: node.name || '',
        fill: cf.rgbHex,
        texts,
      });
    }
  }

  const next = ancestors.concat([node]);
  for (const c of node.children || []) traverse(c, next, screen, ctx);
}

// ---------------------------------------------------------------------------
// Aggregation helpers
// ---------------------------------------------------------------------------

function pairKey(rec) {
  return `${rec.fgHex}|${rec.bgHex}`;
}

function aggregateText(records) {
  const determined = records.filter((r) => r.kind === 'text' && r.pass !== undefined);
  const undetermined = records.filter((r) => r.kind === 'undetermined');
  const opaque = determined.filter((r) => (r.textAlpha ?? 1) >= 0.9995);
  const alpha = determined.filter((r) => (r.textAlpha ?? 1) < 0.9995);
  const map = new Map();
  for (const rec of opaque) {
    const k = pairKey(rec);
    if (!map.has(k)) {
      map.set(k, {
        fg: rec.fgHex,
        bg: rec.bgHex,
        count: 0,
        normal: 0,
        large: 0,
        normalPass: 0,
        normalFail: 0,
        largePass: 0,
        largeFail: 0,
        minRatio: rec.ratio,
        maxRatio: rec.ratio,
        examples: [],
        screens: new Set(),
        apps: new Set(),
      });
    }
    const p = map.get(k);
    p.count++;
    p.screens.add(rec.screen.screenDir);
    p.apps.add(rec.screen.app.label);
    if (rec.large) p.large++;
    else p.normal++;
    if (rec.pass) {
      if (rec.large) p.largePass++;
      else p.normalPass++;
    } else {
      if (rec.large) p.largeFail++;
      else p.normalFail++;
    }
    p.minRatio = Math.min(p.minRatio, rec.ratio);
    p.maxRatio = Math.max(p.maxRatio, rec.ratio);
    if (p.examples.length < 3) {
      p.examples.push({
        app: rec.screen.app.label,
        screen: rec.screen.screenDir,
        id: rec.id,
        text: rec.text,
        fontSize: rec.fontSize,
        fontWeight: rec.fontWeight,
      });
    }
  }
  const alphaMap = new Map();
  for (const rec of alpha) {
    const k = `${rec.fgRaw}|${rec.bgHex}|${rec.textAlpha}`;
    if (!alphaMap.has(k)) {
      alphaMap.set(k, {
        fg: rec.fgHex,
        fgRaw: rec.fgRaw,
        bg: rec.bgHex,
        alpha: rec.textAlpha,
        count: 0,
        pass: 0,
        fail: 0,
        minRatio: rec.ratio,
        maxRatio: rec.ratio,
        unscaledRatio: rec.unscaledRatio,
        examples: [],
      });
    }
    const p = alphaMap.get(k);
    p.count++;
    if (rec.pass) p.pass++;
    else p.fail++;
    p.minRatio = Math.min(p.minRatio, rec.ratio);
    p.maxRatio = Math.max(p.maxRatio, rec.ratio);
    if (p.examples.length < 3) {
      p.examples.push({
        app: rec.screen.app.label,
        screen: rec.screen.screenDir,
        id: rec.id,
        text: rec.text,
        fontSize: rec.fontSize,
        fontWeight: rec.fontWeight,
      });
    }
  }
  return {
    determined,
    opaque,
    alpha,
    undetermined,
    pairs: [...map.values()].map((p) => ({ ...p, screens: [...p.screens], apps: [...p.apps] })),
    alphaPairs: [...alphaMap.values()].sort((a, b) => a.minRatio - b.minRatio),
  };
}

// ---------------------------------------------------------------------------
// Product comparison (tokens.dart + report.css)
// ---------------------------------------------------------------------------

function productPairs() {
  const pairs = [];
  const add = (group, label, fg, bg, req = 4.5, note = '') => {
    const f = parseHex('#' + fg);
    const b = parseHex('#' + bg);
    if (!f || !b) return;
    pairs.push({ group, label, fg: '#' + fg, bg: '#' + bg, ratio: r2(contrast(f, b)), min: req, pass: contrast(f, b) >= req, note });
  };

  // AppStatusColors light (tokens.dart:217-239)
  const statusLight = {
    neutral: ['4D6670', 'EDF1F3'],
    info: ['1D5C8A', 'E5F0F8'],
    success: ['1F6B45', 'E6F3EC'],
    warning: ['8A5A00', 'FFF4D6'],
    danger: ['A3231F', 'FBE9E7'],
    critical: ['7F1D1D', 'F7DADA'],
  };
  const statusDark = {
    neutral: ['C3D4DA', '26373C'],
    info: ['B7DCF7', '173247'],
    success: ['B5E8C9', '173D2B'],
    warning: ['FFDFA3', '463611'],
    danger: ['FFC4BD', '4A1F1C'],
    critical: ['FFD0D0', '551C1C'],
  };
  for (const [tone, [fg, bg]] of Object.entries(statusLight)) add('AppStatusColors light', tone, fg, bg);
  for (const [tone, [fg, bg]] of Object.entries(statusDark)) add('AppStatusColors dark', tone, fg, bg);

  // Explicit scheme colours (tokens.dart:339-368)
  add('ColorScheme light', 'onPrimary on primary', 'FFFFFF', '0B3B4A');
  add('ColorScheme light', 'primary on surface', '0B3B4A', 'F7FAFA');
  add('ColorScheme light', 'primary on surfaceContainerLowest', '0B3B4A', 'FFFFFF');
  add('ColorScheme light', 'secondary on surface', '0F6B6F', 'F7FAFA');
  add('ColorScheme light', 'onSurface on surface', '17212B', 'F7FAFA');
  add('ColorScheme light', 'onSurface on surfaceContainerLow', '17212B', 'F1F5F5');
  add('ColorScheme light', 'error on surface', 'A3231F', 'F7FAFA');
  add('ColorScheme light', 'outlineVariant on surface (UI)', 'D5E3E6', 'F7FAFA', 3);
  add('ColorScheme light', 'outlineVariant on white (UI)', 'D5E3E6', 'FFFFFF', 3);
  add('ColorScheme dark', 'onPrimary on primary', '00363D', '8FD1D8');
  add('ColorScheme dark', 'primary on surface', '8FD1D8', '0D1416');
  add('ColorScheme dark', 'secondary on surface', '82D0D4', '0D1416');
  add('ColorScheme dark', 'onSurface on surface', 'E4ECEF', '0D1416');
  add('ColorScheme dark', 'onSurface on surfaceContainer', 'E4ECEF', '1B262A');
  add('ColorScheme dark', 'error on surface', 'FFB4AB', '0D1416');
  add('ColorScheme dark', 'outlineVariant on surface (UI)', '33464C', '0D1416', 3);
  add('ColorScheme dark', 'outlineVariant on surfaceContainer (UI)', '33464C', '1B262A', 3);

  // report.css variables (:root and dark media block)
  add('report.css light', 'body on-surface on surface', '17212B', 'F7FAFA');
  add('report.css light', 'primary button text on primary', 'FFFFFF', '0B3B4A');
  add('report.css light', 'secondary link on surface', '0F6B6F', 'F7FAFA');
  add('report.css light', 'on-variant on surface', '4D6670', 'F7FAFA');
  add('report.css light', 'on-variant on surface-card', '4D6670', 'FFFFFF');
  add('report.css light', 'badge neutral on-variant on surface-high', '4D6670', 'EAF0F0');
  add('report.css light', 'badge success', '1F6B45', 'E6F3EC');
  add('report.css light', 'badge warning', '8A5A00', 'FFF4D6');
  add('report.css light', 'badge danger', 'A3231F', 'FBE9E7');
  add('report.css light', 'badge critical', '7F1D1D', 'F7DADA');
  add('report.css light', 'outline on surface (UI)', 'D5E3E6', 'F7FAFA', 3);
  add('report.css light', 'outline on card (UI)', 'D5E3E6', 'FFFFFF', 3);
  add('report.css light', 'focus outline secondary on surface (UI)', '0F6B6F', 'F7FAFA', 3);
  add('report.css dark', 'body on-surface on surface', 'E4ECEF', '0D1416');
  // .button.primary / .skip-link use var(--surface-card) as the text colour.
  add('report.css dark', 'primary button text (surface-card) on primary', '1B262A', '8FD1D8');
  add('report.css dark', 'white on primary (hypothetical)', 'FFFFFF', '8FD1D8');
  add('report.css dark', 'secondary link on surface', '82D0D4', '0D1416');
  add('report.css dark', 'on-variant on surface', 'C3D4DA', '0D1416');
  add('report.css dark', 'badge neutral on-variant on surface-high', 'C3D4DA', '223035');
  add('report.css dark', 'badge success', 'B5E8C9', '173D2B');
  add('report.css dark', 'badge warning', 'FFDFA3', '463611');
  add('report.css dark', 'badge danger', 'FFC4BD', '4A1F1C');
  add('report.css dark', 'badge critical', 'FFD0D0', '551C1C');
  add('report.css dark', 'outline on surface (UI)', '33464C', '0D1416', 3);
  add('report.css dark', 'focus outline secondary on surface (UI)', '82D0D4', '0D1416', 3);

  return pairs;
}

// ---------------------------------------------------------------------------
// Palette corpus and component-pair audit
// ---------------------------------------------------------------------------

function buildPalette(results) {
  const fills = new Map();
  const strokes = new Map();
  const add = (map, hex, rec) => {
    if (!hex) return;
    const c = parseHex(hex);
    if (!c) return;
    const key = c.rgbHex + (c.a < 0.9995 ? `/a${r3(c.a)}` : '');
    if (!map.has(key)) map.set(key, { hex: key, rgb: c.rgbHex, alpha: r3(c.a), count: 0, apps: new Set(), examples: [] });
    const e = map.get(key);
    e.count++;
    e.apps.add(rec.screen.app.label);
    if (e.examples.length < 2) e.examples.push({ screen: rec.screen.screenDir, id: rec.id });
  };
  for (const r of results.text) {
    add(fills, r.fgRaw || r.fgHex, { screen: r.screen, id: r.id });
    if (r.bg) add(fills, r.bg, { screen: r.screen, id: r.id });
  }
  for (const s of results.strokes) {
    add(strokes, s.stroke, { screen: s.screen, id: s.id });
    add(fills, s.bg, { screen: s.screen, id: s.id });
  }
  for (const v of results.vectors) {
    add(fills, v.fg, { screen: v.screen, id: v.id });
    add(fills, v.bg, { screen: v.screen, id: v.id });
  }
  for (const c of results.containers) {
    add(fills, c.fill, { screen: c.screen, id: c.id });
    for (const t of c.texts) add(fills, t.fg, { screen: c.screen, id: c.id });
  }
  const clean = (map) =>
    [...map.values()]
      .map((e) => ({ ...e, apps: [...e.apps] }))
      .sort((a, b) => b.count - a.count);
  return { fills: clean(fills), strokes: clean(strokes) };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const screens = enumerateScreens();
const results = {
  screens: [],
  text: [],
  strokes: [],
  vectors: [],
  containers: [],
};

for (const sc of screens) {
  const json = JSON.parse(fs.readFileSync(sc.file, 'utf8'));
  const ctx = { text: [], strokes: [], vectors: [], containers: [] };
  for (const n of json.nodes || []) traverse(n, [], sc, ctx);
  results.text.push(...ctx.text);
  results.strokes.push(...ctx.strokes);
  results.vectors.push(...ctx.vectors);
  results.containers.push(...ctx.containers);
  results.screens.push({
    app: sc.appLabel,
    appKey: sc.appKey,
    screen: sc.screenDir,
    root: (json.nodes && json.nodes[0] && json.nodes[0].name) || sc.screenDir,
    textNodes: ctx.text.filter((r) => r.kind === 'text').length,
    undetermined: ctx.text.filter((r) => r.kind === 'undetermined').length,
  });
}

const textAgg = aggregateText(results.text);
const palette = buildPalette(results);
const product = productPairs();

// Per-screen and per-app summaries.
const byScreen = new Map();
const byApp = new Map();
const touch = (map, key, label) => {
  if (!map.has(key)) map.set(key, { key, label, audited: 0, determined: 0, undetermined: 0, normalPass: 0, normalFail: 0, largePass: 0, largeFail: 0, alphaText: 0, alphaFail: 0 });
  return map.get(key);
};
for (const r of results.text) {
  const s = touch(byScreen, r.screen.appKey + '|' + r.screen.screenDir, r.screen.screenDir);
  const a = touch(byApp, r.screen.appKey, r.screen.app.label);
  for (const x of [s, a]) {
    x.audited++;
    if (r.kind === 'undetermined') x.undetermined++;
    else if (r.kind === 'text') {
      x.determined++;
      if ((r.textAlpha ?? 1) < 0.9995) {
        x.alphaText++;
        if (!r.pass) x.alphaFail++;
      } else if (r.pass) {
        if (r.large) x.largePass++;
        else x.normalPass++;
      } else {
        if (r.large) x.largeFail++;
        else x.normalFail++;
      }
    }
  }
}

const pairFailures = [];
for (const p of textAgg.pairs) {
  if (p.normalFail > 0) {
    pairFailures.push({
      fg: p.fg,
      bg: p.bg,
      ratio: p.minRatio,
      min: 4.5,
      count: p.normalFail,
      total: p.count,
      normal: p.normal,
      large: p.large,
      examples: p.examples,
      apps: p.apps,
    });
  }
  if (p.largeFail > 0) {
    pairFailures.push({
      fg: p.fg,
      bg: p.bg,
      ratio: p.minRatio,
      min: 3,
      count: p.largeFail,
      total: p.count,
      normal: p.normal,
      large: p.large,
      examples: p.examples,
      apps: p.apps,
    });
  }
}
pairFailures.sort((a, b) => a.ratio - b.ratio || b.count - a.count);

const summary = {
  screens: screens.length,
  textNodesAudited: results.text.length,
  textDetermined: textAgg.determined.length,
  opaqueDetermined: textAgg.opaque.length,
  alphaTextNodes: textAgg.alpha.length,
  textUndetermined: textAgg.undetermined.length,
  distinctTextPairs: textAgg.pairs.length,
  distinctAlphaPairs: textAgg.alphaPairs.length,
  normalPass: textAgg.opaque.filter((r) => !r.large && r.pass).length,
  normalFail: textAgg.opaque.filter((r) => !r.large && !r.pass).length,
  largePass: textAgg.opaque.filter((r) => r.large && r.pass).length,
  largeFail: textAgg.opaque.filter((r) => r.large && !r.pass).length,
  alphaPass: textAgg.alpha.filter((r) => r.pass).length,
  alphaFail: textAgg.alpha.filter((r) => !r.pass).length,
  textNodesFailing: textAgg.determined.filter((r) => !r.pass).length,
  distinctFailingPairs: new Set([
    ...pairFailures.map((p) => `${p.fg}|${p.bg}|${p.min}`),
    ...textAgg.alphaPairs.filter((p) => p.fail > 0).map((p) => `${p.fgRaw}|${p.bg}|${p.alpha}|4.5`),
  ]).size,
};

const output = {
  meta: {
    generatedAt: new Date().toISOString(),
    root: ROOT,
    apps: APPS,
    thresholds: { normal: 4.5, large: 3, ui: 3, largePxBold: 18.66, largePx: 24 },
  },
  summary,
  byApp: [...byApp.values()].map((x) => ({ ...x, ratioSum: undefined })),
  byScreen: [...byScreen.values()].map((x) => ({ ...x, ratioSum: undefined })).sort((a, b) => b.key.localeCompare(a.key)),
  textPairs: textAgg.pairs
    .map((p) => ({
      fg: p.fg,
      bg: p.bg,
      count: p.count,
      normal: p.normal,
      large: p.large,
      normalPass: p.normalPass,
      normalFail: p.normalFail,
      largePass: p.largePass,
      largeFail: p.largeFail,
      minRatio: p.minRatio,
      maxRatio: p.maxRatio,
      required: p.largeFail > 0 ? 3 : 4.5,
      apps: p.apps,
      screens: p.screens,
      examples: p.examples,
      failing: p.normalFail > 0 || p.largeFail > 0,
    }))
    .sort((a, b) => a.minRatio - b.minRatio || b.count - a.count),
  pairFailures,
  alphaPairs: textAgg.alphaPairs,
  undetermined: textAgg.undetermined.slice(0, 400),
  palette,
  strokes: results.strokes,
  vectors: results.vectors,
  containers: results.containers,
  textRecords: results.text,
  product,
};

if (OUT) {
  fs.writeFileSync(OUT, JSON.stringify(output, null, 2));
  console.error(`Wrote ${OUT}`);
}

if (args.format === 'summary' || !OUT) {
  console.log(JSON.stringify({ meta: output.meta, summary, byApp: output.byApp, byScreen: output.byScreen }, null, 2));
}
