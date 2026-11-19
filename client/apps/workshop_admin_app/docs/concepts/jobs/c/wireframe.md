# Direction C — "The triage desk" (jobs queue)

**Signature idea:** the queue is a two-pane workbench — a priority-ordered rail
of jobs on the left, and the selected job's **next action** as the page's hero on
the right. Selection, not navigation, is the screen's state.

Prepared blind to directions A and B. Foundation is frozen: shell C "The dock",
the bay-window visual language, and the `CleanJob` object. Colour, radius and
type are not axes here.

Evidence:

```
lib/preview/jobs/direction_c.dart
test/jobs_direction_c_capture_test.dart
docs/evidence/jobs_directions/c-queue-1440.png       (1440 × 900, EN)
docs/evidence/jobs_directions/c-queue-390.png        (390 × 844, EN)
docs/evidence/jobs_directions/c-queue-1440-ar.png    (1440 × 900, ar / RTL)
```

Reproduce: `flutter test test/jobs_direction_c_capture_test.dart` (from
`client/apps/workshop_admin_app`). Real fonts are asserted loaded; the test
captures `takeException() == null` at every size and also proves row → summary
selection swaps without navigation, and that 1024 opens the summary sheet.

---

## 1. The job this screen answers

> *Within ten seconds, find the job that needs me next and start the action
> without leaving the queue.*

The user is a workshop manager at a desk. The queue is a work surface, not a
catalogue. So the screen answers three questions in order:

1. **Where am I?** The strip names the workshop once; the dock names Jobs.
2. **What matters?** The first row, then the selected job's next action as the
   largest text on the page.
3. **What next?** One labelled action (`Open review`, `Open publish checklist`,
   `View public link`, `Open job`).

The table was good at answering "what exists". It was bad at answering "what is
stuck / what do I do". This direction inverts that.

