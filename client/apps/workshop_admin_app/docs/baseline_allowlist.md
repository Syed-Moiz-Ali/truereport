# Baseline allowlist — Workshop Admin (Phase 0-lite)

Everything below is **already broken before the rebuild starts**. The rebuild's CI rule is
"new failures only": these three failures are allowed to stay red until the sign-in brief
fixes them; anything else that goes red is a stop.

Measured on `ui-reset-polish` @ `db19b24`, Flutter 3.47.9 / Dart 3.13.7, Windows, read-only audit.

## Commands and raw results

### 1. Analyzer

```
$ cd client/apps/workshop_admin_app
$ flutter analyze --fatal-infos
Analyzing workshop_admin_app...
No issues found! (ran in 82.8s)

$ cd client            # this is what .github/workflows/ci.yml actually runs
$ flutter analyze --fatal-infos
Analyzing client...
No issues found! (ran in 24.0s)
```

**Baseline: 0 analyzer issues, 0 infos — app-level and repo-level agree.** Any new issue is a
new failure.

### 1b. CI state today

`.github/workflows/ci.yml` runs `flutter analyze --fatal-infos` at `client/`, then
`flutter test` in `technician_app` and in `workshop_admin_app`. **The admin test step is red
today** on the three `source_scan_test.dart` rules below. The pipeline is therefore already
blocking, and the rebuild's "new failures only" rule is the only way to land engineering work.

### 2. Tests

```
$ cd client/apps/workshop_admin_app
$ flutter test
...
00:54 +393 -3: Some tests failed.

Failing tests:
  .../test/source_scan_test.dart: widgets outside design_system do not hardcode colours or font sizes
  .../test/source_scan_test.dart: widgets outside design_system do not hardcode font families
  .../test/source_scan_test.dart: widgets outside design_system do not hardcode radii, shadows or gradients
```

**Baseline: 396 executed — 393 pass, 3 fail, 0 skipped. Pass rate 99.2%.**

All three failures come from one file: `lib/src/features/auth/workshop_login_page.dart`.

```
$ flutter test test/source_scan_test.dart
  hardcode colours or font sizes  -> workshop_login_page.dart:421, :432, :462, :603
  hardcode radii, shadows, grads  -> workshop_login_page.dart:158, :383, :461, :557
  hardcode font families          -> workshop_login_page.dart:523
```

| Rule | Line | Offender |
|---|---|---|
| colours / font sizes | 421 | `fontSize: 36` on the panel headline |
| colours / font sizes | 432 | `fontSize: 15` on the panel body line |
| colours / font sizes | 462 | `Colors.black.withValues(...)` card shadow |
| colours / font sizes | 603 | `Colors.white.withValues(...)` grid painter |
| radii / shadows / gradients | 158, 383 | `BorderRadius.circular(6)` brand badge |
| radii / shadows / gradients | 461 | `BoxShadow(...)` preview card |
| radii / shadows / gradients | 557 | `BorderRadius.circular(3)` progress track |
| font families | 523 | `fontFamily: 'monospace'` on the plate |

Knock-on evidence: `'monospace'` is not a registered family, so in the test harness the plate
falls back to Ahem and renders as **solid black blocks** in
`test/screenshots/real/workshop_signin_1440.png` and `..._1280_ar.png`.

### 3. Overflow / layout warnings

```
$ flutter test test/ui_matrix_test.dart
+91 ~0 -0  -> no RenderFlex overflow, no exceptions
```

**Baseline: 0 `RenderFlex overflowed`.** The matrix is green — but see A2, it is green
against the wrong widget.

### 4. Coverage

No coverage gate is configured (`flutter test --coverage` is never run in CI for this app).
**Baseline: not measured, not enforced.** Brief 1 introduces the gate; until then this is a gap,
not a failure.

### 5. Build / bundle

```
$ flutter build web --release
```
Recorded in `docs/baseline_build.md` (fills the "not measured" hole for bundle size).

### 6. Screenshot artifacts

`test/screenshots/real/` holds 77 tracked PNGs. `workshop_real_font_screenshot_test.dart`
**rewrites all of them on every `flutter test` run** and asserts nothing about them. Running
the baseline suite dirtying the worktree is expected behaviour today, not a regression:
after the baseline run I restored the files with `git checkout -- test/screenshots` so the
tree is clean.

## Allowed failures

| ID | Failure | Reproduce with | Owner | Remove when |
|---|---|---|---|---|
| A1 | `source_scan_test`: hardcoded colours/font sizes | `flutter test test/source_scan_test.dart` | sign-in rebuild | the sign-in brief replaces lines 421/432/462/603 with tokens |
| A2 | `source_scan_test`: hardcoded radii/shadows | same | sign-in rebuild | lines 158/383/461/557 replaced with `ws.*` tokens / `WorkshopCard` |
| A3 | `source_scan_test`: hardcoded font family | same | sign-in rebuild | `fontFamily: 'monospace'` removed (line 523) |

A1-A3 are one defect (the screen pre-dates the token rules), tracked as one brief item.

## Audit findings that are **not** test failures

These are green-tested lies or unpinned behaviour. They are recorded in
`docs/baseline_metrics.md` and must be fixed by the rebuild, but they do not trip CI:

- **A4** `test/ui_matrix_test.dart:157, 191` and `test/widget_test.dart:35, 47` mount
  `SignInPage` (`packages/auth`), **not** `WorkshopLoginPage`. 22 green "sign-in" tests cover
  the unused page. The real page is only covered at 1280 EN and 390 EN.
- **A5** `ui_matrix_test.dart` iterates `Brightness.dark` although `AppTheme.build` asserts
  light-only (`tokens.dart:736-748`) and the app sets `themeMode: ThemeMode.light`.
- **A6** No `test/flutter_test_config.dart`: real fonts load only inside
  `workshop_real_font_screenshot_test.dart:33`. Every other test lays out with Ahem metrics.
- **A7** No test asserts the error banner, the validation messages, the submitting state or
  the eye toggle.
- **A8** `AuthChallenge` (2FA) is ignored (`workshop_login_page.dart:51-53`) — silent no-op.

## Change-detection rule for this rebuild

A run fails on: any analyzer issue, any test failure not listed above, any new
`RenderFlex overflowed`, any deleted or weakened existing test, any screenshot PNG changed
without a matching `docs/` note.

## Status after W1 (2026-11-18)

The machine-readable form lives in `docs/baseline_allowlist.json` and is enforced by
`tool/baseline_check.dart` (wired into CI).

| Check | Baseline | Now |
|---|---|---|
| Tests executed | 396 | **406** |
| Pass | 393 | **403** |
| Fail | 3 | **3 — same three, still allowlisted** |
| Analyzer | 0 | **0** |
| Format | 19 files unformatted (never gated) | **19 allowlisted, 0 new** |
| `RenderFlex overflowed` | 0 | **0** |

Evidence of the gate actually working: `docs/briefs/brief-1-results.md` §Phase D contains the
injected-failure run (exit 1) and the stale-entry run (exit 1), plus the revert.

**A4 is fixed** — no test mounts `SignInPage` as a proxy for this screen any more. **A5 is fixed**
— the dead dark axis is gone and replaced by an explicit light-only assertion. **A6 is fixed** —
`flutter_test_config.dart` loads real fonts for every test file. **A7 is fixed** in the
characterization suite (error banner, validation, submitting, eye toggle). **A8 was a real bug**
and is fixed (2FA challenge now shows a localized message).

A1–A3 remain open by design: they are the three token rules the visual rebuild must satisfy, so
they are the first thing the mini Brief must make green.
