# Auth server contract — technician app sign-in (Phase 1 data truth)

**Scope:** the five endpoints the technician sign-in screen touches, as implemented on this
commit. **Method:** static read of server code, migrations, tests and the Dart client. **No live
calls, no database, no server run.** Every row carries a status:

Companion Phase-1 artefacts for the same screen (package side, not duplicated here):
`client/apps/technician_app/docs/data/signin_client_trace.md` (client hop trace) and
`client/apps/technician_app/docs/data/inventory.md` (gate summary). This file is the **server**
contract.

| Status | Meaning |
|---|---|
| **VERIFIED** | Proven by the cited implementation/test line. |
| **ASSUMED** | Inferred from framework/library behaviour that this repo does not pin with a test. |
| **SUSPECT** | Evidence contradicts another source, or the behaviour is ambiguous/unsafe. |
| **MISSING** | The contract does not exist. |

Endpoint list (client mapping: `client/packages/api_client/lib/src/api_endpoints.dart:10-14`):

| # | Endpoint | Used by the screen for |
|---|---|---|
| 1 | `POST /api/v1/auth/login` | email + password sign-in |
| 2 | `POST /api/v1/auth/2fa/verify` | TOTP / recovery-code challenge |
| 3 | `GET /api/v1/auth/me` | session restore validation |
| 4 | `POST /api/v1/auth/logout` | profile / unauthorized-screen sign-out |
| 5 | `POST /api/v1/auth/refresh` | **never called** (see §7.4) |

Server stack: Spring Boot `4.1.2` (`server/pom.xml:9-10`), Java 25 (`server/pom.xml:21`),
stateless OAuth2 resource server, MySQL/H2 Flyway migrations.

---

## 0. Cross-cutting transport rules (apply to all five)

| Fact | Status | Evidence |
|---|---|---|
| Base URL is compile-time: `API_BASE_URL` else a hard-coded dev tunnel, `APP_ENV` default `dev` | VERIFIED | `client/packages/api_client/lib/src/api_config.dart:7-22` |
| Auth is `Authorization: Bearer <accessToken>`, attached whenever a token is set | VERIFIED | `client/packages/api_client/lib/src/api_client.dart:230-245` |
| No cookies, no server session: `SessionCreationPolicy.STATELESS` | VERIFIED | `server/src/main/java/com/truereport/shared/security/SecurityConfig.java:80` |
| **CSRF is disabled** (safe because bearer-only, no cookie auth) | VERIFIED | `server/src/main/java/com/truereport/shared/security/SecurityConfig.java:78` |
| CORS: allowed-origin **patterns** from `truereport.security.cors-allowed-origins`, default `http://localhost:*,http://127.0.0.1:*`; credentials **false**; methods GET/POST/PUT/PATCH/DELETE/OPTIONS; allowed headers `Authorization, Content-Type, Accept-Language, X-Request-Id, X-Client, Idempotency-Key, If-Match`; exposed `X-Request-Id, ETag, Location` | VERIFIED | `server/src/main/java/com/truereport/shared/security/SecurityConfig.java:106-121`; override key `server/src/main/resources/application.yml:97-98` |
| Preflight `OPTIONS /**` is permitAll; an unknown origin is rejected `403` | VERIFIED | `server/src/main/java/com/truereport/shared/security/SecurityConfig.java:85`; `server/src/test/java/com/truereport/SecurityEndpointInventoryIT.java:118-129` |
| Mobile/Flutter is not subject to CORS; the CORS rules matter only for web builds | VERIFIED by construction (no browser) | — |
| `X-Request-Id` is always sent by the client (UUIDv7); the server echoes it or generates one when absent/blank/>64 chars | VERIFIED | `client/packages/api_client/lib/src/api_client.dart:25-32`; `server/src/main/java/com/truereport/shared/web/RequestIdFilter.java:26-31` |
| The technician app never sets `acceptLanguage` or `clientName`, so no `Accept-Language`/`X-Client` header is sent on sign-in | VERIFIED (no assignment outside workshop/platform admin apps) | assignments only at `client/apps/workshop_admin_app/lib/src/api_language_sync.dart:16-18`, `client/apps/platform_admin_app/lib/main.dart:38-39`; client fields at `client/packages/api_client/lib/src/api_client.dart:61,65` |
| With no `Accept-Language`, server error `detail`/`messageEn` resolve to **English**; `?lang` beats the header | VERIFIED | `server/src/main/java/com/truereport/localization/LocaleConfig.java:35-51`; `server/src/main/java/com/truereport/shared/error/ApiExceptionHandler.java:183-201` |
| Two error writers exist: (a) Spring Security entry point for 401/403, (b) `@RestControllerAdvice` for application errors. Their `traceId` sources differ (a: client header, may be null; b: server-side MDC value) | VERIFIED | `server/src/main/java/com/truereport/shared/security/SecurityProblemWriter.java:39-51`; `server/src/main/java/com/truereport/shared/error/ApiExceptionHandler.java:157-172` |
| Application errors carry `code` + `messageKey` (+ `messageEn`/`messageAr` for unmarked clients) — the client keys off `code` only | VERIFIED | `server/src/main/java/com/truereport/shared/error/ApiExceptionHandler.java:46-59,164-171`; `client/packages/api_client/lib/src/api_client.dart:247-265` |
| Error bodies are RFC 9457-shaped. Content-Type is **explicitly** `application/problem+json` for the security writer; the `ApiException` path does not set it, so the media type is not pinned by code or test | VERIFIED / **ASSUMED** (media type) | `server/src/main/java/com/truereport/shared/security/SecurityProblemWriter.java:49`; `server/src/main/java/com/truereport/shared/error/ApiExceptionHandler.java:80,100` |

