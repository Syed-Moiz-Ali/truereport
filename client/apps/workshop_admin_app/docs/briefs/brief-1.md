TITLE: Pin Workshop Admin sign-in behaviour and make CI honest (no UI work)

WORKDIR: `E:\syed_moiz_ali\bitlogix\truereport\client\apps\workshop_admin_app`
MODE: implement (engineering only)
COMMITS: none

## OUTCOME

When this brief is done, the Workshop Admin sign-in screen's behaviour is pinned by tests that
mount the **real** `WorkshopLoginPage`, every widget test in the app lays out with real bundled
fonts, and CI fails on any failure that is not in `docs/baseline_allowlist.json`. Three known
defects (silent 2FA challenge, arbitrary membership selection, missing API language header) are
fixed with tests that prove the new behaviour. **No pixel, layout, colour, type, spacing or copy
decision changes in this brief.**

## WHY THE CURRENT STATE IS REJECTED

- `test/ui_matrix_test.dart:157,191` and `test/widget_test.dart:35,47` mount `SignInPage`
  (`package:auth`), not `WorkshopLoginPage`. 22 "sign-in" tests are green against a page this app
  does not use.
- `test/ui_matrix_test.dart` iterates `Brightness.dark` although `AppTheme.build` asserts
  light-only (`packages/design_system/lib/src/tokens.dart:736-748`).
- Real fonts load only inside `test/workshop_real_font_screenshot_test.dart:33`; every other test
  measures Ahem.
- CI (`\\.github/workflows/ci.yml`) runs `flutter test` for this app, which is red today on 3
  `source_scan_test.dart` rules. There is no mechanism to distinguish those from a new break.
- `_submit()` discards the `AuthResult`, so an `AuthChallenge` is a silent no-op.
- `Session.role` uses `memberships.first`; the API does not guarantee order.
- The workshop app never sets `ApiClient.acceptLanguage` / `clientName`.

## CONTEXT

- Flutter 3.47.9 / Dart 3.13.7, workspace at `client/` (`flutter pub get` at `client/`).
- Entry: `lib/main.dart` → `lib/app.dart` → `lib/src/admin_router.dart` → `lib/src/features/auth/workshop_login_page.dart`.
- Auth: `packages/auth/lib/src/{auth_controller,auth_repository}.dart`.
- Domain: `packages/domain/lib/src/{session,membership,role}.dart`.
- API: `packages/api_client/lib/src/{api_client,problem_details,api_endpoints}.dart`.
- Read first: `docs/invariants.md`, `docs/baseline_allowlist.md`, `docs/data_gaps.md`,
  `docs/api/contracts.md`. Sample payloads: `docs/data/samples/`.
- Skills to load: `flutter-test`, `api-data-integrity`.

## SCOPE

**In scope:** `test/`, `tool/`, `docs/`, and the *behaviour* of
`lib/src/features/auth/workshop_login_page.dart` (branching/state only), `packages/auth`,
`packages/domain`, `packages/api_client`, `lib/main.dart`.

**DO NOT TOUCH:** any visual property of `workshop_login_page.dart` (colours, sizes, radii,
shadows, fonts, spacing, widget tree shape), `packages/design_system`, `packages/l10n` copy
(except the one new key in R7), the router's redirect logic, other apps, the server, migrations.

If a fix seems to require an out-of-scope change: **stop and report**, do not improvise.

## REQUIREMENTS

**R1 — Retarget the fake tests.** `ui_matrix_test.dart` and `widget_test.dart` must mount
`WorkshopLoginPage`. Replace the `Brightness` loop with light-only and add one test asserting
`AppTheme.build(brightness: Brightness.dark)` throws (the light-only decision becomes pinned, not
silently dropped).

**R2 — Record what the corrected harness reveals.** Any failure that appears only because the
harness was wrong is **pre-existing**, not new: add it to `docs/baseline_allowlist.md` (with the
exact reproducing output) and to `docs/baseline_allowlist.json`. Do **not** fix layout in this
brief.

**R3 — One real-font loader.** Create `test/flutter_test_config.dart` that loads the bundled
`.ttf/.otf` files from `packages/design_system/assets/fonts` into `FontLoader`s using the
`TrFonts` family names (both the `packages/design_system/` prefixed and bare names) plus
`MaterialIcons`. Delete the private `_loadRealFonts()` from
`workshop_real_font_screenshot_test.dart` and make it depend on the global loader. Prove it: a
test that renders `Text('Inspection')` with the theme and asserts the resolved family is
`packages/design_system/Plus Jakarta Sans` (not Ahem).

