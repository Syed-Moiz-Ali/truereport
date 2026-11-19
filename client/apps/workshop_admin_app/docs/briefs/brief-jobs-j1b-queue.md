# Brief J1b — job queue, legacy archive, legacy family deletion

WORKDIR: `client/apps/workshop_admin_app`
MODE: implement (UI + data + tests + evidence)
COMMITS: none

## OUTCOME

The primary jobs queue is rebuilt as direction A "the counter" on `CleanJob`:
server-scoped status strip, server-paginated sheet, local page sort, a fixed
380 px inspector (wide) / full-width region (mid) / cards (phone), and a
read-only legacy archive as the only surviving legacy surface. The legacy queue
family (quick sheet, schedule sheet, legacy counts, legacy assign dialog, legacy
count/mutation API) is deleted in the same change.

## SCOPE (owned)

- `lib/src/features/jobs/queue/**` (new regions)
- `lib/src/features/jobs/archive/**` (new)
- `lib/src/features/jobs/jobs_tab.dart` (thin `JobsTab` wrapper)
- `lib/src/features/jobs/job_presentation.dart` (legacy half deleted)
- deletions: `job_quick_sheet.dart`, `schedule_job_sheet.dart`,
  `job_counts.dart`, `assign_technician_dialog.dart`
- `admin_api.dart`, `admin_providers.dart`, `packages/api_client/.../api_endpoints.dart`
  (legacy count/mutation members only)
- tests named in the task + new queue/archive/capture tests

Not owned: detail/**, shared/**, assign/**, board, wizard, approve, checklist,
documents, public link, notifications, shell/home, packages/design_system, l10n,
pubspec.

## DATA RULES

- Rows and the list: `cleanJobsProvider(cleanJobsKey(page, size: 10, status, search))`.
- Status strip: `cleanJobCountsProvider` only. No client-derived counts.
- Status and search are server-side; both reset to page 0. Search debounced
  300 ms (`jobs-search`).
- Footer shows the server `total`, never `items.length` as a total.
- Sort is local to the loaded page and the footer says `jobsSortNote`.
- No `createdAt`-derived ages, no "today", no "active".

## REGIONS

```
queue/jobs_queue_page.dart      state: search/status/page/selection/sort (<=220)
queue/jobs_queue_header.dart    eyebrow, title, meta, New job, archive overflow
queue/jobs_status_strip.dart    "Workshop totals" + All + 9 server-counted statuses
queue/jobs_queue_table.dart     wide sheet, sortable Job/Vehicle/Customer/Technician
queue/jobs_queue_cards.dart     phone cards with the policy primary action
queue/jobs_inspector.dart       380 px / full-width inspector, policy action
queue/jobs_queue_footer.dart    range + prev/next + sort note
queue/jobs_queue_states.dart    loading / list error / empty / filtered empty
archive/legacy_archive_page.dart read-only legacy list + banner
```

## POLICY REUSE

`jobActionsFor(status, consentGranted)` from `shared/job_actions.dart`, and the
existing routes: `showAssignSheet`, `ApproveIssuePage`, `PublishChecklistPage`,
`PublicLinkPage`, `JobDetailPage`, `JobCreationWizardPage`. APPROVED without
consent shows `jobsPublicationBlocked` + `jobsPublicationBlockedBody` + a
checklist link, never a publish promise. Mutations send `job.version` and are
blocked when it is null.

## KILL LIST

Files: `job_quick_sheet.dart`, `schedule_job_sheet.dart`, `job_counts.dart`,
`assign_technician_dialog.dart`. Symbols: `JobListHeader`, `JobListRow`,
`JobListRow` internals, `jobVehicleTitle`, `jobVehicleMeta`, `jobScheduleLabel`,
`jobTemplateLabel`, `_rowSemanticLabel`, `JobCounts`, `jobCountsProvider`,
`AdminApi.jobCounts/createJob/assignJob/cancelJob` and their endpoints.
Tests: `schedule_job_sheet_test.dart`, `job_counts_test.dart`,
`assign_technician_dialog_test.dart`.

## ACCEPTANCE

- Filter by status -> request carries `status`, page resets, rows match.
- Counts -> server counts only; counts error shows labels without numbers.
- Select -> inspector shows that job; close clears selection.
- Pagination -> footer range from server `total`, prev/next change the page.
- Phone -> card footer carries the same policy action; body opens detail.
- Archive -> opens from the header overflow, banner, read-only, no actions.
- Source scan -> no legacy symbol under `features/jobs/` except `archive/`.
- Evidence: `docs/evidence/jobs_j1/queue_{1440,1280,1024,768,390,360}.png`,
  `queue_1280_ar.png`, `queue_loading_1280.png`, `queue_error_1280.png`,
  `queue_empty_1280.png`, `queue_filtered_empty_1280.png`, `archive_1280.png`.
- `dart format`, `flutter analyze --fatal-infos`, `flutter test` green.
