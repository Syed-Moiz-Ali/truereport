# TrueReport — Figma ↔ Product Gap Report (Phase F0)

**Status:** Read-only analysis. No application code, server, config or existing docs were modified.
**Deliverable:** `docs/ui/figma/gap-report.md` only.
**Date:** 5 November 2026

---

## 1. Method, inputs read, confidence and limits

### 1.1 Method

1. Read all **45 screen specs** under `docs/ui/figma/specs/` (10 Platform Admin, 7 Public Report, 16 Technician, 12 Workshop Admin). The specs already contain measured geometry, content mapping and conflict notes; I did **not** re-do the pixel analysis.
2. Spot-verified spec claims against the Figma exports/manifests only where needed to confirm a field/asset/screen number (e.g. the missing 11th Platform Admin 2FA screen, the stock vehicle images, the three different public hashes). I did not re-walk every node.
3. Read the authoritative product inputs:
   - `master.md` (topic scan for roles, review, public report, PDF, consent, TOTP, VIN, account creation, immutability),
   - `docs/phase-0/02-confirmed-scope.md`, `03-roles-and-permissions.md`,
   - `docs/phase-1/01-navigation-maps.md`, `02-screen-inventory.md`, `04-platform-admin-hierarchy.md`, `05-master-library-and-templates.md`, `06-public-report-design.md`, `08-api-design.md`, `10-design-system.md`, `11-security-and-privacy-design.md`, `13-adrs` (0007, 0008, 0011, 0013, 0021),
   - `docs/phase-3.5/ui-decisions.md`, `docs/phase-7/00-decisions.md`, `docs/phase-8/00-decisions.md`.
4. Read current code and data:
   - `client/packages/design_system/lib/src/{tokens,components}.dart`,
   - `client/apps/technician_app/lib/src/**` (router, models, pages, offline),
   - `client/apps/admin_app/lib/src/**` (router, models, pages),
   - `client/packages/api_client/lib/src/api_endpoints.dart`,
   - `client/packages/l10n/lib/l10n/*.arb`,
   - `server/src/main/resources/templates/report/{public-report,print-report}.html`,
   - `server/src/main/resources/public-report/report.css`,
   - `server/src/main/java/com/truereport/**` (controllers, snapshots, report mapping),
   - `server/src/main/resources/db/migration/*` (actual columns).
5. `docs/ui/DESIGN.md` and `docs/ui/apex_vehicle_inspection_ecosystem_product_prd.md` were treated as **non-authoritative** and were not used to define scope. The PRD is not evidence of an approved feature.

### 1.2 Evidence conventions

- Figma node IDs and exact strings come from the specs.
- Code paths are `file:line` where a line reference is stable.
- DB evidence uses `table.column` from Flyway migrations.
- Rule quotations are verbatim from the locked rules supplied with this task, or from the cited approved document.

### 1.3 Confidence

| Area | Confidence | Reason |
|---|---|---|
| Layout, colour, type, radii measurements | High | Specs measured from JSON/PNG; spot checks agree. |
| Current route/endpoint/field presence | High | Direct source and migration reads. |
| Product intent of each Figma screen | Medium | Static frames, no prototype, some screens mix multiple roles/product surfaces. |
| Whether sample values are real | High for "not in the model"; low for legal/asset truth | No licences, certifications, consents or source data exist in the repo. |
| Arabic/RTL wording | Medium | Arabic codepoints are present in the JSON (verified by codepoint count); the terminal display garbles them. Wording, tashkeel and bidi were not native-reviewed. |
| Real device / 200% / screen-reader behaviour | Not verified | Static exports only. |

### 1.4 Limits

- I did not run the apps, query a database, or render the server.
- I could not verify whether any ISO/DOT/ASE/ANSI/VDA licence is factually held; none is evidenced in the repo. Under the locked rule, unevidenced claims are treated as unsafe.
- I did not inspect every raster asset for licence or PII.
- Some Figma screens are internally contradictory (different vehicles, VINs, odometers and hashes for the same report). I record the contradiction rather than choosing a winner.
- The current product and the Figma use different brands (`TrueReport` vs `TechInspect`/`Apex`). I assume the Figma is a proposed redesign of the same product, not a separate white-label build.

---

## 2. Executive counts (primary classification)

**Classification labels used**

- **M — Matches:** an existing screen/route/endpoint/component genuinely covers the same job.
- **U — Needs UI work only:** the job and required data/API/state already exist; only presentation/UI is missing.
- **N — Needs new data / server / feature:** at least one material field, endpoint, model, table or state concept is absent.
- **C — Conflicts with a locked rule:** the screen/element violates a locked rule or approved decision (rule quoted in §4).
- **O — Out of scope / not understood:** different product/role, or intent cannot be determined.

Each screen has **one primary** classification. Secondary issues are recorded in the per-screen table and in §4. Public Report screens are counted as **C** primary because the dominant content of all seven violates the public-report boundary; they also need data/UI work.

| App | M | U | N | C | O | Total |
|---|---:|---:|---:|---:|---:|---:|
| Platform Admin | 1 | 5 | 4 | 0 | 0 | 10 |
| Public Report | 0 | 0 | 0 | 7 | 0 | 7 |
| Technician | 8 | 1 | 4 | 3 | 0 | 16 |
| Workshop Admin | 7 | 1 | 2 | 2 | 0 | 12 |
| **Total** | **16** | **7** | **10** | **12** | **0** | **45** |

**Reading the count**

- 16 screens (36%) are fundamentally the same job as an existing screen; they should be treated as redesigns, not new features.
- 12 screens (27%) have a locked-rule blocker that must be removed before any build decision.
- 10 screens (22%) require at least one new DB/API/model concept. This is **not** permission to build them; most are unapproved scope.
- 0 screens are genuinely "not understood"; every screen maps to a known product area. Some *elements* are different-product artefacts (Fleet Portal, marketplace quote, 360 wireframe, print studio) and are called out as out-of-scope (P3).

### 2.1 Secondary flags (not counted twice)

| App | Screens with a secondary conflict | Screens with a secondary data gap | Screens with a secondary UI-only gap |
|---|---:|---:|---:|
| Platform Admin | 8 | 5 | 3 |
| Public Report | 7 | 7 | 0 |
| Technician | 6 | 6 | 3 |
| Workshop Admin | 7 | 8 | 2 |

---

## 3. Per-screen table

`Blocking gate` uses priorities, not a build order: **P0** = locked-rule/accessibility blocker, **P1** = data/API/feature required, **P2** = UI-only, **—** = no blocker found.

### 3.1 Platform Admin (10)

| Screen | Current match (file/route/endpoint) | Primary | Secondary | Key differences | Blocking gate |
|---|---|---|---|---|---|
| 01 Global Hierarchy & Staff Tree | `hierarchy_tab.dart`; `GET /api/v1/platform/hierarchy`; `GET /api/v1/platform/workshops/{id}/hierarchy`; `HierarchyWorkshop`, `PlatformAccount` | N | C | 256 px rail/tree board, photo avatars, bay/shift/certification columns, roster pagination and throughput metrics are absent. | P1 + P0 |
| 02 Add Staff / Create Account | `hierarchy_tab.dart` dialogs; `POST /platform/users`; `POST /platform/invitations` | U | C | Dialog → 440 px drawer. "Activation token dispatched via secure push" is new delivery. Temporary password visible by default. | P2 + P0 copy |
| 03 Register New Workshop | No route/method; `PlatformController` has GET only; `Workshop` = `name/status/branch_name/timezone` | N | C | No create-workshop endpoint; no region, contact email, template assignment or sync switch. "Verified fleet standard" claim. | P1 + P0 |
| 04 Workshop Details & Settings | `GET /platform/workshops/{id}` only; no detail route/tabs/update/disable | N | C | Admin name/phone, telemetry, ISO 26262 copy, killswitch, Permissions/Audit tabs and update endpoint absent. | P1 + P0 |
| 05 Shared Master Inspection-Item Library | `master_content_tab.dart`; `/platform/master/items`; `item_form_page.dart`; publish/retire | U | N, C | Existing list/edit works. New card layout, item "type" badges, Rules Matrix, cluster count, Instant Push/sync policy. | P2 + P1/P0 |
| 06 Master Item Content & Translation Editor | `item_form_page.dart`; `/master/items/{id}/versions`, `/translations/{locale}`, `/rules`, `/publish` | U | N, C | Side-by-side EN/AR is UI-only; measurement/OEM threshold/sync/multi-image fields are absent; "Save Changes" implies in-place edit. | P2 + P0/P1 |
| 07 Master Dropdowns & Data Catalogues | `admin_api.dropdowns/createDropdown/addDropdownValue`; `/master/dropdowns`; no UI | U | N, C | No dropdown UI. Severity is a fixed enum; workshop overrides, OEM preset, publish, quick index and bulk sync are absent. | P2 + P1/P0 |
| 08 Global Equipment Library | `admin_api.equipment/createEquipment`; `/master/equipment`; no UI | U | N, C | No equipment UI. Calibration, telemetry, manufacturer/precision/connection/toggles are absent; ISO/CAT claims. | P2 + P0/P1 |
| 09 Platform Audit Events Log | `audit_tab.dart`; `GET /platform/audit-events?limit=` | M | N, C | Read-only list exists. Filters/search/export/verify/count/hash/integrity seal are new; "tamper-proof ledger"/Root CA claims. | P1 + P0 |
| 10 Global Platform Settings | No route/endpoint; only `ADMIN_TOTP_REQUIRED` flag and en/ar locale | N | C | No settings API/model. Languages, session timeout, IP allowlist, telemetry, PDF auto-distribution, ED25519 claim. | P1 + P0 |

### 3.2 Public Report (7)

All seven are server-rendered HTML at `/r/{token}` in the current product. The current renderer is `server/src/main/resources/templates/report/public-report.html`; styles are `server/src/main/resources/public-report/report.css`. There is no Flutter public app, no portal and no write endpoint.

| Screen | Current match (file/route) | Primary | Secondary | Key differences | Blocking gate |
|---|---|---|---|---|---|
| 01 Customer Summary Hero (mobile) | `public-report.html:17–92` header/summary/vehicle | C | N | Adds plate, "Certified/Verified", 95% progress, "Zero Critical Faults", EST, miles, stock vehicle photo, CTA. | P0 |
| 02 Findings by Category: Tyre (mobile) | `public-report.html:118–161` category tables; `.item` / `.photos` | C | N | Adds customer filters, axle diagram, PSI/mm measurements, quote CTA, acknowledgement write, green healthy corners. | P0 |
| 03 Exterior Condition & Evidence (mobile) | `public-report.html:94–161` key findings/categories/photos | C | N | Adds damage pin, "Acknowledge & Validate Defect", Level 1 grade, 42 mm measurement, "optical scan". | P0 |
| 04 Verification & PDF Footer (mobile) | `public-report.html:28–35, 195–204` language switch/hash/PDF gate | C | N | Adds ISO/IEC 17020 claim, "Bay #04 Certified", "Verified Snapshot", unconditional PDF CTA, wrong Arabic font. | P0 |
| 05 Wide Hero & Summary (desktop) | Same document, single column | C | N | Adds desktop nav tabs, account avatar, "Download PDF", partial VIN, pass rate, compliance matrix, live-update and "Sign & Release". | P0 |
| 06 Detailed Findings Grid (desktop) | Category tables/key findings | C | N | Adds GPS coordinates, internal zone/marker IDs, bento health cards, "Approve & Finalize Report", certification/signature. | P0 |
| 07 Limitations & Disclaimer (desktop) | `public-report.html:163–213` not-checked/limitations/details | C | N | Adds exemption protocol IDs, "Customer Waiver Signed", ISO 17020 legal box, "Download Official Certificate PDF". | P0 |

