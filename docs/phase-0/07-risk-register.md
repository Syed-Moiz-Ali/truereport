# Initial Risk Register

**Project:** TrueReport  
**Document:** 07-risk-register.md  
**Status:** Phase 0 initial register. Review at every phase gate.

---

## 1. Scoring and risk appetite

**Impact:** 1 = negligible, 2 = minor, 3 = moderate, 4 = major, 5 = severe.  
**Likelihood:** 1 = rare, 2 = unlikely, 3 = possible, 4 = likely, 5 = almost certain.  
**Score:** Impact × Likelihood.  
**Priority:** 20–25 Critical, 12–19 High, 6–11 Medium, 1–5 Low.

**Risk appetite:**

- **Zero tolerance** for cross-workshop data leaks and for editing finalized findings. These are product-integrity failures, not trade-offs.
- **Low tolerance** for public-report privacy leaks and Arabic report defects.
- **Managed tolerance** for delivery-provider outages, performance tuning and cosmetic issues, provided the report remains intact and a manual fallback exists.

---

## 2. Register

| ID | Risk | Category | Impact | Likelihood | Score | Mitigation | Owner | Early warning |
|---|---|---|---|---|---|---|---|---|
| R01 | A finalized finding, severity, note or evidence item is changed through an admin screen, API or database path. | Integrity | 5 | 3 | 15 High | Domain lock; no update/delete code paths; DB triggers; app DB user without UPDATE/DELETE on snapshots; report hash check; direct-SQL tests; audit. | Backend lead | Any “quick fix” request from a workshop; any support request to edit a report. |
| R02 | Workshop A reads or writes Workshop B’s jobs, reports, media or templates. | Security / tenancy | 5 | 3 | 15 High | `workshop_id` on every owned table; tenant-aware repositories; server-side membership; cross-workshop tests per endpoint; file-access tests. | Backend lead | A 403/404 anomaly; a support ticket showing the wrong workshop name. |
| R03 | The public report exposes customer name, phone, email, full VIN, registration or precise location. | Privacy | 5 | 4 | 20 Critical | Explicit public allowlist serializer; public DTO tests; field-level review; no live entity serialization; no PII in metadata/logs. | Backend + product | A public page containing any field not on the allowlist; a link preview showing private data. |
| R04 | A public link is indexed by search engines or previewed with private data. | Privacy | 4 | 3 | 12 High | `noindex`; neutral title/description; no customer data in OG/meta; robots; rate limiting; review after deploy. | Backend + ops | Search result for a report; a messaging-app preview showing vehicle/customer data. |
| R05 | A public link is shared beyond the intended recipient, and revocation cannot recall copies. | Privacy / business | 4 | 4 | 16 High | Specific consent wording; explain shareability; revoke future access; audit; no “secret” promise. | Product + counsel | Customer complaint; link forwarded to an unknown party. |
| R06 | Arabic PDF has incorrect shaping, bidi ordering, broken lam-alef ligatures or missing glyphs. | Arabic / PDF | 5 | 4 | 20 Critical | Arabic PDF spike; native Arabic reviewer; Chromium default; bundled fonts; mixed-direction test corpus; multi-page tests. | PDF spike lead | Reviewer finds reversed text, disconnected letters, wrong number order. |
| R07 | The PDF engine is too slow, memory-heavy or expensive at pilot volume. | Performance | 3 | 3 | 9 Medium | Spike measures p50/p95 generation time, memory and concurrency; queue; cache; limit photos; consider worker pool. | Backend lead | Report queue backlog; worker OOM; timeouts. |
| R08 | Flutter Web public report is slow on a poor connection or inaccessible, and link previews are poor. | Public report | 4 | 4 | 16 High | Run the Flutter Web vs server-rendered HTML spike; measure first load, accessibility, no-JS, text selection and previews. | Frontend lead | High bounce/timeout from WhatsApp; screen-reader failure; blank page before JS loads. |
| R09 | Offline work is lost, duplicated or silently overwritten. | Offline | 5 | 3 | 15 High | Local write-ahead; client UUIDs; revision numbers; queue persistence; idempotent upserts; conflict UI; app-kill tests; finalize gate. | Mobile lead | “My answers disappeared”; duplicate answers; finalize after a conflict. |
| R10 | Double finalization creates duplicate reports or public links. | Integrity | 4 | 3 | 12 High | `Idempotency-Key`; unique constraint on inspection finalization; return existing result; retry tests. | Backend lead | Two report versions for one inspection; duplicate delivery. |
| R11 | Photo volume makes inspection too slow, storage too expensive or the report too large. | Operations | 4 | 4 | 16 High | Per-item photo requirements; compress to 1–2 MB target; pilot measurement; storage lifecycle; report photo limit; no original high-res public files. | Product + mobile | Technician overtime; storage growth; PDF generation time. |
| R12 | The 100+ checklist is not credible, is unsafe, or is not validated by a specialist. | Content / legal | 4 | 3 | 12 High | Automotive specialist validation; clear “not official” wording; pilot review; versioned content; no copied competitor assets. | Product + specialist | Workshop rejects items; customer dispute; legal question about claims. |
| R13 | A master item or template update silently changes an existing inspection or report. | Integrity | 5 | 3 | 15 High | Templates reference master item **versions**; snapshots at finalization; no live joins for reports; version tests. | Backend lead | Old report wording changes after a catalogue edit. |
| R14 | MySQL 8.0 is deployed and reaches/extends beyond EOL. | Platform | 4 | 3 | 12 High | Pin MySQL 8.4 LTS; confirm D1; upgrade plan; version check in CI. | Tech lead | Server reports 8.0.x; no security patches. |
| R15 | MinIO OSS is used in production and receives no security patches. | Platform / licence | 5 | 3 | 15 High | Use MinIO only for local dev; choose a maintained S3-compatible provider; document the decision; scan images. | Tech lead | Production bucket on an archived MinIO build. |
| R16 | MySQL Connector/J GPLv2 creates a distribution/licence problem. | Legal / licence | 4 | 3 | 12 High | Legal review; prefer server-side hosting without distributing the driver; consider MariaDB Connector/J (LGPL) or a commercial licence; record the decision. | Tech lead + counsel | A customer asks for a Docker image; a distributor requests redistribution rights. |
| R17 | OpenHTMLtoPDF is chosen and fails Arabic or Java 25 compatibility. | PDF / platform | 4 | 3 | 12 High | Do not choose before the spike; default Chromium; test on Java 25; keep the abstraction boundary so the engine can be swapped. | PDF lead | RTL defects; classpath conflicts with PDFBox 3; runtime errors. |
| R18 | WhatsApp templates are rejected, the business is not verified, or messages violate opt-in rules. | Delivery / legal | 4 | 4 | 16 High | Start Meta/provider onboarding early; capture channel-specific opt-in; use approved utility templates; maintain a manual fallback; audit. | Product + delivery lead | Template rejection; account restriction; customer complaint. |
| R19 | SMS sender ID or provider rules block delivery in the UAE. | Delivery / legal | 3 | 3 | 9 Medium | Choose a provider with UAE sender-ID support; register the sender ID; test; keep WhatsApp/email as fallbacks. | Delivery lead | Messages rejected or marked spam. |
| R20 | Email PDFs bounce or land in spam. | Delivery | 3 | 3 | 9 Medium | Reputable provider; SPF/DKIM/DMARC; bounce handling; link fallback; test with major mailbox providers. | Delivery lead | High bounce rate; spam complaints. |
| R21 | UAE PDPL obligations are misunderstood or the Executive Regulations change. | Legal | 5 | 3 | 15 High | Counsel review; data minimisation; consent records; UAE hosting preference; no compliance claims; monitor official sources. | Product + counsel | New regulation/guidance; customer request; breach. |
| R22 | India DPDP requirements are underestimated for the later market. | Legal | 4 | 3 | 12 High | Defer India launch; local counsel; verify Rules commencement; localisation and data-residency review. | Product + counsel | India pilot request before review. |
| R23 | An admin account is compromised and used to view or revoke reports. | Security | 5 | 3 | 15 High | Argon2; TOTP for admins; short-lived access tokens; refresh rotation; rate limiting; audit; device/session revocation. | Security lead | Impossible-travel login; mass revocation; unusual export. |
| R24 | A dependency has a critical vulnerability or a malicious update. | Supply chain | 4 | 4 | 16 High | Lockfiles; dependency scanning; pinned images; least-privilege CI; review new packages; no secrets in build logs. | Tech lead | Scanner alert; unexpected package publish. |
| R25 | Scope creep adds a customer app, payments, manager review or AI. | Delivery / business | 4 | 4 | 16 High | Scope fence in `02-confirmed-scope.md`; change control; product-owner approval for every addition. | Product owner | “While we are here, can we also…” requests. |
| R26 | The pilot disrupts a workshop’s daily operation. | Operations | 3 | 4 | 12 High | Training; one-hand phone UX; offline mode; printed fallback; pilot support; measure inspection time. | Product + ops | Technicians abandon the app; queue builds up. |
| R27 | Server failure, data loss or an untested restore. | Operations | 5 | 3 | 15 High | Off-site encrypted backups; tested restore; UPS/power plan; monitoring; incident process; RPO/RTO defined. | Ops | Failed backup; long outage; missing evidence. |
| R28 | Public tokens are guessable or leaked in logs/referrers. | Security | 5 | 2 | 10 Medium | 256-bit random tokens; store hash; rate limit; no token in logs; `Referrer-Policy`; neutral errors. | Security lead | Token enumeration attempts; token in analytics. |
| R29 | A malicious upload or SVG/image exploit compromises the server or viewers. | Security | 4 | 3 | 12 High | Validate type/size/content; re-encode images; strip EXIF; serve from a separate domain; consider AV; no untrusted SVG. | Security lead | Malware alert; unusual outbound traffic. |
| R30 | Font licensing or CJK font size causes legal/app-size problems. | Legal / UX | 3 | 3 | 9 Medium | Verify licences; bundle only needed weights; subset; lazy-load CJK; test app size. | Frontend + counsel | Font foundry claim; app size unacceptable. |
| R31 | Timezone/date errors make inspection dates or audit times wrong. | Data quality | 3 | 3 | 9 Medium | Store UTC; convert in UI; test UAE/India/UTC; fixed date format in reports. | Backend | Report date off by one; audit ordering wrong. |
| R32 | Retention/deletion requests conflict with report immutability. | Legal / integrity | 5 | 3 | 15 High | Counsel-approved retention policy; soft-delete/disable; keep report history; define legal hold; no hard delete of dependencies. | Counsel + backend | Customer deletion request; regulator request. |
| R33 | Transferring or disabling a user breaks audit history or orphan records. | Operations | 3 | 3 | 9 Medium | Soft-disable; membership history; never hard-delete users/reports; reassign in-flight jobs; audit. | Backend | Orphaned assignments; missing technician name. |
| R34 | A revoked link is still served from a cache. | Privacy | 4 | 3 | 12 High | Short cache TTL; `no-store` for private responses; revoke check at origin; CDN purge; test. | Backend + ops | Revoked link still opens from a cached copy. |
| R35 | Public web report and PDF disagree. | Integrity | 4 | 3 | 12 High | Both render from one snapshot; hash; consistency test; version footer. | Backend | Customer sees different findings in PDF and web. |
| R36 | Consent is not properly captured, is ambiguous, or is lost. | Legal | 5 | 4 | 20 Critical | Versioned consent records; specific wording; timestamp/actor/channel; training; audit; counsel review; no link without consent. | Product + counsel | Missing consent for an active link; disputed consent. |
| R37 | Key-person dependency and undocumented decisions slow the project. | Delivery | 3 | 4 | 12 High | ADRs; phase documents; code ownership; CI; handover notes. | Tech lead | Only one person can deploy or explain a module. |
| R38 | The 100+ item checklist performs poorly on low-end Android phones. | Performance | 3 | 3 | 9 Medium | Lazy lists; local pagination; profile on real devices; image caching; avoid rebuilding the whole list. | Mobile lead | Jank; slow scrolling; ANRs. |
| R39 | Technicians cannot switch the device keyboard to Arabic and blame the app. | UX / support | 3 | 4 | 12 High | Clear help hint; device settings guide; test on Android/iOS; do not promise automatic switching; provide field direction controls. | Mobile + support | Support tickets about Arabic typing. |
| R40 | Chromium PDF rendering is costly or hard to operate at scale. | Operations | 3 | 3 | 9 Medium | Spike measures; queue; reuse browser context carefully; memory limits; container health checks; fallback engine only if proven. | Backend + ops | Worker crashes; slow PDF queue. |

