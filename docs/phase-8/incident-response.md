# Phase 8 Incident Response Plan

**Project:** TrueReport  
**Status:** Draft. Legal notification timing is not decided; get UAE counsel input.

---

## 1. First 30 minutes

1. Declare incident, assign commander and scribe.
2. Preserve evidence: request IDs, server logs (no PII), audit events, Flyway version, container/image digest, provider event IDs.
3. Contain: revoke sessions/tokens, disable accounts, revoke public links, stop delivery workers, block affected IPs, or stop the server if necessary.
4. Do not delete data or overwrite logs.
5. Notify Product/Legal/Security using the contact placeholders in `ops-runbook.md`.

---

## 2. Data exposure

1. Identify records, report versions, public links, delivery attempts and recipients.
2. Revoke all affected links; note that copies/screenshots/PDFs already shared cannot be recalled.
3. Determine whether PII, evidence, report content or only aggregate metadata was exposed.
4. Check logs/audit for the actor, time window and access path.
5. Preserve a hash/evidence bundle without copying PII into chat or tickets.
6. Counsel decides notification obligations; do not invent a legal conclusion or deadline.
7. Rotate affected keys if credentials, tokens or encryption keys may be compromised.
8. Fix the root cause and add a regression test before restoring service.

---

## 3. Wrongly sent link or message

1. Revoke all active links for the report version.
2. Record the delivery ID and provider message ID; do not resend to the wrong recipient.
3. Contact the recipient/workshop through the approved support process; do not send another link until identity and consent are confirmed.
4. Check whether the recipient replied or forwarded; preserve evidence.
5. Review allowlist/consent/recipient selection. Add a test or UI guard if the cause is technical.
6. Document that downloaded copies cannot be recalled.

---

## 4. Compromised account

1. Disable the user; revoke all refresh-token families/sessions.
2. Force password reset and TOTP recovery-code regeneration.
3. Review audit/events for actions during the compromise window.
4. If a Platform Admin is compromised, review account/workshop changes, report access and exports.
5. Rotate secrets if the account had access to them.
6. Re-enable only after identity verification and a new TOTP enrollment.

---

## 5. Provider outage or compromise

1. Stop new sends; leave existing delivery rows intact.
2. Do not switch providers silently; D8 approval is required.
3. Use the manual PDF/copy-link fallback only through an approved support process.
4. Check webhook signatures and provider event IDs; reject unsigned/stale events.
5. Monitor dead-letter growth and error rates.
6. Record outage start/end and affected deliveries.

---

## 6. Storage/database incident

1. Stop writes if integrity is uncertain.
2. Restore into a fresh database/container; verify report hashes before repointing.
3. Check object-storage versioning/lifecycle and restore deleted objects from provider versioning if available.
4. Re-run report hash/integrity checks.
5. Do not claim the restore worked until hashes match.

---

## 7. Post-incident

- Timeline, root cause, affected scope, data categories, decisions and notifications.
- Regression tests and control changes.
- Update consolidated risk register.
- Tabletop exercise before pilot; **NOT RUN**.
