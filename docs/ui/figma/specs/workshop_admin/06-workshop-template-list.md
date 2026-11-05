# 06. 7. Workshop Template List

- App: Workshop Admin
- Figma node: `1:1307`
- Frame: 1280x1586 px (desktop web; >=1200 breakpoint)
- Export folder: `screens/06_7._Workshop_Template_List`
- Sources read: `7._Workshop_Template_List.json` (developerSummary, nodes), `7._Workshop_Template_List@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html` header, `package-manifest.json`
- Export/screen-number mismatch: this is export slot **06** but Figma screen **7** ("Workshop Template List"). Screen 6 (Add Staff) was exported earlier in slot 07, so export order is not screen order; screen 3 is slot 01.
- Confidence: medium — card geometry/type are exact; several card labels (tags, compliance, PPE, caliper, audit lock) have no model/API and include prohibited claims.

## 1. Purpose

Manage the workshop's inspection templates ("protocols"): KPI strip, filter/view controls, five published template cards plus a create-card, and a validation/audit footnote with export actions.

## 2. Layout structure

Root `1:1307` 1280x1586; rail `1:1623` 96x800; main `1:1309` 1184 px with padding 80/40/48/40. Content `1:1310` 1104x1458, top-to-bottom:

1. **Title/KPI row** `1:1311` 1104x132 (48 px bottom margin): title block 399.8x84 ("STANDARD OPERATING PROCEDURES", 32 px title, subtitle) on the left; on the right a "5 Active Blueprints / 42 Bays Bound" pill (260.4x32) and a 190.6x56 "+ New Template" button. The row is 84 high, with an extra 48 px margin.
2. **Operational KPI strip** `1:1332` 1104x183.2 (48 px margin): four cards 258x130/135.2, 24 px gap, radius 16, padding 24: Total Checkpoints 294 Items, Avg. Completion 14.2 min, Compliance Rate 99.4%, Protocol Audit Up to date.
3. **Filter/view row** `1:1378` 1104x76 (32 px margin): a 531.9x44 tonal pill with All Protocols (5) / Fleet Mandatory / High-Voltage EV / Quick Lane; right-aligned "Layout:" + two 32x32 view toggles (grid selected).
4. **3-column grid** `1:1398` 1104x914.8: 346.7-wide cards, 32 px column gap, two rows. Row 1 y=471.2 (cards 437.1 high), row 2 y=944.6 (437.8), so the row gap is 36.3. Five 346.7x437 template cards (`1:1399`, `1:1433`, `1:1467`, `1:1501`, `1:1535`) and one 346.7x439.1 dashed create-card (`1:1569`). Each card: 32 px padding, 24 radius, 48x48 icon tile, tag chip, 18 px title, version line, 3-line description, 282.7x56 tonal requirement pill, "Updated…" + 99.5x48 Edit button.
5. **Bottom footnote** `1:1586` 1104x88, radius 16, 64 px top margin: "Strict Validation Lock Enabled / Checklist changes require Master Inspector sign-off before field deployment." plus "Export Schemas (JSON)" and "Version Audit Log" buttons.

Fixed 3-column desktop grid; no responsive reflow, no list state drawn despite the list/grid control.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx fill count)

| Hex | Count | Usage |
|---|---:|---|
| `#5E5D69` | 42 | Secondary text, metadata, labels |
| `#1A1B1F` | 34 | Titles, values, icons |
| `#FFFFFF` | 31 | Page, cards, buttons |
| `#F4F3F8` | 18 | Tags, icon tiles, tonal pill, footnote |
| `#006C49` | 15 | Green icons/labels, "Open Template Architect" |
| `#10B981` | 9 | New Template, Edit buttons, active nav |
| `#3C4A42` | 6 | Card descriptions |
| `#F4F3F866` | 5 | Requirement pill background |
| `#1B1B25` | 2 | Tag text on lilac/neutral tags |
| `#10B98126` | 1 | "Fleet Default" tag tint |
| `#E3E1EF` | 1 | "Specialized" tag background |
| `#E9E7ED` | 1 | "Rapid Intake" tag background |
| `#EEEDF3` | 1 | Footnote icon tile |
| `#FFFFFFE5` | 1 | Blurred header |

