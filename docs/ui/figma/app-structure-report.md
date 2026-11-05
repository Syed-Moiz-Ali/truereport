# App-structure report (F1.1, report only)

**Project:** TrueReport
**Date:** 5 November 2026
**Scope:** inspection and options only. **No restructuring was performed.**
**Decision needed:** one `admin_app` (A) or two admin apps (B). See section 7.

---

## 1. What exists today

### 1.1 One `admin_app` serves both admin roles

| Concern | Current behaviour | Evidence |
|---|---|---|
| Entry point | `ProviderScope(child: AdminApp())` | `client/apps/admin_app/lib/main.dart:5-8` |
| App root | `MaterialApp.router` with `adminRouterProvider` and `AppTheme.build` | `client/apps/admin_app/lib/app.dart:7-29` |
| Role guard | Redirects unauthenticated users to `/signin`; `platformAdmin` to `/platform`; `workshopAdmin` to `/workshop`; every other role to `/unauthorized` | `client/apps/admin_app/lib/src/admin_router.dart:15-31` |
| Workshop UI | `/workshop` -> `WorkshopAdminHomePage`; tabs Jobs / Staff / Templates | `admin_router.dart:38-41`; `lib/src/pages/workshop_admin_home.dart:10-127` |
| Platform UI | `/platform` -> `PlatformAdminHomePage`; tabs Hierarchy / Master content / Audit | `admin_router.dart:34-37`; `lib/src/pages/platform_admin_home.dart:10-127` |
| Sub-pages | Pushed imperatively (`Navigator.push`), not declared routes | `pages/jobs_tab.dart:180-230`; `pages/templates_tab.dart:136-169`; `pages/master_content_tab.dart:300-306` |
| Shared state | Riverpod providers for both roles in one file | `lib/src/admin_providers.dart:6-132` |
| Role derivation | Client: `platformAdmin` flag wins, else first membership role | `packages/domain/lib/src/session.dart:18-29` |
| Build targets | Android, iOS and web; web output copied to `infra/web/admin/` | `admin_app/pubspec.yaml`; `infra/web/admin/README.md:3-6`; `docs/phase-8/server-deployment.md:91` |
| Deployment | One Nginx SPA at `/` from `/usr/share/nginx/html`; one read-only mount | `infra/nginx/nginx.conf:85-89`; `infra/docker-compose.prod.yml:75` |
| Decision record | D2 approved one `admin_app` with role-based feature folders and server-enforced permissions | `docs/phase-1/13-adrs/0002-one-admin-app.md:19-26`; `docs/phase-1/00-decisions.md:51` |

**Observed gap vs ADR-0002:** the ADR asks for role-based feature folders; the code
uses one flat `lib/src/pages/` folder for both roles. The roles are separated by
the router and tabs only. There is no analyzer boundary preventing workshop UI
from importing platform UI.

### 1.2 Technician app

Single-role app at `client/apps/technician_app`. Its router only allows
`Role.technician` and routes `/jobs`, `/jobs/:id`, checklist, review, sync and
finalized screens (`lib/src/technician_router.dart:17-82`). It builds for
Android, iOS and web. It does not import the admin app.

### 1.3 Public report

The public report is server-rendered, not a Flutter app: Spring resources under
`server/src/main/resources/public-report/` and templates under
`server/src/main/resources/templates/report/`. It is served at `/r/**` and is
permitted without authentication (`SecurityConfig.java:92`).

### 1.4 `ui_gallery`

`client/apps/ui_gallery` is a developer-only workspace member
(`client/pubspec.yaml:10`, `client/apps/ui_gallery/README.md:1-3`). It is not
referenced by any product app, by `infra/`, by Nginx, by the production compose
file or by CI (`.github/workflows/ci.yml:25-33`).

**Guard added in F1.1:**
- `lib/fixture_guard.dart`: `FixtureGuard.enabled` is `false` in release builds
  unless `--dart-define=ALLOW_FIDELITY_FIXTURES=true` is supplied.
- `lib/main.dart`: a release build without the opt-in mounts `_ReleaseBlockedApp`
  and renders no fixtures.
- `test/release_guard_test.dart`: asserts the default is off, that product apps
  and infra do not reference `ui_gallery`, and that the entry guard exists.
- Fidelity sections are also hidden behind `if (FixtureGuard.enabled)`.

This is a technical guard in addition to the structural exclusion. It is not a
security boundary, but it prevents an accidental release gallery containing
Figma sample copy.

---

## 2. What the Figma implies per app

Frame sizes from the package manifests; radii, gaps and header heights measured
from the exported JSON.

