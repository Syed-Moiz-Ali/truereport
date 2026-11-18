# Jobs module — data-truth inventory (Gate 1, investigate-only)

Scope: the 12 job surfaces listed in `docs/rebuild_queue.md` — queue, job detail,
creation wizard, schedule sheet, approve/review, publish checklist, documents,
client board, notifications, public link, quick sheet, assign technician.
Target model: **one job object, `CleanJob` on `platform_jobs`**; the legacy
`inspection_jobs` family is scheduled for deletion in this wave.

Nothing under `lib/`, `test/` or `server/` was modified to produce this file.
Six missing sample shapes were added under `docs/data/samples/` (listed in §1.2).

---

## 1. Provenance

### 1.1 What "verified" means here

**There is no reachable server in this environment.** Every status below is
therefore *verified against server source + the client mapper*, never against a
captured live response. Where the two disagree, the disagreement itself is the
finding (see §4). No number in this document was estimated, derived or filled.

The inherited provenance rule, unchanged and quoted from
`docs/data/samples/README.md`:

> **These are not captured responses.** No server was reachable from this
> environment (no Docker; Java 17 only; carried gap from the sign-in wave). Each
> file below is constructed from the server DTO definitions and the client
> mappers, so the **shape** is exact and the **values** are illustrative.
>
> Every file carries `"provenance": "derived-from-dto"` so nothing here can be
> mistaken for evidence of live behaviour. When a server is available, replace
> these with sanitized captures and bump `provenance` to `captured`, recording the
> request, status code and timing in this README.

That rule applies to the six new files in §1.2 as well. None of them is evidence
of runtime behaviour; they are evidence of *shape*.

### 1.2 Samples used

| File | Endpoint | State |
|---|---|---|
| `samples/clean-jobs-page.json` | `GET /workshop/jobs` | pre-existing, `derived-from-dto` |
| `samples/clean-job-counts.json` | `GET /workshop/jobs/counts` | pre-existing, `derived-from-dto` |
| `samples/legacy-jobs.json` | `GET /workshop/legacy/jobs` | pre-existing, `derived-from-dto` |
| `samples/legacy-job-counts.json` | `GET /workshop/legacy/jobs/counts` | pre-existing, `derived-from-dto` |
| `samples/clean-job-review.json` | `GET /workshop/jobs/{id}/review` | **new**, `derived-from-dto` |
| `samples/clean-job-assignments.json` | `GET /workshop/jobs/{id}/assignments` | **new**, `derived-from-dto` |
| `samples/clean-job-checklist.json` | `GET /workshop/jobs/{id}/publish-checklist` | **new**, `derived-from-dto` |
| `samples/clean-job-public-link.json` | `GET /workshop/jobs/{id}/public-link` | **new**, `derived-from-dto` |
| `samples/clean-job-documents.json` | `GET /workshop/jobs/{id}/documents` | **new**, `derived-from-dto` |
| `samples/workshop-notifications.json` | `GET /workshop/notifications` | **new**, `derived-from-dto` |

The four legacy files remain relevant only to the two surfaces that still read
the legacy family (queue, quick sheet) and to the legacy create sheet.

### 1.3 Files read as ground truth

Client: `lib/src/admin_api.dart`, `admin_providers.dart`, `models.dart`,
`workshop_job_models.dart`, `workshop_job_providers.dart`, `job_counts.dart`,
`workshop_clock.dart`, `labels.dart`, `features/jobs/**`,
`features/dashboard/dashboard_tab.dart`, `packages/api_client/lib/src/api_endpoints.dart`,
`packages/l10n/lib/l10n/app_en.arb` + `app_ar.arb`.

Server (`server/src/main/java/com/truereport/...`): `jobs/api/WorkshopJobAdminController.java`,
`jobs/api/WorkshopJobDtos.java`, `jobs/WorkshopJobAdminService.java`,
`jobs/PlatformJobStore.java`, `jobs/PlatformJobDocumentService.java`,
`jobs/WorkshopJobService.java`, `jobs/api/WorkshopJobController.java`,
`identity/api/StaffController.java`, `reports/ReportService.java`,
`technician/TechnicianStore.java`, `shared/error/ApiException.java`, and
`resources/db/migration/V105__workshop_jobs_clean.sql` (external vocabulary
constraints).

---

## 2. Endpoint / table matrix

### 2.1 Per surface

| # | Surface | Endpoint(s) | Server class | Table(s) | Status vocabulary on the wire | Create/update flow | Client model |
|---|---|---|---|---|---|---|---|
| 1 | Queue (Job queue tab) | `GET /workshop/legacy/jobs`, `GET /workshop/legacy/jobs/counts` | `WorkshopJobController` / `WorkshopJobService` | `inspection_jobs` | DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, READY_TO_FINALIZE, FINALIZED, CANCELLED | none in this surface (create goes to the sheet, §4) | `WorkshopJob`, `JobCounts` |
| 2 | Job detail | `GET /workshop/jobs/{id}`, `/assignments`, `/review`; `POST /assign`, `/cancel`; `GET /review`; `POST /approve`, `/reject`; `GET /report` | `WorkshopJobAdminService` (+ `ReportService` for the report button) | `platform_jobs`, `platform_job_assignments`, `platform_job_results`, `platform_report_versions`, `platform_job_approvals` | DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, PENDING_REVIEW, APPROVED, PUBLISHED, REJECTED, CANCELLED | assign / cancel / approve / reject (all send `version`) | `CleanJob`, `JobAssignment`, `JobReview` |
| 3 | Creation wizard | `GET /template-versions/available`, `GET /template-versions/{id}`, `GET /staff`, `POST /jobs` | `WorkshopJobAdminService`, `StaffController` | `platform_jobs`, `platform_templates*`, `workshop_memberships` | created status is ASSIGNED (technician chosen) or DRAFT (never SCHEDULED — no time input) | create only; `Idempotency-Key` sent | `AvailableTemplate`, `JobTemplateDetail`, `StaffMember`, `NewCleanJob` → `CleanJob` |
| 4 | Schedule sheet (legacy create) | `GET /workshop/templates/versions`, `GET /workshop/templates`, `POST /workshop/legacy/jobs` | `WorkshopTemplateService`, `WorkshopJobService` | `inspection_jobs` | row is created in the legacy family; status per legacy defaults | create only; **no idempotency key** | `TemplateVersionOption`, `TemplateSummary`, `WorkshopJob` |
| 5 | Approve / review | `GET /jobs/{id}/review`, `POST /jobs/{id}/approve`, `POST /jobs/{id}/reject` | `WorkshopJobAdminService` | `platform_jobs`, `platform_job_approvals`, `platform_job_status_history`, `platform_report_versions` | status must be PENDING_REVIEW to act | approve / reject (send `version`; approve sends `Idempotency-Key`) | `JobReview`, `CleanJob` |
| 6 | Publish checklist | `GET /jobs/{id}/publish-checklist`, `POST /jobs/{id}/publish` | `WorkshopJobAdminService` | `platform_jobs`, `platform_job_results`, `platform_report_versions`, `platform_public_links` | publish requires status APPROVED + `consent_granted` | publish (sends `Idempotency-Key`; no `version` on the wire) | `PublishChecklist`, `PublicLink` |
| 7 | Documents | `GET /jobs/{id}/documents`, `POST /jobs/{id}/documents/{type}/retry`, `GET /jobs/{id}/documents/{documentId}/content` | `WorkshopJobAdminService`, `PlatformJobDocumentService` | `platform_report_documents`, `platform_document_types` | PENDING, GENERATING, READY, FAILED (DB check constraint) | retry by `documentTypeCode` | `JobDocument` |
| 8 | Client board | `GET /workshop/jobs?page&size&status&search&from&to`, `GET /workshop/jobs/counts` | `WorkshopJobAdminService` | `platform_jobs` | the nine clean statuses | none (create → wizard) | `JobPage`, `CleanJob`, `CleanJobCounts` |
| 9 | Notifications | `GET /workshop/notifications?unreadOnly`, `POST /workshop/notifications/{id}/read` | `WorkshopJobAdminService` | `platform_notifications` | type is free-form `VARCHAR(60)`: JOB_ASSIGNED, JOB_COMPLETED, JOB_APPROVED, JOB_REJECTED, JOB_PUBLISHED | mark read (no version) | `WorkshopNotification` |
| 10 | Public link | `GET /jobs/{id}/public-link`, `POST /publish`, `/unpublish`, `/rotate-token`, `/revoke`, `GET /jobs/{id}/qr` | `WorkshopJobAdminService`, `PlatformJobTokenService`, `PlatformQrService` | `platform_public_links`, `platform_jobs` | link: PENDING, ACTIVE, REVOKED; job publication: UNPUBLISHED, PUBLISHED, REVOKED (two vocabularies) | publish / unpublish / rotate / revoke | `PublicLink` |
| 11 | Quick sheet | legacy read model; `POST /legacy/jobs/{id}/assign`, `/cancel` | `WorkshopJobService` | `inspection_jobs`, `job_assignments` | the seven legacy statuses | assign / cancel (no `version` on the legacy path) | `WorkshopJob` |
| 12 | Assign technician dialog | `GET /workshop/staff`, `POST /legacy/jobs/{id}/assign` | `StaffController`, `WorkshopJobService` | `inspection_jobs`, `job_assignments` | legacy statuses | assign (no `version`) | `StaffMember`, `WorkshopJob` |