---

## 3. Top 10 risks to watch

| Rank | Risk | Why it is top |
|---|---|---|
| 1 | R03 public PII leak | A single leak can destroy trust and create legal exposure. |
| 2 | R06 Arabic PDF defects | The bilingual report is the core customer-facing product. |
| 3 | R36 consent failure | Without valid consent, the public link cannot be used. |
| 4 | R01 finalized data edited | Destroys the product’s integrity promise. |
| 5 | R02 cross-workshop leak | Destroys partner trust and may be a legal breach. |
| 6 | R09 offline data loss | Technicians work in poor connectivity; losing work is unacceptable. |
| 7 | R18 WhatsApp policy failure | The main delivery channel can be blocked. |
| 8 | R08 public report performance/accessibility | The customer may never see the report. |
| 9 | R15 MinIO EOL | A production dependency with no security patches. |
| 10 | R25 scope creep | The fastest way to miss the V1 gate. |

---

## 4. Risks that require a decision, not just a mitigation

| Risk | Decision needed |
|---|---|
| R14 MySQL version | D1: confirm 8.4 LTS. |
| R15 MinIO | D6: choose production object storage. |
| R16 Connector/J licence | Legal: commercial licence, GPL compliance, or alternative driver. |
| R17 PDF engine | D5: spike result. |
| R08 public report | D4: spike result. |
| R21/R32 privacy/retention | Counsel-approved policy. |
| R18/R19/R20 delivery | D8: providers and sender IDs. |

---

## 5. Review cadence

- Review this register at the end of every phase.
- Add a risk when a new dependency, provider or legal requirement appears.
- Close a risk only when the mitigation is implemented and verified, not when it is planned.
- Re-score after each phase gate.
- Keep a link from each risk to the relevant decision or ADR.

**No code has been written. Phase 1 has not started.**
