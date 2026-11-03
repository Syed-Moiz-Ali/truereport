# ADR-0011: Role and account defaults

- **Status:** **Accepted** — approved by product owner 3 November 2026
- **Date:** 3 November 2026
- **Owner:** Product owner
- **Decision IDs:** RQ1–RQ14

## Context

`master.md` fixes three roles and forbids manager/review queues, but leaves several operational boundaries ambiguous: technician job visibility, Workshop Admin intake editing, account creation, Platform Admin PII, resend/revoke authority and audit visibility.

## Options

1. Broad Workshop Admin powers (manage staff, audit, intake, links).
2. **Narrow, server-enforced defaults with explicit escalation** (chosen).
3. Platform Admin central control of everything (rejected — weakens workshop ownership).

## Decision (safe defaults)

- Technician sees **only assigned jobs**; no unassigned queue.
- Workshop Admin may edit **intake fields before finalization**, never checklist answers/findings/evidence.
- **Platform Admin creates all accounts**; Workshop Admin assigns/reassigns work (RQ3 Pending).
- Platform Admin **does not see customer contact details by default**; oversight is read-only and audited.
- Platform Admin **does not resend/revoke by default**; Workshop Admin owns link/delivery.
- Workshop Admin audit visibility is **off by default**.
- Technician belongs to **one primary workshop** in V1.
- Disabled/transferred user: tokens revoked; local data wiped on next sign-in.
- Resend only to the recorded customer/recipient; a different recipient needs new consent.
- No link reactivation in V1.

## Consequences

- Clear, conservative permissions; less support convenience.
- Platform Admin support may need an approved break-glass process later.
- Workshop Admins cannot fully self-serve staff onboarding until RQ3 is decided.
- Cross-workshop isolation remains simple.

## Follow-ups

- Product owner confirms each default.
- Encode in the API permission matrix and automated tests.
- If any default changes, update the matrix, UI and tests together.

## What was not proven

No usability or support workload was measured. The defaults are risk-based, not validated with pilot workshops.

