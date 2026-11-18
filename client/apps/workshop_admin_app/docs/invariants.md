# Invariants — Workshop Admin sign-in (Phase 0-lite)

Scope: the `sign in` screen (`lib/src/features/auth/workshop_login_page.dart`) and the
auth/tenancy behaviour it triggers. LITE path: this list is limited to what this screen
touches, but auth and tenancy are cross-screen, so the router and repository are included.

Written read-only. No app code was changed to produce this file.

| # | Invariant | Where enforced | Where tested | Status |
|---|---|---|---|---|
| I1 | Unauthenticated visits land on `/signin`; while auth is restoring there is **no** redirect; an authenticated `workshopAdmin` goes to `/workshop`; any other authenticated role goes to `/unauthorized` | `lib/src/admin_router.dart:26-42` | none direct (screenshots fake the session) | **UNPINNED** |
| I2 | The router instance is created once and refreshed via a `ChangeNotifier`; re-running `redirect` must never reset the sign-in form (regression that wiped typed email + error copy) | `lib/src/admin_router.dart:16-27` | none | **UNPINNED** |
| I3 | The password is never logged. Debug logging may include the email only | `packages/auth/lib/src/auth_repository.dart:54-56, 69-74` | none | **UNPINNED** |
| I4 | A successful sign-in persists the session (`SecureSessionStore.save`) and sets the API bearer token; `restore()` validates via `/auth/me` and clears the store only on 401, keeping the last session on network failure | `auth_repository.dart:30-49, 109-117` | none | **UNPINNED** |
| I5 | Failure copy mapping: `AUTH_INVALID_CREDENTIALS` → `invalidCredentials`; `NETWORK`/`CONNECTIONERROR`/`CONNECTIONTIMEOUT`/`RECEIVETIMEOUT`/`SENDTIMEOUT` → `networkError`; anything else → `genericError`; raw codes never reach the UI | `workshop_login_page.dart:74-84, 114-119` | none | **UNPINNED** |
| I6 | Multi-factor: the server can answer `requiresTwoFactor` + `challengeToken` (`AuthService.java:97-100`). The admin app deliberately ships **no** TOTP UI (`test/source_scan_test.dart:248-264`), and `ADMIN_TOTP_REQUIRED` defaults to `false` (`server/src/main/resources/application.yml:80-81`). Therefore any `AuthChallenge` result must surface a localized, actionable message — never a silent no-op | `workshop_login_page.dart:51-53` (ignores the returned `AuthResult`) | none | **VIOLATED** (silent no-op) |
| I7 | Client-side validation: email required + syntactically valid, password required; invalid input blocks the request | `workshop_login_page.dart:86-101, 254-304` | `test/widget_test.dart:130-166` (text entry only, not validation) | **PARTIAL** |
| I8 | Double submit is impossible: the submit control is disabled while a request is in flight | `workshop_login_page.dart:338-344` (`onPressed: _submitting ? null : _submit`) | none | **UNPINNED** |
| I9 | The eye toggle reveals/conceals the password without submitting or moving focus | `workshop_login_page.dart:287-297` | none | **UNPINNED** |
| I10 | Every visible string is localized in `en` **and** `ar`; the Arabic build is RTL-correct | `packages/l10n/lib/l10n/app_en.arb`, `app_ar.arb` | `test/workshop_real_font_screenshot_test.dart` captures 1280 AR | **VIOLATED** — 7 hardcoded English strings (`workshop_login_page.dart:418, 477, 521, 532, 542, 546, 578, 585`) |
| I11 | Widget keys `sign-in-email`, `sign-in-password`, `sign-in-submit` are the stable test contract | `workshop_login_page.dart:271, 281, 339` | `widget_test.dart:103-105, 179` | **PINNED** |
| I12 | The screen uses only `WorkshopTokens` (`context.ws`) and design-system primitives — no local colours, type sizes, radii, shadows or font families; layout uses a 900 px split breakpoint and a 400 px form column | `workshop_login_page.dart` (see `baseline_allowlist.md`) | 3 failing `source_scan_test.dart` rules | **VIOLATED** (allowlisted in Phase 0) |
| I13 | The role/tenancy boundary is driven by server-issued memberships, not by anything the sign-in form sends. A workshop sign-in must never reach the platform-admin surface | `admin_router.dart:38-41`, `Session.fromJson` | none | **UNPINNED** |
| I14 | The theme is light-only by decision (`AppTheme.build` asserts `Brightness.light`; dark theme removed in C0 Workstream B) | `packages/design_system/lib/src/tokens.dart:736-748` | `ui_matrix_test.dart` still iterates `Brightness.dark` | **CONTRADICTION** — tests exercise a removed mode |

## Notes

- I6 and I10 are real defects, not missing tests. Both are user-visible.
- I1/I2/I5/I8 are the invariants the rebuild must pin **before** any pixel changes (Gate 2b).
- I11 must keep working: the screenshot harness and widget tests drive the form through those keys.
- I13 is the reason a "test login" shortcut on this screen (prefilled credentials, demo button)
  is forbidden. `widget_test.dart:106` already asserts a demo-fill button is absent — keep that.
