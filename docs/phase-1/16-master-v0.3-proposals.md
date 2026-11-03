# Proposed `master.md` v0.3 Changes

**Project:** TrueReport  
**Document:** 16-master-v0.3-proposals.md  
**Status:** Proposals only. **`master.md` was not edited.** Every change requires product-owner approval.

---

## 1. Why this file exists

Phase 0's `10-consistency-check.md` and Phase 1's spike/design work found contradictions, outdated facts and ambiguities in `master.md` v0.2. This file records proposed changes in one place so the master can be revised deliberately, without silently rewriting the source of truth.

**Do not treat any item here as approved.** The master remains authoritative until the product owner signs a new version.

---

## 2. Document control

| Proposal | Current | Proposed |
|---|---|---|
| Header status | “Phase 0 delivered and awaiting product-owner approval” | “Phase 1 delivered for approval; no production code written” (update per actual approval date). |
| Header rule | “No application code is to be written before the Phase 2 gate” | “No application code before Phase 1 is approved and Phase 2 starts. Spike code stays isolated in `spikes/` and is never reused as production code.” |
| Version | v0.2 | v0.3 after approval. |
| Decision log | D1–D13 | Add Phase 1 decisions/defaults, source links and approval status. |

---

## 3. Contradictions to resolve

| ID | Section | Issue | Proposed wording |
|---|---|---|---|
| C01 | Header | Status does not match the phase actually being executed. | Update the status line to the current phase and approval state. |
| C02 | Header / §20 Phase 2 | “No application code before the Phase 2 gate” conflicts with Phase 2 building the foundation; a gate follows the work. | “No application code before Phase 1 approval; Phase 2 builds the foundation and ends at the Phase 2 gate.” |
| C03 | §12, §13A.8 | Lists Flutter Web for the public report while D4 is OPEN and the same section allows SSR. | “Public report: Flutter Web **or** server-rendered HTML, pending Phase 1 spike/approval. The rest of the client remains Flutter.” |
| C04 | §2 | “customer-approved public report” — no customer approval workflow exists. | “customer-consented public report link.” |
| C05 | §1, §8, §13A.5.1 | “Finalized findings can never be edited by anyone” vs a correction/new version. | “Finalized findings are immutable. A correction, if approved, creates a new immutable report version; the earlier version is never modified. D9 governs who may request it.” |
| C06 | §2, §8 | “assigned to their workshop account” is ambiguous. | “A technician sees jobs assigned to them by default. An optional workshop queue requires an explicit workshop policy and approval.” |
| C07 | §2, §3 | Workshop Admin “manage staff” vs Platform Admin “create/disable/transfer”. | Add the account-authority table; default Platform Admin creates all accounts, Workshop Admin assigns work (RQ3 pending). |
| C08 | §2, §3 | Platform Admin report/PII access is undefined. | “Platform Admin may view read-only report snapshots for oversight; customer contact details are hidden by default and any access is limited and audited.” |
| C09 | §2, §11 | Only Workshop Admin has resend/revoke; no support path. | Keep Workshop Admin as primary; add an optional audited break-glass support process only if approved. |
| C10 | §11 | Link reactivation undefined. | “No reactivation in V1; a new link requires a new consent/authorization decision.” |
| C11 | §10, §18 | PDF download “if authorized” is undefined. | “PDF download from the public page is disabled by default. PDF delivery is to the recorded customer through an approved channel.” |
| C12 | §8, §9 | Consent timing is unclear. | “Finalization may succeed without public-link consent; the link stays inactive until the specific public-link consent is recorded.” |
| C13 | §7, §8 | Status model lacks report-generation states. | Add internal `QUEUED/GENERATING/READY/FAILED` for report generation, separate from inspection status. Never add manager/review states. |
| C14 | §15 | `assessments` and `findings` overlap. | “`assessments` = the answer/result per item; `findings` = defect details derived from an assessment. A finding exists only for attention/defect results.” |

---

## 4. Technical facts to update