### 0.1 Error envelope — security entry point (401 / 403)

```json
{
  "type": "https://truereport.example/problems/unauthenticated",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Request denied",
  "instance": "/api/v1/auth/me",
  "code": "UNAUTHENTICATED",
  "messageKey": "error.unauthenticated",
  "traceId": "<echoed X-Request-Id, or null>"
}
```
Status **VERIFIED** (`server/src/main/java/com/truereport/shared/security/SecurityProblemWriter.java:27-51`).
`traceId` is the **request header** value, not the filter's generated value (same file, line 47);
it is `null` when the client sent none. `error.unauthenticated` has no message-bundle entry, so
`messageAr`/`messageEn` are **not** present on this path (the writer never adds them).

### 0.2 Error envelope — application exceptions

```
type, title, status, detail, instance,
code, messageKey, messageEn, messageAr, traceId
[errors[], fieldErrors[]]   // only when field issues exist
```
Status **VERIFIED** (`server/src/main/java/com/truereport/shared/error/ApiExceptionHandler.java:46-81,157-172`).
`errors` and `fieldErrors` are the same array; each item is
`{field, code, messageKey, messageEn, messageAr}` (`ApiExceptionHandler.java:58-79`;
`ApiErrorContractTest.java:80-101`). Clients sending `X-Client: platform_admin` or calling
`/api/v1/platform/**` get `messageEn`/`messageAr` **omitted**
(`ApiExceptionHandler.java:49,166-181`; `server/src/test/java/com/truereport/ApiErrorContractTest.java:118-138,197-208`).
The technician app does neither.

---

## 1. `POST /api/v1/auth/login`

| Property | Value | Status |
|---|---|---|
| Method + path | `POST /api/v1/auth/login` | VERIFIED — `server/src/main/java/com/truereport/identity/api/AuthController.java:29-33` |
| Auth requirement | Public. `@PermitAll` on the handler **and** an explicit permitAll URL entry | VERIFIED — `AuthController.java:30`; `SecurityConfig.java:86-90` |
| Role requirement | None to call. A successful password with **no ACTIVE membership** fails `403 NO_WORKSHOP_MEMBERSHIP` | VERIFIED — `server/src/main/java/com/truereport/identity/AuthService.java:330-340` |
| CSRF/CORS | Disabled CSRF / standard CORS (§0) | VERIFIED |
| Success HTTP status | **200 OK** (not 202) | VERIFIED — `AuthController.java:32`; `server/src/test/java/com/truereport/IntegrationTestBase.java:42-52` |
| Content type | `application/json` | ASSUMED (no explicit `produces`) |

### 1.1 Request schema

| Field | Type | Null? | Validation | Status |
|---|---|---|---|---|
| `email` | string | no | `@NotBlank`, `@Email`; **no max length**; trimmed + lower-cased for lookup | VERIFIED — `server/src/main/java/com/truereport/identity/api/LoginRequest.java:6-9`; `AuthService.java:82`; `server/src/main/java/com/truereport/identity/User.java:78-80` |
| `password` | string | no | `@NotBlank` only. **No length/complexity rule at login** (policy applies when setting a password) | VERIFIED — `LoginRequest.java:8`; `server/src/main/java/com/truereport/identity/PasswordPolicy.java:18-46` |
| Unknown extra fields | ignored (no `FAIL_ON_UNKNOWN_PROPERTIES` configured) | — | ASSUMED |

The client sends `{'email': email.trim(), 'password': password}` plus `X-Request-Id`
(`client/packages/auth/lib/src/auth_repository.dart:58-61`).

Request validation failure → `422 VALIDATION_FAILED` with `fieldErrors`
(`server/src/main/java/com/truereport/shared/error/ApiExceptionHandler.java:83-101`).
The client maps that code to `genericError` (`client/packages/auth/lib/src/sign_in_page.dart:81-92`).

### 1.2 Success response schema (`AuthResponse`)

Record: `server/src/main/java/com/truereport/identity/api/AuthResponse.java:5-14`.

| Field | Type | Null? | Meaning | Status |
|---|---|---|---|---|
| `accessToken` | string (HS256 JWT) | null only on challenge | Bearer token | VERIFIED — `AuthService.java:313`; `server/src/main/java/com/truereport/shared/security/JwtService.java:29-45` |
| `refreshToken` | string (43-char base64url, 32 random bytes) | null only on challenge | Opaque; only its SHA-256 is stored | VERIFIED — `AuthService.java:321-328,368-380` |
| `tokenType` | string | null only on challenge | Always the literal `"Bearer"` | VERIFIED — `AuthService.java:317` |
| `expiresInSeconds` | integer (long) | never (primitive) | Access-token TTL in seconds = **900** (`PT15M`) | VERIFIED — `AuthService.java:318`; `server/src/main/resources/application.yml:74` |
| `user` | object `UserDto` | null only on challenge | see below | VERIFIED — `AuthResponse.java:10` |
| `memberships` | array `MembershipDto` | never (empty list on challenge) | **All** ACTIVE memberships | VERIFIED — `AuthResponse.java:11,16`; `AuthService.java:206-215` |
| `requiresTwoFactor` | boolean | never | `true` only for the challenge response | VERIFIED — `AuthResponse.java:12` |
| `challengeToken` | string | null on success | Short-lived 2FA challenge JWT | VERIFIED — `AuthResponse.java:13` |

