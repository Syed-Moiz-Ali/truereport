# Gate 6 — QA checklist and evidence (technician sign-in)

Reviewer: independent `qa-reviewer` session. Grade only from this sheet, the
images, the briefs and the code diff. Do not accept the builder's prose as
evidence.

## What was rebuilt

- **Screen:** `/signin` of `client/apps/technician_app`.
- **Direction:** C "The dock" (Gate 3, user). Spec: `docs/ui_brief.md`.
- **Visual language:** `docs/visual_language.md`.
- **Behaviour:** unchanged except three audited defects fixed at the root
  (no PII logging, no double submit, 2FA recovery codes accepted). Pinned by
  `test/features/auth/signin/signin_behaviour_test.dart`.

## Edit-vs-replace test (all four must pass)

| Test | Evidence |
|---|---|
| 1. Screen file rewritten, not tweaked | Old screen was `packages/auth/lib/src/sign_in_view.dart` (459 lines) + `sign_in_page.dart` (137). Both are **deleted**. New app-owned page + view: `lib/src/features/auth/signin/technician_sign_in_page.dart`, `technician_sign_in_view.dart` |
| 2. ≥1 new widget file per region | `widgets/`: `signin_command_strip`, `signin_statement`, `signin_dock`, `signin_field`, `signin_primary`, `signin_language_switch`, `signin_meta_row`, `signin_error_row` (8 files) |
| 3. Non-empty kill list | Old view/page; the dead `auth` shell (`true_report_app.dart`, `router.dart`); their barrel exports; `_BrandMark`, `_Reveal`, the fixed `_M` Figma metric set. See `docs/visual_language.md` §9 |
| 4. Visibly different structure at 1440, 1024, 390 | 1440/1024: statement canvas + horizontal bottom band (email · password · primary). 390: canvas + stacked bottom band, primary in the thumb zone. Old: 222 px glow hero + centred 350 px column at every size |

## Capture matrix (real bundled fonts, light)

| Width | EN | AR | Notes |
|---|---|---|---|
| 1440 | `signin_1440_en.png` | — | horizontal dock, meta inside the band |
| 1280 | `signin_1280_en.png`, `signin_1280_en_15x.png` | `signin_1280_ar.png` | 1.5× stacks the dock |
| 1024 | `signin_1024_en.png` | — | horizontal dock boundary |
| 768 | `signin_768_en.png` | — | two-row dock, primary full width |
| 600 | `signin_600_en.png` | — | stacked dock boundary |
| 390 | `signin_390_en.png`, `signin_390_error.png`, `signin_390_error_ar.png`, `signin_390_challenge.png`, `signin_390_keyboard.png` | `signin_390_ar.png` | error / 2FA / keyboard-up states |
| 360 | `signin_360_en.png`, `signin_360_20x.png` (EN 2×) | `signin_360_15x.png` (AR 1.5×) | extreme text scale |

Primitive gallery: `docs/evidence/gallery/signin_primitives_ltr.png`,
`signin_primitives_rtl.png`, `signin_field_invalid_en.png`,
`signin_field_invalid_ar.png`, `signin_index.html`.

## Mechanical evidence

| Check | Result | Artifact |
|---|---|---|
| App analyzer `--fatal-infos` | **0** | `docs/evidence/logs/after_analyze.txt` |
| Auth package analyzer | **0** | `docs/evidence/logs/after_analyze_auth.txt` |
| Technician tests | **263 pass / 19 fail** — the exact 19 baseline failures, no new one | `docs/evidence/logs/after_test.txt`; allowlist §B |
| Login goldens | 2 regenerated; the other 14 byte-identical | `test/goldens/` |
| Resize 1440 → 360 | no render exception; test asserts it | `signin_gallery_test.dart` |
| Banned primitives on the screen | none (`FxTextField`, `FxButton`, `FxLanguageSwitch` absent) | grep in §E of the allowlist |
| Raw user-visible literals | none added; i18n scan still red only for the external B3/B4 baseline | `docs/baseline_allowlist.md` §B |
| Workspace-wide analyze | red for 11 issues in **untracked preview files of other apps** created after this wave's baseline; not touched here | allowlist §E external delta |

## States to look for in the images

Default · focused (email ring) · filled · validation error (field + message) ·
auth error (reserved row, primary unmoved) · network copy (same row) ·
2FA challenge (read-only account, code cell, Verify) · submitting (gallery:
primary busy spinner) · disabled (challenge account) · RTL · 1.5× · 2× ·
reduced motion (no visual difference; test only).

## Acceptance checklist (from `docs/ui_brief.md` §13)

