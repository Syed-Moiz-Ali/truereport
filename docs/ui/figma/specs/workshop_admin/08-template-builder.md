# 08. Template Builder

- App: Workshop Admin
- Figma node: `1:1882`
- Frame: 1280x1251.5 px (desktop web, >=1200 per `AppBreakpoints.desktop`)
- Export folder: `screens/08_8._Template_Builder`
- Sources read: `8._Template_Builder.json`, `8._Template_Builder@2x.png`, `assets/manifest.json`
- Export-order note: package index **08** equals Figma screen **8**. The inversion is at package index **07** = screen **6** and package index **06** = screen **7**; this file is otherwise aligned.
- Confidence: medium. Geometry and visual tokens are high confidence; product correspondence is medium because several visible concepts (custom items, autosave, telemetry, AI, ISO validation, numeric ranges) do not exist in the current model and would require server changes.

## 1. Purpose
A two-column template authoring workbench: browse approved master checkpoints on the left, compose an ordered workshop template on the right, monitor four summary pods, preview the sequence and publish an immutable template version.

## 2. Layout structure
Root is a fixed 1280x1251.5 `VERTICAL` frame (`FIXED/HUG`), white.

- `Background` (`1:1883`) fills width with 96 left padding for the rail.
- `Main` (`1:1884`) 1184 wide at x=96, padding 80/40/48/40.
- Content (`1:1885`) 1104x1123.5, vertical sections.
- `Top Bar / Meta Actions` (`1:1886`) 1104x114, `HORIZONTAL`, `SPACE_BETWEEN`, bottom padding 40. Left: 28px `V2.4` pill, `STANDARD OPERATING PROCEDURE` label, H1 `Template Builder: Comprehensive Inspection` at 32/38. Right: `Preview Flow` (151.9x44, white pill) and `Publish Template` (205.2x46, emerald, radius 16).
- Metric pods (`1:1904`) 1104x193.5, `HORIZONTAL` gap 24, bottom padding 48: four cards 258x143/145.5/142/142, radius 16, padding 24, value 32/38, label 11/14 uppercase, optional 210x6 progress bar.
- Split workspace (`1:1956`) 1104x816, `HORIZONTAL` gap 40:
  - Left `LEFT COLUMN: Master Items Library` (`1:1957`) fixed 404.3 wide, `VERTICAL` gap 24. Header 50; search/filter pill 404.3x42 (radius 9999); five item cards 404.3x84, 16 gap, radius 16, padding 20; `Create Custom Diagnostic Item` button 404.3x48.7.
  - Right `RIGHT COLUMN: Workshop Template Flow Sequence` (`1:2062`) fixed 659.7 wide, `VERTICAL` gap 24. Header 46 (`Workshop Template`, subtitle `(Drag to reorder)`, `Autosave Active` pill); three sequence cards 659.7x128, 20 gap, radius 16, padding 24; drop zone 659.7x168, radius 16, padding 32; QA helper card 659.7x106.
- Shell `Header` (`1:2194`) 1184x80 overlay: `BAY ACTIVE · Shop Floor #04`, search pill, user identity/avatar.
- `Aside` (`1:2217`) 96x1182, active Settings tile; nav 96x982.
- Scroll: the frame grows to 1251.5; no scrollbar is drawn. The right column is 816 high and the page content ends at 1123.5.
- Responsiveness: only fixed 1280 desktop. The two fixed columns (404.3 + 40 + 659.7) cannot collapse; no tablet/phone composition. No RTL/Arabic frame.

## 3. Visual tokens observed
### Colours (exact hex, usage, approx count)
| Hex | Usage | Count |
|---|---|---:|
| `#5E5D69` | Secondary text, labels, icons, inactive controls | 57 |
| `#F4F3F8` | Tonal chips, icon tiles, search field, drop-zone surfaces | 30 |
| `#FFFFFF` | Cards, sequence cards, inputs | 26 |
| `#1A1B1F` | Primary text, values | 24 |
| `#10B981` | Primary CTA, progress, active icons, dots | 12 |
| `#006C49` | Positive/active icons, small text | 11 |
| `#3C4A42` | Item metadata text | 6 |
| `#BBCABF` | Metadata separators | 5 |
| `#002113` | `Active` chip text | 2 |
| `#6FFBBE66` | `Active` chip background | 2 |
| `#EEEDF3` | `Automated` chip background | 2 |
| `#B91A24` | Mandatory-photo warning icon | 1 |
| `#FFFFFFE5` | Sticky header tint | 1 |

