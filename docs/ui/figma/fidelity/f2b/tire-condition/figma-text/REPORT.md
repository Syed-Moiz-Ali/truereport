# Fidelity report — f2b-tire-condition-figma-text

- **Sample id:** `f2b-tire-condition-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/tire-condition-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/13_12._Tire_Condition_Capture/12._Tire_Condition_Capture@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2171}
- **Logical size:** 390 × 1085.5 @ DPR 2
- **Compared pixels:** 780 × 2171
- **Generated:** 2026-11-08T07:42:23.120Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.97266; min 64×64 tile 0.64 |
| Text | pass | 26 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 4/4 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.97266 |
| SSIM (worst 64×64 tile) | 0.64 |
| RMSE (RGB 0–255) | 16.773 |
| MAE (RGB 0–255) | 2.583 |
| ΔE2000 mean | 0.863 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.679 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 3.8% |
| ΔE2000 > 5 | 2.1% |
| ΔE2000 > 10 | 1.59% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 236.5 | 25.5 | 62.5 | 17.5 | 1873 |
| 2 | 64 | 25 | 36 | 14.5 | 1164 |
| 3 | 162.5 | 25 | 41.5 | 14.5 | 1112 |
| 4 | 128 | 25.5 | 30.5 | 13.5 | 988 |
| 5 | 207.5 | 25 | 28 | 14.5 | 879 |
| 6 | 299.5 | 29 | 24.5 | 10.5 | 677 |
| 7 | 316 | 501 | 26 | 10 | 591 |
| 8 | 100.5 | 25.5 | 14 | 14 | 388 |
| 9 | 115.5 | 25 | 13.5 | 14.5 | 383 |
| 10 | 282.5 | 501 | 17.5 | 10 | 341 |
| 11 | 300.5 | 501 | 14 | 10 | 292 |
| 12 | 317 | 597.5 | 15 | 7 | 235 |
| 13 | 56 | 910.5 | 17 | 9.5 | 189 |
| 14 | 201.5 | 29 | 7 | 10.5 | 183 |
| 15 | 86 | 157.5 | 18.5 | 23.5 | 176 |
| 16 | 106.5 | 689.5 | 22 | 11.5 | 158 |
| 17 | 237 | 900.5 | 6 | 10 | 155 |
| 18 | 85 | 900.5 | 8 | 10 | 150 |
| 19 | 260 | 903 | 9 | 7.5 | 141 |
| 20 | 246.5 | 900.5 | 6 | 10 | 134 |

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

