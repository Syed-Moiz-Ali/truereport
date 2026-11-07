# UI Reset Map -- TrueReport (client/ + docs)

> Status: PROPOSAL ONLY. No deletions performed. Awaiting approval before any deletion.
> Branch: `ui-reset` (HEAD `9cdf27e`). Tag `before-ui-reset` points to `9cdf27e` (verified `git show-ref --tags`, `git rev-parse HEAD`, `git rev-parse before-ui-reset` -- all three equal on 2026-11-07).
> Scope: `git ls-files client` = **677 tracked files**. Untracked/ignored tooling caches (`.gradle/`, `.kotlin/`, `.dart_tool/`, `build/`, `ephemeral/`, `pubspec.lock`) exist on disk (~86 files) -- all regenerable, excluded from this map and from any deletion.
> Rules enforced: light mode only (`ThemeMode.light` in both apps); no static text (ARB only -- `app_en.arb`/`app_ar.arb` + `gen/`); account model from C0 (admin-created chain, no invites); never invent results (unverified items listed at bottom).

## 1. Label definitions

| Label | Meaning |
|---|---|
| KEEP-LOGIC | providers, controllers, repositories, API client, models, routing logic, offline sync, ARB files, fonts, generated l10n, `main.dart` bootstrap, `pubspec.yaml`/`analysis_options.yaml`/`l10n.yaml` build manifests, env `config/*.json`, logic test doubles/guards |
| UI-ONLY | widgets, screens, `design_system` components, gallery, fidelity harness, goldens (`test/goldens/`, `test/failures/`, `docs/ui/**/figma.png|render.png|diff.png`), UI-only tests, theme/token files, platform shells (`android/`, `ios/`, `web/`, `.idea/`), icons/SVGs, docs blobs |
| MIXED | one file contains both UI and logic -- split plan given in sec.3 |

## 2. Counts (authoritative, from `git ls-files client`)

| Label | Count |
|---|---|
| KEEP-LOGIC | 105 |
| UI-ONLY | 560 |
| MIXED | 12 |
| **Total tracked** | **677** |

Notes on counting differences:
- Subagent disk walks reported 763 files on disk (incl. ignored `.gradle/.kotlin` caches) / 761 excl. `pubspec.lock`; git-tracked authoritative set is 677. Ignored caches are UI-ONLY/regenerable and never deleted by hand.
- `analysis_options.yaml`/`pubspec.yaml` are counted as KEEP-LOGIC here (uniform rule: build manifests needed to compile logic). An early per-app pass labeled app-level `analysis_options.yaml` as UI-ONLY -- immaterial for deletion since manifests are never deleted.
- `client/apps/technician_app/lib/src/screens/f2b/f2b_intl.dart` is KEEP-LOGIC (pure `intl` formatting service, verified no-widget -- read 117-line file). `labels.dart`/`ui_helpers.dart` stay UI-ONLY (presentational mappers).

## 3. MIXED files -- how to split (12)

| File | UI part -> stays/goes with UI | Logic part -> stays | Split plan |
|---|---|---|---|
| `client/apps/admin_app/lib/app.dart` | `AdminApp.build` MaterialApp.router shell | `localeProvider` + `adminRouterProvider` wiring | Keep wiring in `app.dart`; extract widget to `screens/app_shell.dart` |
| `client/apps/admin_app/lib/src/admin_router.dart` | `_UnauthorizedPage` widget | `adminRouterProvider`, redirect by `Role` | Keep provider/routes; extract `_UnauthorizedPage` to `screens/unauthorized_page.dart` |
| `client/apps/technician_app/lib/app.dart` | `TechnicianApp.build` shell | `localeProvider` + `technicianRouterProvider` wiring | Keep wiring; extract widget to `screens/app_shell.dart` |
| `client/apps/technician_app/lib/src/technician_router.dart` | `_TechnicianUnauthorizedPage` | `technicianRouterProvider`, GoRoutes, auth redirect | Keep provider/routes; extract widget to `screens/unauthorized_page.dart` |
| `client/apps/technician_app/lib/src/screens/f2a/assigned_jobs_view.dart` | All `*View` widgets/layout | `formatOdometer`, `scheduledTimeUtc4`, `scheduledTodayUtc4` pure helpers | Move helpers to `utils/job_time.dart` (KEEP); widgets stay UI-ONLY |
| `client/apps/technician_app/lib/src/screens/f2a/profile_sheet.dart` | Sheet layout | `authControllerProvider`/locale session read | Keep session/locale reads as caller-injected params; extract pure sheet widget |
| `client/apps/ui_gallery/lib/main.dart` | `_ReleaseBlockedApp` Scaffold/Text | `FixtureGuard.enabled` gate + `runApp` branch | Keep guard in `main.dart`; extract widget to `support/blocked_app.dart` (gallery-only) |
| `client/packages/auth/lib/auth.dart` | barrel UI exports | barrel logic exports | Split into `auth_logic.dart` + `auth_ui.dart` |
| `client/packages/auth/lib/src/role_home.dart` | `RoleHomeScaffold` StatelessWidget | `RoleHomeShell` (`ref.watch(localeProvider)`, signOut) | Extract view to `role_home_view.dart`; keep connector |
| `client/packages/auth/lib/src/router.dart` | `errorBuilder` AppScaffold+ErrorState screen | `routerProvider`, redirect, `_homeFor`, GoRoute table | Keep provider/routes; extract error view to `router_error_view.dart` |
| `client/packages/auth/lib/src/sign_in_page.dart` | `SignInView` build call (view itself already UI-ONLY) | controllers, validation, `_submit`, `_messageFor`, TOTP challenge, `authController` calls | Keep connector; `sign_in_view.dart` stays UI-ONLY |
| `client/packages/auth/lib/src/true_report_app.dart` | `MaterialApp.router` assembly | `localeProvider`/`routerProvider` watches, themeMode/locale/delegates selection | Keep selection logic; extract shell to `true_report_shell.dart` |

