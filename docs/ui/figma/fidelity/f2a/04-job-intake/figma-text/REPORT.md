# Fidelity report — F2-A 04-job-intake - Figma-text fixture

- **Sample id:** `04-job-intake-figma-text`
- **Batch:** `f2a-technician-screens-1-7`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a/04-job-intake-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/04_4._Job_Details_&_Intake/4._Job_Details_&_Intake@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2256}
- **Logical size:** 390 × 1128 @ DPR 2
- **Compared pixels:** 780 × 2256
- **Generated:** 2026-11-05T19:24:20.724Z
- **Owner:** fidelity-auditor

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.80675; min 64×64 tile 0.08443 |
| Text | pass | 18 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.80675 |
| SSIM (worst 64×64 tile) | 0.08443 |
| RMSE (RGB 0–255) | 54.577 |
| MAE (RGB 0–255) | 21.493 |
| ΔE2000 mean | 7.245 |
| ΔE2000 median | 0.796 |
| ΔE2000 p95 | 45.619 |
| ΔE2000 max | 99.921 |
| ΔE2000 > 2 (JND) | 43.7% |
| ΔE2000 > 5 | 19.85% |
| ΔE2000 > 10 | 17.93% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 20 | 157 | 350 | 137 | 137750 |
| 2 | 11.5 | 1060 | 366.5 | 68 | 95044 |
| 3 | 20 | 78.5 | 103.5 | 33.5 | 11766 |
| 4 | 131.5 | 72 | 130.5 | 22 | 11047 |
| 5 | 330 | 12 | 44 | 40 | 5464 |
| 6 | 40 | 946 | 32 | 32 | 3424 |
| 7 | 203.5 | 481.5 | 40 | 15 | 1298 |
| 8 | 214 | 966 | 40 | 12 | 1118 |
| 9 | 44.5 | 481.5 | 31.5 | 13 | 1069 |
| 10 | 116.5 | 861 | 34 | 15.5 | 1033 |
| 11 | 118 | 790.5 | 21 | 29.5 | 1011 |
| 12 | 54.5 | 653 | 20.5 | 28.5 | 996 |
| 13 | 54.5 | 352.5 | 19 | 19 | 980 |
| 14 | 137 | 966 | 33.5 | 15.5 | 912 |
| 15 | 327.5 | 861 | 18.5 | 18 | 867 |
| 16 | 54 | 789 | 22.5 | 31 | 838 |
| 17 | 132 | 25.5 | 27 | 14 | 740 |
| 18 | 90.5 | 25 | 24 | 14.5 | 737 |
| 19 | 143.5 | 946 | 21.5 | 13.5 | 681 |
| 20 | 340.5 | 183.5 | 18.5 | 20 | 642 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Hatchback`, `Vehicle info`, `Make`, `Renault`, `Model`, `Megane 3`, `Year`, `2021`, `Odometer`, `VIN`, `Plate`, `Customer info`, `Customer name`, `Arthur Pendelton`, `Inspection template`, `Full Pre-Delivery Inspection v1`, `Start inspection`, `Job intake`
- Actual: `Assigned`, `10:42 UTC+4`, `Versions 1`, `Hatchback`, `Vehicle info`, `Make`, `Renault`, `Model`, `Megane 3`, `Year`, `2021`, `Odometer`, `34,180 MI`, `VIN`, `VF1KZ040647192831`, `Plate`, `LV71 XZP`, `Customer info`, `Customer name`, `Arthur Pendelton`, `Phone`, `+44 7700 900077`, `Inspection template`, `Full Pre-Delivery Inspection v1`, `Scope`, `Full inspection`, `Details`, `Customer information`, `Vehicle identification`, `Consent`, `Equipment`, `Start the inspection when the vehicle and customer details are confirmed.`, `Job intake`, `DV`, `Start inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Test-only Figma-like sample copy. Replaced vehicle photo with an original vehicle-type silhouette; removed Bay, readiness, fuel, step, owner, scan icon, call/message (no endpoint/data). Time is derived from scheduledAt in UTC+4. Kept real customer/vehicle/template fields. Labels above fields (P2); 56 px inputs; primary CTA P1. Removed hero photo is the largest residual.

