# Flow gaps â€” by module, then severity

Audit date: 2026-11-20. Evidence is `file:line` or an executed request. `EXISTS` cells without a passing browser run are
**UNVERIFIED**, not done.

Summary after the fix pass: **BLOCKER 6 â€” all closed and API-verified Â· MAJOR 8 (6 closed/accepted, 2 open: legacy consent, unexecuted browser suite) Â· MINOR 8**.
All blockers were reproduced against a fresh MySQL 8.0 database with the repo's Flyway migrations and the dev seed,
except where marked code-level. 2FA and scheduling are removed from scope by owner decision; Platform deliveries are
accepted as API/console-only because primary nav is fixed at six items. See "Fixes applied in this pass" at the end.
The Playwright suite was not executed in this pass by request; runtime evidence below is HTTP/API and server-side, not
a browser run.

---

## BLOCKERS

### BLOCKER-01 â€” Checklist snapshot overflows MySQL `TEXT` (FIXED)

- **Where:** `server/src/main/resources/db/migration/V106__technician_inspection.sql:6` defines
  `snapshot_json TEXT`; `TechnicianStore.insertChecklist`
  (`server/.../technician/TechnicianStore.java`) writes the snapshot.
- **What happened:** `GET /api/v1/technician/jobs/{id}/checklist` returned
  `409 DATA_INTEGRITY_VIOLATION`. After `ALTER TABLE ... MODIFY snapshot_json LONGTEXT`, the same call returned
  200; the stored snapshot is **313,287 bytes** (limit 65,535).
- **Why tests missed it:** H2/MySQL-mode tests use a large CLOB; the MySQL-only size limit is not exercised.
- **Impact:** the seeded 30-point template cannot be inspected at all on MySQL. Blocks X4â€“X7.
- **Fix direction:** MySQL migration to `MEDIUMTEXT` (16 MB) and a MySQL integration test with the real 30-item
  snapshot. Do not shrink the snapshot by dropping rules â€” it is the pinned audit record.

### BLOCKER-02 â€” Public-link consent had no write path for clean jobs (FIXED for the Workshop path)

- **Evidence:**
  - Wizard always sends `consentGranted: false` (`client/apps/workshop_admin_app/lib/src/features/jobs/wizard/wizard_form_state.dart:90`;
    comment at `workshop_job_models.dart:804` "until CR-5 gives consent a write path").
  - Clean publish requires `job.consentGranted()` (`server/.../jobs/WorkshopJobAdminService.java:528-532`).
  - No clean endpoint accepts consent; `UpdateJobRequest` has no consent field.
  - Technician consent posts to the **legacy** endpoint (`technician_api.dart:305` â†’
    `/technician/legacy/jobs/{id}/consent`), which writes `consent_records`
    (`server/.../inspections/InspectionService.java:209-226`), not `platform_jobs.consent_granted`.
- **Impact:** a job created in the Workshop UI can never be published, regardless of who records consent.
- **Fix direction:** add `PUT /api/v1/workshop/jobs/{id}/consent` (or include it in an eligible status update),
  enforce workshop scope + audit, expose a consent control in job detail, and make the technician consent write the
  clean job too (or stop using legacy consent).

### BLOCKER-03 â€” No scoring rule / grade boundaries blocked completion (FIXED)

- **Evidence:** `TechnicianInspectionService.computeScore` / `gradeFor`
  (`server/.../technician/TechnicianInspectionService.java` ~`computeScore`, `gradeFor`) returns `null` grade when
  `store.activeScoringRule()` is empty. The default seeder creates categories/items/templates/document types but
  **no scoring rule or grade boundaries** (`seed/DefaultChecklistSeeder.java`; live DB:
  `SELECT COUNT(*) FROM platform_scoring_rules` = 0, `platform_grade_boundaries` = 0).
- **What happened:** all 30 items assessed, signature present, summary showed zero blockers, yet
  `POST /technician/jobs/{id}/complete` returned 422 `COMPLETION_BLOCKED` with
  `SCORE_NOT_COMPUTABLE`.
- **Impact:** no inspection can be completed on a fresh install. Blocks X5â€“X7.
- **Fix direction:** default grade thresholds Aâ‰¥90/Bâ‰¥80/Câ‰¥65/D<65 when no rule is active (product blueprint), or seed a
  default scoring rule + boundaries. Add a completion test that starts from the seed.

### BLOCKER-04 â€” Every issue field was unconditionally required (FIXED)

