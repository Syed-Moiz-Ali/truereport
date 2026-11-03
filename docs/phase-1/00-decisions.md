# Phase 1 Decision Record

**Project:** TrueReport — Partner-Workshop Vehicle Inspection and Public Report Platform  
**Document:** 00-decisions.md  
**Date:** 3 November 2026  
**Status:** Working record. Only items marked **Approved** are binding. Everything else is **Pending**.

**Phase 2 update (3 November 2026):** the product owner approved D1, D2, D3, D4, D5, D9, D10, D12, and the role/consent/PDF-download safe defaults recorded below. D6, D7, D8 and D11 remain Pending and must stay abstracted. D13 is being executed as the Phase 2 version-lock task. The approval is recorded here and reflected in `master.md` v0.3; see `docs/phase-2/master-v0.3-changes.md`.

---

## 1. How to read this record

- **Approved** means the product owner has already fixed the point in `master.md` (v0.2) or in an explicit written instruction. The source is named.
- **Pending** means no product-owner answer was available when this document was written. A safe default is proposed so Phase 1 design can continue. A default is **not** production authorisation.
- The request contained the placeholder `[paste my confirmed answers to D1-D13 and the role/consent/PDF-download questions here]` with no answers pasted. Therefore **no D1–D13 answer was received in this session**. This document does not invent approvals.
- Anything that changes scope, law, money, data residency or a safety rule needs a written decision before the dependent phase. Do not treat a default as an approved requirement.

---

## 2. Product and architecture decisions

| ID | Decision | Status | Source / proposed default | Needed by |
|---|---|---|---|---|
| P1 | Business model: B2B partner-workshop inspection platform for the UAE; India later | **Approved** | `master.md` §1 | — |
| P2 | Three authenticated roles only: Technician, Workshop Admin, Platform Admin | **Approved** | `master.md` §2 | — |
| P3 | Customer is a record, not a login; public viewer is unauthenticated | **Approved** | `master.md` §2 | — |
| P4 | No manager role, no second-person review, no approval queue, no resubmission | **Approved** | `master.md` §2, §8 | — |
| P5 | Technician self-finalizes; final status is `FINALIZED`, not “approved” | **Approved** | `master.md` §8 | — |
| P6 | Finalized findings, severities, notes and evidence are immutable for everyone | **Approved** | `master.md` §2, §8, §13A.5.1 | — |
| P7 | No correction UI or API until a correction policy is approved | **Approved** | User instruction; `master.md` §13A.5.1 (D9 open) | Phase 6 |
| P8 | No customer app, customer portal, booking site or customer account | **Approved** | `master.md` §1, §12 | — |
| P9 | No in-platform customer payments, card forms or card data | **Approved** | `master.md` §1, §11 | — |
| P10 | English and Arabic at launch; genuine RTL; Russian and Chinese data entry supported | **Approved** | `master.md` §1, §6 | — |
| P11 | Flutter for technician and admin apps | **Approved** | `master.md` §12, §13A.1 | — |
| P12 | `go_router` for navigation | **Approved** | `master.md` §13A.1 | — |
| P13 | `flutter_animate` for subtle animation | **Approved** | `master.md` §13A.1 | — |
| P14 | Java backend, modular monolith; Spring Boot version verified in Phase 2 | **Approved** | `master.md` §13, §13A.1 | — |
| P15 | Local development first; production hosting location decided later | **Approved** | `master.md` §1, §13A.9 | Phase 2/8 |
| P16 | Public report must be reachable from WhatsApp/SMS/email without login or app install | **Approved** | `master.md` §11 | — |
| P17 | Public report and PDF must never expose customer name, phone, email, precise location, full VIN or registration by default | **Approved** | `master.md` §9, §11, §21 | — |
| P18 | Report is not an official RTA/Tasjeel certificate, warranty or condition guarantee | **Approved** | `master.md` §7, §10 | — |

---

## 3. D1–D13

