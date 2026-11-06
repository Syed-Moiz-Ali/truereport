# Fidelity report — f2a1-assigned-jobs-figma-text

- **Sample id:** `f2a1-assigned-jobs-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/assigned-jobs-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/2._Assigned_Jobs_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2004}
- **Logical size:** 390 × 1002 @ DPR 2
- **Compared pixels:** 780 × 2004
- **Generated:** 2026-11-06T04:35:50.048Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.94907; min 64×64 tile 0.36677 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.94907 |
| SSIM (worst 64×64 tile) | 0.36677 |
| RMSE (RGB 0–255) | 19.921 |
| MAE (RGB 0–255) | 4.219 |
| ΔE2000 mean | 1.318 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 3.126 |
| ΔE2000 max | 97.026 |
| ΔE2000 > 2 (JND) | 8.03% |
| ΔE2000 > 5 | 3.8% |
| ΔE2000 > 10 | 2.56% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 26 | 78 | 49 | 49.5 | 6854 |
| 2 | 195 | 346 | 77 | 18 | 5248 |
| 3 | 289 | 346 | 77 | 18 | 5240 |
| 4 | 333.5 | 17.5 | 28.5 | 30.5 | 1594 |
| 5 | 249.5 | 93 | 39.5 | 14 | 1135 |
| 6 | 304.5 | 711 | 47 | 30 | 1057 |
| 7 | 304.5 | 564.5 | 47 | 31 | 1052 |
| 8 | 304.5 | 419.5 | 47 | 30 | 1044 |
| 9 | 297.5 | 284.5 | 50.5 | 8 | 950 |
| 10 | 292.5 | 269 | 29 | 9 | 873 |
| 11 | 275 | 34.5 | 32.5 | 9 | 769 |
| 12 | 269.5 | 266 | 21 | 12.5 | 613 |
| 13 | 167.5 | 575 | 25 | 13 | 532 |
| 14 | 137.5 | 721 | 25.5 | 10.5 | 519 |
| 15 | 269 | 283.5 | 24.5 | 11 | 513 |
| 16 | 171 | 429 | 22 | 13 | 459 |
| 17 | 183 | 721 | 23.5 | 13 | 425 |
| 18 | 228.5 | 268 | 14.5 | 20 | 419 |
| 19 | 100.5 | 476.5 | 18.5 | 9 | 377 |
| 20 | 283.5 | 20.5 | 16.5 | 8.5 | 374 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `SHIFT 1 · BAY A`, `Welcome back,`, `David Vance`, `3 Tasks`, `Pending check`, `45 min`, `Avg. turnover`, `ASSIGNED TODAY`, `3 In Queue`, `Renault Megan 3`, `ABC 123 · Bay 4`, `Full inspection`, `Ready`, `Renault Megan 3`, `ABC 123 · Bay 4`, `Full inspection`, `High Priority`, `Renault Megan 3`, `ABC 123 · Bay 4`, `Full inspection`, `Scheduled`, `Scan New VIN Tag`, `Inspection Queue`, `LIVE
SYNC`, `Intake`, `Fleet`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

