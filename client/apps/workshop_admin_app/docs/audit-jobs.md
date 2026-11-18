# Jobs module — structural audit (read-only)

Date: 2026-11-19 · Scope: `lib/src/features/jobs/**` + its data seams · No code changed.
Inputs: `docs/invariants.md`, `docs/audit-dashboard-jobs.md`, `docs/baseline_allowlist.md`,
`docs/rebuild_queue.md`, server `WorkshopJobAdminController` / `WorkshopJobController` /
`PlatformJobStore` / `checkVersion`.

---

## 1. Summary

**Health: Yellow, with three red seams.** Presentation is disciplined (tokens, states,
ARB, adaptive tests), but the module still runs **two job products against two database
families**, and the clean path has three unguarded edges (publish gating, optimistic
concurrency, filtered counts).

| Screen | Health | Verdict |
|---|---|---|
| Queue (`jobs_tab`) | **RED** | legacy model + legacy create; replaced in J1 |
| Detail (`job_detail_page`) | **YELLOW** | behaviour survives, 1 141-line composition replaced |
| Wizard (`job_creation_wizard_page`) | YELLOW | survives, old design kit, rehosted on queue |
| Schedule sheet | **RED** | deletes (legacy create) |
| Approve | YELLOW | survives, old kit + generic error mapping |
| Checklist | YELLOW | survives, only publish gate, needs document link |
| Documents | GREEN | survives with small fixes |
| Board (`jobs_board_tab`) | YELLOW | survives, counts are not filter-scoped |
| Notifications | YELLOW | survives, raw JSON/type rendering |
| Public link | **RED** | second, ungated publish path |
| Quick sheet | **RED** | deletes with the legacy queue |
| Assign dialog | **RED/YELLOW** | rewritten (legacy model + legacy assign, no version) |

### The three biggest risks to a module rebuild

1. **Data loss / dead rows (blocker).** `inspection_jobs` (legacy, `/api/v1/workshop/legacy/jobs`,
   `WorkshopJobService.create`) and `platform_jobs` (clean, `/api/v1/workshop/jobs`,
   `PlatformJobStore.insertJob`) are **disjoint stores with separate UUID spaces**. Deleting the
   legacy queue and legacy create path makes every `inspection_jobs` row unreachable, and the queue's
   only "New job" path (`jobs_tab.dart:266-272`) is exactly the path that writes them. Client-side
   mapping is impossible (different fields: `scope` vs `templateVersionId`, `FINALIZED` has no clean
   equivalent). See §5.5 and §10.
2. **Publish is gated in the UI only, and one screen bypasses the gate.**
   `public_link_page.dart:159-166, 266-274` calls `publishJob` directly for any non-ACTIVE link.
   The server (`WorkshopJobAdminService.publish`, lines 507-537) checks only `APPROVED`, consent and a
   report version — **not** the checklist. An APPROVED job that fails the checklist can be published
   from this screen.
3. **Optimistic concurrency is optional end-to-end.** `CleanJob.version` is `int?`
   (`workshop_job_models.dart:263`), the UI forwards it unchecked
   (`job_detail_page.dart:234-242, 274-277`), `assignCleanJob`/`cancelCleanJob` accept `int?`
   (`admin_api.dart:1163-1190`) and the server skips the guard when it is null
   (`WorkshopJobAdminService.checkVersion:1076-1080`). A missing `version` silently disables J6.
   The assign dialog sends **no** version at all (`assign_technician_dialog.dart:180-182`).

---

## 2. Screen table

Line counts are physical lines. "Private widgets" excludes the `State` class.
States: L=loading, E=empty, X=error, P=partial (sub-region failures), R=permission/role.

