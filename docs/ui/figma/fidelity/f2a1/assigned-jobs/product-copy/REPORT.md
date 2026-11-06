# Fidelity report — f2a1-assigned-jobs-product-copy

- **Sample id:** `f2a1-assigned-jobs-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/assigned-jobs-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/2._Assigned_Jobs_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2004}
- **Logical size:** 390 × 1002 @ DPR 2
- **Compared pixels:** 780 × 2004
- **Generated:** 2026-11-06T04:35:52.894Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.89062; min 64×64 tile 0.2569 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.89062 |
| SSIM (worst 64×64 tile) | 0.2569 |
| RMSE (RGB 0–255) | 56.252 |
| MAE (RGB 0–255) | 20.081 |
| ΔE2000 mean | 5.599 |
| ΔE2000 median | 0.199 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 97.017 |
| ΔE2000 > 2 (JND) | 24.1% |
| ΔE2000 > 5 | 18.32% |
| ΔE2000 > 10 | 14.68% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 10.5 | 675.5 | 369 | 83.5 | 115173 |
| 2 | 11.5 | 825.5 | 366.5 | 76.5 | 103241 |
| 3 | 289 | 346 | 77 | 18 | 5240 |
| 4 | 195 | 346 | 74 | 18 | 5053 |
| 5 | 21 | 185 | 112 | 26 | 5049 |
| 6 | 0 | 48 | 85.5 | 16 | 3472 |
| 7 | 332 | 16 | 32 | 32 | 3278 |
| 8 | 128 | 190.5 | 47 | 15 | 1605 |
| 9 | 169.5 | 553.5 | 51 | 15 | 1389 |
| 10 | 109 | 406.5 | 49.5 | 13 | 1325 |
| 11 | 249.5 | 93 | 46.5 | 14 | 1206 |
| 12 | 304.5 | 564.5 | 47 | 31 | 1052 |
| 13 | 304.5 | 419.5 | 47 | 30 | 1044 |
| 14 | 108 | 553 | 35.5 | 15.5 | 1020 |
| 15 | 30 | 113.5 | 45 | 14 | 879 |
| 16 | 296.5 | 284.5 | 44.5 | 9.5 | 814 |
| 17 | 159.5 | 407 | 22 | 12.5 | 645 |
| 18 | 134 | 575 | 32 | 10.5 | 635 |
| 19 | 138 | 429 | 28.5 | 10.5 | 559 |
| 20 | 36.5 | 93 | 16.5 | 14 | 538 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `LH`, `TODAY • 2 JOBS`, `Welcome back,`, `Layla Hassan`, `2`, `Pending check`, `1`, `In progress`, `ASSIGNED TODAY`, `2 in queue`, `Honda Accord`, `JOB-2601 · A 12345`, `Full inspection`, `Assigned`, `Toyota Camry`, `JOB-2602 · B 67890`, `Full inspection`, `In progress`, `Walk-in job`, `Inspection Queue`, `ONLINE
SYNC`, `LH`, `Jobs`, `Finalized`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

