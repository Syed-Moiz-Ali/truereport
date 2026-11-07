# F3-0 Screen 8 — Template Builder (Workshop Admin)

- Export folder: `docs/ui/figma-export/Workshop_admin_figma/screens/08_8._Template_Builder`
- Figma node: `1:1882` ("8. Template Builder"), 354 serialized nodes
- Frame (JSON `developerSummary.screen`): **1280×1251.5**, VERTICAL, bg `#FFFFFF`
- PNG: `8._Template_Builder@2x.png` 2592×2515 px (≈1296×1258 @1x; bleed — per O3 use **1280×1251.5** as drawn)
- Prior spec read (not edited): `docs/ui/figma/specs/workshop_admin/08-template-builder.md`
- Viewed PNG as image: yes

## 1. Node-level layout

- Root 1280×1251.5 FIXED/HUG; `Background 1:1883` + `Main 1:1884` 1184 at x=96 (pad 80/40/48/40); `Content 1:1885` 1104×1123.5.
- Top bar `1:1886` 1104×114 (pad-bottom 40, SPACE_BETWEEN): left `V2.4` 28-pill + `STANDARD OPERATING PROCEDURE` + H1 `Template Builder: Comprehensive Inspection` 32/800; right `Preview Flow` 151.9×44 white pill + `Publish Template` 205.2×46 emerald r16.
- Pods `1:1904` 1104×193.5 gap 24 (pad-bottom 48): 4× 258 cards r16 pad 24: Sequence Total / Mandatory Photos / Avg Field Time / Telemetry Link; value 32, label 11-upper, optional 210×6 progress bar.
- Workspace `1:1956` 1104×816 gap 40:
  - Left `1:1957` 404.3: header 50 (`Master Items`, `5 In Catalog`, subtitle) + search pill 404.3×42 r9999 + 5 item cards 404.3×84 gap 16 r16 pad 20 (48 icon tile, title 16/700, meta 13, drag-dots) + `Create Custom Diagnostic Item` 404.3×48.7.
  - Right `1:2062` 659.7 gap 24: header 46 (`Workshop Template`, `(Drag to reorder)`, `Autosave Active` pill) + 3 sequence cards 659.7×128 gap 20 r16 pad 24 (01/02/03 numeral, title 18/700, Active/Automated chip, rule pill, category note, control cluster: icon buttons + trash + drag handle) + drop zone 659.7×168 r16 pad 32 (centered) + QA card 659.7×106 (`Quality Assurance Rule Set` + `ACTIVE POLICY`).
- Shell header/aside same as screens 5–7. Fixed 404.3+40+659.7 columns; no tablet/phone/RTL frame; no scrollbar drawn.

## 2. Components

| Figma pattern | Design-system map |
|---|---|
| Metric pods | No equivalent → new `MetricPod` (or reuse screen-7 card) |
| Master item cards + search pill + category filter | `cards.dart`+`lists.dart` `AppListTile`; `inputs.dart` `AppTextField`; `DropdownButtonFormField` (current) vs Figma pill |
| Sequence cards (numbered) | No equivalent → new `SequenceCard` |
| Drag handles + drop zone | No equivalent — current reorder = `PopupMenuButton` Move up/down/remove (`template_builder_page.dart:210`); A09 allows drag + accessible move buttons → new `ReorderControls` + `DropZone` |
| `Card Controls` composed SVGs (3× ~157×40) | `buttons.dart` icon buttons / menu |
| Active/Automated chips, Autosave pill | `chips.dart` `StatusChip` (states themselves are gaps) |
| QA policy card | `cards.dart` `AppCard` (policy engine gap) |
| EN/AR preview | `overlays.dart` `showAppBottomSheet` (existing `_preview` in `template_builder_page.dart:428`) |

## 3. Assets

- `assets/manifest.json`: **50 assets — 42 individual SVGs + 8 composed** (3× `Card Controls` ~157×40, 3× `Background` 84×40, `Nav` 96×982, `Aside` 96×1182), **0 rasters**. Icons 9–21 px (drag, delete, camera, sliders, sparkle).

## 4. Element → data mapping (EVERY visible string)

Per O7: builder only with existing template rules — approved master items, reorder, drafts, publish, versions, locked indicators; required-photo gates follow master evidence rules; no new capabilities.
Server: `WorkshopTemplateController.java` (`GET/POST /api/v1/workshop/templates`, `GET/POST .../{id}/draft`, `PUT .../draft`, `POST .../publish|retire`, `GET .../versions|preview`); `WorkshopMasterController.java` (`GET /api/v1/workshop/master/categories|items|items/{versionId}` — GET only). App: `template_builder_page.dart`. Model `TemplateItemView`: labelEn/Ar, instructionEn/Ar, versionNo int, resultOptions, severityPolicy, reasonCodes, noteRequirement, evidenceRequirement, minPhotos, equipmentIds, guideImageId.

