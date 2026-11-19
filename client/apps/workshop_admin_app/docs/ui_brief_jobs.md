# UI brief — jobs module, direction A "the counter"

Chosen at Gate 3 (autopilot, 2026-11-19) from the three rendered directions in
`docs/evidence/jobs_directions/`. Foundation is frozen: shell C "the dock", the
"bay window" language, tokens and primitives are read-only.

Evidence: `a-queue-1440.png` (EN), `a-queue-390.png`, `a-queue-1440-ar.png`,
`docs/concepts/jobs/a/wireframe.md`. Rejected directions and reasons:
`docs/design_decision.md`.

---

## 1. Product feeling

A service counter, not a catalogue. The queue is one dense sheet of work; the row
you touch pulls that job forward into a fixed inspector and tells you the single
next thing to do. Counts describe the workshop, the list describes the current
view, and the two never pretend to be each other.

**Signature idea (committed):** *sort one sheet, select a row, act from the
inspector — the decision happens without leaving the queue.*

## 2. Anti-goals

- No second job object: no `WorkshopJob`, no legacy endpoint, no quick sheet.
- No chip row whose numbers are derived from the current page while wearing a
  workshop-wide label. Counts come from `GET /workshop/jobs/counts` and say so.
- No "today / this week / active / utilisation / SLA" number — none exists.
- No relative age ("3h ago") derived from server instants (G-J18, CR-8).
- No publish action outside the checklist (M6).
- No card-at-a-time flow at 1440; no sidebar; no new navigation pattern.
- No raw enum, raw ISO string, raw JSON, or a `0` where the value is absent.

## 3. Information architecture

```
Identity strip (44 px, shell)
Content
  page header      eyebrow "JOB QUEUE" · title "Job queue" · one meta line
                   meta: "Sorted by scheduled · ascending" + "New job"
  toolbar          search (reference / plate / VIN) · New job
  status strip     "Workshop totals" + 9 statuses + All, each with a server count
  body
    ≥1100          sheet (table) + 380 px inspector
    680–1099       inspector becomes a full-width region above the sheet
    <680           card list; the card footer carries the next action
  footer           "1–10 of 24 shown" · previous/next · "Sort applies to this page"
Dock (88/78 px reserve)
```

Flows:

| Flow | Steps |
|---|---|
| Find a job | status strip or search (server-scoped) → scan/sort the sheet |
| Act | select a row → inspector → primary action (status-derived) |
| Open the full record | inspector footer "Open job" → `JobDetailPage` |
| Create | "New job" → `JobCreationWizardPage` (clean create) |
| Legacy rows | header overflow → "Legacy archive" → read-only list |

## 4. The sheet (≥1100)

Columns, in this order; the first four are sortable locally:

| Column | Content | Notes |
|---|---|---|
| Job | reference (LTR tabular) + template name · version | reference is the identifier, never truncated before 12 chars |
| Vehicle | model + plate (LTR) | no year in the cell (it lives in the inspector) |
| Customer | name | one line, ellipsis |
| Technician | name or "Unassigned" | muted when unassigned |
| Status | status badge (label + tone) | never colour-only |
| Scheduled | date + time (user-picked field) | `—` when not scheduled |

Row height 56, hairline dividers, sticky header. Selected row: 3 px accent bar at
the start edge + `accentSoft` tint. Keyboard: arrows move selection, Home/End jump,
Enter is unbound; focus follows selection.

**Ordering** is local to the loaded page and the footer says so. Default: scheduled
ascending, unscheduled last. Status strip filters are server-side (`status` param)
and page resets to 1.

**Text scale above 1.3× (1.5× and 2×):** the 380 px inspector can no longer hold a
full action label and the six-column sheet splits words, so the queue switches to
the card list at every width (1440/1024 included). No table, no inspector; each card
keeps a full-width action footer, and the strip, search, New job, archive entry and
pagination remain. From 900 px the cards sit two-up so a desktop card stays readable.

