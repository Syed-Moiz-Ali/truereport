# Consistency Check Against `master.md`

**Project:** TrueReport  
**Document:** 10-consistency-check.md  
**Status:** Review findings only. **`master.md` was not edited.** Every proposed change requires product-owner approval.

---

## 1. Purpose

This document compares the Phase 0 outputs with `master.md` v0.2 and records:

- Hard contradictions.
- Technical facts that were correct when v0.2 was written but are now outdated.
- Ambiguities and gaps that need a decision.
- Wording that could mislead a developer or a workshop owner.
- Proposed changes, without applying them.

The master document remains the source of truth until the product owner approves a new version.

---

## 2. Summary

`master.md` is strong on product boundaries: B2B partner workshops, three authenticated roles, no manager role, no review queue, no admin editing, no customer app, no payments, immutable finalized findings, bilingual report, public link. Those rules are internally consistent and should not be weakened.

The main issues are:

1. **Status and gate wording** in the header and Phase 2 description is contradictory.
2. **Several technical facts have changed** since v0.2: MySQL 8.0 EOL, MinIO OSS EOL, `sqlite3_flutter_libs` obsolete, Melos 8 layout, OpenHTMLtoPDF limitations, Flutter Web evidence.
3. **Several role/workflow details are ambiguous**: technician job visibility, Workshop Admin account authority, Platform Admin access to PII/reports, resend/revoke authority, link reactivation, PDF download, consent timing, correction authority.
4. **A few statements are stronger than the product can support**: “customer-approved public report”, “finalized findings can never be edited by anyone” versus a correction/new-version flow, and “public_report_web (Flutter Web)” while D4 is still open.

None of these requires changing the core product. They require a v0.3 clarification.

---

## 3. Hard contradictions

| ID | `master.md` location | Issue | Proposed resolution | Severity |
|---|---|---|---|---|
| C01 | Header lines 5–7 | The header says “Phase 0 research delivered” and “Project status: Phase 0 delivered and awaiting product-owner approval”, but this task is executing Phase 0. | Change the status to “Phase 0 in progress; approval pending” until the owner signs off. After approval, record the approval date and version. | High (document control) |
| C02 | Header line 6, §20 Phase 2 | “No application code is to be written before the Phase 2 gate” conflicts with Phase 2 itself building the Flutter/Java foundation. A gate comes **after** the phase work. | Replace with: “No application code is to be written before Phase 1 is approved and Phase 2 starts.” | High |
| C03 | §12 and §13A.8 | §12 lists “Public Report Website — Flutter Web”; §13A.8 says `public_report_web` (Flutter Web) at `/r/{token}`. But D4 is explicitly OPEN and §13A.8 itself says “If the spike disappoints, render the public report as server-rendered HTML instead.” | Make D4 a genuine option in §12 and §13A.8: “Public report: Flutter Web **or** server-rendered HTML, pending the Phase 1 spike. The rest of the client remains Flutter.” | High |
| C04 | §2, “Customer and public viewer” | §2 says “Anyone with an active public report URL can view the customer-approved public report.” There is no customer approval workflow anywhere in the document; there is only consent to create a public link. | Replace “customer-approved” with “customer-consented” and state that the customer consents to the link, not to a line-by-line approval of findings. | High (legal clarity) |
| C05 | §1, §8, §13A.5.1; task rule | The product rule (and the phase instruction) says finalized findings can never be edited by anyone. §13A.5.1 also allows a “new report version that references the earlier one, with a visible correction note and reason”. A reader may think the system edits the old version. | Add a definition: “Editing” means changing the existing finalized record. A correction creates a **new immutable report version**; the earlier version is never modified. The policy for who may create a correction remains D9. | High |
| C06 | §2 Technician, §8 main flow | A technician can “see inspections assigned to their workshop account”. This could mean all workshop jobs or only jobs assigned to that technician. | State the default: “A technician sees jobs assigned to them. A workshop may optionally expose an unassigned queue; this is a workshop setting to be confirmed (Q13).” | Medium |
| C07 | §2 Workshop Admin, §3 | Workshop Admin can “manage only their own workshop’s inspections and staff”. Platform Admin can “create, invite, disable, reactivate, or transfer accounts”. The split for creating technicians is undefined. | Add an explicit account-authority table: Platform Admin creates Workshop Admins and can create any account; Workshop Admin may invite/disable technicians for their own workshop only if approved (Q13). | Medium |
| C08 | §2 Platform Admin, §3 | Platform Admin can see the hierarchy and audit history, and the tree shows “Inspections and reports”, but the document does not say whether Platform Admin can see customer PII or full reports. | Add a data-visibility rule: Platform Admin sees operational metadata and read-only reports; customer PII is limited and audited. Finalized findings are never editable. | High (privacy) |
| C09 | §2 Workshop Admin, §11 | Only Workshop Admin is granted resend and link revocation. There is no support path for Platform Admin. | Keep Workshop Admin as the primary authority. Add an optional audited support/break-glass process if the product owner wants Platform Admin support; do not grant it silently. | Medium |
| C10 | §11 | Reactivating a revoked link is not defined. | Add a decision: no reactivation in V1, or a separate audited permission. Currently proposed: no reactivation. | Medium |
| C11 | §10, §18 | “PDF download if authorized by the sharing policy” — the sharing policy is not defined. | Define: link-only by default; PDF download requires a separate approved policy and consent. Resolve before Phase 6 (Q18). | Medium |
| C12 | §8, §9 | It is not clear whether consent is a precondition for **finalization** or only for **activating the public link**. | State the rule: finalization may succeed without public-link consent; the link remains inactive until consent is recorded (A15/W2). Confirm with counsel. | High |

