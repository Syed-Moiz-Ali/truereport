# Fidelity report — f2b-final-review-figma-text

- **Sample id:** `f2b-final-review-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/final-review-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/12_13._Final_Review_(Missing_Items)/13._Final_Review_(Missing_Items)@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2016}
- **Logical size:** 390 × 1008 @ DPR 2
- **Compared pixels:** 780 × 2016
- **Generated:** 2026-11-06T11:35:19.226Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.76743; min 64×64 tile 0.13039 |
| Text | pass | 10 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.76743 |
| SSIM (worst 64×64 tile) | 0.13039 |
| RMSE (RGB 0–255) | 56.87 |
| MAE (RGB 0–255) | 21.845 |
| ΔE2000 mean | 6.951 |
| ΔE2000 median | 0.997 |
| ΔE2000 p95 | 38.842 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 35.77% |
| ΔE2000 > 5 | 22.19% |
| ΔE2000 > 10 | 16.32% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 10.5 | 784.5 | 369 | 98.5 | 118218 |
| 2 | 20 | 289.5 | 350 | 72.5 | 62536 |
| 3 | 198 | 383 | 101 | 22 | 8226 |
| 4 | 202 | 485 | 97 | 22 | 8140 |
| 5 | 202 | 584 | 97 | 22 | 8140 |
| 6 | 20.5 | 198 | 349 | 28.5 | 5435 |
| 7 | 186 | 645 | 67.5 | 18 | 4611 |
| 8 | 299.5 | 442 | 36.5 | 36 | 4110 |
| 9 | 299.5 | 544 | 36.5 | 36 | 4110 |
| 10 | 299.5 | 646 | 36.5 | 36 | 4110 |
| 11 | 307 | 386 | 36 | 36 | 4091 |
| 12 | 307 | 488 | 36 | 36 | 4091 |
| 13 | 307 | 596 | 36 | 36 | 4091 |
| 14 | 136.5 | 25 | 79.5 | 18 | 2503 |
| 15 | 334 | 16 | 40 | 32 | 2189 |
| 16 | 68 | 159 | 83.5 | 18 | 2167 |
| 17 | 135.5 | 109 | 30 | 36 | 1716 |
| 18 | 21 | 109.5 | 16 | 44.5 | 1643 |
| 19 | 115.5 | 109.5 | 19 | 45 | 1602 |
| 20 | 127 | 227 | 43.5 | 13.5 | 1488 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `banner` | 20, 360, 350, 88 | 20, 360, 350, 88 | 0 | pass |
| `continue` | 20, 798, 350, 56 | 20, 798, 350, 56 | 0 | pass |

## Text

- Expected: `REVIEW & FINALIZE`, `3 Missing items`, `Review & Finalize`, `MISSING ITEMS`, `Brake Fluid`, `Tread Photo`, `Signature`, `28 / 31`, `Coverage`, `90%`
- Actual: `REVIEW & FINALIZE`, `3 Missing items`, `Review & Finalize`, `Finalized findings cannot be edited by anyone.`, `3 Missing items`, `Finalized findings cannot be edited by anyone.`, `MISSING ITEMS`, `1`, `Brake Fluid`, `Missing items`, `Tap to capture`, `2`, `Tread Photo`, `Missing items`, `Tap to capture`, `3`, `Signature`, `Missing items`, `Add defect notes (e.g. 2.5cm door ding)...`, `completed`, `28 / 31`, `Coverage`, `90%`, `Review & Finalize`, `Finalized findings cannot be edited by anyone.`, `Full Pre-Delivery Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

