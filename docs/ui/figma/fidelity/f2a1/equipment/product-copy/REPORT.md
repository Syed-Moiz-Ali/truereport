# Fidelity report — f2a1-equipment-product-copy

- **Sample id:** `f2a1-equipment-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/equipment-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/06_6._Equipment_Checklist/6._Equipment_Checklist@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":1820}
- **Logical size:** 390 × 910 @ DPR 2
- **Compared pixels:** 780 × 1820
- **Generated:** 2026-11-06T04:36:14.588Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.91971; min 64×64 tile 0.20397 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.91971 |
| SSIM (worst 64×64 tile) | 0.20397 |
| RMSE (RGB 0–255) | 26.036 |
| MAE (RGB 0–255) | 5.18 |
| ΔE2000 mean | 1.661 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 3.584 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 7.87% |
| ΔE2000 > 5 | 3.89% |
| ΔE2000 > 10 | 3.28% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 314.5 | 260 | 39 | 39 | 4669 |
| 2 | 137 | 185 | 43 | 14.5 | 1110 |
| 3 | 86 | 29 | 41.5 | 14 | 992 |
| 4 | 53 | 719.5 | 14 | 25.5 | 963 |
| 5 | 195 | 722 | 38 | 12 | 905 |
| 6 | 104.5 | 361.5 | 13 | 39.5 | 874 |
| 7 | 53 | 269.5 | 22 | 13 | 752 |
| 8 | 218.5 | 185 | 35 | 11.5 | 719 |
| 9 | 65 | 25.5 | 20 | 17 | 708 |
| 10 | 96 | 722 | 29.5 | 12 | 641 |
| 11 | 118.5 | 362 | 10 | 21 | 579 |
| 12 | 133.5 | 282 | 30.5 | 10.5 | 576 |
| 13 | 188.5 | 365 | 11.5 | 27.5 | 567 |
| 14 | 104 | 282 | 28.5 | 10 | 556 |
| 15 | 153.5 | 365 | 13.5 | 36 | 539 |
| 16 | 129.5 | 362 | 11 | 21 | 521 |
| 17 | 53 | 483 | 22 | 22 | 503 |
| 18 | 168 | 723.5 | 20.5 | 12.5 | 490 |
| 19 | 132 | 722 | 20.5 | 14 | 456 |
| 20 | 189.5 | 188 | 20 | 11 | 453 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `01`, `PRE-INSPECTION SETUP`, `4 items`, `Required Equipment`, `Ensure all diagnostic hardware is calibrated and paired before starting the inspection.`, `Tire Depth Gauge`, `TDG · ACTIVE`, `OBD Scanner`, `OBD · ACTIVE`, `Torque Wrench`, `TW · ACTIVE`, `Paint Depth Gauge`, `PDG · ACTIVE`, `Workshop equipment standards`, `Equipment availability is confirmed by the workshop.`, `Proceed`, `Equipment`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

