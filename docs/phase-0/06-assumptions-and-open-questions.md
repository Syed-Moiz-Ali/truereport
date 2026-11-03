# Assumptions and Open Questions

**Project:** TrueReport  
**Document:** 06-assumptions-and-open-questions.md  
**Status:** Phase 0 decision log. Items marked **BLOCKING** must be answered before the relevant phase starts.

---

## 1. How to use this document

- **Assumptions** are things we had to assume to produce a coherent Phase 0 plan. They are not approved facts.
- **Open questions** are decisions or facts we do not have. Each has an owner, a phase when it is needed, and a safe default so work is not frozen.
- **D1–D13** are the decisions already listed in `master.md` §13A.12. They are repeated here with the Phase 0 evidence.
- Additional IDs (Q, W, A) are new Phase 0 items.

**Rule:** do not implement a feature whose answer is marked **BLOCKING** by guessing. Use the default only for planning, not for production behaviour.

---

## 2. Assumptions

| ID | Assumption | Why we assumed it | Impact if wrong | Confirm by |
|---|---|---|---|---|
| A1 | The scope is exactly `master.md` v0.2, including all explicit exclusions. | The master document is the source of truth. | Scope creep or missing feature. | Phase 0 approval |
| A2 | “MySQL 8.x” means **MySQL 8.4 LTS**, not 8.0. | MySQL 8.0 reached EOL in April 2026. | Security/support risk; schema and hosting changes. | Phase 1 (D1) |
| A3 | One `admin_app` Flutter project serves both Workshop Admin and Platform Admin, with role-selected screens. | `master.md` recommends one app (D2). | Extra codebase and release overhead if two apps are required. | Phase 1 (D2) |
| A4 | Riverpod is the state-management choice. | `master.md` recommends Riverpod (D3). | Rewrite of state layer if Bloc is chosen. | Phase 1 (D3) |
| A5 | The public report may be Flutter Web or server-rendered HTML; no decision yet. | `master.md` keeps D4 open; Flutter’s own docs say static text content is not its ideal use case. | Public report performance/accessibility and repo layout. | Phase 1 spike (D4) |
| A6 | The PDF engine is not chosen; headless Chromium is the default candidate. | OpenHTMLtoPDF has limited RTL support and is old. | Arabic PDF quality and server cost. | Phase 1 spike (D5) |
| A7 | A technician sees only jobs assigned to them by default, with an optional workshop queue if policy allows. | Safer interpretation of “assigned to their workshop account”. | Job-list design and privacy. | Phase 1 (Q13) |
| A8 | A Workshop Admin can manage job/intake details before finalization but cannot edit checklist findings, notes or evidence. | “Manage inspections” is broad; findings must remain technician-owned. | Role matrix and API permissions. | Phase 1 (Q14) |
| A9 | Platform Admin can read finalized reports for oversight but cannot edit them. | `master.md` grants hierarchy/audit oversight and forbids editing findings. | Privacy exposure and support workflow. | Phase 1 (Q20) |
| A10 | A technician belongs to one primary workshop in V1. | `master.md` says so unless approved. | Membership model and queries. | Phase 2 |
| A11 | Video evidence is not in V1. | `master.md` marks it pending approval. | Storage, capture, report size. | Phase 5 |
| A12 | Public PDF download is not enabled until a sharing policy is approved. | `master.md` says “if authorized by the sharing policy” but does not define it. | Public report behaviour. | Phase 6 (Q18) |
| A13 | Target evidence photo size is roughly 1–2 MB after compression, to be validated. | `master.md` gives this as a starting target. | Upload time, storage, report size. | Phase 5 pilot (D11) |
| A14 | The 100+ item library is a minimum, not a claim of market-leading coverage; an automotive specialist must validate it. | Competitors claim 240–248 points; quality matters more than count. | Credibility and sales. | Phase 3/5 |
| A15 | Finalization can succeed without public-link consent, but the link stays inactive. | Consent is described as a link condition, not a finalization condition. | Workflow and UI. | Phase 1 (W2) |
| A16 | Production hosting location is not decided; UAE data-protection review is required before real data. | `master.md` says hosting is local now, production later. | Cross-border transfer, latency, cost. | Phase 2/8 |
| A17 | Launch interface languages are English and Arabic; Russian/Chinese are data-entry ready but not fully translated. | `master.md` says so. | Localisation scope. | Phase 1 |
| A18 | Future Chinese is Simplified (`zh-Hans`) unless corrected. | `master.md` suggests it but marks D10 open. | Translation and font choices. | Phase 1 (D10) |
| A19 | The platform never processes or stores customer payments or card data. | Explicit requirement. | Legal/security scope. | Always |
| A20 | The public report excludes customer name, email, phone, precise location, full VIN and registration by default. | Explicit requirement. | Report layout and data model. | Phase 1 |
| A21 | A correction is a new report version, not an edit; the policy is unresolved. | `master.md` says this but leaves D9 open. | Immutability design and UI. | Phase 6 (D9) |
| A22 | Phase 0 version numbers are a snapshot, not the final lock. | Versions change; `master.md` makes version lock a Phase 2 task. | Build reproducibility. | Phase 2 (D13) |
| A23 | WhatsApp may be sent directly through Meta Cloud API or through a provider; provider is not selected. | D8 open. | Integration, cost, support. | Phase 7 (D8) |
| A24 | Production object storage is not selected; MinIO OSS is not acceptable for production. | MinIO OSS is EOL. | Storage architecture and cost. | Phase 2 (D6) |
| A25 | Public report tokens are at least 256 bits of randomness, stored only as a hash. | `master.md` requires a long random token and protected representation. | Security. | Phase 2 |
| A26 | Timestamps are stored in UTC and displayed in the user’s locale/timezone (UAE is UTC+4). | `master.md` requires UTC storage. | Reporting and audit. | Phase 2 |
| A27 | The technician’s approval is self-finalization; there is no manager or review state. | Explicit requirement. | Status model and UI. | Always |
| A28 | Reports are not indexed by search engines. | Explicit requirement. | Public page metadata and robots. | Phase 6 |
| A29 | The report is a point-in-time inspection record, not a warranty, valuation or official certificate. | Explicit requirement and legal caution. | Wording, disclaimers, sales claims. | Always |
| A30 | Customer consent is captured by workshop staff, not by a customer login. | No customer app/portal. | Intake UI and evidence of consent. | Phase 1 |

