# Fidelity report — Synthetic degraded pair (known noise + colour shift)

- **Sample id:** `synthetic-degraded`
- **Batch:** `synthetic`
- **Renderer:** `synthetic`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/synthetic/synthetic-degraded.json`
- **Reference:** `docs/ui/figma/fidelity/synthetic/synthetic-degraded/reference.png`
- **Logical size:** 390 × 120 @ DPR 2
- **Compared pixels:** 780 × 240
- **Generated:** 2026-11-05T08:32:52.604Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.89708; min 64×64 tile 0.73485 |
| Text | pass | 1 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.89708 |
| SSIM (worst 64×64 tile) | 0.73485 |
| RMSE (RGB 0–255) | 18.539 |
| MAE (RGB 0–255) | 4.408 |
| ΔE2000 mean | 1.284 |
| ΔE2000 median | 0.608 |
| ΔE2000 p95 | 1.686 |
| ΔE2000 max | 29.113 |
| ΔE2000 > 2 (JND) | 2.4% |
| ΔE2000 > 5 | 2.4% |
| ΔE2000 > 10 | 2.4% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 32 | 32 | 60 | 12 | 2880 |
| 2 | 260 | 75 | 45 | 9 | 1620 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: `Continue`
- Actual: `Continue`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Deterministic degradation used to prove the gate fails and the diff boxes are reported.

