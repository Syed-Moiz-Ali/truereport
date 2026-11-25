# Brief 1 — technician jobs module: kill list + safety net (no UI)

Phase: 2 (W1). Owner: engineering. **This brief changes no pixels.**

## Goal

Make the module safe to rebuild: remove the dead job screens that duplicate it, and put a real test
harness under the five invariants, so Wave 2 cannot silently break behavior.

## A. Kill list (verified zero import sites in `lib/`)

Delete these files, then remove any now-empty directories and unused imports:

```
lib/src/features/inspection/inspection_hub_view.dart          859
lib/src/features/jobs/job_intake_view.dart                   1154
lib/src/features/jobs/consent_view.dart                       697
lib/src/features/jobs/equipment_view.dart                     440
lib/src/features/jobs/empty_jobs_view.dart                    827
lib/src/features/jobs/assigned_jobs_view.dart                1376
lib/src/features/review/final_review_view.dart
lib/src/features/review/finalize_view.dart
lib/src/features/review/success_view.dart
lib/src/features/sync/offline_sync_view.dart
lib/src/features/inspection/tire_condition_view.dart
lib/src/features/inspection/dense_mechanical_view.dart
lib/src/features/inspection/defect_detail_view.dart
lib/src/features/inspection/exterior_wireframe_view.dart
lib/src/features/inspection/photo_annotation_view.dart
```

Rules: re-verify each has no import site before deleting; if one is referenced, stop and report instead
of deleting. Do not delete `photo_markup_page.dart` (live via `assessment_screen.dart:1577`).

## B. Test harness

1. `test/flutter_test_config.dart` with a real-font `FontLoader` for Plus Jakarta Sans (assets ship in
   `design_system`). Ahem glyphs are not evidence.
2. `test/support/fixtures.dart` — `JobSummary` / `Checklist` builders with the real field set
   (`inspection_models.dart`).
3. Characterization tests (they pin current behavior; they must pass before any UI change):
   - `queueDayKey` / `groupQueueJobs`: today / upcoming / past buckets, undated jobs.
   - `queueDayLabel`: the weekday printed for a known date equals the rail's weekday.
   - `queueSlotLabel`: scheduled time wins; started time is the fallback.
   - `queueVehicleLabel`: plate fallback when make/model are missing.
   - `technicianCanComplete`: false with blockers, conflicts, zero items.
   - reference label fallback: `IN_PROGRESS` → "In progress" when taxonomy is unavailable.
4. CI: add `flutter test` to the Flutter job after `flutter analyze`.

## C. Two correctness fixes that are not visual

1. **Day bucket vs label disagree.** `queueMoment` buckets by `startedAt ?? scheduledAt`, while
   `queueSlotLabel` prints `scheduledAt`. One rule: bucket by the same moment that is printed.
2. **Receipt status is a constant.** `technician_completed_page.dart:88-91` hard-codes `PENDING_REVIEW`
   instead of `job.status`.

## Out of scope

Any layout, color, type or copy change. Any change to the photo gate, signature, completion or sync
state machines.

## Acceptance

- `flutter analyze` → 0 issues.
- `flutter test` → all pass, output pasted.
- `node tools/gate_all.js` → same 9 pre-existing literals, no new ones.
- `git diff --stat` shows deletions, tests and the two fixes only.