### 3.3 Technician (16)

Current routes are in `client/apps/technician_app/lib/src/technician_router.dart`: `/signin`, `/jobs`, `/jobs/new`, `/sync`, `/jobs/:id`, `/jobs/:id/checklist`, `/jobs/:id/items/:itemId`, `/jobs/:id/review`, `/jobs/:id/finalized`. There is no shell/bottom-nav, no `/settings`, `/language`, `/consent`, `/equipment`, `/photo`, `/status`, `/offline` route.

| Screen | Current match | Primary | Secondary | Key differences | Blocking gate |
|---|---|---|---|---|---|
| 01 Login & Language Selection | `sign_in_page.dart`; `/signin`; `POST /auth/login`, `/auth/2fa/verify` | M | C | Sign-in + EN/AR toggle + conditional 2FA code already exist. Adds "TechInspect" brand, ISO 27001 claim, forgot-password and Request ID (no endpoint). | P0 copy |
| 02 Assigned Jobs Dashboard | `/jobs`; `technician_jobs_page.dart`; `GET /technician/jobs` | M | N, C | Existing search/status/refresh/empty-state/walk-in/sync. Adds dashboard metrics, avatar photo, shift/bay, "Scan New VIN Tag" (deferred), Live Sync, Fleet/Profile nav. | P1 + P0 |
| 03 Empty State Dashboard | Same list `EmptyState` | M | C | Existing empty state links to Workshop Admin/walk-in. Adds "100% Pass Rate", "14 Completed", "Synced just now", Fleet. | P0 |
| 04 Job Details & Intake | `/jobs/:id`; `job_detail_page.dart`; customer/vehicle edit sheets | M | N | Existing make/model/year/VIN/plate/phone and edit sheets. Adds bay/phase/readiness/fuel/step/owner, photo, call/message. | P1 |
| 05 Consent & Signatures | `job_detail_page.dart:350–424` consent bottom sheet; `POST /technician/jobs/{id}/consent` | C | N | No signature model; customer e-signature is explicitly out of scope. Design also adds road-test/data-storage consents, pre-ticks two switches, drops public-link consent, fabricated "Recorded" signature. Current code also starts `granted = true` (a real bug). | P0 + P1 |
| 06 Equipment Checklist | `job_detail_page.dart:426+` equipment sheet; `GET /technician/jobs/{id}/equipment` | N | C | API returns IDs only; no names/descriptions/specs/verified state. ISO-9001, Bluetooth v4.2, torque range are invented. | P1 + P0 |
| 07 Main Inspection Hub | `/jobs/:id/checklist`; `checklist_page.dart`; `GET /technician/jobs/{id}/checklist` | C | U | Coverage counts are derivable, but "42 Passed", hero condition ring, "Action Items", Active Bay and "Fleet" conflict. 2×2 hub is new UI. | P0 + P2 |
| 08 360 Exterior Wireframe | None | N | C | No damage/pin/panel model, no geometry, no other views. "360", 2.5 cm, green damage pin and "1 Detected" are unsupported. | P1 + P0 |
| 09 Defect Detail & Evidence | `/jobs/:id/items/:itemId`; `assessment_page.dart`; `technicianAssessment` | M | N, C | Existing result/severity/note/reason/photos. Adds defect taxonomy, pin/defect identity, per-photo tags, "Pass" label, hardcoded "1 of 4". | P0 copy + P1 |
| 10 Photo Annotation & Markup | Photo capture exists (`photo_service.dart`, evidence init/complete); no annotation | N | C | No annotation model/route; invented 0.8 mm; HEIC input is not accepted by server MIME rules. | P1 + P0 |
| 11 Dense Mechanical List | `/jobs/:id/checklist` + `assessment_page.dart` | U | C | Accordion/inline capture is new UI; Pass/Marginal/Fail and Normal/Low/Critical are forbidden vocabulary; 5W-30/DOT 4 invented. | P2 + P0 |
| 12 Final Review (Missing Items) | `/jobs/:id/review`; `review_page.dart`; `technicianReview`; `technicianReady` | M | C | Existing coverage/blocking/warnings. Adds compliance wording, "3 Mandatory Photos Missing", signature gate, "28 Verified Data Points", "91% Complete". | P0 + P1 |
| 13 Tire Condition Capture | None | N | C | No tyre/wheel/PSI/tread model or endpoint. 7.2 mm, 34.5 PSI, Michelin model and 1.6 mm legal minimum invented. | P1 + P0 |
| 14 Offline Sync Queue | `/sync`; `sync_queue_page.dart`; `pendingOperationsProvider` | M | N, C | Existing queue/retry/status. Adds cache/transfer metrics, "Local Engine v4.2", paused state, 60 s claim, Fleet/Profile nav. | P1 + P0 |
| 15 Finalize & Approval (Swipe) | `/jobs/:id/review` + `ConfirmDialog` + `technicianFinalize` | C | U | Self-finalization exists. Design adds "Approval", sign-off/compliance, GPS, Fleet Ledger, fake signature, swipe-only gesture. | P0 |
| 16 Post-Finalization Success | `/jobs/:id/finalized`; `finalized_page.dart`; `technicianReport`, `technicianJobDeliveries` | M | N, C | Existing final status + delivery cards. Adds "Locked & Signed", Fleet Portal channel, PDF size, "uploaded", VIN ending. | P0 + P1 |

### 3.4 Workshop Admin (12)

Current routes: `/signin`, `/workshop` only. `workshop_admin_home.dart` is a 3-tab shell **Jobs / Staff / Templates**; reports and forms are pushed pages. There is no `/dashboard`, `/settings/workshop`, `/audit` surface, or `/jobs/:id/report` route.

| Screen | Current match | Primary | Secondary | Key differences | Blocking gate |
|---|---|---|---|---|---|
| 01 Create / Schedule Job | `job_form_page.dart`; `jobs_tab.dart:179`; `POST /workshop/jobs` | M | N, C | Existing form requires `templateVersionId` and scope. Design drops template/scope and adds bay, fixed 60/110 tiers, auto-assign and telematics. | P1 + P0 |
| 02 Workshop Dashboard | None; `WorkshopAdminHomePage` has no dashboard | N | C | No dashboard endpoint. Bays, capacity, accuracy, review, telemetry, "certificate" all absent/conflicting. | P1 + P0 |
| 03 Live Job Queue | `jobs_tab.dart`; `GET /workshop/jobs`; `JobDto` | M | N, C | Existing search/status list. Adds bay/progress/review state, stats, export, batch reassign, live sync. | P1 + P0 |
| 04 Assign Technician | `jobs_tab.dart:266+` bottom sheet; `POST /jobs/{id}/assign`; `AssignJobRequest` | M | N, C | Existing picker (name + masked email) and reason field in API. Adds skills/certifications, bay, workload, recall, estimate. UI still passes `null` reason. | P1 + P0 |
| 05 Workshop Staff Management | `staff_tab.dart`; `GET /workshop/staff`; `StaffMember` (5 fields) | M | C, N | Existing read-only list. Adds Add Staff, supervisor/lead roles, certifications, hours, NFC, roster PDF; counts inconsistent. | P0 + P1 |
| 06 Workshop Template List | `templates_tab.dart`; `/workshop/templates`; `TemplateSummaryDto` | M | C, N | Existing list/create. New grid, custom tags, compliance metrics, DOT/ISO claims, "Master Inspector sign-off". | P0 + P1 |
| 07 Add Staff / Create Account | None; account creation is Platform Admin-only (`POST /platform/invitations`; RQ3) | C | N | Workshop-side account creation is not approved. Full emails, "[sample temporary password - redacted]", station/NFC are new. | P0 |
| 08 Template Builder | `template_builder_page.dart`; draft/publish/retire/versions/preview | M | C, N | Existing builder. Adds custom master item, autosave, Active/Automated, measurement ranges, laser/OBD/AI, ISO-9001 QA. | P0 + P1 |
| 09 Completed Report Viewer | `report_page.dart`; `GET /workshop/jobs/{id}/report`; `ReportAdminDto`; `ReportSnapshot` | M | C, N | Existing viewer with link/PDF/delivery controls. Adds certificate seal, score, signature/QR, full VIN, telemetry, full email, findings cards. | P0 + P1 |
| 10 Share-Link Deactivation | `report_page.dart:530+` revoke bottom sheet; `POST .../link/revoke`; reason enum | U | C, N | Existing revoke works. Modal, activity log, IP/browser, free-text-only reason and "copies cannot be recalled" gap. | P2 + P0/P1 |
| 11 Workshop Settings | None; `Workshop` = name/status/branch/timezone | N | C | No settings endpoint/columns. Contact/address/region/licences/default template/auto-send/telemetry. | P1 + P0 |
| 12 Print-Ready PDF Preview | `print-report.html` (bilingual A4); `GET .../report/pdf`; `PUT .../pdf-download` | C | N | Actual PDF is bilingual with masked VIN, no plate, "Not an official certificate". Design adds certificate/ISO/APPROVED/full VIN/plate/signature, English-only preview, print settings. | P0 |

---

## 4. Detailed findings by theme

### 4.1 Design-system / token drift

**Locked rule:** *"Arabic RTL must work; WCAG 2.2 AA; colours/text styles/radii/spacing/endpoints from central tokens/classes, not hardcoded."*

**Current contract**

- `client/packages/design_system/lib/src/tokens.dart`
  - primary `#0B3B4A`, secondary `#0F6B6F`, surface `#F7FAFA`, ink `#17212B` (`tokens.dart:326–369`);
  - spacing `4/8/12/16/24/32/48` (`tokens.dart:18–26`);
  - radii `4/8/12/16/999` (`tokens.dart:84–90`);
  - status/severity pairs mirror Phase 1 (`tokens.dart:215–267`);
  - filled, borderless, tonal inputs (`tokens.dart:414–439`).
- `docs/phase-3.5/ui-decisions.md` §3–§6 requires theme-only text/colour, filled borderless inputs, 48 dp targets, 600/900/1200 breakpoints and EN/AR + light/dark + 1.5×/2.0× tests.
- Public report CSS already uses the token palette (`server/src/main/resources/public-report/report.css:19–51`), Noto Sans/Naskh Arabic/CJK, dark mode (`:53–73`), responsive `auto-fit` grids (`:221`), print styles (`:419`).

**Figma drift observed across all four apps**

| Token family | Figma | Current contract | Impact |
|---|---|---|---|
| Primary/brand | `#10B981` (emerald) and `#006C49` in nearly every screen | `#0B3B4A` / `#0F6B6F` | Every primary button, active nav, icon and success state is off-token. |
| Accent/success | `#6FFBBE`, `#10B9811A`, `#10B98133`, `#00422B`, `#002113` | `AppStatusColors.success` `#1F6B45` / `#E6F3EC` | New one-off greens; success is used as "verified/pass" rather than "received/finalized". |
| Danger | `#BA1A1A`, `#B91A24`, `#FFDAD6`, `#93000A`, `#79000E` | `#A3231F` / `#FBE9E7`, `#7F1D1D` / `#F7DADA` | Danger is not the approved pair; no destructive button variant in `AppButtonVariant`. |
| Radii | `16`, `24`, `32`, `48`, `9999` | max `16` before `pill` | 24/32/48 are outside `AppRadiiTokens`; the public report uses 4/8/12/16. |
| Spacing | `20`, `28`, `40`, `56`, `80`, `96`, `140` | `4/8/12/16/24/32/48` | Card padding, gutters and section gaps are off-scale. |
| Type | H1 `32/38`, hero `26/32`, body `13/18`, labels `11/14` | `type.h1 24/30`, `type.body 15/22`, `type.label 13/18`, `type.caption 12/16` | Larger display type and smaller body/labels than the contract; 11 px labels recur. |
| Font | `Plus Jakarta Sans`, `Liberation Mono`, `FreeSerif`, `Nimbus Sans` | Bundled system/Noto fonts; licences pending | `Plus Jakarta Sans` is licence-pending per `10-design-system.md` §2.4; `FreeSerif` cannot shape Arabic correctly. |
| Fields | white, borderless, shadowed, often 48–52 px | filled tonal `surfaceContainerHighest` + no border | Contradicts the Phase 3.5 "filled, borderless tonal inputs" decision. |
| Toggles/targets | 28–32 px switches/circles, 24 px language segments | 44 px minimum, 48 preferred | Fails WCAG 2.2 target size and the project's own 44/48 rule. |
| Contrast | white on `#10B981` ≈ 2.54:1; `#10B981` on white ≈ 2.54:1; `#E9E7ED` circles ≈ 1.2:1 | 4.5:1 text / 3:1 UI | Repeated AA failure on primary CTAs, status dots, "Verified", "Pass". |

