# UI brief — Workshop dashboard, direction B "The floor"

Chosen at Gate 3 (user, 2026-11-18) from `docs/dashboard_directions.md`.
This document is the build contract. The existing `dashboard_tab.dart` is a
requirements document, not a starting point: read it for data and invariants,
then compose from here.

---

## 1. Product feeling

A printed operations sheet come to life: one enormous number, one full-width
partition, three honest lists. Quiet, factual, and instantly readable from two
metres away. Nothing decorated for its own sake; no card inside a card.

**Signature idea (committed):** *the partition is the page.* One nine-segment bar
spans the full content width; its segments are the nine real statuses; the
numbers under it are the same numbers inside it; the total is the largest object
on screen.

## 2. Anti-goals

- No stat-card grid; no card containing a header containing a list.
- No metric that is derived, overlapping, or windowed unless the API supplies it
  (so: no "Active jobs", no "Finalized today", no "New & scheduled").
- No "Next up", no "today", no "this week" — the API has no time ordering or
  window. `J21`.
- No quick-actions module (the shell already navigates to every tab).
- No second primary action. "New job" is the only filled button on the page.
- No dark theme (W-LIGHT). No new routes. No shell edits (write-locked).
- No animated number counters, no parallax, no decorative illustration.

## 3. The hero moment

The eye lands on `24` (or whatever the total is) at 76 px, then follows the
words "jobs on the floor" and the one sentence that makes it personal:
**"4 are waiting for your decision."** That sentence is the page's reason to
exist; when it is zero, the sentence changes to a calm, honest "Nothing is
waiting for your decision."

## 4. Information architecture

```
Eyebrow            workshop name · "every job on the floor"
Hero               76 px total + "jobs on the floor" + decision sentence
                    + [New job]  (right-aligned at ≥900, below title at <900)
Atlas              full-width 64 px partition (≥900) / 10 px per-stage spine (<900)
                   stage labels with counts beneath each segment (≥900)
                   **amended after Gate 6:** the labels are a legend sized to
                   content, not a positional ruler under each segment
                   explicit remainder handling if buckets ≠ total
Groups             Waiting for you (pendingReview)  · rows + Review verb
                   In the bay (assigned + inProgress) · rows
                   Ready to publish (approved + published) · rows + Publish/Open
Footer             "Every segment is a status count. They sum to 24." + total
```

**Flows** (step counts are the acceptance measure):

| Flow | Steps | Notes |
|---|---|---|
| Read the state of the workshop | 1 glance at the total | no scroll at 1440 |
| Find work that needs a decision | ≤1 scroll / 0 taps | group is above the fold at 1440 |
| Open the job that needs a decision | tap row (1) → **job detail page** | **Amended during the build:** the legacy quick sheet (`showJobQuickSheet`) accepts only `WorkshopJob` from `inspection_jobs`, which J19 excludes. The detail page is the clean-world surface and carries the same actions (reassign, cancel, report). See `docs/waivers.md` W-ROWOPEN. |
| Open a review | tap `Review` (1) | `Review` is a text verb, not a second filled button |
| Create a job | tap New job (1) → wizard | unchanged route |
| Understand an unfamiliar number | read its legend entry | every status is labelled with its count |

## 5. Data contract (from `docs/data/dashboard_inventory.md`)

| Surface | Source | Rule |
|---|---|---|
| Total | `cleanJobCountsProvider.total` | never derived client-side |
| Nine segments | the nine fields of `CleanJobCounts` | order fixed: draft, scheduled, assigned, inProgress, pendingReview, approved, published, rejected, cancelled |
| Decision sentence | `pendingReview` | "N waiting for your decision" / "Nothing is waiting for your decision" |
| Waiting for you rows | `cleanJobsProvider(status: PENDING_REVIEW, size: 5)` | newest first |
| In the bay rows | `cleanJobsProvider(status: IN_PROGRESS, size: 3)` | newest first |
| Ready to publish rows | `cleanJobsProvider(status: APPROVED, size: 3)` | newest first |
| Row action | status → verb | PENDING_REVIEW → Review; APPROVED → Publish; PUBLISHED → Open; others → none |
| Remainder | `total − sum(nine)` | if > 0, render a final neutral segment labelled "Other" so the bar still equals the total |