### 2.2 Status vocabularies and where they are fixed

| Vocabulary | Values | Proven by | Client usage |
|---|---|---|---|
| Clean job status | DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, PENDING_REVIEW, APPROVED, PUBLISHED, REJECTED, CANCELLED | `WorkshopJobAdminService.STATUSES` L77-79; `V105` check constraint | `CleanJob.status`, board filter, detail badge |
| Clean review status | NOT_SUBMITTED, PENDING_REVIEW, APPROVED, REJECTED | `V105` check constraint; `WorkshopJobAdminService` L231, 271, 283 | `CleanJob.reviewStatus` → detail chip |
| Clean publication status | **UNPUBLISHED, PUBLISHED, REVOKED** | `V105` check constraint; `PlatformJobStore.publish` L292 sets `PUBLISHED` | `CleanJob.publicationStatus` → detail chip. **Client maps `ACTIVE`, which is not a member** (G-J2) |
| Public link status | PENDING, ACTIVE, REVOKED | `V105` check constraint; `linkDto` L1001-1005 | `PublicLink.status` → link page |
| Document status | PENDING, GENERATING, READY, FAILED | `V105` check constraint | `JobDocument.status` |
| Legacy job status | DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, READY_TO_FINALIZE, FINALIZED, CANCELLED | `WorkshopJobService.validateStatus` L271 + entity | queue chips, quick sheet, legacy assign |
| Assignment decision | APPROVED, REJECTED (rows in `platform_job_approvals`) | `insertApproval` calls L458, 494 | not rendered |
| Notification type | free-form; five values written | `WorkshopJobAdminService.notify` call sites | shown raw |

### 2.3 Legacy references that survive in the jobs module (must be closed in J1–J3)

| # | Legacy reference | Where | Consequence |
|---|---|---|---|
| L1 | `jobsProvider` → `GET /workshop/legacy/jobs` | `admin_providers.dart:90-99`, `jobs_tab.dart:46-47` | queue rows are a different table from every other surface |
| L2 | `JobCounts` + `jobCountsProvider` → `/legacy/jobs/counts` | `job_counts.dart`, `admin_providers.dart:101-103` | dashboard-era counts still compiled and invalidated by the queue (`jobs_tab.dart:270`) |
| L3 | `WorkshopJob` model + `models.dart` half | `models.dart:489-550` | the queue/quick-sheet/assign-dialog data contract |
| L4 | `ScheduleJobSheet` → `createJob` → legacy table | `schedule_job_sheet.dart:387-403` | the queue's "New job" writes a job that the board and detail cannot open (T4) |
| L5 | `job_quick_sheet.dart` + `assign_technician_dialog.dart` | reachable only from the queue | a second assign UI, on the legacy endpoint, without `version` |
| L6 | `report_page.dart` → `GET /workshop/jobs/{id}/report` | `job_detail_page.dart:901-907` | that endpoint reads `inspection_jobs` (`ReportService.java:226,248`); a `platform_jobs` id returns 404 (G-J8) |
| L7 | `FINALIZED` in clean-family logic | `job_detail_page.dart:52, 903`; `labels.dart:41`; `jobs_tab.dart:114`; `invariants.md` J7 | no clean job can ever be FINALIZED (approve sets `completed_at`, status APPROVED) → dead branch and an unreachable filter |
| L8 | `report_page.dart` clock helpers | `report_page.dart:20-29` | now delegates to `WorkshopClock`; the old duplicate is gone — but `report_*` endpoints remain legacy |
| L9 | `invariants.md` J4 says `/workshop/clean-jobs/counts` | `docs/invariants.md:17` | stale endpoint name; the client uses `/workshop/jobs/counts` |
| L10 | `JobAssignment` comment "carries ids only" | `workshop_job_models.dart:463-488`, `job_detail_page.dart:682-684` | comment is false: `AssignmentDto` has `technicianName`; the client drops it (G-J4) |

---

## 3. Element inventory per screen

Legend: **VERIFIED** = source + definition proven from server source and client
mapper · **ASSUMED** = plausible, unproven · **SUSPECT** = contradiction or
demonstrable doubt · **MISSING** = no source exists.
Every SUSPECT row names its root cause (`T#` = inherited contradiction, `X#` =
cross-check in §4, `G-J#` = gap in §5).

### 3.1 Queue — `features/jobs/jobs_tab.dart` (legacy)

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| Q1 | Subtitle | "Every inspection job in one place." | static ARB `jobsQueueSubtitle` | — | — | claims all jobs | SUSPECT | T4: only `inspection_jobs`; `platform_jobs` jobs are absent |
| Q2 | Chip "All" count | number | `jobsProvider(search\u0001'')` → `AdminApi.jobs` | `GET /legacy/jobs` | `List<JobDto>.length` | count of rows reachable by the current search, status-unfiltered | VERIFIED | honest to its scope (`job_counts`-free derivation, `jobs_tab.dart:118-126`) |
| Q3 | Chip "In progress" count | number | same | same | `status == 'IN_PROGRESS'` filtered locally | search-scoped | SUSPECT | D2 / X1: identical label to the dashboard's workshop-wide number |
| Q4 | Chip "Ready" count | number | same | same | `status == 'READY_TO_FINALIZE'` | search-scoped | SUSPECT | D2 / X1 (same label collision; `statusReadyToFinalize`) |
| Q5 | Chip "Finalized" count | number | same | same | `status == 'FINALIZED'` | search-scoped | SUSPECT | G-J14: no clean job can carry FINALIZED; the chip is a dead filter after J1 |
| Q6 | Chip count scope qualifier | — | — | — | — | "in this view" is not stated | MISSING | J5/D2; user cannot explain why the dashboard differs |
| Q7 | Footer total | "Total: N" | `jobsProvider(_key)` | `GET /legacy/jobs` | `items.length` | current search **and** status filter | VERIFIED | equals the filtered list length; no pagination exists (`WorkshopJobService.list` L73-82) |
| Q8 | Row vehicle | "Make Model" | `jobsProvider` → `AdminApi.jobs` | `GET /legacy/jobs` | `vehicleMake`, `vehicleModel` | — | VERIFIED | fallback to customer name |
| Q9 | Row year · plate | text | same | same | `vehicleYear`, `vehiclePlate` | — | VERIFIED | |
| Q10 | Row reference | text | same | same | `reference` | — | VERIFIED | |
| Q11 | Row customer | text | same | same | `customerName` | — | VERIFIED | |
| Q12 | Row scheduled | localized date+time | same | same | `scheduledAt` | naive wall time | VERIFIED | T1 policy: `WorkshopClock` treats a naive value as Dubai wall time |
| Q13 | Row technician | text or "Unassigned" | same | same | `assignedTechnicianName` | — | VERIFIED | legacy DTO resolves the name server-side |
| Q14 | Row template | "Name vN" | same | same | `templateName`, `templateVersionNo` | — | VERIFIED | |
| Q15 | Row status badge | localized label + tone | same | same | `status` | 7 legacy values | SUSPECT | G-J9: unknown value falls through to the raw code (`labels.dart:43`) |
| Q16 | Search | text field | `jobsProvider(key)` | `GET /legacy/jobs?search` | server match over reference, customer name/phone/email, make, model, VIN, plate (`WorkshopJobService:278-288`) | per keystroke, no debounce | VERIFIED | broader than the clean search (X13) |
| Q17 | Row tap | opens quick sheet | `showJobQuickSheet` | — | — | — | SUSPECT | D3 / G-J12: a legacy row cannot open the clean detail page |
| Q18 | Loading / error / empty | states | provider async states | — | — | — | VERIFIED | empty copy distinguishes "this view" from "no jobs" |
| Q19 | Pull to refresh | gesture | invalidates legacy list + legacy counts | — | — | — | VERIFIED | invalidates `jobCountsProvider` (legacy) only |
| Q20 | "New job" action | drawer | `ScheduleJobSheet` → `createJob` | `POST /legacy/jobs` | — | — | SUSPECT | T4/L4: writes a row that the board/detail never show |

