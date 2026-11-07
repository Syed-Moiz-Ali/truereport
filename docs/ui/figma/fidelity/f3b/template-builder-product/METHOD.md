# F3-B builder Level 2 — product-vs-Figma method (slot replacements by design)

Screen 8 "Template Builder", Figma node `1:1882`, frame **1280 x 1251.5**,
reference `docs/ui/figma-export/Workshop_admin_figma/screens/08_8._Template_Builder/8._Template_Builder@2x.png`
(821690 bytes), crop **x=32, y=0, w=2560, h=2503** (same opaque-frame box as
the Level 1 fixture). Render is the REAL product `TemplateBuilderPage`
(`client/apps/admin_app/lib/src/pages/template_builder_page.dart`) pumped
standalone at 1280 logical px wide x the Figma frame height (1251.5), DPR 2,
top-of-scroll, `TextScaler.noScaling`, bundled Plus Jakarta Sans +
MaterialIcons, `debugDisableShadows = false` during capture and restored
after. Compared grid 2560 x 2503 — 1:1, no resample stretch.

Capture: `client/apps/admin_app/test/f3b_capture_builder_product_test.dart`
(new, test-only; `lib/` untouched). Fixture:
`docs/ui/figma/fidelity/fixtures/f3b/builder-level2.json` (same reference +
crop as Level 1, `thresholdSsim` 0.98, `expectedStrings` = the 33 distinct
product strings actually rendered, deny-list
`docs/ui/figma/fidelity/forbidden-terms-admin-product.json`, no key boxes
declared — product layout differs by design, so geometry is informational
only).

Fake data (same approach as `test/template_builder_test.dart`, inline minimal
fake): two workshop categories, five published master items, a draft with
three sequence items (`mv-brake/mv-oil/mv-battery`, sortOrder 0/1/2) plus one
published version (`v1`, 3 items). No `updatedAt`-style Figma copy is faked;
the `3 items selected · 2026-11-03T10:00:00` version line renders the real
`publishedAt` passthrough from the fake.

## 1. Measured result (`compare.mjs`) — gate FAILS on SSIM by design

| Metric | Value |
|---|---|
| SSIM global / threshold | **0.85681** / 0.98 → deficit **0.12319** |
| SSIM worst 64x64 tile | **0.27036** (sequence-card / drop-zone column) |
| RMSE / MAE (RGB 0–255) | 41.352 / 13.03 |
| dE2000 mean / median / p95 / max | 4.483 / 0.997 / 19.993 / 86.617 |
| dE2000 > 2 / > 5 / > 10 | 46.43 % / 6.67 % / 6.07 % |
| Text | **33/33 pass**, 0 missing |
| Forbidden terms | **0 matches — pass** |
| Key boxes | none declared — pass (geometry informational) |
| Diff boxes (dE > 5) | 20 |

Product-anchored geometry (`geometry.json`, logical px): title
~205.7x22 @ (16, 72); dropzone ~759.2x102 @ (504.8, 874); first sequence
remove control 48x48 @ (1176, 558).

## 2. Difference map — every Figma element vs slot-sheet row

