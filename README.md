# TrueReport — Phase 3 Platform Admin Foundation

TrueReport is a B2B partner-workshop vehicle inspection platform. This repository currently contains the **Phase 2 foundation and Phase 3 Platform Admin hierarchy/master content**:

- Java Spring Boot modular monolith with MySQL 8.4/Flyway, authentication, rotating refresh tokens, roles, workshop membership, tenant enforcement, RFC 9457 errors, OpenAPI, audit events and UUIDv7 `BINARY(16)`.
- Platform Admin hierarchy: searchable/filterable workshop tree, account invite/create/disable/reactivate/transfer and audit history.
- Master content library: categories, versioned inspection items, EN/AR (+ optional RU/ZH-Hans) translations, rules, reasons, equipment, dropdowns and guide images with alt text.
- Flutter workspace with technician and admin apps, English/Arabic localization, RTL shell, design tokens, sign-in, role-based home shells and Platform Admin management screens.
- Neutral `/r/unavailable` server page.
- Local Docker Compose for MySQL, MinIO (local only), Mailpit and the server.
- CI for Flutter analyze/test, Java/Testcontainers/Modulith/ArchUnit, and secret scanning.

**No Phase 4+ feature is implemented.** There is no workshop template builder, technician inspection/checklist, PDF, public report content, delivery provider, customer app/portal, manager/review queue, correction UI/API or payment feature.

---

## 1. Prerequisites

| Tool | Version |
|---|---|
| Java | 25 (Temurin 25.0.5+8 used for verification) |
| Maven | 3.9.16 |
| Flutter | 3.47.9 (Dart 3.13.7) |
| Docker Desktop / Docker Engine + Compose | For local infrastructure and Testcontainers |
| Git | Any current version |

The Phase 2/3 verification environment did **not** have Docker installed. Compose and the MySQL Testcontainers test could not be run locally; they are configured for CI.

---

## 2. Local secrets

Copy the example file and fill local values. **Do not commit `.env`.**

```powershell
Copy-Item infra/.env.example infra/.env
# Edit infra/.env
```

Generate 32-byte base64 secrets:

```powershell
[Convert]::ToBase64String([byte[]](1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

Or with OpenSSL:

```bash
openssl rand -base64 32
```

Set:

- `JWT_SECRET` — base64 32-byte HMAC secret.
- `APP_ENCRYPTION_KEY` — base64 32-byte AES key for TOTP secrets.
- `DB_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `MINIO_ROOT_PASSWORD`.
- `DEV_SEED_ENABLED=true` and `DEV_SEED_PASSWORD` only for local development.

No real secrets are in source.

---

## 3. Run the server locally

### Option A — Docker Compose (recommended when Docker is available)

```powershell
cd infra
docker compose up --build
```

The server starts on `http://localhost:8080`. MySQL is on `3306`, MinIO on `9000/9001`, Mailpit UI on `8025`.

MinIO is **local development only**; it is archived and must not be used in production. D6 production object storage remains Pending.

### Option B — Maven against local MySQL

```powershell
cd server
$env:JAVA_HOME="C:\path\to\jdk-25"
$env:DB_URL="jdbc:mysql://localhost:3306/truereport?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=utf8"
$env:DB_USER="truereport"
$env:DB_PASSWORD="your-local-password"
$env:JWT_SECRET="base64-32-byte-secret"
$env:APP_ENCRYPTION_KEY="base64-32-byte-key"
$env:DEV_SEED_ENABLED="true"
$env:DEV_SEED_PASSWORD="local-only-password"
mvn spring-boot:run
```

### Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /actuator/health` | Health |
| `GET /v3/api-docs` | OpenAPI JSON |
| `GET /swagger-ui.html` | Swagger UI |
| `POST /api/v1/auth/login` | Sign in |
| `POST /api/v1/auth/refresh` | Rotate refresh token |
| `POST /api/v1/auth/2fa/verify` | TOTP challenge |
| `GET /api/v1/auth/me` | Current user and memberships |
| `GET /api/v1/workshops/{id}` | Workshop visible to the caller |
| `GET /api/v1/workshop/staff` | Workshop Admin staff list |
| `GET /api/v1/platform/workshops` | Platform Admin workshop list |
| `GET /r/unavailable` | Neutral public page |
| `GET /r/{token}` | Neutral 404 page; real report is Phase 6 |

