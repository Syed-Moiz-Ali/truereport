# Workshop Admin consolidation plan (Step 1 — approval needed, no code changed)

Step 0 map: `docs/ui/consolidation-map-admin.md`. This plan implements the owner decisions on the Step 0 questions. No code changed, no deletions, nothing committed in this step.

**Authority note.** `docs/ui/UI_INPLACE_ALIGNMENT_PROMPT.md` and `docs/ui/UI_WORKSHOP_ADMIN_START_PROMPT.md` are **still absent from `docs/`** at plan time (`docs/ui/UI_*.md` glob: no files). Per owner decision 1, the session-prompt text plus rebuilt map §4/§8 stand in; the incoming `UI_INPLACE_ALIGNMENT_PROMPT.md` is authoritative once landed — **re-verify it at the start of Step 2** and flag any conflict before editing.

**Verified in this step.** `GET /api/v1/workshop/jobs/counts` exists server-side: `server/.../jobs/api/WorkshopJobController.java:33-37` (`@GetMapping("/counts")`, class+method `@PreAuthorize("hasRole('WORKSHOP_ADMIN')")`), DTO `jobs/api/JobCountsDto.java` (`draft, scheduled, newScheduled, assigned, inProgress, readyToFinalize, finalized, finalizedToday, cancelled, total`; `newScheduled` = draft+scheduled; `finalizedToday` = Asia/Dubai date), covered by `server/src/test/java/com/truereport/WorkshopJobCountsIT.java` (role matrix 403/401, per-status counts, tenant isolation, no-PII body, write-method rejection). Client gap: `ApiEndpoints` has **no** counts getter (`api_endpoints.dart:73-78` lists jobs/assign/cancel/assignments only); `admin_api.dart:766` interpolates `'${_endpoints.workshopJobs}/counts'`.

## 1. Fabricated/sample fallbacks inventory (owner decision 3)

`admin_providers.dart` (137 lines, read fully): **pure pass-through, zero fallbacks** — every provider delegates to `AdminApi`; errors propagate as `AsyncError` to the UI. No change needed there.

`admin_api.dart`: exactly **two catch sites**, both in `jobCounts()` (`:764-819`):

| # | Location | What it returns | Verdict |
|---|---|---|---|
| F1 | `:769-803` inner try | Derives counts from `jobs()` list client-side, but **wrong**: `assigned: 0`, `cancelled: 0` (statuses never matched), `finalizedToday: finalized` (not Dubai-day), no `ASSIGNED`/`CANCELLED` arms. Derived-but-incorrect = fabricated data. | **Remove** (owner-ordered). Counts come only from the server endpoint. |
| F2 | `:804-817` inner catch | Hardcoded `const JobCounts(draft: 12, scheduled: 4, …, total: 24)` — pure invention, matches Figma numbers. | **Remove** (owner-ordered). On failure: localized error/empty state, never invented data. |

No other `catch (` exists in `admin_api.dart` (only `:768, :804`); the `queue_view.dart:84` catch is image-decode fallback (renders nothing, benign — dies with the fixture wiring at the Queue step); `create_technician_sheet.dart:267,281` catches map `AppFailure` to localized messages (correct, keep). `models.dart ??` defaults are wire-deserialization guards (`''`, `0`, `false`, status codes) — not user-visible fabrications; leave, except new code must not add display defaults that invent meaning.

**Planned fix (Step 2a):** add `String get workshopJobCounts => '$_root/workshop/jobs/counts';` to `ApiEndpoints` (additive, shared package, no existing caller affected); rewrite `jobCounts()` to `getDynamic(_endpoints.workshopJobCounts)` → `JobCounts.fromJson`, no try/catch; callers (`dashboard_tab`, `jobs_tab` via `jobCountsProvider`) already render `AsyncError`/loading — add ARB error/empty copy if missing (check `actionFailed`, `error`, `noResults` first; new key only if none fits). New/updated tests: `ApiEndpoints` path test (if the repo has one — check `api_client/test`), `jobCounts` unit test with fake (success maps all 10 fields; failure propagates, no fallback values), update `dashboard_test.dart`/`jobs_queue_test.dart` fakes if they stub counts.

## 2. Target structure

