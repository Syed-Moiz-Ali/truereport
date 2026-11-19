# Audit — technician_app sign-in (Phase 0-lite, read-only)

Date: 2026-11-19 · Scope: **one screen**, `/signin` of
`client/apps/technician_app` · Path: **LITE**.
Nothing was edited to produce this audit.

## 1. What exists today

| Layer | File | Lines | Role |
|---|---|---|---|
| Route + guard | `client/apps/technician_app/lib/src/technician_router.dart:27-91` | 119 | `/signin` route, role guard, auth-change refresh |
| App shell | `client/apps/technician_app/lib/app.dart` | 25 | `MaterialApp.router`, theme, locale |
| Screen logic | `client/packages/auth/lib/src/sign_in_page.dart` | 137 | controllers, submit, 2FA challenge, error mapping, validation |
| Screen UI | `client/packages/auth/lib/src/sign_in_view.dart` | 459 | layout, brand mark, fields, footer |
| Transport/session | `client/packages/auth/lib/src/auth_repository.dart`, `auth_controller.dart`, `session_store.dart` | — | sign-in / verify / restore / sign-out |

The technician app **does not own its sign-in UI**. It mounts a screen from the
shared `auth` package, and that package is also the home of the platform-admin
sign-in. The UI was transcribed from a 390 px Figma frame: fixed heights
(`_M.headerHeight = 64`, `_M.heroHeight = 222`, `_M.footerHeight = 128`,
`_M.bottomPad = 202`, `sign_in_view.dart:434-459`), a single centred column
capped at 350 px above the tablet breakpoint (`sign_in_view.dart:57-70`), and
one `SingleChildScrollView`.

## 2. What must not break (short form; full list in `docs/invariants.md`)

1. Credentials go to `AuthController.signIn`; a 2FA challenge switches the same
   screen to a code field and submits `verifyTwoFactor`.
2. `AuthResult` is `AuthSuccess` or `AuthChallenge`; the router redirects on
   `authControllerProvider`; role other than `Role.technician` → `/unauthorized`.
3. Session restore keeps the last session when offline and clears on 401.
4. No password in logs; debug logging is `kDebugMode` only.
5. All copy comes from `AppLocalizations`; the i18n source scan covers
   `packages/auth/lib` and `apps/technician_app/lib`.
6. Widget keys used by tests (`sign-in-email`, `sign-in-password`, `sign-in-code`,
   `sign-in-submit`, `sign-in-language-en`, `sign-in-language-ar`,
   `sign-in-access-prompt`, `sign-in-security-line`) are the behaviour contract
   today. A rewrite may keep them (cheapest) or replace them with an equivalent
   set in the same change; silently dropping coverage is a hard stop.

## 3. Top findings