Verified by reading: `admin_app/lib/app.dart`, `admin_router.dart`, `technician_router.dart`, `auth/sign_in_page.dart` (128 lines, `_submit`+TOTP+`_messageFor`), `technician f2b_intl.dart` (117 lines, no widgets), `client/pubspec.yaml` (workspace lists `apps/ui_gallery` line 10).

## 4. Docs classification

### 4.1 `docs/ui/` -- 3027 files on disk (measured `Get-ChildItem -Recurse`)

**KEEP-PRODUCT (do not delete):**
| Doc | Reason |
|---|---|
| `docs/ui/apex_vehicle_inspection_ecosystem_product_prd.md` | Ecosystem PRD v1.0.0 -- roles, 4-tier architecture, workflows |
| `docs/ui/c0-report.md` | Normative C0 decisions (admin-created accounts, light-only, ARB restoration) |
| `docs/ui/i18n-inventory.md` | ARB parity evidence (claims 433/433; today counted 463/463 EN/AR -- delta unverified, see sec.7) + allowlist |
| `docs/ui/figma/adr/ADR-C0-001-admin-created-accounts.md` | Normative C0 account model; supersedes Phase-1 RQ3/ADR-0011 invitation model |
| `docs/ui/figma/adr/ADR-F1-006-light-only-theme.md` | Normative light-only rule |

**UI-PROGRESS-ONLY (safe to delete/archive on approval):**
- `docs/ui/DESIGN.md`, `docs/ui/FIGMA_UI_F2A_1_PROMPT.md` (build prompt, not spec)
- `docs/ui/figma/*.md` (52 files): slot sheets (`f2a1/f2b/f3/c0-admin-accounts`), per-screen fidelity audits (`f2a1-audit-01..07`, `f2a2-audit-01..07`), phase reports (`f1/f2a/f2a1/f2a2/f2b1/f2b2/f2b3/f3a/f3-0/app-structure` + test reports), plans (`build-plan`, `build-plan-f3`), `decisions.md` (note A6 light-first superseded by C0 light-only), `decisions-needed.md`, `f3-decisions-needed.md`, `deviations.md`, `gap-report.md`, `inventory.md`, `golden-rebaseline.md`, `contrast-report.md` (pre-C0 incl. dark), `contrast-after.md`, `fonts-and-licences*.md`, `f1-token-api.md`, `f1-fidelity-audit.md`, `tokens.md` (explicit C0 note: dark rows superseded), a11y/i18n + privacy reviews
- `docs/ui/figma/adr/ADR-F1-001..005` (visual direction/colour, type/fonts, token source, component scope/fidelity, consent defaults -- historical once UI rebuilt)
- Screenshot/node dumps: `figma/f1-screenshots/` (5), `figma/f2a-screenshots/` (28), `figma/f3a-screenshots/` (10), `figma/f2a1-nodes/` (15), `figma/f2b-nodes/` (18)
- `docs/ui/figma/fidelity/` (654 files: README + 5 forbidden-terms + 10 evidence dirs `component-samples/30, f2a/96, f2a1/112, f2b/96, f2b3/54, f3a/72, f3b/72, fixtures/70, lint/32, synthetic/14` -- each with `figma.png/render.png/side-by-side/diff.png/metrics.json/REPORT.md/geometry.json/strings.json`)
- `docs/ui/figma/specs/` (57 files: `technician_app/16, workshop_admin/12, platform_admin/10, workshop/12, public_report/7` -- Figma transcription, not normative)
- `docs/ui/figma/tools/` (3: `aggregate-tokens.js`, `contrast-audit.mjs`, `render-tables.js`)
- `docs/ui/figma-export/` (2174 files: `Workshop_admin_figma/724, platform_admin_figma/614, technision_figma/554, public_report_figma/282` -- raw export blobs + `IMPLEMENTATION_GUIDE.txt` + `ASSET_CATALOG.html`)

### 4.2 `docs/` root + `phase-*/` -- ALL KEEP-PRODUCT (no deletions proposed)

No loose files at `docs/` root. Phase dirs: `phase-0/` (10 files), `phase-1/` (17 + `13-adrs/` 22 ADRs), `phase-2/`, `phase-3/`, `phase-3.5/`, `phase-4/`, `phase-5/`, `phase-5b/`, `phase-6/`, `phase-7/`, `phase-8/` (incl. `openapi-endpoints.md`, `security-review.md`, `ops-runbook.md`, `production-readiness.md`).
Known errata needed (not deletion): phase-1 `04-platform-hierarchy.md` + `08-api-design.md` still describe invitation endpoints (superseded by ADR-C0-001); phase-1 ADR-0011 role/account defaults superseded; `phase-3.5/ui-decisions.md` sec.4.7 dark-mode-as-variant superseded by C0 light-only. Add C0 errata notes instead of editing history.

## 5. Smallest deletion set (proposal -- NOT executed)

Constraints honored: backend (`server/`: `Dockerfile, pom.xml, src/, target/` -- `backend/` does not exist) untouched; logic layer + ARB + `gen/` + fonts + C0 decisions intact; each Flutter app still compiles with plain placeholder login + existing navigation.

**D1. Docs blobs (never compiled; `flutter build` unaffected):**
- `docs/ui/figma-export/` (entire dir)
- `docs/ui/figma/fidelity/` (entire dir)
- `docs/ui/figma/f1-screenshots/`, `f2a-screenshots/`, `f3a-screenshots/`, `f2a1-nodes/`, `f2b-nodes/`
- `docs/ui/figma/specs/`, `docs/ui/figma/tools/`
- `docs/ui/figma/*.md` EXCEPT `adr/ADR-C0-001-admin-created-accounts.md`, `adr/ADR-F1-006-light-only-theme.md` (keep those two in place; optionally relocate with `c0-report.md` + `i18n-inventory.md` later -- no move proposed now)
- `docs/ui/DESIGN.md`, `docs/ui/FIGMA_UI_F2A_1_PROMPT.md`
- KEEP: `docs/ui/apex_*_prd.md`, `docs/ui/c0-report.md`, `docs/ui/i18n-inventory.md`, the two normative ADRs, all `docs/phase-*/`

