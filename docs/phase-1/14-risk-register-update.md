# Risk Register Update (Phase 1)

**Project:** TrueReport  
**Document:** 14-risk-register-update.md  
**Status:** Update to `docs/phase-0/07-risk-register.md`. Scores are re-assessed after the Phase 1 spikes and design work.

---

## 1. Changes since Phase 0

| Risk | Phase 0 | Phase 1 change | Reason |
|---|---|---|---|
| R06 Arabic PDF defects | 5×4 = 20 Critical | **5×2 = 10 Medium** until native review; residual risk remains | Chromium rendered Arabic/RTL/mixed text correctly in the spike; OpenHTMLtoPDF failed and is rejected. Native Arabic review is still outstanding. |
| R08 Public report performance/accessibility | 4×4 = 16 High | **4×2 = 8 Medium** until real-device proof; residual risk remains | SSR measured small, no-JS, semantic, no axe violations; real WhatsApp/devices/screen readers untested. |
| R15 MinIO production | 5×3 = 15 High | **5×1 = 5 Low** | MinIO is now explicitly local-only; production is a shortlist. D6 still pending. |
| R17 OpenHTMLtoPDF | 4×3 = 12 High | **Closed for V1** | Rejected on Arabic quality; Chromium selected (D5 Pending). |
| R14 MySQL 8.0 EOL | 4×3 = 12 High | **4×2 = 8 Medium** | Design targets 8.4 LTS; D1 still Pending. |
| R36 Consent failure | 5×4 = 20 Critical | **5×3 = 15 High** | Consent gate designed; wording/legal review still pending. |
| R09 Offline data loss | 5×3 = 15 High | **5×3 = 15 High** (unchanged) | Design improved; implementation and device tests are still ahead. |
| R10 Double finalization | 4×3 = 12 High | **4×2 = 8 Medium** | Idempotency + unique constraint designed; untested. |
| R02 Cross-workshop leak | 5×3 = 15 High | **5×3 = 15 High** (unchanged) | Design strong; tests not written. |
| R01 Finalized data edited | 5×3 = 15 High | **5×2 = 10 Medium** | Layered controls designed; implementation/tests pending. |
| R25 Scope creep | 4×4 = 16 High | **4×4 = 16 High** (unchanged) | No new scope approved; decisions still open. |

Scores do not fall just because a document exists. A risk closes only when the control is implemented and verified.

---

## 2. New and updated risks

