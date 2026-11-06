# Fidelity report — f2b-defect-detail-product-copy

- **Sample id:** `f2b-defect-detail-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/defect-detail-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/9._Defect_Detail_&_Evidence@2x.png`
- **Reference crop (px):** {"x":120,"y":0,"width":780,"height":2063}
- **Logical size:** 390 × 1032 @ DPR 2
- **Compared pixels:** 780 × 2064
- **Generated:** 2026-11-06T11:35:10.152Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.82509; min 64×64 tile 0.21805 |
| Text | pass | 12 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.82509 |
| SSIM (worst 64×64 tile) | 0.21805 |
| RMSE (RGB 0–255) | 68.575 |
| MAE (RGB 0–255) | 30.993 |
| ΔE2000 mean | 9.019 |
| ΔE2000 median | 2.582 |
| ΔE2000 p95 | 50.285 |
| ΔE2000 max | 99.17 |
| ΔE2000 > 2 (JND) | 50.82% |
| ΔE2000 > 5 | 24.45% |
| ΔE2000 > 10 | 21.44% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 20 | 668 | 167 | 172.5 | 104616 |
| 2 | 12 | 941 | 366.5 | 74 | 101001 |
| 3 | 35 | 135 | 321 | 130.5 | 81385 |
| 4 | 140.5 | 468 | 109 | 44.5 | 17664 |
| 5 | 22 | 1021 | 346 | 11 | 14486 |
| 6 | 258.5 | 784.5 | 56 | 56 | 10001 |
| 7 | 258.5 | 704 | 56 | 56 | 9824 |
| 8 | 21 | 395 | 121 | 25.5 | 5171 |
| 9 | 144 | 395.5 | 33.5 | 20.5 | 1746 |
| 10 | 21 | 446.5 | 42 | 9 | 889 |
| 11 | 336.5 | 872 | 17.5 | 20.5 | 658 |
| 12 | 47 | 372.5 | 27 | 9 | 646 |
| 13 | 228.5 | 27.5 | 28 | 9 | 639 |
| 14 | 223.5 | 400.5 | 14.5 | 15 | 580 |
| 15 | 160 | 27.5 | 27.5 | 9 | 562 |
| 16 | 209 | 400.5 | 13.5 | 14.5 | 558 |
| 17 | 203.5 | 27.5 | 25 | 9 | 552 |
| 18 | 81 | 534 | 20 | 15.5 | 538 |
| 19 | 194.5 | 395.5 | 13.5 | 20 | 504 |
| 20 | 238.5 | 400.5 | 12 | 15 | 480 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `segmented` | 20, 462, 350, 52 | 20, 462, 350, 52 | 0 | pass |
| `save` | 20, 1021, 350, 56 | 20, 1021, 350, 56 | 0 | pass |

## Text

- Expected: `Braking`, `Brake pad thickness`, `RESULT`, `No issue observed`, `Attention recommended`, `Defect found`, `SEVERITY`, `PHOTOS`, `0 / 1`, `Add photo`, `Note`, `Save answer`
- Actual: `⁦JOB-2601⁩ • ASSIGNED`, `Inspection`, `Braking`, `Brake pad thickness`, `RESULT`, `No issue observed`, `Attention recommended`, `Defect found`, `Not checked`, `Could not verify`, `Not applicable`, `SEVERITY`, `Minor`, `Moderate`, `Major`, `Safety-critical`, `PHOTOS`, `0 / 1`, `Add photo`, `Add at least one photo.`, `Add photo`, `Add at least one photo.`, `Note`, `Save answer`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

