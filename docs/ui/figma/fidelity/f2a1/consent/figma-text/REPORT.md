# Fidelity report — f2a1-consent-figma-text

- **Sample id:** `f2a1-consent-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/consent-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/05_5._Consent_&_Signatures/5._Consent_&_Signatures@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":1944}
- **Logical size:** 390 × 972 @ DPR 2
- **Compared pixels:** 780 × 1944
- **Generated:** 2026-11-06T04:36:06.768Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.92212; min 64×64 tile 0.35626 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.92212 |
| SSIM (worst 64×64 tile) | 0.35626 |
| RMSE (RGB 0–255) | 27.172 |
| MAE (RGB 0–255) | 6.081 |
| ΔE2000 mean | 1.922 |
| ΔE2000 median | 0.198 |
| ΔE2000 p95 | 3.486 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 7.07% |
| ΔE2000 > 5 | 4.29% |
| ΔE2000 > 10 | 3.34% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 77 | 606 | 236 | 56 | 4665 |
| 2 | 146.5 | 502 | 67.5 | 17.5 | 3123 |
| 3 | 140 | 512.5 | 67.5 | 17.5 | 2946 |
| 4 | 236.5 | 25.5 | 62.5 | 17.5 | 1873 |
| 5 | 174.5 | 149 | 66.5 | 14.5 | 1498 |
| 6 | 64 | 25 | 36 | 14.5 | 1164 |
| 7 | 162.5 | 25 | 41.5 | 14.5 | 1112 |
| 8 | 153.5 | 731.5 | 46.5 | 14 | 1043 |
| 9 | 128 | 25.5 | 30.5 | 13.5 | 988 |
| 10 | 110.5 | 149 | 40.5 | 11.5 | 885 |
| 11 | 207.5 | 25 | 28 | 14.5 | 879 |
| 12 | 20 | 731.5 | 40.5 | 14 | 862 |
| 13 | 56 | 152 | 43.5 | 8.5 | 856 |
| 14 | 107.5 | 169 | 32.5 | 14.5 | 845 |
| 15 | 60.5 | 734 | 32 | 14 | 708 |
| 16 | 299.5 | 29 | 24.5 | 10.5 | 677 |
| 17 | 285.5 | 149 | 27 | 14.5 | 672 |
| 18 | 20.5 | 149 | 26.5 | 11.5 | 630 |
| 19 | 21 | 172 | 32.5 | 8.5 | 625 |
| 20 | 52.5 | 169 | 28 | 11.5 | 604 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `STEP 4 OF 4 • FINAL SIGN-OFF`, `Authorizations`, `Choose each consent separately. Nothing is recorded until you save.`, `Allow PDF sharing`, `Send detailed diagnostic report via email`, `Customer road test consent`, `Authorize certified technician dynamic evaluation`, `Data storage authorization`, `Encrypt telemetry logs and secure fleet cloud backups`, `Digital Signature`, `Required`, `Sign with finger or stylus`, `Granted`, `Refused`, `Sign Above Line`, `Timestamp: Not recorded yet`, `Clear`, `AL`, `Alex Lindqvist`, `Authorized Representative • VIN 4782`, `Save Consent`, `Vehicle Walkaround Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

