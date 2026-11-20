# Flow — Workshop templates

Scope: `client/apps/workshop_admin_app` Templates tab + `templates` backend module.

## Happy path

1. Workshop Admin opens the Templates tab → `client/apps/workshop_admin_app/lib/src/features/templates/templates_tab.dart`.
2. The catalog loads `GET /api/v1/workshop/templates` (`admin_api.dart:831`) and published version options via
   `GET /api/v1/workshop/templates/versions` (`:982`).
3. "New template" opens `template_create_page.dart`; submit calls `createTemplate` (`admin_api.dart:844`) →
   `POST /api/v1/workshop/templates` → `templates/api/WorkshopTemplateController.java:45`.
4. Server creates the template + first draft (`WorkshopTemplateService`), returns `TemplateDetailDto`.
5. The builder (`template_route_page.dart`, `template_details_step.dart`, `template_sequence_step.dart`) selects
   published master item versions from `GET /api/v1/workshop/master/items`.
6. Saving sends `PUT /api/v1/workshop/templates/{id}/draft` with ordered items (`admin_api.dart:862`) →
   `WorkshopTemplateController.java:62`.
7. Preview uses `GET /api/v1/workshop/templates/{id}/preview` (`:91`) and renders EN/AR content.
8. Publish calls `POST /api/v1/workshop/templates/{id}/publish` (`admin_api.dart:885`) → `:69`.
9. Published version appears in `GET /api/v1/workshop/template-versions/available` and becomes selectable in the job
   wizard (`WorkshopJobAdminController.java:61`).
10. Retire uses `POST /api/v1/workshop/templates/{id}/retire` (`:74`); existing jobs keep their pinned version.

## Branches

- **No published master items** → empty catalog; publish cannot succeed with zero items (validation).
- **Draft conflict** → optimistic version conflict (409) is surfaced as a retryable error.
- **Pinned version immutability** → editing a published template creates a new version; jobs already created keep
  their `template_version_id`. Confirmed in `PlatformTemplateScopeIT` and `WorkshopAdminIT`.
- **Platform retire of a master item** → the workshop template draft cannot newly select it; already-published
  template versions remain valid for existing jobs (snapshot semantics).
- **Permission denied** → workshop endpoints require `WORKSHOP_ADMIN`; technicians only read a pinned snapshot.

## Cross-app consequence

`published workshop template` must be visible to the Technician only through the job's pinned checklist. There is no
technician template browser; this is intentional parity, not a missing screen.

## Verification status

Server: `WorkshopAdminIT`, `PlatformTemplateScopeIT`, `PlatformTemplateCategoryIT`.
Client: template widget tests in `workshop_admin_app/test/features` (47 files total).
Browser: pending.
