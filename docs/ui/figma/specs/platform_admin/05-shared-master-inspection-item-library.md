# 05. 5. Shared Master Inspection-Item Library

- App: Platform Admin
- Figma node: `1:4214`
- Frame: 1280x1360 px (desktop web)
- Export folder: `screens/05_5._Shared_Master_Inspection-Item_Library`
- Sources read: `5._Shared_Master_Inspection-Item_Library.json`, `5._Shared_Master_Inspection-Item_Library@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: high — list cards, codes, chips, and geometry are explicit and readable.

## 1. Purpose
Global catalogue of canonical inspection items, browsable by category, with item metadata chips, edit actions, and a master-sync policy footer.

## 2. Layout structure
Root `1:4214` vertical, 1280x1360, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:4215` 1024x1360, padding 64/32/32/32.
- `Container` `1:4216` 960x1264, gap 32:
  - Header `1:4217` 960x112: title block 471x112 + actions 376x46 (Rules Matrix 152x42, + New Master Item 209x46).
  - Filter bar `1:4237` 960x92, padding-top 8, gap 16: segmented category filter 742x46 (5 segments, active 141x38) + sync count 219x22.
  - Item list `1:4254` 960x764, gap 24: five cards — 960x164 (first) then 960x128 x3, 960x120. Each radius 16, padding 24, horizontal: 56 px icon, text column, right chip column, Edit 74x38 + more 40x40.
  - `Master Fleet Sync Policy` `1:4441` 960x112, radius 16, padding 32: icon 48, copy, “Instant Push” toggle 48x28.
- `Header` `1:4456` 1024x64 glass; `Aside` `1:4481` 256x800.

Cards are 960 wide and full-bleed inside the 960 container; list is vertically stacked, page is 1360 tall. No responsive variant.

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 44 | Meta, descriptions, inactive tabs |
| `#F4F3F8` | 38 | Card icon tiles, chips, segmented track |
| `#1A1B1F` | 20 | Titles/ink |
| `#006C49` | 17 | Mandatory/Standard/Structural badges, Edit |
| `#FFFFFF` | 15 | Cards |
| `#1B1B25` | 13 | Headings/titles |
| `#10B981` | 10 | CTA, sync toggle |
| `#3C4A42` | 5 | Nav/meta |
| `#10B9811A` | 1 | Sync icon tint |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans` plus `Liberation Mono` 600 for item codes (`1:4264` etc., 5 occurrences). H1 32/800 LH38; item title 18/700 LH24 (LH24/-0.45 for some); description 13/400 LH18; code 11/600; status badges 11/600 with `#006C49`; category/equipment chips 12/600 LH16; sync title 16/700; footnote 13/400.

### Radii, shadows, strokes, spacing
- Radii: item cards 16; sync card 16; segmented control/buttons/chips 9999; icon tiles 9999.
- Shadows: cards `0 2 6 .02` + `0 14 40 .04`; chips `0 2 8 .02`; toggle/CTA emerald `0 2 8 .06`; no borders.
- Strokes: none.
- Spacing: card padding 24; card gap 24; icon-to-text 24; chip gaps 16/6; page gutters 32/64.

## 4. Components
Flattened export. Patterns: page header with secondary + primary CTAs; segmented category filter; synced-count pill; item card with icon, code+status line, title, description, metadata chips, Edit and overflow; sync-policy banner with toggle.
Mapping: `SectionHeader`, `AppButton`, `AppSelectableText` (filter chips), `StatusChip`, `AppListTile`/`Card` (but not this multi-column card), `Switch`. No item-card, metadata-chip group, rules-matrix, or sync-policy component exists.