### 3.2 Job detail — `features/jobs/job_detail_page.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| DT1 | Page title | vehicle, else customer | `cleanJobProvider(id)` → `AdminApi.cleanJob` | `GET /jobs/{id}` | `vehicleMake`, `vehicleModel`, `customerName` | — | VERIFIED | |
| DT2 | Page subtitle | "reference · customer" | same | same | `reference`, `customerName` | — | VERIFIED | |
| DT3 | Status badge | localized label + tone | same | same | `status` | 9 values | VERIFIED | `workshopJobTone` covers the 9 clean values plus the legacy FINALIZED |
| DT4 | Unknown status | raw code | same | same | `status` | — | SUSPECT | G-J9: `jobStatusLabel` default returns the raw enum |
| DT5 | Review sub-chip | "Review: Pending review / Approved / Rejected" | same | same | `reviewStatus` | hidden when equal to `status`; `NOT_SUBMITTED` hidden | VERIFIED | matches the DB vocabulary |
| DT6 | Publication chip | "Published" / "Revoked" / "Not published" | same | same | `publicationStatus` | — | SUSPECT | G-J2: client tests for `ACTIVE`; the column only holds UNPUBLISHED/PUBLISHED/REVOKED → a published job renders "Not published" |
| DT7 | Summary: customer | text | same | same | `customerName` | — | VERIFIED | |
| DT8 | Summary: phone | text (LTR) | same | same | `customerPhone` | null → "Not available" | VERIFIED | |
| DT9 | Summary: vehicle | "Make Model" | same | same | `vehicleMake`, `vehicleModel` | — | VERIFIED | |
| DT10 | Summary: scheduled | localized instant (LTR) | same | same | `scheduledAt` | user-picked naive wall time | VERIFIED | T1 policy |
| DT11 | Summary: technician | name or "Unassigned" | same | same | `assignedTechnicianName` | server `displayName()` lookup | VERIFIED | |
| DT12 | Fact: email | text (LTR) | same | same | `customerEmail` | — | VERIFIED | |
| DT13 | Fact: plate | text (LTR) | same | same | `vehiclePlate` | — | VERIFIED | |
| DT14 | Fact: VIN | text (LTR) | same | same | `vehicleVin` | — | VERIFIED | |
| DT15 | Fact: odometer | "N UNIT" | same | same | `odometerValue`, `odometerUnit` | — | VERIFIED | |
| DT16 | Fact: transmission | text | same | same | `transmission` | server upper-cases | VERIFIED | |
| DT17 | Fact: fuel type | text | same | same | `fuelType` | server upper-cases | VERIFIED | |
| DT18 | Fact: preferred language | English / Arabic | same | same | `preferredLanguage` | `ar` else English | VERIFIED | |
| DT19 | Fact: cancel reason | text | same | same | `cancelReason` | rendered only when non-null | VERIFIED | |
| DT20 | Inspection: template | "Name vN" | same | same | `templateNameEn/Ar`, `templateVersionNo` | — | VERIFIED | |
| DT21 | Inspection: score | number or "-" | same | same | `score` | null until approve | VERIFIED | |
| DT22 | Inspection: grade | code or "Not available" | same | same | `gradeCode` | null until approve | VERIFIED | |
| DT23 | Inspection: safety cap | reason or "Not applied" | same | same | `safetyCapApplied`, `safetyCapReason` | — | VERIFIED | |
| DT24 | Finding: label | localized | `jobReviewProvider` → `AdminApi.jobReview` | `GET /jobs/{id}/review` | `findings[].labelEn/Ar` | one row per template item, assessed or not | VERIFIED | |
| DT25 | Finding: stable code | code (LTR) | same | same | `findings[].stableCode` | — | VERIFIED | |
| DT26 | Finding: result badge | raw code ("NO_ISSUE_OBSERVED") | same | same | `findings[].resultCode` | — | SUSPECT | G-J9: no label map; a raw enum is printed |
| DT27 | Finding: photo count | "Photos: 0" | same | same | `findings[].evidencePhotos` | server sends an **int**; client parses a **list** and renders `.length` | SUSPECT | G-J3 / X7: always 0 even when photos exist |
| DT28 | Finding: video count | "Videos: 0" | same | same | `findings[].evidenceVideos` | same mismatch | SUSPECT | G-J3 / X7 |
| DT29 | Finding: signature | Present / Missing | same | same | `findings[].signaturePresent` | bool | VERIFIED | |
| DT30 | Finding: completed time | localized instant | same | same | `findings[].completedAt` | server-generated UTC wall time (tz-less) | SUSPECT | X6/G-J18: displays 4 h early |
| DT31 | Finding: issue values | key/value grid | same | same | server sends `issueValuesJson` (string); client reads `issueValues` (map) | — | SUSPECT | G-J3: always empty; keys would have no labels either |
| DT32 | Review: items assessed | "N / M" | same | same | `itemsAssessed`, `itemsTotal` | `results.size()` / `templateItems.size()` | VERIFIED | X7 explains the difference from the checklist's count |
| DT33 | Review: score preview | number | same | same | `scorePreview` | recomputed per request | VERIFIED | null until every item is scored |
| DT34 | Review: grade preview | code | same | same | `gradePreview` | active scoring rule boundaries | VERIFIED | |
| DT35 | Review: safety preview | reason | same | same | `safetyCapPreview` | `capReason` of the computed score | VERIFIED | |
| DT36 | Assignment: technician | name or "—" | `jobAssignmentsProvider` + `staffProvider` | `GET /jobs/{id}/assignments`, `GET /workshop/staff` | `technicianId` → local lookup | — | SUSPECT | G-J4: the server sends `technicianName`; the client discards it and shows "—" for any user missing from the staff list |
| DT37 | Assignment: assigned by | name or "—" | same | same | `assignedBy` → local lookup | — | SUSPECT | G-J4 |
| DT38 | Assignment: "Assigned technician" label on `assignedBy` | "Assign technician" | same | same | — | label reused for a different fact | SUSPECT | G-J22: mislabel (`l10n.assignTechnicianTitle`) |
| DT39 | Assignment: time label | "Scheduled at" over `assignedAt` | same | same | `assignedAt` | — | SUSPECT | G-J22: wrong label; `scheduledAt` is a different field |
| DT40 | Assignment: unassigned time | localized instant | same | same | `unassignedAt` | only when closed | SUSPECT | X6/G-J18: 4 h early |
| DT41 | Assignment: reason | text | same | same | `reason` | overwritten by `closeAssignments` when a new assign carries a reason | VERIFIED | |
| DT42 | Action bar primary (PENDING_REVIEW) | "Approve" | `ApproveIssuePage` | — | `status` | — | VERIFIED | |
| DT43 | Action bar primary (PUBLISHED/FINALIZED) | "Report" | `ReportPage` | `GET /workshop/jobs/{id}/report` | — | — | SUSPECT | G-J8: legacy report endpoint reads `inspection_jobs`; clean id → 404. FINALIZED is unreachable |
| DT44 | Action bar primary (default) | "Publish checklist" | `PublishChecklistPage` | — | `status` | everything else, incl. CANCELLED/REJECTED/APPROVED | SUSPECT | G-J21: offers a publish flow where publish is impossible |
| DT45 | Mutation availability | assign/cancel shown | `canMutate` | — | `status` | excludes CANCELLED, PUBLISHED, FINALIZED only | SUSPECT | G-J21: also offers assign/cancel on PENDING_REVIEW, APPROVED, REJECTED where the server always returns 409 |
| DT46 | Reassign label | "Assign"/"Reassign" | same | same | `assignedTechnicianId` | — | VERIFIED | |
| DT47 | Job-level signature | not shown | — | — | `JobDto.signaturePresent` exists, never mapped | — | MISSING | G-J7 |
| DT48 | Failure feedback | "Action failed" snackbar | `on Object` catch | — | `AppFailure.code` discarded | — | SUSPECT | G-J10: 409/422 codes are indistinguishable |
| DT49 | Loading / error | skeleton / bounded error | provider states | — | — | — | VERIFIED | no numbers on failure |

### 3.3 Creation wizard — `features/jobs/job_creation_wizard_page.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| WZ1 | Step chips 1–4 | numbered chips | static | — | — | — | VERIFIED | copy only |
| WZ2 | Customer name | required text | `createCleanJob` body | `POST /jobs` | `customerName` | server requires non-blank | VERIFIED | |
| WZ3 | Customer phone | required text | same | same | `customerPhone` | server requires non-blank | VERIFIED | |
| WZ4 | Email | optional text | same | same | `customerEmail` | server validates `@` only when present | VERIFIED | |
| WZ5 | Make / model | required text | same | same | `vehicleMake`, `vehicleModel` | server requires | VERIFIED | |
| WZ6 | Year | optional number | same | same | `vehicleYear` | server requires 1900–2100 | SUSPECT | G-J12: empty year always 422 `YEAR_INVALID`; client does not pre-validate |
| WZ7 | VIN | optional text | same | same | `vehicleVin` | server requires 17 chars, `[A-HJ-NPR-Z0-9]` | SUSPECT | G-J12: optional client-side, length-only check; `I/O/Q` reach a 422 |
| WZ8 | Plate | optional text | same | same | `vehiclePlate` | server requires non-blank | SUSPECT | G-J12 |
| WZ9 | Odometer | optional number | same | same | `odometerValue` | server requires ≥ 0 | SUSPECT | G-J12 |
| WZ10 | Odometer unit | dropdown KM/MI | same | same | `odometerUnit` | server requires any non-blank; value is upper-cased | ASSUMED | the two values are a client convention, not a server enum |
| WZ11 | Transmission | dropdown AUTOMATIC/MANUAL/CVT | same | same | `transmission` | server requires any non-blank | ASSUMED | same |
| WZ12 | Fuel type | dropdown PETROL/DIESEL/HYBRID/ELECTRIC | same | same | `fuelType` | server requires any non-blank | ASSUMED | same |
| WZ13 | Preferred language | EN/AR toggle | same | same | `preferredLanguage` | server validates `en`/`ar`, defaults `en` | VERIFIED | |
| WZ14 | Template picker | radio cards | `availableTemplatesProvider` → `availableTemplates` | `GET /template-versions/available` | `versionId`, `nameEn/Ar`, `versionNo`, `itemCount` | published template versions with an active template and current version | VERIFIED | |
| WZ15 | Template item count | "N items" | same | same | `itemCount` | counts `included = TRUE` items | VERIFIED | |
| WZ16 | Technician picker | radio cards | `staffProvider` → `staff` | `GET /workshop/staff` | `userId`, `displayName`, `emailMasked`, `role` | `role == TECHNICIAN`; server re-validates ACTIVE + role | VERIFIED | |
| WZ17 | "Assign later" | option → null | same | same | `assignedTechnicianId = null` | created status DRAFT | VERIFIED | |
| WZ18 | Resulting status | not shown | — | — | server: ASSIGNED if technician, else DRAFT | — | SUSPECT | G-J11: the wizard has **no scheduled time**, so `SCHEDULED` is unreachable from the UI |
| WZ19 | Consent | absent | — | — | `CreateJobRequest.consentGranted` exists, never sent | — | MISSING | G-J1: job is created permanently unpublishable |
| WZ20 | Create failure copy | "Server rejected (CODE)" or "Action failed" | `on Object` catch | — | `AppFailure.code` only | — | SUSPECT | G-J10/G-J12: field issues from `JOB_VALIDATION_FAILED` are never shown |
| WZ21 | Scope field | absent | — | — | clean DTO has no `scope` | — | VERIFIED | correct: `scope` is legacy-only |
| WZ22 | Search for customer/vehicle | absent | — | — | — | — | MISSING | no customer/vehicle directory endpoint in scope; not a regression, a scope limit |

