# Fidelity report — f2a1-job-intake-figma-text

- **Sample id:** `f2a1-job-intake-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/job-intake-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/04_4._Job_Details_&_Intake/4._Job_Details_&_Intake@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2256}
- **Logical size:** 390 × 1128 @ DPR 2
- **Compared pixels:** 780 × 2256
- **Generated:** 2026-11-06T04:36:00.608Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.88097; min 64×64 tile 0.23533 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.88097 |
| SSIM (worst 64×64 tile) | 0.23533 |
| RMSE (RGB 0–255) | 38.158 |
| MAE (RGB 0–255) | 9.475 |
| ΔE2000 mean | 3.158 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 5.976 |
| ΔE2000 max | 86.282 |
| ΔE2000 > 2 (JND) | 16.88% |
| ΔE2000 > 5 | 5.14% |
| ΔE2000 > 10 | 4.62% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 236.5 | 25.5 | 62.5 | 17.5 | 1873 |
| 2 | 47 | 345 | 26.5 | 26.5 | 1586 |
| 3 | 36.5 | 474 | 37 | 20.5 | 1408 |
| 4 | 53.5 | 728 | 32.5 | 20.5 | 1343 |
| 5 | 136.5 | 661 | 30 | 18.5 | 1209 |
| 6 | 88.5 | 657.5 | 32 | 22 | 1196 |
| 7 | 64 | 25 | 36 | 14.5 | 1164 |
| 8 | 47 | 655 | 26.5 | 26.5 | 1150 |
| 9 | 162.5 | 25 | 41.5 | 14.5 | 1112 |
| 10 | 66.5 | 774.5 | 31.5 | 19.5 | 997 |
| 11 | 128 | 25.5 | 30.5 | 13.5 | 988 |
| 12 | 73.5 | 418 | 21 | 20.5 | 978 |
| 13 | 68.5 | 530 | 22 | 35 | 930 |
| 14 | 175.5 | 657.5 | 23.5 | 21.5 | 886 |
| 15 | 207.5 | 25 | 28 | 14.5 | 879 |
| 16 | 105 | 728 | 20.5 | 20.5 | 874 |
| 17 | 327.5 | 861 | 18.5 | 18 | 867 |
| 18 | 108 | 347.5 | 20 | 22 | 861 |
| 19 | 318 | 236.5 | 36 | 20.5 | 842 |
| 20 | 318 | 770 | 24 | 31 | 826 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `INTAKE PHASE`, `Ready for Check`, `10:42 AM · Bay 3`, `REG: LV71 XZP`, `Renault Megane 3`, `Vehicle info`, `Make`, `Renault`, `Model`, `Megane 3`, `Year`, `2021`, `Odometer`, `34,180 mi`, `VIN / Chassis`, `VF1KZ040647192831`, `Customer info`, `Primary Owner`, `Customer name`, `Arthur Pendelton`, `Phone`, `+44 7700 900077`, `Service Package`, `Comprehensive Fleet Tier-1 Multi-Point`, `Pre-Inspection Ready`, `Keys received · Fuel at 70%`, `Step 1 of 4`, `Customer information`, `Vehicle identification`, `Consent`, `Equipment`, `Vehicle Walkaround Inspection`, `Start Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

