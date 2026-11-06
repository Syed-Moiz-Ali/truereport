# Fidelity report — f2a1-empty-state-product-copy

- **Sample id:** `f2a1-empty-state-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/empty-state-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/03_3._Empty_State_Dashboard/3._Empty_State_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":1768}
- **Logical size:** 390 × 883.75 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-06T04:35:57.251Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.93294; min 64×64 tile 0.36632 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.93294 |
| SSIM (worst 64×64 tile) | 0.36632 |
| RMSE (RGB 0–255) | 29.588 |
| MAE (RGB 0–255) | 5.744 |
| ΔE2000 mean | 1.875 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 2.347 |
| ΔE2000 max | 97.017 |
| ΔE2000 > 2 (JND) | 5.37% |
| ΔE2000 > 5 | 3.9% |
| ΔE2000 > 10 | 3.29% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 21 | 177 | 112 | 26 | 5049 |
| 2 | 188 | 450.5 | 112.5 | 22 | 4731 |
| 3 | 0 | 48 | 83 | 16 | 3518 |
| 4 | 332 | 16 | 32 | 32 | 3278 |
| 5 | 87 | 451 | 79.5 | 17 | 3059 |
| 6 | 88 | 737.5 | 81 | 16.5 | 2307 |
| 7 | 181 | 579 | 72.5 | 14 | 1739 |
| 8 | 128 | 182.5 | 47 | 15 | 1605 |
| 9 | 61 | 487.5 | 63.5 | 14 | 1524 |
| 10 | 235.5 | 490.5 | 55.5 | 8.5 | 1206 |
| 11 | 189.5 | 488 | 45.5 | 13.5 | 1070 |
| 12 | 277.5 | 731.5 | 37.5 | 9.5 | 862 |
| 13 | 168.5 | 737.5 | 26 | 13.5 | 695 |
| 14 | 176.5 | 512 | 32.5 | 13 | 653 |
| 15 | 166 | 450.5 | 16.5 | 17.5 | 641 |
| 16 | 163.5 | 488 | 25 | 13.5 | 611 |
| 17 | 131.5 | 577 | 17.5 | 13.5 | 583 |
| 18 | 146.5 | 91.5 | 26 | 8.5 | 576 |
| 19 | 47.5 | 726.5 | 17 | 18.5 | 571 |
| 20 | 34 | 91 | 21.5 | 12 | 534 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `LH`, `QUEUE EMPTY`, `0 JOBS`, `Welcome back,`, `Layla Hassan`, `0 IN QUEUE`, `You are all caught up`, `No pending inspections are assigned to you.`, `Refresh queue`, `TODAY'S SUMMARY`, `0 Completed`, `Coverage`, `Inspection Queue`, `ONLINE
SYNC`, `LH`, `Jobs`, `Finalized`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

