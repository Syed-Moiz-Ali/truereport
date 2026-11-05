# 04. 4. Workshop Details & Settings

- App: Platform Admin
- Figma node: `1:3976`
- Frame: 1280x1024 px (desktop web)
- Export folder: `screens/04_4._Workshop_Details_&_Settings`
- Sources read: `4._Workshop_Details_&_Settings.json`, `4._Workshop_Details_&_Settings@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: high — card/tree/tab geometry and labels are explicit and readable.

## 1. Purpose
Per-workshop configuration and diagnostics: organisation-tree navigation, workforce/throughput/state metrics, workshop-admin contact, and an enable/disable “killswitch”, with General/Permissions/Audit tabs.

## 2. Layout structure
Root `1:3976` vertical, 1280x1024, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:3977` 1024x1024, padding 64/32/124/32.
- `Container` `1:3978` 960x836, gap 24:
  - `Header Context` `1:3979` 960x22: breadcrumb + “Live Telematics Sync” pill 166x22.
  - `Main Split-Screen Layout` `1:3991` 960x742:
    - Left `Left Pane: Minimal Clean Tree Structure` `1:3992` 216x471, gap 16: tree card 216x312 (pad 24, radius 32), node status card 216x143 (pad 24, radius 32).
    - Right `Workshop A Overview Card` `1:4037` 712x740, radius 48, padding 48, gap 40: title row 616x56 (title block + 264x36 tab pill); 3 metric chips 195x118 gap 16; mid section 616x260 (346 px inputs column + 238x244 toggle card); footer 616x74.
- `Header` `1:4138` 1024x64 glass; `Aside` `1:4163` 256x1024 (nav 224 wide, footer row).

