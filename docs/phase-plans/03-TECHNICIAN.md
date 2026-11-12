# Phase 3 — Technician

**Goal:** Let the technician complete the dynamic inspection with measurements, structured issue options, photo/video/document evidence, signature, and offline-safe sync.

**Depends on:** Phase 1 config; Phase 2 jobs/assignment.

---

## 1. Scope

### Backend
- Technician job list/detail with pinned checklist.
- Dynamic issue schema delivery.
- Assessment save/upsert with issue values and measurements.
- Band-based status/score validation.
- Evidence photo/video/document upload and quality gates.
- Multi-point items.
- Live summary.
- Signature and complete → pending review.
- Offline sync/idempotency/conflict handling.
- Tool/certification checks: not included (D-046).

### Frontend
- Reuse existing Technician app screens/components.
- Dynamic category tabs and issue forms.
- Camera/video capture, poster, upload queue.
- Signature.
- Offline queue/status.
- Adaptive layout pass.

---

## 2. Backend Deliverables

### 2.1 Technician jobs

Endpoints:
- `GET /api/v1/technician/jobs`
- `GET /api/v1/technician/jobs/{id}`
- `GET /api/v1/technician/jobs/{id}/checklist`

Checklist response:
- Job/vehicle/customer summary.
- Categories with order.
- Items with pinned version data: labels EN/AR, instructions, unit, sensor/tool, standard spec, safety flag, multi-point, free-text flag.
- Score bands.
- Evidence rules.
- Issue field schema with options, dependencies, min/max, units.
- Existing assessment/issue values/evidence.

### 2.2 Assessments

Endpoint:
- `PUT /api/v1/technician/jobs/{id}/items/{itemCode}`

Payload:
- `baseVersion`, `clientRevision`.
- `resultCode`, `score`.
- `issueValues[]` (field code, option code, numeric, unit, value index, text if allowed).
- Measurement values/sub-measurements.
- Optional notes EN/AR only if allowed.

Rules:
- Result required.
- Measurement required for numeric items.
- Status/score derived from measurement band.
- Score override only inside band.
- Option values allowed/active/dependency satisfied.
- Required fields for status.
- Multi-point worst-case status.
- Idempotent upsert.
- Optimistic concurrency.
- Structured EN/AR errors.

### 2.3 Evidence

Endpoints:
- `POST /api/v1/technician/jobs/{id}/items/{itemCode}/evidence/init`
- `PUT /api/v1/technician/jobs/{id}/items/{itemCode}/evidence/{evidenceId}/content`
- `POST .../evidence/{evidenceId}/complete`
- `GET .../evidence`
- `DELETE .../evidence/{evidenceId}`

Types:
- PHOTO (JPEG/HEIC/HEIF/WebP; size limit).
- VIDEO (MP4/WebM/QuickTime; 15–30s, max 50 MB).
- DOCUMENT (PDF/image for OBD reports).

Features:
- Hash, size/type limits.
- Captions EN/AR.
- Duration, poster/thumbnail.
- Quality gates: camera-only metadata, timestamp/window, duplicate/reuse detection, min resolution, optional blur.
- Idempotent upload; soft delete.
- Evidence rules per status: every item requires ≥1 photo + ≥1 video (D-023); FAIL ≥2 photos + ≥1 video.

### 2.4 Review/summary/complete

Endpoints:
- `GET /api/v1/technician/jobs/{id}/summary` (live score preview).
- `GET /api/v1/technician/jobs/{id}/review` (blocking/warnings).
- `POST /api/v1/technician/jobs/{id}/signature`
- `POST /api/v1/technician/jobs/{id}/complete`

Rules:
- All items assessed.
- All validation/evidence rules met.
- Signature present.
- All offline changes synced.
- Complete moves job to pending review.
- No finalization offline.
- Server returns all blockers at once.

### 2.5 Offline sync

- Idempotency keys per mutation.
- Batch sync endpoint or replay existing upserts.
- Conflict: server wins, return current state + diff, require revalidation (D-026).
- Evidence idempotent by hash.
- No completion until clean.

---

## 3. Frontend Deliverables

### 3.1 Reuse
- Keep job list, job detail, inspection hub, category views, item cards, review/finalize screens.
- Keep visual design and components.
- Replace hardcoded result/severity/category/icon logic with API-driven data.

### 3.2 Data layer
- Extend models: checklist, category, item, bands, issue field, issue value, measurement, evidence, review, signature.
- API client with `Accept-Language`.
- Offline store mapping for issue values/media.
- Error mapping to inline fields.

### 3.3 Screens
- Job list with sync status.
- Job detail with category tabs from API.
- Item card: instructions, spec, unit, tool, evidence checklist.
- Dynamic issue form: cascading dropdowns, measurement + unit, severity/action/urgency.
- Band-suggested status/score with in-band override.
- Evidence capture: photo/video/document; camera-only; poster; upload progress/retry.
- Multi-point grid FL/FR/RL/RR.
- Summary with draft score and blockers.
- Signature pad.
- Complete action.
- Offline queue/status/conflict UI.

### 3.4 Adaptive
- No fixed widths/heights.
- Responsive category tabs, grids, forms, dialogs.
- Tablet-friendly inspection layout.
- EN/AR/RTL; long labels; Western digits.

---

## 4. Tests

### Backend
- Checklist dynamic schema delivery.
- Assessment validation: result, measurement, band, options, dependencies, required fields.
- Band override inside/outside.
- Multi-point worst-case.
- Evidence rules for PASS/ATTENTION/FAIL.
- Video/document upload, captions, duration.
- Quality gates and duplicate detection.
- Signature and complete blockers.
- Offline conflict/idempotency.
- Tenant/technician isolation.
- Localized errors.

### Frontend
- Dynamic form rendering.
- Band suggestion logic.
- Evidence checklist blocking.
- Offline queue/replay.
- Conflict UI.
- Signature.
- Adaptive layout at phone/tablet.
- EN/AR/RTL.
- `flutter analyze` + tests.

---

## 5. Acceptance Criteria

1. Technician sees only their jobs and pinned checklist.
2. Category tabs and issue fields are generated from API, not hardcoded.
3. Measurement drives status/score; override only inside band.
4. FAIL cannot save without required photos/videos/notes.
5. Every item requires ≥1 photo + ≥1 video.
6. Video/document evidence uploads with captions/duration/poster.
7. Multi-point items derive worst status.
8. Offline queue syncs safely; conflicts require revalidation.
9. Signature and complete move job to pending review.
10. Server enforces validation even if client is bypassed.
11. UI is reused and adaptive.
12. Tests pass.

---

## 6. Implementation Order

1. Checklist schema/API.
2. Assessment/issue value/measurement model + validation.
3. Scoring/band suggestion integration.
4. Evidence upload (photo/video/document) + quality gates.
5. Summary/review/complete/signature.
6. Offline sync/conflict.
7. Backend tests.
8. Flutter models/API/providers.
9. Flutter dynamic forms/evidence/signature/offline.
10. Adaptive pass + tests/analyze.
11. Review and approval before Phase 4.
