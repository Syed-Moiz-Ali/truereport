# Fidelity report — f2a1-inspection-hub-product-copy

- **Sample id:** `f2a1-inspection-hub-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/inspection-hub-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/07_7._Main_Inspection_Hub/7._Main_Inspection_Hub@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2260}
- **Logical size:** 390 × 1130 @ DPR 2
- **Compared pixels:** 780 × 2260
- **Generated:** 2026-11-06T04:36:21.544Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.92641; min 64×64 tile 0.26822 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.92641 |
| SSIM (worst 64×64 tile) | 0.26822 |
| RMSE (RGB 0–255) | 29.816 |
| MAE (RGB 0–255) | 6.408 |
| ΔE2000 mean | 1.909 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 4.794 |
| ΔE2000 max | 91.841 |
| ΔE2000 > 2 (JND) | 7.52% |
| ΔE2000 > 5 | 4.33% |
| ΔE2000 > 10 | 3.79% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 188 | 154 | 95 | 167.5 | 16549 |
| 2 | 36 | 449.5 | 48 | 40.5 | 5305 |
| 3 | 133.5 | 596.5 | 38.5 | 35 | 2388 |
| 4 | 97 | 451.5 | 51.5 | 13 | 1372 |
| 5 | 119.5 | 970 | 56.5 | 10.5 | 1225 |
| 6 | 76.5 | 356 | 31 | 14 | 1167 |
| 7 | 114.5 | 24.5 | 32 | 17 | 1075 |
| 8 | 41 | 670.5 | 26.5 | 18 | 1070 |
| 9 | 154 | 88.5 | 33.5 | 9.5 | 887 |
| 10 | 86.5 | 24 | 29.5 | 17.5 | 884 |
| 11 | 161 | 452 | 35 | 12.5 | 863 |
| 12 | 179.5 | 969 | 37 | 11.5 | 810 |
| 13 | 246 | 697 | 44.5 | 13 | 799 |
| 14 | 145.5 | 1065 | 19.5 | 17.5 | 698 |
| 15 | 282 | 880 | 31.5 | 10.5 | 659 |
| 16 | 169 | 472 | 28.5 | 12 | 651 |
| 17 | 228.5 | 356.5 | 19 | 12.5 | 643 |
| 18 | 235.5 | 778 | 15 | 18 | 634 |
| 19 | 99.5 | 880 | 31 | 10.5 | 632 |
| 20 | 48.5 | 88.5 | 26.5 | 9 | 611 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `ASSIGNED`, `JOB-2601 • v1`, `17`, `/40`, `CHECKS DONE`, `15 no issue observed`, `2 attention`, `Honda Accord`, `JOB-2601 • 48,210 KM`, `Inspection modules`, `4 categories`, `Exterior`, `10/10 checks`, `7/10`, `Interior`, `7/10 checks`, `Engine`, `0/10 checks`, `Not started`, `Underbody`, `0/10 checks`, `Not started`, `Continue checklist · Interior`, `Inspection hub`, `Jobs`, `Finalized`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

