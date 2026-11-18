# Data inventory — dashboard + jobs (Phase 1, investigate-only)

Every displayed datum, traced to a source. Status: **VERIFIED** (source and
definition proven), **ASSUMED** (plausible, unproven), **SUSPECT**
(contradiction or doubt), **MISSING** (no source).

Provenance note: there is **no reachable server** in this environment, so
"verified" means *verified against server source and client mapper code*, not
against a captured live response. Samples are DTO-derived
(`docs/data/samples/README.md` says so explicitly).

## The structural fact that governs everything below

| | Dashboard + jobs queue | Job board + job detail |
|---|---|---|
| Endpoint | `/api/v1/workshop/**legacy**/jobs` (+ `/counts`) | `/api/v1/workshop/jobs` (+ `/jobs/counts`) |
| Server class | `WorkshopJobService` | `WorkshopJobAdminService` |
| Table | `inspection_jobs` (`@Table(name = "inspection_jobs")`) | `platform_jobs` (`PlatformJobStore`) |
| Statuses | DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, READY_TO_FINALIZE, FINALIZED, CANCELLED | + PENDING_REVIEW, APPROVED, PUBLISHED, REJECTED |
| "New job" flow | `ScheduleJobSheet` → `createJob` (legacy) | `JobCreationWizardPage` → `createCleanJob` |
| Open a job | quick sheet | detail page |

**Two tables, two lifecycles, two create flows.** A job created from the
dashboard's primary action goes to `platform_jobs` and therefore never appears in
the dashboard's own counts, "Next up" or "Recent jobs" — those read
`inspection_jobs`.

## Dashboard

| # | Element | Displayed as | Source | Definition / window | Status |
|---|---|---|---|---|---|
| 1 | Greeting name | "Good afternoon, Layla" | `session.user.displayName` (`dashboard_tab.dart:40-48`) | first token of display name | **VERIFIED** (session) · copy is **SUSPECT** (concatenated, J12) |
| 2 | Subtitle date | "Today, Tuesday 18 November 2026" | device `DateTime.now()` + hardcoded English (`:51-54`) | device clock, device locale date | **MISSING** (no l10n key; not workshop time) |
| 3 | Active | number | `JobCounts.active` = `assigned + inProgress` (`job_counts.dart:37`) | derived client-side; endpoint exposes no `active` | **SUSPECT** — overlaps tile 5 |
| 4 | New & scheduled | number | `JobCounts.newScheduled` = `draft + scheduled` | all-time, workshop | **VERIFIED** (`WorkshopJobService.counts:117`) |
| 5 | In progress | number | `JobCounts.inProgress` | all-time, workshop | **VERIFIED** — but same label as queue chips with a different scope (SUSPECT, J5) |
| 6 | Ready to finalize | number | `JobCounts.readyToFinalize` | all-time, workshop | **VERIFIED** |
| 7 | Finalized today | number | `JobCounts.finalizedToday` | `finalizedAt` today in Asia/Dubai | **VERIFIED** (`:104-110`) |
| 8 | Pipeline bar segments | 4 coloured segments | tiles 4,5,6,7 | proportions of their sum | **SUSPECT** — not a partition: omits ASSIGNED, all-time FINALIZED and CANCELLED, and mixes an all-time bucket with a today-subset |
| 9 | Pipeline legend values | 4 numbers | same | same | **SUSPECT** — same reason; legend sum ≠ total |
| 10 | Next-up job | vehicle, plate, customer, status, time | first open job by `scheduledAt` (`:328-346`) | excludes FINALIZED/PUBLISHED/CANCELLED/REJECTED | **VERIFIED** source · time **SUSPECT** (+4 h, see T1) |
| 11 | Recent jobs | up to 4 rows | legacy list, `take(4)` | **includes** finished jobs; excludes only the next-up one | **VERIFIED** source · **SUSPECT** definition (no "recent = open" rule) |
| 12 | Refresh | pull-to-refresh | invalidates counts + list | — | **VERIFIED** |

## Jobs queue

| # | Element | Source | Definition | Status |
|---|---|---|---|---|
| 13 | Chips: All / In progress / Ready / Finalized | client-derived from a **search-scoped, status-unfiltered** list (`jobs_tab.dart:118-126`) | count of rows currently reachable by the search | **SUSPECT** — differs from the dashboard's identical label; no on-screen hint |
| 14 | Footer total | `items.length` of the filtered list | current filter | **VERIFIED** (honest, scoped) |
| 15 | Rows | `WorkshopJob` | legacy table | **VERIFIED** · times **SUSPECT** (T1) |
| 16 | Search | server-side `search` param | `matches(job, query)` in `WorkshopJobService:73-81` | **ASSUMED** — match fields not enumerated in the UI or tested |
| 17 | Empty / error / loading | states | — | **VERIFIED** |

