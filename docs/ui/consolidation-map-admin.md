# Workshop Admin consolidation map (Step 0 audit — read-only, 9 Nov 2026)

**Status: AUDIT ONLY. No code changed, no deletions, nothing committed. Stop at this gate.**

Scope: Workshop Admin app first (`client/apps/admin_app`, Workshop Admin role), then Platform Admin and public report later. Technician screens (1–7, 9, 11, 13–16) must not regress. Steps 1+ need owner approval before any edit.

Normative inputs read: `master.md` (v0.3); `docs/ui/c0-report.md` (C0 account model, light-only, 433/433 ARB at the time); `docs/ui/i18n-inventory.md` (C0 Workstream C). Two referenced files **do not exist** and were rebuilt from audit evidence instead:

- `docs/ui/UI_INPLACE_ALIGNMENT_PROMPT.md` — **not found** (only `docs/ui/FIGMA_UI_F2A_1_PROMPT.md` and `docs/ui/ui-reset-map.md` exist). Standing rules applied from the session prompt itself: existing centralized components/theme, one component per role, one file per screen, ARB for every string (EN+AR), light-only, no logic/API/model/validation/permission/state change.
- `docs/ui/figma/f3-slot-sheet.md` — **not found** (only `docs/ui/figma/f2a1-slot-sheet.md` exists; only `f2a1-slot-sheet.md` matches `docs/ui/figma/*.md`). A dangling reference to it exists in `docs/ui/figma/fidelity/forbidden-terms-admin-product.json:3` (rows 41–47). Slot decisions below are rebuilt from the audit (§4, §8).

Owner prerequisite: `git tag before-consolidation` **exists** (verified `TAG FOUND`), but the working tree is **dirty** (`M client/apps/admin_app/lib/src/screens/f3b/completed_report_assets.dart`, `M spikes/public-report/flutter/lib/main.dart`, `D tools/add_import.dart`). Recommend a clean snapshot before Step 2.

## 1. Figma source mapping (verified against `package-manifest.json`)

Folder number prefix ≠ screen number. Confirmed each folder vs its `.json` + `@2x.png`:

| Screen | Figma frame | Folder |
|---|---|---|
| 1 Dashboard | `1. Workshop Dashboard` (1:299, 1280×1230.67) | `screens/02_1._Workshop_Dashboard` |
| 2 Queue | `2. Live Job Queue` (1:529, 1280×1125) | `screens/03_2._Live_Job_Queue` |
| 3 Create/Schedule drawer | `3. Create / Schedule Job` (1:2, 1280×1058) | `screens/01_3._Create_-_Schedule_Job` |
| 4 Assign dialog | `4. Assign Technician` (1:821, 1280×1120) | `screens/04_4._Assign_Technician` |
| 5 Staff | `5. Workshop Staff Management` (1:1026, 1280×1048) | `screens/05_5._Workshop_Staff_Management` |
| 6 Create Technician | `6. Add Staff / Create Account` (1:1642, 1280×1024) | `screens/07_6._Add_Staff_-_Create_Account` |
| 7 Template List | `7. Workshop Template List` (1:1307, 1280×1586) | `screens/06_7._Workshop_Template_List` |
| 8 Template Builder | `8. Template Builder` (1:1882, 1280×1251.5) | `screens/08_8._Template_Builder` |
| 9 Report Viewer | `9. Completed Report Viewer` (1:2236, 1280×1680.75) | `screens/09_9._Completed_Report_Viewer` |
| 10 Deactivation | `10. Share-Link Deactivation` (1:2502, 1280×1024) | `screens/10_10._Share-Link_Deactivation` |
| 11 Settings (**ON HOLD**) | `11. Workshop Settings` (1:2645, 1280×1674) | `screens/11_11._Workshop_Settings` |
| 12 PDF Preview | `12. Print-Ready PDF Preview` (1:2857, 1280×1227.58) | `screens/12_12._Print-Ready_PDF_Preview` |

No login frame exists in the Workshop Admin Figma export (Step 3 will derive from technician login).

## 2. Screen map: what renders each screen, router status, state vs Figma

Router (`admin_app/lib/src/admin_router.dart:22-60`) has only 4 routes: `/signin`, `/platform`, `/platform`-only tabs, `/workshop` (tabs 0–3), `/unauthorized`. No sub-routes; dialogs/sheets are overlays (`show*`), builder pages are `MaterialPageRoute` pushes.

