# Brief 2 — technician jobs reference slice (direction A)

Phase: 3 (W2). Screens: `/jobs` (queue) and `/jobs/:id` (job detail). Visual language unchanged —
the size, colour and type tokens stay; the **structure** changes.

## The one idea

The queue answers "what do I do next" in the first 120 px, and every row carries its own verb.
The calendar stops being the screen and becomes a filter.

## `/jobs` — queue

Phone (390):
- Header: `Jobs` + one status line: `{toStart} to start · {inProgress} in progress` + avatar.
- **Now card** (only when a job is `IN_PROGRESS`, else the next due job): time, vehicle, plate,
  `{done}/{total} items`, primary `Continue · item {n}` or `Start`.
- Sections, in this order: `TODAY`, `UPCOMING`, `UNFINISHED` (any assigned job dated before today),
  `DONE TODAY` (collapsed, completed/review).
- Row (min 78 px, whole row tappable): time · vehicle (1 line, ellipsis) · plate on the meta line ·
  state-derived verb on the right (`Start`, `Continue`, `Finish`, `View`) · `{done}/{total}`.
  Cancelled jobs are hidden by default; the filter shows `Cancelled · n` so they are not lost.
- Filter sheet replaces the day rail: `Today / Tomorrow / All dates / Pick date`, plus status.
  The current selection is visible as one chip under the header, never as a 7-cell rail.

Tablet (≥1024): queue pane 380 px + selected job detail pane; selecting a row must not navigate away.

Empty / error / loading:
- empty-day: "Nothing scheduled for {date}" + the nearest day that has work as a button.
- empty-all: "No jobs assigned to you" (no filter hint when no filter is active).
- `UNFINISHED` must be reachable from the empty state ("1 job from 23 Nov is unfinished").

## `/jobs/:id` — job detail

Header block (phone, 3 lines max):
1. vehicle + plate (plate as a pill), back, photo thumb.
2. state line: status label · `{scheduled time}` · `{done} of {total} items` · offline/sync chip when
   pending (`n waiting to sync`).
3. customer · reference (one line, small).

Categories: replace the clipped rail with a wrapping chip set that always shows every section and its
`{done}/{total}`; the selected chip is the only filled one. No horizontal scroll at 390.

Item rows: number, label (allow 2 lines at 390 so safety-critical items are not the only ones that fit),
one state chip (`Not checked`, `Pass`, `Attention`, `Fail`) toned, safety pill inline. No chevron noise
if the whole row is tappable.

Footer: one primary action whose label is derived — `Continue · {next item}`, `Check {next item}`, or
`Finish job` when every item is assessed; secondary `Summary`. Delete the duplicate summary card at the
end of the ledger (one entry point, not two).

Tablet: 720 → 900 px content, two-column item grid (2 × 340) once width ≥ 900, sections as a left rail
≥ 1024.

## Copy rules

- One noun for the object: **job**. One for the work inside: **items**. Never "inspection queue",
  "on the board", "checklist", "hub" for the same things.
- No `{done}/{total}` without a unit in the same line ("12 of 30 items").
- A status never appears twice in the same view.
- "All caught up" is only allowed when **every section** is complete, and it must say what happens
  next ("Ready for summary").

## States that must exist on both screens

loading (skeleton), empty (3 variants above), error (retry), offline banner, per-job sync pending,
partially complete, completed/read-only (no editable footer, no Start, item rows non-interactive).

## Preserved behaviors (do not change)

Photo gate ordering and its error fallback; item route deep links (URI-encoded); `pushReplacement`
item→next so one back returns to the ledger; summary → signature → completed; offline queue and
"saved on this phone"; RTL mirroring.

## Implementation map (one owner per file)

| Owner | Files | Notes |
|---|---|---|
| Main | `technician_router.dart`, `technician_workspace_page.dart` | point `/jobs` at the new page; pass `job.status`/sync info into the deck; keep the photo gate order |
| List unit | **new** `features/jobs/queue/jobs_queue_page.dart`, `widgets/now_card.dart`, `widgets/queue_section.dart`, `widgets/job_row.dart`, `widgets/queue_filter_sheet.dart`, `widgets/job_preview_pane.dart`, `queue_model.dart` | `queue_model.dart` is pure Dart (grouping + verb + plate) so it is unit-testable; delete `technician_jobs_clean_page.dart` when the route moves |
| Detail unit | **rewrite** `features/inspection/inspection_deck.dart`; **new** `features/inspection/deck/deck_header.dart`, `deck/deck_sections.dart`, `deck/deck_ledger.dart`, `deck/deck_footer.dart` | keep the ledger's per-item state model and the tap-anywhere row; change header, category selector, footer logic, row wrapping |

Shared tokens stay in `features/jobs/queue/jobs_queue_style.dart` (main owns edits to it).
No unit writes another unit's file; both may import `queue_model.dart`.

Tablet rule for the slice: ≥1024 the queue shows a second pane with the selected job's summary and an
`Open job` action; the pane never embeds the deck (that is what `Open job` is for).

## Acceptance (Gate 6, reference slice)

- Screenshots at 390 / 768 / 1024, EN, plus 390 AR.
- Zero new `RenderFlex overflowed`; both screens scroll with 1.5× text scale.
- Executed: `flutter test` (harness from Brief 1) + the CRUD/flow walk list → open → continue →
  save → back → progress updated.
- Kill list from Brief 1 applied; no dead job screen remains.
