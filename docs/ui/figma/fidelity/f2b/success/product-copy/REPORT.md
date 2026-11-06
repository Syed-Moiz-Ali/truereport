# Fidelity report — f2b-success-product-copy

- **Sample id:** `f2b-success-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/success-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/16_16._Post-Finalization_Success/16._Post-Finalization_Success@2x.png`
- **Reference crop (px):** {"x":40,"y":0,"width":780,"height":1768}
- **Logical size:** 390 × 884 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-06T11:35:40.567Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.86443; min 64×64 tile 0.2564 |
| Text | pass | 9 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.86443 |
| SSIM (worst 64×64 tile) | 0.2564 |
| RMSE (RGB 0–255) | 64.671 |
| MAE (RGB 0–255) | 25.804 |
| ΔE2000 mean | 7.142 |
| ΔE2000 median | 0.198 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.209 |
| ΔE2000 > 2 (JND) | 35.72% |
| ΔE2000 > 5 | 19.4% |
| ΔE2000 > 10 | 17.42% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 10.5 | 808 | 369 | 76 | 106619 |
| 2 | 11.5 | 731.5 | 366.5 | 71 | 96564 |
| 3 | 167.5 | 153 | 55 | 78 | 10873 |
| 4 | 223 | 314.5 | 41 | 29 | 2330 |
| 5 | 42 | 499.5 | 29 | 14.5 | 968 |
| 6 | 187.5 | 320 | 20 | 20 | 872 |
| 7 | 255 | 127.5 | 16 | 16 | 852 |
| 8 | 126.5 | 320 | 16 | 20 | 846 |
| 9 | 142 | 320 | 19 | 23 | 771 |
| 10 | 113 | 296.5 | 15.5 | 20 | 751 |
| 11 | 296.5 | 291.5 | 15.5 | 20 | 750 |
| 12 | 298.5 | 314.5 | 15.5 | 20.5 | 750 |
| 13 | 110.5 | 320 | 15.5 | 20 | 750 |
| 14 | 173.5 | 320 | 15.5 | 20 | 719 |
| 15 | 211.5 | 291 | 15 | 20 | 715 |
| 16 | 208.5 | 315 | 15 | 25 | 708 |
| 17 | 283 | 320 | 15 | 15 | 600 |
| 18 | 281 | 296.5 | 14.5 | 15 | 581 |
| 19 | 129.5 | 296.5 | 14.5 | 15 | 580 |
| 20 | 176.5 | 296.5 | 15.5 | 15 | 576 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `delivery` | 20, 376, 350, 76 | 20, 376, 350, 76 | 0 | pass |
| `cta` | 20, 808, 350, 56 | 20, 808, 350, 56 | 0 | pass |

## Text

- Expected: `JOB-2601`, `Finalized`, `Inspection finalized`, `Report status: Ready`, `WhatsApp`, `Delivery sent`, `·4352`, `17 / 40`, `Jobs`
- Actual: `JOB-2601`, `Finalized`, `Inspection finalized`, `Report status: Ready`, `WhatsApp`, `Delivery sent`, `VIN / Chassis`, `·4352`, `completed`, `17 / 40`, `Report`, `v1`, `Jobs`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

