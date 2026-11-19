# Invariants — technician sign-in (Phase 0-lite)

Only the invariants this screen touches. IDs are used by the mini Brief and by
Gate 6. **Behaviour is preserved; UI implementation is replaced.**

Legend for "Rebuild action": KEEP = must behave identically; PIN = add/keep a
test; FIX = a defect the rebuild removes at the root (recorded, not silent);
OUT = out of scope for this wave.

| ID | Invariant | Enforced at | Tested at | Rebuild action |
|---|---|---|---|---|
| **I1** | A signed-out user at any route is redirected to `/signin`; a signed-in technician at `/signin` is redirected to `/jobs` | `technician_router.dart:33-47` | indirect: `widget_test.dart`; router itself **untested** | KEEP + PIN |
| **I2** | A session whose role is not `Role.technician` is redirected to `/unauthorized` | `technician_router.dart:43-45` | untested in this app | KEEP + PIN |
| **I3** | Sign-in calls `AuthController.signIn(email, password)`; email is trimmed, password is passed verbatim; credentials are never persisted | `sign_in_page.dart:46-52`, `auth_repository.dart:58-61` | no repository test in this app | KEEP + PIN |
| **I4** | A `requiresTwoFactor` response yields `AuthChallenge`; the same screen shows a code field and submits `verifyTwoFactor(challengeToken, code)`; the challenge token lives only in memory | `auth_repository.dart:109-112`, `sign_in_page.dart:56-58`, `sign_in_view.dart:194-209` | **untested** | KEEP + PIN (this is the largest current gap) |
| **I5** | `AUTH_INVALID_CREDENTIALS` and `AUTH_2FA_INVALID` both map to `invalidCredentials` (no account enumeration); network codes map to `networkError`; anything else maps to `genericError` | `sign_in_page.dart:81-92` | **untested** | KEEP + PIN |
| **I6** | Session is stored in `FlutterSecureStorage` under `truereport.session`; restore validates with `/auth/me`; a 401 clears it; a non-401 failure keeps the last known session (offline) | `session_store.dart:17-35`, `auth_repository.dart:30-49` | **untested** | KEEP (no change) + record gap |
| **I7** | Sign-out clears the local token and store even if the server call fails | `auth_repository.dart:98-107` | untested | KEEP |
| **I8** | Email: required + `Validators.email`. Password: required only — **no length/complexity rule on login** (legacy accounts) | `sign_in_page.dart:94-99`, `:121-129` | validation path untested | KEEP + PIN |
| **I9** | Passwords are never logged. (Current defect: the email and exception text are logged without `kDebugMode`.) | `sign_in_page.dart:35-40, 63, 69` | none | **FIX** (remove/gate all page-level logging) + PIN |
| **I10** | A submit cannot issue a second request while one is in flight (current defect: the button disables, but Enter bypasses it because `onFieldSubmitted` calls `_submit` unconditionally) | `sign_in_view.dart:184`, `sign_in_page.dart:33-79` | none | **FIX** + PIN (double-submit test) |
| **I11** | Every user-visible string comes from `AppLocalizations`; no raw literals in `lib/`; no forbidden Figma sample strings | `test/i18n_source_scan_test.dart:236-287` | i18n scan (2 pre-existing fails, see allowlist B3/B4) | KEEP; **no shared ARB edit in this wave** |
| **I12** | The screen renders EN/LTR and AR/RTL from `localeProvider`; the toggle writes `localeProvider.notifier.setLocale` | `sign_in_page.dart:104, 117-119`, `locale_controller.dart:9-15` | `widget_test.dart:92-145` | KEEP + PIN |
| **I13** | Locale choice is session-scoped (in-memory, resets to EN on restart) | `locale_controller.dart:9-21` | none | KEEP (persisting it would be a behaviour change; out of scope) |
| **I14** | The app is light-only; `AppTheme.build` asserts `Brightness.light` | `tokens.dart:739-748` | design-system tests | KEEP; a "dark theme" deliverable is not possible in this wave |
| **I15** | The error message is announced (`liveRegion`) and focus stays usable on failure; password is obscured by default and the reveal control has an accessible name | `sign_in_view.dart:48, 180, 234-245, 354-388` | partially: `widget_test` renders only | KEEP + strengthen (accessible name is missing today) |
| **I16** | Autofill hint contracts: email → `AutofillHints.email`, password → `AutofillHints.password`; email field is LTR; email keyboard type is `emailAddress`; Enter on password submits | `sign_in_view.dart:163-185` | geometry tests reference the keys | KEEP + PIN |
| **I17** | The eight widget keys used by tests keep working (or are replaced by a documented equivalent set in the same change): `sign-in-email`, `sign-in-password`, `sign-in-code`, `sign-in-submit`, `sign-in-language-en`, `sign-in-language-ar`, `sign-in-access-prompt`, `sign-in-security-line` | `sign_in_view.dart:89-90, 156, 172, 197, 249, 286, 314` | `widget_test.dart`, `o2_copy_fit_test.dart`, `f2a1_geometry_test.dart` | KEEP (cheapest, keeps the suite honest) |
| **I18** | No account creation, no "forgot password" link, no SSO: the technician screen offers sign-in + help only | `widget_test.dart:73-90` | yes | KEEP + PIN |
| **I19** | Tenant scoping is **not** enforced client-side: the guard checks role only; job access control is server-side | `technician_router.dart:43-46`; `Session.workshopId` from memberships | **UNVERIFIED** (server) | KEEP; do not claim client-side tenancy. Out of scope to add |
| **I20** | Config: `APP_ENV`/`API_BASE_URL` are compile-time (`String.fromEnvironment`) with a dev-tunnel default | `api_config.dart:7-22` | none | KEEP; release builds must pass `--dart-define-from-file=config/prod.json` (CI concern, out of scope) |

## Behaviour pins that the rebuild must add (they do not exist today)

1. **Double-submit**: pressing Enter twice / tapping twice issues one request.
2. **Invalid form never calls the repository** (empty email, malformed email,
   empty password).
3. **2FA challenge**: first response `requiresTwoFactor` renders the code field;
   submitting calls `verifyTwoFactor` with the token and the code; invalid code
   shows `invalidCredentials`; the password field is no longer the submit path.
4. **Error mapping** for the three families in I5.
5. **Router guard**: signed-out → `/signin`; wrong role → `/unauthorized`;
   technician at `/signin` → `/jobs`.
6. **Reveal control** has an accessible name and a ≥44 px target.
7. **No logging**: a submit does not emit the email in release (assert on the
   `debugPrint` seam or, preferably, remove the call sites).
8. **Locale**: AR switch flips the base direction and preserves typed values.

## Deliberate non-goals

- Persisting the locale (I13).
- Client-side tenant checks (I19).
- Fixing the dead `refresh()` / global-401 handling (`auth_repository.dart:87`,
  `api_client.dart`) — recorded as a pre-existing security finding, not a
  sign-in UI change.
- Editing the shared ARB (I11).
- Touching the platform-admin legacy `SignInCopy` (allowlist B3).