Counts and lists are **independent** async values: either may fail alone
(partial state). A failed counts call never hides the lists and vice versa.

## 6. Layout per breakpoint

**Amended during the build:** breakpoints are computed from the width the page is
*given*, not the window width. The shell's sidebar takes 256 px at desktop, so a
1024 px window hands the page 768 px. The bands below are content widths.

| Content width | Composition |
|---|---|
| **≥1000** (≈1440/1280 window) | gutter 40. Hero row: numeral + words left, New job right. Atlas 64 px full content width; legend wraps to content. Groups: 6/4 split — "Waiting for you" left; "In the bay" and "Ready to publish" stacked right. |
| **820–999** (≈1280 window without sidebar) | identical, numeral 64, atlas 56, groups 6/4. |
| **640–819** (≈1024 window) | numeral 56, atlas 48, groups 1 column ("In the bay" then "Ready to publish" full width). Legend is a content-sized wrap and may take 2 rows. |
| **520–639** | numeral 48, **vertical spine** replaces the bar, groups 1 column, gutter 24. |
| **<520** | numeral 40, gutter 16, New job full width under the hero text, spine rows wrap their label, verb on its own line. |

## 7. States (all must exist)

| State | Hero | Atlas | Groups |
|---|---|---|---|
| **Loading** | skeleton bar where the numeral is (never a placeholder number) | hidden until counts arrive (a hollow bar reads as zero) | 2 skeleton rows per group |
| **Ready** | total + sentence | 9 segments + labels | rows |
| **Empty workshop** (`total == 0`) | "No jobs on the floor" + one sentence inviting the first job | hidden (nothing to partition) | single empty state with New job; not three empty groups |
| **Counts error, lists ready** | numeral replaced by an inline error + Retry | hidden, replaced by a one-line note | rows render normally |
| **Lists error, counts ready** | normal | normal | the failing group shows a bounded inline error + Retry; other groups unaffected |
| **Both error** | inline error + Retry | hidden | each failing region reports once, with its own Retry |
| **Partial group empty** | normal | normal | "Nothing waiting" row for that group only |
| **Remainder > 0** | normal | extra "Other N" segment appended, total unchanged | normal |
| **No session** | eyebrow without workshop name; no greeting name | normal | normal |
| **Offline** | same as both-error (no separate banner in scope) | — | — |
| **Text scale 1.5 / 2.0** | numeral scales, never clips | labels wrap to 2 lines max, then ellipsis | rows grow; no overflow |
| **RTL (ar)** | mirrored order; numeral LTR-pinned; atlas order mirrored (draft on the right) | labels RTL | verbs mirrored |

## 8. Microcopy (ARB keys to add — never rewrite existing keys)

| Key | en | ar |
|---|---|---|
| `dashFloorTotal` | `{count, plural, =1{1 job on the floor} other{{count} jobs on the floor}}` | `{count, plural, =1{مهمة واحدة في الورشة} other{{count} مهمة في الورشة}}` |
| `dashDecisionWaiting` | `{count, plural, =1{1 is waiting for your decision} other{{count} are waiting for your decision}}` | `{count, plural, =1{واحدة بانتظار قرارك} other{{count} بانتظار قرارك}}` |
| `dashNothingWaiting` | `Nothing is waiting for your decision` | `لا شيء بانتظار قرارك` |
| `dashFloorEmpty` | `No jobs on the floor` | `لا توجد مهمات في الورشة` |
| `dashFloorEmptyBody` | `Create the first job to see it here.` | `أنشئ أول مهمة لتظهر هنا.` |
| `dashGroupWaiting` | `Waiting for you` | `بانتظارك` |
| `dashGroupInBay` | `In the bay` | `في الورشة` |
| `dashGroupReady` | `Ready to publish` | `جاهزة للنشر` |
| `dashGroupEmpty` | `Nothing here right now` | `لا شيء هنا الآن` |
| `dashSegmentOther` | `Other` | `أخرى` |
| `dashAtlasLabel` | `Jobs by status` | `المهمات حسب الحالة` |
| `dashFooterSum` | `Every segment is a status count. They sum to {total}.` | `كل قطعة تمثّل عدد مهمات بحالة معيّنة، ومجموعها {total}.` |
| `dashReviewVerb` | `Review` | `مراجعة` |
| `dashPublishVerb` | `Publish` | `نشر` |
| `dashOpenVerb` | `Open` | `فتح` |
| `dashGroupCountPending` | `{count} pending review` | `{count} بانتظار المراجعة` |
| `dashGroupCountInBay` | `{count} in progress` | `{count} قيد التنفيذ` |
| `dashGroupCountReady` | `{count} ready` | `{count} جاهزة` |

