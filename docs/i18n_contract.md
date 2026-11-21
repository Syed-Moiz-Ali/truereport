# UI language contract (single process for all three apps)

Status: target architecture. Replaces the two parallel systems that exist today
(`/api/v1/i18n/ui-messages/manifest|bundle` namespaced API used by Platform Admin,
and `/{client}/manifest|bundle` flat API used by Workshop Admin and Technician).

## 1. Non-negotiable rules

1. **One source of truth per key.** English text is authored on the backend only.
   Flutter never ships hardcoded UI copy (the generated ARB getters are only a
   typed accessor over the backend bundle).
2. **One language process for every app.** Platform Admin, Workshop Admin and
   Technician use the same endpoints, the same manifest shape, and the same
   shared Flutter package (`client/packages/l10n`). No app-local manifest,
   bundle, language-list or selector code.
3. **A UI language is a backend-only change.** Dropping
   `i18n/<scope>/<code>.json` and registering the code in `i18n/languages.json`
   makes the language appear in all three selectors and load without a frontend
   rebuild.
   **A content language** is added at runtime: Platform Admin → Languages →
   **Add language** (`POST /api/v1/platform/i18n/languages`). It is immediately
   writable through the manual-translation screen and content endpoints, and its
   interface text falls back to English until the `<code>.json` catalogs exist.
   `DELETE /api/v1/platform/i18n/languages/{code}` retires it softly (rows and
   translations are kept); re-adding reactivates it.
4. **English is the fallback.** Any missing key resolves to the English value.
5. **Arabic is gone.** No Arabic locale, ARB, generated localization, RTL flag,
   `isArabic` parameter, Arabic property file, or hardcoded `"ar"` branch in
   application code. Flyway migrations already applied are immutable history and
   stay as they are.

## 2. Backend catalog layout

```
server/src/main/resources/i18n/
  languages.json                 # registry, one entry per language
  common/en.json                 # keys shared by >= 2 clients (identical English text)
  common/es.json
  platform_admin/en.json         # keys used only by Platform Admin (dotted keys)
  workshop_admin/en.json         # keys used only by Workshop Admin (ARB-style keys)
  workshop_admin/es.json
  technician/en.json             # keys used only by Technician (ARB-style keys)
  technician/es.json
```

`languages.json`:

```json
{
  "defaultLanguage": "en",
  "languages": [
    { "code": "en", "name": "English", "nativeName": "English", "direction": "ltr" },
    { "code": "es", "name": "Spanish", "nativeName": "Español", "direction": "ltr" }
  ]
}
```

Rules:
- `en` is mandatory for `common/` and for every client scope.
- A language is offered for a client when it is registered in `languages.json`
  **and** `i18n/<client>/<code>.json` exists (a `common/<code>.json` alone is not
  enough to advertise a language for that client; partial catalogs fall back to
  English per key).
- Shared helpers/properties that are not UI bundles (`messages_en.properties`,
  `report_en.properties`, `delivery_en.properties`) stay English-only.

### Key taxonomy (intentional, enforced)

| Scope | Key shape | Example | Why |
|---|---|---|---|
| `platform_admin`, `common` | dotted, hierarchical | `activity.action.categoryCreated` | These keys are **server-qualified message keys**. The backend puts them in API payloads (`messageKey`, `dashboard.alert.*`, checklist keys) and the client resolves them by that exact string. |
| `workshop_admin`, `technician` | flat camelCase | `accountCreated` | UI-only strings. Nothing outside the app addresses them; the generated getter is the only access path. |

The generator uses one rule for all four files — `constant = camelCase(key)` — so a
dotted key surfaces as `activityActionCategoryCreated` and a flat key surfaces
unchanged as `accountCreated`. Renaming either side breaks a contract: flattening
`platform_admin`/`common` breaks `messageKey` resolution, and dotting the client
catalogs would rename 1,237 generated getters.

