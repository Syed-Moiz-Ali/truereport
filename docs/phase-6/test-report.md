# Phase 6 Test Report

**Project:** TrueReport  
**Date:** 4 November 2026  
**Environment:** Windows 11, Flutter 3.47.9 / Dart 3.13.7, Java 25.0.5, Maven 3.9.16, Docker Desktop 4.98.0, Docker engine 29.9.2, MySQL 8.4.13.

---

## 1. Step 0 - Base verification (before Phase 6 changes)

Docker Compose was started and the existing base was verified before new feature work.

| Check | Result |
|---|---|
| `docker compose up --build --detach` | PASS |
| MySQL 8.4.13 / Mailpit / server healthy | PASS |
| Server tests | **34/34 passed**, 0 skipped, including `MySqlMigrationIT` |
| Technician Flutter tests | **20/20 passed** |
| Admin Flutter tests | **77/77 passed** |
| Flutter analyze | clean |

The pre-Phase 6 server suite included the existing Phase 5B evidence tests and MySQL triggers. No regression was accepted into Phase 6.

---

## 2. Final server tests

Command:

```powershell
$env:Path='C:\Users\sanja\AppData\Local\Programs\DockerDesktop\resources\bin;'+$env:Path
mvn -q test
```

Result: **38 tests run, 0 failures, 0 errors, 1 skipped** (the conditional PDF sample test is skipped in the normal suite).

| Suite | Tests |
|---|---:|
| ArchitectureTest | 2 |
| AuthTenancyIT | 7 |
| EvidenceIT | 3 |
| FlywayMigrationTest | 1 |
| FoundationIT | 3 |
| TotpServiceTest | 2 |
| MasterContentIT | 3 |
| MySqlMigrationIT | 1 |
| PlatformHierarchyIT | 4 |
| ReportIT | 3 |
| ReportPdfSampleTest | 1 skipped in normal suite |
| TechnicianInspectionConcurrencyIT | 1 |
| TechnicianInspectionIT | 4 |
| WorkshopAdminIT | 3 |

### ReportIT coverage - PASS

- Report v1 is created from the frozen final snapshot; changing the master item after finalization does not change the report snapshot.
- Strict allowlist: fake customer name, phone, email, full VIN and plate are absent from report snapshot, HTML and PDF text.
- Full VIN-like strings and email addresses inside technician notes are redacted.
- Report snapshot hash remains stable while a failed generation job is retried.
- Forced `FAILED` generation does not alter the finalized inspection or final snapshot; admin retry returns to `READY`.
- Public-link activation without `PUBLIC_LINK` consent returns `422 CONSENT_REQUIRED`.
- Token length is at least 43 characters; only a 32-byte SHA-256 hash is stored.
- Public HTML, photo and PDF access stop immediately after revocation.
- Invalid and revoked tokens return the same neutral 404 body.
- `403`/`404` role and cross-workshop matrix checks cover report, retry, link and PDF endpoints.
- Public rate limit returns `429` with `Retry-After: 60` after 240 requests in a minute.
- Security headers include `X-Robots-Tag: noindex, nofollow`, `Referrer-Policy: no-referrer`, `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`, CSP and frame denial.
- Arabic page sets `dir="rtl"` and Arabic labels.
- PDF download is disabled by default; enabling the per-report flag allows the token-bound PDF.
- A scan of Surefire reports for the fake customer name, phone, email, full VIN and plate found no matches.

### MySQL - PASS

`MySqlMigrationIT` on Testcontainers MySQL 8.4.13:

- V1-V11 applied successfully.
- Report tables exist: `reports`, `report_versions`, `report_generation_jobs`, `report_artifacts`, `public_share_links`.
- Report triggers exist and reject update/delete:
  - `trg_reports_no_update`
  - `trg_reports_no_delete`
  - `trg_report_versions_no_update`
  - `trg_report_versions_no_delete`
  - `trg_public_share_link_no_token_change`
- Direct SQL updates to `reports` and `report_versions` were rejected with `40000`/immutability errors.

Real Compose MySQL:

```text
1 core tenancy auth               1
2 audit events                    1
3 platform hierarchy              1
4 master content                  1
5 workshop templates and jobs     1
6 immutability triggers           1
7 inspection execution            1
8 inspection immutability triggers 1
9 evidence uploads                1
10 reports public links           1
11 report immutability triggers   1
```

Real Compose report/PDF check:

```text
generationStatus=READY
reportReady=true
pdfReady=true
admin PDF bytes=269279
PDF magic bytes=37,80,68,70,45  (%PDF-)
```

The Docker runtime reports:

```text
Google Chrome for Testing 156.0.8078.4
final server image size=1,883,064,008 bytes (~1.88 GB)
idle server container memory=395.7 MiB (docker stats, no load)
```

The Playwright build stage is ~5.38 GB; only Chromium is copied into the final JRE image. Chromium peak memory under concurrent PDF generation was **not measured**.

