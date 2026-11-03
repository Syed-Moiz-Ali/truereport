# ADR 0017 — Online Inspection Execution and Immutable Finalization

**Status:** Accepted for Phase 5A  
**Date:** 3 November 2026  
**Related:** ADR-0009, ADR-0014, ADR-0016, `docs/phase-1/07-database-design.md`, `docs/phase-1/08-api-design.md`, `docs/phase-1/09-offline-and-upload-design.md`

---

## Context

Phase 5A must let a technician execute an assigned or own walk-in inspection online, validate answers against the pinned template item rules, and finalize an immutable snapshot. Offline mode, photo capture and evidence upload are Phase 5B. The database/API design must remain additive so 5B can add evidence without replacing 5A records.

## Decision

1. Starting an inspection pins the template version and creates `inspection_item_snapshots` containing item content and effective rules.
2. Assessments store the result, optional severity, exact note, note language, reason, client revision, server revision and a `@Version` base version.
3. Result/severity/reason/note/applicability are validated on every assessment write; stale writes return `409 VERSION_CONFLICT`.
4. Technician writes re-check assignment and job status; reassignment returns `409 JOB_REASSIGNED`, cancellation `409 JOB_CANCELLED`.
5. Finalization requires `READY_TO_FINALIZE`, an `Idempotency-Key`, and a pessimistic job row lock. The same key replay returns the same finalized response; a different key on a finalized job returns `409 ALREADY_FINALIZED`.
6. Finalization writes findings, an `inspection_final_snapshots` row with canonical JSON and SHA-256, then sets `FINALIZED`, in one transaction.
7. No report, PDF, public link, delivery, correction or manager review is created in 5A.
8. Evidence tables (`evidence_assets`, `evidence_derivatives`) are reserved in V7; 5A does not write them and no evidence is claimed.
9. **Temporary evidence rule:** evidence-required items produce a non-blocking `EVIDENCE_PENDING_5B` warning. Phase 5B must convert required evidence to a blocking finalization gate.
10. MySQL V8 triggers protect finalized jobs, assessments, findings, snapshots, consent and evidence; they are written but untested locally without Docker.

## Consequences

- 5A can be used online without pretending photo evidence exists.
- 5B can add local persistence, photo capture/upload and evidence validation without changing 5A API contracts or tables.
- The temporary warning is visible to both the UI and finalization response.
- Finalized data is protected by service guards, immutability snapshots and (when verified) MySQL triggers.

## What was not proven

- MySQL 8.4 migration and trigger execution.
- Direct SQL immutability as the app DB user.
- Offline and evidence flows.
- Real-device keyboard, RTL and accessibility behaviour.
