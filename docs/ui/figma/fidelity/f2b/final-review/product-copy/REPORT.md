# Fidelity report — f2b-final-review-product-copy

- **Sample id:** `f2b-final-review-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/final-review-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/12_13._Final_Review_(Missing_Items)/13._Final_Review_(Missing_Items)@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2016}
- **Logical size:** 390 × 1008 @ DPR 2
- **Compared pixels:** 780 × 2016
- **Generated:** 2026-11-06T11:35:22.010Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.78379; min 64×64 tile 0.1334 |
| Text | pass | 9 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.78379 |
| SSIM (worst 64×64 tile) | 0.1334 |
| RMSE (RGB 0–255) | 55.74 |
| MAE (RGB 0–255) | 21.029 |
| ΔE2000 mean | 6.659 |
| ΔE2000 median | 1.07 |
| ΔE2000 p95 | 34.699 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 38.81% |
| ΔE2000 > 5 | 21.09% |
| ΔE2000 > 10 | 15.35% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 10.5 | 646 | 369 | 123.5 | 124236 |
| 2 | 20 | 289.5 | 350 | 72.5 | 62536 |
| 3 | 198 | 383 | 101 | 22 | 8226 |
| 4 | 202 | 485 | 97 | 22 | 8140 |
| 5 | 20.5 | 198 | 349 | 28.5 | 5435 |
| 6 | 186 | 645 | 67.5 | 18 | 4611 |
| 7 | 299.5 | 442 | 36.5 | 36 | 4110 |
| 8 | 299.5 | 544 | 36.5 | 36 | 4110 |
| 9 | 307 | 386 | 36 | 36 | 4091 |
| 10 | 307 | 488 | 36 | 36 | 4091 |
| 11 | 334 | 16 | 40 | 32 | 2189 |
| 12 | 28.5 | 79 | 103 | 9.5 | 2187 |
| 13 | 109.5 | 25 | 78 | 17.5 | 2176 |
| 14 | 68 | 159 | 83.5 | 18 | 2167 |
| 15 | 181 | 114.5 | 27.5 | 39.5 | 1912 |
| 16 | 21 | 109.5 | 16 | 44.5 | 1643 |
| 17 | 127 | 227 | 43.5 | 13.5 | 1515 |
| 18 | 117 | 389 | 49 | 12 | 1454 |
| 19 | 205.5 | 159 | 55 | 15.5 | 1441 |
| 20 | 164.5 | 114.5 | 22.5 | 30.5 | 1439 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `banner` | 20, 360, 350, 88 | 20, 360, 350, 88 | 0 | pass |
| `continue` | 20, 684, 350, 56 | 20, 684, 350, 56 | 0 | pass |

## Text

- Expected: `REVIEW AND FINALIZE`, `2 Missing items`, `Review and finalize`, `MISSING ITEMS`, `Choose a result first`, `17 / 40`, `Coverage`, `43%`, `Full inspection`
- Actual: `REVIEW AND FINALIZE`, `2 Missing items`, `Review and finalize`, `Finalized findings cannot be edited by anyone.`, `2 Missing items`, `Finalized findings cannot be edited by anyone.`, `MISSING ITEMS`, `1`, `Choose a result first`, `Missing items`, `Choose a result first`, `2`, `Add at least one photo.`, `Missing items`, `Add at least one photo.`, `completed`, `17 / 40`, `Coverage`, `43%`, `Review and finalize`, `Finalized findings cannot be edited by anyone.`, `Full inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

