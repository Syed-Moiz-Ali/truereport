# Gate 6 — independent QA verdict: technician sign-in ("The dock")

**Verdict: FAIL**
**One line:** the rebuild itself is real and mostly well-evidenced, but the specified keyboard-up state is unimplemented/untested (the primary is covered by the keyboard on platforms that do not resize) and the language switch is pointer-only, so the committed tab order cannot be entered from a keyboard.

- Reviewed by: independent `qa-reviewer` subagent (did not build this).
- Inputs opened: `qa_checklist.md`, `ui_brief.md`, `visual_language.md`, `invariants.md`, `baseline_allowlist.md`, `briefs/brief-signin-mini.md`, both after-logs, all PNGs in `docs/evidence/signin/`, all 4 PNGs in `docs/evidence/gallery/`, the Gate 3 direction C renders, and the source under `lib/src/features/auth/signin/**`, `technician_router.dart`, `packages/auth/**`, and the sign-in/router tests.
- Not available in this session: a shell/VCS. Claims that need `git status`/`git diff` are graded from the filesystem plus the test log and are labelled as such. Nothing in the checklist prose was accepted without opening the image or file.
- The visual work is strong; the fix list is short.

## Grades

| # | Area | Grade | Evidence |
|---|---|---|---|
| 1 | Edit-vs-replace (all four) | **PASS** | see §1 |
| 2 | Behaviour | **PASS** | see §2 |
| 3 | States | **FAIL** | keyboard-up state missing (B1); everything else present |
| 4 | Visual/UX honesty | **PASS** | see §4 |
| 5 | Accessibility | **FAIL** | B2 |
| 6 | i18n/RTL | **PASS** | see §6 |
| 7 | Mechanical | **PASS** | see §7 |
| 8 | Spec compliance (14 items) | **PASS WITH FIXES** | 12 clean, #8/#9 unverified as claimed, #3 has m5 |

## Blockers

### B1 — The keyboard-up state does not exist (specified state, no capture, no test)

`ui_brief.md:166-174` specifies: "Scaffold resizes; the dock lifts above the keyboard and the canvas scrolls away… the primary stays visible above the keyboard at ≥ 640 px viewport height." `ui_brief.md:302-305` makes mitigation and a **test at 390 × 500 with `viewInsets`** mandatory.

- `technician_sign_in_view.dart:65-70` returns `Material` → `SafeArea(top: true, bottom: false)` → `LayoutBuilder`. There is **no `Scaffold`** and **no consumption of `MediaQuery.viewInsets`** anywhere in `lib/src/features/auth/signin/**` (grep: zero matches for `viewInsets` / `resizeToAvoidBottomInset` / `Scaffold`).
- `signin_dock.dart:115` adds only `MediaQuery.paddingOf(context).bottom` (safe area), never `viewInsets.bottom`.
- `technician_sign_in_view.dart:133-144`: when height ≥ 640 the dock is the last child of a non-scrollable `Column`; only the canvas is scrollable. The dock therefore stays at the bottom of the *layout* height.
- Android is saved by `android:windowSoftInputMode="adjustResize"` (`android/app/src/main/AndroidManifest.xml:17`), which shrinks the window. iOS (`ios/Runner/` exists) does not resize: `viewInsets.bottom` (≈300-340 px) is the only signal, and nothing consumes it, so the email cell, password cell and primary all sit behind the keyboard. No `Scrollable` wraps the dock, so `EditableText.ensureVisible` cannot rescue the focused field either.
- No evidence anywhere: the capture matrix (`qa_checklist.md:27-34`) has no keyboard row; `signin_gallery_test.dart:129-250` has no `viewInsets` case; `signin_behaviour_test.dart` has none.

Why a blocker: it is a **missing state** on the primary phone layout, at the exact place the primary user lives. The proposed waiver W-SIGNIN-WEB ("no live device/browser walk") cannot cover a state that was specified, testable in a widget test, and is simply absent. The 390 × 844 captures cannot show it.

Fix: wrap the route in a `Scaffold(resizeToAvoidBottomInset: true)` (or pad the dock by `viewInsets.bottom` and switch to the scrollable branch when `height - viewInsets.bottom < 640`), then add the required `390 × 500` + `viewInsets` test asserting the primary's rect is above `viewInsets.bottom`.

