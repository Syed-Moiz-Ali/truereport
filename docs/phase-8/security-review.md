# Phase 8 Security Review

**Project:** TrueReport  
**Date:** 4 November 2026  
**Review frame:** OWASP ASVS 4.0 **Level 2 target** (not a certification), OWASP API Security Top 10, and `docs/phase-1/11-security-and-privacy-design.md`.

ASVS L2 is the target because the system has authenticated staff, tenant isolation, sensitive PII, public links, uploads and delivery integrations, but no payment or high-assurance identity function. No external penetration test was performed.

---

## 1. Findings and fixes

| ID | Finding | Severity | Evidence | Fix | Regression |
|---|---|---|---|---|---|
| SEC-01 | Customer name/phone/email/VIN/plate and the final snapshot were plaintext at rest | High | `inspection_jobs`, `inspection_final_snapshots` before V15 | AES-256-GCM field encryption with key IDs; V15/V16 migration | `PiiCryptoTest`; `MySqlPiiMigrationIT`; Compose DB values start `v1:` |
| SEC-02 | Production could start with unsafe/local storage | High | `LocalObjectStorage` was unconditional | Production `FileSystemObjectStorage` + guard (filesystem, persistent, writable, outside web root, free-space reserve); S3 retained unused | `FileSystemObjectStorageTest`; `ProductionSafetyGuardTest` |
| SEC-03 | S3 adapter had no checksum, signed URL or private-ACL enforcement | High | New adapter | SHA-256 metadata verification; pre-signed GET/PUT; no public ACL; optional SSE | Local SeaweedFS put/get/presign PASS |
| SEC-04 | Admin TOTP had no recovery path and no lockout | High | `TotpService`/`AuthService` | Ten one-time hashed recovery codes; regeneration endpoint; 5 failures/15-minute lockout. TOTP now configurable and **off by default** per owner decision | `AuthRecoveryIT` (flag on); `AdminPasswordOnlyIT` (flag off) |
| SEC-05 | Public link storage had no retention/cleanup design | Medium | No retention code | Conservative `RetentionService`, disabled by default; never deletes finalized reports | Code review; no destructive test run |
| SEC-06 | CORS allowed localhost patterns in every profile | Medium | `SecurityConfig` | Configurable `CORS_ALLOWED_ORIGINS`; production example explicit; test | `SecurityEndpointInventoryIT` CORS test |
| SEC-07 | Swagger/OpenAPI could be exposed in production | Medium | `application.yml` | Disabled in `application-prod.yml`; startup guard | `ProductionSafetyGuardTest` |
| SEC-08 | Production credentials/secret-file integration is not verified | High | `production.env.example` only | Env-file pattern, no secrets in git; document secret manager requirement | Not production-tested |
| SEC-09 | Java dependency vulnerability scan could not complete | High | OWASP Dependency-Check 13.0.0 | Requires an NVD API key; no result is claimed | NOT RUN |
| SEC-10 | Flutter advisory scan is limited to outdated-package output | Medium | `flutter pub outdated` | Three constrained direct dependencies; no advisory API result | NOT RUN for advisories |
| SEC-11 | Secret scan flags two test vectors | Medium | Gitleaks tracked-history report | RFC 6238 TOTP test secrets, not production secrets; `infra/.env` is ignored/untracked | False positives documented |
| SEC-12 | Container image scan coverage is high/critical only | Medium | Docker Scout SARIF | 579 packages; no vulnerable package at high/critical | `docs/phase-8/samples/truereport-server-cves.sarif` |
| SEC-13 | No independent penetration test | High | No engagement | Required before real-customer pilot | Open |
| SEC-14 | Every endpoint has anonymous-auth coverage, but not every endpoint has object-level cross-tenant coverage | High | 99 OpenAPI operations | Anonymous test loops all operations; existing suites cover role/tenant for many resources | `SecurityEndpointInventoryIT` (3 tests); partial object-level |
| SEC-15 | Public invalid/revoked pages are neutral but timing was not measured | Medium | `ReportIT` neutral body tests | No timing claim | NOT RUN |
| SEC-16 | Image decompression bombs are not explicitly tested | Medium | Evidence validation tests cover MIME/hash/size/role | Re-encode through ImageIO; add dimension bomb test | NOT RUN |
| SEC-17 | Log redaction has no automated logger test | Medium | Code review found no PII logging | Add log appender regression | NOT RUN |
| SEC-18 | No generic 500 leak regression test | Low | Problem-details config | Stack traces disabled; correlation ID only | Partial |
| SEC-19 | Public/message preview behavior on real WhatsApp/email is untested | High | Phase 7 docs | Neutral bodies only | NOT RUN |
| SEC-20 | Single-instance rate limits and workers | Medium | In-memory filters; DB polling | Nginx edge limits; document scaling blocker | Open |

