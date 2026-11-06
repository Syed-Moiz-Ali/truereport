# Fidelity report — f2b3-final-review-level1

- **Sample id:** `f2b3-final-review-level1`
- **Batch:** `f2b3-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b3/final-review-level1.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/12_13._Final_Review_(Missing_Items)/13._Final_Review_(Missing_Items)@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2016}
- **Logical size:** 390 × 1008 @ DPR 2
- **Compared pixels:** 780 × 2016
- **Generated:** 2026-11-06T13:23:55.587Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98209; min 64×64 tile 0.81097 |
| Text | pass | 26 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98209 |
| SSIM (worst 64×64 tile) | 0.81097 |
| RMSE (RGB 0–255) | 10.991 |
| MAE (RGB 0–255) | 3.149 |
| ΔE2000 mean | 0.834 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 2.291 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 11.44% |
| ΔE2000 > 5 | 2.3% |
| ΔE2000 > 10 | 1.45% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 122.5 | 762 | 14 | 7.5 | 201 |
| 2 | 125 | 321.5 | 6 | 11.5 | 200 |
| 3 | 141 | 321.5 | 6 | 11.5 | 180 |
| 4 | 115 | 109.5 | 14 | 19.5 | 177 |
| 5 | 59.5 | 114.5 | 11.5 | 14.5 | 172 |
| 6 | 308.5 | 453 | 17 | 15.5 | 161 |
| 7 | 171.5 | 760 | 7.5 | 9 | 155 |
| 8 | 86.5 | 114.5 | 19.5 | 14.5 | 151 |
| 9 | 179.5 | 548 | 5.5 | 11.5 | 132 |
| 10 | 167 | 114.5 | 5 | 14.5 | 120 |
| 11 | 310 | 554.5 | 16.5 | 15 | 104 |
| 12 | 186 | 550 | 4 | 9.5 | 98 |
| 13 | 192.5 | 114.5 | 10.5 | 17.5 | 95 |
| 14 | 108.5 | 79 | 8.5 | 9 | 94 |
| 15 | 21 | 109.5 | 8.5 | 19.5 | 93 |
| 16 | 192 | 762 | 5.5 | 7 | 92 |
| 17 | 155 | 109 | 10.5 | 20 | 90 |
| 18 | 141 | 760 | 8.5 | 9 | 88 |
| 19 | 109.5 | 321.5 | 4 | 11.5 | 83 |
| 20 | 149.5 | 762 | 5.5 | 7.5 | 78 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `f2b3-header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `f2b3-banner` | 20, 202, 350, 160 | 20, 202, 350, 160 | 0 | pass |
| `f2b3-continue` | 20, 864, 350, 56 | 20, 864, 350, 56 | 0 | pass |

## Text

- Expected: `STEP 4 OF 4 • VALIDATION`, `3 Action Items`, `Review Findings`, `Resolve outstanding compliance requirements
before submitting the digital work order.`, `3 Mandatory Photos Missing`, `Customer sign-off & quality assurance
mandate verified optical documentation
for critical fluid and wear sections.`, `1`, `2`, `3`, `Tap any item below to capture
instantly`, `MANDATORY RESOLUTION ITEMS`, `Brake Fluid`, `Chassis`, `Reservoir moisture gauge & test strip`, `Tread Photo`, `Front Left`, `3/32" depth indicator macro verification`, `Signature`, `Required`, `Digital advisor & vehicle owner sign-off`, `28 Verified Data Points`, `Powertrain, OBD-II & exterior
scans passed`, `91%
Complete`, `Resolve to Continue`, `All 3 critical checklist items must be resolved to unlock
client sign-off.`, `Diagnostic Checklist`
- Actual: `STEP 4 OF 4 • VALIDATION`, `3 Action Items`, `Review Findings`, `Resolve outstanding compliance requirements
before submitting the digital work order.`, `3 Mandatory Photos Missing`, `Customer sign-off & quality assurance
mandate verified optical documentation
for critical fluid and wear sections.`, `1`, `2`, `3`, `Tap any item below to capture
instantly`, `MANDATORY RESOLUTION ITEMS`, `Brake Fluid`, `Chassis`, `Reservoir moisture gauge & test strip`, `Tread Photo`, `Front Left`, `3/32" depth indicator macro verification`, `Signature`, `Required`, `Digital advisor & vehicle owner sign-off`, `28 Verified Data Points`, `Powertrain, OBD-II & exterior
scans passed`, `91%
Complete`, `Resolve to Continue`, `All 3 critical checklist items must be resolved to unlock
client sign-off.`, `Diagnostic Checklist`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

