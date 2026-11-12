# Backend Rebuild Plan

**Decision:** The backend is rebuilt cleanly. The existing implementation is treated as a reference, not a foundation to keep patching.

---

## 1. Goals

- One coherent domain model matching the approved flows.
- Clean module boundaries and predictable dependencies.
- Server-authoritative validation, scoring, grading, and snapshots.
- Consistent API contracts, errors, idempotency, concurrency, audit.
- Full EN/AR support.
- Production-grade operations: outbox, observability, migrations, tests.

---

## 2. What We Reuse vs Rebuild

### Reuse (libraries/patterns)

- Spring Boot 4.x, Java 25, Maven.
- MySQL 8.4 + Flyway; H2 for tests.
- Spring Security + JWT/refresh pattern.
- Object storage abstraction.
- Existing proven test utilities and CI structure.
- Existing Figma/design-system work on the frontend.

### Rebuild (application code/schema)

- Package structure and module ownership.
- Database schema and migrations.
- Entities/repositories/services/controllers.
- Error contract and validation.
- Scoring, snapshot, report payload, document generation.
- Dynamic issue configuration and assessment model.
- Tests aligned to the new model.

---

## 3. Module Structure

```text
com.truereport
├── identity          users, auth, sessions, TOTP, preferences
├── tenancy           workshops, memberships, scoping
├── localization      languages, messages, localized content helpers
├── masterdata        categories, items, versions, bands, evidence rules,
│                     option sets, issue fields, measurement bands
├── templates         platform global templates + versions
├── jobs              inspection jobs, customer/vehicle, assignments
├── inspections       assessments, issue values, measurements, findings
├── evidence          photo/video/document assets, derivatives, quality gates
├── scoring           scoring rules, grade boundaries, caps, computation
├── reports           snapshots, generation jobs, artifacts, validity
├── publicreport      public JSON/HTML payload, token resolution, media
├── documents         generated report documents (EN/AR)
├── delivery          email/SMS/WhatsApp + notifications
├── audit             immutable audit events
└── shared            errors, security, storage, uuid, outbox, config
```

Rules:
- No cyclic module dependencies.
- Controllers never call repositories directly.
- Modules expose services/DTOs, not entities, across boundaries.
- Enforce with ArchUnit/Modulith tests.

---

## 4. Database Strategy

### 4.1 Clean baseline

- Do **not** build on the current V1–V18 schema.
- Create a new clean migration baseline for the rebuilt backend.
- Keep the old schema/migrations archived for reference and data comparison.
- Use a new database/schema for V2 during development, then cut over.

### 4.2 Migration approach

1. New schema is created by a clean Flyway baseline.
2. Any real production data is migrated by an explicit data migration script.
3. Old tables are not referenced by the new application.
4. A cutover runbook documents backup, migration, verification, rollback.

### 4.3 Core tables

- identity: `users`, `refresh_tokens`, `totp_*`, `user_preferences`
- tenancy: `workshops`, `workshop_memberships`
- localization: `languages`, `localized_content`, `message_overrides` (optional)
- masterdata: `master_categories`, `master_items`, `master_item_versions`,
  `item_score_bands`, `item_evidence_rules`, `option_sets`, `option_values`,
  `item_issue_fields`, `item_issue_field_options`, `item_measurement_bands`
- templates: `master_templates`, `master_template_versions`, `master_template_items`
- jobs: `inspection_jobs`, `job_assignments`, `job_status_history`
- inspections: `assessments`, `assessment_issue_values`, `assessment_measurements`,
  `findings`
- evidence: `evidence_assets`, `evidence_derivatives`, `evidence_quality_checks`
- scoring: `scoring_rules`, `grade_boundaries`
- reports: `reports`, `report_versions`, `report_generation_jobs`,
  `report_artifacts`, `public_share_links`, `report_validity`
- documents: `report_document_types`, `report_documents`
- delivery: `delivery_requests`, `delivery_attempts`, `notifications`
- audit: `audit_events`
- shared: `outbox_events`, `idempotency_keys`

### 4.4 Data rules

