#!/usr/bin/env node
/**
 * F0 design-token aggregator for the four Figma exports.
 *
 * Read-only over the exports. Writes one JSON aggregate; no app code touched.
 *
 * Usage:
 *   node docs/ui/figma/tools/aggregate-tokens.js [--root <repo>] [--out <file>]
 *
 * Recommended:
 *   node docs/ui/figma/tools/aggregate-tokens.js \
 *     --out docs/ui/figma/tools/tokens-aggregate.json
 */
'use strict';

const fs = require('fs');
const path = require('path');

const APPS = [
  { key: 'tech', dir: 'technision_figma', label: 'Technician (mobile)' },
  { key: 'workshop', dir: 'Workshop_admin_figma', label: 'Workshop Admin (desktop)' },
  { key: 'platform', dir: 'platform_admin_figma', label: 'Platform Admin (desktop)' },
  { key: 'public', dir: 'public_report_figma', label: 'Public Report (web)' },
];

function parseArgs(argv) {
  const args = { root: path.resolve(__dirname, '../../../..'), out: null };
  for (let i = 2; i < argv.length; i += 1) {
    if (argv[i] === '--root') args.root = path.resolve(argv[++i]);
    else if (argv[i] === '--out') args.out = path.resolve(argv[++i]);
  }
  return args;
}

const round = (n) => (typeof n === 'number' ? Math.round(n * 1000) / 1000 : n);

function normHex(hex) {
  if (!hex || typeof hex !== 'string') return null;
  const v = hex.trim().toUpperCase();
  return v.startsWith('#') ? v : `#${v}`;
}

function hexFromColor(color) {
  if (!color) return null;
  const r = Math.round((color.r || 0) * 255);
  const g = Math.round((color.g || 0) * 255);
  const b = Math.round((color.b || 0) * 255);
  const a = color.a === undefined ? 1 : color.a;
  const base = `#${[r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('').toUpperCase()}`;
  if (a < 0.999) return `${base}${Math.round(a * 255).toString(16).padStart(2, '0').toUpperCase()}`;
  return base;
}

function rgbaFromColor(color) {
  if (!color) return 'transparent';
  const r = Math.round((color.r || 0) * 255);
  const g = Math.round((color.g || 0) * 255);
  const b = Math.round((color.b || 0) * 255);
  const a = color.a === undefined ? 1 : color.a;
  return `rgba(${r},${g},${b},${round(a)})`;
}

const bucket = () => ({ count: 0, apps: new Set(), screens: new Set(), roles: {}, details: new Set() });

function addToMap(map, key, meta) {
  if (key === null || key === undefined) return;
  if (!map[key]) map[key] = { key, ...bucket() };
  const rec = map[key];
  rec.count += 1;
  if (meta) {
    if (meta.app) rec.apps.add(meta.app);
    if (meta.screenKey) rec.screens.add(meta.screenKey);
    if (meta.role) rec.roles[meta.role] = (rec.roles[meta.role] || 0) + 1;
    if (meta.detail) rec.details.add(meta.detail);
  }
}

function finalizeMap(map) {
  return Object.values(map)
    .map((r) => ({
      key: r.key,
      count: r.count,
      apps: [...r.apps].sort(),
      appCount: r.apps.size,
      screens: [...r.screens].sort(),
      screenCount: r.screens.size,
      roles: r.roles,
      details: [...r.details].sort(),
    }))
    .sort((a, b) => b.count - a.count || String(a.key).localeCompare(String(b.key)));
}

const COMPONENT_PATTERNS = [
  ['button/cta', /\b(button|btn|cta)\b/i],
  ['card', /\bcard\b/i],
  ['chip/badge/tag/pill', /\b(chip|badge|tag|pill)\b/i],
  ['input/field/select', /\b(input|field|textfield|text field|select|dropdown|combobox)\b/i],
  ['segmented/tabs/toggle/switch', /\b(segmented|segment|tab|toggle|switch)\b/i],
  ['nav/rail/sidebar', /\b(nav|navigation|rail|sidebar|menu)\b/i],
  ['header/appbar/topbar', /\b(header|appbar|app bar|top bar|topbar)\b/i],
  ['bottom bar/footer', /\b(bottom|footer|dock|tab bar)\b/i],
  ['modal/sheet/drawer/dialog', /\b(modal|sheet|drawer|dialog|overlay)\b/i],
  ['progress/stepper', /\b(progress|stepper|step)\b/i],
  ['table/grid/list/queue', /\b(table|grid|list|queue|row|cell)\b/i],
  ['avatar/photo/media', /\b(avatar|photo|image|thumbnail|media|video)\b/i],
  ['pin/marker', /\b(pin|marker)\b/i],
  ['icon', /\bicon\b/i],
  ['checkbox/radio/slider', /\b(checkbox|check box|radio|slider)\b/i],
  ['banner/alert/toast/skeleton', /\b(banner|alert|toast|snackbar|snack bar|skeleton)\b/i],
  ['divider/separator', /\b(divider|separator|line)\b/i],
  ['accordion/tree/timeline', /\b(accordion|tree|timeline)\b/i],
];

