# Fidelity report — Forbidden-term proof — bad string

- **Sample id:** `forbidden-bad-string`
- **Batch:** `synthetic`
- **Renderer:** `synthetic`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/forbidden/bad-string.json`
- **Reference:** `docs/ui/figma/fidelity/lint/bad/reference.png`
- **Logical size:** 390 × 120 @ DPR 2
- **Compared pixels:** 780 × 240
- **Generated:** 2026-11-05T11:03:15.749Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 1; min 64×64 tile 1 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | fail | 3 match(es) |
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
- Actual: `Certified inspection report`, `Verified score 98`

### Forbidden-term matches

- **certified** (term) matched `Certified`: Certified inspection report Verified …
- **verified** (term) matched `Verified`: Certified inspection report Verified score 98
- **score** (term) matched `score`: … inspection report Verified score 98

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Images are identical; the gate must fail only because the deny-list matched.