| # | Screen | File | Lines | Private widgets | Regions | States (L/E/X/P/R) | What is structurally wrong | Fate |
|---|---|---|---|---|---|---|---|---|
| 1 | Queue | `jobs_tab.dart` | 273 | 0 | 4 | ✔/✔/✔/✘/✘ | legacy `WorkshopJob` (`:46-47`); counts derived from search snapshot (`:32-38, 118-126`); chips unkeyed (`:103-116`); create opens legacy sheet (`:266-272`); row opens legacy quick sheet (`:258-264`); dead `jobCountsProvider` invalidation (`:262, 270`) | **Replaced** (J1) |
| 2 | Detail | `job_detail_page.dart` | 1141 | 11 | 8 | ✔/✔/✔/✔/✘ | duplicate spacing (`:138-140`); inline assign duplicates the dialog (`:170-256`); terminal predicate incomplete — excludes CANCELLED/PUBLISHED/FINALIZED but not APPROVED/REJECTED (`:48-52`); primary action switch sends CANCELLED/REJECTED to publish checklist (`:897-913`); generic mutation failures (`:246-250, 284-288`) | **Survives**, rewritten into region files |
| 3 | Wizard | `job_creation_wizard_page.dart` | 498 | 0 | 6 | ✔/✔/✔/✘/✘ | old visual kit (`:57, 69, 103, 392`); unreachable from queue; only 3 of 9 fields carry keys (`:132, 139, 166`); step label concatenated (`:104`) | Survives, restyled + rehosted |
| 4 | Schedule sheet | `schedule_job_sheet.dart` | 422 | 2 | 2 | ✔/✔/✔/✘/✘ | legacy `WorkshopJob` return (`:21, 25`); `createJob` → `/legacy/jobs` (`:393-409`); `scope` required (`:313-319`) has no clean equivalent; duplicate template picker (`:335-371`) | **Deleted** |
| 5 | Approve | `approve_job_page.dart` | 321 | 0 | 3 | ✔/✘/✔/✘/✘ | old kit (`:78-140, 199-229`); maps every failure to one string (`:273-276, 306-309`) so `APPROVER_IS_TECHNICIAN` and `JOB_NOT_PENDING_REVIEW` are invisible; version nullable (`:263, 298`) | Survives, restyled |
| 6 | Publish checklist | `publish_checklist_page.dart` | 268 | 0 | 3 | ✔/✘/✔/✘/✘ | nested `JobPanel` per checklist row (`:155-186`); old `AppButton` (`:211`); no documents/public-link route; checklist is the **only** client gate (`:214`) | Survives |
| 7 | Documents | `job_documents_page.dart` | 192 | 0 | 2 | ✔/✔/✔/✘/✘ | old kit for rows (`:83-152`); "Download" copies a URL to clipboard (`:145-151, 184-190`) rather than downloading | Survives (small fixes) |
| 8 | Board | `jobs_board_tab.dart` | 652 | 3 | 5 | ✔/✔/✔/✘/✘ | counts are workshop-global, not filter/search scoped (`:61, 143-149`); search key is `jobs-jobs-search` (`:100`); duplicate row/header composition (`:326-652`); chip values use clean vocabulary while queue uses legacy | Survives |
| 9 | Notifications | `workshop_notifications_page.dart` + `notification_center.dart` | 72 + 197 | 0 + 1 | 3 | ✔/✔/✔/✘/✘ | raw `item.type` and raw `payloadJson` rendered as user copy (`notification_center.dart:147-177`); fixed 60-px top bar (`workshop_notifications_page.dart:31-32`) untested at 2× | Survives |
| 10 | Public link | `public_link_page.dart` | 351 | 0 | 4 | ✔/✘/✔/✘/✘ | raw status code as label (`:82`); **publish bypasses checklist** (`:159-166, 266-274`); old `AppButton` row (`:142-190`); "Share" = clipboard (`:257-264`) | **RED — fix/replace publish action** |
| 11 | Quick sheet | `job_quick_sheet.dart` | 253 | 1 | 3 | n/a/✘/✘/✘/✘ | takes legacy `WorkshopJob` (`:17, 37`); assign → legacy API (`:197`); cancel → legacy API without version (`:239`); Report with a legacy id routed to the clean report endpoint (`:188-192`); invalidates legacy providers (`:198-199, 240-241`) | **Deleted** (queue opens detail) |
| 12 | Assign | `assign_technician_dialog.dart` | 353 | 4 | 3 | ✔/✔/✔/✘/✘ | legacy `WorkshopJob` (`:38`); `assignJob` legacy endpoint, no version (`:180-182`); rejects only FINALIZED/CANCELLED, so PUBLISHED/APPROVED/REJECTED are offered (`:44, 127`); second assign implementation vs detail | **Rewritten** or deleted in favour of one shared sheet |

---

## 3. Data / provider map per screen

Vocabulary notes: **legacy** = `DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, READY_TO_FINALIZE, FINALIZED, CANCELLED`.
**Clean** = `DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, PENDING_REVIEW, APPROVED, PUBLISHED, REJECTED, CANCELLED`
plus `reviewStatus ∈ {NOT_SUBMITTED, PENDING_REVIEW, APPROVED, REJECTED}` and
`publicationStatus ∈ {UNPUBLISHED, NOT_PUBLISHED, ACTIVE, REVOKED}`.

