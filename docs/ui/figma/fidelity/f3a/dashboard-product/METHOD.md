# F3-A dashboard Level 2 — product-vs-Figma method (slot replacements by design)

Screen 1 "Workshop Dashboard", Figma node `1:299`, frame **1280 x 1230.672**,
reference `docs/ui/figma-export/Workshop_admin_figma/screens/02_1._Workshop_Dashboard/1._Workshop_Dashboard@2x.png`
(2592 x 2474 px), crop **x=32, y=0, w=2560, h=2461** (same opaque-frame box as
the Level 1 fixture). Render is the REAL product `DashboardTab`
(`client/apps/admin_app/lib/src/pages/dashboard_tab.dart`) pumped standalone
at 1280 x 1230.672 logical, DPR 2, top-of-scroll, `TextScaler.noScaling`,
bundled Plus Jakarta Sans + MaterialIcons, `debugDisableShadows = false`
during capture and restored after. Compared grid 2560 x 2461 — 1:1, no
resample stretch.

Capture: `client/apps/admin_app/test/f3a_capture_dashboard_product_test.dart`
(new, test-only; `lib/` untouched). Fixture:
`docs/ui/figma/fidelity/fixtures/f3a/dashboard-level2.json` (same reference +
crop as Level 1, `thresholdSsim` 0.98, `expectedStrings` = the 31 distinct
product strings actually rendered, deny-list
`docs/ui/figma/fidelity/forbidden-terms.json`, no key boxes declared —
product layout differs by design, so geometry is informational only).

Fake data (realistic, status-spanning): counts endpoint
`{draft:2, scheduled:3, newScheduled:5, assigned:4, inProgress:3,
readyToFinalize:2, finalized:6, finalizedToday:1, cancelled:1, total:17}`
(active = 7 = 4 + 3, derived client-side) plus four jobs (`IN_PROGRESS`,
`READY_TO_FINALIZE`, `FINALIZED`, `ASSIGNED`; synthetic `Customer A–D` /
`Technician A` names, `JOB-0001–0004`, `TESTVIN…` values that never render
top-of-scroll). No session is provided, so the account chip is omitted — the
product renders `displayName + workshopName` only when signed in (covered by
`dashboard_test.dart` "user chip shows account and workshop names").

## 1. Measured result (`compare.mjs`) — gate FAILS on SSIM by design

| Metric | Value |
|---|---|
| SSIM global / threshold | **0.88768** / 0.98 → deficit **0.09232** |
| SSIM worst 64x64 tile | **0.2121** at logical (256, 768, 32x32) — job-rows zone: Figma activity rows vs product job cards |
| RMSE / MAE (RGB 0–255) | 31.737 / 7.818 |
| dE2000 mean / median / p95 / max | 2.325 / 0 / 6.304 / 85.576 |
| dE2000 > 2 / > 5 / > 10 | 15.76 % / 5.37 % / 4.23 % |
| Text | **31/31 pass**, 0 missing |
| Forbidden terms | **0 matches — pass** |
| Key boxes | none declared — pass (geometry informational) |
| Diff boxes (dE > 5) | 20 |

Product-anchored geometry (`geometry.json`, logical px): header
1248x80 @ (16, 16); stat-active card 240x120 @ (16, 140); first job card
1248x154 @ (16, 322).

## 2. Difference map — every Figma element vs slot-sheet row