| Figma element | Mapping |
|---|---|
| `V2.4` | CONFLICT — version is int (`versionNo`); semver must not ship |
| `STANDARD OPERATING PROCEDURE` kicker | New marketing label — DATA GAP (copy) |
| `Template Builder: Comprehensive Inspection` | EXISTS → `TemplateDetail.name` |
| `Preview Flow` | EXISTS (EN/AR bottom-sheet preview `_preview`; "Flow" wording new) |
| `Publish Template` | EXISTS → `POST .../{id}/publish` (after draft save) |
| `SEQUENCE TOTAL 3 of 14 configured` + progress | PARTIAL: `3` = `_selected.length` EXISTS; "of 14" CONTRADICTS 5-catalog/3-cards (self-inconsistent) — no 14 source |
| `MANDATORY PHOTOS 1 checkpoint flagged / Optical AI analysis enabled` | PARTIAL: required-photo gates follow master evidence rules (`evidenceRequirement`/`minPhotos` EXIST); "flagged" aggregation + "Optical AI" = DATA GAP + invented capability |
| `AVG FIELD TIME 12 minutes estimated / Fast Track Eligible` | DATA GAP — invented timing/eligibility |
| `TELEMETRY LINK Laser & OBD / Direct BT calibration on` | DATA GAP — no telemetry/BT/OBD integration (hardware claim) |
| `Master Items / 5 In Catalog / Available Diagnostic Checkpoints` | EXISTS → `GET /workshop/master/items` list/count; wording new |
| `Filter checkpoints by system...` | EXISTS → `GET .../items?search=` + category dropdown |
| Item 1 `Check Brakes & Calipers / Chassis • Wear & Hydraulics` | EXISTS → `PublishedItem.labelEn/categoryLabelEn` (server-owned) |
| Item 2 `Oil Level & Viscosity / Powertrain • Spectro Grade` | PARTIAL: labels exist; `Spectro Grade` invented terminology gap |
| Item 3 `Battery State of Health / Electrical • 12V / High Voltage` | PARTIAL: labels exist; value metadata gap |
| Item 4 `Tread Depth All Axles / Tires • 32nds Measurement` | PARTIAL; invented unit gap |
| Item 5 `Coolant Expansion Tank / Fluids • Boilover PSI` | PARTIAL; invented unit gap |
| `Create Custom Diagnostic Item` | LOCKED-RULE CONFLICT — workshop cannot create master items (Platform Admin-only; `WorkshopMasterController` GET-only) |
| `Workshop Template / Active Inspection Sequence (Drag to reorder) / Autosave Active` | PARTIAL: draft items + reorder EXIST via move buttons; drag/drop + autosave = DATA GAP (explicit save/publish + unsaved-warning required; autosave = state change) |
| Seq 01 `Check Brakes & Calipers / Active / Mandatory Optical Photo / • Chassis Integrity` | PARTIAL: label/category/rules EXIST; per-item `Active` flag + note = gap (locked-indicator subtitle `noteRequirement/evidenceRequirement · lockedByPlatform` is the existing equivalent) |
| Seq 02 `Oil Level & Viscosity / Active / Value Range Input [0.0 – 8.5L] / • Powertrain Module` | DATA GAP — no numeric-range field; invented measurement |
| Seq 03 `Tread Depth All Axles / Automated / Laser Gauge Integration / • Tire Quad-Sensor` | DATA GAP — automated/laser/sensor not in model |
| Drop zone `Drag master checkpoint here... / Or click any catalog item...` | PARTIAL: tap-to-add EXISTS; drag/drop zone new |
| QA `Quality Assurance Rule Set / Enforces ISO-9001... on save / ACTIVE POLICY` | DATA GAP + LOCKED-RULE conflict (ISO certification claim; save-time policy engine doesn't exist; `TEMPLATE_WEAKENS_SAFETY_RULE` surfacing is the existing validation path) |
| Shell bay/search/user | DATA GAP (same shell) |

## 5. States shown / not shown

- Shown: draft w/ 3 selected, 5 masters, autosave "active", Active/Automated states, populated drop zone, active QA policy.
- Not shown: loading (`LoadingSkeleton`), empty catalog/sequence (`EmptyState`), no-result search, error, `TEMPLATE_WEAKENS_SAFETY_RULE`, missing-AR, retired item, read-only published (`readOnlyVersion` + `createDraft`), publish-disabled/success, unsaved warning, drag-over, keyboard reorder, 200% text, RTL/Arabic, phone/tablet.

## 6. Classification

**Matches existing feature**: master catalog browse (approved items only), tap-to-add, explicit move up/down/remove reorder, save draft / publish / retire / versions, locked-by-platform indicators, EN/AR preview, photo-gate rules from master evidence.
**UI work only**: two-column workbench restyle, numbered sequence cards, search pill, drop-zone visuals (wired to existing tap-to-add + move buttons), `Mandatory Optical Photo` pill rendered from `evidenceRequirement`.
**Needs new data or server change** (out of scope): autosave, drag-and-drop DnD, per-item Active/Automated, numeric ranges, telemetry/AI/BT/OBD, QA policy engine, time estimates, sequence-total "of 14".
**Conflicts with locked rule**: custom-item creation, semver, invented measurements/units, ISO-9001 claim, telemetry/AI claims, self-contradicting counts.

## 7. New-component list

Metric pods, numbered sequence cards, reorder control cluster (icon buttons + trash + drag handle), drop zone, `Autosave Active` pill (do not implement — flagged as gap), QA policy card, side-by-side workbench layout. Role selects: none. Tables: none. Drawers: none on this screen (Preview is existing bottom sheet).

## 8. Could not verify

- `Preview Flow` vs existing EN/AR bottom-sheet diff (assumed same).
- Autosave semantics (server draft vs local vs decorative) + conflict behavior.
- Active/Automated ownership (template vs master item).
- Numeric-range authorship/storage; telemetry/AI/BT/OBD roadmap reality.
- Safety-rule violation panel placement; "14 configured" source; Arabic/RTL editor design.