**Pagination:** page size 10. Footer: "1–10 of 24 shown", previous/next buttons
(keys `jobs-page-prev`, `jobs-page-next`), disabled at the ends. The count in the
footer is the server `total`, never `items.length` presented as the total.

## 5. Inspector (≥1100)

380 px, full body height, start edge of the row; at 680–1099 it is a full-width
region above the sheet and the "close" control clears the selection.

Blocks, in order:

1. Identity: reference · vehicle title · status badge · publication badge.
2. Customer: name, phone (LTR), email.
3. Job facts: technician, scheduled, template + version, mileage, review status,
   consent state.
4. Footer: one primary action (table below) + a text "Open job".

Empty selection (first load or after clearing): the inspector shows a bounded
"Select a job" placeholder, not a blank pane. On phone there is no inspector.

### Next-action policy (server-authoritative, one pure function + table test)

| Status | Primary action | Enabled when |
|---|---|---|
| DRAFT | Assign technician | `version != null` |
| SCHEDULED | Assign technician | `version != null` |
| ASSIGNED | Open job | always |
| IN_PROGRESS | Open job | always |
| PENDING_REVIEW | Review & approve | `version != null` |
| APPROVED | Publish checklist | `consentGranted == true`; otherwise "Publication blocked" with the reason and the same checklist link |
| PUBLISHED | View public link | always |
| REJECTED | Open job (read-only) | always |
| CANCELLED | Open job (read-only) | always |
| unknown | Open job | never invent an action |

Terminal/read-only: `PUBLISHED`, `REJECTED`, `CANCELLED` hide assign/cancel.
`APPROVED` hides assign/cancel. `version == null` blocks every mutation with a
distinct message (not a generic failure).

## 6. Phone (<680)

Cards, 16 px gutters, one per row, separated by 12 px:

```
Vehicle model                          [Status]
Plate
# reference   · customer
◷ scheduled   · technician
─────────────────────────────────────────────
[ primary action ]  (full width, 46)
```

The action is the same policy table. The card has no disclosure chevron; tapping
the body opens the detail page. Selected state is not used on phone.

## 7. States

| State | Behaviour |
|---|---|
| Loading | 6 skeleton rows in the real column geometry + inspector skeleton at ≥1100; no counts until counts load |
| Counts error | status strip shows labels without numbers; the sheet still renders; one bounded retry |
| List error | bounded `WorkshopErrorState` in the body with retry; counts may still show |
| Empty (no jobs) | bounded `WorkshopEmptyState`: "No jobs yet" + New job |
| Filtered empty | "No jobs in this view" + "Clear filters"; never "0 jobs" about the workshop |
| Page out of range | clamp to the last page, refetch |
| No session / 403 / 404 | distinct copy: sign-in required / not allowed / job not found (detail) |
| Stale version (409) | inspector shows a conflict message + "Reload job"; no silent overwrite |
| Unknown status | neutral badge "Unknown status"; action = Open job |
| Text scale 1.5×/2× | **Text scale ≥ 1.5** (switch at > 1.3): card list at every width — no sheet, no inspector, full-width action footer, no word split, no ellipsized action label; strip/search/New job/archive/pagination kept |

## 8. Data honesty (from `docs/data/jobs_inventory.md` §8)

May show: reference, status, reviewStatus, publicationStatus, customer name/phone/
email, technician name, vehicle make/model/year/plate/VIN, odometer, transmission,
fuel, template name/version, `scheduledAt`, score, grade, consent, cancellation
reason, checklist items, document name/status, link status/URL/timestamps, QR.

Must not show: any client-summed "total"; windowed counts; "active"; relative ages
from `createdAt/updatedAt/startedAt/completedAt`; finding evidence counts (CR-7);
documents-ready claims (CR-6); raw codes/JSON; a publish action outside the
checklist (CR-1); any workshop id in a request (M1).

Publication mapping: `PUBLISHED → Published`, `UNPUBLISHED/NOT_PUBLISHED → Not
published`, `REVOKED → Revoked`, anything else → Not published. Never test
`ACTIVE` on `CleanJob.publicationStatus` (G-J2).

