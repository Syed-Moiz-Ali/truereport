# Fidelity report — f2b-offline-sync-figma-text

- **Sample id:** `f2b-offline-sync-figma-text`
- **Batch:** `f2b-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b/offline-sync-figma-text.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/14_15._Offline_Sync_Queue/15._Offline_Sync_Queue@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2724}
- **Logical size:** 390 × 1362 @ DPR 2
- **Compared pixels:** 780 × 2724
- **Generated:** 2026-11-08T09:44:00.793Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98103; min 64×64 tile 0.78528 |
| Text | pass | 10 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98103 |
| SSIM (worst 64×64 tile) | 0.78528 |
| RMSE (RGB 0–255) | 11.21 |
| MAE (RGB 0–255) | 2.352 |
| ΔE2000 mean | 0.693 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.737 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 4.36% |
| ΔE2000 > 5 | 2.48% |
| ΔE2000 > 10 | 1.74% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 47 | 1051.5 | 296 | 0.5 | 592 |
| 2 | 66.5 | 1295.5 | 18.5 | 20 | 259 |
| 3 | 262 | 375.5 | 8.5 | 9.5 | 196 |
| 4 | 42.5 | 685.5 | 98 | 0.5 | 196 |
| 5 | 274 | 375.5 | 7 | 9.5 | 175 |
| 6 | 241 | 375.5 | 7.5 | 9.5 | 173 |
| 7 | 225.5 | 375.5 | 6 | 9.5 | 162 |
| 8 | 34 | 99.5 | 14 | 13.5 | 158 |
| 9 | 47 | 1124 | 8.5 | 10 | 153 |
| 10 | 156 | 658.5 | 7.5 | 10.5 | 150 |
| 11 | 127.5 | 960 | 7.5 | 10 | 150 |
| 12 | 56 | 623 | 6 | 13.5 | 149 |
| 13 | 143.5 | 1126.5 | 10.5 | 7.5 | 149 |
| 14 | 219.5 | 852.5 | 7.5 | 10.5 | 144 |
| 15 | 217.5 | 375.5 | 6.5 | 9.5 | 143 |
| 16 | 117 | 658.5 | 7.5 | 10.5 | 143 |
| 17 | 132.5 | 1126.5 | 7 | 10.5 | 142 |
| 18 | 218 | 437.5 | 4 | 16.5 | 140 |
| 19 | 232.5 | 375.5 | 7 | 9.5 | 137 |
| 20 | 107 | 850 | 9.5 | 10 | 136 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `queue` | 20, 569.9, 350, 222 | 20, 569.9, 350, 222 | 0 | pass |
| `retry` | 20, 1051.9, 350, 56 | 20, 1051.9, 350, 56 | 0 | pass |

## Text

- Expected: `Sync Status`, `Upload Queue`, `Retry Sync Now`, `Queued`, `Standby`, `3`, `Inspections`, `BUFFERED CACHE`, `PENDING BATCH`, `Transfer Speed`
- Actual: `Sync Status`, `Local Engine v4.2 • Background
sync`, `No
Signal`, `Working Offline — Saving
Locally`, `Store
Active`, `All high-res vehicle capture tags and
inspection checkpoints are safely cached to
device storage. Sync will automatically
resume when network restores.`, `BUFFERED CACHE`, `148.6`, `MB Local`, `PENDING BATCH`, `3`, `Inspections`, `Awaiting link`, `Upload Queue`, `Auto-retry paused`, `Uploading Evidence
Photos (4/12)`, `Job #IN-88912 • 2024 Ford F-
150 Lightning`, `Standby`, `33% completed`, `8 items remaining`, `Transfer Speed`, `0.0 KB/s`, `Pending Jobs`, `2 in Line`, `Telemetry Telematics & Checkpoints`, `Job #IN-88909 • 6 Diagnostic
Codes`, `Queued`, `18.4 MB`, `Body Schematics Pin Markups`, `Job #IN-88904 • 4 Dent
Annotations`, `Queued`, `6.2 MB`, `Retry Sync Now`, `Device will ping master servers every 60 seconds`, `Sync Queue`, `Intake`, `Fleet`, `Sync`, `Profile`

## Artifacts

- `figma.png` — cropped reference, normalised to the render pixel grid
- `render.png` — render, normalised to the same pixel grid
- `side-by-side.png` — reference (left), render (right)
- `diff.png` — ΔE2000 heatmap over a dimmed render
- `metrics.json` — machine-readable metrics

## Residuals / notes

Any non-zero SSIM or ΔE2000 is a measured residual; it is not a pixel-perfect claim.

