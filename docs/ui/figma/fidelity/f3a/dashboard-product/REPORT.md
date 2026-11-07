# Fidelity report — f3a-dashboard-level2

- **Sample id:** `f3a-dashboard-level2`
- **Batch:** `f3a-dashboard`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/dashboard-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/02_1._Workshop_Dashboard/1._Workshop_Dashboard@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2461}
- **Logical size:** 1280 × 1230.672 @ DPR 2
- **Compared pixels:** 2560 × 2461
- **Generated:** 2026-11-07T10:09:42.989Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.88843; min 64×64 tile 0.21214 |
| Text | fail | 4 missing |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.88843 |
| SSIM (worst 64×64 tile) | 0.21214 |
| RMSE (RGB 0–255) | 31.693 |
| MAE (RGB 0–255) | 7.793 |
| ΔE2000 mean | 2.318 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 6.304 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 15.73% |
| ΔE2000 > 5 | 5.34% |
| ΔE2000 > 10 | 4.21% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 1074 | 120.5 | 173.5 | 76.5 | 37167 |
| 2 | 36.5 | 718 | 1207 | 141.5 | 22284 |
| 3 | 168 | 500 | 298 | 27.5 | 20712 |
| 4 | 10.5 | 128 | 215.5 | 80 | 19506 |
| 5 | 318 | 338 | 114.5 | 27.5 | 11958 |
| 6 | 317 | 660 | 106.5 | 37.5 | 11606 |
| 7 | 322.5 | 824 | 103 | 27.5 | 10695 |
| 8 | 925 | 512.5 | 283 | 6.5 | 7325 |
| 9 | 1208 | 24 | 32 | 32 | 2986 |
| 10 | 36.5 | 474 | 511 | 11 | 2808 |
| 11 | 37 | 319 | 1206 | 6 | 2540 |
| 12 | 36 | 637.5 | 1208 | 0.5 | 2416 |
| 13 | 36 | 645.5 | 1207.5 | 0.5 | 2415 |
| 14 | 36.5 | 961.5 | 1206.5 | 0.5 | 2413 |
| 15 | 133.5 | 105.5 | 49 | 25 | 2366 |
| 16 | 547.5 | 474 | 122 | 14 | 2338 |
| 17 | 181.5 | 109 | 48 | 21.5 | 2323 |
| 18 | 546.5 | 512.5 | 79.5 | 6.5 | 2032 |
| 19 | 655.5 | 474 | 306 | 13.5 | 1831 |
| 20 | 933.5 | 474 | 310 | 11 | 1516 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Overview`, `Search jobs`, `Jobs by status in your workshop`, `7`, `Active jobs`, `5`, `New & scheduled`, `3`, `In progress`, `2`, `Ready to finalize`, `1`, `Finalized today`, `Recent jobs`, `JOB-0001 · Customer A`, `Toyota Camry`, `Full inspection`, `Scheduled at: 2026-11-05T09:00:00`, `Assigned to: Technician A`, `JOB-0002 · Customer B`, `Honda Civic`, `Scheduled at: 2026-11-05T10:00:00`, `JOB-0003 · Customer C`, `Finalized`, `Ford Transit`, `Scheduled at: 2026-11-04T09:00:00`, `Assigned to: Unassigned`, `JOB-0004 · Customer D`, `Assigned`, `Nissan Patrol`, `Scheduled at: 2026-11-06T09:00:00`
- Actual: `Overview`, `Search jobs`, `Search jobs`, `Jobs by status in your workshop`, `7`, `Active jobs`, `5`, `New & scheduled`, `3`, `In progress`, `2`, `Ready to finalize`, `1`, `Finalized today`, `Recent jobs`, `JOB-0001 · Customer A`, `In progress`, `Toyota Camry`, `Full inspection`, `Scheduled at: 11/5/2026 13:00`, `Assigned to: Technician A`, `JOB-0002 · Customer B`, `Ready to finalize`, `Honda Civic`, `Full inspection`, `Scheduled at: 11/5/2026 14:00`, `Assigned to: Technician A`, `JOB-0003 · Customer C`, `Finalized`, `Ford Transit`, `Full inspection`, `Scheduled at: 11/4/2026 13:00`, `Assigned to: Unassigned`, `JOB-0004 · Customer D`, `Assigned`, `Nissan Patrol`, `Full inspection`, `Scheduled at: 11/6/2026 13:00`, `Assigned to: Unassigned`
- Missing: `Scheduled at: 2026-11-05T09:00:00`, `Scheduled at: 2026-11-05T10:00:00`, `Scheduled at: 2026-11-04T09:00:00`, `Scheduled at: 2026-11-06T09:00:00`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

