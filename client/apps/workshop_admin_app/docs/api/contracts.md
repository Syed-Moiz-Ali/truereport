# API contracts — Workshop Admin sign-in

Derived from the producer code, not from a live capture:

- `server/src/main/java/com/truereport/identity/api/AuthController.java`
- `server/src/main/java/com/truereport/identity/AuthService.java`
- `server/src/main/java/com/truereport/identity/api/AuthResponse.java`
- `server/src/main/java/com/truereport/identity/api/UserDto.java`, `MembershipDto.java`
- `server/src/main/java/com/truereport/shared/error/ApiExceptionHandler.java`
- client: `packages/api_client/lib/src/api_client.dart`, `problem_details.dart`,
  `packages/domain/lib/src/session.dart`, `membership.dart`, `role.dart`,
  `packages/auth/lib/src/auth_repository.dart`

Samples in `docs/data/samples/` are **constructed to this contract** and marked accordingly.

## POST `/api/v1/auth/login`

Request — `application/json`, no auth header:

```json
{ "email": "admin.a@truereport.test", "password": "<password>" }
```

`email` is sent already trimmed (`auth_repository.dart:60`). Response `200 OK` is one of **two**
shapes:

### 1. Success (2FA not required)

```json
{
  "accessToken": "<jwt>",
  "refreshToken": "<opaque>",
  "tokenType": "Bearer",
  "expiresInSeconds": 3600,
  "user": {
    "id": "<uuid>",
    "email": "admin.a@truereport.test",
    "displayName": "Admin A",
    "platformAdmin": false,
    "totpEnabled": false
  },
  "memberships": [
    { "workshopId": "<uuid>", "workshopName": "Workshop A", "role": "WORKSHOP_ADMIN" }
  ],
  "requiresTwoFactor": false,
  "challengeToken": null
}
```

Client handling: `requiresTwoFactor != true` → `Session.fromJson(json)`, API token set,
`SecureSessionStore.save(json)` (`auth_repository.dart:109-117`). Keys the client requires:
`accessToken`, `refreshToken`, `user.{id,email,displayName,platformAdmin,totpEnabled}`,
`memberships[].{workshopId,workshopName,role}`. `tokenType` and `expiresInSeconds` are ignored
by the client — do not build UI that depends on them.

### 2. Challenge (2FA required)

```json
{
  "accessToken": null,
  "refreshToken": null,
  "tokenType": null,
  "expiresInSeconds": 0,
  "user": null,
  "memberships": [],
  "requiresTwoFactor": true,
  "challengeToken": "<short-lived jwt, purpose=2fa>"
}
```

Client handling: `auth_repository.dart:110-112` returns `AuthChallenge(challengeToken)`; the
session store is **not** written. The screen currently discards this result
(`workshop_login_page.dart:51-53`) — that is the F4 defect. Contract requirement: the screen must
branch on `AuthChallenge` and show localized copy; it must **not** call `/auth/2fa/verify`
(`source_scan_test.dart:248-264` forbids TOTP UI in this app).

## POST `/api/v1/auth/refresh`

Request `{ "refreshToken": "<opaque>" }` → same success shape. Not used by the sign-in screen.
`refresh()` does not distinguish a challenge response (unreachable for refresh).

## GET `/api/v1/auth/me`  (Bearer)

Returns `{ user: {...}, memberships: [...] }`. The client only consumes the **status code**:
`401` → clear the session, anything else → keep the stored session (offline-tolerant restore,
`auth_repository.dart:30-49`). Do not add UI that renders `/auth/me` fields without a new contract
entry.

## POST `/api/v1/auth/logout`  (Bearer)

Always succeeds locally: `AppFailure` is swallowed and the store is cleared
(`auth_repository.dart:98-107`). Not reachable from the sign-in screen except via
`/unauthorized`.

## Error envelope (all failures)

`ApiExceptionHandler` emits RFC-7807 `ProblemDetail` plus custom properties:

```json
{
  "type": "about:blank",
  "title": "Unauthorized",
  "status": 401,
  "detail": "<localized message>",
  "instance": "/api/v1/auth/login",
  "code": "AUTH_INVALID_CREDENTIALS",
  "messageKey": "error.auth.invalidCredentials",
  "traceId": "<id>",
  "messageEn": "...",
  "messageAr": "..."
}
```

Client mapping (`api_client.dart:247-265`): any error **with a JSON body** →
`ApiFailure(code, messageKey, traceId, statusCode, detail, errors)`; any error **without** a body →
`AppFailure(code: <dio type uppercased>, messageKey: 'error.network')`.

### Codes the sign-in screen can receive

| HTTP | `code` | When | Screen copy |
|---|---|---|---|
| 401 | `AUTH_INVALID_CREDENTIALS` | unknown email, wrong password, locked account (`AuthService.java:83, 87, 93`) | `invalidCredentials` |
| 422 | `VALIDATION_FAILED` | `@Valid` rejects the request body (e.g. blank email) | `genericError` today — the client validates first, so this is a backstop |
| 400/500 | various `ApiException` codes | unexpected server fault | `genericError` |
| — | `CONNECTIONERROR`, `CONNECTIONTIMEOUT`, `SENDTIMEOUT`, `RECEIVETIMEOUT` | transport failure | `networkError` |
| — | `UNKNOWN`, `BADCERTIFICATE`, `CANCEL` | web CORS/offline edge, TLS, cancellation | `genericError` |

**Lockout is not distinguishable from a wrong password.** `AUTH_INVALID_CREDENTIALS` is returned
for both, deliberately (no account enumeration). The UI must not invent a "account locked" state.

**No rate limiting on `/auth/login`.** A 429 branch is not required; if one is ever added, it must
map to a new localized message rather than `genericError`.

## Request headers the app does not send

`platform_admin_app` sets `acceptLanguage` and `clientName` (`main.dart:38-39`); the workshop app
sets **neither** (`api_client.dart:61-65`). Consequence:

- the server's localized `detail` / `messageEn` / `messageAr` are always resolved in the server
  default locale for this app;
- `X-Client` audit attribution is absent for workshop requests.

The sign-in UI does not read `detail`, so this is **not** user-visible today. It becomes visible
the moment any screen renders `AppFailure.detail`. Fix belongs in a shared bootstrap, not in the
sign-in screen. Tracked as gap G6.

## Locale note

`Locale` changes only affect client-side `l10n` and layout direction on this screen. Because the
banner is built from `code` + `l10n`, the Arabic build shows Arabic errors regardless of G6.
