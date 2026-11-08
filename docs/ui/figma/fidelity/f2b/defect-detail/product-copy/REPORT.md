# Fidelity report — f2b-defect-detail-product-copy

- **Sample id:** `f2b-defect-detail-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/defect-detail-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/9._Defect_Detail_&_Evidence@2x.png`
- **Reference crop (px):** {"x":120,"y":0,"width":780,"height":2063}
- **Logical size:** 390 × 1031.67 @ DPR 2
- **Compared pixels:** 780 × 2063
- **Generated:** 2026-11-08T06:20:41.915Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.91008; min 64×64 tile 0.3214 |
| Text | pass | 11 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.91008 |
| SSIM (worst 64×64 tile) | 0.3214 |
| RMSE (RGB 0–255) | 35.602 |
| MAE (RGB 0–255) | 10.472 |
| ΔE2000 mean | 3.067 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 26.204 |
| ΔE2000 max | 95.657 |
| ΔE2000 > 2 (JND) | 13.3% |
| ΔE2000 > 5 | 9.4% |
| ΔE2000 > 10 | 8.11% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 20 | 668 | 167 | 167 | 102527 |
| 2 | 62 | 395 | 80 | 25.5 | 3554 |
| 3 | 252 | 767.5 | 75.5 | 14.5 | 2019 |
| 4 | 144 | 395 | 33.5 | 20.5 | 1749 |
| 5 | 173 | 967 | 64.5 | 11 | 1630 |
| 6 | 22 | 398 | 42.5 | 17.5 | 1544 |
| 7 | 174 | 193.5 | 41.5 | 11 | 1249 |
| 8 | 130.5 | 967 | 42 | 11 | 1210 |
| 9 | 30.5 | 446.5 | 32.5 | 9 | 666 |
| 10 | 45.5 | 372.5 | 28.5 | 8.5 | 664 |
| 11 | 228.5 | 27.5 | 28 | 9 | 635 |
| 12 | 223.5 | 400 | 14.5 | 15.5 | 617 |
| 13 | 174.5 | 484 | 24.5 | 9 | 595 |
| 14 | 209 | 400 | 13.5 | 15 | 577 |
| 15 | 160 | 27.5 | 27.5 | 9 | 563 |
| 16 | 203.5 | 27.5 | 25 | 9 | 550 |
| 17 | 65 | 882.5 | 26 | 10 | 535 |
| 18 | 238.5 | 400 | 12 | 15.5 | 509 |
| 19 | 251.5 | 400 | 12 | 15.5 | 509 |
| 20 | 258.5 | 788.5 | 23.5 | 10.5 | 483 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `segmented` | 20, 462, 350, 52 | 20, 462, 350, 52 | 0 | pass |
| `save` | 20, 943.7, 350, 56 | 20, 944.2, 350, 56 | 0.5 | pass |

## Text

- Expected: `Braking`, `Brake pad thickness`, `RESULT`, `No issue observed`, `Attention recommended`, `Defect found`, `SEVERITY`, `PHOTOS`, `Add photo`, `Note`, `SAVE ANSWER`
- Actual: `⁦JOB-2601⁩ • ASSIGNED`, `PIN #03`, `Braking`, `Brake pad thickness`, `RESULT`, `No issue observed`, `Attention recommended`, `Defect found`, `SEVERITY`, `1 Selected`, `Dent / Crease`, `Surface Scratch`, `Paint Chip`, `PHOTOS`, `0 of 1 Required`, `Tagged`, `Add photo`, `Add at least one photo.`, `Note`, `SAVE ANSWER`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

