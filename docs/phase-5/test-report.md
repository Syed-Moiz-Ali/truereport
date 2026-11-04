# Phase 5A Test Report

> **Phase 5B update (4 November 2026):** The Step 0 Docker/MySQL gate is now passed. Docker Desktop, Compose, MySQL 8.4.13, V1-V9, MySQL triggers and MySQL concurrency were verified. See `docs/phase-5b/test-report.md` for current results. The Docker-blocked section below is retained as Phase 5A history.

**Project:** TrueReport  
**Date:** 3 November 2026  
**Environment:** Windows 11, Flutter 3.47.9 / Dart 3.13.7, Java 25.0.5 (Temurin 25.0.5+8), Maven 3.9.16. Docker is **not installed**.

---

## 1. Step 0 — Docker

Docker is still not installed. `docker compose up --build` and `MySqlMigrationIT` against MySQL 8.4, including V6/V8 triggers, were **not run**. This remains open risk R71/R74/R83.

---

## 2. Server tests — PASS

Command:

```powershell
$env:JAVA_HOME='C:\Users\sanja\jdk-25.0.5+8'
$env:Path='C:\Users\sanja\jdk-25.0.5+8\bin;'+$env:Path
cd server
mvn test
```

Result:

```text
Tests run: 31, Failures: 0, Errors: 0, Skipped: 1
BUILD SUCCESS
```

Suites:

- `TechnicianInspectionIT` — 4 tests
- `TechnicianInspectionConcurrencyIT` — 1 test
- Existing auth/tenancy, Flyway, Foundation, TOTP, MasterContent, PlatformHierarchy, WorkshopAdmin and Architecture tests
- `MySqlMigrationIT` — 1 skipped (Docker absent)

Phase 5A coverage:

- Assigned/own job access; neutral 404 for another workshop.
- Workshop Admin and Platform Admin denied all new technician inspection endpoints.
- Start pins the template and item versions.
- Master/template changes after start do not alter the pinned checklist.
- Validation matrix: result, severity, reason, note, applicability, version conflict.
- Arabic, Russian and Chinese notes round-trip exactly.
- 105-item checklist completed end to end.
- Finalization is idempotent and returns the same snapshot hash on replay.
- A second key on a finalized job returns 409.
- Two concurrent same-key finalize requests both return the same finalized result.
- Final snapshot is stored with a hash; audit contains start/finalize events.
- Finalized assessment/customer/start edits are rejected.
- Reassignment and cancellation produce visible 409 conflicts.
- Technician walk-in is created assigned to the technician and visible to Workshop Admin.
- Flyway common migrations V1–V7 on H2.
- Spring Modulith and ArchUnit boundaries remain valid.

Skipped:

- `MySqlMigrationIT` — Docker absent. MySQL-only V6/V8 trigger migrations are written but **untested**.

---

## 3. Flutter tests — PASS

Commands:

```powershell
cd client
flutter analyze --fatal-infos
cd apps/technician_app; flutter test
cd ../admin_app; flutter test
```

Result:

```text
flutter analyze --fatal-infos  → No issues found!
technician_app                 → 18 tests passed
admin_app                      → 77 tests passed
```

Technician tests include:

- Existing sign-in/RTL/role-home tests.
- Jobs, job detail, checklist, assessment, review, finalized view and walk-in form.
- English/Arabic and light/dark.
- Phone and tablet widths.
- 2.0x text scale.
- No overflow in tested configurations.

Admin tests still include the existing Platform Admin/Workshop Admin screens and source scans.

---

## 4. Builds — PASS

| Check | Result |
|---|---|
| `mvn test` on JDK 25 | **PASS** — 31 run, 1 skipped |
| `flutter analyze --fatal-infos` | **PASS** — no issues |
| `flutter build web --release` (technician) | **PASS** — `build/web` produced |
| `flutter build apk --debug` (technician) | **PASS** — `app-debug.apk` produced |
| `flutter build web --release` (admin) | **PASS** — `build/web` produced |
| Docker Compose | **NOT RUN** — Docker absent |
| MySQL Testcontainers/triggers | **NOT RUN / SKIPPED** |

Both web builds emit the non-fatal CupertinoIcons font warning; builds succeed.

---

## 5. Not verified

- Docker Compose and MySQL 8.4.
- V6/V8 MySQL trigger creation/execution and direct-SQL immutability.
- MySQL pessimistic-lock behaviour; concurrency was tested on H2 only.
- Real Android/iOS device interaction, on-device Arabic/Russian/Chinese keyboards, accessibility screen reader.
- Offline mode, local persistence, camera/photo capture/upload, evidence storage and evidence validation (Phase 5B).
- Report/PDF/public link/delivery (Phase 6/7).
- Customer/vehicle encryption/retention; Phase 5A data is fake-only.
- Final 100+ checklist wording and specialist validation.
- Production object storage, forms package, delivery providers and photo limits (D6/D7/D8/D11 Pending).
---

## 6. Phase 5B Step 0 — HARD GATE: BLOCKED

**Date checked:** 3 November 2026  
**Command:** `Get-Command docker` and, if found, `docker --version`, `docker info`, and `docker compose version`.  
**Result:** `DOCKER_NOT_INSTALLED` — the `docker` command is not available, so Docker is not installed/running.

Per the Phase 5B instruction, execution stopped at Step 0. The following were **not run**:

- `docker compose up --build`
- MySQL 8.4 `MySqlMigrationIT`
- V1–V8 migrations and V6/V8 trigger creation on real MySQL
- Direct-SQL immutability tests as the application DB user
- Finalization lock/trigger verification on MySQL

No Phase 5B code, migrations, Flutter features or decisions were added. This remains open risk **R71/R74/R83**. Phase 5B must be restarted only after Docker is installed and running.