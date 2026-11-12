# Backend-Driven Platform Admin UI Text + CORS Preflight — Prompt

You are moving **all Platform Admin static UI text** from Flutter ARB files to the backend, adding startup download/caching for the UI-message bundle, and fixing CORS preflight for `X-Request-Id` in:

`E:\syed_moiz_ali\bitlogix\truereport`

This is a large functional refactor. Do not mix it with visual redesign or unrelated product changes.

## Read First

1. `docs/phase-plans/BACKEND_DRIVEN_UI_TEXT_AND_CORS_PROMPT.md`
2. `docs/DECISIONS.md` (D-033–D-040, D-074, D-075, D-076)
3. `docs/I18N_PLAN.md`
4. `docs/NAMING_AND_TESTING_RULES.md`
5. `docs/FRONTEND_ADAPTIVE_RULES.md`
6. Backend security/CORS:
   `server/src/main/java/com/truereport/shared/security/SecurityConfig.java`
7. Backend localization:
   `server/src/main/java/com/truereport/localization/**`
8. Backend shared errors:
   `server/src/main/java/com/truereport/shared/error/**`
9. Flutter l10n:
   `client/packages/l10n/lib/**`
   `client/packages/l10n/lib/l10n/app_en.arb`
   `client/packages/l10n/lib/l10n/app_ar.arb`
10. Platform Admin entry:
    `client/apps/platform_admin_app/lib/main.dart`
    `client/apps/platform_admin_app/lib/src/platform_router.dart`
11. API client:
    `client/packages/api_client/lib/src/api_client.dart`
12. Platform Admin languages/translation queue:
    `client/apps/platform_admin_app/lib/src/features/languages/**`
13. Platform Admin auth:
    `client/apps/platform_admin_app/lib/src/features/auth/**`

## Goal

- Backend is the **source of truth** for all Platform Admin static UI text.
- Flutter Platform Admin no longer uses ARB files or `AppLocalizations` for static text.
- On app startup, Flutter fetches a small manifest of LIVE languages and versions, then loops each language key, downloads that language catalog separately, and stores each catalog locally.
- On later launches, Flutter loads cached catalogs immediately and checks the manifest. It downloads only missing or version-changed languages.
- Language changes use the cached catalog for that language. If it is not cached yet, Flutter downloads only that one language and saves it.
- Adding a new language such as `zh-Hans` requires only backend translations and publishing — no Flutter code change or redeploy.
- CORS preflight for `X-Request-Id` works and is tested.

## Non-Goals

- Do not perform visual redesign, layout polish, card/table restyling, or UX changes.
- Make only the minimum UI changes needed for startup loading, retry, and replacing static text calls.
- Do not migrate Workshop Admin, Technician, or Public Report static text in this pass. Keep their ARB files and localization behavior intact until their phases.
- Do not change domain behavior, scoring, templates, hierarchy, equipment, or catalogues.
- Do not remove `X-Request-Id`.
- Do not suppress the Dio CORS warning.
- Do not commit.
- Do not add code comments.
- Do not translate user-generated data such as workshop names, item labels, customer content, or report content. Only static platform UI text moves to the backend.

## Scope

Platform Admin only:

- navigation labels
- page titles/subtitles
- buttons, filters, chips
- table/card labels
- dialogs
- empty/loading/error text
- helper text/tooltips
- validation/error messages shown in the UI
- action labels
- status/enum labels displayed by the UI

## 1. Backend UI Message Catalog

Add a table `platform_ui_messages` (or an equivalent dedicated catalog):

- `id`
- `namespace` (`platform_admin`, `common`)
- `message_key`
- `language_code`
- `value`
- `status` (`DRAFT`, `APPROVED`, `RETIRED`)
- `version`
- `updated_by`
- `created_at`
- `updated_at`

Constraints and rules:

- Unique `(namespace, message_key, language_code)`.
- Index on `(namespace, language_code)`.
- EN + AR are seeded as `APPROVED`.
- New languages start as `DRAFT`.
- Only `APPROVED` messages for `LIVE` languages may be served to user-facing clients.
- `version` drives the bundle ETag and client cache invalidation.
- Message keys are stable, namespaced, and never renamed silently.

Stable key format:

