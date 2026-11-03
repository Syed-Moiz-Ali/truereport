# Phase 3 Decision Record

**Project:** TrueReport  
**Date:** 3 November 2026  
**Status:** Phase 3 implementation decisions. Product decisions from Phase 1 remain authoritative.

---

## 1. Hierarchy and account decisions

| ID | Decision | Status | Notes |
|---|---|---|---|
| P3-H1 | Platform Admin sees the workshop tree with Workshop Admins, Technicians and pending invitations | Accepted for Phase 3 | Every account is scoped to one workshop; pending accounts are shown from invitations. |
| P3-H2 | Platform Admin creates or invites Workshop Admin/Technician accounts | Accepted for Phase 3 | Create requires a temporary password; invite creates a pending account and one-time invitation token. |
| P3-H3 | Disable/reactivate/transfer are audited and revoke sessions | Accepted for Phase 3 | Last active Workshop Admin and last Platform Admin cannot be disabled. |
| P3-H4 | Transfer updates the single primary membership | Accepted for Phase 3 | Historical audit records old and new workshop IDs; future jobs must be reassigned before transfer. |
| P3-H5 | Technician and Workshop Admin cannot use Platform Admin endpoints | Accepted for Phase 3 | Security config + tests. Workshop Admin continues to see only its own workshop through `/api/v1/workshop/*`. |
| P3-H6 | Invitation tokens are returned once to the Platform Admin because D8 email delivery is Pending | Accepted for Phase 3 | The response is `no-store`; the token is shown once and must be delivered by an approved manual channel. |

---

## 2. Master content decisions

| ID | Decision | Status | Notes |
|---|---|---|---|
| P3-M1 | Master categories and items are server-managed; Flutter contains no checklist wording | Accepted for Phase 3 | Content is loaded from the API. |
| P3-M2 | A published item version is immutable; editing creates a new draft version | Accepted for Phase 3 | ADR-0014. |
| P3-M3 | Retiring an item never deletes versions and never changes old versions | Accepted for Phase 3 | Item status becomes `RETIRED`; versions remain. |
| P3-M4 | Templates will reference master item versions, not “latest” items | Accepted for Phase 3 | Phase 4 must implement this; schema already has `master_item_version_id` in the Phase 1 design. |
| P3-M5 | Guide images are a separate type from evidence and cannot be shown as evidence | Accepted for Phase 3 | ADR-0015. |
| P3-M6 | Phase 3 uses `LocalObjectStorage` behind `ObjectStorage` for development/tests | Accepted for Phase 3 | D6 production storage remains Pending; MinIO remains local-only. |
| P3-M7 | Sample content is marked `sampleData=true` and is not final 100+ checklist wording | Accepted for Phase 3 | The UI displays a placeholder warning. Final wording requires an automotive specialist. |
| P3-M8 | EN/AR are required to publish; RU/ZH-Hans are optional translations | Accepted for Phase 3 | Publish validation rejects missing EN/AR label or instruction. |
| P3-M9 | Result/severity/reason/equipment rules are stored on the item version | Accepted for Phase 3 | Validation rejects unknown result codes, reason codes and equipment. |
| P3-M10 | Guide image uploads use the provider-neutral storage interface | Accepted for Phase 3 | Local filesystem only in Phase 3; S3 adapter later. |

---

## 3. Decisions still pending / unchanged

| Decision | Status | Impact |
|---|---|---|
| D6 production object storage | **Pending** | Production guide image/evidence storage cannot be finalized. MinIO local only. |
| D7 forms package | **Pending** | Phase 3 uses standard Flutter form widgets; no complex forms package selected. |
| D8 WhatsApp/SMS/email providers | **Pending** | Invitation delivery is manual in Phase 3. |
| D11 photo limits | **Pending** | Phase 3 stores guide images only; evidence photo limits remain Phase 5. |
| C2 legal consent wording/lawful basis/retention | **Pending (legal)** | No real customer data is stored in Phase 3. |

---

## 4. Deliberate non-decisions

- No workshop template model or builder. Phase 4.
- No technician inspection, answers, evidence capture or offline sync. Phase 5.
- No PDF/public report. Phase 6.
- No delivery provider. Phase 7.
- No correction UI/API. D9 fence remains.
- No manager/review queue.
- No customer app/portal/payment.
- No final 100+ checklist wording.
