# Dashboard — design exploration (Phase 3, before the spec)

Nothing in production was touched. Every render below comes from
`lib/preview/dashboard_directions.dart` (throwaway) captured by
`test/dashboard_directions_preview_test.dart` with the real bundled fonts.

Evidence: `docs/evidence/dashboard_directions/`
Contact sheet: `docs/evidence/dashboard_directions/index.html`

---

## 3a. Thinking protocol

### The job

One sentence: **tell the workshop admin what needs their decision right now, and
let them act on it without leaving the page.**

### What today's screen gets wrong

Not "it looks dated". Structurally:

1. It answers *lifetime totals*, not *today's attention*.
2. The five numbers do not add up (one is derived, one is a today-subset, three
   are all-time) and the pipeline bar is not a partition.
3. It reads a different table from the one its own **New job** button writes to,
   so the page cannot reflect the action it just offered.
4. Every module has the same weight: four equal cards, no focal point.
5. On phone it is a stack of five cards with a stranded fifth stat tile.
6. Its "Next up" claims a time ordering the API does not provide.

### Three constraints that actually bind

1. **Data.** Only the clean family: nine status buckets that sum to `total`, and
   a list ordered by `created_at DESC`. No time windows, no schedule ordering,
   no technician aggregates, no money.
2. **Shell.** The sidebar / bottom bar and the six tab indices are fixed and
   write-locked. The page owns its content area only.
3. **Platform + brand.** Light only (W-LIGHT), Plus Jakarta Sans, one green
   accent on warm paper, RTL Arabic must mirror without inventing new copy.

### The axes I varied (colour is not one)

| Axis | Values used |
|---|---|
| Layout logic | master-detail rail · full-bleed editorial canvas · two-column feed |
| Hierarchy | decision-led · partition-led · action-led |
| Density | medium (rows) · low (display type) · high (feed) |
| Nav shell | untouched in all three |
| Motion verb | cross-fade (A) · bars grow (B) · rows settle (C) |

Three directions follow, each rendered at 1440 and 390.

---

## 3b. The three directions

### A — "Triage rail"

**Signature idea:** the page is a single ranked work list; the pipeline is a
fixed instrument panel beside it.

```
1440                                            390
┌───────────────────────────────┬──────────┐   ┌──────────────┐
│ 4  waiting for your decision  │ PIPELINE │   │ MARINA       │
│    [New job]                  │ 24 total │   │ 4 waiting…   │
├───────────────────────────────┤ Draft  1 │   │ [New job]    │
│ Nissan Patrol   [Review]      │ Sched. 4 │   ├──────────────┤
│ Toyota LC       [Review]      │ Assign. 3│   │ 1│4│3│5 →    │ horizontal
│ Lexus LX        [Review]      │ In prog 5│   │ stage cards  │ stage rail
│ Ford F-150      [Review]      │ Pending 4│   ├──────────────┤
│ Open the review queue →       │ Approved2│   │ Nissan  [Rev]│
├───────────────────────────────┤ Publ.   3│   │ Toyota  [Rev]│
│ IN THE BAY  5 in progress     │ Rejected1│   │ Lexus   [Rev]│
│ Mercedes G 63  …  [In prog]   │ Cancel. 1│   │              │
│ BMW X5         …  [In prog]   ├──────────┤   │ 24 on floor  │
│ Hilux          …  [Assigned]  │ note     │   └──────────────┘
├───────────────────────────────┤          │
│ READY TO PUBLISH  3 approved  │          │
│ Porsche Macan  …  [Approved]  │          │
│ 24 jobs on the floor          │          │
└───────────────────────────────┴──────────┘
```

**Structural departures from today:** a *ranked* list replaces four equal cards;
the pipeline becomes a persistent instrument panel, not a card; the header
number is the decision count, not a greeting; the strip of five numbers is gone;
the two secondary groups are compact rows, not modules.

**Type + colour character:** tight, clinical, near-black on paper, one green
accent, hairline rules instead of card borders. Reference energy: Linear issue
lists / Stripe's dashboard exception views — density with restraint.

**Rendered:** `a-triage-rail-1440.png`, `a-triage-rail-390.png`,
`a-style-tile.png`.

**Trade-off:** only the top stage is expanded, so the other eight stages are a
legend rather than a workspace. If the admin's job is *publishing*, this page
buries it one section lower.

---

### B — "The floor"

**Signature idea:** the partition *is* the page — one full-bleed nine-segment bar
that every other element hangs from.

