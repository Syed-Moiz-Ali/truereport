# Phase 8 Decisions

**Project:** TrueReport  
**Date:** 4 November 2026  
**Status:** Accepted for Phase 8 implementation. Product decisions from Phase 1 remain authoritative.

---

## 1. Scope fence

Phase 8 adds security hardening, production readiness and pilot preparation only.

No product feature was added:

- no correction UI/API;
- no manager/review/approval queue;
- no customer app/portal;
- no payment table, endpoint or card field;
- no provider or cloud contract.

D7, D8, D11 and C2 remain **Pending**. D6 is **resolved by owner decision: self-hosted filesystem storage, no cloud object storage** (Phase 8.1). Admin TOTP is **off by default** under a configuration flag (Phase 8.1).

---

## 2. D6 - production object storage

| Item | Decision | Evidence / limit |
|---|---|---|
| Interface | Existing `ObjectStorage` boundary | No controller depends on a storage SDK |
| Production adapter | **`FileSystemObjectStorage` on a persistent server volume** | Owner decision, Phase 8.1; ADR-0020 |
| Local adapter | `LocalObjectStorage` only when `STORAGE_PROVIDER=local` | Development/test |
| S3 adapter | `S3ObjectStorage` retained but **unused/disabled** | No cloud account required; ADR-0020 |
| Production guard | Fails startup unless `STORAGE_PROVIDER=filesystem`, root exists/writable/persistent, not web/static, and free-space reserve is met | `ProductionSafetyGuardTest` |
| Serving | Files only through authorized backend/token endpoints; never Nginx/Spring static handlers | Evidence/report controllers; Nginx has no storage alias |
| Write | Temp file + fsync + hash + atomic rename; sidecar SHA-256 | `FileSystemObjectStorageTest` |
| Read | SHA-256 sidecar verified; startup backfill for legacy objects | Adapter + test |
| Permissions | Directories `0700`, files `0600` where POSIX is supported | Storage test (POSIX); Windows skips |
| Quotas | Per-object, total quota, minimum free-space reserve | Adapter tests; real ENOSPC NOT RUN |
| Encryption at rest | **Not application-provided**; use full-disk/volume encryption and key custody | Host/volume control; pending ops |
| Backups | Database + storage bundle, encrypted; off-site command configurable | Actual drill PASS |
| Cloud provider | **None** | Owner decision |

The S3 adapter remains in code as an optional alternative only; SeaweedFS is not used for this deployment and MinIO is not used.

---

## 3. PII protection

| Item | Decision |
|---|---|
| Algorithm | AES-256-GCM, 96-bit random IV, 128-bit tag |
| Envelope | Stored value is `<key-id>:<base64(iv+ciphertext)>` |
| Key source | `APP_PII_KEYS` key ring (`id:base64,...`) with `APP_PII_ACTIVE_KEY_ID`; `APP_ENCRYPTION_KEY` is the v1 fallback for local/dev |
| Rotation | New writes use the active key ID; retired keys remain decrypt-only until re-encryption |
| Fields encrypted | `inspection_jobs.customer_name`, `customer_phone`, `customer_email`, `vehicle_vin`, `vehicle_plate`; `inspection_final_snapshots.snapshot_json` |
| Legacy rows | Flyway Java data migration `V16__Encrypt_existing_pii` encrypts existing fake/development data and restores triggers |
| Existing fake data | **Verified on real MySQL Compose**: values start `v1:`; triggers recreated |
| Blind index | Existing delivery recipient SHA-256 hash used for allowlist/rate matching; current job search is in-memory after decryption, so no new lookup index was needed |
| Not protected | Backups, Flutter local Drift data, database memory/query logs, a privileged DBA, crash dumps and already-exported files |
| Legal claim | **None**. This is not a compliance certification |

The final-snapshot hash remains the hash of the plaintext snapshot, so report integrity checks are unchanged. A privileged DBA can still read data while the application is running; encryption reduces at-rest exposure, not authorized runtime access.

---

## 4. Admin 2FA recovery and lockout

| Item | Decision |
|---|---|
| Enforcement flag | `truereport.auth.admin-totp.required` / `ADMIN_TOTP_REQUIRED`, **default false** |
| Default login | Workshop Admin and Platform Admin use password only while the flag is false |
| When enabled | Existing TOTP challenge, recovery codes and lockout return without code changes |
| Recovery endpoints | Return `409 TOTP_DISABLED` while the flag is false |
| Recovery codes | Ten random one-time codes, grouped `XXXXX-XXXXX`, generated at TOTP confirmation and on authenticated regeneration |
| Storage | SHA-256 hash only; used codes retained with `used_at` |
| Login | A recovery code can replace the TOTP code when the flag is enabled; a used code is rejected |
| Regeneration | `POST /api/v1/auth/2fa/recovery-codes`; requires an authenticated admin and the flag |
| Lockout | Five failed password attempts or five failed TOTP attempts lock the account for 15 minutes; generic login error |
| Display | Recovery codes are returned once; the server cannot show them again |
| Residual risk | Stolen admin password gives that admin access; Platform Admin can reach all workshops. Owner accepted for now; 2FA recommended before real customers |
| Not implemented | SMS/email recovery, hardware keys, admin-assisted identity proofing |

---

## 5. Retention

Configuration placeholders, default disabled:

- revoked public links;
- terminal delivery requests, attempts and webhook events;
- expired upload tokens;
- soft-deleted evidence only for non-finalized jobs.

`RetentionService` never deletes finalized inspections, final snapshots, reports or report versions. Exact periods remain **Pending C2 legal input**; defaults are zero/disabled until approved. Backup retention must follow the same approved periods.

---

## 6. Security target

- Target: **OWASP ASVS 4.0 Level 2** for a business application handling PII and public report links.
- This is a target and review frame, not a certification.
- OWASP API Security Top 10 is used for endpoint review.
- The project threat model is `docs/phase-1/11-security-and-privacy-design.md`.

ASVS L2 is appropriate because the app has authenticated staff, tenant isolation, sensitive personal data, public links and uploads, but is not a payment or high-assurance identity system.

---

## 7. Production profile

`SPRING_PROFILES_ACTIVE=prod` must fail startup when any of these is true:

- storage provider is not `filesystem`;
- storage root is missing, not writable, not persistent, inside a web/static path, or below the free-space reserve;
- fake delivery provider is enabled;
- email provider is `fake`;
- real recipients are not explicitly enabled after D8 approval;
- development seed users are enabled;
- OpenAPI/Swagger is exposed.

Production also uses:

- non-root container;
- read-only root filesystem for the server, with writable `/tmp` and cache tmpfs;
- graceful shutdown;
- health/readiness probes;
- Nginx TLS/HSTS/rate/size limits;
- Prometheus metrics;
- encrypted backup script and a tested restore procedure.

No cloud provider, TLS certificate, domain or secret is committed.

---

## 8. Decisions still needed from the user

- Off-site backup destination, host/volume encryption and key custody (D6 no longer requires a cloud provider).
- D8 WhatsApp/SMS/email providers, templates, sender IDs and production email authentication.
- D7 forms package.
- D11 final photo limits/retention.
- C2 lawyer-approved consent, privacy and retention wording.
- Automotive specialist validation of the checklist.
- Native Arabic review of report/PDF/messages.
- Real-device test execution.
- Whether to run a paid penetration test before pilot.
