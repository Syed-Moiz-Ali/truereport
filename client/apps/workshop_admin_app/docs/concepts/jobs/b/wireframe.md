# Jobs queue — direction B, "The lanes"

Design proof for the module's reference screen. Foundation (shell C "The dock",
"bay window" language, tokens) is frozen and untouched; this direction only
changes the queue's geometry and the object it opens.

Files: `lib/preview/jobs/direction_b.dart`,
`test/jobs_direction_b_capture_test.dart`.
Evidence: `docs/evidence/jobs_directions/b-queue-1440.png`, `b-queue-390.png`,
`b-queue-1440-ar.png`.

---

## 1. Signature idea

**The lifecycle is the layout.** Status stops being a chip you filter by and
becomes the four columns the work physically sits in. You do not read "what is
stuck" out of a sorted table — you look at the lane that is filling up.

A card lifts (accent hairline + `accentSoft` tint + a 3 px accent rail on its
leading edge, 180 ms) and the detail pane beside the lanes becomes that job,
including the one thing the row never said: **what happens next in this lane**.

---

## 2. Wireframe — 1440 × 900

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ TR TrueReport │ Al Quoz Auto Works                     العربية   🔔   SM          │ 44
├──────────────────────────────────────────────────────────────────────────────────┤
│  Jobs                                                                            │
│  24 jobs in this workshop · 1 outside the lanes                                  │
│  ┌ Search jobs ────────────┐  Lane counts cover the whole workshop,   [ + New job]│
│                              not the search.                                     │
│                                                                                  │
│  01 Scheduled & assigned  3 │ 02 In progress      3 │ 03 Pending review 4 │ 04 Approved & published 13
│  Scheduled or assigned —    │ Started — checklist   │ Submitted — needs  │ Approved — ready for
│  not started                │ with the technician   │ a decision         │ the client
│  ═══════════════════════════╪═══════════════════════╪════════════════════╪══════════════════
│ ┌─────────────────────────┐ │ ┌───────────────────┐ │ ┌────────────────┐ │ ┌──────────────┐
│ │ JOB-2026-0112       2d  │ │ │ JOB-2026-0108  1d │ │ │ JOB-2026-0107  │ │ │ JOB-2026-0099│
│ │ 2024 Toyota Land        │ │ │ 2021 BMW X5       │ │ │ 2023 Porsche   │ │ │ 2021 Audi RS 6
│ │ Cruiser                 │ │ │ 2021 · DXB 44120  │ │ │ 911 GT3        │ │ │ 2021·DXB51264│
│ │ 2024 · DXB 55210        │ │ │ Noora Al Suwaidi  │ │ │ 2023·DXB 48291 │ │ │ Layla Al Ham.│
│ │ Fatima Al Zaabi         │ │ │ ⏱ 3h ago          │ │ │ Rashid Al Man. │ │ │ ⏱ 2d ago     │
│ │ ⏱ Tomorrow, 09:00       │ │ │ 👤 Karim Ahmed    │ │ │ ⏱ 21h ago      │ │ │ 👤 Yusuf A.  │
│ │ 👤 Hana Yousef          │ │ │ ● In progress     │ │ │ 👤 Karim Ahmed │ │ │ ● Approved   │
│ │ ● Scheduled             │ │ └───────────────────┘ │ │ ● Pending rev. │ │ └──────────────┘
│ └─────────────────────────┘ │ ┌───────────────────┐ │ └────────────────┘ │ ┌──────────────┐
│ ┌─────────────────────────┐ │ │ JOB-2026-0106  2d │ │ ┌────────────────┐ │ │ JOB-2026-0094│
│ │ JOB-2026-0111       1d  │ │ │ 2020 Nissan Patrol│ │ │ JOB-2026-0103  │ │ │ …            │
│ │ 2022 Mercedes-Benz G 63 │ │ │ …                 │ │ │ …              │ │ └──────────────┘
│ └─────────────────────────┘ │ └───────────────────┘ │ └────────────────┘ │
│ Showing 2 of 3              │ Showing 2 of 3        │ Showing 2 of 4      │ Showing 2 of 13
│                                                      ┌─────────────────────────────┐
│  (detail pane, 300 wide, spans the lane area)        │ SELECTED JOB                │
│                                                      │ 2023 Porsche 911 GT3        │
│                                                      │ JOB-2026-0107   DXB 48291   │
│                                                      │ ● Pending review            │
│                                                      │ → Waiting for your decision │
│                                                      │ [ Review job ]              │
│                                                      │ Client link: not published  │
│                                                      │ Customer   Rashid Al Man.   │
│                                                      │ Phone      +971 50 000 0000 │
│                                                      │ Technician Karim Ahmed      │
│                                                      │ Scheduled  Yesterday, 10:00 │
│                                                      │ Template   Pre-purchase v3  │
│                                                      │ Created    3d ago           │
│                                                      │ WHY IT IS IN THIS LANE      │
│                                                      │ Every job that was submitted│
│                                                      │ and is waiting for a manager│
│                                                      └─────────────────────────────┘
│                      ┌ Overview · Jobs · Staff · Templates · Board · Settings ─┐  │ 88 reserve
└──────────────────────────────────────────────────────────────────────────────────┘
```

Content column is capped at 1200 with 32 px gutters, so the board does not
stretch on a 1600 monitor. Lanes are equal-width columns separated by 1 px
hairlines — no boxes around lanes, one bordered surface per card.

## 3. Wireframe — 390 × 844

```
┌──────────────────────────────────┐
│ TR Al Quoz Auto Works  ع  🔔  SM  │ 44
├──────────────────────────────────┤
│ Jobs                             │
│ 24 jobs in this workshop · 1 outside the lanes
│ ┌ Search jobs ─────────────────┐ │
│ └──────────────────────────────┘ │
│ [          + New job           ] │
│ ┌───────┬───────┬───────┬──────┐ │
│ │   3   │   3   │   4   │  13  │ │ segmented = the four lanes
│ │Sched. │In pr. │Review │Appr. │ │ 44
│ └───────┴───────┴───────┴──────┘ │
│ ┌──────────────────────────────┐ │
│ │ JOB-2026-0107           3d   │ │
│ │ 2023 Porsche 911 GT3         │ │
│ │ 2023 · DXB 48291             │ │
│ │ Rashid Al Mansoori           │ │
│ │ ⏱ 21h ago  👤 Karim Ahmed    │ │
│ │ ● Pending review             │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ JOB-2026-0103           4d   │ │  second card fully above the bar
│ │ 2019 Lexus LX 600 …          │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ JOB-2026-0107                │ │ action bar for the selected card
│ │ Porsche 911 GT3              │ │
│ │ Client link: not published   │ │ [ Review job ]
│ └──────────────────────────────┘ │
│      ┌ dock: overview · Jobs · … ┐│ 78 reserve
└──────────────────────────────────┘
```

The action bar is a sibling of the feed inside the content region, not an
overlay: the shell's 78 px dock reserve keeps both visible without stacking two
floating surfaces.

---

## 4. Lanes, predicates and where the counts come from

| # | Lane | Predicate, on screen | Full predicate (tooltip + semantics) | Count source |
|---|---|---|---|---|
| 01 | Scheduled & assigned | Scheduled or assigned — not started | Every job that is scheduled or assigned to a technician and has not started. | `counts.scheduled + counts.assigned` |
| 02 | In progress | Started — checklist with the technician | Every job the technician has started and not yet submitted. | `counts.inProgress` |
| 03 | Pending review | Submitted — needs a decision | Every job that was submitted and is waiting for a manager to approve or reject. | `counts.pendingReview` |
| 04 | Approved & published | Approved — ready for the client | Every approved job, published to the client or still waiting to be published. | `counts.approved + counts.published` |

**Source:** `GET /workshop/jobs/counts` (`CleanJobCounts`) — workshop-wide, no
search and no status parameter (`WorkshopJobAdminController:86-89`). That is
exactly why the lane header may show `4` while the lane holds two cards: the
header is the workshop, the cards are a page. Every lane states it
(`Showing 2 of 4`) at the wide board.

**The lanes partition `total` and the remainder is named.** With the sample
partition (`docs/data/samples/clean-job-counts.json`):

```
2 scheduled + 1 assigned + 3 in progress + 4 pending review
+ 2 approved + 11 published + 1 rejected + 0 cancelled = 24 = total
└────────── lanes: 23 ──────────┘   └─ outside: 1 ─┘
```

`rejected`, `cancelled` and `draft` have no lane (a rejected job is not
"pending" anything; a cancelled one is not work in flight). The page's subtitle
says so in words — `24 jobs in this workshop · 1 outside the lanes` — and its
semantics label names the remainder's composition. `draft` is included in that
computation even though the sample has none, so a draft-heavy workshop cannot
silently break the arithmetic.

No count is ever `items.length`. No `+10 more` is invented: the footer reads
`Showing 2 of 13` because 2 cards are rendered and 13 is the server's number.

**Vocabulary:** the direction was briefed as "Waiting review"; the lane ships as
**Pending review**, the status label the card's own badge uses
(`jobStatusLabel`). One word per concept beats matching the brief's prose.

---

## 5. Structural departures from today's flat table

1. **Status is structure, not a filter.** The table could show one status at a
   time; the four lanes are on screen together, so "what is stuck?" is answered
   by looking, not by clicking four chips.
2. **Chips are gone.** Lanes replace `All / In progress / Ready / Finalized`;
   there is no search-scoped count anywhere on the screen, so the dashboard and
   the queue can no longer disagree about "In progress" (X1 / D2 / J5).
3. **Counts are the workshop's, and the remainder is printed.** Every number
   traces to `GET /jobs/counts`; the one population without a lane is named.
4. **The card says age and owner.** Reference, created age, the lane's own
   moment (scheduled / started / completed / published), technician and badge —
   the row showed what, never how long or whose.
5. **Selection opens the clean object.** Selecting a card fills a pane built
   from `CleanJob`; there is no legacy `WorkshopJob`, no quick sheet, no second
   id space (`jobs_inventory` D3 / J1, `design_decision.md` "one job object").
6. **The primary action is lane-specific.** Review job · Assign technician ·
   Open job · Publish checklist. The default "Publish checklist" for every
   status (DT44, G-J21) is not reproduced.
7. **The camera is the board.** The header is two lines and one toolbar; nothing
   above the lanes is allowed to grow with content.
8. **No second identity.** Workshop name appears once, in the frozen strip.

---

## 6. Behaviour per breakpoint

| Width | Composition | Why |
|---|---|---|
| **≥ 1280** | Four equal lane columns (≈200 px each) + 300 px detail pane at the trailing edge, both full height. Lane footers `Showing X of Y` pinned to one baseline. | All four lanes are comparable in one glance; the pane is a peer of the board, not a modal. |
| **680 – 1279** | Lanes become a horizontal list of 262 px columns; the selected job's detail is a full-width sheet (214 px) under the lanes. | Four columns would be unreadable at 1024; horizontal travel is honest, and the sheet keeps list + detail on one screen. |
| **< 680** | Segmented control (four lanes, count above name) over a single vertical feed, plus a bottom action bar for the selected card. | Four columns on a phone is a grid of unreadable slivers. One lane at a time, chosen by the same four predicates. |
| **RTL (any)** | Whole composition mirrors: lane 1 at the right, pane at the leading edge, segmented order reversed, dock mirrored. Vehicle titles, references, plates and phone numbers are pinned LTR (a mirrored `2023 Porsche 911 GT3` read `Porsche 911 GT3 2023`). | Parity, not a second layout. |

Motion: one 180 ms border/tint settle on selection. Nothing loops. Reduced
motion zeroes the duration through `context.motionDuration`.

---

## 7. States

| State | Treatment |
|---|---|
| **Loading** | Lane headers render with their predicate and a skeleton count; two card skeletons per lane (`WorkshopSkeleton` shape, not a spinner). The board keeps its geometry so the page does not jump when data lands. |
| **Empty workshop** | Lanes keep their headers at `0` and the lane area shows one bounded `WorkshopEmptyState`: "No jobs yet" + **New job**. The lifecycle map stays on screen — the empty state is inside the board, never instead of it. |
| **Empty lane** | Header stays with `0` and a one-line "Nothing here" inside the column. Collapsing the column would delete the map. |
| **Error** | Counts and rows fail independently. A failed count prints `—` in the header (never `0`, which would be a claim) and a bounded inline error strip above the lanes offers Retry; a failed page shows `WorkshopErrorState` inside each lane body. Never a full-page takeover. |
| **Filtered empty** | Search narrows the cards, not the headers. The lane stays with its count, the body says "No job in this lane matches *plate*", and a **Clear search** action is offered once (not per lane). |
| **Selected** | Accent hairline + `accentSoft` tint + 3 px leading rail; `Semantics(selected: true)`. The pane always shows a selection: the last selected card, else the first card of the current lane, so there is no empty pane state to design. |
| **Long names / large text** | Vehicle titles wrap to two lines, customer names to two, facts to three; identity is never ellipsized. At 1.5×/2× the lanes scroll and the card grows — no fixed card height. |

---

## 8. Trade-offs this direction accepts

1. **Horizontal travel.** At 1440 the four lanes are one sweep; at 1024 the
   fourth lane is only partly visible and the user must scroll the lanes
   sideways (or shrink to the phone model, where only one lane is on screen).
   The header count of the hidden lane is not visible while it is off-screen —
   a filter-chip row would have kept all four numbers visible.
2. **Lane height variance.** Cards are content-height (a two-line vehicle title
   adds 22 px), so the same vertical position means different ages across lanes;
   only the headers and the footers align. Comparing "oldest thing in each lane"
   needs a skim, not a fixed row.
3. **Counts above a page.** A header may say `13` over one card. That is honest
   but it costs a beat: the reader must accept that the lane is a window.
   Mitigated by `Showing 2 of 13` and by never summing cards into a total.
4. **One lane at a time on a phone.** Comparison between lanes becomes memory
   (four counts in the segmented control) instead of sight.
5. **Cards are not sortable or bulk-selectable.** A board optimises "where is
   the work"; it gives up the table's column sort and row multi-select. The
   detail page (or a later table view) has to carry those.

---

## 9. What is deliberately **not** shown — the field is MISSING

Every omission below is a missing field or a missing definition, not a styling
choice (`docs/data/jobs_inventory.md` §8.2, gaps G-J…):

| Not shown | Why | Would have been |
|---|---|---|
| Priority / urgency / triage flag | no field on the clean DTO | a leading rail on the card |
| Due date, promised completion, "days late" | not modelled; `scheduledAt` is an appointment, not a deadline | an overdue tone on the card |
| Elapsed time in lane / waiting time / turnaround | no state-transition timestamps exposed on the job (`startedAt`/`completedAt` exist, but no `enteredLaneAt`) | "waiting 2d in review" |
| SLA / breach badge | no SLA exists; inventing one would be a claim | a warning count per lane |
| Technician workload, capacity, utilisation | no aggregate endpoint (`§8.2`) | load dots beside the avatar |
| Bay / lift / bay occupancy | not modelled | a lane-by-bay grid |
| Findings count, photo/video counts, issue values | mapper reads the wrong types — always 0 today (G-J3 / X7) | "12 of 24 items" on the card |
| Score / grade before approval | null until approve; the sample's `82/B` on a pending job is an inconsistency, so it is not rendered | a score chip in the pane |
| Tags, notes, customer history | not modelled | chips under the customer |
| "Next appointment" ordering | the API orders by `created_at`, not schedule (BD14) | the lane sorted by time |
| Unread notification count | no count endpoint (G-J15) | a badge on the bell |
| "Documents ready" / PDF availability | constant `true` server-side (G-J5); "Download" copies a path (G-J6) | a document row in the pane |

The pane instead stops at `Client link: not published`, which maps
`publicationStatus` honestly (`UNPUBLISHED / PUBLISHED / REVOKED`), instead of
the buggy `ACTIVE` test (G-J2).

---

## 10. Accessibility

- Lane header: `Semantics(container: true, label: "<name>, <count>. <full
  predicate>")`, `excludeSemantics` on the decorative parts; the count is
  tabular and pinned LTR.
- Card: one `button` node, `selected` when chosen, label =
  vehicle · reference · customer · status · lane moment. The visual content is
  `ExcludeSemantics`d so nothing is announced twice.
- Segments: full lane name and count in the label, `selected` announced; the
  visible short label ("Review") never becomes the accessible name.
- Facts: each is `label: value` as one node, so a screen reader does not read
  two disconnected fragments.
- Focus: the accent hairline doubles as the focus ring's neighbour; keyboard
  focus paints `shadows.focusRing`. Order: header → toolbar → lanes (leading to
  trailing) → detail pane → dock.
- Status is never colour-only (dot + text in every badge); the selected card is
  not colour-only (rail + border + semantics).
- Contrast: `ink` on `surface`, `muted` on `surface`/`canvas`, `accent` on
  `accentSoft` — all token pairs already in use across the app; no new colours
  and no `Color(0x…)` anywhere in the preview.

---

## 11. Microcopy (EN / AR)

| Slot | EN | AR |
|---|---|---|
| Subtitle | 24 jobs in this workshop · 1 outside the lanes | 24 مهمة في هذه الورشة · 1 خارج المسارات |
| Count scoping | Lane counts cover the whole workshop, not the search. | أعداد المسارات للورشة كاملة، وليست نتيجة البحث. |
| Lane 1 | Scheduled & assigned · Scheduled or assigned — not started | مجدولة ومسندة · مجدولة أو مسندة — لم تبدأ |
| Lane 2 | In progress · Started — checklist with the technician | قيد التنفيذ · بدأت — القائمة مع الفني |
| Lane 3 | Pending review · Submitted — needs a decision | بانتظار المراجعة · أُرسلت — تحتاج قرارًا |
| Lane 4 | Approved & published · Approved — ready for the client | معتمدة ومنشورة · معتمدة — جاهزة للعميل |
| Next action | Waiting for your decision — review, then approve or reject. | بانتظار قرارك — راجع ثم اعتمد أو ارفض. |
| Window | Showing 2 of 13 | عرض 2 من 13 |
| Lane footnote | Why it is in this lane | لماذا في هذا المسار |

Relative times are written, not formatted from ISO: `21h ago` / `قبل 21 ساعة`,
`2d ago` / `قبل يومين` (dual and 3–10 plurals handled). `Today/Yesterday/
Tomorrow, HH:mm` for appointments. No raw ISO string appears anywhere.

---

## 12. Verification

```
flutter test test/jobs_direction_b_capture_test.dart   # 5 tests, all pass
flutter analyze --fatal-infos                          # clean
```

The capture test asserts, at every captured size, that
`tester.takeException()` is null, that the real fonts are loaded, that the six
shell destinations and the notification action exist, that four lanes and eight
`CleanJob` cards are built at 1440, and that each PNG is a real (>20 KB) frame:

| File | Size |
|---|---|
| `docs/evidence/jobs_directions/b-queue-1440.png` | 183 KB |
| `docs/evidence/jobs_directions/b-queue-390.png` | 57 KB |
| `docs/evidence/jobs_directions/b-queue-1440-ar.png` | 176 KB |

Two review rounds changed the following, both found in the captures: Arabic
reordered `2023 Porsche 911 GT3` into `Porsche 911 GT3 2023` (vehicle titles are
now pinned LTR), and the detail pane clipped its last fact at 900 px (facts are
now label/value rows). A third round balanced the lanes to two cards each so no
column was left with a 200 px void, pinned the `Showing X of Y` footers to one
baseline, and tightened the phone stack so both visible cards clear the action
bar.
