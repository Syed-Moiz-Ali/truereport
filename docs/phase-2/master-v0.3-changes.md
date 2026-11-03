# `master.md` v0.3 — Exactly What Changed

**Project:** TrueReport  
**Document:** docs/phase-2/master-v0.3-changes.md  
**Date:** 3 November 2026  
**Status:** Applied to `master.md` as v0.3. Only the approved Phase 1 decisions and directly implied corrections were applied.

---

## 1. What was approved and applied

| Decision | Applied change |
|---|---|
| **D1** MySQL 8.4 LTS | Database references now say **MySQL 8.4 LTS** (not 8.0, not open “8.x”). `§13A.1`, `§13A.1.1`, `§13` and the decision log updated. |
| **D2** one admin app | `§13A.2` now states one `admin_app` for both admin roles with role-selected feature folders; the “confirm one or two” decision is removed. |
| **D3** Riverpod | `§13A.1` and `§13A.3.3` now mark Riverpod as **DECIDED**, not recommended. |
| **D4** server-rendered public report | `§12`, `§13A.2`, `§13A.8`, `§20 Phase 6` and the decision log now say the public report is **server-rendered HTML**; Flutter Web `public_report_web` is removed from the approved public-report path. |
| **D5** headless Chromium PDF | `§13A.1` and `§13A.8` now choose **headless Chromium**; OpenHTMLtoPDF is explicitly rejected for V1 based on the Phase 1 spike. |
| **D9** no correction UI/API | `§13A.5.1` now says **no correction UI or API in V1**; a future correction, if approved, is a new immutable report version. |
| **D10** `zh-Hans` | `§6` and `§13A.3.9` confirm **Simplified Chinese `zh-Hans`** as the future variant. |
| **D12** admin TOTP | `§13A.4.3` now says **TOTP** is decided for admins, with implementation/security review. |
| **Role defaults** | `§2` now states: technician sees assigned jobs only; Workshop Admin may edit intake before finalization but never findings; Platform Admin creates accounts; Platform Admin does not see customer contact details or resend/revoke by default. |
| **Consent defaults** | `§9` now says consent is separate for processing, public link, each delivery channel and optional PDF; finalization may succeed without public-link consent, but the link stays inactive. |
| **PDF-download defaults** | `§10`/`§18` now say PDF download is **disabled by default**; a later policy may enable a short-lived authorized download. |
| **Public report language** | `§2` changes “customer-approved” to “customer-consented”. |

---

## 2. Document-control changes

- Header version: **v0.2 → v0.3**.
- Header status: “Phase 0 delivered…” → “**Phase 1 approved. Phase 2 foundation is in progress.**”
- Header gate wording: “before the Phase 2 gate” → “before the Phase 2 gate; no Phase 3+ feature is to be built before the Phase 2 gate.”
- Changelog: added a v0.3 entry listing D1, D2, D3, D4, D5, D9, D10, D12 and the role/consent/PDF defaults.
- Decision log `§13A.12`: D1, D2, D3, D4, D5, D9, D10, D12 updated from OPEN/RECOMMENDED to DECIDED. D6, D7, D8, D11 remain OPEN/Pending. D13 remains the Phase 2 version-lock task (in progress).
- `§13A.1` status table: Riverpod, modular monolith, MySQL, PDF and object-storage interface statuses updated. MinIO is explicitly local-only; production storage remains D6.
- `§13A.2` repository layout: `melos.yaml / pubspec.yaml` → `pubspec.yaml` workspace root; `public_report_web` removed from the Flutter apps list because the public report is server-rendered.
- `§13A.8`: public web and PDF engine rewritten; OpenHTMLtoPDF rejection recorded.
- `§13A.9`: MinIO explicitly local-development only; production provider remains Pending; S3-compatible interface retained.
- `§13A.1.1`: “SQL instead of Postgres” now states MySQL 8.4 LTS is decided and 8.0 must not be used.

---

## 3. What was deliberately not applied

The following Phase 0/1 proposals were **not** applied because they were not part of the approved decision set:

- D6 production object-storage provider selection.
- D7 forms package selection.
- D8 WhatsApp/SMS/email provider selection.
- D11 final photo limits.
- The exact legal consent wording, lawful basis and retention (C2).
- The full set of technical-fact corrections in `16-master-v0.3-proposals.md` (for example `sqlite3_flutter_libs`, Melos layout details, package version notes, JobRunr licence). The Phase 2 version lock and README record those where relevant; master remains conservative.
- Any change to the 100+ item library content; that is Phase 3 specialist work.
- Any correction UI/API, manager/review queue, customer app/portal or payment feature.

---

## 4. What did not change

- Three authenticated roles only: Technician, Workshop Admin, Platform Admin.
- Customer is a record, not a login; public viewer is unauthenticated.
- No manager role, review queue, approval or resubmission.
- No customer app, portal, booking or account.
- No in-platform payments or card data.
- Finalized findings are immutable; no admin edit.
- Technician self-finalizes.
- 100+ inspection points, master library, workshop templates, versioning and snapshots.
- English/Arabic launch, RTL, future Russian/Chinese entry.
- Guide image vs evidence image distinction.
- Public token, hash, revocation, neutral invalid/revoked states, no indexing.
- Offline save with “received by server” proof before finalize.
- Modular monolith, MySQL, Flyway, S3-compatible storage, background jobs.
- No payment-card columns anywhere.

---

## 5. Review note

`master.md` is now v0.3. If any of the above wording is not what the product owner intended, correct it in a new revision; do not silently change the meaning of the approved decisions.
