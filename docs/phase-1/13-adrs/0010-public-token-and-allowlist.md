# ADR-0010: Public token and allowlist boundary

- **Status:** Proposed
- **Date:** 3 November 2026
- **Owner:** Backend/security lead

## Context

Anyone with the link can read the report. The token must be unguessable and must not expose internal IDs. The public page must never leak customer or vehicle private fields.

## Options

1. Sequential report ID in the URL (rejected — enumerable).
2. Random UUIDv4 token (acceptable, 122 bits; less than target).
3. **256-bit random token, stored as SHA-256 hash** (chosen).
4. Signed URL with expiry (rejected as the only control — links must remain shareable until revoked).

## Decision

- Generate at least 32 random bytes (256 bits), base64url-encode.
- Store only the SHA-256 hash; lookup by hash; never log the plaintext token.
- Generate at activation, not at finalization, to avoid dormant secrets.
- Public page renders from an explicit allowlist DTO, not a live entity.
- Invalid, revoked, consent-missing and rate-limited states use the same neutral page.
- `noindex`, neutral metadata, `Referrer-Policy: no-referrer`, `Cache-Control: no-store` for HTML.
- No PDF download by default.

## Consequences

- Token leakage is limited by revocation and rate limits, but a shared link can be forwarded.
- Token rotation would require a new link; not in V1.
- Public template and PDF must share the same allowlist DTO.
- Caching must not bypass revocation.

## Follow-ups

- Test token hashing, lookup, rate limits and neutral errors.
- Test no private field in HTML/JSON/metadata.
- Test revoke ? no content, including behind the chosen proxy/CDN.
- Confirm token lifetime/expiry policy (currently no expiry; revoke only).

## What was not proven

No public route or token implementation exists. Real messaging-app preview behavior is untested.
