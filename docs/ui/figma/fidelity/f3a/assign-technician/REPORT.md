# Fidelity report — f3a-assign-level1

- **Sample id:** `f3a-assign-level1`
- **Batch:** `f3a-assign-technician`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/assign-level1.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/04_4._Assign_Technician/4._Assign_Technician@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2240}
- **Logical size:** 1280 × 1120 @ DPR 2
- **Compared pixels:** 2560 × 2240
- **Generated:** 2026-11-07T10:09:14.362Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.99135; min 64×64 tile 0.65239 |
| Text | pass | 38 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.99135 |
| SSIM (worst 64×64 tile) | 0.65239 |
| RMSE (RGB 0–255) | 6.972 |
| MAE (RGB 0–255) | 0.98 |
| ΔE2000 mean | 0.335 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.015 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 2.08% |
| ΔE2000 > 5 | 0.64% |
| ΔE2000 > 10 | 0.4% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 26.5 | 213 | 44.5 | 45.5 | 4660 |
| 2 | 1211 | 26.5 | 26.5 | 25 | 1910 |
| 3 | 0 | 212.5 | 5.5 | 40.5 | 485 |
| 4 | 477.5 | 246.5 | 8 | 11.5 | 204 |
| 5 | 576.5 | 497 | 7.5 | 11 | 201 |
| 6 | 524 | 246.5 | 7 | 11.5 | 198 |
| 7 | 597 | 248.5 | 7 | 11.5 | 198 |
| 8 | 447 | 246.5 | 8 | 11.5 | 193 |
| 9 | 614.5 | 246.5 | 7.5 | 11.5 | 191 |
| 10 | 426.5 | 246.5 | 6.5 | 11.5 | 188 |
| 11 | 459 | 246.5 | 6.5 | 11.5 | 184 |
| 12 | 487 | 246.5 | 6.5 | 11.5 | 183 |
| 13 | 532 | 396.5 | 7.5 | 11 | 181 |
| 14 | 539.5 | 246.5 | 6 | 11.5 | 174 |
| 15 | 447 | 575 | 18.5 | 18 | 172 |
| 16 | 608.5 | 399 | 7 | 8.5 | 169 |
| 17 | 563.5 | 248 | 6.5 | 9 | 166 |
| 18 | 668 | 396.5 | 7 | 11 | 166 |
| 19 | 578.5 | 246.5 | 6 | 11.5 | 165 |
| 20 | 611 | 497 | 7 | 11 | 165 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `modal` | 384, 206, 512, 660 | 384, 206, 512, 660 | 0 | pass |
| `tech-card-1` | 416, 450, 448, 80 | 416, 450, 448, 80 | 0 | pass |
| `confirm` | 526.9, 774, 337.1, 56 | 526.9, 774, 337.1, 56 | 0 | pass |

## Text

- Expected: `ACTIVE DISPATCH BOARD`, `Service Bay Diagnostics`, `Shift A • Morning Inflow`, `12 Bays Operational`, `#1040 • Express`, `In Progress`, `Audi e-tron GT`, `VIN: 9AU4810294J`, `#1041 • Heavy`, `Inspection`, `Freightliner M2`, `VIN: 1FUJGLD9381`, `#1042 • Intake`, `Unassigned`, `2024 Ford Transit`, `VIN: 1FTBR1Y80RKA391`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`, `REPAIR TICKET #1042`, `Stage 01`, `Assign Technician for Job #1042`, `Select an available certified specialist for 2024 Ford Transit`, `Transit 350 High Roof`, `3.5L EcoBoost • Brake System Recall`, `Est. 2.5h`, `David Vance`, `Brakes L2`, `1 Active Job • Bay 02`, `Lead Tech`, `3 Active Jobs • Bay 04`, `Sarah Jenkins`, `Powertrain`, `0 Active Jobs • Bay 01 (Available)`, `Cancel`, `Confirm Assignment`
- Actual: `ACTIVE DISPATCH BOARD`, `Service Bay Diagnostics`, `Shift A • Morning Inflow`, `12 Bays Operational`, `#1040 • Express`, `In Progress`, `Audi e-tron GT`, `VIN: 9AU4810294J`, `#1041 • Heavy`, `Inspection`, `Freightliner M2`, `VIN: 1FUJGLD9381`, `#1042 • Intake`, `Unassigned`, `2024 Ford Transit`, `VIN: 1FTBR1Y80RKA391`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`, `REPAIR TICKET #1042`, `Stage 01`, `Assign Technician for Job #1042`, `Select an available certified specialist for 2024 Ford Transit`, `Transit 350 High Roof`, `3.5L EcoBoost • Brake System Recall`, `Est. 2.5h`, `David Vance`, `Brakes L2`, `1 Active Job • Bay 02`, `Marcus Vance`, `Lead Tech`, `3 Active Jobs • Bay 04`, `Sarah Jenkins`, `Powertrain`, `0 Active Jobs • Bay 01 (Available)`, `Cancel`, `Confirm Assignment`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

