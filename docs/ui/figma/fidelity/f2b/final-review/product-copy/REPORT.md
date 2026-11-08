# Fidelity report — f2b-final-review-product-copy

- **Sample id:** `f2b-final-review-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/final-review-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/12_13._Final_Review_(Missing_Items)/13._Final_Review_(Missing_Items)@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2016}
- **Logical size:** 390 × 1008 @ DPR 2
- **Compared pixels:** 780 × 2016
- **Generated:** 2026-11-08T08:34:06.027Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.85.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.87653; min 64×64 tile 0.05495 |
| Text | pass | 11 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.87653 |
| SSIM (worst 64×64 tile) | 0.05495 |
| RMSE (RGB 0–255) | 31.068 |
| MAE (RGB 0–255) | 8.124 |
| ΔE2000 mean | 2.435 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 8.874 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 14.27% |
| ΔE2000 > 5 | 5.77% |
| ΔE2000 > 10 | 4.62% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 100 | 289.5 | 56 | 50.5 | 8760 |
| 2 | 71.5 | 25.5 | 72.5 | 17.5 | 2249 |
| 3 | 171.5 | 227.5 | 46.5 | 16 | 1281 |
| 4 | 139.5 | 109 | 26 | 20.5 | 1192 |
| 5 | 184 | 114.5 | 32 | 20.5 | 1184 |
| 6 | 35 | 390 | 48.5 | 9.5 | 1086 |
| 7 | 163.5 | 143 | 39.5 | 14 | 897 |
| 8 | 162 | 937.5 | 44 | 9 | 823 |
| 9 | 54 | 143 | 37 | 11.5 | 818 |
| 10 | 204.5 | 143 | 35 | 11.5 | 805 |
| 11 | 127 | 227.5 | 30.5 | 13 | 749 |
| 12 | 104 | 569 | 34.5 | 11.5 | 736 |
| 13 | 136 | 146 | 27 | 11 | 612 |
| 14 | 29 | 143 | 24 | 11.5 | 583 |
| 15 | 234 | 114.5 | 14.5 | 15 | 581 |
| 16 | 309 | 784.5 | 26.5 | 11 | 528 |
| 17 | 142.5 | 762 | 15 | 24.5 | 516 |
| 18 | 114.5 | 672.5 | 25 | 11.5 | 505 |
| 19 | 221.5 | 115 | 12.5 | 14 | 496 |
| 20 | 287 | 146 | 22 | 11.5 | 473 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `banner` | 20, 202, 350, 160 | 20, 202, 350, 160 | 0 | pass |
| `continue` | 20, 864, 350, 56 | 20, 864, 350, 56 | 0 | pass |

## Text

- Expected: `STEP 4 OF 4 • VALIDATION`, `3 Missing items`, `Review and finalize`, `MISSING ITEMS`, `Brake Fluid`, `Tread Photo`, `Signature`, `28 completed`, `28 / 31 Coverage`, `90%
Coverage`, `Full inspection`
- Actual: `STEP 4 OF 4 • VALIDATION`, `3 Missing items`, `Review and finalize`, `Finalized findings cannot be edited by anyone.`, `3 Missing items`, `Finalized findings cannot be edited by anyone.`, `1`, `2`, `3`, `Add at least one photo.`, `MISSING ITEMS`, `Brake Fluid`, `Chassis`, `Add at least one photo.`, `Tread Photo`, `Front Left`, `Add at least one photo.`, `Signature`, `Required`, `Note`, `28 completed`, `28 / 31 Coverage`, `90%
Coverage`, `Review and finalize`, `Finalized findings cannot be edited by anyone.`, `Full inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