---

## 4. Outdated technical facts

These are not product contradictions. They are facts that changed after v0.2 or were not checked when v0.2 was written. They must be corrected in a v0.3.

| ID | `master.md` location | v0.2 statement | Phase 0 finding | Proposed change | Severity |
|---|---|---|---|---|---|
| T01 | §13A.1, §13A.1.1, §13A.5, §13A.9 | “MySQL 8.x” | MySQL 8.0 reached EOL in April 2026. MySQL 8.4 is the current 8.x LTS (8.4.13 at the snapshot), supported to 2032. | Specify **MySQL 8.4 LTS** everywhere and add a minimum-version check. Confirm D1. | High |
| T02 | §13A.1, §13A.9 | MinIO for local; production TBD; “check licensing” | MinIO OSS is archived, AGPL-3.0, source-only, and no longer maintained; no security patches. AIStor Free is proprietary, single-node, no encryption at rest; distributed/encryption are paid. | Keep MinIO as a **local-dev-only** convenience with a pinned image. Remove it as a production candidate. Choose a maintained S3-compatible provider (D6). | High |
| T03 | §13A.4.3, §13A.10 | MySQL Connector/J is not listed as a licence risk | Connector/J Community is GPLv2 with the Universal FOSS Exception. Oracle says commercial distributors that do not want GPL obligations need a commercial licence. | Add a licence review item. Decide: hosted-only use, commercial licence, or MariaDB Connector/J (LGPL). Record in the ADR. | High |
| T04 | §13A.3.7 | `drift` + `sqlite3_flutter_libs` | `sqlite3_flutter_libs` is **0.6.0+eol**; its page says it is obsolete and does nothing after 0.6.0. Drift’s setup docs recommend `drift_flutter` or `sqlite3` 3.x. | Replace with `sqlite3` 3.8.0 + `drift_flutter` 0.3.1. Remove `sqlite3_flutter_libs` from the dependency list. | High |
| T05 | §13A.2, §13A.3.1 | `melos.yaml / pubspec.yaml (workspace root)` | Melos 7/8 uses Dart pub workspaces. There is no `melos.yaml`; the root `pubspec.yaml` declares `workspace:` and packages declare `resolution: workspace`. Melos 8 requires Dart 3.9+. | Update the repository layout and tooling description. | Medium |
| T06 | §13A.3.13 | `alchemist` or `golden_toolkit` alternative | `golden_toolkit` is 0.15.0, last published 2023. `alchemist` is 0.14.1 and maintained. | Prefer `alchemist`; remove `golden_toolkit` from the recommended set. | Low |
| T07 | §13A.3.8 | `photo_view` or `InteractiveViewer` | `photo_view` is 0.15.0, last published 2024. `InteractiveViewer` is built in. | Prefer `InteractiveViewer` unless `photo_view` provides a required feature. | Low |
| T08 | §13A.3.8 | `exif` read | `exif` is 3.3.0, last published 2023. | Keep only if needed; test; consider a maintained alternative. Strip GPS from public derivatives regardless. | Low |
| T09 | §13A.3.10 | `phone_form_field` or `intl_phone_field` | `intl_phone_field` is 3.2.0, last published 2023; `phone_form_field` is 12.0.1 and maintained. | Prefer `phone_form_field`; pick one, not both. | Low |
| T10 | §13A.8 | OpenHTMLtoPDF is “lighter, but Arabic shaping and bidi must be proven” | OpenHTMLtoPDF 1.0.10 is from 2021, is LGPL-2.1+, says **limited RTL/bidi**, has **no OpenType font support**, was tested up to Java 17, and uses PDFBox 2.x. Current PDFBox is 3.0.8. | Keep it only as a spike alternative. Default to headless Chromium. Add the Java 25 and PDFBox 3 compatibility checks to the spike. | High |
| T11 | §12, §13A.8 | Flutter Web is the public report | Flutter web is canvas-based, has a larger runtime, accessibility is opt-in, and Flutter’s own docs say static text content is not its ideal use case. | Make D4 a real comparison. Do not build the public report before the spike. | High |
| T12 | §13A.3.9 | Font candidates “IBM Plex Sans / Noto Sans Arabic” | Licences, glyph coverage, embedding permissions and CJK size were not verified in Phase 0. | Add a font-licence and subsetting gate in Phase 2. Do not bundle a font until its licence is checked. | Medium |
| T13 | §13A.1 table | “Flutter version pinning: FVM” | FVM is 4.3.2 and current. | No change; record the version. | Low |
| T14 | §13A.4.1 | “Java current LTS” | Java 25 is the current LTS (Java 21 still supported; Java 29 next). | Pin Java 25 LTS in Phase 2. | Low |
| T15 | §13A.4.1 | “Spring Boot current stable” | Spring Boot 4.1.2 is current stable; 4.2.0-RC1 is preview. | Pin 4.1.2 and do not use RC builds. | Low |
| T16 | §13A.4.3 | “JobRunr [VERIFY licence/features]” | JobRunr 9.0.3 is LGPL-3.0 or commercial. OSS is limited to about 100 recurring jobs and a simple dashboard. | Record the licence and the OSS limits. Use OSS for the outbox workload; do not rely on Pro features without a purchase. | Medium |
| T17 | §13A.11 | “OpenAPI spec generated and Dart client regenerated” | OpenAPI generator quality was not verified in Phase 0. | Add a Phase 2 checkpoint; fallback to hand-written Retrofit interfaces. | Medium |
| T18 | §13A.3.9 | “Bundle fonts with the app and PDF” | Flutter web can fall back to `fonts.gstatic.com` when bundled fonts lack glyphs; this is configurable. | Explicitly set `fontFallbackBaseUrl` or disable runtime fallback; bundle required glyphs. | Medium |
| T19 | §13A.1 | “Push: Firebase Cloud Messaging” | FCM is optional and adds native configuration; it is not in the core acceptance tests. | Mark as optional/deferred unless the pilot needs push. | Low |

