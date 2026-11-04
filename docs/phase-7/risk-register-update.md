# Phase 7 Risk Register Update

**Project:** TrueReport  
**Date:** 4 November 2026  
**Baseline:** `docs/phase-6/risk-register-update.md`

---

## 1. Closed / reduced risks

| ID | Previous risk | Status | Evidence |
|---|---|---|---|
| R93 | No report/link/PDF implementation | Closed in Phase 6 | Report HTML, PDF, links and derivatives implemented |
| R94 | No report allowlist | Closed in Phase 6 | Public snapshot allowlist and PII tests |
| R95 | Report generation tied to finalization failure | Mitigated in Phase 6 | Report v1/job created at finalization; failure is retryable |
| R96 | No MySQL report immutability | Closed in Phase 6 | V11 triggers |
| R117 | No delivery implementation | **Closed for local subsystem** | Delivery service, fake providers, SMTP, webhooks, retries and admin/technician UI |
| R118 | Message body could expose customer data | **Mitigated** | Fake/Mailpit tests assert neutral body; no customer fields |
| R119 | Report can only have one public link | **Closed** | V13 removes unique constraint; ADR-0018; delivery creates a link per send |

---

## 2. New / remaining risks

| ID | Risk | Impact | Likelihood | Score | Mitigation | Early warning |
|---|---|---|---|---|---|---|
| R120 | D8 remains Pending; no real WhatsApp/SMS provider is contracted or tested | 4 | 4 | 16 High | Keep provider adapters abstract; require sandbox and allowlist before pilot; do not claim provider readiness | Pilot asks to send to real customers |
| R121 | Real recipients are disabled by default and only allowlisted test recipients work unless explicitly enabled | 3 | 4 | 12 High | Keep allowlist enforced by default; require explicit approved configuration change and test before enabling | Admin reports `RECIPIENT_NOT_ALLOWED` |
| R122 | Multiple active links exist per report and cannot be recalled after delivery | 3 | 4 | 12 High | Explicit revocation revokes all active links; `no-store`; warn admins that copies/screenshots/PDFs cannot be recalled; add retention/cleanup policy | Active link count grows unexpectedly |
| R123 | Provider inbox/app previews or sender identity may leak metadata | 3 | 4 | 12 High | Keep bodies neutral; test real WhatsApp/email previews before pilot; avoid customer data in subject/body | Screenshot shows unintended metadata |
| R124 | Webhook spoofing or replay | 3 | 3 | 9 Medium | HMAC-SHA256 signature; event ID replay storage; secret config; add provider-specific signature verification | Repeated event IDs or invalid signatures spike |
| R125 | Retry storms or rate-limit bypass across instances | 3 | 3 | 9 Medium | Exponential backoff, max attempts, dead-letter, per-workshop recipient-hour limit; replace in-memory limit for multi-instance | Dead-letter or 429 spike |
| R126 | PDF attachment exceeds provider/email limit | 3 | 3 | 9 Medium | Configurable 10 MiB attachment limit; link fallback only with public-link consent; otherwise fail safely | Attempts fail with `PDF_TOO_LARGE` |
| R127 | Production email deliverability and spoofing | 3 | 4 | 12 High | Configure SPF/DKIM/DMARC, bounce/complaint handling and monitored sending domain before pilot | Mail lands in spam or is rejected |
| R128 | Arabic delivery wording has no native review | 4 | 4 | 16 High | Native reviewer sign-off before pilot; keep wording minimal and avoid legal/condition claims | Native reader reports awkward or incorrect text |
| R129 | Real WhatsApp/iOS/Safari/device behavior untested | 4 | 4 | 16 High | Device and in-app browser matrix; preview checks; accessibility review | Broken links or previews on real devices |
| R130 | Provider status callbacks are fake-only; real mapping unproven | 3 | 4 | 12 High | Implement provider-specific signature/status mapping and sandbox tests; keep `SENT` distinct from `DELIVERED` | Deliveries stay `SENT` or status never updates |
| R131 | Local server restart loses in-flight scheduled work | 3 | 3 | 9 Medium | State is persisted in `delivery_requests`; worker resumes; verify dead-letter and due-time recovery | Queue stalls after restart |
| R132 | Link retention/cleanup is undefined | 2 | 4 | 8 Medium | Add retention policy and cleanup job; monitor active links per report | Link table growth or stale links remain active |
| R133 | No multi-instance worker coordination or shared rate limiting | 3 | 3 | 9 Medium | Review row locking/idempotency before replicas; add shared queue/limiter; load-test | Duplicate sends or inconsistent 429s across replicas |
| R134 | Customer/vehicle data remains fake-only and unencrypted | 4 | 3 | 12 High | No real data; D6/C2/encryption pending; no compliance claim | Real data entered before legal/encryption work |
| R135 | Provider pricing/consent/template approval can block launch | 3 | 4 | 12 High | Complete D8 commercial, template and consent review before implementation commitment | Template rejected or cost exceeds budget |

---

## 3. Unchanged

- D6 production object storage, D7 forms, D8 messaging, D11 final photo/retention policy and C2 legal wording remain Pending.
- No correction UI/API, manager/review queue, customer portal/app or payments.
- No claim of encryption, PDPL/GDPR compliance or native Arabic certification.
- No public face/plate blurring.
- No real provider is represented as tested.

---

## 4. Top Phase 7 risks

1. R120 D8 provider not selected or contracted.
2. R128 Arabic delivery wording not reviewed.
3. R129 real WhatsApp/iOS/device matrix untested.
4. R127 production email deliverability/authentication.
5. R122 multiple active links and irreversible copies.
6. R123 message/preview metadata leakage.
7. R130 real provider webhook/status mapping unproven.
8. R134 real customer data would be unencrypted.

---

## 5. Decisions needed

- Approve D8 provider route, contracts, sandbox credentials and test recipients.
- Approve UAE SMS sender ID and WhatsApp template wording.
- Approve production email domain, SPF/DKIM/DMARC and bounce handling.
- Decide link retention/cleanup and whether admins need a multi-link view.
- Decide when real-provider webhook signature/status mapping will be implemented and tested.
- Decide when native Arabic delivery wording can be signed off.
- Confirm D6, D7, D11, C2 and encryption before any real customer pilot.