---

## 3. Decisions already listed in `master.md` §13A.12

| ID | Decision | Phase 0 evidence / recommendation | Status | Needed by |
|---|---|---|---|---|
| D1 | Database product: MySQL 8.x | MySQL 8.0 is EOL; **MySQL 8.4 LTS** is the only sensible “8.x” pin. | **OPEN — confirm 8.4 LTS** | Phase 1 |
| D2 | One `admin_app` for both admin roles | One app reduces duplication; role-based feature folders + server enforcement. | **RECOMMENDED: one app** | Phase 1 |
| D3 | Riverpod versus Bloc | Riverpod 3.4.3 is current; recommended for DI/offline state. | **RECOMMENDED: Riverpod** | Phase 1 |
| D4 | Public report: Flutter Web versus server-rendered HTML | Flutter web is canvas-based with opt-in accessibility; static text content is not its ideal use case. | **OPEN — Phase 1 spike** | Phase 1 |
| D5 | PDF engine | OpenHTMLtoPDF is 2021, limited RTL, no OpenType, PDFBox 2.x; Chromium is safer for Arabic. | **OPEN — Arabic spike; default Chromium** | Phase 1 |
| D6 | Production object storage | MinIO OSS is EOL; AIStor Free is single-node/proprietary/no encryption at rest. | **OPEN — must change** | Phase 2 |
| D7 | Forms package | `reactive_forms` vs `flutter_form_builder`; both current. | **OPEN** | Phase 2 |
| D8 | WhatsApp, SMS, email providers | WhatsApp requires opt-in/templates; SMS/email providers not selected. | **OPEN** | Phase 7 |
| D9 | Correction/new-version policy | Immutability is clear; who/how/what is shown is not. | **OPEN — product + legal** | Phase 6 |
| D10 | Chinese variant | `zh-Hans` is the working assumption. | **OPEN — confirm** | Phase 1 |
| D11 | Photo requirements per item and size limits | Competitors use 100+ photos; 1–2 MB is a starting target. | **OPEN — pilot tests** | Phase 5 |
| D12 | Admin 2FA method | TOTP is proposed; library not selected. | **OPEN** | Phase 2/7 |
| D13 | Version lock of all packages | 05 is a snapshot only. | **Phase 2 task 1** | Phase 2 |

