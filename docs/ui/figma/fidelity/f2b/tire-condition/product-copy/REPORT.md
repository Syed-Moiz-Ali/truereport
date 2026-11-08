# Fidelity report — f2b-tire-condition-product-copy

- **Sample id:** `f2b-tire-condition-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/tire-condition-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/13_12._Tire_Condition_Capture/12._Tire_Condition_Capture@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2171}
- **Logical size:** 390 × 1085.5 @ DPR 2
- **Compared pixels:** 780 × 2171
- **Generated:** 2026-11-08T08:22:47.456Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98057; min 64×64 tile 0.64 |
| Text | pass | 26 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 4/4 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98057 |
| SSIM (worst 64×64 tile) | 0.64 |
| RMSE (RGB 0–255) | 11.046 |
| MAE (RGB 0–255) | 1.869 |
| ΔE2000 mean | 0.599 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.632 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 3.51% |
| ΔE2000 > 5 | 1.78% |
| ΔE2000 > 10 | 1.27% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 317 | 597.5 | 15 | 7 | 235 |
| 2 | 132 | 25.5 | 18.5 | 13.5 | 195 |
| 3 | 56 | 910.5 | 17 | 9.5 | 189 |
| 4 | 86 | 157.5 | 18.5 | 23.5 | 176 |
| 5 | 106.5 | 689.5 | 22 | 11.5 | 158 |
| 6 | 237 | 900.5 | 6 | 10 | 155 |
| 7 | 85 | 900.5 | 8 | 10 | 150 |
| 8 | 310.5 | 826 | 10.5 | 10 | 141 |
| 9 | 260 | 903 | 9 | 7.5 | 141 |
| 10 | 246.5 | 900.5 | 6 | 10 | 134 |
| 11 | 253.5 | 903 | 6 | 7.5 | 129 |
| 12 | 68 | 25.5 | 12.5 | 13.5 | 128 |
| 13 | 113 | 900.5 | 6 | 10 | 125 |
| 14 | 151.5 | 903 | 5.5 | 7.5 | 124 |
| 15 | 240.5 | 826 | 9 | 12 | 123 |
| 16 | 123.5 | 903 | 5.5 | 7.5 | 122 |
| 17 | 26 | 82.5 | 6 | 8.5 | 118 |
| 18 | 93.5 | 903 | 6.5 | 7.5 | 118 |
| 19 | 163.5 | 731 | 9 | 6 | 117 |
| 20 | 103.5 | 900.5 | 6 | 10 | 117 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `chassisCard` | 20, 244, 350, 288 | 20, 244, 350, 288 | 0 | pass |
| `detailCard` | 20, 556, 350, 489.5 | 20, 556, 350, 489.5 | 0 | pass |
| `saveButton` | 44, 965.5, 302, 56 | 44, 965.5, 302, 56 | 0 | pass |

## Text

- Expected: `Vehicle Walkaround Inspection`, `INSPECTION SEQUENCE`, `6 of 8 Completed`, `Step 6: Set condition for
each tyre`, `FL`, `FR`, `RLT`, `RR`, `Active Zone`, `RLT — Rear Left Tyre`, `Axle 2 • Michelin Pilot Sport 4S`, `Verified`, `Physical Wear Assessment`, `As New`, `OEM Standard (>6mm)`, `Part Worn`, `Usable Wear (3-6mm)`, `Measured Groove Depth`, `Legal Minimum: 1.6 mm`, `Tread Depth
(mm)`, `7.2`, `Cold Pressure`, `34.5 PSI (Norm)`, `Sidewall`, `No Gouges / Flaws`, `SAVE`
- Actual: `INSPECTION SEQUENCE`, `6 of 8 Completed`, `Step 6: Set condition for
each tyre`, `Tap any wheel position on the chassis to log physical
wear.`, `FL`, `FR`, `RR`, `RLT`, `Active Zone`, `RLT — Rear Left Tyre`, `Axle 2 • Michelin Pilot Sport 4S`, `Verified`, `Physical Wear Assessment`, `As New`, `OEM Standard (>6mm)`, `Part Worn`, `Usable Wear (3-6mm)`, `Measured Groove Depth`, `Legal Minimum: 1.6 mm`, `Tread Depth
(mm)`, `7.2`, `Cold Pressure`, `34.5 PSI (Norm)`, `Sidewall`, `No Gouges / Flaws`, `SAVE`, `Vehicle Walkaround Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