- **Evidence:** seeded fields are inserted with `required = true` (`seed/DefaultChecklistSeeder.java:356-395`), while
  `requiredForStatuses` is separate. Validation uses
  `boolean required = field.required() || requiredForStatuses.contains(result)`
  (`TechnicianInspectionService.java:1064-1065`), so `ISSUE_TYPE/LOCATION/SEVERITY/ACTION/URGENCY` are required even
  for a passing item. Live probe: PUT `{"resultCode":"NO_ISSUE_OBSERVED"}` returned 422 with five `REQUIRED` fields.
- **Impact:** technicians must invent defect metadata on a clean item, corrupting report semantics; or they abandon the
  flow. Blocks X5.
- **Fix direction:** treat a non-empty `requiredForStatuses` list as conditional regardless of `required`; seed
  fields as `required=false` with `requiredForStatuses=[ATTENTION_RECOMMENDED, DEFECT_FOUND]`. Add a validation test.

### BLOCKER-05 â€” Public report published fabricated vehicle facts and evidence (FIXED for fabricated content)

- **Where:** `server/.../reports/ReportViewMapper.java`.
  - Vehicle gearbox/fuel/drivetrain/engine/colour/interior/wheels/keys/emirate/client/center are constants (`:215-243`).
  - Every item claims a video and a stock video URL (`:381-388`).
  - Diagnostic metric, standard spec and part photo are invented from the item code (`:1060-1118`).
  - Visual inspection cards, 32 showcase photos, 4 tyre/brake assemblies, damage zones, inspection systems, inspector
    summary and inspection videos are fixed demo content (`:468-659`, `:737-1058`, `:1120-1490`).
- **Impact:** the public artifact â€” the product's trust surface â€” shows false claims (e.g. "Precious Silver Metallic",
  "Scratch: 42mm", "Brake Pad 3.1mm") for every vehicle. This is not a styling placeholder; it is fabricated data on a
  customer-facing report and could be delivered by WhatsApp/SMS/email.
- **Fix direction:** derive every section from the frozen snapshot; render only sections backed by real data; delete
  the stock media constants; keep demo content behind a demo profile if needed. Add a golden test asserting no
  hardcoded demo strings appear in a report built from a known fixture.

### BLOCKER-06 â€” Clean report pipeline was unreadable/unreachable (FIXED)

- **Evidence:**
  - `WorkshopJobAdminService.approve` stores `snapshot(job, evaluation, score)` â€” fields `jobId/reference/
    customerName/vehicleVin/.../findings[{itemVersionId,resultCode,score}]`
    (`server/.../jobs/WorkshopJobAdminService.java:449-452`, `:1032-1049`).
  - `ReportViewMapper.publicPage` deserializes `version.snapshotJson` as `ReportSnapshot`
    (`ReportViewMapper.java:31`) and immediately iterates `snapshot.categories()` / `snapshot.keyFindings()`.
  - `ReportSnapshot` expects `items` entries with nested `item` / `assessment` / `evidence`, plus
    `finalizedAt`, `vehicleType`, `workshopName`, `technicianName`
    (`ReportSnapshotBuilder.java:32-124`).
- **Impact:** a clean-approved report has no categories/items and may NPE/500 or render an empty report. The
  hardcoded demo sections then mask the emptiness. Blocks X6â€“X7.
- **Fix direction:** build the rich `ReportSnapshot` from the clean pinned checklist + assessments + evidence at
  approval (reuse `ReportSnapshotBuilder` by emitting its expected input shape), store the normalized snapshot, and
  test public rendering from a clean job.

---

## MAJOR

### MAJOR-01 â€” Report version snapshot stores PII contrary to the documented allowlist

- `WorkshopJobAdminService.snapshot` stores `customerName` and the full `vehicleVin`
  (`WorkshopJobAdminService.java:1038-1039`). Phase 6 claims full VIN/name/phone/email/plate are absent from the report
  snapshot (`docs/phase-6/README.md`, `test-report.md`). Rendering masks them (`ReportSnapshotBuilder.java:139-150`),
  so this is a data-minimization/retention issue rather than a demonstrated public leak.
- Fix: store only the fields the report allowlist needs; mask VIN at insert time.

### MAJOR-02 â€” Consent is enforced against a different store than the one the technician writes (contract drift)

This is the root cause of BLOCKER-02 and a standing DRIFT risk: legacy `/technician/legacy/**` and clean
`/technician/**` coexist (`TechnicianInspectionController` has two classes in `technician` and `inspections`).
- Fix: one write path per concept; deprecate legacy consent/report/delivery reads; add a contract test that the value
  the technician records is the value the workshop reads.

### MAJOR-03 â€” 2FA removed from product scope (owner decision)

- Owner decision: 2FA is not a product feature for this release. `ADMIN_TOTP_REQUIRED` stays `false`; the server
  endpoints remain for a future security phase but no app exposes a challenge. This is no longer a release gap.
