# Fidelity report — f2b-success-product-copy

- **Sample id:** `f2b-success-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/success-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/16_16._Post-Finalization_Success/16._Post-Finalization_Success@2x.png`
- **Reference crop (px):** {"x":40,"y":0,"width":780,"height":1768}
- **Logical size:** 390 × 884 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-08T09:56:59.323Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.8.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.97101; min 64×64 tile 0.31831 |
| Text | pass | 7 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.97101 |
| SSIM (worst 64×64 tile) | 0.31831 |
| RMSE (RGB 0–255) | 16.024 |
| MAE (RGB 0–255) | 2.104 |
| ΔE2000 mean | 0.699 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.341 |
| ΔE2000 max | 85.209 |
| ΔE2000 > 2 (JND) | 2.66% |
| ΔE2000 > 5 | 1.74% |
| ΔE2000 > 10 | 1.44% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 247.5 | 352.5 | 99 | 14 | 2176 |
| 2 | 127.5 | 501.5 | 44 | 12.5 | 1376 |
| 3 | 88 | 501 | 38.5 | 13 | 1169 |
| 4 | 206 | 594 | 22 | 13 | 730 |
| 5 | 199 | 352.5 | 30 | 11.5 | 665 |
| 6 | 110 | 352.5 | 27.5 | 11.5 | 608 |
| 7 | 173.5 | 352.5 | 24.5 | 11.5 | 559 |
| 8 | 176.5 | 594.5 | 18.5 | 12.5 | 529 |
| 9 | 173.5 | 179.5 | 49 | 51.5 | 418 |
| 10 | 60 | 22.5 | 21 | 9 | 414 |
| 11 | 108 | 22.5 | 18.5 | 9 | 384 |
| 12 | 268 | 22.5 | 20.5 | 9 | 332 |
| 13 | 70.5 | 594.5 | 13.5 | 12 | 294 |
| 14 | 126 | 22.5 | 13 | 9 | 267 |
| 15 | 228.5 | 575 | 10.5 | 8.5 | 267 |
| 16 | 36.5 | 22.5 | 14.5 | 9 | 256 |
| 17 | 65 | 594 | 8 | 13 | 232 |
| 18 | 155 | 352.5 | 9.5 | 11.5 | 228 |
| 19 | 165 | 352.5 | 8 | 11.5 | 223 |
| 20 | 84.5 | 594.5 | 9 | 12 | 223 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `delivery` | 20, 399.5, 350, 145 | 20, 399.5, 350, 145 | 0 | pass |
| `cta` | 20, 732, 350, 56 | 20, 732, 350, 56 | 0 | pass |

## Text

- Expected: `JOB #JOB-2601`, `Finalized`, `Inspection Finalized`, `WhatsApp`, `·4352`, `ITEMS CHECKED`, `Back to Job List`
- Actual: `JOB #JOB-2601`, `Finalized`, `Inspection Finalized`, `Report #JOB-2601 has been locked and uploaded.`, `WhatsApp`, `Sent`, `Web Portal`, `Synced`, `VIN ENDING`, `·4352`, `ITEMS CHECKED`, `17 / 40`, `PDF SIZE`, `2.4 MB`, `Back to Job List`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