---

## 4. Product and business questions

| ID | Question | Why it matters | Default if unanswered | Owner | Needed by |
|---|---|---|---|---|---|
| Q1 | What is the commercial model: per workshop, per report, subscription, pilot, or internal? | Affects billing (outside the platform in V1), onboarding and admin screens. | No billing in V1; manual commercial agreement. | Product owner | Phase 1 |
| Q2 | Which partner workshops are in the pilot, and how many? | Affects tenancy, training, support and data volume. | One pilot workshop. | Product owner | Phase 8 |
| Q3 | Which inspection services/templates are sold first: pre-purchase, general check, fleet, EV, other? | Drives the initial item library and template design. | One general/pre-purchase template with 100+ items. | Product owner + specialist | Phase 3 |
| Q4 | What inspection duration and photo volume are acceptable? | Competitors claim 45–75 minutes and 100+ photos. | 60–90 minutes; photo requirements per template, not every item. | Product owner + specialist | Phase 5 |
| Q5 | Who validates the 100+ checklist and severity guidance? | Credibility and safety. | An automotive inspection specialist must sign off before launch. | Product owner | Phase 3/5 |
| Q6 | Will any workshop be authorised to issue an official RTA/Tasjeel certificate? | Determines whether any official wording is allowed. | No official claims; report is a private inspection record. | Product owner + counsel | Phase 1 |
| Q7 | Is the report branded by the platform, the workshop, or both? | PDF/web design and customer trust. | Workshop name prominent; platform as “powered by”. | Product owner | Phase 1 |
| Q8 | Who owns the customer relationship and customer data? | Privacy roles (controller/processor) and consent wording. | Workshop is the customer-facing party; platform is the processor. Confirm with counsel. | Product owner + counsel | Phase 1 |
| Q9 | What is the retention period for reports, evidence, drafts, delivery logs and audit events? | Storage cost and legal exposure. | No hard delete of report dependencies; define in Phase 1/8. | Product owner + counsel | Phase 1 |
| Q10 | Is India a committed 2027 market or a future idea? | Affects localisation and legal preparation. | Prepare structure only; no India launch in V1. | Product owner | Phase 8 |

---

## 5. Workflow and role questions