- `nav.dashboard`
- `page.dashboard.title`
- `page.dashboard.subtitle`
- `button.save`
- `button.cancel`
- `filter.status`
- `table.workshop.name`
- `dialog.delete.title`
- `empty.items.title`
- `error.generic`
- `validation.required`
- `tooltip.refresh`

Rules:

- One message key per concept.
- Reuse `common` keys across screens where appropriate.
- No screen-specific duplicate keys unless wording differs.
- Preserve parameterized messages using `{name}` placeholders.
- Known enum/status labels must resolve through catalog keys, not raw enum text.

## 2. Seed / Migration

One-time import of all Platform Admin ARB keys from:

- `client/packages/l10n/lib/l10n/app_en.arb`
- `client/packages/l10n/lib/l10n/app_ar.arb`

Requirements:

- Convert ARB keys to stable namespaced keys.
- Do not change the meaning of existing text.
- Preserve parameter placeholders.
- Seed EN + AR as `APPROVED`.
- New languages start `DRAFT`.
- Provide a repeatable import/registration path for future keys.
- Add a completeness test that every Platform Admin key used by Flutter exists in the backend catalog.
- Add a test that EN and AR catalogs have identical key sets.

## 3. Public Bootstrap APIs

Add anonymous endpoints:

Manifest:
- `GET /api/v1/i18n/ui-messages/manifest?namespaces=platform_admin,common`

Per-language catalog:
- `GET /api/v1/i18n/ui-messages?namespace=platform_admin&lang=en`
- `GET /api/v1/i18n/ui-messages/bundle?namespaces=platform_admin,common&lang=en`

Do not return all languages in one large payload. The Flutter app fetches the small manifest first, then loops the language keys and downloads each language catalog separately.

Manifest response shape:

```json
{
  "catalogVersion": 12,
  "defaultLanguage": "en",
  "namespaces": ["platform_admin", "common"],
  "languages": [
    { "code": "en", "version": 12, "direction": "ltr", "coverage": 100 },
    { "code": "ar", "version": 12, "direction": "rtl", "coverage": 100 },
    { "code": "zh-Hans", "version": 8, "direction": "ltr", "coverage": 98 }
  ]
}
```

Per-language response shape:

```json
{
  "language": "en",
  "fallbackLanguage": "en",
  "version": 12,
  "namespaces": ["platform_admin", "common"],
  "catalog": {
    "nav.dashboard": "Dashboard",
    "nav.workshops": "Workshops",
    "button.save": "Save",
    "empty.noItems.title": "No checklist items yet",
    "empty.noItems.body": "Create your first item to get started."
  },
  "missingKeys": []
}
```

Requirements:

- The manifest is small, anonymous, and cheap to fetch on every app open.
- The manifest lists every LIVE language and its own catalog `version`.
- The client loops `manifest.languages`; for each `code`, it downloads that language catalog and saves it separately.
- `catalog` is a flat `message_key -> value` map for one language. Do not use a single-language `messages` field.
- `missingKeys` lists keys missing for that language.
- `defaultLanguage` must always be included for client-side fallback.
- Use gzip/brotli response compression.
- Support `ETag` and `If-None-Match` per language with `304 Not Modified`.
- Add `Vary: Accept-Language` only if a per-language endpoint can be negotiated by header; otherwise cache by `lang` + version.
- Do not require JWT.
- Do not leak `DRAFT` or `RETIRED` messages to user-facing clients.
- A failure loading one language must not prevent other languages from loading.

## 4. Admin APIs

Add authenticated Platform Admin endpoints:

- `GET /api/v1/platform/i18n/ui-messages?namespace=&language=&status=&search=&missingOnly=`
- `GET /api/v1/platform/i18n/ui-messages/bundle?namespace=&language=`
- `PUT /api/v1/platform/i18n/ui-messages`
- `PUT /api/v1/platform/i18n/ui-messages/bulk`
- `GET /api/v1/platform/i18n/ui-messages/coverage?language=`

Requirements:

- Require Platform Admin authority.
- Support filtering by namespace, language, status, search, and missing-only.
- Bulk update must be transactional and audited.
- Coverage must report approved/total/missing counts by namespace and language.
- Admin APIs may request `DRAFT` languages with an admin role.

## 5. Language Lifecycle and Publish Gate