**Missing primitives (UI-only work, but substantial)**

`SegmentedControl`, tree, metric/KPI card, bento grid, damage canvas, signature pad, annotation editor, print-preview canvas, slide-to-confirm, activity timeline, integrity seal, success medallion, photo grid with tags. `components.dart` currently provides `AppScaffold`, `AppButton` (primary/tonal/text), `AppTextField`, `AppCard`, `AppSelectableText`, `StatusChip`, `SeverityBadge`, `SectionHeader`, `AppListTile`, `EmptyState`, `ErrorState`, `LoadingSkeleton`, `OfflineBanner`, `ConfirmDialog` and `showAppBottomSheet` (`components.dart:5–744`).

**Endpoint drift:** every Figma network action must still go through `ApiEndpoints` (`client/packages/api_client/lib/src/api_endpoints.dart`). Several Figma screens imply endpoints that do not exist (settings, create workshop, equipment UI, dashboard, tyre, annotation, access log, print). Those are N/P1, not UI-only.

---

### 4.2 Navigation, shell and route differences

**Technician app**

- Current: pushed-page flow with no shell; bottom navigation is not implemented. Routes are only `technician_router.dart:31–75`.
- Figma: persistent 4-item floating nav **Intake / Fleet / Sync / Profile** on screens 02, 03, 07, 14. Documented nav is **Jobs / Sync / Settings** (`docs/phase-1/01-navigation-maps.md` §2.2).
- `Fleet` and `Profile` are out of scope: there is no fleet module, no `/fleet`, no `/profile`, and `docs/phase-0/02-confirmed-scope.md` excludes customer/portal/marketplace scope. `Intake` is not a documented tab; the job list is `Jobs`.
- Missing documented routes: `/language`, `/settings`, `/help/keyboard`, `/offline`, `/jobs/:id/status`, and distinct `/consent`, `/equipment`, `/photo` routes. The current app implements consent/equipment as bottom sheets inside job detail.
- The current job list has search, status filters, pull-to-refresh, offline/sync banner, language switch, sign-out and a walk-in FAB (`technician_jobs_page.dart`). The Figma dashboard removes most of these.

**Workshop Admin**

- Current: `/workshop` with **Jobs / Staff / Templates** tabs; `workshop_admin_home.dart:47–119`.
- Figma: rail with **Dashboard / Jobs / Settings**, plus Dashboard/Settings screens that have no route. The rail's active item is often Settings even on Templates/Staff.
- No `/dashboard`, `/settings/workshop`, `/audit` (hidden by default, RQ4), `/jobs/:jobId/report` route, or `/jobs/new` route. `JobFormPage` and `ReportPage` are pushed from the jobs tab.
- Current admin shell has no persistent global header with `BAY ACTIVE / Shop Floor #04`, search, or user chip. Those are new shell elements.

**Platform Admin**

- Current: `/platform` with **Hierarchy / Master Content / Audit** tabs; `platform_admin_home.dart:47–108`.
- Figma: persistent 256 px sidebar and split tree/detail board. That shell does not exist.
- No `/dashboard`, `/settings/platform`, `/hierarchy/workshops/:id`, `/master/dropdowns` UI, `/master/equipment` UI, `/master/media` UI or `/templates` overview. The dropdown/equipment/guide-image APIs exist, but only guide images have a UI (`MasterContentTab` includes `GuideImageManager`).

**Public Report**

- Current: one server-rendered document at `/r/{token}`, language switch via `?lang=en|ar`, optional PDF link only when `r.pdfDownloadEnabled` (`public-report.html:28–35`). No tabs, no avatar, no account menu, no other-report browsing.
- Figma desktop: app bar with three tabs ("Report Overview / Detailed Findings / Compliance & Scope"), account avatar, print/share/audit-tag controls and a footer with accreditation claims. This is a portal shell and directly conflicts with:
  - *"No admin code, no customer login, no other-report browsing"* (`06-public-report-design.md` hard rule 8);
  - *"The customer never enters an app or portal"* (`01-navigation-maps.md` §5).
- Figma mobile: CTA/chevron on summary, filter pills, acknowledgement/continue, quote, PDF CTA. None are in the current read-only document.

**Missing/incorrect role navigation**

- Technician "Fleet" tab invents an entire product area.
- Workshop Admin "Dashboard" and "Settings" are new surfaces.
- Platform Admin "Audit" is shown as a normal nav item, but Workshop Admin audit is hidden by default (RQ4) and Platform Admin audit is currently a tab, not a route.
- The Figma's "Settings" active state on Staff/Templates screens is an information-architecture error, not a route.

---

### 4.3 Screens needing data/fields not in the DB or API

Evidence is from Flyway migrations and current DTOs/records. "Absent" means no table/column/endpoint/field was found in the repo.

| Concept shown in Figma | Where it appears | Current DB / API status | Evidence |
|---|---|---|---|
| Bay / station / shift | Technician 02/04/07/09/11/12/13/15; Workshop 01–05; Platform 01/04 | **Absent.** Jobs have no `bay_id`/`station`; staff have no shift; templates have no bay binding. | `V5__workshop_templates_and_jobs.sql` `inspection_jobs` columns; `JobDto`; `StaffMember` (`models.dart:465`). |
| Certification / licence / skill level | Platform 01/05/08; Technician 01/06; Workshop 04/05/06/09/12 | **Absent.** Roles are only PLATFORM_ADMIN / WORKSHOP_ADMIN / TECHNICIAN; no certification, skill, level, issuer, expiry. | `V1__core_tenancy_auth.sql`; `V3` role checks; `StaffMember`. |
| Dashboard / throughput / latency / capacity / compliance metrics | Platform 01/04; Workshop 02/03/05/06 | **Absent.** No metric tables, no aggregation endpoint, no "dashboard" controller. | `PlatformController` GET only; `api_endpoints.dart`; `JobDto` has no progress/turnaround. |
| Tyre/wheel position, tread mm, PSI, tyre brand, axle | Technician 02/07/13; Public 02/06; Workshop 09 | **Absent.** `ReportSnapshot.ItemSnapshot` has `note` only; no tyre table/endpoint. `InspectionItem` has `minPhotos` but no measurement fields. | `ReportSnapshot.java`; `V7__inspection_execution.sql`; `api_endpoints.dart` has no tyre route. |
| Fluids, battery, OBD/DTC, voltage, CCA, underbody measurements | Technician 11; Public 06; Workshop 09 | **Absent as structured data.** Only free-text `note`/`reasonText`. | `ReportSnapshot.ItemSnapshot`; `InspectionAssessment`. |
| Damage pin / panel / defect type / severity grade / annotation geometry | Technician 08/09/10; Public 03/06 | **Absent.** No damage/mark/annotation table; evidence stores hash/mime/bytes/dimensions only. | `V9__evidence_uploads.sql`; `EvidenceAsset`; `offline_models.dart` `SyncOperation`. |
| Signature capture, signer, timestamp, signature payload | Technician 05/12/15; Workshop 12; Public 03/06 | **Absent, and customer e-signature is explicitly out of scope.** Consent body has only `consentType/status/wordingVersion/channel`. | `job_detail_page.dart:384–400`; `docs/phase-0/02-confirmed-scope.md` excludes "Customer e-signatures or customer approval of findings". |
| Consent wording hash / per-channel consent UI | Technician 05; Workshop 11 | **Partly absent.** API records type/status/wordingVersion/channel, but not a wording hash/evidence object; current UI offers only `PROCESSING` and `PUBLIC_LINK`. | `job_detail_page.dart:350–424`; `ADR-0008`. |
| Public plate / full VIN / coordinates / precise location | Public 01/05/06; Workshop 12 | **Absent by design.** Snapshot stores `vinMasked` only; no plate/coordinates. Adding them would violate the allowlist. | `ReportSnapshot.Vehicle`; `ReportSnapshotBuilder.maskVin`; `06-public-report-design.md` §3.2. |
| Public customer identity / portal account | Public 05/06 | **Absent by design.** Customer is a record, not a login; snapshot has no customer. | `02-confirmed-scope.md` roles table; `ReportSnapshot`. |
| Public access log: view count, last viewed, IP, user-agent, client activity | Workshop 10 | **Absent.** `public_share_links` stores status, PDF flag, activated/revoked timestamps, reason code/note only. | `V10__reports_public_links.sql`. |
| Audit filters/search/export/count/integrity hash | Platform 09 | **Partly absent.** `audit_events` has action/actor/entity/reason/metadata; controller accepts only `limit`; no export, search, count, hash or block paging. | `V2__audit_events.sql`; `PlatformHierarchyController`. |
| Platform settings (localization, session timeout, 2FA toggle, IP whitelist, telemetry, webhooks, PDF auto-hook) | Platform 10 | **Absent.** No settings table/endpoint; only `ADMIN_TOTP_REQUIRED` config and `en/ar` locale. | `api_endpoints.dart`; `PlatformController`; `ADR-0021`. |
| Create/update/disable workshop; contact, address, region, licence | Platform 03/04 | **Absent.** `Workshop` only `name/status/branch_name/timezone`; `PlatformController` only GET. | `V1`, `V3`; `PlatformController`. |
| Workshop settings: contact, address, default template, auto-send, photo policy, telemetry | Workshop 11 | **Absent.** No settings endpoint/columns; delivery is explicit per-job with consent. | `V5`; `V12`; `docs/phase-7/00-decisions.md` §2. |
| Master item "Mandatory/Standard/Structural/High Voltage Cert", rules matrix, sync policy, OEM threshold, measurement metric, secondary images | Platform 05/06/07/08 | **Absent.** `master_item_versions` has result/severity/note/evidence/equipment/guide image only; no measurement/OEM/sync/multi-image. | `V4__master_content.sql`; `ItemVersion`; `TemplateItemView`. |
| Dropdown workshop overrides, OEM preset, bulk publish, quick index | Platform 07 | **Absent.** Only dropdown list/values endpoints. | `MasterContentController`; `admin_api.dart`. |
| Equipment manufacturer/category/precision/connection/calibration/telemetry/toggles | Platform 08 | **Absent.** `equipment` has code/status/sort + localized labels only. | `V4`; `Equipment`. |
| Template custom item, autosave, Active/Automated, measurement range, laser/OBD/AI, QA policy | Workshop 08 | **Absent.** Builder supports name/description/service/vehicle, item add/remove/reorder, save draft, publish, retire, versions, preview. | `template_builder_page.dart`; `V5`. |
| Staff hours, shift, NFC, availability, roster PDF, skills | Workshop 05 | **Absent.** `StaffMember` has 5 fields. | `staff_tab.dart`; `StaffMember`. |
| PDF size, page count, signature, licence, print orientation, prepress status | Workshop 12; Technician 16 | **Absent.** `ReportAdminDto` has `pdfReady/pdfDownloadEnabled`; no size/page/signature/licence. | `ReportAdminDto` (`models.dart:814`); `V10`. |
| "Fleet Portal" delivery channel | Technician 16 | **Absent.** Channels are WhatsApp/SMS/email. | `V12`; `TechnicianDelivery`. |
| Vehicle hero/stock image | Public 01/05; Technician 04/07/15; Workshop 09 | **Absent from snapshot.** Snapshot carries `evidenceIds`, not a vehicle image. | `ReportSnapshot.ItemSnapshot`; `V9`. |
| Public per-photo caption/tag, typed defect taxonomy, recommendation | Public 02/03/06 | **Partly absent.** `evidenceIds` only; public mapper generates "Evidence" caption. `ItemSnapshot` has no recommendation. | `public-report.html:108–113`; `ReportSnapshot.ItemSnapshot`. |
| "Mechanical health"/"Zero Critical Faults"/"Optimal"/"100% Nominal" | Public 01/05/06 | **Absent as a field.** Key findings are rule-based (DEFECT_FOUND/ATTENTION_RECOMMENDED). | `ReportSnapshotBuilder:90–94`; `report_page.dart:407–423`. |