**R4 — Characterization tests for the invariants (tests first, against today's behaviour).**
Add `test/signin_characterization_test.dart` covering, with a fake `AuthRepository`/`ApiClient`:
I1 (redirect matrix: null session → `/signin`, workshopAdmin → `/workshop`, technician →
`/unauthorized`, loading → no redirect), I5 (each `AppFailure.code` → the exact l10n string),
I7 (blank email, malformed email, blank password block the call), I8 (double-tap sends exactly one
request), I9 (eye toggle flips `obscureText` and sends nothing), I11 (the three keys resolve).
These must pass on unchanged behaviour before R5-R8 change anything.

**R5 — 2FA is not silent (invariant I6).** `AuthChallenge` must produce a visible, localized
message and must not write a session. Add `twoFactorRequired` to `app_en.arb` + `app_ar.arb` with
factual provisional copy ("Two-factor authentication is required for this account. Contact your
platform administrator."). Gate 3 owns the final wording — do not invent a TOTP input
(`test/source_scan_test.dart:248-264` forbids it).

**R6 — Membership selection is deterministic (I13, gaps G4/G5).** Pin today's behaviour with a
test, then change it: pick the membership that grants the highest privilege
(`PLATFORM_ADMIN` > `WORKSHOP_ADMIN` > `TECHNICIAN`) instead of `memberships.first`, and make an
unknown role string an explicit, tested outcome rather than a silent `technician` fallback.

**R7 — API language + client attribution (gap G6).** In `lib/main.dart` (or a small bootstrap
called from it), set `apiClient.acceptLanguage` to the active `Locale.languageCode` and
`clientName = 'workshop_admin'`, and keep them in sync when the locale changes. Test it.

**R8 — Baseline enforcement, new failures only.** Create
`docs/baseline_allowlist.json` (machine-readable: analyzer entries + failing test names) and
`tool/baseline_check.dart` that runs the suite and **exits 1** if: a test fails that is not
allowlisted; an allowlisted test now passes (forces the list to stay truthful); or an analyzer
issue appears that is not allowlisted. Wire it into `.github/workflows/ci.yml` as a step after
`flutter test` for this app. Prove it by injecting one deliberate failing test, showing CI red,
then reverting.

**R9 — Autofill group (gap F5).** Wrap the sign-in form in `AutofillGroup` and call
`TextInput.finishAutofillContext()` after a successful sign-in. No visual change.

**R10 — Coverage and gates.** Run `dart format --output=none --set-exit-if-changed .`,
`flutter analyze --fatal-infos`, `flutter test --coverage`. Record baseline coverage in
`docs/baseline_coverage.md`; the sign-in auth path must not lose coverage.

**R11 — Live contract confirmation (closes evidence gap G7).** Start the dev server, sign in with
a seeded workshop admin from `TEST_LOGIN_CREDENTIALS.txt`, and diff the real response against
`docs/data/samples/login-success.json`. Record the diff in `docs/api/contracts.md` under
"Live confirmation". If the server cannot be started, say so explicitly and leave G7 open.

## BANNED

- Any change that alters rendering: `Colors.`, `Color(`, `fontSize:`, `BorderRadius.circular(`,
  `BoxShadow(`, `fontFamily:`, hardcoded `EdgeInsets`/`SizedBox` numbers, widget tree rewrites in
  `workshop_login_page.dart`.
- Deleting a test without an equivalent replacement (except the wrong-widget and dark-axis loops,
  which R1 replaces).
- `// ignore:` on analyzer findings instead of fixing them.
- New dependencies. Goldens. Commits.

## PHASES (stop after each)

**Phase A — R3 + R1 + R2.** Global font loader, retargeted tests, corrected harness results
recorded. Evidence: full test output before/after, allowlist diff, one screenshot regenerated to
prove real glyphs. **STOP.**

**Phase B — R4.** Characterization tests green against unchanged behaviour. Evidence: test names
+ "these pass without touching lib/". **STOP.**

**Phase C — R5, R6, R7, R9.** Behaviour fixes, each with its test. Evidence: per-fix test name and
what it asserted before/after. **STOP.**

**Phase D — R8, R10, R11.** Baseline gate, format/analyze/coverage, live contract diff.
**STOP.**

## VERIFICATION (paste results, do not summarise)

```
cd client && flutter analyze --fatal-infos
cd client/apps/workshop_admin_app && dart format --output=none --set-exit-if-changed . && flutter test
cd client/apps/workshop_admin_app && flutter test --coverage
cd client/apps/workshop_admin_app && dart run tool/baseline_check.dart
git status --short        # prove no visual file changed
git diff -- lib/src/features/auth/workshop_login_page.dart   # must show no styling hunk
```

## ACCEPTANCE CRITERIA

1. Zero tests mount `SignInPage` as a proxy for the workshop sign-in screen.
2. `flutter test` is green **or** red only on entries in `docs/baseline_allowlist.json`.
3. The injected-failure proof exists (command, output, revert).
4. Every R4 invariant has a named passing test.
5. `git diff` on `workshop_login_page.dart` contains no styling change.
6. No new dependency; no commit.

## REPORT FORMAT

What changed and why · what was retargeted vs replaced · evidence paths · test counts
(pass/fail/allowlisted) · coverage before/after · live contract diff or "G7 still open" ·
assumptions · risks · confirmation that no visual property changed.