| ID | Risk | Category | Impact | Likelihood | Score | Mitigation | Owner | Early warning |
|---|---|---|---|---|---|---|---|---|
| R41 | Server-rendered public report drifts from the PDF snapshot or the Flutter design language | Integrity / UX | 4 | 3 | 12 High | One snapshot DTO for HTML + PDF; shared tokens; consistency test; visual regression; version footer. | Frontend/backend lead | Customer sees different content in PDF vs web; design divergence. |
| R42 | Chromium PDF runtime is heavy, unstable or hard to patch in production | Operations / security | 4 | 3 | 12 High | Worker pool, memory limits, health checks, queue, pinned browser image, patching process, load test, fallback escalation. | Backend/ops | Worker OOM, PDF queue backlog, browser crash. |
| R43 | Public report is cached after revocation | Privacy | 4 | 3 | 12 High | `no-store` HTML, short TTL, purge, origin revocation check, test through proxy/CDN. | Backend/ops | Revoked link still opens from cache. |
| R44 | SSR template XSS or unsafe HTML injection | Security | 5 | 2 | 10 Medium | Auto-escaping, no raw user HTML, CSP, allowlist DTO, template tests, security review. | Backend/security | Unexpected script/HTML in report; CSP violation. |
| R45 | Public link preview or metadata leaks private data | Privacy | 5 | 2 | 10 Medium | Neutral title/description, no OG with PII, `noindex`, no external embeds, preview test in messaging apps. | Backend/product | Preview shows vehicle/customer data. |
| R46 | Production object storage cannot meet UAE residency or contract terms | Legal / platform | 5 | 3 | 15 High | Shortlist AWS S3 UAE / OCI UAE; counsel review; one-day proof; contract data-location terms. | Product + counsel + tech lead | Provider cannot confirm UAE storage; legal rejects terms. |
| R47 | PDF text is not selectable/searchable or not accessible | Accessibility / UX | 3 | 3 | 9 Medium | Test extraction, tagged PDF if required, accessibility review; do not rely on text extraction alone. | PDF lead | Customer cannot copy a finding; screen reader fails. |
| R48 | Font licence or glyph coverage blocks Arabic/CJK | Legal / UX | 4 | 3 | 12 High | Verify licences and embedding; test glyph coverage; bundle only allowed fonts; fallback plan. | Frontend + counsel | Foundry claim; tofu in a report. |
| R49 | CJK font size makes the app or web build too large | Performance | 3 | 3 | 9 Medium | Subset or lazy-load CJK; measure app size; do not ship full CJK to every user. | Frontend lead | App size unacceptable; slow first load. |
| R50 | Flutter Web semantics/layout is inadequate if D4 changes | Accessibility | 4 | 3 | 12 High | If Flutter is reconsidered, require a semantics-first build, axe/screen-reader tests, zoom, text selection strategy; do not assume parity. | Frontend lead | Screen-reader failure; no text selection. |
| R51 | Decisions are assumed approved because the answer block was empty | Delivery / governance | 4 | 4 | 16 High | This document marks all D1–D13/role/consent/PDF items **Pending**; require written approval before dependent work; track in `00-decisions.md`. | Product owner / PM | A team builds a default as if it were approved. |
| R52 | Consent wording is legally insufficient or evidence is weak | Legal | 5 | 4 | 20 Critical | Counsel-approved wording; version/hash/time/actor/channel; no link without consent; training; audit. | Product + counsel | Disputed consent; regulator/customer complaint. |
| R53 | No native Arabic reviewer is available before launch | Arabic / delivery | 5 | 3 | 15 High | Book a native Arabic reviewer with automotive knowledge; block launch on sign-off; include PDF and UI. | Product owner | Arabic defects found late. |
| R54 | SSR public route is used for enumeration or DoS | Security | 4 | 3 | 12 High | 256-bit token, hash lookup, rate limit, neutral errors, WAF/CDN, monitoring, timeouts. | Security/ops | 404/429 spikes; scanning. |
| R55 | Pre-signed upload URLs leak or are over-privileged | Security | 4 | 3 | 12 High | Short expiry, one object key, content-length/type constraints, authorization before issue, no logging, bucket policy. | Backend/security | Unexpected uploads; URL in logs. |
| R56 | Offline conflict UI encourages unsafe overwrite | Integrity / UX | 4 | 3 | 12 High | No silent overwrite; explicit server/local compare; preserve local for support; tests; technician training. | Mobile lead | Technician chooses “keep mine” and loses server data. |
| R57 | Object storage backup/restore is inconsistent with DB snapshots | Operations / integrity | 5 | 3 | 15 High | Versioned objects, content hashes, coordinated backup, restore drill, hash verification after restore. | Ops/backend | Report references missing photo after restore. |
| R58 | Public PDF download is accidentally enabled | Privacy / scope | 4 | 2 | 8 Medium | Feature flag off by default; route returns 404; test; product approval required. | Backend/product | Download button appears; route serves PDF. |
| R59 | Arabic/English master content is published without specialist review | Content / legal | 4 | 3 | 12 High | Specialist + native Arabic reviewer; publish gate; versioned content; no official claims. | Product + specialist | Workshop rejects wording; safety dispute. |
| R60 | A “condition score” or pass/fail language creeps into the report | Product / trust | 3 | 3 | 9 Medium | Design system bans score; content review; tests for forbidden labels; disclaimer. | Product/design | Report implies a guarantee. |

---

## 3. Top 10 risks after Phase 1

| Rank | Risk | Why |
|---|---|---|
| 1 | R52 Consent wording/evidence | Legal exposure if the link is published without valid consent. |
| 2 | R02 Cross-workshop leak | Destroys partner trust; zero tolerance. |
| 3 | R01 Finalized data edited | Destroys the product’s integrity promise. |
| 4 | R03 Public PII leak | A single leak can destroy trust and create legal exposure. |
| 5 | R46 Object-storage residency | D6 unresolved; UAE data location is a gating legal issue. |
| 6 | R09 Offline data loss | Technicians work in poor connectivity; losing work is unacceptable. |
| 7 | R53 Arabic reviewer availability | Arabic PDF/UI quality cannot be signed off without a reviewer. |
| 8 | R18 WhatsApp policy failure | Main delivery channel can be blocked. |
| 9 | R57 Backup/restore consistency | A report that references missing evidence is not a valid record. |
| 10 | R25 Scope creep | The fastest way to miss the V1 gate. |

---

## 4. Risks that require a decision, not only a mitigation

| Risk | Decision | Status |
|---|---|---|
| R14 MySQL version | D1: MySQL 8.4 LTS | Pending |
| R46 Object storage | D6: AWS S3 UAE or OCI UAE shortlist; MinIO local-only | Pending |
| R06/R47 PDF | D5: headless Chromium; native review follow-up | Pending approval |
| R08 Public report | D4: server-rendered HTML; real-device follow-up | Pending approval |
| R52 Consent | C1–C5 wording/lawful basis | Pending counsel |
| R18/R19/R20 Delivery | D8: providers/sender ID | Pending |
| R01/R09/R56 | D9 corrections; offline conflict policy | Pending |

---

## 5. Review cadence

- Review at every phase gate.
- Re-score after implementation evidence, not after design documents.
- Close a risk only when the control is implemented and verified.
- Link each risk to an ADR or decision in `00-decisions.md`.
- Add risks for every new provider, data location, platform or legal requirement.