### 3.4 Schedule job sheet (legacy create) — `schedule_job_sheet.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| SS1 | Template versions | option cards + dropdown | `templateVersionOptionsProvider` | `GET /workshop/templates/versions` | `versionId`, `templateName`, `versionNo`, `serviceType` | legacy template service | VERIFIED | legacy family |
| SS2 | Template item counts | "N items" caption | `templatesProvider` | `GET /workshop/templates` | `itemCount` keyed by `templateId` | join by `templateId` | ASSUMED | the map lookup is plausible but untested |
| SS3 | Scope | required multi-line text | `createJob` body | `POST /legacy/jobs` | `scope` | legacy-only field | VERIFIED | no clean equivalent |
| SS4 | Scheduled time | picker → `yyyy-MM-ddTHH:mm:00` | `createJob` body | same | `scheduledAt` | naive Dubai wall time | VERIFIED | T1: correct on display only because the client treats naive as Dubai |
| SS5 | Create result | snackbar | same | same | — | — | SUSPECT | T4/L4: the row is invisible to board/detail |
| SS6 | Create failure | "Action failed" | `on Object` | — | — | — | SUSPECT | G-J10 |
| SS7 | Idempotency | none | — | — | — | — | MISSING | a double-submit can create two legacy jobs |

### 3.5 Approve / review — `approve_job_page.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| AP1 | Summary facts | ref/customer/vehicle/technician/score/grade/safety cap | `cleanJobProvider` | `GET /jobs/{id}` | `reference`, `customerName`, `vehicleMake/Model`, `assignedTechnicianName`, `score`, `gradeCode`, `safetyCap*` | — | VERIFIED | |
| AP2 | Items assessed | "Assessed: N / M" | `jobReviewProvider` | `GET /jobs/{id}/review` | `itemsAssessed`, `itemsTotal` | `results.size()` / template size | VERIFIED | |
| AP3 | Score preview | value | same | same | `scorePreview` | live computation | VERIFIED | |
| AP4 | Grade preview | value | same | same | `gradePreview` | active grade boundaries | VERIFIED | |
| AP5 | Safety cap preview | value | same | same | `safetyCapPreview` | computed cap reason | VERIFIED | |
| AP6 | Findings | label → raw result code | same | same | `findings[].labelEn/Ar`, `resultCode` | — | SUSPECT | G-J9: raw enum as the value |
| AP7 | Approve button | always enabled | `AdminApi.approveJob` | `POST /jobs/{id}/approve` | — | server requires status PENDING_REVIEW | SUSPECT | G-J21: enabled on any status; 409 collapsed to one message |
| AP8 | Reject button | requires reason | `AdminApi.rejectJob` | `POST /jobs/{id}/reject` | — | server requires reason + PENDING_REVIEW | VERIFIED | client pre-check matches the server rule |
| AP9 | Approver ≠ technician | no affordance | — | — | — | server guard `APPROVER_IS_TECHNICIAN` | SUSPECT | G-J10: user discovers it as "Action failed" |
| AP10 | Safety-cap reason input | optional text | `approveJob(safetyCapReason)` | `POST /jobs/{id}/approve` | `safetyCapReason` | used only when the computed score applied a cap | VERIFIED | |
| AP11 | Failure message | "Action failed" | catch-all | — | — | — | SUSPECT | G-J10 |

### 3.6 Publish checklist — `publish_checklist_page.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| PC1 | Ready chip | "Ready" / "Not ready" | `publishChecklistProvider` | `GET /jobs/{id}/publish-checklist` | `ready` | every checklist item passed | VERIFIED | server `evaluate().ready` |
| PC2 | Items assessed | "N / M" | same | same | `itemsAssessed`, `itemsTotal` | counts only items in the current template version | VERIFIED | differs from review's `results.size()` (X7) |
| PC3 | Score / grade | values | same | same | `score`, `gradeCode` | full computation | VERIFIED | |
| PC4 | Consent chip | Granted / Missing | same | same | `consentGranted` | `platform_jobs.consent_granted` | VERIFIED | true to the column — and always false for app-created jobs (G-J1) |
| PC5 | Signature chip | Present / Missing | same | same | `signaturePresent` | set by the technician app (`TechnicianStore:212`) | VERIFIED | |
| PC6 | Documents chip | "Documents ready" | same | same | `documentsReady` | **constant `true`** (`WorkshopJobAdminService:410`) | SUSPECT | G-J5: no documents exist before publish |
| PC7 | DOCUMENTS_QUEUED item | "passed" | same | same | `items[].passed` | **constant `true`** (`:862-864`) | SUSPECT | G-J5 |
| PC8 | Safety cap chip | reason / "Not applied" | same | same | `safetyCapApplied`, `safetyCapReason` | job columns, not the recomputation | VERIFIED | |
| PC9 | Checklist rows | passed/failed + message | same | same | `items[].code`, `passed`, `messageEn/Ar` | ordered constant list of 8 | VERIFIED | messages are server-provided bilingual |
| PC10 | Publish gating | button enabled iff `ready` | — | — | `ready` | — | SUSPECT | G-J21: no status check; the server also requires APPROVED → 409 for DRAFT/SCHEDULED/ASSIGNED/IN_PROGRESS/PENDING_REVIEW/REJECTED |
| PC11 | PDF download toggle | switch, default on | `publishJob(pdfDownloadEnabled)` | `POST /jobs/{id}/publish` | `pdfDownloadEnabled` | written to `platform_public_links` | VERIFIED | |
| PC12 | Publish failure | "Publish failed" | catch-all | — | — | — | SUSPECT | G-J10: consent/status/report-version failures are indistinguishable |
| PC13 | Post-publish | navigates to link page | `publicLinkProvider` | `GET /jobs/{id}/public-link` | — | — | VERIFIED | |

### 3.7 Documents — `job_documents_page.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| DOC1 | Name + language chip | "Inspection report (en)" | `jobDocumentsProvider` | `GET /jobs/{id}/documents` | `nameEn/Ar`, `language` | latest report version only | VERIFIED | |
| DOC2 | Status chip | raw "READY"/"FAILED" | same | same | `status` | PENDING/GENERATING/READY/FAILED | SUSPECT | G-J9: raw enum |
| DOC3 | Type row | raw code | same | same | `documentTypeCode` | configured in `platform_document_types` | ASSUMED | a code, not a label; the same value is already in `nameEn/Ar` |
| DOC4 | Language row | "en"/"ar" | same | same | `language` | constrained to en/ar | ASSUMED | raw code |
| DOC5 | Size | "N B" | same | same | `bytes` (nullable) | null → mapper default 0 → "0 B" | SUSPECT | G-J23: a null size is rendered as zero |
| DOC6 | Generated at | localized instant | same | same | `generatedAt` | server-generated UTC wall time | SUSPECT | X6/G-J18: 4 h early |
| DOC7 | Error | text | same | same | `error` | only for FAILED | VERIFIED | |
| DOC8 | Retry | retry by type | `AdminApi.retryJobDocument` | `POST /jobs/{id}/documents/{type}/retry` | `documentTypeCode` | requires an approved report version; 404/409 otherwise | VERIFIED | |
| DOC9 | Download | copies a **relative** path | `Clipboard.setData(downloadUrl)` | none called | `downloadUrl` | `/api/v1/.../content`, no base URL | SUSPECT | G-J6: the label promises a download; the action copies a path, and no content method exists in `ApiEndpoints` |
| DOC10 | Empty state | "No documents" | same | same | `[]` | [] before approval/publish | ASSUMED | G-J16: cannot distinguish "not approved yet" from "none generated" |
| DOC11 | Loading / error | skeleton / bounded error | provider states | — | — | — | VERIFIED | |

