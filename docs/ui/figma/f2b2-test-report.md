# F2-B.2 test report (6 November 2026)

Light-only, EN+AR. No commit.

## Step 0 (pre-fix baseline)

| Suite | Result |
|---|---|
| Client total | 311 pass / 65 fail / 376 total |
| `design_system` | 88 pass / 40 fail (incl. 40 dark-theme stale) |
| auth | 0 tests |
| technician | 128 pass / 22 fail |
| admin | 90 pass / 3 fail (`source_scan`) |
| gallery | 5 pass / 0 fail |
| `tokens generate --check` | pass |
| `print-tokens --check` | pass |
| Web builds (both) | success |
| APK | success |
| Server `mvn test` | 89 run / 0 fail / 3 skipped-conditional (S3 endpoint, PDF-sample property, POSIX assumption); Docker Testcontainers ran (MySqlImmutability / MySqlMigration / MySqlPiiMigration pass) |

## Post-fix targeted results

| Suite | Result |
|---|---|
| `design_system` (dark tests removed) | 52/52 pass |
| Fidelity harness | 2/2 pass |
| `source_scan` (F2b tokenized) | 6/7 pass (only pre-existing `inspection_hub_view` 2 spacing lines left, F2-A scope) |
| `f2b_battery` | 48/48 (geometry 6/6, screens 33/33, a11y 6/6, i18n 3/3) |
| New `test/f2b_a11y_test.dart` | 6/6 pass |
| `flutter analyze --fatal-infos` | clean |
| Server targeted (earlier) | inventory 4/4; arch+hierarchy+tech 22/22; parity+contract 14/14; hierarchy+tenancy 20/20 |

## Left failing / not re-run (open, needs owner)

- `f2a_goldens` 14 (copy-churn re-baseline; do NOT `--update-goldens` without approval).
- `inspection_ui` 3 (F2-A scope).
- `source_scan` 2 spacing lines on `inspection_hub` (pre-existing F2-A `_M` pattern).
- Full client suite not re-run after fixes (only targeted batteries).
- Full `mvn` not re-run.
- Web/APK post-fix not run (ran pre-fix; client-only changes since).
- `f2b` golden-ready tests: 12/12 paths pass, no `matchesGoldenFile` assertions;
  reference renders are the 12 fidelity `render.png` artifacts under
  `docs/ui/figma/fidelity/f2b/`.

## Fidelity SSIM (refreshed)

| Screen | figma-text | product-copy |
|---|---|---|
| defect | 0.83818 | 0.82509 |
| dense | 0.86017 | 0.82944 |
| review | 0.76743 | 0.78379 |
| finalize | 0.76102 | 0.74529 |
| sync | 0.80480 | 0.81609 |
| success | 0.86278 | 0.86443 |

Strings 12/12, keyboxes 12/12, forbidden 11/12 (Queued exception). Gate 0.98 NOT
met on any screen. Tokenization deltas: −0.0015 to −0.0039 paint-level.

## Could not verify

Real devices, native Arabic review, Docker-gated beyond what ran, full suites
post-fix, web/APK post-fix, measured shadow exactness.
