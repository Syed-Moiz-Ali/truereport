# Phase 7 Decisions

**Project:** TrueReport  
**Date:** 4 November 2026  
**Status:** Accepted for Phase 7 implementation

---

## 1. Provider scope

| Item | Decision | Evidence / limitation |
|---|---|---|
| D8 provider selection | **Still Pending** | No provider contract or production credentials exist |
| WhatsApp / SMS implementation | Provider-neutral `DeliveryProvider` adapter; fake adapter for development and tests | `DeliveryProvider`, `DeliveryProviderRegistry`, `FakeDeliveryProvider` |
| Email implementation | SMTP adapter configurable by environment | `SmtpEmailProvider` |
| Local email target | Mailpit | Compose service `mailpit`, SMTP `1025`, UI/API `8025` |
| Real recipient delivery | Disabled by default; allowlist only unless explicitly enabled | `truereport.delivery.real-recipients-enabled` and recipient allowlists |
| Real WhatsApp/SMS testing | **Not run** | No sandbox credentials; no provider is claimed as tested |

No production WhatsApp or SMS adapter is shipped in Phase 7. The fake adapter exists so consent, status, retry and webhook behaviour can be tested without inventing provider success.

---

## 2. Channel consent and recipient rules

| Item | Decision |
|---|---|
| WhatsApp send | Requires latest `WHATSAPP` consent `GRANTED` and latest `PUBLIC_LINK` consent `GRANTED` |
| SMS send | Requires latest `SMS` consent `GRANTED` and latest `PUBLIC_LINK` consent `GRANTED` |
| Email with PDF | Requires latest `EMAIL` consent `GRANTED` |
| Email link fallback | Also requires latest `PUBLIC_LINK` consent `GRANTED` |
| Missing recipient | Rejected with `RECIPIENT_MISSING` |
| Recipient not on allowlist | Rejected with `RECIPIENT_NOT_ALLOWED` |
| Stored recipient | Masked value plus SHA-256 recipient hash; no plaintext recipient in delivery rows |
| Rate limit | Per workshop, recipient hash and rolling hour; default 10/hour, test profile 5/hour |

Email does not require public-link consent when the PDF is attached. A link fallback in an email does require public-link consent.

---

## 3. Public link handling per delivery

- Each successful send that needs a link creates a **new public link** for the report version.
- Existing links remain until explicitly revoked; a delivery does not silently reuse or rotate another link.
- Only the token hash is stored. The plaintext URL exists in the outbound message and is never written to the delivery row.
- This required removing the old one-link-per-report-version unique constraint. See ADR-0018 and migration `V13`.
- Manual admin link creation remains available as a fallback, but its URL is also shown only once.
- `ReportService.revoke` revokes all active links for the report version so the admin action cannot leave another delivery link active.

The alternative of storing encrypted plaintext tokens was rejected because it expands the secret-at-rest boundary and does not match the existing token-hash design.

---

## 4. Message content and privacy

Allowed message content:

- Neutral statement that the vehicle inspection report is ready.
- Report ID.
- Public link and/or attached PDF.
- Language label or neutral attachment wording.

Forbidden message content:

- Customer name, phone or email.
- Full VIN, plate or precise vehicle identity.
- Findings, severity, notes or condition claims.
- Internal IDs, technician identity or workshop secrets.

The email attachment filename is `inspection-report.pdf`. The message body contains no customer or vehicle fields. The public report itself remains governed by the Phase 6 allowlist and redaction rules.

---

## 5. Email attachment rule

| Condition | Behaviour |
|---|---|
| PDF is available and within `email-max-attachment-bytes` | Attach PDF |
| PDF exceeds the limit and `PUBLIC_LINK` consent is granted | Send neutral link fallback in email |
| PDF exceeds the limit without `PUBLIC_LINK` consent | Fail the attempt; no link is created |
| PDF artifact is missing | Attempt fails; retry/dead-letter rules apply |

Default attachment limit: **10 MiB**. The value is configurable and is not a provider guarantee.

---

## 6. Idempotency

- `POST /api/v1/workshop/jobs/{jobId}/deliveries` requires `Idempotency-Key`.
- Send idempotency is scoped to workshop and hashes the key; reusing the same key with the same job/channel/language returns the original delivery.
- Reusing the same key with a different request returns `409 IDEMPOTENCY_KEY_REUSED`.
- `POST /api/v1/workshop/jobs/{jobId}/deliveries/{deliveryId}/retry` also requires `Idempotency-Key`.
- The retry key hash is stored on the delivery row; repeating the same retry key returns the current delivery without resetting it again.
- Manual retry extends the attempt budget instead of resetting the attempt counter, keeping attempt history monotonic.

---

## 7. Retry, backoff and dead-letter

| Item | Decision |
|---|---|
| Default max attempts | 3 |
| Retry delay | Exponential from `retry-base-seconds` (default 30s), capped at 1 hour |
| Worker | DB-polled scheduled worker, default every 2 seconds |
| Manual retry | Allowed for `FAILED`, `RETRY_PENDING` and `DEAD_LETTER` |
| Dead-letter | Set when the attempt budget is exhausted |
| Error storage | Redacted/truncated error code and message; no stack traces sent to clients |
| Provider timeouts | Provider adapter returns failure; the worker records the attempt and schedules a retry |

The worker is single-instance in local development. Production horizontal scaling requires a shared queue/lock or database row-locking review.

---

## 8. Roles and UI

| Surface | Phase 7 behaviour |
|---|---|
| Workshop Admin | Send WhatsApp/SMS/email, view masked recipient and history, retry failed/dead-letter, create manual public link, download PDF |
| Technician | Read-only delivery history/status for the finalized job |
| Platform Admin | Read-only delivery oversight endpoint; no send action |
| Public | No delivery UI; token report only |

The admin UI does not collect or display full customer contact details. It displays only masked recipients and status/error metadata.

---

## 9. State model

Delivery statuses:

`QUEUED`, `SENT`, `DELIVERED`, `RETRY_PENDING`, `FAILED`, `DEAD_LETTER`.

Attempt statuses:

`SENT`, `DELIVERED`, `FAILED`, `RETRY_PENDING`, `DEAD_LETTER`.

`SENT` means the provider accepted the message. `DELIVERED` is only set by a verified provider webhook. A provider acceptance is not treated as proof of human delivery.

---

## 10. Deliberate exclusions

- No real WhatsApp or SMS provider contract.
- No correction UI/API, manager/review queue, customer portal/app or payments.
- No production email reputation setup (SPF/DKIM/DMARC) in this phase.
- No native Arabic sign-off for the delivery wording.
- No claim of PDPL/GDPR compliance or encryption of customer/vehicle data.
- No production object storage decision (D6 remains Pending).