### 3.8 Client board — `jobs_board_tab.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| BD1 | Chip "All" count | number | `cleanJobCountsProvider` | `GET /jobs/counts` | `total` | every job in the workshop, **ignores search and status** | SUSPECT | G-J20 / X3: disagrees with the rows whenever a search is active |
| BD2 | Chip "Pending review" count | number | same | same | `pendingReview` | workshop-wide | SUSPECT | G-J20 |
| BD3 | Chip "Approved" count | number | same | same | `approved` | workshop-wide | SUSPECT | G-J20 |
| BD4 | Chip "Published" count | number | same | same | `published` | workshop-wide | SUSPECT | G-J20 |
| BD5 | Page indicator | "Page X of Y" | `cleanJobsProvider(key)` | `GET /jobs?page&size` | `page`, `totalPages` | server page math | VERIFIED | |
| BD6 | Row vehicle | "Make Model" | same | same | `vehicleMake`, `vehicleModel` | — | VERIFIED | |
| BD7 | Row year · plate · VIN | text (LTR) | same | same | `vehicleYear`, `vehiclePlate`, `vehicleVin` | — | VERIFIED | |
| BD8 | Row reference | text (LTR) | same | same | `reference` | — | VERIFIED | |
| BD9 | Row customer | text | same | same | `customerName` | — | VERIFIED | |
| BD10 | Row scheduled | localized instant | same | same | `scheduledAt` | user-picked naive wall time | VERIFIED | T1 policy |
| BD11 | Row status badge | localized label + tone | same | same | `status` | the nine clean values | VERIFIED | unknown → SUSPECT via G-J9 (counted on the detail screen) |
| BD12 | Row technician (stacked) | name or "Unassigned" | same | same | `assignedTechnicianName` | — | VERIFIED | |
| BD13 | Row template (stacked) | "Name" localized | same | same | `templateNameEn/Ar` | — | VERIFIED | |
| BD14 | Order | newest first | server | same | `created_at DESC, id DESC` | **creation** order, not appointment order | VERIFIED | no schedule ordering exists |
| BD15 | Page size | 10 per page | client constant | same | `size` | server clamps 1–100 | VERIFIED | |
| BD16 | Empty state | "No jobs" / "No jobs in this view" | same | same | `items = []` | — | VERIFIED | |
| BD17 | Search | text field | same | same | server match over reference, make, model, VIN, plate | no customer name (X13) | VERIFIED | |
| BD18 | "New job" | wizard | `createCleanJob` | `POST /jobs` | — | — | VERIFIED | T4 is closed for this surface |
| BD19 | Row tap | clean detail | `cleanJobProvider` | `GET /jobs/{id}` | `id` | — | VERIFIED | |
| BD20 | Loading / error | states | provider states | — | — | — | VERIFIED | |

### 3.9 Notifications — `notification_center.dart` + `workshop_notifications_page.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| NT1 | Type | raw "JOB_PUBLISHED" | `notificationsProvider(false)` | `GET /workshop/notifications` | `type` | free-form string | SUSPECT | G-J9: no label map; a machine code is the headline |
| NT2 | Created time | localized instant | same | same | `createdAt` | server-generated UTC wall time | SUSPECT | X6/G-J18: 4 h early |
| NT3 | Read badge | Read / Unread | same | same | `readAt` (null ⇒ unread) | — | VERIFIED | |
| NT4 | Payload | raw JSON string | same | same | `payloadJson` | `{jobId, reference, ...}` | SUSPECT | G-J24: raw JSON on screen, no job link, no field parsing |
| NT5 | Mark read | action | `AdminApi.readNotification` | `POST /workshop/notifications/{id}/read` | — | idempotent (`COALESCE`) | VERIFIED | |
| NT6 | Unread filter | chip | `notificationsProvider(true)` | `?unreadOnly=true` | `read_at IS NULL` | — | VERIFIED | |
| NT7 | Scope | — | — | — | `workshop_id = caller.workshop`, `user_id = caller.user` | per-recipient | VERIFIED | X10: two admins see different lists |
| NT8 | Unread count / bell badge | absent | — | — | — | no count endpoint; would need `items.length` | MISSING | G-J15 |
| NT9 | Empty state | "No notifications" | same | same | `[]` | — | VERIFIED | |

### 3.10 Public link — `public_link_page.dart`

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| PL1 | Status chip | raw "PENDING"/"ACTIVE"/"REVOKED" | `publicLinkProvider` | `GET /jobs/{id}/public-link` | `status` | latest link row, or synthesized PENDING | SUSPECT | G-J9: raw enum |
| PL2 | PDF download chip | "PDF download" / "Not available" | same | same | `pdfDownloadEnabled` | link flag | SUSPECT | G-J25: "disabled" is rendered as "not available"; two different meanings |
| PL3 | Public URL | URL (LTR) | same | same | `publicUrl` | `publicBaseUrl + /r/{token}`, only when a token is returned | VERIFIED | |
| PL4 | Token | token (LTR) | same | same | `token` | decrypted link token | VERIFIED | sensitive by design; never log |
| PL5 | Activated at | localized instant | same | same | `activatedAt` | UTC wall time | SUSPECT | X6/G-J18 |
| PL6 | Revoked at / reason | instant + text | same | same | `revokedAt`, `revocationReason` | — | VERIFIED | field present; time inherits X6 |
| PL7 | Copy link | copies URL | `Clipboard` | — | `publicUrl` | — | VERIFIED | |
| PL8 | Share | copies URL | `Clipboard` | — | `publicUrl` | labelled "Share" | SUSPECT | G-J26: no share sheet; the action is a copy |
| PL9 | Publish now (not active) | button | `AdminApi.publishJob` | `POST /jobs/{id}/publish` | — | server requires APPROVED + consent + report version | SUSPECT | G-J21/G-J1: no precondition shown; every failure collapses to "Action failed" |
| PL10 | Rotate token | button | `AdminApi.rotateJobToken` | `POST /jobs/{id}/rotate-token` | — | requires ACTIVE link | VERIFIED | invalidates the QR provider |
| PL11 | Unpublish | reason sheet | `AdminApi.unpublishJob` | `POST /jobs/{id}/unpublish` | `reason` | requires status PUBLISHED | VERIFIED | |
| PL12 | Revoke | reason sheet | `AdminApi.revokeJob` | `POST /jobs/{id}/revoke` | `reason` | requires ACTIVE link | VERIFIED | |
| PL13 | QR image | 360 px PNG | `jobQrProvider` | `GET /jobs/{id}/qr` | bytes | requires ACTIVE link; 409 otherwise | VERIFIED | empty/error → honest placeholder |
| PL14 | QR while PENDING | placeholder | same | same | — | — | VERIFIED | the 409 is caught and shown as "QR unavailable" |

### 3.11 Quick sheet — `job_quick_sheet.dart` (legacy)

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| QS1 | Title | vehicle, else reference | passed `WorkshopJob` | — | `vehicleMake/Model`, `reference` | snapshot from the queue row | VERIFIED | |
| QS2 | Reference + status badge | text + badge | — | — | `reference`, `status` | legacy vocabulary | VERIFIED | |
| QS3 | Customer name/phone/email | facts | — | — | `customerName`, `customerPhone`, `customerEmail` | — | VERIFIED | |
| QS4 | Scheduled | localized instant | — | — | `scheduledAt` | legacy naive wall time | VERIFIED | T1 policy |
| QS5 | Technician | name or "Unassigned" | — | — | `assignedTechnicianName` | — | VERIFIED | |
| QS6 | Template | "Name vN" | — | — | `templateName`, `templateVersionNo` | — | VERIFIED | |
| QS7 | Assign / Reassign | opens legacy dialog | `WorkshopAssignDialog` | `POST /legacy/jobs/{id}/assign` | — | no `version` | SUSPECT | L5/G-J17: second assign path, legacy table, no concurrency guard |
| QS8 | Report | opens report page | `ReportPage` | `GET /workshop/jobs/{id}/report` | — | legacy report family | SUSPECT | G-J8 |
| QS9 | Cancel | reason dialog | `AdminApi.cancelJob` (legacy) | `POST /legacy/jobs/{id}/cancel` | `reason` | no `version` | SUSPECT | L5/G-J17 |
| QS10 | Post-mutation refresh | legacy providers only | `ref.invalidate` | — | — | board/detail not invalidated | SUSPECT | D3: a second surface can show stale data after a sheet mutation |

### 3.12 Assign technician dialog — `assign_technician_dialog.dart` (legacy)

| # | Element | Displayed as | Provider → API method | Endpoint | DTO field | Definition / window | Status | Root cause / note |
|---|---|---|---|---|---|---|---|---|
| AS1 | Vehicle strip title | vehicle or reference | passed `WorkshopJob` | — | `vehicleMake/Model`, `reference` | — | VERIFIED | |
| AS2 | Vehicle strip detail | "reference · template · scope" | — | — | `templateName`, `scope` | `scope` is legacy-only | VERIFIED | |
| AS3 | Technician options | name + masked email | `staffProvider` → `staff` | `GET /workshop/staff` | `userId`, `displayName`, `emailMasked`, `role`, `status` | `role == TECHNICIAN && status == ACTIVE` | VERIFIED | server re-validates |
| AS4 | Empty technicians | "No technicians" | same | same | `[]` | — | VERIFIED | |
| AS5 | Reason | optional text → null | submit body | `POST /legacy/jobs/{id}/assign` | `reason` | — | VERIFIED | |
| AS6 | Job-state rejection | dialog blocks FINALIZED/CANCELLED | local predicate | — | `status` | — | SUSPECT | G-J21: the server rejects PENDING_REVIEW/APPROVED/REJECTED/PUBLISHED too; those reach "Action failed" |
| AS7 | Confirm | assign | `AdminApi.assignJob` (legacy) | same | `technicianId`, `reason` | no `version` | SUSPECT | L5/G-J17: writes the legacy table, not `platform_jobs` |
| AS8 | Failure | "Action failed" | catch-all | — | — | — | SUSPECT | G-J10 |
| AS9 | Certifications / workload / bays | absent | — | — | — | — | MISSING | not modelled; correctly omitted (never invent) |

