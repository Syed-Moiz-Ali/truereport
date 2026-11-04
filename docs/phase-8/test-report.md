# Phase 8 Test Report

**Project:** TrueReport  
**Date:** 4 November 2026  
**Environment:** Windows 11, Flutter 3.47.9 / Dart 3.13.7, Java 25.0.5, Maven 3.9.16, Docker Desktop 4.98.0, Docker engine 29.9.2, MySQL 8.4.13, Mailpit 1.33.0.

---

## 1. Step 0 - clean baseline (before Phase 8 changes)

| Check | Result |
|---|---|
| `docker compose up --build -d` | PASS; MySQL/Mailpit/server healthy |
| Server `mvn test` | **44 tests, 0 failures, 0 errors, 1 skipped** |
| `MySqlMigrationIT` | PASS at V14 |
| Admin `flutter analyze --fatal-infos` | No issues |
| Technician `flutter analyze --fatal-infos` | No issues |
| Admin tests | **79/79 passed** |
| Technician tests | **20/20 passed** |
| Admin web/APK | PASS; **56,788,405 bytes** APK |
| Technician web/APK | PASS; **62,446,893 bytes** APK |
| Server image | 1,886,884,932 bytes |

Baseline evidence was recorded before Phase 8 code/docs changes.

---

## 2. Final server tests

Command:

```powershell
$env:Path='C:\Users\sanja\AppData\Local\Programs\DockerDesktop\resources\bin;'+$env:Path
cd server
mvn test
```

Result: **56 tests run, 0 failures, 0 errors, 2 skipped** (conditional PDF sample and S3 integration without `S3_TEST_ENDPOINT`).

| Suite | Tests |
|---|---:|
| ArchitectureTest | 2 |
| AuthRecoveryIT | 2 |
| AuthTenancyIT | 7 |
| DeliveryIT | 4 |
| DeliveryRecipientPolicyTest | 2 |
| EvidenceIT | 3 |
| FlywayMigrationTest | 1 |
| FoundationIT | 3 |
| TotpServiceTest | 2 |
| MasterContentIT | 3 |
| MySqlImmutabilityIT | 1 |
| MySqlMigrationIT | 1 |
| MySqlPiiMigrationIT | 1 |
| PiiCryptoTest | 2 |
| PlatformHierarchyIT | 4 |
| ProductionSafetyGuardTest | 3 |
| ReportIT | 3 |
| ReportPdfSampleTest | 1 skipped |
| S3ObjectStorageIT | 1 skipped in normal suite; **1 PASS** with local S3 |
| SecurityEndpointInventoryIT | 2 |
| TechnicianInspectionConcurrencyIT | 1 |
| TechnicianInspectionIT | 4 |
| WorkshopAdminIT | 3 |

### New Phase 8 coverage

- **PII encryption:** round-trip, key ID, rotation, unknown key fail-closed; real MySQL migration of pre-existing fake rows; encrypted columns verified; triggers recreated; finalized job update rejected.
- **S3:** put/get/checksum/pre-signed GET against local **SeaweedFS 4.52**; 1/1 PASS when run with `S3_TEST_ENDPOINT=http://localhost:8333`.
- **2FA recovery:** ten one-time codes, lowercase recovery login, regeneration invalidates old codes, lockout after five failures.
- **Endpoint auth:** 99 OpenAPI operations enumerated; every non-public operation rejected anonymous access with 401/403.
- **CORS:** configured localhost origin accepted; unknown origin rejected.
- **Immutability:** direct SQL rejected for finalized jobs, assessments, findings, item snapshots, final snapshots, evidence, published master versions, published template versions, reports and report versions.
- **Production guard:** local storage, fake providers, disabled real recipients, seed users and Swagger exposure are rejected under `prod`.

---

## 3. Real MySQL and Compose

