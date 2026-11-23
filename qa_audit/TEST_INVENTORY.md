# Test Inventory — TrueReport

Generated from source routes, OpenAPI (`/v3/api-docs`) and live UI. Counts are exact where a source of truth exists and labelled where estimated.

## 1. Applications

| App | Build | Port | Role gate | Routes |
|---|---|---|---|---|
| Platform Admin (Flutter web) | `client/apps/platform_admin_app/build/web` | 5301 | **none in client** | 20 functional + 13 legacy redirects |
| Workshop Admin (Flutter web) | `client/apps/workshop_admin_app/build/web` | 5302 | `session.role == WORKSHOP_ADMIN` | 3 routes; 5 shell sections |
| Technician (Flutter web) | `client/apps/technician_app/build/web` | 5303 | `session.role == TECHNICIAN` | 11 routes |
| Public report (server HTML) | Spring `PublicReportController` | 8080 | token only | `/r/{token}`, `/r/unavailable` |
| API | Spring Boot modular monolith | 8080 | JWT + `@PreAuthorize` | 189 paths / 225 operations |

## 2. Platform Admin screens (20)

| # | Screen | Route | Role | API | CRUD | Status |
|---|---|---|---|---|---|---|
| P1 | Sign in | `/signin` | public | `POST /auth/login` | — | PASS (valid, invalid, empty validation) |
| P2 | Dashboard | `/dashboard` | PLATFORM_ADMIN | `/platform/overview` | R | PASS (7 KPIs match API) |
| P3 | Workshops | `/workshops` | PLATFORM_ADMIN | `/platform/hierarchy` | R | PASS (search/filter/detail) |
| P4 | New workshop | `/workshops/new` | PLATFORM_ADMIN | `POST /platform/workshops` | C | PARTIAL (render only; write not executed) |
| P5 | Workshop detail | `/workshops/:id` | PLATFORM_ADMIN | `/platform/workshops/{id}` | R/U | PASS (Overview/Staff/Activity; edit dialog) |
| P6 | Checklist items | `/checklist/items` | PLATFORM_ADMIN | `/platform/master/items` | R | PASS |
| P7 | New item | `/checklist/items/new` | PLATFORM_ADMIN | `POST /platform/master/items` | C | PARTIAL (render only) |
| P8 | Edit item | `/checklist/items/:id/edit` | PLATFORM_ADMIN | `/platform/master/items/{id}` | R/U | PASS (E2E item editor) |
| P9 | Categories | `/checklist/categories` | PLATFORM_ADMIN | `/platform/master/categories` | R | PASS |
| P10 | Option sets | `/checklist/option-sets` | PLATFORM_ADMIN | `/platform/master/option-sets` | R | PASS (statuses/enums tabs) |
| P11 | Config health | `/checklist/health` | PLATFORM_ADMIN | governance | R | PASS |
| P12 | Transitions | `/configuration/transitions` | PLATFORM_ADMIN | `/reference/transitions` | R | PARTIAL (render) |
| P13 | Translation review | `/configuration/translations` | PLATFORM_ADMIN | `/platform/i18n/content/review` | R/U | PASS (E2E) |
| P14 | Document types | `/reports/document-types` | PLATFORM_ADMIN | `/platform/document-types` | R | PARTIAL (render) |
| P15 | Settings | `/settings` | PLATFORM_ADMIN | — | R | PARTIAL (render) |
| P16 | Languages | `/settings/languages` | PLATFORM_ADMIN | `/platform/i18n/languages` | R/C/U | PASS (add + retire via E2E) |
| P17 | Language workspace | `/settings/languages/:code` | PLATFORM_ADMIN | readiness/backlog | R | PASS |
| P18 | Translation queue | `/settings/languages/:code/translations` | PLATFORM_ADMIN | content units | R/U | PASS (E2E) |
| P19 | Manual translations | `/settings/languages/:code/manual` | PLATFORM_ADMIN | content | R/U | PASS (E2E edit + restore) |
| P20 | Audit log | `/audit-log` | PLATFORM_ADMIN | `/platform/hierarchy/audit-events` | R | PARTIAL (render) |

Legacy redirects verified by the E2E suite: `/master-library*`, `/config-health`, `/document-types`, `/languages`, `/data-catalogues`, `/equipment`, `/configuration`, `/configuration/statuses|enums|dropdowns`, `/workshops/details`, `/workshops/register`, `/workshops/add-staff`.

## 3. Workshop Admin screens (11 surfaces)

