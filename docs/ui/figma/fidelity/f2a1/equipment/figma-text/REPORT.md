# Fidelity report — f2a1-equipment-figma-text

- **Sample id:** `f2a1-equipment-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/equipment-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/06_6._Equipment_Checklist/6._Equipment_Checklist@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":1820}
- **Logical size:** 390 × 910 @ DPR 2
- **Compared pixels:** 780 × 1820
- **Generated:** 2026-11-06T04:36:12.157Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.93352; min 64×64 tile 0.2307 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.93352 |
| SSIM (worst 64×64 tile) | 0.2307 |
| RMSE (RGB 0–255) | 23.893 |
| MAE (RGB 0–255) | 4.473 |
| ΔE2000 mean | 1.464 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 3.584 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 7.32% |
| ΔE2000 > 5 | 3.42% |
| ΔE2000 > 10 | 2.77% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 144.5 | 25 | 71.5 | 14.5 | 2088 |
| 2 | 314.5 | 267 | 39 | 32 | 1412 |
| 3 | 153 | 722 | 58 | 11 | 1357 |
| 4 | 137 | 185 | 43 | 14.5 | 1110 |
| 5 | 105 | 25.5 | 38 | 14 | 1077 |
| 6 | 117.5 | 362 | 23 | 21 | 1055 |
| 7 | 53 | 719.5 | 14 | 25.5 | 963 |
| 8 | 104.5 | 361.5 | 13 | 38 | 776 |
| 9 | 81.5 | 29 | 24 | 14 | 747 |
| 10 | 218.5 | 185 | 35 | 11.5 | 719 |
| 11 | 126 | 722 | 27.5 | 11 | 694 |
| 12 | 97 | 722 | 23 | 11 | 579 |
| 13 | 65 | 25.5 | 15.5 | 13.5 | 574 |
| 14 | 220 | 27 | 19.5 | 12.5 | 571 |
| 15 | 149.5 | 740 | 29.5 | 10.5 | 533 |
| 16 | 53 | 483 | 22 | 22 | 503 |
| 17 | 140 | 361.5 | 13 | 21.5 | 469 |
| 18 | 189.5 | 188 | 20 | 11 | 453 |
| 19 | 55 | 587 | 18 | 22 | 448 |
| 20 | 113.5 | 185 | 19.5 | 11.5 | 429 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `01`, `PRE-INSPECTION SETUP`, `1 of 4 Verified`, `Required Equipment`, `Ensure all diagnostic hardware is calibrated and paired before starting the inspection.`, `Tire Depth Gauge`, `Digital laser calibration · Ready`, `OBD Scanner`, `Bluetooth module v4.2 · Tap to verify`, `Torque Wrench`, `Preset 120-140 Nm · Mechanical`, `Paint Depth Gauge`, `Fe / NFe substrate probe`, `Fleet Station Standards`, `ISO-9001 certified diagnostic requirements`, `Proceed`, `Diagnostic Checklist`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