| Check | Result |
|---|---|
| Flyway H2 | V17 PASS |
| Testcontainers MySQL 8.4.13 | V17 PASS |
| `MySqlPiiMigrationIT` | PASS: plaintext fake rows encrypted, hashes/triggers preserved |
| Compose server rebuild | PASS; V14 → V17 applied to existing dev database |
| Existing job PII columns | Start with `v1:` |
| Existing final snapshot | Starts with `v1:` |
| Finalized-job trigger | Recreated after migration |
| Final-snapshot update trigger | Recreated after migration |
| Final server image | **1,960,189,430 bytes (~1.96 GB)** |
| Chrome for Testing | **156.0.8078.4** |
| Post-restart idle memory | **442.8 MiB / 7.62 GiB** |

---

## 4. Backup/restore drill

| Step | Result |
|---|---|
| MySQL dump | **213,126 bytes** |
| Restore target | Fresh `mysql:8.4.13` container |
| Report versions source/restore | **5 / 5** |
| Snapshot hashes source vs restore | **Equal** |
| Encrypted backup | **223,024 bytes**, AES-256-CBC/PBKDF2 decrypt/restore PASS |
| Object-storage restore | **NOT RUN** |
| Restore pass/fail | **PASS for plain and encrypted database dumps; object-storage restore pending** |

The encrypted database dump was decrypted and restored into a fresh MySQL container; 5 report versions and hash lengths matched. Object-storage restore was not executed. No RPO/RTO is approved; both remain Pending.

---

## 5. Accessibility and public report

Playwright + axe against the live public report at 390×844, dark/light, EN/AR:

| Check | Result |
|---|---|
| HTTP status | 200 |
| External requests | **0** |
| Axe violations | **0** |
| Arabic direction | `rtl` |
| Robots | `noindex, nofollow, noarchive` |
| Focused first control | `A` |
| Screenshots | `docs/phase-8/samples/` |

Axe does not prove screen-reader quality, WCAG 2.2 AA, native Arabic quality or WhatsApp in-app behavior. Flutter screen-reader/manual checks are **NOT RUN**.

---

## 6. Load test

Command: `infra/scripts/load-test.ps1 -Iterations 20` against the local Compose server.

| Step | Requests | Errors | p50 | p95 |
|---|---:|---:|---:|---:|
| Login | 20 | 0 | **71.6 ms** | **1,254.3 ms** |
| Job list | 20 | 0 | **37.7 ms** | **224.4 ms** |
| Public report | 20 | 0 | **29.8 ms** | **99.6 ms** |

This is a **single-client, sequential, local Windows/Docker workload**, not a production benchmark. Checklist fetch, answer save, evidence upload, finalize, report generation and concurrency 1/2/4 PDF memory were **NOT load-tested**.

---

## 7. Scans

| Scan | Result |
|---|---|
| Docker Scout CVE scan | **579 packages; no high/critical vulnerable package**; SARIF saved |
| Gitleaks tracked history | 2 findings: RFC 6238 TOTP test vectors, false positives; no tracked production secret found |
| OWASP Dependency-Check | **NOT RUN**: NVD API key missing |
| Flutter advisories | **NOT RUN**: only `flutter pub outdated` output; 3 direct dependencies constrained |
| Prometheus demo | **PASS**: local Prometheus scraped `/actuator/prometheus`; target health `up`, `up{job="truereport"}=1` |
| Payment tables/endpoints | **None found** |
| Secret files tracked | `infra/.env` is ignored/untracked; local secrets must never be committed |

Scan artifacts:

- `docs/phase-8/samples/truereport-server-cves.sarif`
- `docs/phase-8/samples/gitleaks-git.json`

---

## 8. Client verification

| Check | Result |
|---|---|
| Admin analyze `--fatal-infos` | No issues |
| Admin tests | **79/79 passed** |
| Technician analyze `--fatal-infos` | No issues |
| Technician tests | **20/20 passed** |
| Admin web/APK | Baseline PASS (no Phase 8 client code changes) |
| Technician web/APK | Baseline PASS (no Phase 8 client code changes) |

Phase 8 did not add a Flutter feature. Existing `Warning (drift): database created multiple times` test noise remains; it is not a test failure.