**D2. Gallery app (product apps do not depend on it -- verified via pubspecs; only removal + workspace edit):**
- `client/apps/ui_gallery/` (entire dir: 13 UI-ONLY + 1 MIXED `lib/main.dart` + 2 KEEP manifests + 1 KEEP guard test -- manifests/guard vanish with the dir; no product code references them)
- Edit `client/pubspec.yaml`: remove line 10 `  - apps/ui_gallery` from `workspace:` list

**D3. Product UI code -- content reset only (files stay, bodies replaced with placeholders; routers/navigation kept):**
- `client/apps/admin_app/lib/src/pages/` (all 15 pages: assign_technician_dialog, audit_tab, create_technician_sheet, dashboard_tab, hierarchy_tab, item_form_page, job_form_page, jobs_tab, master_content_tab, platform_admin_home, report_page, schedule_job_sheet, staff_tab, template_builder_page, template_version_page, templates_tab, workshop_admin_home) -> placeholder widgets
- `client/apps/admin_app/lib/src/labels.dart` -> placeholder mappers (ARB keys unchanged)
- `client/apps/technician_app/lib/src/pages/` (9 pages) + `lib/src/screens/f2a/*` (minus extracted helpers) + `lib/src/screens/f2b/*` (minus `f2b_intl.dart`) + `lib/src/ui_helpers.dart` -> placeholders
- `client/packages/auth/lib/src/sign_in_view.dart`, `role_home.dart` (view part), `true_report_app.dart` (shell part), `router.dart` (error view part) -> placeholder login screen + existing navigation (routes/redirects unchanged)
- `client/packages/design_system/lib/src/components/*`, `figma_spec.dart`, `tokens.dart`, `generated/tokens.g.dart`, `tokens/tokens.json`, `assets/icons/*` (154 SVGs), `test/goldens/*`, `test/failures/*` -> replaced by minimal light-only token/component set in a later step (NOT deleted in this step)

**Explicitly NOT deleted in this step:** `server/` anything; `client/packages/{api_client,auth(logic),core,domain,l10n,offline_sync}/` logic; `*/lib/main.dart`, `*router.dart` (logic halves), `admin_api/admin_providers/models/job_counts/report_pdf_saver*`, `technician_api/technician_providers/models/offline/*`, `f2b_intl.dart`, `assigned_jobs_view.dart` helpers, ARB + `gen/` + fonts + `fonts.dart` + `fonts.json`, `config/*.json`, `pubspec.yaml`/`analysis_options.yaml`/`l10n.yaml`, `fake_*`/`test_offline_store`/`fixture_data`, guard/scan tests.

## 6. Tests -- break/fix list

Fidelity/capture/geometry/golden tests read the docs blobs at runtime, so deleting D1 breaks them (they fail on missing `docs/ui/...` paths; some skip, most hard-require). All widget/capture tests also fail after D3 placeholder reset by design (assertions target old Figma-exact trees).

| Test file(s) | Breaks if D1+D2+D3 executed? | Delete or fix |
|---|---|---|
| `admin_app/test/source_scan_test.dart` (pure source/i18n gate) | No -- keep passing; update allowlists after placeholder rewrite | FIX (update expectations) |
| `technician_app/test/i18n_source_scan_test.dart`, `f2a2_asset_guard_test.dart`, `f2b_release_guard_test.dart` | No -- keep passing; asset guards get simpler | FIX if paths change, else keep |
| `technician_app/test/offline_store_test.dart` (+ `support/test_offline_store.dart`, `fake_technician_api.dart`, `f2a_fixture_data.dart`) | No (pure Drift/store logic) | KEEP as-is |
| `admin_app/test/support/fake_admin_api.dart` | No | KEEP as-is |
| `ui_gallery/test/release_guard_test.dart` + `test/gallery_smoke_test.dart` | Deleted with `ui_gallery/` | DELETE with dir |
| All other `admin_app/test/*` (~40 files: widget, f3a/f3b capture, screenshots, geometry, ui_matrix, intl_dates, jobs_queue, report_page, schedule/dashboards/staff/templates) | Yes -- capture/fidelity tests hard-require `docs/ui/figma-export|fidelity` PNGs; widget tests assert old trees | DELETE (fidelity/capture/geometry/goldens + `support/f3*_fixture.dart`, `fidelity harness` helpers) or rewrite after new UI lands; decision needed per file at reset time |
| All other `technician_app/test/*` (f2a/f2b screens, goldens in `test/goldens/` + `test/failures/`, captures, a11y, o2_copy_fit, inspection_ui, intl_dates_tech) | Yes -- same reason | DELETE (same categories); KEEP only the 4 guard/scan/store tests above |
| `design_system/test/*` (9 test files + 32 goldens + harness) | Yes -- all assert current visual contract | DELETE (or park until new token set lands); new minimal-token tests replace them later |

Current suite was NOT run (no `flutter test` executed in this step) -- exact fail count unverified, see sec.7.

## 7. Risks + what could not be verified

