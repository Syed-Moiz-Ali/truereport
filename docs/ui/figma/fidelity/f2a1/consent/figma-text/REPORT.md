# Fidelity report — f2a1-consent-figma-text

- **Sample id:** `f2a1-consent-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/consent-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/05_5._Consent_&_Signatures/5._Consent_&_Signatures@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":1944}
- **Logical size:** 390 × 972 @ DPR 2
- **Compared pixels:** 780 × 1944
- **Generated:** 2026-11-07T21:12:37.482Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.9816; min 64×64 tile 0.81283 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.9816 |
| SSIM (worst 64×64 tile) | 0.81283 |
| RMSE (RGB 0–255) | 11.416 |
| MAE (RGB 0–255) | 2.691 |
| ΔE2000 mean | 0.778 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.716 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 4.21% |
| ΔE2000 > 5 | 2.06% |
| ΔE2000 > 10 | 1.36% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 226.5 | 630 | 86.5 | 27 | 672 |
| 2 | 170 | 629.5 | 50 | 25.5 | 450 |
| 3 | 76.5 | 608.5 | 36 | 48.5 | 280 |
| 4 | 77.5 | 611 | 34 | 46.5 | 246 |
| 5 | 125 | 637 | 39 | 17 | 220 |
| 6 | 51.5 | 336 | 17 | 15 | 206 |
| 7 | 276.5 | 429 | 10 | 9.5 | 202 |
| 8 | 56.5 | 241 | 10.5 | 10.5 | 183 |
| 9 | 125.5 | 634.5 | 40.5 | 17 | 175 |
| 10 | 274 | 333 | 7.5 | 9.5 | 165 |
| 11 | 20 | 115.5 | 19 | 19.5 | 139 |
| 12 | 112.5 | 612 | 10 | 39 | 139 |
| 13 | 53.5 | 342.5 | 13 | 5 | 138 |
| 14 | 113.5 | 610 | 10.5 | 39 | 137 |
| 15 | 276 | 350 | 7 | 10.5 | 128 |
| 16 | 147.5 | 120.5 | 5 | 14.5 | 120 |
| 17 | 68 | 25.5 | 12.5 | 13.5 | 116 |
| 18 | 64 | 115 | 5.5 | 20 | 116 |
| 19 | 138 | 25.5 | 12.5 | 13.5 | 113 |
| 20 | 38.5 | 120.5 | 7 | 12.5 | 98 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `STEP 4 OF 4 • FINAL SIGN-OFF`, `Authorizations`, `Review compliance permissions and provide
customer digital sign-off.`, `Allow PDF sharing`, `Send detailed diagnostic report via email`, `Customer road test consent`, `Authorize certified technician dynamic evaluation`, `Data storage authorization`, `Encrypt telemetry logs and secure fleet cloud backups`, `Digital Signature`, `Required`, `Sign with finger or stylus`, `Sign Above Line`, `Recorded`, `Timestamp: Today, 14:38 EST`, `Clear`, `AL`, `Alex Lindqvist`, `Authorized Representative • VIN 4782`, `Save Consent`, `Vehicle Walkaround Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

