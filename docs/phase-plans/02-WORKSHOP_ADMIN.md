# Phase 2 — Workshop Admin

**Goal:** Let Workshop Admin create jobs, assign technicians, review completed inspections, approve, publish, and share reports.

**Depends on:** Phase 1 Platform Admin config and templates.

---

## 1. Scope

### Backend
- Workshop-scoped job creation and lifecycle.
- Customer/vehicle data.
- Global template selection and version pinning.
- Technician assignment/reassignment.
- Inspection review and approval checklist.
- Approval → scoring snapshot → publish → token/QR.
- Post-publish document generation (EN/AR).
- Consent, unpublish/revoke, notifications, outbox.
- Workshop dashboards/counts.

### Frontend
- Reuse existing Workshop Admin screens/components.
- Replace mock data with APIs.
- Add approve/publish, QR, documents, publish checklist.
- Adaptive layout pass.

---

## 2. Backend Deliverables

### 2.1 Jobs

Endpoints:
- `GET /api/v1/workshop/jobs` (paginated/filter/search)
- `GET /api/v1/workshop/jobs/{id}`
- `POST /api/v1/workshop/jobs`
- `PUT /api/v1/workshop/jobs/{id}`
- `POST /api/v1/workshop/jobs/{id}/assign`
- `POST /api/v1/workshop/jobs/{id}/cancel`
- `GET /api/v1/workshop/jobs/{id}/assignments`
- `GET /api/v1/workshop/jobs/counts`

Fields:
- Customer name/phone/email (phone required, email optional).
- Vehicle VIN, make, model, year, plate, odometer, transmission, fuel.
- Preferred language.
- Template version.
- Assigned technician.
- Status + review/publication state.
- Timestamps, audit, version.

Rules:
- VIN format validation; duplicate detection warning.
- Template must be published and active.
- Customer/vehicle edits allowed only before finalization.
- Workshop scope enforced.

### 2.2 Assignment

- Only active technicians in the same workshop.
- Reassignment audited.
- Workload warning (not a hard block).
- Removed: certification/tool calibration checks (D-046).

### 2.3 Review and approval

Review payload:
- Job summary, technician, completed items, findings, evidence, score preview.
- Blocking issues and warnings.

Approval checklist:
- All items assessed.
- Evidence rules met.
- Signature present.
- Score/grade computed.
- Safety cap explained.
- Consent granted.
- Documents ready or queued.
- Approver is Workshop Admin and not the technician.

Endpoints:
- `GET /api/v1/workshop/jobs/{id}/review`
- `GET /api/v1/workshop/jobs/{id}/publish-checklist`
- `POST /api/v1/workshop/jobs/{id}/approve`
- `POST /api/v1/workshop/jobs/{id}/reject`

Rules:
- No correction flow; rejection closes the job and requires a new inspection (D-021).
- Approval writes the immutable result snapshot.
- Publish creates/activates the public token.

### 2.4 Publish / unpublish / revoke

Endpoints:
- `POST /api/v1/workshop/jobs/{id}/publish`
- `POST /api/v1/workshop/jobs/{id}/unpublish`
- `POST /api/v1/workshop/jobs/{id}/rotate-token`
- `POST /api/v1/workshop/jobs/{id}/revoke`
- `GET /api/v1/workshop/jobs/{id}/qr`
- `GET /api/v1/workshop/jobs/{id}/public-link`

Rules:
- Token stored hashed; plaintext returned only at creation/rotation.
- QR generated server-side.
- Unpublish/revoke requires reason and audit.
- Consent required before activation.
- PDF download setting configurable.

### 2.5 Documents

- After publish, enqueue generation for active document types.
- Generate EN and AR PDFs (D-037).
- Store artifacts linked to the report version.
- Retry via outbox.
- Public report links current language version.
- No manual upload gate (D-024).

Endpoints:
- `GET /api/v1/workshop/jobs/{id}/documents`
- `POST /api/v1/workshop/jobs/{id}/documents/{type}/retry`

### 2.6 Consent and notifications

- Record public-link consent before activation.
- In-app notifications for assignment, pending review, approval, publish, failures.
- Outbox events for async work.

### 2.7 Dashboards

- Job counts by status.
- Pending review queue.
- Failed generation/upload alerts.
- SLA timers (D-042 professional pack).

---

## 3. Frontend Deliverables

### 3.1 Reuse
- Keep dashboard, jobs tab, schedule sheet, assignments, report page, staff/template screens.
- Do not redesign.
- Extend with missing actions using existing components.

### 3.2 Data layer
- Replace mock/demo data with API.
- Add models: workshop job, review, publish checklist, public link, QR, documents, notifications.
- Error mapping.

### 3.3 Screens
- Job creation wizard: customer, vehicle, template, technician.
- Job list with filters/counts/search.
- Job detail: progress, findings, evidence, review.
- Approve & issue certificate screen with score/grade/caps.
- Publish checklist screen.
- Public link + QR + share.
- Documents status/retry.
- Unpublish/revoke dialogs with reasons.
- Notification center.

### 3.4 Adaptive
- No fixed widths/heights.
- Responsive lists/tables/cards/dialogs.
- Phone/tablet/desktop + EN/AR/RTL tests.

---

## 4. Tests

### Backend
- Job create/update/assign scope and validation.
- Template pinning and published-version enforcement.
- Review and approval checklist.
- Approver ≠ technician.
- Rejection closes job; no correction.
- Publish creates token; unpublish/revoke behavior.
- Consent required.
- QR generation.
- Document generation EN/AR and retry.
- Outbox/worker retries.
- Tenant isolation.
- Localized errors.

### Frontend
- Job creation validation.
- Approval checklist states.
- Publish/QR/link display.
- Error handling.
- Adaptive layout.
- EN/AR/RTL.
- `flutter analyze` + tests.

---

## 5. Acceptance Criteria

1. Workshop Admin can create a job with customer/vehicle/template/technician.
2. Jobs list/filter/counts work and are workshop-scoped.
3. Technician assignment/reassignment works and is audited.
4. Review shows findings/evidence/score preview.
5. Approval requires the checklist and a Workshop Admin who is not the technician.
6. Publish creates a public token and QR.
7. Unpublish/revoke works with reason.
8. EN/AR documents are generated after publish and retried on failure.
9. No correction flow exists; rejection requires a new inspection.
10. UI is reused and adaptive.
11. Backend and Flutter tests pass.

---

## 6. Implementation Order

1. Jobs schema/entities/services.
2. Job APIs + assignment.
3. Review/approval checklist.
4. Scoring snapshot + publish/token/QR.
5. Documents + outbox.
6. Consent/notifications.
7. Backend tests.
8. Flutter models/API/providers.
9. Flutter screens + adaptive pass.
10. Tests/analyze.
11. Review and approval before Phase 3.