| Screen | Provider | AdminApi method | Endpoint | Model | Status vocabulary |
|---|---|---|---|---|---|
| Queue | `jobsProvider(key)` twice (`admin_providers.dart:90-99`) | `jobs()` (`admin_api.dart:813-827`) | `GET /api/v1/workshop/legacy/jobs` | `WorkshopJob` (`models.dart:489-550`) | legacy |
| Queue (dead) | `jobCountsProvider` (`:101-103`) | `jobCounts()` (`:830-836`) | `GET /api/v1/workshop/legacy/jobs/counts` | `JobCounts` (`job_counts.dart`) | legacy |
| Detail | `cleanJobProvider(id)` (`workshop_job_providers.dart:46-51`) | `cleanJob()` (`:1138-1141`) | `GET /workshop/jobs/{id}` | `CleanJob` | clean |
| Detail (findings) | `jobReviewProvider(id)` (`:64-69`) | `jobReview()` (`:1205-1208`) | `GET /jobs/{id}/review` | `JobReview` | clean |
| Detail (history) | `jobAssignmentsProvider(id)` (`:59-62`) | `jobAssignments()` (`:1194-1202`) | `GET /jobs/{id}/assignments` | `JobAssignment` | ids only |
| Detail (names) | `staffProvider` (`admin_providers.dart:86-88`) | `staff()` (`:805-810`) | `GET /workshop/staff` | `StaffMember` | role/status |
| Detail (mutations) | direct `read` | `assignCleanJob` (`:1163-1178`), `cancelCleanJob` (`:1181-1191`) | `POST /jobs/{id}/assign|cancel` | `CleanJob` | versioned |
| Wizard | `availableTemplatesProvider` (`workshop_job_providers.dart:16-19`) | `availableTemplates()` (`:1098-1104`) | `GET /workshop/template-versions/available` | `AvailableTemplate` | template status |
| Wizard | `staffProvider` | `staff()` | `/workshop/staff` | `StaffMember` | `TECHNICIAN` filter |
| Wizard (create) | direct | `createCleanJob` (`:1144-1151`) | `POST /workshop/jobs` | `CleanJob` | clean |
| Schedule | `templateVersionOptionsProvider` (`admin_providers.dart:133-136`) + `templatesProvider` (`:122-126`) | `templateVersionOptions()`, `templates()` | `/workshop/...` | `TemplateVersionOption`, `TemplateSummary` | template status |
| Schedule (create) | direct | `createJob()` (`:839-869`) | `POST /workshop/legacy/jobs` | `WorkshopJob` | legacy |
| Approve | `cleanJobProvider`, `jobReviewProvider` | `approveJob()` (`:1219-1235`), `rejectJob()` (`:1238-1248`) | `POST /jobs/{id}/approve|reject` | `CleanJob` | versioned |
| Checklist | `publishChecklistProvider(id)` (`:71-74`) | `publishChecklist()` (`:1211-1216`) | `GET /jobs/{id}/publish-checklist` | `PublishChecklist` | clean + booleans |
| Checklist (publish) | direct | `publishJob()` (`:1251-1261`) | `POST /jobs/{id}/publish` | `PublicLink` | `ACTIVE` |
| Documents | `jobDocumentsProvider(id)` (`:88-91`) | `jobDocuments()` (`:1301-1307`), `retryJobDocument()` (`:1310-1318`) | `GET /jobs/{id}/documents`, `POST /documents/{type}/retry` | `JobDocument` | `QUEUED/READY/FAILED` |
| Board | `cleanJobsProvider(key)` (`:26-44`) | `cleanJobs()` (`:1115-1135`) | `GET /workshop/jobs?page&size&status&search&from&to` | `JobPage` → `CleanJob` | clean |
| Board counts | `cleanJobCountsProvider` (`:53-57`) | `cleanJobCounts()` (`:1343-1346`) | `GET /workshop/jobs/counts` | `CleanJobCounts` | clean, **no filter params** |
| Notifications | `notificationsProvider(unreadOnly)` (`:93-96`) | `notifications()` (`:1321-1332`), `readNotification()` (`:1335-1340`) | `/workshop/notifications` | `WorkshopNotification` | `readAt` |
| Public link | `publicLinkProvider(id)` (`:76-79`), `jobQrProvider(id)` (`:81-86`) | `publicLink()`, `jobQr()` | `/jobs/{id}/public-link`, `/jobs/{id}/qr` | `PublicLink` | `ACTIVE/UNPUBLISHED/REVOKED/NOT_PUBLISHED` |
| Public link (mutations) | direct | `publishJob`, `unpublishJob`, `rotateJobToken`, `revokeJob` (`:1251-1288`) | `/jobs/{id}/publish|unpublish|rotate-token|revoke` | `PublicLink` | gate bypass, see F2 |
| Quick sheet | job passed in memory | `assignJob()` (`:872-882`), `cancelJob()` (`:885-891`) | `POST /legacy/jobs/{id}/assign|cancel` | `WorkshopJob` | legacy, **no version** |
| Quick sheet (report) | `reportProvider(jobId)` (`admin_providers.dart:146-151`) | `report()` (`:986-990`) | `GET /workshop/jobs/{id}/report` | `ReportAdmin` | **clean endpoint with legacy id** |
| Assign | job passed in; `staffProvider` | `assignJob()` | `POST /legacy/jobs/{id}/assign` | `WorkshopJob` | legacy |

### Every place the two worlds are mixed

1. `jobs_tab.dart:258-264` → `job_quick_sheet.dart:17` — clean screen hands a **legacy** object to the sheet.
2. `job_quick_sheet.dart:188-192` — legacy id pushed into `ReportPage` → `GET /workshop/jobs/{id}/report` (clean). 404 or another job's report if ids ever collide.
3. `job_quick_sheet.dart:197` → `assign_technician_dialog.dart:38-63, 180-182` — legacy model + legacy assign.
4. `job_quick_sheet.dart:239` — legacy cancel without `version`.
5. `jobs_tab.dart:266-272` — "New job" writes `inspection_jobs`; `jobs_board_tab.dart:299-313` writes `platform_jobs`. Two create contracts, one product.
6. `job_presentation.dart:8-59, 134-546` — one file owns legacy row/helpers while `JobStatusBadge` and `jobWideRowMinWidth` are consumed by the **clean** board (`jobs_board_tab.dart:559, 616`).
7. `labels.dart:31-44` — `jobStatusLabel` maps **both** vocabularies; `labels.dart:47-53` maps tones for both.
8. `workshop_job_models.dart` vs `models.dart` — `CleanJob` and `WorkshopJob` both `fromJson` `status` as a free string; nothing stops a legacy payload entering a clean screen.
9. Tests: `test/support/fake_admin_api.dart:402-430` keeps `jobs()` alongside the clean fake, so the mixed model is exercised in the same fixture set.

---

## 4. Invariant mapping (J1-J18 + module invariants)

