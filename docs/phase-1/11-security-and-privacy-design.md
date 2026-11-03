# Security and Privacy Design

**Project:** TrueReport  
**Document:** 11-security-and-privacy-design.md  
**Status:** Phase 1 proposal. Not legal advice. No compliance claim is made.

---

## 1. Security objectives

1. **Tenant isolation.** One workshop can never read or write another workshop’s data.
2. **Report integrity.** Finalized findings cannot be changed through an app, API, normal database path or admin action.
3. **Public privacy.** A public link exposes only allowlisted report data; no customer identity, full VIN, contact details or original evidence.
4. **Consent enforcement.** No active public link without recorded public-link consent; no message without channel consent.
5. **Account protection.** Admin accounts resist takeover; sessions can be revoked.
6. **Evidence safety.** Uploads are validated, private at rest, stripped of metadata in public derivatives, and served through short-lived access.
7. **Auditability.** Sensitive actions are recorded; logs are useful but redacted.
8. **Operational resilience.** Backups, restore tests, monitoring and an incident process exist before real customer data.

---

## 2. Threat model (summary)

| Threat | Impact | Primary controls |
|---|---|---|
| Cross-workshop data access | Severe | Server-side membership resolution, tenant-scoped repositories, composite indexes, cross-tenant tests, neutral 404/403. |
| Admin edits finalized findings | Severe | No edit code path, DB triggers, grants, immutable snapshot, hash monitoring, audit, tests. |
| Public report leaks PII | Severe | Explicit allowlist DTO, public serializer tests, no live entity serialization, no PII in metadata/logs. |
| Token guessing or leakage | Severe | 256-bit random token, hash at rest, rate limit, no token in logs/referrers, neutral errors, revocation. |
| Account takeover | Severe | Argon2id, short-lived access tokens, rotating refresh tokens, TOTP for admins, rate limits, session revocation, audit. |
| Malicious upload | High | MIME/content sniffing, size limits, re-encode images, no SVG, decompression limits, optional AV, private bucket. |
| SQL injection / broken access control | High | Parameterized queries, JPA/`JdbcClient`, server authorization on every object, no client-supplied tenant. |
| XSS in public/admin pages | High | Auto-escaping templates, CSP, no untrusted HTML, sanitize rich text, no inline scripts. |
| SSRF via image/URL fetch | High | Do not fetch arbitrary URLs; allowlist providers; block link-local/metadata IPs. |
| Delivery provider abuse | High | Consent, templates, rate limits, opt-out, provider adapters, no PII in previews, audit. |
| Insider/DBA bypass | High | Separation of duties, least privilege, audit, immutable backups, hash monitoring; acknowledge a privileged DBA can bypass triggers. |
| Backup theft | High | Encryption at rest and in transit, key separation, access control, restore tests. |
| Dependency compromise | High | Lockfiles, dependency scanning, SBOM, pinned images, least-privilege CI. |
| DoS on public report/login | Medium/High | Rate limits, caching, timeouts, resource limits, WAF/CDN if available. |
| Revoked link still cached | Medium | `no-store` HTML, purge, short TTL, origin revocation check. |
| Log/PII leakage | Medium | Structured logging with redaction, no tokens/phones/VINs, log access control. |
| Time/clock errors | Medium | UTC storage, server time for finalization, workshop time zone display, tests. |

---

## 3. Authentication and session security

- Passwords: Argon2id with reviewed parameters; never reversible; password reset tokens single-use, short-lived, hashed.
- Access tokens: short-lived JWT; include `sub`, `role`, `workshopId`, `sessionId`, `jti`; sign with a rotated key; validate issuer/audience/expiry.
- Refresh tokens: opaque random, hashed at rest, rotated on every use; reuse detection revokes the family.
- Admin 2FA: TOTP (D12 Pending); recovery codes hashed, single-use; no SMS-only 2FA.
- Session revocation on disable, role change, workshop transfer, password reset and “logout all”.
- Login rate limiting and generic errors; no account enumeration.
- Device/session list with last seen and revoke action.
- Do not store tokens in `localStorage` on the admin web if avoidable; prefer secure, HttpOnly cookies with CSRF protection, or an in-memory access token plus rotating refresh in a secure store. This is a Phase 2 architecture decision; document it.
- Re-authentication for high-risk admin actions (disable last admin, transfer, mass export).

