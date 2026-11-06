# ADR-C0-001 — Admin-created accounts, no invitations (supersedes RQ3 + ADR-0011)

- **Status:** accepted (C0)
- **Date:** 6 November 2026
- **Supersedes:** Phase-1 RQ3 invitation model, ADR-0011 role/account defaults (invitation/token/acceptance/pending-status), and Phase-3 hierarchy invitation flows.
- **Deciders:** product owner (A1–A8); integration lead.

## Decision
1. Strict chain: Platform Admin creates Workshop Admins (+ workshop assignment); Workshop Admin creates Technicians in own workshop only. No self-signup, no Technician invite/create.
2. No invitations anywhere: no invite endpoints, tokens, acceptance, pending status/filter. Account is ACTIVE on creation.
3. Initial password set by creating admin (policy: 12–128 chars, upper+lower+digit+special), Argon2 hashed, never returned/logged/audited; Idempotency-Key required; neutral EMAIL_EXISTS; rate limits/lockout unchanged.
4. "Forgot password" replaced by admin reset (audited ACCOUNT_PASSWORD_RESET, sessions revoked). Login help slot shows localized "contact your admin" text.
5. No forced password change at first login in v1 (owner-accepted risk A6; designed screen deferred).
6. Admin TOTP stays off by config (A7).
7. Invitation tables/rows retained (no drop in C0); separate reviewed migration proposed.

## Consequences
- New: POST /platform/users (WORKSHOP_ADMIN only), POST /workshop/technicians, POST /platform/users/{id}/password-reset, POST /workshop/technicians/{id}/password-reset.
- Removed: POST /platform/invitations, POST /auth/invitations/accept (404 authed, 401 anon after permitAll cleanup), pendingInvitations/invitationExpiresAt, PENDING filter (400 INVALID_FILTER).
- Lead fixes in C0: transfer LAST_WORKSHOP_ADMIN guard, idempotency canonical excludes password (no plaintext-derived hash stored), SecurityConfig permitAll cleanup.
- Security review: F1 transfer guard fixed; F2 add @PreAuthorize defense-in-depth (open); F3 idempotency hash fixed; F4 stale permitAll fixed; F5 client updated.
- Risk register: A6 recorded; F2/F5 follow-ups open.
