# Flow — Workshop jobs (create → assign → technician visibility)

Scope: `workshop_admin_app` Jobs tab + `jobs` backend module + technician job list.

## Happy path — create a job

1. Workshop Admin opens Jobs → `features/jobs/jobs_tab.dart` / `dispatch/dispatch_queue.dart`.
2. Queue loads `GET /api/v1/workshop/jobs` and `GET /api/v1/workshop/jobs/counts`
   (`admin_api.dart:1035`, `:1255`) → `jobs/api/WorkshopJobAdminController.java:78,88`.
3. "New job" opens `job_creation_wizard_page.dart` (4 steps: customer, vehicle, template, technician).
4. Submit builds `NewCleanJob` in `wizard/wizard_form_state.dart:74` and calls `createCleanJob`
   (`dispatch/dispatch_create.dart:111`, `admin_api.dart:1055`).
5. `POST /api/v1/workshop/jobs` with `Idempotency-Key` → `WorkshopJobAdminController.java:93`.
6. `WorkshopJobAdminService.create` validates fields, requires a **published** template version, requires an active
   technician of the same workshop, generates `JOB-XXXXXXXX`, and chooses status
   `ASSIGNED` (technician set) / `SCHEDULED` (time set) / `DRAFT` (`WorkshopJobAdminService.java:200-251`).
7. Server inserts the job + history + outbox event + notification; returns `JobDto`.
8. UI returns to the queue, invalidates the list/counts, and the new row appears.
9. Technicians see it from `GET /api/v1/technician/jobs` (`technician/api/TechnicianInspectionController.java:63`)
   because `TechnicianInspectionService.listJobs` scopes to workshop + assigned technician.

## Branches

- **Assign/reassign** → `POST /workshop/jobs/{id}/assign`; allowed in DRAFT/SCHEDULED/ASSIGNED/IN_PROGRESS; history and
  technician notification are written (`WorkshopJobAdminService.java:302-336`).
- **Cancel** → `POST /workshop/jobs/{id}/cancel` with a required reason; blocked for APPROVED/REJECTED/PUBLISHED
  (`:339-364`).
- **Update** → `PUT /workshop/jobs/{id}` only in editable statuses, optimistic version check.
- **Validation** → missing phone/vehicle fields return `JOB_VALIDATION_FAILED` with per-field issues; VIN is 17 chars
  in the UI (`wizard_form_state.dart:63-70`) but the server does not currently enforce the same VIN rule
  (`VALIDATION_GAP`, see gaps).
- **Empty state** → `dispatch_states.dart` empty queue; counts all zero.
- **Wrong tenant** → neutral 404 from `requireJob` (no cross-workshop leakage).
- **Schedule or start now** → the technician step offers **Start immediately** (null `scheduledAt`, DRAFT/ASSIGNED) or
  **Schedule for later** (date + time picker, `SCHEDULED`). The API accepts the chosen wall time and the queue shows it.
  Verified: create with `scheduledAt=2026-12-01T10:30:00` → `status=SCHEDULED`.
- **Consent** → the wizard sends `consentGranted:false`; the Workshop job detail now grants/withdraws consent via
  `PUT /workshop/jobs/{id}/consent`, so publish is reachable.
- **Customer/vehicle fields** → UI/API capture `transmission` and `fuelType` but not `drivetrain`/`engineSize`, which
  the product blueprint calls mandatory and the public report hardcodes.

## Cross-app flow

Actor WA → observer TA: create/assign job → technician refresh (or app open) must show it. No push channel is used
for jobs; propagation is next fetch. Declared window for the E2E spec: **visible within 10 s of a reload**.

## Verification status

Server: `WorkshopJobAdminIT`, `WorkshopJobCountsIT`, `TechnicianInspectionIT`.
Client: job queue/wizard widget tests (47 files across the app).
Browser: pending — this is the first vertical-slice spec.