---

## 4. Authorization and tenancy

- Resolve role/membership on the server from the token and database; never trust a client-supplied `workshopId`.
- Every object fetch checks workshop ownership and role.
- Cross-workshop returns neutral 404/403 without revealing existence.
- Platform Admin oversight is read-only for reports; no edit.
- Public routes authorize only by token and active link state.
- Object storage access is via short-lived signed URLs issued after the same authorization check.
- ArchUnit/tests enforce that controllers do not access repositories directly without a tenant guard.

---

## 5. Immutability controls

1. **Domain:** no update/delete operations for finalized data; finalization is a single transactional transition.
2. **API:** no correction endpoint; no endpoint accepts finalized findings.
3. **Database triggers:** reject updates/deletes on finalized child rows and snapshot/report rows.
4. **Grants:** app user has no update/delete on immutable tables; worker has narrow grants.
5. **Integrity:** SHA-256 of canonical report JSON; nightly recomputation; alert on mismatch.
6. **Audit:** finalization, report generation, link activation/revocation, resend, account changes.
7. **Tests:** direct SQL as the app user fails; API attempts fail; double finalize is idempotent.
8. **Honesty:** a MySQL superuser can disable triggers. Separation of duties and monitoring are mandatory. Do not claim cryptographic impossibility.

---

## 6. Public report and link security

- Token: ≥256 bits random, base64url; store only SHA-256 hash; lookup by hash.
- No token in logs, analytics, referrers, link previews or support screenshots.
- `noindex, nofollow`; neutral title/description; `Referrer-Policy: no-referrer`.
- `Cache-Control: no-store` for HTML; public derivatives content-hashed and cacheable.
- Rate limit by IP and token hash; neutral 404/429.
- Revocation is immediate at the origin; CDN purge if used; explain cached copies cannot be recalled.
- Invalid/revoked/consent-missing all show the same neutral page.
- No public JSON API that returns internal IDs; the page is rendered server-side from the allowlisted snapshot.
- No customer login, no other-report browsing, no search.
- No PDF download by default (PDF1 Pending).
- Link activation only after specific public-link consent.

---

## 7. Data protection and privacy

### 7.1 Data map (summary)

| Data | Purpose | Storage | Public? | Retention |
|---|---|---|---|---|
| Customer name | Identify the job/customer | Encrypted DB | **No** | Pending legal |
| Phone/email | Delivery, support | Encrypted DB + blind index | **No** | Pending legal |
| Vehicle VIN/plate/registration | Identify vehicle | Encrypted DB | **No** | Pending legal |
| Inspection answers/findings | Report | DB + snapshot | Allowlisted only | Pending legal |
| Evidence photos | Proof | Private object storage + public derivative | Derivative only | Pending legal |
| Consent records | Legal evidence | DB append-only | No | Pending legal |
| Audit events | Accountability | DB append-only | No | Pending legal |
| Delivery logs | Operations | DB | No | Pending legal |
| Public token hash | Link lookup | DB | No | While link/report retained |
| Guide images | Training | Private object storage | Not evidence | Per licence |

### 7.2 Principles

