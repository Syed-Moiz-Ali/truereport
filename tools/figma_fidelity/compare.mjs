#!/usr/bin/env node
/**
 * F1 fidelity comparison tool.
 *
 * Usage (from the repository root):
 *   node tools/figma_fidelity/compare.mjs \
 *     --fixture docs/ui/figma/fidelity/fixtures/component-samples/primary-button-en-light-1x.json \
 *     --threshold-ssim 0.98
 *
 * Exit codes: 0 = gate passed, 1 = gate failed, 2 = input/runtime error.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  decodePng,
  encodePng,
  cropImage,
  resizeBilinear,
  compositeOverWhite,
} from './lib/png.mjs';
import {
  ssim,
  rmseAndMae,
  deltaE2000,
  diffBoxes,
  makeDiffImage,
} from './lib/metrics.mjs';
import { loadDenyList, lintStrings } from './lib/lint.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const [key, inline] = token.slice(2).split('=');
    if (inline !== undefined) {
      args[key] = inline;
    } else if (argv[i + 1] && !argv[i + 1].startsWith('--')) {
      args[key] = argv[i + 1];
      i += 1;
    } else {
      args[key] = true;
    }
  }
  return args;
}

function findRepoRoot(start) {
  let dir = path.resolve(start);
  for (;;) {
    if (
      fs.existsSync(path.join(dir, 'docs', 'ui', 'figma')) &&
      fs.existsSync(path.join(dir, 'client'))
    ) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) throw new Error('Could not locate repository root (docs/ui/figma + client)');
    dir = parent;
  }
}

function resolveFrom(base, p) {
  return path.isAbsolute(p) ? p : path.resolve(base, p);
}

function fmt(value, digits = 4) {
  if (!Number.isFinite(value)) return String(value);
  return Number(value.toFixed(digits)).toString();
}

function readJsonIfExists(file) {
  if (!fs.existsSync(file)) return null;
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function extractStrings(outDir, fixture) {
  if (Array.isArray(fixture.actualStrings)) return fixture.actualStrings.slice();
  const fromFile = readJsonIfExists(path.join(outDir, 'strings.json'));
  if (Array.isArray(fromFile)) return fromFile;
  if (fromFile && Array.isArray(fromFile.strings)) return fromFile.strings;
  return null;
}

function extractGeometry(outDir, fixture) {
  if (fixture.actualBoxes && typeof fixture.actualBoxes === 'object') return fixture.actualBoxes;
  const data = readJsonIfExists(path.join(outDir, 'geometry.json'));
  if (!data) return null;
  return data.boxes ?? data;
}

function blit(target, source, x, y) {
  for (let row = 0; row < source.height; row += 1) {
    const ty = y + row;
    if (ty < 0 || ty >= target.height) continue;
    const srcStart = row * source.width * 4;
    const dstStart = (ty * target.width + x) * 4;
    target.data.set(source.data.subarray(srcStart, srcStart + source.width * 4), dstStart);
  }
}

function writeReport(ctx, outDir) {
  const { fixture, ssimResult, rmse, deltaE, boxes, geometry, strings, lint, gate, target } = ctx;
  const lines = [];
  lines.push(`# Fidelity report — ${fixture.name ?? fixture.id}`);
  lines.push('');
  lines.push(`- **Sample id:** \`${fixture.id}\``);
  lines.push(`- **Batch:** \`${fixture.batch ?? 'unassigned'}\``);
  lines.push(`- **Renderer:** \`${fixture.renderer ?? 'unknown'}\``);
  lines.push(`- **Fixture:** \`${ctx.fixturePath}\``);
  lines.push(`- **Reference:** \`${fixture.reference}\``);
  if (fixture.crop) lines.push(`- **Reference crop (px):** ${JSON.stringify(fixture.crop)}`);
  lines.push(`- **Logical size:** ${fixture.logicalWidth} × ${fixture.logicalHeight} @ DPR ${target.dpr}`);
  lines.push(`- **Compared pixels:** ${target.width} × ${target.height}`);
  lines.push(`- **Generated:** ${ctx.generatedAt}`);
  lines.push(`- **Owner:** ${fixture.owner ?? 'harness-engineer'}`);
  lines.push('');
  lines.push('## Gate');
  lines.push('');
  lines.push(`**${gate.pass ? 'PASS' : 'FAIL'}** — SSIM threshold ${gate.thresholdSsim}.`);
  lines.push('');
  lines.push('| Check | Result | Detail |');
  lines.push('|---|---|---|');
  lines.push(`| SSIM | ${gate.ssim ? 'pass' : 'fail'} | global ${fmt(ssimResult.global, 5)}; min 64×64 tile ${fmt(ssimResult.minTile, 5)} |`);
  lines.push(`| Text | ${gate.strings ? 'pass' : 'fail'} | ${strings.detail} |`);
  lines.push(`| Forbidden terms | ${gate.forbidden ? 'pass' : 'fail'} | ${lint.matches.length} match(es) |`);
  lines.push(`| Key boxes | ${gate.geometry ? 'pass' : 'fail'} | ${geometry.detail} |`);
  lines.push('');
  lines.push('## Measured metrics');
  lines.push('');
  lines.push('| Metric | Value |');
  lines.push('|---|---|');
  lines.push(`| SSIM (global) | ${fmt(ssimResult.global, 5)} |`);
  lines.push(`| SSIM (worst 64×64 tile) | ${fmt(ssimResult.minTile, 5)} |`);
  lines.push(`| RMSE (RGB 0–255) | ${fmt(rmse.rmse, 3)} |`);
  lines.push(`| MAE (RGB 0–255) | ${fmt(rmse.mae, 3)} |`);
  lines.push(`| ΔE2000 mean | ${fmt(deltaE.mean, 3)} |`);
  lines.push(`| ΔE2000 median | ${fmt(deltaE.median, 3)} |`);
  lines.push(`| ΔE2000 p95 | ${fmt(deltaE.p95, 3)} |`);
  lines.push(`| ΔE2000 max | ${fmt(deltaE.max, 3)} |`);
  lines.push(`| ΔE2000 > 2 (JND) | ${fmt(deltaE.percentOver2, 2)}% |`);
  lines.push(`| ΔE2000 > 5 | ${fmt(deltaE.percentOver5, 2)}% |`);
  lines.push(`| ΔE2000 > 10 | ${fmt(deltaE.percentOver10, 2)}% |`);
  lines.push('');
  lines.push('## Diff bounding boxes (ΔE2000 > 5)');
  lines.push('');
  if (boxes.length === 0) {
    lines.push('None above the threshold (minimum area 16 px).');
  } else {
    lines.push('| # | logical x | logical y | logical w | logical h | area (px) |');
    lines.push('|---:|---:|---:|---:|---:|---:|');
    boxes.forEach((box, index) => {
      lines.push(
        `| ${index + 1} | ${fmt(box.logical.x, 1)} | ${fmt(box.logical.y, 1)} | ${fmt(box.logical.width, 1)} | ${fmt(box.logical.height, 1)} | ${box.area} |`,
      );
    });
  }
  lines.push('');
  lines.push('## Key-box geometry');
  lines.push('');
  if (!geometry.expected.length) {
    lines.push('No key boxes declared for this sample.');
  } else {
    lines.push('| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |');
    lines.push('|---|---|---|---:|---|');
    for (const row of geometry.rows) {
      const exp = row.expected
        ? `${fmt(row.expected.x, 1)}, ${fmt(row.expected.y, 1)}, ${fmt(row.expected.width, 1)}, ${fmt(row.expected.height, 1)}`
        : '—';
      const act = row.actual
        ? `${fmt(row.actual.x, 1)}, ${fmt(row.actual.y, 1)}, ${fmt(row.actual.width, 1)}, ${fmt(row.actual.height, 1)}`
        : '—';
      lines.push(`| \`${row.key}\` | ${exp} | ${act} | ${row.delta === null ? '—' : fmt(row.delta, 2)} | ${row.pass ? 'pass' : 'fail'} |`);
    }
  }
  lines.push('');
  lines.push('## Text');
  lines.push('');
  lines.push(`- Expected: ${strings.expected.length ? strings.expected.map((s) => `\`${s}\``).join(', ') : '—'}`);
  lines.push(`- Actual: ${strings.actual ? strings.actual.map((s) => `\`${s}\``).join(', ') || '—' : 'not captured'}`);
  if (strings.missing.length) lines.push(`- Missing: ${strings.missing.map((s) => `\`${s}\``).join(', ')}`);
  if (lint.matches.length) {
    lines.push('');
    lines.push('### Forbidden-term matches');
    lines.push('');
    for (const match of lint.matches) {
      lines.push(`- **${match.id}** (${match.kind}) matched \`${match.match}\`: ${match.context}`);
    }
  }
  lines.push('');
  lines.push('## Artifacts');
  lines.push('');
  lines.push('- `figma.png` — cropped reference, normalised to the render pixel grid');
  lines.push('- `render.png` — render, normalised to the same pixel grid');
  lines.push('- `side-by-side.png` — reference (left), render (right)');
  lines.push('- `diff.png` — ΔE2000 heatmap over a dimmed render');
  lines.push('- `metrics.json` — machine-readable metrics');
  lines.push('');
  lines.push('## Residuals / notes');
  lines.push('');
  lines.push(fixture.residualNotes ?? 'Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.');
  lines.push('');
  fs.writeFileSync(path.join(outDir, 'REPORT.md'), `${lines.join('\n')}\n`);
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(
      'Usage: node tools/figma_fidelity/compare.mjs --fixture <fixture.json> [--out <dir>] [--threshold-ssim 0.98] [--prepare-only]',
    );
    return 0;
  }
  if (!args.fixture) throw new Error('Missing --fixture');

  const repoRoot = findRepoRoot(process.cwd());
  const fixturePath = resolveFrom(process.cwd(), args.fixture);
  const fixture = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));
  const outDir = resolveFrom(
    process.cwd(),
    args.out ?? fixture.output ?? `docs/ui/figma/fidelity/samples/${fixture.id}`,
  );
  fs.mkdirSync(outDir, { recursive: true });

  const referencePath = resolveFrom(repoRoot, fixture.reference);
  if (!fs.existsSync(referencePath)) throw new Error(`Reference not found: ${referencePath}`);
  const rawReference = decodePng(fs.readFileSync(referencePath));
  const cropped = fixture.crop ? cropImage(rawReference, fixture.crop) : rawReference;

  const dpr = fixture.dpr ?? 2;
  const target = {
    width: Math.round(fixture.logicalWidth * dpr),
    height: Math.round(fixture.logicalHeight * dpr),
    dpr,
  };
  const referenceImage = compositeOverWhite(resizeBilinear(cropped, target.width, target.height));
  fs.writeFileSync(path.join(outDir, 'figma.png'), encodePng(referenceImage));

  const renderPath = resolveFrom(repoRoot, fixture.render);
  if (!fs.existsSync(renderPath)) {
    fs.writeFileSync(
      path.join(outDir, 'metrics.json'),
      `${JSON.stringify(
        {
          sample: fixture.id,
          status: 'pending-render',
          render: fixture.render,
          message: 'render.png not found; reference crop prepared only',
        },
        null,
        2,
      )}\n`,
    );
    fs.writeFileSync(
      path.join(outDir, 'REPORT.md'),
      `# Fidelity report — ${fixture.id}\n\n**PENDING** — \`${fixture.render}\` does not exist yet. The reference crop is available at \`figma.png\`.\n`,
    );
    if (args['prepare-only']) {
      console.log(`[fidelity] prepared ${fixture.id} (pending render)`);
      return 0;
    }
    throw new Error(`Render not found: ${renderPath} (use --prepare-only to emit just figma.png)`);
  }

  const rawRender = decodePng(fs.readFileSync(renderPath));
  const renderImage = compositeOverWhite(resizeBilinear(rawRender, target.width, target.height));
  fs.writeFileSync(path.join(outDir, 'render.png'), encodePng(renderImage));

  const ssimResult = ssim(referenceImage, renderImage, Number(args['tile-size'] ?? 64));
  const rmse = rmseAndMae(referenceImage, renderImage);
  const deltaE = deltaE2000(referenceImage, renderImage);
  const boxes = diffBoxes(referenceImage, renderImage, deltaE.values, {
    threshold: Number(args['de-threshold'] ?? 5),
    minArea: Number(args['min-area'] ?? 16),
  }).map((box) => ({
    ...box,
    logical: {
      x: box.x / dpr,
      y: box.y / dpr,
      width: box.width / dpr,
      height: box.height / dpr,
    },
  }));

  const diffImage = makeDiffImage(renderImage, deltaE.values);
  fs.writeFileSync(path.join(outDir, 'diff.png'), encodePng(diffImage));

  const gutter = 32;
  const sideBySide = {
    width: target.width * 2 + gutter,
    height: target.height,
    data: new Uint8ClampedArray((target.width * 2 + gutter) * target.height * 4).fill(255),
  };
  blit(sideBySide, referenceImage, 0, 0);
  blit(sideBySide, renderImage, target.width + gutter, 0);
  fs.writeFileSync(path.join(outDir, 'side-by-side.png'), encodePng(sideBySide));

  const expectedStrings = fixture.expectedStrings ?? [];
  const actualStrings = extractStrings(outDir, fixture);
  const missing = actualStrings
    ? expectedStrings.filter((s) => !actualStrings.includes(s))
    : expectedStrings.slice();
  const stringsPass = expectedStrings.length === 0 || (actualStrings !== null && missing.length === 0);
  const strings = {
    expected: expectedStrings,
    actual: actualStrings,
    missing,
    pass: stringsPass,
    detail: actualStrings === null
      ? 'no strings.json captured'
      : missing.length === 0
        ? `${expectedStrings.length} expected string(s) present`
        : `${missing.length} missing`,
  };

  const denyListPath = resolveFrom(
    repoRoot,
    fixture.forbiddenTermsFile ?? 'docs/ui/figma/fidelity/forbidden-terms.json',
  );
  const denyList = loadDenyList(denyListPath);
  const lint = lintStrings(
    [...(actualStrings ?? []), ...(fixture.lintText ? [fixture.lintText] : [])],
    denyList,
  );

  const expectedBoxes = fixture.keyBoxes ?? [];
  const actualBoxes = extractGeometry(outDir, fixture);
  const tolerance = fixture.keyBoxTolerance ?? 2;
  const geometryRows = expectedBoxes.map((expected) => {
    const actual = actualBoxes?.[expected.key] ?? null;
    if (!actual) {
      return { key: expected.key, expected, actual: null, delta: null, pass: false };
    }
    const delta = Math.max(
      Math.abs(actual.x - expected.x),
      Math.abs(actual.y - expected.y),
      Math.abs(actual.width - expected.width),
      Math.abs(actual.height - expected.height),
    );
    return { key: expected.key, expected, actual, delta, pass: delta <= tolerance };
  });
  const geometryPass = expectedBoxes.length === 0
    ? true
    : actualBoxes !== null && geometryRows.every((row) => row.pass);
  const geometry = {
    expected: expectedBoxes,
    actual: actualBoxes,
    rows: geometryRows,
    tolerance,
    pass: geometryPass,
    detail: expectedBoxes.length === 0
      ? 'no key boxes declared'
      : actualBoxes === null
        ? 'geometry.json not captured'
        : `${geometryRows.filter((r) => r.pass).length}/${geometryRows.length} within ${tolerance} logical px`,
  };

  const thresholdSsim = Number(args['threshold-ssim'] ?? fixture.thresholdSsim ?? 0.98);
  const gate = {
    thresholdSsim,
    ssim: ssimResult.global >= thresholdSsim,
    strings: strings.pass,
    forbidden: lint.matches.length === 0,
    geometry: geometry.pass,
  };
  gate.pass = gate.ssim && gate.strings && gate.forbidden && gate.geometry;

  const generatedAt = new Date().toISOString();
  const metrics = {
    sample: fixture.id,
    name: fixture.name ?? fixture.id,
    batch: fixture.batch ?? null,
    renderer: fixture.renderer ?? null,
    fixture: path.relative(repoRoot, fixturePath).split(path.sep).join('/'),
    reference: fixture.reference,
    crop: fixture.crop ?? null,
    logical: { width: fixture.logicalWidth, height: fixture.logicalHeight, dpr },
    comparedPixels: { width: target.width, height: target.height },
    generatedAt,
    ssim: {
      global: ssimResult.global,
      minTile: ssimResult.minTile,
      tileSize: Number(args['tile-size'] ?? 64),
      tiles: ssimResult.tiles,
    },
    rmse,
    deltaE2000: {
      mean: deltaE.mean,
      median: deltaE.median,
      p95: deltaE.p95,
      p99: deltaE.p99,
      max: deltaE.max,
      percentOver2: deltaE.percentOver2,
      percentOver5: deltaE.percentOver5,
      percentOver10: deltaE.percentOver10,
    },
    diffBoxes: boxes,
    keyBoxes: {
      tolerance,
      rows: geometryRows,
      pass: geometryPass,
    },
    text: {
      expected: strings.expected,
      actual: strings.actual,
      missing,
      pass: strings.pass,
    },
    forbiddenTerms: {
      denyList: path.relative(repoRoot, denyListPath).split(path.sep).join('/'),
      matches: lint.matches,
      pass: lint.matches.length === 0,
    },
    gate,
    note: 'All metrics are computed from the two normalised images. No pixel-perfect claim is made.',
  };
  fs.writeFileSync(path.join(outDir, 'metrics.json'), `${JSON.stringify(metrics, null, 2)}\n`);

  writeReport(
    {
      fixture,
      fixturePath: path.relative(repoRoot, fixturePath).split(path.sep).join('/'),
      ssimResult,
      rmse,
      deltaE,
      boxes,
      geometry,
      strings,
      lint,
      gate,
      target,
      generatedAt,
    },
    outDir,
  );

  console.log(
    `[fidelity] ${fixture.id}: SSIM ${fmt(ssimResult.global, 5)} (min tile ${fmt(ssimResult.minTile, 5)}), ` +
      `RMSE ${fmt(rmse.rmse, 3)}, ΔE>5 ${fmt(deltaE.percentOver5, 2)}%, ` +
      `diff boxes ${boxes.length}, ${gate.pass ? 'PASS' : 'FAIL'} -> ${path.relative(repoRoot, outDir)}`,
  );
  return gate.pass ? 0 : 1;
}

try {
  process.exitCode = main();
} catch (error) {
  console.error(`[fidelity] error: ${error.message}`);
  process.exitCode = 2;
}