- **One token source:** `design_system/tokens/tokens.json` → `generated/tokens.g.dart` (+ `tokens.g.css`, print template, `contrast-after.md`) via `tools/design_tokens/generate.mjs --write`, verified by `--check` in CI. Hand-written `tokens.dart` (`AppTheme.build`, light-only assert) consumes generated values; no literals in product code. `figma_spec.dart` stays fidelity-target-only, never product.
- **One component per role:** product screens compose `App*` (generic), `Workshop*` (Workshop Admin Figma roles), `Admin*` (app chrome); technician keeps `Technician*` + shared `App*`; login keeps `Fx*` inside `SignInView` (untouched). Twin pairs resolved in Step 2b (§4); no new components for login or per-screen copies afterward.
- **One file per screen:** the F3 `screens/*` view file becomes THE file at its screen step (§5 table); the older `pages/*` duplicate is deleted in the same step. Dialogs/sheets that are Figma screens (4, 10) live in the owning screen's file; supporting read-only version view folds into the builder file.
- **Fixtures only in `test/`:** `test/support/*`, `test/goldens/*` (light only after Step 2a), `docs/ui/figma/fidelity/*`. `lib/` holds zero Figma sample text after each screen step (enforced by `i18n_source_scan_test` + `source_scan_test`).
- **ARB for every string** (EN+AR, placeholder parity, no sample text); light mode only (`ThemeMode.light` pinned, no dark branches/goldens); no logic/API/model/validation/permission/state change at any step.

## 3. Migration order and gates

| Step | Layer | Gate before next |
|---|---|---|
| 2a | Shared logic hygiene + approved cleanups + release guard (§4) | analyze clean; admin suites green; technician suites green; `generate.mjs --check` passes; `release_guard_test` green |
| 2b | Shared components twin resolution (§4), no screen edits | design_system + technician suites green (goldens unchanged); admin geometry/source_scan green |
| 3 | Admin sign-in (§7) | login tests EN/AR green; technician login goldens byte-identical |
| 4 | App shell (§5, shell row) | shell tests; navigation/guard tests; EN/AR side-by-side vs Figma |
| 5+ | One screen per gate in owner order: Queue → Create drawer → Assign dialog → Dashboard → Staff → Create Technician → Template List → Template Builder → Report Viewer → Deactivation → PDF Preview | per-screen §5 row; full client + server suites + web build at each gate end |

**Checks after every step:** `flutter analyze --fatal-infos`; affected suites (§6); technician goldens + tests must stay green (any shared-component step re-runs the full §6 guard list); at gate end: full client suites, server suite (Docker/MySQL if available), web build. For Steps 3+: 1280px EN+AR `side-by-side.png` vs Figma PNG with remaining-difference list; no "pixel-perfect" claim without measurement.

## 4. Step 2 detail (shared layers only, lead edits)

**2a — logic hygiene + approved cleanups + release guard.** Files changed: `api_client/.../api_endpoints.dart` (+1 getter); `admin_app/.../admin_api.dart` (`jobCounts` rewrite); ARB (+error/empty key only if missing); `admin_router.dart` untouched. Files deleted (owner-approved): `admin_app/.../pages/job_form_page.dart`; `admin_app/.../screens/f3b/completed_report_assets.dart`; 16 `design_system/test/goldens/*_dark.png`; stale `contrast-after.md` regenerated via `generate.mjs --write` (review diff first — must touch only generated content). One-key swap `template_version_page.dart:49 retryLabel: l10n.search → l10n.retryAction` (fix the 5 other `l10n.search`-as-retry misuses by grep in the same edit if found; report count). regenerate: `flutter gen-l10n` if ARB changed; `wire-print-tokens.mjs --check` must stay passing. **Release guard (new):** tab wrappers (`jobs_tab`, `dashboard_tab`, `staff_tab`, `templates_tab`) render the F3 showcase view only under `--dart-define=ADMIN_FIGMA_SHOWCASE=true` (used by capture tests); default release path renders provider-driven content or localized `EmptyState` — so unwired screens are unreachable in release builds. New `admin_app/test/release_guard_test.dart`: default build contains none of the fixture markers (`Porsche Taycan`, `BAY 04`, `David Vance`, `100-Point`, `Floor Telemetry`, …); flag-on build renders views (keeps capture tests working — update their invocations to pass the flag). Tests affected: new `jobCounts` + `release_guard` tests; `dashboard_test`, `jobs_queue_test`, `f3a/b_capture_*` (flag threading); `figma_goldens_test` (drop dark variants); `source_scan_test` allowlist if paths change.

**2b — component twin resolution (no screen-file edits; screens keep compiling against unchanged APIs).** Decisions (propose deviations in Step 2 report if evidence disagrees):

