# Gate 1 — data truth self-grade

Date: 2026-11-19 · Screen: `/signin` · Mode: investigate-only (no source edited)

## Verdict: **PASS (self-graded, with artifacts)**

- **Zero unexplained SUSPECT.** All 11 SUSPECT rows in
  `docs/data/inventory.md` are root-caused with file:line evidence in
  `docs/data/signin_client_trace.md` / `docs/data/auth_server_contract.md`.
- **Zero designed metrics depend on MISSING data.** This screen has no numbers,
  counts, dates, money or charts. The five MISSING items are affordances and a
  brand mark:
  - dead "Password help" → **removed** in the rebuild;
  - link-styled "Get help" with no action → rendered as **static text**;
  - no brand asset → **typographic lockup** (no invented logo);
  - server `detail`/`errors[]`/`traceId` not surfaced → **not invented**, recorded;
  - token lifetime not parsed → recorded, out of this screen's scope.
- **No mock fills a gap.** Nothing on this screen will pretend to be real data.

## Evidence index

| Artifact | Content |
|---|---|
| `docs/data/inventory.md` | 16 VERIFIED · 1 ASSUMED · 11 SUSPECT · 5 MISSING (33 rows) |
| `docs/data/signin_client_trace.md` | 37-row client trace, 8 sections, every hop cited |
| `docs/data/auth_server_contract.md` | 5 endpoints, schemas, enums, errors, session semantics |
| `docs/data/samples/` | 9 sanitized samples, each with `_source` |
| `docs/api/contracts.md` | canonical contract + code→copy mapping + role/tenant contract |
| `docs/data_gaps.md` | G1-G14, each with interim behaviour |

## Items that become design constraints

1. **No pre-auth tenant identity.** The workshop name arrives only inside
   `memberships[]` *after* login. A login screen cannot name the workshop
   without inventing it. No fake "Bay 04 / Al Manara Workshop" panel.
2. **Fixed copy set.** Gate 0 forbids shared ARB edits, so the only copy
   available is: `appTitle`, `technicianSignInTagline`, `signInSubtitle`,
   `emailLabel`, `passwordLabel`, `twoFactorLabel`, `signInButton`,
   `verifyButton`, `technicianNeedTechnicianAccess`, `technicianContactAdmin`,
   `technicianSecurityLine`, `languageEnglish`, `languageArabic`, the four
   error/validation strings. No invented labels, steps or process words.
3. **2FA is not the hero.** Challenges require `ADMIN_TOTP_REQUIRED=true`
   (default false) **and** a TOTP-enabled user; technicians cannot enrol.
   Preserve the state; never make it the signature.
4. **Recovery codes must be enterable.** Server accepts 6-digit TOTP or
   `XXXXX-XXXXX`; the current UI accepts exactly 6 digits. Fix in the rebuild
   and pin with a test (G4).
5. **Role/tenant derivation disagrees with the token.** Do not "fix" it in a UI
   wave; preserve the guard and keep G5/G6 on record.
6. **Error taxonomy needs new copy that this wave cannot add.** Keep the
   existing three-family copy; do not design fake error states.

## Self-grade checks (skill §2-§9)

| Check | Result |
|---|---|
| Inventory built first | PASS — `docs/data/inventory.md` |
| End-to-end trace per element | PASS — client + server traces |
| Real samples captured | PASS — 9 sanitized samples, source-cited |
| Cross-check contradictions | PASS — role vs token, 2FA length, timeout dead branches, error collapse |
| Contracts defined | PASS — `docs/api/contracts.md` |
| Data gaps registered | PASS — G1-G14 |
| Changes made | none (read-only) |

## What is still unverified (honest)

- **2FA wire shape:** whether null fields are omitted or serialized (Jackson 2 vs 3
  ambiguity). Does not affect the client: it branches on `requiresTwoFactor` and
  reads `challengeToken` only on that path.
- **Production values** of `ADMIN_TOTP_REQUIRED` and `API_BASE_URL`.
- **Server-side tenant authorization** for `/technician/*` (out of this screen).
- **Live API timing/lockout** (no server run, no database).
