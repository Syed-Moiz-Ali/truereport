# Data gaps — dashboard + jobs (Phase 1)

| # | UI need | Why it matters | What exists today | What's missing | Proposed backend change | Interim UI behaviour |
|---|---|---|---|---|---|---|
| G1 | One job list for the workshop | The dashboard and queue read `inspection_jobs`; the wizard writes `platform_jobs` | Two endpoints, two tables, no dual-write | A single canonical jobs read model | Decide the system of record; either migrate legacy rows or point the dashboard/queue at `platform_jobs` | **Blocking for the rebuild** — do not design a dashboard on a dataset the primary action does not write to |
| G2 | A trustworthy "Active" number | "Active" is derived `assigned + inProgress` on the client and overlaps the "In progress" tile | `assigned` and `inProgress` on the wire | An explicit `active` definition, or honest labels | Add `active` to `JobCountsDto`, or drop the tile | Relabel or remove until decided |
| G3 | A partition-safe pipeline | Current segments mix all-time buckets with a today-subset and omit three statuses | Individual counts only | Either a full 7-segment partition or a clearly scoped "today at a glance" | None needed — this is a client composition fix | Rebuild the chart from the full status set, or remove it |
| G4 | Search-scoped chip counts (or explicit scope) | Queue chips count the search result; board chips ignore search | Both behaviours exist | One consistent rule per screen + a label that states it | Optionally add `search` to `/jobs/counts` | Label the queue chips "in this view"; board chips "all jobs" |
| G5 | Correct local times | User-picked times display 4 h late (T1) | Naive `LocalDateTime` on the wire | An offset (`Z`/`+04:00`) or an explicit "naive = Dubai wall time" contract | Emit ISO-8601 with offset; or document one convention | Client fix: treat naive values as Dubai wall time, do not add 4 h. Centralise the two duplicated helpers first |
| G6 | Technician names in assignment history | The detail screen prints a UUID | `technicianId`, `assignedBy` ids | Names on the assignment DTO | Add `technicianName` / `assignedByName` | Render "Technician" with the row's name elsewhere, or hide the column until the DTO carries it |
| G7 | Specific mutation errors | 409s collapse to "Action failed" | `AppFailure.code` exists | Per-code copy mapping in these screens | None | Map `JOB_ALREADY_ASSIGNED`, `JOB_NOT_ASSIGNABLE`, stale-version to distinct copy |
| G8 | Real contract samples | Phase 1 could not capture responses | DTO-derived shapes only | Captured, sanitized fixtures + a contract test | None (test infrastructure) | Keep `provenance: derived-from-dto` honest |
| G9 | Review/finding shape proof | Detail's inspection section depends on it | Client mapper only | DTO diff + fixture | None | Treat as ASSUMED; do not redesign its layout until verified |

## Dashboard-only gaps (Wave 3, LITE)

| # | UI need | Why it matters | What exists today | What's missing | Interim UI behaviour |
|---|---|---|---|---|---|
| G10 | "What needs me now" as a first-class thing | The dashboard's whole job is priority, but there is no "awaiting my decision" aggregate | `pendingReview` count + `status=PENDING_REVIEW` list filter | Nothing backend-side | Build the hero from `pendingReview` + that filter. Honest, no new endpoint. |
| G11 | A date window ("today", "this week") | Users read "Finalized today" as a promise | `from`/`to` on the list only, semantics unproven; no windowed counts | A windowed counts endpoint | **Drop every "today" claim from the dashboard.** No windowed metric ships. |
| G12 | Schedule ordering ("next appointment") | The most natural hero for a workshop | `ORDER BY created_at DESC` only | An `order=scheduledAt` option | Removed from the design space (J21). The hero is status-driven, not time-driven. |
| G13 | Technician load | "Who is free?" is the second question a manager asks | `assignedTechnicianName` per job | A per-technician aggregate | Not on this screen. Would need a new endpoint; out of scope. |

## Two-phase truth rule

G1 and G5 are **blocking for Brief 2**: any dashboard designed on `inspection_jobs`
while the primary action writes `platform_jobs` would ship a screen that lies about
the user's own work. G2/G3/G4 are client-composition fixes that Brief 1 can pin with
tests. G6–G9 can land inside W1 without blocking design.

## Gate 1 self-grade

- Inventory: 30 elements — 18 VERIFIED, 4 ASSUMED, 6 SUSPECT, 2 MISSING.
- **Every SUSPECT has a named root cause with file:line evidence** (T1–T5).
- No metric is estimated or filled. Where the shape is unproven it is labelled
  ASSUMED and listed here.
- **Verdict: PARTIAL — consistent for the clean-jobs family; the legacy dashboard
  family cannot be certified until G1 is decided.** This gate is self-graded, so
  the honest headline is: *the numbers are explainable, and two of them are
  wrong.*

### Wave 3 re-grade (dashboard only, after Gate 0 accepted J19)

G1 (one job world) is **closed** for this screen: the dashboard reads
`platform_jobs`. Full trace in `docs/data/dashboard_inventory.md`.

- 32 elements: 23 VERIFIED · 1 ASSUMED · 1 SUSPECT (root-caused, handled by the
  W1 clock policy) · 7 MISSING.
- G2/G3 closed by composition: "Active" and "Finalized today" are removed; the
  pipeline is the nine real buckets + explicit remainder.
- G10–G13 opened as new gaps; none blocks a design, because the design space was
  narrowed to what exists.
- **Verdict: PASS (self).** Condition carried into Phase 3/5: a bar may be drawn
  only from the nine verified buckets plus an explicit remainder, with `total`
  always visible; no time window; no ordering other than created-desc.
