# Platform Admin Language Lifecycle E2E

The live test verifies:

- Platform Admin login without UI-message auth
- Add a language
- Generate UI messages with a **stub** translation provider (never Google)
- Review, edit, save, approve, publish
- Manifest includes the new language
- Bundle returns the edited translation
- Publish is blocked before approval
- The generated JSON file exists and the DB path is set
- Screenshots at 1280 / 1440 / 768 / 360, Arabic RTL, and the generated language

Run the backend with the stub provider and a writable UI-message directory:

```powershell
$env:UI_TRANSLATION_PROVIDER="stub"
$env:UI_MESSAGES_DIR="E:\syed_moiz_ali\bitlogix\truereport\server\target\e2e-ui-messages"
$env:UI_MESSAGES_GENERATION_SYNC="true"
mvn spring-boot:run
```

Run the E2E:

```powershell
cd client\apps\platform_admin_app
$env:LIVE_E2E="1"
$env:LIVE_BASE_URL="http://localhost:8080"
$env:LIVE_E2E_EMAIL="platform@truereport.test"
$env:LIVE_E2E_PASSWORD="<platform-admin-password>"
$env:LIVE_UI_MESSAGES_DIR="E:\syed_moiz_ali\bitlogix\truereport\server\target\e2e-ui-messages"
$env:EVIDENCE_DIR="E:\syed_moiz_ali\bitlogix\truereport\docs\evidence\platform_admin_languages"
flutter test test/e2e/language_lifecycle_live_e2e_test.dart
```

Screenshots are written to `EVIDENCE_DIR` (default:
`docs/evidence/platform_admin_languages`).

## Backend test-only stub

`StubTranslationProvider` is enabled only with
`truereport.i18n.translation.provider=stub`. Production defaults to Google.