| App | Figma frames | Target devices | Dominant radii | Header height | Common grid/gap | Button shape |
|---|---|---|---|---|---|---|
| Technician | 16 frames, all **390** wide (858-1362 high) | Phone (Android/iOS); web is a viewer | pill 9999, 32, 16, 24, 48 | 64 | 4/6/8/12/16 | pill |
| Workshop Admin | 12 frames, all **1280** wide (1024-1681 high) | **Web and mobile** (the owner wants both) | pill 9999, 16, 48, 24, 32 | 80 | 8/12/16/24 | pill |
| Platform Admin | 10 frames, all **1280** wide (1024-1544 high) | **Web** | pill 9999, 32, 16, 48 | 64 | 8/16/24/32 | pill |
| Public report | 4 mobile frames **390** wide + 3 desktop frames **1280** wide | Mobile web and desktop web | pill 9999, 32, 48 | 64 mobile / 80 desktop | 8/16/24/32 | pill |

**Design differences that matter:**

- **Large-card radius:** Technician and Workshop use 24 for compact cards and
  32/48 for large cards; Platform uses 32/48; public report uses 32/48. The
  shared `radii.card` (24) and `radii.cardLarge` (32) are both needed; the new
  `radii.sheet` (48) covers the large sheets/cards.
- **Header height:** Workshop 80; Technician, Platform and mobile public report
  64; desktop public report 80. `AdminTopBar` currently defaults to 64 and must
  be skinned per role if A is kept.
- **Grid gaps:** Technician 16, Workshop 24, Platform 16/32, public report
  16/32. A single 16 default is not exact for Workshop.
- **Button radius:** pill (9999) in all four designs; no change needed.
- **Content width:** all admin frames are 1280 wide; the existing
  `maxContentWidth` token (1280) matches.

---

## 3. Server authorization (security is not in the UI)

The server is authoritative. UI separation is a convenience only
(`ADR-0002:25-26`; `master.md:562,720`; `docs/phase-0/03-roles-and-permissions.md:294-298`).

Confirmed controls:

- JWT role claim is mapped to `ROLE_` authorities
  (`server/.../shared/security/SecurityConfig.java:63-71`).
- Path rules: `/api/v1/platform/**` -> `PLATFORM_ADMIN`;
  `/api/v1/workshop/**` -> `WORKSHOP_ADMIN`; `/api/v1/technician/**` ->
  `TECHNICIAN`; everything else authenticated (`SecurityConfig.java:93-96`).
- Representative method-level checks:
  `@PreAuthorize("hasRole('WORKSHOP_ADMIN')")` on `StaffController` and
  `@PreAuthorize("hasRole('PLATFORM_ADMIN')")` on `PlatformController`.
- Tenant and role checks in `WorkshopService` reject technicians and cross-tenant
  workshop admins (`WorkshopService.java:24-36`).
- Integration tests cover technician/workshop/platform separation
  (`AuthTenancyIT.java:15-83`; `WorkshopAdminIT.java:143-202`) and anonymous
  access to every non-public operation (`SecurityEndpointInventoryIT.java:17-50`).

Places where authorization is weaker or depends on configuration:

1. **`GET /api/v1/workshops/{id}` has no method-level role annotation.** It falls
   through to `anyRequest().authenticated()` and is protected only by
   `WorkshopService.getWorkshop` (`WorkshopController.java:26-30`). It is tested,
   but defense-in-depth is weaker than the role-prefixed APIs.
2. **Most controllers rely on URL-prefix rules, not per-method annotations.** A
   new controller mapped outside `/platform`, `/workshop` or `/technician` would
   silently become authenticated-only. Examples: `MasterContentController`,
   `PlatformHierarchyController`, `WorkshopJobController`,
   `WorkshopReportController`, `WorkshopTemplateController`.
3. **Delivery webhooks are `permitAll`** and rely on an HMAC secret
   (`SecurityConfig.java:90`; `DeliveryWebhookService.java:48-53`). The default
   secret is `change-me-local-only` and must be overridden in production
   (`infra/env/production.env.example:38`).
4. **`/actuator/prometheus` is `permitAll` at Spring level**
   (`SecurityConfig.java:91`); only Nginx restricts `/actuator/`
   (`infra/nginx/nginx.conf:43-49`). Production compose does not expose 8080,
   but dev compose does (`infra/docker-compose.yml:72-73`).
5. **Client/server role derivation differs subtly:** the server prefers a primary
   membership (`AuthService.java:334-339`), the client uses the first membership
   (`session.dart:22-25`). Multiple-membership users can be routed to a home the
   token no longer authorizes.

None of these changes with option A or B. The recommendation is to add
method-level annotations or an ArchUnit/OpenAPI check regardless.

---

## 4. Option A - keep one `admin_app`

Two role shells and two skins in one codebase. This is the current direction
(D2).