---

## 5. Ambiguities and gaps requiring a decision

| ID | `master.md` location | Gap | Why it matters | Proposed decision | Owner | Phase |
|---|---|---|---|---|---|---|
| G01 | §2, §3 | Who creates/invites technicians? | Account lifecycle and audit. | Platform Admin creates all accounts; Workshop Admin assigns work. If Workshop Admin should invite technicians, add an explicit audited permission. | Product owner | Phase 1 |
| G02 | §2 | Can a Workshop Admin edit intake/customer/vehicle fields? | Role boundary and data quality. | Yes for intake before finalization; never findings, notes or evidence. | Product owner | Phase 1 |
| G03 | §2 | Can Platform Admin see customer PII? | Privacy. | Limited, audited; default to no contact details. | Product owner + counsel | Phase 1 |
| G04 | §2, §11 | Can Platform Admin resend/revoke? | Support vs central control. | No by default; add a separate audited support process if needed. | Product owner | Phase 6/7 |
| G05 | §11 | Link reactivation | Privacy and customer expectations. | No reactivation in V1. | Product owner | Phase 6 |
| G06 | §10, §18 | Public PDF download policy | Sharing and privacy. | Link-only by default; PDF download only with an approved policy. | Product owner + counsel | Phase 6 |
| G07 | §9 | Consent timing | Workflow and evidence. | Finalization can succeed; link inactive without consent. | Product owner + counsel | Phase 1 |
| G08 | §13A.5.1 | Correction authority and mechanics | Immutability and public link. | D9; no correction UI/API until approved. | Product owner + counsel | Phase 6 |
| G09 | §8 | Status model has no transient report-generation states | Developers need to represent PDF/link failures without changing the inspection status. | Add internal report-generation states (`QUEUED`, `GENERATING`, `READY`, `FAILED`) separate from inspection status. Do not add manager/review states. | Tech lead | Phase 1 |
| G10 | §15 | `assessments` and `findings` are both listed, but their responsibilities are not defined | Data model ambiguity. | Define: `assessments` = the answer/result per item; `findings` = the defect details/severity/recommendation derived from a result. Confirm in Phase 1. | Tech lead | Phase 1 |
| G11 | §13A.5.1 | The app DB user has no UPDATE/DELETE on report/snapshot tables, but the app must mark report jobs ready/failed | Permission design gap. | Use a separate worker role for report/status writes, or allow narrow UPDATE on a status column through a controlled path. Document the grants. | Tech lead + DBA | Phase 1 |
| G12 | §13A.5.1 | Triggers list `assessments`, `findings`, `evidence_assets`, snapshots, reports, versions; the trigger condition depends on the parent inspection | Need a clear rule for child tables without a direct parent FK. | Define parent-resolution rules and test every table. Do not rely on application code alone. | Tech lead | Phase 1 |
| G13 | §13A.5.1 | Report hash recomputation job needs read access to immutable tables | Operational design. | A read-only integrity job runs under a separate role; alerts on mismatch. | Tech lead | Phase 6 |
| G14 | §3 | “Platform Admin tree shows inspections and reports” but the tree’s data scope is not defined | Privacy and UI scope. | Tree shows counts/status and links to read-only reports; customer PII is not shown in the tree. | Product owner | Phase 1 |
| G15 | §2, §3 | Workshop Admin “manage staff” vs Platform Admin “create/disable/transfer” | Overlap. | Use the explicit account-authority table (G01). | Product owner | Phase 1 |
| G16 | §8 | “Technician finalizes their inspection” but a Workshop Admin may reassign before finalization | Who owns the finalization if the technician is reassigned at the last moment? | The current assignee finalizes; the old assignee gets a conflict. If no assignee, Workshop Admin must assign before finalization. | Product owner | Phase 5 |
| G17 | §9 | “Record when and how consent was obtained” but no consent versioning model | Legal evidence. | Store consent wording version, timestamp, actor, channel, and evidence (e.g., checkbox/recorded confirmation). | Counsel + tech lead | Phase 1 |
| G18 | §10 | “Coverage count for applicable checklist items” but no definition of “applicable” | Report math and consistency. | Define applicability from the template + technician answers; show the formula in the report. | Product owner + specialist | Phase 1 |
| G19 | §10 | “Summary of key findings” but no rule for what is “key” | Report consistency. | Define: all safety-critical/major defects, plus a count of moderate/minor, with a link to the category detail. | Product owner + specialist | Phase 1 |
| G20 | §7 | “Suggested results” but not all combinations of result/severity/reason are defined | UI and validation. | Define a result/severity/reason matrix in Phase 1; specialist validates. | Specialist | Phase 1 |
| G21 | §7 | “100+ inspection points” but no content ownership or review cadence | Content quality. | Name an automotive specialist and a review cadence; version content. | Product owner | Phase 1 |
| G22 | §5 | “Platform Admin controls which settings a workshop may change” but the configurable settings are not enumerated | Template builder. | Define an explicit allowed-overrides list; default to none. | Product owner | Phase 1 |
| G23 | §6 | “Request an Arabic keyboard/input method where the platform supports it” | Feasibility. | State clearly that the OS controls the keyboard; provide a help hint; test on devices. Do not promise automatic switching. | Tech lead | Phase 1 |
| G24 | §6 | Russian/Chinese “supported as entered” but no font/IME testing plan | Data entry quality. | Add real-device tests for Cyrillic and Chinese input; bundle/verify fonts. | Tech lead | Phase 5 |
| G25 | §13A.9 | “A report link needs a public server and domain” but no domain/hosting decision | Production readiness. | Decide domain and hosting before Phase 6/8. | Product owner | Phase 2 |
| G26 | §13A.10 | Security checklist is a summary, not a testable control set | Security review. | Turn it into a control checklist with owners and evidence in Phase 8. | Security lead | Phase 8 |
| G27 | §13A.11 | CI/CD provider (GitHub Actions or equivalent) not decided | Build/release. | Confirm the repository host and CI before Phase 2. | Tech lead | Phase 2 |
| G28 | §17 | “Review UAE data-protection requirements with qualified local counsel” but no budget/owner | Legal readiness. | Assign counsel and budget before real data. | Product owner | Phase 1 |
| G29 | §13A.12 | D9 correction policy is open but Phase 6 includes “correction history” | Phase 6 cannot be accepted without D9. | Make D9 a Phase 6 gate item, or defer correction UI to a later phase. | Product owner | Phase 6 |
| G30 | §13A.12 | D6 production object storage is open but Phase 2 includes storage | Phase 2 cannot finalise storage without D6. | Decide D6 before Phase 2 storage work. | Product owner | Phase 2 |