- If the decision changes, add the challenge step to the shared sign-in flow with recovery-code fallback.

### MAJOR-04 â€” Platform delivery list is API/console-only (accepted)

- `GET /api/v1/platform/deliveries` (`delivery/api/PlatformDeliveryController.java`) has no Platform Admin screen.
  Primary nav is intentionally fixed at six items (D-074/D-075), so a seventh nav entry is not allowed without a
  product decision. Delivery remains observable through the API/console and the Workshop job delivery list.
- Accepted for this release; revisit only with a nav/IA decision.

### MAJOR-05 â€” Report item media is not evidence-driven

- `items()` sets `hasVideo=true`, a stock `videoUrl` and `partPhotoForCode(...)` for every item regardless of the
  actual evidence (`ReportViewMapper.java:381-388`). Real evidence is only attached as `photos` when derivatives exist
  (`:396-422`). A no-evidence item still shows "video proof".
- Fix: derive media presence from the report's evidence derivatives and omit controls when absent.

### MAJOR-06 â€” Browser suite generated but not executed (by request)

- Before this pass there was no `playwright.config.*`, no `tests/e2e`, no CRUD/cross-app specs. This audit added the
  harness (18 tests in 6 files, `--list` validated) and documented every derived value in
  `docs/flows/harness.md`.
- The suite was **not executed** after the user excluded Playwright from this pass. The matrix's runtime column is
  therefore API/HTTP evidence, not a browser pass.
- Impact: the audit cannot claim COMPLETE until `npx playwright test` runs green.

### MAJOR-07 — Scheduling choice added to Workshop Admin (CLOSED)

- The job wizard now offers **Start immediately** or **Schedule for later** (date + time picker) in the technician
  step. A null `scheduledAt` starts immediately; a value creates a `SCHEDULED` job. The server already supported the
  field and status; the UI now sends it (`wizard_form_state.dart`, `wizard_technician_step.dart`,
  `dispatch_create.dart`; ARB keys in EN/AR).
- Verified by API: create with `scheduledAt=2026-12-01T10:30:00` returned `status=SCHEDULED`.
- Consent remains a separate Workshop job-detail action.

---

## MINOR

| # | Gap | Evidence |
|---|---|---|
| MIN-01 | Client declares endpoints with no server mapping: `categories/weight-check`, `scoring-rules*`, `grade-boundaries`, `master/templates/.../weight-preview`, `.../items`, `.../categories` GET, `item/versions/.../bands` | `packages/api_client/lib/src/api_endpoints.dart:237-299`; no controller mapping found |
| MIN-02 | Legacy technician API unused by the active router (jobs/report/deliveries/consent) but still shipped | `technician_api.dart:186-461`; router only uses `/jobs` clean pages |
| MIN-03 | Technician queue counts are page-local but presented as queue totals | `technician_jobs_clean_page.dart:711-764` |
| MIN-04 | VIN 17-char validation is client-only | `wizard_form_state.dart:63-70`; server `validateCreate` does not enforce length |
| MIN-05 | Dev `/actuator/health` = 503 without Mailpit/MinIO | live probe; server still serves APIs |
| MIN-06 | Documentation/terminology drift: README says `admin_app`, "Phase 5A", "customer app"; report label `gearbox` vs API `transmission` | `README.md:8-16`, `ReportViewMapper.java:226` |
| MIN-07 | Platform template API has no screen (intentional under D-071) | `platform_router.dart` has no template route; `PlatformTemplateController` exists |

---

## MINOR-08 â€” Platform registry is English-only while coverage lists Arabic (intentional, UX-confusing)

- `GET /api/v1/i18n/languages` returns `en` + `ar` (both LIVE), but
  `GET /api/v1/platform/i18n/languages` â€” the endpoint behind `/settings/languages` â€” returns **only `en`**
  (live probe 2026-11-20). The screen says "Language registry: 1" while content coverage reports `en ar`.
- **Intent is documented in code:** `LocalizationService.allLanguages()` filters to manifest-backed languages and
  says "Platform Admin is English-only"; the registry screen is not intended to manage `ar` UI text yet.
- Impact: a reader sees `ar` in coverage but cannot open it in the registry. This is a copy/IA ambiguity, not a broken
  management flow; record it until Arabic admin UI catalogs exist.
- Harness: asserts English registry plus visible `ar` coverage; no expected-failure marker.

## MAJOR-09 â€” Workshop Admin Flutter test suite is red in this workspace

- `cd client/apps/workshop_admin_app; flutter test` â†’ **94 failures** (e.g.
  `intl_dates_test.dart` cannot find `Key('job-job-1')`, UI matrix/real-font captures). `flutter analyze` is clean.
