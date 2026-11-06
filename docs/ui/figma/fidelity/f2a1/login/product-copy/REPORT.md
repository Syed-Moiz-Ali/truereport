# Fidelity report — f2a1-login-product-copy

- **Sample id:** `f2a1-login-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/login-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/01_1._Login_&_Language_Selection/1._Login_&_Language_Selection@2x.png`
- **Reference crop (px):** {"x":0,"y":0,"width":780,"height":1716}
- **Logical size:** 390 × 858 @ DPR 2
- **Compared pixels:** 780 × 1716
- **Generated:** 2026-11-06T04:35:47.234Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.96039; min 64×64 tile 0.38311 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.96039 |
| SSIM (worst 64×64 tile) | 0.38311 |
| RMSE (RGB 0–255) | 18.824 |
| MAE (RGB 0–255) | 2.942 |
| ΔE2000 mean | 1.135 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 4.467 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 7.65% |
| ΔE2000 > 5 | 4.67% |
| ΔE2000 > 10 | 2.9% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 14.5 | 473.5 | 361 | 77.5 | 34307 |
| 2 | 44.5 | 469 | 301 | 3.5 | 3400 |
| 3 | 179 | 199.5 | 56 | 25 | 1908 |
| 4 | 231.5 | 201.5 | 38 | 18 | 1323 |
| 5 | 120 | 199.5 | 32.5 | 20 | 1171 |
| 6 | 244 | 597 | 43.5 | 11.5 | 936 |
| 7 | 91.5 | 369 | 45.5 | 11.5 | 891 |
| 8 | 238.5 | 232 | 35 | 13 | 684 |
| 9 | 319.5 | 368 | 26.5 | 12 | 677 |
| 10 | 159 | 628.5 | 34 | 9 | 630 |
| 11 | 163.5 | 199 | 15 | 20.5 | 541 |
| 12 | 191.5 | 628.5 | 27.5 | 9 | 516 |
| 13 | 40 | 365 | 14.5 | 18 | 509 |
| 14 | 128 | 628.5 | 26 | 9 | 502 |
| 15 | 135.5 | 232 | 26.5 | 10.5 | 462 |
| 16 | 204.5 | 232 | 17.5 | 10.5 | 395 |
| 17 | 69.5 | 305 | 17.5 | 11 | 387 |
| 18 | 66.5 | 369 | 15 | 11.5 | 384 |
| 19 | 109 | 628.5 | 18 | 9 | 378 |
| 20 | 219.5 | 628.5 | 15.5 | 10.5 | 373 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `English`, `عربي`, `TrueReport`, `Vehicle inspection reports for partner workshops.`, `Email`, `Password`, `Password help`, `Sign in`, `Need technician access?`, `Contact Admin`, `Authorised workshop staff only`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

