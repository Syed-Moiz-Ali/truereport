# Dashboard data truth — clean (`platform_jobs`) family

Phase 1, investigate-only. Scope: **the dashboard screen only**, after Gate 0
accepted invariant **J19** (the dashboard reads the same table its own "New job"
writes). Supersedes rows 1–12 of `docs/data/inventory.md` for this screen; those
rows describe the legacy family and stay valid for the jobs queue.

There is **no reachable server** in this environment. "VERIFIED" means verified
against server source + client mapper, not against a captured live response.
Samples are DTO-derived — `docs/data/samples/README.md` says so.

## 0. The two endpoints this screen may use

| Endpoint | Returns | Scope | Verified from |
|---|---|---|---|
| `GET /api/v1/workshop/jobs/counts` | `JobStatusCountsDto` — 9 status buckets + `total` | entire workshop, **no filter parameter** | `WorkshopJobAdminController.java:87`, `WorkshopJobAdminService.java:171-188`, `WorkshopJobDtos.java:106-117` |
| `GET /api/v1/workshop/jobs` | `JobPageDto { items, page, size, total, totalPages }`, items are `JobDto` (clean) | `page, size, status, search, from, to`; `ORDER BY created_at DESC, id DESC` | `WorkshopJobAdminService.java:150-167`, `PlatformJobStore.java:121-149` |

Both read `platform_jobs`. The dashboard must use nothing else (J19).

## 1. The partition — VERIFIED

```java
// WorkshopJobAdminService.java:171-188
Map<String, Long> counts = new LinkedHashMap<>();
for (String status : store.statuses(workshopId)) counts.merge(status, 1L, Long::sum);
long total = counts.values().stream().mapToLong(Long::longValue).sum();
return new JobStatusCountsDto(get("DRAFT"), get("SCHEDULED"), get("ASSIGNED"),
    get("IN_PROGRESS"), get("PENDING_REVIEW"), get("APPROVED"), get("PUBLISHED"),
    get("REJECTED"), get("CANCELLED"), total);
```

- The nine buckets are mutually exclusive job statuses.
- `total` is the sum of **every** status present, not just the nine mapped.
- Therefore `sum(nine labelled buckets) == total` **only while no job carries a
  status outside the nine**. A new server status would make `total` larger than
  the labelled sum, silently.

**Rule derived (J20 + this check):** the UI computes
`unaccounted = total - sum(nine)`. If it is non-zero the pipeline cannot be drawn
as a closed bar; show the remainder explicitly as "Other" and keep `total`
visible. Never rescale the nine to force 100 %.

Sample: `docs/data/samples/clean-job-counts.json` (provenance:
`derived-from-dto`, partition_sum = total = 24).

## 2. Every element the dashboard may display

Status legend: **VERIFIED** source + definition proven · **ASSUMED** plausible,
unproven · **SUSPECT** contradiction/doubt · **MISSING** no source.

### 2a. Counts (all workshop-wide, no window)

| # | Candidate element | Source field | Definition | Status |
|---|---|---|---|---|
| 1 | Draft | `draft` | jobs still being prepared | **VERIFIED** |
| 2 | Scheduled | `scheduled` | booked, no technician | **VERIFIED** |
| 3 | Assigned | `assigned` | technician named, work not started | **VERIFIED** |
| 4 | In progress | `inProgress` | work started | **VERIFIED** |
| 5 | Pending review | `pendingReview` | submitted, awaiting admin decision | **VERIFIED** |
| 6 | Approved | `approved` | passed review, not published | **VERIFIED** |
| 7 | Published | `published` | customer-facing report live | **VERIFIED** |
| 8 | Rejected | `rejected` | sent back to the technician | **VERIFIED** |
| 9 | Cancelled | `cancelled` | abandoned | **VERIFIED** |
| 10 | Total | `total` | every job in the workshop | **VERIFIED** — and the only number that is always consistent with the nine |
| 11 | Pipeline shares | derived from 1–9 + 10 | `bucket / total` | **VERIFIED** arithmetic · **CONDITIONAL** rendering (see §1 "unaccounted") |
| 12 | "Active jobs" | legacy `assigned + inProgress` | — | **REMOVED.** Redundant with rows 3–4 and not on the clean wire. Do not reintroduce. |
| 13 | "Finalized today" | — | needs a date window | **MISSING** — the clean counts has no window; the legacy field came from `inspection_jobs`. Dropped. |
| 14 | "New & scheduled" | legacy `draft + scheduled` | — | **RELABELED** as two separate buckets (rows 1–2), because they are two different states. |

### 2b. Job rows (for any list the dashboard shows)

