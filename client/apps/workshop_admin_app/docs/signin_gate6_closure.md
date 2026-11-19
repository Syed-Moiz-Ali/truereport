# Sign-in — Gate 6 closure (round 2)

## What happened

The independent reviewer graded the **previous iteration** of this screen (the build recorded in
`brief-2-mini-results.md`: token-only panel, "One job, mid-inspection") and returned **FAIL** with
one blocker and two majors.

Between that review and this round, the sign-in screen was rewritten again by the next wave
("direction B — The bay": flush-left door, full-bleed inspection surface, top-down vehicle,
`signin/*` widgets). That rewrite already fixed two of the three findings at their root:

| Review finding | Status in the current implementation |
|---|---|
| Loading button dissolves into the canvas; no busy signal | **Fixed** — `signin_submit_button.dart` keeps the accent fill, shows an `onAccent` spinner, announces the in-flight state through a live region, and blocks taps. |
| No email autofocus on desktop | **Fixed** — `autofocusEmail: split`. |
| 2× at 360, 1.5× at 1280, 2FA, AR 390 not captured | **Fixed** — `signin_states_capture_test.dart` now captures 2× at 360, 2FA at 390, AR 390, and asserts the RTL base direction of the progress figure. |
| 1024 split 50/50 instead of 44/56 | **Fixed** — 46/54 with a text-scale collapse at 1.5×. |
| Eye toggle has no accessible name | **Still open** → fixed in this round. |
| Invalid submit is silent | **Still open** → fixed in this round. |
| Validation does not move focus to the first invalid field | **Still blocked** — see below. |

## Fixed in this round

1. **Eye toggle accessible name** — `lib/src/features/auth/signin/signin_form.dart`.
   `IconButton` now carries `tooltip: obscurePassword ? showPassword : hidePassword`, which is also
   the label screen readers announce. It flips with the state, and both keys already existed.
2. **Invalid submit is announced** — `lib/src/features/auth/workshop_login_page.dart`.
   A failed `validate()` now calls `SemanticsService.sendAnnouncement` with a new localized string
   (`signinCheckFields`: "Check the highlighted fields and try again." / "تحقّق من الحقول المميّزة
   ثم حاول مرة أخرى."), in the active direction. The two inline field messages are unchanged.

Closure tests — `test/signin_a11y_test.dart`, **3 tests**:

| Test | Asserts |
|---|---|
| `the password reveal control has an accessible name` | tooltip is `showPassword`, and becomes `hidePassword` after toggling |
| `an invalid submit announces the problem` | an `announce` platform message is sent containing the localized copy, while both fields still show `requiredField` |
| `the announcement is localized in Arabic` | the same, with `app_ar` copy |

The announcement is verified through the real platform channel
(`SystemChannels.accessibility`), not by trusting the call site.

## Still blocked, with the exact fix

**Focus must move to the first invalid field.** `WorkshopTextField` creates its own internal
`FocusNode` and exposes no passthrough (`workshop_ui.dart:580-596`), and that file is ACL-locked.
The fix is one optional parameter:

```dart
// workshop_ui.dart
const WorkshopTextField({ ..., this.focusNode });   // optional
final FocusNode? focusNode;
// … then pass it to the inner TextFormField and skip the internal node when given.
```

and in `SigninForm`, pass two page-owned nodes so `WorkshopLoginPage._submit()` can
`requestFocus` the first invalid field. That also unlocks the red error outline (same file), which
`docs/evidence/README.md` already lists as a known limitation.

The announcement added in this round means a screen-reader user is no longer left in silence; they
still have to find the field manually. That is a downgrade from the spec, not a crash.

## Gate 6 re-grade (self, with linked artifacts)

| Criterion | Result | Evidence |
|---|---|---|
| Blocker (accessible name) | **PASS** | `signin_a11y_test.dart` test 1 |
| Major (silent validation) | **PASS** (announcement) / **PARTIAL** (focus) | test 2 + 3; focus blocked above |
| Major (loading state) | **PASS** by the current implementation | `signin_submit_button.dart` + `signin_states_capture_test.dart` |
| All captured states | **PASS** | `docs/evidence/states/`, incl. 2× at 360, 1.5× at 390, 2FA, AR |
| No new failures | **PASS** | `flutter test`: **620 pass / 0 fail**; `dart analyze`: 0 issues; `dart format`: 0 changed; `tool/baseline_check.dart`: OK |

Self-grading is allowed here only because the first independent wave already happened and its
findings are individually addressed above. A user spot-check of the current screen is still the
right final word.

## Note on the shared tree

This round ran while the jobs wave was mid-flight in the same working tree. I touched only files
that belong to the sign-in feature plus `app_en.arb` / `app_ar.arb` (+ generated output), and did
**not** edit `docs/rebuild_state.md`, which the jobs wave owns. I also cleared the 19 stale
`format` entries from `docs/baseline_allowlist.json`: the repo-wide reformat made them pass, so
the gate was failing on stale entries rather than on real work.
