# Phase 2 Test Report

**Project:** TrueReport  
**Date:** 3 November 2026  
**Environment:** Windows 11, PowerShell 5.1, Flutter 3.47.9 / Dart 3.13.7, Java 25.0.5 (Temurin 25.0.5+8), Maven 3.9.16. Docker was **not installed**.

---

## 1. Java server

Command:

```powershell
cd server
$env:JAVA_HOME="C:\path\to\jdk-25"
mvn test
```

Result:

```
AuthTenancyIT      Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
FlywayMigrationTest Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
FoundationIT       Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
TotpServiceTest    Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
MySqlMigrationIT   Tests run: 1, Failures: 0, Errors: 0, Skipped: 1
ArchitectureTest   Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
Total              Tests run: 16, Failures: 0, Errors: 0, Skipped: 1
BUILD SUCCESS
```

What passed:

- Technician cannot call `/api/v1/workshop/staff` or `/api/v1/platform/workshops` (403).
- Workshop Admin A cannot read Workshop B (`/api/v1/workshops/{B}` → 404).
- Workshop Admin A staff list contains only Workshop A (2 members; no B).
- Platform Admin can list workshops and read any workshop.
- Technician cannot read a workshop summary (404).
- Workshop Admin cannot use Platform Admin workshop detail (403) and can read their own workshop.
- `/api/v1/auth/me` returns only the caller’s membership.
- Refresh token rotation works; reusing the rotated token returns `401 AUTH_REFRESH_REUSED` and revokes the family.
- UUIDv7 round-trips through `BINARY(16)` and is 16 bytes in the database.
- Flyway migrates from empty and incrementally (target 1, then 2).
- Neutral `/r/unavailable` and `/r/{token}` expose no token/report data and set `noindex`, `no-referrer`, `no-store`.
- Health and `/v3/api-docs` are available.
- TOTP matches RFC 6238 SHA-1 vectors (8-digit and 6-digit) and rejects replay.
- Spring Modulith boundaries verify; ArchUnit controller→repository rule passes.

Skipped:

- `MySqlMigrationIT` — **skipped because Docker is not installed locally**. It is configured to run on CI with Testcontainers 2.0.5 and `mysql:8.4.13`.

---

## 2. Flutter

Command:

```powershell
cd client
flutter analyze --fatal-infos
cd apps/technician_app; flutter test
cd ../admin_app; flutter test
```

Result:

```
flutter analyze --fatal-infos
No issues found!

technician_app
+4: All tests passed!

admin_app
+3: All tests passed!
```

What passed:

- English sign-in shell renders at 390×844 with no overflow.
- Arabic sign-in shell renders RTL with no overflow.
- Language toggle changes the app direction to RTL.
- Technician role home renders in Arabic.
- Platform Admin role home renders in Arabic.
- Admin English/Arabic sign-in shells render without overflow.

---

## 3. Build checks

| Check | Result |
|---|---|
| `mvn -q -DskipTests package` | **PASS** — `target/truereport-server-0.2.0-SNAPSHOT.jar` produced |
| `flutter build web --release --dart-define-from-file=config/dev.json` (admin) | **PASS** — `build/web` produced |
| `flutter build apk` / iOS build | **NOT RUN** — no Android SDK/device or macOS in this environment |
| Docker Compose | **NOT RUN** — Docker is not installed |
| Testcontainers MySQL | **SKIPPED** — Docker is not installed |

The Flutter web build printed a non-fatal warning about an expected `CupertinoIcons` font asset. The build completed successfully. The generated app does not use `cupertino_icons` directly; this is a Flutter tooling warning, not a failure.

---

## 4. CI negative-control proof

These probes were created temporarily and deleted after the check.

### 4.1 Lint failure

Probe: a file containing `print('probe');`.

Command:

```powershell
flutter analyze --fatal-infos
```

Result:

```
info - Don't invoke 'print' in production code ... avoid_print
exit code 1
```

**Proven:** CI’s `flutter analyze --fatal-infos` fails on a deliberate lint violation.

### 4.2 Test failure

Probe: a test asserting `expect(1, 2)`.

Command:

```powershell
flutter test test/failure_probe_test.dart
```

Result:

```
Expected: <2>
  Actual: <1>
Some tests failed.
exit code 1
```

**Proven:** CI’s `flutter test` fails on a deliberate test failure.

### 4.3 Architecture failure

Probe: a `ProbeController` depending on `WorkshopRepository`.

Command:

```powershell
mvn -Dtest=ArchitectureTest test
```

Result:

```
ArchitectureTest.controllersDoNotAccessRepositoriesDirectly — Architecture Violation ...
ProbeController ... has parameter of type WorkshopRepository
Tests run: 2, Failures: 1, Errors: 0
BUILD FAILURE
exit code 1
```

**Proven:** the ArchUnit rule fails on a deliberate controller→repository dependency.

After deleting the probes, the normal Java and Flutter suites were re-run successfully.

---

## 5. Not verified

- Docker Compose startup and health (no Docker).
- MySQL 8.4 container migration (Testcontainers skipped locally; CI should run it).
- Real Android/iOS app run, camera, keyboard, or device-specific RTL.
- Real browser UI interaction; widget tests are headless.
- External authenticator app interoperability for TOTP.
- Production object storage, delivery providers, PDF/Chromium and public report content (later phases).
- Any legal/consent wording (Pending counsel).
---

## 6. Phase 3 Step 0 re-check

**Date:** 3 November 2026

Docker was checked again before Phase 3. It is still **not installed** (`docker` is not recognized). Therefore:

- `docker compose up --build` was **not run**.
- `MySqlMigrationIT` remains **skipped** locally.
- MySQL 8.4 container migrations remain **unverified locally**; the CI job is configured to run them on a Docker-enabled runner.

This is recorded as an open Phase 2/Phase 3 risk. No result is claimed for a command that was not executed.