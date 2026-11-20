# Cross-app flows (actor → observer → expected visibility)

No realtime channel is used for jobs, templates, reports or deliveries. Propagation is on the next fetch/reload.
The E2E contract in this repo therefore declares "visible within **10 s of a reload**" (poll with reload, never sleep).

| # | Actor | Action | Observer | Must become visible | Contract source | Window |
|---|---|---|---|---|---|---|
| X1 | Platform Admin | Create/update/deactivate workshop; create staff | Platform Admin list; Workshop Admin can sign in | Row/staff appears; disabled user cannot sign in | `PlatformWorkshopService`, `HierarchyService` | 10 s reload |
| X2 | Platform Admin | Publish master item version | Workshop Admin template builder | Item selectable in workshop master catalog | `/workshop/master/items` reads published versions | 10 s reload |
| X3 | Platform Admin | Change language coverage/translations | All apps | UI strings/locale update on next app load/bundle fetch | `/i18n/ui-messages/bundle`, `StaticLanguageSync` | 10 s reload |
| X4 | Workshop Admin | Create + assign a job | Technician app queue | Job appears with reference/vehicle; checklist opens | `platform_jobs` → `GET /technician/jobs` | 10 s reload |
| X5 | Technician | Save assessment / complete | Workshop Admin job detail/review | Progress and `PENDING_REVIEW` status | `platform_assessments`, job status | 10 s reload |
| X6 | Workshop Admin | Approve | Technician app (report status, legacy) and Workshop report page | APPROVED + report version ready | `platform_report_versions` | 10 s reload |
| X7 | Workshop Admin | Publish | Public viewer | Active `/r/{token}` renders the report | `platform_public_links` + report version | 10 s reload |
| X8 | Workshop Admin | Revoke/unpublish | Public viewer | Neutral 404 within the same request | link ACTIVE→REVOKED | immediate |
| X9 | Workshop Admin | Queue delivery | Delivery worker + Platform delivery list API | Delivery row with status; retry available | `report_deliveries` | 10 s poll |
| X10 | Technician | Offline sync conflict | Technician sync page | Conflict listed and resolvable | `platform_sync_conflicts` | 10 s reload |

## Known cross-app breaks

- **X4/X6 consent**: the technician consent form writes `consent_records` (legacy), while publish reads
  `platform_jobs.consent_granted` (clean). Recording consent in the Technician app does not unblock X7.
- **X7 data**: even when publish succeeds, the observer sees fabricated report sections (see `public_report.md`).
- **X9 UI**: the platform delivery observer has an API but no screen, so the "admin revenue/ops" equivalent cannot be
  observed in the Platform app.