function classifyName(name) {
  const hits = [];
  for (const [label, re] of COMPONENT_PATTERNS) if (re.test(name)) hits.push(label);
  return hits;
}

function walkNodes(nodes, visit, depth = 0) {
  if (!Array.isArray(nodes)) return;
  for (const node of nodes) {
    if (!node || typeof node !== 'object') continue;
    visit(node, depth);
    if (Array.isArray(node.children)) walkNodes(node.children, visit, depth + 1);
  }
}

function discoverScreens(root) {
  const screens = [];
  for (const app of APPS) {
    const appRoot = path.join(root, 'figma', app.dir);
    const screensDir = path.join(appRoot, 'screens');
    if (!fs.existsSync(screensDir)) continue;
    for (const folder of fs.readdirSync(screensDir).sort()) {
      const folderPath = path.join(screensDir, folder);
      if (!fs.statSync(folderPath).isDirectory()) continue;
      const files = fs.readdirSync(folderPath).filter((f) => f.toLowerCase().endsWith('.json'));
      const jsonFile = files.find((f) => f !== 'manifest.json' && f !== 'package-manifest.json');
      if (!jsonFile) continue;
      const manifestPath = path.join(folderPath, 'assets', 'manifest.json');
      screens.push({
        app: app.key,
        appLabel: app.label,
        appDir: app.dir,
        folder,
        screenKey: `${app.key}/${folder}`,
        screenName: folder.replace(/^\d+_/, ''),
        jsonPath: path.join(folderPath, jsonFile),
        manifestPath: fs.existsSync(manifestPath) ? manifestPath : null,
        packageManifestPath: path.join(appRoot, 'package-manifest.json'),
      });
    }
  }
  return screens;
}

