TITLE: Jobs module Brief 1 — pin J6/J10 + the clean-job contract (engineering only, no UI)

WORKDIR: `E:\syed_moiz_ali\bitlogix\truereport\client\apps\workshop_admin_app`
MODE: implement (tests + docs only)
COMMITS: none

## OUTCOME

When this brief is done, the jobs module has a green, characterization-only
safety net under the behaviours the rebuild is about to replace. **J6**
(optimistic-concurrency `version`) and **J10** (a `REVOKED` public link is never
"live") are pinned, the clean-job DTO contract parses the committed samples
without loss, and the legacy queue-count derivation is frozen so Wave J1's
replacement is a conscious diff every reviewer can see.

**No pixel, layout, colour, type, spacing, copy, `lib/` or `pubspec` change is in
this brief.** UI work (directions, Brief 2, any screen edit) is **blocked until
this passes Gate 2b**.

## WHY THIS EXISTS

- `docs/invariants.md` marks **J6** and **J10** UNPINNED. Both are
  consequence-heavy: a stale write can silently move a job; a revoked link shown
  as live is a privacy failure for the customer.
- The audit (`docs/audit-dashboard-jobs.md` D1) measured `admin_api.dart` at
  1.2 % coverage. Every widget test injects `FakeAdminApi`, which builds models
  from constructors, so `fromJson` never runs in the suite.
- **J3/J5** mean the queue chip counts are derived from a search-scoped,
  status-unfiltered *list* while the dashboard reads `/counts`. Replacing the
  queue without pinning this makes two "In progress" numbers change silently.

## SCOPE — WHAT MAY CHANGE

In scope:

1. New test files under `test/**` (this brief: `test/jobs_invariants_characterization_test.dart`).
2. Test-only helpers under `test/support/**` — additive only; every existing
   constructor call must keep working.
3. `docs/briefs/brief-jobs-1.md` (this file).
4. A new derived-from-DTO sample under `docs/data/samples/` **only if** a
   required fixture does not exist. (None was required: `clean-jobs-page.json`,
   `clean-job-counts.json` and `revokedCleanJobJson` already exist.)

Out of scope — **do not touch**:

- any file under `lib/` or `packages/` (foundation is frozen);
- `pubspec.yaml` / `pubspec.lock`;
- any existing test deletion or weakening (`docs/baseline_allowlist.md` rule);
- golden/screenshot regeneration, ARB copy, the router, the server;
- fixing a defect the tests reveal (pin it, log it, stop).

## INVARIANTS TO PIN

| # | Behaviour pinned | How |
|---|---|---|
| **J6a** | Assign sends the version the page loaded. | Real `JobDetailPage` + `FakeAdminApi(enforceVersions: true)`; assert `assignRequests.single['version'] == 3`. |
| **J6b** | A stale assign surfaces a failure and does **not** overwrite. | Bump the fake's stored version to 4 after load; UI still sends 3; assert `commonActionFailed`, status stays `PENDING_REVIEW`, stored version stays 4. |
| **J6c** | Cancel's HTTP body carries `reason` + `version`; a stale cancel is rejected. | `HttpAdminApi` interceptor asserts the body; fake raises `FakeVersionConflict` without mutating. |
| **J10** | `ACTIVE` → Published; `REVOKED` → Revoked; every other/unknown value → Not published. A PUBLISHED job with a revoked link never shows the live publication label. | Real `JobDetailPage`, publication `JobFact` scoped by label, four values incl. `SUPERSEDED`. |
| **D1** | `CleanJob.fromJson` / `CleanJobCounts.fromJson` map the committed samples with no loss; unknown enums are preserved (neutral tone); a missing/extra key cannot crash; non-map page items are dropped. | Reads `docs/data/samples/clean-jobs-page.json` + `clean-job-counts.json` with a provenance guard. |
| **J3/J5** | Queue chips are client-derived from the search-scoped, status-unfiltered list — **not** `/counts`; selecting a status does not rescope them; search does. | Real `JobsTab` + a legacy fake whose `jobCounts()` returns 140 while the list has 3; assert `countsCalls == 0`. |

## CHARACTERIZATION TESTS TO ADD

File: `test/jobs_invariants_characterization_test.dart` (13 tests, all green on
unchanged behaviour).