---

### 4.4 Conflicts with locked rules (quote + exact evidence)

The locked rules are quoted exactly. Each conflict is a blocker regardless of how attractive the layout is.

#### A. Certification, "verified", compliance and official claims

**Rule:** *"Public report never shows customer name, phone, email, full VIN or plate; no certification, "verified by" or compliance claims; no single unexplained condition score."*
Supporting approved text: `docs/phase-1/06-public-report-design.md` §12 *"Do not use 'certified', 'independently reviewed', 'manager approved' or 'RTA approved' unless factually and legally true."*; `docs/phase-8/00-decisions.md` §3 *"Legal claim: None. This is not a compliance certification."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Public 04 | *"Conforms to ISO/IEC 17020 and fleet compliance directives."* (`1:6273`); *"Bay #04 Certified"* (`1:6288`) | ISO accreditation and bay certification claims; no accreditation record exists. Highest-severity public conflict. |
| Public 01/02/03/04 | *"Certified Inspection Report"* (`1:5949`), *"Verified"* pill (`1:5951`), verified seal icon (`1:5944`) | Certification/verification claim on a read-only inspection. |
| Public 05/06/07 | *"Verified Session"*, *"ISO 9001:2015 Accredited"*, *"Official Inspection Dossier"*, *"Tamper-Proof Audit Vault"* (`1:6328`, `1:6545`, `1:6542`) | Official/accreditation/infrastructure claims with no evidence. |
| Public 05/06 | *"Sign & Release Fleet Certificate"* (`1:6535`); *"Technician Certification & Signature"*, *"ASE Master Tech #48102-L"*, *"VDA 6.3 standards"* (`1:6870`) | Certificate and credential claims; no signature or credential model. |
| Public 07 | *"Download Official Certificate PDF"* (`1:7025`); *"certified bay timestamp above"* | Certificate noun and incoherent "above" timestamp. |
| Workshop 12 | *"VEHICLE INSPECTION & COMPLIANCE CERTIFICATE"*, *"ISO 17020"*, *"APPROVED"*, *"Licence #DOT-CA-994012"*, *"Master Inspector ASE #40921"*, *"TechInspect Certified Facility"* (`1:2979+`) | A customer-facing PDF rendered as a certificate with invented licences. |
| Platform 09 | *"TAMPER-PROOF LEDGER"*, *"SHA256: 9b2d...f4e1"*, *"All entries signed with CoreOS Platform Root CA. 0 validation anomalies found across 14,802 historic blocks."* (`1:5356`, `1:5536`) | Product stores an append-only database, not a PKI/blockchain ledger. |
| Platform 04 | *"Active node authenticated via ISO 26262 diagnostic relay."* (`1:4036`) | ISO 26262 is a functional-safety standard; it does not authenticate a workshop node. |
| Platform 05/06/07 | *"High Voltage Cert"*, *"OEM minimum threshold 3.00 mm Standard"*, *"18 Hubs"*, *"SYNCED: 48 Workshop Clusters"* | Certification and authoritative-source claims with no model. |
| Platform 08 | *"ISO Certified"* (`1:5161`), *"CAT IV 1000V"* (`1:5236`), *"All certified devices"* (`1:5262`) | Device certification claims not evidenced. |
| Technician 01 | *"ISO 27001 Certified Fleet Security"* (`1:7130`) | Compliance/certification claim. |
| Technician 06 | *"ISO-9001 certified diagnostic requirements"* (`1:7724`) | Certification claim. |
| Workshop 11 | *"DOT Certified #99401-AF"*, *"Compliant with ANSI Tier-4 EV & Combustion Fleet standards"*, *"certified vehicle inspection slips"* | Certification/compliance claims; no fields. |
| Workshop 06 | *"DOT Compliant"*, *"OEM ISO-9001 sync"*, *"Brake & Chassis Certification"*, *"Master Inspector sign-off"* | Certification plus approval. |

#### B. Scores, percentages, "pass" and false reassurance

**Rule:** *"Public report ... no single unexplained condition score."*
Supporting: `06-public-report-design.md` §12 *"Coverage, not a single condition score."*; `10-design-system.md` §3.3 *"`NO_ISSUE_OBSERVED` must never be labelled 'Pass', 'Perfect' or 'Certified'."*; §1 *"Never use a green 'pass' badge that implies the vehicle is perfect."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Public 01 | *"95%"* + progress bar (`1:6004`); *"Zero Critical Faults Detected"* (`1:6025`); green check/shield | Condition score and absolute reassurance; current product deliberately says "Coverage is not a condition score." |
| Public 05 | *"OVERALL COMPLIANCE"*, *"95%"*, *"Pass Rate"*, *"104 Passed / 4 Minor Advisory / 2 Pending"*, *"Exterior Chassis: Optimal"* (`1:6398–6420`, `1:6369`) | Pass rate and aggregate health. |
| Public 06 | *"Passed (46)"*, *"100% Nominal"*, *"HEALTH 98%"*, *"0 Faults Logged"*, *"Laser Geometry Verified"* (`1:6597+, 1:6737, 1:6796`) | Multiple single-number health claims. |
| Technician 03 | *"100% Pass Rate"* (`1:7358`) | Forbidden pass score. |
| Technician 07 | *"42 Passed"* (`1:7792`), hero `45/110` ring (`1:7773`) | Forbidden "Passed" label; ring is a condition-style hero score. |
| Technician 12 | *"28 Verified Data Points"*, *"91% Complete"* (`1:8447+`) | Invented counts/percentage; ambiguous completion vs condition. |
| Technician 15 | *"104 Checks Completed"*, *"2 Defects Found"* (`1:8822+`) | A defect count is acceptable only if labelled as findings; the surrounding "sign off"/compliance copy makes it a verdict. |
| Workshop 02 | *"100% ACCURACY"*, *"99.4% Inspection Compliance"*, *"76% CAPACITY"* (`1:363+`, `1:448+`) | Vanity/operational scores with no definition; 76% contradicts 12/14 bays. |
| Workshop 09 | *"98.1% Specification Compliance"*, *"Target Fleet Threshold: >95.0%"* (`1:2305`) | Exactly the forbidden single condition score. |
| Platform 01 | *"PASS RATE VELOCITY 99.1%"*, *"LIVE UTILIZATION 94.2%"*, *"AVG INSPECTION TIME 18.4m"* (`1:3460–3483`) | Unexplained operational scores. |

#### C. Customer PII, contact details and avatars

**Rule:** *"Public report never shows customer name, phone, email, full VIN or plate."*
Supporting: `11-security-and-privacy-design.md` §7.3 *"Mask phone/email in UI and logs"*; `phase-7/00-decisions.md` *"The admin UI does not collect or display full customer contact details. It displays only masked recipients and status/error metadata."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Workshop 09 | *"fleet-compliance@apex.io"*, *"Apex Logistics Fleet Ops"* (`1:2442`) | Full recipient email in an admin viewer; API exposes `recipientMasked` only. |
| Workshop 12 | *"fleet-compliance@apex.io"* (`1:2947`) | Same, and this is a customer-facing PDF preview. |
| Workshop 07 | *"m.vance@techinspect.io"*, *"a.lindqvist@techinspect.io"*, *"r.kapoor@techinspect.io"*, *"[sample temporary password - redacted]"* | Full staff emails + sample password; current API returns `emailMasked` only. |
| Platform 01 | Four real photographic staff portraits (JPEG) | Personal data with no consent/licence evidence; manifest reports 0×0 dimensions. |
| Technician 02/03/15 | Photo avatar of a person (and vehicle photos) | Internal PII/asset provenance; must not be reused publicly. |
| Public 01/05 | Stock vehicle photo presented as the inspected vehicle | Not evidence and not a generic brand image; licence unknown and model does not match. |

No public screen shows a customer name or phone. That is correct and must be preserved.

#### D. Full/partial VIN, plate and precise location

**Rule:** *"Public report never shows customer name, phone, email, full VIN or plate."*
Supporting: `06-public-report-design.md` §3.2 **Never public** includes *"Full VIN, plate, registration, engine number"*; §2.2 *"No customer name or vehicle model in the metadata/title."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Public 01 | *"License Plate / LV71 XZP"* (`1:5988`) | Plate is never public and is not in `ReportSnapshot`. |
| Public 05 | *"VIN Reference: VF1KZ040647 / EU Matched"* (`1:6432`) | Full/partial VIN; current snapshot only has `vinMasked`. |
| Public 06 | *"LAT 52.88 / LON 14.02"* (`1:6637`); *"Zone B-4"*, *"Point Marker #01"* | Precise location and internal IDs are explicitly never public. |
| Public 06 | *"DOSSIER #APX-88294 · PORSCHE MACAN GTS (2023)"* | Vehicle model belongs in the vehicle section, not the title/metadata. |
| Workshop 12 | *"VIN 1FTBR1Y85RKB92104"*, *"7XYZ994 (CA)"* (`1:2979+`) | Full VIN and plate on a customer-facing PDF; actual `print-report.html` uses `vinMasked` and omits the plate. |
| Workshop 10 | *"VIN: WP0AA2Y15PSA90412 · RO #8829-FLT · Bay 04"*; *"share.shopflow.io/r/Taycan-8829"* | Full VIN in a screenshot-prone modal; guessable URL instead of a 256-bit token. |
| Technician 04/07/15 | Full VIN/plate on internal screens | Allowed internally, but must never flow to public/PDF/logs; the design does not show masking rules. |

#### E. PDF download and certificate controls

**Rule:** *"Public report is server-rendered HTML (D4) with bilingual PDF (D5)."* Decision **D8 / ADR-0008**: *"PDF download from the public page is disabled by default. No download control in V1."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Public 04 | *"Download PDF Report"* (`1:6305`) | Unconditional body CTA; no `pdfDownloadEnabled` state or consent. |
| Public 05 | *"Download PDF"* in the app bar (`1:6570`) | Same; appears as a portal action. |
| Public 07 | *"Download Official Certificate PDF"* (`1:7025`) | PDF + certificate; both forbidden. |
| Workshop 12 | *"Download PDF"*, *"Send Email to Client"*, *"Direct System Print"*, print toggles | Admin PDF exists, but this is a certificate-style customer artifact; print settings have no endpoint. |
| Workshop 09 | *"Download PDF"*, *"Resend WhatsApp/SMS"* | Admin actions exist, but the design omits consent/link/PDF-disabled state and adds a certificate seal. |

Current code is correct: `public-report.html:33` renders the PDF link only when `r.pdfDownloadEnabled`; `report_page.dart:113–126` handles admin PDF and the toggle. **Do not copy the Figma public PDF controls.**