| # | Invariant | Enforced by | Test | Status in this module |
|---|---|---|---|---|
| J1 | Two models never mixed | `labels.dart:31`, `job_presentation.dart:18`, quick sheet path | queue/board chips only | **VIOLATED cross-screen** — quick sheet, assign, report (§3) |
| J2 | Counts only from counts endpoint | dashboard, not module | `dashboard_test` | OK (dashboard already on clean counts) |
| J3 | Queue chips client-derived from search snapshot | `jobs_tab.dart:32-38, 118-126` | `jobs_queue_test:241-254` | **Dies with the queue**; replace with server counts + explicit scope label |
| J4 | Board counts scoped to page predicate | `jobs_board_tab.dart:61, 143-149` | `jobs_adaptive_test:104-126` | **FALSE** — counts endpoint takes no filters; search/paging does not rescope chips |
| J5 | Dashboard vs queue "in progress" may differ, never conflated | derived | none | **UNPINNED**; convergence should make one source |
| J6 | Mutations version-guarded | UI forwards `version` | `job_api_error_test:191-209` (transport only) | **UNPINNED** — nullable version; assign dialog sends none |
| J7 | Terminal read-only | `job_detail_page.dart:48-52`, `job_quick_sheet.dart:48-64` | `jobs_queue_test:293-305`; `dashboard_test` | **PARTIAL** — APPROVED/REJECTED still offer assign/cancel; quick sheet dies |
| J8 | Cancel requires reason | `job_detail_page.dart:264-269`; server `requireReason` | none | **PARTIAL** (UI-only, untested) |
| J9 | Publish gated by checklist | `publish_checklist_page.dart:214` | `jobs_adaptive_test:144-180` | **VIOLATED** — public link publishes directly (`public_link_page.dart:159-166, 266-274`); server does not re-check |
| J10 | Revoked link never shown live | `job_detail_page.dart:304-315` | none in UI | **UNPINNED**; public link shows raw `REVOKED` |
| J11 | No fabricated data | screens' state branches | `no_fabricated_data_test` | OK; after deletion the forbidden list must target clean models |
| J12 | All strings localized, no concatenation | ARB + screens | AR tests | **PARTIAL** — raw status/type/JSON (`public_link:82`, `notification_center:147-177`); concatenations (`jobs_tab:227-228`, `job_detail:135, 341, 499`, `wizard:104`) |
| J13 | RTL mirror / LTR data | directional padding + `TextDirection.ltr` | queue/detail AR tests | **PARTIAL** — board counts/notifications/public link lack AR assertions |
| J14 | Stable keys | screens | all job tests | **PARTIAL** — queue chips unkeyed; board search is `jobs-jobs-search` |
| J15 | Six-tab nav contract | `workshop_admin_home.dart:73-108` | `dashboard_test` | OK, untouched |
| J16 | Queue = sheet, board = page | `jobs_tab.dart:259`, `jobs_board_tab.dart:315` | queue/board tests | **Dies by decision** (queue → detail) |
| J17 | Light-only | `AppTheme` | `ui_matrix_test:245-254` | OK |
| J18 | Sign-in pinned | untouched | sign-in suite | OK |

### Module invariants found (must become J19+ / M-series)

- **M1 Tenant scoping is server-derived.** `/api/v1/workshop/**` resolves `workshopId` from the JWT
  membership (`WorkshopJobAdminService.requireWorkshop:730-735`). The client never sends a workshop id.
  The rebuild must not add one to any query/body, or it becomes a cross-tenant vector.
- **M2 Role is workshop-admin-only.** Both controllers carry `@PreAuthorize("hasRole('WORKSHOP_ADMIN')")`;
  `admin_router.dart:38-41` matches it. There is **no per-action role split** in this app — do not invent
  client RBAC; do not let a technician build reach these routes.
- **M3 Lifecycle transitions are server-authoritative.** Assign/update only
  `DRAFT/SCHEDULED/ASSIGNED/IN_PROGRESS`; approve/reject only `PENDING_REVIEW`;
  cancel not `CANCELLED/PUBLISHED/APPROVED/REJECTED`; publish only `APPROVED` + consent + report version.
  Client affordances must mirror these sets (today they do not — F7).
- **M4 Approver ≠ assigned technician** (`WorkshopJobAdminService.approve:428-432`). The client maps this
  to the generic "action failed"; it needs a distinct state.
- **M5 Version must be non-null for every mutation.** Server skips OCC when `version == null`
  (`checkVersion:1076-1080`). Refuse to submit if `job.version == null`.
- **M6 Publish has exactly one client gate.** Only `publish_checklist_page` may call `publishJob`;
  the public-link page may not. (Server change is out of scope — see §10.)
- **M7 Public-link state is independent of job state.** `publicationStatus`/`PublicLink.status` is the
  only source for live/revoked; never infer "live" from `status == PUBLISHED` alone.
- **M8 A job id is namespace-bound.** A legacy id must never be passed to a clean endpoint (report,
  detail, documents). Routing is by source screen, not by id shape.
- **M9 Counts are workshop-wide by contract.** `GET /jobs/counts` has no `status/search/from/to` and
  `CleanJobCounts` has no `readyToFinalize`/`finalized`. Chips must be labelled "whole workshop" or the
  server must add scoped counts; a page-sized client sum is not a count.
- **M10 Every list has four distinct states** — loading, error, empty-because-no-data, empty-because-filtered.
  The queue already distinguishes these (`jobs_tab.dart:170-197`); preserve it in every region file.
- **M11 A filtered empty state must not offer "create" for a screen that cannot create** (documents,
  checklist, public link).