`UserDto` (`server/src/main/java/com/truereport/identity/api/UserDto.java:5`):
`id` (UUID string, non-null), `email` (string), `displayName` (string), `platformAdmin` (boolean),
`totpEnabled` (boolean). All non-null.

`MembershipDto` (`server/src/main/java/com/truereport/identity/api/MembershipDto.java:5`):
`workshopId` (UUID string), `workshopName` (string), `role` (string).
Workshop name falls back to the literal `"Unknown workshop"` if the row is gone
(`AuthService.java:209-212`).

### 1.3 `requiresTwoFactor: true` — exact conditions

Both conditions must hold at the moment of login:

1. `truereport.auth.admin-totp.required` / `ADMIN_TOTP_REQUIRED` is **true** — default **false**
   (`server/src/main/java/com/truereport/identity/AuthService.java:63-65,97`;
   `server/src/main/resources/application.yml:79-81`).
2. The user has `totpEnabled = true` (`AuthService.java:97`).

Then `AuthResponse.challenge(jwtService.issueChallenge(userId))` returns
`accessToken=null, refreshToken=null, tokenType=null, expiresInSeconds=0, user=null,
memberships=[], requiresTwoFactor=true, challengeToken=<jwt>`
(`server/src/main/java/com/truereport/identity/api/AuthResponse.java:15-17`).

Consequences, all VERIFIED from code:

- With the default config, **no technician can ever receive a challenge**, because TOTP enrolment
  is restricted to workshop/platform admins (`AuthService.java:221-223`;
  `AuthController.java:47-67`).
- If a user has TOTP enabled while the flag is **false**, login **completes with tokens and skips
  2FA entirely** (`AuthService.java:97-101`). This is a security-relevant bypass.
- A user who is admin in workshop A and technician in workshop B can still get a challenge,
  because the check is on the user, not the resolved role (`AuthService.java:97`;
  role resolution at `AuthService.java:330-340`).

Wire shape caveat: whether null fields are **serialized** or **omitted** is not pinned by any test
in this repo. `server/src/main/resources/application.yml:42-43` sets
`spring.jackson.default-property-inclusion: non_null`, but
`server/src/main/java/com/truereport/shared/config/JacksonConfig.java:12-17` defines its own
`com.fasterxml.jackson.databind.ObjectMapper`, and Boot 4.1.2's `spring-boot-starter-json` pulls
`tools.jackson.core:jackson-databind` (Jackson 3) as the framework default. Which mapper wins for
HTTP bodies is **UNVERIFIED** → status **SUSPECT**, see §9 item S1.

### 1.4 Error responses

| Status | `code` | Trigger | Evidence | Status |
|---|---|---|---|---|
| 401 | `AUTH_INVALID_CREDENTIALS` | unknown email, wrong password, status ≠ ACTIVE, or locked | `AuthService.java:82-94` | VERIFIED |
| 403 | `NO_WORKSHOP_MEMBERSHIP` | password OK, `platformAdmin=false`, no ACTIVE membership | `AuthService.java:334-338` | VERIFIED |
| 422 | `VALIDATION_FAILED` | blank/malformed email, blank password | `AuthController.java:31`; `ApiExceptionHandler.java:83-101` | VERIFIED |
| 400 | `BAD_REQUEST` | malformed JSON body → actually **unhandled**; see §9 S8 | **UNVERIFIED** | ASSUMED |
| 500 | *(none defined)* | unexpected | — | MISSING |

`AUTH_INVALID_CREDENTIALS` uses `messageKey = "error.unauthorized"`
(`server/src/main/java/com/truereport/shared/error/ApiException.java:51-53`), which resolves to
**"Authentication is required."**, *not* the `"Invalid credentials"` string passed to the factory
(`server/src/main/resources/i18n/messages_en.properties:3`;
`server/src/main/resources/i18n/messages_ar.properties:3`).
The client shows copy from its own ARB based on `code`, so this is cosmetic for the app but is a
contract/documentation trap (see §9 S6).

There is **no 429 and no `Retry-After`** on this endpoint (see §6).

### 1.5 Session semantics on login

