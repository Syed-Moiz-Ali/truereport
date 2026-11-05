# F1 fidelity harness

Non-product tooling for the TrueReport F1 gate (build-plan §8). It compares a
reference image (Figma export crop) with a render and writes measured evidence.
It never claims pixel perfection.

## Prerequisites

| Requirement | Tested version | Notes |
|---|---|---|
| Node.js | v24.11.1 | Node 18+ is enough. No npm install, no native image libraries. |
| Flutter SDK | 3.47.9 / Dart 3.13.7 | Only needed to run the Flutter capture test. |
| Chromium/Chrome | optional | Only for the public-report scaffold in `chromium/`. |

The PNG decoder/encoder, SSIM, RMSE, CIEDE2000 and connected-component diff code
are dependency-free in `lib/`. Everything is computed from the two images; no
metric is estimated.

## Commands (run from the repository root)

```powershell
# 1. Generate the deterministic synthetic pairs and lint fixtures.
node tools/figma_fidelity/make-synthetic.mjs

# 2. Prove the metric path, gate and deny-list.
node tools/figma_fidelity/compare.mjs --fixture docs/ui/figma/fidelity/fixtures/synthetic/synthetic-clean.json --threshold-ssim 0.98
node tools/figma_fidelity/compare.mjs --fixture docs/ui/figma/fidelity/fixtures/synthetic/synthetic-degraded.json --threshold-ssim 0.98
node tools/figma_fidelity/compare.mjs --fixture docs/ui/figma/fidelity/fixtures/forbidden/bad-string.json --threshold-ssim 0.98
node tools/figma_fidelity/compare.mjs --fixture docs/ui/figma/fidelity/fixtures/forbidden/safe-string.json --threshold-ssim 0.98

# 3. Capture component samples (writes render.png, geometry.json, strings.json).
cd client/packages/design_system
flutter test test/fidelity_capture_test.dart
cd ../../..

# 4. Compare each component sample.
node tools/figma_fidelity/compare.mjs --fixture docs/ui/figma/fidelity/fixtures/component-samples/primary-button-en-light-1x.json --threshold-ssim 0.98
node tools/figma_fidelity/compare.mjs --fixture docs/ui/figma/fidelity/fixtures/component-samples/delivery-status-card-en-light-1x.json --threshold-ssim 0.98
node tools/figma_fidelity/compare.mjs --fixture docs/ui/figma/fidelity/fixtures/component-samples/inspection-result-selector-en-light-1x.json --threshold-ssim 0.98
```

If a render is not ready yet, `--prepare-only` writes just the cropped
`figma.png` and a `PENDING` report.

## CLI

```
node tools/figma_fidelity/compare.mjs --fixture <fixture.json> [options]
  --out <dir>              artifact directory (fixture.output is the default)
  --threshold-ssim <n>     gate threshold, default 0.98
  --tile-size <n>          SSIM tile size, default 64
  --de-threshold <n>       ΔE2000 box threshold, default 5
  --min-area <n>           minimum connected area in px, default 16
  --prepare-only           emit the reference crop without a render
```

Exit codes: `0` gate passed, `1` gate failed, `2` input/runtime error.

The gate requires **all** of:

1. global SSIM ≥ `--threshold-ssim`;
2. every declared key box within `keyBoxTolerance` logical px of the captured
   `geometry.json`;
3. every `expectedStrings` entry present in `strings.json` (or
   `actualStrings`);
4. zero forbidden-term matches.

## Fixture schema

```json
{
  "id": "primary-button-en-light-1x",
  "batch": "f1-component-samples",
  "renderer": "flutter",
  "reference": "docs/ui/figma-export/...@2x.png",
  "crop": { "x": 0, "y": 880, "width": 780, "height": 240 },
  "logicalWidth": 390,
  "logicalHeight": 120,
  "dpr": 2,
  "render": "docs/ui/figma/fidelity/component-samples/.../render.png",
  "output": "docs/ui/figma/fidelity/component-samples/...",
  "expectedStrings": ["Continue"],
  "keyBoxes": [
    { "key": "primary-button", "x": 24, "y": 32, "width": 342, "height": 56 }
  ],
  "keyBoxTolerance": 2,
  "forbiddenTermsFile": "docs/ui/figma/fidelity/forbidden-terms.json",
  "thresholdSsim": 0.98
}
```

- `crop` is in **reference pixels** (Figma previews are `@2x`). Omit it to use
  the full image.
- Both images are composited over white and normalised to
  `logicalWidth × dpr` by `logicalHeight × dpr` before measurement.
- `strings.json` and `geometry.json` are read from the output directory when
  present; `actualStrings` / `actualBoxes` in the fixture are also accepted
  (used by the synthetic fixtures).
- `forbiddenTermsFile` defaults to
  `docs/ui/figma/fidelity/forbidden-terms.json`.

## Artifacts per sample

| File | Contents |
|---|---|
| `figma.png` | cropped reference, normalised to the render pixel grid |
| `render.png` | render, normalised to the same pixel grid |
| `side-by-side.png` | reference left, render right |
| `diff.png` | ΔE2000 heatmap over a dimmed render |
| `metrics.json` | SSIM global + 64×64 tiles, RMSE/MAE, ΔE2000 stats, diff boxes, key boxes, text, deny-list, gate |
| `REPORT.md` | human summary with residuals, owner and date |

## Metric definitions

- **SSIM** — 11×11 Gaussian window (σ 1.5) on sRGB luminance; global value is
  the mean of the SSIM map; tiles are the mean over each 64×64 block.
- **RMSE / MAE** — RGB channels in 0–255.
- **ΔE2000** — sRGB → linear → XYZ D65 → CIELAB, pairwise CIEDE2000 per pixel;
  reports mean, median, p95, p99, max and % > 2 / > 5 / > 10.
- **Diff boxes** — 4-connected components of pixels with ΔE2000 > 5 (area ≥ 16
  px), largest first, coordinates also given in logical px.

## Forbidden-term lint

`docs/ui/figma/fidelity/forbidden-terms.json` is the deny-list. Terms are
whole-word and case-insensitive; patterns cover a 17-character VIN, email
address, GPS coordinate pair and PSI value. It is applied to the captured
strings (and `lintText` if a fixture supplies it). A match fails the gate.

## Chromium capture scaffold

See `chromium/README.md`. F1 only validates Flutter component samples; the
public-report renderer is not built here and no real screen is created.