#### F. Manager role, review, approval and sign-off

**Rule:** *"No manager role, review queue, customer app/portal or in-platform payments."*
Supporting: `02-confirmed-scope.md` *"There is no manager role, no second-person review, no approval queue, and no resubmission workflow."*; `10-design-system.md` §3.2 *"Do not add `PENDING_REVIEW`, `APPROVED`, `REJECTED` or `RESUBMITTED`."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Workshop 03 | *"Pending Review (3)"*, *"REVIEW ITEMS"*, *"2 Flags Marked"*, *"Awaiting Review"* (`1:563–620`) | Invents a review state and queue. |
| Workshop 02 | *"Secondary structural markup awaiting lead inspector review"*, *"Awaiting Review"*, *"Signed Off"* (`1:382–447`) | Second-person review and approval. |
| Workshop 06 | *"Strict Validation Lock Enabled"*, *"Checklist changes require Master Inspector sign-off before field deployment."* (`1:1586`) | Approval gate and invented "Master Inspector" role. |
| Workshop 05 | *"Shop Floor Supervisor"*, *"Lead Inspector"*, *"Lead Master"* | Manager-like hierarchy not in the three-role model. |
| Platform 04 | *"Primary authority for job sign-offs and diagnostic overrides."* | Sign-off/override authority. |
| Platform 05 | *"Dual Tech Signoff"* | Two-person approval. |
| Technician 15 | *"Finalize & Approval"*, *"sign off"* | The product's action is self-finalization, not approval. |
| Public 05/06 | *"Sign & Release Fleet Certificate"*, *"Approve & Finalize Report"* | Write/approval actions in a public page. |

#### G. Editability of finalized findings/reports and versioning

**Rule:** *"Finalized findings, evidence and reports never editable by anyone."* Decision **D9 / ADR-0007**: *"Do not build any correction UI or API in V1. No 'edit report', 'fix finding', 'reissue' or 'new version' action is exposed."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Platform 06 | *"Save Changes"* (`1:4732`), *"Audit Version 4.1"* | In-place edit of master content; ADR-0014 requires a new draft version. |
| Platform 05 | *"Edit"* on canonical items; *"Instant Push"* | In-place edit/live propagation of published master content. |
| Platform 07 | *"Changes automatically sync to active work orders"*, *"Pushed down ... every 4 hours"* (`1:5004`) | Mutates in-progress work and contradicts pinned snapshots. |
| Public 05 | *"Sign & Release Fleet Certificate"*; *"Updated Real-Time"* | Write and live-state actions on a frozen snapshot. |
| Public 06 | *"Approve & Finalize Report"*, *"Audit Trail Log"* | Write and internal audit on a public page. |
| Public 02/03 | *"Acknowledge and Continue to Brakes"*, *"Acknowledge & Validate Defect"* | Public write actions; the page is read-only. |
| Workshop 09 | *"Digital Certification Seal ... cryptographically signed"* | Implies an edit/sign event that does not exist. |
| Workshop 10 | *"Client Activity Log"*, *"Damage Markup #02 Zoomed"* | Client interaction tracking; not part of a read-only public page. |

Current product correctly has no correction/edit path; `ReportSnapshot` is frozen and the public renderer only reads it. Do not add Figma "edit"/"push"/"sign" actions.

#### H. Consent flows

**Rule:** *"Public report is server-rendered HTML (D4)..."* and decision **ADR-0008**: *"Record separate, versioned consents: processing, public link, WhatsApp, SMS, email, PDF download (if enabled). ... No active link without recorded public-link consent. ... No message without channel-specific consent."* `02-screen-inventory.md` T07: *"never pre-ticked."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Technician 05 | Two switches ON by default (`1:7557`, `1:7569`); labels *"Allow PDF sharing"*, *"Customer road test consent"*, *"Data storage authorization"* | Pre-ticked consent; drops the public-link consent; invents channels. |
| Technician 05 | *"Recorded"* badge, cursive signature, *"Timestamp: Today, 14:38 EST"* | Fabricated consent evidence; wrong timezone. |
| Technician 05 | current code `granted = true` (`job_detail_page.dart:353`) | Current product also pre-selects granted; this is a real defect independent of Figma and must be fixed. |
| Workshop 11 | *"Auto-Send PDF to Customers ... upon technician sign-off"* (`1:2779+`) | Bypasses per-send channel consent; delivery is explicit today. |
| Public 07 | *"Customer Waiver Signed"*, *"Customer declined ..."* (`1:6978–6981`) | Consent records are **Never public** (`06-public-report-design.md` §3.2). |
| Workshop 10 | Free-text-only reason; *"This will instantly block customer access"* | Server accepts only `PRIVACY/SECURITY/LEGAL/CUSTOMER_REQUEST/OTHER`; omits "copies cannot be recalled". |

#### I. Signatures and fabricated evidence

**Rule:** *"Finalized findings, evidence and reports never editable by anyone."* `02-confirmed-scope.md` excludes *"Customer e-signatures or customer approval of findings."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Technician 05 | Signature pad labelled *"Required"*, prefilled cursive sample, *"Recorded"* | No signature model; a prefilled sample would be fabricated evidence. |
| Technician 15 | *"Digital signature and GPS coordinates will be permanently appended to Fleet Ledger #2024-FLT-0982."* | Invents a signature, GPS and external ledger. |
| Workshop 09/12 | *"Digitally cryptographically signed by Inspector Marcus Vance"*, signature SVG, *"URN: fleet:inspect:..."* | No signing key/QR/ledger; only a SHA-256 snapshot hash. |
| Public 06 | *"Technician Certification & Signature"*, *"ASE Master Tech #48102-L"* | Public signature/credential claim. |

#### J. Hardware, BLE, OBD, tread depth, PSI, telematics

**Rule:** *"UI layer only; no change to business logic, API contracts, models, validation, permissions, state management or server."* and *"Never invent versions, licences, measurements or results."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Technician 06 | *"Bluetooth module v4.2 · Tap to verify"*, *"Preset 120-140 Nm"*, *"Fe / NFe substrate probe"*, *"Digital laser calibration"* | No pairing/calibration model or hardware integration. |
| Technician 11 | *"OBD-II"*, barcode button, *"5W-30 synthetic"*, *"DOT 4 standard"* | No OBD/telemetry or fluid spec fields; device scanning absent. |
| Technician 13 | *"7.2 mm"*, *"34.5 PSI (Norm)"*, *"Michelin Pilot Sport 4S"*, *"Legal Minimum: 1.6 mm"* | No tyre model; legal threshold is jurisdiction-specific. |
| Technician 10 | *"0.8 mm Scuff"*, *"IMG_0842.HEIC"* | Invented measurement; HEIC is not accepted by the upload MIME rules. |
| Public 02/06 | *"31.0 PSI (Low)"*, *"2.4 mm"*, *"5.4mm Avg"*, *"12.78V"*, *"840 CCA"*, *"14.3V"*, *"18mA"* | No structured measurement fields in the snapshot. |
| Platform 08 | *"0.01mm Precision"*, *"120-140 Nm"*, *"CAT IV 1000V"*, *"BLE 5.0"*, *"Signal Locked"*, *"Auto Zeroing"* | No device telemetry/calibration data. |
| Platform 10 | *"Real-Time Telematics Ingestion ... WEBSOCKET STREAMING ACTIVE"*, *"OBD relays"* | No telematics/OBD integration. |
| Workshop 08 | *"Laser Gauge Integration"*, *"Tire Quad-Sensor"*, *"Direct BT calibration on"* | No integrations; master content is Platform Admin-only. |
| Workshop 06 | *"Digital Caliper Sync / BLE Ready"*, *"Hazmat PPE Mandatory Class 00"* | Hardware/certification claims. |
| Workshop 05 | *"Auto-Shift NFC Badging Active"*, *"Terminal 3 logged 14 seamless shop floor entries"* | No NFC/terminal data. |

#### K. Timezone, currency and units

**Rule:** *"Never invent versions, licences, measurements or results."* Supporting: `06-public-report-design.md` §3.1 *"Include time zone (GST/UTC+4)"*; `03-localization-and-rtl-rules.md` §3.2 uses `Asia/Dubai` in the product default.

| Screen | Exact sample text / element | Why |
|---|---|---|
| Public 01 | *"October 24, 2024 · 14:32 EST"* | Wrong zone; product display is GST/UTC+4. |
| Public 05 | *"14:32 EST"* | Same. |
| Technician 05 | *"Today, 14:38 EST"* | Same. |
| Technician 15 | *"Today 14:48 PST"* | Same, different invented zone. |
| Platform 04/09 | *"14:28 EST"*, *"Today, 14:32 EST"* | Audit is UTC; display conversion is not defined as EST. |
| Technician 04/07/15; Public 01/05 | *"34,180 mi"*, *"12,480 mi"*, *"24,812 mi"*, *"14,820 mi"* | Odometer unit/approval inconsistent; UAE product uses km; different values for the same VIN. |
| Technician 13; Public 02/06 | *"34.5 PSI"*, *"31.0 PSI"*, *"2.4 mm"*, *"3/32 in."*, *"0.75 hrs"* | Mixed units and fabricated measurements; no unit/locale source. |

No currency or payment amount was found in the exports (good), but the public marketplace/quote CTA (Public 02) is payment-adjacent and out of scope.

#### L. Invented versions, hashes, IDs and measurements

**Rule:** *"Never invent versions, licences, measurements or results."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Public 04/05/07 | Three different hashes for one report: `9b2d...f4e1` (`1:6288`), `4f98...d71a` (`1:6450`), `89c41f` (`1:7023`) | One immutable version can only have one hash. |
| Workshop 12 | *"PDF Ready (v2.1)"*, *"File Size 2.4 MB (Vector HQ)"*, *"4K"*, *"Page 1 of 1"*, *"Prepress Verified"* | `version` is an integer; no file size/page/prepress data. |
| Platform 01 | *"Core Platform v4.2"*, *"GRID V4.2 ONLINE"* | No product version field. |
| Technician 14 | *"Local Engine v4.2"*, *"148.6 MB"*, *"0.0 KB/s"*, *"every 60 seconds"* | No storage/speed metrics; retry policy is exponential backoff. |
| Technician 13 | *"Michelin Pilot Sport 4S"*, *"Step 6 of 8"* | No tyre catalogue/step model. |
| Platform 06 | *"3.00 mm Standard"*, *"Audit Version 4.1"*, *"18 Hubs"* | No measurement/OEM/version/hub model. |
| Workshop 12 | *"VIN 1FTBR1Y85RKB92104"*, *"Odometer: 14,820 mi"* vs Workshop 09 *"24,812 mi"* | Same VIN, two odometers. |
| Public 05 vs 06 | *"Renault Megan 3"* vs *"Porsche Macan GTS (2023)"*; 110 vs 48 checks; 5.4 vs 2.4 mm | Different vehicles/counts/measurements for the same report. |

#### M. Public portal and write actions

**Rule:** *"No manager role, review queue, customer app/portal or in-platform payments."* Supporting: `01-navigation-maps.md` §4.3 *"There is no search, directory, 'other reports', account menu, booking, payment or contact form. The only interactive controls are language switch, optional photo zoom, print and, only if approved later, PDF download."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Public 05 | Three nav tabs, account avatar, print/share/audit tag (`1:6550+`) | Portal shell and internal audit access. |
| Public 02 | *"Request Tyre Replacement Quote"* (`1:6151`) | Marketplace/booking/payment cue; no backend. |
| Public 02/03 | *"Acknowledge and Continue to Brakes"*, *"Acknowledge & Validate Defect"* | Write/acknowledgement state. |
| Public 05/06 | *"Sign & Release Fleet Certificate"*, *"Approve & Finalize Report"* | Write/approval actions. |
| Public 04/07 | Download CTAs | PDF control (also §E). |
| Public 05 | *"Updated Real-Time"* | Live-state claim contradicts the frozen snapshot. |

