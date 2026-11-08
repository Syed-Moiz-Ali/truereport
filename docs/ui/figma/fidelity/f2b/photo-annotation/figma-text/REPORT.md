# Fidelity report — f2b-photo-annotation-figma-text

- **Sample id:** `f2b-photo-annotation-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/photo-annotation-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/10_10._Photo_Annotation_&_Markup/10._Photo_Annotation_&_Markup@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":1768}
- **Logical size:** 390 × 884 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-08T06:29:07.956Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98627; min 64×64 tile 0.76632 |
| Text | pass | 13 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 4/4 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98627 |
| SSIM (worst 64×64 tile) | 0.76632 |
| RMSE (RGB 0–255) | 8.877 |
| MAE (RGB 0–255) | 1.531 |
| ΔE2000 mean | 0.58 |
| ΔE2000 median | 0.199 |
| ΔE2000 p95 | 1.392 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 2.78% |
| ΔE2000 > 5 | 1.13% |
| ΔE2000 > 10 | 0.79% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 152.5 | 365.5 | 95 | 26.5 | 326 |
| 2 | 163 | 358 | 83.5 | 29 | 288 |
| 3 | 50 | 139 | 15 | 14 | 281 |
| 4 | 76.5 | 141.5 | 9 | 8.5 | 211 |
| 5 | 290 | 670.5 | 23 | 17.5 | 172 |
| 6 | 291.5 | 677 | 23 | 17.5 | 172 |
| 7 | 103 | 141.5 | 8 | 9 | 150 |
| 8 | 111.5 | 141.5 | 6.5 | 9 | 150 |
| 9 | 138 | 141.5 | 7.5 | 8.5 | 148 |
| 10 | 30.5 | 78 | 12 | 16 | 123 |
| 11 | 299 | 675 | 11 | 11 | 123 |
| 12 | 167 | 133 | 13 | 23.5 | 122 |
| 13 | 301.5 | 706 | 7.5 | 7.5 | 122 |
| 14 | 189.5 | 680 | 14.5 | 11 | 112 |
| 15 | 78.5 | 672.5 | 19.5 | 20 | 109 |
| 16 | 86 | 141.5 | 8.5 | 8.5 | 101 |
| 17 | 146.5 | 141.5 | 6.5 | 8.5 | 100 |
| 18 | 80.5 | 677.5 | 12.5 | 13 | 99 |
| 19 | 118.5 | 141.5 | 6.5 | 7 | 98 |
| 20 | 126 | 141.5 | 6.5 | 8.5 | 95 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `card` | 20, 112, 350, 437.5 | 20, 112, 350, 437.5 | 0 | pass |
| `tools` | 20, 569.5, 350, 260 | 20, 569.5, 350, 260 | 0 | pass |
| `draw` | 40, 653.5, 95.3, 80 | 40, 653.5, 95.3, 80 | 0 | pass |
| `save` | 40, 753.5, 310, 56 | 40, 753.5, 310, 56 | 0 | pass |

## Text

- Expected: `Damage Markup Studio`, `Front Bumper Inspection`, `Markup Active`, `IMG_0842.HEIC`, `1 Defect Callout`, `0.8 mm Scuff`, `Annotation Tools`, `Tap draw to circle surface damages`, `4.0 pt`, `Draw`, `Undo`, `Crop`, `Save Photo`
- Actual: `Front Bumper Inspection`, `Markup Active`, `IMG_0842.HEIC`, `1 Defect Callout`, `0.8 mm Scuff`, `Annotation Tools`, `Tap draw to circle surface damages`, `4.0 pt`, `Draw`, `Undo`, `Crop`, `Save Photo`, `Damage Markup Studio`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