| ID | Finding | Evidence | Consequence | Fix | Effort | Risk |
|---|---|---|---|---|---|---|
| **S1** | The screen is owned by the shared package, not the app | `technician_router.dart:49` imports `SignInPage` from `package:auth`; `sign_in_view.dart` lives under `packages/auth/lib/src/` | Every technician-only design change edits a package used by another app; ownership and ACLs are unclear | Technician app gains `lib/src/features/auth/signin/`; `auth` keeps controller/repository; router points at the app screen | M | Low |
| **S2** | Layout is a 390 px vertical stack, not a responsive composition | `sign_in_view.dart:57-70` (only change above 900 px is a 350 px max width), fixed `_M` heights | Desktop/tablet are a phone column on a large canvas; a restyle would preserve this | New per-breakpoint structure (Phase 3), not token swaps | M | Low |
| **S3** | Placeholder is the only field label | `FxTextField(hint: l10n.emailLabel)` at `sign_in_view.dart:155-169`; `FxTextField` draws only `hintText` (`figma_screen_kit.dart:577-580`) | Once typed, the field has no visible label; weak for accessibility and for screen readers that rely on visible text | Visible labels above fields, hints as examples only | S | Low |
| **S4** | The "logo" is an empty blurred glow | `_BrandMark` draws a blurred pill and nothing else (`sign_in_view.dart:390-432`) | The brand mark is absent; the screen reads as an unfinished template | Commit a real mark or a typographic lockup in Phase 5 | S | Low |
| **S5** | Validation failure is silent to assistive tech and does not move focus | `sign_in_page.dart:34-38` returns after `validate()`; no announcement, no `requestFocus` | Screen-reader user gets no feedback; keyboard user must hunt for the field | Announce + focus first invalid field | S | Low |
| **S6** | Error mapping is a closed string switch in the page | `sign_in_page.dart:81-92` | Unknown codes silently become "Something went wrong"; no distinct 2FA-expired copy | Keep the map, add a tested fallback; never remove the codes pinned by tests | S | Low |
| **S7** | The 2FA state is a code field appended to the same column | `sign_in_view.dart:194-209`; button label switches to `verifyButton` | No explanation of what was sent where, no way back to credentials, no resend. Behaviour is correct but the state is under-designed | Specify the challenge state fully in `ui_brief.md` | S | Low |
| **S8** | Login copy-fit test pins exact Figma slot widths | `o2_copy_fit_test.dart:11-87` (153.53 / 64.94 px) | A structurally different footer cannot satisfy those slots; the test must be rewritten to its intent (no truncation at 360, both locales) | Rewrite the two login cases with the same guarantee, keep the empty-state case untouched | S | Low |
| **S9** | Only the login goldens pass in the current baseline | `docs/evidence/logs/baseline_test.txt` | Regenerating `f2a_login_{en,ar}_light.png` is unavoidable and must be an explicit Gate 6 artefact | Regenerate two files, review them, never touch the other 14 | S | Low |
| **S10** | Fonts are already bundled; the harness already loads them | `design_system/pubspec.yaml` (6 families), `test/support/f2a_test_fonts.dart:7-71`, no `google_fonts` anywhere | No runtime font risk; the screenshot gate can be real-font from day one | Reuse; add no font work | — | — |
| **S11** | A geometry gate pins the login screen to Figma boxes at **1 logical px** | `f2a1_geometry_test.dart:138-207` (language switch 241.58,8,128.42,32; brand 120.31,192; fields 24,286 and 24,350; submit 24,472,342,56; exact text styles) | A structurally different screen fails by construction. This is a fidelity test, not a behaviour invariant | Replace the `login` case with structural assertions (region order, key controls present, no clipping at 360/390) — same intent, new structure. Do not delete the test file | S | Low |
| **S12** | A source-scan gate forbids URLs, `/api/`, and `fontSize:` literals in feature files | `f2a_screens_test.dart` scan block | New widgets must not inline sizes via `fontSize:` nor URLs; use tokens | Use `Fx`/theme tokens and `AppLocalizations` | S | Low |

## 3b. Security findings (read-only audit, must be handled by the rebuild)

| ID | Finding | Evidence | Rebuild action |
|---|---|---|---|
| **S11** | **BLOCKER:** page-level `debugPrint` is not `kDebugMode`-gated and logs the email plus exception text | `sign_in_page.dart:36, 40, 57, 60, 63, 69` (repository prints *are* gated, `auth_repository.dart:53-75`) | Remove or gate every page-level print; never log the password. Pin with a test that submits and asserts the log seam is silent in non-debug. |
| **S12** | Double-submit is possible: the button disables, but Enter bypasses it (`onFieldSubmitted` calls `_submit` unconditionally) and `_submit` never checks `_submitting` | `sign_in_view.dart:184`, `sign_in_page.dart:33-79` | Guard at the source: an in-flight/submitting check at the top of submit; keep the disabled button. Pin with a test. |
| **S13** | The 2FA success path, error-code mapping and session restore have **no tests** in this app; validation failure calling the API is untested | grep: no `authControllerProvider|verifyTwoFactor` in `test/` | Add characterisation tests before the UI swap (mini Brief step 1). |
| **S14** | No `AutofillGroup`; password field has autofill hints but password managers are not told when the form is submitted (`TextInput.finishAutofillContext` absent) | `sign_in_view.dart:71-264` | Add `AutofillGroup` + finish on success (workshop page already does: `workshop_login_page.dart:79`). |
| **S15** | Config default is a dev tunnel compiled into every build unless `--dart-define-from-file` is passed | `api_config.dart:7-22` | Record; release-build CI concern, out of scope for the screen. |
| **S16** | `jsonDecode` of the stored session is unguarded; corrupted storage throws inside `build()` | `session_store.dart:32` | Record; resilience fix belongs to the auth layer, not the UI. Out of scope this wave. |
| **S17** | `refresh()` exists but is never called; no global 401→sign-out interceptor | `auth_repository.dart:87-96` | Record as pre-existing; not introduced by the rebuild. |