| ID | Question | Why it matters | Default if unanswered | Owner | Needed by |
|---|---|---|---|---|---|
| Q11 / W1 | Can a technician see all workshop jobs or only their assigned jobs? | Job-list design and privacy. | Only assigned jobs. | Product owner | Phase 1 |
| Q12 / W2 | Can a Workshop Admin edit intake fields before finalization? | Role boundaries. | Yes for intake; never findings/evidence. | Product owner | Phase 1 |
| Q13 / Q3 | Can a Workshop Admin create/invite technicians, or only Platform Admin? | Account lifecycle and audit. | Platform Admin creates all accounts; Workshop Admin assigns work. | Product owner | Phase 1 |
| Q14 | Can a Workshop Admin see their own workshop’s audit history? | Transparency and support. | No; Platform Admin only. | Product owner | Phase 1 |
| Q15 / W4 | Who may initiate a correction, and what can it correct? | D9. | No correction UI/API until approved. | Product owner + counsel | Phase 6 |
| Q16 / W3 | Can a revoked link be reactivated? | Privacy and customer expectations. | No reactivation in V1. | Product owner | Phase 6 |
| Q17 / W5 | Does an existing link serve a corrected version, or is a new link issued? | Public link/version design. | No correction flow until D9. | Product owner + counsel | Phase 6 |
| Q18 / W7 | Can a public viewer download the PDF? | Sharing policy and privacy. | Link-only until approved. | Product owner | Phase 6 |
| Q19 | Can a Workshop Admin resend a link/PDF to a different recipient, or only the original customer? | Prevents accidental disclosure. | Only the recorded customer/recipient; any other recipient needs a new consent record. | Product owner + counsel | Phase 7 |
| Q20 / W6 | Can Platform Admin resend or revoke links? | Support vs central control. | No by default; audited support process if needed. | Product owner | Phase 6/7 |
| Q21 | What happens to evidence and drafts when a job is cancelled? | Retention and privacy. | Retain privately per retention policy; never publish. | Product owner + counsel | Phase 5 |
| Q22 | What happens when a job is reassigned while the technician is offline? | Conflict handling. | Old technician stops; new assignee continues; no silent overwrite. | Product owner | Phase 5 |
| Q23 | Who authorises a walk-in job? | Fraud/abuse control. | Workshop Admin or an authorised technician; policy per workshop. | Product owner | Phase 4/5 |
| Q24 / W2 | Is consent a finalization precondition or only a link precondition? | Workflow and legal evidence. | Finalization can succeed; link inactive without consent. | Product owner + counsel | Phase 1 |
| Q25 | What happens if consent is withdrawn after the link is active? | Legal and operational. | Revoke link; record reason; advise customer copies may exist. | Counsel | Phase 6 |
| Q26 | Who can disable a Workshop Admin or technician, and what happens to their in-flight jobs? | Continuity and security. | Platform Admin disables; Workshop Admin reassigns before disabling; offline data wiped on next sign-in. | Product owner | Phase 2/4 |

---

## 6. Content and inspection questions

| ID | Question | Why it matters | Default if unanswered | Owner | Needed by |
|---|---|---|---|---|---|
| Q27 | What are the 100+ inspection items, categories, instructions and applicability rules? | Core product content. | Draft library from UAE practice; specialist validation required. | Product owner + automotive specialist | Phase 3 |
| Q28 | What are the exact result options and severity definitions? | Consistency and safety. | Use the six suggested result options and four severity levels from `master.md`, with specialist wording. | Specialist | Phase 3 |
| Q29 | Which results require a reason? | Data quality. | “Not checked” and “Could not verify” require a reason; “Not applicable” if template requires. | Product owner | Phase 3 |
| Q30 | Which items require evidence photos? | Inspection time and report size. | Per-item setting; not every item. | Specialist + pilot | Phase 3/5 |
| Q31 | What guide images are needed, and who owns/licenses them? | Copyright and training quality. | Create/licence original images; no copied competitor assets. | Product owner | Phase 3 |
| Q32 | What equipment list applies to each template? | Technician preparation. | Use the examples in `master.md`; specialist confirms. | Specialist | Phase 3 |
| Q33 | What vehicle make/model data source will be used, and is it licensed for commercial use? | Catalogue completeness and licensing. | Start with a small curated list + “Other”; do not scrape a proprietary catalogue. | Product owner | Phase 3 |
| Q34 | Who reviews Arabic translations and bilingual report wording? | Quality and trust. | A native Arabic reviewer with automotive knowledge. | Product owner | Phase 3 |
| Q35 | What standard recommendations and disclaimers are approved? | Legal and consistency. | Draft plain-language disclaimers; counsel reviews. | Product owner + counsel | Phase 3/6 |
| Q36 | What template settings may a Workshop Admin change without weakening a platform safety rule? | Template builder design. | Only order, inclusion of optional items, and settings explicitly marked overridable. | Product owner | Phase 4 |
| Q37 | Should the 100+ item library be one “full package” or multiple service templates? | Template design. | One full package plus smaller service templates. | Product owner | Phase 3/4 |
| Q38 | Is EV/hybrid inspection in V1? | Specialist content and safety. | Conditional category, only if specialist approves. | Product owner + specialist | Phase 3 |

---

## 7. Technical questions

