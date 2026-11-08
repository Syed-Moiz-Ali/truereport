# Fidelity report — f2a1-assigned-jobs-product-copy

- **Sample id:** `f2a1-assigned-jobs-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/assigned-jobs-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/2._Assigned_Jobs_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2004}
- **Logical size:** 390 × 1002 @ DPR 2
- **Compared pixels:** 780 × 2004
- **Generated:** 2026-11-07T19:42:04.064Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.89973; min 64×64 tile 0.22547 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | fail | 1 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.89973 |
| SSIM (worst 64×64 tile) | 0.22547 |
| RMSE (RGB 0–255) | 55.553 |
| MAE (RGB 0–255) | 19.195 |
| ΔE2000 mean | 5.317 |
| ΔE2000 median | 0.198 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 92.513 |
| ΔE2000 > 2 (JND) | 20.96% |
| ΔE2000 > 5 | 17.09% |
| ΔE2000 > 10 | 14.35% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 10.5 | 675.5 | 369 | 83.5 | 115070 |
| 2 | 11.5 | 825.5 | 366.5 | 76.5 | 103241 |
| 3 | 21 | 185 | 112 | 26 | 5049 |
| 4 | 333 | 16 | 32.5 | 32 | 3241 |
| 5 | 128 | 190.5 | 47 | 15 | 1605 |
| 6 | 169.5 | 553.5 | 51 | 15 | 1389 |
| 7 | 109 | 406.5 | 49.5 | 13 | 1325 |
| 8 | 108 | 553 | 35.5 | 15.5 | 1020 |
| 9 | 244 | 93 | 20 | 14 | 705 |
| 10 | 159.5 | 407 | 22 | 12.5 | 645 |
| 11 | 134 | 575 | 32 | 10.5 | 635 |
| 12 | 138 | 429 | 28.5 | 10.5 | 559 |
| 13 | 36.5 | 93 | 16.5 | 14 | 538 |
| 14 | 264.5 | 95.5 | 24.5 | 9 | 466 |
| 15 | 270 | 622.5 | 18 | 11 | 457 |
| 16 | 297.5 | 622.5 | 23 | 10.5 | 452 |
| 17 | 152 | 552.5 | 20 | 13 | 432 |
| 18 | 269 | 283.5 | 20.5 | 11 | 405 |
| 19 | 331.5 | 95.5 | 18.5 | 8.5 | 387 |
| 20 | 100.5 | 476.5 | 18.5 | 9 | 377 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `LH`, `TODAY • 2 JOBS`, `Welcome back,`, `Layla Hassan`, `2`, `Pending check`, `1`, `In progress`, `ASSIGNED TODAY`, `2 in queue`, `Honda Accord`, `JOB-2601 · A 12345`, `Full inspection`, `Assigned`, `Toyota Camry`, `JOB-2602 · B 67890`, `Full inspection`, `In progress`, `Walk-in job`, `Inspection Queue`, `ONLINE
SYNC`, `LH`, `Intake`, `Fleet`, `Sync`, `Profile`

### Forbidden-term matches

- **fleet** (term) matched `Fleet`: …Queue ONLINE SYNC LH Intake Fleet Sync Profile

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

