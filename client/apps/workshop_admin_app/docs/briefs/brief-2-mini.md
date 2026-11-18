# Mini Brief 2 — rebuild sign-in as "The bay" (direction B)

Phase 5 → 6. Inputs: `docs/ui_brief.md` (B spec), `docs/visual_language.md`
(committed), `docs/adr/0002-target-architecture.md` (no new boundary),
`docs/invariants.md`, `docs/api/contracts.md`.

**Non-negotiable:** this is a rebuild, not a restyle. The screen file is
rewritten, every region gets its own widget file, the kill list is executed, and
the structure at 1440 / 1024 / 390 differs from the shipped version.

## Files

**Rewrite**

- `lib/src/features/auth/workshop_login_page.dart` — composition + behaviour only.

**Create**

- `lib/src/features/auth/signin/signin_example.dart` — approved example constants.
- `lib/src/features/auth/signin/signin_primitives.dart` — `WorkshopChassisMark`,
  `WorkshopTickSpine` (app-local; DS barrel is write-locked).
- `lib/src/features/auth/signin/signin_mark.dart` — lockup.
- `lib/src/features/auth/signin/signin_language_toggle.dart` — locale switch.
- `lib/src/features/auth/signin/signin_form.dart` — title, fields, banner, action.
- `lib/src/features/auth/signin/signin_inspection_surface.dart` — the ink surface.
- `lib/src/features/auth/signin/signin_identity_band.dart` — the phone band.

**Delete**

`_BrandPanel`, `_ExampleJobCard`, `_BrandBar`, `_Lockup`, inline `_buildForm`, the
`WorkshopCard`/`WorkshopStatusBadge`/`LinearProgressIndicator` usage, the 50/50
shell, and the `signInHeadline`/`signInBrandLine` renders. ARB keys stay.

## Behaviour that must not change

1. Keys `sign-in-email`, `sign-in-password`, `sign-in-submit`.
2. Validation blocks the request; empty → `requiredField` ×2, malformed email →
   `invalidEmail`; focus moves to the first invalid field.
3. One tap = one request; a second tap while submitting is impossible.
4. Failure codes map exactly: `AUTH_INVALID_CREDENTIALS` → `invalidCredentials`;
   `NETWORK|CONNECTIONERROR|CONNECTIONTIMEOUT|RECEIVETIMEOUT|SENDTIMEOUT` →
   `networkError`; anything else → `genericError`. Email is preserved.
5. `AuthChallenge` → `twoFactorRequired` copy, **no code field**, Sign in stays
   enabled.
6. Success calls `TextInput.finishAutofillContext()`; the router redirects.
7. `AutofillGroup` + autofill hints (username/email, password) survive.
8. Eye toggle flips `obscureText` and never submits; Enter from the password
   field submits.
9. Locale toggle persists typed values and flips direction.
10. Reduced motion: no tick animation.

## Design constraints

- Tokens only: no `Colors.*`, `Color(`, `fontSize:`, `fontFamily:`, numeric
  `BorderRadius.circular`, `BoxShadow`, `LinearGradient`, or raw spacing values.
- No `WorkshopCard`, no `WorkshopStatusBadge`, no elevation.
- Accent exactly three times (eyebrow, filled ticks, primary button).
- Chassis drawing pinned LTR; model/plate/customer/counts wrapped LTR.
- Split at ≥900 px, or ≥1100 px when text scale ≥1.5×. Below that: 132 px ink
  band with `minHeight`, not a fixed height.

## Done when

- 1440 / 1280 / 1024 / 768 / 390 / 360 EN and 1280 AR render without clipping,
  horizontal scroll or `RenderFlex overflowed`.
- 200 % text scale at 360 and 1280 is readable with the submit reachable.
- A1–A3 in `docs/baseline_allowlist.json` stay green; no new allowlist rows.
- `dart format` clean, `flutter analyze --fatal-infos` clean, full `flutter test`
  green apart from the allowlisted pre-existing failures (none for this screen).
- Captures regenerated into `test/screenshots/real/` and copied to
  `docs/evidence/` for the states that gates require.
- Edit-vs-replace evidence recorded: rewritten file, ≥1 new widget file per
  region, non-empty kill list, different structure at 1440 / 1024 / 390.
