#!/usr/bin/env node
/**
 * Generates deterministic synthetic image pairs used to validate the harness
 * itself (metrics maths, gate behaviour and forbidden-term lint).
 *
 * Run from the repository root:
 *   node tools/figma_fidelity/make-synthetic.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { encodePng, makeImage, fillRect } from './lib/png.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(HERE, '..', '..');
const FIDELITY = path.join(REPO_ROOT, 'docs', 'ui', 'figma', 'fidelity');

const WIDTH = 780;
const HEIGHT = 240;

function baseImage() {
  const image = makeImage(WIDTH, HEIGHT, [250, 249, 254, 255]);
  fillRect(image, { x: 48, y: 64, width: 684, height: 112 }, [16, 185, 129, 255]);
  fillRect(image, { x: 72, y: 92, width: 280, height: 24 }, [26, 27, 31, 255]);
  fillRect(image, { x: 72, y: 128, width: 180, height: 14 }, [26, 27, 31, 255]);
  fillRect(image, { x: 560, y: 104, width: 132, height: 32 }, [217, 251, 232, 255]);
  return image;
}

function degradedImage() {
  const image = baseImage();
  fillRect(image, { x: 64, y: 64, width: 120, height: 24 }, [230, 243, 236, 255]);
  fillRect(image, { x: 520, y: 150, width: 90, height: 18 }, [0, 108, 73, 255]);
  for (let y = 0; y < HEIGHT; y += 1) {
    for (let x = 0; x < WIDTH; x += 1) {
      const i = (y * WIDTH + x) * 4;
      const noise = ((x * 13 + y * 7) % 9) - 4;
      image.data[i] = Math.max(0, Math.min(255, image.data[i] + noise));
      image.data[i + 1] = Math.max(0, Math.min(255, image.data[i + 1] + noise));
      image.data[i + 2] = Math.max(0, Math.min(255, image.data[i + 2] + noise));
    }
  }
  return image;
}

function writePair(relativeDir, renderImage) {
  const dir = path.join(FIDELITY, relativeDir);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'reference.png'), encodePng(baseImage()));
  fs.writeFileSync(path.join(dir, 'render.png'), encodePng(renderImage));
  return dir;
}

const cleanDir = writePair('synthetic/synthetic-clean', baseImage());
const degradedDir = writePair('synthetic/synthetic-degraded', degradedImage());
const badDir = writePair('lint/bad', baseImage());
const safeDir = writePair('lint/safe', baseImage());

function writeFixture(relativeDir, body) {
  const file = path.join(FIDELITY, 'fixtures', relativeDir);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(body, null, 2)}\n`);
  return file;
}

const common = {
  batch: 'synthetic',
  logicalWidth: 390,
  logicalHeight: 120,
  dpr: 2,
  renderer: 'synthetic',
  keyBoxes: [],
  keyBoxTolerance: 2,
  forbiddenTermsFile: 'docs/ui/figma/fidelity/forbidden-terms.json',
};

writeFixture('synthetic/synthetic-clean.json', {
  ...common,
  id: 'synthetic-clean',
  name: 'Synthetic clean pair (identical images)',
  reference: 'docs/ui/figma/fidelity/synthetic/synthetic-clean/reference.png',
  render: 'docs/ui/figma/fidelity/synthetic/synthetic-clean/render.png',
  output: 'docs/ui/figma/fidelity/synthetic/synthetic-clean',
  expectedStrings: ['Continue'],
  actualStrings: ['Continue'],
  thresholdSsim: 0.98,
  residualNotes: 'Reference and render are the same generated image; this validates the metric code path, not a UI.',
});

writeFixture('synthetic/synthetic-degraded.json', {
  ...common,
  id: 'synthetic-degraded',
  name: 'Synthetic degraded pair (known noise + colour shift)',
  reference: 'docs/ui/figma/fidelity/synthetic/synthetic-degraded/reference.png',
  render: 'docs/ui/figma/fidelity/synthetic/synthetic-degraded/render.png',
  output: 'docs/ui/figma/fidelity/synthetic/synthetic-degraded',
  expectedStrings: ['Continue'],
  actualStrings: ['Continue'],
  thresholdSsim: 0.98,
  residualNotes: 'Deterministic degradation used to prove the gate fails and the diff boxes are reported.',
});

writeFixture('forbidden/bad-string.json', {
  ...common,
  id: 'forbidden-bad-string',
  name: 'Forbidden-term proof — bad string',
  reference: 'docs/ui/figma/fidelity/lint/bad/reference.png',
  render: 'docs/ui/figma/fidelity/lint/bad/render.png',
  output: 'docs/ui/figma/fidelity/lint/bad',
  expectedStrings: [],
  actualStrings: ['Certified inspection report', 'Verified score 98'],
  thresholdSsim: 0.98,
  residualNotes: 'Images are identical; the gate must fail only because the deny-list matched.',
});

writeFixture('forbidden/safe-string.json', {
  ...common,
  id: 'forbidden-safe-string',
  name: 'Forbidden-term proof — safe string',
  reference: 'docs/ui/figma/fidelity/lint/safe/reference.png',
  render: 'docs/ui/figma/fidelity/lint/safe/render.png',
  output: 'docs/ui/figma/fidelity/lint/safe',
  expectedStrings: ['No issue observed'],
  actualStrings: ['No issue observed'],
  thresholdSsim: 0.98,
  residualNotes: 'Images are identical and the strings contain no deny-listed term.',
});

console.log(
  `[fidelity] synthetic fixtures written: ${[
    cleanDir,
    degradedDir,
    badDir,
    safeDir,
  ]
    .map((d) => path.relative(REPO_ROOT, d))
    .join(', ')}`,
);