- `J6 — assign/cancel carry the job version`
  - `assign sends the version the page loaded`
  - `a stale version surfaces a failure and does not overwrite the job`
  - `a stale cancel is rejected without cancelling`
  - `cancel forwards reason + version on the HTTP wire`
- `J10 — publication status mapping` (4 generated tests, `ACTIVE`, `REVOKED`,
  `UNPUBLISHED`, `SUPERSEDED`)
- `clean-job contract — committed docs/data/samples`
  - every `CleanJob` field of `clean-jobs-page.json`
  - `CleanJobCounts` fields + partition on `clean-job-counts.json`
  - unknown enums preserved / tone neutral
  - missing or extra field cannot crash (both mappers + page items)
- `queue counts scope (legacy, pinned until replaced)` — one widget test.

Test-support change (additive, default-compatible):

`test/support/fake_admin_api.dart` gains `FakeAdminApi({... , enforceVersions = false})`,
a `FakeVersionConflict` exception, `assignRequests` / `cancelRequests`,
`versionOf()` and `bumpVersion()`. With the default `false` every pre-existing
test keeps its exact behaviour; successful mutations now increment the stored
version like the server.

## KNOWN DEFECTS FOUND (pin, do not fix here)

1. **Reason-sheet controller disposal — J8, affects J6 cancel UI.**
   `lib/src/features/jobs/job_widgets.dart` `showJobReasonSheet` disposes its
   `TextEditingController` before the sheet's exit transition finishes; driving
   cancel/unpublish/revoke to completion throws
   `A TextEditingController was used after being disposed`.
   Pinned at the fake + HTTP-wire layers; the page-level cancel test is deferred
   and marked `TODO(J8)` in the test file. **Needs a `lib/` fix** (dispose after
   the route settles, or own the controller in a stateful sheet).
2. **Unknown status prints the raw enum — J1/contract §Enum mapping.** The
   mapper preserves unknown values (good), but `jobStatusLabel` falls through to
   the raw code and the tone is neutral. Marked `TODO(J1)`; the contract asks
   for an explicit "Unknown status". Pin only.
3. **`signaturePresent` is on the wire, not on `CleanJob` — D1.** The committed
   sample carries it; the mapper drops it. Marked `TODO(J1)` in the loss check.

## COMMANDS

From `client/apps/workshop_admin_app`:

```
dart format --output=none --set-exit-if-changed test/jobs_invariants_characterization_test.dart test/support/fake_admin_api.dart
flutter analyze --fatal-infos
flutter test --no-pub test/jobs_invariants_characterization_test.dart
flutter test --no-pub            # full suite: must stay >= the 562-test baseline
git status --short               # only test/**, docs/briefs/brief-jobs-1.md, docs/data/samples/** (if added)
git diff -- lib pubspec.yaml     # must be empty
```

## GATE 2b CHECKLIST (all must be true before any UI wave starts)

- [ ] `flutter analyze --fatal-infos` → **0 issues**.
- [ ] `flutter test test/jobs_invariants_characterization_test.dart` → **13/13 pass**.
- [ ] Full `flutter test` → **0 failures**, test count ≥ 562; no test deleted or weakened.
- [ ] J6a/J6b/J6c each have a named passing test; the stale write provably leaves the job untouched.
- [ ] J10 has a passing case for `ACTIVE`, `REVOKED`, `UNPUBLISHED` and an unknown value; `REVOKED` never resolves to "Published".
- [ ] Both committed clean-job samples parse without loss; partition holds; unknown enums preserved; missing/extra fields do not throw.
- [ ] Queue test proves chip counts come from the list, **`jobCounts()` is never called**, status filters do not rescope, search does.
- [ ] `git diff -- lib pubspec.yaml` is empty; `docs/baseline_allowlist.*` unchanged.
- [ ] Defects are recorded with `TODO(invariant-id)` plus this brief — not fixed in `lib/`.
- [ ] Coverage of `admin_api.dart` / `workshop_job_models.dart` strictly increased (record the before/after if running `--coverage`).

If any box is unticked, **stop**: the UI wave is not allowed to begin.

## REPORT FORMAT

New test files · tests added (names) · exact commands + pasted output (analyze,
targeted, full) · defect list with invariant id · confirmation that no `lib/` or
`pubspec` byte changed · single next action.
