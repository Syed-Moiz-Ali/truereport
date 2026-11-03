# Phase 5A Decision Record

**Project:** TrueReport  
**Date:** 3 November 2026  
**Status:** Phase 5A implementation decisions. Phase 1 approved product decisions remain authoritative. D6, D7, D8, D11 and C2 remain Pending.

---

## 1. Technician access and walk-ins

| ID | Decision | Status | Notes |
|---|---|---|---|
| P5A-W1 | A technician may create a walk-in job in their own workshop | Accepted for Phase 5A | `POST /api/v1/technician/jobs`; the job is immediately `ASSIGNED` to the creator. |
| P5A-W2 | Workshop Admin can see technician walk-ins in the own-workshop job list | Accepted for Phase 5A | Same workshop-scoped job list; audit records `walkIn=true`. |
| P5A-W3 | Technician endpoints are technician-only | Accepted for Phase 5A | `/api/v1/technician/**` is guarded by `ROLE_TECHNICIAN`; Workshop Admin and Platform Admin receive 403. |
| P5A-W4 | A technician sees only assigned jobs and jobs they created | Accepted for Phase 5A | Cross-workshop access is neutral 404. |

---

## 2. Inspection execution

| ID | Decision | Status | Notes |
|---|---|---|---|
| P5A-I1 | Starting an inspection pins the template version and master item versions | Accepted for Phase 5A | `inspection_item_snapshots` stores labels, instructions, rules, applicability, equipment and guide-image IDs at start. |
| P5A-I2 | A pinned inspection is unaffected by later master/template changes | Accepted for Phase 5A | Server tests cover master edit/retirement after start. |
| P5A-I3 | Status flow is `ASSIGNED -> IN_PROGRESS -> READY_TO_FINALIZE -> FINALIZED` | Accepted for Phase 5A | `CANCELLED` is terminal and blocks edits. |
| P5A-I4 | Assessment concurrency uses a base version | Accepted for Phase 5A | Stale assessment writes return `409 VERSION_CONFLICT`. |
| P5A-I5 | Reassignment/cancellation is checked on every write | Accepted for Phase 5A | The previous technician receives `409 JOB_REASSIGNED`/`JOB_CANCELLED`, never a silent overwrite. |
| P5A-I6 | Notes are stored exactly as entered with a language tag | Accepted for Phase 5A | Arabic, Russian and Chinese round-trip tests pass; no translation. |

---

## 3. Rules and the temporary evidence state

| ID | Decision | Status | Notes |
|---|---|---|---|
| P5A-R1 | Allowed result options come from the pinned snapshot | Accepted for Phase 5A | Unknown results fail `422 RESULT_INVALID`; a result not allowed by the item fails `RESULT_NOT_ALLOWED`. |
| P5A-R2 | Severity is required for defects/attention | Accepted for Phase 5A | `DEFECT_FOUND` and `ATTENTION_RECOMMENDED` require a valid severity. |
| P5A-R3 | Reason is required for `NOT_CHECKED` and `COULD_NOT_VERIFY` | Accepted for Phase 5A | Reason code or reason text must be present. |
| P5A-R4 | Note requirement is enforced | Accepted for Phase 5A | `REQUIRED` blocks save/review without a note. |
| P5A-R5 | Applicability is checked when the pinned snapshot specifies `vehicleTypes` | Accepted for Phase 5A | Non-applicable items allow only `NOT_APPLICABLE`/`NOT_CHECKED`. |
| P5A-R6 | **Temporary evidence rule** | Accepted for Phase 5A only | Evidence requirements and minimum photos are stored and shown, but produce only a non-blocking `EVIDENCE_PENDING_5B` warning. No evidence is claimed. Phase 5B must make required evidence blocking. |

---

## 4. Finalization and immutability

| ID | Decision | Status | Notes |
|---|---|---|---|
| P5A-F1 | Finalize requires `Idempotency-Key` | Accepted for Phase 5A | Same key replay returns the same finalized response. A different key on a finalized job returns `409 ALREADY_FINALIZED`. |
| P5A-F2 | Finalization uses a pessimistic job lock | Accepted for Phase 5A | A real two-request concurrency test passes. |
| P5A-F3 | Finalization is one transaction | Accepted for Phase 5A | Validation, findings, immutable snapshot and status commit together. Failure rolls back. |
| P5A-F4 | Final snapshot has a SHA-256 content hash | Accepted for Phase 5A | Stored in `inspection_final_snapshots`. |
| P5A-F5 | No report, PDF, public link or delivery | Accepted for Phase 5A | Phase 6/7 only. |
| P5A-F6 | Finalized data has no edit path | Accepted for Phase 5A | Service checks reject all mutations; MySQL triggers are written but untested locally. |
| P5A-F7 | C1 stands | Accepted for Phase 5A | Finalization succeeds without public-link consent; no link is created. |

---

## 5. Phase 5B reservation

The following are reserved and not exposed in 5A:

- Tables: `evidence_assets`, `evidence_derivatives` (V7), with upload status and hash fields.
- Future endpoints: evidence init/complete/read, offline sync, local job manifest.
- Finalization will add a blocking evidence validation once capture/upload exists.
- No photo is faked or represented as evidence in 5A.

---

## 6. Pending or unchanged

D6 production object storage, D7 forms package, D8 messaging providers, D11 photo limits and C2 legal consent/retention remain Pending. Customer/vehicle data is fake-only and unencrypted.