1. Fidelity tests write back into `docs/ui/figma/fidelity/` at runtime -- deleting docs mid-suite can leave partial writes; delete docs + tests atomically in the approved commit.
2. `assigned_jobs_view.dart` helpers + `f2b_intl.dart` must be extracted BEFORE pages are placeholdered, or UTC+4/odometer/digit-shaping behavior regresses silently.
3. `auth` barrel split must land with the placeholder login or `SignInPage` imports break both apps (single-consumer change -- coordinate `auth.dart` + both routers).
4. Removing `apps/ui_gallery` from `client/pubspec.yaml` workspace requires `flutter pub get`/`melos` re-resolve; CI scripts referencing gallery must be updated.
5. ARB delta: `i18n-inventory.md` claims 433/433 keys; today counted 463/463 non-`@` keys in `app_en/app_ar.arb`. Cause (growth vs counting method) not investigated -- re-run inventory after reset.
6. NOT verified: full `flutter test` outcome post-deletion (suite not run per no-deletion rule); whether `server/src` references `docs/ui` (out of scope, not deep-dived); binary PNG/SVG contents (enumerated, not opened); who already annotated superseded phase-1 invitation sections (grep shows old text still present with no C0 errata note found).
7. Phase-1 `04-platform-hierarchy` + `08-api-design` + ADR-0011 + phase-3.5 sec.4.7 need C0 errata notes -- proposed as follow-up docs edit, not part of deletion.

## 8. Exact deletion list (execute ONLY after approval)

```text
# D1 -- docs blobs
docs/ui/figma-export/
docs/ui/figma/fidelity/
docs/ui/figma/f1-screenshots/
docs/ui/figma/f2a-screenshots/
docs/ui/figma/f3a-screenshots/
docs/ui/figma/f2a1-nodes/
docs/ui/figma/f2b-nodes/
docs/ui/figma/specs/
docs/ui/figma/tools/
docs/ui/figma/f1-report.md
docs/ui/figma/f2a-report.md
docs/ui/figma/f2a1-report.md
docs/ui/figma/f2a2-report.md
docs/ui/figma/f2b1-report.md
docs/ui/figma/f2b2-report.md
docs/ui/figma/f2b3-report.md
docs/ui/figma/f2b2-test-report.md
docs/ui/figma/f2b3-test-report.md
docs/ui/figma/f3-0-test-report.md
docs/ui/figma/f3a-report.md
docs/ui/figma/f3a-test-report.md
docs/ui/figma/app-structure-report.md
docs/ui/figma/build-plan.md
docs/ui/figma/build-plan-f3.md
docs/ui/figma/decisions.md
docs/ui/figma/decisions-needed.md
docs/ui/figma/f3-decisions-needed.md
docs/ui/figma/deviations.md
docs/ui/figma/gap-report.md
docs/ui/figma/inventory.md
docs/ui/figma/golden-rebaseline.md
docs/ui/figma/contrast-report.md
docs/ui/figma/contrast-after.md
docs/ui/figma/fonts-and-licences.md
docs/ui/figma/fonts-and-licences-final.md
docs/ui/figma/f1-token-api.md
docs/ui/figma/f1-fidelity-audit.md
docs/ui/figma/tokens.md
docs/ui/figma/f2a1-slot-sheet.md
docs/ui/figma/f2b-slot-sheet.md
docs/ui/figma/f3-slot-sheet.md
docs/ui/figma/c0-admin-accounts-slot-sheet.md
docs/ui/figma/f2a1-audit-01-login.md ... f2a1-audit-07-inspection-hub.md (7 files)
docs/ui/figma/f2a2-audit-01-login.md ... f2a2-audit-07-inspection-hub.md (7 files)
docs/ui/figma/f1-a11y-i18n-review.md
docs/ui/figma/f1-privacy-review.md
docs/ui/figma/f2a-a11y-i18n-review.md
docs/ui/figma/f2a-privacy-review.md
docs/ui/figma/adr/ADR-F1-001*.md ... ADR-F1-005*.md (5 files, keep ADR-C0-001 + ADR-F1-006)
docs/ui/DESIGN.md
docs/ui/FIGMA_UI_F2A_1_PROMPT.md
# D2 -- gallery
client/apps/ui_gallery/
# D2b -- workspace edit
client/pubspec.yaml (remove `  - apps/ui_gallery` line only)
# D3 -- UI test + golden + harness files deleted alongside placeholder rewrite
# (admin_app) test/f3a_*, test/f3b_*, test/*_test.dart EXCEPT source_scan_test.dart,
# test/support/* EXCEPT fake_admin_api.dart
# (technician_app) test/f2a_*, test/f2b_*, test/f2b3_*, test/o2_copy_fit_test.dart,
# test/inspection_ui_test.dart, test/intl_dates_tech_test.dart, test/consent_test.dart,
# test/widget_test.dart, test/goldens/, test/failures/, test/support/* EXCEPT
# fake_technician_api.dart, test_offline_store.dart, f2a_fixture_data.dart
# (design_system) test/* + test/goldens/ (replaced later by minimal-token tests)
# D3 content reset (files KEPT, bodies placeholdered -- NOT deletions):
# admin_app/lib/src/pages/*, admin_app/lib/src/labels.dart,
# technician_app/lib/src/pages/*, technician_app/lib/src/screens/f2a/* (keep helpers),
# technician_app/lib/src/screens/f2b/* (keep f2b_intl.dart), technician_app/lib/src/ui_helpers.dart,
# auth/lib/src/sign_in_view.dart + view halves of role_home/router/sign_in_page/true_report_app,
# design_system components/tokens/icons (minimal set lands in later step)
```

STOP: waiting for approval before any deletion. Nothing above has been deleted or committed.

## Appendix A -- every tracked file under client/ (677 rows, generated from `git ls-files client`)