---

## 2. Tenant and role review

- **Anonymous coverage:** 99 OpenAPI operations were enumerated from `/v3/api-docs`; every non-public operation returned `401` or `403` with no token.
- Public exceptions are the documented auth routes, delivery webhook, health/docs and `/r/**`.
- Existing integration suites cover:
  - Workshop Admin A cannot read Workshop B.
  - Technician cannot use Workshop Admin/Platform Admin endpoints.
  - Platform Admin oversight does not grant send/revoke by default.
  - Cross-workshop job/report/link/evidence/delivery access returns neutral 404/403.
- **Gap:** the dynamic test proves authentication, not object-level authorization for every one of the 99 operations. Object-level tests remain a combination of targeted suites and manual inventory review (`openapi-endpoints.md`).

---

## 3. Finalized immutability

`MySqlImmutabilityIT` proves direct SQL cannot update:

- finalized `inspection_jobs`;
- `assessments`;
- `findings`;
- `inspection_item_snapshots`;
- `inspection_final_snapshots`;
- finalized `evidence_assets`;
- published `master_item_versions`;
- published `template_versions`.

`MySqlMigrationIT` also proves `reports` and `report_versions` reject updates. API paths have no correction endpoint. A privileged DBA can still disable triggers; this is stated in the threat model.

---

## 4. Authentication and session review

- Argon2id password hashing.
- Short-lived JWT; refresh token rotation; reuse revokes the family (`AuthTenancyIT`).
- **Admin TOTP is off by default** (`ADMIN_TOTP_REQUIRED=false`, Phase 8.1 owner decision). Password-only admin login is accepted for now.
- When the flag is true, TOTP replay rejection (`TotpServiceTest`), recovery codes (`AuthRecoveryIT`) and TOTP lockout remain active.
- When the flag is false, enrollment/confirm/recovery endpoints return `409 TOTP_DISABLED` and the admin app has no TOTP UI (`AdminPasswordOnlyIT`, source scan).
- Five password/TOTP failures lock for 15 minutes; generic login errors; login rate limits remain.
- Logout-all exists; disable/transfer revoke sessions.
- Residual risk: a stolen admin password gives that admin's access; Platform Admin can reach all workshops. Compensating controls: Argon2id, lockout, rate limits, short JWT, refresh rotation/reuse detection, audit, tenant checks. Recommend revisiting 2FA before real customers, at least Platform Admin.
- No SMS/email recovery; no WebAuthn.
- No shared lockout store for multiple instances.

---

## 5. Upload, SSRF and path traversal

- Allowed evidence types are checked by content/processing, not only the client MIME; PNG/JPEG/HEIC path is bounded by size and hash checks.
- 9 MiB upload is rejected with 413 in tests; wrong type returns 415; hash mismatch returns 422; wrong role/tenant returns 403/404.
- No arbitrary URL fetching exists, so there is no user-controlled SSRF fetch path in the current code.
- `LocalObjectStorage` resolves and normalizes keys and rejects paths outside the root; `S3ObjectStorage` rejects absolute, `..` and backslash keys.
- **Gap:** no explicit pixel-dimension/decompression-bomb test; no antivirus scan.

---

## 5A. OWASP API Security Top 10 mapping

| API risk | Current evidence | Status |
|---|---|---|
| API1 Broken object level authorization | Tenant-scoped services, neutral 404/403 tests; not exhaustive for all 99 operations | Partial |
| API2 Broken authentication | JWT rotation/reuse test, Argon2id, TOTP, recovery, lockout | Good; no shared lockout store |
| API3 Broken object property level authorization | Explicit DTOs; public snapshot allowlist; no entity serialization | Good; manual review |
| API4 Unrestricted resource consumption | Upload size limit, public rate limit, delivery rate limit; no production load proof | Partial |
| API5 Broken function level authorization | Role matrix tests; anonymous rejection for 99 operations | Partial object-level coverage |
| API6 Unrestricted access to sensitive business flows | Consent gates, idempotency, allowlist, no payment flow | Good |
| API7 Server-side request forgery | No arbitrary URL fetch; storage keys constrained | Good; no SSRF feature |
| API8 Security misconfiguration | Prod guard, CORS, Swagger off, headers, non-root image | Partial (deployment unverified) |
| API9 Improper inventory management | OpenAPI inventory generated; 99 operations documented | Good |
| API10 Unsafe consumption of APIs | Provider adapters isolated; real provider not tested | Open |
## 6. Public report review