---

## 4. Cross-checks (numbers that can disagree)

Each check is written as *claim → method A → method B → verdict*.

| # | Claim | Method A | Method B | Verdict → exact reason |
|---|---|---|---|---|
| X1 | "In progress" is one number | Dashboard hero group: `counts.inProgress` from `GET /jobs/counts` (`dashboard_tab.dart:239,333`) — workshop-wide, all statuses, all time | Queue chip: count of `status == 'IN_PROGRESS'` inside the search-scoped legacy list (`jobs_tab.dart:118-126`) | **They can differ.** Different tables (`platform_jobs` vs `inspection_jobs`), different scope (whole workshop vs current search). This is **D2/J5**; no on-screen qualifier exists (Q6). |
| X2 | Queue footer total equals its chips | Footer `items.length` with search **and** status applied | Chips count with search **and no** status applied | **Differs whenever a status chip is selected.** The footer describes the filtered view; the chips describe the unfiltered match set. Neither hides a bug, but nothing labels the difference. |
| X3 | Board chips describe the rows | Chips: `JobStatusCountsDto` — no parameters at all (`WorkshopJobAdminController:86-89`) | Rows: `JobPageDto` with `status`, `search`, `page`, `size` | **Differs whenever search or status is active, and always differs from a single page of 10.** This is the inverse of D2 (G-J20). |
| X4 | A job on the dashboard appears in the queue | Dashboard + create: `platform_jobs` | Queue: `inspection_jobs` | **Never.** No dual write exists (`PlatformJobStore` writes only `platform_*`; `WorkshopJobService` writes `inspection_jobs`). This is **T4/L4**. |
| X5 | The board's total equals the queue's total | Board: `counts.total` = sum of every `status` row in `platform_jobs` for the workshop | Queue: `items.length` of `inspection_jobs` | **Independent.** Two tables, two lifecycles. Any equality today is a coincidence of seed data. **D3**. |
| X6 | A timestamp means the same thing on every screen | User-picked `scheduledAt`: naive Dubai wall time, stored unchanged | Server-generated `createdAt/updatedAt/startedAt/completedAt/approvedAt/publishedAt/cancelledAt`, `assignedAt`, `notification.createdAt`, `document.generatedAt`: written as `LocalDateTime.now(ZoneOffset.UTC)` into `DATETIME(6)` and serialized with `toString()` | **They do not.** The client rule "naive ⇒ Dubai wall time" is right for `scheduledAt` and **wrong for every server-generated field**, which then renders 4 h early. T1's client fix over-corrects. See G-J18. |
| X7 | Detail's "items assessed" equals the checklist's | `review()` uses `results.size()` — the number of **distinct result item-versions** for the job, with no template filter | `evaluate()` counts only results whose `itemVersionId` is in the **current** template version | **Can differ** if a result exists for an item outside the current version (e.g. template re-published). Both are honest to their own definition, but they are not the same number. |
| X8 | Stored score equals previewed score | `job.score` / `gradeCode` — written only by `approve()` (`PlatformJobStore.approve`) | `scorePreview` / `gradePreview` — recomputed from current results on every request | **Can differ** after an approve if results change (technician edits are blocked in terminal states, so today they usually agree). Never show both as if one number. |
| X9 | "Published" means the same thing on detail and on the link page | Job chip: `platform_jobs.publication_status` ∈ UNPUBLISHED/PUBLISHED/REVOKED | Link page: `platform_public_links.status` ∈ PENDING/ACTIVE/REVOKED | **Two vocabularies.** The client maps the *job* field as if it were the *link* field (tests `ACTIVE`) → detail shows "Not published" for a PUBLISHED job. **G-J2**. |
| X10 | Every admin sees the same notifications | `notifications(workshop, caller.userId, unreadOnly)` | Events are written to the technician (`JOB_ASSIGNED`) or to `job.createdBy` | **No.** Each admin sees only rows addressed to them; a job created by a colleague produces no row for the viewer. Workshop-wide inbox does not exist. |
| X11 | "Documents ready" implies documents exist | Checklist chip + `DOCUMENTS_QUEUED` = constant `true` | `GET /jobs/{id}/documents` → `[]` until a report version exists, and rows are created only by `generateForVersion` **after publish** | **Contradiction.** The chip cannot be true in the state where it is rendered. **G-J5**. |
| X12 | Approve makes publish possible | `approve()` writes score/grade and status APPROVED | `publish()` requires status APPROVED **and** `consent_granted` **and** a report version | **No** for any job created in this app: `consent_granted` is written `false` at create and has no updater (G-J1). Approve → publish is blocked forever. |
| X13 | Search behaves the same on both tabs | Clean: reference, make, model, VIN, plate (`PlatformJobStore:130-140`) | Legacy: reference, customer name, customer phone, customer email, make, model, VIN, plate (`WorkshopJobService:278-288`) | **No.** Searching a customer name finds the row in the queue and not on the board. G-J13. |
| X14 | Dashboard group header count equals the rows under it | Header: `counts.inProgress` / `pendingReview` | List: `size = 3` page (`dashboard_tab.dart:90-93`) | **Differs when the count > 3.** A count above a truncated list, with no "view all" total. Outside the 12 surfaces but it is the same class of defect as X3. |
| X15 | A row's status is always one of the nine | Server writes only the nine (`STATUSES`, DB check constraint) | Client has no exhaustive handling; unknown ⇒ raw string | **Assumed, not enforced client-side.** DB constraint makes it true today; a future migration would print a raw enum. G-J9. |
| X16 | Reopening a job after assign shows the new technician | Detail `assignedTechnicianName` from `jobDto` | Assignment history from `assignmentDto` | **Yes on the summary card**, and on the history row only via the staff directory. If the user left the workshop, history shows "—" although the server sent the name (G-J4). |

### Inherited contradictions, restated with this evidence

- **T4 (two tables / primary action disagrees).** Still true **only for the queue and quick sheet**: the queue's "New job" (`ScheduleJobSheet` → legacy create) and its rows/counts are `inspection_jobs`; the board, dashboard and detail are `platform_jobs`. J1 closes it by deleting the legacy queue family. Evidence: `api_endpoints.dart:79-80` vs `107-108`; `admin_api.dart:813-836` vs `1114-1135`; L1–L4.
- **T5 (a UUID shown as a technician name).** **No longer a UUID.** The detail now resolves names through `staffProvider` and prints "—" otherwise (`job_detail_page.dart:722-742`). But the server has sent `technicianName` since `AssignmentDto` was written (`WorkshopJobDtos.java:175`, `WorkshopJobAdminService:995-999`) and the client mapper drops it (`workshop_job_models.dart:480-487`). T5 is therefore *half-fixed*: no UUID is printed, but a known name is discarded for anyone absent from `staff()` — and `StaffService.staff` returns **only ACTIVE memberships** (`StaffService.java:29`), so a technician who was disabled or transferred out of the workshop renders as "—" in history even though the assignment DTO still carries the name.
- **D2 (two count scopes under one label).** X1. Unchanged; the rebuild must give the queue chips a scope qualifier or move them to a server count with the same predicate.
- **D3 (two parallel job worlds).** X4/X5/X13. Unchanged; the module decision (one `CleanJob`) is the fix and it is not yet implemented.

---

## 5. Gaps (G-J…)

Rules: a gap is an element the design needs that has **no honest source**, or a
source that would render a false statement. Nothing here is to be filled with a
mock or an estimate.

