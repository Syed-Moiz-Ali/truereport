# Flow — Public report and PDF

Scope: anonymous `/r/{token}` + `reports` module.

## Happy path

1. Workshop Admin publishes an approved job → active `platform_public_links` row (token hash + encrypted token).
2. Public viewer opens `GET /r/{token}` → `reports/api/PublicReportController.java:42`.
3. `PublicReportService.resolve(token, language)` hashes the token, looks up the ACTIVE link, loads the report
   version, and distinguishes ACTIVE / TEMPORARY / missing (`PublicReportService`).
4. ACTIVE → Thymeleaf `templates/report/public-report.html`; model from
   `ReportViewMapper.publicPage(version, derivatives, language, false)`.
5. Photos: `GET /r/{token}/photo/{derivativeId}` serves only public-safe derivatives of evidence attached to that
   report (`PublicReportController.java:64`).
6. PDF: `GET /r/{token}/pdf` serves the artifact only when the report's PDF toggle is on and the document is READY
   (`:74`); otherwise 404.
7. Language switch EN/AR re-renders the same token with `?lang=ar`; RTL and Arabic labels come from
   `ReportMessages`/templates.
8. Revoke/unpublish → neutral `unavailable` page with 404 status; invalid token gets the same neutral page (no
   existence oracle).
9. Security: rate limit filter, no-store cache headers, no customer PII (name/phone/email/full VIN/plate) in the
   snapshot, masked VIN, EXIF-stripped derivatives.

## Branches

- **TEMPORARY** → `temporarily-unavailable.html` (report still generating); status from
  `PublicReportService.statusFor`.
- **Revoked/invalid** → neutral `unavailable.html` (404).
- **PDF disabled** → 404 on `/pdf` and the download control is hidden.
- **Clean report resolution (fixed)** → `PublicReportService` now falls back to
  `platform_public_links -> platform_report_versions` through `CleanPublicReportReader` when the legacy tables have no
  match. Verified `GET /r/{token}` = 200 with real Toyota/Land Cruiser + real checklist rows, and
  `GET /r/{token}/pdf` = 200 with `%PDF`. The active-report browser assertion remains skipped by request, not by a
  known failure.
- **Report data honesty (dynamic sections)** → the hardcoded vehicle facts and per-item fake media were removed.
  `tyreAssemblies` is derived from real multi-point tyre measurements, `damageZones` from real non-pass body/tyre
  items, and `vehicleShowcase` from real public evidence photo URLs (`/r/{token}/photo/{id}`). Sections render empty
  when the underlying data is absent. The historical code path injected:
  - vehicle gearbox/fuel/drivetrain/engine/colour/interior/wheels/keys/emirate/client/center are constants
    (`ReportViewMapper.java:215-243`), ignoring the job's `transmission`/`fuelType`;
  - every item claims `hasVideo = true` and a stock video URL (`:381-388`);
  - per-item "diagnostic metric"/"standard spec"/part photo are invented from the stable code (`:1060-1118`);
  - eight visual inspection cards, 32 showcase photos, four tyre assemblies, damage zones, inspection systems,
    inspector summary and inspection videos are fixed demo content (`:468-659`, `:737-1058`, `:1120-1490`).
  A published report therefore shows fabricated facts (e.g. "Precious Silver Metallic", "Scratch: 42mm",
  "Brake Pad 3.1mm") for any vehicle. This must be treated as fabricated public data, not styling.
- **Report version from legacy snapshots** may have blank workshop/technician/VIN (documented Phase 6 limitation).
- **Arabic** → translated labels; native Arabic sign-off is still open (documented).

## Verification status

Server: `ReportIT`, `ReportDeliveryBundleParityTest`, `ReportPdfSampleTest` (conditional), `SecurityEndpointInventoryIT`.
Browser: pending — will assert neutral 404, active render and PDF toggle; the data-fabrication checks are code-level
until the mapper is fixed.