| Screen | Renders it (router-used file **bold**) | Router? | State vs Figma |
|---|---|---|---|
| 1 Dashboard | **`pages/dashboard_tab.dart`** → `screens/f3a/dashboard_view.dart` (+ `dashboard_assets.dart`) | Yes (tab 0) | 3 KPI numbers live via `jobCountsProvider`; `recentJobs` plumbed but never read — activity feed, telemetry donut, bays, shifts are hardcoded Figma static |
| 2 Queue | **`pages/jobs_tab.dart`** → `screens/f3a/queue_view.dart` (+ `queue_assets.dart`) | Yes (tab 1) | `jobsProvider` accepted but `_main()` renders 4 static `_CardData` (Porsche/Ford/Renault/BMW) + static filter counts, bay chips, `Avg 42m`; `onOpenJob` never passed/invoked |
| 3 Create drawer | **`pages/schedule_job_sheet.dart`** (`WorkshopSideSheet`, 420 drawer) | Overlay only (from dashboard + jobs tabs) | Closest to backend parity: customer/vehicle/scope/scheduledAt + `templateVersionOptionsProvider` tier cards + `POST /workshop/jobs`; date picker is custom (no Figma calendar claim) |
| 4 Assign dialog | **`pages/assign_technician_dialog.dart`** (`WorkshopDialog`, 512 centered) | **No production call site** (tests only) | Matches slot spec (ACTIVE TECHNICIAN only, assign/reassign, reject FINALIZED/CANCELLED); queue cards have no tap handler wiring it |
| 5 Staff | **`pages/staff_tab.dart`** → `screens/f3b/staff_view.dart` (+ `staff_assets.dart`) | Yes (tab 2) | Pixel-static shell: 6 hardcoded cards (David/Marcus/Sarah/Arthur/Liam/Elena), metrics `87.5%/100%/3 Leads`, `Auto-Shift NFC` banner; live `staffProvider` passed as `staffList` but never read for cards |
| 6 Create Technician | **`pages/create_technician_sheet.dart`** (`WorkshopSideSheet`) | Overlay only (from staff tab) | Backend-backed (`POST /workshop/technicians`, 12–128 policy, `EMAIL_EXISTS`); no role picker/station/magic-link (no server counterpart) |
| 7 Template List | **`pages/templates_tab.dart`** → `screens/f3b/template_list_view.dart` (+ `template_list_assets.dart`) | Yes (tab 3) | Static 5-card grid + 4 KPI + footnote are Figma copy; `templates` list drives only `Active Blueprints` count; `_onNewTemplate` → `POST /workshop/templates` → pushes builder |
| 8 Template Builder | **`pages/template_builder_page.dart`** (+ `template_version_page.dart` read-only) | Push only (from templates tab) | Backend-backed for modelled subset (catalog, reorder, draft/publish/retire, EN/AR preview); custom items, autosave, Active/Automated flags, numeric ranges, semver, time estimates explicitly omitted |
| 9 Report Viewer | `pages/report_page.dart` (generic `AppScaffold`+`ListView`) + `report_pdf_saver*.dart` | **Unreachable** (no route/push; `onOpenJob` never wired) | Data layer complete (status/link/controls/deliveries), but layout is a functional admin console, not the Figma 9 pixel build; PDF is download-only |
| 10 Deactivation | Inside `report_page.dart:578-636` (`_revoke` bottom sheet: PRIVACY/SECURITY/LEGAL/CUSTOMER_REQUEST/OTHER + note → `POST …/report/link/revoke`) | **No standalone screen** (and host page unreachable) | Reason codes + note supported; no Figma-10 pixel screen in `admin_app` |
| 11 Settings | **Nothing** — no file, route, provider, or API | N/A (on hold) | Unimplemented by design; no settings endpoint |
| 12 PDF Preview | **Nothing as viewer** — only download via `report_page.dart:645-656` → `saveReportPdf` (io/web/stub) | N/A | No in-app preview layout; `pdfReady`/`pdfDownloadEnabled` flags + bytes only |
| Login (new) | **Nothing in `admin_app`** — only shared `packages/auth` `SignInPage`+`SignInView` via `/signin` | Yes (`/signin`) | Step 3 derives one "Admin sign in" screen from technician login; role redirect already exists (`platformAdmin→/platform`, `workshopAdmin→/workshop`, else `/unauthorized`) |

### Dead code (routes never reached in `lib/`)

