# Fidelity report — f2b3-defect-detail-level1

- **Sample id:** `f2b3-defect-detail-level1`
- **Batch:** `f2b3-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b3/defect-detail-level1.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/9._Defect_Detail_&_Evidence@2x.png`
- **Reference crop (px):** {"x":120,"y":0,"width":780,"height":2063}
- **Logical size:** 390 × 1031.67 @ DPR 2
- **Compared pixels:** 780 × 2063
- **Generated:** 2026-11-08T02:47:16.703Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98261; min 64×64 tile 0.8282 |
| Text | pass | 20 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98261 |
| SSIM (worst 64×64 tile) | 0.8282 |
| RMSE (RGB 0–255) | 8.942 |
| MAE (RGB 0–255) | 1.622 |
| ΔE2000 mean | 0.524 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.642 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 3.6% |
| ΔE2000 > 5 | 1.63% |
| ΔE2000 > 10 | 1.12% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 174 | 193.5 | 41.5 | 11 | 1249 |
| 2 | 20 | 835 | 167 | 0.5 | 334 |
| 3 | 21 | 395 | 14 | 20 | 301 |
| 4 | 144 | 395 | 17 | 20 | 168 |
| 5 | 337 | 23 | 18.5 | 18.5 | 159 |
| 6 | 344 | 388 | 12 | 5.5 | 158 |
| 7 | 60.5 | 400 | 13.5 | 15 | 152 |
| 8 | 157 | 507.5 | 76 | 0.5 | 152 |
| 9 | 157.5 | 467.5 | 75 | 0.5 | 150 |
| 10 | 90 | 395 | 13 | 20 | 139 |
| 11 | 138.5 | 652.5 | 7.5 | 9 | 133 |
| 12 | 191.5 | 566.5 | 8.5 | 9.5 | 132 |
| 13 | 32.5 | 825.5 | 60.5 | 2 | 129 |
| 14 | 214.5 | 569 | 6 | 7 | 120 |
| 15 | 36 | 886 | 13 | 10 | 119 |
| 16 | 36 | 568.5 | 9.5 | 8.5 | 118 |
| 17 | 20.5 | 652.5 | 6.5 | 9 | 116 |
| 18 | 46.5 | 400 | 13 | 15.5 | 114 |
| 19 | 164.5 | 400 | 13 | 15.5 | 114 |
| 20 | 66.5 | 815.5 | 6.5 | 9 | 112 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `segmented` | 20, 462, 350, 52 | 20, 462, 350, 52 | 0 | pass |
| `save` | 20, 943.7, 350, 56 | 20, 944.2, 350, 56 | 0.5 | pass |

## Text

- Expected: `BAY 04 • IN PROGRESS`, `PIN #03`, `EXTERIOR BODYWORK`, `Front Left Door`, `INSPECTION STATUS`, `Pass`, `Minor`, `Major`, `DEFECT CLASSIFICATION`, `1 Selected`, `Dent / Crease`, `Surface Scratch`, `Paint Chip`, `PHOTOGRAPHIC EVIDENCE`, `1 of 4 Required`, `Tagged`, `Take a photo`, `Tap to capture`, `Add defect notes (e.g. 2.5cm door ding)...`, `SAVE DEFECT`
- Actual: `BAY 04 • IN PROGRESS`, `PIN #03`, `EXTERIOR BODYWORK`, `Front Left Door`, `INSPECTION STATUS`, `Pass`, `Minor`, `Major`, `DEFECT CLASSIFICATION`, `1 Selected`, `Dent / Crease`, `Surface Scratch`, `Paint Chip`, `PHOTOGRAPHIC EVIDENCE`, `1 of 4 Required`, `Tagged`, `Take a photo`, `Tap to capture`, `Add defect notes (e.g. 2.5cm door ding)...`, `SAVE DEFECT`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

