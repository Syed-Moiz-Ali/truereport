# Phase 2 Prompt — Workshop Admin + Clean URLs

You are continuing the TrueReport rebuild in:

`E:\syed_moiz_ali\bitlogix\truereport`

Phase 1 (Platform Admin) is accepted. The clean Platform Admin content lives in `platform_*` tables. Do not regress it.

## Read First

1. `docs/IMPLEMENTATION_PLAN.md`
2. `docs/BACKEND_REBUILD_PLAN.md`
3. `docs/FRONTEND_ADAPTIVE_RULES.md`
4. `docs/phase-plans/02-WORKSHOP_ADMIN.md`
5. `docs/I18N_PLAN.md`
6. `docs/PROFESSIONAL_FLOWS.md`
7. `docs/DECISIONS.md` (D-001 to D-057)
8. `docs/MIGRATION.md`
9. `docs/DYNAMIC_ISSUE_CONFIG.md`

## Non-Negotiable Rules

1. **Backend full rebuild.** Workshop Admin code must use clean `platform_*` tables. Do not build new features on legacy `inspection_jobs`, `job_assignments`, `reports`, or `public_share_links` tables. Legacy code may remain for the reference app but must not be used by new Workshop Admin flows.
2. **Frontend UI is reused.** Keep existing Workshop Admin screens, components, design system, visual identity. Adapt data wiring, state, and responsive layout only.
3. **No fixed layout widths/heights.** Use `LayoutBuilder`, `MediaQuery`, `Flexible`, `Expanded`, `Wrap`, `AspectRatio`, `ConstrainedBox`, breakpoints, design tokens.
4. **No Workshop/Technician/Public Report code outside Phase 2 scope.** No Technician inspection UI or Public Report page work.
5. **No post-publish corrections.** No correction/return flow. Rejection closes the job; a new inspection is required.
6. **Approval:** Workshop Admin only; approver must not be the assigned technician.
7. **Evidence rule:** every item requires ≥1 photo + ≥1 video for every result; FAIL ≥2 photos + ≥1 video.
8. **Documents:** generated automatically after publish, EN and AR PDFs, stored; no manual upload gate.
9. **No LLM/auto-translation.**
10. **No technician qualification, tool calibration, or QC sampling.**
11. **No commits unless explicitly asked.**
12. **Do not touch** the uncommitted `PublicReportService.java` / `print-report.html` work.
13. **Ask only when blocked.** Record decisions in `docs/DECISIONS.md`.

---

## Part A — Fix Platform Admin (and Workshop Admin) Web URLs

Problem: Flutter web currently uses hash URLs like `https://host/#/workshops`. This looks unprofessional.

Fix:
1. Add the Flutter SDK dependency to the affected app pubspec:
   ```yaml
   dependencies:
     flutter_web_plugins:
       sdk: flutter
   ```
2. Add conditional URL-strategy files in each web app:
   - `lib/src/web_url_strategy_stub.dart`
     ```dart
     void configureWebUrlStrategy() {}
     ```
   - `lib/src/web_url_strategy_web.dart`
     ```dart
     import 'package:flutter_web_plugins/url_strategy.dart';

     void configureWebUrlStrategy() {
       usePathUrlStrategy();
     }
     ```
3. In `main.dart`, before `runApp`:
   ```dart
   import 'src/web_url_strategy_stub.dart'
       if (dart.library.html) 'src/web_url_strategy_web.dart';

   void main() {
     WidgetsFlutterBinding.ensureInitialized();
     configureWebUrlStrategy();
     runApp(...);
   }
   ```
4. Apply to `platform_admin_app` and `workshop_admin_app`. Technician later.
5. Document the deployment requirement: the web server must rewrite unknown paths to `index.html` (Nginx `try_files $uri $uri/ /index.html;`, Firebase Hosting rewrite, Netlify redirect, etc.). Without this, deep links will 404.
6. Verify:
   - `/#/workshops` becomes `/workshops`
   - `/#/master-library` becomes `/master-library`
   - `/#/workshop` becomes `/workshop`
   - Refresh/deep-link works with the server rewrite.
7. Run `flutter analyze --fatal-infos` and the app tests.

---

## Part B — Workshop Admin Backend

### Clean schema (new migration V105+)

Create clean Workshop Admin tables. Do not reuse legacy job tables for new flows.

Suggested tables:
- `platform_jobs`
  - id, workshop_id, reference, status, review_status, publication_status
  - template_version_id (platform template version)
  - assigned_technician_id
  - customer_name, customer_phone, customer_email
  - vehicle_vin, vehicle_make, vehicle_model, vehicle_year, vehicle_plate,
    odometer_value, odometer_unit, transmission, fuel_type
  - preferred_language
  - scheduled_at, started_at, completed_at, approved_at, published_at, cancelled_at
  - approved_by, cancelled_by, cancel_reason
  - created_by, created_at, updated_at, version
- `platform_job_assignments`
  - id, job_id, technician_id, assigned_by, assigned_at, unassigned_at, reason
- `platform_job_status_history`
  - id, job_id, from_status, to_status, actor_id, occurred_at, reason
- `platform_job_approvals`
  - id, job_id, approved_by, approved_at, decision, reason
- `platform_public_links`
  - id, job_id, report_version_id, token_hash, status, pdf_download_enabled,
    activated_at, revoked_at, revocation_reason
- `platform_report_documents`
  - id, report_version_id, document_type_code, language, storage_key, mime, bytes,
    status, generated_at, error
- `platform_notifications`
  - id, workshop_id, user_id, type, payload_json, read_at, created_at

Add FKs, indexes, audit/outbox integration.

