# Fidelity report — f2a1-login-product-copy

- **Sample id:** `f2a1-login-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/login-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/01_1._Login_&_Language_Selection/1._Login_&_Language_Selection@2x.png`
- **Reference crop (px):** {"x":0,"y":0,"width":780,"height":1716}
- **Logical size:** 390 × 858 @ DPR 2
- **Compared pixels:** 780 × 1716
- **Generated:** 2026-11-07T14:19:09.971Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.95.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.96292; min 64×64 tile 0.38311 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.96292 |
| SSIM (worst 64×64 tile) | 0.38311 |
| RMSE (RGB 0–255) | 18.195 |
| MAE (RGB 0–255) | 2.285 |
| ΔE2000 mean | 0.742 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.939 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 2.56% |
| ΔE2000 > 5 | 1.77% |
| ΔE2000 > 10 | 1.52% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 179 | 199.5 | 56 | 25 | 1908 |
| 2 | 231.5 | 201.5 | 38 | 18 | 1323 |
| 3 | 120 | 199.5 | 32.5 | 20 | 1171 |
| 4 | 238.5 | 232 | 35 | 13 | 684 |
| 5 | 159 | 628.5 | 34 | 9 | 630 |
| 6 | 267.5 | 597 | 26.5 | 11.5 | 629 |
| 7 | 163.5 | 199 | 15 | 20.5 | 541 |
| 8 | 191.5 | 628.5 | 27.5 | 9 | 516 |
| 9 | 325 | 19 | 29 | 12 | 504 |
| 10 | 244 | 597 | 22 | 11.5 | 502 |
| 11 | 128 | 628.5 | 26 | 9 | 502 |
| 12 | 135.5 | 232 | 26.5 | 10.5 | 462 |
| 13 | 185.5 | 596.5 | 21.5 | 12.5 | 450 |
| 14 | 204.5 | 232 | 17.5 | 10.5 | 395 |
| 15 | 109 | 628.5 | 18 | 9 | 378 |
| 16 | 219.5 | 628.5 | 15.5 | 10.5 | 373 |
| 17 | 277.5 | 233.5 | 20 | 9 | 372 |
| 18 | 72.5 | 232 | 17 | 10.5 | 346 |
| 19 | 275.5 | 628.5 | 15.5 | 10.5 | 330 |
| 20 | 171 | 234.5 | 16.5 | 10 | 328 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `English`, `العربية`, `TrueReport`, `Vehicle inspection reports for partner workshops.`, `Email`, `Password`, `Password help`, `Sign in`, `Need technician login?`, `Get help`, `Authorised workshop staff only`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

