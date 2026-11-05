# 01. 1. Global Hierarchy & Staff Tree

- App: Platform Admin
- Figma node: `1:3172`
- Frame: 1280x1196 px (desktop web)
- Export folder: `screens/01_1._Global_Hierarchy_&_Staff_Tree`
- Sources read: `1._Global_Hierarchy_&_Staff_Tree.json`, `1._Global_Hierarchy_&_Staff_Tree@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: medium — layout and text are measured from JSON/PNG, but several white cards report `cornerRadius: 0` while the PNG shows rounded corners, and the four portrait assets report `0x0` dimensions in the manifest.

## 1. Purpose
Platform-wide workshop/account directory: a 256 px persistent navigation shell, a workshop tree in the left pane (299 px), and a selected-workshop staff board in the right pane (629 px). It combines hierarchy browsing with staff roster, search/filter, pagination, and operational metrics.

## 2. Layout structure
Root FRAME `1:3172` is vertical, 1280x1196, `paddingLeft: 256`, fill `#FFFFFF`. Three `ABSOLUTE`/overlapping root children:
- `Header` `1:3484`, 1024x64, x=256, fill `#FFFFFFE5` (glass app bar).
- `Aside` `1:3509`, 256x1196, padding 24/16/24/16, `SPACE_BETWEEN`, fill `#FFFFFF`.
- `Main` `1:3173`, 1024x1196, padding 64/32/32/32, fill `#FFFFFF`.

Main (`1:3174`, 960 wide, gap 32):
1. `Context Bar & View Controls` `1:3175` 960x38: breadcrumb (HIERARCHY ROOT / EMEA INDUSTRIAL / Active Workshops) + segmented pill `1:3187` 287x38, radius 9999, fill `#F4F3F8`; active `Directory View` segment 151x30 white.
2. `Asymmetric Split Layout` `1:3198` 960x1030, no gap:
   - Left `LEFT PANE: Folder-Tree Node Navigator` `1:3199` 299x764, gap 24: summary pill `1:3200` 299x96 (pad 24); tree card `1:3211` 299x568 (pad 24, gap 24); quick-filter card `1:3294` 299x52 (pad 16).
   - Right `RIGHT PANE: Workshop A Staff Card Board` `1:3302` 629x1030, gap 24: staff card `1:3303` 629x890 (pad 40, gap 32); utility strip `1:3459` 629x116 with three 199x116 cards.

Staff card internals: header/CTA `1:3304` 549x82; search + tag row `1:3318` 549x52; profile stack `1:3334` 549x520, four 549x104 rows, gap 16; pagination `1:3443` 549x60.

Sidebar: brand block 224x54; nav `1:3521` 224x236 with six 224x36 links, gap 4; footer status pill 216x46.

Scroll/responsiveness: the Figma frame is a fixed 1280 desktop canvas. Implementation implies a fixed sidebar + independently scrolling right board; below 1200 px the sidebar should collapse (phase-1 04) — no mobile/tablet variant is exported.

## 3. Visual tokens observed
### Colours (exact hex, usage, approx count)
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 79 | Secondary text, labels, metadata, icons |
| `#F4F3F8` | 30 | Pill/segment/search/search-chip surfaces, sidebar active row |
| `#1A1B1F` | 25 | Primary ink, headings, names |
| `#FFFFFF` | 21 | Cards, sidebar, drawer |
| `#10B981` | 12 | Primary CTA fill, status dot, logo tile |
| `#006C49` | 6 | Emerald text (ACTIVE, 14 Active, CHANGE), avatar |
| `#3C4A42` | 5 | Secondary nav text |
| `#FFFFFF01` | 4 | Near-transparent fills |
| `#E9E7ED` | 2 | Divider/rail |
| `#006C490D`, `#006C491A` | 1 each | Emerald tints |
| `#DAD9DF`, `#E1DEEC` | 1 each | Neutral chip / avatar tint |
| `#FFFFFFE5` | 1 | Header glass |

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)
Family `Plus Jakarta Sans` (400/500/600/700/800). Dominant measured styles:
| Size/weight | LH | Tracking | Colour | Usage |
|---|---|---|---|---|
| 32/800 | 38 | -0.80 | `#1A1B1F` | Page title “Workshop A Staff” |
| 22/700 | 28 | -0.44 | `#1A1B1F` | Metric values |
| 18/700 | 24 | -0.27 | `#1A1B1F`/`#5E5D69` | Workshop names, staff names |
| 16/700 | 22 | -0.16 | `#1A1B1F` | Card headings, certification values |
| 14/500 | 20 | -0.07 | `#5E5D69`/`#3C4A42` | Nav, body, subtitles |
| 13/400 | 18 | 0 | `#5E5D69` | Meta, footnotes |
| 11/600 | 14 | +0.44 to +0.55 | `#5E5D69`, `#006C49` | Uppercase labels, status, chips |

