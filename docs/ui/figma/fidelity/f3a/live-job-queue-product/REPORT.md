# Fidelity report — f3a-queue-level2

- **Sample id:** `f3a-queue-level2`
- **Batch:** `f3a-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/queue-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/03_2._Live_Job_Queue/2._Live_Job_Queue@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2250}
- **Logical size:** 1280 × 1125 @ DPR 2
- **Compared pixels:** 2560 × 2250
- **Generated:** 2026-11-07T10:09:59.835Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.89698; min 64×64 tile 0.06948 |
| Text | pass | 26 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.89698 |
| SSIM (worst 64×64 tile) | 0.06948 |
| RMSE (RGB 0–255) | 37.196 |
| MAE (RGB 0–255) | 10.148 |
| ΔE2000 mean | 3.122 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 15.023 |
| ΔE2000 max | 100 |
| ΔE2000 > 2 (JND) | 21.96% |
| ΔE2000 > 5 | 7.42% |
| ΔE2000 > 10 | 5.75% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 1073 | 126.5 | 176.5 | 76.5 | 48590 |
| 2 | 159.5 | 345 | 215.5 | 77 | 43766 |
| 3 | 167 | 678 | 180 | 92 | 35748 |
| 4 | 163.5 | 516 | 167.5 | 80 | 32563 |
| 5 | 768 | 28 | 139.5 | 57.5 | 28404 |
| 6 | 168 | 864 | 80 | 80 | 24212 |
| 7 | 10 | 208 | 81 | 80 | 19961 |
| 8 | 16 | 104 | 82.5 | 53 | 14035 |
| 9 | 242 | 192 | 114.5 | 28 | 12152 |
| 10 | 268 | 553 | 116 | 22 | 9735 |
| 11 | 268 | 727 | 90 | 22 | 7475 |
| 12 | 1208 | 24 | 32 | 32 | 2986 |
| 13 | 133 | 227.5 | 535.5 | 10.5 | 2339 |
| 14 | 998 | 387 | 62.5 | 8 | 1960 |
| 15 | 260 | 123 | 26 | 31 | 1757 |
| 16 | 147 | 126 | 31.5 | 25 | 1687 |
| 17 | 235 | 123.5 | 19 | 28 | 1333 |
| 18 | 37 | 45 | 29.5 | 22 | 1332 |
| 19 | 304.5 | 123.5 | 19 | 28 | 1251 |
| 20 | 321.5 | 123 | 21 | 28.5 | 1219 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Job queue`, `Search jobs`, `New job`, `All (4)`, `In progress (1)`, `Ready to finalize (1)`, `Finalized (1)`, `Toyota Camry`, `In progress`, `JOB-0001`, `Customer A`, `Full inspection v1`, `Technician A`, `Honda Civic`, `Ready to finalize`, `JOB-0002`, `Customer B`, `Ford Transit`, `Finalized`, `JOB-0003`, `Customer C`, `Unassigned`, `Nissan Patrol`, `Scheduled`, `JOB-0004`, `Customer D`
- Actual: `Job queue`, `Search jobs`, `Search jobs`, `New job`, `All (4)`, `In progress (1)`, `Ready to finalize (1)`, `Finalized (1)`, `Toyota Camry`, `In progress`, `JOB-0001`, `Customer A`, `Full inspection v1`, `Technician A`, `Honda Civic`, `Ready to finalize`, `JOB-0002`, `Customer B`, `Full inspection v1`, `Technician A`, `Ford Transit`, `Finalized`, `JOB-0003`, `Customer C`, `Full inspection v1`, `Unassigned`, `Nissan Patrol`, `Scheduled`, `JOB-0004`, `Customer D`, `Full inspection v1`, `Unassigned`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

