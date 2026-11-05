# 07. 7. Master Dropdowns & Data Catalogues

- App: Platform Admin
- Figma node: `1:4809`
- Frame: 1280x1024 px (desktop web)
- Export folder: `screens/07_7._Master_Dropdowns_&_Data_Catalogues`
- Sources read: `7._Master_Dropdowns_&_Data_Catalogues.json`, `7._Master_Dropdowns_&_Data_Catalogues@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: high — two-pane catalogue UI, chips, labels, and geometry are explicit.

## 1. Purpose
Manage global taxonomies used by inspections: vehicle makes, defect severities, not-checked reasons, fuel/powertrain types, and fluid specifications, with a global-vs-workshop override switch and catalogue publishing.

## 2. Layout structure
Root `1:4809` vertical, 1280x1024, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:4810` 1024x1024, padding 64/32/192/32.
- `Container` `1:4811` 960x768, gap 32:
  - Header `1:4812` 960x56: title block 367x56 + segmented “Global Standard / Workshop Overrides” 306x40 (active 130x28 white).
  - Content `1:4823` 960x680, no gap:
    - Left catalogue column `1:4824` 299x678, gap 16: header 299x24 (“Catalogues”, “5 Entities”); list `1:4830` 299x494, gap 8: five 299x88 cards (one 110 tall) radius 32; sync card 299x128 radius 32.
    - Right detail card `1:4899` 629x652, radius 48, padding 40, gap 32: header 549x84; quick index 549x36; chip wrap 549x272 (11 chips 48 px tall); footer 549x84.
- `Header` `1:5010` 1024x64 glass; `Aside` `1:5035` 256x1024.

Left column is a master-detail list; right column is the selected catalogue. No scroll; the chip grid wraps 11 values.

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 52 | Meta, labels, inactive |
| `#F4F3F8` | 25 | Chips, icon tiles, segmented track |
| `#1B1B25` | 21 | Titles/ink |
| `#FFFFFF` | 16 | Cards/active pill |
| `#10B981` | 6 | Selected outline? CTA, status dot |
| `#3C4A42` | 5 | Nav |
| `#1A1B1F` | 4 | Active index |
| `#006C49` | 3 | “11 Catalogued” |
| `#10B9811A` | 1 | Sync icon tint |
| `#6FFBBE4D` | 1 | Selected catalogue ring |
| `#F4F3F899` | 1 | Quick index track |
| `#FFFFFF01` | 1 | Transparent |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans`. H1 32/800 LH38 -0.80; catalogue names 16/700 LH22; descriptions 13/400 LH18; selected title 22/700 LH28; “11 Catalogued” 11/700 `#006C49`; chips 16/600 LH24; index 11/600; CTA 12/600; card count “5 Entities” 11/600.

### Radii, shadows, strokes, spacing
- Radii: 32 (catalogue cards/sync card), 48 (detail card), 9999 (chips, segmented, buttons).
- Shadows: cards `0 2 8 .03` + `0 14 40 .04`; chips `0 2 8 .01`; CTA `0 4 12 .20`/`0 10 25 .30`; no borders.
- Strokes: none.
- Spacing: page 64/32/192; pane gap 0; card padding 24; detail padding 40; chip gap ~16/18; section gap 32.

## 4. Components
Flattened export. Patterns: master-detail catalogue list, selected card with emerald ring, global/workshop segmented switch, quick-index pill bar, removable value chips, catalogue publish/revert actions, OEM sync banner.
Mapping: `AppSelectableText`/chips, `Card`/`AppListTile`, `AppButton`, `SectionHeader`, `StatusChip`; no catalogue selector, removable chip group, quick index, or publish-action pattern exists. No `data_table_2`/grid in this screen.

