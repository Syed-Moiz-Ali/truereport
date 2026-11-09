# Fidelity report — f3a-dashboard-level1

- **Sample id:** `f3a-dashboard-level1`
- **Batch:** `f3a-dashboard`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/dashboard-level1.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/02_1._Workshop_Dashboard/1._Workshop_Dashboard@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2461}
- **Logical size:** 1280 × 1230.672 @ DPR 2
- **Compared pixels:** 2560 × 2461
- **Generated:** 2026-11-08T12:13:55.789Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98137; min 64×64 tile 0.38973 |
| Text | pass | 51 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 4/4 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98137 |
| SSIM (worst 64×64 tile) | 0.38973 |
| RMSE (RGB 0–255) | 10.791 |
| MAE (RGB 0–255) | 1.302 |
| ΔE2000 mean | 0.396 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.401 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 1.78% |
| ΔE2000 > 5 | 1.37% |
| ΔE2000 > 10 | 1.06% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 680 | 989 | 33.5 | 11.5 | 880 |
| 2 | 927 | 518.5 | 279.5 | 0.5 | 559 |
| 3 | 927.5 | 512.5 | 278.5 | 0.5 | 557 |
| 4 | 180.5 | 431 | 17 | 26 | 516 |
| 5 | 170 | 512.5 | 237 | 1 | 476 |
| 6 | 169.5 | 518.5 | 237 | 0.5 | 474 |
| 7 | 1010.5 | 828 | 114.5 | 31.5 | 412 |
| 8 | 680 | 873 | 17.5 | 9 | 366 |
| 9 | 669 | 887 | 16.5 | 9 | 349 |
| 10 | 685 | 887 | 16 | 9 | 339 |
| 11 | 547.5 | 431.5 | 20 | 25.5 | 330 |
| 12 | 662.5 | 873 | 16 | 9 | 324 |
| 13 | 937.5 | 250 | 22.5 | 18 | 317 |
| 14 | 168.5 | 431.5 | 10.5 | 25.5 | 295 |
| 15 | 1028.5 | 824.5 | 83 | 22 | 288 |
| 16 | 727.5 | 764 | 7 | 15 | 268 |
| 17 | 720.5 | 766 | 6.5 | 13 | 247 |
| 18 | 701.5 | 766 | 6 | 13 | 239 |
| 19 | 1104.5 | 120.5 | 117 | 0.5 | 234 |
| 20 | 1029.5 | 655 | 14.5 | 13.5 | 234 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 96, 0, 1184, 80 | 96, 0, 1184, 80 | 0 | pass |
| `kpi-1` | 136, 204, 346.7, 346.7 | 136, 204, 346.7, 346.7 | 0.01 | pass |
| `activity` | 136, 614.7, 725.3, 476 | 136, 614.7, 725.3, 476 | 0 | pass |
| `telemetry` | 893.3, 614.7, 346.7, 566 | 893.3, 614.7, 346.7, 566 | 0 | pass |

## Text

- Expected: `TELEMETRICS • REAL-TIME`, `Overview`, `Fleet throughput and active inspection velocity today`, `Shift A (Current)`, `Past 24h`, `Dispatch Bay`, `12`, `/ 14 BAYS`, `+2 incoming`, `Active Jobs`, `4`, `QUEUE`, `Requires Action`, `Pending Finalization`, `8`, `100% ACCURACY`, `Reports Sent`, `Live Workshop Activity`, `Real-time status stream across active physical bays`, `FEED SYNCED`, `Porsche Taycan 4S`, `VIN • 9J18`, `Bay 04 • Full diagnostic pass complete (48/48 points checked)`, `Passed`, `2m ago`, `Ford Transit Custom`, `VIN • 3E41`, `Bay 02 • Secondary structural markup awaiting lead
inspector review`, `Awaiting
Review`, `14m
ago`, `Renault Mégane E-Tech`, `VIN • 7K89`, `Bay 01 • Sign-off certificate compiled and dispatched to fleet
lead`, `Signed
Off`, `42m
ago`, `Floor Telemetry`, `Bays 01-08`, `76%`, `CAPACITY`, `Turnaround Target`, `45 mins / car`, `Median Flow Rate`, `38 mins`, `Inspection Compliance`, `99.4%`, `View Detailed Floor Map`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`
- Actual: `TELEMETRICS • REAL-TIME`, `Overview`, `Fleet throughput and active inspection velocity today`, `Shift A (Current)`, `Past 24h`, `Dispatch Bay`, `+2 incoming`, `12`, `/ 14 BAYS`, `Active Jobs`, `Requires Action`, `4`, `QUEUE`, `Pending Finalization`, `8`, `100% ACCURACY`, `Reports Sent`, `Live Workshop Activity`, `Real-time status stream across active physical bays`, `FEED SYNCED`, `Porsche Taycan 4S`, `VIN • 9J18`, `Bay 04 • Full diagnostic pass complete (48/48 points checked)`, `Passed`, `2m ago`, `Ford Transit Custom`, `VIN • 3E41`, `Bay 02 • Secondary structural markup awaiting lead
inspector review`, `Awaiting
Review`, `14m
ago`, `Renault Mégane E-Tech`, `VIN • 7K89`, `Bay 01 • Sign-off certificate compiled and dispatched to fleet
lead`, `Signed
Off`, `42m
ago`, `Floor Telemetry`, `Bays 01-08`, `76%`, `CAPACITY`, `Turnaround Target`, `45 mins / car`, `Median Flow Rate`, `38 mins`, `Inspection Compliance`, `99.4%`, `View Detailed Floor Map`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

