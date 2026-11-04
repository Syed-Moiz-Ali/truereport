# ADR-0021: Admin TOTP is configurable and off by default

- **Status:** Accepted by owner, Phase 8.1
- **Date:** 4 November 2026
- **Owner:** Product owner + Security
- **Amends:** ADR-0013 (admin TOTP)

## Context

The owner decided that admin TOTP is not required for now. The TOTP implementation and recovery codes exist but must not force a login challenge or enrollment prompt while the flag is off.

## Decision

- Keep TOTP, recovery-code and lockout code in the server.
- Add `truereport.auth.admin-totp.required` (`ADMIN_TOTP_REQUIRED`), default **false**.
- When false:
  - Workshop Admin and Platform Admin sign in with password only.
  - No TOTP challenge is issued even if an account has an old TOTP secret.
  - Enrollment, confirmation and recovery-code endpoints return `409 TOTP_DISABLED`.
  - The admin app has no TOTP challenge UI.
- When true, the existing TOTP/recovery flow is enforced again without code changes.
- Password hashing, lockout, login rate limiting, refresh rotation/reuse detection and audit events remain active.

## Consequences

- A stolen admin password grants that admin's access; a stolen Platform Admin password can access all workshops, subject to existing authorization and audit.
- This is a conscious owner risk acceptance, not a claim that password-only is equivalent to 2FA.
- Compensating controls: Argon2id, lockout, generic errors, rate limits, short-lived JWT, refresh rotation/reuse detection, audit and tenant checks.
- Recommend revisiting 2FA before real customers, at least for Platform Admin.

## Follow-ups

- Re-enable `ADMIN_TOTP_REQUIRED=true` after owner approval.
- Add an explicit UI enrollment flow only when the flag is enabled.
- Consider WebAuthn/passkeys later.
