# Phase 6 Decisions

**Project:** TrueReport  
**Date:** 4 November 2026  
**Status:** Accepted for Phase 6 implementation

---

## 1. D4 - Public report rendering

| Item | Decision | Evidence |
|---|---|---|
| Renderer | Server-rendered HTML from Spring MVC using Thymeleaf | D4 approved; ADR-0004; Phase 6 implementation |
| Template engine | **Thymeleaf 3.1.5.RELEASE** (resolved by Spring Boot 4.1.2) | Maven dependency tree; `thymeleaf.org` (21 April 2026 release note) |
| Licence | Apache License 2.0 | `https://www.thymeleaf.org/` footer links Apache-2.0 |
| Client JavaScript | None | Public templates contain no `<script>` |
| Styling | Local `/r/assets/report.css`; design-system colours, spacing, type scale; light/dark via `prefers-color-scheme` | Phase 6 template/CSS |
| Fonts | Bundled Noto Naskh Arabic, Noto Sans, Noto Sans SC in `server/src/main/resources/public-report/fonts/` | OFL licence file included; no runtime font download |
| External requests | None expected or allowed | Browser check recorded zero external requests |
| URL | `/r/{token}`; language selector `?lang=en` / `?lang=ar` | Phase 6 controller |
| Rendering source | Only `ReportSnapshot` built from the immutable final inspection snapshot | `ReportSnapshotBuilder` |
| Public DTO boundary | Explicit allowlist map/snapshot; no entity serialization, no customer fields, no original evidence | `ReportSnapshot`, `ReportViewMapper` |

---

## 2. D5 - Bilingual PDF

| Item | Decision | Evidence |
|---|---|---|
| Engine | Headless Chromium rendering a dedicated print HTML template | D5 approved; ADR-0005 |
| Runtime image | `mcr.microsoft.com/playwright/java:v1.64.0-noble` used as a **build stage only** to supply Chromium | Dockerfile; image inspected |
| Chromium binary in runtime | `Google Chrome for Testing 156.0.8078.4` copied from the Playwright image to `/opt/chromium` | `docker compose exec server /opt/chromium/chrome-linux64/chrome --version` |
| Playwright Java | **1.64.0**, Apache License 2.0 | Maven Central metadata; `raw.githubusercontent.com/microsoft/playwright-java/main/LICENSE` |
| Chromium licence | BSD-style Chromium licence | `chromium.googlesource.com/chromium/src/+/main/LICENSE` |
| Rendering process | `ChromiumPdfRenderer` runs Chromium in headless mode with a temporary profile; no network needed | Process command is local-file only |
| PDF template | `templates/report/print-report.html`; same snapshot as HTML | Phase 6 template |
| Fonts | Bundled Arabic/Latin/CJK fonts embedded as data URIs in print HTML | `ReportFonts` |
| Report ID and version | Repeated fixed footer on every PDF page | `print-report.html` |
| Runtime image size | **1,883,063,993 bytes (~1.88 GB)** final image; Playwright builder stage is ~5.38 GB | `docker image inspect` |
| Memory impact | Chromium process is separate from the JVM; peak memory under concurrency was **not measured** in Phase 6 | Honest limitation |
| PDF download | Public download disabled by default; Workshop Admin can enable per report; admin download always available when READY | `public_share_links.pdf_download_enabled` |
| Failure isolation | PDF/derivative failure marks the generation job `FAILED`; it never rolls back a finalized inspection | `ReportGenerationService` |

---

## 3. D9 - Report versions and corrections

| Item | Decision | Notes |
|---|---|---|
| Report model | `reports` + `report_versions`; v1 only | Schema and API create v1 only |
| Correction UI/API | None | D9 constraint |
| Future correction | A later approved correction can insert report v2 referencing v1 without overwriting | No policy invented now |
| Finalized immutability | Report and report-version rows are protected by service guards and MySQL triggers | V11 triggers verified |

---

## 4. Public link and consent

| Item | Decision | Notes |
|---|---|---|
| Token | 32 random bytes from `SecureRandom`, base64url, at least 43 characters | `ReportTokenService` |
| Storage | Only SHA-256 token hash; lookup by hash; plaintext token never logged | `public_share_links.token_hash` |
| Activation | Only after latest `PUBLIC_LINK` consent is `GRANTED` | C1 / RQ13 |
| Link states | `PENDING_CONSENT`, `ACTIVE`, `REVOKED` | No active link without consent |
| Reactivation | **Not allowed in V1** | RQ13 approved; fresh consent alone is not sufficient |
| Revocation | Workshop Admin only, own workshop, reason code required, audited | `ReportService.revoke` |
| Revocation notice | Page/API state that copies, screenshots and downloaded PDFs cannot be recalled | UI and docs |
| Public URL visibility | Returned once at activation; only the hash is stored, so it cannot be re-read later | Honest UX limitation |
| Invalid/revoked/inactive | Same neutral 404 page and body | Tested |
| Rate limit | 240 requests/minute per IP for token routes; neutral 429 | In-memory filter; production needs shared/WAF limiting |
| Cache policy | `Cache-Control: no-store` for HTML, photos and PDF; revocation takes effect at origin immediately | Header test |
| Headers | `noindex, nofollow`, `Referrer-Policy: no-referrer`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, strict CSP | `PublicReportHeadersFilter` |

---

## 5. Public content and privacy

- Public allowlist is implemented in `ReportSnapshotBuilder` and `ReportViewMapper`.
- Customer name, phone, email, full VIN, plate and internal IDs are not copied into the report snapshot.
- VIN is masked to the last four characters.
- Full VIN-like 17-character strings and email addresses in technician notes are redacted before publication.
- Original evidence is never served publicly. `PUBLIC_FULL` derivatives are resized, re-encoded, EXIF/GPS-stripped and content-hashed.
- Public photos are token-bound and `no-store`; revocation stops future server access.
- Guide images are not included as evidence.
- Report text avoids "certified", "approved" and "independently verified"; it uses coverage counts, not a condition score.
- A clean result is explicitly not presented as a perfect vehicle.

---

## 6. Report generation state

| State | Meaning |
|---|---|
| `QUEUED` | Report v1 and generation job created at finalization |
| `GENERATING` | Worker is generating public derivatives and the PDF |
| `READY` | Derivatives and PDF are available |
| `FAILED` | Generation failed; finalized inspection and report version are unchanged; admin can retry |

Generation is a scheduled DB-polled worker. The final inspection transaction creates the immutable report v1/job; worker failure does not undo finalization.

---

## 7. Unchanged or pending

- D6 production object storage remains **Pending**; local disk storage is development-only.
- D7 forms, D8 messaging, D11 final photo/retention policy and C2 legal wording remain Pending.
- Phase 7 delivery (WhatsApp/SMS/email) is not implemented.
- No correction UI/API, manager/review queue, customer app/portal, or payments.
- Customer/vehicle data remains fake-only; encryption and legal compliance are not claimed.
- Public photo face/plate blurring is **not implemented**; a product/legal policy is required before real evidence is published.