### B2 — The language switch cannot be reached or operated from a keyboard

`ui_brief.md:211` ("Tab order: language → email → password → reveal → primary") and `ui_brief.md:251` ("Keyboard: language → email → …") are committed.

- `signin_language_switch.dart:54-61` wraps each segment in `Semantics(button: true, selected: …, label: …)` + a bare **`GestureDetector`**. A `GestureDetector` creates no `Focus` node and has no Enter/Space handling; `Semantics` adds an accessibility action but does not make the widget focusable.
- Nothing else in `signin_command_strip.dart` provides a `Focus`/`Shortcuts`/`Actions` wrapper.
- Consequence: Tab from the strip jumps straight to the email field; a keyboard-only or switch-access user cannot change language (WCAG 2.1.1 Keyboard, level A). TalkBack/VoiceOver still work (the semantics tap action is present), which is why the widget tests pass.
- No test covers it: `signin_behaviour_test.dart:287-302` only asserts the *keys* exist; `widget_test.dart:142` taps it with a pointer.

Fix: use an `InkWell` (focusable, activates on Enter/Space) or `FocusableActionDetector` inside the existing `Semantics`, keep the 44 px box, and pin the tab order with a `FocusTraversal`/`sendKeyEvent` test.

## Major

### M1 — The evidence sheet claims tests that do not exist

`qa_checklist.md:72-73` marks acceptance #8 and #9 as "code + test" and says reduced motion is "test only". Grepping the whole test tree for `primaryFocus`/`requestFocus` in the sign-in tests, for `BySemanticsLabel`, and for a 44 px assertion returns nothing:

- **Focus moves to the first invalid field** — implemented (`technician_sign_in_page.dart:99-111`) but never asserted. The invalid-submit test (`signin_behaviour_test.dart:104-113`) asserts only call count and messages.
- **Reveal 44 px target** — never measured. `signin_behaviour_test.dart:304-315` asserts `tooltip == passwordLabel` and the icon swap only. It is *probably* 48 px from the Material default, but the evidence says "test", and there is no test.
- **Reduced motion** — `ReduceMotion.duration` (`reduce_motion.dart:4-6`) is correct and wired (`technician_sign_in_view.dart:177`), but no test sets `disableAnimations` for this screen.

Why major: a Gate 6 sheet that certifies tests which do not exist poisons every other claim on it. Mark those items UNVERIFIED until the tests exist (they are all one-screen widget tests).

## Minors

- **m1** 2FA input contract drift: `signin_dock.dart:229-233` uses `TextInputType.visiblePassword` and `textCapitalization: characters`; `ui_brief.md:218` requires `TextInputType.text` with `autocorrect: false`, `enableSuggestions: false`. Neither flag is set (defaults are `true`).
- **m2** No `Semantics(busy: true)` while submitting (`signin_primary.dart:38-41` sets `enabled: false` only), against `ui_brief.md:215`.
- **m3** The 2FA failure path is unpinned: there is no `AUTH_2FA_INVALID → invalidCredentials` widget test (required by `invariants.md:40`), and the fake never asserts the **challenge token** (`signin_behaviour_test.dart:36-40` discards it), so "calls `verifyTwoFactor` with the token and code" is half-asserted.
- **m4** After an auth error the password is not re-focused (`technician_sign_in_page.dart:82-88`), against `ui_brief.md:216` ("Password keeps focus for retry").
- **m5** At 360 × 800 / 2× text the tagline is below the canvas fold at first paint and the statement's last line sits 16 px above the meta row (`signin_360_20x.png`). `ui_brief.md:180-181` says the *dock* becomes the scrollable sheet; instead the canvas scrolls, without a scroll affordance. Primary is reachable and nothing overflows, so this is not a blocker.
- **m6** The dock stacks at text scale ≥ **1.4** (`signin_tokens.dart:21`) while `ui_brief.md:178` says ≥ 1.5, and `qa_checklist.md:86` silently rewrites the brief's "below 1200" rule to "at every width" instead of recording a deviation. The behaviour is defensible; the paper trail is not.
- **m7** `SignInDims.primaryWidthTablet = 240` (`signin_tokens.dart:34-35`) is dead: the primary is `300` at every width (`signin_dock.dart:159`), where `ui_brief.md:108-112` says 280 at ≥ 1280 and 240 at 1024-1279. (The approved Gate 3 render `docs/evidence/signin_directions/c/c_1440_en.png` also shows ~300, so the *brief* is the stale document — fix the doc or the token, not both.)
- **m8** The auth-package analyzer result has no artifact; `baseline_allowlist.md:64` points to a prose line. Attach the command output.
- **m9** No 600 px capture although 600 is in acceptance #1 (`qa_checklist.md:27-34`). It is covered only by `f2a_screens_test.dart` rendering at 600 with no exception.
- **m10** The gallery's error capture passes a hardcoded English literal (`signin_gallery_test.dart:157`) instead of `l10n.invalidCredentials`, so no AR error-row image exists.
- **m11** Minor language/token drift: the selected language pill is a hardcoded `Fx.white` + `Fx.pillShadow` with `Fx.ink`/`Fx.muted` text (`signin_language_switch.dart:71-80`), while `signin_tokens.dart:3-5` promises colours come from the theme, and `visual_language.md:60-61` says there are no shadows on the band/fields/primary.

