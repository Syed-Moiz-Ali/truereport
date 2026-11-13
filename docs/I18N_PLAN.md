# Backend & Cross-Platform Language Plan

**Goal:** Full EN/AR language support across Platform Admin, Workshop Admin, Technician, public report, PDFs, generated documents, notifications, and API errors — not only Flutter static text.

**Status:** Approved 2026-11-11. No code starts until the Platform phase start is approved.

---

## 1. Current State

| Layer | Current state |
|---|---|
| Flutter static UI | EN/AR ARB files |
| Master data | `localized_content` supports EN/AR/RU/ZH-Hans |
| Public report/PDF labels | `i18n/report_en.properties` + `report_ar.properties` |
| Delivery messages | `i18n/delivery_en.properties` + `delivery_ar.properties` |
| API errors/validation | English only; returns `messageKey` but no Arabic |
| `Accept-Language` from Flutter | Not sent (`ApiClient` only sends `X-Request-Id`) |
| Spring `MessageSource` / locale resolver | Not configured |
| Generated documents | Not implemented |
| Notifications | Not implemented |
| Technician free-text notes | Single note + language, not bilingual |

---

## 2. Translation Layers

| Layer | Storage | Owner | Required at publish |
|---|---|---|---|
| Flutter UI chrome | `app_en.arb` / `app_ar.arb` | Developers | CI parity |
| API errors, validation, notifications, PDF labels | `messages_en.properties` / `messages_ar.properties` | Developers | CI parity |
| Categories, items, options, templates, grades, document types, issue fields, bands | DB (`localized_content` or bilingual columns) | Platform Admin | EN + AR |
| Report snapshots | DB JSON, both languages | System | At finalize/publish |
| Generated PDFs | Object storage, one file per language | System | After publish |

RU and ZH-Hans are prepared but optional at launch. Missing values fall back to EN.

### 2.1 V1 scope: manual bilingual entry

For V1, **no LLM or machine translation is used**. Platform Admin manually enters English and Arabic for every user-facing configuration field.

This is deliberate:
- Accurate automotive terminology.
- Stable legal/report wording.
- No extra translation service to operate.
- No runtime or authoring dependency on a model.

Platform Admin screens must provide EN/AR inputs for:
- Category names
- Item labels and instructions
- Standard spec text
- Option set names and option values
- Issue field labels and help text
- Measurement/score band criteria
- Grade labels
- Document type names
- Template names and descriptions
- Any other user-facing text

Publishing requires both EN and AR. A future LLM auto-translate feature is out of scope for V1 (D-041).

---

## 3. Language Registry

### 3.1 Table `languages`

| Column | Notes |
|---|---|
| `code` | `en`, `ar`, `ru`, `zh-Hans` |
| `name_en` | English name |
| `name_ar` | Arabic name |
| `native_name` | Native display name |
| `direction` | `ltr` / `rtl` |
| `active` | Whether selectable |
| `is_default` | Single default |
| `sort_order` | Display order |

### 3.2 User preference

- `users.preferred_language` (or `user_preferences.language`).
- Cached locally on the device for instant switch and offline use.
- Sent as `Accept-Language` on every API request.

### 3.3 Job/customer preference

- `inspection_jobs.preferred_language` (`en`/`ar`).
- Used for generated documents and notifications.
- Public report defaults to this; `?lang` overrides.

---

## 4. API Surface

### 4.1 Common API — all platforms

```text
GET  /api/v1/i18n/languages
GET  /api/v1/i18n/me
PUT  /api/v1/i18n/me
```

`GET /api/v1/i18n/languages`:

```json
[
  {
    "code": "en",
    "name": "English",
    "nativeName": "English",
    "direction": "ltr",
    "default": true,
    "active": true
  },
  {
    "code": "ar",
    "name": "Arabic",
    "nativeName": "العربية",
    "direction": "rtl",
    "default": false,
    "active": true
  }
]
```

`GET /api/v1/i18n/me`:

```json
{
  "language": "ar",
  "direction": "rtl",
  "fallback": "en"
}
```

`PUT /api/v1/i18n/me`:

```json
{ "language": "ar" }
```

### 4.2 Platform Admin language CRUD

```text
GET    /api/v1/platform/i18n/languages
POST   /api/v1/platform/i18n/languages
PUT    /api/v1/platform/i18n/languages/{code}
POST   /api/v1/platform/i18n/languages/{code}/activate
POST   /api/v1/platform/i18n/languages/{code}/deactivate
PUT    /api/v1/platform/i18n/languages/reorder
PUT    /api/v1/platform/i18n/languages/default
GET    /api/v1/platform/i18n/coverage
```