```
1440                                            390
┌──────────────────────────────────────────┐   ┌──────────────┐
│ MARINA WORKSHOP · EVERY JOB   [New job]  │   │ MARINA       │
│ 24  jobs on the floor                    │   │ 24 jobs on   │
│     4 are waiting for your decision      │   │   the floor  │
│ ████▓▓▓▓░░███████▲▲▲▲████████▓▓███▨▨    │   │ 4 waiting…   │
│ 1  4  3  5  4  2  3  1  1               │   │ [New job]    │
├──────────────────────┬───────────────────┤   ├──────────────┤
│ ▪ Waiting for you  4 │ ▪ In the bay    5 │   │ Draft    ▏ 1 │
│ Nissan Patrol Review │ Mercedes G63     │   │ Scheduled ▍4 │
│ Toyota LC     Review │ BMW X5           │   │ Assigned  ▎3 │ vertical
│ Lexus LX      Review │ Hilux            │   │ In prog  █  5 │ spine
│ Ford F-150    Review │ ▪ Ready to pub 3 │   │ Pending  █  4 │
│                      │ Porsche   Publish │   │ …            │
└──────────────────────┴───────────────────┘   │ Waiting for… │
                                               │ Nissan  [Rev]│
```

**Structural departures:** no cards at all inside the page; a 64 px full-width
partition replaces the five-tile strip *and* the pipeline card; a 76 px numeral
replaces the greeting as the largest object; three labelled groups replace
"Next up / Recent / Quick actions"; quick actions are deleted (the shell already
has them).

**Type + colour character:** editorial — display type at 76, uppercase tracking
eyebrow, data colours used as data (warning = needs you), generous white space.
Reference energy: a printed operations wall-chart, or a Stripe annual-report
spread.

**Rendered:** `b-the-floor-1440.png`, `b-the-floor-390.png`, `b-style-tile.png`.

**Trade-off:** the strongest identity and the clearest truth, but the least
actionable per pixel — one row action per item, no inline controls, and a very
large number that does not itself do anything.

---

### C — "The desk"

**Signature idea:** three decisions, one feed. The only numbers on the page are
the three things the admin can act on.

```
1440                                            390
┌──────────────┬────────────────────────────┐  ┌──────────────┐
│ YOUR DESK    │ Your desk, newest first    │  │ YOUR DESK    │
│ Three        │ ordered by created_at      │  │ 4 │ 5 │ 3 →  │ counters
│ decisions,   ├────────────────────────────┤  ├──────────────┤
│ nothing else.│ Nissan Patrol  [Rev]       │  │ [New job]    │
│ ┌──────────┐ │ Toyota LC      [Rev]       │  ├──────────────┤
│ │4 To review│ │ Lexus LX      [Rev]       │  │ Nissan [Rev] │
│ └──────────┘ │ Mercedes G63               │  │ Toyota [Rev] │
│ ┌──────────┐ │ BMW X5                     │  │ Mercedes     │
│ │5 In bay  │ │ Hilux                      │  │ BMW          │
│ └──────────┘ │ Porsche Macan  [Publish]   │  └──────────────┘
│ ┌──────────┐ │ Defender       [Publish]   │
│ │3 To pub. │ │ Jeep Wrangler  [Open]      │
│ └──────────┘ │ newest 9 of 24 · queue →   │
│ whole wk 24  │                            │
│ [New job]    │                            │
└──────────────┴────────────────────────────┘
```

**Structural departures:** the right pane is a *feed with a verb per row*, not a
list to open; the left pane is three decision counters that own the page's only
numbers; the nine-stage partition is demoted to a thin bar plus an explicit
legend string; "Next up" and "Quick actions" are removed; navigation between
tabs is untouched.

**Type + colour character:** product-software — tinted counter tiles
(warning/warningSoft, accent/accentSoft, success/successSoft), a white feed
surface, 14.5 px row titles, one black action per row. Reference energy: the
approval inboxes in Linear or Vercel.

**Rendered:** `c-the-desk-1440.png`, `c-the-desk-390.png`, `c-style-tile.png`.

**Trade-off:** the counters are three interpretations of the nine statuses, so
the page shows less of the workshop than A or B; and "nothing else" is a claim
the data partly contradicts (there are also approved, rejected and cancelled
jobs), which the legend has to absorb.

---

## Comparison at a glance

| | A Triage rail | B The floor | C The desk |
|---|---|---|---|
| Hero | the decision count | the partition | the three counters |
| Focal point | the review list | the 24 numeral + bar | the feed |
| One primary action | New job | New job | New job |
| Reads as | a work queue | an operations chart | an inbox |
| Phone | stage rail + list | vertical spine + list | counter strip + feed |
| Clearest truth | medium | **high** | medium |
| Most actionable | medium | low | **high** |
| Risk | decision-blind to publishing | least actable | three windows onto nine states |

All three: no fabricated metric, no time window, no ordering claim, no card
duplication of the shell's navigation, one primary action, real fonts.

---

## What happens after the choice

1. `docs/ui_brief.md` is written for the chosen direction only: per-breakpoint
   layout, all states, microcopy (ARB keys), acceptance checklist.
2. Phase 4-lite confirms the harness (already built: `RealFonts`, smoke capture).
3. Phase 5 builds the tokens/primitives the direction needs, with a gallery.
4. The mini Brief then rebuilds `dashboard_tab.dart` into region files and the
   kill list in `docs/audit-dashboard.md` §10 is executed.
