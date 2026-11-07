# F3-0 Screen 7 — Template List (Workshop Admin)

- Export folder: `docs/ui/figma-export/Workshop_admin_figma/screens/06_7._Workshop_Template_List`
- Figma node: `1:1307` ("7. Workshop Template List"), 335 serialized nodes
- Frame (JSON `developerSummary.screen`): **1280×1586**, VERTICAL, bg `#FFFFFF`
- PNG: `7._Workshop_Template_List@2x.png` 2592×3172 px (=1296×1586 @1x; +16 bleed — per O3 use **1280** as drawn)
- Prior spec read (not edited): `docs/ui/figma/specs/workshop_admin/06-workshop-template-list.md`
- Viewed PNG as image: yes

## 1. Node-level layout

- Root `1:1307` 1280×1586; `Background 1:1308` 1280×1586; `Main 1:1309` 1184 at x=96 (pad 80/40/48/40); `Content 1:1310` 1104×1458.
- Title/KPI row `1:1311` 1104×132 (+48 margin): left title block (`STANDARD OPERATING PROCEDURES` eyebrow, `Inspection Templates` 32/800, subtitle); right `5 Active Blueprints / 42 Bays Bound` pill + `+ New Template` 190.6×56 emerald.
- KPI strip `1:1332` 1104×183.2 (margin 48): 4× 258 cards gap 24 r16 pad 24: 294 Items / 14.2 min / 99.4% / Up to date.
- Filter/view row `1:1378` 1104×76 (margin 32): 531.9×44 tonal pill (`All Protocols (5)` selected / Fleet Mandatory / High-Voltage EV / Quick Lane); right `Layout:` + 2× 32×32 toggles (grid selected).
- Grid `1:1398` 1104×914.8: 346.7-wide cards, col-gap 32, row-gap ~36.3; five 346.7×437 template cards + one 346.7×439.1 dashed create-card. Per card: pad 32 r24, 48 icon tile, tag chip, title 18/700, version line, 3-line description 13/400, 282.7×56 tonal requirement pill, `Updated…` + 99.5×48 Edit.
- Footnote `1:1586` 1104×88 r16 (margin-top 64): validation-lock sentence + `Export Schemas (JSON)` / `Version Audit Log`.
- Shell header/rail same as screens 5–8 (rail active = Settings). Fixed 3-col grid only; list view not drawn despite toggle.

## 2. Components

| Figma pattern | Design-system map |
|---|---|
| KPI card | No equivalent → new `MetricCard` |
| Filter segmented pill | `chips.dart` `AppSelectableText` |
| Grid/list 32 px toggle | No equivalent → new (must meet 44/48 target) |
| Template grid card | `cards.dart`+`lists.dart` (current `templates_tab.dart` is `ListView` of `AppListTile`, not grid) → new `TemplateCard` |
| Tag chip / requirement pill | `chips.dart` `StatusChip` / new tonal pill |
| Primary/tonal buttons | `buttons.dart` `AppButton` |
| Dashed create-card | `states.dart` `EmptyState` / add tile |
| Footnote banner | tonal card / `states.dart` `OfflineBanner` language |

## 3. Assets

- `assets/manifest.json`: **39 assets — 37 individual SVGs + 2 composed** (`Nav-1_1629`, `Aside-1_1623`), **0 rasters**. All 11–24 px icons; no template thumbnails.

## 4. Element → data mapping (EVERY visible string)

Server: `server/.../templates/api/WorkshopTemplateController.java` — `GET /api/v1/workshop/templates` → `TemplateSummaryDto` (id, name, serviceType, vehicleType, status, currentVersion int, itemCount, updatedAt); `POST` create; `PUT .../draft`; `POST .../publish|retire`; `GET .../versions|preview`. App: `client/apps/admin_app/lib/src/pages/templates_tab.dart`.

