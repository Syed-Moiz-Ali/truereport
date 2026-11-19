# ADR 0002 — Sign-in ownership, boundaries and migration seams

Status: accepted for the LITE sign-in rebuild · Date: 2026-11-19 ·
Scope: `client/apps/technician_app` + `client/packages/auth`

## Context

The technician app mounts its sign-in screen from the shared `auth` package
(`technician_router.dart:49` → `packages/auth/lib/src/sign_in_page.dart` →
`sign_in_view.dart`). The view contains technician-only copy and a 390 px Figma
layout. The shared package also carries a dead true-report shell
(`true_report_app.dart`, `router.dart`) whose only route mounts that same screen.
No other app consumes it: workshop has its own login page; platform admin uses
`AdminSignInView`. The `auth` package has no test suite.

Phase 0/1 established: behaviour that must survive is in
`docs/invariants.md`; the auth contract is in `docs/api/contracts.md`; the
chosen visual direction is C "The dock" (`docs/ui_brief.md`).

## Decision

1. **The technician app owns the screen.** New code lives in
   `lib/src/features/auth/signin/` (page + view + region widgets + local style).
2. **`packages/auth` keeps the non-visual auth layer**: `AuthController`,
   `AuthRepository`, `SessionStore`, `AuthResult`/`AuthSuccess`/`AuthChallenge`,
   the providers, and `role_home.dart` (still used by a technician test).
3. **After the swap, delete the now-dead technician sign-in surface**
   (`sign_in_page.dart`, `sign_in_view.dart`) and the dead shell that only
   mounts it (`true_report_app.dart`, `router.dart`), including their barrel
   exports. This is one revertible commit.
4. **Nothing else moves.** No changes to `domain`, `api_client`, `core`,
   `l10n`, `offline_sync`, `design_system` (except additive primitives if the
   visual language needs them, owned separately), the router guard, the route
   path, or the ARB.

## Boundaries and dependency direction

```
technician_app/lib/src/features/auth/signin/*   (UI, local form state)
        │  depends on
        ▼
packages/auth  (AuthController → AuthRepository → SessionStore, AuthResult)
        │  depends on
        ▼
packages/api_client → packages/core        packages/domain (Session, Role)
        ▲
        └── technician_app also depends on packages/design_system, packages/l10n
```

- The screen reads `authControllerProvider` and `localeProvider`; it never
  constructs an `ApiClient` or a `Session`.
- The router remains the only place that decides where an authenticated user
  goes. The screen never navigates.
- No business logic in the view: the page owns controllers, submit, error
  mapping and validation; the view is presentational and takes callbacks.

## State, DI, routing, l10n

| Concern | Decision |
|---|---|
| State | Riverpod `AsyncNotifier` for auth; local `StatefulWidget` for form/obscure/challenge |
| DI | Existing providers only; no new global singleton |
| Routing | `/signin` unchanged; redirect logic unchanged |
| l10n / RTL | Existing `AppLocalizations` keys only; no ARB edit; AR mirrors by `Directionality` |
| Theme | `AppTheme.build(isArabic:)`, light only |
| Fonts | Bundled families via `TrFonts`; real-font loader in tests |

## Migration seams (ordered; each compiles and is independently revertible)

| # | Step | Revert |
|---|---|---|
| 1 | Add `features/auth/signin/` screen files, unreferenced by the router | delete the folder |
| 2 | Add characterisation tests for the auth behaviour (fake controller): success, challenge, error mapping, validation, double-submit | delete the test file |
| 3 | Point `technician_router.dart:49` at the new page | restore the import/one line |
| 4 | Repoint the existing sign-in tests and `f2a_views.dart` to the new view; rewrite the login cases of the geometry and copy-fit tests to their intent | restore those test files |
| 5 | Delete the old shared page/view + dead shell + exports | `git revert` one commit |
| 6 | Regenerate exactly two login goldens | restore the two PNGs |

No step touches the shared ARB, the router guard semantics, the auth
repository, or any other screen's files.

## Test harness

- **Real-font loader:** `test/support/f2a_test_fonts.dart:7-71` already loads
  every bundled family from `packages/design_system/assets/fonts` plus the
  MaterialIcons font, and registers the Figma SVGs. It is reused as-is.
- **Proof it paints real glyphs:** `test/support/font_harness_smoke_test.dart`
  asserts proportional metrics (`WWWWWW` wider than `iiiiii`) and captures a
  real-font PNG. Ahem/Ahem-like block fonts fail the width assertion.
- **Screen captures:** a RepaintBoundary + `toByteData` capture per screen state
  writes to the system temp dir; curated PNGs are copied to
  `docs/evidence/signin/` by the main session, never written by the suite.

## Consequences

- The technician app can evolve its sign-in without touching a shared package.
- The `auth` package becomes smaller and truly non-visual.
- The dead true-report shell disappears (no consumer; confirmed by grep).
- The `auth` package's barrel changes; no app outside `technician_app`/tests
  references the removed exports.
- Risk: an unseen import of the removed symbols. Mitigation: workspace
  `flutter analyze --fatal-infos` after step 5; the only consumers found were
  the technician tests and the removed shell.

## Phase 0 finding map

| Finding | Target |
|---|---|
| S1 ownership in shared package | this ADR, steps 1-5 |
| S2 phone-only layout | `ui_brief.md` §7 (dock, 4 breakpoints) |
| S3 placeholder-as-label | `ui_brief.md` §9 (persistent labels) |
| S4 empty glow mark | delete `_BrandMark`; typographic lockup |
| S5 silent validation | `ui_brief.md` §9/§11; characterisation tests |
| S6 closed error map | keep the map; add fallback test; G3 recorded |
| S7 bolted-on 2FA | `ui_brief.md` §9 (dock mode); G4 fix |
| S8 fixed-slot copy test | rewrite login cases to intent (step 4) |
| S9 two login goldens | step 6 |
| S10 fonts | reuse; harness smoke test |
| S11 geometry test | rewrite login case to intent (step 4) |
| S12 source-scan limits | tokens + `AppLocalizations` only |
| G1 dead help | delete "Password help"; de-link "Get help" |
| G2 server detail | won't fix this wave (no UI surface, no new keys) |
| G3 error taxonomy | won't fix this wave (needs ARB keys) |
| G4 2FA recovery codes | fix in the build + test |
| G5 role vs token | won't fix (server contract; preserve guard) |
| G6 unknown role downgrade | won't fix (behaviour preservation) |
| G7 session lifetime | won't fix (auth layer) |
| G8 Dio timeouts | won't fix (transport layer) |
| G9 dev-tunnel default | won't fix (release CI) |
| G10 me-body ignored | won't fix (auth layer) |
| G11 locale persistence | won't fix (behaviour change) |
| G12 no brand mark | typographic lockup |
| G13 headers | won't fix (not shown) |
| G14 duplicated error map | won't fix (cross-app refactor) |
