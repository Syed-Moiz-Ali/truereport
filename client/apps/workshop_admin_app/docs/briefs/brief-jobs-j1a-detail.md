# Brief J1a — job detail screen (single-screen rebuild)

WORKDIR: `client/apps/workshop_admin_app`
MODE: implement (UI + tests + evidence)
COMMITS: none

## OUTCOME

`job_detail_page.dart` becomes a ≤220-line composition that owns data and
mutations only. Everything visible lives in one file per region under
`features/jobs/detail/`; shared primitives move to `features/jobs/shared/`;
the assign flow becomes one versioned sheet for `CleanJob`; and a pure
`JobActions` policy replaces the two inline status switches. Behaviour is
rebuilt, not restyled: the old stacked-card column, duplicate summary, inline
assign block and App-kit reason sheet are deleted.

## SCOPE (owned files)

- `lib/src/features/jobs/job_detail_page.dart` (rewrite, ≤220 lines)
- `lib/src/features/jobs/detail/**` (new): top bar, summary/identity,
  customer+vehicle, inspection/findings, assignment, review+publication,
  action bar, states.
- `lib/src/features/jobs/shared/**` (new): `job_status_badge.dart`,
  `job_fact.dart`, `job_fact_grid.dart`, `job_actions.dart` (pure policy),
  `job_reason_sheet.dart`, `job_error_copy.dart`.
- `lib/src/features/jobs/assign/assign_sheet.dart` (new, CleanJob + version).
- `lib/src/features/jobs/job_presentation.dart` (split; re-export shared names
  so the board/queue keep compiling).
- `lib/src/features/jobs/job_widgets.dart` (move the reason sheet out; keep a
  re-export so other screens keep compiling).
- Tests: `test/job_detail_test.dart` (rewrite),
  `test/job_actions_policy_test.dart` (new),
  `test/job_detail_capture_test.dart` (new), and the detail-related
  characterization selectors/expectations in
  `test/jobs_invariants_characterization_test.dart`.

Not touched: `jobs_tab.dart`, `job_quick_sheet.dart`, `schedule_job_sheet.dart`,
`job_counts.dart`, `assign_technician_dialog.dart`, `admin_api.dart`,
`admin_providers.dart`, `models.dart`, the board, the wizard, packages,
`pubspec.yaml`, router/theme/tokens/shell, ARB files.

## KILL LIST (deleted in this wave)

1. The inline assign bottom sheet in `job_detail_page.dart` (the duplicate of
   `assign_technician_dialog` with its own `StatefulBuilder`).
2. The old private detail widgets: `_StatusRow`, `_SummaryCard`,
   `_CustomerVehicleSection`, `_InspectionSection`, `_Findings`,
   `_FindingRow`, `_AssignmentSection`, `_AssignmentRow`,
   `_ReviewPublicationSection`, `_ActionBar`, `_MoreMenuButton`.
3. Old detail-level App-kit usage: `AppTextField`, `AppButton`,
   `AppSelectableText`, `showAppBottomSheet`-hosted App widgets, `SectionHeader`
   inside the detail cancellation flow.
4. Duplicate spacing: the two adjacent `SizedBox` calls before the summary
   (`spacing.lg` + `spacing.xl`) and the repeated customer/vehicle/technician
   facts across three cards.
5. The `_ActionBar` status switch with the wrong terminal branches
   (`PENDING_REVIEW`, `PUBLISHED || FINALIZED`, default → publish checklist).
6. The finding evidence counts, issue values and `completedAt` display (CR-7 /
   CR-8) and the raw `resultCode` badge label.

## REGIONS (one file each)

```
detail/job_detail_top_bar.dart          back, reference, refresh + overflow
detail/job_detail_summary.dart          vehicle + reference + status badges + 5 facts
detail/job_detail_customer_vehicle.dart customer + vehicle + cancellation reason
detail/job_detail_inspection.dart       template/score/grade/safety + findings
detail/job_detail_assignment.dart       current technician + assignment history
detail/job_detail_review_publication.dart review/publication/consent + blocked note
detail/job_detail_action_bar.dart       policy-driven primary/secondary/overflow
detail/job_detail_states.dart           loading / load error / conflict banner / version note
```

