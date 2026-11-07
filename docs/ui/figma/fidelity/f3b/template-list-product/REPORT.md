# Fidelity report — f3b-templates-level2

- **Sample id:** `f3b-templates-level2`
- **Batch:** `f3b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f3b/templates-level2.json`
- **Reference:** `docs/ui/figma-export/Workshop_admin_figma/screens/06_7._Workshop_Template_List/7._Workshop_Template_List@2x.png`
- **Reference crop (px):** {"x":32,"y":0,"width":2560,"height":3172}
- **Logical size:** 1280 × 1586 @ DPR 2
- **Compared pixels:** 2560 × 3172
- **Generated:** 2026-11-07T12:30:32.932Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.88902; min 64×64 tile 0.23688 |
| Text | pass | 25 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.88902 |
| SSIM (worst 64×64 tile) | 0.23688 |
| RMSE (RGB 0–255) | 39.509 |
| MAE (RGB 0–255) | 10.998 |
| ΔE2000 mean | 3.402 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 24.86 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 21.79% |
| ΔE2000 > 5 | 7.94% |
| ΔE2000 > 10 | 6.99% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 1041 | 93.5 | 207 | 76.5 | 55328 |
| 2 | 828.5 | 28 | 175 | 57.5 | 37437 |
| 3 | 1101 | 748 | 147 | 56 | 30223 |
| 4 | 723.5 | 828 | 112 | 60.5 | 23883 |
| 5 | 345 | 828 | 112 | 60.5 | 23869 |
| 6 | 345 | 1302 | 111.5 | 60.5 | 23869 |
| 7 | 723.5 | 1301.5 | 112 | 60.5 | 23826 |
| 8 | 1102.5 | 828.5 | 111.5 | 61 | 23791 |
| 9 | 410 | 228 | 114 | 48 | 20028 |
| 10 | 10.5 | 288 | 77.5 | 76 | 19482 |
| 11 | 880 | 464 | 74.5 | 56 | 14076 |
| 12 | 40 | 464 | 74.5 | 56 | 14066 |
| 13 | 460 | 464 | 74.5 | 56 | 14066 |
| 14 | 16 | 226 | 82 | 50 | 13811 |
| 15 | 244 | 326 | 107.5 | 28 | 11323 |
| 16 | 353 | 503 | 97.5 | 22.5 | 8361 |
| 17 | 664 | 326 | 79.5 | 28 | 8202 |
| 18 | 734 | 503.5 | 95 | 21.5 | 7772 |
| 19 | 1117.5 | 503.5 | 90.5 | 21.5 | 7406 |
| 20 | 1208 | 24 | 32 | 32 | 2986 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Inspection templates`, `Search`, `New template`, `179`, `Total checkpoints`, `All (3)`, `Published (1)`, `Draft (1)`, `Retired (1)`, `Grid`, `List`, `Published`, `Full inspection`, `v2 · 110 items selected`, `FULL`, `Edit`, `Draft`, `Quick oil service`, `v1 · 24 items selected`, `QUICK`, `Retired`, `Highway check`, `v3 · 45 items selected`, `Locked by platform`, `Version history`
- Actual: `Inspection templates`, `Search`, `Search`, `New template`, `179`, `Total checkpoints`, `All (3)`, `Published (1)`, `Draft (1)`, `Retired (1)`, `Grid`, `List`, `Published`, `Full inspection`, `v2 · 110 items selected`, `FULL`, `Edit`, `Draft`, `Quick oil service`, `v1 · 24 items selected`, `QUICK`, `Edit`, `Retired`, `Highway check`, `v3 · 45 items selected`, `FULL`, `Edit`, `New template`, `Locked by platform`, `Version history`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