## 3c. Ownership confirmation

- `SignInView` is referenced **only** by `sign_in_page.dart:111` and
  `test/support/f2a_views.dart:45`. No other app imports it.
- `SignInPage` is referenced by `technician_router.dart:49`, the auth package's
  own `router.dart:45`, and the technician tests.
- The workshop app has its own `workshop_login_page.dart`; platform admin uses
  `AdminSignInView`. `TrueReportApp` + `routerProvider` have **zero consumers**.
- `auth` has no test directory at all, so there is no shared-package suite to
  break by moving the technician screen into the app.

## 4. Dead / adjacent surfaces (do not delete in this wave)

| Surface | Why it is not ours |
|---|---|
| `packages/auth/lib/src/true_report_app.dart` + `packages/auth/lib/src/router.dart` | No consumer anywhere (`grep TrueReportApp/trueReportRouter` → definition only). Dead, but shared-package cleanup needs its own wave. |
| `packages/auth/lib/src/admin_sign_in_view.dart` | Platform admin legacy. It is the only reason the i18n scan is red (`SignInCopy`), and it is outside this scope. |
| `apps/technician_app/lib/src/features/**` (jobs, inspection, review, sync) | Other screens; the router already separates them. |

## 5. Strategy — strangler, 5 independently revertible steps

1. Add the technician-owned screen under `lib/src/features/auth/signin/` with
   no route change (`/signin` still renders the auth page).
2. Switch `technician_router.dart:49` to the new page (one-line seam; revert =
   restore the import).
3. Move the 5 sign-in behaviour tests to the new page; add state/RTL/a11y tests.
4. Regenerate only the two login goldens; keep every other golden byte-identical.
5. Delete the technician app's dependency on `auth.SignInView` / `auth.SignInPage`
   (barrel exports stay for the unused true-report shell; no shared file is
   deleted in this wave).

Each step compiles and tests on its own. No step touches the shared ARB.

## 6. Font strategy decision (settled at Gate 0)

**Bundle, do not fetch.** The families already ship as real `.ttf`/`.otf` files
declared in `packages/design_system/pubspec.yaml` and are referenced through
`TrFonts` (`fonts.dart:7-15`); the theme uses the same names
(`tokens.dart:799-812`); the test harness loads the files from disk
(`f2a_test_fonts.dart:7-71`). No `google_fonts` dependency exists in the
workspace. **Decision: reuse this setup unchanged; any new widget uses `Fx`/
theme tokens, never a literal family name.** Screenshot evidence is therefore
real-font by construction.

## 7. Baseline and allowlist

`docs/baseline_metrics.md`, `docs/baseline_allowlist.md`. Headline: analyzer 0,
tests 231 pass / 19 fail (all pre-existing, none on the sign-in behaviour).
Login behaviour, login copy-fit and both login goldens pass today.

## 8. What to keep

- The Riverpod/`AuthController` boundary and the router guard (behaviour).
- `AuthResult` semantics, error-code map, 2FA flow, validation rules.
- All existing l10n keys (no ARB edit this wave).
- The eight widget keys, or a documented equivalent.
- `Fx` visual tokens as the source of colour/type values until Phase 5 commits
  its own primitive set.

## 9. Kill list (initial — Phase 5 makes it final)

| Killed | Why |
|---|---|
| The technician app's use of `auth.SignInPage` + `auth.SignInView` | Replaced by app-owned screen |
| `_BrandMark` (empty glow) | No mark; replaced by a real lockup |
| `_Reveal` (24.5×19.25 hard-coded) | Replaced by a primitive with a 44 px target and an accessible name |
| The `_M` fixed-metric layout (`headerHeight`, `heroHeight`, `footerHeight`, `bottomPad`, per-slot widths) | Replaced by per-breakpoint composition |
| The 350 px centred single column above 900 px | Replaced by the chosen direction's structure |
| `o2_copy_fit_test` login cases (exact-slot version) | Replaced by non-truncation assertions at 360/390 EN+AR |
