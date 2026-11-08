# Fidelity report — f2b-finalize-figma-text

- **Sample id:** `f2b-finalize-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/finalize-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/14._Finalize_&_Approval_(Swipe)@2x.png`
- **Reference crop (px):** {"x":76,"y":14,"width":780,"height":2463}
- **Logical size:** 390 × 1231.5 @ DPR 2
- **Compared pixels:** 780 × 2463
- **Generated:** 2026-11-08T09:25:36.465Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98223; min 64×64 tile 0.80509 |
| Text | pass | 8 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98223 |
| SSIM (worst 64×64 tile) | 0.80509 |
| RMSE (RGB 0–255) | 11.129 |
| MAE (RGB 0–255) | 1.981 |
| ΔE2000 mean | 0.558 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.046 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 3.37% |
| ΔE2000 > 5 | 2.17% |
| ΔE2000 > 10 | 1.46% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 206 | 660 | 15 | 14 | 568 |
| 2 | 264.5 | 660 | 14 | 14 | 539 |
| 3 | 139.5 | 113.5 | 14 | 19.5 | 215 |
| 4 | 59.5 | 118.5 | 11.5 | 14.5 | 172 |
| 5 | 45.5 | 845.5 | 13 | 8.5 | 157 |
| 6 | 45.5 | 913.5 | 13 | 8.5 | 157 |
| 7 | 86.5 | 118.5 | 19.5 | 14.5 | 151 |
| 8 | 227 | 491.5 | 12 | 13 | 141 |
| 9 | 60.5 | 253 | 15.5 | 5.5 | 137 |
| 10 | 32 | 84.5 | 12.5 | 9 | 120 |
| 11 | 61 | 245 | 17 | 18 | 103 |
| 12 | 21 | 113.5 | 8.5 | 19.5 | 93 |
| 13 | 60 | 532.5 | 7 | 16.5 | 88 |
| 14 | 189.5 | 113 | 4.5 | 20 | 87 |
| 15 | 190.5 | 1176.5 | 7.5 | 8.5 | 85 |
| 16 | 238.5 | 1176.5 | 7.5 | 8.5 | 85 |
| 17 | 59.5 | 1045.5 | 8 | 9 | 78 |
| 18 | 42 | 1003.5 | 7 | 10 | 76 |
| 19 | 76.5 | 418.5 | 6.5 | 9 | 74 |
| 20 | 130.5 | 1173.5 | 2.5 | 11.5 | 74 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `summary` | 20, 206, 350, 558 | 20, 206, 350, 558 | 0 | pass |
| `slide` | 20, 1147, 350, 64 | 20, 1146.6, 350, 64 | 0.37 | pass |

## Text

- Expected: `Review & Finalize`, `2024 Ford Transit 350`, `VIN • 1FTBR1Y85RKB92104`, `Bay #04`, `Odometer: 14,820 mi`, `Slide to Finalize Inspection`, `Diagnostic Checklist`, `Marcus Vance`
- Actual: `INSPECTION STEP 4 OF 4`, `Review & Finalize`, `Review verified points and sign off to dispatch fleet
records.`, `2024 Ford Transit 350`, `VIN • 1FTBR1Y85RKB92104`, `Bay #04`, `Odometer: 14,820 mi`, `104`, `Checks`, `Completed`, `2`, `Defects Found`, `Marcus Vance`, `Lead Fleet Specialist • ID`, `#8842`, `Today`, `14:48`, `PST`, `Flagged Items Summary`, `Requires Follow-up`, `Front Left Tire Tread Depth`, `Measured at 3/32 in. Marginal wear pattern
documented.`, `Rear Cargo Door Latch`, `Minor resistance observed on secondary
strike latch.`, `By completing this inspection, technician confirms
vehicle condition complies with fleet standards.
Digital signature and GPS coordinates will be
permanently appended to Fleet Ledger #2024-FLT-
0982.`, `Slide to Finalize Inspection`, `Diagnostic Checklist`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

