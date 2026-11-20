# Flow — Reports, PDF and delivery

Scope: Workshop Admin report screens + `reports`/`documents`/`delivery` backend. The public viewer is covered in
`public_report.md`.

## Happy path — link + PDF

1. After approval, the report version exists (`platform_report_versions`, built in `approve`).
2. Report page `features/reports/report_page.dart` loads `GET /api/v1/workshop/jobs/{id}/report`
   (`admin_api.dart:898`) → `reports/api/WorkshopReportController`.
3. Link creation/revoke go through the job endpoints (`/workshop/jobs/{id}/report/link`,
   `/report/link/revoke`) → token hash stored; plaintext URL returned once.
4. PDF toggle `PUT /workshop/jobs/{id}/report/pdf-download` controls whether the public page exposes the PDF.
5. Admin PDF download `GET /workshop/jobs/{id}/report/pdf` streams the generated artifact.
6. Retry `POST /workshop/jobs/{id}/report/retry` re-queues generation.
7. Public URL `GET /r/{token}` is served by `reports/api/PublicReportController.java:42`; ACTIVE renders
   `report/public-report.html`, TEMPORARY renders `temporarily-unavailable`, otherwise neutral 404.

## Happy path — delivery

1. Workshop Admin opens the report distribution sheet (`features/reports/report_distribution.dart`).
2. Queue a delivery: `POST /api/v1/workshop/jobs/{jobId}/deliveries` with channel/recipient/consent context
   (`admin_api.dart:960`) → `delivery/api/WorkshopDeliveryController`.
3. Delivery worker polls `report_deliveries`; fake provider returns a deterministic result by default
   (`truereport.delivery.fake-enabled=true`), SMTP is used for email.
4. Status/retry: `GET /workshop/jobs/{jobId}/deliveries`, `POST .../{deliveryId}/retry`.
5. Provider callbacks: `POST /api/v1/delivery/webhooks/{provider}` with HMAC + replay rejection.
6. Platform delivery list `GET /api/v1/platform/deliveries` exists (`PlatformDeliveryController.java`) but has **no
   Platform Admin screen**.

## Branches

- **No consent / no link** → delivery cannot be queued from UI; server validates state.
- **Fake provider** → delivery is accepted but not actually sent; this is explicit dev behaviour, not a success claim.
- **SMTP down** → email delivery fails and is retryable; `/actuator/health` returns 503 in the audit environment
  because Mailpit/MinIO are absent.
- **PDF engine absent** → document status `FAILED` with admin retry; `CHROME_PATH` must be configured for local PDFs.
- **Report data honesty** → the HTML/PDF view mapper currently injects hardcoded demo content (see
  `public_report.md` and `docs/flow_gaps.md` BLOCKER-03); delivery of that report would distribute fabricated vehicle
  facts.

## Verification status

Server: `ReportIT`, `DeliveryIT`, `DeliveryRecipientPolicyTest`, `ReportDeliveryBundleParityTest`,
`ReportPdfSampleTest` (conditional). Browser: pending.
