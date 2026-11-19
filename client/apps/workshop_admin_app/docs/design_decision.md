# Design decisions — workshop_admin_app

Decisions are recorded here so a later reader can see *why*, and so a rejected
direction can be re-run cheaply. Foundation decisions are closed; module
decisions are appended below.

---

## Foundation (frozen 2026-11-19)

### Shell — direction C, "The dock" (chosen by the owner, 2026-11-18)

**Signature idea:** the dock is the only navigation, and it names only the place
you are. A 44 px identity strip holds brand, workshop, language, notifications and
account; content is full-width; six destinations float at the bottom centre, the
active one expanded to a labelled pill.

Why it won:

1. Gives ~256 px back to tables at 1440 — the jobs table and the template builder
   are the widest surfaces in the app, and both were squeezed by the old sidebar.
2. Identity appears exactly once (audit S1: the old shell repeated the workshop
   name in the bar and the page eyebrow).
3. It survives 5 modules × 6 screens with one navigation model — no second
   pattern appears at any width; the same six indices and test keys are preserved.
4. It mirrors cleanly in RTL: the dock is centred, not start-aligned, and the
   strip's directional padding flips without re-ordering anything.

Rejected:

- **A "The spine"** — 84 px icon rail + command bar. Best discoverability, but it
  still spends width on chrome and re-introduces a second identity surface in the
  command bar.
- **B "The ledger"** — 64 px tab band with inline search. Clean at 1440, but the
  search field belonged to neither the shell nor the screens; and the tab band
  plus strip cost more vertical space on a laptop than the dock costs at the
  bottom.

Cost accepted: unconventional for a desktop admin tool; the dock overlays nothing
because the content area reserves its height (brief §5), but every screen must
honour that bottom reserve.

Evidence: `docs/evidence/shell_directions/` (3 × 1440/390 + 3 style tiles),
`docs/evidence/shell_after/` (8 real screens), `docs/evidence/gallery/`.

### Visual language — "The bay window" (committed in Wave 1, extended in Wave 3)

Quiet product software: hairline borders, one accent, a compact type scale, no
elevated cards, no gradients, no glass. Data-led screens get one display role
(`WorkshopDisplay`) and a single accent only for the current state. Light only
(waiver W-LIGHT).

Tokens/primitives live in `packages/design_system` and are **read-only** to module
sessions. Jobs inherits them; it does not restyle them.

### Screen archetypes (decided once)

list = page header + toolbar (search/filters) + rows (table ≥ wide, cards < wide) +
counted footer · detail = identity header + fact grid + action rail + timeline ·
form = single column, sectioned, sticky action bar on wide screens · dashboard =
hero + partition atlas + group list · empty/error = bounded state inside the
content region, never a full-page takeover.

---

## Module decisions

### Jobs — one job object (2026-11-19)

**Chosen:** `CleanJob` (`platform_jobs`) becomes the single object for queue,
detail and board. The legacy `inspection_jobs` queue (`jobsProvider`,
`WorkshopJob`, `job_counts.dart`, `job_quick_sheet.dart`, `schedule_job_sheet.dart`)
is deleted in wave J1.

Why:

1. A job created by the app's own primary action (`createCleanJob`) is invisible
   in the queue today (audit T4). No amount of styling fixes a queue reading the
   other table.
2. A queue row cannot open the clean detail page — the two id spaces are
   different (audit D3/J1). One object makes list → detail true by construction.
3. The dashboard already reads the clean counts endpoint, so the queue is the
   last surface on the legacy family; allowlist B4 already scheduled its deletion.

Rejected:

- **Keep both worlds, rename them.** Cheapest, but keeps two create flows, two
  row vocabularies and a queue that lies about what was created.
- **Build a legacy detail page.** New UI on a table that is being retired.

Consequence recorded: `inspection_jobs` rows stop appearing in the primary queue
unless the server backfills them into `platform_jobs`. This is a **data migration
risk** reported at the gate, not something the client can invent.

### Jobs — legacy visibility bridge (2026-11-19, after audit F1)

**Problem:** `inspection_jobs` is not dead data. The technician controllers
(`/api/v1/technician/legacy/jobs/**` — inspections, evidence, report, delivery)
still read and write it, and `seed_report.sql` populates it. Deleting the legacy
reader outright would hide active work from the workshop.

**Decision:** the primary queue moves to `CleanJob`, and the legacy family is
quarantined behind one read-only surface:

- `features/jobs/archive/` — a read-only list of `inspection_jobs` reached from
  the queue's overflow ("Legacy archive"), with a persistent banner: *legacy
  records, read-only, not migrated*. No create, assign, cancel, report or publish.
- The legacy **read** API (`jobs()`, `WorkshopJob`) and its provider survive only
  for this surface. Every legacy **mutation** (`createJob`, `assignJob`,
  `cancelJob`), the quick sheet, the schedule sheet and `job_counts.dart` are
  deleted in J1.
- A source-scan test forbids legacy symbols anywhere under `features/jobs/`
  except `features/jobs/archive/`.
- Removal condition: when the server backfills `inspection_jobs` into
  `platform_jobs` (change request CR-3), delete `features/jobs/archive/` and the
  legacy read API. Until then the bridge is the only honest non-lossy option.

Rejected: a signed waiver hiding the rows (no human available in autopilot);
client-side remapping (no field correspondence; `scope`/`finalizedAt` have no
clean equivalent); keeping the legacy queue as the primary surface (keeps the
create/job-visibility contradiction this module exists to fix).

### Jobs — reference-screen directions

Three directions were generated blind for the queue and rendered inside the real
frozen shell: `docs/evidence/jobs_directions/{a,b,c}-queue-{1440,390,1440-ar}.png`.

**Chosen: A — "the counter"** (`docs/concepts/jobs/a/wireframe.md`, spec in
`docs/ui_brief_jobs.md`).

Why:

1. **It answers the audit's question without lying about scale.** The status strip
   carries server workshop totals; the list is the current view; the footer says
   "1–10 of 24 shown · sort applies to this page". It is the only direction whose
   counts, rows and ordering can all be true at the same time on page 2.
2. **It keeps scanning.** A manager can sweep six columns at 1440 — the lanes
   spend horizontal travel on four numbers and the triage desk spends 40 % of the
   width on one job.
3. **The next action still exists.** Selecting a row pulls the job into a 380 px
   inspector whose footer carries exactly one status-derived action; on phone the
   card footer carries it.
4. **No unreliable data.** It shows only `scheduledAt` (a user-picked field) and
   never derives ages from server instants (G-J18/CR-8).

Rejected:

- **B "the lanes"** — the strongest spatial idea, and its partition with a stated
  remainder is honest. Rejected because every card carried a relative age
  ("3h ago", "3d") derived from server instants that the inventory proves are
  4 h off (CR-8), and because four lanes of two cards each spend more space on
  lane headers than on work at 1440. The phone feed also repeated the selected
  card as a second summary bar.
- **C "the triage desk"** — the best single-job hierarchy, and the most honest
  about consent. Rejected because its core promise is a priority order, but the
  clean endpoint returns one page in `created_at DESC`; the most urgent job in the
  workshop can be on page 2. It admits the limit, which means the hero is
  sometimes wrong. It also gives 40 % of the width to one job and is the least
  scannable of the three for a 24-job queue.

Cost accepted: at 1440 the table is still a table — the structural change is the
persistent inspector, the status-distribution strip and the row anatomy, not the
abolition of columns. The edit-vs-replace test is satisfied by a rewritten file,
seven new region files, the deleted quick sheet/schedule sheet/legacy row, and a
different 1024 and 390 composition.
