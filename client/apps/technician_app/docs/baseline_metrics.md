# Baseline metrics — technician_app (Phase 0-lite)

Measured 2026-11-19 before any edit, from
`E:\syed_moiz_ali\bitlogix\truereport\client\apps\technician_app`.

| Metric | Value | Command / note |
|---|---|---|
| Flutter | 3.47.9 stable · Dart 3.13.7 | `flutter --version` |
| Analyzer (app) | **0 issues** | `flutter analyze --no-pub` (raw: `docs/evidence/logs/baseline_analyze.txt`) |
| Analyzer (CI command, whole workspace) | **0 issues** | `cd client && flutter analyze --fatal-infos` (7.3 s, after `flutter pub get`) |
| Tests | **231 pass / 19 fail / 0 skip (250 total)** | `flutter test --no-pub --reporter compact` (raw: `docs/evidence/logs/baseline_test.txt`) |
| New failures caused by this wave so far | 0 | No source edited |
| Coverage | **not measured** — no coverage config in this app | `flutter test --coverage` would write to `coverage/lcov.info`; not part of the current gate |
| Build status | **not measured** — Phase 0 is read-only | build is exercised at Phase 6 (`flutter build web` if the app supports it) |
| Bundle size | **not measured** — no build artifact | same |
| Golden files committed | 16 (`test/goldens/f2a_*.png`) | 14 fail pre-wave, 2 login goldens pass |
| Capture tests | write PNG/JSON, assert nothing | `test/f2a_screenshots_test.dart`, `test/f2a_fidelity_capture_test.dart` |

## Scope-local status (sign-in)

| Check | Baseline |
|---|---|
| `test/widget_test.dart` sign-in tests (5) | **PASS** |
| `test/o2_copy_fit_test.dart` login footer copy EN + AR | **PASS** |
| `test/f2a_goldens_test.dart` login golden EN + AR | **PASS** |
| `test/f2a_screens_test.dart` `login` at 360/390/600/900 × 1x/1.5x/2x + reduce motion | **PASS** |
| `test/f2a_screenshots_test.dart` login capture (writes PNG) | **PASS** |
| `test/f2a_fidelity_capture_test.dart` login capture (writes PNG/JSON) | **PASS** |

## Test-suite caveat

**CI is red before this wave starts.** `.github/workflows/ci.yml` runs
`flutter test` in this app with no allowlist gate (only the workshop admin app
has `tool/baseline_check.dart`), so the 19 pre-existing failures fail the
`Technician widget tests` job today. This wave must not add to them; the
allowlist is the review contract at Gate 6.

The 19 failures are pre-existing and allowlisted in
`docs/baseline_allowlist.md`. They come from unrelated surfaces (14 goldens,
one a11y case, one date-format case, one empty-state geometry case) and from a
shared-ARB placeholder drift introduced by the concurrent workshop-admin wave
(two `i18n_source_scan_test` cases). None of them is a sign-in behaviour.

Two concurrent waves are editing this working tree (workshop admin rebuild and
this technician sign-in rebuild). The shared ARB and generated l10n files are
already modified (`git status`), which is why the placeholder scan is red
before this wave starts.
