# Brief 1 (wave 2) — dashboard + jobs: engineering only

Phase 2 artifact. **No pixels, no layout, no new components, no design
decisions.** Blueprint: `docs/audit-dashboard-jobs.md`,
`docs/data/inventory.md`, `docs/api/contracts.md`, `docs/data_gaps.md`.

Decision carried in: **G1 = `platform_jobs` is the source of truth.** The
dashboard and queue stop reading `/workshop/legacy/jobs`.

## Phases (each independently revertible, each ends green)

### A. Pin the contract seam (D1 / G8) — tests only

- Add `test/support/job_fixtures.dart` holding JSON payloads for
  `JobDto`, `JobPageDto`, `JobStatusCountsDto`, `JobCountsDto` (legacy, for
  removal), `AssignmentDto`, `ReviewDto` — shapes copied from the server DTOs,
  marked `derived-from-dto` until a capture exists.
- Add tests that build every model **from JSON**, not from constructors:
  `CleanJob`, `JobPage`, `CleanJobCounts`, `JobReview`, `ReviewFinding`,
  `JobAssignment`. Rename a field in the fixture and the test must fail.
- Add mapper edge cases: unknown status, null optional fields, empty lists,
  unparseable date, `REVOKED` publication.
- Add error-mapping tests: 401, 403, 404, 409 (`JOB_ALREADY_ASSIGNED`,
  `JOB_NOT_ASSIGNABLE`), 5xx → distinct `AppFailure` codes.
- No production code changes in this phase.

**Done when** `admin_api.dart`-adjacent mapping has fixtures that would catch a
server rename, and the suite is still green.

### B. One time policy (T1 / G5)

- Introduce a single helper (`WorkshopClock`) with one documented rule:
  - value **with** an offset (`Z`, `+04:00`) → convert to Asia/Dubai;
  - value **without** an offset → it is a Dubai wall time; **do not add 4 h**.
- Route `formatInstant` / `dubaiWallTime` through it; delete the duplicate in
  `report_page.dart:27-52`.
- Tests: naive `2026-11-18T10:00` renders 10:00; `2026-11-18T06:00Z` renders
  10:00; empty/unparseable renders the existing fallback.
- **Behaviour change, intended and approved:** every user-picked time now shows
  the time the user actually picked. Server-generated instants are correct only
  if the server runs UTC — the fix makes that assumption explicit and testable.

### C. Point dashboard + queue at the clean API (G1, T2, T3, G3, G4)

- Queue: `JobsTab` reads `cleanJobsProvider` (paged, status filter, search) and
  `cleanJobCountsProvider`. Status chips become the clean vocabulary already
  used by the board: All / In review / Approved / Published, counts from the
  counts endpoint. Opening a row keeps the current sheet behaviour for now.
- Dashboard: counts from `cleanJobCountsProvider`; job list from
  `cleanJobsProvider(page 0, size 5)`.
- Dashboard tiles become **one server field each, no overlap**:
  `New = draft + scheduled` · `In progress = inProgress` ·
  `In review = pendingReview` · `Approved = approved` · `Published = published`.
  Labels reuse existing keys (`dashboardStatNewScheduled`, `statusInProgress`,
  `jobsCountPendingReview`, `jobsCountApproved`, `jobsCountPublished`). This is a
  data-contract decision, not a visual one: Phase 3 may rearrange the strip, not
  redefine the numbers.
- Pipeline: render the nine-status partition from the same counts, so segments
  sum to `total`. If a full partition does not fit the current card, render the
  same numbers as a legend only — **do not** keep a non-partition bar.
- Remove `jobsProvider`, `jobCountsProvider`, `JobCounts` and the legacy screen
  code **only after** nothing imports them (analyzer + grep).
- "New job" from both the dashboard and the queue opens `JobCreationWizardPage`.

**Done when** creating a job from the dashboard changes the dashboard's own
numbers, and no screen references `legacy/jobs`.

### D. Assignment rows stop printing UUIDs (T5 / G6)

- `_AssignmentRow` resolves `technicianId` → name through `staffProvider`; if the
  id is unknown, render an em-dash, never the raw id.
- Same for `assignedBy` if it is an id (confirm from `AssignmentDto`).

### E. Dashboard copy is localized (D4 / J12)

- New ARB messages: `dashboardToday` (`{date}`), `dashboardGreeting` (`{name}`);
  no string concatenation for a sentence.
- Arabic build must contain no English on the dashboard.

### F. CI gates

- `tool/baseline_check.dart` stays the gate (new failures only).
- Add a coverage floor for the newly tested files (`job_presentation`,
  the counts mapper, the clock helper) in the same tool or a small script.
- Format/analyze/test stay clean; allowlist stays empty.

## Out of scope

Any colour, spacing, type, layout, widget structure, navigation shell change, or
new design-system primitive. Phase 3 owns those. The dashboard/tiles will look
different only in their numbers and labels during W1; W2 replaces the layout.

## Acceptance

1. All existing 428 tests stay green; new tests cover A, B, C, E.
2. Analyzer clean (`--fatal-infos`), format 0 new, allowlist empty.
3. Creating a job via the dashboard's primary action increments the dashboard's
   `New` or `In progress` count on refresh.
4. No screen calls `/legacy/jobs`; no screen renders a UUID as a person.
5. A naive timestamp displays as picked; an offset timestamp converts correctly.
6. `renderFlex` counts unchanged at every breakpoint (this brief should not move
   a single pixel except times, numbers and two labels).

## Verification commands

```
cd client/apps/workshop_admin_app
flutter analyze --fatal-infos
flutter test
dart run tool/baseline_check.dart
flutter test test/screenshot*          # expect time/label diffs only, listed in the report
```