Existing keys reused: `dashboardTab`, `newJob`, `error`, `retryAction`,
`jobsEmpty`, `commonLoadFailed`, `commonNotAvailable`, `statusDraft`,
`statusScheduled`, `statusAssigned`, `statusInProgress`, `jobsStatusPendingReview`,
`jobsStatusApproved`, `jobsStatusPublished`, `jobsStatusRejected`,
`statusCancelled`, `statusFinalized`.

Non-ASCII copy must be written to both ARBs in the same commit; the Arabic above
is a first pass and is flagged for native review at Gate 6.

## 9. Structural departures (non-empty, enforced at Gate 6)

1. The five-tile metric strip is **deleted**.
2. The `Pipeline` card and its 4-segment 8 px bar are **deleted** (replaced by a
   full-width nine-segment atlas with a remainder rule).
3. The `Next up` card is **deleted** (no such fact exists in the API).
4. The `Recent jobs` card is **deleted** (replaced by three status groups).
5. The `Quick actions` card is **deleted** entirely.
6. The greeting headline is **deleted**; the total is the largest text on the
   page.
7. Card containers are **not used** on the page itself (rows sit on rules).
8. The page no longer imports `job_counts.dart`, `JobCounts`, `jobsProvider`,
   `jobCountsProvider`, or `JobListRow`.
9. On phone, a vertical spine replaces the horizontal bar; nothing stacks as
   five equal cards.

## 10. Acceptance checklist (Gate 6)

1. `dashboard_tab.dart` rewritten; every region is a new file under
   `lib/src/features/dashboard/widgets/`; kill list in
   `docs/audit-dashboard.md` §10 all gone.
2. Structure visibly different from `test/screenshots/real/workshop_dashboard_*.png`
   at 1440, 1024 and 390 (recorded side-by-side).
3. Nine segments + total visible; segment counts sum to the total in the
   fixture; a fixture with an unknown-status remainder renders "Other".
4. Counts failure shows no numbers anywhere (not even 0).
5. One primary action per breakpoint; `New job` opens the wizard.
6. A row opens the quick sheet; `Review` / `Publish` / `Open` appear only for the
   statuses listed in §5.
7. No legacy symbol imported by the dashboard (`grep` proof).
8. 1440/1280/1024/768/390/360 EN + 1280 AR captured with real fonts; all states
   captured; 1.5× and 2.0× text scale; no new `RenderFlex overflowed`.
9. `dart format`, `flutter analyze --fatal-infos`, `flutter test` clean; no test
   deleted or weakened.
10. ARB keys added to both locales; Arabic screenshot has no Latin body copy.

## 11. Notes for the build

- The shell is write-locked; `DashboardTab` must keep its class name and
  zero-argument constructor.
- `formatNumber` is currently exported from `dashboard_tab.dart` and used
  elsewhere — if it is referenced outside, move it to a shared file rather than
  deleting it.
- Use `workshop_clock.dart` for any instant formatting; never add offset hours.
- The page owns its own refresh: pull-to-refresh invalidates counts + the three
  lists.