Text is left-aligned except right-aligned certification columns and user-name block. No Arabic content in this screen.

### Radii, shadows/elevation, strokes, spacing
- Radii: only pill `9999` is recorded (55 nodes). Cards `1:3200`, `1:3211`, `1:3294`, `1:3303`, `1:3460` report `cornerRadius: 0` even though the PNG shows generous rounding; treat ~32 px as a visual estimate only. Avatar `1:3338` is 56x56, radius 9999.
- Shadows (observable): ambient card `0 2 8 rgba(0,0,0,0.02)` + `0 14 40 rgba(0,0,0,0.04)`; floating strip `0 18 50 rgba(0,0,0,0.06)`; staff row `0 2 12 rgba(0,0,0,0.03)`; avatar `0 4 12 rgba(0,0,0,0.08)`.
- Strokes: none in the export (zero stroke records).
- Spacing: 4/8/12/16/24/32/40; card padding 24–40; section gap 32; sidebar padding 24/16; content margin 64 top / 32 sides.

## 4. Components
The export is flattened: node types are only FRAME/TEXT/VECTOR/RECTANGLE — no COMPONENT or INSTANCE nodes. Recurring patterns inferred:
- Persistent sidebar nav (`1:3521`) and footer status (`1:3553`) — no equivalent; current app uses `NavigationRail`/tabs.
- Global app bar with 448 px search, notification/help icon buttons, user identity (`1:3485`) — no equivalent.
- Breadcrumb (`1:3176`) — no equivalent.
- Segmented pill switcher (`1:3187`) — closest is `AppSelectableText`; no segmented control primitive.
- Search pill (`1:3486`, `1:3320`) — `AppTextField` exists but uses a rectangular filled theme.
- Workshop tree card (`1:3211`) — current `ExpansionTile` inside `Card`; no tree component.
- Staff list row with avatar/photo, name, role, bay chip, certification column, actions (`1:3335`+) — `AppListTile` + `CircleAvatar` exist; photo/avatar and four-column row are new.
- Status chip/tag (`1:3326` etc.) — `StatusChip` exists.
- Primary emerald pill CTA 56 px (`1:3313`) — `AppButton` primary exists, but current radius/height/min-size differ.
- Staff pagination (`1:3443`) — no equivalent.
- Metric tiles (`1:3460`, `1:3468`, `1:3476`) — no equivalent.
- Quick-filter chip (`1:3294`) — no equivalent (plain chip).
- Icons are Material-like SVGs, plus 4 composed 84x40 action clusters (`1:3355`, `1:3382`, `1:3409`, `1:3436`).

## 5. Assets
42 assets: 34 individual SVG icons, 4 composed SVGs (84x40 action clusters), 4 raster JPEG portraits (`1:3338`, `1:3365`, `1:3392`, `1:3419`). The portraits are real photographic headshots (staff avatars), not illustrations. Manifest reports width/height 0 for them; node size is 56x56 with radius 9999. No vehicle imagery.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Search placeholder | “Search platform assets, specs, workshop nodes...” | No global search endpoint | Implies cross-domain search |
| Breadcrumb | HIERARCHY ROOT / EMEA INDUSTRIAL / Active Workshops | Partly (`workshop.status`) | Region grouping not modelled |
| View switch | Directory View / Throughput | No | New view |
| Root summary | Grid Facilities · 2 operational nodes | No | Facility grouping not modelled |
| Platform node | Core Platform · v4.2 | No | Invented system version |
| Workshop rows | Workshop A, 14 Active Staff, 8 Bays | Partly (name, status, memberCount) | Bays count not stored |
| Status | ACTIVE / STANDBY / DEPOT HUB / Offline Maintenance | `workshop.status` exists | Extra states not in model |
| Capacity | ASSIGNED BAY CAPACITY 88% | No | Calculated metric |
| Shift filter | Filter Shift: Day Rotation / CHANGE | No | Shift model absent |
| Staff names | David Vance, Marcus Vance, Sarah Jenkins, Elena Rostova | Yes (displayName) | Fictional people |
| Role labels | Lead Inspector, Diagnostic Tech, Shop Floor Supervisor, Optics & Sensor Calibration | Partly (`role`) | Only TECHNICIAN/WORKSHOP_ADMIN exist |
| Bay/area tags | Bay 01-04, Diagnostics Bay, Floor Command, ADAS Align | No | New field |
| Certifications | Level 3 Master, CAN Bus / EV High-V, ISO-9001 Lead, Bosch / Hella ADAS | No | Unsourced certification claims |
| Pagination | Showing 4 of 14 registered personnel in Workshop A | Partly | No pagination in current API |
| Metrics | LIVE UTILIZATION 94.2% (+3.1%), AVG INSPECTION TIME 18.4m (-2.2m), PASS RATE VELOCITY 99.1%, “Audit compliance score” | No | Invented scores/measurements |
| Footer | GRID V4.2 ONLINE | No | Invented product/version branding |
| User | Alex Vance · Principal Admin | Partly (`displayName`, `role`) | “Principal Admin” not a role |

