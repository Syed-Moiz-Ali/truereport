# Flow — Auth & session

Scope: all three Flutter apps + Spring `identity` module.

## Happy path (email/password)

1. Platform Admin opens `/signin` → `client/apps/platform_admin_app/lib/src/features/auth/platform_login_page.dart`.
2. Submit calls the shared auth controller → `client/packages/auth/lib/src/auth_controller.dart` (signIn).
3. API client posts `POST /api/v1/auth/login` → `client/packages/api_client/lib/src/api_client.dart`.
4. Server `AuthController.login` → `server/src/main/java/com/truereport/identity/api/AuthController.java:29-32`.
5. Credentials verified, access + rotating refresh tokens issued → `identity/AuthService`.
6. Response contains `accessToken`, `refreshToken`, `expiresInSeconds`, `user`, `memberships`,
   `requiresTwoFactor` (verified live).
7. App stores the session (`packages/auth`), GoRouter redirect fires.
8. Role routing:
   - Platform app keeps any authenticated user in `/dashboard`; server `@PreAuthorize` enforces platform endpoints
     (`platform_router.dart:164-179`).
   - Workshop app allows only `Role.workshopAdmin`, otherwise `/unauthorized` (`admin_router.dart:28-42`).
   - Technician app allows only `Role.technician`, otherwise `/unauthorized` (`technician_router.dart:35-50`).
9. Session restored on reload from secure storage; `GET /api/v1/auth/me` rehydrates memberships.
10. Sign-out calls `POST /api/v1/auth/logout` and clears local session.

## Branches

- **Wrong password** → 401 problem+json `invalid_credentials`; UI shows the sign-in error row. Confirmed by widget
  tests and live API probe.
- **Wrong role** → login succeeds at the auth layer, but the app redirects to `/unauthorized`; server calls return
  403. This is intent parity for a multi-app platform, not a gap.
- **2FA required** → login returns `requiresTwoFactor`; `/signin` must route to a challenge. Platform/workshop UI
  does not expose a 2FA challenge screen (server supports `/auth/2fa/verify`). Marked as a UX gap in
  `docs/flow_gaps.md` (admin TOTP is off by default in dev).
- **Expired access token** → refresh rotation via `POST /auth/refresh`; refresh reuse is rejected (`AuthTenancyIT`).
- **Empty state** → N/A.
- **Public viewer** → no auth; `/r/{token}` is anonymous by design.

## Other apps

The same happy path exists in `workshop_login_page.dart` and `technician_sign_in_page.dart`; only the redirect rule
differs. The shared auth package means fixes here propagate to all apps.

## Verification status

- Server: `AuthTenancyIT`, `AuthRecoveryIT`, `TotpServiceTest`, `SecurityEndpointInventoryIT` (anonymous access to
  every non-public operation rejected).
- Client: sign-in widget tests in all three apps.
- Browser: to be executed in Step 5B (runtime column in `docs/flow_matrix.md`).