- UUIDv7 binary keys.
- `created_at`, `updated_at`, `version` on mutable entities.
- Published/finalized rows immutable.
- Soft-deactivate master data; never hard-delete referenced rows.
- Unique indexes: `stable_code`, `(job_id, item_id)`, `(job_id, issue_field, value_index)`, `public_token_hash`.
- Indexes on `workshop_id`, `job_id`, `report_version_id`, `token_hash`, `status`.

---

## 5. API Standards

- Base path: `/api/v1`.
- Public report: `/public/reports/{token}`; aliases `/r/{token}`.
- RFC 9457 problem details:
  - `code`, `messageKey`, `messageEn`, `messageAr`, `detail`, `traceId`.
  - Field errors array with EN/AR.
- Pagination: `page`, `size`, `sort`.
- Filtering via explicit params.
- `ETag`/`If-Match` for mutable resources.
- `Idempotency-Key` on create/save/upload/approve/publish.
- `Accept-Language` for response language.
- OpenAPI docs for every endpoint.
- Breaking changes documented in `docs/MIGRATION.md`.

---

## 6. Domain Rules

### Master data
- EN + AR required before publish.
- Versioned items; published versions immutable.
- Options/issue fields versioned with the item.
- Category weights validated.
- Bands contiguous and non-overlapping.
- Maker-checker for scoring/safety/template publication.

### Jobs
- Template version pinned at creation.
- Status: additive review/publication fields.
- Approval by Workshop Admin, never the technician.
- No correction; rejection requires a new inspection.
- Customer/vehicle edits only before finalization.

### Assessments
- Result code required.
- Measurement required for numeric items.
- Status/score derived from Platform-Admin bands.
- Score override only inside the band.
- Dynamic issue values validated against the item schema.
- Evidence rules per item/status.
- Multi-point worst-case derivation.
- All failing items returned on complete.

### Evidence
- PHOTO, VIDEO, DOCUMENT.
- Camera-only capture.
- Size/type limits, quality checks, hash dedup.
- Captions EN/AR, duration, poster/thumbnail.
- Idempotent upload; soft delete.

### Reports
- Snapshot at finalize/publish.
- Scoring computed server-side.
- Grade boundaries/caps from snapshot.
- Public payload built only from snapshot.
- No PII/internal IDs exposed.
- Validity/expiry stored in snapshot.

---

## 7. Cross-Cutting Infrastructure

### Transactional outbox
- Write domain change + outbox event in one transaction.
- Workers claim with lease/lock, retry with backoff, dead-letter.
- Events: report generation, document generation, delivery, notifications.

### Idempotency
- Persistent idempotency keys with actor + endpoint + key hash.
- Return the original response on replay.

### Optimistic concurrency
- `version`/ETag checks on every mutation.
- `409 CONFLICT` with current state.

### Audit
- Actor, action, entity, before/after, reason, timestamp, IP, trace ID.
- Immutable append-only.

### Observability
- Structured JSON logs with trace ID, user ID, workshop ID, job/report ID.
- Metrics: latency, errors, validation failures, upload failures, generation time,
  queue depth, public 5xx, publish SLA.
- Alerts for backlog, failures, and stuck jobs.
- No tokens/PII/media in logs.

### Security
- Role/tenant scoping server-side.
- PII encryption at rest.
- Token hashing; no plaintext tokens stored.
- Rate limiting; public token probing resistance.
- CSP/security headers.
- Secrets via environment/secret store.
- Dependency and container scanning in CI.

---

## 8. Testing Strategy

- Unit tests for scoring, bands, validator, weights, i18n.
- Integration tests for each role and key endpoint.
- Tenant/role isolation tests.
- Migration tests on empty and existing DBs.
- Contract tests for API errors and payloads.
- Public report tests: 404/expired, redaction, EN/AR.
- Outbox/worker retry tests.
- Performance smoke tests for public report and uploads.
- ArchUnit/Modulith boundary tests.

---

## 9. Cutover Plan

1. Build new schema alongside old.
2. Seed master config.
3. Migrate any real data via explicit script.
4. Run new backend in staging; verify reports and public pages.
5. Freeze writes; final delta migration.
6. Switch traffic.
7. Keep old schema read-only for rollback window.
8. Document rollback and verification steps.