- **Minimisation:** collect only what the workshop needs; no customer account, no payment data, no marketing profile.
- **Purpose limitation:** inspection, report, delivery, support, audit.
- **Consent:** separate consents for processing, public link, each delivery channel, and optional PDF download; versioned wording.
- **Accuracy:** technician confirms intake; corrections to personal data follow the approved process, not silent edits to finalized findings.
- **Retention:** legal decision; do not hard-delete report dependencies until approved.
- **Data subject rights:** access/correction/restriction/deletion requests handled through a documented process with counsel; revocation of a link is not deletion of copies already shared.
- **Cross-border:** prefer UAE hosting; object storage and messaging providers may transfer data; counsel must approve. Do not claim adequacy.
- **Controller/processor:** the workshop is the customer-facing party; the platform is likely a processor. Confirm contractually with counsel.
- **DPIA:** prepare a draft; counsel decides whether required.
- **No compliance claims:** do not say “PDPL compliant”, “GDPR compliant” or “certified” until legally verified.

### 7.3 PII handling

- Contact fields encrypted at application level (AES-256-GCM) with a KEK/DEK scheme and rotation.
- Blind-index hashes for duplicate lookup; never log the plaintext.
- Mask phone/email in UI and logs (`+971••••••4567`, `a•••@example.com`).
- No PII in URLs, query strings, analytics, crash reports, screenshots or link previews.
- Access to PII is role-limited and audited.
- Production data is not used in development; use fake data.

### 7.4 UAE and India

- UAE PDPL is in force; Executive Regulations status must be verified with counsel against the Official Gazette.
- India DPDP Act and 2025 Rules are future-market considerations; do not launch India features without local review.
- This document is not legal advice.

---

## 8. Upload and media security

- Enforce max size and allowed MIME types (JPEG, PNG, WebP; no SVG, no HTML, no executables).
- Sniff content, do not trust `Content-Type`.
- Re-encode images server-side; strip EXIF/GPS; create separate public derivatives.
- Private bucket; no public ACL; signed URLs only.
- Validate image dimensions and decompression limits; reject bombs.
- Optional malware scan (ClamAV or provider) before public launch.
- Serve public images from a separate domain or path with no cookies and a strict CSP.
- Do not fetch remote images by URL (SSRF).
- Store content hash, size, MIME, uploader, captured time; verify hash on completion.
- Evidence originals are never public; public derivatives are immutable and content-hashed.

---

## 9. Application security

- Parameterized queries/JPA; no string-concatenated SQL.
- Output encoding by default; no raw HTML from users; sanitize any approved rich text with a strict allowlist.
- CSP, HSTS, `nosniff`, frame denial, referrer policy.
- CSRF protection for cookie-based admin web; SameSite cookies; origin checks.
- CORS deny-by-default; allow only the admin web origin if needed.
- Validate all input server-side (length, type, range, enum, Unicode normalization rules).
- Safe file paths; no path traversal; no user-controlled object keys.
- SSRF protections for any outbound HTTP (allowlist, block private/metadata IPs, timeouts).
- Deserialization: no untrusted polymorphic JSON; strict DTOs.
- Error handling: no stack traces or SQL to clients; correlation ID only.
- Dependency scanning, lockfiles, SBOM, pinned container images, least-privilege CI.
- Secrets in environment/secret manager; never in git, Flutter assets or logs.
- Rate limits on login, public, resend, upload init, master writes.
- Idempotency and optimistic locking to prevent duplicate/unsafe writes.
- Audit all sensitive actions; protect audit from update/delete.
- Security headers and TLS only in production; HSTS after HTTPS is stable.

---

## 10. Logging and monitoring

### 10.1 Log rules

- Structured JSON; UTC timestamps; request ID; user/workshop ID where safe.
- **Never log:** passwords, tokens, refresh tokens, public tokens, full VIN, phone, email, customer name, report contents, object keys with PII.
- Redact at the logger boundary, not ad hoc.
- Log security events: login success/failure (generic), lockout, 2FA failure, permission denial, cross-tenant attempt, upload rejection, link revocation, finalization, report hash mismatch, provider failure.
- Do not log request bodies for PII endpoints.

### 10.2 Monitoring

- Auth failure rate, lockouts, refresh reuse.
- 403/404 spikes (possible enumeration).
- Finalization errors, report generation failures, PDF queue depth.
- Upload failures, storage errors, hash mismatches.
- Delivery failures by provider/channel.
- Public report 404/429 rates.
- DB replication/backup status, disk, memory, CPU.
- Certificate expiry, dependency vulnerabilities.
- Alerts route to an on-call owner; runbooks exist.