| # | Screen | Route / section | Role | API | Status |
|---|---|---|---|---|---|
| W1 | Sign in | `/signin` | public | auth | PASS |
| W2 | Overview | `/workshop` → Overview | WORKSHOP_ADMIN | `/workshop/jobs/counts` | PASS (106 = 69+6+31) |
| W3 | Jobs | `/workshop` → Jobs | WORKSHOP_ADMIN | `/workshop/jobs` | PASS (filter/search/pagination) |
| W4 | Job detail | internal push | WORKSHOP_ADMIN | `/workshop/jobs/{id}` + review/report/documents | PASS (read + publication surface) |
| W5 | New job wizard | internal push | WORKSHOP_ADMIN | `POST /workshop/jobs` | NOT TESTED (UI); API create PASS |
| W6 | Staff | `/workshop` → Staff | WORKSHOP_ADMIN | `/workshop/staff` | PASS (list/filters); create NOT TESTED (avoids sending invites) |
| W7 | Templates | `/workshop` → Templates | WORKSHOP_ADMIN | `/workshop/templates` | PASS (2 templates) |
| W8 | Template editor | Details / Sequence / Publish | WORKSHOP_ADMIN | template endpoints | PASS (view); publish/retire NOT TESTED |
| W9 | Settings | `/workshop` → Settings | WORKSHOP_ADMIN | i18n | PASS |
| W10 | Notifications | internal push | WORKSHOP_ADMIN | `/workshop/notifications` | NOT TESTED |
| W11 | Unauthorized | `/unauthorized` | any non-admin | — | PASS |

## 4. Technician screens (11)

| # | Screen | Route | Role | API | Status |
|---|---|---|---|---|---|
| T1 | Sign in | `/signin` | public | auth | PASS |
| T2 | Job queue | `/jobs` | TECHNICIAN | `/technician/jobs` | PASS (day strip, filters, pagination) |
| T3 | Job workspace | `/jobs/:id` (URL not updated) | TECHNICIAN | checklist | PASS |
| T4 | Item assessment | `/jobs/:id/items/:itemCode` | TECHNICIAN | `PUT .../items/{code}` + evidence | PARTIAL (evidence config blocks; PNG defect) |
| T5 | Summary | `/jobs/:id/summary` | TECHNICIAN | `/summary` | PARTIAL (API PASS, UI not visited) |
| T6 | Signature | `/jobs/:id/signature` | TECHNICIAN | `POST /signature` | PARTIAL (API PASS, UI not visited) |
| T7 | Completed | `/jobs/:id/completed` | TECHNICIAN | complete | NOT TESTED (UI) |
| T8 | Sync | `/sync` | TECHNICIAN | `/sync` | NOT TESTED |
| T9 | Sync conflict | `/sync/conflicts/:id` | TECHNICIAN | sync | NOT TESTED |
| T10 | Profile | `/profile` | TECHNICIAN | — | PASS |
| T11 | Unauthorized | `/unauthorized` | any non-technician | — | PASS |

## 5. API inventory

- **189 paths, 225 operations**, 31 controllers.
- Largest: workshop-job-admin (26), master-content (24), reference (16), technician-inspection (15), platform-template (12), platform-master-config (12), workshop-template (11), platform-option-set (10).
- **95 GET operations** contract-swept by `tests/e2e/api/sweep.spec.ts` (first run: 200×63, 400×3, 404×25, 409×2, 422×2, **0 × 5xx**).
- **50 operations** behaviour-tested directly by this audit (enumerated in `API_AUDIT.md` §2).

## 6. Roles and identities

| Role | Account | Membership | Observed JWT role | Notes |
|---|---|---|---|---|
| Platform Admin | `platform@truereport.test` | none | PLATFORM_ADMIN | expected |
| Workshop Admin A | `admin.a@truereport.test` | Workshop A | WORKSHOP_ADMIN | expected |
| Workshop Admin B | `admin.b@truereport.test` | Workshop B | **PLATFORM_ADMIN** | **deviation** — DB `platform_admin=1` (BUG-003) |
| Technician A | `tech.a@truereport.test` | Workshop A | TECHNICIAN | expected |
| Manual technician | `tech.test@gmail.com` | — | — | **does not exist** (401; BUG-019) |
| Anonymous | — | — | — | 401 everywhere protected |

## 7. Workflows discovered

1. **Inspection lifecycle:** job create → assign → technician photo → assess 30 items + evidence → signature → complete → admin review → approve → publish → public report → PDF/documents.
2. **Workshop/staff management:** workshop create → invite admin → staff invite/disable → transfer.
3. **Master content → template → job:** categories/items/option sets → template draft → publish → available to workshop → pinned job checklist.
4. **Localization:** language register → translate → review → activate → client manifest → UI language switch.
5. **Audit/governance:** every mutation → audit event → audit log/export.
6. **Delivery:** publish → delivery channels/attempts/webhooks (only contract-tested).

## 8. Coverage counters

| Metric | Count |
|---|---|
| Modules discovered | 19 backend modules / 3 client apps |
| Modules tested (behaviour) | 9 |
| Screens discovered | 42 (20 + 11 + 11) |
| Screens verified in a real browser | 36 (20 platform + 9 workshop + 7 technician; controlled sweep + manual) |
| Screens with behaviour-level tests | 29 |
| Screens not tested | 6 (workshop new-job wizard, workshop notifications, technician summary/signature/completed/conflict UI) |
| API operations discovered | 225 |
| API operations contract-swept | 95 (GET) |
| API operations behaviour-tested | 50 |
| Roles tested | 4 + anonymous |
| Permission combinations tested | 13 matrix cells + 4 tenant-isolation checks |
| Cross-module workflows executed end-to-end | 2 (inspection lifecycle, localization publish→manifest) |
| Automated browser tests executed | 41 (repo suite) + 73 API + 24 workflow steps |