White on `#10B981` is about 2.54:1; `Publish Template` and the active nav tile rely on it. `#10B981` as text/icon on white is also 2.54:1, below the 3:1 non-text threshold.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)
All `Plus Jakarta Sans`; no Arabic family or RTL text.

| Role | Weight | Size/line | Tracking | Usage |
|---|---|---|---|---|
| H1 | 800 | 32/38 | -0.80 | Builder title, metric values |
| H2 | 700 | 22/28 | -0.44 | `Master Items`, `Workshop Template` |
| H3 | 700 | 18/24 | -0.27 | Sequence card titles |
| Item title | 700 | 16/22 | -0.16 | Master item labels |
| Body | 400 | 13/18 | 0 | Metadata, helper copy |
| Label | 600 | 11/14 | +0.44 to +1.10 | Uppercase pod labels, chips |
| Micro | 600 | 12/16 | +0.24 | Buttons, `Autosave Active` |

All alignment is left except centered drop-zone/help copy and button labels. `ACTIVE POLICY` splits onto two lines, indicating a width/overflow constraint that must be handled responsively.

### Radii, shadows/elevation, strokes, spacing
- Radii: 16 for all cards, item rows, drop zone and primary Publish button; 9999 for pills, search, status chips and small controls. No 24/32/40 radius on this screen.
- Shadows: cards use `0 2 8 rgba(0,0,0,0.016)` + `0 14 40 rgba(0,0,0,0.043)`; primary `Publish Template` uses `0 10 25 rgba(16,185,129,0.30)`.
- Strokes: none on cards; the active chip uses a translucent `#6FFBBE66` fill, not a border.
- Spacing: 24 (38), 8 (32), 12 (30), 4 (25), 16 (22), 20 (21), 32 (8), 40 (6), 48 (3). Off-grid 10/14/41 appear. Main padding 80 top/48 bottom is outside the 4/8/12/16/24/32/48 token set.

Token drift: current `AppTheme` primary is `#0B3B4A`, secondary `#0F6B6F`; `AppRadiiTokens` tops at 16 before pill; H1 is 24/30 in the phase-1 type scale. This frame uses `#006C49`/`#10B981`, 32px display and 16px radii. `Plus Jakarta Sans` remains licence-pending.

## 4. Components
| Figma pattern / node | Map to current design system | Notes |
|---|---|---|
| Metric pods `1:1905`-`1:1944` | `AppCard` / `SectionHeader` | No metric-pod component. |
| Master item cards `1:1973`-`1:2041` | `AppCard` + `AppListTile` | Current builder uses `AppListTile` item cards with add icon. |
| Search pill `1:1966` | `AppTextField` | Current component is a filled `TextFormField`, not a pill. |
| Category filter | `DropdownButtonFormField` | Current code uses an expanded dropdown, not a visible filter chip. |
| Sequence cards `1:2074`, `1:2107`, `1:2140` | No equivalent | Current `template_builder_page.dart` shows selected items as `AppListTile`; no numbered sequence cards. |
| Drag handles / drop zone `1:2172` | No equivalent | Current reorder is a `PopupMenuButton` with `Move up`/`Move down`; docs A09 allows drag plus accessible move buttons. |
| `Card Controls` composed SVGs (`1:2094`, `1:2127`, `1:2159`) | `AppButton` icon buttons / menu | Composed groups of 3-4 icon buttons and a drag handle. |
| `Active` / `Automated` chips | `StatusChip` | New per-item states; no model field. |
| `Autosave Active` pill | `StatusChip` / `OfflineBanner` language | No autosave exists. |
| `Quality Assurance Rule Set` card | `AppCard` / `SectionHeader` | No policy engine. |
| Header/aside | `AppBar` + `NavigationRail` | Current shell is Jobs/Staff/Templates, not Dashboard/Jobs/Settings. |

## 5. Assets
`assets/manifest.json` reports **50** assets: 42 individual SVGs (icons), and 8 composed SVGs. Composed: three `Card Controls` groups at ~157x40, three `Background` decoration SVGs at 84x40, `Nav` 96x982 and `Aside` 96x1182. **0 raster** assets; no photos, avatars or vehicle images. The tiny icons are mostly 9-21px; several repeat as drag handles, delete, camera, sliders and sparkle.

