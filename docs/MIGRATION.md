# API & Schema Migration Notes

## Phase 1 â€” Platform Admin (rebuilt backend)

### Clean Platform Admin schema

New migrations:
1. `V100__platform_admin_clean_baseline.sql` â€” child configuration, languages, templates, scoring, document types, governance, outbox, idempotency, platform audit.
2. `V101__platform_clean_content.sql` â€” clean `platform_categories`, `platform_items`, `platform_item_versions`, `platform_guide_images`.
3. `V102__Migrate_platform_content.java` â€” copies legacy master content into the clean parent tables when present (no-op on a fresh DB).
4. `V103__platform_clean_content_constraints.sql` â€” adds foreign keys and drops `platform_category_config` / `platform_item_metadata`.
5. `V104__drop_legacy_template_fk` â€” vendor-specific H2/MySQL migration removing the legacy `template_items` FK to the old master version table. Workshop templates now pin clean UUIDs and snapshot the item rules.

Platform Admin content uses only:
- `platform_categories`
- `platform_items`
- `platform_item_versions`
- `platform_guide_images`
- child tables keyed by `item_version_id`

All Platform Admin IDs are UUIDv7 strings (`VARCHAR(36)`). Legacy BINARY(16) master IDs are converted to string UUIDs during `V102`. Legacy master tables remain only for the reference Workshop/Report application and are not read by Platform Admin configuration code.

### Data migration behavior

- If clean parent tables are empty, `V102` copies legacy categories, items, versions, labels/instructions, item metadata, weights and guide images.
- Existing child rows keep their `item_version_id` because version UUIDs are preserved as strings.
- Orphaned child rows are removed before foreign keys are added.
- On a fresh database `V102` performs no inserts; the seed endpoint populates the data.

### Seed

`POST /api/v1/platform/seed/default-checklist` is idempotent and writes only clean `platform_*` tables. It creates:
10 option sets, 6 categories (25/18/20/17/10/10), 30 items with score bands, evidence rules, measurement bands and issue fields, 5 document types, the GCC scoring rule with A/B/C/D boundaries, and `TPL-30-GCC`.

### Common language API

| Method | Path | Auth |
|---|---|---|
| GET | `/api/v1/i18n/languages` | **anonymous** |
| GET | `/api/v1/i18n/me` | authenticated |
| PUT | `/api/v1/i18n/me` | authenticated |

Platform language CRUD under `/api/v1/platform/i18n/**` remains Platform Admin only.

### Platform Admin endpoints

- Categories: CRUD, `GET /categories/weight-check`, `PUT /categories/reorder`.
- Items: list/detail/create/update, draft, metadata, bands, evidence rules, issue fields, measurement bands, publish, retire, reorder.
- Option sets and values: CRUD/reorder/retire with replacement.
- Global templates: versions, items, weight preview, publish/approve/reject/retire.
- Scoring rules, grade boundaries and approvals.
- Document types: CRUD/reorder/retire.
- Governance: config health, impact analysis, releases.
- Seed.

### Error contract

Errors include `code`, `messageKey`, `messageEn`, `messageAr`, localized `detail`, `traceId`, and `errors`/`fieldErrors`. Legacy `fieldErrors` remains for existing clients.

### Frontend

- `ApiClient` sends `Accept-Language` from the shared locale controller.
- Platform Admin screens are API-backed; production sample master data and workshop fallbacks were removed.
- Adaptive checks cover 360/600/768/1024/1440 px and Arabic RTL.

## Phase 2 â€” Workshop Admin (rebuilt backend)

### Clean Workshop Admin schema

New migration `V105__workshop_jobs_clean.sql` adds:
- `platform_jobs` â€” workshop-scoped job lifecycle, customer/vehicle data, pinned template version, score/grade and safety-cap summary.
- `platform_job_assignments`, `platform_job_status_history`, `platform_job_approvals` â€” assignment, transition and approval audit rows.
- `platform_job_results` â€” clean assessment results consumed by review/approval (Phase 3 will populate these).
- `platform_report_versions` â€” immutable approval snapshot per job.
- `platform_public_links` â€” hashed lookup token, encrypted token for re-display, activation/revocation state.
- `platform_report_documents` â€” generated EN/AR artifacts per document type.
- `platform_notifications` â€” in-app notifications.