1. `pages/job_form_page.dart` — full-page create form, superseded by `ScheduleJobSheet`, zero imports/pushes.
2. `pages/report_page.dart` — zero pushes, no route (host for screens 9/10/12 logic).
3. `pages/assign_technician_dialog.dart` `WorkshopAssignDialog.show` — zero `lib/` call sites.
4. `pages/template_version_page.dart` — reachable only via builder push, not router.
5. `screens/f3b/completed_report_assets.dart` (327 lines SVG constants) — orphan, no importing view, zero `lib/` importers.
6. Plumbed-but-unread params: `WorkshopQueueView.jobs`, `WorkshopDashboardView.recentJobs` (+ `counts` except 3 KPI ints) — static Figma copy rendered instead.

## 3. Backend mapping (existing backend only; verified `ApiEndpoints`, controller refs from audit)

| Family | Endpoint (`ApiEndpoints`) | Server controller |
|---|---|---|
| Auth sign-in / refresh / 2FA / me | `POST /api/v1/auth/login`, `POST …/auth/refresh`, `POST …/auth/2fa/verify`, `GET …/auth/me` | `identity/api/AuthController.java:18,29,35,41,85` |
| Dashboard counts | ⚠️ **No `counts` path in `ApiEndpoints`** (grep confirms: only `workshopJobs` list + `…/{id}` + assign/cancel/assignments). `admin_api.dart:764-819` `jobCounts()` reads list/fallback (fabricates `draft:12/scheduled:4/…/total:24` on total failure — possible Figma-number leak, verify) | Claimed `jobs/api/WorkshopJobController.java:21,33` — **must confirm counts endpoint exists server-side in Step 1** |
| Jobs queue / create / assign / cancel | `GET/POST /api/v1/workshop/jobs`, `POST …/{id}/assign`, `POST …/{id}/cancel`, `GET …/{id}/assignments` | `jobs/api/WorkshopJobController.java:21,39,46,53,59,65` |
| Staff / create tech / reset tech pw | `GET /api/v1/workshop/staff`, `POST /api/v1/workshop/technicians` (+`Idempotency-Key`), `POST …/technicians/{userId}/password-reset` | `identity/api/StaffController.java:22,37,43,52` |
| Templates (workshop) | `GET/POST /api/v1/workshop/templates`, `GET …/versions`, `GET/…/{id}`, `POST …/{id}/draft`, `PUT …/{id}/draft`, `POST …/{id}/publish`, `POST …/{id}/retire`, `GET …/{id}/versions/{versionId}`, `GET …/{id}/preview` | `templates/api/WorkshopTemplateController.java:22–96` (`preview:91-96` never called by client — possibly dead server-side) |
| Master catalog (read-only) | `GET /api/v1/workshop/master/categories`, `GET …/items?search&categoryId`, `GET …/items/{versionId}` | `templates/api/WorkshopMasterController.java:17,27,32,38` |
| Reports (admin) | `GET /api/v1/workshop/jobs/{jobId}/report`, `POST …/retry`, `POST …/link`, `POST …/link/revoke`, `PUT …/pdf-download`, `GET …/pdf` | `reports/api/WorkshopReportController.java:24,36,41,46,51,57,63` |
| Deliveries | `POST+GET …/{jobId}/deliveries`, `POST …/{deliveryId}/retry` (POSTs with `Idempotency-Key`) | `delivery/api/WorkshopDeliveryController.java:21,34,43,49` |
| Public (unauthenticated) | `GET /r/{token}?lang`, `/r/{token}/photo/{id}`, `/r/{token}/pdf`, `/r/unavailable` (no `/api/v1` prefix, Thymeleaf, `PermitAll`) | `reports/api/PublicReportController.java:24,32,42,64,74` |
| Platform-only (not workshop) | hierarchy/users/master/audit paths | `identity/api/PlatformHierarchyController.java`, `masterdata/api/MasterContentController.java` |

### Figma elements with NO backend (neutral same-slot ARB replacement, never shown as drawn)

