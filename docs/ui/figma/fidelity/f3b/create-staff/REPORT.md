# Fidelity report — f3b-create-staff-level1

- **Sample id:** `f3b-create-staff-level1`
- **Batch:** `f3b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3b/create-staff-level1.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/07_6._Add_Staff_-_Create_Account/6._Add_Staff_-_Create_Account@2x.png`
- **Reference crop (px):** {"x":32,"y":84,"width":2560,"height":2048}
- **Logical size:** 1280 × 1024 @ DPR 2
- **Compared pixels:** 2560 × 2048
- **Generated:** 2026-11-08T12:46:33.222Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98225; min 64×64 tile 0.60225 |
| Text | pass | 54 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98225 |
| SSIM (worst 64×64 tile) | 0.60225 |
| RMSE (RGB 0–255) | 10.584 |
| MAE (RGB 0–255) | 1.625 |
| ΔE2000 mean | 0.5 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.008 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 1.44% |
| ΔE2000 > 5 | 0.86% |
| ΔE2000 > 10 | 0.72% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 1207 | 373 | 17 | 19.5 | 775 |
| 2 | 1207 | 275 | 17 | 21 | 769 |
| 3 | 876 | 699.5 | 18 | 13 | 674 |
| 4 | 1207.5 | 775.5 | 16.5 | 28 | 673 |
| 5 | 1205.5 | 474.5 | 18.5 | 15.5 | 630 |
| 6 | 1172.5 | 775.5 | 16 | 28 | 424 |
| 7 | 1194.5 | 777.5 | 13.5 | 24 | 387 |
| 8 | 942.5 | 57.5 | 8.5 | 9.5 | 206 |
| 9 | 867.5 | 536.5 | 8.5 | 9.5 | 201 |
| 10 | 174.5 | 35.5 | 7 | 9.5 | 200 |
| 11 | 1031.5 | 170.5 | 7.5 | 11.5 | 199 |
| 12 | 1182 | 170.5 | 7.5 | 11.5 | 197 |
| 13 | 868.5 | 57.5 | 9 | 9.5 | 189 |
| 14 | 921.5 | 57.5 | 8 | 9.5 | 189 |
| 15 | 840.5 | 168 | 7 | 11 | 187 |
| 16 | 896 | 536.5 | 9 | 9.5 | 187 |
| 17 | 895.5 | 57.5 | 9 | 9.5 | 185 |
| 18 | 914 | 646.5 | 9 | 9.5 | 185 |
| 19 | 1183 | 682.5 | 6.5 | 9.5 | 185 |
| 20 | 840.5 | 340.5 | 6 | 9.5 | 183 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `sheet` | 800, 0, 480, 1024 | 800, 0, 480, 1024 | 0 | pass |
| `sheet-head` | 840, 40, 400, 76 | 840, 40, 400, 76 | 0 | pass |
| `sheet-cta` | 950.9, 928, 289.1, 56 | 950.9, 928, 289.1, 56 | 0 | pass |

## Text

- Expected: `ADMINISTRATION`, `Personnel Roster`, `Staff Directory & Access`, `18 Active Technicians`, `Add Staff Member`, `4 / 4`, `Operational Diagnostic Bays`, `99.4%`, `Inspection Protocol Accuracy`, `3 Admins`, `Master Security Privileges`, `MV`, `Marcus Vance`, `m.vance@techinspect.io`, `Bay 04 (Lead)`, `AL`, `Alicia Lindqvist`, `a.lindqvist@techinspect.io`, `Bay 01`, `RK`, `Rohan Kapoor`, `r.kapoor@techinspect.io`, `Bay 02`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`, `ONBOARDING`, `Create Staff Account`, `Set up permissions, station assignments, and onboarding
credentials.`, `FULL NAME`, `e.g. David Vance`, `EMAIL ADDRESS`, `e.g. d.vance@techinspect.io`, `TEMPORARY PASSWORD`, `InspectGuard99!`, `ASSIGN ROLE (TECHNICIAN / ADMIN)`, `Technician`, `Admin`, `STATION ALLOCATION`, `1 Required`, `STN`, `01`, `STN`, `02`, `STN`, `03`, `STN`, `04`, `Send welcome magic link`, `Bypasses initial manual password reset`, `Cancel`, `Create Account`
- Actual: `ADMINISTRATION`, `Personnel Roster`, `Staff Directory & Access`, `18 Active Technicians`, `Add Staff Member`, `4 / 4`, `Operational Diagnostic Bays`, `99.4%`, `Inspection Protocol Accuracy`, `3 Admins`, `Master Security Privileges`, `MV`, `Marcus Vance`, `m.vance@techinspect.io`, `Bay 04 (Lead)`, `AL`, `Alicia Lindqvist`, `a.lindqvist@techinspect.io`, `Bay 01`, `RK`, `Rohan Kapoor`, `r.kapoor@techinspect.io`, `Bay 02`, `BAY ACTIVE`, `Shop Floor #04`, `Search VIN, tech, job ticket...`, `Marcus Vance`, `Lead Inspector`, `ONBOARDING`, `Create Staff Account`, `Set up permissions, station assignments, and onboarding
credentials.`, `FULL NAME`, `e.g. David Vance`, `EMAIL ADDRESS`, `e.g. d.vance@techinspect.io`, `TEMPORARY PASSWORD`, `InspectGuard99!`, `ASSIGN ROLE (TECHNICIAN / ADMIN)`, `Technician`, `Admin`, `STATION ALLOCATION`, `1 Required`, `STN`, `01`, `STN`, `02`, `STN`, `03`, `STN`, `04`, `Send welcome magic link`, `Bypasses initial manual password reset`, `Cancel`, `Create Account`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