| ID | Section | Current | Proposed |
|---|---|---|---|
| T01 | §13A.1.1, §13A.5, §13A.9 | “MySQL 8.x” | **MySQL 8.4 LTS** everywhere; 8.0 is EOL. |
| T02 | §13A.9 | MinIO as local/production candidate | MinIO **local development only**; production D6 shortlist AWS S3 UAE / OCI UAE. |
| T03 | §13A.4.3 | No Connector/J licence note | Add GPLv2/FOSS-exception note and legal review; consider MariaDB Connector/J. |
| T04 | §13A.3.7 | `drift` + `sqlite3_flutter_libs` | Use `drift` + `sqlite3` 3.x + `drift_flutter`; `sqlite3_flutter_libs` is EOL. |
| T05 | §13A.2, §13A.3.1 | `melos.yaml` layout | Melos 8 uses a root `pubspec.yaml` with `workspace:`; no `melos.yaml`. |
| T06 | §13A.3.13 | `golden_toolkit` alternative | Prefer `alchemist`; `golden_toolkit` is stale. |
| T07 | §13A.3.8 | `photo_view` | Prefer built-in `InteractiveViewer` unless a feature is required. |
| T08 | §13A.3.10 | `intl_phone_field` | Prefer maintained `phone_form_field`; pick one. |
| T09 | §13A.8 | OpenHTMLtoPDF as a candidate | Keep only as a rejected spike alternative; Arabic failed. Default Chromium. |
| T10 | §12, §13A.8 | Flutter Web public report | Make D4 a real comparison; Phase 1 spike recommends SSR. |
| T11 | §13A.3.9 | Fonts not licence-checked | Add a font-licence/coverage gate; no bundling before verification. |
| T12 | §13A.1 | Firebase push | Mark optional/deferred; not in core acceptance. |
| T13 | §13A.4.1 | “current LTS/stable” | Phase 2 pins Java 25/Spring Boot 4.1.2 (verify at lock); no RC builds. |
| T14 | §13A.4.3 | JobRunr licence | Record LGPL-3.0/commercial and OSS limits; do not rely on Pro features. |
| T15 | §13A.6 | API conventions | Add RFC 9457, idempotency table, cursor pagination, tenant resolution, public allowlist. |

---

## 5. Phase 1 outcomes to record

| Area | Proposed addition |
|---|---|
| Public report | Spike B recommends server-rendered HTML; real-device/WhatsApp/accessibility proof remains before Phase 6. |
| PDF | Spike A recommends headless Chromium; OpenHTMLtoPDF rejected for Arabic; Linux/Java 25/native review remain. |
| Object storage | MinIO local-only; production shortlist AWS S3 UAE / OCI UAE; D6 pending. |
| Database | MySQL 8.4 LTS schema with UUIDv7 `BINARY(16)`, snapshots, triggers, grants, hash monitoring. |
| API | `/api/v1`, RFC 9457, idempotency, 409 conflicts, permission matrix, public allowlist. |
| Offline | Local-first Drift model, sync states, conflict rules, server-receipt gate. |
| Localization | Three settings (app language, field direction, report language), LTR isolates for identifiers, Western digits for technical fields, OS keyboard limits. |
| Roles | Safe defaults for technician visibility, Workshop Admin intake, account creation, PII, resend/revoke, audit. |
| Consent | Separate versioned consents; finalization can succeed without public-link consent; link stays inactive. |
| Governance | No correction UI/API until D9; no manager/review/customer app/payments. |

---

## 6. Wording that could mislead

| Current | Problem | Proposed |
|---|---|---|
| “Customer-approved public report” | Implies line-by-line approval. | “Customer-consented public report link.” |
| “Finalized findings can never be edited by anyone” | Can read as forbidding a correction version. | “Finalized findings are immutable. A correction creates a new report version; the old version is never modified.” |
| “The system then creates the report” | Implies synchronous. | “The server locks the inspection, then asynchronously builds the report and PDF.” |
| “Technician finalizes their inspection” | Could imply a manager step. | “Technician self-finalizes; there is no manager approval.” |
| “Public report page is a web page, but not a customer portal” | Good rule; keep. | Add: “It is a read-only report view with no account, booking, payment or messaging features.” |
| “The customer receives the report URL and PDF” | Could imply both always. | “The customer receives the URL and, where the delivery policy allows, the PDF.” |
| “PDF download if authorized by the sharing policy” | Undefined. | “PDF download is disabled by default; enable only under an approved policy.” |
| “No manager role” | Some may treat Workshop Admin as manager. | “No manager/approver role; Workshop Admin is an operational administrator, not a report approver.” |
| “AI-generated diagnoses ... unless approved” | Invites scope creep. | “Not in V1. Any later AI feature requires a separate approved phase, data-protection review and accuracy evaluation.” |
| “Report version and publication date” | “Publication” undefined. | “Finalization time, report version, and first public-link activation time if different.” |

