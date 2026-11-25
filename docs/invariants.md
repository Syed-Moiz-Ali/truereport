# Invariants — technician jobs module

Behavior that a UI rebuild must not change. Enforced locations are from reading the module; there is no
test on any of them (see `baseline_allowlist.md`).

| # | Invariant | Enforced | Tested |
|---|---|---|---|
| 1 | Only `TECHNICIAN` role reaches `/jobs*`; assignment scoping is server-side (`/api/v1/technician/jobs`) | `technician_router.dart` guard, `AuthService`/`TechnicianStore` | none |
| 2 | Job list is fetched once (paged, created-at desc, ≤50) and day-filtered on the client | `TechnicianStore.java:167-184`, `technician_jobs_clean_page.dart:422-450` | none |
| 3 | A job with no cover photo and no completed items opens the **blocking** vehicle-photo gate; a photo-service **error** must render the deck with a retry banner instead | `technician_workspace_page.dart:63-105` | none |
| 4 | Item → next uses `pushReplacement`, so one back returns to the ledger; "Save & finish" on the last item pops to the ledger | `assessment_screen.dart:846-858` | none |
| 5 | Completion path is job → summary → review/signature → completed, reachable both from the deck footer and the ledger tail | `inspection_deck.dart:967-973, 1034-1086`, router `/summary`, `/signature`, `/completed` | none |
| 6 | Assessment and evidence writes still queue offline, survive restart, flush on reconnect, and show "saved on this phone" until the op is `RECEIVED` | `offline_store.dart:331-435`, `assessment_screen.dart:1251-1254` | none |
| 7 | Per-job pending-operation and conflict counts stay available to the list UI | `offline_store.dart:480, 538` | none |
| 8 | Completed/finalized jobs are read-only server-side (`JOB_NOT_EDITABLE`); the UI must not imply they are editable | `TechnicianInspectionService.java:757-760` | none |
| 9 | Item codes are URI-encoded in navigation and deep links keep resolving | `assessment_screen.dart:856`, router | none |
| 10 | Directionality/RTL is app-wide (`UiDirectionality`) and every new row/nav must stay mirrored | `app.dart:45` | none |

## Known contradictions the rebuild must fix (not preserve)

- `inspection_deck.dart:911-915`: the `Continue checklist` branch is unreachable because `next` is by
  definition unchecked; the primary action always says "Start".
- "You are all caught up" is computed from the **selected section** but claims global completion
  (`inspection_deck.dart:97-107`), and the list reuses the same string when a status filter is empty.
- Days are bucketed by `startedAt ?? scheduledAt` but labelled with `scheduledAt ?? moment`, so a job
  can sit under today with yesterday's time.
- The day rail cannot reach dates before today, while the API returns them.

## Deletable (kill list candidates, verified unreferenced in `lib/`)

`features/inspection/inspection_hub_view.dart` (859 ln), `features/jobs/job_intake_view.dart` (1154 ln),
`features/jobs/consent_view.dart` (697 ln), `features/jobs/equipment_view.dart` (440 ln),
`features/jobs/empty_jobs_view.dart` (827 ln), `features/jobs/assigned_jobs_view.dart` (1376 ln).
Total ≈ 5,350 lines of dead screen code that still compiles and misleads anyone reading the module.
