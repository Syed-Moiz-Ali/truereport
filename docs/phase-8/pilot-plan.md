# Phase 8 Pilot Plan

**Project:** TrueReport  
**Status:** Preparation only. No pilot has started.

---

## 1. Scope

- **1?2 partner workshops** in the UAE, one branch each.
- **Fake data only** is approved for the first technical rehearsal.
- **Real customer data is NO-GO** until every gate in section 6 is closed.
- Channels: public report link, PDF download/admin fallback, and only the providers approved under D8.
- No customer app, portal, booking, payment, correction workflow or manager queue.

---

## 2. Duration and workload

| Item | Proposed |
|---|---|
| Technical rehearsal | 1 week, fake data |
| Controlled pilot | 2?4 weeks after gates close |
| Inspections | Start with 5?10 per workshop per week |
| Users | 1?2 Workshop Admins, 2?4 Technicians per workshop |
| Support window | Workshop business hours + agreed on-call escalation |

The duration and volume must be confirmed by the product owner.

---

## 3. Success metrics

| Metric | Target |
|---|---|
| Inspection completion without support | ? 90% |
| App crash-free sessions | ? 99% |
| Report generated within agreed worker target | ? 95% |
| Delivery accepted by provider | ? 95% |
| Public report opens from real device/browser | 100% of tested devices |
| Data/privacy incidents | 0 tolerated |
| Cross-workshop exposure | 0 tolerated |
| Support tickets per 10 inspections | Record baseline; target downward trend |
| Technicians reporting the checklist as usable | ? agreed threshold with automotive specialist |

No metric is a substitute for the hard gates.

---

## 4. Support process

- Workshop Admin is first-line support.
- Platform on-call handles account, report, storage and provider issues.
- Every incident gets a request ID and is classified: P1 data/security, P2 blocked inspection/report, P3 degraded, P4 question.
- Never ask a customer to send a full public token, VIN, phone or email in a support ticket.
- Manual fallback: admin PDF download and approved copy-link process.
- P1 stops the pilot until contained and reviewed.

---

## 5. Data handling in the pilot

- Fake data for rehearsal; no real customer PII.
- Real pilot data only after C2, PII/key custody, D6 and D8 approval.
- PII is encrypted at rest by the application; evidence/PDF files live on the organisation's self-hosted volume.
- Files at rest depend on host/volume encryption; backups, local device data and runtime access remain separate risks.
- Admin TOTP is currently off by owner decision; password-only access is an accepted residual risk for the pilot decision.
- Do not use production data in development.
- Public evidence must not contain readable plates/faces until the photo policy is approved.
- Retention periods remain pending legal input.

---

## 6. Go/no-go checklist

Every item is a hard gate unless marked otherwise.

| Gate | Status | Owner | Evidence required |
|---|---|---|---|
| D6 self-hosted filesystem storage configured on a persistent volume, outside web root, with quotas/free-space checks, disk encryption and off-site backup | **PARTIAL** | User/Eng/Ops | Adapter/guard/tests pass; host encryption/off-site destination pending |
| D8 WhatsApp/SMS/email providers contracted; templates, sender IDs and production email authentication approved | **OPEN** | User/Product/Ops | Contracts, template IDs, SPF/DKIM/DMARC |
| C2 lawyer-approved consent, privacy notice, retention and data-subject process | **OPEN** | Legal | Signed wording |
| Checklist validated by named automotive specialist | **OPEN** | Automotive specialist | Signed review |
| Native Arabic review of report, PDF, delivery messages and RTL | **OPEN** | Arabic reviewer | Signed review |
| Real-device test matrix passed | **OPEN** | QA | Completed `real-device-test-plan.md` |
| Backup restore tested for database + storage, encrypted, with off-site copy | **PARTIAL** | Ops | Fresh MySQL/storage restore PASS; sample evidence/PDF/report hashes PASS; off-site destination pending |
| PII encryption active and key custody approved | **PARTIAL** | Security/Ops | App encryption + MySQL test pass; secret manager/KMS pending |
| No fake providers or fake data in production | **OPEN** | Ops | Production guard + provider config review |
| Admin 2FA decision reviewed | **ACCEPTED RESIDUAL** | Owner/Security | Password-only accepted for now; revisit before real customers, especially Platform Admin |
| Independent penetration test completed | **OPEN** | Security | Report and remediation |
| Dependency vulnerability scan clean or exceptions approved | **OPEN** | Security | NVD key and completed scan |
| Monitoring/alerts/on-call live | **OPEN** | Ops | Paging test and dashboard |
| Incident tabletop completed | **OPEN** | Security/Ops | Notes and actions |
| Photo plate/face policy approved | **OPEN** | Product/Legal | Written policy |
| Data-processing/DPIA worksheet reviewed by counsel | **OPEN** | Legal | Counsel sign-off |

A single critical OPEN gate means **NO-GO for real customers**.

---

## 7. Rollback criteria

- Any cross-workshop or public PII exposure.
- Any finalized-data mutation through an API or SQL path.
- Encryption/key failure or restore integrity mismatch.
- Provider compromise or repeated uncontrolled sends.
- Workshop cannot complete/report inspections without an approved workaround.
- Legal/security direction to stop.

---

## 8. Pilot exit

At the end, review metrics, incidents, support load, data requests and user feedback. Decide: extend, remediate, or stop. No automatic production rollout.

---

## 9. Assessment

| Scenario | Decision | Reason |
|---|---|---|
| Pilot with **real customers** | **NO-GO** | D8, C2, device matrix, Arabic review, specialist validation, independent penetration test, dependency scan, off-site backup, host/volume encryption and password-only admin residual remain open |
| Technical rehearsal with **fake data only** | **CONDITIONAL GO** | No real PII/providers/evidence; keep fake adapters, allowlist, local/private environment and close support. This is not a production or real-customer approval |

Any change from fake data to real customer data requires a fresh go/no-go review against the hard gates.