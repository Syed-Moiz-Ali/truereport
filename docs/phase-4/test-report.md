# Phase 4 Test Report

**Project:** TrueReport  
**Date:** 3 November 2026  
**Environment:** Windows 11, Flutter 3.47.9 / Dart 3.13.7, Java 25.0.5 (Temurin 25.0.5+8), Maven 3.9.16. Docker is **not installed**.

---

## 1. Step 0 — Docker

`docker --version` and Docker Compose were not available. `docker compose up --build` and `MySqlMigrationIT` against MySQL 8.4 were **not run**. This remains open risk R71/R74.

---

## 2. Server tests

Command:

```powershell
$env:JAVA_HOME='C:\Users\sanja\jdk-25.0.5+8'
$env:Path='C:\Users\sanja\jdk-25.0.5+8\bin;'+$env:Path
cd server
mvn test
```

Result:

```text
Tests run: 26, Failures: 0, Errors: 0, Skipped: 1
BUILD SUCCESS
```

Included suites:

- `AuthTenancyIT` — 7
- `FlywayMigrationTest` — 1
- `FoundationIT` — 3
- `TotpServiceTest` — 2
- `MasterContentIT` — 3
- `PlatformHierarchyIT` — 4
- `WorkshopAdminIT` — 3
- `ArchitectureTest` — 2
- `MySqlMigrationIT` — 1 skipped (Docker absent)

Phase 4 server coverage:

- Workshop Admin A cannot read/edit Workshop Admin B template/job/staff data (neutral 404 / empty list).
- Technician and Platform Admin role matrix across new workshop, master-catalog, job and template endpoints.
- Technician sees only assigned jobs and own-created jobs; unassigned job detail is 404.
- Template items pin master item versions.
- Publishing template v2 leaves v1 readable; existing job keeps v1.
- Master item retirement leaves old template version readable; retired item cannot be added to a new template.
- Crafted override requests fail with `422 TEMPLATE_WEAKENS_SAFETY_RULE`.
- 105-item template saves and publishes.
- Template/job audit actions recorded (`TEMPLATE_PUBLISHED`, `JOB_CREATED`, `JOB_ASSIGNED`).
- Flyway common migrations V1–V5 from empty and incrementally on H2.
- Spring Modulith/ArchUnit, tenancy, auth and master-content regressions.

Skipped:

- `MySqlMigrationIT` — Docker absent. The MySQL-only trigger migration is written but **untested**.

---

## 3. Flutter tests

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
technician_app                 → 4 tests passed
admin_app                      → 77 tests passed
```

Admin tests include:

- Existing Platform Admin hierarchy/master/audit/item-editor tests.
- Existing source-scan tests for endpoint centralisation and hardcoded colours/fonts.
- Workshop Admin jobs/staff/templates screens.
- Template builder and read-only version view.
- Job form.
- English/Arabic RTL, light/dark, phone/tablet/wide.
- Text scale 1.5x and 2.0x.
- Reduced motion helper.
- No overflow at tested sizes.

Technician tests remain the sign-in/RTL/role-home checks.

---

## 4. Builds

| Check | Result |
|---|---|
| `mvn test` on JDK 25 | **PASS** — 26 run, 1 skipped |
| `flutter analyze --fatal-infos` | **PASS** — no issues |
| `flutter build web --release` (admin) | **PASS** — `build/web` produced |
| Docker Compose | **NOT RUN** — Docker absent |
| MySQL Testcontainers/triggers | **NOT RUN / SKIPPED** |
| Android/iOS build | **NOT RUN** |

The web build emitted the existing non-fatal CupertinoIcons font warning; the build succeeded.

---

## 5. Not verified

- Docker Compose and MySQL 8.4 migrations.
- MySQL triggers for published master/template versions (written, untested).
- Real Android/iOS device interaction; camera/image picker not touched in Phase 4.
- Real browser interaction beyond headless widget tests and release web build.
- Customer/vehicle PII encryption and retention; Phase 4 job fields are plain columns and must not hold real customer data yet.
- Technician walk-in creation (blocked by undefined workshop policy).
- Final 100+ checklist wording and specialist validation.
- Legal consent/retention (C2).
- Production object storage, forms package, delivery providers and photo limits (D6/D7/D8/D11 remain Pending).