| ID | Question | Why it matters | Default if unanswered | Owner | Needed by |
|---|---|---|---|---|---|
| Q39 | Confirm MySQL 8.4 LTS. | D1. | MySQL 8.4 LTS. | Product owner | Phase 1 |
| Q40 | One admin app or two? | D2. | One app. | Product owner | Phase 1 |
| Q41 | Riverpod or Bloc? | D3. | Riverpod. | Product owner/tech lead | Phase 1 |
| Q42 | Public report: Flutter Web or server-rendered HTML? | D4. | Run the spike; do not build either until decided. | Tech lead + product owner | Phase 1 |
| Q43 | PDF engine: Chromium or OpenHTMLtoPDF? | D5. | Chromium unless spike fails. | Tech lead | Phase 1 |
| Q44 | Production object storage? | D6. | S3-compatible managed/self-hosted with encryption; not MinIO OSS. | Tech lead + product owner | Phase 2 |
| Q45 | Forms package? | D7. | `reactive_forms` for complex forms, or `flutter_form_builder`; pick one in Phase 2. | Tech lead | Phase 2 |
| Q46 | WhatsApp/SMS/email providers? | D8. | Meta Cloud API + one SMS + one email provider; test in Phase 7. | Product owner + tech lead | Phase 7 |
| Q47 | Correction policy? | D9. | No correction UI until approved. | Product owner + counsel | Phase 6 |
| Q48 | Chinese variant? | D10. | `zh-Hans`. | Product owner | Phase 1 |
| Q49 | Photo requirements/size limits? | D11. | Per-item, 1–2 MB target; pilot. | Tech lead + specialist | Phase 5 |
| Q50 | Admin 2FA method? | D12. | TOTP; library selection requires security review. | Tech lead | Phase 2 |
| Q51 | Final version lock? | D13. | 05 is a snapshot; lock in Phase 2. | Tech lead | Phase 2 |
| Q52 | Where will production be hosted, and in which country? | Data residency, latency, cost. | Local dev first; no production commitment. | Product owner | Phase 2/8 |
| Q53 | Which SMS sender ID is approved in the UAE? | Deliverability/regulation. | No SMS until approved. | Product owner | Phase 7 |
| Q54 | Which email domain/provider, and are SPF/DKIM/DMARC configured? | Deliverability. | Use a reputable provider; configure before pilot. | Tech lead | Phase 7 |
| Q55 | Minimum Android/iOS versions? | Package compatibility and device support. | Set during Phase 2 after checking the workshop devices. | Tech lead | Phase 2 |
| Q56 | Which browsers must the admin website and public report support? | Flutter Web/HTML compatibility. | Chrome/Edge/Safari current; test WhatsApp in-app browsers. | Tech lead | Phase 1/6 |
| Q57 | Are the chosen fonts licensed for embedding and redistribution? | Legal and app size. | Verify OFL/embedding rights before bundling. | Tech lead + counsel | Phase 2 |
| Q58 | Is Redis needed in V1? | Simplicity. | No; Caffeine in-process first. | Tech lead | Phase 2 |
| Q59 | What are the backup RPO/RTO and retention targets? | Production readiness. | Daily encrypted backups, tested restore; confirm numbers. | Product owner + tech lead | Phase 8 |
| Q60 | What monitoring/alerting is required? | Operations. | Prometheus/Grafana + Sentry + uptime checks; minimum viable. | Tech lead | Phase 8 |
| Q61 | Do we need antivirus/content scanning for uploads? | Malicious files. | Validate type/size/sniff; consider ClamAV before public launch. | Security | Phase 8 |
| Q62 | Do we need report PDF encryption/password? | Privacy/sharing. | No by default; link token + HTTPS. Decide with counsel. | Product owner + counsel | Phase 6 |

---

## 8. Legal and privacy questions

**All legal items require qualified local counsel. This document does not provide legal advice.**

