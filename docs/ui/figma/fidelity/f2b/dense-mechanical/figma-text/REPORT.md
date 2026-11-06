# Fidelity report — f2b-dense-mechanical-figma-text

- **Sample id:** `f2b-dense-mechanical-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/dense-mechanical-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/11_11._Dense_Mechanical_List/11._Dense_Mechanical_List@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2160}
- **Logical size:** 390 × 1080 @ DPR 2
- **Compared pixels:** 780 × 2160
- **Generated:** 2026-11-06T11:35:13.168Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.86017; min 64×64 tile 0.22324 |
| Text | pass | 8 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.86017 |
| SSIM (worst 64×64 tile) | 0.22324 |
| RMSE (RGB 0–255) | 44.455 |
| MAE (RGB 0–255) | 13.733 |
| ΔE2000 mean | 4.177 |
| ΔE2000 median | 0.396 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 24.02% |
| ΔE2000 > 5 | 9.21% |
| ΔE2000 > 10 | 8.03% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 34.5 | 484.5 | 260.5 | 76.5 | 64374 |
| 2 | 282.5 | 293 | 67.5 | 22 | 5140 |
| 3 | 314 | 590 | 36 | 48.5 | 4354 |
| 4 | 314 | 890 | 36 | 36 | 4110 |
| 5 | 161.5 | 25 | 81.5 | 14.5 | 2762 |
| 6 | 153 | 1027 | 109 | 11.5 | 2639 |
| 7 | 334 | 16 | 40 | 32 | 2184 |
| 8 | 102 | 614 | 48.5 | 14.5 | 1643 |
| 9 | 114 | 1022.5 | 38.5 | 19 | 1576 |
| 10 | 314 | 180.5 | 36 | 21.5 | 1180 |
| 11 | 100 | 376.5 | 40 | 13.5 | 1171 |
| 12 | 314 | 158 | 36 | 21 | 1149 |
| 13 | 323.5 | 167.5 | 17 | 25 | 1094 |
| 14 | 54.5 | 784.5 | 19 | 19 | 881 |
| 15 | 168 | 614 | 25.5 | 14.5 | 852 |
| 16 | 56.5 | 898.5 | 15 | 19 | 793 |
| 17 | 54.5 | 294.5 | 19 | 19 | 778 |
| 18 | 54 | 98.5 | 32 | 12 | 672 |
| 19 | 57.5 | 599.5 | 13 | 16.5 | 616 |
| 20 | 55.5 | 275.5 | 16.5 | 16.5 | 614 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `card` | 20, 132, 350, 88 | 20, 132, 350, 88 | 0 | pass |
| `cta` | 20, 1004, 350, 56 | 20, 1004, 350, 56 | 0 | pass |

## Text

- Expected: `INSPECTION ZONE 04`, `3 checks done / 6`, `JOB-5A0001`, `Engine Oil Level`, `Dipstick at optimal line.`, `Brake Fluid Level`, `Diagnostic Checklist`, `Review & Finalize`
- Actual: `INSPECTION ZONE 04`, `3 checks done / 6`, `JOB-5A0001`, `Engine Oil Level`, `Dipstick at optimal line.`, `Coolant`, `Expansion reservoir inspection.`, `Brake Fluid Level`, `DOT 4 standard.`, `Transmission Fluid`, `Sealed system.`, `Washer Fluid`, `Topped to max line.`, `Diagnostic Checklist`, `Review & Finalize`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