**Work**
1. Keep `admin_router.dart` role redirects.
2. Introduce `WorkshopAdminSkin` and `PlatformAdminSkin` (tokens only):
   Workshop header 80, large-card 48, grid gap 24; Platform header 64,
   large-card 32, gap 16/32.
3. Split `lib/src/pages/` into `workshop/` and `platform/` folders and add an
   import-boundary test (e.g. a source scan that forbids cross-folder imports).
4. Add an `AdminShell` variant per skin; keep one `AdminTopBar` with a height
   parameter.
5. Add router redirect tests for all three roles (currently missing).

**Cost:** low-to-medium. No new packages, releases, domains, CI jobs,
Dockerfiles or Nginx servers. One web build and one Nginx SPA.

**Risk:** the release web bundle contains both roles' UI (dead code for each
user); the skins must be kept in sync with two Figma files; a code-split is not
possible without a route-level lazy-loading layer; the bundle grows with every
admin screen.

**When it is the right choice:** one domain, one release cadence, a small team,
and no requirement to ship Workshop mobile and Platform web independently.

---

## 5. Option B - split into two admin apps

`workshop_admin_app` (web and mobile) and `platform_admin_app` (web), sharing
`design_system`, `domain`, `api_client`, `auth`, `core` and `l10n` through the
Melos workspace.

**Work**
1. Create two app packages from the current `admin_app`; move the workshop pages
   and providers to one and the platform pages/providers to the other.
2. Split `AdminApi`/providers so each app only imports the endpoints it uses.
3. Build two routers: Workshop (`/signin`, `/workshop`, `/unauthorized`) and
   Platform (`/signin`, `/platform`, `/unauthorized`).
4. Split tests, golden suites and CI jobs; add two web builds and (for Workshop)
   the Android/iOS targets.
5. Add two Nginx server blocks/domains and two `infra/web/*` mounts; update
   `docker-compose.prod.yml`, deployment docs and CORS origins.
6. Update ADR-0002 or replace it with a new ADR.
7. Keep the technician app and public report unchanged.

**Cost:** medium-to-high. New packages, routes, tests, CI, Docker/Nginx, domains,
release notes and docs. Two bundles to keep on the same design-token version.

**Risk:** duplicated shell/route/provider code; two releases to coordinate; two
domains/CORS entries; migration churn in the middle of F2-F5; the server role
model is unchanged, so the split does not improve security.

**When it is the right choice:** independent Workshop mobile and Platform web
releases, separate customers/domains, bundle-size or compliance pressure, or two
teams owning the two admin surfaces.

---

## 6. Recommendation

**Keep Option A for F1.1 through F5.** It preserves D2, needs no server, route or
deployment change, and lets F2-F5 focus on fidelity. Add the role skins and the
folder boundary now; they are the expensive part of B anyway.

**Re-open B only when one of these is true:** Workshop mobile and Platform web
need separate release cadences or domains; the admin web bundle becomes a
measured problem; or two teams own the surfaces. If B is chosen, it should be a
dedicated phase, not folded into a UI fidelity batch.

---

## 7. Migration steps (exact, for the chosen option)

### A. Keep one app

1. Create `lib/src/pages/workshop/` and `lib/src/pages/platform/`; move the
   existing pages and tabs; update imports only.
2. Add `AdminSkin` records for both roles (header height, card radius, grid gap,
   content padding) in `design_system` or in the admin app.
3. Wire `WorkshopAdminHomePage` and `PlatformAdminHomePage` to their skins.
4. Add a source-scan test that forbids `pages/platform/**` importing
   `pages/workshop/**` and vice versa.
5. Add `admin_router` redirect tests: no session -> `/signin`;
   platform -> `/platform`; workshop -> `/workshop`; technician -> `/unauthorized`.
6. Run `flutter analyze --fatal-infos`, admin tests, web build and
   `flutter build apk --debug`.

### B. Split apps

1. Create `client/apps/workshop_admin_app` and
   `client/apps/platform_admin_app`; add both to the workspace
   (`client/pubspec.yaml`).
2. Move the workshop pages/providers/API methods and the platform pages/
   providers/API methods; delete the combined `admin_app`.
3. Add two routers and two `app.dart` roots; keep the shared `auth` package.
4. Split tests and goldens; add both apps to CI.
5. Add two web build outputs under `infra/web/workshop-admin` and
   `infra/web/platform-admin`; add Nginx server blocks/domains and update
   `docker-compose.prod.yml` and CORS.
6. Add the Workshop Android/iOS build targets and release signing.
7. Update ADR-0002, the deployment doc, the README and the risk register.
8. Run both analyze/test/build matrices before switching DNS.

**No restructuring was performed in F1.1.**
