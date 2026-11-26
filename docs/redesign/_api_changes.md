# API changes — Inspection · Fieldwork

**None.** The redesign reads and writes only through the existing technician
endpoints (see `packages/api_client/lib/src/api_endpoints.dart`):

- `GET  /api/v1/technician/jobs/{jobId}/checklist` — job, categories, items, assessments, served result options
- `GET  /api/v1/technician/jobs/{jobId}/items/{itemCode}` — one item
- `POST /api/v1/technician/jobs/{jobId}/sync` — queued assessment mutations (result, issue values, measurements, notes)
- `POST /api/v1/technician/jobs/{jobId}/items/{itemCode}/evidence/init`
- `PUT  /api/v1/technician/jobs/{jobId}/items/{itemCode}/evidence/{evidenceId}/content`
- `POST /api/v1/technician/jobs/{jobId}/items/{itemCode}/evidence/{evidenceId}/complete`
- `GET  /api/v1/technician/jobs/{jobId}/items/{itemCode}/evidence`
- existing vehicle-photo init/content/complete endpoints
- existing `enumsProvider('result')` / `enumsProvider('evidence-type')` for labels and tones

No field was added, removed or re-shaped. No client DTO, mapper, repository or
OpenAPI change. No migration or rollback note is required.

## Review module (summary · signature · completed)

**None.** The review screens reuse the existing `technicianSummaryProvider`,
`technicianReviewProvider`, `technicianJobSummaryProvider`,
`technicianConflictsProvider`, `submitSignature` and `completeJob` calls
unchanged. No new field, endpoint or shape.

**done 0 · blocked 0**
