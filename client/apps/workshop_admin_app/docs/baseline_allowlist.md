# Baseline allowlist — dashboard LITE rebuild

Rule for this rebuild: **new failures only**. Everything listed below is the
state before the first design edit. Anything not listed that goes red is a stop.

Measured 2026-11-18 on `ui-reset-polish`, Flutter 3.47.9 / Dart 3.13.7, Windows.
Reproduce from `client/apps/workshop_admin_app`.

## Current state — nothing is red

```
$ flutter analyze --no-pub
No issues found! (ran in 4.6s)

$ flutter test --no-pub
00:59 +480: All tests passed!

$ flutter test --no-pub --coverage
480 pass; dashboard_tab.dart 93.4 %, admin_api.dart 6.3 %,
workshop_job_models.dart 53.2 %
```

## Repaired before measuring (see `docs/audit-dashboard.md` §R)

The previous Wave-2 attempt left the tree **unbuildable** — `flutter analyze`
reported 60 issues (46 errors) because a phase-C revert deleted
`lib/src/job_counts.dart` and `lib/src/features/jobs/schedule_job_sheet.dart` and
the legacy `jobs()`/`jobCounts()` API while four files still referenced them.
Restored additively from `HEAD`:

```
git checkout HEAD -- \
  lib/src/job_counts.dart \
  lib/src/features/jobs/schedule_job_sheet.dart \
  lib/src/admin_api.dart \
  lib/src/admin_providers.dart
```

Nothing was redesigned to produce the numbers above. This is the baseline.

## Allowed behaviours that look like failures

| ID | Behaviour | Why it is allowed | Remove when |
|---|---|---|---|
| B1 | `test/workshop_real_font_screenshot_test.dart` rewrites 77 PNGs on every `flutter test` run | Pre-existing harness design: it recaptures evidence, it does not assert pixels | the suite moves to golden assertions (proposed waiver W-SCREENSHOTS) |
| B2 | 19 unformatted files listed in `baseline_allowlist.json` | Never gated before this rebuild; reformatting them is a separate mechanical change | a later brief formats the whole tree |
| B3 | `IndexedStack` mounts all six tabs at once | Existing shell contract (J15); the shell is out of scope and write-locked | the shell is rebuilt |
| B4 | `job_counts.dart` / `schedule_job_sheet.dart` / legacy `jobs()` exist again | Restored to make the tree compile; the rebuilt dashboard will **not** use them, the jobs queue still does until its own wave | the jobs queue wave deletes them |
| B5 | `dashboard_test.dart` pins widget types (`WorkshopMetricStrip`, a 4-segment 8 px bar) | Pre-existing structural test; a rebuild must replace these assertions with new-composition ones, keeping every behavioural assertion | the build wave replaces the structural half (see audit §5) |

## Change-detection rule for this rebuild

A run fails on:

- any new analyzer issue (`--fatal-infos`);
- any new test failure;
- any **deleted or weakened** test (a structural assertion may be rewritten
  against the new composition; it may not be dropped);
- any new `RenderFlex overflowed` at 1440 → 360;
- any allowlist entry that starts passing (stale entry);
- any screenshot PNG changed without a matching note in `docs/`;
- any legacy (`jobs()` / `jobCounts()` / `JobCounts` / `WorkshopJob`) reference
  added to the rebuilt dashboard.

## Scope note

Sign-in (Wave 1) is complete and independently passed — 10/10 acceptance items.
Its invariants stay pinned by `test/signin_*`. The jobs queue, board and detail
are **not** in this wave; their Wave-2 state is frozen at the repaired baseline.