Rules:
- Only Platform Admin can create/activate/deactivate languages.
- Cannot deactivate the default language.
- Cannot deactivate a language used as a job/customer preference without a replacement.
- `coverage` returns missing translations by namespace/entity.

### 4.3 Translation coverage response

```json
{
  "languages": ["en", "ar"],
  "namespaces": {
    "master.categories": { "total": 6, "missing": [] },
    "master.items": { "total": 30, "missing": ["ENG-OIL-01.ar.label"] },
    "master.options": { "total": 120, "missing": ["ISSUE_TYPE.CRACKED.ar"] },
    "messages": { "total": 180, "missing": [] }
  }
}
```

---

## 5. API Response Localization

### 5.1 Dynamic content

Every user-facing dynamic object returns both languages plus a resolved value:

```json
{
  "code": "BRK-PAD-01",
  "labelEn": "Brake Pad Thickness",
  "labelAr": "سمك أقمشة الفرامل",
  "label": "سمك أقمشة الفرامل",
  "instructionEn": "...",
  "instructionAr": "...",
  "instruction": "..."
}
```

Clients can switch language without refetching because both values are present.

### 5.2 Errors and validation

`ApiExceptionHandler` returns:

```json
{
  "type": "about:blank",
  "title": "Validation failed",
  "status": 422,
  "code": "ITEM_VALIDATION_FAILED",
  "messageKey": "error.validation.failed",
  "messageEn": "Validation failed.",
  "messageAr": "فشل التحقق.",
  "detail": "فشل التحقق.",
  "traceId": "...",
  "errors": [
    {
      "field": "MEASUREMENT",
      "code": "MEASUREMENT_BAND_MISMATCH",
      "messageKey": "error.measurement.bandMismatch",
      "messageEn": "4.2 mm maps to ATTENTION; submitted result was PASS.",
      "messageAr": "4.2 مم يطابق حالة الانتباه؛ النتيجة المرسلة كانت ناجحة."
    }
  ]
}
```

- `detail` is resolved from `Accept-Language`/`?lang`.
- `messageEn` and `messageAr` are always included.
- `code` and `messageKey` are stable machine identifiers.
- Field names remain English machine keys; only messages are localized.

### 5.3 Fallback

1. Requested language.
2. Default language.
3. English.

---

## 6. Backend Implementation

### 6.1 New localization module

| Component | Purpose |
|---|---|
| `Language` entity/repo | Registry |
| `UserLanguagePreference` | Per-user server preference |
| `LocaleResolver` | `Accept-Language` + `?lang` |
| `MessageSource` config | System messages |
| `LocalizationService` | Resolve labels/fallbacks |
| `TranslationCoverageService` | Missing-key reporting |
| `LocalizedApiExceptionHandler` | Bilingual ProblemDetail |
| `LanguageAdminController` | Platform CRUD |
| `I18nController` | Common list/current/set |

### 6.2 Configuration

```yaml
spring:
  messages:
    basename: i18n/messages
    encoding: UTF-8
    fallback-to-system-locale: false
```

- Locale resolver: `Accept-Language`, then `?lang`, then default.
- Public page/PDF uses `?lang` first.
- API responses use `Accept-Language`.

### 6.2.1 Google Translate provider overrides

`truereport.i18n.translation.target-languages` is an **optional override
map**, not an allowlist of supported app languages.

- Any language code from the language registry is accepted.
- Resolution order: exact override, case-insensitive override, canonicalized
  provider code, then the original code.
- Canonicalization lowercases the language, title-cases the script, and
  uppercases the region (`pt-br` -> `pt-BR`, `zh-hans` -> `zh-Hans`).
- Add an override only when Google expects a different code. Examples:
  `zh-Hans: zh-CN`, `zh-Hant: zh-TW`, and `pt-BR: pt` only if required.
- A missing override never rejects a language.
- If Google rejects an unsupported target, generation fails clearly and the
  language stays non-LIVE. The provider may retry once with the base language
  (`pt-BR` -> `pt`, `zh-Hans` -> `zh`, `es-MX` -> `es`) only for an
  unsupported-target error.

### 6.3 Master content

- EN + AR required before publish.
- RU/ZH optional.
- `localized_content` remains the source of truth.
- Option values, grade labels, document types, issue fields, and band criteria use the same localization mechanism.
- Publish validation returns `TRANSLATION_REQUIRED` with the missing locale/field.

