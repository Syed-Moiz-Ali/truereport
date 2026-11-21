# Browser harness — generation provenance

Generated 2026-11-20. No value below was invented; each is either read from code or explicitly marked `INFERRED`.
**Execution status:** `npx playwright test --list` discovers **18 tests in 6 files**. The suite was **not executed** in
this pass at the user's request; pass/fail runtime evidence in this audit is HTTP/API, not Playwright. The harness is
ready to run with the commands below. The harness lives at the repository root:

```
playwright.config.ts
package.json
tests/e2e/apps.ts
tests/e2e/auth.ts
tests/e2e/flutter.ts
tests/e2e/static-server.js
tests/e2e/fixtures/jobs.ts
tests/e2e/modules/auth.flow.spec.ts
tests/e2e/modules/platform_admin.flow.spec.ts
tests/e2e/modules/workshop_jobs.flow.spec.ts
tests/e2e/modules/technician.flow.spec.ts
tests/e2e/modules/public_report.flow.spec.ts
tests/e2e/cross-app/job_to_technician.flow.spec.ts
```

## Values and their sources

| Value | Used in | Derived from | Confidence |
|---|---|---|---|
| Apps: platform_admin, workshop_admin, technician | `apps.ts` | `client/pubspec.yaml` workspace; `client/apps/*` | CONFIRMED |
| Public viewer is server-rendered, not an app | `public_report.spec.ts` | `reports/api/PublicReportController`, `templates/report/*` | CONFIRMED |
| Build dirs `client/apps/<app>/build/web` | `playwright.config.ts` | `flutter build web` output | CONFIRMED |
| Ports 5301/5302/5303 | `apps.ts`, `playwright.config.ts` | chosen for the audit; no port is fixed in the repo | INFERRED (harness-owned) |
| API base `http://localhost:8080` | `apps.ts` | `server/src/main/resources/application.yml` `${SERVER_PORT:8080}` | CONFIRMED |
| Platform home `/workshops` | `apps.ts` | observed post-login URL in the built app (router redirect) | CONFIRMED (runtime) |
| Workshop home `/workshop` | `apps.ts` | `admin_router.dart:49` | CONFIRMED |
| Technician home `/jobs` | `apps.ts` | `technician_router.dart:72` | CONFIRMED |
| Sign-in labels `Email`, `Password`, `Sign in` | `auth.ts` | `app_en.arb` `emailLabel/passwordLabel/signInButton`; runtime semantics | CONFIRMED |
| Flutter semantics boot | `flutter.ts` | `flt-semantics-placeholder` "Enable accessibility"; Flutter web engine | CONFIRMED (runtime) |
| Seed user emails | `apps.ts` | `dev/DevDataInitializer.java:60-72` | CONFIRMED |
| Passwords | env only | `infra/.env` `DEV_SEED_PASSWORD` (never committed) | CONFIRMED |
| Job create payload | `fixtures/jobs.ts` | `WorkshopJobDtos.CreateJobRequest`; `wizard_form_state.dart` | CONFIRMED |
| Template selection | `fixtures/jobs.ts` | `GET /workshop/template-versions/available` | CONFIRMED |
| Technician assignment | `fixtures/jobs.ts` | `GET /workshop/staff` role `TECHNICIAN` | CONFIRMED |
| Queue card accessible name = reference + vehicle | `flutter.ts` | runtime semantics tree of the built technician app | CONFIRMED (runtime) |
| Cross-app window 10 s | `cross-app/job_to_technician.flow.spec.ts` | no push channel; contract declared by this audit | INFERRED (product contract) |
| Arabic label `العربية` | `platform_admin.flow.spec.ts` | `/api/v1/i18n/languages` response | CONFIRMED |

## Environment contract

- `E2E_PASSWORD` (or per-app `E2E_PLATFORM_PASSWORD`, `E2E_WORKSHOP_PASSWORD`,
  `E2E_TECHNICIAN_PASSWORD`) is required. The harness never stores credentials.
- `E2E_API_URL` defaults to `http://localhost:8080`.
- `E2E_PUBLIC_REPORT_TOKEN` (optional) and `E2E_PUBLIC_VEHICLE_MAKE` enable the active-report assertion. Without a
  token that test is **skipped with a reason**, never passed.
- Staging/local only. The harness refuses to encode production URLs.

## Run

```powershell
# 1. builds (already produced for this audit)
cd client/apps/platform_admin_app; flutter build web --release --no-pub --dart-define=API_BASE_URL=http://localhost:8080
cd ../workshop_admin_app;       flutter build web --release --no-pub --dart-define=API_BASE_URL=http://localhost:8080
cd ../technician_app;           flutter build web --release --no-pub --dart-define=API_BASE_URL=http://localhost:8080
cd ../../..

> Flutter web registers a service worker. After a rebuild, an **already-open tab** can keep
> serving the old bundle (this looks like "the fix didn't work"). Hard reload
> (`Ctrl+Shift+R`) or unregister the service worker once. For local harness builds you can
> also add `--pwa-strategy=none` to the three `flutter build web` commands.

# 2. server (needs MySQL + Flyway + dev seed)
cd server; mvn -q -DskipTests spring-boot:run
cd ..

# 3. harness
# Optional interactive MCP (separate from the spec runner):
#   opencode mcp add playwright -- npx -y @playwright/mcp
npm install
npx playwright install chromium
$env:E2E_PASSWORD = (Get-Content infra/.env | Where-Object { $_ -match '^DEV_SEED_PASSWORD=' }).Split('=',2)[1]
npx playwright test --list          # discovery gate
npx playwright test                 # all apps + public
```

Playwright starts the three static servers if they are not already running; `reuseExistingServer` keeps a manual
server. The Spring server is external and must be healthy before the run.

## Known harness limitations (recorded, never hidden)

| Limitation | Reason | Status |
|---|---|---|
| Active public report assertion requires `E2E_PUBLIC_REPORT_TOKEN` | The suite does not mint a token; the audit verified one via HTTP (`GET /r/{token}` 200, PDF 200) | NOT RUN (token optional) |
| Full inspection completion (30 items × photo/video evidence) is API-driven, not UI-driven | Real camera capture needs getUserMedia fake-device flags; the audit seeded evidence via the API | UNVERIFIED with reason |
| Arabic registry assertion | Platform registry is intentionally manifest-backed/English-only; the test asserts English registry + visible `ar` coverage | Covered (MINOR-08) |

## Discovery validation

`npx playwright test --list` must list every spec. The list is captured in the run report; a missing spec fails the
harness gate.
