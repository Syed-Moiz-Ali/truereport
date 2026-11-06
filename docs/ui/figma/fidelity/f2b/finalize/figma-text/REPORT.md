# Fidelity report — f2b-finalize-figma-text

- **Sample id:** `f2b-finalize-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/finalize-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/14._Finalize_&_Approval_(Swipe)@2x.png`
- **Reference crop (px):** {"x":76,"y":14,"width":780,"height":2463}
- **Logical size:** 390 × 1232 @ DPR 2
- **Compared pixels:** 780 × 2464
- **Generated:** 2026-11-06T11:36:53.379Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.76102; min 64×64 tile 0.13242 |
| Text | pass | 10 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.76102 |
| SSIM (worst 64×64 tile) | 0.13242 |
| RMSE (RGB 0–255) | 58.102 |
| MAE (RGB 0–255) | 23.917 |
| ΔE2000 mean | 7.101 |
| ΔE2000 median | 0.201 |
| ΔE2000 p95 | 51.337 |
| ΔE2000 max | 99.111 |
| ΔE2000 > 2 (JND) | 33.94% |
| ΔE2000 > 5 | 18.96% |
| ΔE2000 > 10 | 16.13% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 44 | 274 | 302 | 168.5 | 158533 |
| 2 | 60.5 | 556 | 265 | 84.5 | 52411 |
| 3 | 56 | 446 | 40 | 68.5 | 8104 |
| 4 | 31.5 | 758 | 326 | 12.5 | 6986 |
| 5 | 272 | 243 | 74 | 22 | 6071 |
| 6 | 281 | 203 | 69 | 22 | 5646 |
| 7 | 60 | 671 | 35 | 40.5 | 4455 |
| 8 | 217 | 482 | 32 | 32.5 | 3301 |
| 9 | 161.5 | 25 | 81.5 | 14.5 | 2746 |
| 10 | 334 | 16 | 40 | 32 | 2186 |
| 11 | 21 | 105.5 | 30 | 28 | 1941 |
| 12 | 40 | 836 | 24 | 24.5 | 1853 |
| 13 | 40 | 904.5 | 24 | 24 | 1849 |
| 14 | 200.5 | 110.5 | 27.5 | 23 | 1710 |
| 15 | 15 | 1231 | 359.5 | 1 | 1400 |
| 16 | 86.5 | 111 | 23.5 | 22.5 | 1385 |
| 17 | 162 | 809 | 37.5 | 15 | 1290 |
| 18 | 51 | 111 | 20 | 22.5 | 1106 |
| 19 | 115.5 | 105 | 17.5 | 28.5 | 999 |
| 20 | 58 | 245 | 20 | 18.5 | 948 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `summary` | 20, 170, 350, 516 | 20, 170, 350, 516 | 0 | pass |
| `slide` | 20, 1148, 350, 64 | 20, 1148, 350, 64 | 0 | pass |

## Text

- Expected: `REVIEW & FINALIZE`, `Review & Finalize`, `2024 Ford Transit 350`, `VIN • 1FTBR1Y85RKB92104`, `LV71 XZP`, `JOB-5A0001`, `Odometer: 34180 MI`, `Slide to Finalize Inspection`, `Diagnostic Checklist`, `David Vance`
- Actual: `REVIEW & FINALIZE`, `Review & Finalize`, `Finalized findings cannot be edited by anyone.`, `2024 Ford Transit 350`, `VIN • 1FTBR1Y85RKB92104`, `LV71 XZP`, `3`, `completed`, `0`, `Major`, `DV`, `David Vance`, `JOB-5A0001`, `Odometer: 34180 MI`, `Missing items`, `0 attention`, `No results`, `Finalized findings cannot be edited by anyone.`, `Diagnostic Checklist`, `Slide to Finalize Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

