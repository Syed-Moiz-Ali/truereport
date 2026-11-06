# Fidelity report — f2a1-empty-state-figma-text

- **Sample id:** `f2a1-empty-state-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/empty-state-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/03_3._Empty_State_Dashboard/3._Empty_State_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":1768}
- **Logical size:** 390 × 883.75 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-06T04:35:55.063Z
- **Owner:** harness-engineer

## Gate

**FAIL** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | fail | global 0.96216; min 64×64 tile 0.5207 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.96216 |
| SSIM (worst 64×64 tile) | 0.5207 |
| RMSE (RGB 0–255) | 19.086 |
| MAE (RGB 0–255) | 3.3 |
| ΔE2000 mean | 1.013 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.422 |
| ΔE2000 max | 97.336 |
| ΔE2000 > 2 (JND) | 3.8% |
| ΔE2000 > 5 | 2.6% |
| ΔE2000 > 10 | 2.17% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 24 | 76 | 40 | 40 | 4951 |
| 2 | 88 | 737.5 | 81 | 16.5 | 2307 |
| 3 | 333.5 | 17.5 | 28.5 | 30.5 | 1594 |
| 4 | 200 | 579 | 55 | 12 | 1338 |
| 5 | 153.5 | 579 | 49 | 11 | 1297 |
| 6 | 239.5 | 731.5 | 33 | 9.5 | 780 |
| 7 | 275 | 34.5 | 32.5 | 9 | 769 |
| 8 | 307.5 | 731.5 | 30 | 9.5 | 743 |
| 9 | 168.5 | 737.5 | 26 | 13.5 | 695 |
| 10 | 277.5 | 731.5 | 29.5 | 9.5 | 676 |
| 11 | 47.5 | 726.5 | 17 | 18.5 | 571 |
| 12 | 131.5 | 577 | 16 | 13.5 | 536 |
| 13 | 226.5 | 819 | 20.5 | 16 | 391 |
| 14 | 283.5 | 20.5 | 16.5 | 8.5 | 374 |
| 15 | 192 | 238 | 6 | 16 | 344 |
| 16 | 299 | 90.5 | 11.5 | 11 | 343 |
| 17 | 143.5 | 819 | 19.5 | 17.5 | 229 |
| 18 | 32 | 120 | 23 | 3.5 | 224 |
| 19 | 339 | 731 | 15 | 9.5 | 212 |
| 20 | 228.5 | 821 | 16.5 | 11 | 175 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `SHIFT ACTIVE`, `Bay 04`, `Welcome back,`, `David Vance`, `0 IN QUEUE`, `You are all caught up!`, `No pending vehicle inspections assigned
to you today.`, `Refresh Queue`, `TODAY'S SUMMARY`, `0 Completed`, `100% Pass Rate`, `Inspection Queue`, `LIVE
SYNC`, `Intake`, `Fleet`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