### Development users (only when seeding is enabled)

| Email | Role |
|---|---|
| `admin.a@truereport.test` | Workshop Admin, Workshop A |
| `tech.a@truereport.test` | Technician, Workshop A |
| `admin.b@truereport.test` | Workshop Admin, Workshop B |
| `platform@truereport.test` | Platform Admin |

Passwords come from `DEV_SEED_PASSWORD`; they are not logged.

---

## 4. Run the Flutter apps

```powershell
cd client
flutter pub get
cd packages/l10n
flutter gen-l10n
cd ../..
```

Analyze and test:

```powershell
flutter analyze --fatal-infos
cd apps/technician_app
flutter test
cd ../admin_app
flutter test
```

Run the technician app:

```powershell
cd client/apps/technician_app
flutter run --dart-define-from-file=config/dev.json
```

Run the admin app (web):

```powershell
cd client/apps/admin_app
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Environment files: `config/dev.json`, `config/staging.json`, `config/prod.json`. The production URL is a placeholder; it must be replaced with the approved domain before a production build.

The sign-in screen uses the server API. Workshop Admin home remains a foundation placeholder; Platform Admin has hierarchy and master-content management screens.

---

## 5. Test commands

### Java

```powershell
cd server
mvn test
```

This runs:

- unit tests,
- Spring context/H2 integration tests,
- Flyway from empty and incremental migrations,
- cross-workshop and role tests,
- UUIDv7 `BINARY(16)` round-trip,
- refresh rotation/reuse,
- neutral public page,
- ArchUnit and Spring Modulith boundary checks,
- `MySqlMigrationIT` (Testcontainers) when Docker is available; otherwise skipped.

### Flutter

```powershell
cd client
flutter analyze --fatal-infos
cd apps/technician_app; flutter test
cd ../admin_app; flutter test
```

Widget tests cover English/Arabic sign-in shells, RTL direction, role home shells and the Platform Admin hierarchy/master/audit screens at phone width.

### CI

`.github/workflows/ci.yml` runs Flutter analyze/test, Java build/test with Testcontainers, Modulith/ArchUnit and gitleaks. The Java job uses a GitHub runner with Docker, so the MySQL Testcontainers test is expected to run there.

---

## 6. Repository layout

```
docs/                 Phase 0/1/2/3 documents and ADRs
server/               Spring Boot modular monolith
client/               Flutter pub workspace (Melos)
  apps/technician_app
  apps/admin_app
  packages/core
  packages/design_system
  packages/l10n
  packages/api_client
  packages/domain
  packages/auth
  packages/offline_sync
infra/                docker-compose.yml, .env.example
spikes/               Isolated Phase 1 spikes; never production code
```

---

## 7. Security notes

- Tenant isolation is enforced in the server, not by hiding Flutter screens.
- Finalized findings are Phases 5/6 work; the design and immutability controls remain in `docs/phase-1/07-database-design.md`.
- No payment tables or endpoints exist.
- MinIO is local-only. Production object storage is behind a provider-neutral `ObjectStorage` interface; D6 remains Pending.
- The public report is not implemented; `/r/*` is neutral and exposes no data.
- TOTP is implemented in the auth module with replay protection; recovery is not production-ready.
- Report all security issues through the process defined by the project owner. Do not put customer data in tickets or logs.

---

## 8. Known limitations of this Phase 2/3 verification

- Docker was unavailable locally; Compose and MySQL Testcontainers were not executed.
- The Testcontainers MySQL test is present but skipped without Docker.
- No real Android/iOS device or web browser UI run was performed; Flutter widget tests ran headlessly.
- The TOTP implementation is unit-tested against RFC 6238 vectors but not with an external authenticator app.
- No production object storage, delivery provider, PDF engine or public report implementation is included.
- The `master.md` v0.3 revision applies only approved decisions; D6/D7/D8/D11 and legal consent wording remain Pending.

See `docs/phase-2/version-lock.md`, `docs/phase-2/master-v0.3-changes.md`, `docs/phase-3/` and the Phase 1 docs for the full rationale.
