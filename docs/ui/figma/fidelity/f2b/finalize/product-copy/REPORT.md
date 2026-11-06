# Fidelity report — f2b-finalize-product-copy

- **Sample id:** `f2b-finalize-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/finalize-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/14._Finalize_&_Approval_(Swipe)@2x.png`
- **Reference crop (px):** {"x":76,"y":14,"width":780,"height":2463}
- **Logical size:** 390 × 1232 @ DPR 2
- **Compared pixels:** 780 × 2464
- **Generated:** 2026-11-06T11:35:28.171Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.74529; min 64×64 tile 0.13185 |
| Text | pass | 9 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.74529 |
| SSIM (worst 64×64 tile) | 0.13185 |
| RMSE (RGB 0–255) | 59.294 |
| MAE (RGB 0–255) | 24.732 |
| ΔE2000 mean | 7.385 |
| ΔE2000 median | 0.222 |
| ΔE2000 p95 | 51.337 |
| ΔE2000 max | 99.111 |
| ΔE2000 > 2 (JND) | 34.51% |
| ΔE2000 > 5 | 19.54% |
| ΔE2000 > 10 | 16.76% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 44 | 274 | 302 | 168.5 | 158527 |
| 2 | 60.5 | 556 | 265 | 84.5 | 52411 |
| 3 | 56 | 446 | 40 | 68.5 | 8104 |
| 4 | 272 | 243 | 74 | 22 | 6071 |
| 5 | 286 | 203 | 64 | 22 | 5215 |
| 6 | 135.5 | 758.5 | 222 | 13.5 | 4922 |
| 7 | 60 | 671 | 35 | 40.5 | 4455 |
| 8 | 31.5 | 758 | 104 | 24 | 3787 |
| 9 | 217 | 482 | 32 | 32.5 | 3301 |
| 10 | 114 | 105.5 | 45 | 28 | 2380 |
| 11 | 40 | 806 | 32 | 26 | 2339 |
| 12 | 196 | 105.5 | 38 | 28 | 2267 |
| 13 | 334 | 16 | 40 | 32 | 2186 |
| 14 | 160.5 | 105 | 34 | 28.5 | 2052 |
| 15 | 21 | 105.5 | 30 | 28 | 1941 |
| 16 | 40 | 896.5 | 24 | 32 | 1936 |
| 17 | 40 | 836 | 24 | 24.5 | 1853 |
| 18 | 15 | 1231 | 359.5 | 1 | 1400 |
| 19 | 86.5 | 111 | 23.5 | 22.5 | 1385 |
| 20 | 73 | 806 | 36.5 | 16 | 1261 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `summary` | 20, 170, 350, 516 | 20, 170, 350, 516 | 0 | pass |
| `slide` | 20, 1148, 350, 64 | 20, 1148, 350, 64 | 0 | pass |

## Text

- Expected: `REVIEW AND FINALIZE`, `Review and finalize`, `2022 Honda Accord`, `VIN • 1HGCM82633A004352`, `A 12345`, `JOB-2601`, `Odometer: 48210 KM`, `Finalize`, `Checklist`
- Actual: `REVIEW AND FINALIZE`, `Review and finalize`, `Finalized findings cannot be edited by anyone.`, `2022 Honda Accord`, `VIN • 1HGCM82633A004352`, `A 12345`, `17`, `completed`, `2`, `Defect found`, `DV`, `David Vance`, `JOB-2601`, `Odometer: 48210 KM`, `Missing items`, `2 attention`, `Interior check 6`, `Attention recommended`, `Interior check 7`, `Attention recommended`, `Finalized findings cannot be edited by anyone.`, `Checklist`, `Finalize`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