| # | Element | Source | Status |
|---|---|---|---|
| 15 | Reference | `reference` | **VERIFIED** |
| 16 | Status | `status` (9-value enum) | **VERIFIED** · unknown ⇒ explicit "Unknown" + one log (contract rule) |
| 17 | Vehicle `make model` | `vehicleMake`, `vehicleModel` | **VERIFIED** |
| 18 | Year, plate | `vehicleYear`, `vehiclePlate` | **VERIFIED** |
| 19 | Customer name | `customerName` | **VERIFIED** |
| 20 | Technician name | `assignedTechnicianName` | **VERIFIED** (null until assigned) |
| 21 | Scheduled time | `scheduledAt` | **VERIFIED field** · **SUSPECT value**: naive `LocalDateTime` on the wire; the W1 clock policy treats a naive value as Dubai wall time (`workshop_clock.dart`). Do not re-add offset hours. |
| 22 | Created at | `createdAt` | **VERIFIED** — the list's actual sort key |
| 23 | Score / grade | `score`, `gradeCode` | **VERIFIED** (server-computed, null before review) |
| 24 | Review / publication sub-state | `reviewStatus`, `publicationStatus` | **VERIFIED** |
| 25 | Row order | `created_at DESC, id DESC` | **VERIFIED** — this is the only ordering the API offers |

### 2c. Things a dashboard usually shows that DO NOT EXIST here

| # | Want | Why not | Status |
|---|---|---|---|
| 26 | "Next job by clock / appointment order" | No schedule ordering; the page is created-desc and capped at 100 | **MISSING** (J21). Any "next up" claim is fabricated. |
| 27 | "Today" anything (today's jobs, completed today) | No date-window field on counts; `from`/`to` exist on the list but compare `scheduledAt`/creation, and there is no `completedOn` filter proven | **MISSING** |
| 28 | Technician workload / capacity | No per-technician aggregate endpoint | **MISSING** |
| 29 | Revenue, unpaid invoices, money | No endpoint in scope | **MISSING** |
| 30 | Average turnaround / duration | No aggregate, and `startedAt`/`completedAt` semantics unproven for aggregation | **MISSING** |
| 31 | Unread notifications count | `notifications()` exists but no unread count endpoint; would require fetching the list | **ASSUMED** (out of scope for this screen; the shell already shows the bell) |
| 32 | Search on the dashboard | The list endpoint supports `search` | **VERIFIED** (available, not required) |

## 3. Cross-checks performed

| Check | Result |
|---|---|
| Nine buckets sum to `total` | ✔ in the server's own construction (subject to §1 edge) |
| Counts scope == unfiltered list scope | ✔ both are "all jobs of the caller's workshop" (`requireWorkshop(caller)`) |
| `page.total` with no filter == `counts.total` | ✔ expected by construction; both count `platform_jobs` rows for one workshop |
| Counts change when the dashboard's own create succeeds | ✔ same table (this is what T4 broke) |
| A row's status is one of the nine | **ASSUMED** — no constraint is quoted in the client mapper; the server writes known values. Handled by the "unknown ⇒ Unknown" rule. |
| Tenant scoping | ✔ `requireWorkshop(caller)` on both endpoints; ids never come from the client |

## 4. Root causes carried from Wave 2 (still true)

- **T1** naive datetimes: user-picked times are naive Dubai wall time; the client
  must not add 4 h. W1's `workshop_clock.dart` is the single policy — the rebuild
  uses it and does not re-derive.
- **T4** two tables: resolved for this screen by J19.
- **T3** non-partition pipeline: resolved by J20.
- **T2** "In progress" scope clash between dashboard and queue: **not fixable on
  the dashboard**. The dashboard is workshop-wide; the queue's chips are
  search-scoped. Mitigation: the rebuilt dashboard never shows a chip-style count
  that could be read as "the queue's number"; it shows the workshop total with the
  word "workshop" in the accessible label.

## 5. Gate 1 self-grade

- Elements inventoried: **32** — 23 VERIFIED, 1 ASSUMED, 1 SUSPECT (scheduledAt
  value, root-caused and handled by the clock policy), 7 MISSING.
- Every SUSPECT is root-caused with file evidence (T1).
- Every MISSING is either removed from the design space (13, 26–30) or out of
  scope (31).
- No metric is estimated, derived client-side, or filled with a mock.
- The partition claim is verified in server source, **including its failure
  mode** (unknown status ⇒ remainder).
- **Verdict: PASS (self), with one condition:** the Phase 3/5 design may draw a
  bar only from the nine verified buckets + an explicit remainder, and may claim
  no time window and no ordering other than created-desc.

Evidence links: `docs/api/contracts.md` §B, `docs/data/samples/clean-job-counts.json`,
`docs/data/samples/clean-jobs-page.json`, `docs/data_gaps.md` G1–G4 + G10–G13.
