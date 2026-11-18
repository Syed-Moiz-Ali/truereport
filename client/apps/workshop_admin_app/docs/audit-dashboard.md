# Phase 0-lite audit — dashboard only (2026-11-18, read-only)

Scope: `lib/src/features/dashboard/dashboard_tab.dart` and the shell it sits in.
Path: **LITE** (one screen), per `rebuild-pipeline` §0.
Read-only: no app code was changed to produce this file. The one repair described
in §R was a restoration of a botched revert, not a design edit.

Supersedes the dashboard half of `docs/audit-dashboard-jobs.md`; that file remains
the source for the jobs queue / board / detail findings.

## R. Finding zero — the tree was not buildable

The last Wave-2 run stopped at Gate 2b with "phase C blocked and reverted". The
revert was incomplete. Measured before any edit in this run:

```
$ flutter analyze --no-pub
60 issues found.   <- 46 errors, 14 warnings
```

Cause: W1 phase C deleted `lib/src/job_counts.dart` and
`lib/src/features/jobs/schedule_job_sheet.dart` and removed the legacy
`jobs()`/`jobCounts()` surface from `admin_api.dart`, but `dashboard_tab.dart`,
`jobs_tab.dart`, `admin_providers.dart` and `job_quick_sheet.dart` still referenced
them. Nothing built; no screenshot or test in that state was evidence of anything.

Repair (reversible, additive): `git checkout HEAD --` on
`lib/src/job_counts.dart`, `lib/src/features/jobs/schedule_job_sheet.dart`,
`lib/src/admin_api.dart`, `lib/src/admin_providers.dart`. Legacy surface restored;
W1's landed work (`workshop_clock.dart`, time policy, job_widgets, detail, reports,
templates, dashboard copy) untouched.

After repair:

```
$ flutter analyze --no-pub        No issues found! (4.6 s)
$ flutter test                   00:59 +480: All tests passed!
```

**Consequence for this run:** the dashboard is rebuilt on a tree that compiles.
Every earlier "the redesign didn't work" judgement about Wave 2 was made against a
broken tree; it could not have been otherwise.

## 1. What this screen is for

A workshop admin opens the app to answer one question: *what needs me right now?*
Everything else on the page is context. Today the page answers a different
question — "what are the lifetime totals?" — which is why it feels like a template.

## 2. What today's screen gets wrong (structural, not cosmetic)

| # | Defect | Evidence |
|---|---|---|
| S1 | **Five numbers that do not add up.** The strip shows Active (derived), New & scheduled, In progress, Ready to finalize, Finalized today. `active` overlaps `in progress`; `finalized today` is a time subset; the rest are all-time. Nothing on screen says so. | `dashboard_tab.dart:176-209`, `job_counts.dart:37` |
| S2 | **The pipeline bar is not a partition.** Four segments omit ASSIGNED, all-time FINALIZED and CANCELLED, and mix an all-time bucket with a today subset. Its widths describe unrelated buckets. | `dashboard_tab.dart:556-578`; `docs/invariants.md` J5/T3 |
| S3 | **The page reads a different table than its own primary action writes.** "New job" → `JobCreationWizardPage` → `platform_jobs`. Counts, Next up and Recent jobs → `inspection_jobs`. Create a job and the dashboard does not change. | `docs/data/inventory.md` T4 |
| S4 | **No time-based meaning.** "Next up" is the soonest scheduled *open* job computed from a page fetched with no ordering contract; "Recent" is `take(4)` of a created-desc list that includes finished jobs. | `dashboard_tab.dart:297-301, 327-345` |
| S5 | **Dead canvas.** At 1440 the right column ends at 775 px in a 900 px viewport and the left column ends at 604 px; 40 % of the page is empty, while the five numbers that matter are compressed into one strip. | `test/screenshots/real/workshop_dashboard_1440.png` |
| S6 | **Phone composition is a stack of cards.** Metric strip wraps 2+2+1 (the fifth tile is stranded), New job is a full-width button, then three cards. No product identity, no priority. | `test/screenshots/real/workshop_dashboard_390.png` |
| S7 | **Arabic is half-English.** `'Today, $formatted'` and greeting concatenation were fixed at the copy level in W1; the layout still assumes LTR card widths. | J12, W1 |
| S8 | **Every module is a card with a header inside a card.** Next up, Recent jobs, Pipeline, Quick actions all use the same container, so nothing is dominant. Zero focal point. | screenshot 1440 |

