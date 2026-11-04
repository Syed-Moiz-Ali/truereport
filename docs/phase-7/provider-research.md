# Phase 7 Provider Research

**Project:** TrueReport  
**Date:** 4 November 2026  
**Status:** Research only. D8 is still Pending.

---

## 1. Scope

Phase 7 needs three delivery channels:

- WhatsApp report link.
- SMS report link/fallback.
- Email with PDF or link fallback.

The application must keep provider adapters abstract until D8 is approved. No provider was contracted, no sandbox credentials were supplied, and no real WhatsApp/SMS message was sent in this phase.

---

## 2. Candidate comparison

| Candidate | Channels | Access model | Strengths | Constraints / open questions | Phase 7 status |
|---|---|---|---|---|---|
| Meta WhatsApp Cloud API | WhatsApp | Meta app/business account, Graph API | First-party WhatsApp API; direct control of templates and webhooks | Business verification, template approval, message category/pricing rules, UAE-recipient support, webhook hosting and secret rotation | **Not contracted, not tested** |
| Twilio | WhatsApp + SMS | Paid account, REST APIs | One vendor for WhatsApp and SMS; mature SDKs/webhooks; sandbox options | UAE sender ID/SMS regulatory approval, WhatsApp template approval, per-message cost, DPA/regional terms | **Not contracted, not tested** |
| Unifonic | SMS (and broader messaging) | Commercial account, REST API | Regional presence and Arabic support; UAE SMS experience | Contract/pricing, sender ID registration, API/webhook limits, exact WhatsApp capability to confirm | **Not contracted, not tested** |
| Approved WhatsApp BSP | WhatsApp | BSP contract | May simplify onboarding/support in UAE | BSP markup, lock-in, data-processing terms, template control | **Not evaluated** |
| SMTP / transactional email provider | Email | SMTP or API | Simple integration; PDF attachment works with standard SMTP | SPF/DKIM/DMARC, bounce/complaint handling, attachment size, regional data terms | **SMTP adapter implemented; Mailpit tested only** |

The Phase 7 implementation therefore uses a provider-neutral interface and a fake adapter. This is deliberate: a fake success result is safer than fabricating a real provider integration.

---

## 3. Recommended evaluation order (not a selection)

1. **Email first:** keep the generic SMTP adapter; evaluate a UAE-capable transactional email provider with attachment support, bounce handling and SPF/DKIM/DMARC guidance.
2. **WhatsApp:** compare Meta Cloud API directly with one approved BSP. Require template approval, webhook signature verification, delivery-status callbacks and documented data residency.
3. **SMS:** require a UAE sender-ID process and clear per-message pricing. Test delivery to Etisalat and du numbers before pilot.
4. **Fallback:** keep manual copy-link and admin PDF download available regardless of provider choice.

Do not select a provider on price alone. Template approval and sender-ID registration can block a pilot even when the API works.

---

## 4. Adapter contract

The implemented boundary is `DeliveryProvider`:

- `send(DeliveryMessage)` returns accepted/rejected, a provider message ID, an error code/message, and a delivered flag.
- `DeliveryMessage` carries channel, recipient, language, subject/body, report number and optional PDF bytes.
- The service, not the adapter, owns consent, allowlist, idempotency, retry, dead-letter, audit and persistence.
- A real adapter must not log recipient plaintext, message bodies containing private data, or provider credentials.
- A real adapter must map provider status callbacks into the existing webhook service; it must not write delivery rows directly.

Provider-specific work still required:

| Item | Status |
|---|---|
| Meta Graph API client | Not implemented |
| Twilio REST client | Not implemented |
| Unifonic REST client | Not implemented |
| WhatsApp template registration | Not started |
| SMS sender ID registration | Not started |
| Provider webhook signature verification | Fake HMAC only |
| Bounce/complaint ingestion | Not implemented |
| Production email authentication | Not configured |

---

## 5. Webhook and operations requirements

Any selected provider must support or the integration must add:

- Signed webhooks and replay protection.
- Idempotent event IDs.
- Status mapping for accepted, sent, delivered, failed and expired states.
- Retry/backoff guidance and rate limits.
- Sandbox/test recipients and deterministic failure injection.
- Log retention and audit access without storing message bodies containing private data.
- Regional data-processing terms, retention and deletion rules.
- Operational alerts for dead-letter growth, provider auth failure and webhook verification failure.

The fake webhook endpoint uses HMAC-SHA256 with a configured secret and stores event IDs to reject replay. That proves the local contract, not a provider's production signature scheme.

---

## 6. Test status

| Path | Status |
|---|---|
| Fake WhatsApp/SMS provider | Tested in `DeliveryIT` |
| Fake webhook + replay rejection | Tested in `DeliveryIT` |
| SMTP email via Mailpit | Tested end-to-end with PDF attachment |
| Real Meta WhatsApp | **NOT RUN** |
| Real Twilio/Unifonic SMS | **NOT RUN** |
| Production email provider | **NOT RUN** |
| WhatsApp in-app/iOS/Android preview | **NOT RUN** |
| Arabic native wording review | **NOT RUN** |

---

## 7. Sources checked

Accessed 4 November 2026:

- Meta WhatsApp Cloud API documentation: `https://developers.facebook.com/docs/whatsapp/cloud-api`
- Meta WhatsApp Business Platform overview: `https://business.whatsapp.com/products/platform-pricing`
- Twilio WhatsApp documentation: `https://www.twilio.com/docs/whatsapp`
- Twilio Messaging documentation: `https://www.twilio.com/docs/messaging`
- Unifonic documentation: `https://docs.unifonic.com/`
- Mailpit documentation: `https://mailpit.axllent.org/`

Pricing, template categories, sender-ID rules and UAE regulatory requirements change. Re-check them at D8 approval; this document does not record prices as commitments.

---

## 8. Decision needed

D8 remains **Pending**:

- Choose WhatsApp route: Meta Cloud API directly or an approved BSP.
- Choose SMS provider and complete UAE sender-ID registration.
- Choose production email provider and authentication setup.
- Approve data-processing, retention and cost terms.
- Provide sandbox credentials and allowlisted test recipients before real-provider testing.

Until then, Phase 7 remains a locally tested delivery subsystem with fake WhatsApp/SMS and SMTP email to Mailpit.
