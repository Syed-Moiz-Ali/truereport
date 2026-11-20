# Flow — Technician inspection (jobs → checklist → assessment → evidence → signature → complete)

Scope: `technician_app` + `technician` backend module (clean API) + `inspections` legacy API.

## Happy path

1. Technician signs in; router sends to `/jobs` (`technician_router.dart:49`).
2. Queue loads `GET /api/v1/technician/jobs?page&size&status`
   (`technician_api.dart:484`) → `technician/api/TechnicianInspectionController.java:63`.
3. Server scopes to the caller's workshop and assigned technician
   (`TechnicianInspectionService.listJobs:139-155`). Assigned jobs created in the Workshop app appear here.
4. Open job → `/jobs/{id}` → `technician_workspace_page.dart` loads the pinned checklist
   (`technicianChecklistProvider`, `:29`) → `GET /api/v1/technician/jobs/{id}/checklist` (`:71`).
5. Server builds a canonical JSON snapshot of the template, hashes it, and inserts it into
   `platform_job_checklists` on first open; subsequent opens verify the hash and reject drift with
   `CHECKLIST_SNAPSHOT_MISMATCH` (`TechnicianInspectionService.checklist:161-193`).
6. Open an item → `/jobs/{id}/items/{itemCode}` → `technician_dynamic_item_page.dart`.
7. Save an assessment → `PUT /api/v1/technician/jobs/{id}/items/{itemCode}` with result code, measurements,
   issue values and note (`technician_dynamic_item_page.dart:550`, `TechnicianInspectionService.saveAssessment:195`).
   The server validates result-specific evidence rules and required issue fields (`:927-1139`).
8. Evidence (for items whose rules require it):
   - `POST .../items/{itemCode}/evidence/init` (`:504`),
   - `PUT .../evidence/{evidenceId}/content` (octet-stream, `:600`),
   - `POST .../evidence/{evidenceId}/complete` (`:627`).
   The client uses `EvidenceCaptureService` + `evidence_capture_sheet.dart` (`:752-798`).
9. Summary → `GET /api/v1/technician/jobs/{id}/summary` (`:298`) renders progress/score.
10. Review → `GET /api/v1/technician/jobs/{id}/review` (`:336`) lists blockers and findings.
11. Signature → `POST /api/v1/technician/jobs/{id}/signature` (`:370`) with signer name/device/base64; the server
    validates a non-empty image and stores a signature record (`technician_signature_page.dart:133`).
12. Complete → `POST /api/v1/technician/jobs/{id}/complete` (`:417`), idempotency-keyed
    (`technician_summary_page.dart:216`). Server requires every editable item assessed, evidence rules met, signature
    present; transitions to `PENDING_REVIEW` and writes history/outbox.
13. Workshop Admin now sees the job as PENDING_REVIEW and can approve/reject.

## Branches

- **Checklist snapshot too large on MySQL** → was `409 DATA_INTEGRITY_VIOLATION` because
  `platform_job_checklists.snapshot_json` was `TEXT` (65 KB) while the seeded 30-item snapshot is **313,287 bytes**.
  Fixed by `V123__widen_snapshot_columns.sql` (`MEDIUMTEXT`); verified by loading the 30-item checklist (BLOCKER-01).
- **Not editable** → job must be `ASSIGNED` or `IN_PROGRESS`; otherwise 409 `JOB_NOT_EDITABLE`.
- **Concurrent assessment** → server revision check returns 409 `SYNC_CONFLICT` with current revision;
  `TechnicianInspectionConcurrencyIT` covers it.
- **Offline** → assessments/evidence/consent can be queued locally (`offline/offline_store.dart`,
  `sync_service.dart`). Sync posts `POST /technician/jobs/{id}/sync` (`:258`); conflicts are surfaced at
  `/sync/conflicts/{id}`.
- **Camera denied** → evidence capture errors are mapped to `technicianEvidenceFailed`; evidence cannot be faked.
- **Consent** → the technician app's consent form posts to the **legacy** endpoint
  (`technician_api.dart:305` → `/technician/legacy/jobs/{id}/consent`), which writes `consent_records`; it does **not**
  set `platform_jobs.consent_granted`. The clean publish flow therefore stays blocked.
- **Empty state** → `empty_jobs_view.dart`.
- **Wrong technician** → job lookup is scoped; another technician gets 404.

## Legacy vs clean API

The clean API (`/api/v1/technician/jobs/**`) is the active surface used by the router. Legacy endpoints
(`/api/v1/technician/legacy/**`) still exist for old screens, report status, deliveries and consent. The technician
app contains both; this is **DRIFT** and a source of bugs (consent is the concrete one).

## Verification status

Server: `TechnicianInspectionIT`, `TechnicianInspectionConcurrencyIT`, `TechnicianPhase3IT`, `EvidenceIT`.
Client: 31 test files incl. inspection/review flows.
Browser: pending; full evidence capture needs fake-camera flags, so the E2E will verify open/save/reload and mark
complete-with-evidence as UNVERIFIED unless the fixture template has zero evidence rules.
