# Fidelity report — F2-A 01-login - real product copy

- **Sample id:** `01-login-product-copy`
- **Batch:** `f2a-technician-screens-1-7`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a/01-login-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/01_1._Login_&_Language_Selection/1._Login_&_Language_Selection@2x.png`
- **Reference crop (px):** {"x":0,"y":0,"width":780,"height":1716}
- **Logical size:** 390 × 858 @ DPR 2
- **Compared pixels:** 780 × 1716
- **Generated:** 2026-11-05T14:57:49.724Z
- **Owner:** fidelity-auditor

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.88604; min 64×64 tile 0.283 |
| Text | pass | 6 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.88604 |
| SSIM (worst 64×64 tile) | 0.283 |
| RMSE (RGB 0–255) | 47.899 |
| MAE (RGB 0–255) | 14.825 |
| ΔE2000 mean | 4.359 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.722 |
| ΔE2000 > 2 (JND) | 25.54% |
| ΔE2000 > 5 | 13.51% |
| ΔE2000 > 10 | 12.48% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 20 | 448 | 350 | 81.5 | 109335 |
| 2 | 156.5 | 97.5 | 77 | 91 | 20439 |
| 3 | 211 | 19.5 | 91.5 | 54.5 | 15909 |
| 4 | 119.5 | 198 | 43 | 21.5 | 1985 |
| 5 | 244.5 | 198 | 28 | 21.5 | 1244 |
| 6 | 179 | 198 | 19.5 | 21 | 1008 |
| 7 | 36 | 365 | 17.5 | 29 | 920 |
| 8 | 213 | 200 | 15.5 | 24.5 | 882 |
| 9 | 161 | 199 | 17 | 20 | 842 |
| 10 | 229 | 200 | 16 | 19.5 | 814 |
| 11 | 244 | 165.5 | 19 | 17.5 | 721 |
| 12 | 329.5 | 368 | 27.5 | 23 | 713 |
| 13 | 34 | 282 | 20 | 16 | 674 |
| 14 | 198 | 197 | 14.5 | 22.5 | 661 |
| 15 | 227.5 | 168.5 | 15.5 | 15 | 576 |
| 16 | 149.5 | 169 | 13.5 | 14.5 | 541 |
| 17 | 40 | 303 | 17 | 14 | 519 |
| 18 | 127 | 163.5 | 14 | 19.5 | 484 |
| 19 | 333.5 | 43.5 | 18 | 14 | 383 |
| 20 | 140 | 169 | 9 | 14 | 319 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `TrueReport`, `Vehicle inspection reports for partner workshops.`, `Email`, `Password`, `Sign in`, `Your workshop account is created by a Platform Admin.`
- Actual: `English`, `العربية`, `TR`, `TrueReport`, `Vehicle inspection reports for partner workshops.`, `Email`, `Password`, `Sign in`, `Your workshop account is created by a Platform Admin.`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Real product copy and neutral test data. Removed: Forgot password, Request ID, ISO 27001 claim, TechInspect brand/logo asset, 202 px bottom pad. Replaced brand with TrueReport + drawn TR monogram; tagline is factual. Fields use P2 visible label above + F1 focus ring and 56 px target (Figma 48). Primary CTA uses P1 #059669 fill + 19 px bold white label (Figma 14 px white on #10B981). Language control is 48 px target (Figma 24). Copy/height differences are residuals, not geometry regressions.

