# Fidelity report — F2-A 05-consent - real product copy

- **Sample id:** `05-consent-product-copy`
- **Batch:** `f2a-technician-screens-1-7`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a/05-consent-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/05_5._Consent_&_Signatures/5._Consent_&_Signatures@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":1944}
- **Logical size:** 390 × 972 @ DPR 2
- **Compared pixels:** 780 × 1944
- **Generated:** 2026-11-05T14:58:11.054Z
- **Owner:** fidelity-auditor

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.79604; min 64×64 tile 0.27474 |
| Text | pass | 9 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.79604 |
| SSIM (worst 64×64 tile) | 0.27474 |
| RMSE (RGB 0–255) | 57.377 |
| MAE (RGB 0–255) | 21.924 |
| ΔE2000 mean | 6.45 |
| ΔE2000 median | 0.796 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 41.76% |
| ΔE2000 > 5 | 18.54% |
| ΔE2000 > 10 | 13.52% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 11.5 | 875.5 | 366 | 76.5 | 103070 |
| 2 | 20 | 494 | 350 | 54 | 65048 |
| 3 | 36 | 788 | 40 | 40 | 5057 |
| 4 | 298 | 232 | 52 | 50 | 4587 |
| 5 | 77 | 609 | 236 | 48.5 | 4483 |
| 6 | 298 | 328 | 52 | 32 | 4121 |
| 7 | 342 | 16 | 32 | 32 | 2986 |
| 8 | 68 | 25 | 61 | 22.5 | 2673 |
| 9 | 20 | 65 | 30.5 | 35 | 2112 |
| 10 | 172 | 151 | 62 | 11 | 1775 |
| 11 | 85 | 169 | 55 | 15 | 1578 |
| 12 | 20.5 | 22 | 34.5 | 25.5 | 1385 |
| 13 | 52 | 677 | 286 | 1 | 1144 |
| 14 | 110.5 | 149 | 38.5 | 13 | 1132 |
| 15 | 110 | 120.5 | 26 | 15 | 1124 |
| 16 | 234 | 441 | 33.5 | 15.5 | 989 |
| 17 | 210 | 441.5 | 23.5 | 17.5 | 818 |
| 18 | 20 | 115.5 | 19 | 19.5 | 788 |
| 19 | 47.5 | 152 | 20 | 15.5 | 712 |
| 20 | 48.5 | 433.5 | 21.5 | 18.5 | 687 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Consent`, `Choose each consent separately. Nothing is recorded until you save.`, `Processing consent`, `Public-link consent`, `Status`, `Not recorded yet`, `Granted`, `Refused`, `Save consent`
- Actual: `Consent`, `Choose each consent separately. Nothing is recorded until you save.`, `Processing consent`, `Record the customer answer for processing inspection data.`, `Public-link consent`, `Record the customer answer for sharing the public report link.`, `Status`, `Not recorded yet`, `Granted`, `Refused`, `Save consent`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Real product copy and neutral test data. Removed signature pad, prefilled signature, Recorded badge, EST timestamp, PDF/road-test/data-storage consents (not in the model). Kept PROCESSING and PUBLIC_LINK only; both start unselected and no record exists until Save. Consent types are explicit selectable cards plus Granted/Refused choices (three states) rather than the Figma switches. Third consent card and signature block are the largest residuals.

