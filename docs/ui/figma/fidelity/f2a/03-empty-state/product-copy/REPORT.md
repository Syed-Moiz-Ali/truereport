# Fidelity report — F2-A 03-empty-state - real product copy

- **Sample id:** `03-empty-state-product-copy`
- **Batch:** `f2a-technician-screens-1-7`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a/03-empty-state-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/03_3._Empty_State_Dashboard/3._Empty_State_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":1768}
- **Logical size:** 390 × 883.75 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-05T14:57:59.335Z
- **Owner:** fidelity-auditor

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.85336; min 64×64 tile 0.2271 |
| Text | pass | 8 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.85336 |
| SSIM (worst 64×64 tile) | 0.2271 |
| RMSE (RGB 0–255) | 44.438 |
| MAE (RGB 0–255) | 13.47 |
| ΔE2000 mean | 4.788 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 29.041 |
| ΔE2000 max | 94.907 |
| ΔE2000 > 2 (JND) | 30.18% |
| ΔE2000 > 5 | 11.47% |
| ΔE2000 > 10 | 10.59% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 52 | 488 | 286 | 56 | 61589 |
| 2 | 141.5 | 394 | 107 | 49 | 13455 |
| 3 | 19.5 | 72 | 49 | 60 | 8613 |
| 4 | 330 | 12 | 40 | 40 | 5051 |
| 5 | 12 | 16 | 48.5 | 32 | 3880 |
| 6 | 178.5 | 297.5 | 33 | 26 | 2882 |
| 7 | 177 | 238.5 | 36 | 43.5 | 2821 |
| 8 | 60.5 | 818 | 33.5 | 33.5 | 2018 |
| 9 | 115.5 | 25.5 | 47 | 17.5 | 1429 |
| 10 | 298 | 818 | 32.5 | 33 | 1190 |
| 11 | 81 | 111.5 | 26 | 20 | 1042 |
| 12 | 80.5 | 25.5 | 34.5 | 14 | 1040 |
| 13 | 21.5 | 177.5 | 17 | 19.5 | 846 |
| 14 | 102 | 89 | 33 | 11.5 | 836 |
| 15 | 149 | 111.5 | 16 | 19.5 | 800 |
| 16 | 231.5 | 571 | 20 | 19 | 747 |
| 17 | 74 | 177 | 15.5 | 20.5 | 745 |
| 18 | 170 | 571.5 | 18.5 | 18.5 | 739 |
| 19 | 94.5 | 177.5 | 18 | 19.5 | 678 |
| 20 | 47.5 | 726.5 | 17 | 18.5 | 661 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Welcome back,`, `Layla Hassan`, `0 in queue`, `You are all caught up`, `No pending inspections are assigned to you.`, `Refresh queue`, `Walk-in job`, `No changes waiting to sync`
- Actual: `LH`, `Welcome back,`, `Layla Hassan`, `0 in queue`, `You are all caught up`, `No pending inspections are assigned to you.`, `Refresh queue`, `Walk-in job`, `No changes waiting to sync`, `TR`, `Assigned jobs`, `LH`, `Jobs`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Real product copy and neutral test data. Removed: SHIFT/Bay pills, TODAY SUMMARY, 14 Completed, 100% Pass Rate (no data; pass rate is a forbidden score), Synced just now (no receipt state). Sync line shows real pending count; Walk-in job action retained. Removed elements leave intentional empty space below the CTA.