#### N. TOTP / 2FA and admin security claims

**Rule:** *"D12/admin TOTP (ADR-0013/0021)."* ADR-0021: `ADMIN_TOTP_REQUIRED` default **false**; *"The admin app has no TOTP challenge UI."*

| Screen | Exact sample text / element | Why |
|---|---|---|
| Platform 10 | *"Enforce 2FA (TOTP) for All Admins"* shown ON; *"Mandatory hardware security key or authenticator app"* (`1:5707–5709`) | Contradicts the default and the hardware-key exclusion. |
| Platform 09 | *"Dual-Factor Approved"* (`1:5484`) | Implies TOTP enforcement that may be off. |
| — | No 2FA/TOTP enrolment or recovery screen in the export | The PRD claims 11 Platform Admin screens; only 10 exist. The missing TOTP screen is not designed, and ADR-0021 says no admin TOTP UI while off. |
| Current | `sign_in_page.dart` has a conditional 2FA code field after a challenge; no enrolment/recovery UI | The shared sign-in is ahead of the Figma here; keep the server flag as the source of truth. |

#### O. UI-layer-only violations (new business logic disguised as UI)

**Rule:** *"UI layer only; no change to business logic, API contracts, models, validation, permissions, state management or server."*

The following screens cannot be delivered as UI-only even if the visuals are simplified:

- Platform 03/04/10 (workshop create/update, platform settings).
- Workshop 02/11 (dashboard, settings).
- Technician 05 (signature/consent model), 08 (damage model), 10 (annotation model), 13 (tyre model), 15 (GPS/ledger).
- Workshop 12 (print settings/preview).
- Public 02/03/04/05/06/07 (portal, filters, measurements, PDF, approve).
- Any "auto-send", "real-time", "telemetry", "NFC", "OBD", "AI", "compliance score" element.

---

### 4.5 Public report: Figma vs current server-rendered document

**Current public report sections** (`server/src/main/resources/templates/report/public-report.html`):

| Section | Current content | Verdict |
|---|---|---|
| Header | `TrueReport` brand, neutral title, report number + version, language link, optional PDF (`:17–37`) | Keep; Figma replaces with customer/workshop brand and "Certified". |
| Summary | Coverage text, key-findings count, inspection date/scope, "Coverage is not a condition score." (`:40–59`) | Keep; Figma replaces with 95% progress and drops the disclaimer. |
| Vehicle | Make/model/year, `vinMasked`, conditional odometer, workshop/branch, technician display name, template version (`:62–92`) | Keep; Figma adds plate, full VIN, vehicle photo. |
| Key findings | Severity badge, note, reason, photo derivatives (`:94–116`) | Keep; Figma adds health/verdict copy and captions. |
| Findings by category | Table: result/severity/note/reason + photos (`:118–161`) | Keep; Figma replaces with cards, filters, axle diagram, measurements. |
| Not checked | Result + reason table (`:163–181`) | Keep; Figma converts to exemption cards with internal protocol IDs. |
| Limitations | Approved limitations, disclaimer, "Not an official certificate.", revocation notice (`:183–193`) | Keep; Figma replaces with ISO/liability claims. |
| Report details | Report ID, version, finalized, published, verification hash (`:195–204`) | Keep; Figma elevates to "Verified Snapshot"/crypto card. |
| Footer | Report number, version, workshop (`:207–213`) | Keep; Figma adds reference/accreditation claims. |

**Public sections we already have:** neutral header, language switch, coverage (counts + disclaimer), vehicle with masked VIN, workshop, technician, template, key findings, category tables, not-checked reasons, limitations, disclaimer, anti-certification statement, report identity, hash, optional gated PDF.

**UI-only additions that would be safe if they never change data or semantics:**

- Better typography/spacing/cards within the existing token set.
- Responsive layout and print CSS improvements.
- A clearer coverage presentation that keeps "coverage, not a score" and shows completed/applicable/not-applicable/not-checked/could-not-verify.
- A safer language switch and focus/zoom treatment.
- A photo lightbox that remains keyboard accessible and uses derivatives only.
- Report-ID/version/finalized/workshop footer consistency with the PDF.
- A bilingual PDF that matches the public page (already implemented in `print-report.html`).

**Public additions that need new snapshot data (and are therefore N/P1, not UI-only):**

- Per-category counts and per-item recommendation (not in `ReportSnapshot`).
- Photo captions beyond "Evidence" (only `evidenceIds` exist).
- A coverage percentage (the renderer receives a preformatted `coverage.text`; no numeric percentage field).
- A vehicle image (no snapshot image field).
- Any structured tyre/measurement/health/defect taxonomy (no fields).

**Public elements that are forbidden regardless of data:**

- Customer name/phone/email/address/precise location.
- Full VIN, plate, registration, engine number.
- Certification/"verified by"/compliance/"official" claims.
- Single condition score/pass rate/health/percentage verdict.
- PDF default download/certificate download.
- Write actions (acknowledge/approve/sign/release/quote).
- Portal shell (tabs, avatar, other reports, search, print/share token exposure).
- Internal IDs, consent records, audit events, delivery logs, IP/device data.
- Original high-resolution evidence or EXIF/GPS.

**PDF comparison**

| Aspect | Current `print-report.html` | Figma Workshop 12 |
|---|---|---|
| Language | Bilingual EN + AR grids (`:18`, `:64–69`, `:108–116`) | English-only preview |
| VIN | `vinMasked` (`:101`, `:111`) | Full VIN `1FTBR1Y85RKB92104` |
| Plate | Absent | `7XYZ994 (CA)` |
| Certificate claim | `Not an official certificate.` (`:65`, `:211`) | `CERTIFICATE`, `APPROVED`, `ISO 17020`, `Licence #DOT-CA-994012` |
| Signature/QR | None | Signature line, QR-like seal, `ASE #40921` |
| Content | Snapshot categories/notes/limitations/hash | Invented metrics, tests, 4K photos, labour estimate |
| Orientation/page | Fixed A4; no controls | Portrait/landscape, page count, prepress toggles |

---

### 4.6 Admin, Workshop and Platform: what exists vs new

#### Current admin surfaces (evidence)

| Surface | Code/endpoint | What it really does |
|---|---|---|
| Workshop jobs | `jobs_tab.dart`; `GET /workshop/jobs`; `JobDto` | Search, status chips, job list, create form, assign sheet, report page. No bay/progress/review/export. |
| Create job | `job_form_page.dart`; `POST /workshop/jobs`; `JobCreateRequest` | Customer/vehicle/scope/schedule/template; requires `templateVersionId`. |
| Assign | `jobs_tab.dart:266+`; `POST /jobs/{id}/assign`; `AssignJobRequest` | Technician picker (name + masked email); reason accepted by API but UI passes `null`. |
| Staff | `staff_tab.dart`; `GET /workshop/staff`; `StaffMember` | Read-only 5-field list + explicit "Platform Admin creates accounts" copy. |
| Templates | `templates_tab.dart`, `template_builder_page.dart`, `template_version_page.dart`; `/workshop/templates`, draft/publish/retire/versions/preview | List + 4-field create dialog + builder + version history + EN/AR preview. |
| Report | `report_page.dart`; `GET /workshop/jobs/{id}/report`; `ReportAdminDto` | Status, link activate/revoke, PDF toggle/download, delivery send/history. |
| Platform hierarchy | `hierarchy_tab.dart`; `/platform/hierarchy`, `/workshops/{id}/hierarchy` | ExpansionTile cards + account rows; no rail/tree board. |
| Account creation | `hierarchy_tab.dart` dialogs; `POST /platform/users`, `/platform/invitations` | Create with temp password or invite; returns invite token. |
| Master content | `master_content_tab.dart`; `/platform/master/categories`, `/items`; `item_form_page.dart` | Category/item list, item editor with translations/rules/equipment/guide image, publish/retire, versions. Guide image manager. |
| Dropdowns/equipment | `admin_api.dart`; `/master/dropdowns`, `/master/equipment` | API only; no UI. |
| Audit | `audit_tab.dart`; `/platform/audit-events?limit=` | Read-only event list; action/actor/entity/time/reason/metadata. |

#### What is genuinely new in Figma

| Area | New surfaces/features | Status |
|---|---|---|
| Platform | Workshop create/update/disable, platform settings, dashboard metrics, equipment/dropdown UI, master rules matrix/sync, access-log activity | No model/endpoint (N/P1). |
| Workshop | Dashboard, workshop settings, staff management, template grid/metrics, print studio, review state | No model/endpoint or conflicts (N/C). |
| Technician | Bottom-nav shell, dashboard stats, hub, 360/damage, annotation, tyre capture, signature, swipe finalize, offline metrics | Mostly N/C; some out of scope. |
| Public | Portal shell, filters, measurements, health, PDF/certificate, write actions | Forbidden (C/P0). |

#### Role/permission conflicts

- **RQ3:** `ADR-0011` and `master.md` say Platform Admin creates all accounts; Workshop Admin does not create accounts in V1. `docs/phase-1/02-screen-inventory.md` A07 says "account creation hidden by default (RQ3)". `docs/phase-1/08-api-design.md` marks `POST /workshop/staff/invitations` "No by default". The Figma **Workshop Admin 07 Add Staff / Create Account** directly contradicts this.
- **No manager role:** "Supervisor", "Lead Inspector", "Lead Master", "Master Inspector", "Principal Admin" are not roles. The only roles are PLATFORM_ADMIN / WORKSHOP_ADMIN / TECHNICIAN (`V1`/`V3`; `StaffMember`).
- **Platform PII:** Platform Admin should not see customer contact details by default (`ADR-0011`; `04-platform-admin-hierarchy.md` §5.2). Figma hierarchy does not show customer PII (good), but Workshop 09/12 show full recipient email.
- **Audit:** Workshop Admin audit is hidden by default (RQ4). The Figma shows `Shop Audit Trail` IDs in the revoke modal and a full audit page in Platform; the current Workshop app has no audit tab.
- **TOTP:** Platform 10 shows 2FA ON; ADR-0021 default off. Platform 09 shows "Dual-Factor Approved". The missing 11th TOTP screen is not a licence to add one while the flag is off.

#### Master-content editing/versioning

- Current is correct: `item_form_page.dart` creates/updates a **draft** version, then publish/retire; `template_builder_page.dart` saves draft/publishes a new version; old reports keep snapshots (`ADR-0014`, `ADR-0016`).
- Figma regresses:
  - Platform 06 **"Save Changes"** + **"Audit Version 4.1"** imply in-place edit.
  - Platform 05 **"Edit"** on the canonical list + **"Instant Push"** implies live mutation.
  - Platform 07 **"Changes automatically sync to active work orders"** would mutate pinned jobs.
  - Workshop 08 **"Create Custom Diagnostic Item"** contradicts `05-master-library-and-templates.md` §5.1: *"A missing item can be requested from Platform Admin; the Workshop Admin cannot create a master item."*
  - Workshop 08 **"Autosave Active"** is a new persistence state; current is explicit save draft/publish and an unsaved-change warning.

#### Audit claims

- Current: append-only DB audit (`V2`), `AuditEvent` with `action/occurredAt/actorRole/entityType/reasonCode/metadataJson`; no hash, signature, export or verify.
- Figma: *"TAMPER-PROOF LEDGER"*, *"Cryptographic ledger"*, *"SHA256: 9b2d...f4e1"*, *"Ledger Integrity Seal: 0x489F...A39E"*, *"CoreOS Platform Root CA"*, *"0 validation anomalies across 14,802 historic blocks"*.
- `11-security-and-privacy-design.md` §6.3 says append-only, not blockchain; §7/§14 explicitly says immutability *"does not make data immutable against a privileged database administrator."* The Figma overclaims.