The four labels that exist in both shapes (`filterAll`, `rolePlatformAdmin`,
`roleTechnician`, `roleWorkshopAdmin`) must keep identical English text so the
merged bundle cannot diverge.

## 3. Endpoints

All three apps use the `{client}` routes. `client` is one of
`platform_admin | workshop_admin | technician`; anything else is `404`.

```
GET /api/v1/i18n/ui-messages/{client}/manifest
200 {
  "defaultLanguage": "en",
  "client": "workshop_admin",
  "namespaces": ["common", "workshop_admin"],
  "languages": [
    { "code": "en", "name": "English", "nativeName": "English", "direction": "ltr", "version": 1 }
  ]
}
```

```
GET /api/v1/i18n/ui-messages/{client}/bundle?lang=es
200 {
  "language": "es",
  "fallbackLanguage": "en",
  "client": "workshop_admin",
  "namespaces": ["common", "workshop_admin"],
  "versions": { "common": 1, "workshop_admin": 3 },
  "catalogs": {
    "common": { "signInTitle": "...", "button.save": "..." },
    "workshop_admin": { "jobsTab": "..." }
  },
  "messages": { "signInTitle": "...", "button.save": "...", "jobsTab": "..." }
}
```

- `messages` is `catalogs.common` merged with `catalogs.<client>`, already
  English-filled. ARB-backed apps read `messages`; namespaced apps read
  `catalogs`.
- Both responses send `Cache-Control: no-store`. Catalogs are edited at runtime.
- Unknown `lang` → `404`. Missing keys in an existing language → English value.
- The existing `/manifest` and `/bundle` (no client segment) routes remain only
  as thin delegates to `platform_admin` for compatibility, and must return the
  same shape as the client routes.

## 4. Flutter package (`client/packages/l10n`)

Owns everything language-related; apps only wire `ApiClient` in.

- `UiMessageApi.forClient(client)` → `/{client}/manifest|bundle`.
- `UiMessageBundle` keeps `catalogs`, gains `messages` (flat merged map).
- `languageSelectionProvider` (keyed by client) holds the selected code, applies
  it immediately, and resolves the bundle. Selection is persisted through a
  store interface; default in-memory, apps may supply a persistent store.
- `BackendLanguageSelector` widget: list of languages from the manifest, one tap
  on an option changes the app language with no save button. Styling via
  `Theme`/`InkWell` only (no dependency on `design_system`).
- Typed key files in `lib/src/ui_messages/keys/`:
  `common_keys.dart`, `platform_admin_keys.dart`, `workshop_admin_keys.dart`,
  `technician_keys.dart`, generated from the backend catalogs by
  `tool/generate_ui_keys.dart`, guarded by a parity test.
- The three apps must have zero local language providers/widgets.

## 5. Removed by this change

- `client/packages/l10n/lib/l10n/app_ar.arb`
- `client/packages/l10n/lib/l10n/gen/app_localizations_ar.dart`
- `languageArabic` key (ARB + generated)
- `signin_language_toggle.dart` Arabic toggle (replaced by the shared selector)
- `isArabic` parameters on `AppTheme.build`, `WorkshopTokens.standard`,
  `context.isArabic`, `ui_gallery` Arabic toggles, `role_home` Arabic branch
- `labelAr` / `instructionAr` / `nameAr` legacy accessors and Arabic input
  fields in Platform Admin models
- `server/src/main/resources/i18n/*_ar.properties`
- every hardcoded `"ar"` language branch in Java services and filters

## 6. Verification (must be reported with real output)

```
cd server && mvn -q -DskipTests compile
cd server && mvn test
cd client/packages/l10n && flutter test
flutter analyze  (platform_admin_app, workshop_admin_app, technician_app, packages/l10n)
npx playwright test --project=workshop-admin tests/e2e/modules/language_dynamic.flow.spec.ts
```

Language-addition proof: remove `es` from `languages.json` + delete the `es`
files → manifest lists only `en`; restore → `es` appears in all three manifests
and selecting it changes UI text, with no Flutter rebuild.
