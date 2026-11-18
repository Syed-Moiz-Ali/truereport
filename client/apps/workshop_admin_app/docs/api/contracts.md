# API contracts — dashboard + jobs (Phase 1)

Derived from server source on 2026-11-18. **No live capture was possible** in this
environment; every field below is read from the Java DTOs/controllers and the
Dart mappers, not from a recorded response. Samples in `docs/data/samples/` are
shape-accurate but DTO-derived.

Two API families serve job data. They must not be confused.

---

## A. Legacy jobs — dashboard + queue

### GET `/api/v1/workshop/legacy/jobs/counts`
- **Auth**: `hasRole('WORKSHOP_ADMIN')`, tenant = caller's workshop.
- **Query**: none.
- **Response** `JobCountsDto` (all `long`):
  `draft, scheduled, newScheduled, assigned, inProgress, readyToFinalize, finalized, finalizedToday, cancelled, total`
- **Definitions** (`WorkshopJobService:85-119`): one pass over every job of the
  workshop; statuses are mutually exclusive; `newScheduled = draft + scheduled`;
  `finalizedToday` = `finalizedAt` on the current date **in Asia/Dubai**;
  `total` includes cancelled.
- **Partition**: `draft+scheduled+assigned+inProgress+readyToFinalize+finalized+cancelled == total`. ✔
- **Quirks**: there is **no `active` field**. The client derives
  `active = assigned + inProgress` (`job_counts.dart:37`), which overlaps the
  `inProgress` tile.

### GET `/api/v1/workshop/legacy/jobs`
- **Query**: `search` (string), `status` (one of the seven legacy statuses).
- **Filtering**: server-side, in memory, over `findByWorkshopIdOrderByCreatedAtDesc`
  (`WorkshopJobService:73-81`). No pagination — the whole list is returned.
- **Response**: `List<JobDto>`; fields include
  `id, reference, status, reviewStatus, publicationStatus, templateNameEn/Ar, templateVersionNo,
  assignedTechnicianId, assignedTechnicianName, customerName/Phone/Email,
  vehicleVin/Make/Model/Year/Plate, odometerValue/Unit, transmission, fuelType,
  preferredLanguage, scheduledAt, startedAt, readyAt, finalizedAt, score, gradeCode,
  safetyCapApplied/Reason, createdAt, updatedAt`.
- **Dates**: `LocalDateTime.toString()` — **no offset**, e.g. `2026-11-18T10:00`.
- **Enums**: `DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, READY_TO_FINALIZE, FINALIZED, CANCELLED`.

### POST `/legacy/jobs`, `/legacy/jobs/{id}/assign`, `/legacy/jobs/{id}/cancel`
- Create takes a published `templateVersionId` and a **naive local** `scheduledAt`.
- Assign/cancel are state-guarded server-side (`JOB_NOT_ASSIGNABLE`, etc.).

---

## B. Clean jobs — board + detail

### GET `/api/v1/workshop/jobs/counts`
- **Response** `JobStatusCountsDto`: `draft, scheduled, assigned, inProgress,
  pendingReview, approved, published, rejected, cancelled, total`.
- **Scope**: entire workshop; **no search parameter** (`WorkshopJobAdminController:86`).

### GET `/api/v1/workshop/jobs`
- **Query**: `page` (default 0), `size` (default 10 client / 20 API), `status`,
  `search`, `from`, `to`.
- **Response** `JobPageDto { items: JobDto[], page, size, total, totalPages }`.
- **Status enum** (single field, review and publication folded in):
  `DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, PENDING_REVIEW, APPROVED, PUBLISHED, REJECTED, CANCELLED`.
  `reviewStatus` and `publicationStatus` are separate sub-state strings
  (initialised `NOT_SUBMITTED` / `UNPUBLISHED`; `ACTIVE` / `REVOKED` for a live or
  revoked public link).
- **Table**: `platform_jobs`.

### GET `/workshop/jobs/{id}`, `/assign`, `/cancel`, `/assignments`, `/review`, `/publish-checklist`, `/approve`, `/reject`, `/publish`
- Mutations take `version` for optimistic concurrency; a stale version must
  surface as a conflict Failure, never a silent overwrite.
- `/review` returns findings with `labelEn/Ar, stableCode, resultCode,
  evidencePhotos[], evidenceVideos[], signaturePresent, completedAt, issueValues`,
  plus `itemsAssessed/itemsTotal/scorePreview/gradePreview/safetyCapPreview`.
- `/assignments` returns `technicianId, assignedBy, assignedAt, unassignedAt, reason`
  — **ids, not names**, which is why the detail screen currently prints a UUID.

---

## Enum → UI label mapping (both families)

| Server value | Tone (`workshopJobTone`) | Label source |
|---|---|---|
| DRAFT / SCHEDULED | neutral | `statusDraft` / `statusScheduled` |
| ASSIGNED / IN_PROGRESS | accent | `statusAssigned` / `statusInProgress` |
| READY_TO_FINALIZE / PENDING_REVIEW | warning | `statusReadyToFinalize` / `jobsStatusPendingReview` |
| APPROVED / PUBLISHED / FINALIZED | success | `jobsStatusApproved` / `jobsStatusPublished` / `statusFinalized` |
| CANCELLED / REJECTED | danger | `statusCancelled` / `jobsStatusRejected` |
| anything else | neutral | **silent** — no log, no label |

Unknown statuses fall through to neutral with the raw string as the label in
several places. Contract requirement: unknown ⇒ explicit "Unknown status" +
one-time log, never a raw enum on screen.

## Error mapping

Client maps `AppFailure.code` / HTTP status to localized copy. The job screens
mostly collapse every mutation failure to `commonActionFailed`
(`job_detail_page.dart:245-249, 283-287`), so `JOB_ALREADY_ASSIGNED`,
`JOB_NOT_ASSIGNABLE` and a stale-version conflict are indistinguishable to the
user. Contract requirement: 409 codes must map to specific copy.

## Known quirks / drift risks

1. **`legacy` in the path** — the dashboard's data source is explicitly marked
   legacy by its own URL.
2. **Two tables** — `inspection_jobs` vs `platform_jobs`; no dual-write exists.
3. **Naive datetimes everywhere** — no offsets on the wire; the client guesses.
4. **Counts ignore search on the board** and **are scoped to search in the queue**.
5. **No `active` on the wire** — derived client-side, overlapping `inProgress`.
