# Fidelity report — f2b3-dense-mechanical-level1

- **Sample id:** `f2b3-dense-mechanical-level1`
- **Batch:** `f2b3-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b3/dense-mechanical-level1.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/11_11._Dense_Mechanical_List/11._Dense_Mechanical_List@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2160}
- **Logical size:** 390 × 1080 @ DPR 2
- **Compared pixels:** 780 × 2160
- **Generated:** 2026-11-06T13:23:52.901Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98311; min 64×64 tile 0.71534 |
| Text | pass | 24 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98311 |
| SSIM (worst 64×64 tile) | 0.71534 |
| RMSE (RGB 0–255) | 13.197 |
| MAE (RGB 0–255) | 2.149 |
| ΔE2000 mean | 0.706 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.973 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 4.92% |
| ΔE2000 > 5 | 1.79% |
| ΔE2000 > 10 | 1.19% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 144.5 | 25 | 71.5 | 14.5 | 2089 |
| 2 | 105 | 25.5 | 38 | 14 | 1062 |
| 3 | 81.5 | 29 | 24 | 14 | 731 |
| 4 | 65 | 25.5 | 15.5 | 13.5 | 573 |
| 5 | 220 | 27 | 19.5 | 12.5 | 571 |
| 6 | 56.5 | 621 | 15 | 18 | 202 |
| 7 | 102 | 892.5 | 18.5 | 13.5 | 161 |
| 8 | 154 | 614.5 | 10.5 | 13.5 | 143 |
| 9 | 168.5 | 892.5 | 10.5 | 13.5 | 143 |
| 10 | 326.5 | 522.5 | 8 | 8 | 134 |
| 11 | 102 | 769.5 | 10 | 13.5 | 133 |
| 12 | 103 | 159.5 | 9.5 | 13.5 | 121 |
| 13 | 212.5 | 769.5 | 9.5 | 13.5 | 115 |
| 14 | 56.5 | 903.5 | 15 | 14 | 109 |
| 15 | 120 | 1026 | 14 | 15.5 | 104 |
| 16 | 90.5 | 84 | 8 | 9 | 101 |
| 17 | 228 | 159 | 3 | 14 | 86 |
| 18 | 328.5 | 789 | 6.5 | 10 | 78 |
| 19 | 165.5 | 159 | 11 | 14.5 | 74 |
| 20 | 55.5 | 190.5 | 17 | 2 | 71 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `card` | 20, 134, 350, 100 | 20, 134, 350, 100 | 0 | pass |
| `cta` | 20, 1004, 350, 56 | 20, 1004, 350, 56 | 0 | pass |

## Text

- Expected: `INSPECTION ZONE 04`, `3 of 6 checkpoints logged`, `Live Bay #2`, `Engine Oil Level`, `Dipstick at optimal line • 5W-30 synthetic`, `Coolant`, `Expansion reservoir inspection`, `ACTIVE`, `Normal`, `Low`, `Critical`, `Enter fluid level / notes`, `Take Photo`, `Brake Fluid Level`, `DOT 4 standard • Reservoir visual`, `Pass`, `Marginal`, `Fail`, `Transmission Fluid`, `Sealed system • Check overflow valve`, `Washer Fluid`, `Topped to max reservoir line`, `Diagnostic Checklist`, `Confirm Fluid Levels`
- Actual: `INSPECTION ZONE 04`, `3 of 6 checkpoints logged`, `Live Bay #2`, `Engine Oil Level`, `Dipstick at optimal line • 5W-30 synthetic`, `Coolant`, `Expansion reservoir inspection`, `ACTIVE`, `Normal`, `Low`, `Critical`, `Enter fluid level / notes`, `Take Photo`, `Brake Fluid Level`, `DOT 4 standard • Reservoir visual`, `Pass`, `Marginal`, `Fail`, `Transmission Fluid`, `Sealed system • Check overflow valve`, `Washer Fluid`, `Topped to max reservoir line`, `Diagnostic Checklist`, `Confirm Fluid Levels`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

