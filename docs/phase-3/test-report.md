# Phase 3 Test Report

**Project:** TrueReport  
**Date:** 3 November 2026  
**Environment:** Windows 11, Flutter 3.47.9 / Dart 3.13.7, Java 25.0.5 (Temurin 25.0.5+8), Maven 3.9.16. Docker is **not installed**.

---

## 1. Server tests

Command:

```powershell
cd server
$env:JAVA_HOME="C:\path\to\jdk-25"
mvn test
```

Result:

```
AuthTenancyIT       Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
FlywayMigrationTest Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
FoundationIT        Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
TotpServiceTest     Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
MasterContentIT     Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
PlatformHierarchyIT Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
ArchitectureTest    Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
MySqlMigrationIT    Tests run: 1, Failures: 0, Errors: 0, Skipped: 1
Total               Tests run: 23, Failures: 0, Errors: 0, Skipped: 1
BUILD SUCCESS
```

Phase 3 coverage:

- Platform Admin hierarchy search/filter and workshop detail.
- Account create, invite, invitation acceptance, disable, reactivate, transfer.
- Audit events for account lifecycle.
- Last Workshop Admin cannot be disabled.
- Technician and Workshop Admin denied Platform Admin hierarchy and master-content endpoints.
- Master category, item, reason, equipment, dropdown and guide-image operations.
- Publishing creates a new immutable version; v1 label remains unchanged after v2 publishing.
- Retiring leaves all versions and their translations unchanged.
- Guide image upload/content is separate from evidence.
- Flyway migrations V1–V4 from empty and incrementally.
- Spring Modulith and ArchUnit boundaries.
- UUIDv7 and Phase 2 auth/tenancy regressions remain green.

Skipped:

- `MySqlMigrationIT` — **Docker is not installed locally**. It is present for CI with Testcontainers and `mysql:8.4.13`; MySQL 8.4 execution is not locally verified.

---

## 2. Flutter tests

Command:

```powershell
cd client
flutter analyze --fatal-infos
cd apps/technician_app; flutter test
cd ../admin_app; flutter test
```

Result:

```
flutter analyze --fatal-infos  → No issues found!
technician_app                 → 4 tests passed
admin_app                      → 5 tests passed
```

Admin tests cover:

- English hierarchy tree render (workshop, admin, technician).
- Arabic RTL hierarchy/master/audit shell render.
- Master categories/items render.
- Item editor renders without overflow.
- Audit tab render.

Technician tests remain the Phase 2 sign-in/RTL/role-home checks.

---

## 3. Builds

| Check | Result |
|---|---|
| `mvn -DskipTests package` | **PASS** — server JAR produced |
| `flutter build web --release` (admin) | **PASS** — `build/web` produced |
| `flutter build apk` / iOS | **NOT RUN** — no Android SDK/device or macOS |
| Docker Compose | **NOT RUN** — Docker absent |
| MySQL Testcontainers | **SKIPPED** — Docker absent |

---

## 4. Not verified

- Docker Compose and MySQL 8.4 container migration.
- Real Android/iOS device testing, camera/image picker, keyboard and RTL on device.
- Real browser interaction beyond headless widget tests.
- Production S3-compatible storage; Phase 3 uses local filesystem storage behind the `ObjectStorage` interface.
- Final 100+ inspection wording and specialist validation. Sample content is marked `sampleData=true` and is not final.
- Legal review of privacy/consent.
- Direct SQL tamper resistance for published master versions (service enforcement is tested; no MySQL trigger is added in Phase 3).