## 6. Content and data
| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Version badge | `V2.4` | Template version is `int` in `TemplateSummary`/`TemplateVersionSummary` | `V2.4` is not the current integer version format. |
| Kicker | `STANDARD OPERATING PROCEDURE` | No | New marketing label. |
| H1 | `Template Builder: Comprehensive Inspection` | `TemplateDetail.name` | Name is dynamic in code; sample is fine but not real. |
| Actions | `Preview Flow`, `Publish Template` | Preview/publish endpoints exist | Flow preview is new; publish exists. |
| Pod | `SEQUENCE TOTAL`, `3 of 14 configured` | `_selected.length` and template item count | `14 configured` contradicts the 5-item catalog and 3 selected cards. |
| Pod | `MANDATORY PHOTOS`, `1 checkpoint flagged`, `Optical AI analysis enabled` | `TemplateItemView.evidenceRequirement`/`minPhotos` | No "flagged" aggregation, optical AI or analysis field. |
| Pod | `AVG FIELD TIME`, `12 minutes estimated`, `Fast Track Eligible` | No | Invented timing/eligibility; nothing in model. |
| Pod | `TELEMETRY LINK`, `Laser & OBD`, `Direct BT calibration on` | No | No telemetry, Bluetooth or OBD integration. |
| Left header | `Master Items`, `5 In Catalog`, `Available Diagnostic Checkpoints` | `PublishedItem` list/count | Catalog count can be derived; wording is new. |
| Search | `Filter checkpoints by system...` | `GET /workshop/master/items?search=` | Current search field exists. |
| Item 1 | `Check Brakes & Calipers`, `Chassis · Wear & Hydraulics` | `PublishedItem.labelEn`, `categoryLabelEn` | Master item content is server-owned. |
| Item 2 | `Oil Level & Viscosity`, `Powertrain · Spectro Grade` | Same | `Spectro Grade` is invented analysis terminology. |
| Item 3 | `Battery State of Health`, `Electrical · 12V / High Voltage` | Same | Category/value metadata not in `PublishedItem`. |
| Item 4 | `Tread Depth All Axles`, `Tires · 32nds Measurement` | Same | `32nds Measurement` is an invented unit/method. |
| Item 5 | `Coolant Expansion Tank`, `Fluids · Boilover PSI` | Same | `Boilover PSI` is invented. |
| Left action | `Create Custom Diagnostic Item` | No | Workshop cannot create master items. |
| Right header | `Workshop Template`, `Active Inspection Sequence (Drag to reorder)`, `Autosave Active` | `TemplateDetail` + draft items | Drag and autosave are not implemented. |
| Sequence 01 | `Check Brakes & Calipers`, `Active`, `Mandatory Optical Photo`, `• Chassis Integrity` | `TemplateItemView` label/category/rules | `Active` per-item state and "Chassis Integrity" note are new. |
| Sequence 02 | `Oil Level & Viscosity`, `Active`, `Value Range Input [0.0 - 8.5L]`, `• Powertrain Module` | No numeric range field | `[0.0 - 8.5L]` is an invented measurement/range. |
| Sequence 03 | `Tread Depth All Axles`, `Automated`, `Laser Gauge Integration`, `• Tire Quad-Sensor` | No | Automated/laser/sensor concepts are not in the model. |
| Drop zone | `Drag master checkpoint here to append to flow` / `Or click any catalog item from the left panel to insert` | No drag-and-drop | Current add action is an add icon/tap. |
| QA card | `Quality Assurance Rule Set`; `Enforces ISO-9001 brake testing standards & laser calibration validation on save.`; `ACTIVE POLICY` | No | ISO-9001 claim and save-time validation rule are invented. |

The screen contains no customer PII or VIN value. Every measurement, time, percentage, unit and version above is sample/invented and should not be shipped as real data.

## 7. States shown / not shown
Shown: a draft with three selected items, five available masters, autosave "active", three `Active`/`Automated` sequence states, a populated drop zone and an active QA policy.

Not shown: loading, empty catalog, empty sequence, search no-results, error, server validation (`TEMPLATE_WEAKENS_SAFETY_RULE`), missing Arabic translation, retired item, read-only published version, publish-disabled state, publish success/audit, unsaved-changes warning, drag-over state, keyboard reorder state, 200% text, RTL/Arabic, phone/tablet layouts.

## 8. Implied interactions
Search/filter masters; add an item; drag to reorder or use move controls; remove an item; toggle item active; edit item settings; create a custom diagnostic item; preview the flow; publish; rely on autosave. The overflow menu and drag handles imply reorder/delete without confirmation. The `Active` chip and `Automated` label imply per-item enablement/execution modes.