## 3. The one fact that unlocks a real redesign (measured, not assumed)

`GET /api/v1/workshop/jobs/counts` is a **true partition**:

```java
// WorkshopJobAdminService.java:171-188
for (String status : store.statuses(workshopId)) counts.merge(status, 1L, Long::sum);
long total = counts.values().stream().mapToLong(Long::longValue).sum();
```

Nine mutually exclusive statuses — `DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS,
PENDING_REVIEW, APPROVED, PUBLISHED, REJECTED, CANCELLED` — always summing to
`total`. There is no client-side derivation and no "today" subset.

`GET /api/v1/workshop/jobs` returns the **same rows** (`platform_jobs`) with
`page/size/status/search/from/to`, ordered `created_at DESC, id DESC`
(`PlatformJobStore.java:149`).

So a dashboard built on this pair can show a pipeline where the segments literally
sum to the total, and a list that is the same data. That is the structural idea
this rebuild can own. The legacy pair cannot: it has no such guarantee.

**Constraint that follows:** there is no server-side scheduled-time ordering, so
"the next job by clock" is not a fetchable fact. Any hero must be built from
status + created_at (e.g. "waiting for your review"), or it is fabricated.

## 4. Invariants this screen must not break

From `docs/invariants.md` (Wave 2, still in force), the ones the dashboard touches:

| # | Invariant | Test today |
|---|---|---|
| J2 | Counts come only from a server endpoint; a failure renders one bounded error, never guessed figures | `dashboard_test`: counts error |
| J7 | A terminal job is read-only; a finished job offers the report, no mutations | `dashboard_test`: finalized job |
| J11 | No fabricated data — empty, error, loading all render honest states | `dashboard_test`, `no_fabricated_data_test` |
| J12 | Every visible string localized `en` + `ar`, one ARB message with placeholders | AR screenshots |
| J13 | RTL mirrors layout; data values stay LTR | AR tests |
| J14 | Stable keys: `dashboard-stat-*`, `dashboard-job-<id>`, `dashboard-pipeline-bar` | dashboard/queue tests |
| J15 | Six-tab shell, index-based navigation via `WorkshopNavigationScope.select` | `dashboard_test` |
| J16 | Opening a job from the queue shows the quick sheet | `dashboard_test` |
| J17 | Light-only (waiver W-LIGHT) | `ui_matrix_test` |

Added by this audit:

| # | Invariant | Why |
|---|---|---|
| **J19** | **One job world per surface.** The rebuilt dashboard reads only the clean (`platform_jobs`) API — counts and rows from the same table, so its own "New job" is visible on its own page. | Kills T4/S3 |
| **J20** | **A partition, or no chart.** If a pipeline is drawn, the segments shown must sum to the displayed total. A partial breakdown is rendered as a list, not a bar. | Kills S2 |
| **J21** | **No time claim without a time field.** "Next up" requires a schedule ordering the API does not provide; the page may not imply one. | Kills S4 |

## 5. Test-contract problem (must be handled before the build)

`test/dashboard_test.dart` currently pins **implementation**, not behaviour:

- `find.byType(WorkshopMetricStrip)` / `WorkshopPageHeader` — one specific widget;
- `find.byKey('dashboard-pipeline-bar')` at exactly `8` px with exactly `4`
  `ColoredBox` segments;
- the label set "Active jobs / New & scheduled / In progress / Ready to finalize /
  Finalized today".

A genuine rebuild changes all of these by construction. The plan is therefore:

- **Keep** (behaviour): counts reach the screen from the counts provider; one
  bounded error with no numbers on failure; empty state with one primary action;
  a job row opens the quick sheet; finalized row offers no mutations; tab
  navigation reaches every tab; no session still yields a page title; AR is RTL;
  no overflow at 360/390/768/1280 × 1.0/1.5/2.0.
- **Rewrite** (structure): widget types, the segment count, the tail of the
  metric-strip assertions.
- Any test deleted rather than rewritten is a stop. The new file is
  `test/dashboard_invariants_test.dart`; the structural assertions move to
  `test/dashboard_structure_test.dart` and describe the *new* composition.

## 6. Font strategy (Gate 0 decision, inherited)

