# ADR-0007: No correction UI/API until a policy is approved

- **Status:** **Accepted constraint** — `master.md` + Phase 1 instruction
- **Date:** 3 November 2026
- **Owner:** Product owner + counsel
- **Decision ID:** D9 (policy remains Pending)

## Context

`master.md` says finalized findings cannot be edited and that a correction creates a new report version referencing the earlier one, with a visible note and reason. It also says Admins cannot edit findings and the technician self-finalizes. The policy for who may create a correction, what it may correct, and how the link behaves is unresolved.

## Decision

**Do not build any correction UI or API in V1.** No “edit report”, “fix finding”, “reissue” or “new version” action is exposed. Finalized findings, severities, notes and evidence remain immutable.

If a correction policy is approved later, it must:

1. create a **new immutable report version** that references the earlier version,
2. preserve the earlier version unchanged,
3. show a visible correction note and reason,
4. be authorized by an explicitly approved role/process,
5. define the public-link behaviour for the corrected version,
6. be audited.

## Consequences

- A clerical error cannot be corrected through the product until D9 is decided.
- The platform must provide a support process for such cases without weakening immutability (documented, audited, not a silent edit).
- The database keeps `report_versions` ready for a future correction, but no code path creates v2.
- The public report and PDF show v1 only.

## Follow-ups

- Product owner + counsel decide D9.
- If approved, write a new ADR, API endpoints, UI, tests and link policy.
- Do not add a hidden/admin endpoint in the meantime.

## What was not proven

No correction process, support workflow or legal position exists. This ADR deliberately does nothing beyond fencing the feature.

---

## Phase 6 implementation note (4 November 2026)

`reports` and `report_versions` are implemented with v1 only. No correction endpoint, UI or hidden edit path exists. Report-version rows are immutable in the service and by MySQL V11 triggers.
