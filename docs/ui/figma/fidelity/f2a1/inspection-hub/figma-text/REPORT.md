# Fidelity report — f2a1-inspection-hub-figma-text

- **Sample id:** `f2a1-inspection-hub-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/inspection-hub-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/07_7._Main_Inspection_Hub/7._Main_Inspection_Hub@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2260}
- **Logical size:** 390 × 1130 @ DPR 2
- **Compared pixels:** 780 × 2260
- **Generated:** 2026-11-06T04:36:18.037Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.94963; min 64×64 tile 0.34894 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.94963 |
| SSIM (worst 64×64 tile) | 0.34894 |
| RMSE (RGB 0–255) | 23.986 |
| MAE (RGB 0–255) | 4.688 |
| ΔE2000 mean | 1.331 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 2.45 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 5.87% |
| ΔE2000 > 5 | 3.31% |
| ΔE2000 > 10 | 2.82% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 188 | 154 | 95 | 164 | 16374 |
| 2 | 133.5 | 596.5 | 38.5 | 35 | 2388 |
| 3 | 230 | 969 | 63.5 | 11.5 | 1632 |
| 4 | 115 | 969.5 | 62 | 11 | 1400 |
| 5 | 41 | 670.5 | 26.5 | 18 | 1070 |
| 6 | 73.5 | 880 | 46 | 10.5 | 920 |
| 7 | 127 | 358.5 | 41.5 | 9 | 914 |
| 8 | 226.5 | 358.5 | 38.5 | 9 | 795 |
| 9 | 179.5 | 969.5 | 30 | 11 | 779 |
| 10 | 182.5 | 222.5 | 14.5 | 22.5 | 750 |
| 11 | 267 | 880 | 35.5 | 10.5 | 709 |
| 12 | 145.5 | 1065 | 19.5 | 17.5 | 698 |
| 13 | 269 | 358.5 | 30.5 | 9 | 669 |
| 14 | 235.5 | 778 | 15 | 18 | 634 |
| 15 | 251.5 | 89 | 23.5 | 12 | 598 |
| 16 | 223 | 697 | 25 | 11.5 | 499 |
| 17 | 249 | 697 | 24 | 10.5 | 486 |
| 18 | 90 | 674 | 11 | 14.5 | 452 |
| 19 | 209 | 972 | 19.5 | 8.5 | 440 |
| 20 | 225 | 1064 | 8 | 19.5 | 411 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `INSPECTION IN PROGRESS`, `Bay #04 • VIN 8492`, `45`, `/110`, `CHECKS DONE`, `42 Passed`, `3 Action Items`, `Porsche Taycan 4S`, `WA1-VAA-Y7890 • 12,480 mi`, `Inspection Modules`, `4 categories`, `Exterior`, `28/28 Done`, `17/32`, `Interior`, `17/32 checks`, `Engine`, `0/24 checks`, `Queued`, `Underbody`, `0/26 checks`, `Queued`, `Continue Interior Checklist`, `Intake Hub`, `Intake`, `Fleet`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