Job statuses:
- Inspection: `DRAFT`, `SCHEDULED`, `ASSIGNED`, `IN_PROGRESS`, `PENDING_REVIEW`, `APPROVED`, `PUBLISHED`, `REJECTED`, `CANCELLED`.
- Or preserve additive `review_status`/`publication_status` if cleaner. Document in `DECISIONS.md`.

### APIs

Base: `/api/v1/workshop`

Jobs:
- `GET /jobs` (paginated, filter by status/search/date)
- `GET /jobs/counts`
- `GET /jobs/{id}`
- `POST /jobs`
- `PUT /jobs/{id}`
- `POST /jobs/{id}/assign`
- `POST /jobs/{id}/cancel`
- `GET /jobs/{id}/assignments`

Templates:
- `GET /templates/available` (published platform templates)
- `GET /templates/{id}`

Review/approval:
- `GET /jobs/{id}/review`
- `GET /jobs/{id}/publish-checklist`
- `POST /jobs/{id}/approve`
- `POST /jobs/{id}/reject`

Publish:
- `POST /jobs/{id}/publish`
- `POST /jobs/{id}/unpublish`
- `POST /jobs/{id}/rotate-token`
- `POST /jobs/{id}/revoke`
- `GET /jobs/{id}/public-link`
- `GET /jobs/{id}/qr`

Documents:
- `GET /jobs/{id}/documents`
- `POST /jobs/{id}/documents/{type}/retry`

Notifications:
- `GET /notifications`
- `POST /notifications/{id}/read`

All write endpoints: `WORKSHOP_ADMIN` only, scoped by `workshop_id`.

### Business rules

- Customer name + phone required; email optional.
- VIN, make, model, year, plate, odometer, transmission, fuel required.
- Template must be published; pin its version at job creation.
- Assignment only to active technicians in the same workshop.
- Customer/vehicle edits only before finalization.
- Approver must be Workshop Admin and not the assigned technician.
- Approval requires:
  - all items assessed
  - evidence rules met
  - signature present
  - score/grade computed
  - safety cap explained
  - consent granted
  - approval checklist green
- Reject closes the job; no correction flow.
- Publish generates/activates token and QR.
- Unpublish/revoke requires reason and audit.
- Documents auto-generate EN + AR after publish; retry via outbox.
- All writes idempotent + optimistic concurrency.
- Structured EN/AR errors.

### Tests

- Job CRUD, filters, counts, tenant scoping.
- Template pinning.
- Assignment rules and audit.
- Approval checklist and approver ≠ technician.
- Reject/no-correction behavior.
- Publish/token/QR/unpublish/revoke.
- Document generation EN/AR and retry.
- Outbox/retry.
- Role denial.
- Localized errors.

---

## Part C — Workshop Admin Flutter

Reuse existing Workshop Admin app; do not redesign.

### Data layer
- Extend `AdminApi`/`ApiEndpoints` for the new endpoints.
- Add models: workshop job, job counts, assignment, review, publish checklist, public link, QR, report document, notification.
- Replace mock/demo data with API-backed Riverpod providers.
- Error mapping to inline fields.

### Screens
- Job creation wizard: customer → vehicle → template → technician.
- Job list with filters/counts/search.
- Job detail: progress, findings, evidence, review.
- Approve & Issue Certificate screen with score/grade/caps.
- Publish checklist screen.
- Public link + QR + share.
- Documents status/retry.
- Unpublish/revoke dialogs with reasons.
- Notification center.

### Adaptive
- No fixed layout dimensions.
- Test 360/600/768/1024/1440.
- EN/AR/RTL.
- Reuse design-system components.

### Localization
- All new UI strings in ARB.
- API `Accept-Language` already injected by `ApiClient`.
- Dynamic API content uses `label` / `labelEn` / `labelAr`.

---

## Verification

Backend:

```powershell
cd server
mvn "-Dtest=WorkshopAdminPhase2IT,WorkshopAdminIT,ArchitectureTest,SecurityEndpointInventoryIT,FlywayMigrationTest" test
mvn test
```

Expected: only the two known pre-existing report failures remain.

Frontend:

```powershell
cd client
flutter pub get
cd packages\l10n
flutter gen-l10n
cd ..\..
flutter analyze --fatal-infos
cd apps\platform_admin_app
flutter test
cd ..\workshop_admin_app
flutter test
```

URL checks:
- `/#/workshops` must not appear.
- `/workshops` must load directly after server rewrite.
- `/#/workshop` must not appear; `/workshop` must load.

## Acceptance Criteria

1. Platform Admin and Workshop Admin web apps use path URLs, not hash URLs.
2. Deep links work with the documented server rewrite.
3. Workshop Admin backend uses clean `platform_*` job tables, not legacy job tables.
4. Job create/list/detail/assign/counts work and are workshop-scoped.
5. Approval is Workshop-Admin-only and approver ≠ technician.
6. Reject closes job; no correction flow.
7. Publish creates token + QR; unpublish/revoke works with reason.
8. EN/AR documents generate after publish and retry safely.
9. Frontend reuses existing UI and is adaptive; no fixed layout sizes.
10. EN/AR/RTL tests pass.
11. Targeted backend tests pass; full suite only has known report failures.
12. `flutter analyze --fatal-infos` and Workshop Admin tests pass.
13. Docs updated (`DECISIONS.md`, `MIGRATION.md`).

## Output Format

Report:
- Files created/changed.
- Schema/API changes.
- URL strategy changes and deployment note.
- Commands run and results.
- Decisions recorded.
- Remaining blockers.

Do not claim completion unless the acceptance criteria are verified.
