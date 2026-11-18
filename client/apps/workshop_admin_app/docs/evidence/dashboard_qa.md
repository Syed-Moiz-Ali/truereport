# Dashboard rebuild — proof sheet (Gate 6, round 2)

Screen: `lib/src/features/dashboard/dashboard_tab.dart` (direction B "The floor")
Spec: `docs/ui_brief.md` · Language: `docs/visual_language_dashboard.md`
Date: 2026-11-18 · Flutter 3.47.9

## Commands (raw logs kept)

```
docs/evidence/logs/analyze.txt   flutter analyze --fatal-infos --no-pub
                                 No issues found!
docs/evidence/logs/test.txt      flutter test --no-pub
                                 00:55 +534: All tests passed!
```

`dart run tool/baseline_check.dart` → `tests green · format 0 new · analyzer
clean · baseline_check: OK`.

Baseline before this wave: 480 tests. After: **534** (dashboard suites grew from
28 to 73; every old behaviour case is rewritten or stronger, none deleted).

## Files

```
dashboard_tab.dart                 364 lines  (was 760; every private widget deleted)
dashboard_style.dart               scale table + status tints + status order
widgets/dashboard_hero.dart        eyebrow, numeral, decision sentence, CTA
widgets/dashboard_atlas.dart       bar + legend + phone spine + remainder
widgets/dashboard_groups.dart      three groups, loading/error/empty
widgets/dashboard_rows.dart        group header, job row, row verb, empty line
widgets/dashboard_states.dart      hero skeleton, atlas skeleton, rows skeleton, error line
```

## Round-1 findings and what changed

| Finding (independent review) | Fix |
|---|---|
| **Legend was a positional ruler that lied**: nine labels in a fixed grid under a proportional bar, so "Pending review" sat under the in-progress block | Legend is now a **content-sized wrap** — swatch + count + label per status, no positional claim. Amended in `visual_language_dashboard.md` §1 ("the legend repeats exactly the counts inside the bar"). |
| 2× text broke labels mid-word (`Schedul/ed`, `Approv/ed`) | Same fix: each legend item has bounded width (150) and wraps on spaces. Verified in `scale200_390`, `scale200_1280`. |
| Primary action at 390 was 42 px and not full width | `WorkshopButton(expand: compact)` — full width at <600, 46 px tall. `scale200_390`. |
| Arabic mixed numbering systems (Latin counts, Arabic-Indic dates) | `pinDashboardDigits()` applies one convention to the page: Latin digits for every number it prints. |
| Arabic singular label was "مهمة في الورشة" | `dashFloorLabelOne` → **"مهمة واحدة في الورشة"**; regenerated l10n. |
| Missing page states in evidence | Added `loading_1280`, `both_error_1280`, `groups_empty_1280`, `no_session_1280`, `scale150_1280`, `ready_768`, `ready_360`. |
| Proof sheet said 430 lines for a 364-line file | Corrected here; the raw logs are committed. |

## Acceptance checklist (docs/ui_brief.md §10)

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Rewritten screen, region files, kill list | PASS | file table above; source-scan test |
| 2 | Different structure at 1440/1024/390 | PASS | `dashboard_compare.html` (+768/360/AR) |
| 3 | Nine segments + total; remainder as "Other" | PASS | `ready_1280`, `remainder_1280`; legend no longer claims a position |
| 4 | Counts failure shows no numbers | PASS | `counts_error_1280`, `both_error_1280`; invariants |
| 5 | One primary action; full width on phone | PASS | `dashboard_390`, `scale200_390` |
| 6 | Row opens the job; verbs only for their statuses | **awaiting countersign** | W-ROWOPEN (proposed) — see below |
| 7 | No legacy symbols | PASS | invariants source-scan (word-boundary regex) |
| 8 | Widths + AR + scales + no overflow | PASS | `ready_{1440,1024,768,390,360}`, `ready_1280_ar`, `scale150_390/1280`, `scale200_390/1280`; 36-case matrix |
| 9 | format / analyze / test clean; no test removed | PASS | `docs/evidence/logs/` |
| 10 | ARB keys both locales; no Latin in AR body copy | PASS | `dashboard_localization_test`; singular fixed |

## States captured (`docs/evidence/dashboard_states/`)

ready_1280 · ready_768 · ready_360 · empty_1280 · loading_1280 ·
counts_error_1280 · both_error_1280 · group_error_1280 · groups_empty_1280 ·
no_session_1280 · remainder_1280 · ready_1280_ar · scale150_390 · scale200_390 ·
scale150_1280 · scale200_1280 — 16 files.

## Open decision at this gate

`W-ROWOPEN`: a row opens `JobDetailPage` instead of the legacy quick sheet — **countersigned by the product owner on 2026-11-18**, recorded in `docs/waivers.md`. The sheet accepts only `WorkshopJob` from `inspection_jobs`, which J19 excludes; the detail page carries the same actions.

## Round-2 follow-ups (non-blocking, fixed after the review)

1. **Arabic row meta** — the date split around the reference (`…2026/11/JOB-10485`). Cause: `DateFormat('ar')` inserts RLM/LRM controls, and an RTL paragraph reorders the neutral-separated runs. Fix: `pinDashboardDigits()` now strips bidi controls, and `DashboardJobRow` renders the meta line with an explicit LTR base. Verified in `ready_1280_ar.png`.
2. **Empty group vs count** — a group could print "4 pending review" above "Nothing here right now" (counts are workshop-wide, the list is filtered). Fix: a group with no rows drops its meta. Covered by an invariants test.
3. Docs updated where they still described the deleted positional legend, the loading atlas and the multi-error state.