- Language activation/publish is blocked until all required `platform_admin` and `common` UI messages are `APPROVED`.
- Missing UI messages appear in translation coverage.
- A language cannot become `LIVE` while required UI messages are missing.
- Retiring a language must not break cached clients; the fallback language remains available.

## 6. Translation Queue

Extend the existing Translation Queue at `/settings/languages/{code}/translations` with:

- Entity type `UI Messages`.
- Grouping by namespace (`platform_admin`, `common`).
- Filters: namespace, missing-only, search, status.
- Inline editor showing default-language source text and target-language value.
- Bulk approve and bulk update.
- Progress per namespace and overall.
- Language publish blocked until required UI messages are approved.

## 7. Flutter Remote Strings

Create a remote localization layer in `client/packages/l10n`:

- `RemoteStrings` / `UiMessageController`
- `UiMessageManifest` model
- `UiMessageCatalog` model
- `UiMessageApi` client
- `UiMessageCache`

Responsibilities:

- Fetch the small language manifest first.
- Loop `manifest.languages`; for each language `code`, download that language catalog separately and save it.
- Cache each language catalog in memory and local storage by `language_code + version`.
- Expose `String t(String key)` and `String tArgs(String key, Map<String, Object?> args)` using the active language catalog.
- Fallback chain: selected language → default language → key.
- Log a debug warning for missing keys, but never show raw keys in release when a cached fallback exists.
- On language change, use the cached catalog for that language when present; otherwise download only that language and save it.
- Work before login.
- Provide a bootstrap loading/retry state when no cache exists.

## 8. Startup Behavior

First launch:

1. Show a minimal bootstrap loading/retry state.
2. Fetch the language manifest.
3. Loop the manifest languages; download each language catalog separately.
4. Store each language catalog in the cache.
5. Render the app using the active language catalog.

Later launches:

1. Load the cached catalogs immediately and render.
2. Fetch the manifest in the background.
3. For each manifest language, skip it when the cached `language_code + version` matches.
4. Download only missing or version-changed languages, then replace those catalogs atomically.
5. If the network fails, keep using the cache.
6. Never block the app on network when a valid active-language cache exists.

Loop rules:

- Use a small concurrency limit (for example 2–4) when downloading multiple languages.
- Do not download a language that is already cached at the manifest version.
- One language failing must not block the others.
- If the active language fails and no cache exists, fall back to the default language.

Error rules:

- Missing key: log in debug, use fallback text, never crash.
- Catalog failure with cache: continue with cache.
- Manifest or active-language failure without cache: show retry screen.
- Invalid JSON: keep the previous cache for that language.
- Version mismatch: replace only that language's cache atomically.
- No raw keys in release builds when cache exists.

## 9. Remove Platform Admin ARB Usage

- Remove `AppLocalizations` usage from `client/apps/platform_admin_app/lib/`.
- Replace all `l10n.foo` calls with `strings.t('namespace.key')`.
- Replace parameterized calls with `strings.tArgs('namespace.key', args)`.
- Remove unused `AppLocalizations` imports and Platform Admin ARB delegate usage.
- Keep Flutter built-in Material/Widgets localizations for date pickers, dialogs, and text direction.
- Keep ARB files for other apps until their migration phases.
- Do not delete shared l10n infrastructure required by other apps.

## 10. Language Switching

- Update locale.
- Use the cached catalog for the selected language when present.
- If that language is not cached, download only that language catalog, save it, then switch.
- Do not re-download every language on switch.
- Update `Accept-Language` on the API client for data requests.
- If the selected language is missing or fails to load, fall back to the default language and log a debug warning.
- Text direction must still follow the selected language.

## 11. Validation and Error Messages

- Keep backend RFC 9457 `messageKey`, `messageEn`, and `messageAr`.
- Flutter should prefer backend `messageKey` resolved through the UI catalog.
- For dynamic/structured validation errors, show the response `message` fields.
- Do not duplicate backend validation text in ARB.

## 12. CI Guards

Add automated checks:

- Zero `AppLocalizations` and zero `l10n.` usage in `client/apps/platform_admin_app/lib/`.
- Every code key exists in the backend catalog.
- EN/AR key parity.
- No hardcoded Platform Admin UI strings remain in `lib/`.
- Bundle contract test.
- Cache fallback test.
- Missing-key fallback test.
- Language-change reload test.

