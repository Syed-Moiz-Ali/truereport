# Fidelity report — f2b3-defect-detail-level1

- **Sample id:** `f2b3-defect-detail-level1`
- **Batch:** `f2b3-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b3/defect-detail-level1.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/9._Defect_Detail_&_Evidence@2x.png`
- **Reference crop (px):** {"x":120,"y":0,"width":780,"height":2063}
- **Logical size:** 390 × 1031.67 @ DPR 2
- **Compared pixels:** 780 × 2063
- **Generated:** 2026-11-06T13:23:49.716Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.97362; min 64×64 tile 0.76533 |
| Text | pass | 20 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.97362 |
| SSIM (worst 64×64 tile) | 0.76533 |
| RMSE (RGB 0–255) | 10.974 |
| MAE (RGB 0–255) | 2 |
| ΔE2000 mean | 0.647 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.872 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 4.58% |
| ΔE2000 > 5 | 2.15% |
| ΔE2000 > 10 | 1.4% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 168.5 | 168 | 53 | 36.5 | 3239 |
| 2 | 141 | 492.5 | 108 | 20 | 1836 |
| 3 | 26 | 943 | 338 | 11 | 1343 |
| 4 | 27 | 990 | 336 | 10 | 1332 |
| 5 | 20 | 834.5 | 167 | 0.5 | 334 |
| 6 | 21 | 395 | 14 | 20 | 301 |
| 7 | 100 | 667.5 | 87 | 0.5 | 174 |
| 8 | 144 | 395 | 17 | 20 | 168 |
| 9 | 206.5 | 966.5 | 7.5 | 11.5 | 160 |
| 10 | 337 | 23 | 18.5 | 18.5 | 159 |
| 11 | 28.5 | 808.5 | 66.5 | 6.5 | 159 |
| 12 | 344 | 388 | 12 | 5.5 | 158 |
| 13 | 29 | 821.5 | 67 | 5.5 | 157 |
| 14 | 60.5 | 400 | 13.5 | 15 | 152 |
| 15 | 37 | 568.5 | 7 | 7 | 152 |
| 16 | 242.5 | 966 | 13.5 | 10.5 | 151 |
| 17 | 158 | 467.5 | 74 | 0.5 | 148 |
| 18 | 252 | 770 | 7.5 | 9 | 148 |
| 19 | 278 | 770 | 7 | 9 | 142 |
| 20 | 90 | 395 | 13 | 20 | 139 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `segmented` | 20, 462, 350, 52 | 20, 462, 350, 52 | 0 | pass |
| `save` | 20, 943.7, 350, 56 | 20, 943.7, 350, 56 | 0 | pass |

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

