# Fidelity report — f2a1-empty-state-product-copy

- **Sample id:** `f2a1-empty-state-product-copy`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/empty-state-product-copy.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/03_3._Empty_State_Dashboard/3._Empty_State_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":1768}
- **Logical size:** 390 × 883.75 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-07T19:41:47.233Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.94052; min 64×64 tile 0.36632 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | fail | 1 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.94052 |
| SSIM (worst 64×64 tile) | 0.36632 |
| RMSE (RGB 0–255) | 28.418 |
| MAE (RGB 0–255) | 5.065 |
| ΔE2000 mean | 1.673 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.275 |
| ΔE2000 max | 92.513 |
| ΔE2000 > 2 (JND) | 3.95% |
| ΔE2000 > 5 | 3.37% |
| ΔE2000 > 10 | 3.02% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 21 | 177 | 112 | 26 | 5049 |
| 2 | 188 | 450.5 | 112.5 | 22 | 4731 |
| 3 | 333 | 16 | 32.5 | 32 | 3241 |
| 4 | 87 | 451 | 79.5 | 17 | 3059 |
| 5 | 128 | 182.5 | 47 | 15 | 1605 |
| 6 | 61 | 487.5 | 63.5 | 14 | 1524 |
| 7 | 153.5 | 579 | 51.5 | 11 | 1363 |
| 8 | 88 | 737.5 | 45 | 12.5 | 1270 |
| 9 | 235.5 | 490.5 | 55.5 | 8.5 | 1206 |
| 10 | 207 | 579 | 44.5 | 11 | 1100 |
| 11 | 189.5 | 488 | 45.5 | 13.5 | 1070 |
| 12 | 133.5 | 737.5 | 35.5 | 15.5 | 883 |
| 13 | 169 | 737.5 | 25.5 | 12.5 | 673 |
| 14 | 176.5 | 512 | 32.5 | 13 | 653 |
| 15 | 166 | 450.5 | 16.5 | 17.5 | 641 |
| 16 | 163.5 | 488 | 25 | 13.5 | 611 |
| 17 | 146.5 | 91.5 | 26 | 8.5 | 576 |
| 18 | 34 | 91 | 21.5 | 12 | 534 |
| 19 | 291 | 487.5 | 20.5 | 14.5 | 491 |
| 20 | 307.5 | 731.5 | 19.5 | 12 | 484 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `LH`, `QUEUE EMPTY`, `0 JOBS`, `Welcome back,`, `Layla Hassan`, `0 IN QUEUE`, `You are all caught up`, `No pending inspections are assigned to you.`, `Refresh queue`, `Queue is current • Synced just now`, `TODAY'S SUMMARY`, `0 Completed`, `Coverage`, `Inspection Queue`, `ONLINE
SYNC`, `LH`, `Intake`, `Fleet`, `Sync`, `Profile`

### Forbidden-term matches

- **fleet** (term) matched `Fleet`: …Queue ONLINE SYNC LH Intake Fleet Sync Profile

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

