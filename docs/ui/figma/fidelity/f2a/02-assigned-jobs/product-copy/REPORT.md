# Fidelity report — F2-A 02-assigned-jobs - real product copy

- **Sample id:** `02-assigned-jobs-product-copy`
- **Batch:** `f2a-technician-screens-1-7`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a/02-assigned-jobs-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/2._Assigned_Jobs_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2004}
- **Logical size:** 390 × 1002 @ DPR 2
- **Compared pixels:** 780 × 2004
- **Generated:** 2026-11-05T14:57:55.149Z
- **Owner:** fidelity-auditor

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.79494; min 64×64 tile 0.22332 |
| Text | pass | 13 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.79494 |
| SSIM (worst 64×64 tile) | 0.22332 |
| RMSE (RGB 0–255) | 67.367 |
| MAE (RGB 0–255) | 27.652 |
| ΔE2000 mean | 8.016 |
| ΔE2000 median | 0.198 |
| ΔE2000 p95 | 40.384 |
| ΔE2000 max | 94.907 |
| ΔE2000 > 2 (JND) | 35.84% |
| ΔE2000 > 5 | 22.63% |
| ΔE2000 > 10 | 18.5% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 11.5 | 825.5 | 366.5 | 77 | 103242 |
| 2 | 20 | 600 | 350 | 56 | 73841 |
| 3 | 199 | 240 | 171 | 48 | 22170 |
| 4 | 92 | 467 | 115 | 45 | 13670 |
| 5 | 91.5 | 330 | 104 | 31.5 | 11341 |
| 6 | 17 | 72 | 61.5 | 62.5 | 9903 |
| 7 | 304 | 546 | 48 | 50 | 7229 |
| 8 | 304 | 692 | 47.5 | 49.5 | 7226 |
| 9 | 304 | 400 | 47.5 | 49.5 | 7218 |
| 10 | 36 | 249 | 40 | 49 | 5323 |
| 11 | 289 | 346 | 77 | 18 | 5240 |
| 12 | 330 | 12 | 40 | 40 | 5051 |
| 13 | 12 | 16 | 48.5 | 32 | 3880 |
| 14 | 94.5 | 185.5 | 76.5 | 20 | 3297 |
| 15 | 60.5 | 936 | 33.5 | 33.5 | 2018 |
| 16 | 39.5 | 176.5 | 28 | 29 | 1502 |
| 17 | 115.5 | 25.5 | 47 | 17.5 | 1429 |
| 18 | 68.5 | 185 | 25.5 | 20.5 | 1206 |
| 19 | 298 | 936 | 32.5 | 33 | 1190 |
| 20 | 81 | 111.5 | 26 | 20 | 1042 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Welcome back,`, `Layla Hassan`, `Pending check`, `In progress`, `Assigned today`, `2 in queue`, `Honda Accord`, `Toyota Camry`, `Walk-in job`, `Assigned jobs`, `Jobs`, `Sync`, `Profile`
- Actual: `LH`, `Welcome back,`, `Layla Hassan`, `2`, `Pending check`, `1`, `In progress`, `Assigned today`, `2 in queue`, `Honda Accord`, `Assigned`, `JOB-2601`, `10:42 UTC+4`, `48,210 KM`, `Full inspection`, `Toyota Camry`, `In progress`, `JOB-2602`, `10:42 UTC+4`, `92,100 KM`, `Full inspection`, `Walk-in job`, `TR`, `Assigned jobs`, `LH`, `Jobs`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Real product copy and neutral test data. Removed: avatar photo (initials instead), SHIFT/BAY pill, LIVE SYNC badge, Scan New VIN Tag (replaced by existing Walk-in job), Fleet dock (product dock is Jobs/Sync/Profile), avg turnover and dashboard summary (no data). Counts are derived from the existing jobs list. Plates are not shown; search moved to the app bar. Job status chip moves below the title when large text would overflow. Dock labels differ; copy/removal differences are residuals.

