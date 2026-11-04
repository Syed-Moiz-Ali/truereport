# Phase 5A — Technician Online Inspection and Finalization

**Status:** Delivered for review. Phase 5B (offline, photo capture/upload, evidence) is implemented and documented in `docs/phase-5b/`.

## Scope delivered

- Technician walk-in job creation in the technician's own workshop (RQ12).
- Assigned/own job list and job detail.
- Customer and vehicle confirmation, consent recording, scope and equipment display.
- Start inspection; pin the exact template version and item versions.
- 100+ item checklist with category grouping and progress.
- Per-item result, severity, note (Unicode preserved), note language, reason.
- Server validation against pinned result/severity/reason/note/applicability rules.
- Review, mark ready and finalize with `Idempotency-Key`.
- Pessimistic job lock plus idempotent replay; concurrent same-key finalization tested.
- Immutable final inspection snapshot with SHA-256 content hash.
- Finalized read-only technician view.
- Technician endpoints restricted to technicians; Workshop Admin and Platform Admin denied.
- Evidence requirements are reported as `EVIDENCE_PENDING_5B` warnings in 5A; no evidence is fabricated.

## Explicitly not in Phase 5A

- Offline queue/local Drift database.
- Camera, photo capture, upload, evidence storage or evidence validation.
- Report/PDF/public link/delivery.
- Correction UI/API, manager/review queue, customer portal or payments.

## Key decisions

- RQ12 is enabled: a technician may create a walk-in job in their own workshop; it is immediately assigned to them and visible to the Workshop Admin.
- C1 remains: finalization can succeed without public-link consent; no public link is created in 5A.
- Customer/vehicle data remains fake-only and is not encrypted yet.
- **Temporary 5A evidence rule:** items with `REQUIRED`/`REQUIRED_MIN_N` evidence or `minPhotos > 0` produce a non-blocking `EVIDENCE_PENDING_5B` warning. Finalization does not claim evidence exists. Phase 5B must make evidence a blocking gate and add the evidence APIs/tables already reserved in V7.

## Documents

- `00-decisions.md`
- `test-report.md`
- `risk-register-update.md`
- `db-grants.sql`
- `../phase-1/13-adrs/0017-online-inspection-finalization.md`