---

## 11. Backups, retention and incident response

- Encrypted backups, off-site, with a tested restore at least quarterly.
- Define RPO/RTO (Pending).
- Backups contain PII; access is restricted and audited.
- Retention: legal/ops decision; no hard delete of report dependencies before approval.
- Incident process: detect, contain, assess, notify per counsel, remediate, post-mortem.
- Breach notification timing: confirm with UAE counsel; do not guess.
- Key rotation: JWT signing keys, refresh token hashes, PII encryption keys, object storage credentials.
- Disaster recovery: restore DB and object storage consistently; verify report hashes after restore.

---

## 12. Delivery security

- Channel-specific opt-in; store consent version and timestamp.
- WhatsApp: approved utility template outside the 24-hour window; no private findings in template variables; respect opt-out.
- SMS: approved sender ID; short neutral message; no PII beyond the link.
- Email: SPF/DKIM/DMARC; reputable provider; bounce handling; PDF attachment or secure link per policy.
- Message bodies and link previews contain no customer name, VIN, findings or phone.
- Provider adapters isolate vendor APIs; store provider message IDs; failed delivery never changes the report.
- Rate limit resend; idempotency key prevents duplicates.
- Manual fallback: authorized Workshop Admin can download the PDF and resend through an approved channel.

---

## 13. Third parties and data processing

- Object storage, database hosting, messaging providers and error tracking are subprocessors; list them, contract terms, data location and retention.
- Error tracking (Sentry) must scrub PII/tokens; disable request bodies.
- Analytics must not receive tokens, PII or report content; prefer aggregate, first-party metrics.
- No third-party fonts/scripts on the public report if they can observe the token.
- Vendor breach notification and data-return/deletion terms must be reviewed.

---

## 14. Security test plan

### 14.1 Automated

- Cross-workshop isolation for every endpoint.
- Role matrix per endpoint.
- Finalized data cannot be updated/deleted via API or direct SQL as the app user.
- Public allowlist: no denied field in HTML/JSON.
- Revoked/invalid/consent-missing link returns neutral and no data.
- Idempotency under double submit and timeout.
- Stale version returns 409, never silent overwrite.
- Upload type/size/hash validation.
- Log redaction tests.
- Dependency/secret scanning.
- Rate-limit tests.

### 14.2 Manual / pre-production

- Penetration test: auth, tenancy, IDOR, upload, public link, headers, rate limits.
- Screen-reader and keyboard pass on public/admin.
- Restore drill.
- Incident tabletop.
- Provider failure injection (WhatsApp/SMS/email/storage/PDF).
- Arabic PDF visual review by a native reader.
- Real-device public link test from WhatsApp.
- Review of logs for accidental PII.
- Review of all subprocessors and data locations.

---

## 15. Security acceptance criteria for the pilot

1. No cross-workshop access in automated or manual tests.
2. No finalized finding can be changed through any normal path.
3. No public page exposes a denied field.
4. No active link without consent.
5. Revocation works at the origin and is understood by support.
6. Admin accounts require 2FA.
7. Uploads are validated and public derivatives are stripped.
8. Logs contain no tokens, passwords, full VIN, phone or email.
9. Backups restore successfully.
10. Incident and breach processes are documented and reviewed by counsel.
11. Dependency and secret scans are clean or have approved exceptions.
12. Legal review for UAE PDPL is complete before real customer data.

---

## 16. Explicit non-claims

- This design does **not** certify compliance with UAE PDPL, India DPDP, ISO 27001, PCI DSS or any other standard.
- It does **not** make data immutable against a privileged database administrator.
- It does **not** guarantee that a revoked link erases copies, screenshots or PDFs already saved by a recipient.
- It does **not** replace a qualified legal review, penetration test or operational security program.