## 5. Assets
35 assets, all individual SVG icons (no raster/composed/photo). Icons: logo/nav, search/chrome, category icons (brake, engine, tire, EV bolt, chassis), equipment chips, edit/more, sync, plus “Rules Matrix” icon.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Eyebrow | ACTIVE CANONICAL REPO | No | “repo” metaphor |
| Title | Global Master Library | — | Existing tab title is “Master Content” |
| Subtitle | “Centrally governed diagnostic checkpoints deployed across all workshop nodes” | Partly | Master content exists |
| CTA | Rules Matrix | No | No rules-matrix screen/endpoint |
| CTA | + New Master Item | Yes (`POST /master/items`) | Exists |
| Category filter | All Categories, Brakes & Calipers, Powertrain, Tires & Axles, Chassis Integrity | Partly (`category`) | Categories exist; these exact labels are sample |
| Sync counter | SYNCED: 48 Workshop Clusters | No | No cluster count |
| Item 1 | CHK-BRK-001 · Mandatory · “Brake Pad Thickness & Disc Runout” · “Micrometer disc thickness variance check and rotor…” | Partly (`stableCode`, labels, category) | “Mandatory” status not a field |
| Item 2 | CHK-PWR-014 · Standard · “Engine Oil Level & Viscosity Grade” · “Spectrometric optical degradation check…” | Partly | “Standard” not a field |
| Item 3 | CHK-TIR-004 · Mandatory · “Tread Depth All Axles” | Partly | — |
| Item 4 | CHK-EV-082 · High Voltage Cert · “High-Voltage Battery Insulation” · “1000V DC megohmmeter chassis isolation…” | Partly | “High Voltage Cert” not a field |
| Item 5 | CHK-CHS-019 · Structural · “Chassis Subframe Torque & Bushing Play” | Partly | “Structural” not a field |
| Metadata chips | Category: Brakes/Powertrain/Tires & Axles/Chassis Integrity | Yes (category) | — |
| Equipment chips | Laser Caliper Supported, OBD Telemetry Live, Fluid Spec Match, Digital Depth Gauge, Safety Gate Interlock, Acoustic Play Sensor | Partly (`equipmentIds`) | Equipment names/codes exist; these readings/features do not |
| Requirement chips | Mandatory Photo, Dual Tech Signoff | Partly (`evidenceRequirement`) | “Dual Tech Signoff” is not a field |
| Actions | Edit, overflow menu | Yes (edit) | Edit opens item form; overflow unknown |
| Sync policy | “Master Fleet Sync Policy” / “Next synchronized release pushes to edge terminals automatically at 02:00 UTC” / “Instant Push” | No | No scheduled push or edge terminals |
| Header search | “Search platform assets, specs, workshop nodes...” | No | Global search absent |

No customer PII/VIN/plate/report findings.

## 7. States shown / not shown
Shown: populated list, active category filter, all statuses as static badges, sync toggle on, enabled CTAs. Not shown: empty library/category, loading/skeleton, error/retry, search/no-results, draft vs published distinction, retired items, pagination/virtualization, long translations, RTL, keyboard focus, 200% text, sync failure.

## 8. Implied interactions
Switch category; open Rules Matrix; create item; edit item; open overflow actions; toggle instant push; (header) search. No bulk selection or reordering.

## 9. Correspondence to current product
Partial. Existing: `master_content_tab.dart` lists categories and items with search, category dropdown, status chips; `item_form_page.dart` for create/edit; `admin_api.dart` `items()/itemDetail()/createItem()/createDraft()/publish()/retireItem()`; `MasterContentController` `/platform/master/categories` and `/items`. `ItemSummary` exposes `stableCode`, `labelEn`, `labelAr`, `categoryLabelEn`, `currentVersion`, `status`, `sampleData`; `ItemVersion` exposes result options, requirements, equipment IDs, guide image, etc.
Missing: card layout with metadata badge groups, item “type” badges (Mandatory/Standard/Structural/High Voltage Cert), “Rules Matrix”, sync policy/“Instant Push”, cluster counts, and a global search. Badge data would require item-rule/model additions; sync is new server behaviour.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “no manager role, review queue…” Evidence: “Dual Tech Signoff” (`1:4396`) introduces a two-person approval gate; “Mandatory/Standard/Structural/High Voltage Cert” classify items but have no product definition.
- Rule: “no certification/‘verified by’/compliance claims.” Evidence: “High Voltage Cert” status (`1:4378`); “1000V DC megohmmeter” reads as a calibration/spec claim; “SYNCED: 48 Workshop Clusters” implies a governed network.
- Rule: “Never invent versions/licences/measurements/results.” Evidence: item codes `CHK-BRK-001` etc. look real but are sample; “1000V DC”, “micrometer”, “spectrometric optical degradation”, “acoustic play sensor”, “48 Workshop Clusters”, “18 Hubs” (screen 6) are unsourced.
- Rule: “Finalized findings/evidence/reports immutable.” Evidence: the page offers direct “Edit” on canonical items with no visible version/draft/publish affordance (`1:4287` etc.), and “Master Fleet Sync Policy / Instant Push” implies live propagation; master edits must create a new draft version, never edit in place.
- Rule: “no business logic/API/server change.” Evidence: “Rules Matrix”, per-category sync counts, scheduled 02:00 UTC edge push, and “Instant Push” have no endpoints/worker in the server.
- Rule: “no certification claims”: “OBD Telemetry Live” and “Laser Caliper Supported” imply calibrated hardware integration.
- Rule: “tokens from central tokens.” Evidence: 16/32 radii, `#10B981`, `#006C49`, lavender surfaces, and Liberation Mono are not in the current token set.

## 11. Open questions / could not verify
- Is “Mandatory/Standard/Structural/High Voltage Cert” a severity, an applicability class, or decoration? No model field exists.
- Should the master list show draft/published/retired versions, and how are they distinguished?
- Is “Rules Matrix” a real editor or the existing item rules form in another presentation?
- Does “Instant Push” change published items in place? That would violate version immutability.
- What are “Workshop Clusters” vs the actual workshop count?
- No empty/error/loading/RTL/overflow states were exported.
