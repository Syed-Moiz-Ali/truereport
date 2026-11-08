# Fidelity report — f2a1-inspection-hub-figma-text

- **Sample id:** `f2a1-inspection-hub-figma-text`
- **Batch:** `f2a1-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2a1/inspection-hub-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/07_7._Main_Inspection_Hub/7._Main_Inspection_Hub@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2260}
- **Logical size:** 390 × 1130 @ DPR 2
- **Compared pixels:** 780 × 2260
- **Generated:** 2026-11-07T21:54:18.244Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98216; min 64×64 tile 0.73193 |
| Text | pass | 0 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | no key boxes declared |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98216 |
| SSIM (worst 64×64 tile) | 0.73193 |
| RMSE (RGB 0–255) | 10.618 |
| MAE (RGB 0–255) | 1.719 |
| ΔE2000 mean | 0.513 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.338 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 2.59% |
| ΔE2000 > 5 | 1.43% |
| ΔE2000 > 10 | 1.04% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 68 | 1063.5 | 17 | 21 | 245 |
| 2 | 303.5 | 1088.5 | 11 | 8.5 | 232 |
| 3 | 136 | 24.5 | 14 | 16.5 | 210 |
| 4 | 235.5 | 778 | 15 | 18 | 199 |
| 5 | 221 | 1086 | 6.5 | 11 | 184 |
| 6 | 164 | 88.5 | 8.5 | 9 | 166 |
| 7 | 315 | 1086.5 | 7 | 10.5 | 163 |
| 8 | 174 | 88.5 | 6.5 | 8.5 | 155 |
| 9 | 223 | 254.5 | 7.5 | 9 | 155 |
| 10 | 181.5 | 88.5 | 6 | 8.5 | 154 |
| 11 | 296 | 1086.5 | 6.5 | 10.5 | 152 |
| 12 | 228.5 | 1088 | 6 | 11 | 152 |
| 13 | 196 | 88.5 | 6.5 | 9 | 148 |
| 14 | 204 | 254.5 | 8 | 9 | 146 |
| 15 | 158 | 1088 | 6.5 | 9 | 146 |
| 16 | 188.5 | 88.5 | 6.5 | 9 | 143 |
| 17 | 151 | 1088 | 6.5 | 9 | 140 |
| 18 | 242 | 1088 | 6 | 9 | 139 |
| 19 | 69 | 24.5 | 4 | 16.5 | 136 |
| 20 | 51.5 | 596.5 | 17 | 15 | 136 |

## Key-box geometry

No key boxes declared for this sample.

## Text

- Expected: —
- Actual: `INSPECTION IN PROGRESS`, `Bay #04 • VIN 8492`, `45`, `/110`, `CHECKS DONE`, `42 Passed`, `3 Action Items`, `Porsche Taycan 4S`, `WA1-VAA-Y7890 • 12,480 MI`, `Inspection Modules`, ` Categories`, `Exterior`, `28/28 Done`, `17/32`, `Interior`, `Active Bay`, `Engine`, `0/24 Done`, `Queued`, `Underbody`, `0/26 Done`, `Queued`, `Continue Interior Checklist`, `Intake Hub`, `Intake`, `Fleet`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

