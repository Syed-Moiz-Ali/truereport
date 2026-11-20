# Flow — Dashboards and KPI truth

## Platform Admin dashboard

1. `/dashboard` → `client/apps/platform_admin_app/lib/src/features/dashboard/dashboard_screen.dart:45`.
2. Provider calls `GET /api/v1/platform/overview` (`platform_config_api.dart:474`).
3. `PlatformOverviewController` → `PlatformOverviewService.overview()`.
4. Every number is a direct SQL aggregate, not client math:
   - workshops total/active → `SELECT COUNT(*) FROM workshops ...` (`PlatformOverviewService.java:37-39`)
   - technicians/admins → `workshop_memberships` (`:40-42`)
   - active/pending jobs → `platform_jobs` status sets (`:43-45`)
   - reports active links / published jobs (`:46-49`)
   - checklist counts (`:62-66`) and language lifecycle counts (`:67-69`)
   - recent audit activity (`:87-109`), alerts for incomplete translations, failed documents, published jobs without
     active links (`:111-168`).
5. UI renders only those fields (`dashboard_screen.dart` comments: "nothing is derived or invented").

**Verdict:** numbers trace to the database. No FAKE_DATA found here. The only risk is definitional: "active jobs"
means DRAFT/SCHEDULED/ASSIGNED/IN_PROGRESS, not "today"; the UI labels must match that definition (checked in browser
QA).

## Workshop Admin dashboard

1. `features/dashboard/dashboard_tab.dart` + `widgets/dashboard_*`.
2. Counts come from `GET /api/v1/workshop/jobs/counts` (`admin_api.dart:1255`) and the job page
   (`GET /workshop/jobs`), both workshop-scoped.
3. `WorkshopJobAdminService.counts` merges `store.statuses(workshopId)` and maps each lifecycle status
   (`WorkshopJobAdminService:171-190`). The returned DTO exposes draft/scheduled/assigned/inProgress/pendingReview/
   approved/published/rejected/cancelled/total.
4. No local arithmetic was found for the headline counts; filters/search reuse the same backend page.

**Verdict:** traces to real jobs. No dedicated dashboard test exists, so the rendering/labels are UNVERIFIED until the
browser spec.

## Technician dashboard (queue)

Not a KPI dashboard: the queue header builds counts from the fetched page
(`technician_jobs_clean_page.dart:711-764`). Because it counts only the current page (default size 20), the label must
not read as a global total. Flagged as a UX/metadata risk, not fabricated data.