## 9. Correspondence to current product
- **Existing screen:** `client/apps/admin_app/lib/src/pages/template_builder_page.dart` implements name, description, service type, vehicle type, search, category dropdown, published item list (first 80), selected items, move up/down/remove menu, save draft, publish, retire, version history and an EN/AR preview bottom sheet.
- **Existing endpoints:** `GET/POST /api/v1/workshop/templates`, `GET/POST /api/v1/workshop/templates/{id}/draft`, `PUT .../draft`, `POST .../publish`, `POST .../retire`, `GET .../versions`, `GET .../preview`; master reads are `GET /api/v1/workshop/master/categories` and `/items`.
- **Gap:** the current builder has explicit save/publish actions, not autosave; it has no drag-and-drop, no drop zone, no metric pods, no per-item `Active`/`Automated` state, no numeric range, no telemetry/AI/Bluetooth, and no QA policy card.
- **Not allowed by current server:** `WorkshopMasterController` exposes only `GET` methods; there is no workshop custom-item endpoint.
- **Model:** `TemplateItemView` exposes `labelEn/Ar`, `instructionEn/Ar`, `versionNo`, `resultOptions`, `severityPolicy`, `reasonCodes`, `noteRequirement`, `evidenceRequirement`, `minPhotos`, `equipmentIds`, `guideImageId`; no measurement range, analysis mode or per-item active flag.
- The screen is a redesign of an existing screen but includes **new features/data/server changes**; it cannot be delivered as a UI-only change.

## 10. Locked-rule conflicts / unsafe-to-ship content
1. **Master content is Platform Admin-only.** `docs/phase-1/05-master-library-and-templates.md` §1 says a Workshop Admin "Can change wording? **No**"; §5.1 says "A missing item can be requested from Platform Admin; the Workshop Admin cannot create a master item." The `Create Custom Diagnostic Item` action contradicts this.
2. **No invented measurements/results.** The task rule says "Never invent versions/licences/measurements/results." The screen shows `V2.4`, `12 minutes estimated`, `[0.0 - 8.5L]`, `32nds Measurement`, `Boilover PSI`, `12V / High Voltage`, `Spectro Grade`, `Laser Gauge Integration` and `Tire Quad-Sensor` with no model field.
3. **No certification/compliance claims.** `Quality Assurance Rule Set` says "Enforces ISO-9001 brake testing standards & laser calibration validation on save." The task rule forbids certification/compliance claims; `docs/phase-1/05-master-library-and-templates.md` §8 also says no official RTA/Tasjeel claim unless legally supportable.
4. **Autosave is a state/behaviour change.** `docs/phase-3.5/ui-decisions.md` preserved explicit create/edit/publish/retire logic; `docs/phase-1/10-design-system.md` §4.4 requires an unsaved-change warning. `Autosave Active` introduces a new persistence state not in the current client/server.
5. **New item states.** `Active`/`Automated` and "1 checkpoint flagged" imply per-item enablement and execution telemetry that `TemplateItemView` does not carry; implementing them needs model/server/validation changes.
6. **The deck contradicts itself.** `3 of 14 configured`, `5 In Catalog` and three visible sequence cards cannot all describe the same draft state without a hidden 11-item list; the summary must be backed by real counts.
7. **WCAG 2.2 AA.** White on `#10B981` is ~2.54:1; `#10B981` icons/text on white are ~2.54:1; many labels are 11px. The drag-only affordance is not keyboard-operable without the accessible move buttons required by A09.
8. **Tokens/fonts/RTL.** `#006C49`/`#10B981`, 32px H1, 16px-only radii and `Plus Jakarta Sans` are not the current tokens; no Arabic/RTL layout or field direction is shown.

## 11. Open questions / could not verify
- What does `Preview Flow` show, and does it differ from the existing EN/AR preview bottom sheet?
- Is `Autosave Active` a real server draft save, a local-only state, or decorative? What conflict behaviour applies?
- Are `Active` and `Automated` properties of a template item or of a master item? Who can change them?
- Is the numeric range `[0.0 - 8.5L]` authored by the workshop or inherited from the master? Where is it stored?
- Are the telemetry/AI/BT/OBD claims planned hardware integrations or visual fiction?
- Which validation panel shows safety-rule violations, and where is `TEMPLATE_WEAKENS_SAFETY_RULE` surfaced?
- Why 14 configured when the catalog shows 5 items and the flow shows 3?
- Where is the Arabic preview and RTL sequence editor?
