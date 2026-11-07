# F3-B staff Level 2 — product-vs-Figma method (slot replacements by design)

Screen 5 "Workshop Staff Management", Figma node `1:1026`, frame
**1280 x 1048**, reference
`docs/ui/figma-export/Workshop_admin_figma/screens/05_5._Workshop_Staff_Management/5._Workshop_Staff_Management@2x.png`,
crop **x=32, y=0, w=2560, h=2096** (same opaque-frame box as the Level 1
fixture). Render is the REAL product `StaffTab`
(`client/apps/admin_app/lib/src/pages/staff_tab.dart`) pumped standalone at
1280 x 1048 logical, DPR 2, top-of-scroll, `TextScaler.noScaling`, bundled
Plus Jakarta Sans + MaterialIcons, `debugDisableShadows = false` during
capture and restored after. Compared grid 2560 x 2096 — 1:1, no resample
stretch.

Capture: `client/apps/admin_app/test/f3b_capture_staff_product_test.dart`
(new, test-only; `lib/` untouched). Fixture:
`docs/ui/figma/fidelity/fixtures/f3b/staff-level2.json` (same reference +
crop as Level 1, `thresholdSsim` 0.98, `expectedStrings` = the 18 distinct
product strings actually rendered, deny-list
`docs/ui/figma/fidelity/forbidden-terms-admin-product.json`, no key boxes
declared — product layout differs by design, so geometry is informational
only).

Fake data (realistic, role-spanning): four members — `Technician A/B`
(`t***`, `tb***`), `Admin A/B` (`a***`, `ab***`), one DISABLED. No session
is provided, so the account chip is omitted — the product renders
`displayName + workshopName` only when signed in (covered by
`staff_roster_test.dart` "signed-in header chip shows name and workshop
without role").

## 1. Measured result (`compare.mjs`) — gate FAILS on SSIM by design

| Metric | Value |
|---|---|
| SSIM global / threshold | **0.90856** / 0.98 → deficit **0.07144** |
| SSIM worst 64x64 tile | **0.1529** at logical (576, 192, 32x32) — metric-card zone: Figma `BAY UTILIZATION 87.5%` card vs product staff-card row |
| RMSE / MAE (RGB 0–255) | 32.843 / 8.550 |
| dE2000 mean / median / p95 / max | 2.689 / 0 / 9.641 / 85.576 |
| dE2000 > 2 / > 5 / > 10 | 21.74 % / 6.13 % / 4.52 % |
| Text | **18/18 pass**, 0 missing |
| Forbidden terms | **0 matches — pass** |
| Key boxes | none declared — pass (geometry informational) |
| Diff boxes (dE > 5) | 20 |

Product-anchored geometry (`geometry.json`, logical px): header
1248x80 @ (16, 16); first staff card 410.67x96 @ (16, 176).

## 2. Difference map — every Figma element vs slot-sheet row

| # | Figma element (slot sheet) | Product behaviour | Numeric effect |
|---|---|---|---|
| D1 | `LIVE ROSTER` pill (row 48) | Omitted (no live/shift source; O5) | Part of header/chip-zone boxes #4 (16, 104, 82.5x53), #12 (136, 96), #18 (268.5, 102), #19 (347.5, 95.5) |
| D2 | Filter `Active Shift 6` chip (row 48; self-inconsistent 6 vs 5 dots) | Omitted; chips are `All (4) / Technicians (2) / Admins (2)` with client-side counts from `GET /staff` | Same chip-zone boxes as D1; counts verified in rendered strings |
| D3 | Header search `Search VIN, tech, job ticket…` + `Add Staff` 149 px CTA (rows 48–49) | Same slots: `Search` field → existing search; `Create` button → opens the screen-6 sheet | Right-header boxes #1 (1082, 100, 165.5x75.5), #2 (815, 28, 127x56) |
| D4 | User chip `Marcus Vance / Lead Inspector` (All-family row 59) | Omitted in this capture (no session); signed-in product shows account + workshop, never the sample name/role | Part of box #1 zone |
| D5 | Metric cards `Bay Utilization 87.5% / Shift Compliance 100% / EV Specialists 3 Leads` (row 49) | Omitted (no bay/shift/skill source); counts live in the chips only | Worst tile (576, 192, 32x32, 0.1529); boxes #3 (10.5, 288, 75.5x75.5), #5–#10 avatar row below |
| D6 | Card skill rows `EV Certified / Level 4 / Lead Master / OBD-II Specialist / High-voltage ready`, `Logged 6h 12m`, `Bay 02`, `Front Desk`, `Returns 08:00 AM` (row 49) | Same card slots carry initials disc + `displayName` + neutral role + `emailMasked` only; no hours/bays/schedules | Card-row 32x32 glyph boxes #13–#17, #20 (x≈422/801/1180, y≈456/654); deny-list `certif`/`bay`/`lead` = 0 |
| D7 | Availability toggles (row 49) | Omitted (no mutation endpoint) | No switch widgets rendered — verified (same card rows as D6) |
| D8 | Banner `Auto-Shift NFC Badging / Terminal 3 … / Download Roster PDF / Shift Rules` (row 49) | Omitted (no NFC/terminal/roster-export source) | Lower-frame zone matches product background (median dE2000 = 0 there); no banner boxes |
| D9 | All-family: fleet wording (row 58) | 0 occurrences in rendered strings — verified | No effect |
| D10 | All-family: full VIN / plates / full emails / photos / avatars / sample people (row 59) | 0 rendered; references stay out of this screen, emails stay masked (`t***@test.local`), avatar slots are initial discs (TA/TB/AA/AB) | Avatar-slot 56x56 boxes #5–#10 (x≈164/542/921, y≈459/657): Figma photo tiles vs product initials discs |
| D11 | All-family: hardware/BLE/telemetry/NFC wording (row 60) | 0 occurrences — verified | No effect |
| D12 | All-family: scores / `%` / invented counts (row 61) | 0 `%` signs; only real counts 4/2/2 with plain labels — verified | No effect |

New residuals (structural, not slot-sheet rows): N1 — standalone tab, no
96 px icon rail and no shell header (`BAY ACTIVE`, VIN search, sample user
chip); left-column tiles y0 ≈ 0.99 but rail-adjacent tiles y64–128 drop to
0.42–0.65 where the chrome boundary sits. N2 — product cards are 410.67x96
single-row (3-column grid) vs Figma 346.67x190 skill cards; six 56x56 avatar
boxes (#5–#10) are the 6 Figma avatar slots vs 4 product initials discs
(extra two are Figma-only cards 5–6). N3 — box #11 (1208, 24, 32x32, area
2986): right-header avatar/icon zone (Figma user avatar vs product header
trailing edge).

## 3. Not verified

Below-fold/scrolled content; the signed-in account-chip variant (covered by
`staff_roster_test.dart`); reset-password dialog; Arabic/RTL; text scaling
above 1.0x; hover/focus; dark theme (product is light-only); widths other
than 1280; phone/tablet derived grids (covered by unit tests, not captured);
loading/empty/error states; real server data. No pixel-perfect claim is
made — every non-zero SSIM/dE value above is a measured residual.
