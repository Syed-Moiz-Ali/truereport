# Sign-in (`/signin`) — client data trace

Date: 2026-11-19 · App: `client/apps/technician_app` · Screen: shared `SignInPage`/`SignInView` from `client/packages/auth`
Mode: read-only investigation (Phase 1 data truth). No production file was modified to produce this.

Scope paths

- UI — `client/packages/auth/lib/src/sign_in_view.dart`, `sign_in_page.dart`
- State — `client/packages/auth/lib/src/auth_controller.dart`
- Transport — `client/packages/auth/lib/src/auth_repository.dart`, `client/packages/api_client/lib/src/{api_client,api_endpoints,api_config,problem_details}.dart`
- Models — `client/packages/domain/lib/src/{session,user,membership,role}.dart`
- Errors/validation — `client/packages/core/lib/src/{app_failure,validators}.dart`
- Locale — `client/packages/l10n/lib/src/locale_controller.dart`, `client/packages/l10n/lib/l10n/app_{en,ar}.arb`
- Server truth (used to verify, not modified) — `server/src/main/java/com/truereport/identity/*`, `server/src/main/resources/application.yml`

Legend: **VERIFIED** = every hop of the value exists in code at the cited line. **ASSUMED** = client behaviour proven, environment premise not. **SUSPECT** = trace exists but produces a misleading/wrong/incomplete result. **MISSING** = shown or expected, no source at all. **UNVERIFIED** = explicitly flagged where no proof exists.

---

## 1. Element-by-element trace