---

### 4.7 Unsafe-to-ship sample content (consolidated)

This is a non-exhaustive consolidated list. Exact strings are preserved. All are unsafe because they are wrong, invented, or contrary to a locked rule.

| # | Screen | Exact string/element | Why unsafe |
|---:|---|---|---|
| 1 | Public 04 | "Conforms to ISO/IEC 17020 and fleet compliance directives." | ISO accreditation/compliance claim; no record. |
| 2 | Public 04 | "Bay #04 Certified" | Bay certification claim. |
| 3 | Public 04/05/07 | "Download PDF Report", "Download PDF", "Download Official Certificate PDF" | PDF disabled by default (ADR-0008) and certificate noun. |
| 4 | Public 01 | "License Plate / LV71 XZP" | Plate never public. |
| 5 | Public 05 | "VIN Reference: VF1KZ040647 / EU Matched" | Full/partial VIN never public. |
| 6 | Public 06 | "LAT 52.88 / LON 14.02" | Precise location never public. |
| 7 | Public 01 | "95%" + progress bar; "Zero Critical Faults Detected" | Condition score and false reassurance. |
| 8 | Public 05 | "OVERALL COMPLIANCE", "Pass Rate", "104 Passed" | Pass/score language. |
| 9 | Public 05/06 | "Sign & Release Fleet Certificate", "Approve & Finalize Report" | Write/approval in a public page. |
| 10 | Public 02 | "Request Tyre Replacement Quote" | Marketplace/payment-adjacent; no backend. |
| 11 | Public 02/03 | "Acknowledge and Continue to Brakes", "Acknowledge & Validate Defect" | Public write actions. |
| 12 | Public 07 | "Customer Waiver Signed" | Consent record never public. |
| 13 | Public 07 | "Download Official Certificate PDF" | Certificate + PDF. |
| 14 | Public 05/06 | "ISO 9001:2015 Accredited", "Tamper-Proof Audit Vault", "Official Inspection Dossier" | Accreditation/infrastructure claims. |
| 15 | Public 01 | "October 24, 2024 · 14:32 EST" | Wrong timezone. |
| 16 | Public 01 | "34,180 mi" | Unit/approval mismatch. |
| 17 | Public 02 | "31.0 PSI (Low)", "2.4 mm" | Invented measurements. |
| 18 | Public 03 | "Level 1 (Cosmetic)", "approx 42mm" | Invented grade/measurement. |
| 19 | Public 06 | "ASE Master Tech #48102-L", "VDA 6.3 standards" | Invented credentials. |
| 20 | Technician 01 | "ISO 27001 Certified Fleet Security" | Certification claim. |
| 21 | Technician 03 | "100% Pass Rate" | Forbidden pass score. |
| 22 | Technician 03 | "Queue is current · Synced just now" | False sync claim. |
| 23 | Technician 02/07 | "Scan New VIN Tag" | VIN scanning is deferred. |
| 24 | Technician 05 | "Allow PDF sharing" ON; "Customer road test consent" ON | Pre-ticked consent. |
| 25 | Technician 05 | "Recorded" + cursive sample + "Today, 14:38 EST" | Fabricated signature and wrong timezone. |
| 26 | Technician 06 | "ISO-9001 certified diagnostic requirements", "Bluetooth module v4.2", "120-140 Nm" | Certification/hardware/measurement claims. |
| 27 | Technician 07 | "42 Passed" | Forbidden pass label. |
| 28 | Technician 08 | "360", "2.5 cm Crease", green damage pin | Overclaim, invented measurement, wrong danger colour. |
| 29 | Technician 10 | "0.8 mm Scuff", "IMG_0842.HEIC" | Invented measurement; unsupported format. |
| 30 | Technician 11 | "Pass / Marginal / Fail", "Normal / Low / Critical", "5W-30", "DOT 4" | Forbidden result vocabulary and invented specs. |
| 31 | Technician 13 | "7.2 mm", "34.5 PSI", "Michelin Pilot Sport 4S", "Legal Minimum: 1.6 mm" | Invented measurements/legal claim. |
| 32 | Technician 14 | "Local Engine v4.2", "148.6 MB", "0.0 KB/s", "every 60 seconds" | Invented version/metrics/policy. |
| 33 | Technician 15 | "Digital signature and GPS coordinates ... Fleet Ledger #2024-FLT-0982" | Fabricated signature/GPS/ledger. |
| 34 | Technician 15 | "Slide to Finalize Inspection" | Gesture-only irreversible action; no accessible alternative. |
| 35 | Technician 16 | "Locked & Signed", "Fleet Portal / Synced", "PDF SIZE 2.4 MB" | Fabricated signature/channel/size. |
| 36 | Workshop 02 | "100% ACCURACY", "99.4% Inspection Compliance", "Signed Off" | Score/certification/approval. |
| 37 | Workshop 03 | "Pending Review", "REVIEW ITEMS", "2 Flags Marked" | Review queue. |
| 38 | Workshop 05 | "Add Staff", "Shop Floor Supervisor", "EV Certified", "Level 4" | RQ3 violation, manager role, certification. |
| 39 | Workshop 06 | "DOT Compliant", "OEM ISO-9001 sync", "Master Inspector sign-off" | Certification/approval. |
| 40 | Workshop 07 | "[sample temporary password - redacted]", full staff emails, "STN 04" | Credential/PII/station. |
| 41 | Workshop 08 | "ISO-9001 brake testing standards", "Laser Gauge Integration", "Tire Quad-Sensor" | Certification/hardware. |
| 42 | Workshop 09 | "Passed Certification Stage", "98.1% Specification Compliance", "Digital Certification Seal" | Certificate/score/signature. |
| 43 | Workshop 10 | "share.shopflow.io/r/Taycan-8829", "Action logged ... ID #ACT-9902" | Guessable URL and exposed audit ID. |
| 44 | Workshop 11 | "DOT Certified #99401-AF", "ANSI Tier-4", "Auto-Send PDF ... upon sign-off" | Certification/consent bypass. |
| 45 | Workshop 12 | "VEHICLE INSPECTION & COMPLIANCE CERTIFICATE", "ISO 17020", "APPROVED", "Licence #DOT-CA-994012", full VIN/plate | Certificate/licence/PII on a customer PDF. |
| 46 | Platform 01 | "ISO-9001 Lead", "PASS RATE VELOCITY 99.1%", "Core Platform v4.2" | Certification/score/version. |
| 47 | Platform 04 | "Active node authenticated via ISO 26262 diagnostic relay", "450 Total Jobs", "Latency: 14ms" | ISO misuse and invented metrics. |
| 48 | Platform 05 | "High Voltage Cert", "Dual Tech Signoff", "Instant Push" | Certification/review/live mutation. |
| 49 | Platform 06 | "3.00 mm Standard", "Save Changes", "Audit Version 4.1" | Invented measurement and in-place edit. |
| 50 | Platform 07 | "Defect Severities – Grading definitions (P0–P3)", "Changes automatically sync to active work orders" | Invented severity scale and mutability. |
| 51 | Platform 08 | "ISO Certified", "CAT IV 1000V", "0.01mm Precision" | Certification/measurement. |
| 52 | Platform 09 | "TAMPER-PROOF LEDGER", "CoreOS Platform Root CA", "14,802 historic blocks" | Fabricated PKI/ledger. |
| 53 | Platform 10 | "Enforce 2FA (TOTP) for All Admins" ON, "ED25519-SHA512", "99.98% SLA" | TOTP default conflict, invented algorithm/SLA. |

---

## 5. What matches well (preserve these)

### 5.1 Technician

- **Sign-in**: email/password, language toggle, validation, conditional 2FA code (`sign_in_page.dart`). The Figma's visual language can be applied, but keep the real auth states and brand `TrueReport`.
- **Jobs list**: search, status filters (ASSIGNED/IN_PROGRESS/READY_TO_FINALIZE/FINALIZED), pull-to-refresh, sync badge, walk-in creation, empty state (`technician_jobs_page.dart`).
- **Job detail**: make/model/year, VIN, plate, odometer, customer, schedule, template, start/resume, customer and vehicle edit sheets, consent and equipment sheets (`job_detail_page.dart`).
- **Checklist**: grouping by category, progress `completed/total`, per-item sync state, local/offline behaviour (`checklist_page.dart`).
- **Assessment**: item label/instruction, result options from the pinned template, severity, note, reason, evidence photos, save (`assessment_page.dart`).
- **Review**: coverage, blocking/warning lists, deep links to items, disabled finalize until ready (`review_page.dart`).
- **Finalization**: explicit confirm dialog, idempotency key, server-confirmed `FINALIZED` (`review_page.dart`; `ADR-0017`).
- **Finalized page**: report number/version, generation status, delivery cards, masked recipients (`finalized_page.dart`).
- **Sync queue**: per-operation state, conflict/danger tone, retry, empty state (`sync_queue_page.dart`).

### 5.2 Workshop Admin

- **Jobs list + filters** (`jobs_tab.dart`), **create job form** (`job_form_page.dart`), **assign/reassign bottom sheet** with API reason support (`AssignJobRequest`).
- **Staff read-only list** and the explicit "Platform Admin creates accounts" message (`staff_tab.dart`).
- **Template list/builder/version history/EN-AR preview** (`templates_tab.dart`, `template_builder_page.dart`, `template_version_page.dart`).
- **Report viewer**: report status, link activate/revoke with reason codes, PDF toggle/download, delivery send/history (`report_page.dart`). This is the best base for the Figma viewer; keep its state controls rather than the certificate layer.

### 5.3 Platform Admin

- **Hierarchy + staff tree** (`hierarchy_tab.dart`, `/platform/hierarchy`), including masked emails and role/status.
- **Create/invite account dialogs** (`/platform/users`, `/platform/invitations`).
- **Master content**: category/item list, bilingual item editor, rules/equipment/guide image, draft/publish/retire/versions (`master_content_tab.dart`, `item_form_page.dart`).
- **Audit read-only list** with actor/entity/time/reason (`audit_tab.dart`).

### 5.4 Public report and PDF

- **Server-rendered HTML (D4)** with neutral metadata, `noindex`, `no-referrer`, semantic sections, skip link, language switch and no JS requirement (`public-report.html:1–215`).
- **Public allowlist**: `vinMasked`, no plate/customer/coordinates, workshop/technician, category tables, not-checked reasons, limitations, anti-certificate disclaimer, report ID/version/finalized/published/hash (`ReportSnapshot.java`; `public-report.html`).
- **"Coverage is not a condition score."** (`public-report.html:47`).
- **Bilingual PDF (D5)**: A4, EN/AR grids, `vinMasked`, no plate, disclaimer, `Not an official certificate.`, `verificationHash` (`print-report.html`; `ChromiumPdfRenderer`/`ReportPdfService`).
- **Token/registry**: `public_share_links` status machine `PENDING_CONSENT → ACTIVE → REVOKED`, 256-bit token hash, PDF flag, revocation reason (`V10`; `ADR-0008`, `ADR-0010`).
- **Design tokens**: Phase 1 palette, spacing, radii, status/severity pairs, dark mode, Noto Arabic/CJK fonts (`tokens.dart`; `report.css:19–51`).

### 5.5 Cross-cutting