All IDs are UUIDv7 strings. Customer/vehicle PII is encrypted with the existing `PiiCipher`. Foreign keys are limited to clean tables; workshop/user identifiers are stored as UUID strings because the legacy identity/tenancy tables use BINARY(16) during the phased rebuild.

> **Upgrading an existing dev database:** this migration was renamed from `V105__workshop_admin_phase2.sql` to `V105__workshop_jobs_clean.sql` (version stays 105). If your local database already recorded the old filename, Flyway will report a checksum/description mismatch. Run `flyway repair` (or `mvn flyway:repair`) against that database, or start from a fresh database.

### Route change for legacy job endpoints

Reference-app job routes moved to `/api/v1/workshop/legacy/jobs` (`GET`, `POST`, `/{id}/assign`, `/{id}/cancel`, `/{id}/assignments`, `/counts`). The new Phase 2 Workshop Admin flows own `/api/v1/workshop/jobs`. Legacy report and delivery endpoints remain at `/api/v1/workshop/jobs/{jobId}/report` and `/deliveries`.

### Workshop Admin endpoints

Templates:
- `GET /api/v1/workshop/template-versions/available`
- `GET /api/v1/workshop/template-versions/{versionId}`

Jobs:
- `GET /api/v1/workshop/jobs` (page, size, status, search, from, to)
- `GET /api/v1/workshop/jobs/counts`
- `GET /api/v1/workshop/jobs/{id}`
- `POST /api/v1/workshop/jobs` (`Idempotency-Key`)
- `PUT /api/v1/workshop/jobs/{id}` (optimistic `version`)
- `POST /api/v1/workshop/jobs/{id}/assign`
- `POST /api/v1/workshop/jobs/{id}/cancel`
- `GET /api/v1/workshop/jobs/{id}/assignments`

Review/approval:
- `GET /api/v1/workshop/jobs/{id}/review`
- `GET /api/v1/workshop/jobs/{id}/publish-checklist`
- `POST /api/v1/workshop/jobs/{id}/approve` (`Idempotency-Key`)
- `POST /api/v1/workshop/jobs/{id}/reject`

Publish:
- `POST /api/v1/workshop/jobs/{id}/publish` (`Idempotency-Key`)
- `POST /api/v1/workshop/jobs/{id}/unpublish`
- `POST /api/v1/workshop/jobs/{id}/rotate-token`
- `POST /api/v1/workshop/jobs/{id}/revoke`
- `GET /api/v1/workshop/jobs/{id}/public-link`
- `GET /api/v1/workshop/jobs/{id}/qr` (PNG)

Documents/notifications:
- `GET /api/v1/workshop/jobs/{id}/documents`
- `POST /api/v1/workshop/jobs/{id}/documents/{type}/retry`
- `GET /api/v1/workshop/jobs/{id}/documents/{documentId}/content`
- `GET /api/v1/workshop/notifications`
- `POST /api/v1/workshop/notifications/{id}/read`

### Business rules

- Customer name/phone, VIN, make, model, year, plate, odometer, transmission and fuel are required; email is optional.
- VIN is validated as 17 alphanumeric characters (excluding I/O/Q).
- Only published Platform template versions can be pinned at job creation.
- Assignments accept only active technicians in the same workshop.
- Customer/vehicle edits are allowed only before finalization.
- Approval requires all items assessed, evidence rules met, signature, computed score/grade, safety-cap explanation when applicable, consent, and an approver who is a Workshop Admin and not the assigned technician.
- Rejection closes the job; there is no correction flow.
- Publish requires approval and consent, creates a token and QR, and generates EN/AR documents for active document types.
- Unpublish/revoke require a reason and are audited. Rotation invalidates the previous token.

### Errors

New message keys in `messages_en.properties` / `messages_ar.properties` cover job state, template publication, technician activity, consent, document and public-link failures. Validation returns bilingual `errors` entries.

### Frontend

- Workshop Admin `ApiEndpoints`, `AdminApi`, models and Riverpod providers now target the Phase 2 endpoints.
- Legacy Workshop Admin list/create/assign/cancel calls use `/workshop/legacy/jobs`.
- New screens: job board/list, creation wizard, job detail/review, approve & issue certificate, publish checklist, public link + QR, documents/retry, notification center.
- Platform Admin and Workshop Admin web builds use path URLs; deployment rewrite is documented in `docs/WEB_URL_STRATEGY.md`.

