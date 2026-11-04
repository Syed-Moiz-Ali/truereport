# Phase 5B Test Report

**Project:** TrueReport  
**Date:** 4 November 2026  
**Environment:** Windows 11, Flutter 3.47.9 / Dart 3.13.7, Java 25.0.5 (Temurin), Maven 3.9.16, Docker Desktop 4.98.0, Docker engine 29.9.2, Compose v5.6.1, MySQL 8.4.13.

---

## 1. Step 0 - Docker/MySQL gate

Status: **PASSED**.

Docker Desktop is installed per-user at `C:\Users\sanja\AppData\Local\Programs\DockerDesktop`. The CLI is not permanently on PATH; commands used a temporary PATH entry for `resources\bin`.

```text
docker version: 29.9.2
docker compose version: v5.6.1
hello-world: pass
Docker Desktop: Linux containers, 12 CPU, ~7.8 GiB
```

Compose services were started from `infra`:

```text
truereport-mysql-1     mysql:8.4.13          Up (healthy)
truereport-mailpit-1   axllent/mailpit       Up (healthy)
truereport-server-1    truereport-server     Up
```

MySQL migration history:

```text
1 core tenancy auth               1
2 audit events                    1
3 platform hierarchy              1
4 master content                  1
5 workshop templates and jobs     1
6 immutability triggers           1
7 inspection execution            1
8 inspection immutability triggers 1
9 evidence uploads                1
```

V9 applied successfully at runtime:

```text
Current version of schema `truereport`: 8
Migrating schema `truereport` to version "9 - evidence uploads"
Successfully applied 1 migration to schema `truereport`, now at version v9
```

MinIO remains optional. Its pinned image is unavailable/unauthorized, so the default Compose stack does not start MinIO. Phase 5B uses local disk storage.

---

## 2. Server tests - PASS

Command:

```powershell
$env:Path='C:\Users\sanja\AppData\Local\Programs\DockerDesktop\resources\bin;'+$env:Path
mvn -q test
```

Result: **34 tests run, 0 failures, 0 errors, 0 skipped**.

| Suite | Tests |
|---|---:|
| ArchitectureTest | 2 |
| AuthTenancyIT | 7 |
| EvidenceIT | 3 |
| FlywayMigrationTest | 1 |
| FoundationIT | 3 |
| TotpServiceTest | 2 |
| MasterContentIT | 3 |
| MySqlMigrationIT | 1 |
| PlatformHierarchyIT | 4 |
| TechnicianInspectionConcurrencyIT | 1 |
| TechnicianInspectionIT | 4 |
| WorkshopAdminIT | 3 |

### Phase 5B server coverage

- Evidence init is idempotent for the same evidence ID/hash.
- Evidence rejects invalid MIME, oversized payloads, wrong workshop/role and bad upload token.
- Upload hash mismatch returns `422 EVIDENCE_HASH_MISMATCH`.
- Evidence is normalized to JPEG and recorded with source/normalized hashes.
- Required evidence blocks review/ready/finalize with `EVIDENCE_REQUIRED`.
- Evidence count below the pinned minimum still blocks; verified count at/above minimum unblocks.
- Final snapshot contains evidence IDs, source hash and `VERIFIED` state.
- Deleting evidence after finalization returns `409`.
- Guide image is served separately from evidence.
- ISO captured time with `Z` is accepted.

### MySQL-specific checks - PASS

- `MySqlMigrationIT` runs against Testcontainers MySQL 8.4.13: V1-V9 apply, including V6/V8 triggers and V9 evidence columns.
- Direct SQL by the application DB user on a finalized job was rejected:
  - `UPDATE assessments ...` -> `ERROR 1644 (45000): Finalized assessment is immutable`
  - `DELETE FROM assessments ...` -> rejected
  - `UPDATE inspection_item_snapshots ...` -> rejected
  - `DELETE FROM inspection_item_snapshots ...` -> rejected
  - `DELETE FROM inspection_final_snapshots ...` -> rejected
  - `UPDATE inspection_jobs ...` -> rejected
- Evidence-specific trigger test: a test evidence row was inserted for a finalized job, then the app user attempted update/delete:
  - `ERROR 1644 (45000): Finalized evidence is immutable`
- The test row was removed and the delete trigger restored; `SHOW TRIGGERS` confirms both evidence triggers exist.
- Real concurrent same-key finalization on MySQL returned two `200 FINALIZED` responses with the same snapshot hash.

### Real API evidence test on MySQL - PASS

```text
jobId=01a1a195-a70a-7b49-a034-82d1a6b56b3d
itemId=01a1a195-a72b-7ad7-87d1-ecdc7fb0e4da
evidenceId=9e817b4e-2860-46b9-8a90-8c004f4b8e41
status=VERIFIED
mime=image/jpeg
bytes=1710
sha=2938ee4f0d5f70e356d8318fe8c073e67a378f928b2698ca87f8470c181cbd8d
```

This test caught and fixed two real integration defects:

1. `capturedAt` with a trailing `Z` failed `LocalDateTime.parse`; the server now accepts ISO-8601 offset values.
2. The server container user could not write `/app/.truereport-storage`; the image now creates and owns the directory and Compose mounts a persistent `server_storage` volume.

---

## 3. Flutter analysis and tests - PASS

### Workspace analysis

```text
flutter analyze --fatal-infos
No issues found! (ran in 38.8s)
```

### Technician app

```text
flutter test
20 tests passed
```

Includes 18 existing Phase 5A UI tests plus 2 Drift store tests:

- Cached jobs/checklist survive closing and reopening the local database.
- Local assessment and photo evidence stay queued until sync.
- Existing EN/AR, light/dark, phone/tablet and 2.0 text-scale tests still pass.

### Admin app regression

```text
flutter test
77 tests passed
```

### Builds

```text
flutter build web --release --no-pub
exit=0
build\web\main.dart.js
build\web\drift_worker.js
build\web\sqlite3.wasm

flutter build apk --debug --no-pub
exit=0
build\app\outputs\flutter-apk\app-debug.apk
size=247,595,794 bytes
```

`kotlin.incremental=false` was added to `android/gradle.properties` because the Kotlin incremental cache failed when the Pub cache (`C:`) and project (`E:`) were on different drives.

---

## 4. Explicitly not run

- Real Android/iOS camera capture, permission denial and HEIC capture.
- Airplane-mode/manual offline toggling on a physical device.
- Kill-app-mid-upload and resume.
- Low-storage and large-photo stress tests.
- 100+ item checklist on a low-end device.
- OS-level background upload (5B syncs on save, reconnect and manual action).
- MinIO path; optional profile only.
- Production object storage, D6, D7, D8, D11 or C2.

## 5. Known warnings / open technical notes

- `imageio-heif` cannot load native `libheif`; HEIC normalization is unverified. Client compresses to JPEG before upload.
- `sqlite3_flutter_libs` / `sqlcipher_flutter_libs` resolve to EOL-pinned versions via Drift.
- `flutter_image_compress_common` applies the legacy Kotlin Gradle Plugin; future Flutter releases may require a plugin update.
- Drift emits a "database class created multiple times" debug warning in widget tests because each test/provider creates a database instance. It does not affect the passing suite.
- Local disk storage is development-only and is not a substitute for D6 production storage.
