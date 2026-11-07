# Fidelity report — f3b-builder-level1

- **Sample id:** `f3b-builder-level1`
- **Batch:** `f3b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3b/builder-level1.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/08_8._Template_Builder/8._Template_Builder@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2503}
- **Logical size:** 1280 × 1251.5 @ DPR 2
- **Compared pixels:** 2560 × 2503
- **Generated:** 2026-11-07T12:29:42.554Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.9847; min 64×64 tile 0.66119 |
| Text | pass | 63 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 6/6 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.9847 |
| SSIM (worst 64×64 tile) | 0.66119 |
| RMSE (RGB 0–255) | 9.943 |
| MAE (RGB 0–255) | 1.298 |
| ΔE2000 mean | 0.383 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.409 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 1.92% |
| ΔE2000 > 5 | 1.43% |
| ΔE2000 > 10 | 1% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 1240 | 103.5 | 9 | 46.5 | 1149 |
| 2 | 282 | 877 | 56.5 | 9 | 973 |
| 3 | 299 | 677 | 38 | 11 | 660 |
| 4 | 280 | 577 | 29 | 9 | 527 |
| 5 | 369.5 | 778 | 25 | 10 | 469 |
| 6 | 315.5 | 977 | 20.5 | 9 | 399 |
| 7 | 337.5 | 677 | 23 | 9 | 390 |
| 8 | 269 | 977 | 18 | 9 | 366 |
| 9 | 261 | 877 | 22.5 | 9 | 359 |
| 10 | 292.5 | 979 | 22.5 | 7 | 331 |
| 11 | 293.5 | 777 | 18.5 | 8.5 | 329 |
| 12 | 331 | 777 | 17 | 11 | 322 |
| 13 | 331.5 | 577 | 18 | 11 | 299 |
| 14 | 347.5 | 777 | 18 | 9 | 292 |
| 15 | 315 | 777 | 15 | 10 | 280 |
| 16 | 369.5 | 579 | 16 | 7 | 249 |
| 17 | 312 | 577 | 11 | 8.5 | 218 |
| 18 | 891 | 112.5 | 16.5 | 10.5 | 212 |
| 19 | 354.5 | 879 | 16.5 | 7 | 207 |
| 20 | 220 | 123.5 | 6 | 24.5 | 204 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `topbar` | 136, 80, 1104, 114 | 136, 80, 1104, 114 | 0 | pass |
| `pod-1` | 136, 194, 258, 143 | 136, 194, 258, 143 | 0 | pass |
| `card-1` | 136, 527.5, 404.3, 84 | 136, 527.5, 404.3, 84 | 0 | pass |
| `seq-1` | 580.3, 457.5, 659.7, 128 | 580.3, 457.5, 659.7, 128 | 0 | pass |
| `drop` | 580.3, 905.5, 659.7, 168 | 580.3, 905.5, 659.7, 168 | 0 | pass |
| `qa` | 580.3, 1097.5, 659.7, 106 | 580.3, 1097.5, 659.7, 106 | 0 | pass |

## Text

- Expected: `V2.4`, `STANDARD OPERATING PROCEDURE`, `Template Builder: Comprehensive Inspection`, `Preview Flow`, `Publish Template`, `SEQUENCE TOTAL`, `3`, `of 14 configured`, `MANDATORY PHOTOS`, `1`, `checkpoint flagged`, `Optical AI analysis enabled`, `AVG FIELD TIME`, `12`, `minutes estimated`, `Fast Track Eligible`, `TELEMETRY LINK`, `Laser & OBD`, `Direct BT calibration on`, `Master Items`, `5 In Catalog`, `Available Diagnostic Checkpoints`, `Filter checkpoints by system...`, `Check Brakes & Calipers`, `Chassis`, `Wear & Hydraulics`, `Oil Level & Viscosity`, `Powertrain`, `Spectro Grade`, `Battery State of Health`, `Electrical`, `12V / High Voltage`, `Tread Depth All Axles`, `Tires`, `32nds Measurement`, `Coolant Expansion Tank`, `Fluids`, `Boilover PSI`, `Create Custom Diagnostic Item`, `Workshop Template`, `Active Inspection Sequence (Drag to reorder)`, `Autosave Active`, `01`, `Active`, `Mandatory Optical Photo`, `• Chassis Integrity`, `02`, `Value Range Input [0.0 - 8.5L]`, `• Powertrain Module`, `03`, `Automated`, `Laser Gauge Integration`, `• Tire Quad-Sensor`, `Drag master checkpoint here to append to flow`, `Or click any catalog item from the left panel to insert`, `Quality Assurance Rule Set`, `Enforces ISO-9001 brake testing standards & laser calibration validation on
save.`, `ACTIVE
POLICY`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`
- Actual: `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`, `V2.4`, `STANDARD OPERATING PROCEDURE`, `Template Builder: Comprehensive Inspection`, `Preview Flow`, `Publish Template`, `SEQUENCE TOTAL`, `3`, `of 14 configured`, `MANDATORY PHOTOS`, `1`, `checkpoint flagged`, `Optical AI analysis enabled`, `AVG FIELD TIME`, `12`, `minutes estimated`, `Fast Track Eligible`, `TELEMETRY LINK`, `Laser & OBD`, `Direct BT calibration on`, `Master Items`, `5 In Catalog`, `Available Diagnostic Checkpoints`, `Filter checkpoints by system...`, `Check Brakes & Calipers`, `Chassis`, `Wear & Hydraulics`, `Oil Level & Viscosity`, `Powertrain`, `Spectro Grade`, `Battery State of Health`, `Electrical`, `12V / High Voltage`, `Tread Depth All Axles`, `Tires`, `32nds Measurement`, `Coolant Expansion Tank`, `Fluids`, `Boilover PSI`, `Create Custom Diagnostic Item`, `Workshop Template`, `Active Inspection Sequence (Drag to reorder)`, `Autosave Active`, `01`, `Check Brakes & Calipers`, `Active`, `Mandatory Optical Photo`, `• Chassis Integrity`, `02`, `Oil Level & Viscosity`, `Active`, `Value Range Input [0.0 - 8.5L]`, `• Powertrain Module`, `03`, `Tread Depth All Axles`, `Automated`, `Laser Gauge Integration`, `• Tire Quad-Sensor`, `Drag master checkpoint here to append to flow`, `Or click any catalog item from the left panel to insert`, `Quality Assurance Rule Set`, `Enforces ISO-9001 brake testing standards & laser calibration validation on
save.`, `ACTIVE
POLICY`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

