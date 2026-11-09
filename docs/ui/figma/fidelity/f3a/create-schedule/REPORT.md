# Fidelity report — f3a-schedule-level1

- **Sample id:** `f3a-schedule-level1`
- **Batch:** `f3a-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/schedule-level1.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/01_3._Create_-_Schedule_Job/3._Create_-_Schedule_Job@2x.png`
- **Reference crop (px):** {"x":32,"y":90,"width":2560,"height":2116}
- **Logical size:** 1280 × 1058 @ DPR 2
- **Compared pixels:** 2560 × 2116
- **Generated:** 2026-11-08T12:34:50.554Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98569; min 64×64 tile 0.27108 |
| Text | pass | 66 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98569 |
| SSIM (worst 64×64 tile) | 0.27108 |
| RMSE (RGB 0–255) | 9.876 |
| MAE (RGB 0–255) | 1.515 |
| ΔE2000 mean | 0.487 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.487 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 3.02% |
| ΔE2000 > 5 | 0.91% |
| ΔE2000 > 10 | 0.58% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 547.5 | 368 | 41 | 25.5 | 3099 |
| 2 | 178 | 373.5 | 30 | 16 | 1250 |
| 3 | 304 | 458 | 40 | 13.5 | 1071 |
| 4 | 173.5 | 458 | 34 | 12.5 | 978 |
| 5 | 150 | 156 | 24 | 9 | 481 |
| 6 | 908 | 711 | 13.5 | 20.5 | 477 |
| 7 | 225.5 | 460.5 | 46.5 | 5 | 441 |
| 8 | 933.5 | 706 | 14.5 | 13.5 | 377 |
| 9 | 1042 | 706 | 13 | 13.5 | 347 |
| 10 | 271 | 460.5 | 34.5 | 4.5 | 320 |
| 11 | 932.5 | 510 | 9.5 | 13.5 | 256 |
| 12 | 992.5 | 708.5 | 7 | 13.5 | 255 |
| 13 | 1073 | 595 | 9 | 10.5 | 239 |
| 14 | 1014.5 | 595 | 9 | 10.5 | 238 |
| 15 | 1033.5 | 595 | 9 | 10.5 | 238 |
| 16 | 174.5 | 158.5 | 23 | 4 | 232 |
| 17 | 932.5 | 532 | 10 | 12 | 230 |
| 18 | 1006.5 | 510 | 8.5 | 13.5 | 223 |
| 19 | 967.5 | 510 | 9.5 | 13.5 | 222 |
| 20 | 993 | 510 | 9.5 | 13.5 | 220 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `drawer` | 860, 0, 420, 1058 | 860, 0, 420, 1058 | 0 | pass |
| `drawer-head` | 892, 40, 356, 126 | 892, 40, 356, 126 | 0 | pass |
| `drawer-cta` | 892, 936, 356, 56 | 892, 936, 356, 56 | 0 | pass |

## Text

- Expected: `ACTIVE BAY OPERATIONS`, `Live Job Queue`, `Active Work Orders`, `18 Vehicles`, `Bays Available`, `3 of 8 Open`, `Bay 01 • In Progress`, `2023 Audi RS6 Avant`, `VIN: WUA894G23PN01928`, `Customer`, `Julian Vance`, `Comprehensive 110-Point`, `75%`, `Bay 02 • Intake Ready`, `2022 Rivian R1T`, `VIN: 7PDSGABA4NN00318`, `Elena Rostova`, `Standard 60-Point`, `20%`, `Bay 04 • Inspection Hold`, `2021 BMW M4 Competition`, `VIN: WBS43AZ08MCH91024`, `Marcus Vance (Fleet)`, `Pre-Purchase Audit`, `40%`, `Facility Bay Allocations`, `Real-time lift assignment and hardware readiness`, `Refresh Sensors`, `Bay 01`, `Occupied`, `Bay 02`, `Bay 03`, `Available`, `Bay 04`, `Hold`, `Bay 05`, `Scheduled`, `Bay 06`, `Bay 07`, `Bay 08`, `Service Off`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`, `BAY INTAKE`, `Schedule New Job`, `Create an intake record and assign to technician
bay`, `Customer Name`, `e.g. Arthur Pendelton`, `Vehicle Make & Model`, `e.g. 2024 Porsche Taycan 4S`, `Select Date & Bay`, `Today, 2:30 PM (Bay 03)`, `Inspection Protocol Tier`, `Standard 60-Point`, `Quick triage & safety verification`, `30m`, `Full Comprehensive 110-Point`, `High-voltage battery, chassis &
powertrain`, `75m`, `Auto-assign Lead Tech`, `Marcus Vance assigned to Bay 03`, `Create Job`, `Notifies floor dispatch and syncs telematics`
- Actual: `ACTIVE BAY OPERATIONS`, `Live Job Queue`, `Active Work Orders`, `18 Vehicles`, `Bays Available`, `3 of 8 Open`, `Bay 01 • In Progress`, `2023 Audi RS6 Avant`, `VIN: WUA894G23PN01928`, `Customer`, `Julian Vance`, `Comprehensive 110-Point`, `75%`, `Bay 02 • Intake Ready`, `2022 Rivian R1T`, `VIN: 7PDSGABA4NN00318`, `Customer`, `Elena Rostova`, `Standard 60-Point`, `20%`, `Bay 04 • Inspection Hold`, `2021 BMW M4 Competition`, `VIN: WBS43AZ08MCH91024`, `Customer`, `Marcus Vance (Fleet)`, `Pre-Purchase Audit`, `40%`, `Facility Bay Allocations`, `Real-time lift assignment and hardware readiness`, `Refresh Sensors`, `Bay 01`, `Occupied`, `Bay 02`, `Occupied`, `Bay 03`, `Available`, `Bay 04`, `Hold`, `Bay 05`, `Scheduled`, `Bay 06`, `Available`, `Bay 07`, `Available`, `Bay 08`, `Service Off`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`, `BAY INTAKE`, `Schedule New Job`, `Create an intake record and assign to technician
bay`, `Customer Name`, `e.g. Arthur Pendelton`, `Vehicle Make & Model`, `e.g. 2024 Porsche Taycan 4S`, `Select Date & Bay`, `Today, 2:30 PM (Bay 03)`, `Inspection Protocol Tier`, `Standard 60-Point`, `Quick triage & safety verification`, `30m`, `Full Comprehensive 110-Point`, `High-voltage battery, chassis &
powertrain`, `75m`, `Auto-assign Lead Tech`, `Marcus Vance assigned to Bay 03`, `Create Job`, `Notifies floor dispatch and syncs telematics`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