| Figma element | Mapping |
|---|---|
| `Inspection Templates / Standardized vehicle diagnostic...` | EXISTS (list screen `TemplatesTab`); title wording new |
| `5 Active Blueprints / 42 Bays Bound` | PARTIAL: count derivable; "Bays Bound" DATA GAP (no bay entity) |
| `+ New Template` | EXISTS → create dialog (name/description/serviceType/vehicleType) then builder (`templates_tab.dart:87`) |
| `TOTAL CHECKPOINTS 294 Items / Across active catalog` | DERIVABLE (sums itemCount; 110+24+45+80+35=294 consistent) — UI work only |
| `AVG. COMPLETION 14.2 min / -1.8 min vs last cycle` | DATA GAP — no timing metric; invented measurement |
| `COMPLIANCE RATE 99.4% / OEM ISO-9001 sync` | DATA GAP + LOCKED-RULE conflict (compliance/ISO certification claim) |
| `PROTOCOL AUDIT Up to date / Next review in 12 days` | DATA GAP — no audit schedule; review/approve wording conflict per O6 |
| Filters `All Protocols (5) / Fleet Mandatory / High-Voltage EV / Quick Lane` | PARTIAL: status/serviceType exist; custom tags DATA GAP |
| `Layout:` grid/list toggle | DATA GAP — list-only today; no view preference |
| Card 1 `100-Point Standard Check / Fleet Default / Version 2.0 • 110 checkpoints` + desc + `Mandatory Photo Gates 8 points` + `Updated 2d ago` + Edit | PARTIAL: name/itemCount/updatedAt EXIST in DTO (client `TemplateSummary` doesn't parse updatedAt — UI work); tag/description/photo-gate count DATA GAP; "Version 2.0" semver CONFLICTS with integer `versionNo`; "100-Point" vs 110 inconsistent; required-photo gates follow master evidence rules per O7 (count display derivable from detail, not list DTO) |
| Card 2 `Quick Oil Service / Rapid Intake / Version 1.4 • 24` + `Target Cycle Time 12 mins` | PARTIAL (name/count); cycle-time/tag/semver DATA GAP |
| Card 3 `EV High-Voltage Battery Audit / Specialized / Version 3.1 • 45` + `Hazmat PPE Mandatory Class 00` | PARTIAL (name/count); PPE/class DATA GAP + certification/hardware claim conflict |
| Card 4 `Commercial Fleet Pre-Delivery / DOT Compliant / Version 1.8 • 80` + DOT sentences + `Asset Tagging Req. Active` | PARTIAL (name/count); DOT/compliance/certification/telematics/hardware claims = LOCKED-RULE conflict + DATA GAP |
| Card 5 `Brake & Chassis Certification / Chassis Safety / Version 2.2 • 35` + micrometer/caliper/BLE sentences | PARTIAL (name/count); certification + BLE-hardware claims = conflict + DATA GAP |
| `+ Create Custom Protocol / Assemble... thresholds... triggers / Open Template Architect` | Create/edit EXISTS; "thresholds/instant triggers" DATA GAP (no new capabilities per O7) |
| `Strict Validation Lock Enabled / ... Master Inspector sign-off... / Export Schemas (JSON) / Version Audit Log` | "Validation lock" label + `Version Audit Log` map to versions endpoint (`GET .../versions`, `template_version_page.dart`) w/ rename; "Master Inspector sign-off" = approval-gate conflict per O6; JSON schema export DATA GAP (no endpoint) |
| Shell bay/search/user | DATA GAP (same as screen 5) |

## 5. States shown / not shown

- Shown: 5 published-style cards, one tag each, grid selected, All selected, KPI values, validation-lock footnote.
- Not shown: draft/retired, empty, loading (`LoadingSkeleton`), error (`ErrorState`), zero-result filter, list view, long text, 200% scale, RTL/Arabic (publish gate requires EN/AR), dark, mobile, permission-denied, publish-validation failure, version diff.

## 6. Classification

**Matches existing feature**: template list (name · serviceType · vN · itemCount · status chip), open/create, versions/audit, Edit→builder.
**UI work only**: 3-col grid restyle, KPI "Total Checkpoints" sum, `updatedAt` relative labels (parse existing DTO field), tag chips rendered from `serviceType`/`status` only.
**Needs new data or server change**: custom tags, descriptions/photo-gate/cycle/PPE/bay fields in list payload, completion/compliance/audit metrics, list/grid preference, JSON schema export, bay binding.
**Conflicts with locked rule**: DOT/ISO/certification/compliance claims, `Master Inspector` approval gate, semver versions, invented measurements/timings, hardware (telematics/BLE/caliper) claims. Per O7 builder-only with existing template rules — no new capabilities from this screen.

## 7. New-component list

Metric card, segmented filter pill (with counts), grid/list toggle, template grid card (icon tile + tag + requirement pill + Edit), dashed create-card, footnote banner. Drawers / role selects / drag handles / tables: none.

## 8. Could not verify

- Whether custom tags are approved serviceTypes or free copy.
- Semver source (integer `versionNo` cannot yield 1.4/2.2).
- Legal basis for DOT/ISO/Certification/Class-00 claims (assume remove).
- What "bay bound" means; which metrics may use itemCount/updatedAt/versions.
- Edit-on-published labeling (must open new draft/version, never mutate).
- List-view design (toggle decorative?); rail active=Settings rationale.