| # | Figma element (slot sheet) | Product behaviour | Numeric effect |
|---|---|---|---|
| D1 | `BAY ACTIVE Shop Floor #04` pill + 96 px icon rail | Omitted (no bay entity; O4). Capture pumps the tab standalone, so no rail/shell at all | Left-column tiles y64–128 collapse (0.31–0.65); box (10.5, 128, 215.5x80, area 19506) |
| D2 | Header search `Search VIN, tech, job ticket…` | Same slot, `Search jobs` → existing search | Glyph-level only; header small boxes (133.5, 105.5, 49x25), (181.5, 109, 48x21.5) |
| D3 | User chip `Marcus Vance / Lead Inspector` | Omitted in this capture (no session); signed-in product shows account + workshop, never the sample name/role | Part of right-header diff zone; box (1074, 120.5, 173.5x76.5, area 37167) |
| D4 | Eyebrow `TELEMETRICS • REAL-TIME` + subtitle | `Overview` + `Jobs by status in your workshop` | Title-glyph boxes above; text check passes on product copy |
| D5 | Shift toggle `Shift A (Current) / Past 24h` | Omitted (no shift entity) | Same zone as D3/D6 box |
| D6 | `Dispatch Bay` CTA | Omitted (no dispatch; `+ New Job` lives on the queue) | Same zone as D3/D5 box |
| D7 | KPI `12 / 14 BAYS … +2 incoming` | `7 Active jobs` from counts (assigned + inProgress) | Product card 240x120 vs Figma 346.67x346.67; KPI-zone boxes (318, 338, 114.5x27.5), (37, 319, 1206x6), (36.5, 474, 511x11), (547.5, 474, 122x14), (655.5, 474, 306x13.5), (933.5, 474, 310x11), (925, 512.5, 283x6.5), (546.5, 512.5, 79.5x6.5), (168, 500, 298x27.5) |
| D8 | KPI `4 QUEUE … Requires Action` | `2 Ready to finalize`, neutral O6 wording | Same KPI zone as D7 |
| D9 | KPI `8 REPORTS SENT — 100% ACCURACY` | `1 Finalized today`, never an accuracy line | Same KPI zone as D7 |
| D10 | Activity rows (Porsche/Ford/Renault, bays, `48/48 points`, `Passed`, `Awaiting Review`, sign-off/certificate) | Four real job rows (`JOB-… · Customer`, vehicle, template, `Scheduled at:`, `Assigned to:`, neutral `StatusChip`) | Job card 1248x154 vs Figma activity card 725.33x476; worst tile (256, 768, 32x32, 0.2121); boxes (36.5, 718, 1207x141.5, area 22284), (317, 660, 106.5x37.5), (322.5, 824, 103x27.5) |
| D11 | Telemetry column (`76% CAPACITY`, turnaround, median, compliance, floor map) | Omitted (no bay/telemetry source) | Same lower zone as D10 box (36.5, 718, 1207x141.5) |
| D12 | All-family: fleet wording | 0 occurrences in rendered strings — verified | No effect |
| D13 | All-family: full VIN / plates / emails / photos / avatars / sample people | 0 rendered top-of-scroll (references stay `JOB-…`; no thumbs; no sample names) — verified | No effect |
| D14 | All-family: hardware/BLE/telemetry wording | 0 occurrences — verified | No effect |
| D15 | All-family: scores / `%` / invented counts | 0 `%` signs; only real counts 7/5/3/2/1 with plain labels — verified | No effect |

New residuals (structural, not slot-sheet rows): N1 — standalone tab, no
96 px rail and no tab bar (capture construction; left-column tiles ~0.99 at
y0 but 0.31–0.79 at y64–128 where the rail/header-chrome boundary sits). N2 —
stat grid is five 240x120 Wrap cards, not three 346.67² cards. N3 — job cards
are full-width 1248 px rows; there is no 346.67 px telemetry column. N4 —
thin full-width card-edge strips (1206x6 @ y319; 1208x0.5 @ y637.5; 1207.5x0.5
@ y645.5; 1206.5x0.5 @ y961.5) where product card edges meet flat Figma
background. N5 — `1208, 24, 32x32` (area 2986): right-header avatar/icon zone
(Figma user avatar vs product header trailing edge).

## 3. Not verified

Below-fold/scrolled content; job detail bottom sheets; the signed-in account-chip
variant (covered separately by `dashboard_test.dart`); Arabic/RTL; text
scaling above 1.0x; hover/focus; dark theme (product is light-only); widths
other than 1280; loading/empty/error states; counts-error and jobs-error
states; tap/assign/report navigation; real server data. No pixel-perfect claim
is made — every non-zero SSIM/dE value above is a measured residual.
