# Jobs — design exploration (module scope)

Reference screen: **the queue** (`features/jobs/jobs_tab.dart` today). Siblings
(detail, board, wizard) inherit its anatomy. Foundation (shell C + "bay window"
language) is frozen and is **not** re-opened here.

## 3a. Thinking protocol

### The job

*Within ten seconds, find the job that needs me next and start the action without
leaving the queue.*

The queue is a work surface, not a catalogue. Its primary user is a workshop
manager at a desk, with a phone for the floor.

### What today's queue gets wrong

1. **It is a flat table with no priority.** Every row has the same weight; the
   only ordering is server default. "Ready to finalize" (the money step) sits
   between "in progress" rows.
2. **Its numbers are scoped to the search box, not the workshop** (J3/J5). Four
   chips repeat a count under a label the dashboard already uses for a different
   population.
3. **It leads to the wrong object.** A row opens the legacy quick sheet (J16)
   while every other surface opens the clean detail page.
4. **Its primary action is inert.** "New job" creates a job in `platform_jobs`
   that this queue — reading `inspection_jobs` — will never show (T4).
5. **The row says what, never what next.** Reference/vehicle/status; no age, no
   owner, no next action.
6. **The table has no lane or group.** Status is a chip you filter by, so the
   screen can only show one state at a time; the composition cannot answer
   "what is stuck?".

### Three constraints that bind

- **One object, one vocabulary:** `CleanJob` (+ `CleanJobCounts`), one status
  policy from `job_presentation.dart`; no legacy `WorkshopJob` on this screen.
- **Frozen chrome:** 44 px identity strip + floating dock with ~84 px bottom
  reserve; page gutters 32/24/16; content max width 1200.
- **Frozen language:** hairline borders, one accent, no shadows; light only;
  RTL parity; every element traceable to a VERIFIED field (no invented badge,
  no invented "SLA" number unless the field exists).

### Axes (colour is not one)

| Axis | A | B | C |
|---|---|---|---|
| Layout logic | dense sortable table | spatial lanes by lifecycle | triage split (list + persistent selection) |
| Grouping | status as sticky row bands | status as columns | status as sort, not structure |
| Action surface | row + end inspector | card footer + detail page | inline primary action + summary rail |
| Selection | row selects, inspector slides | card opens page | selection is the screen's state |
| Motion verb | inspector slides in | lane scroll / feed advance | summary pane swaps |
| Mobile (<680) | cards with footer action | segmented lane tabs + feed | one-card feed with bottom action |

Colour, radius, type and spacing come from the frozen tokens; they are not
directions.

## 3b. Required per direction

Name + one-sentence signature idea · ASCII wireframe at 1440 and 390 · structural
departure list vs today · rendered widget **inside the real frozen shell** with
6–8 real rows and a real detail panel (never an empty frame) · screenshot at 1440
and 390 EN + 1440 AR · the trade-off it accepts.

Data for previews: `docs/data/samples/clean-jobs-page.json` and
`clean-job-counts.json` shapes; statuses from `job_presentation.dart`; no invented
fields.

## 3c. Evidence paths

```
lib/preview/jobs/direction_<a|b|c>.dart      (design proof only, production never imports it)
test/jobs_direction_<a|b|c>_capture_test.dart
docs/concepts/jobs/<a|b|c>/wireframe.md
docs/evidence/jobs_directions/{a,b,c}-queue-1440.png
docs/evidence/jobs_directions/{a,b,c}-queue-390.png
docs/evidence/jobs_directions/<chosen>-queue-1440-ar.png
```