| UI element | Displayed as | Source (provider → repository → endpoint → response field) | Definition | Role/tenant scope | Status | Evidence |
|---|---|---|---|---|---|---|
| App title (visible heading) | `TrueReport` / AR `ترو ريبورت` | none (static l10n) — `AppLocalizations.appTitle` | ARB key `appTitle` | All roles / all tenants (product name, not tenant name) | VERIFIED | `sign_in_view.dart:117-123`; `app_en.arb:3`; `app_ar.arb:3`; `app_localizations_ar.dart:13` |
| Wordmark graphic (80 px box above title) | *nothing visible* — a blurred 60 px emerald pill on white | **none** | `_BrandMark` draws only `ImageFiltered(blur) + Container(Fx.glow)`; the `label` constructor arg (`:393`) is never read in `build` | — | MISSING | `sign_in_view.dart:104-107, 390-432` (glow `:411-425`); no asset/`Image` in the widget; duplicate a11y name (`:105` vs `:118`) |
| Tagline | `Vehicle inspection reports for partner workshops.` | none (static l10n) — `technicianSignInTagline` | ARB key `technicianSignInTagline` | Technician | VERIFIED | `sign_in_view.dart:132-142`; `app_en.arb:446`; `app_ar.arb:446` |
| Language switch (top-end) | `English` / `العربية`, pill segmented control | `localeProvider` (state) + `languageEnglish` / `languageArabic` (copy) | `NotifierProvider<LocaleController, Locale>` | All | VERIFIED (copy + state); persistence is SUSPECT — see row 34 | `sign_in_view.dart:84-91`; `figma_screen_kit.dart:593-684` (`:627-642`); `locale_controller.dart:5-15`; `app_en.arb:11-12` |
| Email field | hint + a11y name `Email` / `البريد الإلكتروني`; LTR; email keyboard; autofill `email` | none (static) — `emailLabel`; input is user data | `FxTextField.hint` only (no floating label) | All | VERIFIED (copy) — placeholder-only labelling is a usability defect, not a data defect | `sign_in_view.dart:155-169` (`hint :163`); `figma_screen_kit.dart:552-581` (`hintText :577`); `app_en.arb:6` |
| Password field | hint `Password` / `كلمة المرور`; obscured; eye icon `1_7107` reveals | none (static) — `passwordLabel` | `obscure: _obscurePassword` local UI state | All | VERIFIED | `sign_in_view.dart:171-193` (reveal `:354-388`); `app_en.arb:7` |
| 2FA code field | `Authentication code` / `رمز المصادقة`; numeric keyboard; appears only after challenge | none (static) — `twoFactorLabel`; local validator | rendered iff `widget.challenge` | Only when `requiresTwoFactor: true` (see row 7b) | SUSPECT | `sign_in_view.dart:194-209`; `app_en.arb:9`; server recovery codes are 11 chars (`AuthService.java:290-300`) — see §3 |
| 7b. 2FA reachability for a technician | nothing shown | deployed env `ADMIN_TOTP_REQUIRED` + `user.totpEnabled` | login challenges only when `adminTotpRequired && isTotpEnabled`; verify 401s when `!adminTotpRequired` | Technicians | ASSUMED | default is `false` (`application.yml:80-81`), so no challenge is ever issued and `verify` always fails (`AuthService.java:97, 112-114`); technicians cannot enrol (`AuthService.java:221-223`, `AuthController.java:54-56`); prod value UNVERIFIED |
| `Password help` line (right-aligned under password) | `Password help` / `مساعدة كلمة المرور` | none (static l10n) — `technicianPasswordHelp` | plain `Text`, **no gesture, no route** | Technician | MISSING | `sign_in_view.dart:210-222` (text `:214-220`); copy `app_en.arb:494`; no reset route in the app (`grep` over `apps/technician_app/lib` → 0 hits); no self-service reset endpoint exists (`AuthController.java:29-93`; only admin-initiated `/platform/users/{id}/password-reset`, `api_endpoints.dart:21-22`) |
| Primary button label | `Sign in` → `Verify` in challenge state | none (static l10n) — `signInButton` / `verifyButton`, selected on `challenge` | `challenge = _challengeToken != null` | All | VERIFIED | `sign_in_view.dart:248-264` (`:250-252`); `sign_in_page.dart:131`; `app_en.arb:8,10` |
| Primary button enabled state | disabled while submitting | `_submitting` local state | set `true` before await, `false` in `finally` | All | VERIFIED (but keyboard bypass — row 22) | `sign_in_view.dart:253-255`; `sign_in_page.dart:41-44, 74-78` |
| Access / help line | `Need technician login?` + `Get help` (green, styled as link) | none (static l10n) — `technicianNeedTechnicianAccess`, `technicianContactAdmin` | two plain `Text` widgets in fixed slots | Technician | MISSING (action) — both are non-interactive; `Get help` is `Fx.deepGreen` like a link but has no tap target, no mailto, no route | `sign_in_view.dart:280-311` (prompt `:285-296`, action `:298-308`); slot widths `:455-456`; copy `app_en.arb:495-496`; test pins copy only (`test/widget_test.dart:84-86`) |
| Security line (footer) | shield icon `1_7128` + `Authorised workshop staff only` / `لفنيي الورشة المعتمدين فقط` | none (static l10n) — `technicianSecurityLine` | plain `Text` + icon | All | VERIFIED as copy; it is a static assurance string, not a computed security state | `sign_in_view.dart:313-336`; `app_en.arb:534`; `app_ar.arb:534` |
| Error text — invalid credentials | `Email or password is incorrect.` | server `ProblemDetail.code = AUTH_INVALID_CREDENTIALS` → `_messageFor` → `invalidCredentials` → l10n | `AppFailure.code` only; `messageKey`/`detail` ignored | All | VERIFIED | `sign_in_page.dart:81-92` (`:83`), `:105-110`; `auth_repository.dart:68-76`; server `AuthService.java:83,87,93`; `api_client.dart:247-265`; `app_en.arb:19` |
| Error text — network | `Cannot reach the server. Check your connection.` | `DioExceptionType.name.toUpperCase()` → `CONNECTIONERROR`/`CONNECTIONTIMEOUT`/… → `networkError` | fallback `AppFailure(code: <TYPE>, messageKey: 'error.network')` | All | SUSPECT | mapping `sign_in_page.dart:85-89`; producer `api_client.dart:260-264`; **no** `connectTimeout`/`sendTimeout`/`receiveTimeout` is configured (`api_client.dart:24` sets only `baseUrl`; grep over `packages/api_client` → 0), so the timeout branches are dead and a hung socket leaves the button disabled forever |
| Error text — 2FA failure | `Email or password is incorrect.` (in the verify state) | `AUTH_2FA_INVALID` → `invalidCredentials` | same mapping as login | Challenge state | SUSPECT | `sign_in_page.dart:84`; server reuses `AUTH_2FA_INVALID` for expired/forged challenge, 2FA-not-enabled, lockout and wrong code (`AuthService.java:110,113,116,119,124,146`) — copy misdescribes all of them; no "code expired" message |
| Error text — any other code | `Something went wrong. Try again.` | `_ => 'genericError'` | closed string switch | All | SUSPECT | `sign_in_page.dart:90`; `app_en.arb:21`; codes that land here today: `ACCOUNT_DISABLED` (`AuthService.java:359`), `NO_WORKSHOP_MEMBERSHIP` (`:337`), `VALIDATION_FAILED` (`ApiExceptionHandler.java:93`), `AUTH_TOKEN_INVALID`, `UNKNOWN` (`problem_details.dart:21`), `BADRESPONSE` (non-JSON error body, `api_client.dart:260-264`), any 429 |
| Server message / messageKey / detail / field `errors[]` / traceId | **not shown anywhere** | `ApiFailure.messageKey`, `.traceId`, `.detail`, `.errors` | `AppFailure` carries them; page reads only `code` | All | MISSING | `app_failure.dart:10-14`; `api_client.dart:251-258, 267-279`; `sign_in_page.dart:63,67` (prints `code` only); server populates `code/messageKey/detail/traceId` (`ApiExceptionHandler.java:164-170`) — all discarded, so a support ticket cannot be tied to a request |
| Validation — required | `This field is required.` | `_required` | `value == null \|\| value.trim().isEmpty` | All | VERIFIED | `sign_in_page.dart:94-99`; `app_en.arb:23`; `app_ar.arb:23` |
| Validation — email format | `Enter a valid email address.` | `Validators.email` regex | `^[^@\s]+@[^@\s]+\.[^@\s]+$` | All | VERIFIED — see §3 for exact semantics | `validators.dart:4, 7-16`; `sign_in_page.dart:121-129`; `app_en.arb:24` |
| Validation — password | required only (no length, no complexity) | `_required` reused as password validator | `Validators.password` (min 8) exists but is **not** wired | All | VERIFIED (deliberate: login must not echo policy) — but a 1-character password is accepted locally and POSTed | `sign_in_page.dart:130`; `sign_in_view.dart:185`; `validators.dart:18-23` (no callers) |
| Validation — 2FA code | `This field is required.` for anything that is not exactly 6 chars | inline closure | `(value ?? '').length == 6 ? null : requiredField` | Challenge | SUSPECT | `sign_in_view.dart:204-207`; server accepts `\d{6}` **or** an 11-char recovery code (`AuthService.java:127-129, 137-142, 290-300`), so recovery codes are unenterable; `ABCDEF` passes the client check |
| Submit re-entry (keyboard) | — | `onFieldSubmitted` → `onSubmit` bypasses the disabled button | `_submit` never checks `_submitting` | All | SUSPECT | `sign_in_view.dart:184`; `sign_in_page.dart:33-38`; two concurrent `POST /auth/login` possible |
| Sent — email | not displayed as a value, only as typed | controller → `email.trim()` | body field `email` | — | VERIFIED | `auth_repository.dart:58-61` (`:60`); trims at send; server normalizes again (`AuthService.java:82`) |
| Sent — password | never displayed | controller, **untrimmed** | body field `password` | — | VERIFIED (correctly untrimmed, never logged: `sign_in_page.dart:40` prints email only) | `auth_repository.dart:60`; server `LoginRequest.java:6-9` |
| Sent — 2FA | — | `verifyTwoFactor` | body `{challengeToken, code}`; `code` raw, no trim, no formatter | Challenge | VERIFIED body; untrimmed code | `auth_repository.dart:79-85` (`:82`); `sign_in_view.dart:196-208` (no `inputFormatters`); server `AuthService.java:105-147` |
| Sent — headers | — | `X-Request-Id: <uuid v7>` (interceptor) + Dio default JSON content type; **no** `Authorization`, **no** `Accept-Language`, **no** `X-Client` | `_authHeaders()` adds only token/language/client when set | — | SUSPECT | `api_client.dart:25-32, 69-83, 230-245`; technician app never sets `acceptLanguage`/`clientName` (contrast `apps/workshop_admin_app/lib/src/api_language_sync.dart:16-18`, `apps/platform_admin_app/lib/main.dart:38-39`) |
| Sent — endpoint + base URL | — | `POST {baseUrl}/api/v1/auth/login`; verify at `/api/v1/auth/2fa/verify` | compiled default `https://56zk48dj-8080.inc1.devtunnels.ms` | — | SUSPECT | `api_config.dart:7-16`; `api_endpoints.dart:11-12`; no `API_BASE_URL`/`--dart-define` in any CI workflow (`grep` over `.github` → only `ci.yml:29` working dir) |
| Not displayed — role | — | `Session.role` = `platformAdmin` flag else highest-privilege membership | privilege order platformAdmin 3 > workshopAdmin 2 > technician 1 | Drives the route guard | SUSPECT | `session.dart:18-38`; guard `technician_router.dart:43-46`; server instead puts the **primary/first** membership's role in the JWT (`AuthService.java:330-340`) and sends no role field (`AuthResponse.java:5-17`) — client re-derives it differently |
| Not displayed — workshopId | — | `memberships.isEmpty ? null : memberships.first.workshopId` | first element of the memberships array | Tenant scope | SUSPECT | `session.dart:40-41`; server orders/picks primary membership (`AuthService.java:334-339`), so a multi-workshop user can be scoped differently in UI than in the token |
| Not displayed — memberships list | — | `memberships[]` `{workshopId, workshopName, role}` | `List<Membership>` | Used only for role/workshop derivation; never rendered on this screen | VERIFIED | `session.dart:47-49`; `membership.dart:3-18`; `MembershipDto.java:5`; `AuthService.java:206-215` |
| Not displayed — token type / expiry | — | server sends `tokenType: "Bearer"`, `expiresInSeconds: 900` | **not parsed** — absent from `Session` | — | MISSING | `AuthResponse.java:7-9`; `application.yml:74` (`access-ttl: PT15M`); `session.dart:13-16, 43-50`; `refresh()` exists but has zero callers (`auth_repository.dart:87-96`) |
| Not displayed — unknown/missing role string | silently treated as technician | `Role.fromApi(...) ?? Role.leastPrivilege` | `leastPrivilege = Role.technician` | Routing | SUSPECT | `role.dart:10-17, 25`; `membership.dart:17`; a newer server role yields the technician surface while the JWT keeps the unknown role, so `/technician/*` calls 403 after a "successful" login; pinned only in `apps/workshop_admin_app/test/signin_behaviour_fixes_test.dart`, never in technician tests → technician behaviour UNVERIFIED by test |
| Not displayed — missing keys in the auth response | — | `Session.fromJson` casts | `memberships` defaults to `[]`; every other key is a non-null cast | — | SUSPECT | `session.dart:44-49`; missing `accessToken`/`refreshToken`/`user`/`workshopId`/`workshopName` or a non-string `role` throws `TypeError`, not `AppFailure`, so it lands in `catch (error)` → `genericError` (`sign_in_page.dart:68-73`) and is indistinguishable from a network fault; a missing `memberships` key silently becomes a "technician with no workshop" |
| Not displayed — role/tenant in the session store | — | raw response JSON saved to secure storage | key `truereport.session`; `jsonDecode` unguarded | — | SUSPECT | `session_store.dart:17-36` (decode `:32` throws on corrupt/older payload inside `AuthController.build`, `auth_controller.dart:36-39`) |
| Locale persistence | — | `localeProvider` only | `LocaleController.build() => const Locale('en')`; no disk write | — | SUSPECT | `locale_controller.dart:11-15`; `shared_preferences` exists in the app but only for UI messages and technician prefs (`ui_message_cache.dart:32-53`, `clean_shared.dart:212`); sign-out does not reset it (`auth_controller.dart:73-76`) |
| Numbers / dates on this screen | none | — | no `intl`, no number/date/currency formatting | — | VERIFIED (nothing to mistranslate); only `_M` px constants | `sign_in_view.dart:1-5` (imports), `:434-459` |

