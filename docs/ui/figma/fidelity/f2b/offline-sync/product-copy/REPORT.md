# Fidelity report — f2b-offline-sync-product-copy

- **Sample id:** `f2b-offline-sync-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/offline-sync-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/14_15._Offline_Sync_Queue/15._Offline_Sync_Queue@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2724}
- **Logical size:** 390 × 1362 @ DPR 2
- **Compared pixels:** 780 × 2724
- **Generated:** 2026-11-06T11:35:36.187Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.81609; min 64×64 tile 0.13874 |
| Text | pass | 9 expected string(s) present |
| Forbidden terms | fail | 2 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.81609 |
| SSIM (worst 64×64 tile) | 0.13874 |
| RMSE (RGB 0–255) | 57.917 |
| MAE (RGB 0–255) | 21.31 |
| ΔE2000 mean | 6.25 |
| ΔE2000 median | 0.202 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 26.87% |
| ΔE2000 > 5 | 20.09% |
| ΔE2000 > 10 | 14.12% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 10.5 | 685.5 | 369 | 89.5 | 115467 |
| 2 | 11.5 | 1051 | 366.5 | 86 | 107326 |
| 3 | 20 | 239 | 350 | 93 | 92665 |
| 4 | 20.5 | 156 | 349 | 28.5 | 5450 |
| 5 | 75 | 79 | 80 | 40.5 | 4085 |
| 6 | 276.5 | 186 | 73.5 | 32 | 3137 |
| 7 | 68 | 182 | 53.5 | 16.5 | 1947 |
| 8 | 130 | 182 | 60.5 | 16.5 | 1938 |
| 9 | 31.5 | 459.5 | 46 | 21.5 | 1843 |
| 10 | 192 | 182 | 49 | 16.5 | 1496 |
| 11 | 78 | 459.5 | 45.5 | 17.5 | 1442 |
| 12 | 181.5 | 107 | 51.5 | 14.5 | 1182 |
| 13 | 334 | 16 | 36 | 32 | 1178 |
| 14 | 68.5 | 24 | 29.5 | 22 | 974 |
| 15 | 137 | 615 | 27 | 33.5 | 941 |
| 16 | 68.5 | 205 | 28 | 15.5 | 925 |
| 17 | 105.5 | 540.5 | 30.5 | 13 | 901 |
| 18 | 48 | 618.5 | 19 | 18.5 | 714 |
| 19 | 95 | 28.5 | 24 | 13 | 697 |
| 20 | 29 | 23 | 18 | 18 | 666 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `queue` | 20, 494, 350, 80 | 20, 494, 350, 80 | 0 | pass |
| `retry` | 20, 690, 350, 56 | 20, 690, 350, 56 | 0 | pass |

## Text

- Expected: `Sync`, `Sync queue`, `Sync now`, `Queued`, `Jobs • JOB-2601`, `Save answer`, `Photos`, `2`, `Inspection items`
- Actual: `Sync`, `Offline. Work will be saved on this phone.`, `OFFLINE
SYNC`, `Offline. Work will be saved on this phone.`, `OFFLINE
SYNC`, `Changes saved on this phone`, `CHANGES SAVED ON THIS PHONE`, `2`, `Inspection items`, `SYNC QUEUE`, `1`, `Inspection Queue`, `Sync queue`, `Changes saved on this phone`, `Save answer`, `Jobs • JOB-2601`, `Queued`, `Photos`, `Jobs • JOB-2601`, `Queued`, `Sync now`, `Changes saved on this phone`, `Sync`

### Forbidden-term matches

- **queued** (term) matched `Queued`: …Save answer Jobs • JOB-2601 Queued Photos Jobs • JOB-2601 Queu…
- **queued** (term) matched `Queued`: …eued Photos Jobs • JOB-2601 Queued Sync now Changes saved on t…

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

