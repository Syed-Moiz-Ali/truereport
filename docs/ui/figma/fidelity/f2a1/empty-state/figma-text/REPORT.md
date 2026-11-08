# Fidelity report — f2a1-empty-state-figma-text

- **Sample id:** `f2a1-empty-state-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/empty-state-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/03_3._Empty_State_Dashboard/3._Empty_State_Dashboard@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":1768}
- **Logical size:** 390 × 883.75 @ DPR 2
- **Compared pixels:** 780 × 1768
- **Generated:** 2026-11-07T19:56:19.625Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98366; min 64×64 tile 0.72003 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98366 |
| SSIM (worst 64×64 tile) | 0.72003 |
| RMSE (RGB 0–255) | 9.927 |
| MAE (RGB 0–255) | 1.511 |
| ΔE2000 mean | 0.43 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0.836 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 2.11% |
| ΔE2000 > 5 | 1.52% |
| ΔE2000 > 10 | 1.13% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 192 | 238 | 6 | 16 | 324 |
| 2 | 94 | 177.5 | 18.5 | 19.5 | 174 |
| 3 | 223 | 841.5 | 6.5 | 9.5 | 162 |
| 4 | 47.5 | 728.5 | 17 | 16.5 | 155 |
| 5 | 52.5 | 182.5 | 15 | 14.5 | 152 |
| 6 | 139 | 577 | 6 | 13 | 138 |
| 7 | 156 | 843 | 6.5 | 8 | 132 |
| 8 | 139.5 | 840.5 | 5.5 | 10.5 | 128 |
| 9 | 149 | 843 | 6.5 | 8 | 126 |
| 10 | 87 | 451 | 9.5 | 17 | 123 |
| 11 | 20 | 151 | 15 | 10 | 121 |
| 12 | 68 | 182.5 | 5 | 14.5 | 120 |
| 13 | 263.5 | 731.5 | 9.5 | 9.5 | 116 |
| 14 | 178.5 | 450.5 | 4 | 17.5 | 113 |
| 15 | 183.5 | 450.5 | 4 | 17.5 | 113 |
| 16 | 244 | 844 | 6 | 7 | 108 |
| 17 | 331.5 | 845 | 7 | 6.5 | 107 |
| 18 | 60.5 | 821 | 18.5 | 17 | 103 |
| 19 | 322 | 842.5 | 6 | 8.5 | 97 |
| 20 | 21 | 177.5 | 8 | 19.5 | 92 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `DV`, `SHIFT ACTIVE`, `Bay 04`, `Welcome back,`, `David Vance`, `0 IN QUEUE`, `You are all caught up!`, `No pending vehicle inspections assigned
to you today.`, `Refresh Queue`, `Queue is current • Synced just now`, `TODAY'S SUMMARY`, `14 Completed`, `100% Pass Rate`, `Inspection Queue`, `LIVE
SYNC`, `Intake`, `Fleet`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

