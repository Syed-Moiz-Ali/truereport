# Fidelity report — f2b-success-figma-text

- **Sample id:** `f2b-success-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/success-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/16_16._Post-Finalization_Success/16._Post-Finalization_Success@2x.png`
- **Reference crop (px):** {"x":40,"y":0,"width":780,"height":1768}
- **Logical size:** 390 × 884 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-06T11:35:38.373Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.86278; min 64×64 tile 0.25611 |
| Text | pass | 9 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.86278 |
| SSIM (worst 64×64 tile) | 0.25611 |
| RMSE (RGB 0–255) | 64.463 |
| MAE (RGB 0–255) | 25.663 |
| ΔE2000 mean | 7.113 |
| ΔE2000 median | 0.198 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.209 |
| ΔE2000 > 2 (JND) | 35.67% |
| ΔE2000 > 5 | 19.32% |
| ΔE2000 > 10 | 17.34% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 10.5 | 808 | 369 | 76 | 105464 |
| 2 | 11.5 | 731.5 | 366.5 | 71 | 96564 |
| 3 | 167.5 | 153 | 55 | 78 | 10873 |
| 4 | 223 | 314.5 | 41 | 29 | 2330 |
| 5 | 42.5 | 499.5 | 28 | 14.5 | 989 |
| 6 | 187.5 | 320 | 20 | 20 | 872 |
| 7 | 255 | 127.5 | 16 | 16 | 852 |
| 8 | 126.5 | 320 | 16 | 20 | 846 |
| 9 | 142 | 320 | 19 | 23 | 771 |
| 10 | 110.5 | 296.5 | 16 | 20 | 758 |
| 11 | 299 | 291.5 | 15.5 | 20 | 751 |
| 12 | 298.5 | 314.5 | 15.5 | 20.5 | 750 |
| 13 | 110.5 | 320 | 15.5 | 20 | 750 |
| 14 | 173.5 | 320 | 15.5 | 20 | 719 |
| 15 | 208.5 | 315 | 15 | 25 | 708 |
| 16 | 283 | 320 | 15 | 15 | 600 |
| 17 | 244.5 | 296.5 | 13.5 | 15 | 585 |
| 18 | 210 | 291.5 | 13.5 | 19.5 | 582 |
| 19 | 127 | 296.5 | 14.5 | 15 | 580 |
| 20 | 283.5 | 296.5 | 14.5 | 15 | 580 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `delivery` | 20, 376, 350, 76 | 20, 376, 350, 76 | 0 | pass |
| `cta` | 20, 808, 350, 56 | 20, 808, 350, 56 | 0 | pass |

## Text

- Expected: `JOB-5A0001`, `Finalized`, `Inspection Finalized`, `Report status: Ready`, `WhatsApp`, `Delivery sent`, `·2831`, `3 / 6`, `Back to Job List`
- Actual: `JOB-5A0001`, `Finalized`, `Inspection Finalized`, `Report status: Ready`, `WhatsApp`, `Delivery sent`, `VIN / Chassis`, `·2831`, `completed`, `3 / 6`, `Report`, `v1`, `Back to Job List`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

