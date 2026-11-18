# Phase 1 — Data inventory: Workshop Admin sign-in

Investigate-only. No app code changed. Method: read the client call path
(`workshop_login_page.dart` → `auth_controller.dart` → `auth_repository.dart` → `api_client.dart`)
and the server producer (`AuthController`, `AuthService`, `AuthResponse`, `ApiExceptionHandler`).
No live capture was possible (no server running in this session) — that is recorded as a gap, not
hidden.

Legend: **VERIFIED** = proven from producer code; **ASSUMED** = consistent with code but not
exercised; **SUSPECT** = a known contradiction or unexplained behaviour; **MISSING** = no source.

## Every element visible on the screen

| # | Element | Where | Source of truth | Status |
|---|---|---|---|---|
| 1 | `TrueReport` wordmark (both layouts) | :177, :400 | hardcoded literal; `appTitle` key exists but is unused here | **ASSUMED** (brand constant, single-source it) |
| 2 | `Workshop Admin` portal label | :185, :407 | `l10n.signInPortalLabel` | **VERIFIED** |
| 3 | Brand headline `Inspections your customers can trust.` | :418 | **hardcoded English literal**, no l10n key | **MISSING** (copy not keyed) |
| 4 | Brand value line | :429 | `l10n.signInBrandLine` | **VERIFIED** |
| 5 | Preview card title `2023 Porsche 911 GT3` | :477 | hardcoded literal, no API source | **FABRICATED — DECORATIVE** (Gate 0: keep + localize) |
| 6 | Status pill `In progress` | :505 | `l10n.statusInProgress` | **VERIFIED** (copy), data is FABRICATED |
| 7 | Plate `DXB 48291` | :521 | hardcoded literal; `fontFamily: 'monospace'` unregistered | **FABRICATED**, and **SUSPECT** (renders as tofu) |
| 8 | Customer `Rashid Al Mansoori` | :532 | hardcoded literal | **FABRICATED** |
| 9 | `Inspection checklist` | :542 | hardcoded literal | **FABRICATED** |
| 10 | `18 / 24 items (75%)` | :546 | hardcoded literal | **FABRICATED**; arithmetic **VERIFIED** (18/24 = 75.0%); AR render reorders to `items (75%) 24 / 18` (**SUSPECT — bidi**) |
| 11 | Progress bar `value: 0.75` | :561 | hardcoded 0.75 | **FABRICATED**, consistent with #10 |
| 12 | Technician `Karim Ahmed · Lead Tech` | :571, :578 | hardcoded literal + hardcoded role string | **FABRICATED** |
| 13 | `Started 45m ago` | :585 | hardcoded literal | **FABRICATED** |
| 14 | `Sign in` title | :261 | `l10n.signInTitle` | **VERIFIED** |
| 15 | `Use your workshop account.` subtitle | :266 | `l10n.signInSubtitle` | **VERIFIED** |
| 16 | `Email` / `Password` labels | :273, :283 | `l10n.emailLabel`, `l10n.passwordLabel` | **VERIFIED** |
| 17 | Field validation copy | :88, :100 | `l10n.requiredField`, `l10n.invalidEmail` | **VERIFIED** |
| 18 | Error banner copy | :114-119 | `AppFailure.code` → `l10n.invalidCredentials / networkError / genericError` | **VERIFIED** (see contracts §Error) |
| 19 | Submit label + spinner | :340-343 | `l10n.signInButton`; `WorkshopButton.isLoading` | **VERIFIED** |
| 20 | Help line | :348 | `l10n.signInHelp` | **VERIFIED** |
| 21 | Language toggle | :122 | `l10n.languageEnglish / languageArabic` | **VERIFIED** |
| 22 | Destination after success | `admin_router.dart:38-41` | `Session.role` ← `user.platformAdmin` / `memberships` | **SUSPECT** (see gap G4) |

## Numbers the screen shows

Only one: **18 / 24 → 75%**. It is fabricated decorative content, and it is internally consistent
(18/24 = 0.75). The defect is presentation, not arithmetic: the string is concatenated, so Arabic
reorders the operands. Fix = localized message with number placeholders, not string concat.

## Cross-checks performed

| Check | Result |
|---|---|
| `AuthResponse` JSON keys vs client `Session.fromJson` | ✅ match (`accessToken`, `refreshToken`, `user`, `memberships`); extra `tokenType`/`expiresInSeconds` correctly ignored |
| `MembershipDto.role` values vs client `Role.apiValue` | ✅ `TECHNICIAN` / `WORKSHOP_ADMIN` / `PLATFORM_ADMIN` match |
| Error body vs client `ProblemDetails.fromJson` | ✅ `code`, `messageKey`, `detail`, `traceId`, `status` all mapped |
| `AUTH_INVALID_CREDENTIALS` is what the login endpoint actually throws | ✅ `AuthService.java:83, 87, 93` — every credential/lockout path uses that one code |
| Client network-code switch covers what `_toFailure` can produce | ✅ `CONNECTIONERROR`/`CONNECTIONTIMEOUT`/`RECEIVETIMEOUT`/`SENDTIMEOUT` covered; `UNKNOWN` and `BADCERTIFICATE` fall to `genericError` (acceptable) |
| Login rate limiting (would need a 429 branch) | ✅ none on `/auth/login`; 429 exists only for delivery + public report links |
| 2FA challenge shape | ✅ `AuthResponse.challenge(...)` = all tokens null, `requiresTwoFactor: true`, `challengeToken` set |
| Arabic strings exist for every `l10n` key the screen uses | ✅ except the 8 hardcoded literals in the table |
| `/auth/me` body is used | ✅ not used — `restore()` only needs the 200/401 status (documented, not a bug) |