| # | Figma element (slot sheet, row 53 + All rows) | Product behaviour | Numeric effect |
|---|---|---|---|
| D1 | Top bar `V2.4` pill + `STANDARD OPERATING PROCEDURE` kicker + `Preview Flow` + `Publish Template` CTA | Real header: template name + integer `v2` pill (semver banned) + tonal `Preview` (existing EN/AR sheet) + `Publish template` (save-then-publish); SOP kicker omitted | Top-bar CTA zone box (929.5, 72, 334.5x88, area 74918 — largest box) |
| D2 | Pods `SEQUENCE TOTAL 3 of 14`, `MANDATORY PHOTOS 1`, `AVG FIELD TIME 12 min`, `TELEMETRY LINK Laser & OBD` | Entire pod row omitted — `of 14`/AI/timing/telemetry/BT/OBD claims are data gaps + conflicts; no `WorkshopMetric` renders (`findsNothing` in unit tests) | Pod-zone boxes (10.5, 277.5, 82x91.5, area 22668), (160, 307, 59x6), (282.5/200/336/448.5/477.5/171, 123.5–130, ~19–27x18–25 x6) |
| D3 | Catalog items `Check Brakes & Calipers / Oil Level & Viscosity / Battery State of Health / Tread Depth All Axles / Coolant Expansion Tank` + system meta (`Wear & Hydraulics`, `Spectro Grade`, `32nds`, `Boilover PSI`) | Five real master items (`Brake pad wear check`, `Engine oil level`, `Battery health check`, `Coolant level check`, `Wiper blade check`) with `category · v1` meta; measurement-grade meta omitted | Catalog text-zone boxes (1008/1149.5/1170.5/1093, ~256, ~19–31.5x24–25), (670.5, 695.5, 38x16.5); text check passes on product copy |
| D4 | `Create Custom Diagnostic Item` | Omitted — master catalogue is platform GET-only (`WorkshopMasterController` GET-only); workshop cannot create master items | Part of left-column residual (no separate box; catalog panel is shorter) |
| D5 | Sequence cards `01/02/03` with `Active / Automated` pills, `Value Range Input [0.0-8.5L]`, `Laser Gauge Integration`, `Tire Quad-Sensor`, category notes | Three real numbered cards with locked-rule pills `REQUIRED/REQUIRED · Locked by platform` (from `evidenceRequirement/minPhotos`), `category · v1` chips, instruction rule notes, and move up/down/remove + drag-handle controls | Rule-pill text boxes (842, 632.5, 67x18, area 4561), (879.5, 484.5, 66.5x18, area 4539), (652.5, 780, 58.5x17) |
| D6 | Drop zone `Drag master checkpoint here to append to flow / Or click any catalog item…` | Real `WorkshopDropZone`: `Drop checkpoint here / Add items`, tap-to-add wired to the existing add flow (drag visuals only) | Drop-zone box (897, 949.5, 23x22); dropzone geometry 759.2x102 vs Figma 659.67x168 |
| D7 | QA card `Enforces ISO-9001 … / ACTIVE POLICY` | Omitted — QA/ISO policy engine is a data gap + locked-rule conflict | Lower-column residual (same zone as D6 box) |
| D8 | `Autosave Active` pill | Omitted — never rendered (banned copy; unit test asserts `autosave` absent) | No box (absent slot) |
| D9 | Product-only additions: `Template details` form (name/description/service/vehicle fields), `Master items · 5`, category filter, `Template sequence / 3 items selected`, `Version history` + `v1 · Published` | Existing features preserved (edit fields, search + category filter, tap-to-add, reorder, save/publish/retire, versions → `TemplateVersionPage`); below-fold at this height | Version-row text included in expectedStrings; sequence header boxes (1008, 256, 31.5x24.5) |
| D10 | All-family: fleet wording | 0 occurrences — verified | No effect |
| D11 | All-family: full VIN / plates / emails / photos / avatars / sample people | 0 rendered (labels stay master-item copy; no thumbs; no sample names) — verified | No effect |
| D12 | All-family: hardware/BLE/telemetry (`Laser & OBD`, `Direct BT`, optical AI, custom, ranges, `of 14`, autosave, ISO, `32nds`, `Boilover PSI`, `Quad-Sensor`, `Spectro`) | 0 occurrences — verified via strings + unit-test banned list | No effect |
| D13 | All-family: scores / `%` / invented counts / semver | 0 `%` signs; integer counts only (`Master items · 5`, `3 items selected`); versions are ints (`v2`, `v1`), never `V2.4` — verified | No effect |

New residuals (structural, not slot-sheet rows): N1 — standalone page, no
96 px rail and no workshop shell (header zone differs). N2 — product has no
metric-pod row at all, so the whole Figma pod band (y ~194–337) diffs. N3 —
product catalog cards are `AppListTile` rows, not 404.33x84 Figma item cards.
N4 — thin control-edge strips where product sequence-card controls meet flat
Figma card background (the ≤38x25 boxes above). N5 — right-header zone box
(1201, 23, 39x33, area 3227): Figma bay-pill/avatar vs product `AppBar`
actions (save/publish/retire icons).

## 3. Not verified

Below-fold/scrolled content (template-details form is at top in product but
below the Figma fold mapping; version rows need scrolling — covered by
`template_builder_test.dart` scroll + tap tests); save/publish/retire flows,
create-draft, EN/AR preview sheet, keyboard-only reorder, drag-reorder
gesture (all covered by unit tests, not captured); Arabic/RTL; text scaling
above 1.0x; hover/focus; dark theme (product is light-only); widths other
than 1280; loading/error states; real server data. No pixel-perfect claim is
made — every non-zero SSIM/dE value above is a measured residual.
