# Fidelity report — f3a-dashboard-level2

- **Sample id:** `f3a-dashboard-level2`
- **Batch:** `f3a-dashboard`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3a/dashboard-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/02_1._Workshop_Dashboard/1._Workshop_Dashboard@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2461}
- **Logical size:** 1280 × 1230.672 @ DPR 2
- **Compared pixels:** 2560 × 2461
- **Generated:** 2026-11-08T12:16:46.010Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.97682; min 64×64 tile 0.30484 |
| Text | fail | 28 missing |
| Forbidden terms | fail | 7 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.97682 |
| SSIM (worst 64×64 tile) | 0.30484 |
| RMSE (RGB 0–255) | 12.825 |
| MAE (RGB 0–255) | 1.586 |
| ΔE2000 mean | 0.492 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.401 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 2.3% |
| ΔE2000 > 5 | 1.48% |
| ΔE2000 > 10 | 1.19% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 168.5 | 432 | 29 | 27.5 | 1746 |
| 2 | 547.5 | 432.5 | 19.5 | 26.5 | 1203 |
| 3 | 680 | 988 | 33.5 | 12.5 | 904 |
| 4 | 815 | 34.5 | 37.5 | 11 | 762 |
| 5 | 924 | 34.5 | 34 | 12.5 | 618 |
| 6 | 927.5 | 432 | 17 | 20.5 | 596 |
| 7 | 927 | 518.5 | 279.5 | 0.5 | 559 |
| 8 | 927.5 | 512.5 | 278.5 | 0.5 | 557 |
| 9 | 891.5 | 34.5 | 27 | 12.5 | 516 |
| 10 | 953.5 | 34.5 | 25 | 11 | 485 |
| 11 | 170 | 512.5 | 237 | 1 | 476 |
| 12 | 169.5 | 518.5 | 237 | 0.5 | 474 |
| 13 | 678.5 | 872 | 19 | 10 | 432 |
| 14 | 1010.5 | 828 | 114.5 | 31.5 | 412 |
| 15 | 200.5 | 112 | 22 | 19 | 396 |
| 16 | 669 | 886 | 16.5 | 10 | 391 |
| 17 | 685 | 886 | 16 | 10 | 352 |
| 18 | 662.5 | 872 | 16 | 10 | 340 |
| 19 | 937.5 | 250 | 22.5 | 18 | 317 |
| 20 | 851.5 | 34.5 | 19.5 | 10.5 | 307 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Overview`, `Search jobs`, `Jobs by status in your workshop`, `7`, `Active jobs`, `5`, `New & scheduled`, `3`, `In progress`, `2`, `Ready to finalize`, `1`, `Finalized today`, `Recent jobs`, `JOB-0001 · Customer A`, `Toyota Camry`, `Full inspection`, `Scheduled at: 2026-11-05T09:00:00`, `Assigned to: Technician A`, `JOB-0002 · Customer B`, `Honda Civic`, `Scheduled at: 2026-11-05T10:00:00`, `JOB-0003 · Customer C`, `Finalized`, `Ford Transit`, `Scheduled at: 2026-11-04T09:00:00`, `Assigned to: Unassigned`, `JOB-0004 · Customer D`, `Assigned`, `Nissan Patrol`, `Scheduled at: 2026-11-06T09:00:00`
- Actual: `TELEMETRICS • REAL-TIME`, `Overview`, `Fleet throughput and active inspection velocity today`, `Shift A (Current)`, `Past 24h`, `Dispatch Bay`, `+2 incoming`, `3`, `/ 14 BAYS`, `Active Jobs`, `Requires Action`, `2`, `QUEUE`, `Pending Finalization`, `6`, `100% ACCURACY`, `Reports Sent`, `Live Workshop Activity`, `Real-time status stream across active physical bays`, `FEED SYNCED`, `Porsche Taycan 4S`, `VIN • 9J18`, `Bay 04 • Full diagnostic pass complete (48/48 points checked)`, `Passed`, `2m ago`, `Ford Transit Custom`, `VIN • 3E41`, `Bay 02 • Secondary structural markup awaiting lead
inspector review`, `Awaiting
Review`, `14m
ago`, `Renault Mégane E-Tech`, `VIN • 7K89`, `Bay 01 • Sign-off certificate compiled and dispatched to fleet
lead`, `Signed
Off`, `42m
ago`, `Floor Telemetry`, `Bays 01-08`, `76%`, `CAPACITY`, `Turnaround Target`, `45 mins / car`, `Median Flow Rate`, `38 mins`, `Inspection Compliance`, `99.4%`, `View Detailed Floor Map`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`
- Missing: `Search jobs`, `Jobs by status in your workshop`, `7`, `Active jobs`, `5`, `New & scheduled`, `In progress`, `Ready to finalize`, `1`, `Finalized today`, `Recent jobs`, `JOB-0001 · Customer A`, `Toyota Camry`, `Full inspection`, `Scheduled at: 2026-11-05T09:00:00`, `Assigned to: Technician A`, `JOB-0002 · Customer B`, `Honda Civic`, `Scheduled at: 2026-11-05T10:00:00`, `JOB-0003 · Customer C`, `Finalized`, `Ford Transit`, `Scheduled at: 2026-11-04T09:00:00`, `Assigned to: Unassigned`, `JOB-0004 · Customer D`, `Assigned`, `Nissan Patrol`, `Scheduled at: 2026-11-06T09:00:00`

### Forbidden-term matches

- **vin** (term) matched `VIN`: …ED SYNCED Porsche Taycan 4S VIN • 9J18 Bay 04 • Full diagno…
- **vin** (term) matched `VIN`: … 2m ago Ford Transit Custom VIN • 3E41 Bay 02 • Secondary s…
- **vin** (term) matched `VIN`: …m ago Renault Mégane E-Tech VIN • 7K89 Bay 01 • Sign-off ce…
- **sign-off** (term) matched `Sign-off`: … E-Tech VIN • 7K89 Bay 01 • Sign-off certificate compiled and di…
- **certificate** (term) matched `certificate`: …IN • 7K89 Bay 01 • Sign-off certificate compiled and dispatched to …
- **compliance** (term) matched `Compliance`: …low Rate 38 mins Inspection Compliance 99.4% View Detailed Floor M…
- **vin** (term) matched `VIN`: …CTIVE Shop Floor #04 Search VIN, tech, job ticket... Marcus…

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

