# Fidelity report — f2b-photo-annotation-product-copy

- **Sample id:** `f2b-photo-annotation-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/photo-annotation-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/10_10._Photo_Annotation_&_Markup/10._Photo_Annotation_&_Markup@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":1768}
- **Logical size:** 390 × 884 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-08T06:20:30.469Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.81018; min 64×64 tile 0.02475 |
| Text | pass | 6 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 4/4 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.81018 |
| SSIM (worst 64×64 tile) | 0.02475 |
| RMSE (RGB 0–255) | 77.722 |
| MAE (RGB 0–255) | 40.081 |
| ΔE2000 mean | 13.797 |
| ΔE2000 median | 0.83 |
| ΔE2000 p95 | 74.725 |
| ΔE2000 max | 94.873 |
| ΔE2000 > 2 (JND) | 44.11% |
| ΔE2000 > 5 | 36.83% |
| ΔE2000 > 10 | 26.61% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 20 | 112 | 350 | 437.5 | 440833 |
| 2 | 131 | 282 | 123.5 | 105 | 40265 |
| 3 | 69 | 25.5 | 82.5 | 17.5 | 2457 |
| 4 | 105.5 | 186.5 | 30 | 22.5 | 1533 |
| 5 | 57 | 82 | 41 | 9.5 | 775 |
| 6 | 144.5 | 199 | 18 | 13.5 | 678 |
| 7 | 77 | 141.5 | 20.5 | 9 | 449 |
| 8 | 145 | 141.5 | 20 | 9 | 431 |
| 9 | 194.5 | 29 | 11 | 14 | 354 |
| 10 | 104 | 141.5 | 16.5 | 9.5 | 347 |
| 11 | 208.5 | 25 | 10.5 | 14.5 | 342 |
| 12 | 237 | 25 | 10.5 | 14.5 | 341 |
| 13 | 67.5 | 185 | 19 | 9 | 331 |
| 14 | 119.5 | 141.5 | 14 | 8.5 | 316 |
| 15 | 119.5 | 216 | 13 | 9.5 | 304 |
| 16 | 50 | 139 | 15 | 14 | 283 |
| 17 | 157.5 | 29 | 9.5 | 10.5 | 282 |
| 18 | 174.5 | 25 | 9 | 14 | 278 |
| 19 | 82 | 237 | 12.5 | 7 | 278 |
| 20 | 252.5 | 29 | 11 | 10.5 | 274 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `card` | 20, 112, 350, 437.5 | 20, 112, 350, 437.5 | 0 | pass |
| `tools` | 20, 569.5, 350, 260 | 20, 569.5, 350, 260 | 0 | pass |
| `draw` | 40, 653.5, 95.3, 80 | 40, 653.5, 95.3, 80 | 0 | pass |
| `save` | 40, 753.5, 310, 56 | 40, 753.5, 310, 56 | 0 | pass |

## Text

- Expected: `PHOTO_01.JPG`, `Annotation Tools`, `Draw`, `Undo`, `Crop`, `Save Photo`
- Actual: `Photos`, `Markup Active`, `PHOTO_01.JPG`, `1 Defect`, `Scuff`, `Annotation Tools`, `Tap draw to circle surface damages`, `4.0 pt`, `Draw`, `Undo`, `Crop`, `Save Photo`, `Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

