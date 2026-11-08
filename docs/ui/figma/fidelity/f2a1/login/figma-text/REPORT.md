# Fidelity report — f2a1-login-figma-text

- **Sample id:** `f2a1-login-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/login-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/01_1._Login_&_Language_Selection/1._Login_&_Language_Selection@2x.png`
- **Reference crop (px):** {"x":0,"y":0,"width":780,"height":1716}
- **Logical size:** 390 × 858 @ DPR 2
- **Compared pixels:** 780 × 1716
- **Generated:** 2026-11-07T14:19:02.839Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98578; min 64×64 tile 0.56743 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98578 |
| SSIM (worst 64×64 tile) | 0.56743 |
| RMSE (RGB 0–255) | 9.004 |
| MAE (RGB 0–255) | 0.926 |
| ΔE2000 mean | 0.307 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.824 |
| ΔE2000 max | 83.864 |
| ΔE2000 > 2 (JND) | 1.82% |
| ΔE2000 > 5 | 1% |
| ΔE2000 > 10 | 0.74% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 219.5 | 628.5 | 16.5 | 9 | 309 |
| 2 | 329.5 | 370 | 16.5 | 10 | 210 |
| 3 | 287 | 629.5 | 12 | 10 | 201 |
| 4 | 40 | 303 | 17 | 14 | 168 |
| 5 | 259.5 | 201.5 | 10 | 18 | 155 |
| 6 | 202 | 631 | 10.5 | 6.5 | 151 |
| 7 | 258.5 | 631 | 11 | 6.5 | 151 |
| 8 | 269.5 | 631 | 9.5 | 6.5 | 142 |
| 9 | 279.5 | 631 | 7 | 6 | 138 |
| 10 | 251 | 628.5 | 7 | 9 | 137 |
| 11 | 281.5 | 423 | 6 | 8.5 | 136 |
| 12 | 281.5 | 413 | 6 | 8 | 133 |
| 13 | 330 | 413 | 9.5 | 6 | 128 |
| 14 | 304 | 423 | 6.5 | 8.5 | 124 |
| 15 | 352 | 420.5 | 6.5 | 9 | 122 |
| 16 | 330 | 423 | 9.5 | 6 | 122 |
| 17 | 120 | 199.5 | 14.5 | 19.5 | 121 |
| 18 | 352 | 411 | 6.5 | 8 | 118 |
| 19 | 304 | 413 | 6.5 | 8 | 118 |
| 20 | 41.5 | 372.5 | 10.5 | 9 | 106 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `English`, `عربي`, `TechInspect`, `Vehicle Condition & Fleet Diagnostics`, `Email`, `Password`, `Forgot password?`, `Sign In`, `Need technician access?`, `Request ID`, `ISO 27001 Certified Fleet Security`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

