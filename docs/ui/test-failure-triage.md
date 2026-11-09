# Test-failure triage — Workshop Admin session baseline (Step 2a gate)

**Baseline (clean HEAD `dd8afbd`, verified identical with and without Step 2a changes): admin_app +184 −91, technician_app +218 −30, design_system +106 pass, ui_gallery +5 pass. Total failing: 121. No failing test is skipped, silenced, or marked expected. The failing set must never grow: exact before/after sets are compared at every sub-step; any new failure stops the line.**

Method: full suites run on workdir-with-changes and on stashed clean HEAD; failure sets diffed (admin: identical modulo the replaced counts-error test; technician: identical). Reasons below come from reading each failing test against the code it exercises (see Step 2a subagent reports). Verdicts use only: **REAL REGRESSION** (code is wrong), **STALE TEST** (test is wrong), **SCREEN-NOT-YET-WIRED** (kept passing or N/A — not used below; every failure below is classified into the first two).

## 1. Git history — what broke the suites and when

- Tags: only `before-ui-reset` → `9cdf27e`. No `before-consolidation*` tag exists (owner v2 snapshot pending). Nothing was committed by the agent.
- Reflog `reset: moving to HEAD` entries are the agent's own Step 2a stash A/B comparisons (all verified restored, one redundant stash dropped). No owner revert/reset found; nothing explains the failures except the commits below.
- Commit order (newest first): `dd8afbd` (HEAD, F3 view rewrite) → `5474f8c` → `622dfdd` → `a74aa76` → `9a15b7d` → `9cdf27e` (snapshot) → older.
- **Admin:** every failing product test file last changed at `9cdf27e`; every F3 view/tab lib file was rewritten after it (last touch `dd8afbd`; `git log -S counts.active` proves `dd8afbd` removed the `counts.active` rendering the dashboard tests expect). The suites were coherent with the lib at the snapshot; the 5 post-snapshot fidelity commits replaced wired views with static showcases and broke them.
- **Technician:** lib moved post-snapshot too (`f2b_kit.dart` @`5474f8c`, `assigned_jobs_view.dart` + `consent_view.dart` @`622dfdd`); `offline_store.dart` last changed pre-snapshot (@`94d9ead`, ancestor of the snapshot) so those 2 failures predate it. Technician failures are therefore mixed: post-snapshot drift, older drift, and environment-sensitive gates (goldens).
- "Last passed": not re-executed historically (would require rebuilding old commits); the evidence above shows test↔lib coherence at `9cdf27e` and divergence only afterward for admin. Technician groups that reference code last changed pre-snapshot (offline_store) were already failing then or are environment-sensitive — flagged per row.

## 2. Admin_app — 91 failing

Fix steps: Shell(4), Queue(2), CreateDrawer(3), AssignDialog(4), Dashboard(1), Staff(5), CreateTech(6), TemplateList(7), TemplateBuilder(8), ReportViewer(9), Deactivation(10), PDFPreview(12); 2b = twin-resolution/scan-scoping step.

### dashboard_test.dart (17) — lib: `pages/dashboard_tab.dart`, `screens/f3a/dashboard_view.dart`

| Test | Reason | Fix step | Verdict |
|---|---|---|---|
| wide EN renders counts and recent jobs | Expects `23` (=14+9 `counts.active`), `34/9/45/56`, `dashboard-search` key, `WorkshopHeader`, stat semantics; view renders only inProgress/readyToFinalize/finalized KPIs, no `active`, no keyed widgets | Dashboard(1) | REAL REGRESSION |
| phone AR stacked with RTL | Expects `JOB-TEST0001` rows + `23`; view is fixed 1280px static English copy | Dashboard(1) | REAL REGRESSION |
| en/ar × 1.5/2.0 × phone/wide overflow (8) | Fixed-pixel Stack/Positioned overflows at 390w/2.0x | Dashboard(1) | REAL REGRESSION |
| search filters the recent list client-side | `onSearch` only setState; `recentJobs` unused by view; no `dashboard-search` key | Dashboard(1) | REAL REGRESSION |
| empty jobs show the empty state | No jobs-empty branch; `recentJobs` ignored | Dashboard(1) | REAL REGRESSION |
| dashboard counts error shows error state, no numbers | (Step 2a replacement — **passes**) | — | — |
| jobs error keeps the counts visible | No `jobsAsync.hasError` branch exists; counts row shows fixture numbers | Dashboard(1) | REAL REGRESSION |
| tab navigation reaches every tab | No `workshop-tab-*` keys at 1280 (wide layout has no TabBar); fixture copy, not fake data | Shell(4)+screens | REAL REGRESSION |
| tapping a job opens the assign flow | No `dashboard-job-*` keys, no `onOpenJob` wiring | Queue(2)→Assign(4) wiring | REAL REGRESSION |
| tapping a finalized job offers the report | Same, no per-job tap | ReportViewer(9) wiring | REAL REGRESSION |
| user chip shows account and workshop names | View falls back to `Marcus Vance/Lead Inspector`; workshop name never passed; tab maps `workshopAdmin→Workshop Lead` literal | Shell(4) | REAL REGRESSION |
| without a session omits the user chip | Header block always renders; `WorkshopUserChip` type never built | Shell(4) | REAL REGRESSION |