## Observations (no action required)

- `ui_brief.md:49-53` says the band *holds* the meta row at every size, but the approved Gate 3 render `docs/evidence/signin_directions/c/c_390_en.png` shows the meta row above the band, exactly as built (`signin_dock.dart:121-125`). The build follows the approved visual; the brief's prose is stale. Do not "fix" the screen.
- The error row sits between the password and the primary on phone (`signin_dock.dart:178-183`), which is neither the §7 ASCII (after the primary) nor §9 ("above the fields"). It is reserved, it does not move the primary (`signin_390_en.png` vs `signin_390_error.png`: primary ~771-823 in both), and it matches the desktop rule. Confirm the intended phone position with the owner.
- The statement's ≥1.5× rule is implemented as a *base* size (`signin_statement.dart:26-28`) that is then scaled again by the platform text scaler, so at 1.5× it renders ≈66 px on desktop, not 44. Visually it preserves the composition; the doc wording and the code disagree.

## Section detail

### §1 Edit-vs-replace — PASS (all four)

1. **Screen file rewritten, not tweaked — PASS.** `packages/auth/lib/src/sign_in_view.dart` and `sign_in_page.dart` are gone; the package now contains only `session_store.dart`, `role_home.dart`, `auth_repository.dart`, `auth_controller.dart`, `admin_sign_in_view.dart` and the barrel. The new 199-line page and 189-line view are app-owned. No file imports the old classes (grep across `client/`).
2. **≥ 1 new widget file per region — PASS.** `widgets/` holds exactly the 8 named files: `signin_command_strip`, `signin_statement`, `signin_dock`, `signin_field`, `signin_primary`, `signin_language_switch`, `signin_meta_row`, `signin_error_row`, plus `signin_tokens.dart`.
3. **Kill list actually deleted — PASS.** `true_report_app.dart` and `router.dart` are gone; `auth.dart` exports only 5 files, none of them the killed four. No `FxTextField`/`FxButton`/`FxLanguageSwitch`, no `technicianPasswordHelp`, no `_BrandMark`/`_Reveal`/`_M` in the sign-in source (grep). "Get help" is plain text (`signin_meta_row.dart:46`). `test/preview/**` is empty/absent. The two login cases are rewritten (`f2a1_geometry_test.dart:147-207`, `o2_copy_fit_test.dart:12-78`).
4. **Visibly different at 1440 / 1024 / 390 — PASS.** 1440/1024: statement top-left + full-width horizontal band on the bottom edge. 390: statement + stacked band, primary in the thumb zone. This is not a centred 350 px column at any of the three.

### §2 Behaviour — PASS

- The 19 failures in `after_test.txt` are exactly the baseline set: 14 goldens, `f2b_a11y`, the two `i18n_source_scan` offenders, `intl_dates_tech`, `o2_copy_fit` empty-state. Final line `+255 -19`; baseline `+231 -19`. +24 net new tests, no new failure.
- Both login goldens pass in the new run and the 14 others still fail identically.
- Non-vacuous pins: invalid submit never calls the repository and shows `requiredField` twice; two Enters issue one request; mapping for `AUTH_INVALID_CREDENTIALS`/`CONNECTIONERROR`/`ACCOUNT_DISABLED`; challenge renders the code cell, Verify, read-only email, no password cell; 6-digit TOTP and `ABCDE-FGHIJ` reach `verifyTwoFactor`; `ABC` never does; locale flip is RTL and preserves the email; the 7 always-present keys exist; no `debugPrint`/`print(` in the page.
- Not pinned: the `AUTH_2FA_INVALID` widget path and the challenge-token value (m3); focus move (M1).

