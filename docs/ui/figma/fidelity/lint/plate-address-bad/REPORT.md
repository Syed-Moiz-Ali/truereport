# Fidelity report — Plate and precise-location values must be denied

- **Sample id:** `forbidden-plate-address`
- **Batch:** `lint`
- **Renderer:** `synthetic`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/forbidden/plate-address-bad.json`
- **Reference:** `docs/ui/figma/fidelity/synthetic/synthetic-clean/reference.png`
- **Logical size:** 390 × 120 @ DPR 2
- **Compared pixels:** 780 × 240
- **Generated:** 2026-11-05T11:49:11.728Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 1; min 64×64 tile 1 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | fail | 2 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 1 |
| SSIM (worst 64×64 tile) | 1 |
| RMSE (RGB 0–255) | 0 |
| MAE (RGB 0–255) | 0 |
| ΔE2000 mean | 0 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0 |
| ΔE2000 max | 0 |
| ΔE2000 > 2 (JND) | 0% |
| ΔE2000 > 5 | 0% |
| ΔE2000 > 10 | 0% |

## Diff bounding boxes (ΔE2000 > 5)

None above the threshold (minimum area 16 px).

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `DXB A 12345`, `Dubai Marina`

### Forbidden-term matches

- **uae-plate-value** (pattern) matched `DXB A 12345`: DXB A 12345 Dubai Marina
- **uae-area-address** (pattern) matched `Dubai Marina`: DXB A 12345 Dubai Marina

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Negative fixture: the plate and address patterns must match.

