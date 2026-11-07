# F3-B templates Level 2 — product-vs-Figma method (slot replacements by design)

Screen 7 "Workshop Template List", Figma node `1:1307`, frame **1280 x 1586**,
reference `docs/ui/figma-export/Workshop_admin_figma/screens/06_7._Workshop_Template_List/7._Workshop_Template_List@2x.png`
(1029174 bytes), crop **x=32, y=0, w=2560, h=3172** (same opaque-frame box as
the Level 1 fixture). Render is the REAL product `TemplatesTab`
(`client/apps/admin_app/lib/src/pages/templates_tab.dart`) pumped standalone
at 1280 logical px wide x the Figma frame height (1586), DPR 2, top-of-scroll,
`TextScaler.noScaling`, bundled Plus Jakarta Sans + MaterialIcons,
`debugDisableShadows = false` during capture and restored after. Compared grid
2560 x 3172 — 1:1, no resample stretch.

Capture: `client/apps/admin_app/test/f3b_capture_templates_product_test.dart`
(new, test-only; `lib/` untouched). Fixture:
`docs/ui/figma/fidelity/fixtures/f3b/templates-level2.json` (same reference +
crop as Level 1, `thresholdSsim` 0.98, `expectedStrings` = the 25 distinct
product strings actually rendered, deny-list
`docs/ui/figma/fidelity/forbidden-terms-admin-product.json`, no key boxes
declared — product layout differs by design, so geometry is informational
only).

Fake data (same approach as `test/template_list_test.dart`, inline minimal
fake): three templates (`PUBLISHED`/`DRAFT`/`RETIRED`, integer versions
v2/v1/v3, 110 + 24 + 45 = 179 checkpoints). One deliberate rename vs the unit
test: `Fleet check` → `Highway check` — the admin deny-list blocks the
whole-word term `fleet` (slot-sheet All-family fleet row: fleet wording never
ships), and the first capture tripped it (`fleet` matched 1x), so the fake
uses neutral user data. No `updatedAt` values (empty, as in the unit test), so
no `Updated …` line renders.

## 1. Measured result (`compare.mjs`) — gate FAILS on SSIM by design

| Metric | Value |
|---|---|
| SSIM global / threshold | **0.88902** / 0.98 → deficit **0.09098** |
| SSIM worst 64x64 tile | **0.23688** (card requirement/footer zone) |
| RMSE / MAE (RGB 0–255) | 39.509 / 10.998 |
| dE2000 mean / median / p95 / max | 3.402 / 0 / 24.86 / 85.576 |
| dE2000 > 2 / > 5 / > 10 | 21.79 % / 7.94 % / 6.99 % |
| Text | **25/25 pass**, 0 missing |
| Forbidden terms | **0 matches — pass** |
| Key boxes | none declared — pass (geometry informational) |
| Diff boxes (dE > 5) | 20 |

Product-anchored geometry (`geometry.json`, logical px): header
1248x80 @ (16, 16); metric 1248x104 @ (16, 112); first template card
408x252 @ (16, 292).

## 2. Difference map — every Figma element vs slot-sheet row