### Typography

Plus Jakarta Sans only. 75 text nodes: SemiBold 600 x42, Regular 400 x17, Bold 700 x14, ExtraBold 800 x1, Medium 500 x1.
Sizes: 11 x24, 12 x20, 13 x17, 18 x6, 22 x4, 14 x2, 16 x1, 32 x1.

| Role | Style | Example |
|---|---|---|
| Page title | 32 / 38, 800, -0.8 px | `1:1317` "Inspection Templates" |
| KPI value | 22 / 28, 700, -0.44 px | `1:1343` "294 Items" |
| Card title | 18 / 24, 700, -0.27 px | `1:1408` "100-Point Standard Check" |
| Card description | 13 / 21.13, 400 | `1:1412` |
| Version/meta | 13 / 18, 400 | `1:1410` "Version 2.0 • 110 checkpoints" |
| Chip/label | 11 / 14, 600, +0.44 px; 12 / 16, 600 | `1:1337`, `1:1406` |
| Eyebrow | 11 / 14, 600, +1.1 px, UPPER | `1:1315` |
| Edit/CTA | 14 / 17.5, 700; 12 / 16, 700 | `1:1432`, `1:1582` |

Card descriptions are left-aligned; the create-card title is centred. No Arabic/RTL sample.

### Radii, shadows/elevation, strokes, spacing

- Radii: 24 (cards/banner), 16 (KPI cards, requirement pills, Edit, footnote), 9999 (tags/pills). Candidate counts: 16 x24, 9999 x24, 24 x6.
- Shadows: template cards `0 2 8 rgba(0,0,0,.016)` + `0 14 40 rgba(0,0,0,.043)`; create-card uses 1%/2% opacity versions of the same pair; KPI cards 2/14 px pair.
- No strokes; the create-card is described as dashed in its layer name but no dash is visible in the PNG.
- Spacing: 32 x35, 24 x29, 16 x27, 12 x23, 4 x21, 20 x20, 8 x18; card padding 32; grid gap 32/36.3.

## 4. Components

| Figma pattern | Node | Our design-system equivalent |
|---|---|---|
| Floating header/rail | `1:1600`, `1:1629` | `AppBar`/`NavigationRail` (rail active on Settings) |
| KPI/overview card | `1:1334` | No equivalent |
| Filter segmented pill | `1:1380` | `AppSelectableText` |
| Grid/list view toggle | `1:1389` | No equivalent |
| Template card | `1:1399` | `Card` + `AppListTile` (current list), not a grid card |
| Tag chip | `1:1405` | `StatusChip` |
| Requirement pill | `1:1413` | No equivalent |
| Primary/tonal buttons | `1:1428`, `1:1596` | `AppButton` primary/tonal |
| Dashed create-card | `1:1569` | `EmptyState`/add tile is closest |
| Footnote banner | `1:1586` | tonal card/`OfflineBanner` |

## 5. Assets

39 assets: 37 individual SVGs, 2 composed SVGs (`Nav-1_1629`, `Aside-1_1623`), **0 rasters**. All are 11–24 px icons; no photos, avatars or vehicle images. No template thumbnails are exported.

## 6. Content and data

| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Title/subtitle | "Inspection Templates", "Standardized vehicle diagnostic and safety checklists" | Yes (templates) | "Inspection Templates" differs from frame/spec "Template List" |
| Badge | "5 Active Blueprints / 42 Bays Bound" | Partly | Template count can be derived; "bays bound" has no entity |
| Primary action | "+ New Template" | Yes (create) | Current app opens a 4-field dialog then builder |
| KPI 1 | "TOTAL CHECKPOINTS 294 Items / Across active catalog" | Yes/derived | 110+24+45+80+35 = 294, so internally consistent; sum of item counts |
| KPI 2 | "AVG. COMPLETION 14.2 min / -1.8 min vs last cycle" | No | No completion-time metric |
| KPI 3 | "COMPLIANCE RATE 99.4% / OEM ISO-9001 sync" | No | No compliance metric; ISO claim |
| KPI 4 | "PROTOCOL AUDIT Up to date / Next review in 12 days" | No | No review/audit schedule |
| Filters | "All Protocols (5)", "Fleet Mandatory", "High-Voltage EV", "Quick Lane" | Partly | Status/service type exist; these are custom tags not in `TemplateSummary` |
| Layout | "Layout:" + grid/list icons | No | Current screen is list-only; no view preference |
| Card 1 | "100-Point Standard Check", "Fleet Default", "Version 2.0 • 110 checkpoints", description, "Mandatory Photo Gates 8 points", "Updated 2d ago", Edit | Partly | Name/itemCount/updatedAt exist (`TemplateSummaryDto`); tag, semver, photo-gate count, description are missing from the list payload; name says 100 but 110 checkpoints |
| Card 2 | "Quick Oil Service", "Rapid Intake", "Version 1.4 • 24 checkpoints", "Target Cycle Time 12 mins", "Updated 1w ago" | Partly | Target cycle time and custom tag absent; "Version 1.4" cannot come from integer `versionNo` |
| Card 3 | "EV High-Voltage Battery Audit", "Specialized", "Version 3.1 • 45 checkpoints", "Hazmat PPE Mandatory Class 00", "Updated 4h ago" | No/partly | PPE/class data absent; `Class 00` is an electrical glove class claim |
| Card 4 | "Commercial Fleet Pre-Delivery", "DOT Compliant", "Version 1.8 • 80 checkpoints", "Federal DOT baseline… cargo tie-down certification… telematics hardware handshake", "Asset Tagging Req. Active", "Updated 3d ago" | No | DOT/compliance/certification and hardware integration claims |
| Card 5 | "Brake & Chassis Certification", "Chassis Safety", "Version 2.2 • 35 checkpoints", "Digital micrometer rotor depth… Digital Caliper Sync BLE Ready", "Updated 5d ago" | No | "Certification", caliper/BLE hardware claim; measurements |
| Create card | "+ Create Custom Protocol", "Assemble a bespoke diagnostic flow with custom thresholds, required imagery, and instant technician triggers."; "Open Template Architect" | Partly | Create/edit exists; "custom thresholds/instant triggers" are not modelled |
| Footnote | "Strict Validation Lock Enabled", "Checklist changes require Master Inspector sign-off before field deployment."; "Export Schemas (JSON)"; "Version Audit Log" | No | Version history endpoint exists; "Master Inspector sign-off" is an approval gate; JSON schema export is not designed |

No customer PII, VIN/plate, avatars or vehicle photos. The content is entirely template/workshop metadata.

## 7. States shown / not shown

Shown: five published-looking cards, one custom tag each, grid view selected, All Protocols selected, KPI values, footnote "validation lock".
Not shown: draft, retired, empty ("no templates"), loading skeleton, error/retry, filter with zero results, list view (despite toggle), long names/descriptions, 200% text, RTL/Arabic, dark theme, mobile/tablet, disabled permissions, publish validation failure, missing Arabic translation, version diff/preview.

## 8. Implied interactions

Filter by protocol/tag; switch grid/list; New Template; Edit (published card); create custom protocol/open architect; export schemas; version audit log; nav/search/user menu. "Edit" on a published card is ambiguous: it must open a draft/new version, never mutate the published version. No duplicate/retire/delete/preview action is shown.

## 9. Correspondence to current product

