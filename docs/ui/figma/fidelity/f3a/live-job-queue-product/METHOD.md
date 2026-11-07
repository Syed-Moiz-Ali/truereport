# F3-A live-job-queue Level 2 — product-vs-Figma method (slot replacements by design)

Screen 2 "Live Job Queue", Figma node `1:529`, frame **1280 x 1125**,
reference `docs/ui/figma-export/Workshop_admin_figma/screens/03_2._Live_Job_Queue/2._Live_Job_Queue@2x.png`,
crop **x=32, y=0, w=2560, h=2250** (same opaque-frame box as the Level 1
fixture). Render is the REAL product `JobsTab`
(`client/apps/admin_app/lib/src/pages/jobs_tab.dart`) pumped standalone at
1280 x 1125 logical, DPR 2, top-of-scroll, `TextScaler.noScaling`, bundled
Plus Jakarta Sans + MaterialIcons, `debugDisableShadows = false` during
capture and restored after. Compared grid 2560 x 2250 — 1:1, no resample
stretch.

Capture: `client/apps/admin_app/test/f3a_capture_queue_product_test.dart`
(new, test-only; `lib/` untouched). Fixture:
`docs/ui/figma/fidelity/fixtures/f3a/queue-level2.json` (same reference +
crop as Level 1, `thresholdSsim` 0.98, `expectedStrings` = the 26 distinct
product strings actually rendered, deny-list
`docs/ui/figma/fidelity/forbidden-terms.json`, no key boxes declared —
product layout differs by design, so geometry is informational only).

Fake data (realistic, status-spanning): four jobs (`IN_PROGRESS`,
`READY_TO_FINALIZE`, `FINALIZED`, `SCHEDULED`; synthetic `Customer A–D` /
`Technician A` names, `JOB-0001–0004`); filter-chip counts are derived
client-side from the same snapshot (`All (4) / In progress (1) / Ready to
finalize (1) / Finalized (1)`), exactly like the product.

## 1. Measured result (`compare.mjs`) — gate FAILS on SSIM by design

| Metric | Value |
|---|---|
| SSIM global / threshold | **0.89698** / 0.98 → deficit **0.08302** |
| SSIM worst 64x64 tile | **0.0695** at logical (192, 704, 32x32) — card-3 zone: Figma photo + `REVIEW ITEMS` vs product card |
| RMSE / MAE (RGB 0–255) | 37.196 / 10.148 |
| dE2000 mean / median / p95 / max | 3.122 / 0 / 15.023 / 100.0 |
| dE2000 > 2 / > 5 / > 10 | 21.96 % / 7.42 % / 5.75 % |
| Text | **26/26 pass**, 0 missing |
| Forbidden terms | **0 matches — pass** |
| Key boxes | none declared — pass (geometry informational) |
| Diff boxes (dE > 5) | 20 |

Product-anchored geometry (`geometry.json`, logical px): first job card
1248x154 @ (16, 176); search field 622.3x62.5 @ (134.2, 24.75).

## 2. Difference map — every Figma element vs slot-sheet row

| # | Figma element (slot sheet) | Product behaviour | Numeric effect |
|---|---|---|---|
| Q1 | Eyebrow `REAL-TIME DISPATCH`, stats `ACTIVE BAYS 06/08`, `AVG TURNAROUND 42m` | Neutral `Job queue` title + search + `New job`; stats omitted (no live/bay source) | Header boxes (768, 28, 139.5x57.5, area 28404), (16, 104, 82.5x53), glyph boxes (147, 126, 31.5x25), (235, 123.5, 19x28), (260, 123, 26x31), (304.5, 123.5, 19x28), (321.5, 123, 21x28.5), (37, 45, 29.5x22) |
| Q2 | Filters `All (12) / In Progress (4) / Pending Review (3) / Completed (5)` | Same segmented slot, neutral wording + real counts: `All (4) / In progress (1) / Ready to finalize (1) / Finalized (1)` | Chip-row boxes (242, 192, 114.5x28, area 12152), (133, 227.5, 535.5x10.5); text check passes on product copy |
| Q3 | Sort `Bay Order` + filter button; rows: `Bay 04`, `65%/30%` progress, `REVIEW ITEMS 2 Flags Marked`, `SLOT TIME 14:30 Today` | Bay/progress/flags/slot-time omitted (no source); rows show vehicle + reference + customer + `template vN` + assignee + `StatusChip` + chevron | Card-right-zone boxes (159.5, 345, 215.5x77, area 43766), (163.5, 516, 167.5x80, area 32563), (167, 678, 180x92, area 35748); row-text boxes (268, 553, 116x22), (268, 727, 90x22); chip edge (998, 387, 62.5x8); worst tile (192, 704, 32x32, 0.0695) |
| Q4 | Vehicle photos (4 JPG 80x80) | Omitted — neutral, no thumbs (no image field, no licence) | Thumbnail-column box (10, 208, 81x80, area 19961); card-4 photo box (168, 864, 80x80, area 24212); product card 1248x154 vs Figma 1104x150 |
| Q5 | Footer strip (`Live sync active…`, `Export Daily Log`, `Batch Reassign`, `Bay Schedule Matrix →`) | Omitted; product keeps pull-to-refresh/loading/error only | 0 live-sync/export/batch/matrix strings in rendered copy — verified |
| Q6 | All-family: fleet wording | 0 occurrences — verified | No effect |
| Q7 | All-family: full VIN / plates / emails / photos / sample people | 0 rendered (references stay `JOB-…`; assignees are plain fake names, not Figma samples) — verified | No effect |
| Q8 | All-family: hardware/BLE/telemetry wording | 0 occurrences — verified | No effect |
| Q9 | All-family: scores / `%` / invented counts | 0 `%` signs; only real chip counts — verified | No effect |

New residuals (structural, not slot-sheet rows): N1 — standalone tab, no
96 px rail and no tab bar (capture construction). N2 — product search field
is 622.3x62.5, far larger than the Figma 299x34 slot. N3 — cards are
full-width 1248 px rows vs Figma 1104 px photo cards. N4 — `New job` is the
product kit button, not the Figma 157.14x56 treatment. N5 — `1208, 24, 32x32`
(area 2986): right-header avatar/icon zone (Figma user avatar vs product
header trailing edge).

## 3. Not verified

Scrolled content below the fourth card; job detail bottom sheets;
assign/cancel flows; `+ New Job` sheet; Arabic/RTL; text scaling above 1.0x;
hover/focus; dark theme (product is light-only); widths other than 1280;
loading/empty/error states; search/filter interaction visuals; real server
data. No pixel-perfect claim is made — every non-zero SSIM/dE value above is
a measured residual.
