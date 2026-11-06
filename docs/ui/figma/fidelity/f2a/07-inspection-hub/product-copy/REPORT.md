# Fidelity report — F2-A 07-inspection-hub - real product copy

- **Sample id:** `07-inspection-hub-product-copy`
- **Batch:** `f2a-technician-screens-1-7`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a/07-inspection-hub-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/07_7._Main_Inspection_Hub/7._Main_Inspection_Hub@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2260}
- **Logical size:** 390 × 1130 @ DPR 2
- **Compared pixels:** 780 × 2260
- **Generated:** 2026-11-05T15:01:34.242Z
- **Owner:** fidelity-auditor

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.80987; min 64×64 tile 0.19525 |
| Text | pass | 18 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.80987 |
| SSIM (worst 64×64 tile) | 0.19525 |
| RMSE (RGB 0–255) | 60.622 |
| MAE (RGB 0–255) | 23.288 |
| ΔE2000 mean | 6.568 |
| ΔE2000 median | 0.198 |
| ΔE2000 p95 | 39.793 |
| ΔE2000 max | 99.726 |
| ΔE2000 > 2 (JND) | 31.7% |
| ΔE2000 > 5 | 18.82% |
| ΔE2000 > 10 | 15.36% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 11.5 | 936.5 | 366.5 | 117.5 | 145758 |
| 2 | 129.5 | 162.5 | 153.5 | 193 | 23472 |
| 3 | 92 | 412 | 206 | 28 | 22420 |
| 4 | 108.5 | 380 | 173 | 28 | 18679 |
| 5 | 122.5 | 444 | 142 | 38.5 | 16334 |
| 6 | 20 | 84 | 103.5 | 28 | 10863 |
| 7 | 36 | 449.5 | 48 | 40.5 | 6223 |
| 8 | 107 | 239 | 86 | 124.5 | 6052 |
| 9 | 129.5 | 590 | 42.5 | 44 | 5448 |
| 10 | 330 | 12 | 40 | 40 | 5046 |
| 11 | 64 | 24 | 67.5 | 17.5 | 2546 |
| 12 | 108 | 535.5 | 71 | 13.5 | 1832 |
| 13 | 69 | 1066.5 | 25 | 31 | 1772 |
| 14 | 134 | 24 | 43 | 17.5 | 1673 |
| 15 | 41 | 849.5 | 30.5 | 21.5 | 1420 |
| 16 | 224 | 852 | 33.5 | 15.5 | 1273 |
| 17 | 46.5 | 539 | 28.5 | 22 | 1188 |
| 18 | 26.5 | 23 | 22 | 18.5 | 1001 |
| 19 | 47.5 | 690 | 19 | 19.5 | 806 |
| 20 | 41 | 674.5 | 26.5 | 14 | 803 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Assigned`, `17`, `of 40`, `checks done`, `15 No issue observed`, `2 Attention recommended`, `0 Defect found`, `Inspection modules`, `4 categories`, `Exterior`, `10/10 checks`, `Interior`, `7/10 checks`, `Engine`, `0/10 checks`, `Underbody`, `0/10 checks`, `Inspection hub`
- Actual: `Assigned`, `Versions 1`, `17`, `of 40`, `checks done`, `15 No issue observed`, `2 Attention recommended`, `0 Defect found`, `Honda Accord`, `JOB-2601 â€¢ 48,210 KM`, `Inspection modules`, `4 categories`, `Exterior`, `10/10 checks`, `Done`, `Interior`, `7/10 checks`, `In progress`, `Engine`, `0/10 checks`, `Not started`, `Underbody`, `0/10 checks`, `Not started`, `Continue checklist â€¢ Interior`, `Inspection hub`, `DV`, `Jobs`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Real product copy and neutral test data. Coverage ring shows N of M checks done only (no score). Passed replaced with result vocabulary counts (no issue observed / attention / defects). Removed Bay and VIN fragment; vehicle photo replaced with car icon; Active Bay/Queued replaced with Done/In progress/Not started derived from assessments; categories are template-driven. Ring arc uses brand fill with numeric fallback. Visual differences from removed Figma elements are residuals.

