# Fidelity report — f2a1-job-intake-product-copy

- **Sample id:** `f2a1-job-intake-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/job-intake-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/04_4._Job_Details_&_Intake/4._Job_Details_&_Intake@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2256}
- **Logical size:** 390 × 1128 @ DPR 2
- **Compared pixels:** 780 × 2256
- **Generated:** 2026-11-06T04:36:03.861Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.83288; min 64×64 tile 0.09402 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.83288 |
| SSIM (worst 64×64 tile) | 0.09402 |
| RMSE (RGB 0–255) | 46.739 |
| MAE (RGB 0–255) | 14.825 |
| ΔE2000 mean | 5.28 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 39.826 |
| ΔE2000 max | 99.921 |
| ΔE2000 > 2 (JND) | 25.18% |
| ΔE2000 > 5 | 11.07% |
| ΔE2000 > 10 | 10.09% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 64.5 | 157 | 301 | 110.5 | 89621 |
| 2 | 190.5 | 72 | 74 | 22 | 5527 |
| 3 | 36 | 728 | 56.5 | 20.5 | 2195 |
| 4 | 317 | 258 | 40 | 36 | 2122 |
| 5 | 105.5 | 72 | 35 | 22 | 1979 |
| 6 | 119 | 948 | 68.5 | 14 | 1703 |
| 7 | 47 | 345 | 26.5 | 26.5 | 1586 |
| 8 | 130 | 25 | 43.5 | 14.5 | 1485 |
| 9 | 54.5 | 418 | 36 | 20.5 | 1478 |
| 10 | 36.5 | 474 | 38 | 20.5 | 1422 |
| 11 | 136.5 | 661 | 30 | 18.5 | 1209 |
| 12 | 88.5 | 657.5 | 32 | 22 | 1196 |
| 13 | 47 | 655 | 26.5 | 26.5 | 1150 |
| 14 | 224 | 421 | 25 | 20.5 | 1027 |
| 15 | 259 | 474 | 23.5 | 20 | 983 |
| 16 | 76 | 530 | 23 | 35 | 959 |
| 17 | 203 | 418 | 23.5 | 20.5 | 944 |
| 18 | 105 | 728 | 20 | 20.5 | 932 |
| 19 | 97.5 | 774.5 | 25 | 19.5 | 925 |
| 20 | 39.5 | 262 | 37.5 | 12.5 | 917 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `ASSIGNED`, `Assigned`, `10:42 UTC+4`, `A 12345`, `Honda Accord`, `Vehicle info`, `Make`, `Honda`, `Model`, `Accord`, `Year`, `2022`, `Odometer`, `48,210 KM`, `VIN / Chassis`, `1HGCM82633A004352`, `Customer info`, `Customer`, `Customer name`, `Ahmed Al Mansoori`, `Phone`, `+971 50 123 4567`, `Service Package`, `Full inspection`, `Job details ready`, `Assigned · Versions 1`, `Versions 1`, `Customer information`, `Vehicle identification`, `Consent`, `Equipment`, `Full inspection`, `Start inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