| Fact | Status | Evidence |
|---|---|---|
| Each successful login creates a **new refresh-token family**; previous sessions are **not revoked** and there is no session cap | VERIFIED | `AuthService.java:309-319` (family = `UuidV7.generate()` at line 312); no revoke call |
| Failed logins increment `failed_login_count`; at **5** the account is locked for **15 minutes** | VERIFIED | `server/src/main/java/com/truereport/identity/User.java:150-155`; columns `server/src/main/resources/db/migration/V17__totp_recovery_and_lockout.sql:2-4` |
| While locked, every attempt returns the **same** `401 AUTH_INVALID_CREDENTIALS`, does **not** extend the lock, and is audited as `LOGIN_LOCKED` | VERIFIED | `AuthService.java:85-88` |
| The failure counter is **not reset when the lock expires**, so the next wrong password (count 6) re-locks immediately for another 15 min; only a success resets it | VERIFIED | `User.java:150-160` |
| Successful login clears the failure counter and `locked_until` | VERIFIED | `AuthService.java:95-96`; `User.java:157-160` |
| Lock test exists but is **service-level only** (no HTTP/JSON assertion) | VERIFIED | `server/src/test/java/com/truereport/AuthRecoveryIT.java:52-59` |

---

## 2. `POST /api/v1/auth/2fa/verify`

| Property | Value | Status |
|---|---|---|
| Method + path | `POST /api/v1/auth/2fa/verify` | VERIFIED — `AuthController.java:41-45` |
| Auth requirement | Public (`@PermitAll` + permitAll URL). The **challenge JWT is the credential**, carried in the body, not the `Authorization` header | VERIFIED — `AuthController.java:42`; `SecurityConfig.java:86-90` |
| Role requirement | None at the filter level; the code re-checks `adminTotpRequired` and the user's TOTP state | VERIFIED — `AuthService.java:112-120` |
| CSRF/CORS | As §0 | VERIFIED |
| Success status | **200 OK** with a full `AuthResponse` (same schema as §1.2, `requiresTwoFactor=false`, `challengeToken=null`) | VERIFIED — `AuthController.java:44`; `AuthService.java:135,141` |

### 2.1 Request schema

`server/src/main/java/com/truereport/identity/api/TwoFactorVerifyRequest.java:6-9`

| Field | Type | Null? | Validation | Status |
|---|---|---|---|---|
| `challengeToken` | string | no | `@NotBlank`; no max length | VERIFIED |
| `code` | string | **yes, allowed null** (`@NotBlank` absent) | `@Size(max = 40)` only | VERIFIED |

Client sends `{'challengeToken': ..., 'code': code}` verbatim
(`client/packages/auth/lib/src/auth_repository.dart:79-84`).

**SUSPECT (client/server mismatch):** the technician sign-in UI only accepts a code of
**exactly 6 characters** before it will submit
(`client/packages/auth/lib/src/sign_in_view.dart:196-208`), but the server also accepts
recovery codes: 10 alphabet characters formatted `ABCDE-FGHIJ` (11 chars incl. the hyphen)
(`AuthService.java:137-142,290-300`).
A technician with a recovery code cannot use this screen (keyboard is numeric as well,
`sign_in_view.dart:202`). See §9 S2.

### 2.2 Challenge token

| Fact | Value | Status |
|---|---|---|
| Format | HS256 JWT, claims `iss`, `aud`, `sub`(=userId), `iat`, `exp`, `uid`, `purpose="2fa"`; **no `jti`** | VERIFIED — `server/src/main/java/com/truereport/shared/security/JwtService.java:47-59` |
| Lifetime | `PT5M` (300 s) from `truereport.jwt.challenge-ttl` | VERIFIED — `server/src/main/resources/application.yml:76`; `JwtService.java:54` |
| Single use? | **No.** There is no server-side state and no `jti`; the token stays valid for its full TTL and can start multiple verify attempts (each still needs a fresh TOTP step or an unused recovery code) | VERIFIED (absence of any store/consumption at `AuthService.java:104-147`; `JwtService.java:47-59`) |
| Validity guard | Rejected with `AUTH_2FA_INVALID` if the token no longer decodes/verifies, or `purpose != "2fa"`, or `adminTotpRequired` is now **false** | VERIFIED — `AuthService.java:107-114` |
| Claims are trusted for identity (`uid`) — no DB nonce check | — | VERIFIED — `AuthService.java:115-117` |

Signing key is the same HMAC secret as access tokens (≥32 bytes, base64)
(`server/src/main/java/com/truereport/shared/security/SecurityConfig.java:36-56`).

### 2.3 Code rules, attempts, lockout, replay

