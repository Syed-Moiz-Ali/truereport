# Fidelity report — f2a1-consent-product-copy

- **Sample id:** `f2a1-consent-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/consent-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/05_5._Consent_&_Signatures/5._Consent_&_Signatures@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":1944}
- **Logical size:** 390 × 972 @ DPR 2
- **Compared pixels:** 780 × 1944
- **Generated:** 2026-11-06T04:36:09.722Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.86533; min 64×64 tile 0.35688 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.86533 |
| SSIM (worst 64×64 tile) | 0.35688 |
| RMSE (RGB 0–255) | 39.3 |
| MAE (RGB 0–255) | 10.315 |
| ΔE2000 mean | 3.293 |
| ΔE2000 median | 0.198 |
| ΔE2000 p95 | 20.355 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 9.45% |
| ΔE2000 > 5 | 6.86% |
| ΔE2000 > 10 | 5.82% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 298 | 232 | 52 | 32 | 5723 |
| 2 | 298 | 328 | 52 | 32 | 5723 |
| 3 | 77 | 606 | 236 | 56 | 4682 |
| 4 | 146.5 | 502 | 67.5 | 17.5 | 3123 |
| 5 | 140 | 512.5 | 67.5 | 17.5 | 2946 |
| 6 | 20 | 115 | 54.5 | 20.5 | 1867 |
| 7 | 64.5 | 25 | 53.5 | 14.5 | 1585 |
| 8 | 174.5 | 149 | 66.5 | 14.5 | 1498 |
| 9 | 70.5 | 120.5 | 38 | 15 | 1482 |
| 10 | 151 | 233.5 | 46.5 | 13 | 1313 |
| 11 | 124.5 | 793.5 | 46 | 16 | 1136 |
| 12 | 153.5 | 731.5 | 46.5 | 14 | 1043 |
| 13 | 190.5 | 350 | 56 | 10.5 | 1023 |
| 14 | 108 | 120.5 | 28 | 15 | 995 |
| 15 | 119 | 25.5 | 31.5 | 14 | 930 |
| 16 | 95 | 329.5 | 35 | 13 | 909 |
| 17 | 110.5 | 149 | 40.5 | 11.5 | 885 |
| 18 | 200.5 | 237 | 35 | 12.5 | 872 |
| 19 | 179 | 329.5 | 31.5 | 13 | 872 |
| 20 | 20 | 731.5 | 40.5 | 14 | 862 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `CONSENT • FINAL STEP`, `Consent`, `Choose each consent separately. Nothing is recorded until you save.`, `Public-link consent`, `Record the customer answer for sharing the public report link.`, `Processing consent`, `Record the customer answer for processing inspection data.`, `Data storage`, `Not available in this version`, `Consent decision`, `Required`, `Choose Granted or Refused`, `Granted`, `Refused`, `No signature captured`, `Timestamp: Not recorded yet`, `Clear`, `—`, `Authorized representative`, `Not recorded yet`, `Save consent`, `Consent`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

