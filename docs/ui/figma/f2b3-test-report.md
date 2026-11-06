# F2-B.3 test report (6 November 2026)

Light-only, EN+AR. No commit. Stop at gate; no F3/F4/F5.

## 1. Baseline (before fixes, this session)

| Suite | Result |
|---|---|
| Client total | 355 pass / 16 fail / 371 total |
| `design_system` | 88 pass / 0 fail (no dark-only tests found; N4 nothing to remove) |
| auth (`client/packages/auth` has no `test/` dir) | 0 tests |
| technician_app | 154 pass / 15 fail / 169 total (`f2a_goldens` 14 copy-churn, `inspection_ui` 1 review-2.0x overflow) |
| admin_app | 92 pass / 1 fail / 93 total (`source_scan` 2 spacing lines in `inspection_hub_view`) |
| ui_gallery | 5 pass / 0 fail |
| Server `mvn -DskipITs=false test` | 89 run / 0 fail / 3 skipped-conditional (POSIX assumption, PDF-sample property, S3 endpoint); Docker Testcontainers ran (MySqlImmutability / MySqlMigration / MySqlPiiMigration pass) |
| `tokens generate --check` | initially FAIL (stale `contrast-after.md`: a hand-added F2-B.2 note line made the generated file mismatch); fixed by emitting the note from `contrast.mjs` — see §3 |
| `print-tokens --check` | pass |
| Web builds (both), debug APK | verified after fixes — see §2 |

F2-B.2 reported 311 pass / 65 fail; the committed tree at session start
already contained the F2-B.2 dark-test removals, so the live baseline is
355 pass / 16 fail as above.

## 2. Fixes (this session)

- **N4 (dark-only tests):** searched `design_system`, technician, admin,
  gallery tests for dark-only tests — none exist (dark legs were removed
  in the committed tree; `inspection_ui` brightness matrix tests both
  themes together and passes). Nothing removed; recorded in
  `decisions.md` (N4).
- **Spacing tokenisation (no visual change):**
  `inspection_hub_view.dart:290` `_M.g12` → `context.spacing.md` (12),
  `:329` `_M.g8` → `context.spacing.sm` (8). Same doubles; F2-A.1
  geometry still 7/7.
- **Review 2.0x overflow (real):** `finalize_view.dart:63` header pill row
  overflowed 105 px right at phone 360 EN 2.0x. First fix attempt (subagent)
  clamped text scaling to 1.3x on the review route; the lead replaced it
  with the structural fix — the unflexed `F2bStatusPill` is now wrapped in
  `Flexible` (pill already ellipsizes internally). Full 1.0x–2.0x scaling
  preserved, no 1.0x geometry change. No new strings; light-only respected.
- **N3 re-baseline:** `flutter test --update-goldens
  test/f2a_goldens_test.dart` after a visual check of all 7 EN renders
  (+ login/inspection-hub AR) against the Figma exports. Diffs were
  intentional C0 copy churn (Figma marketing copy → product `l10n`, tofu →
  real Arabic, locale number/time formatting, `notAvailable` fallback);
  no layout/theme/navigation regression. Recorded in
  `docs/ui/figma/golden-rebaseline.md` with residuals R1–R4 (login
  `Contact Admin` truncation, fixture `Not available` pills, empty-state
  header clip, count/helper ellipsis — all pre-existing patterns).
- **Lint gate:** Part 2 fixture files introduced 173 analyzer issues
  (165 `prefer_const_constructors` infos, 8 unused warnings), all
  test-only. Fixed with `dart fix --apply` (226 fixes) + manual removal
  of 7 unused declarations. All six Level 1 SSIMs reproduce bit-identically
  after the fix.

## 3. Final verification (after the last change, in order)

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos` (client) | clean — `No issues found!` |
| `design_system` full | 88/88 pass |
| auth | 0 tests (no `test/` dir) |
| technician_app full (incl. 6 new `f2b3_capture_*` tests) | **175/175 pass** |
| admin_app full | 93/93 pass |
| ui_gallery full | 5/5 pass |
| Client total | **361 pass / 0 fail / 361 total** |
| Server `mvn -DskipITs=false test` (full, Docker) | **89 run / 0 fail / 3 skipped-conditional; BUILD SUCCESS** |
| `tokens generate --check` | pass (`design tokens are up to date`) |
| `print-tokens --check` | pass |
| Web build technician_app | success (`build\web`, 101.4 s) |
| Web build admin_app | success (`build\web`, 79.9 s) |
| Debug APK technician_app | success (`app-debug.apk`, ~237 MB) |

Note on builds: web/APK were built after all `lib/` changes (spacing,
Flexible fix) and before the test-only Part 2 additions. Test-only files
under `test/` are not compiled into release builds; `analyze`,
token checks and the full suites above all ran after the last change.

## 4. Left open (not failures — recorded residuals)

- Level 1 gate on screen 09: 0.97362 < 0.98 (quantified rasterisation +
  pipeline residual; see `f2b3-report.md`). All other gates green.
- `test/failures/*.png` in the working tree are stale outputs of the
  pre-baseline failing golden run, not sources of truth.

## 5. Could not verify

Real devices; native Arabic review; Docker-gated beyond what ran;
measured shadow exactness beyond SSIM; Figma text shaping beyond rendered
SSIM; fresh-capture determinism (compare step proven deterministic by
repeated identical re-runs).
