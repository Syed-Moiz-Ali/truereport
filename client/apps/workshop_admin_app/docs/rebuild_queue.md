# Rebuild queue — workshop_admin_app

**Scope locked: jobs module** (2026-11-19). Foundation (shell + visual language +
tokens) is frozen from Waves 1/3/4 and is read-only to module sessions.

Path: **FULL, restricted to the jobs module** — audit → data truth → Brief 1 →
directions → Brief 2 (reference slice) → Brief 3 (remaining groups) → flow proof.

## Already rebuilt (do not re-open)

| Wave | Surface | Gate |
|---|---|---|
| 1 | sign-in (`features/auth/**`) | 6 PASS (independent, round 3) |
| 3 | dashboard (`features/dashboard/**`) | 6 PASS (independent) |
| 4 | shell (`packages/design_system/.../shell/**` + `features/home`) | 6 pending independent review at resume |

## Jobs module — screen inventory (verified against `lib/src/features/jobs/`)

| # | Screen / surface | File | Lines | Wave |
|---|---|---|---|---|
| 1 | Queue (tab) | `jobs_tab.dart` | 273 | **J1** |
| 2 | Job detail | `job_detail_page.dart` | 1141 | **J1** |
| 3 | Creation wizard | `job_creation_wizard_page.dart` | 498 | J2 |
| 4 | Schedule job sheet (legacy create) | `schedule_job_sheet.dart` | 422 | J2 |
| 5 | Approve / review | `approve_job_page.dart` | 321 | J2 |
| 6 | Publish checklist | `publish_checklist_page.dart` | 268 | J2 |
| 7 | Documents | `job_documents_page.dart` | 192 | J2 |
| 8 | Client board (tab) | `jobs_board_tab.dart` | 652 | J3 |
| 9 | Notifications list | `workshop_notifications_page.dart` + `notification_center.dart` | 72 + 197 | J3 |
| 10 | Public link | `public_link_page.dart` | 351 | J3 |
| 11 | Quick sheet | `job_quick_sheet.dart` | 253 | J3 |
| 12 | Assign technician | `assign_technician_dialog.dart` | 353 | J3 |

Helpers that are candidates for deletion/replacement (not screens):
`job_widgets.dart` (213), `job_presentation.dart` (704, status policy — keep the
policy, replace the presentation), `job_counts.dart`, `workshop_job_models.dart`
legacy half, `models.dart` legacy `WorkshopJob`.

## Waves

### J1 — reference slice (Brief 2)

Queue + detail only. List = `CleanJob`, counts = `CleanJobCounts` (one scope per
label, closes J5/D2). Detail rewritten into region files. Old queue, quick-sheet
open path and legacy queue widgets die here.

Blocks: J2, J3. Gate 6 judged by a fresh `qa-reviewer`.

### J2 — write path (Brief 3A)

Create wizard, approve, publish checklist, documents, schedule-sheet fate. Must
prove create → row appears, checklist blocks publish, publish → link live.

### J3 — client surface (Brief 3B)

Board, notifications, public link, quick sheet (or its deletion), assign.
Must prove assign → detail shows the technician name, cancel → active lanes drop
the row, terminal job hides mutations.

## Structural decision recorded for this module

**One job object: `CleanJob` (`platform_jobs`) for queue, detail and board.**
The legacy `inspection_jobs` queue is the reason a newly created job never appears
in the queue (audit T4) and why a queue row cannot open the clean detail page
(J1/D3). The allowlist (B4) already schedules the legacy family for deletion in
this wave. The two shell tabs stay, renamed by scope: **Jobs queue** (workshop
lifecycle) and **Client board** (publication lane) — same records, different
predicate. No server contract changes.

**Legacy bridge (non-lossy):** `inspection_jobs` is still written by the technician
endpoints, so its rows stay reachable through one read-only `features/jobs/archive/`
surface. Legacy *mutations* and UI die in J1; the legacy *read* survives only for
that surface, guarded by a source-scan test. Removal is gated on CR-3 (server
backfill). See `docs/design_decision.md`.

## Out of scope

`features/reports/**`, `features/staff/**`, `features/templates/**`,
`features/settings/**`, auth/dashboard/shell files, `packages/**` (foundation).
Requests for any of these go to `docs/change_requests.md`.