Bays (`Bay 01–08`, `ACTIVE BAYS 06/08`, `Bay Order`, `Dispatch Bay`); telemetry/live floor (`TELEMETRICS • REAL-TIME`, `Live sync active`, `Floor Telemetry` donut, `Turnaround 45 mins`, `Median Flow 38 mins`, `Compliance 99.4%`, activity stream); shifts/roster/NFC (`Shift A`, `AUTO-SHIFT NFC`, `Shift Rules`, `Download Roster PDF`); certifications/skills/levels (`EV Certified`, `Lead Master`, `OBD-II Specialist`, `Level 4`, `Hazmat PPE`); template extras (custom items, autosave, Active/Automated flags, numeric ranges, semver, time estimates); report-viewer richness (severity/coverage charts, admin photo derivatives — photos only via public `/r/{token}/photo/…`). Also never show: GPS, "certified/verified" (as claims), compliance, scores, telemetry, manager/review/approval wording, sample people/vehicles/photos/plates.

## 4. Components: shared layer, kit locations, duplicates

### 4.1 Centralized inventory (design_system + auth)

- **Tokens/theme** (`packages/design_system`): `tokens.dart` (product light-only scale, `AppTheme.build` asserts `brightness==light`), `generated/tokens.g.dart` (from `tokens/tokens.json`, light branches only), `fonts.dart` (package-prefixed Jakarta/Noto/IBM Plex/SC), `figma_spec.dart` (**fidelity target only**, not product), `reduce_motion.dart`.
- **Product components** (`lib/src/components/`): `buttons` (`AppButton`, `AppIconButton`), `inputs` (`AppTextField`), `cards` (`AppCard`, `AppTonalCard`, `AppDeliveryStatusCard`, `AppStatCard`), `chips` (`StatusChip`, `SeverityBadge`, `AppFilterChip`, `AppSegmentedControl`, `AppLanguageSwitch`), `lists` (`SectionHeader`, `AppListTile`), `overlays` (`showAppConfirmDialog`, `showAppBottomSheet`, `AppSnackBar`), `states` (`EmptyState`, `ErrorState`, `LoadingSkeleton`, `OfflineBanner`), `results` (`InspectionResultSelector/Chip/Badge`), `progress` (`AppProgressRing`, `AppCoverageBar`), `data_table` (`AppDataTable`), `navigation` (`AppScaffold`, `AppSliverScaffold`, `AppBottomNavDock`), `icons` (`AppIcon`), `tree_view` (`AppTreeView`).
- **Role chrome**: `admin_chrome.dart` (`AdminSidebar` 256dp/rail, `AdminTopBar` 64dp, `AdminShell` ≥900/600–899/<600) — **zero `lib/` call sites**; `workshop_admin.dart` (F3-A 1–4 + F3-B 5–8 compositions: `WorkshopHeader/StatCard/JobCard/OptionCard/Dialog/SideSheet/StaffCard/Metric/TemplateCard/SequenceCard/LockedPill/DropZone`) — only `Dialog/SideSheet/OptionCard/SequenceCard/DropZone/LockedPill` used by admin pages, rest unused in `lib/`; `technician_shell.dart` — technician-only.
- **Figma-exact kit** (fidelity, not product scale): `figma_components.dart` (`FigmaPrimaryButton`, `FigmaStatusPill`, `FigmaThreeWaySelector`, …), `figma_screen_kit.dart` (`Fx*`: colors/type/shadows, `FxButton/Field/TextField/LanguageSwitch/Header/Dock/Pill/CoverageRing`, `F2b` tokens).
- **Auth** (technician login to reuse): `packages/auth` `SignInView` (presentational, `Fx*` fields, ARB-only copy) + `SignInPage` (controllers, 2FA challenge, error mapping); technician alias `technician_app/.../f2a/login_view.dart:7` (`typedef LoginView = SignInView`) — single implementation, no twin.

### 4.2 Overlap map — the shared layer Step 2 may touch

| Shared component | Workshop Admin uses | Technician uses | Shared? |
|---|---|---|---|
| `AppScaffold/SliverScaffold`, `AppButton`, `AppTextField`, `SectionHeader`, `Empty/Error/Loading` states | yes | yes | **Yes — overlap (Step 2 surface)** |
| `StatusChip`, `AppListTile`, `AppSelectableText` | yes | no hits in F2-A/F2-B (use `FxPill`/`F2bStatusPill`) | Partial (admin-side) |
| `showAppConfirmDialog/showAppBottomSheet` | yes | none found | Admin-side |
| `WorkshopDialog/SideSheet/OptionCard/SequenceCard/DropZone/LockedPill` | yes (assign/create-schedule/builder) | none | Admin-side, live |
| `WorkshopHeader/StatCard/JobCard/StaffCard/Metric/TemplateCard`, `AdminShell/Sidebar/TopBar`, `AppDataTable`, `AppTreeView`, `AppProgressRing/CoverageBar`, `InspectionResult*`, `TechnicianDock/ModuleCard/CoverageRing` | **none in `lib/`** (tests/gallery only) | n/a | **Dead-in-lib — verify before use, do not assume used** |
| `Fx*` tokens + `AppBreakpoints`/spacing | F3 views import `Fx` + tokens only | all F2-A/F2-B + `SignInView` | **Yes — the actual shared layer both sides touch** |