### 6.4 Snapshots

- At finalize/publish, store both languages for every label/option/value.
- Public report reads the snapshot, never live master data.
- Later edits cannot change an old report.

---

## 7. Frontend Implementation

### 7.1 Shared Flutter `l10n` package

- `LanguageController`:
  - loads `/api/v1/i18n/languages`
  - reads/writes `/api/v1/i18n/me`
  - caches locally for offline/instant switch
  - exposes current locale, direction, fallback
- Replace per-app locale providers with the shared controller.
- All apps use `AppLocalizations.supportedLocales`.

### 7.2 API client

- `ApiClient` injects `Accept-Language` from the current language.
- Applies to all requests, including uploads and downloads.
- Falls back to `en` if no preference.

### 7.3 UI

- All new screen strings go into ARB.
- No inline English/Arabic in widgets.
- Dynamic content renders `label` from the API; switches instantly using `labelEn`/`labelAr` if needed.
- RTL direction follows the language registry (`direction`).

---

## 8. Public Report

- Default language = job `preferred_language`.
- `?lang=en|ar` overrides.
- Fallback: job language → default → EN.
- `dir="rtl"` for Arabic.
- JSON always includes both languages.
- HTML/PDF resolves one language for layout, but data carries both.

---

## 9. Generated Documents

- Generate separate EN and AR PDFs per document type after publish.
- Store both artifacts linked to the report version.
- Public report links the current language version.
- If one language fails, fall back to the other and surface retry status.
- No manual upload gate.

---

## 10. Notifications / Delivery

- Use `inspection_jobs.preferred_language` (or customer preference).
- `delivery_en.properties` / `delivery_ar.properties` already exist.
- Add RU/ZH bundles only when those languages are activated.
- Do not use Flutter ARB for SMS/email/WhatsApp.

---

## 11. Audit and Machine Data

- Audit logs store canonical codes and JSON payloads.
- UI localizes labels from bundles.
- No translated sentences in audit storage.
- This keeps logs stable, searchable, and language-independent.

---

## 12. Numerals and Formatting

- Western digits in both languages (existing ADR-0012 direction).
- Dates/times formatted server-side for public report/PDF.
- Flutter uses locale-aware date formatting but keeps Western digits.
- Currency, odometer, and measurements use locale-aware separators where needed.

---

## 13. Enforcement and Tests

### 13.1 CI

- `messages_en` vs `messages_ar` key parity.
- `app_en.arb` vs `app_ar.arb` key parity.
- Seed data EN/AR completeness.
- No literal user-facing text in report templates (existing parity test).

### 13.2 Backend tests

- `Accept-Language: ar` returns Arabic `detail` and both messages.
- Missing Arabic falls back to English.
- Publish fails when EN or AR content is missing.
- Snapshot contains both languages.
- Generated EN/AR PDFs exist after publish.
- Coverage endpoint reports missing keys.

### 13.3 Flutter tests

- Language switch updates UI instantly.
- `Accept-Language` is sent on requests.
- Offline language preference is cached.
- RTL layout after switching to Arabic.
- Dynamic labels use API values, not hardcoded strings.

---

## 14. Approved Decisions

| ID | Decision |
|---|---|
| D-033 | Common `/api/v1/i18n` language API for all platforms |
| D-034 | Hybrid translation source: properties + DB + ARB |
| D-035 | Platform-Admin-only language registry CRUD |
| D-036 | Server-side language preference + local cache |
| D-037 | Separate EN/AR generated PDFs |
| D-038 | Public report defaults to job preferred language, `?lang` override |
| D-039 | EN/AR mandatory at publish; CI parity tests; coverage dashboard |
| D-040 | Western digits in both languages |
| D-041 | Manual bilingual entry in V1; LLM auto-translation deferred |

---

## 15. Future (Out of Scope for V1)

- Self-hosted LLM/MT auto-translation as a draft assistant.
- Human approval gate for auto-translated content.
- Automotive glossary management.
- Bulk translate-missing workflow.
- Feedback loop from approved translations into glossary/fine-tuning.

## 16. Open Items

- Exact `messages_*.properties` key naming convention.
- Whether RU/ZH-Hans bundles are created now or when activated.
- Whether generated PDFs are produced for all document types at publish or lazily on first request.
- Whether translation coverage blocks publish or only warns for optional languages.
- Whether customers can choose language before the report is created.
