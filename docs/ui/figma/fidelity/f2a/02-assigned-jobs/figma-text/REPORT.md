# Fidelity report — F2-A 02-assigned-jobs - Figma-text fixture

- **Sample id:** `02-assigned-jobs-figma-text`
- **Batch:** `f2a-technician-screens-1-7`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a/02-assigned-jobs-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/2._Assigned_Jobs_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2004}
- **Logical size:** 390 × 1002 @ DPR 2
- **Compared pixels:** 780 × 2004
- **Generated:** 2026-11-05T14:57:52.439Z
- **Owner:** fidelity-auditor

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.7723; min 64×64 tile 0.22332 |
| Text | pass | 15 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.7723 |
| SSIM (worst 64×64 tile) | 0.22332 |
| RMSE (RGB 0–255) | 68.761 |
| MAE (RGB 0–255) | 29.003 |
| ΔE2000 mean | 8.405 |
| ΔE2000 median | 0.396 |
| ΔE2000 p95 | 40.384 |
| ΔE2000 max | 94.907 |
| ΔE2000 > 2 (JND) | 38.66% |
| ΔE2000 > 5 | 22.36% |
| ΔE2000 > 10 | 19.32% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 11.5 | 825.5 | 366.5 | 77 | 103242 |
| 2 | 20 | 754 | 350 | 56 | 73297 |
| 3 | 199 | 240 | 171 | 48 | 22170 |
| 4 | 17 | 72 | 61.5 | 62.5 | 9903 |
| 5 | 304 | 692 | 47.5 | 49.5 | 7235 |
| 6 | 304 | 546 | 48 | 50 | 7229 |
| 7 | 304 | 400 | 47.5 | 49.5 | 7218 |
| 8 | 36 | 249 | 40 | 49 | 5323 |
| 9 | 289 | 346 | 77 | 18 | 5240 |
| 10 | 330 | 12 | 40 | 40 | 5051 |
| 11 | 12 | 16 | 48.5 | 32 | 3880 |
| 12 | 94.5 | 185.5 | 76.5 | 20 | 3297 |
| 13 | 108.5 | 698 | 83.5 | 13.5 | 2636 |
| 14 | 60.5 | 936 | 33.5 | 33.5 | 2018 |
| 15 | 39.5 | 176.5 | 28 | 29 | 1502 |
| 16 | 115.5 | 25.5 | 47 | 17.5 | 1429 |
| 17 | 105 | 335.5 | 19.5 | 26 | 1271 |
| 18 | 68.5 | 185 | 25.5 | 20.5 | 1206 |
| 19 | 298 | 936 | 32.5 | 33 | 1190 |
| 20 | 80.5 | 25.5 | 34.5 | 14 | 1040 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Welcome back,`, `David Vance`, `Pending check`, `In progress`, `Assigned today`, `3 in queue`, `Renault Megane 3`, `Ready`, `High Priority`, `Scheduled`, `Walk-in job`, `Assigned jobs`, `Jobs`, `Sync`, `Profile`
- Actual: `DV`, `Welcome back,`, `David Vance`, `3`, `Pending check`, `0`, `In progress`, `Assigned today`, `3 in queue`, `Renault Megane 3`, `Ready`, `JOB-5A0001`, `10:42 UTC+4`, `34,180 MI`, `Full Pre-Delivery Inspection`, `Nissan Patrol`, `High Priority`, `JOB-5A0002`, `10:42 UTC+4`, `61,200 MI`, `Brake Fluid & Tire Diagnostics`, `Toyota Land Cruiser`, `Scheduled`, `JOB-5A0003`, `10:42 UTC+4`, `98,400 MI`, `Routine 60-Point Audit`, `Walk-in job`, `TR`, `Assigned jobs`, `DV`, `Jobs`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Test-only Figma-like sample copy. Removed: avatar photo (initials instead), SHIFT/BAY pill, LIVE SYNC badge, Scan New VIN Tag (replaced by existing Walk-in job), Fleet dock (product dock is Jobs/Sync/Profile), avg turnover and dashboard summary (no data). Counts are derived from the existing jobs list. Plates are not shown; search moved to the app bar. Job status chip moves below the title when large text would overflow. Dock labels differ; copy/removal differences are residuals.

