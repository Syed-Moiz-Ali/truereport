# W1 results — Brief 1 (non-visual engineering)

Executed 2026-11-18. Every phase stopped, was verified, and is recorded below.

## Phase A — harness (R1, R2, R3)

| Change | Evidence |
|---|---|
| Global real-font loader: `test/support/real_fonts.dart` + `test/flutter_test_config.dart` (runs before every test file). Private `_loadRealFonts()` deleted from the screenshot suite. | `test/font_harness_test.dart` asserts the family resolves to `packages/design_system/Plus Jakarta Sans` and that the measured width is **not** Ahem's `fontSize × length` signature (140 px for a 10-char string at 14 px). Passes. |
| `ui_matrix_test.dart` and `widget_test.dart` now mount `WorkshopLoginPage`, not `SignInPage`. | 22 tests retargeted. |
| Dead dark axis removed. `_MatrixApp.brightness` was stored but **never read** — the loop rendered the identical light theme twice. Replaced by one explicit test: `AppTheme.build(brightness: Brightness.dark)` throws. | `test/ui_matrix_test.dart` — "the app is light-only by decision". |
| R2: what the corrected harness revealed | **Nothing new.** Sign-in passes at 360/390/768/1024/1440 × EN/AR and at 2.0× text scale with real fonts. The 3 pre-existing `source_scan` failures are unchanged. No allowlist additions were needed. |

Suite arithmetic: 396 − 20 (dead dark duplicates) + 3 (font ×2, light-only ×1) = **379 at the end of Phase A**, 376 pass / 3 allowlisted.

## Phase B — characterization (R4)

`test/signin_characterization_test.dart` — **14 tests, all green against unchanged behaviour**:

- I11 stable keys · I7 required-field ×2 and malformed email, both proving zero requests · I8 double tap = 1 request · I9 eye toggle flips `obscureText`, sends nothing · I5 `AUTH_INVALID_CREDENTIALS` / `CONNECTIONERROR` / unknown → the exact l10n string · I5 Arabic copy · I2 a failed attempt keeps the typed email · I1 redirect matrix (no session → sign-in, workshop admin → shell, technician → unauthorized, pending restore → no redirect).

These were written and run **before** any `lib/` change in Phase C.

## Phase C — behaviour fixes (R5, R6, R7, R9)

`test/signin_behaviour_fixes_test.dart` — **13 tests**. Each would fail on the pre-brief code.

| Req | Change | Test |
|---|---|---|
| R5 | `AuthChallenge` now sets a visible message; `twoFactorRequired` added to `app_en.arb` + `app_ar.arb`; no code-entry UI, `verifyTwoFactor` never called | 2 tests (EN + AR) |
| R6 | `Session.role` picks the **highest-privilege** membership instead of `memberships.first` | 4 tests (order both ways, empty, platform flag) |
| G5 | unknown role → `Role.leastPrivilege` (explicit, documented constant) | 3 tests (`fromApi` null, unknown string, null role) |
| R7 | `apiLanguageSyncProvider` sets `X-Client: workshop_admin` and `Accept-Language` from the active locale, kept in sync | 3 tests |
| R9 | form wrapped in `AutofillGroup`; `TextInput.finishAutofillContext()` on success | 1 test |

## Phase D — gates (R8, R10, R11)

### Baseline gate — proven both ways

```
$ dart run tool/baseline_check.dart
tests: 3 allowlisted failure(s), 0 new
format: 19 allowlisted file(s), 0 new
analyzer: clean
baseline_check: OK                       (exit 0)
```

**Injected-failure proof** (the requirement):

```
$ # added test/baseline_injection_test.dart with expect(1, 2)
NEW TEST FAILURES (not in docs/baseline_allowlist.json):
  x INJECTED: this must turn the gate red
baseline_check: FAILED                   (exit 1)
$ # file removed
```

**Stale-entry proof** (so the list cannot rot):

```
$ # added a passing test name to the allowlist
STALE ALLOWLIST ENTRIES (now passing — delete them from docs/baseline_allowlist.json):
  ~ sign-in en small-phone has no overflow
baseline_check: FAILED                   (exit 1)
```

Wired into `.github/workflows/ci.yml` right after the admin `flutter test` step, with
`--skip-analyze` because the repo-wide `--fatal-infos` step already covers analysis.

### Format

`dart format --output=none lib test tool` → **19 pre-existing unformatted files**, none of them
new and none of them touched by this brief. They are listed in
`docs/baseline_allowlist.json` so the gate fails only on a **new** unformatted file. Everything
written by Brief 1 is format-clean.

### Coverage

`docs/baseline_coverage.md` — overall 70.1 % of lines; **`workshop_login_page.dart` 96.9 %**
(285/294).

### R11 — live contract

**Not done: no server was reachable** (`http://localhost:8080/health` refused the connection).
Evidence gap **G7 stays open**. The samples in `docs/data/samples/` remain constructed from
producer code, and `docs/api/contracts.md` says so.

## Suite totals

| | Baseline | After W1 |
|---|---|---|
| Executed | 396 | **406** |
| Pass | 393 | **403** |
| Fail | 3 (allowlisted) | **3 (same three, allowlisted)** |
| New tests | — | **30** (2 font, 1 light-only, 14 characterization, 13 behaviour) |
| Analyzer | 0 | **0** |
| Sign-in page coverage | not measured | **96.9 %** |

## Deviation worth flagging

`workshop_login_page.dart` shows 4 whitespace-only hunks (`Expanded`, two `Text`, one
`Border.all` collapsed to one line). They are what the current `dart format` produces and carry
**no** widget-tree, colour, type, spacing, radius or shadow change. The behavioural diff is:
1 import, 1 result capture + 2FA branch + autofill finish, 1 switch arm, 1 `AutofillGroup` wrap.