| ID | Decision | Status | Proposed safe default | Notes / dependency |
|---|---|---|---|---|
| D1 | Database product and version | **Approved** | **MySQL 8.4 LTS** (not 8.0, which is EOL) | Applied in `master.md` v0.3; Phase 2 migrations target 8.4. |
| D2 | One `admin_app` for both admin roles, or two apps | **Approved** | **One** Flutter `admin_app` with role-selected feature folders and server-enforced permissions | Applied in `master.md` v0.3; Platform Admin is web-first. |
| D3 | Riverpod vs Bloc | **Approved** | **Riverpod** | Applied in `master.md` v0.3; no mixed state libraries. |
| D4 | Public report: Flutter Web vs server-rendered HTML | **Approved** | **Server-rendered HTML** (Java MVC), minimal or no JavaScript | Spike B evidence; applied in `master.md` v0.3 and ADR-0004. |
| D5 | PDF engine | **Approved** | **Headless Chromium** (Playwright for Java) rendering a print HTML template | Spike A evidence; applied in `master.md` v0.3 and ADR-0005. |
| D6 | Production object storage | **Pending** | Managed S3-compatible storage in the UAE: **AWS S3 `me-central-1`** or **OCI Object Storage UAE** shortlist | MinIO stays local-development only. Use an S3-compatible interface; do not hardcode a provider. |
| D7 | Forms package | **Pending** | `reactive_forms` for complex forms; do not mix with `flutter_form_builder` | Keep form choices abstracted; decide before complex forms. |
| D8 | WhatsApp, SMS and email providers | **Pending** | Meta WhatsApp Cloud API (or approved BSP) + one UAE-capable SMS provider + one email provider | Keep provider adapters abstract; no provider is contracted. |
| D9 | Correction / new-version policy | **Approved** | **No correction UI or API** until a policy is approved. If approved later, a correction is a new immutable report version. | Applied in `master.md` v0.3; ADR-0007. |
| D10 | Chinese variant | **Approved** | **Simplified Chinese `zh-Hans`** | Applied in `master.md` v0.3; full translation is later. |
| D11 | Photo requirements per item and size limits | **Pending** | Per-item requirement, not every item; target 1–2 MB after compression; validate in pilot | Keep limits configurable; do not hardcode. |
| D12 | Admin 2FA method | **Approved** | **TOTP** for Workshop Admin and Platform Admin | Applied in `master.md` v0.3; implementation in Phase 2 auth. |
| D13 | Version lock of all packages | **Completed for Phase 2** | Phase 2 task 1; exact pins in `docs/phase-2/version-lock.md` | Re-verify at every phase; no floating ranges. |

---

## 4. Role questions

| ID | Question | Status | Safe default | Consequence if unanswered |
|---|---|---|---|---|
| RQ1 / Q1 / W1 | Can a technician see all workshop jobs or only assigned jobs? | **Approved** | **Only jobs assigned to that technician.** No unassigned queue in V1. | Simpler privacy boundary; Workshop Admin assigns work. |
| RQ2 / Q2 / W1 | Can a Workshop Admin edit customer/vehicle intake before finalization? | **Approved** | **Yes for intake fields before finalization; never checklist answers, findings, notes, severity or evidence.** | Server must audit intake edits. |
| RQ3 / Q3 | Who creates/invites technicians? | **Approved** | **Platform Admin creates all accounts.** Workshop Admin assigns and reassigns work. | If Workshop Admin should invite staff, add a separate audited permission. |
| RQ4 / Q14 | Can a Workshop Admin see their workshop’s audit history? | **Approved** | **No by default.** Platform Admin only. | Add a read-only subset later if support needs it. |
| RQ5 / Q20 / W6 | Can Platform Admin resend or revoke links? | **Approved** | **No by default.** | Support must use an approved, audited break-glass process if ever added. |
| RQ6 | Who may initiate a correction? | **Approved** | **Nobody in V1. No correction UI or API.** | D9 blocks Phase 6 correction work. |
| RQ7 / Q18 / W7 | Can a public viewer download the PDF? | **Approved** | **No. Link-only by default.** | No download button. PDF is delivered by an approved channel to the recorded recipient. |
| RQ8 / G03 | Can Platform Admin see customer PII? | **Approved** | **No contact details by default.** Operational metadata and read-only report view only; any PII access is limited and audited. | Privacy review still required. |
| RQ9 / A10 | Can a technician belong to more than one workshop? | **Approved** | **No in V1.** One primary workshop. | Membership model stays simple. |
| RQ10 / Q26 | What happens to offline data when a user is disabled or transferred? | **Approved** | **Tokens revoked; local data wiped on next sign-in or role/workshop change.** | Device-level wipe cannot be guaranteed while offline. |
| RQ11 / Q19 | Can a Workshop Admin resend to a different recipient? | **Approved** | **Only the recorded customer/recipient.** A different recipient needs a new consent record. | Prevents accidental disclosure. |
| RQ12 / Q23 | Who authorises a walk-in job? | **Approved** | Workshop Admin, or an authorised technician under a workshop policy. | Fraud/abuse control. |
| RQ13 / Q16 / W3 | Can a revoked link be reactivated? | **Approved** | **No reactivation in V1.** | Avoids silent re-publication. |
| RQ14 / Q25 | What if consent is withdrawn after the link is active? | **Approved** | **Revoke the link, record the reason, tell the customer copies may already exist.** | Legal review still required. |

