# Gate 6 — independent QA verdict, round 2

**Verdict: PASS WITH FIXES** — no blockers, no majors.
**One line:** B1, B2, M1 and m1-m11 are fixed and verified; only a wording edit
and the owner's endorsement of the six `ui_brief.md` §15 amendments remain.

- Reviewer: the same independent `qa-reviewer` session that returned FAIL in round 1.
- Inputs: `qa_verdict.md` (round 1), `qa_checklist.md` (Round 2 section),
  `ui_brief.md` §7/§9/§15, `visual_language.md`, the three after-logs, all PNGs
  including `signin_390_keyboard.png`, `signin_600_en.png`,
  `signin_390_error_ar.png`, and the sign-in source/tests.

## Verified fixes

| Item | Result | Evidence |
|---|---|---|
| **B1** keyboard-up | **FIXED** | `technician_sign_in_view.dart:65-67` is `Scaffold(resizeToAvoidBottomInset: true)`; `signin_gallery_test.dart:251-284` sets 390×500 + `viewInsets.bottom 300`, scrolls, asserts `rect.bottom <= 200` (non-vacuous); `signin_390_keyboard.png` shows the dock ending at y≈544 with the 300 px inset blank below. At 390×844+keyboard the primary needs a short scroll — permitted by §15.3 |
| **B2** keyboard language | **FIXED** | `signin_language_switch.dart:92-107` is a `FocusableActionDetector` with `ActivateIntent` (Enter/Space) and a 2 px `scheme.primary` ring inside the 32 px pill (no shift); `signin_behaviour_test.dart:291-313` Tabs twice, Enters, gets RTL |
| **M1** missing tests | **FIXED** | Focus move, 44×44 reveal, and reduced motion (position at 0 ms == 300 ms under `disableAnimations`) are real and non-vacuous |
| m1 | fixed | 2FA uses `TextInputType.text`, `autocorrect: false`, `enableSuggestions: false` |
| m2 | fixed in substance | `liveRegion: busy`; Flutter has no `Semantics(busy:)` flag |
| m3 | fixed | `AUTH_2FA_INVALID` mapping test + challenge token asserted |
| m4 | fixed | password/code focus restored after a failure |
| m5 | documented | 2× canvas scroll in §15.4 |
| m6 | fixed | stack threshold exactly 1.5 |
| m7 | fixed | primary 300 at every band width; dead token removed; brief amended |
| m8 | fixed | `after_analyze_auth.txt` |
| m9 | fixed | `signin_600_en.png` |
| m10 | fixed | Arabic error capture uses the localized string |
| m11 | fixed | pill colours from the scheme; documented as the sole shadow |

## No regression

`+263 -19` with the same 19 baseline names. App and auth analyzers 0. Both login
goldens still pass pixel-identical although the view now carries a Scaffold —
proof of no restyle. The auth package still has 5 files + the barrel. §15
matches the build and the approved `c_1440_en.png` (primary 300, error row above
the primary, 2× canvas scroll, sole pill shadow).

## Remaining before close

1. ~~Edit `ui_brief.md:215` to drop the unrepresentable `Semantics(busy: true)`.~~ **Done** (2026-11-19).
2. Owner endorsement of the six `ui_brief.md` §15 amendments.

Gate 6 closes on (2).

**Closed 2026-11-19:** the owner endorsed all six §15 amendments. The screen is
cleared to ship. W-SIGNIN-WEB is approved with this closure.