| ID | UI need | Why it matters | What exists today | What's missing | Required action | Blocks |
|---|---|---|---|---|---|---|
| **G-J1** | A way to grant public-link consent on a `platform_jobs` row | `publish()` returns 422 `CONSENT_REQUIRED` without it, and the `CONSENT_GRANTED` checklist item is part of `ready` | `CreateJobRequest.consentGranted` (accepted, never sent by the client); `PlatformJobStore.setConsent` (no caller); legacy `POST /technician/legacy/jobs/{id}/consent` writes `consent_records` | A clean-family endpoint (or wizard field) that writes `platform_jobs.consent_granted` | **Server work, owner decision.** Until then: do not design a "Publish now" success path; the J2 flow proof "publish → link live" cannot pass | **J2, J3, halt-worthy** |
| **G-J2** | A correct publication chip | A published job renders "Not published" | DB vocabulary UNPUBLISHED/PUBLISHED/REVOKED; client tests `ACTIVE` | Correct mapping (`PUBLISHED` → published, `UNPUBLISHED` → not published, `REVOKED` → revoked) | **Client relabel/fix** (no server change) | Detail, J1 |
| **G-J3** | Real evidence counts and issue values on findings | The detail currently always shows "Photos: 0 / Videos: 0" and never shows issue values, while the server holds the data | Server: `evidencePhotos:int`, `evidenceVideos:int`, `issueValuesJson:string` (see `clean-job-review.json`) | Correct DTO fields/parsing (`int`, JSON-decode) plus labels for the keys | **Client mapper fix** (add `int` fields; decode JSON; label keys or hide) | Detail, J1 |
| **G-J4** | Technician names in assignment history | The UI shows "—" for a person the server can name | `AssignmentDto.technicianName` (present) | Client parsing of `technicianName`; keep the staff lookup only as fallback | **Client mapper fix** | Detail, J3 flow proof "assign → detail shows technician name" |
| **G-J5** | An honest "documents" state on the checklist | "Documents ready" + a passing `DOCUMENTS_QUEUED` claim documents exist; none do before publish | Constant `true` at `WorkshopJobAdminService:410` and `:862-864` | Either real document readiness or a message that says "generated after publish" | **Relabel (client copy)** + server suggestion to stop sending a constant | Publish checklist, J2 |
| **G-J6** | Download a document | The button is labelled "Download" but copies a relative API path | `downloadUrl` = `/api/v1/.../content`; server endpoint exists | An `ApiEndpoints` + `AdminApi` method that fetches bytes (or an absolute URL) | **Client work** (no server change) | Documents, J2 |
| **G-J7** | Job-level signature fact | `JobDto.signaturePresent` is the only job-level proof | Server field exists | Client mapper field (`CleanJob.signaturePresent`) | **Client mapper fix** | Detail/checklist parity |
| **G-J8** | A working "Report" action for a published clean job | The button calls a legacy endpoint that looks the job up in `inspection_jobs` → 404 | Clean report artifacts exist as `platform_report_versions` + documents | A clean report read model, or remove the action | **Server work or remove** (reports module is out of scope — file a change request) | Detail, J3 |
| **G-J9** | Unknown enum handling on every surface | Raw codes (`NO_ISSUE_OBSERVED`, `READY`, `JOB_PUBLISHED`, `PENDING`) reach the screen | `labels.dart:43` and several switches default to the raw value | Explicit "Unknown" label + one-time log, per contract | **Client work with a test** | All surfaces |
| **G-J10** | Specific mutation errors | 409/422 collapse to "Action failed"; the user cannot tell a stale version from a guard | `AppFailure.code` is available; `ProblemDetails` drops `issues` | Per-code copy map; `issues` parsing for validation | **Client work** (mapping) + small `api_client` extension | Detail, wizard, approve, checklist, link |
| **G-J11** | A scheduled job created from the UI | `SCHEDULED` is unreachable: the wizard has no time input | Legacy sheet can schedule, but into the wrong table | A `scheduledAt` input on the clean create path | **Client work** (or drop the SCHEDULED claim from the design) | Wizard, J2 |
| **G-J12** | Client validation that matches the server | VIN/year/plate/odometer are optional in the UI and required server-side | Server rules at `WorkshopJobAdminService:775-808` | Required-field rules in the wizard | **Client work** | Wizard, J2 |
| **G-J13** | One search contract | A customer-name search finds a queue row and not a board row | Clean search: reference/make/model/VIN/plate | Either add customer fields server-side or state the fields on screen | **Server suggestion or copy** | Queue/board convergence |
| **G-J14** | Remove `FINALIZED` from clean-family logic | Dead branch, dead chip, dead label | Legacy-only status | Deleting the legacy queue family | **Client deletion in J1** | J1 |
| **G-J15** | An unread count for the bell | A bell without a count is a promise the shell does not keep | `notifications()` list only | A count endpoint, or derive from the list once (with its own cost) | **Server suggestion; meanwhile show no badge** | Notifications, J3 |
| **G-J16** | Distinguish "not approved yet" from "no documents" | Both render the same empty state | `documents()` returns `[]` for both | Copy driven by `job.status` / presence of a report version | **Client copy** | Documents |
| **G-J17** | Optimistic concurrency on the legacy assign/cancel | Two legacy writes have no `version`; the clean publish family takes none from the wire | Clean update/assign/cancel/approve/reject do check `version` when sent | Always send `version` on the clean path (the legacy path dies) | **Client discipline + contract** | J1/J3 |
| **G-J18** | One time semantic | Server-generated timestamps display 4 h early under the current client rule | Naive `DATETIME(6)` + `LocalDateTime.now(UTC)` (X6) | Offsets on the wire, or per-field knowledge of which values are user-picked | **Server fix preferred**; interim: label the two classes and do not show server times where precision matters | All surfaces |
| **G-J19** | Queue chip scope qualifier | J5/D2 is unexplainable to a user | — | "In this view" label or a matching server count | **Client relabel** (J1 replaces the surface) | Queue |
| **G-J20** | Board chips that describe the page | Chip counts ignore search/status | — | Qualifier ("all jobs") or a counts endpoint that accepts the search | **Client copy or server param** | Board |
| **G-J21** | Actions enabled only when the server allows them | Assign/cancel/publish are offered on states where they always fail | Server guard sets: `EDITABLE_STATUSES`, `ASSIGNABLE_STATUSES`, publish preconditions | One shared client-side state policy mirroring the server guards | **Client work** | Detail, approve, checklist, link, assign |
| **G-J22** | Correct labels on assignment rows | `assignedBy` is labelled "Assign technician"; `assignedAt` is labelled "Scheduled at" | ARB keys exist for both facts | Two label changes | **Client relabel** | Detail |
| **G-J23** | Honest document size | `bytes: null` renders "0 B" | `_int` fallback 0 | Nullable-aware formatting ("—") | **Client fix** | Documents |
| **G-J24** | Readable notifications | The payload JSON is the body | `payloadJson` string | Parse known `type` → localized sentence + job link; unknown → generic | **Client work** | Notifications |
| **G-J25** | Distinguish "download disabled" from "not available" | Two states rendered identically | `pdfDownloadEnabled` bool | Copy: "Download off" vs the field not applying | **Client relabel** | Public link |
| **G-J26** | A real share action or an honest label | "Share" copies to the clipboard | — | Rename to "Copy", or integrate a share sheet | **Client relabel** | Public link |
| **G-J27** | A customer/vehicle look-up when creating a job | The wizard expects the admin to retype a name, phone, VIN and plate that the workshop already knows | `staff()` exists; no customer or vehicle directory endpoint in scope | A searchable customer/vehicle read model | **None now — explicitly out of scope.** Do not fake a type-ahead; the wizard stays manual | Wizard (copy only) |

---

## 6. Contract rules for the rebuild

### 6.1 Wire rules that every jobs screen must honour

1. **Unknown enum ⇒ explicit "Unknown", never the raw code**, plus a single log
   per value. Applies to `status`, `reviewStatus`, `publicationStatus`,
   `PublicLink.status`, `JobDocument.status`, `notification.type`,
   `findings[].resultCode`, `items[].code`. Server side, an unknown *filter*
   value is already rejected with 400 `INVALID_FILTER` / `DATE_INVALID`
   (`WorkshopJobAdminService:1090-1124`).
2. **Never default a count to zero.** `_int`/`_asInt` currently return 0 for a
   missing key; a renamed field would silently show "0 jobs". Required: a
   missing required top-level count is a parse failure surfaced as an error
   state, not a zero. (`workshop_job_models.dart:449-460`, `job_counts.dart:39-48`.)
3. **Dates.** Two classes exist on the wire (X6):
   - user-picked naive values (`scheduledAt` from the legacy sheet) are Dubai
     wall time;
   - server-generated values are UTC wall time serialized without an offset.
   Until the server emits offsets, `WorkshopClock` must gain an explicit
   "server instant" path (add 0, then convert) rather than reusing the
     "naive = Dubai" path. Never call `DateTime.parse` without a policy.
   Note also that `POST/PUT /jobs` accepts an offset but calls
   `toLocalDateTime()` on it (`WorkshopJobAdminService:1126-1140`) — the offset
   is **dropped without conversion**, so `10:00+04:00` stores 10:00. Until that
   is fixed, send naive Dubai wall time and never rely on offset conversion.
4. **Pagination.** Always render `JobPage.total` / `totalPages`; never
   `items.length` as a total. Server clamps `size` to 1–100 (`:158-159`) and
   defaults to 20; the client sends 10 on the board.
5. **Ordering.** The only order the server offers is `created_at DESC, id DESC`
   (`PlatformJobStore:149`). Any "next appointment" claim is fabricated — do not
   design one (carried decision J21).
6. **Window filters.** `from`/`to` filter **`created_at`**, not `scheduled_at`
   or completion (`PlatformJobStore:141-148`). Counts accept no window at all.
   Do not label any number "today".
7. **`version` is the concurrency token and it is optional on the wire.** The
   server only compares it when non-null (`checkVersion`, `:1076-1080`), so a
   client that omits it silently disables the guard. Every mutation from the
   rebuild must send `job.version`. Publish/unpublish/revoke/rotate take no
   `version` parameter — treat them as state-guarded, not version-guarded.
8. **Idempotency.** `POST /jobs`, `/approve`, `/publish` accept
   `Idempotency-Key` and replay the stored body (`:1179-1192`). The client sends
   `Uuid().v7()`. Assign/cancel/reject/retry do not; they are guarded by status
   and version instead. Do not retry a create without a key.
