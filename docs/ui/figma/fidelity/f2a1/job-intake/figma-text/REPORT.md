# Fidelity report — f2a1-job-intake-figma-text

- **Sample id:** `f2a1-job-intake-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/job-intake-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/04_4._Job_Details_&_Intake/4._Job_Details_&_Intake@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2256}
- **Logical size:** 390 × 1128 @ DPR 2
- **Compared pixels:** 780 × 2256
- **Generated:** 2026-11-07T20:46:28.548Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98022; min 64×64 tile 0.59791 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98022 |
| SSIM (worst 64×64 tile) | 0.59791 |
| RMSE (RGB 0–255) | 12.388 |
| MAE (RGB 0–255) | 2.538 |
| ΔE2000 mean | 0.751 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 2.843 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 8.31% |
| ΔE2000 > 5 | 1.78% |
| ΔE2000 > 10 | 1.32% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 327.5 | 861 | 18.5 | 18 | 867 |
| 2 | 44.5 | 714.5 | 15.5 | 9 | 302 |
| 3 | 66 | 714.5 | 16.5 | 9 | 258 |
| 4 | 85.5 | 717 | 15 | 6.5 | 220 |
| 5 | 176.5 | 554 | 7.5 | 11.5 | 219 |
| 6 | 54.5 | 352.5 | 19 | 19 | 208 |
| 7 | 99.5 | 554 | 8.5 | 11.5 | 197 |
| 8 | 118.5 | 554 | 8.5 | 11.5 | 196 |
| 9 | 91 | 554 | 7.5 | 11 | 186 |
| 10 | 128.5 | 554 | 7 | 11.5 | 172 |
| 11 | 82.5 | 554 | 8 | 11 | 169 |
| 12 | 57.5 | 355.5 | 13 | 12.5 | 158 |
| 13 | 159.5 | 554 | 7 | 11 | 156 |
| 14 | 168 | 554 | 7 | 11 | 154 |
| 15 | 68.5 | 554 | 7 | 11 | 153 |
| 16 | 109.5 | 554 | 8 | 11 | 146 |
| 17 | 136.5 | 554 | 8.5 | 11 | 142 |
| 18 | 70 | 537 | 7 | 9 | 135 |
| 19 | 55.5 | 663.5 | 18 | 18 | 134 |
| 20 | 104.5 | 539 | 6 | 7.5 | 131 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `INTAKE PHASE`, `Ready for Check`, `10:42 AM · Bay 3`, `REG: LV71 XZP`, `Renault Megane 3`, `Vehicle Info`, `Make`, `Renault`, `Model`, `Megane 3`, `Year`, `2021`, `Odometer`, `34,180 MI`, `VIN / Chassis`, `VF1KZ040647192831`, `Customer info`, `Primary Owner`, `Customer name`, `Arthur Pendelton`, `Phone Number`, `+44 7700 900077`, `Service Package`, `Comprehensive Fleet Tier-1 Multi-Point`, `Pre-Inspection Ready`, `Keys received · Fuel at 70%`, `Step 1 of 4`, `Vehicle Walkaround Inspection`, `Start Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