Note: the sidebar child is exported at 256x800 while the frame is 1024 tall; the sidebar is visually full height in the PNG.

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 44 | Body/labels/meta |
| `#1A1B1F` | 17 | Ink/metrics/headings |
| `#FFFFFF` | 16 | Cards/outputs |
| `#F4F3F8` | 14 | Toggle card, tab track, node-status pills |
| `#10B981` | 11 | Active node, toggle, sync dot |
| `#3C4A42` | 7 | Copy/body |
| `#006C49` | 1 | Avatar |
| `#5E5D6966` | 1 | Separator |
| `#E9E7ED` | 1 | Tree selected row? |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans`. “Workshop A Overview” 32/800 LH38 -0.80; metric values 22/800 LH28 -0.44; tree root 16/700; field labels 14/700; inputs 16/500; “CONFIGURATION & DIAGNOSTICS” 11/600 uppercase; body 13/400; “Live Telematics Sync” 11/600; tab labels 12/600.

### Radii, shadows, strokes, spacing
- Radii: 32 (tree/status cards, metric chips, toggle card), 48 (right overview card), 9999 (tabs, pills, sync pill, save button).
- Shadows: card `0 2 8 .02` + `0 14 40 .04`; node-status card `0 8 24 rgba(0,0,0,.28)`? — visible soft lift; icon buttons `0 2 6 .02`; toggles no shadow.
- Strokes: none.
- Spacing: right card 48/48/48/48, gap 40; metric gap 16; form gap 24; tree padding 24; page top 64/bottom 124.

## 4. Components
Flattened export. Patterns: breadcrumb + live-status pill, mini organisation tree with selected emerald row, node-status validation card, tab segmented control (General/Permissions/Audit), three metric cards, labelled inputs, large toggle card, save/discard footer.
Mapping: `TabBar`/`TabBarView` exists (current admin home), `AppTextField`, `Switch`, `AppButton`, `SectionHeader`; the tree, metric cards, validation callout, and toggle card have no equivalent.

## 5. Assets
27 assets, all individual SVG icons. No raster/composed/photo. Icons: logo/nav, tree/expand, node status, search/chrome, metric icons, phone, shield, cloud, save.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Breadcrumb | WORKSPACE HIERARCHY · Node ID #WS-8841 | Partly (`workshop.id`) | ID format invented |
| Live status | Live Telematics Sync | No | No telemetry integration |
| Tree | Platform → Workshop A → Workshop B/C → Fleet Central | Partly (`GET /platform/hierarchy`) | Multi-workshop tree exists |
| Node ID | #WS-8841 | Partly | Server uses UUIDv7, not this format |
| Validation copy | “Active node authenticated via ISO 26262 diagnostic relay. Automatic backup scheduled hourly.” | No | ISO standard misuse + invented infra |
| Metrics | 12 Technicians; 450 Total Jobs; +18% this month; Active; Latency: 14ms | Partly (`memberCount`); rest no | Throughput/latency not stored |
| Tabs | General, Permissions, Audit | No | Current UI has no workshop detail tabs |
| Admin name | Arthur Pendelton | No | `Workshop` has no admin-name field |
| Admin help | “Primary authority for job sign-offs and diagnostic overrides.” | No | Manager/sign-off authority construct |
| Contact phone | +1 (555) 382-9011 | No | No phone column |
| Phone help | “Direct escalation hotline for emergency fleet dispatch.” | No | Invented dispatch process |
| Killswitch | Enable/Disable Workshop; “Toggle operational ingestion & bay assignments” | Partly (`Workshop.status`) | No disable endpoint; no ingestion/bays |
| Sync copy | “Workshop node is actively syncing telematics” | No | No telematics |
| Footer | Last modified today at 14:28 EST by Alex Vance | Partly (audit) | EST timezone not product default |
| Actions | Discard, Save Changes | — | No update endpoint for this form |

No customer PII/VIN/plate/report findings. A staff/workshop phone number is displayed in full.

## 7. States shown / not shown
Shown: selected ACTIVE node, General tab, populated metrics, toggle on, enabled save. Not shown: inactive/disabled node, Permissions and Audit tab contents, loading, error, conflict/If-Match, last-admin protection, disable confirmation/reason, validation errors, unsaved-change warning, RTL, keyboard/focus, 200% text, small screens.

## 8. Implied interactions
Select tree nodes; switch tabs; edit admin name/phone; toggle the workshop on/off; discard; save. The toggle is a high-risk state change but has no confirmation, reason, or re-authentication in the frame.

## 9. Correspondence to current product
Partial/new. Existing: `hierarchy_tab.dart` shows workshops as `ExpansionTile` and opens `workshopDetail` (`GET /api/v1/platform/workshops/{id}/hierarchy`); `PlatformController` exposes `GET /platform/workshops/{id}`. `Workshop` has `name`, `status`, `branchName`, `timezone`. Missing: a dedicated workshop-detail route/screen, tabs, admin name/phone columns, metrics, telemetry, and `PATCH`/disable endpoints. Phase-1 API design lists `PATCH /platform/workshops/{id}`, `POST .../disable`, `POST .../reactivate`, but they are not implemented. This screen is primarily a new feature requiring server change.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “no manager role, review queue…” Evidence: “Primary authority for job sign-offs and diagnostic overrides” (`1:4098`) gives the Workshop Admin sign-off/override authority; “Permissions” tab implies role administration. The role model has only three roles.
- Rule: “no certification/‘verified by’/compliance claims.” Evidence: “Active node authenticated via ISO 26262 diagnostic relay” (`1:4036`). ISO 26262 is a functional-safety standard; claiming it authenticates a workshop node is unsupported.
- Rule: “Never invent … measurements/results.” Evidence: “450 Total Jobs”, “+18% this month”, “Latency: 14ms”, “Automatic backup scheduled hourly”, “Node ID #WS-8841”, “Last modified … 14:28 EST”.
- Rule: “Finalized findings/evidence/reports immutable; no … server change.” Evidence: an editable workshop killswitch and “Permissions” tab imply operational control not exposed by the current API; disabling a workshop is a security-relevant state change with no reason/re-auth.
- Rule: “external delivery/consent.” Evidence: “Direct escalation hotline for emergency fleet dispatch” implies dispatch/notification behaviour not in the product.
- Rule: “Never show full PII unnecessarily.” Evidence: full phone number `+1 (555) 382-9011` (`1:4105`) and full admin name.
- Rule: “tokens from central tokens.” Evidence: radii 32/48 and emerald `#10B981`/`#006C49` exceed/differ from the current token set; Plus Jakarta Sans is not bundled.

## 11. Open questions / could not verify
- Is “Enable/Disable Workshop” the same as `Workshop.status`? If so, what happens to active staff, public report links, and in-flight jobs?
- Are admin name/phone new workshop fields or references to an account? No schema exists.
- What do Permissions and Audit tabs contain? Not exported.
- Is “Live Telematics Sync” a real integration or decorative copy? No telemetry endpoint exists.
- Why is the sidebar export 800 px tall on a 1024 px frame?
- No disabled/error/loading/RTL/confirmation states.
