# Professional Flows — V1 Core Pack

**Status:** Approved 2026-11-11  
**Scope:** Adds operational trust, governance, and failure handling to the Platform, Workshop, Technician, and Public flows.

---

## 1. Approved V1 Core Pack

1. Configuration release lifecycle + impact analysis + health dashboard.
2. Evidence quality gates.
3. Approval checklist before publish.
4. Transactional outbox + observability.
5. Public verification page + configurable report validity.
6. API standards: pagination, filtering, ETag/If-Match, idempotency.

**Explicitly out of scope:** technician qualification matrix, tool calibration register, and QC sampling/re-inspection. These are not part of V1 and are not planned (D-046).

---

## 2. Platform Admin Flows

### 2.1 Configuration release lifecycle

States:
- `DRAFT`
- `REVIEW`
- `APPROVED`
- `PUBLISHED`
- `DEPRECATED`

Rules:
- Maker-checker applies to scoring, safety, and template publication.
- Published versions are immutable.
- Rollback creates a new version based on a previous one; it never mutates history.
- Optional `effective_from` date; jobs created before it use the old version.

Data:
- `master_releases` (id, entity_type, entity_id, version_id, status, effective_from, approved_by, approved_at, notes)
- Extend audit events with release actions.

### 2.2 Change impact analysis

Before publish/deactivate:
- Show affected templates, active jobs, workshops, and categories.
- Block deactivation if referenced by an active job/template.
- Provide a read-only list of affected job references (no PII).

Endpoint:
- `GET /api/v1/platform/master/{entityType}/{id}/impact`

### 2.3 Configuration health dashboard

Checks:
- Category weights sum ≠ 100.
- Missing EN/AR labels/instructions/specs.
- Score bands with gaps/overlaps.
- Measurement bands with gaps/overlaps.
- Retired option values referenced by active items.
- Safety-critical items missing evidence rules.
- Templates with zero items or missing category items.
- Items with numeric fields but no measurement bands.
- Report document types with no generation mapping.

Endpoints:
- `GET /api/v1/platform/config-health`
- `GET /api/v1/platform/config-health/{entityType}`

### 2.4 Environment promotion (optional)

- Export a config bundle (JSON) from staging.
- Dry-run import into production.
- Import creates new versions; never overwrites published data.

---

## 3. Workshop Admin Flows

### 3.1 Approval checklist before publish

Server evaluates:
- All items assessed.
- All required evidence present and verified.
- Technician signature present.
- Score/grade computed.
- Safety cap explanation generated.
- Public-link consent granted.
- Documents generated (EN + AR) or generation queued.
- QR/public link ready.
- Job approved by a Workshop Admin who is not the technician.

Endpoint:
- `GET /api/v1/workshop/jobs/{id}/publish-checklist`

Publish is blocked until every required item is green.

---

## 4. Technician Flows

### 4.1 Evidence quality gates

Checks:
- Camera-only capture for evidence.
- Minimum resolution.
- Blur detection (client-side or server-side).
- Capture timestamp within the job window.
- Device/session binding.
- Duplicate media detection by hash.
- Prevent reuse of evidence from another job.

Rules:
- Reject or warn based on Platform Admin configuration.
- Store quality status per evidence asset.

### 4.2 Anomaly checks (basic)

- Item completed implausibly fast.
- Same measurement repeated across many items.
- Same photo/video hash reused.
- Measurement outside physical limits.
- Evidence timestamp mismatch.

These produce warnings to Workshop Admin; they do not auto-reject unless configured.

---

## 5. Public Report Flows

### 5.1 Verification page

- `GET /verify/{token}` or a verification section on the report.
- Shows report hash, issued date, workshop, status.
- QR links to the verification page.
- Verification uses the stored snapshot hash; no live data joins.

### 5.2 Configurable report validity

Data:
- `report_validity_days` on scoring/report config.
- `valid_until` stored in the report snapshot/version.

Rules:
- Public report shows “Valid until …”.
- After expiry, report status changes to `EXPIRED` in the UI.
- Expired reports return the standard neutral unavailable page or a read-only expired page, configurable.
- Revoked reports return the same neutral 404 as unknown tokens.

---

## 6. Cross-Cutting Flows

### 6.1 Transactional outbox

Use an outbox table for:
- Report generation
- Document generation (EN + AR)
- Delivery requests
- Notifications

Rules:
- Write the domain change and outbox event in the same transaction.
- Worker claims events with locking/lease.
- Retries with backoff and dead-letter status.
- Idempotent consumers.

Tables:
- `outbox_events` (id, aggregate_type, aggregate_id, event_type, payload_json, status, attempts, available_at, locked_by, locked_at, last_error)

### 6.2 Observability

Metrics:
- API latency/error rate by endpoint.
- Validation failure counts by code.
- Upload success/failure by media type.
- Report generation duration/failures.
- Document generation duration/failures.
- Delivery success/failure.
- Review SLA.
- Outbox backlog.

Logs:
- Structured JSON with trace ID, user ID, workshop ID, job/report ID.
- No tokens, PII, or evidence contents in logs.

Alerts:
- Outbox backlog over threshold.
- Failed report/document generation.
- Upload failure spike.
- Public report 5xx spike.
- Publish blocked for too long.

### 6.3 API standards

- Pagination: `page`, `size`, `sort`, stable default order.
- Filtering via explicit query params.
- `ETag`/`If-Match` for mutable resources.
- `Idempotency-Key` for create/approve/publish.
- RFC 9457 problem details with `code`, `messageKey`, `messageEn`, `messageAr`.
- OpenAPI documentation for all endpoints.
- Deprecation policy and versioned breaking changes.

---

## 7. Phase Mapping

| Flow | Phase |
|---|---|
| Config lifecycle, impact analysis, health dashboard | Platform |
| Evidence quality gates | Technician |
| Approval checklist | Workshop |
| Transactional outbox, observability | Platform/Workshop/Technician/Public infrastructure |
| Verification page, report validity | Public |
| API standards | All phases |

---

## 8. Acceptance Criteria

1. Publishing a config change shows impact and cannot break referenced data.
2. Config health dashboard reports missing translations, weight gaps, band gaps, and retired references.
3. Evidence fails quality gates when it is camera-less, duplicate, or out of window.
4. Publish is blocked unless the approval checklist is fully green.
5. Report/document/delivery jobs are processed via the outbox with retries.
6. Public report shows verification hash and validity/expiry.
7. API list endpoints support pagination/filtering/sorting.