| Role | THE component | Retired twin / disposition |
|---|---|---|
| Primary CTA (admin) | `AppButton(large:)` | Local `_addButton/_cta` die at their screen step; `FigmaPrimaryButton` stays gallery/test-only; `FxButton` stays login-only |
| Status pill | `StatusChip` (+`SeverityBadge`) | `FigmaStatusPill`, `FxPill`, `F2bStatusPill` stay in their lanes; local pills die at screen steps |
| Selector/filter | `AppSegmentedControl` + `AppFilterChip` + `AppSelectableText` | Local filter rows die at screen steps |
| Text field | `AppTextField` | `FxTextField` stays login-only; `F2bNoteField` stays technician-only |
| Admin dialog / sheet | `WorkshopDialog.show` / `WorkshopSideSheet.show` | Raw `AlertDialog` (`templates_tab:52`) replaced at Template List step; `showAppConfirmDialog/showAppBottomSheet` stay for Platform Admin generic use |
| Selection rows | `WorkshopOptionCard` | Local radio rows die at screen steps |
| Language | `AppLanguageSwitch` (admin chrome) | `FxLanguageSwitch` stays login-only |
| Icons | `AppIcon` (product) | `FxIcon` stays login/fidelity; `*_assets.dart` string constants die at screen steps |
| Headers/chrome | `AdminShell` + `AdminSidebar` + `AdminTopBar` (Step 4) | Per-screen `_rail/_header` die at screen steps; `TechnicianAppBar` untouched |

**Kept components and their Workshop Admin users:** `WorkshopDialog` → Assign dialog (4), Deactivation (10); `WorkshopSideSheet` → Create drawer (3), Create Technician (6); `WorkshopOptionCard` → Assign (4), Create drawer tiers (3); `WorkshopSequenceCard` + `WorkshopDropZone` + `WorkshopLockedPill` → Template Builder (8); `WorkshopHeader/StatCard/JobCard` → Dashboard (1), Queue (2); `WorkshopStaffCard` → Staff (5); `WorkshopMetric` → Dashboard (1); `WorkshopTemplateCard` → Template List (7). **Kept but Platform Admin–bound (not used by Workshop Admin):** `AppDataTable`, `AppTreeView`, `showAppConfirmDialog` (generic), `InspectionResultSelector` (technician-owned). Technician-owned (`Technician*`, `F2b*`, `FxDock`) untouched.

## 5. Per-screen steps (Steps 4–5+; each needs owner approval before the next)

Pattern per screen: (a) diff vs Figma `@2x` + node JSON at 1280px; (b) fix at tokens → shared component → screen; (c) ARB-only text (+neutral same-slot replacements from map §3); (d) AR/RTL/LTR-islands/2.0×/keyboard/focus/48dp/hover; (e) EN+AR `side-by-side.png` + difference list; (f) derived tablet/phone labelled "derived, pending designer review"; (g) delete obsolete duplicate, update affected tests only; (h) suites + build, technician goldens unchanged.