### 4.3 Duplicate/twin candidate pairs (Step 1 consolidation input — no decision taken)

Primary CTA: `FigmaPrimaryButton` vs `AppButton(large)` vs `FxButton` vs local `_addButton/_cta` vs `F2bSlideToConfirm`. Status pill: `FigmaStatusPill` vs `StatusChip` vs `TechnicianResultChip` vs `InspectionResultChip/Badge` vs `FxPill` vs `F2bStatusPill` vs local filter pills. Selector: `FigmaThreeWaySelector` vs `AppSegmentedControl` vs `AppFilterChip` vs `F2bSegmented/F2bChip` vs local filter rows. Text field: `AppTextField` vs `FxTextField/FxField` vs `F2bNoteField`. Cards/stats: `AppStatCard` vs `WorkshopStatCard` vs `WorkshopMetric` vs local stat pods; `AppDeliveryStatusCard` vs `FigmaDeliveryStatusCard`. Staff/user: `WorkshopStaffCard` vs `TechnicianAvatar` vs `FxAvatar/FxProfileButton`. Headers: `WorkshopHeader` vs `AdminTopBar` vs `TechnicianAppBar` vs `FxHeader` vs per-screen `_header()`. Nav: `AppBottomNavDock` vs `TechnicianDock` vs `FxDock` vs F3 96px `_rail()`. Dialogs: `WorkshopDialog.show` vs `showAppConfirmDialog` vs raw `AlertDialog` (in `templates_tab.dart:52`). Language: `AppLanguageSwitch` vs `FxLanguageSwitch`. Icons: `AppIcon` vs `FxIcon` vs per-screen `*_assets.dart` string constants. Per-screen copies flagged: `queue_view`, `dashboard_view`, `staff_view`, `template_list_view` (local `_header/_rail/cards/chips`), `*_assets.dart` embedded SVGs, technician `f2b_kit.dart` (app-local Figma kit duplicating design_system roles).

## 5. Tokens and language

- **Light-only holds in code**: `AppTheme.build` asserts light; `admin_app/lib/app.dart:17-18` pins `ThemeMode.light`; `tokens.g.css` has `color-scheme: light` only. Dark remnants on disk only: 16 `*_dark.png` goldens in `design_system/test/goldens/`; generator dark-branches are dead (no dark keys in `tokens.json`).
- **Generators**: actual paths are `tools/design_tokens/generate.mjs` + `wire-print-tokens.mjs` (not under `client/`). `--check` today: generate → **stale** (`contrast-after.md` drift, exit 1); wire-print → up to date.
- **ARB parity holds**: 477/477 EN/AR non-`@` keys, zero placeholder-set mismatches (16 `@` blocks), zero `?{3,}` runs, no Figma sample strings in ARB. Growth since C0: 433→477 (+44 keys). Suspected wrong key persists: `template_version_page.dart:49 retryLabel: l10n.search` (`retryAction` exists — key-swap only, needs design confirm).
- **Admin `lib/` literals**: `pages/*` + `src/*.dart` clean except allowlisted OS title (`app.dart:15 'TrueReport Admin'`), wire defaults, interpolations of `l10n.*`/data. Zero hardcoded `Colors./Color(0x/fontSize` and zero raw `/api/v1` outside `ApiEndpoints` in product path.
- **F3 `screens/*` showcase is NOT clean**: ~80+ hardcoded EN strings (vehicle titles, bay chips, people names, `Search VIN…`, `Floor Telemetry`, `EV Certified`, `OEM ISO-9001 sync` caption, template titles/tiers, `Toggle Language/Sign Out` debug menus), 83 hardcoded color/fontSize hits, `BorderRadius.circular(9999)`, `Colors.red` logout. Consolidation needs ~40+ new ARB keys here or dev-only exclusion decision (they are currently in `lib/`, not `test/`).
- **Forbidden-word hits** (case-insensitive, `admin_app/lib`): `verified` (`staff_view.dart:696` caption, `assign_technician_dialog.dart:36` comment), `certified` (`staff_view.dart:819`), `bay` (queue/dashboard/staff views + comments), `telemetry` (`dashboard_view` identifiers + `Floor Telemetry` string, `template_builder_page.dart:23` comment), `manager` only as substrings (`DispatchBay`, `GuideImageManager`). ARB `technicianEquipmentVerified` is allowlisted product copy.
- **Arabic risks**: type scale switches correctly (`tracking 0`, body ×1.55, fallbacks incl. CJK); LTR islands correct in product components (`WorkshopJobCard.reference`, `StatCard.value`, `Metric.value`, `TemplateCard.versionLabel`, staff masked-email, assign dialog email/phone) but **missing in F3 showcase** (`VIN`, `VIN • 9J18…`); product components use ellipsis, F3 screens use `overflow: clip` (hides ~30–50% longer Arabic without affordance); explicit `textScaler` handling only in `schedule_job_sheet.dart:69` (helper capped at 1.5×); 2.0×/RTL-VIN/real-device unverified (C0 gap carries over, Arabic "derived, pending native review").

