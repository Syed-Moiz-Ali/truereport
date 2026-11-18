# Invariants — Workshop Admin (Phase 0, dashboard + jobs)

Scope: `dashboard` (`dashboard_tab.dart`), the jobs queue (`jobs_tab.dart`), the
client-visible job board (`jobs_board_tab.dart`) and `job detail`
(`job_detail_page.dart`), plus the shell and data layer they depend on.

Written read-only. No app code was changed to produce this file.
The sign-in invariants from the previous wave live in
`docs/briefs/brief-2-mini-results.md` and are still enforced; they are not
restated here except where a new screen could regress them.

| # | Invariant | Where enforced | Where tested | Status |
|---|---|---|---|---|
| J1 | **Two job models, never mixed.** `WorkshopJob` is the workshop lifecycle (`IN_PROGRESS`, `READY_TO_FINALIZE`, `FINALIZED`); `CleanJob` is the client-visible record (`PENDING_REVIEW`, `APPROVED`, `PUBLISHED`, `REJECTED`, `CANCELLED`) with review/publication sub-status. A screen may render one world's vocabulary, never both. | `workshop_job_models.dart`, `models.dart`, `jobs_tab.dart:112-115`, `jobs_board_tab.dart:145-149` | queue + board tests assert their own chips only | **PARTIAL** — nothing prevents a future screen mixing them |
| J2 | **Dashboard counts come only from `/workshop/jobs/counts`.** No client-side derivation and no fallback numbers; a failure renders one bounded error, never guessed figures. | `admin_api.dart:843-849`, `dashboard_tab.dart:102-114` | `dashboard_test`: "counts error shows one bounded error, no numbers" | **PINNED** |
| J3 | **Queue chip counts are client-derived** from a *search-scoped, status-unfiltered* snapshot (`jobsProvider(search + '' + status)`), so the chips can only ever describe the rows currently reachable by the search. | `jobs_tab.dart:32-38, 47, 118-126` | `jobs_queue_test`: "search narrows the queue and rescopes chip counts" | **PINNED** |
| J4 | **Board counts come only from `/workshop/clean-jobs/counts`**, scoped to the same filter predicate as the page. | `workshop_job_providers.dart:54-58`, `jobs_board_tab.dart:61, 143-149` | `jobs_adaptive_test`: "job board renders counts, filters and API jobs" | **PINNED** |
| J5 | **"In progress" is not the same number on the dashboard and in the queue.** J2 aggregates the whole workshop; J3 counts only the current search snapshot. The two may legitimately differ, so they must never be presented as the same figure. | derived from J2 + J3 | none | **UNPINNED — contradiction risk** |
| J6 | **Lifecycle mutations are optimistic-concurrency guarded.** Assign and cancel send the job `version`; a stale version must surface a failure, never silently overwrite. | `admin_api.dart:1176-1204`, `job_detail_page.dart:234-241, 274-276` | none | **UNPINNED** |
| J7 | **Terminal jobs are read-only.** `FINALIZED`, `PUBLISHED` and `CANCELLED` hide assign/cancel; a finalized job offers the report instead. | `job_detail_page.dart:47-51, 868-884` | `job_detail_test`, `dashboard_test`: "finalized job offers the report, no mutations" | **PINNED** |
| J8 | **Cancel requires a reason** and is confirmed in a sheet; the reason is stored and rendered in the detail facts. | `job_detail_page.dart:263-276`, `_CustomerVehicleSection` cancelReason fact | none | **PARTIAL** — UI path only |
| J9 | **Publishing is gated by the checklist.** A blocked checklist disables publish; publishing makes the public link live. | `publish_checklist_page.dart` | `jobs_adaptive_test`: ready/blocked publish states | **PINNED** |
| J10 | **A revoked public link is never presented as live.** Publication status maps `REVOKED` → revoked tone, everything else not `ACTIVE` → "not published". | `job_detail_page.dart:304-315` | none | **UNPINNED** |
| J11 | **No fabricated data anywhere.** Empty lists render empty states, failures render bounded errors, no sample numbers fill a real screen. | `admin_api.dart:844-846`, screen state handlers | `no_fabricated_data_test`, `dashboard_test` | **PINNED** |
| J12 | **Every visible string is localized in `en` and `ar`.** Prose is a single ARB message with placeholders, never concatenated. | ARB files | screenshots include 1280 AR | **VIOLATED** — `dashboard_tab.dart:54` (`'Today, $todayFormatted'`) and `:46-48` (greeting by concatenation) |
| J13 | **RTL**: directional padding/icons mirror; data-like values (plate, VIN, phone, dates, references) stay LTR. | `EdgeInsetsDirectional`, explicit `TextDirection.ltr` on facts | queue/dashboard AR tests + matrix | **PARTIAL** — LTR facts cover plate/VIN/phone; not every value |
| J14 | **Stable test keys** are the contract: `dashboard-stat-*`, `dashboard-job-<id>`, `dashboard-pipeline-bar`, `jobs-search`, `job-<id>`, `jobs-queue-total`, `jobs-filter-<status>`, `jobs-job-<id>`, `job-detail-refresh`, `workshop-tab-*`. | the screens | all four test files | **PINNED**, except the queue chips have no key (`jobs_tab.dart:104-109`) |
| J15 | **Navigation contract**: six tabs by index (0 dashboard, 1 jobs, 2 staff, 3 templates, 4 job board, 5 settings), selected through `WorkshopNavigationScope.select`; tabs are kept alive in an `IndexedStack`. | `workshop_admin_home.dart:73-148` | `dashboard_test`: "tab navigation reaches every tab" | **PINNED** |
| J16 | **The `Jobs` tab opens a quick sheet; the `Job Board` opens the detail page.** Two different interaction models exist on purpose today. | `jobs_tab.dart:258-264`, `jobs_board_tab.dart:315-318` | queue + board tests | **PINNED** (questionable — see audit A7) |
| J17 | **Theme is light-only by decision** (waiver W-LIGHT, countersigned). New screens must not invent dark mode. | `AppTheme.build`, `ui_matrix_test` | `ui_matrix_test` | **PINNED** |
| J18 | **Sign-in invariants stay pinned** through this rebuild: redirects, single-submit, error mapping, no TOTP UI, Arabic parity. | previous wave | `signin_characterization_test` etc. | **PINNED** |

## Notes

- **J5 is the reason Phase 1 exists.** Two surfaces can legitimately show two
  numbers under the same label ("In progress"), and nothing in the UI explains
  why. Either the labels must differ or the scopes must be made identical.
- **J6 and J10 are unpinned.** Both are money-adjacent in consequence: a stale
  write can silently move a job, and a revoked link shown as live is a privacy
  problem for the customer.
- **J12 is a real defect, not a missing test** — the dashboard is half-English in
  the Arabic build.
- J1/J16 are the structural questions Phase 3 must answer, not Phase 2: whether
  "Jobs" and "Job Board" stay two products or converge on one model.
