# English-only product decision

Date: 2026-11-20. Owner decision: the product ships English only.

## What changed

- **Flutter apps** force `Locale('en')` and `supportedLocales: [Locale('en')]`.
- Language switchers were removed from the Workshop shell, Technician sign-in and Technician profile.
- **API responses** omit every Arabic duplicate field (`labelAr`, `nameAr`, `messageAr`, ...) through
  `EnglishOnlyJacksonConfig`.
- **Error envelopes** no longer include `messageAr` (`ApiExceptionHandler`).
- **Language registry**: `/api/v1/i18n/languages` and `/api/v1/platform/i18n/languages` expose only `en`;
  `setMyLanguage` rejects anything else.
- **Public report**: any `?lang=` value renders English; the AR/EN switch was removed from the template;
  `dir` is always `ltr`.
- **Migration `V124__english_only_content.sql`** deletes non-English languages, preferences and translation
  overlays; the English language row is normalised to LIVE/LTR/default.
- The dynamic-content seeder ignores non-English overlays.

## What is retained

- Arabic **columns** and the internal bilingual-capable model remain in the database for a possible future
  release; no Arabic content is returned or rendered.
- `client/packages/l10n/lib/l10n/app_ar.arb` is retained only as a legacy widget-test fixture. The shipped
  apps do not support Arabic (`supportedLocales` is English-only, locale is clamped to English). Removing it
  requires rewriting the legacy Arabic/RTL tests.

## Verification

- `mvn test` → **166 tests, 0 failures, 0 errors, 15 skipped** (bilingual gate/migration tests disabled with
  an explicit English-only reason).
- `GET /api/v1/platform/master/categories` and `/items` contain no `*Ar` keys.
- `GET /r/{token}` → 200, `dir="ltr"`, no language switch; `GET /r/{token}/pdf` → 200.
- `flutter analyze` clean on all three apps.
- Workshop `flutter test` still has legacy UI failures (Arabic/RTL and old screenshot expectations); this is
  the remaining client test-stabilization task.
