# Fidelity report — f3b-create-staff-level2

- **Sample id:** `f3b-create-staff-level2`
- **Batch:** `f3b-create-staff`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3b/create-staff-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/07_6._Add_Staff_-_Create_Account/6._Add_Staff_-_Create_Account@2x.png`
- **Reference crop (px):** {"x":32,"y":84,"width":2560,"height":2048}
- **Logical size:** 1280 × 1024 @ DPR 2
- **Compared pixels:** 2560 × 2048
- **Generated:** 2026-11-07T12:30:20.830Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.83929; min 64×64 tile 0.19382 |
| Text | pass | 9 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.83929 |
| SSIM (worst 64×64 tile) | 0.19382 |
| RMSE (RGB 0–255) | 97.611 |
| MAE (RGB 0–255) | 82.404 |
| ΔE2000 mean | 21.546 |
| ΔE2000 median | 29.23 |
| ΔE2000 p95 | 29.453 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 80.08% |
| ΔE2000 > 5 | 72.25% |
| ΔE2000 > 10 | 71.62% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 0 | 1035.5 | 1024 | 3557624 |
| 2 | 943 | 927.5 | 305 | 77 | 85421 |
| 3 | 986.5 | 384 | 269.5 | 67 | 59283 |
| 4 | 1137 | 684 | 112 | 70 | 10883 |
| 5 | 945 | 124.5 | 53 | 25 | 3102 |
| 6 | 1176 | 775.5 | 48 | 29.5 | 3084 |
| 7 | 1222.5 | 0 | 57.5 | 57.5 | 2860 |
| 8 | 895 | 125 | 29.5 | 24.5 | 1722 |
| 9 | 879 | 55 | 53.5 | 11.5 | 1484 |
| 10 | 999 | 124.5 | 24.5 | 24.5 | 1315 |
| 11 | 925.5 | 124.5 | 19 | 25 | 1212 |
| 12 | 1028.5 | 125 | 23 | 24 | 1161 |
| 13 | 876.5 | 131 | 17.5 | 18.5 | 894 |
| 14 | 1089 | 131 | 19 | 18.5 | 861 |
| 15 | 1109 | 131.5 | 16.5 | 18 | 821 |
| 16 | 1128 | 131 | 16 | 18 | 790 |
| 17 | 1070 | 131 | 17.5 | 18.5 | 735 |
| 18 | 1051.5 | 131 | 17.5 | 18.5 | 728 |
| 19 | 1145 | 127.5 | 12 | 22 | 613 |
| 20 | 1207 | 373 | 17 | 13.5 | 517 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Create technician`, `Set the name, email and initial password. The technician signs in with these credentials.`, `Display name`, `Email`, `Temporary password`, `Technician`, `Role`, `Cancel`, `Create`
- Actual: `Open`, `Create technician`, `Set the name, email and initial password. The technician signs in with these credentials.`, `Display name`, `Display name`, `Email`, `Email`, `Temporary password`, `Temporary password`, `Technician`, `Role`, `Cancel`, `Create`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

