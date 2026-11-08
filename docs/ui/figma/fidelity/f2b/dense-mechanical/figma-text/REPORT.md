# Fidelity report — f2b-dense-mechanical-figma-text

- **Sample id:** `f2b-dense-mechanical-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/dense-mechanical-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/11_11._Dense_Mechanical_List/11._Dense_Mechanical_List@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2160}
- **Logical size:** 390 × 1080 @ DPR 2
- **Compared pixels:** 780 × 2160
- **Generated:** 2026-11-08T06:53:15.584Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98119; min 64×64 tile 0.70162 |
| Text | pass | 8 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98119 |
| SSIM (worst 64×64 tile) | 0.70162 |
| RMSE (RGB 0–255) | 12.639 |
| MAE (RGB 0–255) | 2.011 |
| ΔE2000 mean | 0.68 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 2.51 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 6.17% |
| ΔE2000 > 5 | 1.76% |
| ΔE2000 > 10 | 1.16% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 161.5 | 25 | 81.5 | 14.5 | 2762 |
| 2 | 141 | 27 | 18.5 | 12.5 | 430 |
| 3 | 317.5 | 92.5 | 14.5 | 9 | 303 |
| 4 | 300.5 | 94.5 | 15 | 7 | 282 |
| 5 | 56.5 | 621 | 15 | 18 | 202 |
| 6 | 102 | 892.5 | 18.5 | 13.5 | 161 |
| 7 | 123 | 29 | 12 | 10.5 | 157 |
| 8 | 154 | 614.5 | 10.5 | 13.5 | 143 |
| 9 | 168.5 | 892.5 | 10.5 | 13.5 | 143 |
| 10 | 326.5 | 522.5 | 8 | 8 | 134 |
| 11 | 102 | 769.5 | 10 | 13.5 | 133 |
| 12 | 292 | 92.5 | 4 | 8.5 | 123 |
| 13 | 103 | 159.5 | 9.5 | 13.5 | 121 |
| 14 | 212.5 | 769.5 | 9.5 | 13.5 | 115 |
| 15 | 328.5 | 789 | 6.5 | 10 | 112 |
| 16 | 113 | 29 | 10.5 | 10.5 | 110 |
| 17 | 56.5 | 903.5 | 15 | 14 | 109 |
| 18 | 120 | 1026 | 14 | 15.5 | 104 |
| 19 | 90.5 | 84 | 8 | 9 | 101 |
| 20 | 332 | 95 | 7 | 7.5 | 101 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `card` | 20, 134, 350, 100 | 20, 134, 350, 100 | 0 | pass |
| `cta` | 20, 1004, 350, 56 | 20, 1004, 350, 56 | 0 | pass |

## Text

- Expected: `INSPECTION ZONE 04`, `3 of 6 checkpoints logged`, `Live Bay #2`, `Engine Oil Level`, `Dipstick at optimal line • 5W-30
synthetic`, `Brake Fluid Level`, `Diagnostic Checklist`, `Confirm Fluid Levels`
- Actual: `INSPECTION ZONE 04`, `3 of 6 checkpoints logged`, `Live Bay #2`, `Engine Oil Level`, `Dipstick at optimal line • 5W-30
synthetic`, `Coolant`, `Expansion reservoir
inspection`, `ACTIVE`, `Normal`, `Low`, `Critical`, `Enter fluid level / notes`, `Take Photo`, `Brake Fluid Level`, `DOT 4 standard • Reservoir visual`, `Pass`, `Marginal`, `Fail`, `Transmission Fluid`, `Sealed system • Check overflow
valve`, `Washer Fluid`, `Topped to max reservoir line`, `Diagnostic Checklist`, `Confirm Fluid Levels`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