Layout: one hero identity surface, then a 7/5 two-column body at ≥1000 px
(customer+vehicle and inspection on the start side, assignment and
review+publication on the end side); below 1000 px it stacks in that order.
The sticky action bar keeps one primary action.

## DATA RULES

- May show: reference, status, reviewStatus, publicationStatus, customer
  name/phone/email, technician name, vehicle make/model/year/plate/VIN,
  odometer, transmission, fuel, template name/version, `scheduledAt`, score,
  grade, safety cap, consent, cancellation reason, assignment reason, finding
  labels/stable codes/result labels.
- Must not show: any `createdAt/updatedAt/startedAt/completedAt/approvedAt/
  publishedAt` or assignment timestamps (CR-8; `scheduledAt` only), finding
  evidence counts / issue values / completedAt (CR-7), raw enum codes, raw ISO
  strings, a publish action (M6), or any workshop id in a request (M1).
- Publication mapping: `PUBLISHED → Published`, `UNPUBLISHED/NOT_PUBLISHED →
  Not published`, `REVOKED → Revoked`, everything else (including the stale
  `ACTIVE` value) → `Not published`. `ACTIVE` is never treated as live (G-J2).
- Every mutation sends `job.version`; `version == null` blocks assign/cancel
  with `jobsNoVersion`. No silent generic failure:
  `JOB_VERSION_CONFLICT/VERSION_CONFLICT/JOB_NOT_ASSIGNABLE → jobsConflictReload`,
  `CONSENT_REQUIRED → jobsPublicationBlockedBody`, 403 → `jobsForbidden`,
  404/`JOB_NOT_FOUND` → `jobsNotFound`.

## ACTION POLICY (pure, table-tested)

| Status | Primary | canAssign | canCancel | readOnly | requiresVersion |
|---|---|---|---|---|---|
| DRAFT | assign | yes | yes | no | yes |
| SCHEDULED | assign | yes | yes | no | yes |
| ASSIGNED | open job | yes | yes | no | yes |
| IN_PROGRESS | open job | yes | yes | no | yes |
| PENDING_REVIEW | review & approve | no | yes | no | yes |
| APPROVED + consent | publish checklist | no | no | no | no |
| APPROVED without consent | none | no | no | no | no |
| PUBLISHED | view public link | no | no | yes | no |
| REJECTED | open job | no | no | yes | no |
| CANCELLED | open job | no | no | yes | no |
| unknown | open job | no | no | yes | no |

"Publish checklist" opens the checklist page; it never calls `publishJob` (M6).

## FLOW PROOF

Tests + captures must show:

1. Assign → `assignCleanJob(job.id, techId, version: job.version)` and the
   assignment region reads the technician name (never the id).
2. Cancel with a reason → status `CANCELLED`, assign/cancel affordances gone.
3. Stale version → `jobsConflictReload` copy and no overwrite.
4. APPROVED without consent → no publish promise, locked reason
   (`jobsPublicationBlocked`), no action.
5. PUBLISHED → reads `Published`, no assign/cancel.

Evidence (real fonts): `docs/evidence/jobs_j1/detail_{1440,1280,1024,768,390,360}.png`,
`detail_1280_ar.png`, `detail_conflict_1280.png`, `detail_terminal_1280.png`.

## COMMANDS

```
dart format lib/src/features/jobs/job_detail_page.dart lib/src/features/jobs/detail lib/src/features/jobs/shared lib/src/features/jobs/assign lib/src/features/jobs/job_presentation.dart lib/src/features/jobs/job_widgets.dart test/job_detail_test.dart test/job_actions_policy_test.dart test/job_detail_capture_test.dart
flutter analyze --fatal-infos
flutter test test/job_detail_test.dart test/job_actions_policy_test.dart test/jobs_invariants_characterization_test.dart
flutter test test/job_detail_capture_test.dart
flutter test
```
