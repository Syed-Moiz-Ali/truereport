# Fidelity report — f2a1-equipment-figma-text

- **Sample id:** `f2a1-equipment-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/equipment-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/06_6._Equipment_Checklist/6._Equipment_Checklist@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":1820}
- **Logical size:** 390 × 910 @ DPR 2
- **Compared pixels:** 780 × 1820
- **Generated:** 2026-11-07T21:24:24.804Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98786; min 64×64 tile 0.86643 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98786 |
| SSIM (worst 64×64 tile) | 0.86643 |
| RMSE (RGB 0–255) | 8.584 |
| MAE (RGB 0–255) | 1.382 |
| ΔE2000 mean | 0.454 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.507 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 3.03% |
| ΔE2000 > 5 | 1.66% |
| ΔE2000 > 10 | 1.05% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 343 | 85.5 | 11 | 7 | 120 |
| 2 | 54.5 | 719.5 | 12.5 | 17 | 110 |
| 3 | 76 | 136.5 | 6.5 | 14.5 | 108 |
| 4 | 221 | 835.5 | 13.5 | 13 | 108 |
| 5 | 328 | 271.5 | 12 | 9 | 106 |
| 6 | 68.5 | 136.5 | 7 | 14 | 104 |
| 7 | 55 | 136.5 | 12.5 | 20 | 100 |
| 8 | 153 | 136.5 | 12.5 | 20 | 100 |
| 9 | 136 | 131.5 | 13.5 | 19.5 | 98 |
| 10 | 21 | 131.5 | 8.5 | 19.5 | 93 |
| 11 | 166.5 | 136.5 | 5.5 | 12.5 | 92 |
| 12 | 175.5 | 136.5 | 5 | 14.5 | 85 |
| 13 | 117.5 | 131 | 12.5 | 20 | 83 |
| 14 | 26 | 83 | 6.5 | 7 | 75 |
| 15 | 34 | 83 | 3.5 | 9 | 71 |
| 16 | 243.5 | 136.5 | 5 | 14.5 | 69 |
| 17 | 84 | 136.5 | 4.5 | 14.5 | 65 |
| 18 | 182 | 136.5 | 4.5 | 14.5 | 65 |
| 19 | 144 | 29 | 3 | 10 | 63 |
| 20 | 98 | 29.5 | 8 | 13.5 | 62 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `01`, `PRE-INSPECTION SETUP`, `1 of 4 Verified`, `Required Equipment`, `Ensure all diagnostic hardware is calibrated and
paired before launching bay intake.`, `Tire Depth Gauge`, `Digital laser calibration · Ready`, `OBD Scanner`, `Bluetooth module v4.2 · Tap to
verify`, `Torque Wrench`, `Preset 120-140 Nm · Mechanical`, `Paint Depth Gauge`, `Fe / NFe substrate probe`, `Fleet Station Standards`, `ISO-9001 certified diagnostic requirements`, `Proceed`, `Diagnostic Checklist`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

