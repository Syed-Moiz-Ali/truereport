# Phase 1 Auth Fix Prompt — Remove Demo Bypass & Hardcoded Credentials

You are fixing the final blocker in the TrueReport Platform Admin phase.

Repository:

`E:\syed_moiz_ali\bitlogix\truereport`

## Context

Platform Admin functionality and evidence are complete, but auth security is not.

This is a production blocker:

- `client/apps/platform_admin_app/lib/src/features/auth/platform_login_page.dart`
  - `_enterDemoMode()` creates a fake session and navigates to `/workshops`.
  - The “Explore Platform Admin (Demo)” button is always rendered.
  - Any auth failure with an email containing `admin` or `test` enters demo mode.
  - Hardcoded credentials `admin@test.local` / `pass123`.
- `client/packages/auth/lib/src/auth_controller.dart`
  - `setDemoSession()` creates fake access/refresh tokens in the production auth package.
- `client/apps/platform_admin_app/test/platform_login_test.dart`
  - Tests the demo quick-fill behavior.
- `client/apps/platform_admin_app/test/e2e/platform_admin_live_e2e_test.dart`
  - Hardcodes the local dev password.
- `TEST_LOGIN_CREDENTIALS.txt`
  - Tracks local credentials. Keep it local-only; do not add production secrets.

## Goal

Remove all production auth bypasses, keep optional demo behavior strictly dev-only, and make the live E2E use environment credentials.

## Read First

1. `docs/NAMING_AND_TESTING_RULES.md`
2. `docs/PLATFORM_ADMIN_SCREEN_API_MATRIX.md`
3. `docs/DECISIONS.md` (D-066 to D-069)
4. `docs/MIGRATION.md`

## Non-Negotiable Rules

1. Production code must never create a fake authenticated session.
2. Auth failure must show an error and stay on the login page; it must never navigate to an authenticated screen.
3. No hardcoded credentials in `lib/`.
4. Fakes/demo sessions may exist only under `test/support/` or behind an explicit dev-only compile-time flag.
5. Do not redesign the login UI; keep the existing components/visual style.
6. No commits unless explicitly asked.
7. Do not touch the uncommitted `PublicReportService.java` / `print-report.html`.

## Required Changes

### 1. Platform login page

File: `client/apps/platform_admin_app/lib/src/features/auth/platform_login_page.dart`

- Remove `_quickFillDemo()`.
- Remove `_enterDemoMode()`.
- Remove the “Explore Platform Admin (Demo)” chip and its `Positioned` block.
- Remove the auth-failure fallback that enters demo mode when the email contains `admin` or `test`.
- Remove hardcoded `admin@test.local` / `pass123`.
- On failure, set `_errorKey` and remain on the login page.
- Pass `onQuickFillDemo: null` or remove the parameter usage.

### 2. Auth package

File: `client/packages/auth/lib/src/auth_controller.dart`

- Remove `setDemoSession()` from production code, or move it to `test/support/`.
- Do not ship fake tokens in the production auth package.

File: `client/packages/auth/lib/src/admin_sign_in_view.dart`

- Remove the `onQuickFillDemo` button/label from production, or gate it behind a dev-only compile flag:
  - `const bool.fromEnvironment('ALLOW_DEMO_LOGIN')`
  - `kDebugMode`
- Default must be off.

### 3. Tests

File: `client/apps/platform_admin_app/test/platform_login_test.dart`

- Remove/replace demo quick-fill tests.
- Add tests:
  - demo chip is absent,
  - invalid credentials show an error and do not navigate,
  - successful login navigates.

File: `client/apps/platform_admin_app/test/e2e/platform_admin_live_e2e_test.dart`

- Replace hardcoded credentials with environment variables:
  - `LIVE_E2E_EMAIL`
  - `LIVE_E2E_PASSWORD`
- Fail with a clear message if env vars are missing when `LIVE_E2E=1`.

### 4. Other apps

Search the Flutter workspace for the same pattern:

```powershell
rg "setDemoSession|_enterDemoMode|Explore Platform Admin|pass123|admin@test.local"
```

Remove or gate any equivalent demo login in Workshop Admin, Technician, or shared auth code.

### 5. Credentials file

- Keep `TEST_LOGIN_CREDENTIALS.txt` local-only.
- Do not add production credentials.
- Add a clear warning at the top: local development only.
- Consider adding it to `.gitignore` and providing a redacted `TEST_LOGIN_CREDENTIALS.example.txt`; do not commit real credentials.

## Local Test Account

A local Platform Admin account has been created:

- Email: `admin@truereport.test`
- Password: `Truereport#Local123`
- Role: Platform Admin
- Source: local MySQL `users` table (copied password hash from `platform@truereport.test`)

Use this account for manual verification.

## Agentic Sub-Sessions

1. **Auth/UI agent**
   - Owns `platform_login_page.dart`, `admin_sign_in_view.dart`.
   - Removes the bypass and demo UI.

2. **Auth package agent**
   - Owns `auth_controller.dart`.
   - Removes/moves `setDemoSession`.

3. **Test/E2E agent**
   - Owns `platform_login_test.dart`, `platform_admin_live_e2e_test.dart`.
   - Moves credentials to env, adds absence tests.

4. **Integrator/verifier**
   - Runs analyze/tests, manual login checks, and reports.

Rules: one file owner at a time; no two agents editing the same file; integrator runs final verification.

## Verification

```powershell
rg "setDemoSession|_enterDemoMode|Explore Platform Admin|pass123|admin@test.local|Truereport#Local123" client
flutter analyze --fatal-infos
cd client/apps/platform_admin_app
flutter test
```

Manual:
1. Build/run Platform Admin.
2. Confirm no demo chip/button exists.
3. Try invalid credentials → error shown, no navigation.
4. Login with `admin@truereport.test` / `Truereport#Local123` → `/workshops` loads.
5. Refresh/deep link `/workshops` works with the server rewrite.
6. Run the live E2E:
   ```powershell
   $env:LIVE_E2E="1"
   $env:LIVE_E2E_EMAIL="admin@truereport.test"
   $env:LIVE_E2E_PASSWORD="Truereport#Local123"
   flutter test test/e2e/platform_admin_live_e2e_test.dart
   ```

## Acceptance Criteria

1. No demo login bypass exists in production code.
2. Auth failure shows an error and never navigates.
3. No hardcoded credentials in `lib/`.
4. `setDemoSession` is removed or test-only.
5. Live E2E uses env credentials.
6. `rg` finds no demo bypass/hardcoded password in production code.
7. `flutter analyze --fatal-infos` passes.
8. Platform Admin tests pass.
9. Manual login with `admin@truereport.test` succeeds.
10. Docs/credentials file updated.

## Output Format

Report:
- Files changed.
- Demo bypass removed/gated.
- Tests added/updated.
- Commands run and results.
- Manual login/E2E evidence.
- Remaining blockers.
