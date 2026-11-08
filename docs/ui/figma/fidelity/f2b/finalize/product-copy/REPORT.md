# Fidelity report — f2b-finalize-product-copy

- **Sample id:** `f2b-finalize-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/finalize-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/14._Finalize_&_Approval_(Swipe)@2x.png`
- **Reference crop (px):** {"x":76,"y":14,"width":780,"height":2463}
- **Logical size:** 390 × 1231.5 @ DPR 2
- **Compared pixels:** 780 × 2463
- **Generated:** 2026-11-08T09:25:44.259Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.84.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.84253; min 64×64 tile 0.16518 |
| Text | pass | 7 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.84253 |
| SSIM (worst 64×64 tile) | 0.16518 |
| RMSE (RGB 0–255) | 43.793 |
| MAE (RGB 0–255) | 14.661 |
| ΔE2000 mean | 4.433 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 37.365 |
| ΔE2000 max | 99.921 |
| ΔE2000 > 2 (JND) | 14.24% |
| ΔE2000 > 5 | 12.91% |
| ΔE2000 > 10 | 11.86% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 44 | 298 | 302 | 144 | 156813 |
| 2 | 60 | 671 | 35 | 40 | 4537 |
| 3 | 114 | 113 | 45 | 20.5 | 1880 |
| 4 | 78 | 147 | 65.5 | 14.5 | 1529 |
| 5 | 77 | 839 | 65.5 | 11.5 | 1507 |
| 6 | 54 | 805.5 | 49.5 | 16 | 1433 |
| 7 | 147 | 239.5 | 52 | 13 | 1388 |
| 8 | 107.5 | 706 | 46.5 | 10.5 | 978 |
| 9 | 284 | 147 | 37 | 14.5 | 947 |
| 10 | 50 | 1003.5 | 48.5 | 13 | 942 |
| 11 | 175.5 | 260 | 42.5 | 10.5 | 927 |
| 12 | 199 | 240 | 34 | 12.5 | 893 |
| 13 | 157 | 662.5 | 34.5 | 11 | 866 |
| 14 | 295 | 1003.5 | 47 | 13 | 866 |
| 15 | 196 | 113.5 | 22.5 | 20 | 776 |
| 16 | 109 | 807 | 39.5 | 11.5 | 747 |
| 17 | 78 | 82.5 | 34 | 9 | 672 |
| 18 | 140.5 | 927.5 | 35.5 | 9 | 643 |
| 19 | 108 | 662.5 | 24.5 | 11 | 642 |
| 20 | 152 | 148 | 30.5 | 10.5 | 637 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `summary` | 20, 206, 350, 558 | 20, 206, 350, 558 | 0 | pass |
| `slide` | 20, 1147, 350, 64 | 20, 1146.6, 350, 64 | 0.37 | pass |

## Text

- Expected: `Review and finalize`, `2022 Honda Accord`, `VIN • 1HGCM82633A004352`, `A 12345`, `JOB-2601`, `Finalize`, `Diagnostic Checklist`
- Actual: `REVIEW AND FINALIZE`, `Review and finalize`, `Finalized findings cannot be edited by anyone.`, `2022 Honda Accord`, `VIN • 1HGCM82633A004352`, `A 12345`, `Odometer: 48,210 KM`, `17`, `completed`, `2`, `Defect found`, `DV`, `David Vance`, `Technician`, `JOB-2601`, `Today`, `14:48`, `PST`, `Missing items`, `2 attention`, `Interior check 6`, `Attention recommended`, `Interior check 7`, `Attention recommended`, `Finalized findings cannot be edited by anyone.`, `Finalize`, `Diagnostic Checklist`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