Counts (37 traced rows): **VERIFIED 17 · ASSUMED 1 · SUSPECT 14 · MISSING 5** (UNVERIFIED is used as a caveat inside the unknown-role row, not as a row status).

---

## 2. `Session.fromJson` — exact contract

`session.dart:43-50`

| JSON key | Type read | Default | Failure mode |
|---|---|---|---|
| `accessToken` | `String` (non-null cast, `:44`) | none | `TypeError` if absent/null/non-string |
| `refreshToken` | `String` (`:45`) | none | `TypeError` |
| `user` | `Map<String,dynamic>` → `User.fromJson` (`:46`) | none | `TypeError` if absent; `User` then requires `id`, `email`, `displayName` as non-null `String` (`user.dart:17-19`) |
| `user.platformAdmin` | `bool?` (`user.dart:20`) | `false` | wrong type → `TypeError` |
| `user.totpEnabled` | `bool?` (`user.dart:21`) | `false` | wrong type → `TypeError` |
| `memberships` | `List?` (`session.dart:47`) | `[]` (null-safe `?? []`) | non-list → `TypeError` |
| `memberships[].workshopId` | `String` (`membership.dart:15`) | none | `TypeError` |
| `memberships[].workshopName` | `String` (`membership.dart:16`) | none | `TypeError` |
| `memberships[].role` | `String?` → `Role.fromApi` (`membership.dart:17`) | `Role.technician` | unknown string → technician; non-string → `TypeError` |

