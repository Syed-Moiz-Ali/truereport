# Mini Brief — technician sign-in build (LITE)

Inputs: `docs/ui_brief.md` (direction C), `docs/visual_language.md`,
`docs/adr/0002-signin-ownership.md`, `docs/invariants.md`,
`docs/api/contracts.md`. Primitives from Phase 5 already exist under
`lib/src/features/auth/signin/`.

## Goal

Route `/signin` to the new app-owned screen, pin the audited behaviour with
tests, delete the old shared screen and its dead shell, and regenerate exactly
two goldens. **No new copy, no ARB edit, no design changes.**

## Steps (each compiles; each revertible)

1. **Route swap.** `technician_router.dart` imports
   `features/auth/signin/technician_sign_in_page.dart` and mounts
   `TechnicianSignInPage` at `/signin`.
2. **Router guard pin.** Extract the redirect into a pure
   `technicianRedirect({loading, session, location})` and unit-test the three
   cases (signed out → `/signin`, wrong role → `/unauthorized`, technician at
   `/signin` → `/jobs`). Behaviour unchanged.
3. **Behaviour tests** (`test/features/auth/signin/signin_behaviour_test.dart`),
   with a fake `AuthController`:
   - invalid submit never calls the repository and shows `requiredField`;
   - double submit (tap + Enter, or two taps) issues one request;
   - `AUTH_INVALID_CREDENTIALS` → `invalidCredentials`; network codes →
     `networkError`; unknown → `genericError`;
   - 2FA: `AuthChallenge` shows the code cell, `Verify`, and calls
     `verifyTwoFactor` with the token and code;
   - the code validator accepts 6 digits **and** `XXXXX-XXXXX`, rejects other
     shapes without calling the repository;
   - locale toggle flips direction and preserves typed values;
   - the eight widget keys exist;
   - source scan: no `debugPrint`/`print(` in the sign-in page.
4. **Repoint the existing screen tests** to the new page/view:
   `widget_test.dart`, `f2a_views.dart`, `f2a1_geometry_test.dart` (login case
   becomes structural), `o2_copy_fit_test.dart` (login cases become
   no-truncation assertions via `RenderParagraph.didExceedMaxLines == false`).
5. **Delete** `packages/auth/lib/src/sign_in_{view,page}.dart`,
   `true_report_app.dart`, `router.dart`, and their barrel exports. Workspace
   `flutter analyze --fatal-infos` must be 0.
6. **Regenerate** `test/goldens/f2a_login_{en,ar}_light.png`.
   Do not touch the other 14 goldens.
7. **Delete throwaway previews** `test/preview/directions/**` after the Gate 3
   evidence is committed (the PNGs stay under `docs/evidence/`).

## Out of scope

Error-taxonomy copy (needs ARB keys), role/token alignment, session refresh,
Dio timeouts, locale persistence, dark theme, any other screen.

## Acceptance

- `flutter analyze --fatal-infos` from `client` = 0.
- New tests pass; the 19 pre-existing failures remain exactly 19.
- Both new goldens render the new screen in EN and AR without overflow.
- `git diff` proves the screen file is new, the region widgets are new, the old
  screen is deleted, and the old private widgets are gone.
- 1440 / 1024 / 390 / 360 EN + 390 AR captures exist for the record.