- **Immutability**: snapshot builder masks VIN, redacts customer/VIN/plate in notes, freezes findings (`ReportSnapshotBuilder:90–159`); report versions are immutable; no correction path (`ADR-0007`).
- **Consent model**: separate `PROCESSING`/`PUBLIC_LINK` consent types are recorded, and the link stays inactive without public-link consent (`ADR-0008`; `job_detail_page.dart`). The *pre-selection* is a bug to fix, not a reason to abandon the model.
- **Localization**: `en`/`ar` UI, Arabic content/font support, `zh-Hans` font fallback and print CSS; D10 remains satisfied for content (not UI).
- **Tested design system**: `flutter analyze`, EN/AR RTL, light/dark, 1.5×/2.0× text and reduce-motion are already covered (`docs/phase-3.5/ui-decisions.md` §9).

---

## 6. Prioritised gap list

Priorities are about **risk and classification**, not a build order. P0 must be resolved (usually by removal) before any design is considered buildable.

### P0 — Locked-rule and accessibility blockers

| # | Gap | Evidence | Required resolution |
|---:|---|---|---|
| P0-1 | Certification/compliance/verified/official claims | Public 04/05/06/07, Workshop 12, Platform 04/05/08/09, Technician 01/06, Workshop 06/11 | Remove all unevidenced certification/licence/credential strings; keep only `Not an official certificate.` and factual inspection language. |
| P0-2 | PDF download/certificate controls on the public page | Public 04/05/07; ADR-0008 | Remove the controls in V1; keep the `r.pdfDownloadEnabled` gate. |
| P0-3 | Public VIN/plate/precise location | Public 01/05/06; Workshop 12 | Remove; never add these fields to the public DTO. |
| P0-4 | Single score/pass/health/percentage/verdict language | Public 01/05/06; Technician 03/07/12; Workshop 02/09; Platform 01 | Remove; publish coverage counts + the existing "coverage is not a condition score" text. |
| P0-5 | Public write/portal/quote/approve/sign actions | Public 02/03/05/06; nav/avatars | Remove; keep only language switch, optional photo zoom, print and the gated PDF. |
| P0-6 | Manager/review/approval constructs | Workshop 02/03/05/06; Platform 04/05; Technician 15 | Remove; self-finalization only; no `PENDING_REVIEW`/`APPROVED`. |
| P0-7 | In-place edit/live-mutation of published/finalized content | Platform 05/06/07; Public 05/06; Workshop 08/09 | Replace with draft/new version/publish; no "Save Changes"/"Instant Push"/"Sign & Release". |
| P0-8 | Pre-ticked consent and fabricated signatures/waivers | Technician 05; Workshop 11; Public 07 | Remove pre-selection; separate consents incl. public link; no fake signature/waiver; fix current `granted = true`. |
| P0-9 | Hardware/measurement/telemetry inventions | Technician 06/10/11/13/14; Public 02/06; Platform 08/10; Workshop 06/08/12 | Remove or source from an approved model; no PSI/mm/Nm/BLE/OBD/NFC/4K values. |
| P0-10 | Wrong timezone/units | Public 01/05; Technician 05/15; Platform 04/09; odometer samples | Remove EST/PST/mi/PSI; use workshop timezone and snapshot unit. |
| P0-11 | RQ3 account-creation conflict | Workshop 07; ADR-0011; `02-screen-inventory.md` A07; `08-api-design.md` | Keep account creation Platform-Admin-only unless RQ3 is separately approved. |
| P0-12 | TOTP default conflict | Platform 10/09; ADR-0021 | Do not show 2FA ON while `ADMIN_TOTP_REQUIRED=false`; no TOTP screen unless the flag is enabled. |
| P0-13 | Contrast/target/typography accessibility | Every screen: 2.54:1 emerald, 11 px labels, 28–32 px controls | Use tokens and 4.5:1/3:1 pairs; 44/48 px targets; 200% text. |
| P0-14 | Token/font hardcoding | Every screen: emerald, 24/32/48 radii, 20/28/40/56 spacing, Plus Jakarta/FreeSerif | Map to `tokens.dart`/`report.css`; bundle a licensed Arabic font; no raw hex. |

### P1 — Needs new data/server/feature (not approved by existing docs)

| # | Gap | Evidence | Why it is P1 |
|---:|---|---|---|
| P1-1 | Bay/station/shift model | Technician 02/04/07/09/11/12/13/15; Workshop 01–05; Platform 01/04 | No columns/endpoints; multi-screen dependency. |
| P1-2 | Tyre/wheel/tread/PSI model | Technician 13; Public 02/06; Workshop 09 | No table/endpoint; cannot be derived from `ItemSnapshot`. |
| P1-3 | Damage/pin/annotation model | Technician 08/09/10; Public 03/06 | No damage/annotation tables or evidence metadata. |
| P1-4 | Signature/consent evidence model | Technician 05/12/15; Workshop 12 | No signature storage; customer e-signature is out of scope, so this may not be approved at all. |
| P1-5 | Public access log/IP/view analytics | Workshop 10 | `public_share_links` has no view/IP/device columns. |
| P1-6 | Platform settings + workshop create/update/disable | Platform 03/04/10 | `PlatformController` GET only; no settings table. |
| P1-7 | Workshop settings/contact/default template/auto-send | Workshop 11 | `Workshop` has only 4 fields; no settings endpoint. |
| P1-8 | Dashboard/throughput metrics | Platform 01/04; Workshop 02/03/05/06 | No aggregation endpoint/model; examples are contradictory (12/14 vs 76%). |
| P1-9 | Audit filters/search/export/count/hash | Platform 09 | Only `limit` is supported; no export/verify/integrity seal. |
| P1-10 | Master metadata: item type/rules matrix/sync/OEM/measurement/multi-image | Platform 05/06/07/08; Workshop 08 | No columns/endpoints; would be new business concepts. |
| P1-11 | PDF size/page count/print settings/preview | Workshop 12; Technician 16 | No data/endpoint; PDF is server-generated with fixed A4. |
| P1-12 | Staff skills/availability/hours/NFC | Workshop 04/05; Platform 01 | `StaffMember` has 5 fields. |
| P1-13 | "Fleet Portal" channel | Technician 16 | Delivery channels are WhatsApp/SMS/email. |
| P1-14 | Vehicle image/hero photo | Public 01/05; Technician 04/07/15; Workshop 09 | Snapshot has evidence IDs only; no vehicle image field. |

### P2 — UI-only (data/API/state already exist)

| # | Gap | What already exists | UI work |
|---:|---|---|---|
| P2-1 | Platform account drawer (02) | create/invite endpoints | 440 px drawer, validation/loading/success states. |
| P2-2 | Master item side-by-side EN/AR editor (06) | item versions/translations/rules/publish | Two-column editor without new fields; keep draft/publish. |
| P2-3 | Dropdown/equipment UI (07/08) | list/create endpoints | List/detail forms limited to existing code/labels/status. |
| P2-4 | Master library card layout (05) | item list/edit | Cards, chips, search/filter; no type/sync badges. |
| P2-5 | Admin report viewer restyle (09) | `report_page.dart` + `ReportAdminDto` | Cards/typography; keep link/PDF/delivery state controls. |
| P2-6 | Share-link modal (10) | revoke bottom sheet + reason enum | Dialog with reason codes + consequence text; no free-text-only. |
| P2-7 | Technician sign-in restyle (01) | `sign_in_page.dart` | Brand/tokens/2FA states; no ISO/forgot/request flows. |
| P2-8 | Technician job list/detail/empty restyle (02/03/04) | existing pages/data | Dashboard visuals using derived counts only; no new metrics/bay/photo. |
| P2-9 | Checklist/assessment restyle (09/11) | checklist + assessment | Accordion/inline capture can be UI; keep exact result vocabulary. |
| P2-10 | Final review/finalized restyle (12/16) | review/finalized pages | Cards/progress; keep warnings and delivery states. |
| P2-11 | Public report responsive/card/print restyle | HTML/CSS/tokens | Typography, cards, photo grid, print CSS; no new sections or claims. |

### P3 — Nice-to-have / out of scope

| # | Item | Why P3 |
|---:|---|---|
| P3-1 | 360 exterior wireframe | No damage model; "360" asset set absent; new product feature. |
| P3-2 | Photo annotation/markup studio | No annotation model; new product feature; HEIC unsupported. |
| P3-3 | Tyre capture step | New model/hardware-adjacent; not approved. |
| P3-4 | Print-ready PDF studio | New preview/print settings; actual PDF is a server template. |
| P3-5 | Fleet tab / Fleet Portal | Out of scope; no module/role. |
| P3-6 | In-platform quote/marketplace | Explicitly excluded; workshop handles payment. |
| P3-7 | Telematics/OBD/BLE/NFC/AI | Future/out of scope; no integrations. |
| P3-8 | Customer signature/approval | Explicitly excluded by `02-confirmed-scope.md`. |
| P3-9 | Platform/workshop dashboards with vanity metrics | Not approved; would need new aggregation and definitions. |
| P3-10 | Vehicle hero/stock images | Not evidence; licence/model risk. |

---

## 7. What I could not verify

1. **Prototype behaviour.** The exports contain no reactions; all navigation, filter, swipe, drawer, zoom and carousel behaviour is inferred from layout and labels.
2. **Exact Arabic strings.** Arabic is present in the JSON (codepoint check), but I did not native-review the wording, tashkeel or bidi isolates. A native-speaker review is still required.
3. **Font/asset licences.** `Plus Jakarta Sans`, `Liberation Mono`, `FreeSerif`, the four staff portraits and all stock vehicle photos have no licence/provenance evidence in the export.
4. **Legal truth of certifications.** No ISO 17020/27001/9001/26262, DOT, ASE, VDA or ANSI certificate or accreditation record exists in the repo. I treat them as unevidenced, not as fact.
5. **Whether RQ3/RQ4/RQ7/RQ8 changed after the cited ADRs.** I found no later approval; `ADR-0011` (Platform Admin creates accounts, audit hidden, no reactivation) and `ADR-0008` (PDF off) are the latest records I could read.
6. **Whether the 11th Platform Admin "2FA/TOTP" screen exists outside the exported package.** The export and `package-manifest.json` contain 10 screens; the PRD's claim of 11 is not supported by the export. ADR-0021 says no admin TOTP UI while the flag is off.
7. **Contrast of every colour pair.** I computed the key ones (emerald/white 2.54:1, `#E9E7ED` ~1.2:1, warning text) but did not run a full contrast audit on all 45 screens.
8. **Responsive behaviour below 1200 px.** Every desktop Figma frame is fixed at 1280; every technician frame is fixed at 390. There is no tablet/phone/RTL variant for the admin screens and no Arabic variant for any screen.
9. **Real-device camera, keyboard, 200% text, screen-reader and print behaviour.** Static exports only.
10. **Current app visual output.** I matched by source code, not by running the app; some runtime states (loading, error, empty) were inferred from widgets.
11. **Whether any sample data is intentionally fictional.** The specs mark much of it as sample; I did not query a database to see what is seeded.
12. **Payment/currency scope.** No currency or payment amount appears in the exports; I did not find payment tables, but I did not exhaustively search every server file for payment-adjacent code. The public quote CTA is treated as out of scope regardless.

---

## 8. Bottom line

- The Figma set is **not a UI refresh of the current product**. It is a different product direction with portal, certification, review, telemetry, hardware and marketplace elements.
- **16 of 45 screens** genuinely match existing jobs and can be redesigned without new data; **7** are UI-only once conflicting copy is removed; **10** need new data/server concepts; **12** are blocked by locked rules.
- The current product is already stronger than the Figma on the things that matter most: **immutable snapshots, masked VIN, no public PII, no certification claims, no review role, no public write actions, a server-rendered public page, a bilingual PDF, and a token-based design system**.
- The correct F0 outcome is to **preserve the current public report and data boundaries**, use the Figma only where it maps to an existing job, and reject the certification/score/portal/approval/hardware layers rather than trying to "restyle" them.
