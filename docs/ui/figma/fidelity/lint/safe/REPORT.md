# Fidelity report — Forbidden-term proof — safe string

- **Sample id:** `forbidden-safe-string`
- **Batch:** `synthetic`
- **Renderer:** `synthetic`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/forbidden/safe-string.json`
- **Reference:** `docs/ui/figma/fidelity/lint/safe/reference.png`
- **Logical size:** 390 × 120 @ DPR 2
- **Compared pixels:** 780 × 240
- **Generated:** 2026-11-05T11:03:15.335Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 1; min 64×64 tile 1 |
| Text | pass | 1 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
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

- Expected: `No issue observed`
- Actual: `No issue observed`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Images are identical and the strings contain no deny-listed term.