- Spec: A08 Template list `/templates` (`docs/phase-1/02-screen-inventory.md:68`) — search, status (draft/published/retired), version, last published, used-by count; open/create/versions; table on web, cards on mobile. A09 builder and A11 versions also exist.
- Current UI: `TemplatesTab` (`templates_tab.dart`) is a `ListView` of `Card` + `AppListTile`: name, `serviceType · v{currentVersion} · {itemCount}`, status chip; tap opens `TemplateBuilderPage`; `+ New template` opens a name/description/serviceType/vehicleType dialog then the builder.
- API: `GET /api/v1/workshop/templates` → `TemplateSummaryDto` (id, name, serviceType, vehicleType, status, currentVersion, itemCount, updatedAt). `POST` create, `PUT .../draft`, `POST .../publish`, `GET .../versions`, `GET .../preview` exist.
- Data gap: the server returns `updatedAt`, but the client `TemplateSummary` (`models.dart:552`) does **not** parse it. Description/tags/photo-gate counts/cycle time/PPE/bays/sign-off/audit export/completion/compliance are not in the list DTO or any endpoint.
- Verdict: **existing screen**, major redesign to a grid; some data can be added without server change (`updatedAt`, itemCount sum); most card metadata and all compliance/certification/audit/export features need new data or are prohibited.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"Do not represent the checklist as an official government inspection or certification unless authorised."** Evidence: "DOT Compliant", "Federal DOT baseline", "cargo tie-down certification", "Brake & Chassis Certification", "OEM ISO-9001 sync". These are regulatory/licence claims.
2. **"ISO/IEC 17020 only as a possible inspection-body reference, not as a checklist or a claim of certification."** Evidence: "OEM ISO-9001 sync" on the compliance KPI.
3. **"No certification/'verified by'/compliance claims."** Evidence: "COMPLIANCE RATE 99.4%", "DOT Compliant", "Certification", "Strict Validation Lock".
4. **"No manager role, second-person review, approval queue or resubmission."** Evidence: "Checklist changes require Master Inspector sign-off before field deployment." This is an approval gate and introduces a "Master Inspector" role.
5. **"Finalized findings/reports immutable; no correction UI."** The "Edit" button on published cards and "Strict Validation Lock" could imply editing published content. Edits must create a new immutable template version, and the card must say so.
6. **"Never invent versions/licences/measurements/results."** Evidence: "Version 2.0 / 1.4 / 3.1 / 1.8 / 2.2" (integer `versionNo` cannot produce 1.4/2.2), "12 mins", "14.2 min", "-1.8 min", "99.4%", "294 Items", "42 Bays Bound", "12 days", "Class 00", "8 points", "Updated 2d/1w/4h/3d/5d ago".
7. **"UI layer only; no business logic/API/model/validation/permission/server change."** Compliance scoring, audit scheduling, protocol tags, bay binding, JSON schema export, sign-off and hardware/BLE are new features; several are explicitly out of scope.
8. **Tokens.** Raw hex; emerald family not in current tokens; 24 radius exceeds current 16; card shadows differ from screen 02; tag colours (`#10B98126`, `#E3E1EF`, `#E9E7ED`) are one-offs.
9. **WCAG 2.2 AA.** White "+ New Template"/"Edit" on `#10B981` approx 2.5:1; 11 px tags; grid/list toggle is 32x32, below the project's 44/48 minimum; icon-only layout toggles have no visible label.
10. **Arabic RTL.** No Arabic; required EN/AR translation is a publish gate in the spec. The grid ordering, left-aligned descriptions and directional "→" need RTL rules; no RTL/bilingual preview is shown.
11. **Hardware.** "Telematics hardware handshake", "Digital Caliper Sync / BLE Ready", "Hazmat PPE Mandatory Class 00" imply integrations/certifications with no support evidence.

## 11. Open questions / could not verify

- Are "Fleet Mandatory / High-Voltage EV / Quick Lane / Fleet Default / Rapid Intake / Specialized / Chassis Safety" approved tags, service types, or free copy? None exist in the template summary.
- Where does semver ("2.0", "2.2") come from when the server stores an integer version? Is "Version 2.0" a template-name string or fabricated?
- Are "DOT Compliant", "ISO-9001", "Certification", "Class 00" claims legally approved? If not, they must be removed, not restyled.
- What is "Master Inspector"? It is not one of the three roles and implies the prohibited review/approval layer.
- Is "42 Bays Bound" meaningful? What is a "bay" and how is a template bound to it?
- Which metrics can be computed from `itemCount`/`updatedAt`/versions, and which require new endpoints? Is sum-of-items a legitimate "Total Checkpoints"?
- Should "Edit" open a new draft/version and how is that labelled for published cards?
- Is "Export Schemas (JSON)" approved? Large exports are async/audited; no schema export API exists.
- Is list view implemented or decorative? Is the current list the intended fallback?
- Why is the rail's active item Settings while the content is Templates?