| Screen (order) | THE file (kept, wired) | Deleted same step | Providers/endpoints wired | ARB to add (~40 total) | Tests affected |
|---|---|---|---|---|---|
| Shell (4) | `pages/workshop_admin_home.dart` (rail + floating header + page container via `AdminShell/Sidebar/TopBar`) | Per-screen `_rail/_header` in `f3a/f3b` views (each removed at its own screen step, not here); `AdminTopBar` user slot stays empty (no avatar/role/search) | Existing routes/guards; workshop name; sign out; language switch | Shell labels if missing (check first) | `admin_pages_test`, `ui_matrix_test`; new shell navigation/guard test |
| Queue (2) | `screens/f3a/queue_view.dart` | `pages/jobs_tab.dart` (folded in); `screens/f3a/queue_assets.dart` strings → `AppIcon` | `jobsProvider` (search+status), `jobCountsProvider` filter counts; `onOpenJob` wired → Report Viewer | Search hint, filter copy beyond `noResults`, bay-neutral replacements, empty states | `jobs_queue_test`, `f3a_geometry_test`, `f3a_capture_queue(+product)`; release-guard row for queue removed |
| Create drawer (3) | `pages/schedule_job_sheet.dart` (already single) | — (`job_form_page` already gone in 2a) | Already wired; verify `templateVersionOptionsProvider` + `POST /workshop/jobs` + Idempotency-Key | Footer/helper copy if missing | `schedule_job_sheet_test`, `f3a_capture_schedule(+product)` |
| Assign dialog (4) | `pages/assign_technician_dialog.dart` | — | `staffProvider` filtered ACTIVE TECHNICIAN; `assignWorkshopJob`; wire queue-card tap → `WorkshopAssignDialog.show` | Reason optional, empty-roster, rejected-finalized | `assign_technician_dialog_test`, `f3a_capture_assign(+product)`; new wiring test (tap → dialog) |
| Dashboard (1) | `screens/f3a/dashboard_view.dart` | `pages/dashboard_tab.dart`; `dashboard_assets.dart` strings | `jobCountsProvider` (counts endpoint, §1); recent jobs list endpoint (verify `GET /workshop/jobs` ordering/limit in this step) | KPI labels, activity-feed neutral replacements, error/empty | `dashboard_test`, `f3a_geometry_test`, `f3a_capture_dashboard(+product)` |
| Staff (5) | `screens/f3b/staff_view.dart` | `pages/staff_tab.dart`; `staff_assets.dart` strings | `staffProvider`; disable/reactivate + `password-reset` actions | Search hint, metric labels, role/status (reuse `memberRoleLabel/memberStatusLabel`), empty states | `staff_roster_test`, `staff_account_test`, `f3b_geometry_test`, `f3b_capture_staff(+product)` |
| Create Technician (6) | `pages/create_technician_sheet.dart` | — | `POST /workshop/technicians` + Idempotency-Key; neutral `EMAIL_EXISTS`; password never echoed/logged | Verify exists; add helper/error keys only if missing | `create_technician_sheet_test`, `staff_account_test`, `f3b_capture_create(+product)` |
| Template List (7) | `screens/f3b/template_list_view.dart` | `pages/templates_tab.dart` (+ raw `AlertDialog` → `WorkshopDialog`); `template_list_assets.dart` strings | `templatesProvider`; `POST /workshop/templates`; counts = ΣitemCount | KPI captions, tier/tag labels, requirement labels, empty states | `template_list_test`, `f3b_capture_templates(+product)` |
| Template Builder (8) | `pages/template_builder_page.dart` | `pages/template_version_page.dart` folded in as private view | Master catalog + draft/publish/retire/version/preview endpoints (already wired; keep) | Verify exists; locked-pill/preview copy only if missing | `template_builder_test`, `f3b_capture_builder(+product)` |
| Report Viewer (9) | `pages/report_page.dart` (rebuilt in place to Figma 9) | Nothing (no duplicate exists) | `reportProvider`, link create/copy, deliveries, `pdfReady` flags; wire `onOpenJob` from Queue (done at Queue step; connected here) | Status/link/delivery copy (mostly exists); coverage/findings labels | `report_page_test` (extended), new viewer layout tests |
| Deactivation (10) | Dialog inside `report_page.dart` (Figma 10 as drawn) | — | `POST …/report/link/revoke` + mandatory reason (already wired in `_revoke`; restyle only) | Reason labels (exist); "copies/screenshots cannot be recalled" line (new key) | `report_page_test` (revoke path) |
| PDF Preview (12) | Preview section in `report_page.dart`; single new file only if size forces it (no twin exists, so creation is allowed) | — | `GET …/report/pdf` bytes + `pdfDownloadEnabled`; same allowlist, bilingual; print via `print-report.html` tokens | Preview labels (`preview/previewEn/previewAr` exist) | `report_page_test` (preview path); print-token `--check` stays green |
| Settings (11) | ON HOLD — nothing | — | No endpoint; no work | — | — |

## 6. Regression guard commands (every step; goldens + tests must stay green)

```sh
flutter analyze --fatal-infos
flutter test apps/technician_app/test/i18n_source_scan_test.dart
flutter test apps/technician_app/test/f2a_screens_test.dart apps/technician_app/test/f2a1_geometry_test.dart apps/technician_app/test/f2a_goldens_test.dart apps/technician_app/test/f2a2_harness_test.dart apps/technician_app/test/f2a2_asset_guard_test.dart
flutter test apps/technician_app/test/f2b_screens_test.dart apps/technician_app/test/f2b_geometry_test.dart apps/technician_app/test/f2b_release_guard_test.dart apps/technician_app/test/f2b_a11y_test.dart
flutter test apps/technician_app/test/offline_store_test.dart apps/technician_app/test/o2_copy_fit_test.dart apps/technician_app/test/consent_test.dart apps/technician_app/test/inspection_ui_test.dart apps/technician_app/test/intl_dates_tech_test.dart
flutter test packages/design_system/test/tokens_test.dart packages/design_system/test/shadow_tokens_test.dart packages/design_system/test/components_test.dart packages/design_system/test/figma_components_test.dart packages/design_system/test/figma_goldens_test.dart packages/design_system/test/workshop_admin_test.dart
flutter test apps/admin_app/test/source_scan_test.dart apps/admin_app/test/ui_matrix_test.dart apps/admin_app/test/f3a_geometry_test.dart apps/admin_app/test/f3b_geometry_test.dart apps/admin_app/test/dashboard_test.dart apps/admin_app/test/jobs_queue_test.dart apps/admin_app/test/staff_account_test.dart apps/admin_app/test/template_list_test.dart apps/admin_app/test/template_builder_test.dart apps/admin_app/test/report_page_test.dart apps/admin_app/test/release_guard_test.dart
```

