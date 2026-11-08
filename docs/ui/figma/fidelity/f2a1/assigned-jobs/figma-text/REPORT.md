# Fidelity report — f2a1-assigned-jobs-figma-text

- **Sample id:** `f2a1-assigned-jobs-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/assigned-jobs-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/2._Assigned_Jobs_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2004}
- **Logical size:** 390 × 1002 @ DPR 2
- **Compared pixels:** 780 × 2004
- **Generated:** 2026-11-07T20:12:34.473Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98497; min 64×64 tile 0.78312 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98497 |
| SSIM (worst 64×64 tile) | 0.78312 |
| RMSE (RGB 0–255) | 9.391 |
| MAE (RGB 0–255) | 1.81 |
| ΔE2000 mean | 0.555 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.61 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 3.39% |
| ΔE2000 > 5 | 1.66% |
| ΔE2000 > 10 | 1.2% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 94 | 185.5 | 18.5 | 19.5 | 174 |
| 2 | 223 | 959.5 | 6.5 | 9.5 | 162 |
| 3 | 52.5 | 190.5 | 15 | 14.5 | 152 |
| 4 | 156 | 961 | 6.5 | 8 | 132 |
| 5 | 139.5 | 958.5 | 5.5 | 10.5 | 128 |
| 6 | 149 | 961 | 6.5 | 8 | 126 |
| 7 | 229 | 271.5 | 16.5 | 16.5 | 121 |
| 8 | 57.5 | 420.5 | 17 | 6.5 | 121 |
| 9 | 57.5 | 566.5 | 17 | 6.5 | 121 |
| 10 | 57.5 | 712.5 | 17 | 6.5 | 121 |
| 11 | 68 | 190.5 | 5 | 14.5 | 120 |
| 12 | 132 | 854.5 | 8 | 8 | 110 |
| 13 | 244 | 962 | 6 | 7 | 108 |
| 14 | 331.5 | 963 | 7 | 6.5 | 107 |
| 15 | 36.5 | 93 | 12 | 14 | 97 |
| 16 | 322 | 960.5 | 6 | 8.5 | 97 |
| 17 | 48 | 93 | 12.5 | 14 | 92 |
| 18 | 21 | 185.5 | 8 | 19.5 | 92 |
| 19 | 79 | 185 | 10.5 | 20 | 90 |
| 20 | 126.5 | 350.5 | 10 | 10.5 | 86 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `DV`, `SHIFT 1 • BAY A`, `Welcome back,`, `David Vance`, `3 Tasks`, `Pending check`, `45 min`, `Avg. turnover`, `ASSIGNED TODAY`, `3 In Queue`, `Renault Megan 3`, `ABC 123 • Bay 4`, `Full Pre-Delivery Inspection`, `Ready`, `Renault Megan 3`, `XYZ 882 • Bay 2`, `Brake Fluid & Tire Diagnostics`, `High Priority`, `Renault Megan 3`, `KLO 904 • Bay 6`, `Routine 60-Point Audit`, `Scheduled`, `Scan New VIN Tag`, `Inspection Queue`, `LIVE
SYNC`, `Intake`, `Fleet`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