Derived (never read from JSON): `role` (`session.dart:18-32`) = `platformAdmin` if the user flag is set, else max-privilege membership; `workshopId` (`:40-41`) = `memberships.first.workshopId` or `null`.
Ignored server fields: `tokenType`, `expiresInSeconds`, `requiresTwoFactor`, `challengeToken` (`AuthResponse.java:5-17`). `requiresTwoFactor`/`challengeToken` are read separately in `_handleAuthJson` (`auth_repository.dart:109-117`) before `Session.fromJson` is called.

**Missing workshop:** no explicit error. Empty/absent `memberships` → `role = technician`, `workshopId = null`, and the technician router still admits the user to `/jobs` (`technician_router.dart:43-46`). The server also refuses to mint a token for a user with no active membership (`AuthService.java:337-338`, `NO_WORKSHOP_MEMBERSHIP`), so this state is only reachable through a contract change — the client has no guard for it.
**Unknown role:** `Role.fromApi` returns `null` → `Role.leastPrivilege` = technician (`role.dart:10-17, 25`), documented as deliberate. Consequence: a server role the client does not know is silently presented as a technician login while the JWT keeps the real role, so subsequent API calls fail with 403 while the UI claims success.

---

## 3. Error-code mapping (server → UI)

Producer: `ApiClient._toFailure` (`api_client.dart:247-265`) reads `code` from the RFC-7807 body (`problem_details.dart:20-27`, default `'UNKNOWN'`); if the error body is not a JSON object it synthesises `code = DioExceptionType.name.toUpperCase()` and `messageKey = 'error.network'`.

