# Fidelity report — f2a1-exterior-wireframe-figma-text

- **Sample id:** `f2a1-exterior-wireframe-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/exterior-wireframe-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/08_8._360_Exterior_Wireframe/8._360_Exterior_Wireframe@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":1812}
- **Logical size:** 390 × 906 @ DPR 2
- **Compared pixels:** 780 × 1812
- **Generated:** 2026-11-07T22:31:37.052Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98038; min 64×64 tile 0.67275 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98038 |
| SSIM (worst 64×64 tile) | 0.67275 |
| RMSE (RGB 0–255) | 11.634 |
| MAE (RGB 0–255) | 1.899 |
| ΔE2000 mean | 0.655 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.888 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 4.5% |
| ΔE2000 > 5 | 2.11% |
| ΔE2000 > 10 | 1.47% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 304.5 | 78.5 | 54.5 | 9 | 1149 |
| 2 | 321.5 | 668 | 17.5 | 17.5 | 387 |
| 3 | 50.5 | 668 | 17.5 | 17.5 | 382 |
| 4 | 231.5 | 668 | 17.5 | 17.5 | 376 |
| 5 | 134 | 415 | 121.5 | 0.5 | 243 |
| 6 | 144.5 | 78.5 | 7 | 8.5 | 154 |
| 7 | 144 | 629.5 | 6 | 9.5 | 139 |
| 8 | 134 | 78.5 | 9 | 9 | 138 |
| 9 | 111 | 105.5 | 14.5 | 19.5 | 129 |
| 10 | 135 | 629.5 | 8 | 9.5 | 128 |
| 11 | 296.5 | 78.5 | 5 | 8.5 | 125 |
| 12 | 152.5 | 413.5 | 59 | 0.5 | 118 |
| 13 | 68 | 25.5 | 12.5 | 13.5 | 116 |
| 14 | 170 | 105 | 6 | 20 | 115 |
| 15 | 138 | 25.5 | 12.5 | 13.5 | 113 |
| 16 | 145 | 674.5 | 13.5 | 4 | 112 |
| 17 | 273.5 | 783.5 | 13.5 | 13.5 | 106 |
| 18 | 57.5 | 520.5 | 27.5 | 7.5 | 105 |
| 19 | 57.5 | 549 | 28 | 8 | 104 |
| 20 | 77 | 629.5 | 6.5 | 9.5 | 102 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `EXTERIOR INSPECTION`, `1 Detected`, `Step 2: Tap the area to
capture damage`, `Pin scratches, dents, or paint chips directly on the
wireframe schematic.`, `DRIVER SIDE VIEW`, `Front Left Door Dent`, `2.5 cm Crease • Photo
Attached`, `Edit`, `ANGLE PERSPECTIVE`, `Tap to rotate 360°`, `Front`, `Driver`, `Passenger`, `Rear`, `Confirm Exterior Markup`, `No Damage Found on this Panel`, `Vehicle Walkaround Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

