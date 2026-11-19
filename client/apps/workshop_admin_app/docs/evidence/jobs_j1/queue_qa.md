# Queue J1b — visual QA report

Date: 2026-11-19 · Screen: job queue + legacy archive · Direction A "the counter"

## Verdict

**PASS WITH FIXES.** The queue is a rebuilt screen, not a restyle: new region
files, a server-counted status strip, a fixed inspector, a counted footer, phone
cards and a quarantined archive. Two first-round issues were fixed before this
verdict: the loading skeleton overflowed the short wide body by 68 px
(`workshop_real_font_screenshot_test`), and the empty/filtered states rendered
as full-height slabs with a contradictory `0–0 of 0` footer.

## Gates

| Gate | Result |
|---|---|
| `dart format` on owned files | 0 changed |
| `flutter analyze --fatal-infos` | **0 issues** |
| `flutter test` | **588 passed / 0 failed** |
| Legacy source scan | `features/jobs/**` outside `archive/` clean (comments stripped; `l10n.cancelJob` is a label, not the removed method) |
| Legacy count/mutation members | `jobCounts`, `createJob`, `assignJob`, `cancelJob`, `jobCountsProvider`, `JobCounts`, legacy endpoints removed |
| Default Material smell | no `Card(`/`DataTable(`/`Chip(`/`AppBar(` in the new queue or archive |

## Evidence (real fonts)

`docs/evidence/jobs_j1/`

- `queue_1440.png`, `queue_1280.png`, `queue_1024.png`, `queue_768.png`,
  `queue_390.png`, `queue_360.png`
- `queue_1280_ar.png`
- `queue_loading_1280.png`, `queue_error_1280.png`, `queue_empty_1280.png`,
  `queue_filtered_empty_1280.png`
- `archive_1280.png`

## Checklist

| # | Check | Result |
|---|---|---|
| 1 | One focal point (sheet + selected row) | PASS |
| 2 | Squint test: header / totals / sheet / footer read in order | PASS |
| 3 | One primary action per region (New job; inspector next action) | PASS |
| 4 | Counts are tabular and server-sourced; "Workshop totals" label | PASS |
| 5 | No horizontal scroll/clipping at 360–1440; no overflow to 2.0× | PASS |
| 6 | Empty/error states bounded, not full-page slabs | PASS (fixed) |
| 7 | No card-in-card; sheet is one bordered surface with hairlines | PASS |
| 8 | Selected row = 3 px accent bar + tint | PASS |
| 9 | No duplicated workshop/brand title | PASS |
| 10 | Dates humanized; no raw ISO | PASS |
| 11 | Identifiers LTR and never ellipsized (reference/plate/phone) | PASS |
| 12 | Counts vs list total never conflated (strip 20, list 12) | PASS |
| 13 | Status is dot + label, max three tones per view | PASS |
| 14 | Buttons 44–46 px; destructive cancel separated in overflow | PASS |
| 15 | Loading skeleton matches the six columns; no spinner page | PASS |
| 16 | Counts error: labels only + one retry; sheet still renders | PASS |
| 17 | Filtered empty: "No jobs in this view" + Clear filters | PASS |
| 18 | Phone card footer carries the same policy action | PASS |
| 19 | Archive: banner, read-only, no create/assign/cancel/report/publish | PASS |
| 20 | RTL mirrors columns, chevrons and footer; Arabic copy renders | PASS |

## Fixed since round 1

1. **Number system (round 2).** Every scheduled date in the table, phone card
   and inspector is now `pinDigits(formatInstant(...))` in an explicit LTR
   direction, so Arabic shows `1/11/2026 10:00` and never mixed Arabic-Indic
   digits or reordered `10:00 2026/11/`. The footer range uses `ltrRange`, so
   Arabic reads `عرض 1–10 من 12`, never `10–1`; the total is pinned too. Status
   counts were already ASCII. The archive date uses the same helper.
2. **Mobile status strip (round 2).** Below 680 px the 11 segments are one
   horizontal scrolling row (44 px high, key `jobs-status-row`); at ≥680 the
   Wrap is unchanged. The first job is back above the fold at 360/390.
3. Loading skeleton (6×56 rows) now scrolls inside the sheet; no 68 px/21 px
   overflow on the short wide body in the real shell.
4. Empty and filtered-empty states are bounded (560×360) instead of filling the
   body; the error state is a bounded card.
5. Footer is hidden when the view total is 0, so "Showing 0–0 of 0" can never
   sit under a strip that says the workshop has 20 jobs.
6. Wide inspector pins its action footer; the primary action is visible without
   scrolling the inspector.
7. Loading/empty screenshot fixtures now use coherent counts (0 when empty).

## Added tests (round 2)

- Arabic queue: scheduled `1/11/2026 09:00`, range `1–10`, counts `(36)` all
  Latin; no Arabic-Indic digit remains (`jobs_queue_test.dart`).
- The Arabic capture test asserts `1/11/2026 10:00`, `1–10`, and no
  Arabic-Indic digits before writing `queue_1280_ar.png`.
- Arabic phone card: the card date is Latin and contiguous.
- Phone status strip: height ≤ 56 px and the last filter is reachable by a
  horizontal drag, then selects `CANCELLED`.

## Remaining risks

- At 680–1099 the full-width inspector is tall by design; it pushes the sheet
  below the fold after a selection. The user is in an act-on-one-job flow there.
- On a phone the status strip is one horizontal row; statuses after the third
  are reached by scrolling. This is intentional and keeps the first job above
  the fold.
- `inspection_jobs` rows remain reachable only through the archive until CR-3
  backfills them; that is a data-migration risk, not a client fix.
