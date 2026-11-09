# Fidelity report — f3b-staff-level1

- **Sample id:** `f3b-staff-level1`
- **Batch:** `f3b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3b/staff-level1.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/05_5._Workshop_Staff_Management/5._Workshop_Staff_Management@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2096}
- **Logical size:** 1280 × 1048 @ DPR 2
- **Compared pixels:** 2560 × 2096
- **Generated:** 2026-11-08T12:44:53.920Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.99093; min 64×64 tile 0.81302 |
| Text | pass | 55 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 4/4 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.99093 |
| SSIM (worst 64×64 tile) | 0.81302 |
| RMSE (RGB 0–255) | 7.186 |
| MAE (RGB 0–255) | 0.887 |
| ΔE2000 mean | 0.265 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.416 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 1.45% |
| ΔE2000 > 5 | 1.08% |
| ΔE2000 > 10 | 0.72% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 141.5 | 96 | 27.5 | 24 | 311 |
| 2 | 238.5 | 574.5 | 17.5 | 9 | 258 |
| 3 | 228 | 205.5 | 8 | 9 | 205 |
| 4 | 181.5 | 484.5 | 22.5 | 23.5 | 174 |
| 5 | 181.5 | 673.5 | 22.5 | 23.5 | 174 |
| 6 | 634 | 205.5 | 8 | 9 | 172 |
| 7 | 554.5 | 754 | 6 | 11 | 172 |
| 8 | 481.5 | 205.5 | 8 | 9 | 167 |
| 9 | 367.5 | 205.5 | 8 | 9 | 163 |
| 10 | 941 | 476 | 20 | 23 | 162 |
| 11 | 941 | 674 | 20 | 23 | 157 |
| 12 | 561.5 | 477 | 21 | 22 | 155 |
| 13 | 561.5 | 675 | 21 | 22 | 155 |
| 14 | 233.5 | 95.5 | 6 | 24.5 | 138 |
| 15 | 934.5 | 557.5 | 11 | 9.5 | 138 |
| 16 | 200 | 95.5 | 6 | 24.5 | 135 |
| 17 | 272 | 102.5 | 11 | 24 | 134 |
| 18 | 554.5 | 560 | 13 | 7 | 130 |
| 19 | 960 | 35 | 6.5 | 10 | 126 |
| 20 | 929.5 | 312.5 | 4 | 16.5 | 125 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `card-1` | 136, 428, 346.7, 190 | 136, 428, 346.7, 190 | 0 | pass |
| `metric-1` | 136, 264, 352, 132 | 136, 264, 352, 132 | 0 | pass |
| `add` | 1090.5, 100, 149.5, 56 | 1090.5, 100, 149.5, 56 | 0 | pass |
| `banner` | 136, 840, 1104, 112 | 136, 840, 1104, 112 | 0 | pass |

## Text

- Expected: `Workshop Staff`, `LIVE ROSTER`, `Active diagnostic technicians and shop floor administrators`, `Add Staff`, `All Staff`, `8`, `Technicians`, `5`, `Admins`, `3`, `Active Shift`, `6`, `BAY UTILIZATION`, `87.5%`, `4 of 5 active bays staffed`, `SHIFT COMPLIANCE`, `100%`, `All tickets logged & verified`, `EV SPECIALISTS`, `3 Leads`, `High-voltage ready`, `David Vance`, `Senior Technician • Bay 02`, `EV Certified`, `Level 4`, `Logged 6h 12m`, `Marcus Vance`, `Lead Inspector • Bay 04`, `Lead Master`, `Logged 7h 45m`, `Sarah Jenkins`, `Diagnostic Tech • Bay 01`, `OBD-II Specialist`, `Logged 5h 20m`, `Arthur Pendelton`, `Workshop Admin • Front Desk`, `Shop Ops`, `Logged 8h 00m`, `Liam O'Connor`, `Chassis Specialist • Bay 03`, `Suspension`, `Logged 4h 10m`, `Elena Rostova`, `Shop Floor Supervisor`, `Off Shift`, `Returns 08:00 AM`, `Auto-Shift NFC Badging Active`, `Terminal 3 logged 14 seamless shop floor entries in the last hour`, `Download Roster PDF`, `Shift Rules`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`
- Actual: `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`, `Workshop Staff`, `LIVE ROSTER`, `Active diagnostic technicians and shop floor administrators`, `Add Staff`, `All Staff`, `8`, `Technicians`, `5`, `Admins`, `3`, `Active Shift`, `6`, `BAY UTILIZATION`, `87.5%`, `4 of 5 active bays staffed`, `SHIFT COMPLIANCE`, `100%`, `All tickets logged & verified`, `EV SPECIALISTS`, `3 Leads`, `High-voltage ready`, `David Vance`, `Senior Technician • Bay 02`, `EV Certified`, `Level 4`, `Logged 6h 12m`, `Marcus Vance`, `Lead Inspector • Bay 04`, `Lead Master`, `Logged 7h 45m`, `Sarah Jenkins`, `Diagnostic Tech • Bay 01`, `OBD-II Specialist`, `Logged 5h 20m`, `Arthur Pendelton`, `Workshop Admin • Front Desk`, `Shop Ops`, `Logged 8h 00m`, `Liam O'Connor`, `Chassis Specialist • Bay 03`, `Suspension`, `Logged 4h 10m`, `Elena Rostova`, `Shop Floor Supervisor`, `Off Shift`, `Returns 08:00 AM`, `Auto-Shift NFC Badging Active`, `Terminal 3 logged 14 seamless shop floor entries in the last hour`, `Download Roster PDF`, `Shift Rules`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