- **M12 Read-only terminal states include the public link, documents, assignment and checklist actions**,
  not just assign/cancel.

---

## 5. Convergence plan — one job object

### 5.0 ADR-JOBS-01 (required before code)

- **Context:** two endpoints, two tables, two vocabularies, one product. Queue cannot open clean detail,
  new jobs do not appear in the queue, and one object is counted twice under one label.
- **Options:** (A) converge on `CleanJob` and delete legacy; (B) keep both and rename surfaces;
  (C) server-side view that unions both. 
- **Decision:** (A) — already recorded in `docs/rebuild_queue.md:60-68`; this audit endorses it **only
  after §5.5 is resolved**, because (A) is lossy for existing `inspection_jobs` rows.
- **Consequences:** one model, one counts source, one create path, one assign path; queue loses
  `READY_TO_FINALIZE`/`FINALIZED` vocabulary; legacy create/assign/cancel/report paths die; tests must be
  rewritten, not merely deleted. Rollback: keep the legacy files behind an unused import until J1 gate,
  then delete in one commit; no server change in this wave.

### 5.1 Seams (exact)

| Seam | Change |
|---|---|
| `jobs_tab.dart:46-47` | `jobsProvider` → `cleanJobsProvider(cleanJobsKey(...))` + `cleanJobCountsProvider` |
| `jobs_tab.dart:103-116` | chips become clean statuses with keys `jobs-filter-<status>`; counts from `CleanJobCounts` |
| `jobs_tab.dart:118-126` | delete `_countFor` client derivation |
| `jobs_tab.dart:209-255` | `JobListHeader`/`JobListRow` → clean row widgets (`board` row can be generalised) |
| `jobs_tab.dart:258-264` | open `JobDetailPage(jobId: job.id)`; delete quick sheet call |
| `jobs_tab.dart:266-272` | open `JobCreationWizardPage`; delete `ScheduleJobSheet` |
| `jobs_tab.dart:262, 270` | drop `jobCountsProvider` invalidation |
| `job_quick_sheet.dart` | delete file; remove `showJobQuickSheet` references |
| `assign_technician_dialog.dart` | replace `WorkshopJob` with `CleanJob`; `assignJob` → `assignCleanJob(..., version: job.version)`; reject unless status ∈ assignable set |
| `job_detail_page.dart:170-256` | delete inline assign; open the single shared assign sheet |
| `job_detail_page.dart:897-913` | primary action switch covers `REJECTED`/`CANCELLED` (read-only / report), `APPROVED` (checklist), `PENDING_REVIEW` (approve) |
| `job_detail_page.dart:48-52` | replace literal status checks with one `JobActions` policy |
| `job_presentation.dart` | keep `jobWideRowMinWidth`, `workshopJobTone`, `JobStatusBadge`, `JobFact`, `JobFactGrid`, `JobPageTopBar`; delete `JobListHeader`, `JobListRow`, `jobVehicle*`, `jobScheduleLabel`, `jobTemplateLabel` (legacy-only) |
| `labels.dart:31-44` | after legacy deletion, remove legacy codes from the switch and add `NOT_SUBMITTED`/`UNPUBLISHED`/`NOT_PUBLISHED` |
| `public_link_page.dart:159-166, 266-274` | delete the publish action; route to checklist. This is M6 |
| `admin_providers.dart:90-103` | delete `jobsProvider`, `jobCountsProvider` |
| `admin_api.dart:133-157, 813-891` | delete `jobs`, `jobCounts`, `createJob`, `assignJob`, `cancelJob` |
| `api_endpoints.dart:107-115` | delete `workshopJobs`, `workshopJobCounts`, `workshopJob`, `assignWorkshopJob`, `cancelWorkshopJob`, `workshopJobAssignments` |
| `models.dart:489-550` | delete `WorkshopJob`; remove the `models.dart` import in `job_presentation.dart` |
| `job_counts.dart` | delete file |
| `schedule_job_sheet.dart` | delete file |
| Board search key `jobs-jobs-search` | rename to `jobs-search` (keeps one contract) |

### 5.2 What breaks (compile-level, expected)

`jobs_queue_test` (constructs `WorkshopJob`, expects `JobListRow`, `job-job-*`), `schedule_job_sheet_test`,
`job_counts_test`, `assign_technician_dialog_test`, `intl_dates_test:125-161`, `job_contract_test:211-232`
(legacy `JobCounts` group), `source_scan_test:273-277`, `support/fake_admin_api.dart:402-430`,
`jobs_adaptive_test` board expectations if counts/labels change. `dashboard_invariants_test:483-509` is a
**model to copy**, not a break (it forbids legacy symbols in `features/dashboard`).

### 5.3 Must be added

- `JobActions` policy (pure Dart) + table-driven test: status → allowed primary/secondary actions,
  terminal set, version requirement.
- A queue row component for `CleanJob` (reuse the board row) with `job-<id>` key.
- A single assign sheet for `CleanJob`, versioned, shared by detail (and any future board action).
- Counts scope copy: either "Whole workshop" beside chips or a server-scoped counts call.
- Distinct error surfaces for `JOB_VERSION_CONFLICT`, `JOB_ALREADY_ASSIGNED`,
  `JOB_NOT_ASSIGNABLE`, `APPROVER_IS_TECHNICIAN`, `CONSENT_REQUIRED`, `REPORT_VERSION_MISSING`.