---

## 3. PDF sample generation - PASS

Command:

```powershell
mvn -q "-Dtruereport.samples=true" -Dtest=ReportPdfSampleTest test
```

Result: **1/1 passed**.

Artifacts:

- `docs/phase-6/samples/bilingual-report-sample.pdf` (469,429 bytes)
- `docs/phase-6/samples/bilingual-report-sample.txt` (PDF text extraction)
- `docs/phase-6/samples/bilingual-report-sample-page-1.png`
- `docs/phase-6/samples/bilingual-report-sample-page-2.png`
- `docs/phase-6/samples/bilingual-report-sample-page-9.png`

Content: 20 photos, long mixed English/Arabic text, Russian and Chinese text, repeated table headers, 9 pages, report ID/version footer on every page.

Manual visual check performed on the exported PNG pages:

- Arabic headings and right-to-left blocks render.
- Latin, Cyrillic and CJK text is visible.
- Mixed numbers/VIN do not visibly break the table layout.
- Long notes wrap instead of clipping.
- Repeated table headers and footer appear on later pages.
- A fixed-footer overlap found on the first render was corrected; page 2/page 9 were rechecked.
- **Native Arabic reviewer sign-off: NOT DONE.**
- PDF text extraction shows Arabic glyphs as question marks/spaced glyphs in this toolchain; visual PNG inspection was used for Arabic review. This is an extraction artifact, not proof of native correctness.

---

## 4. Public browser check - PASS

Script: `docs/phase-6/browser-check.mjs` (run from `spikes/public-report` where Playwright 1.56.1 / Axe 4.10.2 are installed).

Live local report used: active report page from the Phase 6 test job.

Result JSON (`docs/phase-6/samples/public-report-browser-check.json`):

```json
{
  "status": 200,
  "loadMs": 988,
  "title": "Vehicle inspection report",
  "robots": "noindex, nofollow, noarchive",
  "viewport": "width=device-width, initial-scale=1",
  "dir": "rtl",
'  "externalRequests": [],
  "focusedElement": "A",
  "lightScreenshot": "docs/phase-6/samples/public-report-light-phone.png",
  "htmlBytes": 6425,
  "axeViolations": []'
}
```

Screenshots:

- `docs/phase-6/samples/public-report-dark-phone.png`
- `docs/phase-6/samples/public-report-ar-dark-phone.png`
- `docs/phase-6/samples/public-report-light-phone.png`

Observed:

- 390px phone viewport, dark mode, no overflow.
- No external requests; CSS and fonts are same-origin.
- `dir="rtl"` on the Arabic page.
- No axe violations in the tested page.
- Keyboard tab focuses a link (`focusedElement= A`).
- Light-mode screenshot captured.
- Page text is real HTML (not canvas); language switch works.
- Report IDs are not the public token and no customer/contact field appears.
- Revocation test in ReportIT returns the same neutral 404 page for revoked and invalid tokens.
- Public PDF and photo endpoints stop after revocation.

Not tested in a real browser/device: WhatsApp in-app browser, iOS Safari, native screen reader, real slow network, and copy/paste in every messaging app.

---

## 5. Flutter

### Analyze

```text
admin_app       flutter analyze --fatal-infos -> No issues found!
technician_app  flutter analyze --fatal-infos -> No issues found!
```

### Tests

```text
admin_app       79/79 passed
technician_app  20/20 passed
```

Admin coverage includes the report page in EN/AR at phone width; existing matrix covers light/dark, 1.5x/2.0x text, phone/tablet/wide and no-overflow checks. Technician tests retain the existing EN/AR, light/dark, phone/tablet and 2.0x text matrix.

### Builds

```text
admin_app       flutter build web --release --no-pub -> PASS
admin_app       flutter build apk --debug --no-pub -> PASS
technician_app  flutter build web --release --no-pub -> PASS
technician_app  flutter build apk --debug --no-pub -> PASS
```

The admin debug APK was **171,904,653 bytes** and the technician debug APK was **247,595,847 bytes** at the last successful builds. `kotlin.incremental=false` was added to both Android apps because the Kotlin incremental cache failed across different Windows drives.

---

## 6. What was not verified

- Real Android/iPhone and WhatsApp in-app browser behavior.
- Native Arabic reader sign-off on the full PDF corpus.
- Chromium/JVM peak memory and PDF generation at concurrency 2/4.
- 30-page PDF / 30-photo stress case (sample used 20 photos).
- PDF in Adobe Acrobat, Apple Preview and every mobile viewer.
- MinIO path (optional profile; D6 remains Pending).
- Production object storage, CDN/proxy cache purge, D6, D7, D8, D11 and C2.
- Public photo face/plate blurring; no automatic moderation exists.
- Report creation from legacy finalized snapshots may show blank workshop/technician/VIN because those legacy snapshots predate the added metadata. New finalized reports include them.