| Server/transport code | UI string | Evidence |
|---|---|---|
| `AUTH_INVALID_CREDENTIALS` | `Email or password is incorrect.` | `sign_in_page.dart:83`; `app_en.arb:19`; emitted `AuthService.java:83,87,93` |
| `AUTH_2FA_INVALID` | `Email or password is incorrect.` | `sign_in_page.dart:84`; emitted for wrong/expired code, forged challenge, 2FA disabled, lockout `AuthService.java:110,113,116,119,124,146` |
| `NETWORK`, `CONNECTIONERROR`, `CONNECTIONTIMEOUT`, `RECEIVETIMEOUT`, `SENDTIMEOUT` | `Cannot reach the server. Check your connection.` | `sign_in_page.dart:85-89`; `app_en.arb:20`; producer `api_client.dart:260-264` |
| anything else | `Something went wrong. Try again.` | `sign_in_page.dart:90`; `app_en.arb:21` |
| non-`AppFailure` throw (e.g. `TypeError` from a model cast) | `Something went wrong. Try again.` | `sign_in_page.dart:68-73` |

Observed-but-unmapped codes that reach `genericError` in this flow: `ACCOUNT_DISABLED` (401, `AuthService.java:359`), `NO_WORKSHOP_MEMBERSHIP` (403, `:337`), `VALIDATION_FAILED` (422, `ApiExceptionHandler.java:93`), `AUTH_TOKEN_INVALID` (`:153`), `UNKNOWN` (`problem_details.dart:21`), `BADRESPONSE` (`api_client.dart:260-264`), any 429.
`NETWORK` itself is never produced by `api_client.dart` — it is a legacy/defensive case.
`ApiFailure.errors` (`api_client.dart:16-19, 267-279`) is never read by the page: server field-level messages (`messageKey`, `messageEn`, `messageAr` — `ApiExceptionHandler.java:67-74`) are dropped.

