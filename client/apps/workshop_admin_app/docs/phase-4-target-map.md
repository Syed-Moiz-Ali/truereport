# Phase 4-lite — target map and test harness

LITE path. **No ADR is written because this screen needs no new architectural boundary.** That
decision is argued below, and every Phase 0 finding is mapped to something concrete.

## Boundary decision (and why "no new boundary" is not laziness)

The app already has the pieces a rebuild needs:

| Need | Existing home |
|---|---|
| Tokens, type, radii, spacing | `WorkshopTokens` + `context.ws` (`packages/design_system`) |
| Form primitives | `WorkshopTextField`, `WorkshopButton`, `WorkshopCard` (`workshop_ui.dart`) |
| Theme + font families | `AppTheme.build` (`tokens.dart:730-1000`) |
| Localization | `packages/l10n` (en/ar, generated) |
| Auth state | `authControllerProvider` / `AuthRepository` |
| Routing + role gate | `admin_router.dart` |
| Test harness | `test/flutter_test_config.dart` + `support/real_fonts.dart` (added in W1) |

Introducing a `SignInController`, a feature module boundary, or a state-machine library for two
fields would be structure without a consumer — it would also break the router contract that W1
just pinned. The one seam that *is* needed is inside the screen: **panel composition vs form
composition**, so each can be rebuilt and reverted without the other.

## Ordered, independently revertible steps (the visual brief will follow this)

| # | Step | Revert by |
|---|---|---|
| S1 | Delete the mock's hardcoded strings and the monospace plate; add l10n keys (`signInHeadline`, `signInExampleLabel`, `signInExampleProgress`, `signInExampleTech`, `signInExampleStarted`) | reverting the arb + the one widget file |
| S2 | Rebuild `_BrandPanel` on tokens: no `Colors.*`, no `fontSize:`, no raw `BorderRadius`/`BoxShadow`; one `WorkshopCard` for the example job | reverting `workshop_login_page.dart` to the S1 commit |
| S3 | Rebuild the mobile composition: brand bar + top-weighted form, no panel < 900 px | reverting the `build()` layout branch only |
| S4 | Motion: the checklist bar draw + 8 px fade, gated on `disableAnimations` | deleting the animation wrapper |
| S5 | Example-job semantics (`Semantics(container: true, label: 'Example job preview…')`) + focus order + 200 % text behaviour | reverting the semantics wrapper |
| S6 | Regenerate the screenshot evidence set and remove A1–A3 from `docs/baseline_allowlist.json` | restoring the JSON entry (the gate then goes red, which is the point) |

Each step is one file plus tests. No step requires another step's code to compile.

## Finding → target map

| Phase 0 finding | Target | Note |
|---|---|---|
| F1 wrong-widget tests | **delete the lie** | done in W1: tests now mount `WorkshopLoginPage` |
| F2 token violations (A1–A3) | **S1 + S2** | the three allowlist entries die with S2 |
| F3 hardcoded English | **S1** | every visible string becomes an l10n key |
| F4 silent 2FA | **delete the bug** | done in W1 with a test |
| F5 no `AutofillGroup` | **delete the bug** | done in W1 with a test |
| F6 fonts only in one test file | **delete the gap** | done in W1: global loader |
| F7 unasserted screenshot churn | **won't fix here** | see below |
| F8 happy-path-only tests | **delete the gap** | 14 characterization tests in W1 |
| F9 weak mobile composition | **S3** | the visual brief's main layout change |
| F10 two sign-in surfaces | **won't fix in this rebuild** | `SignInPage` is still used by the technician and platform apps; deleting it is a cross-app change, not a screen change |
| A4–A8 (green lies) | **delete** | all five fixed in W1 |

### Two deliberate non-fixes

- **F7 (screenshot suite writes 77 tracked PNGs on every run).** Fixing it means choosing between
  gitignored output and golden assertions — a QA-policy decision that affects every screen, not
  this one. Recorded here so Phase 6 does not "discover" it again. Mitigation for this rebuild:
  every capture is regenerated deliberately and reviewed, and the run is followed by
  `git checkout -- test/screenshots` so a bare `flutter test` never dirties the tree.
- **F10 (duplicate sign-in surfaces).** Removing `SignInPage` would touch `technician_app` and
  `platform_admin_app`. Out of scope. The workshop page stays the single admin sign-in by
  convention, and W1 removed the tests that pretended otherwise.

## Test harness (Gate 4 evidence)

| Requirement | Status |
|---|---|
| Real-font `FontLoader` from Phase 0's bundled fonts | **DONE** — `test/support/real_fonts.dart`, installed globally by `test/flutter_test_config.dart` |
| Family names match the theme | **DONE** — `RealFonts` keys off `TrFonts`, and `font_harness_test.dart` asserts the resolved family is `packages/design_system/Plus Jakarta Sans` |
| Ahem can never masquerade as evidence | **DONE** — the same test asserts the measured width is not `fontSize × length` |
| One-screen smoke capture with real glyphs | `test/smoke_signin_capture_test.dart` → `docs/evidence/phase-4-signin-smoke.png` |
| Missing families fail loudly | `RealFonts.missingFamilies` asserted empty in two suites |

## Gate 4 self-grade

| Criterion | Result |
|---|---|
| Every Phase 0 finding maps to a target, `delete`, or `won't fix` + reason | ✅ 10/10 + 5/5 |
| Every planned step independently revertible | ✅ S1–S6, each one file + tests |
| Smoke capture renders real glyphs | ✅ `docs/evidence/phase-4-signin-smoke.png` — real Latin letters in the headline, labels and button (no Ahem boxes). The plate `DXB 48291` still renders as two black bars: that is the A3 defect, visible proof that the capture is real and that the unregistered `monospace` family must go at S1. |
| No new boundary invented | ✅ argued above |