---

## 6. Wording that could mislead

| ID | Wording | Problem | Proposed wording |
|---|---|---|---|
| W01 | “Customer-approved public report” | Implies the customer approves findings. | “Customer-consented public report link.” |
| W02 | “Finalized findings can never be edited by anyone” (product rule and phase instruction) | Can be read as forbidding a correction version. | “Finalized findings are immutable. A correction creates a new report version; the earlier version is never modified.” |
| W03 | “The system then creates the report” | Implies synchronous generation. | “The server locks the inspection, then asynchronously builds the report and PDF.” |
| W04 | “Technician finalizes their inspection” | Could imply a manager step in some organisations. | “Technician self-finalizes; there is no manager approval.” |
| W05 | “Public report page is a web page, but it is not a customer portal” | Good rule; keep it. | Add: “It is a read-only report view with no account, booking, payment or messaging features.” |
| W06 | “The customer receives the report URL and PDF” | Could imply both are always delivered. | “The customer receives the URL and, where the delivery policy allows, the PDF.” |
| W07 | “PDF download if authorized by the sharing policy” | Undefined policy. | “PDF download is disabled by default; enable only under an approved sharing policy.” |
| W08 | “No manager role” | Some readers may treat Workshop Admin as a manager. | “No manager/approver role; Workshop Admin is an operational administrator, not a report approver.” |
| W09 | “AI-generated diagnoses ... unless approved as a later feature” | Could invite scope creep. | “Not in V1. Any later AI feature requires a separate approved phase, data-protection review and accuracy evaluation.” |
| W10 | “Report version and publication date” | No definition of “publication” vs “finalization”. | Define: finalization time, report version, and first publication time if different. |