## 9. Legacy archive (read-only bridge, audit F1)

Reached from the page-header overflow, not the dock. Full-width page pushed with
`MaterialPageRoute`:

- Banner: "Legacy records. Read-only. These jobs have not been migrated."
- List of `inspection_jobs` (reference, vehicle, customer, status, scheduled).
- No create, assign, cancel, report, publish, link.
- Quarantined in `features/jobs/archive/`; source-scan test forbids legacy symbols
  everywhere else. Removed when CR-3 lands.

## 10. Structure and kill list

New region files (J1):

```
features/jobs/queue/jobs_queue_page.dart        state: search/status/page/selection
features/jobs/queue/jobs_queue_header.dart
features/jobs/queue/jobs_status_strip.dart
features/jobs/queue/jobs_queue_table.dart
features/jobs/queue/jobs_queue_cards.dart
features/jobs/queue/jobs_queue_footer.dart
features/jobs/queue/jobs_inspector.dart
features/jobs/queue/jobs_queue_states.dart
features/jobs/detail/job_detail_page.dart + 7 region files (J1 detail session)
features/jobs/shared/job_status_badge.dart, job_fact.dart, job_fact_grid.dart,
                          job_actions.dart (policy), job_row_data.dart
features/jobs/assign/assign_sheet.dart
features/jobs/archive/legacy_archive_page.dart
```

Deleted: `job_quick_sheet.dart`, `schedule_job_sheet.dart`, `job_counts.dart`,
legacy half of `job_presentation.dart`, the inline assign block in
`job_detail_page.dart`, `WorkshopJob` from `models.dart`, `jobsProvider`/
`jobCountsProvider`, legacy API methods `jobs/jobCounts/createJob/assignJob/
cancelJob`, and the tests named in `docs/audit-jobs.md` §6.

**Recorded exception (Gate 6 round 1, F13):** the legacy *read* members
`WorkshopJob`, `jobsProvider` and `admin_api.jobs()` survive, but only for
`features/jobs/archive/legacy_archive_page.dart` (audit F1: `inspection_jobs` is
still written by technician endpoints). Every legacy *mutation* and every legacy
UI surface is deleted. A source-scan test forbids the read symbols outside
`archive/`. They are removed with CR-3 (server backfill).

## 11. Microcopy (existing ARB first)

Reuse `queueTitle`, `newJob`, `jobSearch`, `jobsTab`, `status*`, `jobsStatus*`,
`jobsCount*`, `notPublished`, `linkRevoked`, `reassign`, `assign`, `cancelJob`,
`commonActionFailed`. New keys (main session adds): `jobsWorkshopTotals`,
`jobsSortNote`, `jobsShownRange`, `jobsPagePrev`, `jobsPageNext`, `jobsSelectJob`,
`jobsNoSelection`, `jobsNoJobsInView`, `jobsClearFilters`, `jobsConflictReload`,
`jobsPublicationBlocked`, `jobsArchiveTitle`, `jobsArchiveBanner`, `jobsArchiveOpen`,
`jobsArchiveEmpty`, `jobsNextReview`, `jobsNextAssign`, `jobsNextOpen`,
`jobsNextPublish`, `jobsNextLink`, `jobsNextTrack`.

## 12. Gate 6 acceptance

- Rewritten queue and detail files; one new widget file per region; non-empty kill
  list; visibly different at 1440 / 1024 / 390.
- Flow proof, captured: filter by status → count and rows agree; select → inspector
  shows that job; assign → detail and inspector show the technician; cancel →
  row leaves the active view; create → the new job appears (J2); terminal job hides
  mutations; stale version shows the conflict state; read-only archive opens and
  has no actions.
- 1440/1280/1024/768/390/360 EN + 1280 AR, 1.5×/2× text, no new
  `RenderFlex overflowed`.
- `dart format`, `flutter analyze --fatal-infos`, `flutter test` green.
- A fresh `qa-reviewer` judges the screenshots + this brief, not the build log.
