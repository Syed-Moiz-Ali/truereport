# Mini Brief — rebuild the dashboard (LITE build step)

Inputs (all approved): `docs/ui_brief.md` (direction B), `docs/visual_language_dashboard.md`,
`docs/data/dashboard_inventory.md`, `docs/invariants.md` (J2/J7/J11–J17, J19–J21),
`docs/phase-4-dashboard-harness.md`, `docs/baseline_allowlist.md`.

One screen. Behaviour is preserved; the UI implementation is replaced. Every phase
leaves the tree compiling, formatting and green.

---

## Phase 1 — Copy seam (ARB only, no UI)

**Goal:** every string the new page needs exists in `en` and `ar` before any
widget references it.

- Add the 18 keys in `docs/ui_brief.md` §8 to
  `client/packages/l10n/lib/l10n/app_en.arb` and `app_ar.arb`.
- Add metadata (`@key` placeholders/types) for the plural/placeholder keys.
- Run `flutter gen-l10n` in `client/packages/l10n`; commit the regenerated
  `lib/l10n/gen/*.dart`.
- Do not modify or remove an existing key.

**Verify:** `cd client/packages/l10n && flutter analyze` clean; the app still
compiles.

## Phase 2 — Screen rewrite (the bulk)

**Goal:** `dashboard_tab.dart` becomes a thin screen over new region files.

Create:

```
lib/src/features/dashboard/widgets/dashboard_hero.dart      eyebrow + total + decision + CTA
lib/src/features/dashboard/widgets/dashboard_groups.dart    three groups, data-driven
```

(already built in Phase 5: `dashboard_atlas.dart`, `dashboard_rows.dart`,
`dashboard_states.dart`, `dashboard_style.dart`)

Rewrite `lib/src/features/dashboard/dashboard_tab.dart` so that it:

- reads `cleanJobCountsProvider` and three `cleanJobsProvider` keys
  (`PENDING_REVIEW` size 5, `IN_PROGRESS` size 3, `APPROVED` size 3);
- renders the hero, the atlas (or spine), the groups, the footer;
- owns pull-to-refresh (invalidate counts + the three keys);
- keeps `DashboardTab` (name, zero-arg constructor) and
  `formatNumber(BuildContext, int)` (imported by five other files);
- imports **no** legacy job symbol.

Delete every private widget named in `docs/visual_language_dashboard.md` §8.

**States:** loading, ready, empty workshop, counts error, group error, both
error, partial empty group, remainder, no session. Every one per `ui_brief.md` §7.

**Verify:** `flutter analyze --no-fatal-infos` clean; `flutter test` still green
except the structural assertions in `test/dashboard_test.dart` that Phase 3
rewrites (they may not be deleted).

## Phase 3 — Tests

- New `test/dashboard_invariants_test.dart`: behaviour only — counts reach the
  screen; a counts failure renders no number; a group failure does not hide the
  others; a row opens the quick sheet; a finalized job offers no mutation; the
  atlas segments sum to the total; the remainder renders "Other"; all four
  breakpoints × 1.0/1.5/2.0 have no overflow; AR is RTL; no session still shows
  the page title.
- Rewrite the structural half of `test/dashboard_test.dart` against the new
  composition (keep its behaviour cases).
- Contract tests for the two clean mappers used here
  (`CleanJobCounts.fromJson`, `JobPage.fromJson`) over the existing fixtures.

**Verify:** 0 failures; no test removed.

## Phase 4 — Proof

- Capture `docs/evidence/states/dashboard_*` at 1440/1280/1024/768/390/360 EN +
  1280 AR, all states, 1.5×/2× scale.
- Side-by-side before/after at 1440/1024/390.
- `dart format`, `flutter analyze --fatal-infos`, `flutter test`,
  `dart run tool/baseline_check.dart`.
- Grep proof: no legacy symbol in the dashboard folder.
- Edit-vs-replace evidence: rewritten screen file, ≥1 new file per region,
  kill list executed, different structure at 1440/1024/390.

---

## Out of scope (stop and ask if it appears)

- The shell, router, jobs queue, board, detail.
- Dark theme, new routes, new endpoints, backend changes.
- Rewriting `job_widgets.dart` or any shared row used by the queue.
- Any arithmetic that is not `count / total` or `sum(nine)` vs `total`.

## Definition of done

`docs/ui_brief.md` §10 acceptance checklist passes item by item, with the
evidence path named for each. Any item that cannot pass is reported, not waived
by the agent.
