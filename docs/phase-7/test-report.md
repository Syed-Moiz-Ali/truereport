# Phase 7 Test Report

**Project:** TrueReport  
**Date:** 4 November 2026  
**Environment:** Windows 11, Flutter 3.47.9 / Dart 3.13.7, Java 25.0.5, Maven 3.9.16, Docker Desktop 4.98.0, Docker engine 29.9.2, MySQL 8.4.13, Mailpit 1.33.0.

---

## 1. Base verification

Phase 6 closed with:

| Check | Result |
|---|---|
| Server tests | **38 run / 0 failures / 1 skipped** |
| Admin Flutter tests | **79/79 passed** |
| Technician Flutter tests | **20/20 passed** |
| Flutter analyze | clean |
| Admin and technician web builds | PASS |

Phase 7 started from that verified baseline. A separate pre-change rerun was not captured; all Phase 7 changes were validated against the full suite and builds after implementation.

---

## 2. Final server tests

Command:

```powershell
$env:Path='C:\Users\sanja\AppData\Local\Programs\DockerDesktop\resources\bin;'+$env:Path
mvn test
```

Result: **44 tests run, 0 failures, 0 errors, 1 skipped**.

| Suite | Tests |
|---|---:|
| ArchitectureTest | 2 |
| AuthTenancyIT | 7 |
| DeliveryIT | 4 |
| DeliveryRecipientPolicyTest | 2 |
| EvidenceIT | 3 |
| FlywayMigrationTest | 1 |
| FoundationIT | 3 |
| TotpServiceTest | 2 |
| MasterContentIT | 3 |
| MySqlMigrationIT | 1 |
| PlatformHierarchyIT | 4 |
| ReportIT | 3 |
| ReportPdfSampleTest | 1 skipped in normal suite |
| TechnicianInspectionConcurrencyIT | 1 |
| TechnicianInspectionIT | 4 |
| WorkshopAdminIT | 3 |

### DeliveryIT coverage - PASS

- WhatsApp delivery is queued and accepted by the fake provider.
- Send idempotency returns the original delivery and does not create a duplicate.
- Delivery link state is `ACTIVE` after send; message body contains only neutral text, report ID and link.
- Message body does not contain customer name, phone, email, full VIN or plate.
- Signed webhook marks `DELIVERED`; the same event replayed is ignored.
- Role matrix rejects technician/platform access to admin delivery actions and rejects unsigned/bad webhook requests.
- Email delivery attaches the PDF when within the configured size limit.
- Missing channel consent returns `422 CONSENT_REQUIRED`.
- Recipient allowlist policy rejects non-allowlisted phone/email and masks stored recipients.
- Automatic retry moves `RETRY_PENDING` to `SENT` after the retry delay.
- Manual retry requires `Idempotency-Key`.
- Manual retry with the same key is idempotent and preserves attempt history.
- Attempt history and attempt counts remain monotonic.

### ReportIT regression - PASS

- Report v1, immutable snapshot, allowed public fields, PDF, link revocation, public headers, rate limit and role checks remain green after multi-link and delivery changes.
- Report retry returns to `READY` after the due-time boundary fix.

### Flyway - PASS

- H2 migration test reaches version **14**.
- MySQL Testcontainers migration reaches version **14**.
- V13 removes the single-link constraint and recreates the report-version foreign key.
- V14 adds `delivery_requests.retry_key_hash`.
- The H2 migration requires dropping the foreign key before the unique index; the vendor-specific file was corrected and re-tested.

---

## 3. Mailpit end-to-end email - PASS

A real SMTP send through the rebuilt Compose server was executed against Mailpit.

| Check | Result |
|---|---|
| Recipient | `private.9900@example.test` (allowlisted) |
| Channel | `EMAIL` |
| Language | `en` |
| Delivery status | `SENT` |
| Attempts | 1 |
| PDF attached | true |
| Mailpit message subject | `Vehicle inspection report ready` |
| Attachment | `inspection-report.pdf`, `application/pdf`, **278,384 bytes** |
| Message body | Neutral report-ready text with report ID; no customer/vehicle data |
| PII scan of body | No customer name, phone, full VIN, plate or email in the body |

The message body was:

```text
Your vehicle inspection report is ready. Report ID: JOB-F6791692. The attached PDF is the report. The Arabic wording is pending native review.
```

The server was rebuilt with `DELIVERY_EMAIL_PROVIDER=smtp`, `SMTP_HOST=mailpit`, and the test allowlist. This proves the SMTP adapter and Mailpit path, not a production email provider.

---

## 4. Flutter verification

| Check | Result |
|---|---|
| Admin analyze | **No issues** |
| Admin tests | **79/79 passed** |
| Technician analyze | **No issues** |
| Technician tests | **20/20 passed** |
| Admin web build | PASS |
| Technician web build | PASS |
| Admin release APK | **56,788,405 bytes (54.2 MB)** |
| Technician release APK | **62,446,893 bytes (59.6 MB)** |

Admin report page coverage includes delivery history, masked recipient, status, attempts, PDF-attached indicator and retry controls. Technician finalized page renders read-only delivery status.

---

## 5. Docker runtime

| Check | Result |
|---|---|
| Server image | **1,886,884,932 bytes (~1.89 GB)** |
| Chrome for Testing | **156.0.8078.4** |
| Server container after email smoke test | **432.9 MiB / 7.62 GiB** |
| Mailpit | healthy, ports `1025`/`8025` |
| MySQL | healthy, port `3306` |

The memory figure was taken after the email smoke test, not at idle. Chromium peak memory under concurrent PDF generation remains unmeasured.

---

## 6. Not run / not proven

- Real Meta WhatsApp Cloud API or BSP delivery.
- Real Twilio/Unifonic/other SMS delivery.
- Production email provider, SPF/DKIM/DMARC and bounce handling.
- Native Arabic sign-off for delivery wording.
- WhatsApp in-app, iOS Safari, Android browser and screen-reader matrix.
- Dead-letter growth under sustained provider failure was not load-tested.
- Multi-instance worker contention and shared rate limiting were not tested.
- Production link retention/cleanup was not tested.
- No claim of encryption, PDPL/GDPR compliance or provider certification.

---

## 7. Reproduce

```powershell
# Server
$env:Path='C:\Users\sanja\AppData\Local\Programs\DockerDesktop\resources\bin;'+$env:Path
cd server
mvn test

# Admin
cd ..\client\apps\admin_app
flutter analyze
flutter test
flutter build web --release
flutter build apk --release

# Technician
cd ..\technician_app
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

Mailpit smoke requires `infra/.env` values, an allowlisted recipient, the rebuilt server container and Mailpit running.
