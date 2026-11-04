# ADR-0013: Admin TOTP

- **Status:** **Accepted** — D12 approved 3 November 2026
- **Date:** 3 November 2026
- **Owner:** Security/backend lead

## Context

Workshop Admin and Platform Admin accounts are higher-risk than technician accounts. `master.md` requires stronger authentication for admins; D12 was open.

## Options

1. TOTP authenticator app.
2. SMS one-time codes.
3. Email one-time codes.
4. Hardware security keys (WebAuthn).

## Decision

Use **TOTP (RFC 6238)** for Workshop Admin and Platform Admin accounts, implemented in the server auth module. The Phase 2 foundation includes:

- a TOTP secret generated per admin,
- an `otpauth://` enrolment URI,
- a verification endpoint for login challenges,
- replay protection by tracking the last accepted time step,
- audit events for enrolment and failed verification.

SMS/email OTP are not the primary second factor. WebAuthn may be added later, not in V1.

## Consequences

- Admins need an authenticator app.
- Recovery codes/process must be designed before production; Phase 2 may ship a placeholder recovery process that is not enabled in production.
- TOTP secrets must be encrypted at rest and never logged.
- The implementation must be reviewed against RFC 6238 and clock-skew handling.

## Follow-ups

- Add recovery codes and account recovery policy before Phase 8.
- Add rate limiting and lockout for TOTP failures.
- Test clock skew, replay, and disabled accounts.
- Security review of the TOTP implementation.

## What was not proven

No authenticator-app interoperability test was run in Phase 2; the implementation is verified with RFC test vectors and unit tests. Recovery is not production-ready.

---

## Phase 8 implementation note (4 November 2026)

Recovery codes are now implemented: ten random one-time codes, SHA-256 hashes only, generated at TOTP confirmation and via authenticated regeneration. Five failed password/TOTP attempts lock the account for 15 minutes. A documented recovery/lockout process is in `docs/phase-8/ops-runbook.md`. External authenticator interoperability and real-device recovery testing remain **NOT RUN**.
---

## Phase 8.1 owner decision (4 November 2026)

Admin TOTP is now configurable and **off by default** (`ADMIN_TOTP_REQUIRED=false`). Password-only admin login is a conscious owner risk acceptance; the TOTP/recovery code remains available when the flag is enabled. See ADR-0021.