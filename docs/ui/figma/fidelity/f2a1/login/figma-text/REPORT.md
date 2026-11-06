# Fidelity report — f2a1-login-figma-text

- **Sample id:** `f2a1-login-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/login-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/01_1._Login_&_Language_Selection/1._Login_&_Language_Selection@2x.png`
- **Reference crop (px):** {"x":0,"y":0,"width":780,"height":1716}
- **Logical size:** 390 × 858 @ DPR 2
- **Compared pixels:** 780 × 1716
- **Generated:** 2026-11-06T04:35:45.186Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.97721; min 64×64 tile 0.56743 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.97721 |
| SSIM (worst 64×64 tile) | 0.56743 |
| RMSE (RGB 0–255) | 11.878 |
| MAE (RGB 0–255) | 1.842 |
| ΔE2000 mean | 0.769 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 3.77 |
| ΔE2000 max | 83.864 |
| ΔE2000 > 2 (JND) | 7.09% |
| ΔE2000 > 5 | 4.08% |
| ΔE2000 > 10 | 2.3% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 14.5 | 473.5 | 361 | 77.5 | 34307 |
| 2 | 44.5 | 469 | 301 | 3.5 | 3400 |
| 3 | 91.5 | 369 | 45.5 | 11.5 | 891 |
| 4 | 319.5 | 368 | 26.5 | 12 | 677 |
| 5 | 159 | 628.5 | 34 | 9 | 630 |
| 6 | 191.5 | 628.5 | 27.5 | 9 | 516 |
| 7 | 40 | 365 | 14.5 | 18 | 509 |
| 8 | 128 | 628.5 | 26 | 9 | 502 |
| 9 | 69.5 | 305 | 17.5 | 11 | 387 |
| 10 | 66.5 | 369 | 15 | 11.5 | 384 |
| 11 | 109 | 628.5 | 18 | 9 | 378 |
| 12 | 219.5 | 628.5 | 15.5 | 10.5 | 373 |
| 13 | 275.5 | 628.5 | 15.5 | 10.5 | 330 |
| 14 | 248.5 | 628.5 | 16 | 9 | 325 |
| 15 | 88.5 | 308 | 13 | 8.5 | 273 |
| 16 | 265.5 | 631 | 10 | 6.5 | 161 |
| 17 | 259.5 | 201.5 | 10 | 18 | 155 |
| 18 | 281.5 | 423 | 6 | 8.5 | 136 |
| 19 | 281.5 | 413 | 6 | 8 | 133 |
| 20 | 330 | 413 | 9.5 | 6 | 128 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `English`, `عربي`, `TechInspect`, `Vehicle Condition & Fleet Diagnostics`, `Email`, `Password`, `Forgot password?`, `Sign In`, `Need technician access?`, `Request ID`, `Authorised workshop staff only`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

