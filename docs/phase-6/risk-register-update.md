# Phase 6 Risk Register Update

**Project:** TrueReport  
**Date:** 4 November 2026  
**Baseline:** `docs/phase-5b/risk-register-update.md`

---

## 1. Closed / reduced risks

| ID | Previous risk | Status | Evidence |
|---|---|---|---|
| R81 | Evidence warnings were non-blocking | Closed earlier in 5B | Required evidence remains blocking |
| R84 | Offline work absent | Closed earlier in 5B | Drift + sync queue |
| R88 | Guide images absent | Closed earlier in 5B | Cached guide-image rendering |
| R93 | No report/link/PDF implementation | **Closed** | Server-rendered report, token links, PDF and derivatives implemented |
| R94 | No report allowlist | **Closed** | `ReportSnapshotBuilder` / `ReportViewMapper`; PII/full-VIN tests |
| R95 | Report generation tied to finalization failure | **Mitigated** | Report v1/job created in finalization; PDF/derivative failure is `FAILED` and retryable |
| R96 | No MySQL report immutability | **Closed** | V11 triggers verified on MySQL 8.4.13 |

---

## 2. New / remaining risks

| ID | Risk | Impact | Likelihood | Score | Mitigation | Early warning |
|---|---|---|---|---|---|---|
| R100 | Public link token cannot be re-read after activation because only its hash is stored | 3 | 4 | 12 High | Return URL once at activation; UI tells admin to copy immediately; a lost URL requires a future policy/report version, not silent reissue | Admin loses the URL and asks support to recover it |
| R101 | Public evidence photos may contain plates, faces or addresses | 4 | 4 | 16 High | Public derivative path only; policy for cropping/blurring is **not implemented**; do not use real evidence publicly before policy/legal approval | A public report contains a readable plate/face |
| R102 | PDF image/runtime is heavy (final image ~1.88 GB; Playwright builder ~5.38 GB) | 3 | 4 | 12 High | Chromium copied into a slim JRE stage; monitor disk/RAM; worker is scheduled; measure concurrency before production | Container disk pressure, slow starts or PDF timeouts |
| R103 | Chromium/JVM memory at concurrency is unmeasured | 4 | 3 | 12 High | Add load test at 1/2/4 concurrent PDF jobs; add worker semaphore/timeouts | OOM or Chromium hangs |
| R104 | In-memory public rate limit is single-instance | 3 | 3 | 9 Medium | Replace with shared limiter/WAF before horizontal scaling; keep neutral 429 | Abuse spikes across replicas |
| R105 | Arabic native review not done | 4 | 4 | 16 High | Native Arabic reviewer must sign off before pilot; do not claim approval | Arabic shaping/bidi errors seen by native reader |
| R106 | Real WhatsApp/iOS/Safari and screen-reader behavior untested | 4 | 4 | 16 High | Device matrix and in-app browser tests before pilot | Preview/layout/accessibility failures on real devices |
| R107 | Legacy finalized reports have blank workshop/technician/VIN metadata | 2 | 3 | 6 Medium | New final snapshots include metadata; legacy reports show blanks rather than invented data; regenerate only through an approved process | Support sees incomplete legacy report |
| R108 | Public PDF download can be enabled per report, contrary to the original PDF1 default | 3 | 2 | 6 Medium | Off by default; Workshop Admin only; audited setting; revocation stops future access; copies cannot be recalled | A report unexpectedly exposes a PDF |
| R109 | Report generation is DB-polled and can be delayed | 2 | 3 | 6 Medium | `QUEUED`/`FAILED` visible to admins; retry endpoint; worker delay 2s | Reports remain queued for long periods |
| R110 | Public report content depends on report worker readiness | 3 | 3 | 9 Medium | Neutral temporary page; no partial report; admins see failure and retry | Public hits temporary page after finalization |
| R111 | No correction process; a wrong report cannot be corrected in-product | 4 | 4 | 16 High | D9 blocks corrections; support/legal process still required; report v1 preserved | Customer requests correction but no approved workflow exists |
| R112 | Local storage is development-only (D6 Pending) | 4 | 3 | 12 High | ObjectStorage boundary retained; do not deploy local storage to production | Production deployment uses local disk |
| R113 | Report photos are token-bound but already-downloaded copies cannot be revoked | 3 | 4 | 12 High | `no-store`, token-bound access, explicit revocation notice in UI/docs | Recipient keeps a screenshot or downloaded PDF |
| R114 | Customer/vehicle data remains fake-only and unencrypted | 4 | 3 | 12 High | No real customer data; C2/encryption pending; no compliance claim | Real data entered before legal/encryption work |
| R115 | PDF text extraction does not preserve Arabic glyphs in test tooling | 2 | 3 | 6 Medium | Visual PNG review used; native reviewer still required; do not use extraction as the sole Arabic test | Accessibility/searchability of PDF text is required later |
| R116 | Google Chrome for Testing binary is copied from Playwright image into the JRE stage | 3 | 2 | 6 Medium | Pin Playwright image tag; verify licence and patch cadence; re-run PDF tests after updates | Browser binary out of date or missing shared library |

---

## 3. Unchanged

- D6 production object storage, D7 forms, D8 messaging, D11 final photo/retention policy and C2 legal wording remain Pending.
- No report delivery, correction UI/API, manager/review queue, customer portal or payments.
- No claim of encryption, PDPL/GDPR compliance or native Arabic certification.
- No public face/plate blurring; this is a product/legal policy gap, not a hidden feature.

---

## 4. Top Phase 6 risks

1. R101 public photos may expose plates/faces.
2. R105 Arabic native review.
3. R106 real WhatsApp/iOS/accessibility matrix.
4. R111 no correction policy.
5. R102/R103 PDF runtime cost and concurrency.
6. R100 lost public URL after activation.
7. R112 local storage is not production storage.

---

## 5. Decisions needed

- Approve or reject public photo cropping/blurring policy before real evidence is published.
- Approve report retention and PDF artifact retention (D11/C2).
- Decide how to recover a lost active public URL without weakening token hashing.
- Decide when a correction policy (D9) will be written; it remains blocked.
- Approve production object storage (D6), delivery providers (D8) and form package (D7) later.
