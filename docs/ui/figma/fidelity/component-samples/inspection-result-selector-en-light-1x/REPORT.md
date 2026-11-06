# Fidelity report — Inspection result selector - Figma exact - EN, light, 1x

- **Sample id:** `inspection-result-selector-en-light-1x`
- **Batch:** `f1.1-component-samples`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/component-samples/inspection-result-selector-en-light-1x.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/9._Defect_Detail_&_Evidence@2x.png`
- **Reference crop (px):** {"x":160,"y":888,"width":700,"height":140}
- **Logical size:** 350 × 70 @ DPR 2
- **Compared pixels:** 700 × 140
- **Generated:** 2026-11-06T03:30:45.300Z
- **Owner:** fidelity-auditor

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98756; min 64×64 tile 0.93706 |
| Text | pass | 4 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 1/1 within 1 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98756 |
| SSIM (worst 64×64 tile) | 0.93706 |
| RMSE (RGB 0–255) | 8.112 |
| MAE (RGB 0–255) | 1.218 |
| ΔE2000 mean | 0.435 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.986 |
| ΔE2000 max | 65.786 |
| ΔE2000 > 2 (JND) | 2.61% |
| ΔE2000 > 5 | 2.1% |
| ΔE2000 > 10 | 1.41% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 35 | 2.5 | 6.5 | 8 | 63 |
| 2 | 7.5 | 2.5 | 4 | 8.5 | 60 |
| 3 | 28.5 | 2.5 | 6 | 8.5 | 58 |
| 4 | 54 | 2.5 | 7 | 7 | 53 |
| 5 | 51 | 2.5 | 2 | 8.5 | 51 |
| 6 | 158.5 | 40 | 9.5 | 9 | 51 |
| 7 | 47 | 3 | 3 | 8 | 38 |
| 8 | 86 | 3 | 3 | 8 | 37 |
| 9 | 99.5 | 3 | 3 | 8 | 37 |
| 10 | 13 | 2.5 | 5 | 4.5 | 36 |
| 11 | 96 | 2.5 | 6 | 8.5 | 36 |
| 12 | 0.5 | 2.5 | 1.5 | 8.5 | 34 |
| 13 | 4 | 2.5 | 1.5 | 8.5 | 34 |
| 14 | 64.5 | 2.5 | 1.5 | 8.5 | 34 |
| 15 | 69 | 2.5 | 2.5 | 8.5 | 34 |
| 16 | 83 | 2.5 | 5.5 | 8.5 | 34 |
| 17 | 44 | 2.5 | 5.5 | 8.5 | 33 |
| 18 | 76 | 2.5 | 4.5 | 4.5 | 33 |
| 19 | 103.5 | 2.5 | 1.5 | 8 | 32 |
| 20 | 111.5 | 2.5 | 5 | 4 | 32 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `inspection-result-selector` | 0, 0, 350, 70 | 0, 0, 350, 70 | 0 | pass |

## Text

- Expected: `INSPECTION STATUS`, `Pass`, `Minor`, `Major`
- Actual: `INSPECTION STATUS`, `Pass`, `Minor`, `Major`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Crop is the Figma Severity Pill-Shaped Toggle Group node bounding box (350 x 70 at logical 20,444). Figma's own sample labels Pass/Minor/Major are used in this test-only fixture; the product variant uses the approved six-result vocabulary with the three extra results in a secondary chip row.

