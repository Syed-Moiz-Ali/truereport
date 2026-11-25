# Brief 3 — production build of direction A (FOCUS)

Phase 6 / W3. The user chose **A — Focus** (`docs/design/proofs/a_*.png`). The preview
(`lib/preview/direction_a.dart`) is the visual reference, **not** the code to copy: it has hardcoded
copy, sample data and no backend. Production must use real providers, real l10n keys, the real save
path, and the real states.

## What is being replaced (kill list, after the new screens pass)

- `features/jobs/queue/**` (the W2 queue redesign) — replaced by `features/jobs/ramp/**`
- `features/inspection/deck/**` and `inspection_deck.dart` — replaced by `features/inspection/session/**`
- `features/jobs/technician_jobs_clean_page.dart` — already deleted in W1
Nothing else in the app is touched.

## Queue — `JobsRampPage` (route `/jobs`)

Data: `technicianJobPageProvider(TechnicianJobsQuery(page: n, size: 50, status: null))`,
`syncQueueStatusProvider`, `authControllerProvider` (initials), pull-to-refresh (invalidate + await).

Structure, phone:
- Header: `Jobs`, `{toStart} to do · {inProgress} in progress`, avatar → `/profile`, search toggle.
  Search filters the loaded page (invariant 2) and says so in a comment.
- Hero (`RampHero`): the in-progress job; else the earliest job dated today; else the earliest
  unfinished job. Status word, time, vehicle (wraps, never ellipsised), plate chip, customer,
  `{done} of {total} items`, a dense `ProgressSpine`, `Section n of m · {name}`.
- Groups: `UP NEXT` (today, not the hero), `UNFINISHED` (dated before today, latest first, each row
  shows its date), `LATER` (future dates, collapsed as one count row that expands). Cancelled jobs are
  not rendered anywhere, only counted in the empty-state sentence.
- Row: time (or date + time in UNFINISHED), vehicle, plate, `{done} of {total} items`, verb
  (Start / Continue / Finish / View), chevron. Whole row tappable.
- The hero's action is docked in the thumb zone: `Resume inspection` (≥56 px) with the next item named
  above it; no floating action.
- Sync/offline: one strip when offline or when sync is pending; tap → `/sync`.
- Pager: `Load more` when `totalPages > 1` (kept from W2).
- States: skeleton shaped like the hero + rows; empty (no jobs / nothing today with the nearest day
  named); error with retry; offline.

Tablet ≥ 820: content max 900, hero becomes a wide ticket (vehicle + plate left, spine and resume
right), groups in two columns only if both have rows. Never a centred 390 column.

## Job session — `JobSession` (inside `/jobs/:id`, replacing InspectionDeck)

The workspace page keeps the photo gate, loading and error branches; it renders `JobSession` when the
checklist is loaded.

Structure:
- Header: back, vehicle, plate chip, reference, sync/offline chip. No app bar.
- `ProgressSpine` (shared, `features/jobs/ramp/progress_spine.dart`): current index = first unanswered;
  tapping a tick jumps to that item.
- Section pill (`{name} · {done} of {total} items`) → bottom sheet listing all sections with counts and
  the next item; selecting one moves the session.
- Item card: `ITEM {n} OF {total}`, label 24/700, instruction 15/1.55, safety-critical and
  photo-required badges, the evidence requirement line (`No photo yet · 0 of 1` + Add), and
  `Section {n} of {m} · {name}`.
- Dock (thumb zone): Pass / Advisory / Fail at 56-64 px (labels + icons, tones from the taxonomy),
  `Add photo` and `Next item` at 48. No chevron-only affordances.

Behaviour:
- Answering calls a new `saveQuickAssessment(...)` in `features/inspection/assessment_saver.dart`:
  builds `AssessmentRequest(baseVersion, clientRevision, resultCode)`, calls
  `technicianApiProvider.saveAssessment`, invalidates the four providers exactly like
  `assessment_screen._save`, and on a network failure queues through the same offline store path the
  item screen uses. It returns an outcome (`saved | queued | needsDetail(error)`).
- `needsDetail` (the server rejects because evidence/fields are required): keep the card, show the
  message inline and open the item route with the chosen result preselected on tap.
- Read-only job status (anything outside ASSIGNED/SCHEDULED/IN_PROGRESS/DRAFT): no answer dock, one
  `Summary` action, rows not tappable.
- All items answered → dock primary becomes `Finish job` → `/summary`.
- `Add photo` opens the item route (evidence lives there); no duplicate capture path.
- Offline: answers still save through the queue and the header shows the sync state; never silently
  drop a tap.

Tablet ≥ 820: item card left (max 720), section rail right (all sections with counts and next item).

## Shared rules

- Real copy only from `TechnicianKeys` (the new `technicianRamp*` / `technicianSession*` keys exist).
  No literals; `gate_no_literals` scans lib.
- Status labels/tones only via `jobStatusLabel` / `jobStatusTone` / `resultLabel` / `resultTone`.
- Tokens: `context.colors`, `context.brand`, `context.statusColors`, `context.texts`; cards 16,
  buttons 14, pills 999, sheets 24; 4/8 spacing.
- 44 px minimum targets, 56 px primary; SafeArea; directional insets; reduced motion respected.
- No new dependencies. No edits to `technician_api.dart`, the router, or the workspace page (the main
  session wires those).

## Acceptance

- `flutter analyze --fatal-infos` 0; `flutter test` green (existing 88 + new).
- Real-font golden capture at 390 and 768 for both screens (states: loaded, empty, offline, read-only).
- No new `RenderFlex overflowed`; 1.5× text passes.
- Real app on `tech.a@truereport.test`: resume → answer a simple item → next card; answer an item that
  needs evidence → item screen; answer offline → header shows pending; finished job → read-only.
