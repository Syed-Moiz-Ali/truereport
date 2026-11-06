# Fidelity report — Delivery status card - Figma exact - EN, light, 1x

- **Sample id:** `delivery-status-card-en-light-1x`
- **Batch:** `f1.1-component-samples`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/component-samples/delivery-status-card-en-light-1x.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/16_16._Post-Finalization_Success/16._Post-Finalization_Success@2x.png`
- **Reference crop (px):** {"x":80,"y":799,"width":700,"height":290}
- **Logical size:** 350 × 145 @ DPR 2
- **Compared pixels:** 700 × 290
- **Generated:** 2026-11-06T03:30:44.936Z
- **Owner:** fidelity-auditor

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.99261; min 64×64 tile 0.89954 |
| Text | pass | 4 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 1/1 within 1 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.99261 |
| SSIM (worst 64×64 tile) | 0.89954 |
| RMSE (RGB 0–255) | 7.554 |
| MAE (RGB 0–255) | 0.805 |
| ΔE2000 mean | 0.253 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 0 |
| ΔE2000 max | 85.209 |
| ΔE2000 > 2 (JND) | 1.56% |
| ΔE2000 > 5 | 1.33% |
| ΔE2000 > 10 | 0.92% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 28.5 | 107 | 19 | 7 | 157 |
| 2 | 29.5 | 30 | 17 | 16.5 | 98 |
| 3 | 129 | 36 | 9.5 | 12.5 | 69 |
| 4 | 35.5 | 102.5 | 8.5 | 8.5 | 66 |
| 5 | 32 | 31 | 13 | 10.5 | 65 |
| 6 | 139.5 | 36 | 9 | 12.5 | 64 |
| 7 | 109.5 | 39.5 | 7 | 6 | 59 |
| 8 | 78 | 101.5 | 2.5 | 12.5 | 53 |
| 9 | 152 | 101.5 | 2.5 | 12.5 | 53 |
| 10 | 100.5 | 103 | 6 | 9 | 52 |
| 11 | 69 | 102 | 8.5 | 12 | 43 |
| 12 | 71 | 104 | 5.5 | 10 | 40 |
| 13 | 82.5 | 111 | 7.5 | 3.5 | 37 |
| 14 | 85 | 32.5 | 2.5 | 12.5 | 36 |
| 15 | 310 | 105 | 5 | 7.5 | 35 |
| 16 | 110.5 | 102 | 5 | 12 | 33 |
| 17 | 30.5 | 29.5 | 15 | 0.5 | 30 |
| 18 | 121.5 | 108.5 | 8 | 6 | 30 |
| 19 | 104 | 34 | 4.5 | 8.5 | 29 |
| 20 | 31.5 | 31 | 12.5 | 0.5 | 25 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `delivery-status-card` | 0, 0, 350, 145 | 0, 0, 350, 145 | 0 | pass |

## Text

- Expected: `WhatsApp`, `Sent`, `Fleet Portal`, `Synced`
- Actual: `WhatsApp`, `Sent`, `Fleet Portal`, `Synced`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Crop is the Figma Delivery Status Card node bounding box (350 x 145 at logical 20,399.5). Figma's own sample copy is used in this test-only fixture: WhatsApp/Sent and Fleet Portal/Synced. The product variant uses report-link/workshop-copy labels; that copy change is a documented content deviation.