| File | Label | Reason |
|---|---|---|
| `client/.fvmrc` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/apps/admin_app/.gitignore` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/apps/admin_app/.metadata` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/apps/admin_app/README.md` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/apps/admin_app/analysis_options.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/apps/admin_app/android/.gitignore` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/build.gradle.kts` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/src/debug/AndroidManifest.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/src/main/AndroidManifest.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/src/main/kotlin/com/truereport/admin_app/MainActivity.kt` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/src/main/res/drawable-v21/launch_background.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/src/main/res/drawable/launch_background.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/android/app/src/main/res/values-night/styles.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/src/main/res/values/styles.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/app/src/profile/AndroidManifest.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/build.gradle.kts` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/gradle.properties` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/gradle/wrapper/gradle-wrapper.properties` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/android/settings.gradle.kts` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/config/dev.json` | KEEP-LOGIC | Env API endpoints config |
| `client/apps/admin_app/config/prod.json` | KEEP-LOGIC | Env API endpoints config |
| `client/apps/admin_app/config/staging.json` | KEEP-LOGIC | Env API endpoints config |
| `client/apps/admin_app/ios/.gitignore` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Flutter/AppFrameworkInfo.plist` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Flutter/Debug.xcconfig` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Flutter/Release.xcconfig` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner.xcodeproj/project.pbxproj` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner.xcworkspace/contents.xcworkspacedata` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/AppDelegate.swift` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/Base.lproj/LaunchScreen.storyboard` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/Base.lproj/Main.storyboard` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/Info.plist` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/Runner-Bridging-Header.h` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/Runner/SceneDelegate.swift` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/ios/RunnerTests/RunnerTests.swift` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/lib/app.dart` | MIXED | MaterialApp.router shell + locale/router provider wiring | KEEP wiring in app.dart; extract AdminApp widget to screens/app_shell.dart |
| `client/apps/admin_app/lib/main.dart` | KEEP-LOGIC | App bootstrap (ProviderScope.runApp) |
| `client/apps/admin_app/lib/src/admin_api.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/lib/src/admin_providers.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/lib/src/admin_router.dart` | MIXED | adminRouterProvider redirect/role logic + _UnauthorizedPage widget | KEEP provider+routes; extract _UnauthorizedPage to screens/unauthorized_page.dart |
| `client/apps/admin_app/lib/src/job_counts.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/lib/src/labels.dart` | UI-ONLY | Presentational label/tone mappers (UI-ONLY) |
| `client/apps/admin_app/lib/src/models.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/lib/src/pages/assign_technician_dialog.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/audit_tab.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/create_technician_sheet.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/dashboard_tab.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/hierarchy_tab.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/item_form_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/job_form_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/jobs_tab.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/master_content_tab.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/platform_admin_home.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/report_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/schedule_job_sheet.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/staff_tab.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/template_builder_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/template_version_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/templates_tab.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/pages/workshop_admin_home.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/admin_app/lib/src/report_pdf_saver.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/lib/src/report_pdf_saver_io.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/lib/src/report_pdf_saver_stub.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/lib/src/report_pdf_saver_web.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/pubspec.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/apps/admin_app/test/admin_pages_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/assign_technician_dialog_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/create_technician_sheet_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/dashboard_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_capture_assign_product_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_capture_assign_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_capture_dashboard_product_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_capture_dashboard_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_capture_queue_product_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_capture_queue_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_capture_schedule_product_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_capture_schedule_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_geometry_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3a_screenshots_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3b_capture_builder_product_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3b_capture_builder_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3b_capture_create_product_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3b_capture_create_staff_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3b_capture_staff_product_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3b_capture_staff_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3b_capture_templates_product_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/f3b_capture_templates_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/intl_dates_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/jobs_queue_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/report_page_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/schedule_job_sheet_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/source_scan_test.dart` | KEEP-LOGIC | Pure unit/guard/scan test (no widgets) |
| `client/apps/admin_app/test/staff_account_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/staff_roster_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/support/f3a_assign_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/support/f3a_queue_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/support/f3a_schedule_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/support/f3b_builder_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/support/f3b_create_staff_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/support/f3b_staff_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/support/f3b_templates_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/support/fake_admin_api.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/admin_app/test/template_builder_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/template_list_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/ui_matrix_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/test/widget_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/admin_app/web/favicon.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/web/icons/Icon-192.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/web/icons/Icon-512.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/web/icons/Icon-maskable-192.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/web/icons/Icon-maskable-512.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/admin_app/web/index.html` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/admin_app/web/manifest.json` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/.gitignore` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/apps/technician_app/.metadata` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/apps/technician_app/README.md` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/apps/technician_app/analysis_options.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/apps/technician_app/android/.gitignore` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/build.gradle.kts` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/src/debug/AndroidManifest.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/src/main/AndroidManifest.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/src/main/kotlin/com/truereport/technician_app/MainActivity.kt` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/src/main/res/drawable-v21/launch_background.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/src/main/res/drawable/launch_background.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/android/app/src/main/res/values-night/styles.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/src/main/res/values/styles.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/app/src/profile/AndroidManifest.xml` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/build.gradle.kts` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/gradle.properties` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/gradle/wrapper/gradle-wrapper.properties` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/android/settings.gradle.kts` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/config/dev.json` | KEEP-LOGIC | Env API endpoints config |
| `client/apps/technician_app/config/prod.json` | KEEP-LOGIC | Env API endpoints config |
| `client/apps/technician_app/config/staging.json` | KEEP-LOGIC | Env API endpoints config |
| `client/apps/technician_app/ios/.gitignore` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Flutter/AppFrameworkInfo.plist` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Flutter/Debug.xcconfig` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Flutter/Release.xcconfig` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner.xcodeproj/project.pbxproj` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner.xcworkspace/contents.xcworkspacedata` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/AppDelegate.swift` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/Base.lproj/LaunchScreen.storyboard` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/Base.lproj/Main.storyboard` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/Info.plist` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/Runner-Bridging-Header.h` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/Runner/SceneDelegate.swift` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/ios/RunnerTests/RunnerTests.swift` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/lib/app.dart` | MIXED | MaterialApp.router shell + locale/router provider wiring | KEEP wiring; extract TechnicianApp widget to screens/app_shell.dart |
| `client/apps/technician_app/lib/main.dart` | KEEP-LOGIC | App bootstrap (ProviderScope.runApp) |
| `client/apps/technician_app/lib/src/models.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/lib/src/offline/offline_database.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/lib/src/offline/offline_models.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/lib/src/offline/offline_store.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/lib/src/offline/photo_service.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/lib/src/offline/sync_service.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/lib/src/pages/assessment_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/pages/checklist_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/pages/finalized_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/pages/inspection_hub_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/pages/job_detail_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/pages/review_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/pages/sync_queue_page.dart` | UI-ONLY | Screen wiring sync queue to view (UI-ONLY) |
| `client/apps/technician_app/lib/src/pages/technician_jobs_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/pages/walk_in_job_page.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2a/assigned_jobs_view.dart` | MIXED | Assigned-jobs widgets + pure odometer/UTC+4 helpers | Move formatOdometer/scheduledTimeUtc4/scheduledTodayUtc4 to utils/job_time.dart (KEEP); widgets stay UI-ONLY |
| `client/apps/technician_app/lib/src/screens/f2a/consent_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2a/equipment_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2a/inspection_hub_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2a/job_intake_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2a/profile_sheet.dart` | MIXED | Bottom-sheet UI reading authController/locale session | Keep session/locale reads as caller-injected params; extract pure TechnicianProfileSheet widget to screens/ |
| `client/apps/technician_app/lib/src/screens/f2b/defect_detail_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2b/dense_mechanical_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2b/f2b_intl.dart` | KEEP-LOGIC | Pure locale number/date formatting service, no widgets (KEEP) |
| `client/apps/technician_app/lib/src/screens/f2b/f2b_kit.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2b/final_review_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2b/finalize_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2b/offline_sync_view.dart` | UI-ONLY | Stateless sync-queue widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/screens/f2b/success_view.dart` | UI-ONLY | Screen/view widget (UI-ONLY) |
| `client/apps/technician_app/lib/src/technician_api.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/lib/src/technician_providers.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/lib/src/technician_router.dart` | MIXED | technicianRouterProvider auth redirect + _TechnicianUnauthorizedPage | KEEP provider+routes; extract unauthorized widget to screens/unauthorized_page.dart |
| `client/apps/technician_app/lib/src/ui_helpers.dart` | UI-ONLY | Presentational label/tone mappers (UI-ONLY) |
| `client/apps/technician_app/pubspec.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/apps/technician_app/test/consent_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2a1_geometry_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2a2_asset_guard_test.dart` | KEEP-LOGIC | Pure unit/guard/scan test (no widgets) |
| `client/apps/technician_app/test/f2a2_harness_test.dart` | UI-ONLY | Fidelity harness (UI-ONLY) |
| `client/apps/technician_app/test/f2a_fidelity_capture_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2a_goldens_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2a_screens_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2a_screenshots_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b3_capture_defect_detail_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b3_capture_dense_mechanical_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b3_capture_final_review_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b3_capture_finalize_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b3_capture_offline_sync_test.dart` | UI-ONLY | Level-1 offline-sync fixture capture (UI-ONLY) |
| `client/apps/technician_app/test/f2b3_capture_success_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b_a11y_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b_fidelity_capture_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b_geometry_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/f2b_release_guard_test.dart` | KEEP-LOGIC | Pure unit/guard/scan test (no widgets) |
| `client/apps/technician_app/test/f2b_screens_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_assigned-jobs_ar_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_assigned-jobs_ar_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_assigned-jobs_ar_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_assigned-jobs_ar_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_assigned-jobs_en_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_assigned-jobs_en_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_assigned-jobs_en_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_assigned-jobs_en_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_consent_ar_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_consent_ar_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_consent_ar_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_consent_ar_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_consent_en_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_consent_en_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_consent_en_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_consent_en_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_empty-state_ar_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_empty-state_ar_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_empty-state_ar_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_empty-state_ar_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_empty-state_en_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_empty-state_en_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_empty-state_en_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_empty-state_en_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_equipment_ar_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_equipment_ar_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_equipment_ar_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_equipment_ar_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_equipment_en_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_equipment_en_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_equipment_en_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_equipment_en_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_inspection-hub_ar_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_inspection-hub_ar_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_inspection-hub_ar_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_inspection-hub_ar_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_inspection-hub_en_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_inspection-hub_en_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_inspection-hub_en_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_inspection-hub_en_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_job-intake_ar_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_job-intake_ar_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_job-intake_ar_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_job-intake_ar_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_job-intake_en_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_job-intake_en_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_job-intake_en_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_job-intake_en_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_login_ar_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_login_ar_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_login_ar_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_login_ar_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_login_en_light_isolatedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_login_en_light_maskedDiff.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_login_en_light_masterImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/failures/f2a_login_en_light_testImage.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_assigned-jobs_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_assigned-jobs_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_consent_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_consent_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_empty-state_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_empty-state_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_equipment_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_equipment_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_inspection-hub_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_inspection-hub_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_job-intake_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_job-intake_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_login_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/goldens/f2a_login_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/test/i18n_source_scan_test.dart` | KEEP-LOGIC | Pure unit/guard/scan test (no widgets) |
| `client/apps/technician_app/test/inspection_ui_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/intl_dates_tech_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/o2_copy_fit_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/offline_store_test.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/test/support/f2a_fidelity_harness.dart` | UI-ONLY | Fidelity harness (UI-ONLY) |
| `client/apps/technician_app/test/support/f2a_fixture_data.dart` | KEEP-LOGIC | Logic test double / model factories |
| `client/apps/technician_app/test/support/f2a_test_fonts.dart` | UI-ONLY | Test font loader harness (UI-ONLY) |
| `client/apps/technician_app/test/support/f2a_test_images.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/support/f2a_views.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/support/f2b3_defect_detail_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/support/f2b3_finalize_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/support/f2b3_offline_sync_fixture.dart` | UI-ONLY | Test-only Figma-exact fixture widget (UI-ONLY) |
| `client/apps/technician_app/test/support/f2b3_success_fixture.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/support/f2b_views.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/support/fake_technician_api.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/test/support/figma_l10n_override.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/test/support/test_offline_store.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/apps/technician_app/test/widget_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/technician_app/web/drift_worker.js` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/web/favicon.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/web/icons/Icon-192.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/web/icons/Icon-512.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/web/icons/Icon-maskable-192.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/web/icons/Icon-maskable-512.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/apps/technician_app/web/index.html` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/web/manifest.json` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/technician_app/web/sqlite3.wasm` | UI-ONLY | Platform shell / IDE / tooling (UI-ONLY, regenerable) |
| `client/apps/ui_gallery/README.md` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/analysis_options.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/apps/ui_gallery/lib/fixture_guard.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/lib/gallery_app.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/lib/main.dart` | MIXED | FixtureGuard gate + _ReleaseBlockedApp widget | KEEP guard check in main.dart; extract _ReleaseBlockedApp to support/blocked_app.dart |
| `client/apps/ui_gallery/lib/showcase_chrome.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/lib/showcase_components.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/lib/showcase_fidelity.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/lib/showcase_selection.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/lib/showcase_tokens.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/lib/support/gallery_widgets.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/lib/workshop_showcase.dart` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/pubspec.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/apps/ui_gallery/test/gallery_smoke_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/apps/ui_gallery/test/release_guard_test.dart` | KEEP-LOGIC | Pure unit/guard/scan test (no widgets) |
| `client/apps/ui_gallery/web/index.html` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/apps/ui_gallery/web/manifest.json` | UI-ONLY | Gallery app (UI-ONLY) |
| `client/packages/api_client/analysis_options.yaml` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/api_client/lib/api_client.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/api_client/lib/src/api_client.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/api_client/lib/src/api_config.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/api_client/lib/src/api_endpoints.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/api_client/lib/src/problem_details.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/api_client/pubspec.yaml` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/auth/analysis_options.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/auth/lib/auth.dart` | MIXED | Barrel mixing logic+UI exports | Split into auth_logic.dart (controller/repository/session/router) + auth_ui.dart (role_home/sign_in_page/sign_in_view/true_report_app) |
| `client/packages/auth/lib/src/auth_controller.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/auth/lib/src/auth_repository.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/auth/lib/src/role_home.dart` | MIXED | RoleHomeScaffold UI + ConsumerWidget session wiring | Extract RoleHomeScaffold to role_home_view.dart (UI); keep RoleHomeShell ref.watch(locale)+signOut in role_home_connector.dart (KEEP) |
| `client/packages/auth/lib/src/router.dart` | MIXED | routerProvider redirect/role table + ErrorState UI | KEEP provider+redirect+routes; extract errorBuilder AppScaffold+ErrorState to router_error_view.dart |
| `client/packages/auth/lib/src/session_store.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/auth/lib/src/sign_in_page.dart` | MIXED | Controllers/validation/_submit/error mapping + SignInView build | KEEP _submit/_messageFor/validation/auth calls in connector; SignInView already UI-ONLY |
| `client/packages/auth/lib/src/sign_in_view.dart` | UI-ONLY | Presentational auth screen (UI-ONLY) |
| `client/packages/auth/lib/src/true_report_app.dart` | MIXED | localeProvider+routerProvider watches + MaterialApp.router assembly | KEEP watches+themeMode/locale/delegate selection; extract MaterialApp.router assembly to true_report_shell.dart |
| `client/packages/auth/pubspec.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/core/analysis_options.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/core/lib/core.dart` | KEEP-LOGIC | Barrel of AppFailure/Result/Validators (KEEP) |
| `client/packages/core/lib/src/app_failure.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/core/lib/src/result.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/core/lib/src/validators.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/core/pubspec.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/design_system/analysis_options.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/design_system/assets/fonts/IBMPlexSansArabic-Bold.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/IBMPlexSansArabic-Medium.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/IBMPlexSansArabic-Regular.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/IBMPlexSansArabic-SemiBold.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/NotoSans-Regular.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/NotoSansArabic-Bold.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/NotoSansArabic-Medium.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/NotoSansArabic-Regular.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/NotoSansArabic-SemiBold.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/NotoSansSC-Regular.otf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/PlusJakartaSans-Bold.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/PlusJakartaSans-ExtraBold.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/PlusJakartaSans-Medium.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/PlusJakartaSans-Regular.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/PlusJakartaSans-SemiBold.ttf` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/fonts.json` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/licenses/OFL-IBMPlexSansArabic.txt` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/licenses/OFL-NotoSans.txt` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/licenses/OFL-NotoSansArabic.txt` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/licenses/OFL-NotoSansSC.txt` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/fonts/licenses/OFL-PlusJakartaSans.txt` | KEEP-LOGIC | Bundled fonts + OFL (KEEP per rules) |
| `client/packages/design_system/assets/icons/arrow_forward.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/delivery_report_link.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/delivery_workshop_copy.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/eye.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7094.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7101.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7107.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7118.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7128.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7143.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7158.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7167.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7185.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7194.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7207.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7216.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7229.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7238.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7249.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7269.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7274.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7279.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7284.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7302.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7318.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7328.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7335.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7350.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7360.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7378.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7383.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7388.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7393.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7415.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7420.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7450.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7457.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7477.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7480.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7488.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7493.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7513.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7519.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7525.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7530.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7539.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7551.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7563.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7575.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7599.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7611.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7625.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7629.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7637.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7642.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7667.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7675.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7680.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7693.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7706.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7719.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7730.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7736.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7741.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7765.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7790.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7795.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7804.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7807.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7819.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7834.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7848.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7861.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7868.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7873.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7878.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7883.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7888.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_7893.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8026.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8033.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8052.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8070.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8090.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8107.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8115.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8122.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8128.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8134.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8241.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8249.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8255.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8277.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8282.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8288.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8296.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8309.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8317.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8323.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8331.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8335.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8343.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8348.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8367.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8394.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8406.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8408.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8413.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8425.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8427.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8432.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8444.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8446.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8452.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8463.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8473.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8478.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8640.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8648.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8672.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8682.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8700.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8720.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8730.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8740.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8755.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8770.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8781.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8786.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8791.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8796.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8801.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8806.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8815.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8828.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8841.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8851.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8865.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8891.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8901.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8919.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8925.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8930.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8953.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8965.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_8995.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Icon-1_9005.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Vector-1_7607.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Vector-1_7608.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Vector-1_7777.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/figma/Vector-1_7778.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/lock.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/mail.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/assets/icons/shield_check.svg` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/packages/design_system/lib/design_system.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/admin_chrome.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/buttons.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/cards.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/chips.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/data_table.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/figma_components.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/figma_screen_kit.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/icons.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/inputs.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/lists.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/navigation.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/overlays.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/progress.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/results.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/states.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/technician_shell.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/tree_view.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/components/workshop_admin.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/figma_spec.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/fonts.dart` | KEEP-LOGIC | Font-family registry logic |
| `client/packages/design_system/lib/src/generated/tokens.g.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/reduce_motion.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/lib/src/tokens.dart` | UI-ONLY | Design-system component/token (UI-ONLY) |
| `client/packages/design_system/pubspec.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/design_system/test/components_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/packages/design_system/test/fidelity_capture_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/packages/design_system/test/figma_components_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/packages/design_system/test/figma_goldens_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_bottom_nav_dock_ar_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_bottom_nav_dock_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_bottom_nav_dock_en_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_bottom_nav_dock_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_button_ar_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_button_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_button_en_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_button_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_card_ar_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_card_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_card_en_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/app_card_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_delivery_card_ar_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_delivery_card_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_delivery_card_en_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_delivery_card_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_primary_button_ar_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_primary_button_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_primary_button_en_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_primary_button_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_result_selector_ar_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_result_selector_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_result_selector_en_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/figma_result_selector_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/inspection_result_selector_ar_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/inspection_result_selector_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/inspection_result_selector_en_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/inspection_result_selector_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/status_chip_ar_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/status_chip_ar_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/status_chip_en_dark.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/goldens/status_chip_en_light.png` | UI-ONLY | Golden/failure PNG or icon asset (UI-ONLY) |
| `client/packages/design_system/test/shadow_tokens_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/packages/design_system/test/support/fidelity_harness.dart` | UI-ONLY | Fidelity harness (UI-ONLY) |
| `client/packages/design_system/test/tokens_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/packages/design_system/test/workshop_admin_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/packages/design_system/test/zz_hdr2_test.dart` | UI-ONLY | Widget/fidelity/golden/capture test (UI-ONLY) |
| `client/packages/design_system/tokens/tokens.json` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/packages/domain/analysis_options.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/domain/lib/domain.dart` | KEEP-LOGIC | Barrel of domain models (KEEP) |
| `client/packages/domain/lib/src/membership.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/domain/lib/src/role.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/domain/lib/src/session.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/domain/lib/src/user.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/domain/lib/src/workshop.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/domain/pubspec.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/l10n/analysis_options.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/l10n/build/e930abff7417f2f2538fd2ed93b0f137/.filecache` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/packages/l10n/build/e930abff7417f2f2538fd2ed93b0f137/gen_l10n_inputs_and_outputs.json` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/packages/l10n/build/e930abff7417f2f2538fd2ed93b0f137/gen_localizations.d` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/packages/l10n/build/e930abff7417f2f2538fd2ed93b0f137/gen_localizations.stamp` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/packages/l10n/build/e930abff7417f2f2538fd2ed93b0f137/outputs.json` | UI-ONLY | Widget/screen/theme/gallery/platform/tooling (UI-ONLY) |
| `client/packages/l10n/l10n.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/l10n/lib/l10n.dart` | KEEP-LOGIC | Locale provider/notifier logic |
| `client/packages/l10n/lib/l10n/app_ar.arb` | KEEP-LOGIC | ARB strings (KEEP per rules) |
| `client/packages/l10n/lib/l10n/app_en.arb` | KEEP-LOGIC | ARB strings (KEEP per rules) |
| `client/packages/l10n/lib/l10n/gen/app_localizations.dart` | KEEP-LOGIC | Generated l10n (KEEP per rules) |
| `client/packages/l10n/lib/l10n/gen/app_localizations_ar.dart` | KEEP-LOGIC | Generated l10n (KEEP per rules) |
| `client/packages/l10n/lib/l10n/gen/app_localizations_en.dart` | KEEP-LOGIC | Generated l10n (KEEP per rules) |
| `client/packages/l10n/lib/src/locale_controller.dart` | KEEP-LOGIC | Locale provider/notifier logic |
| `client/packages/l10n/pubspec.yaml` | KEEP-LOGIC | Build manifest/lint/l10n config (needed to compile logic) |
| `client/packages/offline_sync/analysis_options.yaml` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/offline_sync/lib/offline_sync.dart` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/packages/offline_sync/pubspec.yaml` | KEEP-LOGIC | Providers/controllers/repositories/API client/models/offline-sync/services/DTOs |
| `client/pubspec.lock` | UI-ONLY | Binary asset/tooling cache (UI-ONLY) |
| `client/pubspec.yaml` | KEEP-LOGIC | Workspace manifest (needed to compile logic) |