### §3 States — FAIL

Present: default, focus at ≥900, validation, auth error, network, submitting, 2FA, RTL, 1.5×, 2×, 360/390/768/1024/1280/1440. Missing: **keyboard-up** (B1). Also missing as captures: a filled/long-value state, a password focus ring, and 600 px (m9). No state lies.

### §4 Visual / UX honesty — PASS

No workshop name, job, bay, counter, stat or logo anywhere; the only mark is the wordmark. One focal point, one primary. Labels persistent above every cell. No dead affordance. The band touches the bottom edge at every captured size and never rounds its top corners. One accent. No gradient/glow/illustration.

### §5 Accessibility — FAIL

- Contrast recomputed from the real tokens: accent `#006C49` on white ≈ 6.4:1, muted `#5E5D69` ≈ 6.3:1, error `#A3231F` ≈ 7.4:1, ink `#1A1B1F` ≈ 16:1. Claims are conservative and true.
- Reveal: accessible name present; target not asserted (M1).
- Error live region present, reserved even when empty; field messages are live regions.
- Focus move on invalid submit: implemented, untested (M1).
- Language switch: **fails keyboard access (B2)**. Its 44 px hit area is real.
- Motion: reduce-motion honoured.

### §6 i18n / RTL — PASS

Zero raw user-visible literals in the new screen; every string flows from `AppLocalizations`; no `debugPrint`/`print(`. The statement/tagline map to `signInSubtitle`/`technicianSignInTagline`. AR images: wordmark and language label only in Latin; labels right-aligned; reveal at the visual end; caret LTR; no Arabic-Indic digits. Inputs LTR. ARB no-diff is UNVERIFIED by VCS, but no new key is consumed and the scan shows no new offender.

### §7 Mechanical — PASS

- App analyzer 0 (`after_analyze.txt`).
- Auth analyzer: claimed 0, **no artifact** (m8).
- Workspace-wide red only for the documented external untracked preview files.
- Banned primitives absent. Kill list absent. Preview directions absent.
- Resize 1440 → 360 asserts no exception.
- Net +24 tests, no test removed.

### §8 Acceptance checklist (the 14)

| # | Item | Grade | Note |
|---|---|---|---|
| 1 | No clipping/overflow at the matrix widths | PASS | 600 px only via test (m9) |
| 2 | Primary visible at 360×800; bottom 15% at 390×844 | PASS | images |
| 3 | 1.5×/2× readable, primary reachable | PASS | m5 |
| 4 | AR: only wordmark/language Latin; inputs LTR; mirroring | PASS | images + code |
| 5 | Every string from AppLocalizations; no ARB edit | PASS | no literals; offender set unchanged |
| 6 | 2FA accepts 6 digits and `XXXXX-XXXXX` | PASS | behaviour test |
| 7 | Invalid submit no call; double submit one request | PASS | behaviour test |
| 8 | Error row live region; focus to first invalid | **UNVERIFIED** | implemented; the "test" claim is false (M1) |
| 9 | Reveal accessible name + 44 px target | **UNVERIFIED** | name tested; target not (M1) |
| 10 | No page-level credential logging | PASS | source test |
| 11 | Reduced motion: no rise | PASS | code; no test |
| 12 | Two login goldens regenerated; 14 untouched | PASS | log-consistent |
| 13 | Old screen + dead auth shell deleted | PASS | filesystem |
| 14 | Geometry/copy-fit login cases rewritten to intent | PASS | tests |

## What would clear the block

1. Fix B1 (Scaffold/resize or viewInsets padding + the 390 × 500 `viewInsets` test).
2. Fix B2 (focusable language segments + a keyboard traversal test).
3. Repair M1: add the missing focus-move and 44 px tests, or downgrade those checklist rows to "code only".
4. Optional before merge: m1-m11 in one small pass.

Re-run `flutter analyze --no-pub --fatal-infos`, `flutter test`, and re-capture 390 × 844, 360 × 800 and the new keyboard state. Then this is a PASS WITH FIXES.