## Job board

| # | Element | Source | Definition | Status |
|---|---|---|---|---|
| 18 | Chips: All / Pending review / Approved / Published | server `JobStatusCountsDto` (`WorkshopJobAdminController:86`) | **workshop-wide; ignores search** | **SUSPECT** — chips and rows disagree whenever a search is active (inverse of #13) |
| 19 | Pagination | `JobPageDto.page/totalPages` | server | **VERIFIED** |
| 20 | Rows | `CleanJob` | `platform_jobs` | **VERIFIED** · times **SUSPECT** (T1) |

## Job detail

| # | Element | Source | Status |
|---|---|---|---|
| 21 | Title (vehicle or customer), reference | `CleanJob` | **VERIFIED** |
| 22 | Status chips: status / review / publication | `CleanJob.status`, `reviewStatus`, `publicationStatus` | **VERIFIED** · `REVOKED` → "revoked" tone is **ASSUMED** (no test, J10) |
| 23 | Summary facts (customer, phone, vehicle, scheduled, technician) | `CleanJob` | **VERIFIED** · scheduled **SUSPECT** (T1) |
| 24 | Customer/vehicle facts (email, plate, VIN, odometer, transmission, fuel, language, cancel reason) | `CleanJob`; null → "Not available" | **VERIFIED** |
| 25 | Inspection facts (template + version, score, grade, safety cap) | `CleanJob.templateName*`, `score`, `gradeCode`, `safetyCap*` | **VERIFIED** (server-computed) |
| 26 | Finding rows (label, stable code, result badge, photo/video counts, signature, completed time, issue values) | `ReviewDto` via `jobReviewProvider` | **ASSUMED** — DTO shape not yet diffed against the client mapper |
| 27 | Review preview (items assessed/total, score/grade/safety preview) | same | **ASSUMED** |
| 28 | Assignment rows | `AssignmentDto` | **VERIFIED** shape · **SUSPECT** UX: the "assigned technician" column renders `technicianId` (a UUID), not a name (`job_detail_page.dart:730-734`) |
| 29 | Action bar primary | status switch (`:868-884`) | **VERIFIED** |
| 30 | Documents / public link / QR / report | own providers | out of scope this wave |

## Contradictions found

### T1 — Every user-picked time is displayed 4 hours late (SUSPECT → evidence says real)

- The schedule sheet submits a **naive Dubai wall time**: `yyyy-MM-ddTHH:mm:00`,
  no offset (`schedule_job_sheet.dart:208-215`).
- The server parses `LocalDateTime.parse(...)` and stores it unchanged
  (`WorkshopJobService:155-157`), then sends `LocalDateTime.toString()` — still
  naive (`:315`; clean path `WorkshopJobAdminService.str()` L1146-1148).
- The client, for any string **without** an offset, treats it as UTC and adds
  four hours (`job_widgets.dart:29-42`).

A job the user schedules for 10:00 renders as 14:00 on the dashboard, the queue
and the detail page. Server-generated instants (`startedAt`, `finalizedAt`) may be
correct if the server runs in UTC — so the stored column carries **mixed
semantics**, and one display rule cannot serve both. `dubaiWallTime` is
duplicated in `report_page.dart:27-52`, so the bug is in two places.

### T2 — "In progress" means two different things

Dashboard: whole-workshop `inProgress` from `/legacy/jobs/counts`.
Queue chips: count of the current **search** result. Same label, two scopes, no
qualifier. The queue chip counts are honest for their scope but the label is not
(J5).

### T3 — The pipeline bar is not a partition

`newScheduled + inProgress + readyToFinalize + finalizedToday` omits ASSIGNED,
all-time FINALIZED (only today's is included) and CANCELLED, while `total`
includes all of them. The bar's widths therefore do not describe the workshop's
jobs; they describe four unrelated buckets.

### T4 — The dashboard and its own primary action disagree

"New job" on the dashboard opens `JobCreationWizardPage` → `createCleanJob` →
`platform_jobs`. The dashboard's counts and "Recent jobs" read `inspection_jobs`.
Create a job there and the dashboard does not change.

### T5 — An internal UUID is shown as a technician name

`_AssignmentRow` renders `assignment.technicianId` under the label "Assigned
technician" (`job_detail_page.dart:730-734`). Users see `3f2a…-…` instead of a
person. The summary card next to it shows a proper name, so the screen contradicts
itself.