- A source-proof test mirroring `dashboard_invariants_test`: `features/jobs/**` must contain no
  `jobsProvider|jobCountsProvider|WorkshopJob|inspection_jobs|legacy|job_counts.dart`.
- ARB keys for status/type/publication labels; remove raw-code rendering.

### 5.4 Must be deleted

See §6.

### 5.5 Cannot be done client-side (state this to the owner)

1. **Existing `inspection_jobs` rows.** They are not in `platform_jobs`; no client mapping exists
   (`scope`, `templateName`, `finalizedAt` have no clean counterparts, and UUIDs are unrelated).
   Options: server backfill into `platform_jobs`; a read-only "legacy archive" endpoint; or an explicit,
   signed waiver that those rows become invisible. **Until one is chosen, J1 must not ship the deletion.**
2. **Scoped counts.** `GET /workshop/jobs/counts` accepts no predicate. Search/date-filtered chip counts
   require server params or a documented "whole workshop" label. Client-summing a page would violate
   M9 and J4.
3. **Checklist enforcement on publish.** Server accepts publish without re-evaluating the checklist.
   The only safe client fix is to remove the second publish entry point. A hard guarantee needs a
   server-side checklist check — file in `docs/change_requests.md`.
4. **Non-null OCC.** Server treats `version == null` as "no check". The client can refuse to mutate,
   but only a server change makes the guard mandatory.
5. **Action-level roles.** Server grants every `WORKSHOP_ADMIN` approve/publish/revoke. There is no
   finer permission to mirror. Do not fake one in the UI.

---

## 6. Kill list (explicit)

### Files

| File | Action | Reason |
|---|---|---|
| `lib/src/job_counts.dart` | **delete** | legacy counts DTO; only queue uses it |
| `lib/src/features/jobs/schedule_job_sheet.dart` | **delete** | legacy create |
| `lib/src/features/jobs/job_quick_sheet.dart` | **delete** | legacy object, legacy mutations, cross-world report |
| `lib/src/features/jobs/job_presentation.dart` | **split then delete legacy half** | keep shared badge/tone/fact primitives in `shared/` |
| `lib/src/features/jobs/assign_technician_dialog.dart` | **rewrite** (or delete if merged) | legacy model + unversioned API |
| `lib/src/features/jobs/job_widgets.dart` | **rewrite** | `showJobReasonSheet` still uses `AppTextField`/`AppButton`; move to shared with Workshop primitives |
| `lib/src/models.dart` (`WorkshopJob`) | **delete class** | legacy |
| `lib/src/admin_providers.dart` (`jobsProvider`, `jobCountsProvider`) | **delete** | legacy |
| `lib/src/admin_api.dart` (`jobs`, `jobCounts`, `createJob`, `assignJob`, `cancelJob`) | **delete** | legacy |
| `packages/api_client/.../api_endpoints.dart:107-115` | **delete legacy getters** | unreachable after the above |

### Symbols

`WorkshopJob`, `JobCounts`, `JobsTab` legacy composition, `JobListHeader`, `JobListRow`,
`_QueueFakeApi`, `ScheduleJobSheet`, `showScheduleJobSheet`, `showJobQuickSheet`, `_JobQuickSheet`,
`WorkshopAssignDialog.show(WorkshopJob, …)`, `jobVehicleTitle`, `jobVehicleMeta`,
`jobScheduleLabel`, `jobTemplateLabel`, `_rowSemanticLabel`, `assignJob`, `cancelJob`, `createJob`.

### Tests

| Test | Action |
|---|---|
| `test/jobs_queue_test.dart` | **rewrite** for `CleanJob`; preserve `jobs-search`, `jobs-queue-total`, `job-<id>`, AR/scale matrix; delete subtitle/quick-sheet/finalized-sheet assertions that belong to dead behaviour |
| `test/schedule_job_sheet_test.dart` | **delete** (or replace with a wizard-from-queue test) |
| `test/job_counts_test.dart` | **delete** |
| `test/assign_technician_dialog_test.dart` | **rewrite** against `CleanJob` + `assignCleanJob` + version/409 |
| `test/intl_dates_test.dart` | **rewrite** the `WorkshopJob`/`jobs()` fixture to `CleanJob`/`cleanJobs()` (date assertions survive) |
| `test/job_contract_test.dart:211-232` | **delete** the legacy `JobCounts` group |
| `test/source_scan_test.dart:273-277` | **rewrite** to assert the clean counts path |
| `test/support/fake_admin_api.dart:402-430` | **delete** `jobs()`/legacy create/assign/cancel fakes |
| `test/jobs_adaptive_test.dart` | **edit**: board filter/count expectations, add terminal/public-link cases |
| `test/job_api_error_test.dart` | **keep**; add `JOB_VERSION_CONFLICT` surfaced in the widget, not only transport |
| `test/no_fabricated_data_test.dart` | **edit** forbidden list to `CleanJobCounts`/`cleanJobCounts` |
| `test/workshop_real_font_screenshot_test.dart` | **edit** names/labels only if queue/board screenshot content changes; keep harness |

An empty kill list is not acceptable; this one is 10 files/symbol groups and 11 test actions.

---

## 7. Region file plan (J1 first)

Rule: composition file owns state and ≤ 220 lines; one new widget file per region; no new widget may
import another feature's internals. Shared primitives live in `features/jobs/shared/` and are moved,
not rewritten, from `job_widgets.dart` / `job_presentation.dart`.