---

## 5. Consent questions

Consent is recorded by workshop staff. There is no customer login. These must be **separate, versioned records**:

1. Consent to collect and process customer/vehicle data for the inspection.
2. Consent to send a report link/PDF by each channel (WhatsApp, SMS, email).
3. Consent to create a publicly accessible report link.
4. Consent to download the PDF from the public page, only if RQ7 is later approved.

| ID | Question | Status | Safe default |
|---|---|---|---|
| C1 / W2 / Q24 | Is consent a finalization precondition or only a link precondition? | **Approved** | **Finalization may succeed without public-link consent. The public link stays inactive until the specific public-link consent is recorded.** |
| C2 | What exact wording, lawful basis and retention apply? | **Pending (legal)** | Draft plain-language wording; **legal counsel must approve before real customer data**. Do not claim PDPL compliance. |
| C3 | How is consent evidenced? | **Approved** | Store consent version, wording hash, timestamp (UTC), actor, channel, and a flag/evidence reference. |
| C4 | Can consent be withdrawn? | **Approved** | Yes; revoke link and record. Existing copies/downloads cannot be recalled. |
| C5 | Is consent required before sending a WhatsApp/SMS/email? | **Approved** | **Yes, channel-specific opt-in.** No send without it. |

**Rule that does not wait for approval:** no active public link without recorded public-link consent. No message without channel consent. No customer contact details on the public page.

---

## 6. PDF-download questions

| ID | Question | Status | Safe default |
|---|---|---|---|
| PDF1 / RQ7 | Is PDF download enabled on the public page? | **Approved** | **Disabled.** No download control on the public page. |
| PDF2 | How is the PDF delivered? | **Approved** | Email attachment or secure link to the recorded customer, after channel consent; manual resend by an authorised Workshop Admin. |
| PDF3 | If enabled later, what protects the download? | **Approved** | Short-lived signed URL tied to the active report/link, rate-limited, audited, `no-store`, no original-resolution evidence. |
| PDF4 | Can a public viewer request a fresh PDF after revocation? | **Approved** | **No.** Revocation stops future server access; already-downloaded copies cannot be recalled. |
| PDF5 | Does the PDF include customer contact details? | **Approved** | **No.** The PDF uses the same public allowlist plus workshop/technician display details; no customer contact, full VIN or registration by default. |

---

## 7. Decisions that are fixed but must still be implemented as controls

These are approved product rules; Phase 1 designs them as controls, not options:

- Finalized findings cannot be edited by anyone. A correction, if ever approved, is a new report version; the old version is never modified.
- No manager, reviewer, approval queue or resubmission.
- No customer app, portal, login, booking or payment.
- The public page is read-only and has no admin code.
- The technician’s finalization is self-finalization.
- Workshop isolation is server-enforced on every request.
- Public report fields come from an explicit allowlist, never a live entity serializer.
- No payment-card columns anywhere.

---

## 8. What this record does not decide

- The final legal consent wording.
- The production hosting country or provider contract.
- The object-storage provider (D6).
- The WhatsApp/SMS/email providers (D8).
- Any future correction policy beyond the V1 “no correction UI/API” fence (D9).
- The final photo limits (D11).
- Version numbers beyond the Phase 2 lock; re-verify at each phase (D13).
- Any claim of regulatory compliance.

---

## 9. Approval block

| Item | Status | Approved by | Date |
|---|---|---|---|
| Product scope and fixed rules (P1–P18) | **Approved via `master.md`** | Product owner (per master) | v0.2 |
| D1, D2, D3, D4, D5, D9, D10, D12 | **Approved** | Product owner | 3 Nov 2026 |
| D6, D7, D8, D11 | **Pending** | — | — |
| D13 | **Completed for Phase 2** | Technical lead | 3 Nov 2026 |
| Role questions (RQ1–RQ14) | **Approved** | Product owner | 3 Nov 2026 |
| Consent questions C1, C3, C4, C5 | **Approved** | Product owner | 3 Nov 2026 |
| Consent wording/lawful basis (C2) | **Pending (legal)** | Counsel | — |
| PDF-download questions (PDF1–PDF5) | **Approved** | Product owner | 3 Nov 2026 |

**Phase 2 foundation and Phase 3 Platform Admin work have been delivered for review. Phase 4+ features have not started.**