| Fact | Value | Status |
|---|---|---|
| TOTP alphabet/length | 6 digits, HMAC-SHA1, 30-second step | VERIFIED — `server/src/main/java/com/truereport/identity/TotpService.java:16-20,38-53` |
| Accepted window | `currentStep ± 1` (i.e. up to ~90 s of tolerance) | VERIFIED — `TotpService.java:19,43` |
| Non-6-digit input | TOTP is skipped (`matches("\\d{6}")` fails) and the value is tried as a recovery code | VERIFIED — `AuthService.java:127-129,137` |
| Replay protection (TOTP) | The accepted step must be **strictly greater** than the user's stored `totp_last_step`; otherwise rejected | VERIFIED — `TotpService.java:44-49`; `AuthService.java:130-133` |
| Recovery codes | 10 codes, each 10 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` formatted `XXXXX-XXXXX` (11 chars incl. hyphen); matched case-insensitively (trim + upper-case + SHA-256); **single use** (`used_at`) | VERIFIED — `AuthService.java:266-300,277-288`; `server/src/test/java/com/truereport/AuthRecoveryIT.java:28-50` (lower-case accepted at line 39, second use rejected at lines 42-45) |
| Recovery-code count | 10 regenerated, old set deleted | VERIFIED — `AuthService.java:265-274` |
| Failed-code counter | Every failed code (TOTP **or** recovery) increments `totp_failed_count`; at **5** the account is locked for **15 minutes** | VERIFIED — `AuthService.java:143-146`; `User.java:162-167` |
| Lock check order | Locked accounts are rejected **before** code evaluation, so attempts during a lock do not extend it | VERIFIED — `AuthService.java:121-125` |
| Counter reset | Cleared on any successful TOTP/recovery verification (not on lock expiry) | VERIFIED — `AuthService.java:132,138`; `User.java:169-171` |
| Per-challenge attempt cap | **None.** The cap is per-user lockout only | VERIFIED (no counter on the challenge) |

### 2.4 Error responses

| Status | `code` | Trigger | Evidence | Status |
|---|---|---|---|---|
| 401 | `AUTH_2FA_INVALID` | undecodable/expired token, wrong `purpose`, flag off, unknown user, TOTP not enabled, locked, wrong code | `AuthService.java:110,113,116,119,124,146` | VERIFIED |
| 401 | `ACCOUNT_DISABLED` | user status ≠ ACTIVE | `AuthService.java:117,357-361` | VERIFIED |
| 422 | `VALIDATION_FAILED` | blank `challengeToken`, `code` > 40 chars | `AuthController.java:43`; `TwoFactorVerifyRequest.java:6-9` | VERIFIED |
| 400 | `BAD_REQUEST` | server-issued token with a non-UUID `uid` → `UUID.fromString` throws and is caught as `IllegalArgumentException` | `AuthService.java:115`; `ApiExceptionHandler.java:116-127` | ASSUMED (unreachable with honest tokens) |

All 2FA failures collapse to one code, so the screen cannot distinguish "expired challenge" from
"wrong code" (`AUTH_2FA_INVALID`). The client maps it to the same `invalidCredentials` copy
(`sign_in_page.dart:81-92`).

---

## 3. `GET /api/v1/auth/me`

| Property | Value | Status |
|---|---|---|
| Method + path | `GET /api/v1/auth/me` | VERIFIED — `AuthController.java:85-93` |
| Auth requirement | Bearer access token. `@PreAuthorize("isAuthenticated()")` + `anyRequest().authenticated()` | VERIFIED — `AuthController.java:86`; `SecurityConfig.java:99` |
| Role requirement | Any authenticated role (technician included) | VERIFIED — same lines |
| Request | No body, no query params | VERIFIED |
| Success status | 200 with `MeResponse` | VERIFIED — `AuthController.java:89-92` |

### 3.1 Success schema

`server/src/main/java/com/truereport/identity/api/MeResponse.java:5` —
`{ "user": UserDto, "memberships": MembershipDto[] }`, both non-null.
`memberships` = all ACTIVE memberships for the caller only
(`AuthService.java:206-215`; test `server/src/test/java/com/truereport/AuthTenancyIT.java:117-127`).
Membership order is **not specified** (no `ORDER BY` on
`findByUserIdAndStatus`, `server/src/main/java/com/truereport/tenancy/WorkshopMembershipRepository.java:12`).

### 3.2 Errors

| Status | `code` | Trigger | Evidence | Status |
|---|---|---|---|---|
| 401 | `UNAUTHENTICATED` | missing, malformed or expired access token (security entry point, §0.1) | `SecurityProblemWriter.java:27-31`; `SecurityConfig.java:81-83,100-102` | VERIFIED |
| 401 | `AUTH_TOKEN_INVALID` | token valid but the user row no longer exists | `AuthService.java:200-204` | VERIFIED |
| 403 | `FORBIDDEN` | none for this path; a valid token always passes `isAuthenticated()` | `SecurityProblemWriter.java:33-37` | VERIFIED |

Note: `/auth/me` does **not** re-check `User.status`; a disabled user's token still returns 200
until it expires (see §9 S5).

---

## 4. `POST /api/v1/auth/logout`

| Property | Value | Status |
|---|---|---|
| Method + path | `POST /api/v1/auth/logout` | VERIFIED — `AuthController.java:69-75` |
| Auth requirement | Bearer access token, `@PreAuthorize("isAuthenticated()")` | VERIFIED — `AuthController.java:70` |
| Request body | Ignored. The client sends `{}`; the schema is not declared | VERIFIED — `client/packages/auth/lib/src/auth_repository.dart:100` |
| Success status | **204 No Content**, empty body | VERIFIED — `AuthController.java:74` |
| Effect | Revokes **only** the refresh token whose id equals the token's `sid`; audited `LOGOUT`. A missing `sid` is a silent no-op. It does **not** revoke the access token or other sessions | VERIFIED — `AuthService.java:175-187`; `CurrentUserService.java:16-27` |
| Access token after logout | Remains valid until `exp` — JWT is stateless and there is no denylist | VERIFIED — `SecurityConfig.java:80`; no revocation check in `CurrentUserService`/`JwtService` |
| Multiple sessions | Old refresh families stay usable; `logout-all` exists but is **not** in the client | VERIFIED — `AuthController.java:77-83`; no Dart call site |

### 4.1 Errors

| Status | `code` | Trigger | Evidence | Status |
|---|---|---|---|---|
| 401 | `UNAUTHENTICATED` | no/invalid/expired access token | `SecurityProblemWriter.java:27-31` | VERIFIED |
| 204 | — | success, and also when the `sid` token is already revoked | `AuthService.java:180-186` | VERIFIED |

The client swallows every failure and clears local state regardless
(`client/packages/auth/lib/src/auth_repository.dart:98-107`), so a server-side logout failure is
invisible.

---

## 5. `POST /api/v1/auth/refresh`

| Property | Value | Status |
|---|---|---|
| Method + path | `POST /api/v1/auth/refresh` | VERIFIED — `AuthController.java:35-39` |
| Auth requirement | Public; the refresh token in the body is the credential | VERIFIED — `AuthController.java:36`; `SecurityConfig.java:86-90` |
| Success status | 200 with a **full `AuthResponse`** (new access token, rotated refresh token, `requiresTwoFactor=false`, `challengeToken=null`) | VERIFIED — `AuthService.java:166-172` |
| Lifetime | Refresh token TTL `P30D` | VERIFIED — `server/src/main/resources/application.yml:75` |
| Rotation | Old token is marked revoked and `replaced_by` points at the new token, same `family_id` | VERIFIED — `AuthService.java:167-169`; `server/src/main/java/com/truereport/identity/RefreshToken.java:99-106` |
| Reuse detection | Presenting an already-revoked token revokes the **entire family** and returns `AUTH_REFRESH_REUSED` | VERIFIED — `AuthService.java:154-158,347-355`; test `server/src/test/java/com/truereport/AuthTenancyIT.java:86-115` |
| Role/workshop are re-resolved on every refresh (can change mid-session) | VERIFIED — `AuthService.java:166-170,330-340` |

### 5.1 Request schema

`{ "refreshToken": string }`, `@NotBlank`, no max length
(`server/src/main/java/com/truereport/identity/api/RefreshRequest.java:4-6`;
`client/packages/auth/lib/src/auth_repository.dart:87-96`).

### 5.2 Errors

| Status | `code` | Trigger | Evidence | Status |
|---|---|---|---|---|
| 401 | `AUTH_TOKEN_INVALID` | hash not found, or user row missing | `AuthService.java:152-153,163-164` | VERIFIED |
| 401 | `AUTH_REFRESH_REUSED` | token already revoked → whole family revoked | `AuthService.java:154-158` | VERIFIED |
| 401 | `AUTH_TOKEN_EXPIRED` | past `expires_at` | `AuthService.java:159-162` | VERIFIED |
| 401 | `ACCOUNT_DISABLED` | user status ≠ ACTIVE | `AuthService.java:165,357-361` | VERIFIED |
| 403 | `NO_WORKSHOP_MEMBERSHIP` | user lost all ACTIVE memberships (raised **before** rotation) | `AuthService.java:166` | VERIFIED |
| 422 | `VALIDATION_FAILED` | blank token | `AuthController.java:37` | VERIFIED |

---

## 6. Rate limiting — MISSING

| Fact | Status | Evidence |
|---|---|---|
| There is **no rate limiter on any auth endpoint**. The only rate-limit filter in the server applies to `/r/**` and `/report/**` only. There is no `429`, no `Retry-After`, and no distinct `code` for login throttling | **MISSING** (contradicts the design doc) | `server/src/main/java/com/truereport/reports/PublicReportRateLimitFilter.java:23-33` (limit 240/min, public report paths only) |
| The design document promises "Rate limit login by IP and by account identifier; exponential backoff" | **SUSPECT** (drift) | `docs/phase-1/08-api-design.md:64` |
| The only brake is the per-account lockout (5 failures → 15 min) | VERIFIED | `User.java:150-155` |

Practical consequence: a credential-stuffing run against many emails is unthrottled. Any UI copy
about "too many attempts, try again later" would be **fabricated** — the server never sends it.
A `login-locked` sample therefore carries the same 401 body as invalid credentials.

---

## 7. Identity, roles, and tenancy on the session

### 7.1 Role values

| Fact | Status | Evidence |
|---|---|---|
| Membership roles are exactly `WORKSHOP_ADMIN` and `TECHNICIAN` (DB check constraint) | VERIFIED | `server/src/main/java/com/truereport/tenancy/WorkshopRole.java:3-6`; `server/src/main/resources/db/migration/V1__core_tenancy_auth.sql:49` |
| Token `role` claim is `PLATFORM_ADMIN`, else the single resolved membership role | VERIFIED | `AuthService.java:330-340`; `JwtService.java:38` |
| Spring maps `role` → authority `ROLE_<value>`; `/api/v1/technician/**` requires `ROLE_TECHNICIAN` | VERIFIED | `SecurityConfig.java:64-71,96-99` |
| The client models the same three values and treats an unknown role as `technician` (least privilege) | VERIFIED | `client/packages/domain/lib/src/role.dart:1-27` |
| Client role = **highest privilege across memberships**, not the server's token role | VERIFIED | `client/packages/domain/lib/src/session.dart:18-32` |
| The technician router accepts only `Role.technician`; admins are sent to `/unauthorized` after a **successful** sign-in | VERIFIED | `client/apps/technician_app/lib/src/technician_router.dart:33-47` |
| `platformAdmin` comes from the `user.platformAdmin` boolean, not a membership | VERIFIED | `AuthService.java:363-366`; `session.dart:18-21` |

**SUSPECT:** a user who is `WORKSHOP_ADMIN` in any workshop and `TECHNICIAN` in another resolves to
`Role.workshopAdmin` on the client (`session.dart:22-31`), so the technician app refuses the session
even though the server would allow technician endpoints if the token's role were `TECHNICIAN`. The
two layers use different rules for the same user.

### 7.2 Multiple workshops per technician

| Fact | Status | Evidence |
|---|---|---|
| A user **can** belong to multiple workshops: the only uniqueness is `(workshop_id, user_id)` | VERIFIED | `server/src/main/resources/db/migration/V1__core_tenancy_auth.sql:48` |
| `memberships` returns **all** ACTIVE memberships with workshop names | VERIFIED | `AuthService.java:206-215` |
| `WorkshopMember.isPrimary` exists; the token's `wid` claim is the **primary** membership, falling back to the first ACTIVE row in unspecified order | VERIFIED | `AuthService.java:334-339`; `server/src/main/java/com/truereport/tenancy/WorkshopMembership.java:36-37,76-78`; `WorkshopMembershipRepository.java:10-12` |
| The access token carries **one** `wid`; there is no per-request workshop selection or `X-Workshop` header | VERIFIED | `JwtService.java:41-43`; `SecurityConfig.java:99` |
| The client's `Session.workshopId` is `memberships.first.workshopId`, i.e. **not proven** to equal the token's `wid` | **SUSPECT** | `client/packages/domain/lib/src/session.dart:40-41` vs `AuthService.java:212` (list order unspecified) |

So: yes, a technician can belong to multiple workshops; the session picks one, and the pick is
non-deterministic when more than one row is ACTIVE and no primary is flagged.

### 7.3 Password / hashing notes (context)

| Fact | Status | Evidence |
|---|---|---|
| Passwords are verified with Argon2 (`Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8`) | VERIFIED | `SecurityConfig.java:58-61` |
| Email lookup is case-insensitive and trimmed | VERIFIED | `AuthService.java:82`; `User.java:78-80` |

### 7.4 What the technician sign-in screen actually calls

| Call | Where | Status |
|---|---|---|
| `POST /auth/login` | `client/packages/auth/lib/src/auth_repository.dart:51-77` | VERIFIED |
| `POST /auth/2fa/verify` (only when `requiresTwoFactor == true`) | `auth_repository.dart:79-85,109-117`; `client/packages/auth/lib/src/sign_in_page.dart:56-58` | VERIFIED |
| `GET /auth/me` (restore only; response body is **discarded**) | `auth_repository.dart:30-49` | VERIFIED |
| `POST /auth/logout` | `auth_repository.dart:98-107` (from `profile_sheet.dart:62-66` and `technician_router.dart:108-113`) | VERIFIED |
| `POST /auth/refresh` | implemented at `auth_repository.dart:87-96` but **`.refresh(` has zero call sites**; no 401→refresh interceptor exists | VERIFIED (repo-wide grep, no matches) |

Because `refresh()` is dead and `expiresInSeconds` is ignored, the app keeps using a 15-minute
access token until a request 401s; there is no automatic re-auth (see §9 S4).

---

## 8. Response/status matrix the screen can rely on

| Endpoint | 200 | 204 | 401 | 403 | 422 | 429 |
|---|---|---|---|---|---|---|
| login | success / 2FA challenge | — | `AUTH_INVALID_CREDENTIALS` | `NO_WORKSHOP_MEMBERSHIP` | `VALIDATION_FAILED` | **never** |
| 2fa/verify | success | — | `AUTH_2FA_INVALID`, `ACCOUNT_DISABLED` | — | `VALIDATION_FAILED` | **never** |
| me | success | — | `UNAUTHENTICATED`, `AUTH_TOKEN_INVALID` | — | — | **never** |
| logout | — | success | `UNAUTHENTICATED` | — | — | **never** |
| refresh | success | — | `AUTH_TOKEN_INVALID`, `AUTH_REFRESH_REUSED`, `AUTH_TOKEN_EXPIRED`, `ACCOUNT_DISABLED` | `NO_WORKSHOP_MEMBERSHIP` | `VALIDATION_FAILED` | **never** |

All "never" cells: no rate limiter exists (§6). The client's error switch handles only
`AUTH_INVALID_CREDENTIALS`, `AUTH_2FA_INVALID` and Dio transport codes; everything else becomes
`genericError` (`client/packages/auth/lib/src/sign_in_page.dart:81-92`), so `NO_WORKSHOP_MEMBERSHIP`
(a *successful* password on an account with no workshop) shows "Something went wrong" with no
actionable copy — see §9 S3.

---

## 9. Open items (ranked by trust impact)

| ID | Item | Status | Evidence | Needed to close |
|---|---|---|---|---|
| **S1** | Whether `AuthResponse` nulls are serialized or omitted on the wire. `spring.jackson.default-property-inclusion: non_null` vs a hand-built `com.fasterxml` `ObjectMapper` vs Boot 4.1.2's Jackson 3 default | **SUSPECT/UNVERIFIED** | `server/src/main/resources/application.yml:42-43`; `server/src/main/java/com/truereport/shared/config/JacksonConfig.java:12-17`; `server/pom.xml:57-60` | One HTTP-level MockMvc assertion on the 2FA challenge body (no container needed) |
| **S2** | Recovery codes are unreachable from the technician UI (client requires exactly 6 chars, numeric keyboard) | **SUSPECT** | `client/packages/auth/lib/src/sign_in_view.dart:196-208` vs `server/src/main/java/com/truereport/identity/AuthService.java:137-142,290-300` | Product decision: support recovery codes or hide the possibility |
| **S3** | `NO_WORKSHOP_MEMBERSHIP` (403) renders as generic error; a technician who loses their last membership cannot sign in or self-diagnose | **SUSPECT** | `server/src/main/java/com/truereport/identity/AuthService.java:334-338`; `client/packages/auth/lib/src/sign_in_page.dart:81-92` | Add a mapped code + copy |
| **S4** | No token refresh and no global 401 handling; a 15-minute access token just dies mid-shift (offline technician loses the session) | **SUSPECT** | `client/packages/auth/lib/src/auth_repository.dart:87-96` (no call sites); `server/src/main/resources/application.yml:74` | Wire an interceptor or accept the risk explicitly |
| **S5** | Access tokens are never re-checked against `User.status`; disabling an account leaves up to 15 min of valid access. `logout` does not revoke the access token | **SUSPECT** (design/ops) | `SecurityConfig.java:80,100-102`; `CurrentUserService.java:12-28`; `AuthService.java:175-187` | Accept, shorten TTL, or add a status check |
| **S6** | `AUTH_INVALID_CREDENTIALS` resolves `detail` to "Authentication is required." because `messageKey=error.unauthorized`; the factory's "Invalid credentials" text is unused | **SUSPECT** (cosmetic/observability) | `server/src/main/java/com/truereport/shared/error/ApiException.java:51-53`; `server/src/main/resources/i18n/messages_en.properties:3`; `ApiExceptionHandler.java:50-57` | Add `error.auth.invalidCredentials` or accept |
| **S7** | 2FA challenge token is replayable for its full 5 min (no `jti`, no consumption record) | **SUSPECT** (security) | `JwtService.java:47-59`; `AuthService.java:104-147` | Single-use store or accept the TOTP replay guard as sufficient |
| **S8** | Malformed JSON handling is unhandled by `ApiExceptionHandler`; status/body shape for a truncated login body is not specified | **MISSING** | no handler for `HttpMessageNotReadableException` in `server/src/main/java/com/truereport/shared/error/ApiExceptionHandler.java:46-142` | Decide and pin with a MockMvc test |
| **S9** | No committed OpenAPI document. The only artefact is a path list; schemas are generated at runtime and not diffed in CI | **MISSING** | `docs/phase-8/openapi-endpoints.md:7-16`; generator config `server/src/main/resources/application.yml:60-65` | Commit `/v3/api-docs` snapshot + contract diff |
| **S10** | No HTTP-level test asserts the login success/2FA/401 bodies or `/auth/logout`; identity tests are service-level or assert only a few `jsonPath`s | **MISSING** coverage | `server/src/test/java/com/truereport/AuthRecoveryIT.java:28-59`; `AuthTenancyIT.java:86-127` | Add MockMvc contract tests |
| **S11** | Existing admin sample claims `expiresInSeconds: 3600`, contradicting `PT15M` (=900) | **SUSPECT** (cross-app artefact) | `client/apps/workshop_admin_app/docs/data/samples/login-success.json:7` vs `server/src/main/resources/application.yml:74` | Correct that sample; do not copy it |
| **S12** | Lock counter is not reset when a lock expires, so one further failure re-locks for another 15 min | **SUSPECT** (UX) | `User.java:146-160` | Product decision |

---

## 10. How to prove the SUSPECT items without a database

All of the following are plain `@WebMvcTest`-style checks (no Testcontainers, no MySQL):

1. Mock `AuthService` and assert the JSON of `AuthResponse.challenge(...)` — settles **S1**.
2. `POST /api/v1/auth/login` with `{}` — assert `422 VALIDATION_FAILED` and the `fieldErrors` shape.
3. Anonymous `GET /api/v1/auth/me` — assert `401`, `code=UNAUTHENTICATED`, `traceId` echo.
4. `POST /api/v1/auth/logout` with no token — assert `401`; with a mocked valid token — assert `204`
   and an empty body.
5. A source/contract test that every `code` the client switches on exists in the server's known set
   (prevents **S3**-style drift).

Existing anchors worth extending:
`server/src/test/java/com/truereport/ApiErrorContractTest.java:53-78` (envelope),
`server/src/test/java/com/truereport/SecurityEndpointInventoryIT.java:44-71` (anonymous access),
`server/src/test/java/com/truereport/AuthTenancyIT.java:86-115` (refresh rotation/reuse).