## 5. Assets
36 assets, all individual SVG icons. Icons: logo/nav, search/chrome, catalogue icons (car, clock, slash, fuel, fluid), sync, info, add, close, chevrons.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Eyebrow | PLATFORM DICTIONARIES & TAXONOMIES | No | — |
| Title | System Data Catalogues | — | Current app has no dropdown UI |
| Toggle | Global Standard / Workshop Overrides | No | Workshop overrides are not a product concept |
| Catalogues | 5 Entities | Partly (`GET /master/dropdowns`) | Dropdown list exists |
| Catalogue 1 | Vehicle Makes — Manufacturer master list | Partly | Dropdown can hold values |
| Catalogue 2 | Defect Severities — Grading definitions (P0–P3) | No | Severity is a fixed enum, not a dropdown |
| Catalogue 3 | Not-Checked Reasons — Bypass & exemption tags | Partly (`reasons`) | “Bypass” wording is not a product reason |
| Catalogue 4 | Fuel & Powertrain Types — BEV, Hybrid, PHEV, ICE | Partly (dropdown) | Values not modelled beyond label |
| Catalogue 5 | Fluid Specifications — Viscosities, DOT ratings | No | No fluid metadata |
| Sync banner | OEM Sync Pipeline — “pushed down to offline mobile workshop pads every 4 hours.” | No | No scheduled push |
| Detail title | Vehicle Makes (Active) · 11 Catalogued | Partly | — |
| Search | e.g. Genesis | Partly | Client-side search only |
| Add | Add Make | Yes (`POST /dropdowns/{id}/values`) | UI not implemented |
| Quick index | All, A-F, G-M, N-S, T-Z | No | Alphabetical server filter absent |
| Values | Toyota, Nissan, Porsche, Ford, Renault, BMW, Mercedes-Benz, Audi, Tesla, Volvo, Hyundai | Partly (dropdown values) | Clearly sample; removable chips |
| Footer copy | “Changes automatically sync to active work orders” | No | Conflicts with version immutability |
| Actions | Revert to OEM Preset, Publish Catalogue | No | No bulk publish or OEM preset |

No customer PII/VIN/plate. Vehicle makes are public taxonomy values.

## 7. States shown / not shown
Shown: populated Vehicle Makes catalogue, 11 chips, global mode, active selection. Not shown: empty catalogue, loading/error, add/edit/remove chip flows, duplicate value, workshop override content, publish confirmation, unsaved changes, sync failure, long values, RTL, keyboard, 200% text, small screens.

## 8. Implied interactions
Select a catalogue; switch global/workshop mode; search/filter values; add value; remove value chip; quick-index filter; revert; publish; header search/nav.

## 9. Correspondence to current product
Partial/new. Existing data: `Dropdown`/`DropdownValue` models and `GET/POST /api/v1/platform/master/dropdowns`, `POST /dropdowns/{id}/values` (`MasterContentController`); `admin_api.dart` has `dropdowns()`, `createDropdown()`, `addDropdownValue()`, but `admin_app` exposes **no dropdown UI** (only categories/items/guide images). Reasons (`/master/reasons`) and equipment (`/master/equipment`) exist separately; severities are fixed enums (`NO_ISSUE_OBSERVED`, `ATTENTION_RECOMMENDED`, `DEFECT_FOUND`, `NOT_CHECKED`, `NOT_APPLICABLE`, `COULD_NOT_VERIFY`) and severity codes are `MINOR/MODERATE/MAJOR/SAFETY_CRITICAL`. Bulk publish, overrides, OEM presets, sync, and quick-index need new API/model work.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “no single unexplained condition score” / severity model. Evidence: “Defect Severities — Grading definitions (P0–P3)” (`1:4850`–`1:4852`) contradicts the fixed four-level severity model and introduces an unexplained P0–P3 grading scale.
- Rule: “no manager role, review queue, customer portal, payments.” Evidence: “Workshop Overrides” (`1:4822`) and “Revert to OEM Preset” create a governance layer; not a manager role per se, but an override authority not in the approved model.
- Rule: “A Workshop Admin may not change what an item means or reduce a platform safety requirement.” Evidence: the “Workshop Overrides” mode and “Changes automatically sync to active work orders” imply workshop-level changes to global taxonomy and live propagation, contrary to master-library §4 and version pinning.
- Rule: “Finalized findings/evidence/reports immutable.” Evidence: “Changes automatically sync to active work orders” (`1:5004`) and “pushed down … every 4 hours” would mutate in-progress work orders; reports must keep pinned snapshots.
- Rule: “no certification/‘verified by’/compliance claims.” Evidence: “OEM Sync Pipeline” and “OEM Preset” imply OEM-authoritative data with no source/licence.
- Rule: “Never invent … measurements/results.” Evidence: “5 Entities”, “11 Catalogued”, “every 4 hours”, “P0–P3”, “DOT ratings”.
- Rule: “no business logic/API/server change.” Evidence: publish/revert/override/sync/quick-index have no endpoints; only per-value add exists.
- Rule: “no unsafe bypass.” Evidence: “Not-Checked Reasons — Bypass & exemption tags” (`1:4862`–`1:4864`) normalises bypassing checks, which the product treats as a safety/limitation event with explicit reasons.

## 11. Open questions / could not verify
- Are severity grades editable at all? Product currently fixes them.
- What is a “Workshop Override” — local labels, local values, or local safety rules? The last would be forbidden.
- Is “Publish Catalogue” a bulk publish of all values, or per-dropdown? No endpoint exists.
- Where does “Revert to OEM Preset” data come from? No OEM catalogue is stored.
- Should vehicle makes be seeded/maintained, or left to “Other” + free text?
- No empty/error/loading/publish/RTL states.