---

## 9. Not run / not proven

- Real WhatsApp/SMS provider, template, sender ID and webhook status mapping.
- Real-device Android/iPhone matrix.
- Native Arabic review.
- Screen-reader/WCAG 2.2 AA manual audit.
- OWASP Dependency-Check (no NVD API key).
- Flutter advisory API scan.
- Encrypted-backup restore and object-storage restore.
- Production S3 provider, SSE/KMS, versioning/lifecycle/object-lock.
- Independent penetration test.
- PDF/Chromium concurrency 1/2/4 memory measurement.
- Production secret manager, live monitoring/paging, certificate-expiry alert.
- Legal/DPIA review.
- Real customer data. No claim of PDPL/GDPR/DPDP compliance.

---

## 10. Phase 8.1 owner decisions

**Date:** 4 November 2026

### Server

Command: `mvn test`

Result: **62 tests, 0 failures, 0 errors, 3 skipped**.

Skipped: conditional PDF sample, S3 integration without `S3_TEST_ENDPOINT`, and POSIX permission assertion on Windows.

New/updated coverage:

- `FileSystemObjectStorageTest`: atomic write, checksum sidecar/read mismatch, path traversal, quota/object limit, free-space reserve, legacy checksum backfill; POSIX permission check skipped on Windows.
- `ProductionSafetyGuardTest`: filesystem allowed; local/S3 rejected in production; missing/non-directory/non-persistent/web-root/insufficient-space roots rejected.
- `AdminPasswordOnlyIT`: admin/Platform Admin password-only login; enrollment/recovery endpoints return `409 TOTP_DISABLED` with flag off.
- `AuthRecoveryIT`: existing TOTP/recovery flow PASS with `truereport.auth.admin-totp.required=true`.
- `EvidenceIT`: evidence content own-role 200, wrong role 403, cross-workshop 404, random id 404; guide-image role matrix.
- `ReportIT`: admin report PDF wrong-workshop 404 and wrong-role 403; public PDF/photo revocation remains.
- Existing auth, tenancy, refresh rotation/reuse, lockout, immutability, report, delivery, MySQL and Flyway suites remain green.

### Client

- Admin: **80/80** tests pass; `flutter analyze --fatal-infos` clean. New source-scan test proves no TOTP/2FA UI exists while the flag is off.
- Technician: **20/20** tests pass; analyze clean.

### Storage backup/restore drill

- Encrypted bundle: **1,302,320 bytes**, AES-256-CBC/PBKDF2.
- Restored into a fresh `mysql:8.4.13` container and fresh storage directory.
- Source/restore report versions: **5 / 5**; report snapshot hashes matched.
- Sample normalized evidence file SHA-256 matched DB `normalized_hash`.
- Sample report PDF SHA-256 matched DB `report_artifacts.content_hash`.
- Off-site copy: **NOT RUN** (destination not selected).
- Full-disk/volume encryption: **NOT RUN** (host decision).
- Real ENOSPC: **NOT RUN** (quota/free-space reserve simulated).

### Storage metrics\n\n`/actuator/prometheus` exposes `truereport_storage_free_bytes`, `truereport_storage_capacity_bytes` and `truereport_storage_application_used_bytes`; local scrape showed the gauges populated.\n\n### Nginx / same domain

- `nginx -t` with dummy certificates: **PASS**.
- Routes: `/api/**`, `/r/**` and Admin web at `/`; `/storage`, `/data`, `/files` return 404.
- No production DNS/TLS certificate or real Admin web deployment was provided.

### Final runtime\n\n| Check | Result |\n|---|---|\n| Server image | **1,960,232,754 bytes (~1.96 GB)** |\n| Idle memory after rebuild | **420.4 MiB / 7.62 GiB** |\n| Chrome | 156.0.8078.4 |\n\n### S3

- `S3ObjectStorageIT` remains skipped in the normal suite because it is optional/unused. It can still be run with `S3_TEST_ENDPOINT`; no cloud account is required or used for Phase 8.1.