No customer name/phone/email, VIN, plate, or report findings are shown. Staff names and portrait photos are personal data; the avatars are real photos.

## 7. States shown / not shown
Shown: populated directory; one workshop expanded; active status; selected view; hover-like pill selection. Not shown: loading, empty (no workshops), error/retry, permission-denied, conflict, offline, disabled/pending invitation rows, search-with-no-results, pagination other pages, expanded/collapsed tree variants, RTL, focus/keyboard, 200% text scale, long names/overflow.

## 8. Implied interactions
Sidebar navigation; global search; notification/help/user buttons; Directory/Throughput switch; tree expand/collapse per workshop; quick filter; search staff; All/Diagnostics/Inspectors/Supervisors filter; pagination; Add Staff; per-row chat/more actions; shift change; capacity status. No destructive action is shown.

## 9. Correspondence to current product
Partial. Existing: `client/apps/admin_app/lib/src/pages/hierarchy_tab.dart` renders `hierarchyProvider` as search + status chips + `ExpansionTile` workshop cards with `_AccountSection`/`_AccountTile`; `admin_api.dart` `hierarchy()` and `workshopDetail()`; endpoints `GET /api/v1/platform/hierarchy` and `GET /api/v1/platform/workshops/{id}/hierarchy` (`PlatformHierarchyController`). Models `HierarchyWorkshop`, `PlatformAccount` expose name/branch/status/memberCount/displayName/email/emailMasked/role. Missing: 256 px sidebar shell, right detail board, photos/avatars, bay/shift/certification fields, roster pagination, metrics. `AppListTile`, `StatusChip`, `AppButton` can be reused; the tree, metric tiles, and photo avatar row are new UI. Throughput/capacity/utilisation metrics need new data and calculations (server change).

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “no manager role, review queue, customer app/portal, or in-platform payments.” Evidence: “Shop Floor Supervisor” (`1:3402`), “Supervisors” filter (`1:3333`), “Lead Inspector” (`1:3348`), certifications “Level 3 Master” (`1:3354`), “ISO-9001 Lead” (`1:3408`). These import a management/certification hierarchy not in the role model (only PLATFORM_ADMIN, WORKSHOP_ADMIN, TECHNICIAN).
- Rule: “no certification/‘verified by’/compliance claims.” Evidence: “ISO-9001 Lead” and “Level 3 Master”/“CAN Bus / EV High-V”/“Bosch / Hella ADAS” certification columns.
- Rule: “no single unexplained condition score.” Evidence: “PASS RATE VELOCITY 99.1%” with caption “Audit compliance score” (`1:3478`–`1:3483`); “LIVE UTILIZATION 94.2%” and “AVG INSPECTION TIME 18.4m” are operational scores with no definition.
- Rule: “Never invent versions/licences/measurements/results.” Evidence: “Core Platform v4.2” (`1:3225`), “GRID V4.2 ONLINE” (`1:3557`), “94.2%”, “+3.1%”, “18.4m”, “88%”, “99.1%”.
- Rule: “colours/text/radii/spacing/endpoints from central tokens/classes, not hardcoded.” Evidence: emerald `#10B981`/`#006C49` and lavender `#F4F3F8` do not match current `tokens.dart` (`#0B3B4A`, `#0F6B6F`, `#F7FAFA`); radii 32/48 exceed `AppRadiiTokens` (max 16); Plus Jakarta Sans is not bundled.
- Rule: “WCAG 2.2 AA.” Evidence: 11 px uppercase labels, color-only status dots, icon-only bell/help actions, avatar images with no visible alt mechanism. Contrast of `#5E5D6980` placeholders was not measured.
- Rule: “UI layer only; no business logic/API/model change.” Evidence: capacity, utilisation, inspection-time and pass-rate metrics cannot be rendered from the current hierarchy DTO; implementing them requires server/model work.

## 11. Open questions / could not verify
- Are the four portraits licensed/consented for a real roster, or placeholders? Manifest dimensions are 0x0.
- Is the missing card radius a JSON export omission or a deliberate 0-radius style? PNG and JSON disagree.
- Are “Bays”, “Shift”, “Capacity”, “Certifications” planned fields or decorative mock data?
- What exact role names are allowed? “Principal Admin”, “Lead Inspector”, “Supervisor” are not in the current model.
- Intended responsive behaviour below 1280 px is not exported.
- Contrast, focus order, keyboard tree behaviour, RTL mirroring, and text-scaling states cannot be verified from a static frame.