---

## 4. Validation — exact rules

- **Email** (`sign_in_page.dart:121-129`): trimmed emptiness check first (`_required`, `:94-99`), then `Validators.email` (`validators.dart:7-16`). Regex `^[^@\s]+@[^@\s]+\.[^@\s]+$` (`:4`): requires one `@`, at least one char each side, and a dot with at least one char after it; rejects whitespace; has no max length, no IDN/unicode handling, and accepts odd shapes such as `a@b..c` and `a@b.c.`. Message is the fixed `invalidEmail`, not the validator's `'error.email.invalid'` key (`validators.dart:13`, never surfaced).
- **Password**: only non-blank (`sign_in_page.dart:130` → `_required`). `Validators.password` (min 8, `validators.dart:18-23`) exists but has **no callers** in the client, so no complexity/length policy is enforced on login. No trim (correct). No max length.
- **Password complexity**: not enforced on login anywhere client-side; server only enforces `@NotBlank` at login (`LoginRequest.java:6-9`) and `@Email` on the address. Policy is enforced at account creation, not sign-in.
- **2FA code** (`sign_in_view.dart:204-207`): accepts any string whose length is exactly 6, otherwise `requiredField`. No digits-only check, no `maxLength`, no `inputFormatters`, no trim. The server accepts 6 digits **or** an 11-character recovery code (`AuthService.java:127-129` for TOTP, `:137-142` + `:290-300` for `ABCDE-FGHIJ` recovery codes). Client and server disagree in both directions.
- **Submission gate**: `_formKey.currentState.validate()` (`sign_in_page.dart:34`) then `signIn`/`verifyTwoFactor` (`:46-52`). No `_submitting` re-entry guard (`:33-38`), so `onFieldSubmitted` (`sign_in_view.dart:184`) can fire a second request.

---

## 5. Locale / language

- Stored **in memory only**: `localeProvider = NotifierProvider<LocaleController, Locale>` (`locale_controller.dart:5-7`); `build() => const Locale('en')` (`:11`); `setLocale` just assigns state (`:13-15`). Nothing is written to `SharedPreferences`/secure storage for the locale — the two persisted stores in the technician app hold UI messages and inspection drafts (`ui_message_cache.dart:32-53`, `clean_shared.dart:212`).
- **Resets**: every cold start and every new `ProviderScope` returns English. It survives sign-out within the same process because `AuthController.signOut` only clears the session (`auth_controller.dart:73-76`).
- Consumed by `MaterialApp.router` (`app.dart:12, 19`, theme direction `:17`) and the switch itself (`sign_in_page.dart:104, 116-119`; `sign_in_view.dart:84-91`).
- **Not sent to the server** from this app: `ApiClient.acceptLanguage` is never assigned, so no `Accept-Language` header (`api_client.dart:236-239`) — irrelevant to visible copy because the UI maps `code` → local ARB, but it means server-localized `detail`/`errors` would be English if they were ever displayed.
- **Numbers/dates on this screen**: none. The only literals are pixel metrics (`sign_in_view.dart:434-459`), and the file imports no `intl`/date formatting (`:1-5`). Nothing on `/signin` can display a mis-scoped number, currency, or date.

---