9. **Error mapping.** Map by `code`, not by message text:

   | Status | Codes seen in this module | UI obligation |
   |---|---|---|
   | 400 | `INVALID_FILTER`, `DATE_INVALID` | developer error; log, show generic load failure |
   | 401 | auth | session flow |
   | 403 | `FORBIDDEN` | permission state, not "not found" |
   | 404 | `JOB_NOT_FOUND`, `TEMPLATE_NOT_FOUND`, `DOCUMENT_NOT_FOUND`, `DOCUMENT_TYPE_NOT_FOUND`, `NOTIFICATION_NOT_FOUND`, `REPORT_VERSION_MISSING` | specific "gone" copy + back action |
   | 409 | `VERSION_CONFLICT`, `JOB_NOT_EDITABLE`, `JOB_NOT_ASSIGNABLE`, `JOB_ALREADY_ASSIGNED`, `APPROVER_IS_TECHNICIAN`, `JOB_NOT_PENDING_REVIEW`, `JOB_NOT_CANCELLABLE`, `JOB_ALREADY_CANCELLED`, `JOB_NOT_APPROVED`, `JOB_ALREADY_PUBLISHED`, `JOB_NOT_PUBLISHED`, `LINK_NOT_ACTIVE`, `DOCUMENT_NOT_READY` | distinct copy each; refresh the job afterwards |
   | 422 | `JOB_VALIDATION_FAILED`, `TEMPLATE_NOT_PUBLISHED`, `TECHNICIAN_NOT_FOUND`, `SCHEDULE_INVALID`, `CONSENT_REQUIRED`, `APPROVAL_CHECKLIST_INCOMPLETE`, `ASSIGNMENT_INVALID`, `CANCEL_REASON_REQUIRED`, `REJECT_REASON_REQUIRED` | field-level where `issues` exist; otherwise a specific sentence |
   | 5xx | — | bounded error + retry, never partial numbers |

   `ProblemDetails` currently drops the `issues` array; a field-level form
   cannot be built without extending it (G-J10).
10. **Tenant / permission evidence.** The whole admin controller is
    `@PreAuthorize("hasRole('WORKSHOP_ADMIN')")`; every service entry calls
    `requireWorkshop(caller)` and every store query is `WHERE workshop_id = ?`
    (list, count, find, documents via report version, notifications via
    `workshop_id + user_id`). A job id supplied by the client is always re-checked
    against the caller's workshop, so there is no cross-tenant read path in this
    module. Document content additionally verifies the document belongs to the
    job's **latest** report version.
11. **Caching.** No cache headers on lists/counts; QR and document content are
    `no-store`. Client providers are `autoDispose` and invalidated after every
    mutation — keep that discipline, and add the invalidations the current code
    misses (`cleanJobsProvider` after a detail mutation, `jobReviewProvider`
    after approve/reject is already there).

### 6.2 Model rules

- DTOs mirror the wire exactly, including nullability: `bytes`, `score`,
  `vehicleYear`, `odometerValue`, `generatedAt`, `revokedAt`, `readAt`,
  `technicianName`, `assignedBy`, `reason`.
- `CleanJob` must gain `signaturePresent` (G-J7), `JobAssignment` must gain
  `technicianName` (G-J4), `ReviewFinding` must use `int evidencePhotos`,
  `int evidenceVideos`, `issueValuesJson` (G-J3).
- No business rules in DTOs; unknown enums map to a sentinel, never to a label.
- Money does not appear in this module.

---

## 7. Gate 1 self-grade

Counted from the tables in §3. Every row is one rendered element or one
rendered claim.

**Elements inventoried: 195**

| Status | Count |
|---|---|
| VERIFIED | 119 |
| ASSUMED | 7 |
| SUSPECT | 62 |
| MISSING | 7 |

- **Every SUSPECT has a named root cause** (T4/T5/D2/D3, X1–X16, or
  G-J1–G-J27) and an exact file:line reference. Zero unexplained.
- **Every MISSING is listed as a gap** with a required action (§5).
- **No metric is estimated or filled.** Where a shape is unproven it is
  ASSUMED and the reason is stated.
- The SUSPECT count is high because every legacy reference that must die in J1–J3
  is counted where it renders (e.g. `FINALIZED` appears as a dead branch on three
  surfaces). It is a work list, not a verdict that the screen is untrustworthy.
- **Verdict: PARTIAL — consistent for the read paths of the clean family;
  not certifiable for the write path or for any surface pair that mixes
  families.**

### BLOCKED metrics (two-phase truth rule)

| Blocked item | Phase that must clear it | Why it cannot ship |
|---|---|---|
| "Published" public-link state after a successful publish (checklist → link live) | **J2 write path**, pending G-J1 server decision | `consent_granted` can never become true for an app-created job, so `publish` always returns 422; the J2 flow proof cannot pass |
| "Documents ready" on the checklist | J2, G-J5 | constant `true`; no documents exist before publish |
| Any evidence count / issue value on a finding | J1, G-J3 | client mapper reads the wrong types; the screen always shows zero/empty |
| "Report" for a published job | J3 / change request, G-J8 | the action calls the legacy report family and 404s for a `platform_jobs` id |
| Queue "In progress" vs dashboard "In progress" as one number | J1, G-J19/D2 | two tables, two scopes; must be qualified or unified |
| Any server-generated timestamp shown to the minute | G-J18 | the wire carries a UTC wall time with no offset; the client rule shifts it by 4 h |
| Unread notification count | J3, G-J15 | no count endpoint; a derived count would be a page-length claim, not a total |
| "Scheduled" jobs created from the UI | J2, G-J11 | the clean wizard has no scheduled-time input |

### Halt-worthy contradiction

**G-J1 + X12:** the only create flow in this app writes `consent_granted = false`,
and no endpoint can change it, while `publish` refuses without it. The jobs module
can therefore **never reach PUBLISHED from the UI**. J2's stated proof
("publish → link live") is impossible without a server decision. This should be
resolved before Brief 3A is written, not discovered at Gate 6.

---

## 8. Field dispositions for the rebuild

### 8.1 The new UI may show (VERIFIED, with the stated definition)

- Counts: `draft, scheduled, assigned, inProgress, pendingReview, approved,
  published, rejected, cancelled, total` from `GET /jobs/counts` — workshop-wide,
  no window, mutually exclusive statuses, `total` is the sum of every status
  present. Never present these as a partition of `total` without an explicit
  remainder (server may hold a status outside the nine; today it cannot, per the
  DB check constraint).
- Rows: `reference`, `status`, `vehicleMake`, `vehicleModel`, `vehicleYear`,
  `vehiclePlate`, `vehicleVin`, `customerName`, `customerPhone`,
  `assignedTechnicianName`, `scheduledAt` (user-picked), `createdAt`,
  `templateNameEn/Ar`, `templateVersionNo`, `score`, `gradeCode`,
  `reviewStatus`, `publicationStatus` (with G-J2 fixed).
- Detail facts: `customerEmail`, `odometerValue/Unit`, `transmission`,
  `fuelType`, `preferredLanguage`, `cancelReason`, `safetyCapApplied/Reason`.
- Review: `itemsAssessed`, `itemsTotal`, `scorePreview`, `gradePreview`,
  `safetyCapPreview`, `findings[].labelEn/Ar`, `stableCode`,
  `signaturePresent`, `resultCode` (only with a label map).
- Checklist: `ready`, `items[]` (code/passed/messages), `consentGranted`,
  `signaturePresent`, `safetyCap*`.
- Documents: `nameEn/Ar`, `language`, `status`, `generatedAt`, `error`,
  `downloadUrl` (with G-J6 fixed).
- Link: `status`, `publicUrl`, `pdfDownloadEnabled`, `activatedAt`, `revokedAt`,
  `revocationReason`, and the QR bytes when the link is ACTIVE.
- Notifications: `type` (mapped), `createdAt`, `readAt`, `payloadJson` (parsed).

### 8.2 The new UI may **not** show

- Any number derived client-side from a page (`items.length`) and presented as a
  total.
- "Active jobs" (`assigned + inProgress`) — not on the clean wire and overlaps
  two buckets.
- "Finalized today", "Today", "This week" — no windowed counts exist.
- "Next appointment" / schedule ordering — no such ordering exists.
- Technician workload, capacity, utilisation — no aggregate exists.
- Revenue, invoices, turnaround/duration — not modelled.
- Skills/certifications/bays for a technician — not modelled (and correctly
  absent from the assign dialog today).
- A "Documents ready" claim, a "PDF available" claim when the flag is off, or a
  "Download" that copies a path.
- Raw enum codes, raw ISO strings, raw JSON payloads.
- Any metric labelled with a definition it does not have (e.g. "In progress"
  unless the predicate is stated).

### 8.3 Must be relabelled (source is real, the words are wrong)

| Current label / behaviour | Correct treatment | Gap |
|---|---|---|
| Publication chip tests `ACTIVE` on the **job** field | map `UNPUBLISHED / PUBLISHED / REVOKED` | G-J2 |
| Checklist "Documents ready" / "Documents will be generated after publish" | say "Generated after publish" and stop marking it ready | G-J5 |
| Assignment "Assign technician" over `assignedBy` | "Assigned by" | G-J22 |
| Assignment "Scheduled at" over `assignedAt` | "Assigned at" | G-J22 |
| Public link "PDF download" / "Not available" | "Download on" / "Download off" | G-J25 |
| Public link "Share" | "Copy link" (or implement a share sheet) | G-J26 |
| Queue chip "In progress"/"Ready" | "In this view: In progress" or a server count with the same predicate | G-J19 |
| Board chips | "All jobs (workshop)" or counts scoped to the search | G-J20 |
| Queue chip "Finalized" | remove with the legacy queue | G-J14 |
| Notification type code as the headline | localized sentence per type | G-J24 |
| Documents "Download" | real download, or "Copy API path" | G-J6 |
| Document size `0 B` for null | "—" | G-J23 |
