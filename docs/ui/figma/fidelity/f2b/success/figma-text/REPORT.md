# Fidelity report — f2b-success-figma-text

- **Sample id:** `f2b-success-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/success-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/16_16._Post-Finalization_Success/16._Post-Finalization_Success@2x.png`
- **Reference crop (px):** {"x":40,"y":0,"width":780,"height":1768}
- **Logical size:** 390 × 884 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-08T09:56:28.204Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.99074; min 64×64 tile 0.81279 |
| Text | pass | 15 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.99074 |
| SSIM (worst 64×64 tile) | 0.81279 |
| RMSE (RGB 0–255) | 7.125 |
| MAE (RGB 0–255) | 0.933 |
| ΔE2000 mean | 0.319 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.242 |
| ΔE2000 max | 85.209 |
| ΔE2000 > 2 (JND) | 2.04% |
| ΔE2000 > 5 | 1.09% |
| ΔE2000 > 10 | 0.75% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 173.5 | 179.5 | 49 | 51.5 | 418 |
| 2 | 179.5 | 197 | 30.5 | 19.5 | 179 |
| 3 | 169.5 | 22.5 | 7.5 | 9 | 129 |
| 4 | 243.5 | 753.5 | 13.5 | 13 | 110 |
| 5 | 60 | 22.5 | 8 | 8.5 | 108 |
| 6 | 45 | 22.5 | 6 | 8.5 | 99 |
| 7 | 49.5 | 429.5 | 17 | 16.5 | 98 |
| 8 | 49 | 506.5 | 18.5 | 7 | 93 |
| 9 | 130 | 22.5 | 6.5 | 9 | 91 |
| 10 | 178 | 22.5 | 7 | 7 | 84 |
| 11 | 73.5 | 22.5 | 6 | 9 | 82 |
| 12 | 186.5 | 22.5 | 6 | 8.5 | 79 |
| 13 | 54 | 23 | 5.5 | 8 | 77 |
| 14 | 142.5 | 23 | 6 | 8 | 74 |
| 15 | 231.5 | 575 | 6 | 8.5 | 72 |
| 16 | 110.5 | 320 | 6 | 20 | 71 |
| 17 | 245 | 320 | 12 | 6 | 71 |
| 18 | 154 | 22.5 | 8.5 | 5.5 | 70 |
| 19 | 149 | 435.5 | 9.5 | 12.5 | 69 |
| 20 | 271 | 320 | 12 | 8.5 | 68 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `delivery` | 20, 399.5, 350, 145 | 20, 399.5, 350, 145 | 0 | pass |
| `cta` | 20, 732, 350, 56 | 20, 732, 350, 56 | 0 | pass |

## Text

- Expected: `SERVICE SESSION #1042`, `Locked & Signed`, `Inspection Finalized`, `Report #1042 has been locked and uploaded.`, `WhatsApp`, `Sent`, `Fleet Portal`, `Synced`, `VIN ENDING`, `·8492`, `ITEMS VERIFIED`, `38 / 38`, `PDF SIZE`, `2.4 MB`, `Back to Job List`
- Actual: `SERVICE SESSION #1042`, `Locked & Signed`, `Inspection Finalized`, `Report #1042 has been locked and uploaded.`, `WhatsApp`, `Sent`, `Fleet Portal`, `Synced`, `VIN ENDING`, `·8492`, `ITEMS VERIFIED`, `38 / 38`, `PDF SIZE`, `2.4 MB`, `Back to Job List`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