---

## 7. Proposed new sections

### 7.1 “Phase 1 decision outcomes”

Add a table:

| Decision | Phase 1 outcome | Status |
|---|---|---|
| D1 | MySQL 8.4 LTS | Pending |
| D2 | One admin app | Pending |
| D3 | Riverpod | Pending |
| D4 | Server-rendered HTML (spike) | Pending |
| D5 | Headless Chromium (spike) | Pending |
| D6 | AWS S3 UAE / OCI UAE shortlist | Pending |
| D7 | `reactive_forms` | Pending |
| D8 | Providers TBD | Pending |
| D9 | No correction UI/API | Accepted constraint |
| D10 | `zh-Hans` | Pending |
| D11 | Per-item photos, 1–2 MB target | Pending |
| D12 | TOTP | Pending |
| D13 | Phase 2 task 1 | Pending |

### 7.2 “Role and consent defaults”

Add the short defaults from `00-decisions.md`:
- technician sees assigned jobs only;
- Workshop Admin intake edits only before finalization;
- Platform Admin creates accounts;
- no Platform Admin PII by default;
- no Platform Admin resend/revoke by default;
- one workshop per technician;
- consent gate for link/messages;
- PDF download off by default.

### 7.3 “Public report boundary”

Add:
- explicit allowlist;
- never expose customer name/contact, full VIN, plate, registration, precise location, originals;
- neutral invalid/revoked page;
- noindex, no private preview metadata;
- no admin code;
- no correction/review actions;
- no PDF download by default.

### 7.4 “Immutability definition”

Add:
- finalized findings are immutable;
- no admin/API/SQL-normal-path edit;
- triggers, grants, hash, audit;
- a correction is a new version, not an edit;
- D9 controls corrections;
- a privileged DBA bypass is a monitored, separation-of-duties risk, not a feature.

### 7.5 “API and error conventions”

Add:
- `/api/v1`, RFC 9457, stable codes;
- `Idempotency-Key` on finalize/resend/other unsafe retries;
- `If-Match`/version, 409 on stale;
- cursor pagination;
- tenant resolution server-side;
- public routes outside `/api/v1`.

### 7.6 “Version lock and spike isolation”

Add:
- no version is approved until Phase 2 task 1;
- spike code lives in `spikes/` and is never imported into production;
- re-verify all versions and licences at Phase 2.

---

## 8. Items that should stay unchanged

- B2B partner-workshop model.
- Three authenticated roles only.
- Customer is a record, not a login.
- No manager role, review queue or resubmission.
- No customer app, portal, booking or account.
- No in-platform payments or card data.
- No admin editing of finalized findings.
- Technician self-finalization with `FINALIZED`.
- 100+ inspection points in a shared library.
- Platform Admin owns master content; Workshop Admin builds templates.
- Template versioning and immutable snapshots.
- English/Arabic at launch; RTL; future Russian/Chinese.
- Guide image vs evidence image distinction.
- Long random public token, stored hashed.
- No indexing; no private fields by default.
- Delivery status separate from inspection status.
- Offline save with server-receipt proof before finalize.
- Modular monolith, MySQL, Flyway, S3-compatible storage, background jobs.
- No payment-card columns anywhere.

---

## 9. Approval

This file is a proposal. To apply it:

1. Product owner reviews and approves each section.
2. A new `master.md` v0.3 is created with a changelog.
3. Phase 0/1 documents are cross-referenced to v0.3.
4. No item is applied silently.
5. `master.md` remains the source of truth until v0.3 is approved.
