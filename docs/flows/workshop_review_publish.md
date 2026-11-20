# Flow — Review, approve, publish, documents

Scope: `workshop_admin_app` job detail/approve/publish screens + `jobs`/`reports`/`documents` backend.

## Happy path (assuming a technician completed the job)

1. Technician completes → job `PENDING_REVIEW` (see `technician_inspection.md`).
2. Workshop Admin opens the job → `features/jobs/job_detail_page.dart` / `detail/job_detail_review_publication.dart`.
3. Review loads `GET /api/v1/workshop/jobs/{id}/review` (`admin_api.dart:1117`) →
   `jobs/api/WorkshopJobAdminController.java:145`.
4. `WorkshopJobAdminService.review` compares the pinned items with assessments, evidence and signature, and returns
   per-item results plus a readiness summary (`WorkshopJobAdminService.java:377-400`).
5. "Approve" opens `approve_job_page.dart`; submit calls `approveJob` (`:273`, `admin_api.dart:1137`) →
   `POST /workshop/jobs/{id}/approve` with `Idempotency-Key`.
6. Server requires `PENDING_REVIEW`, approver ≠ assigned technician, a passing approval checklist, and computes the
   score/grade. It writes an immutable report version (`platform_report_versions`) with a JSON snapshot + SHA-256,
   then sets `APPROVED` (`WorkshopJobAdminService.java:414-474`).
7. "Publish checklist" loads `GET /workshop/jobs/{id}/publish-checklist` (`:402-412`), which lists the readiness gates:
   all items assessed, evidence rules met, signature present, score computed, safety cap explained?, consent granted,
   approver ≠ technician, documents queued (`:840-866`).
8. Publish page (`publish_checklist_page.dart`) calls `publishJob` (`:181`) →
   `POST /workshop/jobs/{id}/publish` with `Idempotency-Key` and `pdfDownloadEnabled`.
9. Server requires `APPROVED`, `consent_granted = true`, and a report version; creates a 256-bit token, stores only
   its hash, sets `PUBLISHED`, generates report documents (PDF) asynchronously
   (`WorkshopJobAdminService.java:507-556`).
10. UI shows the public URL + QR (`public_link_page.dart`); link can be rotated (`POST .../rotate-token`), revoked with
    a reason (`POST .../revoke`), or the job unpublished (`POST .../unpublish`).
11. Documents tab (`job_documents_page.dart`) loads `GET /workshop/jobs/{id}/documents`, retries a type via
    `POST .../documents/{type}/retry`, and downloads content. PDF toggle uses
    `PUT /workshop/jobs/{id}/report/pdf-download`.
12. Delivery is queued from `features/reports/report_distribution.dart` via
    `POST /workshop/jobs/{jobId}/deliveries` and retried via `.../deliveries/{deliveryId}/retry`.

## Branches

- **Not pending review** → 409 `JOB_NOT_PENDING_REVIEW`.
- **Approver is the technician** → 409 `APPROVER_IS_TECHNICIAN`.
- **Checklist incomplete** → 422 `APPROVAL_CHECKLIST_INCOMPLETE` with per-gate issues.
- **Consent missing** → 422 `CONSENT_REQUIRED` on publish. Fixed by
  `PUT /api/v1/workshop/jobs/{id}/consent` and the "Granted" action in job detail; the technician's legacy consent
  form still writes `consent_records` and is a remaining DRIFT (BLOCKER-02 closed for the Workshop path).
- **Report version missing** → 409 `REPORT_VERSION_MISSING`.
- **Already published** → idempotent return of the active link.
- **Revoked link** → public route returns neutral 404; cannot be reactivated (rotate instead).
- **Permission denied** → workshop-scoped `@PreAuthorize`; cross-workshop ID is 404.

## Verification status

Server: `WorkshopJobAdminIT` covers approve/reject/consent/publish states; `ReportIT` covers snapshot/public access.
Browser: pending — blocked by BLOCKER-02 until consent is writable.
