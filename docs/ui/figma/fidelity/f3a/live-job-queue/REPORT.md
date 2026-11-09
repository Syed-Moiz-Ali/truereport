# Fidelity report — f3a-queue-level1

- **Sample id:** `f3a-queue-level1`
- **Batch:** `f3a-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/queue-level1.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/03_2._Live_Job_Queue/2._Live_Job_Queue@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2250}
- **Logical size:** 1280 × 1125 @ DPR 2
- **Compared pixels:** 2560 × 2250
- **Generated:** 2026-11-08T12:32:52.980Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98194; min 64×64 tile 0.66562 |
| Text | pass | 54 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98194 |
| SSIM (worst 64×64 tile) | 0.66562 |
| RMSE (RGB 0–255) | 11.38 |
| MAE (RGB 0–255) | 1.341 |
| ΔE2000 mean | 0.414 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.503 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 1.7% |
| ΔE2000 > 5 | 1.28% |
| ΔE2000 > 10 | 0.98% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 926.5 | 907 | 48 | 12 | 967 |
| 2 | 903.5 | 907 | 16 | 9.5 | 348 |
| 3 | 507 | 411 | 12.5 | 11 | 247 |
| 4 | 335 | 759 | 7.5 | 11 | 230 |
| 5 | 314.5 | 585 | 7.5 | 11 | 229 |
| 6 | 349 | 933 | 13 | 11 | 225 |
| 7 | 485.5 | 587.5 | 7.5 | 11.5 | 224 |
| 8 | 334.5 | 411 | 8 | 11 | 222 |
| 9 | 308 | 933 | 8 | 11 | 222 |
| 10 | 294.5 | 411 | 12.5 | 11 | 221 |
| 11 | 294.5 | 933 | 12.5 | 11 | 221 |
| 12 | 148 | 87 | 8 | 11 | 220 |
| 13 | 1108.5 | 731 | 7.5 | 12.5 | 219 |
| 14 | 211 | 87 | 8.5 | 11 | 215 |
| 15 | 527 | 413.5 | 7 | 11.5 | 213 |
| 16 | 434.5 | 519.5 | 14 | 16.5 | 210 |
| 17 | 379.5 | 411 | 7.5 | 11 | 208 |
| 18 | 301.5 | 867.5 | 22.5 | 16.5 | 208 |
| 19 | 231 | 87 | 7.5 | 11 | 204 |
| 20 | 300 | 585 | 13.5 | 11 | 204 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `queue-card-1` | 136, 307, 1104, 150 | 136, 307, 1104, 150 | 0 | pass |
| `queue-filters` | 136, 227, 542.1, 48 | 136, 227, 542.1, 48 | 0 | pass |
| `queue-new-job` | 1082.9, 127, 157.1, 56 | 1082.9, 127, 157.1, 56 | 0 | pass |

## Text

- Expected: `REAL-TIME DISPATCH`, `Live Job Queue`, `All vehicles currently in bays or scheduled for inspection`, `ACTIVE BAYS`, `06 / 08`, `AVG TURNAROUND`, `42m`, `+ New Job`, `All (12)`, `In Progress (4)`, `Pending Review (3)`, `Completed (5)`, `Bay Order`, `Porsche 911 Carrera S`, `In Progress`, `VIN`, `WP0AB2A91LS`, `•`, `Alexander Wright`, `MV`, `ASSIGNED TECH`, `Marcus Vance (Bay 04)`, `PROGRESS`, `65%`, `Ford Transit 350 High Roof`, `Pending Review`, `1FTBR1Y88PK`, `Fleet Logistics Inc`, `DV`, `David Vance (Bay 02)`, `REVIEW ITEMS`, `2 Flags Marked`, `Renault Megan 3 E-Tech`, `VF1RCB00078`, `Arthur Pendelton`, `David Vance (Bay 01)`, `30%`, `BMW i4 M50 Gran Coupe`, `Scheduled`, `WBA33AW05N`, `Elena Rostova`, `--`, `Unassigned`, `SLOT TIME`, `14:30 Today`, `Live sync active. Updated 4 seconds ago.`, `Export Daily Log`, `Batch Reassign`, `Bay Schedule Matrix →`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`
- Actual: `REAL-TIME DISPATCH`, `Live Job Queue`, `All vehicles currently in bays or scheduled for inspection`, `ACTIVE BAYS`, `06 / 08`, `AVG TURNAROUND`, `42m`, `+ New Job`, `All (12)`, `In Progress (4)`, `Pending Review (3)`, `Completed (5)`, `Bay Order`, `Porsche 911 Carrera S`, `In Progress`, `VIN`, `WP0AB2A91LS`, `•`, `Alexander Wright`, `MV`, `ASSIGNED TECH`, `Marcus Vance (Bay 04)`, `PROGRESS`, `65%`, `Ford Transit 350 High Roof`, `Pending Review`, `VIN`, `1FTBR1Y88PK`, `•`, `Fleet Logistics Inc`, `DV`, `ASSIGNED TECH`, `David Vance (Bay 02)`, `REVIEW ITEMS`, `2 Flags Marked`, `Renault Megan 3 E-Tech`, `In Progress`, `VIN`, `VF1RCB00078`, `•`, `Arthur Pendelton`, `DV`, `ASSIGNED TECH`, `David Vance (Bay 01)`, `PROGRESS`, `30%`, `BMW i4 M50 Gran Coupe`, `Scheduled`, `VIN`, `WBA33AW05N`, `•`, `Elena Rostova`, `--`, `ASSIGNED TECH`, `Unassigned`, `SLOT TIME`, `14:30 Today`, `Live sync active. Updated 4 seconds ago.`, `Export Daily Log`, `Batch Reassign`, `Bay Schedule Matrix →`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

