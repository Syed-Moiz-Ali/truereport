# Flow — Platform Admin (workshops, staff, master library, languages, audit)

Scope: `client/apps/platform_admin_app` + `platform`/`masterdata`/`localization`/`audit` backend modules.

## A. Create and manage a workshop

1. Platform Admin opens `/workshops` → `features/workshops/workshops_screen.dart`.
2. "New" opens `/workshops/new` → `workshop_form.dart` (name, branch/location, contact email).
3. Submit calls `registerWorkshop` → `client/apps/platform_admin_app/lib/src/platform_api.dart:97`.
4. `POST /api/v1/platform/workshops` with `Idempotency-Key` → `server/.../localization/api/PlatformWorkshopController.java:41`.
5. `PlatformWorkshopService.create` inserts the workshop + audit (`WORKSHOP_REGISTERED`) →
   `localization/PlatformWorkshopService.java:51-76`.
6. UI invalidates hierarchy and returns to the list; row appears after refetch.
7. Edit uses `PUT /platform/workshops/{id}`; deactivate/reactivate use their POST endpoints; both audited.
8. Staff are managed from the workshop detail tabs → `POST /platform/users`,
   `POST /platform/users/{id}/disable|reactivate|transfer`, `POST /platform/users/{id}/password-reset`
   (`identity/api/PlatformHierarchyController.java:64-110`).

Branches: duplicate email is a neutral `EMAIL_EXISTS` (idempotent create); last-admin guards prevent removing the
final workshop admin; cross-workshop IDs return neutral 404. Server tests: `PlatformHierarchyIT`,
`PlatformAdminPhase1IT`, `AdminPasswordOnlyIT`.

## B. Master library: create/publish an item

1. `/checklist/items` → `features/master_library/master_library_screen.dart`.
2. "New item" → `/checklist/items/new` → `master_item_editor_screen.dart`.
3. `POST /api/v1/platform/master/items` (stable code + category + metadata) →
   `masterdata/api/MasterContentController.java:74`.
4. Draft version: `POST /platform/master/items/{id}/versions` (`:86`).
5. Translations: `PUT .../versions/{versionId}/translations/{locale}` (`:91`).
6. Rules/bands/evidence/issue fields: `PUT .../rules`, `/config`, `/bands` (measurement bands), `/evidence-rules`,
   `/issue-fields` (`PlatformMasterConfigController`, `PlatformMasterConfigController.java:...`).
7. Publish: `POST .../versions/{versionId}/publish` (`:109`). Publication freezes the version; content activation gate
   may hold it for review (`ContentActivationGateIT`).
8. Published version becomes selectable in the workshop catalog (`/workshop/master/items`).
9. Retire: `POST /platform/master/items/{id}/retire` (`:116`).

Branches: missing EN/AR translations block publish; duplicate stable code is rejected; an unpublished/held version
is invisible to workshops; retire does not delete history. Server tests: `MasterContentIT`,
`PlatformTemplateCategoryIT`, `PlatformContentMigrationTest`.

## C. Option sets, reasons, equipment, document types

- Option sets: `/platform/master/option-sets` CRUD + values + retire (`PlatformOptionSetController`).
- Reasons/equipment/guide images: `/platform/master/{reasons,equipment,guide-images}`.
- Document types: `/platform/document-types` + reorder (`PlatformDocumentTypeController`).
- All writes are `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`; workshop reads are separate endpoints.

## D. Languages and dynamic UI text

1. `/settings/languages` → `features/languages/languages_screen.dart`.
2. List uses `GET /api/v1/platform/i18n/languages`; coverage uses `GET /platform/i18n/coverage`.
3. Language workspace (`language_workspace_screen.dart`) edits translations via
   `PUT /api/v1/platform/i18n/translations`.
4. Readiness/backlog: `GET /platform/i18n/languages/{code}/readiness|backlog`.
5. UI messages are JSON catalogs synchronized at boot (`StaticLanguageSync`), served by
   `GET /api/v1/i18n/ui-messages/{manifest,bundle}` (`uimessages/api/UiMessageController`).

Branches: publishing a language without complete coverage is blocked; `en` is the default/fallback; RTL is
direction-driven. Server tests: `DynamicLanguageContentIT`, `PlatformUiMessagesIT`,
`PlatformUiMessagesCompressionIT`.

## E. Audit and config health

1. `/audit-log` → `features/audit/audit_log_screen.dart`.
2. `GET /api/v1/platform/audit-events` (filtered) and `.../export` →
   `identity/api/PlatformHierarchyController.java:111,134`.
3. `/checklist/health` → `GET /api/v1/platform/config-health` and `/{entityType}`; impact analysis uses
   `GET /platform/master/{entityType}/{id}/impact`; releases use `/platform/releases`.
4. Every write above records an audit event; tests assert actor/entity/action.

## Known branch gaps (see `docs/flow_gaps.md`)

- No Platform UI for `/platform/deliveries` even though the endpoint exists.
- No 2FA challenge screen in any app although the server enforces/supports TOTP.
- Platform templates API exists but has no screen (intentional under D-071; recorded, not a blocker).