### jobs_queue_test.dart (6) — lib: `pages/jobs_tab.dart`, `screens/f3a/queue_view.dart`

| Test | Reason | Fix step | Verdict |
|---|---|---|---|
| header, counted chips and job cards | Expects `Job queue/jobs-search/New job/All(3)/…/WorkshopJobCard×3/Toyota Camry/StatusChip`, no bay/telemetry/export wording; view renders `All(12)/…`, 4 Figma cards, `ACTIVE BAYS 06/08`, `Live sync…` | Queue(2) | REAL REGRESSION |
| status chips filter server-side | Filter is local setState; labels fixed; no `jobs(status)` call | Queue(2) | REAL REGRESSION |
| search narrows and rescopes chips | `onSearch` only setState; family key `search\status` unused by view | Queue(2) | REAL REGRESSION |
| tapping a card opens the detail sheet | No `job-*` keys; cards not tappable; `onOpenJob` never passed | Queue(2) | REAL REGRESSION |
| finalized rows stay read-only | Static cards; assign dialog unreachable from queue | Assign(4) wiring | REAL REGRESSION |
| AR RTL renders `قائمة المهام` | View hardcodes English `Live Job Queue/REAL-TIME DISPATCH/…` | Queue(2) | REAL REGRESSION |

### staff_account_test.dart (6), staff_roster_test.dart (16)

Root causes: `screens/f3b/staff_view.dart` renders 6 static cards (`David Vance…`), chips `8/5/3/6`, metrics `BAY UTILIZATION/SHIFT COMPLIANCE/EV SPECIALISTS`, `Auto-Shift NFC` banner; ignores `staffList`; no `PopupMenuButton`/reset wiring; tab maps `workshopAdmin→Lead Inspector`; `staff_tab.dart` has no loading/error branches. Platform-hierarchy tests in the same file pass.

| Tests | Fix step | Verdict |
|---|---|---|
| staff_account: large text en/ar, create technician en/ar, reset-password dialog en/ar | Staff(5)/CreateTech(6) | REAL REGRESSION (all 6) |
| staff_roster: renders 1280, phone collapse 2.0x, chips/search filter, no bay/shift/cert wording, reset menu keyboard, add trigger, loading/empty, error+retry, signed-in chip, signed-out hides chip (× en/ar) | Staff(5) | REAL REGRESSION (all 16) |

### template_list_test.dart (11) — lib: `pages/templates_tab.dart`, `screens/f3b/template_list_view.dart`

View ignores `templates` (except blueprint count), renders 5 static cards (`100-Point/Quick Oil/EV Audit/DOT/Chassis`), KPI `294 Items/14.2 min/99.4%`, filters `All Protocols(5)…`, footnote audit log; contains `DOT/ISO-9001/certifi…/telematics/PPE/compliance/Bays Bound` wording; no `AppDataTable`; chips/layout icons not focusable; fixed 1280×1586 overflows narrow/2.0x.

| Tests | Fix step | Verdict |
|---|---|---|
| header/KPI/chips/grid, locked-rule copy absent, status chips filter, search narrows, grid/list toggle, create flow, edit opens builder, footnote audit→builder, AR RTL, keyboard Tab, overflow variants (11) | TemplateList(7) | REAL REGRESSION (all 11) |

### intl_dates_test.dart (6)

Only `report_page` formats dates (`_dubaiWallTime`); dashboard/queue views never format `scheduledAt`, show static times, English counts.

| Tests | Fix step | Verdict |
|---|---|---|
| jobs sheet EN/AR, queue chips EN/AR, dashboard card meta+stats EN, dashboard stats AR (6) | Queue(2)/Dashboard(1) | REAL REGRESSION (all 6) |

### ui_matrix_test.dart (20)

`workshop … has no overflow` (en/ar × dark/light × phone/tablet/wide, scales, 2.0x): fixed-size fixture stacks overflow; wide layout has no tab keys for the exercise flow. (Job-form block removed with the page in 2a.)

| Tests | Fix step | Verdict |
|---|---|---|
| all 20 workshop overflow variants | Shell(4)+screens | REAL REGRESSION (all 20) |

