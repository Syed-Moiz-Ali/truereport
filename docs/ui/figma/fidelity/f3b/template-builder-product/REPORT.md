# Fidelity report — f3b-builder-level2

- **Sample id:** `f3b-builder-level2`
- **Batch:** `f3b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3b/builder-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/08_8._Template_Builder/8._Template_Builder@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":2503}
- **Logical size:** 1280 × 1251.5 @ DPR 2
- **Compared pixels:** 2560 × 2503
- **Generated:** 2026-11-07T12:30:42.650Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.85681; min 64×64 tile 0.27036 |
| Text | pass | 33 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.85681 |
| SSIM (worst 64×64 tile) | 0.27036 |
| RMSE (RGB 0–255) | 41.352 |
| MAE (RGB 0–255) | 13.03 |
| ΔE2000 mean | 4.483 |
| ΔE2000 median | 0.997 |
| ΔE2000 p95 | 19.993 |
| ΔE2000 max | 86.617 |
| ΔE2000 > 2 (JND) | 46.43% |
| ΔE2000 > 5 | 6.67% |
| ΔE2000 > 10 | 6.07% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 929.5 | 72 | 334.5 | 88 | 74918 |
| 2 | 10.5 | 277.5 | 82 | 91.5 | 22668 |
| 3 | 842 | 632.5 | 67 | 18 | 4561 |
| 4 | 879.5 | 484.5 | 66.5 | 18 | 4539 |
| 5 | 1201 | 23 | 39 | 33 | 3227 |
| 6 | 652.5 | 780 | 58.5 | 17 | 1929 |
| 7 | 1008 | 256 | 31.5 | 24.5 | 1529 |
| 8 | 160 | 307 | 59 | 6 | 1396 |
| 9 | 282.5 | 124 | 19 | 24 | 1379 |
| 10 | 1149.5 | 256 | 19 | 24 | 1369 |
| 11 | 1121.5 | 255.5 | 25.5 | 25 | 1282 |
| 12 | 448.5 | 130 | 27 | 18 | 1279 |
| 13 | 171 | 130 | 27 | 18 | 1277 |
| 14 | 1170.5 | 256 | 21 | 24 | 1252 |
| 15 | 1093 | 255.5 | 21.5 | 25 | 1236 |
| 16 | 670.5 | 695.5 | 38 | 16.5 | 1177 |
| 17 | 897 | 949.5 | 23 | 22 | 1142 |
| 18 | 336 | 123.5 | 19 | 25 | 1121 |
| 19 | 477.5 | 130 | 19 | 24.5 | 1118 |
| 20 | 200 | 130 | 19 | 24.5 | 1113 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Comprehensive Inspection`, `v2`, `Preview`, `Publish template`, `Template details`, `Template name`, `Description`, `Service type`, `Vehicle type`, `Master items · 5`, `Search approved items`, `All categories`, `Brake pad wear check`, `Chassis · v1`, `Engine oil level`, `Engine · v1`, `Battery health check`, `Coolant level check`, `Wiper blade check`, `Template sequence`, `3 items selected`, `01`, `REQUIRED/REQUIRED · Locked by platform`, `Instruction mv-brake en`, `02`, `Instruction mv-oil en`, `03`, `Instruction mv-battery en`, `Drop checkpoint here`, `Add items`, `Version history`, `v1 · Published`, `3 items selected · 2026-11-03T10:00:00`
- Actual: `Comprehensive Inspection`, `v2`, `Preview`, `Publish template`, `Template details`, `Template name`, `Description`, `Service type`, `Vehicle type`, `Master items · 5`, `Search approved items`, `Search approved items`, `All categories`, `Brake pad wear check`, `Chassis · v1`, `Engine oil level`, `Engine · v1`, `Battery health check`, `Chassis · v1`, `Coolant level check`, `Engine · v1`, `Wiper blade check`, `Engine · v1`, `Template sequence`, `3 items selected`, `01`, `Brake pad wear check`, `REQUIRED/REQUIRED · Locked by platform`, `Chassis · v1`, `Instruction mv-brake en`, `02`, `Engine oil level`, `REQUIRED/REQUIRED · Locked by platform`, `Chassis · v1`, `Instruction mv-oil en`, `03`, `Battery health check`, `REQUIRED/REQUIRED · Locked by platform`, `Chassis · v1`, `Instruction mv-battery en`, `Drop checkpoint here`, `Add items`, `Version history`, `v1 · Published`, `3 items selected · 2026-11-03T10:00:00`, `Comprehensive Inspection`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

