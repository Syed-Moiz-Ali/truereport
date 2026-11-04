# Phase 6 - Immutable Report, Public Link and Bilingual PDF

**Status:** Implemented and locally verified; native Arabic and real-device checks remain open.

## Delivered

- Immutable report v1 created from the frozen final inspection snapshot.
- Report versions table ready for a future correction version; only v1 exists.
- Background report generation job with `QUEUED`, `GENERATING`, `READY`, `FAILED` and admin retry.
- Server-rendered public report at `/r/{token}` with English/Arabic switcher, RTL, light/dark CSS, bundled fonts and no JavaScript.
- Strict report allowlist; no customer name/phone/email/full VIN/plate in report snapshot, HTML or PDF.
- VIN masking and full-VIN/email redaction in technician notes.
- Public-safe resized/re-encoded/EXIF-stripped evidence derivatives; originals stay private.
- Public-link creation gated by public-link consent; 256-bit token stored only as a SHA-256 hash.
- Revocation with required reason, audit, neutral 404 for invalid/revoked links, no reactivation in V1.
- Bilingual PDF from a dedicated print template using headless Chromium; report ID/version footer on every page.
- PDF download disabled by default, per-report Workshop Admin toggle; admin download always available when ready.
- Workshop Admin report viewer/status/link controls in `admin_app`; technician report status read-only.
- Security headers, neutral metadata, no-store cache policy and a 240/min/public-IP in-memory rate limit.

## Explicitly not delivered

- WhatsApp/SMS/email delivery (Phase 7).
- Correction UI/API or report v2.
- Manager/review queue, customer app/portal or payments.
- Production object storage (D6 Pending); local storage is development-only.
- Public photo face/plate blurring.
- Native Arabic reviewer sign-off.

## Run

```powershell
$env:Path='C:\Users\sanja\AppData\Local\Programs\DockerDesktop\resources\bin;'+$env:Path
cd infra
docker compose up --build --detach
```

Server tests:

```powershell
cd ..\server
mvn -q test
```

PDF sample:

```powershell
mvn -q "-Dtruereport.samples=true" -Dtest=ReportPdfSampleTest test
```

Flutter:

```powershell
cd ..\client
flutter analyze --fatal-infos
cd apps/admin_app; flutter test; flutter build web --release --no-pub
cd ../technician_app; flutter test; flutter build web --release --no-pub; flutter build apk --debug --no-pub
```

## Samples and evidence

- `docs/phase-6/samples/bilingual-report-sample.pdf`
- `docs/phase-6/samples/bilingual-report-sample.txt`
- `docs/phase-6/samples/bilingual-report-sample-page-*.png`
- `docs/phase-6/samples/public-report-dark-phone.png`
- `docs/phase-6/samples/public-report-ar-dark-phone.png`
- `docs/phase-6/samples/public-report-light-phone.png`
- `docs/phase-6/samples/public-report-browser-check.json`

## Known limitations

- Real Android/iPhone, WhatsApp in-app browser, iOS Safari and native screen readers are not verified.
- Native Arabic reviewer sign-off is **NOT DONE**.
- Chromium memory and PDF generation under concurrency are not measured.
- Report creation from legacy Phase 5 snapshots can show blank workshop/technician/VIN because those snapshots predate the metadata fields.
- Public evidence may still show a plate, face or address; a product/legal redaction policy is required.
- A revoked link cannot be reactivated; the plaintext URL is only returned once at activation.