---

## 7. Proposed `master.md` v0.3 changes (not applied)

If the product owner approves, the next master revision should:

1. Fix the header status and the Phase 2 gate wording (C01, C02).
2. Make D4 a real public-report option in §12 and §13A.8 (C03).
3. Replace “customer-approved” with “customer-consented” (C04).
4. Add the immutability/correction definition (C05).
5. Add the account-authority table and technician job-visibility default (C06, C07, G01).
6. Add the Platform Admin data-visibility rule (C08, G03).
7. Add resend/revoke/reactivation/PDF-download decisions (C09–C11, G05, G06).
8. Add the consent timing rule (C12, G07).
9. Update MySQL to 8.4 LTS (T01).
10. Replace MinIO as a production candidate (T02).
11. Add MySQL Connector/J licence review (T03).
12. Replace `sqlite3_flutter_libs` with `sqlite3` + `drift_flutter` (T04).
13. Update Melos layout (T05).
14. Update the PDF section with the OpenHTMLtoPDF limitations and Chromium default (T10).
15. Add the Flutter Web evidence and make D4 a genuine comparison (T11).
16. Add the report-generation states and the `assessments`/`findings` definition (G09, G10).
17. Add the database privilege/trigger design detail (G11–G13).
18. Add the font-licence and font-fallback gate (T12, T18).
19. Mark Firebase push as optional (T19).
20. Add a “Phase 0 decision outcomes” section once the owner approves.

---

## 8. Items that are consistent and should be kept

These parts of `master.md` are clear and should not be weakened:

- B2B partner-workshop model.
- Three authenticated roles only.
- Customer is a record, not a login.
- No manager role, no review queue, no resubmission.
- No customer app, booking portal or account.
- No in-platform payments or card data.
- No admin editing of finalized findings.
- Technician self-finalization with `FINALIZED`, not “approved”.
- 100+ inspection points in the shared library.
- Platform Admin owns master content; Workshop Admin builds templates from approved items.
- Template versioning and immutable report snapshots.
- English/Arabic at launch, RTL, future Russian/Chinese.
- Guide image vs vehicle evidence distinction.
- Public URL with a long random token, stored as a hash.
- No search indexing; no private fields by default.
- Delivery status separate from inspection status.
- Offline save with “received by server” proof before finalize.
- Modulith monolith, MySQL, Flyway, S3-compatible storage, background jobs.
- No payment-card columns anywhere.

---

## 9. Conclusion

The core product rules are coherent. The master document needs a v0.3 update for:

- document status and gate wording;
- MySQL 8.4 LTS;
- MinIO removal from production;
- the MySQL Connector/J licence;
- `sqlite3_flutter_libs` and Melos 8;
- the public report decision;
- the PDF engine risk;
- the role/consent/correction ambiguities.

Until the product owner approves those changes, the Phase 0 documents should be read as **proposals**, and `master.md` remains the source of truth.

**`master.md` was not edited. No application code was written. Phase 1 has not started.**
