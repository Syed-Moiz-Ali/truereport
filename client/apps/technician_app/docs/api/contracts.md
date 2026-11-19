# API contracts — technician sign-in (Phase 1)

Canonical gate document. Full evidence: `docs/data/auth_server_contract.md`
(server) and `docs/data/signin_client_trace.md` (client). Samples:
`docs/data/samples/`.

All paths are under `{baseUrl}/api/v1`. `baseUrl` comes from `API_BASE_URL`
then a compiled dev-tunnel default (`api_config.dart:7-22`) — see G9.

## Cross-cutting

| Property | Value |
|---|---|
| Auth | `Authorization: Bearer <accessToken>` when a token is set |
| Server session | Stateless (`SecurityConfig.java:80`), CSRF disabled (`:78`) |
| Client headers | `X-Request-Id` (UUIDv7) always; **no** `Accept-Language`, **no** `X-Client` from this app |
| Error shape | RFC 9457 `application/problem+json` with `code`, `messageKey`, `detail`, `traceId`, optional `errors[]`/`fieldErrors[]` |
| Tenant scope | Server-side only; the client never sends a workshop id on auth calls |
| Roles | `PLATFORM_ADMIN`, `WORKSHOP_ADMIN`, `TECHNICIAN` |

## 1. `POST /auth/login`

- **Auth:** public (`@PermitAll`).
- **Request** (`LoginRequest.java:6-9`):
  - `email` — string, required, `@Email`, trimmed + lower-cased for lookup; no max length.
  - `password` — string, required, `@NotBlank` only. **No complexity rule at login.**
- **Success:** `200 OK` (not 202) with `AuthResponse`.

| Field | Type | Null | Meaning |
|---|---|---|---|
| `accessToken` | string (JWT HS256) | only on challenge | Bearer token |
| `refreshToken` | string (opaque, 43 chars) | only on challenge | SHA-256 stored server-side |
| `tokenType` | string | only on challenge | `"Bearer"` |
| `expiresInSeconds` | long | never | **900** (`PT15M`, `application.yml:74`) |
| `user` | `UserDto` | only on challenge | `id`, `email`, `displayName`, `platformAdmin`, `totpEnabled` |
| `memberships` | `MembershipDto[]` | never (empty on challenge) | all ACTIVE: `workshopId`, `workshopName`, `role` (order unspecified) |
| `requiresTwoFactor` | boolean | never | true only for a challenge |
| `challengeToken` | string | null on success | JWT, `purpose=2fa`, TTL **5 min**, no `jti` |

- **2FA challenge requires BOTH:** `ADMIN_TOTP_REQUIRED=true` (default **false**) **and**
  `user.totpEnabled` (`AuthService.java:97`).
- **JWT identity:** one `role` + one `workshopId` from the **primary** active membership,
  falling back to an unspecified first active membership (`AuthService.java:330-340`).
- **Errors:** `401 AUTH_INVALID_CREDENTIALS` (unknown email, bad password, inactive, locked) ·
  `403 NO_WORKSHOP_MEMBERSHIP` · `422 VALIDATION_FAILED`.
- **Lockout:** 5 failures → 15-minute account lock, same 401, no `Retry-After`;
  the failure counter is not reset when the lock expires (`User.java:150-160`).
- **Sessions:** each login creates a new refresh family; prior sessions are not revoked.

## 2. `POST /auth/2fa/verify`

- **Auth:** public; the challenge JWT in the body **is** the credential.
- **Request** (`TwoFactorVerifyRequest.java:6-9`): `challengeToken` string, `@NotBlank`;
  `code` string, nullable, `@Size(max=40)` only.
- **Accepted codes:** 6-digit TOTP (`currentStep ± 1`, replay-protected by `totp_last_step`)
  **or** a recovery code `XXXXX-XXXXX` (10 chars + hyphen, case-insensitive, single use).
- **Success:** `200` with the same `AuthResponse`, `requiresTwoFactor=false`.
- **Errors:** `401 AUTH_2FA_INVALID` for every failure (expired/forged token, flag off,
  TOTP not enabled, locked, wrong code) · `401 ACCOUNT_DISABLED` · `422 VALIDATION_FAILED`.
- **Lockout:** 5 bad codes → 15-minute lock.
- **Client contradiction:** the UI accepts exactly 6 characters and uses a numeric keyboard,
  so TOTP is enterable and **recovery codes are not** (`sign_in_view.dart:196-208`).
  This is a data-truth defect to fix in the rebuild (G4).

## 3. `GET /auth/me`

- **Auth:** bearer, any role.
- **Success:** `200 { user: UserDto, memberships: MembershipDto[] }`.
- **Errors:** `401 UNAUTHENTICATED` (security entry point) · `401 AUTH_TOKEN_INVALID`
  (user row gone).
- **Client behaviour:** `restore()` calls this endpoint and **discards the body**, trusting
  the stored session JSON (`auth_repository.dart:30-49`). Stale roles survive (G10).
- Does **not** re-check `User.status`: a disabled user's token returns 200 until expiry.

## 4. `POST /auth/logout`

- **Auth:** bearer.
- **Request:** none (client sends `{}`).
- **Success:** `204 No Content`.
- **Effect:** revokes only the refresh token referenced by the access token's `sid`;
  the access token stays valid until `exp`. No `logout-all` call site in the client.
- **Client behaviour:** failures are swallowed and local state is cleared regardless
  (`auth_repository.dart:98-107`).

## 5. `POST /auth/refresh` — adjacent, **never called**

- **Auth:** public.
- **Request:** `refreshToken` (`@NotBlank`).
- **Success:** `200` with a rotated `AuthResponse`.
- **Errors:** `401 AUTH_TOKEN_INVALID` · `401 AUTH_REFRESH_REUSED` (reuse revokes the family)
  · `401 AUTH_TOKEN_EXPIRED`.
- **Client:** `refresh()` exists with zero call sites; no 401 interceptor (G7).

## 6. Code → UI mapping (today)

| Server code | UI copy | Correct? |
|---|---|---|
| `AUTH_INVALID_CREDENTIALS` | "Email or password is incorrect." | Yes |
| `AUTH_2FA_INVALID` | the same credential copy | **No** — it also means expired challenge, TOTP disabled, locked |
| `CONNECTIONERROR` / `*TIMEOUT` | "Cannot reach the server…" | Copy yes; timeout branches are dead (no Dio timeouts) |
| `ACCOUNT_DISABLED` | "Something went wrong." | **No** — actionable state |
| `NO_WORKSHOP_MEMBERSHIP` | "Something went wrong." | **No** |
| `VALIDATION_FAILED` | "Something went wrong." | **No** |
| `UNAUTHENTICATED`, `AUTH_TOKEN_INVALID`, 5xx, malformed body | "Something went wrong." | Acceptable fallback |

New copy needs new ARB keys; this wave is ARB-neutral (Gate 0). The two fixes that need
**no new copy** are in scope: accept recovery codes (G4) and stop promising a password-help
channel (G1).

## 7. Role and tenant contract (the important one)

- **Server:** one role + one workshop per session (primary membership), plus the full
  `memberships[]` list with no promised order.
- **Client:** `role` = highest-privilege membership (`session.dart:18-38`), `workshopId` =
  `memberships.first` (`:40-41`). **These disagree with the token** for multi-workshop users.
- **Consequence:** a technician who is an admin elsewhere is sent to `/unauthorized`;
  an unknown role string silently becomes `technician` (`role.dart:10-17, 25`).
- **Decision for this wave:** preserve the current guard; do not change auth semantics.
  Recorded as G5/G6, with the recommended fix being "return and use the server-resolved role".