| Control | Evidence |
|---|---|
| Token 32 random bytes, base64url, ≥43 chars | `ReportIT` |
| Only SHA-256 token hash stored | `ReportIT` |
| Invalid/revoked/consent-missing neutral page | `ReportIT` |
| No external requests | Phase 6 browser check; Phase 8 axe run: `externalRequests: []` |
| Noindex/noarchive, no-referrer, no-store | Phase 6 report tests; Phase 8 browser JSON |
| Rate limit 240/min per IP | `ReportIT` |
| Revocation takes effect at origin | `ReportIT` |
| PDF text/allowlist privacy | Phase 6 tests; Mailpit body scan |
| Axe automated violations | **0** on the current public report |

The public report was checked at 390×844, dark/light, EN/AR. Axe cannot prove screen-reader quality, Arabic semantic quality or real WhatsApp in-app behavior.

---

## 7. Logging and error responses

- Error responses use problem details with stable codes, request ID and no stack trace or SQL.
- No `System.out`, stack-trace printing or request-body logging was found in production code.
- `X-Request-Id` is accepted/validated and returned.
- **Gap:** no automated log-appender test proves every future log call is redacted.

---

## 8. Scans

| Scan | Result |
|---|---|
| Docker Scout CVE scan | 579 packages; **no high/critical vulnerable package**; SARIF saved |
| Gitleaks tracked history | 2 RFC TOTP test-vector false positives; no tracked production secret found |
| OWASP Dependency-Check | **NOT RUN**: NVD API key missing |
| Flutter advisory check | **NOT RUN**: only outdated-package output available |
| Payment endpoint/table scan | No payment table or endpoint found |
| Secret scan of `.env` | `.env` is gitignored and not tracked; file still contains local secrets and must never be committed |

---

## 9. Remaining high findings

1. No independent penetration test.
2. Real provider/webhook/preview behavior untested.
3. Cross-tenant object-level tests are not exhaustive for all 99 operations.
4. Dependency vulnerability coverage is incomplete.
5. No real-device/browser test matrix.
6. Arabic native review not done.
7. PII key custody, backups and privileged DBA access are not production-proven.
8. No legal/DPIA approval.

---

## 10. What this review does not claim

- It does not claim ASVS Level 2 certification.
- It does not claim PDPL, GDPR, DPDP, ISO 27001 or PCI DSS compliance.
- It does not prove cryptographic immutability against a privileged DBA.
- It does not prove real WhatsApp/SMS/email provider security.
- It does not replace a qualified penetration test, legal review or native Arabic review.

---

## 11. Phase 8.1 owner decisions

### Storage

- **D6 resolved:** self-hosted filesystem on a persistent server volume; no cloud object storage.
- Files are served only through backend authorization/token endpoints. Nginx has no storage alias; unknown `/storage`, `/data` and `/files` paths return 404.
- `FileSystemObjectStorage` tests cover atomic write, checksum sidecars, read mismatch, path traversal, quota/object limits, free-space reserve, legacy checksum backfill and POSIX permissions where supported.
- Evidence content, guide image and admin PDF file endpoints have cross-workshop/wrong-role checks; public photo/PDF remain token/revocation checked.
- Backup drill: encrypted database+storage bundle restored into fresh MySQL/storage; 5 report versions and hashes matched; sample evidence and PDF hashes matched.
- **Residual:** single server/volume, no off-site destination configured, disk encryption at rest depends on host/volume encryption, real ENOSPC not simulated.

### Admin 2FA

- Owner deliberately accepted password-only admin login for now.
- TOTP code is not deleted; `ADMIN_TOTP_REQUIRED=true` re-enables enforcement without code changes.
- Residual risk is stated above; the pilot gate recommends 2FA before real customers.