## 13. CORS Preflight Fix

Current Dio warning:

> Request header `X-Request-Id` is not on the CORS safelist and triggers preflight.

This warning is expected for non-safelisted headers. The requirement is that the server handles preflight correctly.

Fix/verify:

- `CorsConfiguration` allows origins from config.
- Allowed methods: `GET, POST, PUT, PATCH, DELETE, OPTIONS`.
- Allowed headers: `Authorization, Content-Type, Accept-Language, X-Request-Id, Idempotency-Key, If-Match`.
- Exposed headers: `X-Request-Id, ETag, Location`.
- Ensure `OPTIONS` preflight is permitted without JWT.
- Add integration tests:
  - `OPTIONS /api/v1/auth/login` with `Access-Control-Request-Headers: x-request-id` returns 200/204 and includes `Access-Control-Allow-Headers`.
  - `OPTIONS` for an authenticated API path succeeds without a token.
  - Actual request still enforces authentication.
- Add `Vary: Origin` behavior for cached CORS responses.
- Do not use wildcard origins with credentials.
- Do not remove `X-Request-Id`; it is required for traceability.
- Document that the Dio warning is informational and preflight must be verified, not suppressed.

## Agentic Sub-Sessions

1. **Backend catalog + APIs + seed + lifecycle + CORS agent**
   - Migration, seed import, public/admin endpoints, ETag, coverage, publish gate.
   - CORS/preflight changes and integration tests.

2. **Flutter remote strings agent**
   - `RemoteStrings`/`UiMessageController`, bundle model, cache, startup bootstrap, language reload.
   - API client integration and `Accept-Language`.

3. **Platform Admin ARB-to-backend migration agent**
   - Replace all `l10n.*` usages with remote keys.
   - Remove `AppLocalizations` from Platform Admin.
   - Report converted call sites and remaining exceptions.

4. **Translation Queue agent**
   - Add `UI Messages`, namespace grouping, filters, inline editor, bulk approve, coverage, publish gate.

5. **CI guards + verifier**
   - Zero ARB usage, key completeness, EN/AR parity, cache/startup, language switch, CORS preflight, tests, screenshots.
   - Only the verifier claims completion.

One file owner at a time.

## Verification

```powershell
cd server
mvn "-Dtest=PlatformUiMessagesIT,CorsPreflightIT,PlatformLanguageLifecycleIT,FlywayMigrationTest" test
mvn test

cd ..\client
flutter analyze --fatal-infos

cd apps\platform_admin_app
flutter test
```

Capture screenshots at 1280/1440/768/360 + RTL + `zh-Hans` fixture.

## Acceptance Criteria

1. Backend is the source of truth for all Platform Admin static UI text.
2. Flutter Platform Admin has zero `AppLocalizations`/`l10n.` usages in `lib/`.
3. A small anonymous manifest lists every LIVE language with its own catalog version.
4. Flutter loops the manifest languages and downloads each language catalog separately.
5. Each language catalog is cached independently by `language_code + version`.
6. On later opens, Flutter loads cached catalogs immediately and downloads only missing or version-changed languages.
7. Language switch uses the cached catalog when present; otherwise it downloads only that one language.
8. A 2000+ key catalog is not downloaded as one all-language mega-payload.
9. Adding `zh-Hans` later requires only backend translations and publishing; the next manifest check downloads it with no Flutter code change or redeploy.
10. Translation Queue includes `UI Messages` and blocks language activation until required messages are approved.
11. EN/AR key parity and code-vs-catalog completeness pass in CI.
12. CORS preflight for `X-Request-Id` is tested and works on public and authenticated paths.
13. Backend tests, Flutter analyze/tests, and screenshots pass.
14. No Workshop Admin, Technician, or Public Report static-text migration in this pass.
15. No visual redesign beyond startup loading/retry and static-text replacement.
16. No commits.

## Output Format

Report:

- Files changed.
- Backend schema/API and seed import.
- Flutter remote-string architecture and cache flow.
- Codemod results (keys converted, remaining exceptions).
- Translation Queue changes.
- CORS preflight test results.
- Commands and results.
- Screenshots.
- Remaining blockers.