| # | Item | Where |
|---|---|---|
| 1 | No clipping/horizontal scroll/new overflow at the matrix widths | images; gallery asserts no exception |
| 2 | Primary visible at 360×800; bottom 15% at 390×844 | `signin_360_en.png`, `signin_390_en.png` |
| 3 | 1.5×/2× readable, primary reachable | `signin_360_15x.png`, `signin_360_20x.png`, `signin_1280_en_15x.png` |
| 4 | AR: only the wordmark/language may be Latin; inputs LTR; mirroring | `signin_390_ar.png`, `signin_1280_ar.png`, `signin_360_15x.png` |
| 5 | Every string from `AppLocalizations`; no ARB edit | code + i18n scan |
| 6 | 2FA accepts 6 digits and `XXXXX-XXXXX` | behaviour test |
| 7 | Invalid submit never calls the repository; double submit issues one request | behaviour test |
| 8 | Error row is a live region; focus moves to the first invalid field | test |
| 9 | Reveal has an accessible name and 44 px target | test + gallery |
| 10 | No page-level credential logging | source test |
| 11 | Reduced motion: no rise | test |
| 12 | Only the two login goldens regenerated | `git status` |
| 13 | Old shared screen + dead auth shell deleted | `git status` deletions |
| 14 | Geometry/copy-fit login cases rewritten to intent, not deleted | `f2a1_geometry_test.dart`, `o2_copy_fit_test.dart` |

## Known deviations and waivers

- **W-LIGHT (approved at Gate 5):** no dark gallery; the app asserts light-only.
- **W-SIGNIN-WEB (proposed):** no live device/browser walk; evidence is widget
  captures + the suite.
- At ≥ 1.5× text the dock stacks at every width (a readability choice, stated in
  the brief).
- At ≥ 1.8× the command strip becomes two rows (the wordmark must not truncate).

## Verdict format

Write `docs/evidence/signin/qa_verdict.md` with:
**PASS / PASS WITH FIXES / FAIL**, a blocker/major/minor list where each item
names the image or file it comes from, and a one-line reason for the verdict.
Blockers are limited to: a restyle (any of the four edit-vs-replace tests
fails), a new render exception, a missing state, an accessibility failure, a
behaviour regression, or a fake/misrepresented number. Taste preferences are
minors at most.

## Round 2 — after the independent FAIL (2026-11-19)

Round 1 verdict: `docs/evidence/signin/qa_verdict.md` — **FAIL** (B1 keyboard-up
state absent; B2 language switch pointer-only; M1 the sheet claimed tests that
did not exist; m1-m11).

| Item | Fix | Evidence |
|---|---|---|
| **B1** keyboard-up | View wrapped in `Scaffold(resizeToAvoidBottomInset: true)`; the body shrinks, the dock joins the scroll view below 640 px available height | tests `keyboard-up keeps the primary above the inset` (390×500, inset 300) and 1440→360 resize; capture `signin_390_keyboard.png` |
| **B2** keyboard language | Each segment is a `FocusableActionDetector` with a focus ring; Tab/Enter/Space activate | test `language switch is keyboard operable and first in tab order` |
| **M1** missing tests | Added: invalid-submit focus move, 44×44 reveal target, reduced-motion no-rise | behaviour + gallery tests |
| m1 | 2FA uses `TextInputType.text`, `autocorrect: false`, `enableSuggestions: false` | `signin_field.dart`, `signin_dock.dart` |
| m2 | `liveRegion` while the primary is busy | `signin_primary.dart` |
| m3 | `AUTH_2FA_INVALID → invalidCredentials` test; the challenge token is asserted | behaviour test |
| m4 | Password (or code) regains focus after a failure | `technician_sign_in_page.dart` + test |
| m5 | 2× canvas scroll documented in `ui_brief.md` §15 | brief |
| m6 | Stack threshold is exactly 1.5, matching the brief | `signin_tokens.dart` |
| m7 | Primary is 300 at every band width; the dead token is gone; the brief is amended | `signin_tokens.dart`, `ui_brief.md` §7/§15 |
| m8 | Auth analyzer output written to `docs/evidence/logs/after_analyze_auth.txt` | log |
| m9 | 600 px capture added | `signin_600_en.png` |
| m10 | Arabic error capture uses the localized string | `signin_390_error_ar.png` |
| m11 | Language pill colours come from the scheme; it is the documented sole shadow | `signin_language_switch.dart`, `visual_language.md` |

Re-run after the fixes: app analyzer 0, auth analyzer 0, **263 pass / 19 fail**
(the same baseline), all captures assert no render exception.