| ID | Question | Why it matters | Default if unanswered | Owner | Needed by |
|---|---|---|---|---|---|
| L1 | What is the lawful basis and exact consent wording for collecting customer data and creating a public link? | PDPL compliance. | Do not store real customer data until counsel approves. | Counsel + product owner | Phase 1 |
| L2 | Are the Executive Regulations of UAE PDPL now issued? | Detailed obligations. | Assume the law’s principles apply; verify with counsel. | Counsel | Phase 1 |
| L3 | Is a DPIA required for this processing? | Privacy risk. | Ask counsel; prepare a DPIA draft regardless. | Counsel | Phase 1 |
| L4 | Can customer data be hosted outside the UAE? | Cross-border transfer. | Prefer UAE hosting until counsel advises. | Counsel + tech lead | Phase 2 |
| L5 | What is the breach-notification process and timing? | Incident response. | Draft a process; confirm with counsel. | Counsel + security | Phase 2/8 |
| L6 | How are data-subject requests handled (access, correction, restriction, deletion)? | PDPL/DPDP rights. | Manual process via workshop + platform; document it. | Counsel + operations | Phase 1/8 |
| L7 | What retention periods apply to inspection reports, evidence and delivery logs? | Legal/storage. | No hard delete of report dependencies; define before launch. | Counsel + product owner | Phase 1 |
| L8 | What must the public report disclaimer say to avoid implying a warranty or official certificate? | Consumer protection/claims. | Draft plain-language disclaimer; counsel reviews. | Counsel | Phase 6 |
| L9 | Is the public report link a “publication” under UAE law, and what consent is needed? | Privacy. | Treat it as a disclosure; specific consent; counsel reviews. | Counsel | Phase 1 |
| L10 | What are the India DPDP requirements and commencement dates for the planned market? | Future expansion. | Do not launch India until local review. | Counsel | Phase 8 |
| L11 | Do we need a privacy notice and terms of service for workshops and customers? | Transparency. | Yes; draft before pilot. | Counsel | Phase 1/8 |
| L12 | Are WhatsApp/SMS/email marketing rules relevant, or is this transactional only? | Messaging compliance. | Treat as transactional; no marketing without separate opt-in. | Counsel | Phase 7 |
| L13 | Who is the data controller versus processor between the platform and each workshop? | Contract and liability. | Workshop-facing contract must define it; counsel drafts. | Counsel | Phase 1 |
| L14 | What happens legally when a customer asks to revoke a link after it has been shared? | Limits of revocation. | Revoke future access; explain copies cannot be recalled. | Counsel | Phase 6 |

---

## 9. Blocking decisions and safe defaults

| Blocking item | Why blocking | Safe default until answered |
|---|---|---|
| D1 MySQL version | Database schema and hosting. | Plan for MySQL 8.4 LTS; do not build against 8.0. |
| D4 public report approach | Two very different implementations. | Do not build the public report until the spike is decided. |
| D5 PDF engine | Arabic quality and server architecture. | Do not implement PDF; spike first. |
| D6 production object storage | Evidence storage security/licence. | Use local dev storage only; no production commitment. |
| D9 correction policy | Immutability and public link behaviour. | No correction UI/API. |
| L1/L2 consent and PDPL | Cannot safely store real customer data. | Fake data only until counsel approves. |
| Q5 checklist validation | Product credibility/safety. | Draft content only; no launch claim. |

---

## 10. Decisions needed from the product owner now

To approve Phase 0 and start Phase 1, please confirm or correct:

1. **Scope:** the in-scope and out-of-scope lists in `02-confirmed-scope.md`.
2. **Roles:** the three authenticated roles and the permission matrix in `03-roles-and-permissions.md`, including the contested cells.
3. **Database:** MySQL 8.4 LTS (D1).
4. **Admin app:** one app or two (D2).
5. **Public report:** approve the spike plan and accept that the decision is made after measurements (D4).
6. **PDF:** approve the spike plan and the Chromium-first default (D5).
7. **Correction policy:** confirm that no correction feature will be built until D9 is decided.
8. **Commercial model and pilot:** enough information to plan onboarding and training.
9. **Checklist owner:** name the automotive specialist who will validate the library.
10. **Legal:** confirm that a UAE lawyer will review consent, privacy notice, retention and public-link wording before real data.

**No code has been written. Phase 1 has not started.**