### J1 — queue + detail (2 screens; 1 session)

```
features/jobs/queue/
  jobs_queue_page.dart            # state: search, status, provider keys, refresh
  jobs_queue_header.dart          # page header + New job
  jobs_queue_filters.dart         # search + chip row (keys)
  jobs_queue_table.dart           # wide header + rows
  jobs_queue_card_list.dart       # narrow stacked cards
  jobs_queue_states.dart          # loading / error / empty / filtered-empty
features/jobs/detail/
  job_detail_page.dart            # composition + mutations only
  job_detail_top_bar.dart
  job_detail_summary.dart
  job_detail_customer_vehicle.dart
  job_detail_inspection.dart      # includes findings list
  job_detail_assignment.dart
  job_detail_review_publication.dart
  job_detail_action_bar.dart      # primary/secondary, terminal policy
features/jobs/shared/
  job_status_badge.dart           # CleanJob status + review/publication badge
  job_fact.dart / job_fact_grid.dart
  job_page_top_bar.dart
  job_reason_sheet.dart           # Workshop primitives, not App* widgets
  job_row.dart                    # one CleanJob row, wide + stacked
```

### J2 — write path (5 screens; 1 session, under the 6-screen cap)

```
features/jobs/wizard/  job_wizard_page.dart, job_wizard_steps.dart (4), job_wizard_footer.dart
features/jobs/approve/ approve_page.dart, approve_summary.dart, approve_score.dart, approve_actions.dart
features/jobs/publish/ publish_checklist_page.dart, checklist_summary.dart,
                       checklist_items.dart, publish_panel.dart
features/jobs/documents/ documents_page.dart, document_row.dart
# schedule_job_sheet.dart: deleted; queue's New job opens wizard
```

### J3 — client surface (5 screens; 1 session)

```
features/jobs/board/ jobs_board_page.dart, jobs_board_header.dart, jobs_board_filters.dart,
                     jobs_board_table.dart, jobs_board_card_list.dart, jobs_board_pagination.dart
features/jobs/notifications/ notifications_page.dart, notifications_toolbar.dart,
                             notification_card.dart
features/jobs/public_link/ public_link_page.dart, public_link_status.dart,
                           public_link_actions.dart, public_link_qr.dart
features/jobs/assign/ assign_sheet.dart, assign_technician_list.dart, assign_vehicle_strip.dart
# job_quick_sheet.dart: deleted; queue opens detail
```

Cap check: J1 = 2 screens, J2 = 5, J3 = 5. No session exceeds 6. Do not merge J2+J3.

---

## 8. Test-key contract

### Must be preserved (J14)

| Key | Owner | Note |
|---|---|---|
| `jobs-search` | queue | keep exactly; board renames to this |
| `jobs-queue-total` | queue | now shows the server/list total, label must say which |
| `job-<id>` | queue row | keep even though the model changes (J14) |
| `job-detail-refresh` | detail | keep |
| `jobs-filter-<status>` | board + queue | queue adopts the board's pattern |
| `jobs-job-<id>` | board row | keep |
| `workshop-tab-jobs`, `workshop-tab-job-board` | shell | untouched |
| `jobs-approve-button`, `jobs-reject-button`, `jobs-checklist-link` | approve | keep |
| `jobs-checklist-ready-chip`, `jobs-checklist-<code>`, `jobs-publish-button` | checklist | keep |
| `jobs-publish-link-button`, `jobs-share-button`, `jobs-unpublish-button`, `jobs-revoke-button` | public link | keep keys; `jobs-publish-link-button` **must disappear** with M6 |
| `jobs-retry-document-<id>` | documents | keep |
| `jobs-unread-only`, `jobs-mark-read-<id>` | notifications | keep |
| `assign-cancel`, `assign-confirm`, `assign-reason`, `assign-tech-<id>`, `assign-vehicle-strip` | assign | keep for the rewritten sheet |
| `jobs-wizard-next`, `jobs-wizard-customer-name`, `jobs-wizard-customer-phone`, `jobs-wizard-vehicle-make`, `jobs-template-<versionId>`, `jobs-technician-<userId>`, `jobs-technician-later` | wizard | keep |

### Intentionally changed

| Key | Change | Why |
|---|---|---|
| `jobs-jobs-search` | → `jobs-search` | accidental duplicate namespace |
| queue chips | gain `jobs-filter-<cleanStatus>` | D8; values change from legacy to clean |
| `jobs-publish-link-button` | removed | public link may not publish (M6) |
| queue row internals | badge/summary structure may change | J14 only pins `job-<id>`, not type |
| board counts text | "Total (N)" may become "Whole workshop N" | M9/F4 |

New keys to add: `job-detail-primary-action`, `job-detail-more`, `job-cancel-reason`,
`job-assign-sheet`, `jobs-count-scope`, `jobs-filter-count-<status>`, `jobs-board-page-<n>`.

---

## 9. Ranked findings

