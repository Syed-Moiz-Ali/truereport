# ADR-0008: Consent gate and PDF-download default

- **Status:** **Accepted** — approved by product owner 3 November 2026
- **Date:** 3 November 2026
- **Owner:** Product owner + counsel
- **Decision IDs:** C1–C5, PDF1–PDF5, RQ7

## Context

The platform needs separate consents for processing, public-link creation, each delivery channel and (optionally) PDF download. The exact wording is a legal decision. The public report must not become active without public-link consent.

## Options

1. Single blanket consent (rejected — too broad, poor evidence).
2. Separate, versioned consents per purpose/channel (chosen).
3. Implied consent through the workshop contract (rejected unless counsel advises).

## Decision

- Record **separate, versioned consents**: processing, public link, WhatsApp, SMS, email, PDF download (if enabled).
- **Finalization may succeed without public-link consent**; the link stays `PENDING_CONSENT` and inactive.
- **No active link without recorded public-link consent.**
- **PDF download from the public page is disabled by default.** No download control in V1. PDF delivery is by an approved channel to the recorded customer.
- Consent withdrawal revokes the link; explain that copies already shared cannot be recalled.
- No message without channel-specific consent.

## Consequences

- The technician/admin UI must capture multiple consents, not one checkbox.
- The link activation is a separate audited step if consent is recorded later.
- Some customers will receive a report without a public link if they refuse.
- The support team needs a clear script for consent and revocation.
- Legal wording must be approved before real data.

## Follow-ups

- Counsel approves wording, lawful basis, evidence and retention.
- Product owner confirms PDF download remains off.
- Build consent records with version/hash/time/actor/channel.
- Test: no consent → no active link; consent later → audited activation; withdrawal → revoked.

## What was not proven

No legal review was performed. The exact wording, retention and data-subject process are unresolved.