function main() {
  const args = parseArgs(process.argv);
  const screens = discoverScreens(args.root);

  const colorsAll = {};
  const colorsText = {};
  const colorsStroke = {};
  const colorsGradient = {};
  const colorsEffect = {};
  const fonts = {};
  const typeCombos = {};
  const sizes = {};
  const lineHeights = {};
  const letterSpacings = {};
  const radii = {};
  const cornerOverrides = {};
  const itemSpacings = {};
  const paddings = {};
  const gridGaps = {};
  const effects = {};
  const effectGeometry = {};
  const strokes = {};
  const nodeTypes = {};
  const namePatterns = {};
  const assetRoles = {};
  const assetShapes = {};
  const assetHashes = {};
  const rasterAssets = [];
  const componentGeometry = {};
  const layoutModes = {};
  const styleRefs = { textStyleId: 0, fillStyleId: 0, strokeStyleId: 0, effectStyleId: 0 };
  const variableCollections = {};
  const variables = {};
  const warnings = [];
  const screenMeta = [];
  const packageTotals = {};
  const nonDefaultFonts = [];

  for (const s of screens) {
    const j = JSON.parse(fs.readFileSync(s.jsonPath, 'utf8'));
    const manifest = s.manifestPath ? JSON.parse(fs.readFileSync(s.manifestPath, 'utf8')) : null;
    const ds = (j.developerSummary && j.developerSummary.designSystemObserved) || {};
    const screenName = (j.developerSummary && j.developerSummary.screen && j.developerSummary.screen.name) || s.screenName;
    const rootNode = Array.isArray(j.nodes) && j.nodes[0] ? j.nodes[0] : null;
    screenMeta.push({
      app: s.app,
      screen: screenName,
      folder: s.folder,
      width: rootNode ? round(rootNode.width) : null,
      height: rootNode ? round(rootNode.height) : null,
      summary: {
        colors: ds.colors || [],
        fonts: ds.fonts || [],
        fontSizes: ds.fontSizes || [],
        radii: ds.cornerRadiusCandidates || [],
        spacing: ds.spacingTokenCandidates || [],
        computedOrLargeLayoutSpacing: ds.computedOrLargeLayoutSpacing || [],
        nodeTypes: (j.developerSummary && j.developerSummary.nodeTypes) || {},
      },
      warnings: j.warnings || [],
      manifestAssets: manifest ? manifest.assets : [],
    });

    if (j.warnings && j.warnings.length) warnings.push({ screen: s.screenKey, warnings: j.warnings });
    for (const k of Object.keys(j.variableCollections || {})) variableCollections[k] = (variableCollections[k] || 0) + 1;
    for (const k of Object.keys(j.variables || {})) variables[k] = (variables[k] || 0) + 1;

    const seenStyleRef = { textStyleId: 0, fillStyleId: 0, strokeStyleId: 0, effectStyleId: 0 };

    walkNodes(j.nodes, (node) => {
      const visible = node.visible !== false;
      if (node.type) nodeTypes[node.type] = (nodeTypes[node.type] || 0) + 1;
      if (node.name) {
        for (const hit of classifyName(node.name)) {
          if (!namePatterns[hit]) namePatterns[hit] = { count: 0, names: {}, apps: new Set(), types: {} };
          namePatterns[hit].count += 1;
          namePatterns[hit].names[node.name] = (namePatterns[hit].names[node.name] || 0) + 1;
          namePatterns[hit].apps.add(s.app);
          namePatterns[hit].types[node.type] = (namePatterns[hit].types[node.type] || 0) + 1;
          const radius = node.cornerRadius > 0 ? round(node.cornerRadius) : 0;
          const heightBucket = node.height ? Math.round(node.height) : '?';
          const fillHex = (node.fills || []).find((f) => f && f.visible !== false && f.type === 'SOLID');
          const fill = fillHex ? normHex(fillHex.hex) || hexFromColor(fillHex.color) : '';
          addToMap(componentGeometry, `${hit}|${s.app}|r=${radius}|h=${heightBucket}|fill=${fill}`, {
            app: s.app,
            screenKey: s.screenKey,
            role: hit,
            detail: node.name,
          });
        }
      }
      if (node.layoutMode) layoutModes[node.layoutMode] = (layoutModes[node.layoutMode] || 0) + 1;
      for (const key of Object.keys(seenStyleRef)) if (node[key]) seenStyleRef[key] += 1;
      if (!visible) return;

      const detail = `${node.type}:${node.name || ''}`;

      for (const fill of node.fills || []) {
        if (!fill || fill.visible === false) continue;
        if (fill.type === 'SOLID') {
          const hex = normHex(fill.hex) || hexFromColor(fill.color);
          const role = node.type === 'TEXT' ? 'text' : 'fill';
          if (hex) {
            addToMap(colorsAll, hex, { app: s.app, screenKey: s.screenKey, role, detail });
            if (role === 'text') addToMap(colorsText, hex, { app: s.app, screenKey: s.screenKey, role, detail });
          }
        } else if (fill.type && fill.type.indexOf('GRADIENT') === 0) {
          addToMap(colorsAll, `GRADIENT:${fill.type}`, { app: s.app, screenKey: s.screenKey, role: 'gradient', detail });
          for (const stop of fill.gradientStops || []) {
            const hex = hexFromColor(stop.color);
            if (hex) addToMap(colorsGradient, hex, { app: s.app, screenKey: s.screenKey, role: 'gradient-stop', detail });
          }
        }
      }

      for (const stroke of node.strokes || []) {
        if (!stroke || stroke.visible === false) continue;
        const hex = stroke.type === 'SOLID' ? normHex(stroke.hex) || hexFromColor(stroke.color) : null;
        if (hex) addToMap(colorsStroke, hex, { app: s.app, screenKey: s.screenKey, role: 'stroke', detail });
        const weight = `${round(node.strokeWeight || 0)}px ${node.strokeAlign || 'INSIDE'}`;
        addToMap(strokes, weight, { app: s.app, screenKey: s.screenKey, role: 'stroke-weight', detail });
      }

      for (const effect of node.effects || []) {
        if (!effect || effect.visible === false) continue;
        const color = effect.color ? rgbaFromColor(effect.color) : 'none';
        const blurType = effect.blurType ? ` ${effect.blurType}` : '';
        const key = `${effect.type}${blurType} x=${round(effect.offset ? effect.offset.x : 0)} y=${round(effect.offset ? effect.offset.y : 0)} blur=${round(effect.radius)} spread=${round(effect.spread || 0)} ${color}`;
        addToMap(effects, key, { app: s.app, screenKey: s.screenKey, role: 'effect', detail });
        const geom = `${effect.type}${blurType} x=${round(effect.offset ? effect.offset.x : 0)} y=${round(effect.offset ? effect.offset.y : 0)} blur=${round(effect.radius)} spread=${round(effect.spread || 0)}`;
        addToMap(effectGeometry, geom, { app: s.app, screenKey: s.screenKey, role: 'effect-geometry', detail });
        if (effect.color) addToMap(colorsEffect, hexFromColor(effect.color), { app: s.app, screenKey: s.screenKey, role: 'effect-color', detail });
      }

      if (typeof node.cornerRadius === 'number' && node.cornerRadius > 0) {
        addToMap(radii, `${round(node.cornerRadius)}`, { app: s.app, screenKey: s.screenKey, role: 'cornerRadius', detail });
      }
      const corners = ['topLeftRadius', 'topRightRadius', 'bottomLeftRadius', 'bottomRightRadius'];
      const cornerVals = corners.map((c) => node[c]).filter((v) => typeof v === 'number');
      if (cornerVals.length) {
        const set = new Set(cornerVals.map(round));
        if (set.size > 1) {
          const key = corners.map((c) => `${c.replace('Radius', '')}=${round(node[c])}`).join(' ');
          addToMap(cornerOverrides, key, { app: s.app, screenKey: s.screenKey, role: 'corner-override', detail });
        } else if (!(node.cornerRadius > 0) && cornerVals[0] > 0) {
          addToMap(radii, `${round(cornerVals[0])}`, { app: s.app, screenKey: s.screenKey, role: 'uniform-corners', detail });
        }
      }

      if (typeof node.itemSpacing === 'number' && node.itemSpacing > 0) {
        addToMap(itemSpacings, `${round(node.itemSpacing)}`, { app: s.app, screenKey: s.screenKey, role: 'itemSpacing', detail });
      }
      if (typeof node.counterAxisSpacing === 'number' && node.counterAxisSpacing > 0) {
        addToMap(itemSpacings, `${round(node.counterAxisSpacing)}`, { app: s.app, screenKey: s.screenKey, role: 'counterAxisSpacing', detail });
      }
      for (const pad of ['paddingLeft', 'paddingRight', 'paddingTop', 'paddingBottom']) {
        if (typeof node[pad] === 'number' && node[pad] > 0) {
          addToMap(paddings, `${round(node[pad])}`, { app: s.app, screenKey: s.screenKey, role: pad, detail });
        }
      }
      if (typeof node.gridRowGap === 'number' && node.gridRowGap > 0) {
        addToMap(gridGaps, `${round(node.gridRowGap)}`, { app: s.app, screenKey: s.screenKey, role: 'gridRowGap', detail });
      }
      if (typeof node.gridColumnGap === 'number' && node.gridColumnGap > 0) {
        addToMap(gridGaps, `${round(node.gridColumnGap)}`, { app: s.app, screenKey: s.screenKey, role: 'gridColumnGap', detail });
      }

      if (node.type === 'TEXT' && node.text) {
        const t = node.text;
        const fam = (t.fontName && t.fontName.family) || 'unknown';
        const style = (t.fontName && t.fontName.style) || 'unknown';
        const weight = t.fontWeight || (t.fontName && t.fontName.variationSettings && t.fontName.variationSettings.wght) || 'unknown';
        const size = typeof t.fontSize === 'number' ? round(t.fontSize) : 'unknown';
        const lh = t.lineHeight && typeof t.lineHeight.value === 'number' ? `${t.lineHeight.unit || 'PIXELS'} ${round(t.lineHeight.value)}` : 'unknown';
        const ls = t.letterSpacing && typeof t.letterSpacing.value === 'number' ? `${t.letterSpacing.unit || 'PIXELS'} ${round(t.letterSpacing.value)}` : 'unknown';
        const fontKey = `${fam} · ${style} · ${weight}`;
        addToMap(fonts, fontKey, { app: s.app, screenKey: s.screenKey, role: 'font', detail });
        addToMap(sizes, `${size}`, { app: s.app, screenKey: s.screenKey, role: 'fontSize', detail });
        addToMap(lineHeights, lh, { app: s.app, screenKey: s.screenKey, role: 'lineHeight', detail });
        addToMap(letterSpacings, ls, { app: s.app, screenKey: s.screenKey, role: 'letterSpacing', detail });
        addToMap(typeCombos, `${fam} ${weight} ${size}/${lh} ls=${ls}`, { app: s.app, screenKey: s.screenKey, role: 'type-combo', detail });
        if (fam !== 'Plus Jakarta Sans') {
          const sample = (t.characters || '').slice(0, 60).replace(/\s+/g, ' ');
          nonDefaultFonts.push({
            app: s.app,
            screen: screenName,
            family: fam,
            style,
            weight,
            size,
            lineHeight: lh,
            letterSpacing: ls,
            characters: sample,
            arabic: /[\u0600-\u06FF]/.test(t.characters || ''),
          });
        }
      }
    });

    for (const key of Object.keys(seenStyleRef)) styleRefs[key] += seenStyleRef[key];

    if (j.assetIndex) {
      const manifestByRef = {};
      for (const a of (manifest && manifest.assets) || []) manifestByRef[a.ref] = a;
      for (const [role, refs] of Object.entries(j.assetIndex.byRole || {})) {
        for (const ref of refs || []) {
          addToMap(assetRoles, role, { app: s.app, screenKey: s.screenKey, role, detail: ref });
          const a = manifestByRef[ref] || {};
          const dim = a.pixelSize && a.pixelSize.width ? `${a.pixelSize.width}x${a.pixelSize.height}` : a.width && a.height ? `${round(a.width)}x${round(a.height)}` : 'unknown';
          addToMap(assetShapes, `${role}|${a.kind || 'unknown'}|${dim}`, { app: s.app, screenKey: s.screenKey, role, detail: ref });
        }
      }
      for (const a of (manifest && manifest.assets) || []) {
        const filePath = a.fileName ? path.join(path.dirname(s.jsonPath), a.fileName) : null;
        if (!filePath || !fs.existsSync(filePath)) continue;
        const bytes = fs.readFileSync(filePath);
        const hash = require('crypto').createHash('sha1').update(bytes).digest('hex');
        const dim = a.pixelSize && a.pixelSize.width ? `${a.pixelSize.width}x${a.pixelSize.height}` : 'unknown';
        addToMap(assetHashes, hash, { app: s.app, screenKey: s.screenKey, role: a.semanticRole, detail: `${a.kind}|${dim}|${a.mime || ''}|${a.nodeName || ''}`.slice(0, 160) });
        if (a.kind === 'raster') {
          rasterAssets.push({
            app: s.app,
            screen: screenName,
            role: a.semanticRole,
            nodeName: (a.nodeName || '').slice(0, 40),
            width: a.pixelSize ? a.pixelSize.width : null,
            height: a.pixelSize ? a.pixelSize.height : null,
            mime: a.mime,
            byteLength: bytes.length,
            ref: a.ref,
          });
        }
      }
    }
  }

  for (const app of APPS) {
    const p = path.join(args.root, 'figma', app.dir, 'package-manifest.json');
    if (!fs.existsSync(p)) continue;
    const pm = JSON.parse(fs.readFileSync(p, 'utf8'));
    packageTotals[app.key] = { screenCount: pm.screenCount, totals: pm.totals };
  }

  const out = {
    generatedAt: new Date().toISOString(),
    root: args.root,
    screenCount: screens.length,
    screens: screenMeta,
    packageTotals,
    colors: {
      all: finalizeMap(colorsAll),
      text: finalizeMap(colorsText),
      stroke: finalizeMap(colorsStroke),
      gradientStops: finalizeMap(colorsGradient),
      effectColors: finalizeMap(colorsEffect),
    },
    typography: {
      fonts: finalizeMap(fonts),
      combos: finalizeMap(typeCombos),
      sizes: finalizeMap(sizes),
      lineHeights: finalizeMap(lineHeights),
      letterSpacings: finalizeMap(letterSpacings),
      nonDefaultFonts,
    },
    radii: { values: finalizeMap(radii), cornerOverrides: finalizeMap(cornerOverrides) },
    spacing: { itemSpacing: finalizeMap(itemSpacings), padding: finalizeMap(paddings), gridGaps: finalizeMap(gridGaps) },
    effects: { values: finalizeMap(effects), geometry: finalizeMap(effectGeometry) },
    strokes: finalizeMap(strokes),
    nodeTypes,
    namePatterns: Object.fromEntries(
      Object.entries(namePatterns).map(([k, v]) => [k, { count: v.count, apps: [...v.apps].sort(), types: v.types, names: v.names }]),
    ),
    assets: {
      roles: finalizeMap(assetRoles),
      shapes: finalizeMap(assetShapes),
      hashes: finalizeMap(assetHashes),
      raster: rasterAssets,
    },
    componentGeometry: finalizeMap(componentGeometry),
    layoutModes,
    styleRefs,
    variableCollections,
    variables,
    warnings,
  };

  const json = JSON.stringify(out, null, 2);
  if (args.out) {
    fs.writeFileSync(args.out, json, 'utf8');
    process.stderr.write(`Wrote ${args.out}\n`);
    process.stderr.write(
      `Screens: ${out.screenCount}; colors: ${out.colors.all.length}; fonts: ${out.typography.fonts.length}; radii: ${out.radii.values.length}; effects: ${out.effects.values.length}\n`,
    );
  } else {
    process.stdout.write(json);
  }
}

main();
