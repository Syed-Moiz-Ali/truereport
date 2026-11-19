# Jobs queue — direction A, "The sheet"

Design proof for the jobs reference screen. Frozen foundation: shell C ("the
dock"), the bay-window visual language, light only. Colour is not an axis here.

**Signature idea:** the queue is one dense sheet you sort, and the row you touch
opens a fixed 380 px inspector at the end edge whose footer carries the single
next action for that job's status — so the decision happens without leaving the
queue.

Evidence: `docs/evidence/jobs_directions/a-queue-1440.png`,
`a-queue-390.png`, `a-queue-1440-ar.png`. Preview: `lib/preview/jobs/direction_a.dart`
(never imported by production). Capture: `test/jobs_direction_a_capture_test.dart`.

---

## 1. Wireframe — 1440 x 900

```
┌ 44 px identity strip ─────────────────────────────────────────────────────┐
│ [TR] TrueReport │ Marina Workshop            [العربية] [bell] [LH]        │
├───────────────────────────────────────────────────────────────────────────┤
│ 32                                                                        │
│   Job queue                                          (page title 30/38)   │
│   Sorted by scheduled · ascending                    (meta, muted)        │
│                                                                           │
│   [ search reference, plate or VIN ] 320        [ + New job ] 46          │
│                                                                           │
│   [ Workshop totals │ All 24 │ Draft 0 │ Scheduled 2 │ Assigned 1 │        │
│     In progress 3 │ Pending review 4 │ Approved 2 │ Published 11 │         │
│     Rejected 1 │ Cancelled 0 ]           one line, 44 px, hugs its content │
│                                                                           │
│   ┌── THE SHEET  800 ────────────────────────────┐   ┌ INSPECTOR 380 ───┐ │
│   │ JOB        VEHICLE     CUSTOMER  TECH  STATUS  SCHEDULED↑│ JOB-…0107 │ │
│   │ ───────────────────────────────────────────────────────── │ 911 GT3   │ │
│   │ JOB-…0104  Land Cruiser Sara K.  Karim Approved Today 08:30│ 2023 · …  │ │
│   │  Full insp v2  DXB 55107                    │            │ [Pending] │ │
│   │ ───────────────────────────────────────────────────────── │ [Not pub] │ │
│   │ JOB-…0105  Patrol      Ahmed A.  Omar  Pending Today 09:00│ CUSTOMER  │ │
│   │ ───────────────────────────────────────────────────────── │ Rashid …  │ │
│   │▌JOB-…0107  911 GT3     Rashid   Karim  Pending Today 10:00│ +9715…    │ │
│   │  (selected: accent bar + tint)                            │ email     │ │
│   │ ───────────────────────────────────────────────────────── │ JOB       │ │
│   │ … 4 more rows, 56 px each, hairlines                     │ Tech/Sched│ │
│   │ ───────────────────────────────────────────────────────── │ Mile/Rev  │ │
│   │ 7 of 24 shown · sort applies to this page  Design proof    │ ✓ consent │ │
│   └──────────────────────────────────────────────────────────┘ ──────────│ │
│                                                              [Review &   │ │
│                                                               approve][Open]│
├───────────────────────────────────────────────────────────────────────────┤
│ 88 px dock reserve          [ ◦ ◦ ◦ ◦ ◦ ● Jobs ◦ ]                        │
└───────────────────────────────────────────────────────────────────────────┘
```

Column flexes (of 124): Job 28 · Vehicle 24 · Customer 18 · Technician 16 ·
Status 22 · Scheduled 16. Row min height 56, hairline dividers, header outside
the scroll (sticky by construction, not by pinning). Measured at 1440 x 900:
content column 1200, sheet 800, inspector 380, seven rows filling 392 px, sheet
ends 100 px above the dock reserve.

## 2. Wireframe — 390 x 844

```
┌ 44 px strip ──────────────────────────────┐
│ [TR] Marina Workshop [العربية][bell][LH]  │
├───────────────────────────────────────────┤
│ Job queue                          [ + ]  │  ← create collapses to 44 px icon
│ Sorted by scheduled · ascending            │
│ [ search reference, plate or VIN ]        │
│ [ Workshop │ All 24 │ Draft 0 │ Sched… ]  │  ← one line, scrolls, no wrap
│                                           │
│ ┌ card ─────────────────────────────────┐ │
│ │ Land Cruiser 300        [Approved]    │ │
│ │ DXB 55107                             │ │
│ │ # JOB-…0104  ⬤ Sara Khalifa           │ │
│ │ ◷ Today, 08:30  ⬤ Karim Ahmed         │ │
│ ├───────────────────────────────────────┤ │
│ │ [ ⚑ Publish checklist ]  46, full     │ │
│ └───────────────────────────────────────┘ │
│ ┌ card … Nissan Patrol [Pending review] ┐ │
│ │ …                                     │ │
│ │ [ Review & approve ]  ← decisive row  │ │
│ └───────────────────────────────────────┘ │
├───────────────────────────────────────────┤
│ 78 px reserve      [ ◦ ◦ ● Jobs ◦ ◦ ]     │
└───────────────────────────────────────────┘
```

## 3. Structural departures from today's queue

| Today | Direction A | Why |
|---|---|---|
| Flat table, server default order, no sort | Sortable header (six columns, real comparators), active column marked with an arrow | The job is "find the one that needs me next"; the manager must be able to order by schedule or status |
| Row opens the legacy quick sheet (a second vocabulary, a second assign path, no `version`) | Row *selects*; facts and the action live in the inspector, which is the clean job object | One object, one vocabulary; no navigation to a legacy surface |
| Status is a chip bar with search-scoped counts (four numbers that contradict the dashboard) | One-line segmented strip, all ten lanes, counts labelled **Workshop totals** (the server's `GET /jobs/counts`, search-independent) | Kills D2/J5/G-J19/G-J20: the number says what it counts |
| "New job" writes `inspection_jobs` and the row never appears here (T4) | "New job" is the clean wizard action | The queue and the create path agree |
| Status filter shows one state at a time, no composition | Same filter, but a status *column* plus page-scoped sorting lets the manager see mixed states and order them | The screen can answer "what is stuck" |
| No next action anywhere in the list | Every row has a status-derived next action in the inspector footer (and in the phone card footer) | The row says what next, not only what |
| One column vocabulary shared with the dashboard row | Job = reference + template version; Vehicle = model + plate; Scheduled = humanized day + tabular time | Denser, scannable, and each column has a single meaning |

## 4. Per-breakpoint behaviour

| Content width | Table | Selection | Create action |
|---|---|---|---|
| **≥ 1100** | Full-height sheet, header pinned outside the scroll, footer with counts | 380 px inspector at the end edge, full body height, identity + badges + customer + job facts + consent, primary action pinned in its footer | Toolbar, labelled button |
| **680 – 1099** | Same sheet, full width, shrinks to content inside the page scroll | Inspector becomes a **full-width region** above the sheet with the same blocks + close button | Toolbar, labelled button |
| **< 680** | Rows become cards: title + status, plate, two wrapped meta lines (reference + customer, scheduled + technician) | No inspector; the card footer is the row's next action; the selected card gets an accent border | Header icon button (44 px) with the same semantic label |

Other rules: the inspector always slides in from the **end** edge (`start` bar on
the selected row, `PositionedDirectional`), so RTL mirrors without extra code;
row and segment respond to hover and keyboard focus with the token focus ring;
all padding is directional.

## 5. States

- **Filtered-empty** (implemented): bounded empty state inside the content
  region — "No jobs match this search", one line telling you what the search
  covers (reference, make, model, VIN, plate), and a "Clear search" action that
  also clears the status lane.
- **Empty (first use)**: same bounded state with `WorkshopEmptyState`, copy
  "No jobs yet" + the single action "New job". Not reachable from static data;
  no separate code path is invented in the proof.
- **Loading**: two `WorkshopSkeleton(card: true)` blocks the height of the
  sheet + inspector, never a spinner page. Documented, not rendered.
- **Error**: `WorkshopErrorState` inside the sheet region with Retry, so the
  header, toolbar and filter strip stay usable. Documented, not rendered.
- **Partial data**: a row whose `assignedTechnicianName` is null prints
  "Unassigned"; a null phone/email prints "Not available"; a null odometer
  prints "Not available". No field is ever filled with a plausible value.
- **Consent missing**: when `consentGranted` is false the inspector's consent
  line turns warning-toned instead of claiming readiness (G-J1), and the phone
  card carries the same warning above its action. A publish that consent blocks
  is never filled with the accent, because it cannot win: on the phone exactly
  one card (the job waiting for a decision) carries a solid primary button.
- **Cancelled**: card footer shows "No action available" instead of a disabled
  primary button; the inspector keeps the status badge and offers "Open job".
- **Long text**: references and plates are LTR-pinned and never wrap; customer
  and technician wrap to two lines; only the template version ellipsizes.
- **RTL**: strip, columns, table order, inspector edge and dock mirror; Latin
  values (reference, plate, VIN, model, phone, email) are pinned LTR because the
  Arabic paragraph direction reordered `911 GT3` into `GT3 911` in the first
  capture — the same class of bug as the mirrored chassis, fixed and verified.
- **Text scale**: rows grow, `minHeight` is a floor not a cap; the inspector
  body scrolls inside its rail.

## 6. Trade-off

**Density beats completeness in the row.** Six columns at ~800 px forces the
row to carry only the model and the plate (the year, make, VIN, email and
mileage live in the inspector), and the template version ellipsizes on the two
longest names. In exchange the queue fits seven jobs without scrolling at 900 px
height and the next action is always one glance away. A manager who wants the
full identity selects the row — the inspector is free, it is not a navigation.

Second cost: the sheet's sort is **page-scoped** until the endpoint accepts a
`sort` parameter; the footer says so out loud rather than implying a workshop-
wide order. Counts stay workshop-wide for the same reason — the API has no
search-scoped count (G-J20).

## 7. Deliberately not shown (field is MISSING or not trusted)

| Not shown | Why |
|---|---|
| "Waiting since" / age / turnaround | No such field on `CleanJob`; `createdAt` exists but an age would be a derived claim with no defined clock |
| SLA, priority, urgency badge, "overdue" | Not modelled anywhere |
| Technician workload, capacity, availability | No aggregate exists; a "3 jobs today" figure would be invented |
| "Next appointment" / schedule ordering | The server returns `created_at DESC`; no schedule ordering exists (inventory §8.2) |
| Photos / documents count on the row | `evidencePhotos` is an int server-side but the client parses it wrong (G-J3) → a count would be a lie |
| "Documents ready" | The checklist constant is `true` before any document exists (G-J5) |
| Invoice, revenue, paid/unpaid | Not modelled in the jobs module |
| Review score on a pending job | `score` is written only on approve; the sample row carries 82 with `PENDING_REVIEW`, which the rows do not display (the sample is illustrative, the rule is the server's) |
| Filtered counts ("Pending review 4" while a search is active) | The counts endpoint takes no search parameter; the strip is labelled as workshop totals instead |
| Bell badge / unread count | No count endpoint (shell anti-goal) |
| A "Report" action on published jobs | The report endpoint reads `inspection_jobs` and 404s for a clean id (G-J8); published jobs offer the public link instead |
