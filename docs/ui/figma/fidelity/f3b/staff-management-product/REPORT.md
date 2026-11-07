# Fidelity report — f3b-staff-level2

- **Sample id:** `f3b-staff-level2`
- **Batch:** `f3b-staff`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3b/staff-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/05_5._Workshop_Staff_Management/5._Workshop_Staff_Management@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2096}
- **Logical size:** 1280 × 1048 @ DPR 2
- **Compared pixels:** 2560 × 2096
- **Generated:** 2026-11-07T12:30:12.131Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.90857; min 64×64 tile 0.22075 |
| Text | fail | 4 missing |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.90857 |
| SSIM (worst 64×64 tile) | 0.22075 |
| RMSE (RGB 0–255) | 32.851 |
| MAE (RGB 0–255) | 8.553 |
| ΔE2000 mean | 2.69 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 9.641 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 21.76% |
| ΔE2000 > 5 | 6.13% |
| ΔE2000 > 10 | 4.52% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 1082 | 100 | 165.5 | 75.5 | 42807 |
| 2 | 815 | 28 | 127 | 56 | 25786 |
| 3 | 10.5 | 288 | 75.5 | 75.5 | 18926 |
| 4 | 16 | 104 | 82.5 | 53 | 14035 |
| 5 | 921.5 | 459 | 56 | 56 | 11369 |
| 6 | 164 | 468 | 56 | 56 | 11367 |
| 7 | 164 | 657 | 56 | 56 | 11367 |
| 8 | 921.5 | 657 | 56 | 56 | 11361 |
| 9 | 542.5 | 459 | 56 | 56 | 11360 |
| 10 | 542.5 | 657 | 56 | 56 | 11360 |
| 11 | 1208 | 24 | 32 | 32 | 2986 |
| 12 | 136 | 96 | 33 | 24 | 1775 |
| 13 | 422.5 | 456 | 32.5 | 32 | 1575 |
| 14 | 422.5 | 654 | 32.5 | 32 | 1574 |
| 15 | 801 | 654 | 32.5 | 32 | 1574 |
| 16 | 801 | 456 | 32.5 | 32 | 1573 |
| 17 | 1180 | 456 | 32 | 32 | 1569 |
| 18 | 268.5 | 102 | 23 | 32 | 1354 |
| 19 | 347.5 | 95.5 | 24.5 | 24.5 | 1351 |
| 20 | 1180 | 654 | 32 | 32 | 1314 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Workshop Staff`, `Search`, `Create`, `All (4)`, `Technicians (2)`, `Admins (2)`, `TA`, `Technician A`, `Technician · t***@test.local`, `TB`, `Technician B`, `Technician · tb***@test.local`, `AA`, `Admin A`, `Workshop Admin · a***@test.local`, `AB`, `Admin B`, `Workshop Admin · ab***@test.local`
- Actual: `Workshop Staff`, `Search`, `Search`, `Create`, `All (4)`, `Technicians (2)`, `Admins (2)`, `TA`, `Technician A`, `Technician`, `t***@test.local`, `TB`, `Technician B`, `Technician`, `tb***@test.local`, `AA`, `Admin A`, `Workshop Admin`, `a***@test.local`, `AB`, `Admin B`, `Workshop Admin`, `ab***@test.local`
- Missing: `Technician · t***@test.local`, `Technician · tb***@test.local`, `Workshop Admin · a***@test.local`, `Workshop Admin · ab***@test.local`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

