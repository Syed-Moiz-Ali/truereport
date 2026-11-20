# Discovery — TrueReport workspace

Generated 2026-11-20. Read-only inventory; no app was excluded without evidence.

## 1. Workspace shape

- **Monorepo root**: `E:\syed_moiz_ali\bitlogix\truereport`.
- **Client**: Dart pub workspace (`client/pubspec.yaml` `workspace:`) managed by Melos 8.10.0; no `melos.yaml` at
  root, scripts live under `pubspec.yaml` `melos:`.
- **Server**: Spring Boot 4.1.2, Java 25 (`server/pom.xml`), Maven 3.9.16, MySQL 8.4 target, Flyway.
- **Infra**: `infra/docker-compose*.yml`, nginx, Prometheus/Grafana, backup scripts.
- **No customer portal / mobile customer app** in the repo. The only anonymous surface is the server-rendered report.

## 2. Apps found

| App | Path | Product? | Routes / entry | Notes |
|---|---|---|---|---|
| Platform Admin | `client/apps/platform_admin_app` | yes | `lib/src/platform_router.dart` | Dashboard, workshops, checklist, reports/document types, settings/languages, audit |
| Workshop Admin | `client/apps/workshop_admin_app` | yes | `lib/src/admin_router.dart` (signin + single `/workshop` shell) | Jobs/templates/staff/reports/settings live inside the shell tabs, not URL routes |
| Technician | `client/apps/technician_app` | yes | `lib/src/technician_router.dart` | jobs, workspace, item, summary, signature, completed, sync, profile |
| UI Gallery | `client/apps/ui_gallery` | no | no router (`lib/support` only) | Design-system showcase; excluded from flow parity |

All three product apps use GoRouter + Riverpod and share `packages/api_client`, `packages/auth`, `packages/domain`,
`packages/design_system`, `packages/l10n`, `packages/offline_sync`.

## 3. Backend

- **In this repo**: yes — `server/`.
- Modules (Java packages): `identity`, `tenancy`, `masterdata`, `templates`, `jobs`, `technician`, `inspections`,
  `reports`, `documents`, `delivery`, `localization`, `uimessages`, `audit`, `governance`, `seed`, `shared`.
- **API surface**: 33 `*Controller` classes with 209 mapping annotations. The canonical generated inventory is
  `docs/phase-8/openapi-endpoints.md` (105 operations at Phase 8) and is **stale**: it predates the clean job API,
  document types, option sets, i18n UI messages, notifications, config health/releases and public-link QR.
  Derived endpoint families:
  - `/api/v1/auth/**` (9)
  - `/api/v1/platform/**` (workshops, hierarchy, users, master, option-sets, templates, document-types, i18n,
    audit-events, overview, deliveries, governance, seed)
  - `/api/v1/workshop/**` (master read, templates, clean jobs + review/approve/publish/documents/notifications,
    legacy jobs)
  - `/api/v1/technician/**` (clean jobs + checklist/assessment/evidence/signature/complete/sync; legacy jobs)
  - `/api/v1/i18n/**` (languages, me, ui-messages)
  - `/api/v1/delivery/webhooks/{provider}`
  - public `/r/{token}`, `/r/{token}/photo/{id}`, `/r/{token}/pdf`, `/r/unavailable`
- **DB**: 26 active migrations under `db/migration` (MySQL/H2 portable) + 7 MySQL-only migrations under
  `db/migration-mysql` (triggers, PII, template FK, snapshot column widths). Legacy migrations archived under
  `db/archive/v1`.
- **Tests**: 14 `*Test.java` + 30 `*IT.java` in `server/src/test` (unit, H2 integration, MySQL Testcontainers).

## 4. Client features

| App | Feature folders |
|---|---|
| platform_admin | `auth`, `dashboard`, `workshops`, `master_library`, `catalogues`, `equipment`, `documents`, `languages`, `audit`, `governance`, `settings` |
| workshop_admin | `auth`, `home`, `dashboard`, `jobs`, `templates`, `staff`, `reports`, `settings` |
| technician | `auth`, `jobs`, `inspection`, `review`, `sync`, `profile` |

Client tests: technician 31, workshop_admin 47, platform_admin 33 Dart test files. One Dart "live e2e" harness exists
(`platform_admin_app/test/e2e/platform_admin_live_e2e_test.dart`) but it is a widget test, not a browser suite, and is
gated behind `LIVE_E2E=1`.

## 5. Runtime configuration

- Server: `http://localhost:8080`; `/actuator/health` currently returns **503** in dev because a health contributor
  (SMTP/MinIO) is down, while the app serves API traffic normally. Recorded as an environment finding, not a product gap.
- App API base URL: `ApiConfig` default is a developer tunnel
  (`https://56zk48dj-8080.inc1.devtunnels.ms`), overridable with `--dart-define=API_BASE_URL=...`.
  `technician_app/config/dev.json` points at the tunnel; `workshop_admin_app/config/dev.json` at localhost.
- Web builds are path-URL based (`configureWebUrlStrategy`), so a static server must rewrite unknown paths to
  `index.html` (`docs/WEB_URL_STRATEGY.md`).
- Local audit environment: installed MySQL on 3306 rejected the repo's `.env` credentials, so the audit started a
  disposable MySQL 8.0 instance on **port 3307** with a fresh data dir and ran all 36 migrations. This is an audit
  fixture, not a repository change.

## 6. What was NOT found

- No Playwright config, no `tests/e2e` tree, no browser CRUD/cross-app specs.
- No customer app, no payment tables/endpoints, no correction UI/report v2.
- No production delivery provider (fake WhatsApp/SMS + SMTP only).
- No `melos.yaml`; README references `apps/admin_app`, which does not exist (it is `workshop_admin_app`).