### f3b_capture_staff/…_templates_product_test.dart (2)

Level-2 product captures pump real tabs at exact Figma size and expect product strings/geometry; fixtures render Figma copy with fixture keys → expected SSIM/text mismatch by design + viewport overflow.

| Tests | Fix step | Verdict |
|---|---|---|
| capture f3b staff/templates level2 product (2) | Staff(5)/TemplateList(7) | REAL REGRESSION (view not wired; tests encode correct expectation) |

### source_scan_test.dart (5)

| Test | Reason | Fix step | Verdict |
|---|---|---|---|
| colours/font sizes, radii/shadows/gradients, spacing tokens, font families (4) | `Colors./Color(/fontSize/BorderRadius/BoxShadow/EdgeInsets numerics/fontFamily` hardcoded in `screens/f3a|f3b/*` (enumerated Step 2a report §9) | Screens as wired | REAL REGRESSION |
| admin app has no TOTP challenge UI | Flags `totpEnabled: false` session fields in `dashboard_test`/`staff_roster_test`; lib itself has no TOTP UI | 2b (narrow scan to lib/ + fixture allowlist) | STALE TEST |

## 3. Technician_app — 30 failing (deferred: out of Workshop Admin session scope; tracked, not silenced)

Owner decisions needed: (a) forbidden-terms deny-list vs ARB product copy ruling; (b) golden rebaseline policy; (c) `isFigma`-literal cleanup in technician lib. No technician lib/test changes in this session.

| File / tests | Reason | Verdict |
|---|---|---|
| f2a_goldens: consent/empty-state/equipment/inspection-hub/job-intake en+ar (10) | Render drift vs masters from lib literals (R1/R2) | REAL REGRESSION (deferred) |
| f2a_goldens: exterior-wireframe en+ar (2) | No master PNG + missing `_heights` entry (test bug) | STALE TEST (deferred) |
| f2a_screens: F2-A tokens scan | ~97 raw colour/size/radius literals in `screens/f2a/` | REAL REGRESSION (deferred) |
| f2a_screens: product forbidden terms; f2b_screens: product forbidden terms | ARB product copy (`Verified`, `SHIFT ACTIVE`, `Queued`, `No condition score`) matches deny-list; needs copy ruling (a) | REAL REGRESSION (deferred, pending ruling) |
| i18n: Figma sample strings in lib | `isFigma`-gated literals (`David Vance`, `Bay 3/#04`, `Alex Lindqvist`, equipment names…) + comments | REAL REGRESSION (deferred) |
| i18n: raw literals | Hardcoded dock/nav/success copy (`Intake/Fleet/Sync/Profile`, `Back to Job List`, `WhatsApp/Sent`, `VIN ENDING`, …) | REAL REGRESSION (deferred) |
| f2b_screens: primary action heights | Code meets spec (56/64); harness measures wrapper → harness-side | STALE TEST (deferred verification) |
| f2b_screens: slide duration documented | Code now uses `motionDuration` (gap fixed); gate documents old gap | STALE TEST (deferred) |
| f2b_a11y: RTL wraps identifiers in LTR | `success_view` has zero `Directionality(ltr)` for VIN/refs/digits | REAL REGRESSION (deferred) |
| consent (2) | `canSave`/save state transition vs `FakeTechnicianApi` never records | REAL REGRESSION (deferred) |
| inspection_ui (5) | Fixed geometry/clip vs 2.0x + dark; hardcoded dock labels | REAL REGRESSION (deferred) |
| intl_dates_tech (3) | F2-A helpers use `Intl.getCurrentLocale()` (bare `ar` → Western digits) vs F2-B `ar_EG`; views interpolate counts instead of locale helpers | REAL REGRESSION (deferred) |
| o2_copy_fit (1) | Fixed header geometry pushes `Bay 04` pill past 354px | REAL REGRESSION (deferred) |
| offline_store (2) | Schema/reopen race + assessment shape mismatch; lib predates snapshot → older drift, possibly environment-sensitive (Windows file lock) | REAL REGRESSION (deferred, needs env check) |

## 4. Non-growth enforcement

- Recorded sets: admin 91 (`admin_full.txt`), technician 30 (`tech_full.txt`) — full name lists in §2–3 above.
- After every sub-step: re-run affected suites + the §6 guard list, diff failure names against these sets. Any name not in the sets (minus items the step fixed, which must be named in the report) stops the line and is fixed before continuing.
- Step 2a record: admin 95→91 (removed old counts-error test, added 3 passing tests), technician unchanged. Fidelity PNG rewrites under `docs/` during capture runs are restored (`git checkout -- docs/`) so the tree never carries test-run artifacts as modifications.
