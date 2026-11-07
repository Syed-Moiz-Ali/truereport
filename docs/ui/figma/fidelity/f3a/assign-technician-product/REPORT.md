# Fidelity report — f3a-assign-level2

- **Sample id:** `f3a-assign-level2`
- **Batch:** `f3a-assign-technician`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/assign-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/04_4._Assign_Technician/4._Assign_Technician@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2240}
- **Logical size:** 1280 × 1120 @ DPR 2
- **Compared pixels:** 2560 × 2240
- **Generated:** 2026-11-07T10:09:22.859Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.82957; min 64×64 tile 0.06811 |
| Text | pass | 12 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.82957 |
| SSIM (worst 64×64 tile) | 0.06811 |
| RMSE (RGB 0–255) | 104.378 |
| MAE (RGB 0–255) | 96.375 |
| ΔE2000 mean | 25.471 |
| ΔE2000 median | 29.453 |
| ΔE2000 p95 | 29.453 |
| ΔE2000 max | 86.617 |
| ΔE2000 > 2 (JND) | 93.96% |
| ΔE2000 > 5 | 87.54% |
| ΔE2000 > 10 | 84.92% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 0 | 1280 | 1120 | 4806960 |
| 2 | 416 | 433 | 448 | 100 | 144187 |
| 3 | 770 | 722 | 102 | 49.5 | 11575 |
| 4 | 428.5 | 660 | 51.5 | 48 | 7483 |
| 5 | 603.5 | 656 | 79 | 18 | 5421 |
| 6 | 772.5 | 713.5 | 90 | 16.5 | 5191 |
| 7 | 432.5 | 560 | 44.5 | 48 | 4270 |
| 8 | 468 | 573.5 | 33 | 39 | 2180 |
| 9 | 575 | 380 | 29.5 | 13 | 822 |
| 10 | 553 | 569 | 18.5 | 20 | 822 |
| 11 | 438 | 383 | 22.5 | 20 | 793 |
| 12 | 503 | 661.5 | 25.5 | 11 | 784 |
| 13 | 519.5 | 380 | 26.5 | 13 | 754 |
| 14 | 571 | 572 | 19.5 | 17 | 754 |
| 15 | 555.5 | 380 | 18 | 13 | 511 |
| 16 | 591.5 | 572 | 10.5 | 17 | 478 |
| 17 | 432 | 583 | 10 | 17 | 449 |
| 18 | 495.5 | 382 | 13.5 | 11 | 400 |
| 19 | 495 | 569 | 12.5 | 12 | 360 |
| 20 | 533.5 | 572 | 10 | 17 | 360 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Assign technician`, `Select an available technician`, `Toyota Camry`, `JOB-TEST0007 · Full inspection · Full inspection`, `Technician A`, `t***@test.local`, `Technician B`, `u***@test.local`, `Reason (optional)`, `Reason`, `Cancel`, `Confirm`
- Actual: `Open`, `Assign technician`, `Select an available technician`, `Toyota Camry`, `JOB-TEST0007 · Full inspection · Full inspection`, `Technician A`, `t***@test.local`, `Technician B`, `u***@test.local`, `Reason (optional)`, `Reason`, `Cancel`, `Confirm`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

