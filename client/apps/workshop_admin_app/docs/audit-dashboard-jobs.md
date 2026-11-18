# Phase 0 audit — dashboard + jobs

Read-only. Nothing in `lib/` was changed to produce this file.
Artifacts: `docs/invariants.md`, `docs/baseline_allowlist.md`,
`docs/baseline_metrics.md`.

## SUMMARY

**Health: Yellow.** The UI layer is disciplined — tokens, l10n, real states,
solid widget coverage, no overflow — but the **contract layer underneath it is
unproven** (1.2 % of `admin_api.dart`, 8–17 % of the models), and the same
business quantity ("in progress") is computed two different ways on two screens.
A visual rebuild on top of that would make a pretty screen that can still show
contradictory numbers.

Biggest risks: unverified DTO/endpoint boundary (D1); two count scopes under one
label (D2); two parallel job worlds (D3).
Biggest opportunities: one status/count policy seam, one row vocabulary, and a
contract test that parses real fixtures — all cheap, all structural.

## Findings (ranked)

| ID | Sev | Location | Evidence | Consequence | Fix | Effort | Risk |
|---|---|---|---|---|---|---|---|
| **D1** | **Critical** | `admin_api.dart` (427 lines, 1.2 % covered), `models.dart` 8.1 %, `workshop_job_models.dart` 16.8 % | every test overrides `adminApiProvider` with `FakeAdminApi`, which builds models from constructors — `fromJson`, queries, error mapping never run | every number on these screens crosses an unverified boundary; a server field rename is invisible until production | contract tests over captured server JSON (or server DTO fixtures), plus mapper tests per model | M | low |
| **D2** | High | `dashboard_tab.dart:56-57,102-114` vs `jobs_tab.dart:47,118-126` | dashboard reads `/jobs/counts` (whole workshop); queue chips count the **search-scoped list** | "In progress 23" on the dashboard and "In progress 34" in the queue are both "correct" and unexplainable to a user | one scope per label: either move chips to the counts endpoint scoped to the same predicate, or label the queue counts as "in this view" | M | low |
| **D3** | High | `jobs_tab.dart` (WorkshopJob) vs `jobs_board_tab.dart` (CleanJob); `workshop_admin_home.dart:73-110` | two tabs both called jobs, disjoint status vocabularies, different open behaviour (sheet vs page) | users must learn two objects; code duplicates rows, filters and counts twice | decide in Phase 3: converge models, or name and separate them unmistakably ("Workshop queue" / "Client board") | L | med |
| **D4** | High | `dashboard_tab.dart:46-48, 51-54` | `'Today, $todayFormatted'` is hardcoded English; greeting is concatenated | the Arabic dashboard is half-English and the greeting word order is wrong | ARB message with placeholders (`dashboardToday`, `dashboardGreeting`) | S | low |
| **D5** | High | `job_detail_page.dart` 1063 lines, 14 private widgets; `:138-139` duplicate spacing; `:169-255` inline assign using `AppButton/AppTextField/AppSelectableText` | `assign_technician_dialog.dart` (330 lines) already implements assignment in the Workshop visual language | two assignment UIs, two behaviours, two visual systems; the file cannot satisfy the rebuild's region-file rule | extract per-region files; reuse or delete the duplicate assign flow | M | low |
| **D6** | Medium | `workshop_admin_home.dart:138-148` | `IndexedStack` mounts all six tabs at once | six provider families fetch on app open; the dashboard's own refresh invalidates only two | lazy tab mounting or a per-tab keep-alive policy | M | med |
| **D7** | Medium | `dashboard_tab.dart:112` | `onSelectFilter: () => goTo(1)` for every cell | tapping "Ready to finalize 4" lands on an unfiltered queue — the number and the destination disagree | pass the status through to the queue's initial filter | S | low |
| **D8** | Medium | `jobs_tab.dart:104-109` vs `jobs_board_tab.dart:136-142` | queue chips have no key; board chips do | inconsistent test contract; new widget tests can only find chips by label text | add `job-filter-<status>` keys to the queue | S | low |
| **D9** | Medium | `dashboard_tab.dart:328-346` | closed-status set is a local literal (`FINALIZED/PUBLISHED/CANCELLED/REJECTED`) | a new lifecycle status silently becomes "next up" | share one status policy with `job_presentation` and test it | S | low |
| **D10** | Low | `job_widgets.dart` `JobListRow` vs `jobs_board_tab.dart` `_BoardRow`; `dashboard_tab.dart:299-302` | two row components for the same object class; "recent jobs" includes closed jobs while "next up" excludes them | duplicated styling and drifting status rules | one row component with variants | M | low |

