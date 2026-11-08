# Fidelity report — f2b3-offline-sync-level1

- **Sample id:** `f2b3-offline-sync-level1`
- **Batch:** `f2b3-screens`
- **Renderer:** `flutter`
- **Fixture:** `docs/ui/figma/fidelity/fixtures/f2b3/offline-sync-level1.json`
- **Reference:** `docs/ui/figma-export/technision_figma/screens/14_15._Offline_Sync_Queue/15._Offline_Sync_Queue@2x.png`
- **Reference crop (px):** {"x":60,"y":14,"width":780,"height":2724}
- **Logical size:** 390 × 1362 @ DPR 2
- **Compared pixels:** 780 × 2724
- **Generated:** 2026-11-08T09:29:08.721Z
- **Owner:** harness-engineer

## Gate

**PASS** — SSIM threshold 0.98.

| Check | Result | Detail |
|---|---|---|
| SSIM | pass | global 0.98039; min 64×64 tile 0.78528 |
| Text | pass | 38 expected string(s) present |
| Forbidden terms | pass | 0 match(es) |
| Key boxes | pass | 3/3 within 2 logical px |

## Measured metrics

| Metric | Value |
|---|---|
| SSIM (global) | 0.98039 |
| SSIM (worst 64×64 tile) | 0.78528 |
| RMSE (RGB 0–255) | 11.657 |
| MAE (RGB 0–255) | 2.405 |
| ΔE2000 mean | 0.706 |
| ΔE2000 median | 0 |
| ΔE2000 p95 | 1.739 |
| ΔE2000 max | 85.576 |
| ΔE2000 > 2 (JND) | 4.39% |
| ΔE2000 > 5 | 2.51% |
| ΔE2000 > 10 | 1.77% |

## Diff bounding boxes (ΔE2000 > 5)

| # | logical x | logical y | logical w | logical h | area (px) |
|---:|---:|---:|---:|---:|---:|
| 1 | 47 | 1051.5 | 296 | 0.5 | 592 |
| 2 | 336 | 372 | 17.5 | 15 | 401 |
| 3 | 340.5 | 380 | 13.5 | 8 | 276 |
| 4 | 66.5 | 1295.5 | 18.5 | 20 | 259 |
| 5 | 262 | 375.5 | 8.5 | 9.5 | 196 |
| 6 | 42.5 | 685.5 | 98 | 0.5 | 196 |
| 7 | 274 | 375.5 | 7 | 9.5 | 175 |
| 8 | 155 | 377.5 | 18 | 3.5 | 175 |
| 9 | 241 | 375.5 | 7.5 | 9.5 | 173 |
| 10 | 155 | 373 | 18 | 3.5 | 166 |
| 11 | 155 | 382 | 18 | 3.5 | 166 |
| 12 | 225.5 | 375.5 | 6 | 9.5 | 162 |
| 13 | 34 | 99.5 | 14 | 13.5 | 158 |
| 14 | 47 | 1124 | 8.5 | 10 | 153 |
| 15 | 156 | 658.5 | 7.5 | 10.5 | 150 |
| 16 | 127.5 | 960 | 7.5 | 10 | 150 |
| 17 | 56 | 623 | 6 | 13.5 | 149 |
| 18 | 143.5 | 1126.5 | 10.5 | 7.5 | 149 |
| 19 | 219.5 | 852.5 | 7.5 | 10.5 | 144 |
| 20 | 217.5 | 375.5 | 6.5 | 9.5 | 143 |

## Key-box geometry

| Key | Expected (x, y, w, h) | Actual (x, y, w, h) | Max delta (logical px) | Result |
|---|---|---|---:|---|
| `header` | 0, 0, 390, 64 | 0, 0, 390, 64 | 0 | pass |
| `active` | 20, 569.9, 350, 222 | 20, 569.9, 350, 222 | 0 | pass |
| `retry` | 20, 1051.9, 350, 56 | 20, 1051.9, 350, 56 | 0 | pass |

## Text

- Expected: `Sync Status`, `Local Engine v4.2 • Background
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
Annotations`, `6.2 MB`, `Retry Sync Now`, `Device will ping master servers every 60 seconds`, `Sync Queue`, `Intake`, `Fleet`, `Sync`, `Profile`
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

