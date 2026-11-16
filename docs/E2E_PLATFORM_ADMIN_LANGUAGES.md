# Platform Admin Language Baseline E2E

Platform Admin is currently English-only. Static UI text is JSON-backed and
there is no Add language screen, UI text generation job, review/approve flow,
publish gate, or per-language font requirement.

The architecture still allows a future language by:

1. Adding `server/src/main/resources/i18n/platform_admin/<code>.json`.
2. Adding the language entry to
   `server/src/main/resources/i18n/platform_admin/manifest.json`.
3. Restarting/reloading the backend.

The live test verifies:

- Platform Admin login without UI-message auth.
- The manifest contains only English.
- `en.json` is served by the bundle endpoint and cached by the app.
- The language selector is a non-interactive English label, not a dropdown.
- The language registry shows one English card.
- There are no Add/Generate/Review/Approve/Publish static-language actions.
- Dynamic content translation queue still edits and approves categories, items,
  option sets, option values, templates, document types and issue fields.
- Platform Admin does not create, build, list, or select templates. Workshop
  Admin owns template creation and publication. Platform Admin workshop detail
  has no Templates tab, and workshop registration does not require a template.
  Dynamic TEMPLATE translation remains available in Language Workspace.
  Backend and Workshop Admin template APIs remain intact.
- Missing dynamic translations fall back to English.
- Shared `platform_languages` rows for other apps are retained.
- `/api/v1/platform/i18n/languages` returns only the Platform Admin manifest
  language (English), while the shared `/api/v1/i18n/languages` endpoint keeps
  shared LIVE languages for other apps.

Run the backend:

```powershell
mvn spring-boot:run
```

Run the Platform Admin tests:

```powershell
cd client\apps\platform_admin_app
flutter test
```