---

## Platform Admin End-to-End Completion (2026-11-12)

### Backend

- `platform_categories`/`platform_items`/`platform_item_versions` are the only
  master-content tables read or written by Platform Admin code.
- `retireCategory` now rejects retirement while items still reference the
  category (`CATEGORY_IN_USE`).
- All category/item/version/band/evidence/issue-field/measurement-band,
  option-set, template, scoring, document-type, language, governance and seed
  endpoints already exist and were exercised against local MySQL.

### Frontend

- Item editor: item retire action, correct required-for-status values, allowed
  option subset editor.
- Master library: item reorder, item retire, seed confirmation.
- Global templates: rename action.
- Scoring: reject action.
- Languages: reorder actions.
- Config health: release lifecycle panel.
- Hierarchy: removed production mock fallback/demo quick-fill, fake pagination
  and hardcoded metric strip.
- Dialog controllers are disposed after route transitions (D-069).

### Verification

- `docs/PLATFORM_ADMIN_SCREEN_API_MATRIX.md` maps screens to endpoints.
- Live UI -> API -> DB test:
  `client/apps/platform_admin_app/test/e2e/platform_admin_live_e2e_test.dart`
  (skipped unless `LIVE_E2E=1`).
- Evidence: `docs/evidence/platform_admin/` contains six UI screenshots,
  `evidence.json` (API payloads) and `db-checks.txt` (MySQL row checks).
### Authentication hardening

- Removed demo login bypasses from `PlatformLoginPage` and `WorkshopLoginPage`.
- Removed `setDemoSession` from `packages/auth`.
- Removed `onQuickFillDemo` / `btn-fill-demo` from `AdminSignInView`.
- Invalid credentials now show an error and keep the user on the login page.
- Local credentials remain in `TEST_LOGIN_CREDENTIALS.txt`, now ignored by Git;
  `TEST_LOGIN_CREDENTIALS.example.txt` contains redacted values.
- Live E2E reads `LIVE_E2E_EMAIL` / `LIVE_E2E_PASSWORD` (and optional
  `LIVE_E2E_SECOND_EMAIL` / `LIVE_E2E_SECOND_PASSWORD`).
- Local backend runner is `server\run-local.bat`. Running
  `mvn spring-boot:run` directly fails because it lacks DB/JWT/encryption env
  values; the batch file sets them and now checks for port 8080 conflicts.
### Template category-first structure (V107)

- Added `platform_template_categories`:
  - `id`, `template_version_id`, `category_id`, `sort_order`, `included`
  - unique `(template_version_id, category_id)`
- Added `platform_template_items.category_id` with FK to `platform_categories`.
- Backfilled item categories from `platform_item_versions -> platform_items`.
- Backfilled existing template categories from included template items.
- Dropped `platform_template_items.item_weight`.
- Legacy `platform_categories.weight_percentage`, `platform_score_bands`,
  `platform_scoring_rules` and `platform_grade_boundaries` remain for the later
  Workshop/Public phases but are no longer used or exposed by Platform Admin.
- Removed endpoints:
  - `GET /api/v1/platform/master/categories/weight-check`
  - `GET/PUT /api/v1/platform/master/items/{id}/versions/{versionId}/bands`
  - `GET /api/v1/platform/master/templates/{id}/versions/{versionId}/weight-preview`
  - `/api/v1/platform/scoring-rules` and grade-boundary endpoints
- Added:
  - `PUT /api/v1/platform/master/templates/{id}/versions/{versionId}/categories`
  - `GET /api/v1/platform/master/templates/{id}/versions/{versionId}`
- `GET /api/v1/platform/master/templates/{id}` now includes `categories[]`.

### Dynamic scoring contract (later phases)

- `includedCategories` = categories with at least one included item
- `categoryWeight` = `100 / includedCategories`
- `itemWeight` = `categoryWeight / includedItemsInCategory`
- `categoryScore` = sum(itemScore * itemWeight)
- `overallScore` = sum(categoryScore * categoryWeight)
- Equal categories and equal items; no Platform Admin scoring configuration.