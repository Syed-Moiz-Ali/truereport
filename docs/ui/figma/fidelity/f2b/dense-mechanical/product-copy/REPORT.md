# Fidelity report — f2b-dense-mechanical-product-copy

- **Sample id:** `f2b-dense-mechanical-product-copy`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/dense-mechanical-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/11_11._Dense_Mechanical_List/11._Dense_Mechanical_List@2x.png`
- **Reference crop (px):** {"x":40,"y":14,"width":780,"height":2160}
- **Logical size:** 390 × 1080 @ DPR 2
- **Compared pixels:** 780 × 2160
- **Generated:** 2026-11-08T08:26:43.118Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.83304; min 64×64 tile 0.16527 |
| Text | pass | 7 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.83304 |
| SSIM (worst 64×64 tile) | 0.16527 |
| RMSE (RGB 0–255) | 48.607 |
| MAE (RGB 0–255) | 15.858 |
| ΔE2000 mean | 4.985 |
| ΔE2000 median | 0.202 |
| ΔE2000 p95 | 33.776 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 27.15% |
| ΔE2000 > 5 | 11.23% |
| ΔE2000 > 10 | 10.01% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 34.5 | 486.5 | 260.5 | 74.5 | 63304 |
| 2 | 287.5 | 268 | 62.5 | 47 | 8112 |
| 3 | 314 | 890 | 36 | 62 | 6825 |
| 4 | 314 | 592 | 36 | 46.5 | 4324 |
| 5 | 314 | 484 | 36 | 37.5 | 4227 |
| 6 | 314 | 376 | 36 | 36 | 4101 |
| 7 | 314 | 700 | 36 | 36 | 4073 |
| 8 | 314 | 808 | 36 | 36 | 4071 |
| 9 | 181 | 159 | 50 | 17 | 1738 |
| 10 | 102 | 915 | 47.5 | 17 | 1717 |
| 11 | 103 | 159.5 | 46 | 17.5 | 1708 |
| 12 | 103 | 614 | 47.5 | 15.5 | 1641 |
| 13 | 54.5 | 277 | 19 | 36.5 | 1475 |
| 14 | 143 | 1027.5 | 53 | 11 | 1243 |
| 15 | 102.5 | 270.5 | 26 | 23 | 1230 |
| 16 | 102 | 810 | 37 | 14 | 1229 |
| 17 | 81.5 | 25.5 | 39.5 | 17.5 | 1137 |
| 18 | 55.5 | 169.5 | 17 | 23 | 988 |
| 19 | 323.5 | 169.5 | 17 | 23 | 988 |
| 20 | 314 | 181.5 | 36 | 20.5 | 896 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `card` | 20, 132, 350, 88 | 20, 134, 350, 88 | 2 | pass |
| `cta` | 20, 1004, 350, 56 | 20, 1004, 350, 56 | 0 | pass |

## Text

- Expected: `EXTERIOR`, `17 checks done / 40`, `JOB-2601`, `Exterior check 1`, `Inspect the item.`, `Checklist`, `Review and finalize`
- Actual: `EXTERIOR`, `17 checks done / 40`, `JOB-2601`, `Exterior check 1`, `Inspect the item.`, `Exterior check 2`, `Inspect the item.`, `Exterior check 3`, `Inspect the item.`, `Exterior check 4`, `Inspect the item.`, `Exterior check 5`, `Inspect the item.`, `Exterior check 6`, `Inspect the item.`, `Exterior check 7`, `Inspect the item.`, `Exterior check 8`, `Inspect the item.`, `Exterior check 9`, `Inspect the item.`, `Checklist`, `Review and finalize`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