Gate-end additions: full client suites, server suite (`mvn test`, Docker/MySQL if available — must include `WorkshopJobCountsIT`), web build (`flutter build web`), debug APK at major gates. Capture suites (`f3a/b_capture_*`, `f2a/b_fidelity_capture`, design_system `fidelity_capture`) run with `ADMIN_FIGMA_SHOWCASE=true` from Step 2a onward; Level-2 product SSIM expected-fail by design (slot replacements), Level-1 SSIM ≥ 0.98.

## 7. Step 3 detail — Admin sign-in (derived, no Figma frame)

Goal: one "Admin sign in" screen for Workshop Admin + Platform Admin, reusing the aligned technician login; server role drives the existing router. **No new components; no role picker.**

- **What exists:** `auth/.../SignInPage` (state, TOTP challenge, error mapping — behaviour unchanged) + `SignInView` (presentational: `FxLanguageSwitch`, logo glow, white field cards with icons, `FxButton` arrow-right + emerald glow, helper slots) + `Fx` tokens + ARB keys (`signInTitle/signInButton`, `technicianAccountNote`, `technicianNeedTechnicianAccess`, `technicianContactAdmin`, `technicianPasswordHelp`, `technicianLanguagePrompt`, `technicianSignInTagline`, `signInSubtitle`). Technician alias `login_view.dart` untouched.
- **Change (in place):** add optional copy inputs to `SignInView` (default = current values, so technician render is byte-identical) + thin `AdminSignInPage` wrapper in `auth` passing admin copy; point `admin_router.dart:/signin` at it (`technician_router` untouched). New ARB keys (~6: admin title, subtitle, email/password labels-placeholders if distinct, button, neutral helper "accounts are created and reset by the Platform Admin") EN+AR. TOTP stays config-off; if on, existing challenge, labelled "derived, pending designer review".
- **Layout:** 1280px white canvas, centered ~420px column, vertically balanced, language pill top-right of page; narrow widths identical to technician login.
- **A11y/RTL:** invisible accessible labels, focus order, Enter submits, visible focus ring, 48dp hit areas (transparent padding, no visual change), password toggle labelled; RTL mirror, email LTR.
- **Verification:** diff list vs technician login; technician `f2a_goldens` (login EN/AR) + `f2a_screens` + `f2a1_geometry` (login) unchanged; new admin login widget test (copy, toggle, submit, error mapping, RTL); EN+AR screenshots labelled "derived from the technician login, no Figma frame". Forbidden: signup/forgot-password/invitation wording, certification/"secure" claims, sample text.
- **Docs:** label the screen "derived from the technician login, no Figma frame" wherever it appears; never claim Figma identity.

## 8. Risks

1. **Shared-component ripple → technician.** Mitigation: §6 guard list at every step; login/`Fx`/technician-owned files off-limits except via optional-default params.
2. **F3 screens currently reachable with sample data in release.** Mitigation: 2a release guard (default path provider-or-empty; showcase behind `ADMIN_FIGMA_SHOWCASE`), removed per screen as wired.
3. **`jobCounts` error UX.** Providers propagate `AsyncError`; each consuming screen step must render localized error/empty (no invented numbers). New ARB keys stay minimal.
4. **Capture-test flag threading.** All `f3a/b_capture_*` invocations must pass the showcase flag; miss one = red suite. Guard test + grep for `WorkshopQueueView(` outside flag path in CI step review.
5. **ARB growth (~40+ keys) + Arabic length.** Placeholder parity check + 360px/2.0× overflow tests per screen; Arabic "derived, pending native review".
6. **`generate.mjs --write` blast radius.** Review diff before commit; must touch only generated files + `contrast-after.md`.
7. **Missing authoritative prompt file.** Re-verify `UI_INPLACE_ALIGNMENT_PROMPT.md` at Step 2 start; stop on conflict.
8. **Dirty tree + tag v2.** Owner re-snapshots; each step ends with `git status` review, no commits (owner commits).