| # | Figma element (slot sheet) | Product behaviour | Numeric effect |
|---|---|---|---|
| D1 | `5 Active Blueprints / 42 Bays Bound` pill + `+ New Template` CTA (row 51) | No bay entity (O4/O7); neutral `New template` button only, no blueprint/bay count | Top-right zone boxes (1041, 93.5, 207x76.5, area 55328) + (828.5, 28, 175x57.5, area 37437) |
| D2 | KPI `AVG. COMPLETION 14.2 min`, `COMPLIANCE RATE 99.4%`, `PROTOCOL AUDIT` (row 51) | Single real metric `Total checkpoints 179` (client-side ΣitemCount); invented timings/compliance/audit omitted | Figma KPI-zone boxes (410, 228, 114x48), (880/40/460, 464, 74.5x56 x3, area ~14066 each), (16, 226, 82x50); product metric is 1248x104 vs Figma 4x258-wide cards |
| D3 | Filters `Fleet Mandatory / High-Voltage EV / Quick Lane` (row 51) | Real status chips `All (3) / Published (1) / Draft (1) / Retired (1)` derived client-side; custom tags are a data gap | Filter-bar boxes (10.5, 288, 77.5x76, area 19482), (244, 326, 107.5x28), (664, 326, 79.5x28) |
| D4 | `Layout:` grid/list toggle (row 51) | Same slot, real `Grid / List` segmented control (grid default, list = `AppDataTable`) | Glyph-level only; no large box |
| D5 | Cards: `100-Point / Version 2.0 • 110`, `Version 1.4 • 24`, `Version 3.1 • 45`, `Version 1.8 • 80`, `Version 2.2 • 35` + `Fleet Default` tag (row 52) | Three real cards: name · serviceType tag · integer `vN · N items selected` · status chip (`110+24+45=179` consistent); semver never rendered (int `versionNo` only) | Version-line boxes (353, 503, 97.5x22.5), (734, 503.5, 95x21.5), (1117.5, 503.5, 90.5x21.5); product card 408x252 vs Figma 346.67-wide cards |
| D6 | Per-card descriptions, `Mandatory Photo Gates 8 points`, `Target Cycle Time 12 mins`, `Hazmat PPE Mandatory Class 00`, `Asset Tagging Req`, `Digital Caliper Sync BLE Ready` (row 52) | Omitted — descriptions/photo-gate/cycle/PPE/bay fields are data gaps; tag slot carries the real `serviceType` only | Card requirement-zone boxes (1101, 748, 147x56, area 30223), (723.5/345, 828, 112x60.5 x2), (345/723.5, ~1302, 111.5/112x60.5 x2), (1102.5, 828.5, 111.5x61) |
| D7 | Card footers `Updated 2d/1w/4h/3d/5d ago + Edit` (row 52) | Footer keeps real `Edit` → new draft/version; `Updated …` line renders only when `updatedAt` parses (empty in this capture) | Same card-row boxes as D6 |
| D8 | `+ Create Custom Protocol` card + `Open Template Architect` (row 52) | Dashed `New template` tile running the existing create flow (dialog + POST + builder); thresholds/triggers are data gaps | Lower-grid zone (same row-2 boxes as D6) |
| D9 | Footnote `Strict Validation Lock … Master Inspector sign-off … Export Schemas (JSON) … Version Audit Log` (row 52) | Neutral `Locked by platform` + `Version history` (opens the builder hosting the versions list); sign-off/export claims omitted (O6 + data gap) | Bottom-zone tiles near SSIM floor (worst tile 0.23688 in this zone) |
| D10 | `BAY ACTIVE Shop Floor #04` pill + 96 px icon rail + search hint `Search VIN, tech, job ticket…` + user chip `Marcus Vance / Lead Inspector` (All rows) | Standalone capture: no rail/shell; search slot is `Search`, no bay pill, no sample user (session chip only when signed in) | Left-column/box (1208, 24, 32x32, area 2986) header-trailing zone; title-glyph boxes absorbed in D1 |
| D11 | All-family: fleet wording | 0 occurrences — verified (`Highway check` rename; deny-list `fleet` 0 matches) | No effect |
| D12 | All-family: full VIN / plates / emails / photos / avatars / sample people | 0 rendered (references stay template names; no thumbs; no sample names) — verified | No effect |
| D13 | All-family: hardware/BLE/telemetry wording | 0 occurrences — verified | No effect |
| D14 | All-family: scores / `%` / invented counts | 0 `%` signs; only real integer counts (179 + chip/card counts) with plain labels — verified | No effect |

New residuals (structural, not slot-sheet rows): N1 — standalone tab, no
96 px rail and no tab bar (left column tiles ~1.0 where empty, header zone
differs). N2 — product KPI is one full-width card (1248x104), not four
258-wide Figma cards. N3 — product cards are 408-wide grid cells in a
1248-wide column, not 346.67-wide Figma cards. N4 — thin card-edge strips
where product card edges meet flat Figma background (the 74.5x56 and
112x60.5 boxes above).

## 3. Not verified

Below-fold/scrolled content; the `updatedAt` date-line variant (empty in this
fake — covered by `templatesUpdatedOn` unit path); create-dialog payload and
builder navigation (covered by `template_list_test.dart`); list-view columns
(grid/List toggle covered by unit tests, not captured); signed-in user chip;
Arabic/RTL; text scaling above 1.0x; hover/focus; dark theme (product is
light-only); widths other than 1280; loading/error/empty states (empty list =
`EmptyState` + create action); real server data. No pixel-perfect claim is
made — every non-zero SSIM/dE value above is a measured residual.