## 6. Tests, goldens, fidelity harness

- **admin_app/test**: 34 files + 7 support fixtures. No checked-in `goldens/`; fidelity lives in `docs/ui/figma/fidelity/` (`f3a/{dashboard,live-job-queue,create-schedule,assign-technician}(+product)`, `f3b/{template-list,template-builder,staff-management,create-staff}(+product)`: `figma/render/side-by-side/diff.png`, `metrics.json` (SSIM), `REPORT.md`, `geometry.json`, `strings.json`). Level-1 REPORTs passed at SSIM ≥ 0.98; Level-2 product captures are **expected to fail SSIM by design** (slot replacements). Geometry gates (`f3a_geometry_test`, `f3b_geometry_test`) assert product boxes within 1px at 1280×800 — not Figma equality. `source_scan_test` (7 tests) + `i18n_source_scan_test` fail on hardcoded colors/literals/`/api/v1` outside allowlists — F3 `screens/*` currently violate the style rules the scan enforces (confirm scope ruling in Step 1).
- **technician_app/test**: 26 files + 13 support + 14 goldens (`f2a_*_en/ar_light.png`, light only). Must-stay-green: `i18n_source_scan_test`, `f2a_screens_test`, `f2a1_geometry_test`, `f2a_goldens_test`, `f2a2_harness_test`, `f2a2_asset_guard_test`, `f2b_screens_test`, `f2b_geometry_test`, `f2b_release_guard_test`, `f2b_a11y_test`, `offline_store_test`, `o2_copy_fit_test`, `consent_test`, `inspection_ui_test`, `intl_dates_tech_test`.
- **design_system/test**: 8 files + 28 goldens (incl. dark). `tokens_test`, `shadow_tokens_test`, `components_test`, `figma_components_test`, `figma_goldens_test`, `workshop_admin_test`, `fidelity_capture_test`, `zz_hdr2_test`.

### Regression guard plan (technician screens 1–7, 9, 11, 13–16 stay green while shared components change)

Screens 1–7 ← `f2a_screens`, `f2a1_geometry`, `f2a_goldens` (14 PNGs), `f2a_fidelity_capture`, `f2a_screenshots`, `f2a2_harness/asset_guard`, `i18n_source_scan`, `o2_copy_fit`, `consent` (screen 5), `inspection_ui`, `offline_store`. Screen 9 (defect-detail) ← `f2b_*` trio + `f2b3_capture_defect_detail`. Screen 11 (dense-mechanical) ← trio + `f2b3_capture_dense_mechanical`. Screen 13 (final-review) ← trio + `f2b3_capture_final_review`. Screen 14 (finalize) ← trio + `f2b3_capture_finalize`. Screen 15 (offline-sync) ← trio + `f2b3_capture_offline_sync` + `offline_store_test`. Screen 16 (success) ← trio + `f2b3_capture_success`. Cross-cutting: `i18n_source_scan`, `f2b_release_guard`, `f2b_a11y`, design_system token/shadow/component/figma suites. Commands (from package dir, not run in Step 0):

