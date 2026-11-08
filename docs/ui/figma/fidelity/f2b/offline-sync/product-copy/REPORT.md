# Fidelity report — f2b-offline-sync-product-copy

- **Sample id:** `f2b-offline-sync-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/offline-sync-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/14_15._Offline_Sync_Queue/15._Offline_Sync_Queue@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2724}
- **Logical size:** 390 × 1362 @ DPR 2
- **Compared pixels:** 780 × 2724
- **Generated:** 2026-11-08T09:44:10.040Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.8.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.89719; min 64×64 tile 0.27576 |
| Text | pass | 4 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.89719 |
| SSIM (worst 64×64 tile) | 0.27576 |
| RMSE (RGB 0–255) | 32.316 |
| MAE (RGB 0–255) | 6.947 |
| ΔE2000 mean | 2.231 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 2.506 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 5.71% |
| ΔE2000 > 5 | 4.62% |
| ΔE2000 > 10 | 4.14% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 82.5 | 829.5 | 61 | 13 | 1746 |
| 2 | 24.5 | 539 | 49.5 | 18 | 1576 |
| 3 | 89.5 | 939.5 | 62 | 16 | 1573 |
| 4 | 83 | 595.5 | 55 | 16 | 1534 |
| 5 | 68 | 185.5 | 53.5 | 13 | 1476 |
| 6 | 122.5 | 185.5 | 53.5 | 16 | 1462 |
| 7 | 192 | 185.5 | 47 | 13 | 1299 |
| 8 | 121.5 | 850 | 56 | 10.5 | 1262 |
| 9 | 105.5 | 1124 | 48.5 | 13 | 1089 |
| 10 | 117.5 | 638 | 46.5 | 10.5 | 1081 |
| 11 | 36.5 | 459 | 22 | 17.5 | 917 |
| 12 | 182.5 | 110.5 | 43.5 | 11 | 837 |
| 13 | 140 | 83 | 15 | 20.5 | 741 |
| 14 | 169 | 1124.5 | 33 | 10 | 663 |
| 15 | 123.5 | 24 | 17.5 | 19 | 652 |
| 16 | 311.5 | 596.5 | 28 | 11 | 616 |
| 17 | 166.5 | 88.5 | 13 | 15 | 593 |
| 18 | 314.5 | 542 | 33.5 | 10.5 | 592 |
| 19 | 47 | 1051.5 | 296 | 0.5 | 592 |
| 20 | 191 | 88.5 | 13.5 | 15 | 576 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `queue` | 20, 569.9, 350, 222 | 20, 569.9, 350, 222 | 0 | pass |
| `retry` | 20, 1051.9, 350, 56 | 20, 1051.9, 350, 56 | 0 | pass |

## Text

- Expected: `Sync`, `Sync now`, `Inspections`, `Waiting`
- Actual: `Sync`, `Offline. Work will be saved on this phone.`, `OFFLINE
SYNC`, `Offline. Work will be saved on this phone.`, `Offline`, `Offline. Work will be saved on this phone.`, `BUFFERED CACHE`, `2`, `Local items`, `PENDING BATCH`, `2`, `Inspections`, `OFFLINE
SYNC`, `Sync`, `OFFLINE
SYNC`, `answer`, `Job #JOB-2601`, `Waiting`, `2 items`, `1 remaining`, `Transfer Speed`, `0.0 KB/s`, `Pending Jobs`, `1 in Line`, `evidence`, `Job #JOB-2601`, `Waiting`, `18.4 MB`, `Photo Markups`, `Waiting`, `6.2 MB`, `Sync now`, `Changes saved on this phone`, `Sync`, `Intake`, `Completed`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

