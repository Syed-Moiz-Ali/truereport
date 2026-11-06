# Fidelity report — f2b-dense-mechanical-product-copy

- **Sample id:** `f2b-dense-mechanical-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/dense-mechanical-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/11_11._Dense_Mechanical_List/11._Dense_Mechanical_List@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2160}
- **Logical size:** 390 × 1080 @ DPR 2
- **Compared pixels:** 780 × 2160
- **Generated:** 2026-11-06T11:35:16.201Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.82944; min 64×64 tile 0.21808 |
| Text | pass | 7 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.82944 |
| SSIM (worst 64×64 tile) | 0.21808 |
| RMSE (RGB 0–255) | 49.308 |
| MAE (RGB 0–255) | 16.507 |
| ΔE2000 mean | 5.135 |
| ΔE2000 median | 0.598 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 27.42% |
| ΔE2000 > 5 | 11.46% |
| ΔE2000 > 10 | 10.24% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 34.5 | 484.5 | 260.5 | 76.5 | 63862 |
| 2 | 287.5 | 266 | 62.5 | 49 | 8354 |
| 3 | 314 | 890 | 36 | 60 | 6534 |
| 4 | 314 | 590 | 36 | 48.5 | 4354 |
| 5 | 314 | 482 | 36 | 39.5 | 4306 |
| 6 | 314 | 374 | 36 | 36 | 4098 |
| 7 | 314 | 698 | 36 | 36 | 4077 |
| 8 | 314 | 806 | 36 | 36 | 4075 |
| 9 | 334 | 16 | 40 | 32 | 2184 |
| 10 | 103 | 159.5 | 57.5 | 17.5 | 1723 |
| 11 | 103 | 614 | 47.5 | 14.5 | 1655 |
| 12 | 102 | 915 | 47.5 | 15 | 1650 |
| 13 | 181 | 159 | 50 | 15 | 1595 |
| 14 | 180.5 | 916.5 | 41.5 | 13.5 | 1359 |
| 15 | 143 | 1027.5 | 53 | 11 | 1243 |
| 16 | 102 | 808.5 | 37 | 13.5 | 1222 |
| 17 | 314 | 180.5 | 36 | 21.5 | 1180 |
| 18 | 314 | 158 | 36 | 21 | 1149 |
| 19 | 81.5 | 25.5 | 39.5 | 17.5 | 1136 |
| 20 | 323.5 | 167.5 | 17 | 25 | 1094 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `card` | 20, 132, 350, 88 | 20, 132, 350, 88 | 0 | pass |
| `cta` | 20, 1004, 350, 56 | 20, 1004, 350, 56 | 0 | pass |

## Text

- Expected: `EXTERIOR`, `17 checks done / 40`, `JOB-2601`, `Exterior check 1`, `Inspect the item.`, `Checklist`, `Review and finalize`
- Actual: `EXTERIOR`, `17 checks done / 40`, `JOB-2601`, `Exterior check 1`, `Inspect the item.`, `Exterior check 2`, `Inspect the item.`, `Exterior check 3`, `Inspect the item.`, `Exterior check 4`, `Inspect the item.`, `Exterior check 5`, `Inspect the item.`, `Exterior check 6`, `Inspect the item.`, `Exterior check 7`, `Inspect the item.`, `Exterior check 8`, `Inspect the item.`, `Exterior check 9`, `Inspect the item.`, `Checklist`, `Review and finalize`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

