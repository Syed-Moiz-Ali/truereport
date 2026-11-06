# Fidelity report — f2b-offline-sync-figma-text

- **Sample id:** `f2b-offline-sync-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/offline-sync-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/14_15._Offline_Sync_Queue/15._Offline_Sync_Queue@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2724}
- **Logical size:** 390 × 1362 @ DPR 2
- **Compared pixels:** 780 × 2724
- **Generated:** 2026-11-06T11:35:32.097Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.8048; min 64×64 tile 0.12656 |
| Text | pass | 10 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.8048 |
| SSIM (worst 64×64 tile) | 0.12656 |
| RMSE (RGB 0–255) | 58.859 |
| MAE (RGB 0–255) | 22.183 |
| ΔE2000 mean | 6.514 |
| ΔE2000 median | 0.396 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 29.02% |
| ΔE2000 > 5 | 20.64% |
| ΔE2000 > 10 | 14.53% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 10.5 | 777.5 | 369 | 90 | 116403 |
| 2 | 11.5 | 1051 | 366.5 | 86 | 107326 |
| 3 | 20 | 239 | 350 | 93 | 92665 |
| 4 | 75 | 79 | 148.5 | 40.5 | 7546 |
| 5 | 20.5 | 156 | 349 | 28.5 | 5450 |
| 6 | 276.5 | 186 | 73.5 | 32 | 3137 |
| 7 | 45.5 | 459.5 | 86 | 19 | 3066 |
| 8 | 40 | 685.5 | 103.5 | 6.5 | 2659 |
| 9 | 68 | 182 | 53.5 | 16.5 | 1947 |
| 10 | 130 | 182 | 60.5 | 16.5 | 1938 |
| 11 | 95 | 24 | 46.5 | 19 | 1587 |
| 12 | 128.5 | 612 | 35.5 | 36.5 | 1585 |
| 13 | 192 | 182 | 49 | 16.5 | 1496 |
| 14 | 181.5 | 107 | 51.5 | 14.5 | 1182 |
| 15 | 334 | 16 | 36 | 32 | 1178 |
| 16 | 68.5 | 24 | 29.5 | 22 | 975 |
| 17 | 68.5 | 205 | 28 | 15.5 | 925 |
| 18 | 105.5 | 540.5 | 30.5 | 13 | 901 |
| 19 | 156 | 28.5 | 22.5 | 13 | 712 |
| 20 | 36.5 | 375 | 15 | 24.5 | 691 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `queue` | 20, 494, 350, 80 | 20, 494, 350, 80 | 0 | pass |
| `retry` | 20, 782, 350, 56 | 20, 782, 350, 56 | 0 | pass |

## Text

- Expected: `Sync Status`, `Upload Queue`, `Retry Sync Now`, `Queued`, `Jobs • JOB-5A0001`, `Jobs • JOB-5A0002`, `3`, `Inspection items`, `Photographic Evidence`, `Save Defect`
- Actual: `Sync Status`, `Offline. Work will be saved on this phone.`, `OFFLINE
SYNC`, `Offline. Work will be saved on this phone.`, `OFFLINE
SYNC`, `Changes saved on this phone`, `CHANGES SAVED ON THIS PHONE`, `3`, `Inspection items`, `UPLOAD QUEUE`, `2`, `Inspection Queue`, `Upload Queue`, `Changes saved on this phone`, `Photographic Evidence`, `Jobs • JOB-5A0001`, `Queued`, `Save Defect`, `Jobs • JOB-5A0001`, `Queued`, `Save Defect`, `Jobs • JOB-5A0002`, `Queued`, `Retry Sync Now`, `Changes saved on this phone`, `Sync Status`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