## 2. Wireframe — 1440 × 900 (two panes, 3 : 2)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ TR TrueReport │ Dubai Marina Workshop          العربية  🔔  LH              │ 44 strip
├──────────────────────────────────────────────────────────────────────────────┤
│ JOB QUEUE                                                                    │
│ Jobs                                             24 jobs in the workshop ·   │ header
│                                                  7 on this page  [+ New job] │
│                                                                              │
│ ┌─ Priority order ────────────[All jobs][Needs a decision] ────────────────┐ │
│ │ Sorted by the next action                                                │ │
│ ├──────────────────────────────────────────────────────────────────────────┤ │
│ │▎JOB-2026-0107 · Porsche 911 GT3                          Review          │ │ selected
│ │▎Rashid Al Mansoori · Karim Ahmed                       Pending review    │ │ row
│ ├──────────────────────────────────────────────────────────────────────────┤ │
│ │▎JOB-2026-0104 · Land Rover Defender 110                 Publish          │ │
│ │▎Sara Khalifa · Omar Haddad                               Approved        │ │
│ ├──────────────────────────────────────────────────────────────────────────┤ │
│ │▎JOB-2026-0098 · BMW X5                                   Rework           │ │
│ │▎Lina Farouk · Omar Haddad                                Rejected         │ │
│ ├──────────────────────────────────────────────────────────────────────────┤ │
│ │▎JOB-2026-0109 · Nissan Patrol                            Track            │ │
│ │▎Ahmed Al Marzouqi · Lina Farouk                          In progress      │ │
│ ├──────────────────────────────────────────────────────────────────────────┤ │
│ │▎JOB-2026-0102 · Toyota Land Cruiser                      Check            │ │
│ │▎Nadia Rahman · Yousef Karim                              Assigned         │ │
│ ├──────────────────────────────────────────────────────────────────────────┤ │
│ │▎JOB-2026-0111 · Mercedes-Benz G 63                       Finish           │ │
│ │▎Khalid Nasser · Unassigned                               Draft            │ │
│ ├──────────────────────────────────────────────────────────────────────────┤ │
│ │▎JOB-2026-0091 · Lexus LX 600                             View             │ │
│ │▎Mariam Al Suwaidi · Karim Ahmed                          Published        │ │
│ ├──────────────────────────────────────────────────────────────────────────┤ │
│ │ Selected 1 of 7                                    ↑ ↓ Use arrow keys     │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
│                                              ┌─ SELECTED JOB ──────────────┐ │
│                                              │ JOB-2026-0107  [Pending     │ │
│                                              │                 review]     │ │
│                                              │ NEXT ACTION                 │ │
│                                              │ Review the findings         │ │ 30 px
│                                              │ Karim Ahmed · Pre-purchase  │ │
│                                              │ inspection v3               │ │
│                                              │ ┌─────────────────────────┐ │ │
│                                              │ │ ✓ Open review           │ │ │ 46 px
│                                              │ └─────────────────────────┘ │ │
│                                              │ ─────────────────────────── │ │
│                                              │ Porsche 911 GT3             │ │
│                                              │ 2023 · DXB 48291            │ │
│                                              │ Customer      Technician    │ │
│                                              │ Rashid …      Karim Ahmed   │ │
│                                              │ Scheduled     Inspection    │ │
│                                              │ 19 Nov …      Pre-purchase… │ │
│                                              │ Odometer                    │ │
│                                              │ 18,240 km                   │ │
│                                              │ REVIEW & PUBLICATION        │ │
│                                              │ (Review · Pending review)   │ │
│                                              │ (Publication · Not published│ │
│                                              │ (Consent · Granted)         │ │
│                                              │ Scheduled times use the     │ │
│                                              │ workshop clock.             │ │
│                                              └─────────────────────────────┘ │
│                                              ~60 % list          ~40 % panel │
│                        ┌ Overview · [Jobs] · Staff · Templates · Board · ⚙ ┐│ dock
│                        └───────────────────────────────────────────────────┘│ 88 reserve
└──────────────────────────────────────────────────────────────────────────────┘
```

Row anatomy, left to right (mirrored in RTL):

```
▎ 3 px status rail  │  line 1: reference (LTR, tabular) · vehicle
                    │  line 2: customer · technician
                    │  trailing: next-action verb  /  status word
```

- The rail colour is the status tone **and** the status word is present, so the
  row is never colour-only.
- Selection is a 1 px accent outline + `accentSoft` fill, announced as
  `selected: true`. It is the single accent on the surface.
- The right verb is chosen by state, not by role: `Review`, `Publish`, `Rework`,
  `Track`, `Check`, `Finish`, `View`, `Assign`, `Open`.

## 3. Wireframe — 390 × 844 (one-card feed)

```
┌──────────────────────────────────────────────┐
│ TR Dubai Marina Workshop  العربية  🔔  LH    │ 44 strip
├──────────────────────────────────────────────┤
│ JOB QUEUE                                    │
│ Jobs                                      +  │
│ 24 in the workshop                           │
│  ‹    1 / 7    ›            Priority order   │ pager
│ ┌──────────────────────────────────────────┐ │
│ │ SELECTED JOB        [● Pending review]   │ │
│ │ JOB-2026-0107                            │ │
│ │ NEXT ACTION                              │ │
│ │ Review the findings                      │ │ 30 px
│ │ Karim Ahmed · Pre-purchase inspection v3 │ │
│ │ ──────────────────────────────────────── │ │
│ │ Porsche 911 GT3                          │ │
│ │ 2023 · DXB 48291                         │ │
│ │ Customer          Technician             │ │
│ │ Rashid …          Karim Ahmed            │ │
│ │ Scheduled         Inspection             │ │
│ │ 19 Nov …          Pre-purchase … v3      │ │
│ │ Odometer                                 │ │
│ │ 18,240 km                                │ │
│ │ REVIEW & PUBLICATION                     │ │
│ │ Review            ● Pending review       │ │
│ │ Publication       ● Not published        │ │
│ │ Consent           ● Granted              │ │
│ └──────────────────────────────────────────┘ │ card (scrolls)
│ ┌──────────────────────────────────────────┐ │
│ │             ✓ Open review                │ │ sticky action
│ └──────────────────────────────────────────┘ │ 58
│        ┌ [Overview] [Jobs] Staff … ⚙ ┐       │ dock
└──────────────────────────────────────────────┘ 78 reserve
```

The feed is a real horizontal `PageView`: swipe, the arrows, or the pager moves
the selection; the sticky bar always acts on the visible card. The card leads
with the next action, then identity, facts, review/publication/consent, so the
hero survives the small screen.

## 4. Structural departures from the flat table

1. **No table header and no aligned columns.** A row is two lines and an
   affordance; comparison across rows is by reading, not by column.
2. **Status is structure, not a filter.** A status rail sorts the eye down the
   list; there is no chip row that hides every other status.
3. **The ambiguous counts are gone.** The old four chips counted the search
   scope and collided with dashboard labels. The header says one qualified
   sentence: *24 jobs in the workshop · 7 on this page*.
4. **The list row is a selector, not a link.** A click swaps the summary in
   place. It never opens the legacy quick sheet.
5. **One persistent summary with the real lifecycle facts** (review status,
   publication status, consent) and exactly **one primary action**. No secondary
   action competes with the hero.
6. **The order is a designed priority order**, not `created_at DESC`. Decision
   states first (`PENDING_REVIEW`, `APPROVED`, `REJECTED`), then work in flight,
   then draft, then archive.
7. **The footer describes selection**, not "Total: N": *Selected 1 of 7 · ↑ ↓
   Use arrow keys*.
8. **One object.** Everything is built from `CleanJob`; no `WorkshopJob`
   vocabulary or legacy widget is imported.
9. **Publication vocabulary is fixed.** `UNPUBLISHED → Not published`,
   `PUBLISHED → Published`, `REVOKED → Revoked`; the chip no longer tests
   `ACTIVE` on the job field.
10. **Consent is visible and honest.** An approved job without consent says
    *Publication is blocked* and explains why, instead of offering a publish
    path that the server will reject.

## 5. Selection and keyboard behaviour

| Input | Behaviour |
|---|---|
| Load | first visible row selected; summary already populated (no empty right pane) |
| Click / tap a row | selects it; summary swaps in place (180 ms fade + 2 % rise). At 1024 it also opens the summary sheet |
| Focus a row (Tab) | focusing selects, so keyboard and pointer cannot disagree |
| `↑` / `↓` | previous / next visible row; focus follows selection |
| `Home` / `End` | first / last visible row |
| Focus ring | the selected row's accent outline is the visible focus; no second ring colour |
| Filter change | selection is kept if the job survives; otherwise the first visible row is selected; if the result is empty, selection is cleared and the summary shows a placeholder |
| No hidden shortcut | `Enter` is deliberately unbound; the action is a labelled 46 px button reached with Tab |

`Semantics`: each row is `button: true`, `selected: <bool>`, with
`"reference, vehicle, customer, status"` as its label. The status rail is
decorative inside the row's single semantic node. The summary is a container;
the action button carries its own label.

## 6. Per-breakpoint behaviour

| Content width | Layout |
|---|---|
| ≥ 1100 (two panes) | 3 : 2 split, 24 px gap. List and summary are both white hairline cards with no shadow. The summary pane is a `SingleChildScrollView`; the list gets its own scroll, so neither pane can overflow the shell. |
| 680–1099 | the list takes the width; the first row is still selected. Tapping a row opens a modal bottom sheet (max 86 % of the viewport height) with the same summary panel and primary action. The sheet mirrors the row selection; dismissing keeps it. |
| < 680 | one-card `PageView` feed with pager arrows and a position counter (`1 / 7`); a sticky bottom action bar sits above the shell's reserved dock band. Card content scrolls independently. |
| RTL | the row rail moves to the right, the trailing affordance to the left, the pager arrows mirror, and the sheet handle is centred. Identifiers (reference, plate, year, counter) stay LTR; names follow the ambient direction. |
| Text scale | type sizes come from the frozen tokens; no fixed-height row, so rows grow instead of clipping. The sheet and feed scroll. |

The shell owns the 44 px strip and the 88 / 78 px bottom reserve; the screen
never adds its own dock padding.

## 7. States

| State | What the user sees |
|---|---|
| **Loading** | seven skeleton rows in the real rail geometry on the left; a skeleton summary on the right. No counts, no numbers, no fake rows. |
| **Empty (first use)** | bounded empty state inside the list card: one sentence and `New job`; the summary pane says *Select a job*. Never a full-page takeover. |
| **Error** | bounded `WorkshopErrorState` per pane with Retry; the other pane still renders if it has data; no number is shown from a failed response. |
| **Filtered empty** | *No job in this view* + `Show all jobs`; the summary is cleared to a placeholder. No "0 jobs" claim about the workshop. |
| **Selection cleared** | selection id is `null`; the summary placeholder explains how to get back (clear the filter). On phone the feed is replaced by the same bounded empty card. |
| **Unknown status** | rendered as *Unknown status* with a neutral rail — never the raw enum code. Unknown review/publication values do the same. |
| **Consent blocked** | approved + `consentGranted == false`: hero becomes *Publication is blocked*, with the reason; the action still opens the checklist (where the state is explained), it does not promise a publish. |
| **Nightly / dark** | out of scope: the app is light-only (waiver W-LIGHT). |
| **Reduced motion** | the 140 ms row fill and 180 ms summary swap become zero via `context.motionDuration`; no looping animation. |

## 8. Data honesty

Rows are constructed from the `CleanJob` shape and values in
`docs/data/samples/clean-jobs-page.json`; counts are the sample
`clean-job-counts.json` total. The preview shows exactly what §8.1 allows:

- shown: `reference`, clean `status`, `reviewStatus`, `publicationStatus`,
  `customerName`, `assignedTechnicianName`, `vehicleMake/Model/Year/Plate`,
  `scheduledAt` (user-picked), `templateNameEn/Ar`, `templateVersionNo`,
  `odometerValue/Unit`, `consentGranted`, `score`, `gradeCode`.
- qualified: **24** is the workshop-wide `total`; **7 on this page** is the
  page, not a total. There are no status-count chips (the counts endpoint takes
  no search parameter), no "today", no "active jobs", no derived percentage.
- no server timestamp is shown: `scheduledAt` is the user-picked class and is
  footnoted *Scheduled times use the workshop clock*. `createdAt`,
  `completedAt`, `approvedAt`, `publishedAt`, `updatedAt` are not displayed
  (G-J18: naive UTC wall time would render 4 h early).
- `UNPUBLISHED` is rendered as *Not published* (G-J2 fixed in the preview).
- absent values read *Unassigned*, *Not scheduled*, *—*; never `0`.

## 9. Trade-off (accepted)

- **Less scannable than a table.** There is no aligned vehicle / customer /
  schedule column to sweep. Two-line rows compress plate, year and VIN out of
  the row; they live in the summary. Comparing three jobs means reading three
  rows, not comparing a column.
- **Selection state to maintain.** One selected id must survive filtering,
  paging and responsive re-layout, and stay in sync with keyboard focus and the
  1024 sheet. Filtering can clear it; the placeholder is the cost of not showing
  a stale summary.
- **Width cost.** 40 % of the content is one job. At 1024 the summary becomes a
  modal, so cross-row triage is slower there than at 1440.
- **One action at a time.** No bulk actions; the desk is for deciding, not for
  batch editing.
- **Page-level priority order is a risk.** The server's only order is
  `created_at DESC` over one page. Sorting the loaded page does **not** prove
  the most urgent job in the workshop is on it. Production needs a server sort
  or one query per status bucket before this ordering can claim to be complete;
  the preview shows `7 on this page` rather than pretending otherwise.
- **Rows are illustrative sample values**, not live data. The shape is exact;
  the values are the sample shapes required for Gate 3 evidence.

## 10. What is deliberately not shown (MISSING fields / claims)

| Not shown | Why |
|---|---|
| Signature state on the job | `CleanJob` does not map `signaturePresent` (G-J7). |
| Technician workload / capacity / utilisation | No aggregate exists (§8.2); a "load" rail would be invented. |
| Age, waiting time, SLA, turnaround, duration | Not modelled; server timestamps are also unreliable (G-J18). |
| "Next appointment" or schedule ordering | No such ordering exists (J21); the priority order is status-based and says so. |
| "Today" / "this week" / windowed counts | No windowed counts endpoint. |
| Status-count chips | `GET /jobs/counts` takes no search/status parameter, so chips would disagree with the rows (G-J20). |
| Unread notification badge | No unread count endpoint (G-J15); the bell is present with no number. |
| "Documents ready" / "PDF available" | The checklist constant is not a readiness fact (G-J5). |
| "Publish now" success | Consent has no updater (G-J1). The blocked state is shown instead. |
| Report action for a published job | The clean report path does not exist (G-J8); the action is *View public link*. |
| Customer/vehicle type-ahead or customer search | No directory endpoint in scope (G-J27); the queue has no search box at all. |
| Assignment history / assigned-by | `JobAssignment.technicianName` is dropped by the model (G-J4); only the current technician is shown. |
| Raw enum codes, raw ISO strings, `items.length` as a total | Contract rule §6.1. |

## 11. Microcopy (English / Arabic)

| Slot | EN | AR |
|---|---|---|
| Page title | Jobs | المهام |
| Eyebrow | JOB QUEUE | قائمة المهام |
| Count qualifier | 24 jobs in the workshop · 7 on this page | 24 مهمة في الورشة · 7 في هذه الصفحة |
| List heading | Priority order / Sorted by the next action | ترتيب الأولوية / مرتبة حسب الإجراء التالي |
| Filters | All jobs · Needs a decision | كل المهام · تحتاج قرارًا |
| Hero | Review the findings · Ready to publish · Publication is blocked | راجع النتائج · جاهز للنشر · النشر متوقف |
| Action | Open review / Open publish checklist / View public link / Open job | فتح المراجعة / فتح قائمة النشر / عرض الرابط العام / فتح المهمة |
| Footer | Selected 1 of 7 · Use arrow keys to move | المختارة 1 من 7 · استخدم الأسهم للتنقل |
| Consent block | Publishing needs the customer's consent. This record has none. | يتطلب النشر موافقة العميل. لا توجد موافقة لهذا السجل. |
| Filtered empty | No job in this view / Clear the filter to bring the queue back. | لا توجد مهمة في هذا العرض / امسح عامل التصفية لإعادة القائمة. |

## 12. Self-check against the gate

1. Rendered inside the **real** `WorkshopAppShell` (six destinations,
   `selectedIndex: 1`, notification action, account name/email/initials) with
   7 real rows and a populated summary. ✔
2. Real fonts asserted; 1440 / 390 / 1440 AR captured; `takeException() == null`
   at each size. ✔
3. Tokens and primitives only; no raw colour, no new type size; no legacy job
   widget imported. ✔
4. Selection is the state: first row selected on load; click and arrows swap the
   summary in place; 1024 opens it as a sheet; 390 is a card feed with a sticky
   action. ✔
5. Every shown field is in §8.1; every missing one is listed above. ✔
6. Trade-off written, not hidden. ✔