**Settled — no action.** `client/packages/design_system/assets/fonts` bundles
PlusJakartaSans (Latin), IBMPlexSansArabic + NotoSansArabic, NotoSans, NotoSansSC,
NotoSansTelugu, declared in the package `pubspec.yaml`, resolved by `TrFonts`
family names in `AppTheme.build`. `test/flutter_test_config.dart` →
`test/support/real_fonts.dart` loads them for every test and asserts
`RealFonts.missingFamilies` is empty. `google_fonts` is not a dependency, so
runtime fetching cannot happen. Screenshots therefore render real glyphs.

## 7. Baseline (measured this run)

| Check | Value |
|---|---|
| `flutter analyze --no-pub` | 0 issues |
| `flutter test` | **480 pass, 0 fail, 0 skip** |
| Coverage — `dashboard_tab.dart` | **93.4 %** (326/349 lines) |
| Coverage — `admin_api.dart` | **6.3 %** (27/427) |
| Coverage — `workshop_job_models.dart` | **53.2 %** (165/310) |
| `RenderFlex overflowed` | 0 in the current matrix |
| Build | not re-run in this phase; last recorded 60.99 MB web build |
| Format | 19 files allowlisted (`docs/baseline_allowlist.json`), 0 new |

## 8. Top findings (ranked, this screen only)

| ID | Sev | Finding | Fix | Effort |
|---|---|---|---|---|
| R1 | Critical | Surface reads `inspection_jobs`; primary action writes `platform_jobs` (S3) | re-point the page to clean counts + clean jobs (J19) | M |
| R2 | High | Numbers and pipeline are not a partition (S1, S2) | pipeline over the 9 real buckets, total always visible (J20) | M |
| R3 | High | No focal point; every module is an equal card (S5, S8) | one hero region, one primary action | M |
| R4 | High | No time truth available (S4) | remove "next up"; use "needs review" / "waiting" from status (J21) | S |
| R5 | Medium | Contract layer largely untested (admin_api 6.3 %) | contract tests for the two clean endpoints' mappers | M |
| R6 | Medium | Test file pins widgets, not behaviour | split invariants vs structure (see §5) | S |
| R7 | Medium | Phone is a 1-column card stack (S6) | one scrolling column with a pinned primary action, sticky filter bar | M |
| R8 | Low | Greeting/date copy is fine but the date is the device clock, not workshop time | label the date honestly (`Today, …`) or drop it; do not claim workshop time | S |

## 9. Strategy

**LITE rebuild, one screen, data seam first.** No shell rebuild, no route changes
(`admin_router.dart` and `workshop_admin_home.dart` carry a Deny ACE for this
account — the dashboard must be rebuilt without editing them).

Seams, each independently revertible:

```
1. data seam     dashboard reads cleanCounts + cleanJobs (new providers already exist)
                 rollback: revert dashboard_tab.dart's provider imports
2. copy seam     ARB keys added (never rewritten); old keys kept
                 rollback: delete added keys; screen falls back
3. test seam     invariants test added first (green on current behaviour), then
                 structure test rewritten against the new composition
                 rollback: restore the old structure test from git
4. screen seam   dashboard_tab.dart rewritten; dashboard/*.dart region files created
                 rollback: git checkout the four paths + delete the region folder
```

## 10. Kill list (named now, executed in the mini Brief)

Gone when the rebuild lands:

- `dashboard_tab.dart`: `_PageColumn`, `_MetricStrip`, `_DashboardBody`,
  `_UpcomingCard`, `_RecentJobsCard`, `_PipelineAndActions`, `_PipelineCard`,
  `_PipelineBody`, `_PipelineLegend`, `_QuickActionsCard`, `_QuietAction`,
  `_nearestUpcoming`
- `dashboard_tab.dart`'s dependency on `job_counts.dart`, `JobCounts`,
  `jobsProvider`, `jobCountsProvider`, `JobListRow` (as used here)
- the "Active jobs" tile and the derived `active` figure from this screen
- `test/dashboard_test.dart`'s structural half (moved, not deleted)

Anything that survives this list must be defended at Gate 6.

## 11. Open questions carried to Gate 3 (product, not code)

1. Quick actions duplicates the shell's own navigation (Staff / Templates / Job
   board / Settings). Delete it, or make it a different thing (recently used)?
2. Is "Finalized today" worth keeping? The clean counts has no date window, so
   keeping it means a second endpoint or a lie. Current answer: drop it.
3. Does the dashboard need to show money (revenue, unpaid invoices)? There is no
   endpoint for it in this scope, so it cannot ship even if wanted.
