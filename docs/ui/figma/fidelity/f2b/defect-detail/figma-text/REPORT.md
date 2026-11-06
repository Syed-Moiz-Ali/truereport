# Fidelity report — f2b-defect-detail-figma-text

- **Sample id:** `f2b-defect-detail-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/defect-detail-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/9._Defect_Detail_&_Evidence@2x.png`
- **Reference crop (px):** {"x":120,"y":0,"width":780,"height":2063}
- **Logical size:** 390 × 1032 @ DPR 2
- **Compared pixels:** 780 × 2064
- **Generated:** 2026-11-06T11:35:07.188Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.83818; min 64×64 tile 0.21805 |
| Text | pass | 12 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 2/2 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.83818 |
| SSIM (worst 64×64 tile) | 0.21805 |
| RMSE (RGB 0–255) | 66.295 |
| MAE (RGB 0–255) | 29.491 |
| ΔE2000 mean | 8.543 |
| ΔE2000 median | 2.13 |
| ΔE2000 p95 | 49.025 |
| ΔE2000 max | 99.17 |
| ΔE2000 > 2 (JND) | 50.25% |
| ΔE2000 > 5 | 23.79% |
| ΔE2000 > 10 | 20.76% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 20 | 668 | 167 | 172.5 | 104478 |
| 2 | 12 | 941 | 366.5 | 74 | 101275 |
| 3 | 35 | 135 | 321 | 130.5 | 81385 |
| 4 | 140.5 | 468 | 109 | 44.5 | 17382 |
| 5 | 22 | 1021 | 346 | 11 | 14486 |
| 6 | 258.5 | 784.5 | 56 | 56 | 10001 |
| 7 | 258.5 | 704 | 56 | 56 | 9824 |
| 8 | 246 | 27.5 | 23.5 | 9 | 539 |
| 9 | 81 | 534 | 20 | 15.5 | 538 |
| 10 | 133 | 27.5 | 23.5 | 8.5 | 498 |
| 11 | 154.5 | 27.5 | 24 | 9 | 486 |
| 12 | 36.5 | 534 | 15 | 15.5 | 436 |
| 13 | 337 | 875 | 17 | 17.5 | 431 |
| 14 | 67 | 534 | 16 | 15.5 | 400 |
| 15 | 342.5 | 383 | 15 | 11 | 392 |
| 16 | 46 | 650 | 17 | 11.5 | 390 |
| 17 | 229 | 27.5 | 16 | 9 | 372 |
| 18 | 110 | 570 | 12 | 12 | 349 |
| 19 | 134 | 650 | 12 | 11.5 | 320 |
| 20 | 152 | 648.5 | 11.5 | 13 | 296 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `segmented` | 20, 462, 350, 52 | 20, 462, 350, 52 | 0 | pass |
| `save` | 20, 1021, 350, 56 | 20, 1021, 350, 56 | 0 | pass |

## Text

- Expected: `EXTERIOR BODYWORK`, `Front Left Door`, `INSPECTION STATUS`, `Pass`, `Minor`, `Major`, `DEFECT CLASSIFICATION`, `PHOTOGRAPHIC EVIDENCE`, `0 / 4`, `Take a photo`, `Tap to capture`, `Save Defect`
- Actual: `⁦JOB-5A0001⁩ • IN PROGRESS`, `Inspection`, `EXTERIOR BODYWORK`, `Front Left Door`, `INSPECTION STATUS`, `Pass`, `Minor`, `Major`, `Not checked`, `Could not verify`, `Not applicable`, `DEFECT CLASSIFICATION`, `Minor`, `Moderate`, `Major`, `Safety-critical`, `PHOTOGRAPHIC EVIDENCE`, `0 / 4`, `Take a photo`, `Tap to capture`, `Take a photo`, `Tap to capture`, `Add defect notes (e.g. 2.5cm door ding)...`, `Save Defect`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