Category summary: data truth 2 (D1, D2) · model duality 1 (D3) · copy/l10n 1
(D4) · structure 3 (D5, D6, D10) · UX contract 3 (D7, D8, D9).
No security or crash findings in this scope. No money handling on these screens.

## What is good — keep it

- **Anti-fabrication discipline**: `jobCounts()` refuses client-side fallbacks
  (`admin_api.dart:843-849`) and the dashboard test asserts that an error shows
  no numbers. Keep this rule in the rebuild.
- **State handling**: every async surface has loading, error, empty and data
  branches; errors are bounded cards, not full-page takeovers.
- **Design-system discipline**: no raw colours/type/radii in these four screens;
  RTL-aware chevrons, directional padding, LTR-pinned data values.
- **Test shape**: 13 dashboard, 9 queue, 4 detail, plus an adaptive/matrix suite
  and AR + 2× text-scale cases. They test behaviour, not mocks-of-mocks.
- **Optimistic concurrency**: assign/cancel send `version`; mutations invalidate
  the right providers.
- **Sign-in wave is intact**: 428 tests, allowlist empty, real-font harness.

## Recommended strategy

**Strangler per screen, with the data layer pinned first.** The UI can be replaced
screen by screen without touching the server; the contract seam cannot be skipped,
because D1 means any "new" number would be built on the same unverified parsing.

Order: pin the boundary → fix the two count scopes → then rebuild composition.

## Font strategy decision (Gate 0)

**Inherited and unchanged — no action.** Fonts are bundled `.ttf`/`.otf` in
`client/packages/design_system/assets/fonts`, declared in that package's
`pubspec.yaml`, resolved by `TrFonts` family names in `AppTheme.build`, loaded for
every test by `test/flutter_test_config.dart` → `test/support/real_fonts.dart`
(with `RealFonts.missingFamilies` asserting the set), and runtime fetching is
impossible because `google_fonts` is not a dependency. Screenshots therefore
render real glyphs, which is what Gate 6 needs.

## Migration steps (first pass)

```
Step 1: Pin the contract boundary
Goal:        every DTO/mapper/query used by dashboard+jobs is tested from real JSON
Changes:     new test/support/job_fixtures.dart (captured payloads), contract tests
Behavior:    unchanged
Tests:       existing 428 stay green + new mapper/query tests
Verify:      flutter test; coverage of admin_api/mappers moves off ~1–17 %
Rollback:    tests only
Depends on:  —
Risk/effort: S/M

Step 2: One count contract per label
Goal:        dashboard "In progress" and queue "In progress" cannot disagree silently
Changes:     queue chips read a server count scoped to the same predicate, or the
             label states its scope; tests assert both surfaces against one fixture
Behavior:    numbers unchanged where already correct; labels/scopes diverge openly
Verify:      dashboard_test + jobs_queue_test agree on one fixture
Rollback:    revert the provider key/param only
Depends on:  Step 1

Step 3: l10n for dashboard copy
Goal:        Arabic build has no English and no concatenated sentences
Changes:     ARB keys + dashboard_tab usage
Behavior:    visual copy only
Verify:      1280 AR screenshot + a test that asserts no Latin words in AR body
Rollback:    revert the screen + keys
Depends on:  —

Step 4: Screen rebuilds (Phase 3–6, one screen per wave)
Goal:        replace composition, keep behaviour
Changes:     rewrite dashboard_tab, jobs_tab, jobs_board_tab, job_detail_page into
             region files; kill list per screen
Verify:      Gate 6 matrix, edit-vs-replace test
Depends on:  Steps 1–3, Phase 4 ADR, Phase 5 tokens/primitives
```

## Quick wins (< 1 day)

1. D4 — two ARB keys, one screen.
2. D7 — pass the tapped status into the queue.
3. D8 — add chip keys.
4. D9 — share the closed-status predicate with `job_presentation`.
5. Delete the duplicate `SizedBox` at `job_detail_page.dart:139`.

## Risks and open questions

1. **No live server** in this environment (carried gap). Contract samples must be
   derived from server DTOs/fixtures, not live capture — say so if that is not
   acceptable.
2. **Are "Jobs" and "Job Board" meant to converge?** This is a product decision for
   Gate 3, not a code decision. Two credible answers (merge, or rename+separate)
   give different designs.
3. **Should dashboard counts be "today" or "all time"?** The strip mixes an all-time
   `total` derivation with `finalizedToday`; the label does not say.
4. Rebuilding the shell (D6) touches all six tabs, outside this scope. Keep it out
   unless the nav shell is explicitly part of the chosen direction.