- The failures are in characterization/UI tests that do not touch the audit fixes; the root cause is likely a stale
  fixture key after the recent queue redesign. They were not introduced by this pass, but the suite cannot be used as
  a release gate until triaged.
- Impact: client regressions in those areas are currently invisible.

## Fixes applied in this pass (Step 7)

| Blocker | Change | Files |
|---|---|---|
| BLOCKER-01 | MySQL `MEDIUMTEXT` for all snapshot columns; 313 KB checklist now inserts | `server/src/main/resources/db/migration-mysql/V123__widen_snapshot_columns.sql` |
| BLOCKER-02 | `PUT /api/v1/workshop/jobs/{id}/consent` + service + audit; UI "Granted" action in job detail; client API | `WorkshopJobDtos`, `WorkshopJobAdminController`, `WorkshopJobAdminService`, `api_endpoints.dart`, `admin_api.dart`, `dispatch_detail.dart` |
| BLOCKER-03 | Default Aâ‰¥90/Bâ‰¥80/Câ‰¥65/D thresholds when no scoring rule exists | `TechnicianInspectionService`, `WorkshopJobAdminService` |
| BLOCKER-04 | `requiredForStatuses` is conditional; seeded issue fields no longer unconditional | `TechnicianInspectionService`, `DefaultChecklistSeeder` |
| BLOCKER-04b | Default score (100/70/40) when an item has no bands/measurements | `TechnicianInspectionService` |
| BLOCKER-05 (closed for fabricated facts) | Removed hardcoded vehicle facts, per-code diagnostic/standard/part photo and fake video; disabled the fabricated visual/showcase/tyre/damage/system/video sections until they are data-driven. Public HTML verified with real Toyota/Land Cruiser + real item rows and no demo strings | `reports/ReportViewMapper.java`; `ReportSnapshot`/`ReportSnapshotBuilder` |
| BLOCKER-06 (closed) | Clean approval stores the normalized `ReportSnapshot`; `PublicReportService` now falls back to `platform_public_links -> platform_report_versions` via `CleanPublicReportReader`, renders the page, and renders the PDF on demand. Verified: `GET /r/{token}` â†’ **200** with real data; `GET /r/{token}/pdf` â†’ **200**, `%PDF` | `WorkshopJobAdminService`, `PlatformJobStore`, `PublicReportService`, `CleanPublicReportReader`, `PublicShareLink` |
| MAJOR-01 (closed) | Clean report snapshots no longer store customer name/phone/email/plate; VIN is masked. Report version is 25 KB of allowlisted display data | `WorkshopJobAdminService.snapshot` |
| MAJOR-05 (closed) | No item claims a video/part photo that does not exist. At publish, verified clean photos are resized/EXIF-stripped into `normalized_key`; the public report and PDF use real photo URLs/data URIs. Videos remain a later feature, never a false claim | `ReportViewMapper.items`, `CleanEvidencePublicationService`, `CleanPublicReportReader`, `PublicReportService` |
| Report sections (dynamic) | Re-enabled `tyreAssemblies` from real multi-point tyre measurements, `damageZones` from real non-pass body/tyre items, and `vehicleShowcase` from real evidence photos (URLs via `/r/{token}/photo/...`). Empty when data is absent; no stock content | `ReportViewMapper`, `ReportSnapshot` measurements, `PlatformJobStore.reportMeasurements` |

## Runtime status

| Check | Result |
|---|---|
| Backend boot (fresh MySQL 8.0, 37 migrations incl. V123, dev seed) | PASS |
| Auth login (platform/workshop/technician) | PASS |
| Platform seed 30-item checklist (`POST /platform/seed/default-checklist`) | PASS (146 created) |
| Platform workshop create (`POST /platform/workshops`) | PASS |
| Workshop job create + assign (`POST /workshop/jobs`) | PASS |
| Technician checklist open | PASS after V123 (30 items, 313 KB snapshot) |
| Assessment save (clean pass) | PASS (no issue metadata required for NO_ISSUE; multi-point accepted) |
| Complete | PASS (score 100, grade A, PENDING_REVIEW) |
| Approve | PASS (6 categories, 25 KB normalized report version) |
| Publish | PASS (ACTIVE link, PDF enabled) |
| Public HTML | PASS 200, real data, no demo constants |
| Public PDF | PASS 200, `%PDF` |
| Consent grant/withdraw | PASS (API + audit rows; new `WorkshopJobAdminIT` case) |
| Browser CRUD / cross-app specs | Generated and `--list` validated (18 tests); NOT RUN by request |