## 6. Shown but not real data (no source — do not invent one)

1. **The wordmark** — an empty blurred pill; `_BrandMark.label` is passed but never rendered (`sign_in_view.dart:390-432`). No asset, no SVG. MISSING.
2. **`Password help`** — l10n string only, no tap handler and no destination anywhere in the app or API (`sign_in_view.dart:210-222`; `AuthController.java:29-93` has no reset route). MISSING.
3. **`Get help`** — styled as an interactive link (`Fx.deepGreen`) but is a bare `Text` (`sign_in_view.dart:298-308`). MISSING action; copy is real.
4. **`Need technician login?`** — same row, static prompt with no follow-up ("contact your workshop admin") other than a non-tappable label. Copy is real, promise is not delivered.
5. **Security line** — "Authorised workshop staff only" is a static caption, not a computed control or policy check (`sign_in_view.dart:313-336`).
6. **`MaterialApp.title` "TrueReport Technician"** (`app.dart:15`) — OS task-switcher chrome, not on-screen data; the builder is not visible in-app.

---

## 7. Answers in brief

1. **`Session.fromJson`** — four keys; `accessToken`/`refreshToken`/`user` are non-null casts, `memberships` null-safe to `[]`; `platformAdmin`/`totpEnabled` default `false`; unknown role → technician (`role.dart:25`); missing workshop → `workshopId = null`, role technician, no error (`session.dart:40-41`).
2. **Error mapping** — 2 codes → `invalidCredentials`, 5 transport names → `networkError`, everything else → `genericError`; unlisted codes lose all distinction and the server `traceId`/`messageKey`/`errors[]` are dropped (`sign_in_page.dart:81-92, 105-110`).
3. **Validation** — email required + regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`; password required only (no 8-char rule at login); 2FA exactly 6 chars of any kind (recovery codes impossible).
4. **Locale** — in-memory notifier, default `en`, reset on cold start, no `Accept-Language`; no numbers/dates on this screen.
5. **Not real** — wordmark, "Password help", "Get help", security caption: marked MISSING, no source invented.
6. **ASSUMED/SUSPECT** — the reason is stated in each affected row's Evidence column (2FA reachability and recovery-code mismatch, dead network-timeout branches, 2FA error copy, unlisted codes, double submit, missing headers, dev-tunnel base URL, role/workshop derivation, unknown-role downgrade, unguarded model casts, locale reset).

---

## 8. Top trust issues (ranked)

1. **Role/tenant re-derivation disagrees with the token.** Client picks max-privilege membership (`session.dart:18-32`) and `memberships.first` for the workshop; server mints the token from the primary membership (`AuthService.java:330-340`) and returns no role/workshop field (`AuthResponse.java:5-17`). A technician who is also admin elsewhere is sent to `/unauthorized` (`technician_router.dart:43-45`); an admin who is technician elsewhere is routed to the technician app while the token says otherwise.
2. **Silent privilege downgrade.** Unknown role → technician UI (`role.dart:10-17, 25`) with a token carrying the unknown role: "login succeeded", then every `/technician/*` call 403s.
3. **Failure copy is not the server's truth.** `AUTH_2FA_INVALID` says "Email or password is incorrect."; `ACCOUNT_DISABLED`/`NO_WORKSHOP_MEMBERSHIP`/422/429 all say "Something went wrong."; `traceId` and field `errors[]` are discarded (`sign_in_page.dart:81-92`; `api_client.dart:251-258`).
4. **Two affordances that cannot work and one that can double-fire.** "Password help" and "Get help" have no action and no endpoint; the 2FA validator rejects the server's own recovery codes; Enter can submit twice while the button is disabled (`sign_in_view.dart:184, 204-207, 210-222, 298-308`).
5. **Session carries no lifetime and the build points at a dev tunnel.** `expiresInSeconds` is never parsed and `refresh()` is never called (`session.dart:13-16`; `auth_repository.dart:87-96`), while the default base URL is a compiled dev tunnel used by CI (`api_config.dart:7-8`; no `API_BASE_URL` in `.github`).

Artifact: `client/apps/technician_app/docs/data/signin_client_trace.md`
