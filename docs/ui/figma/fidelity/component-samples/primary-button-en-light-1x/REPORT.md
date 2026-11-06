# Fidelity report — Primary button - Figma exact - EN, light, 1x

- **Sample id:** `primary-button-en-light-1x`
- **Batch:** `f1.1-component-samples`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/component-samples/primary-button-en-light-1x.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/01_1._Login_&_Language_Selection/1._Login_&_Language_Selection@2x.png`
- **Reference crop (px):** {"x":48,"y":944,"width":684,"height":112}
- **Logical size:** 342 × 56 @ DPR 2
- **Compared pixels:** 684 × 112
- **Generated:** 2026-11-06T03:30:44.396Z
- **Owner:** fidelity-auditor

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.99622; min 64×64 tile 0.97967 |
| Text | pass | 1 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 1/1 within 1 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.99622 |
| SSIM (worst 64×64 tile) | 0.97967 |
| RMSE (RGB 0–255) | 4.663 |
| MAE (RGB 0–255) | 0.387 |
| ΔE2000 mean | 0.105 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0 |
| ΔE2000 max | 30.789 |
| ΔE2000 > 2 (JND) | 0.87% |
| ΔE2000 > 5 | 0.59% |
| ΔE2000 > 10 | 0.38% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 191.5 | 27.5 | 10.5 | 6 | 52 |
| 2 | 153.5 | 26 | 7 | 11.5 | 42 |
| 3 | 149.5 | 26 | 2 | 8 | 34 |
| 4 | 162 | 26 | 7 | 8 | 32 |
| 5 | 176 | 26 | 7 | 8 | 32 |
| 6 | 172.5 | 23.5 | 2 | 10.5 | 24 |
| 7 | 153 | 26 | 6 | 2 | 17 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `primary-button` | 0, 0, 342, 56 | 0, 0, 342, 56 | 0 | pass |

## Text

- Expected: `Sign In`
- Actual: `Sign In`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Crop is the Figma Button node bounding box (342 x 56 at logical 24,472). The render uses the Figma fill #10B981, white 14/18 w700 label, 10.67 px arrow and the subtle Figma shadow. This is option 1; the product default remains the ink-label option until the owner chooses.

