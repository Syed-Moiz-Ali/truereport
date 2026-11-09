# Fidelity report — f3a-schedule-level2

- **Sample id:** `f3a-schedule-level2`
- **Batch:** `f3a-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/schedule-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/01_3._Create_-_Schedule_Job/3._Create_-_Schedule_Job@2x.png`
- **Reference crop (px):** {"x":32,"y":90,"width":2560,"height":2116}
- **Logical size:** 1280 × 1058 @ DPR 2
- **Compared pixels:** 2560 × 2116
- **Generated:** 2026-11-08T12:35:24.060Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.83559; min 64×64 tile 0.11531 |
| Text | fail | 1 missing |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.83559 |
| SSIM (worst 64×64 tile) | 0.11531 |
| RMSE (RGB 0–255) | 94.948 |
| MAE (RGB 0–255) | 80.363 |
| ΔE2000 mean | 21.221 |
| ΔE2000 median | 29.266 |
| ΔE2000 p95 | 29.453 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 87.78% |
| ΔE2000 > 5 | 70.46% |
| ΔE2000 > 10 | 69.9% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 0 | 889 | 1058 | 3641059 |
| 2 | 882 | 935.5 | 376 | 82 | 64210 |
| 3 | 888 | 550 | 364 | 25 | 14818 |
| 4 | 1186 | 515 | 46 | 22 | 3682 |
| 5 | 944.5 | 55 | 63 | 31 | 3452 |
| 6 | 1222.5 | 0 | 57.5 | 57.5 | 2860 |
| 7 | 906 | 56 | 38.5 | 30 | 1888 |
| 8 | 942 | 510.5 | 44 | 19 | 1635 |
| 9 | 1247.5 | 502.5 | 8.5 | 47 | 1108 |
| 10 | 884 | 501.5 | 8.5 | 48 | 1106 |
| 11 | 890 | 58 | 17.5 | 28 | 929 |
| 12 | 1061 | 55 | 19.5 | 26.5 | 839 |
| 13 | 904 | 515.5 | 17 | 16.5 | 704 |
| 14 | 934 | 100 | 18.5 | 16 | 667 |
| 15 | 1021.5 | 69 | 19.5 | 17 | 664 |
| 16 | 904.5 | 296 | 18.5 | 21 | 654 |
| 17 | 1223 | 824 | 18 | 20 | 652 |
| 18 | 890.5 | 97 | 20 | 19 | 641 |
| 19 | 1008 | 68.5 | 13 | 17.5 | 603 |
| 20 | 908 | 397.5 | 15 | 17 | 526 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Schedule new job`, `Create the job in this workshop — assign a technician afterwards`, `Job details`, `Customer name`, `Customer phone`, `Customer email`, `Vehicle make`, `Vehicle model`, `Vehicle year`, `VIN`, `Plate`, `Inspection scope`, `Scheduled at`, `2026-11-05T09:00:00`, `Full inspection · v1`, `12 items`, `Quick check · v2`, `5 items`, `Select a template`, `Create`
- Actual: `Open`, `Schedule new job`, `Create the job in this workshop — assign a technician afterwards`, `Job details`, `Customer name`, `Customer phone`, `Customer email`, `Vehicle make`, `Vehicle model`, `Vehicle year`, `VIN`, `Plate`, `Inspection scope`, `Scheduled at`, `Full inspection · v1`, `12 items`, `Quick check · v2`, `5 items`, `Select a template`, `Create`, `Create the job in this workshop — assign a technician afterwards`
- Missing: `2026-11-05T09:00:00`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