```sh
flutter test apps/technician_app/test/i18n_source_scan_test.dart
flutter test apps/technician_app/test/f2a_screens_test.dart apps/technician_app/test/f2a1_geometry_test.dart apps/technician_app/test/f2a_goldens_test.dart apps/technician_app/test/f2a2_harness_test.dart apps/technician_app/test/f2a2_asset_guard_test.dart
flutter test apps/technician_app/test/f2b_screens_test.dart apps/technician_app/test/f2b_geometry_test.dart apps/technician_app/test/f2b_release_guard_test.dart apps/technician_app/test/f2b_a11y_test.dart
flutter test apps/technician_app/test/offline_store_test.dart apps/technician_app/test/o2_copy_fit_test.dart apps/technician_app/test/consent_test.dart apps/technician_app/test/inspection_ui_test.dart apps/technician_app/test/intl_dates_tech_test.dart
flutter test packages/design_system/test/tokens_test.dart packages/design_system/test/shadow_tokens_test.dart packages/design_system/test/components_test.dart packages/design_system/test/figma_components_test.dart packages/design_system/test/figma_goldens_test.dart packages/design_system/test/workshop_admin_test.dart
flutter test apps/admin_app/test/source_scan_test.dart apps/admin_app/test/ui_matrix_test.dart apps/admin_app/test/f3a_geometry_test.dart apps/admin_app/test/f3b_geometry_test.dart apps/admin_app/test/dashboard_test.dart apps/admin_app/test/jobs_queue_test.dart apps/admin_app/test/staff_account_test.dart apps/admin_app/test/template_list_test.dart apps/admin_app/test/template_builder_test.dart apps/admin_app/test/report_page_test.dart
```

Capture-only (write into `docs/`, not release gates unless SSIM threshold explicitly required): `f3a/b_capture_*` Level-1 + `*_product`, `f2a/b_fidelity_capture`, design_system `fidelity_capture`.

## 7. Step 1 consolidation-plan input (candidate scope — approval needed)

1. Shared-layer surface for Step 2 is small: `AppScaffold`, `AppButton`, `AppTextField`, `SectionHeader`, empty/error/loading, overlays, `StatusChip` (admin pages), `Fx`/token scale. `Workshop*`/`Admin*`/`AppDataTable`/`AppTreeView` have no production call sites — decision needed: wire them in or retire.
2. One-component-per-role twins to resolve: CTA, status pill, selector, text field, stat cards, headers, dock-vs-rail, dialog patterns, language switch, icons (`AppIcon` vs `FxIcon` vs `*_assets.dart` strings).
3. F3 `screens/*` ruling needed: consolidate in place (needs ~40+ ARB keys + style-gate compliance) vs another disposition — they are the only `lib/` code holding Figma sample text and hardcoded styling.
4. Dead code to delete only after plan approval: `job_form_page.dart`, orphan `completed_report_assets.dart`, unwired `assign_technician_dialog` call-site gap, unread `jobs/recentJobs` params.
5. Pre-Step-2 verifications: counts-endpoint existence server-side; `GET …/preview` dead-or-live; `jobCounts()` fallback fabricated numbers; `retryLabel: l10n.search` key swap; dark-golden deletion; `generate.mjs --check` stale `contrast-after.md`.

## 8. Open questions / could-not-verify

- Counts endpoint (`WorkshopJobController.java:33`) and `GET …/templates/{id}/preview` liveness not confirmed from server sources in this pass.
- `assign_technician_dialog` FINALIZED/CANCELLED guard vs server `WorkshopJobService` guards (incl. `READY_TO_FINALIZE` assignability) not audited.
- F3 help/gear icons navigate to Templates tab / sign-out menu — Figma help destination undefined; Screen 11 on hold so target unconfirmable.
- `F2b` tokens live in design_system but `F2b*` widgets live in technician `f2b_kit.dart` — intentional split or misplaced ownership.
- `guideImageBytes` (platform-master) used by `master_content_tab` but never by workshop `TemplateBuilder` — Figma 8 guide thumbnails unverified.
- No tests or builds run in Step 0 (read-only); all pass/fail states are from checked-in REPORTs/metrics, not fresh runs. Goldens needing rebaseline unknown until a run with `--update-goldens`.
- `METHOD.md` kit-gap files referenced by F3 fixtures not enumerated; `docs/ui/figma/specs/workshop/*`, `f2a1-nodes/`, `f2b-nodes/`, `f2b-slot-sheet.md` not listed in this pass.
- Arabic "derived, pending native review"; no real-device testing claimed; ICU date/number + Arabic-Indic digits follow-up open (inventory §7).
