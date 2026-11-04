# ADR-0018: New public link per delivery send

- **Status:** Accepted for Phase 7
- **Date:** 4 November 2026
- **Owner:** Backend/security lead

## Context

Phase 6 created one public share link per report version and enforced that with a unique constraint on `public_share_links.report_version_id`. Only the token hash is stored, so an admin must copy the URL when it is first created; the plaintext URL cannot be read back.

Phase 7 sends the same report to a customer by WhatsApp, SMS or email. A delivery may be retried, and an admin may also create a manual fallback link.

## Options

1. **Reuse the one existing link for every send.**
   - Rejected: the plaintext URL is not stored, so later sends cannot recover it without storing a secret or reissuing the token.
2. **Store encrypted plaintext tokens so any link can be re-read.**
   - Rejected: it adds a long-lived secret-at-rest surface and a new key-rotation problem, and conflicts with the Phase 6 token-hash boundary.
3. **Create a new link per send, keep old links until revoked.**
   - Chosen: no plaintext-at-rest requirement, each send has its own link, and revocation remains explicit.
4. **Create a link only for the first send and fail later sends.**
   - Rejected: it makes retries and multi-channel delivery unreliable and forces a future token-recovery policy.

## Decision

- Generate a new public link for each delivery that needs a link.
- Store only its token hash and link metadata.
- Do not reuse or rewrite an existing token.
- Leave old links active until explicitly revoked.
- Revoke all active links for a report version when the admin revokes the report link.
- Manual admin link creation remains a separate fallback path.
- Remove the report-version unique constraint in a vendor-specific migration:
  - MySQL: `V13__allow_multiple_report_links.sql`.
  - H2: `src/test/resources/db/migration-h2/V13__allow_multiple_report_links.sql`.

The H2/MySQL migrations must drop the foreign key, drop the unique index, add the replacement composite index, and recreate the foreign key. Dropping only the constraint is insufficient because the foreign key can keep the unique index alive.

## Consequences

- A report version can have multiple active links.
- Revocation must affect every active link, not just a single row.
- Link count grows with sends; retention/cleanup is a future operational decision.
- A customer may receive more than one valid link if a report is sent more than once.
- Already-delivered copies/screenshots/PDFs cannot be recalled; this is unchanged from Phase 6.
- The database schema no longer guarantees one link per report version; the service and tests must enforce the intended behaviour.

## Follow-ups

- Add link retention/cleanup policy before production scale.
- Monitor active link count per report.
- Add an admin view if operators need to see all active links.
- Re-test MySQL and H2 migrations on every schema change.
- Keep revocation tests covering all active links.

## What was not proven

- No real WhatsApp/SMS provider was tested.
- Link cleanup/retention is not implemented.
- Concurrent sends are covered by idempotency at the delivery level, but high-volume link growth was not load-tested.