| # | Sev | Location | Consequence | Fix | Effort | Risk |
|---|---|---|---|---|---|---|
| F1 | **Critical** | `admin_api.dart:813-891`, `api_endpoints.dart:107-115`, `jobs_tab.dart:266-272` | deleting the legacy family hides `inspection_jobs` rows; queue's create writes them | server backfill/archive decision before J1 deletion (§5.5) | L | **high (data)** |
| F2 | **Critical** | `public_link_page.dart:159-166, 266-274` | an APPROVED-but-not-ready job can be published; J9 false | delete publish action; route to checklist; optionally server check | S | med |
| F3 | **High** | `workshop_job_models.dart:263`, `job_detail_page.dart:234-242, 274-277`, `assign_technician_dialog.dart:180-182`, server `checkVersion:1076-1080` | null/absent version disables OCC; concurrent edits overwrite silently | non-null version policy + disable mutation when null; test | S/M | med |
| F4 | **High** | `jobs_board_tab.dart:61, 143-149` | chips show workshop totals while the list is searched/paged; J4 is false | scope label or server params | S | low |
| F5 | **High** | `jobs_tab.dart:266-272` → `schedule_job_sheet.dart:393-409` | queue creates rows the queue's own successor cannot read | rehost wizard; delete sheet | S | low |
| F6 | **High** | `job_detail_page.dart:170-256` vs `assign_technician_dialog.dart:38-195` | two assign UIs, different models, one versioned, one not | one `CleanJob` assign sheet | M | low |
| F7 | **High** | `job_detail_page.dart:48-52, 897-913` | APPROVED/REJECTED get wrong primary/cancel affordances; 409s look like generic failures | `JobActions` policy + table test | M | low |
| F8 | Medium | `public_link_page.dart:82`; `notification_center.dart:147-177` | raw `ACTIVE`/`JOB_PENDING_REVIEW` and raw JSON are user-visible; J12 | map codes to ARB; render payload fields or hide | S | low |
| F9 | Medium | `job_creation_wizard_page.dart:57-103`; `approve_job_page.dart:78-140`; `publish_checklist_page.dart:155-218`; `job_documents_page.dart:83-152`; `public_link_page.dart:142-190`; `job_widgets.dart:168-213` | old `App*` kit beside Workshop kit; visual and behavioural drift | region files on Workshop primitives | M | low |
| F10 | Medium | `job_presentation.dart:8-59, 134-546`; `labels.dart:31-44` | one file/function carries both vocabularies; any new screen can mix them | split shared primitives; legacy half deleted | M | low |
| F11 | Medium | `jobs_tab.dart:103-116` | chips have no keys; only findable by label | add `jobs-filter-<status>` | S | low |
| F12 | Medium | `jobs_board_tab.dart:100` | search key inconsistency breaks a single contract | rename | S | low |
| F13 | Low | `jobs_tab.dart:262, 270`; `job_quick_sheet.dart:198-199, 240-241` | invalidates a provider nothing renders | delete with legacy | S | low |
| F14 | Low | `job_detail_page.dart:138-140` | duplicate `SizedBox` renders dead space | delete one | S | low |
| F15 | Medium | `approve_job_page.dart:273-276, 306-309`; server `approve:428-432` | `APPROVER_IS_TECHNICIAN` indistinguishable from network failure | map `AppFailure.code` to states | S | low |
| F16 | Low | `job_documents_page.dart:145-151, 184-190` | "Download" copies a link; user believes a file saved | download or rename to "Copy link" | S | low |
| F17 | Low | `job_detail_page.dart:90-98` | 403/404 collapse into one error card | distinct forbidden/not-found copy | S | low |

### What is good — keep

- **State discipline:** loading/error/empty/partial are all present and bounded; no full-screen takeovers
  (`jobs_tab.dart:144-197`, `job_detail_page.dart:82-99`, `board:167-209`).
- **Contract tests from JSON:** `job_contract_test.dart` builds every DTO from fixtures and asserts
  non-default values; `job_api_error_test.dart` runs the real `HttpAdminApi` and pins 401/403/404/409/5xx
  plus the endpoint path. This is the pattern to extend, not replace.
- **Anti-fabrication:** `no_fabricated_data_test` and the dashboard's "error shows no numbers" rule.
- **Shared source-proof test:** `dashboard_invariants_test.dart:483-509` — clone it for `features/jobs`.
- **`CleanJobCounts` partition test** (`job_contract_test:184-196`) — keep; it proves the nine statuses
  sum to the total.
- **Adaptive + real-font evidence:** `jobs_adaptive_test` (8 screens × 5 sizes × 2 locales) and
  `workshop_real_font_screenshot_test`; the harness catches Ahem-only evidence.
- **LTR-pinned identifiers** (plate/VIN/phone/reference) and RTL-aware chevrons.

---

## 10. Halt conditions (state plainly)

1. **Do not delete the legacy queue until `inspection_jobs` has a destination.** If production contains
   rows in `inspection_jobs`, J1 silently makes them unreachable. This is a **data-visibility loss**, not
   a refactor. Required: server backfill into `platform_jobs`, a read-only legacy archive endpoint, or a
   signed waiver naming the loss. The client cannot do this.
2. **Do not ship the public-link publish action.** It bypasses the only publish gate the product has, and
   the server does not enforce the checklist. Remove it (M6) even if the rest of J3 slips.
3. **Do not treat `version` as optional.** Any mutation whose `job.version` is null must be blocked in the
   UI; otherwise J6 is decorative and a stale write can move a job.
4. **Do not add a workshop id to requests.** Tenancy is server-derived (M1). Adding one creates a
   cross-tenant path.
5. **Board counts:** if the owner insists chips be search-scoped, that is a server contract change
   (`/jobs/counts` params), not a client fix. File it in `docs/change_requests.md`; do not sum pages.
