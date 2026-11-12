# Naming, Test Doubles, and Agentic Workflow Rules

This document explains three common sources of confusion:

1. Why phase-based naming is bad.
2. Why a fake admin API exists when there is a real backend.
3. Why we still build backend APIs and frontend screens.
4. How to use agentic sub-sessions safely.

---

## 1. Do Not Put Phase Numbers in Production Code

Phase numbers are **planning artifacts**, not domain concepts.

### Bad examples

```text
server/.../jobs/WorkshopAdminPhase2Service.java
server/.../jobs/api/WorkshopPhase2Dtos.java
server/.../jobs/api/WorkshopAdminPhase2Controller.java
client/.../features/phase2/job_board_screen.dart
client/.../phase2_models.dart
client/.../phase2_providers.dart
app_en.arb: "phase2JobBoardTitle"
app_en.arb: "phase2ApproveButton"
test/.../WorkshopAdminPhase2IT.java
```

### Good examples

```text
server/.../workshopjobs/WorkshopJobAdminService.java
server/.../workshopjobs/api/WorkshopJobDtos.java
server/.../workshopjobs/api/WorkshopJobAdminController.java
client/.../features/jobs/job_board_screen.dart
client/.../workshop_job_models.dart
client/.../workshop_job_providers.dart
app_en.arb: "jobBoardTitle"
app_en.arb: "approveAndIssueCertificate"
test/.../WorkshopJobAdminIT.java
```

### Why phase naming is harmful

- It becomes permanent technical debt after the phase is over.
- It tells future developers nothing about the domain.
- It makes files/classes harder to find and reuse.
- It encourages duplicate implementations (`Phase2Service`, `Phase3Service`).
- ARB keys are a localization contract; phase keys make translations inconsistent.
- It leaks project timeline into public contracts/tests.
- It makes refactoring/renaming later riskier.

### Allowed temporary qualifiers

If a clean implementation must coexist with a legacy one, use a **domain qualifier**, not a phase number:

- `WorkshopJobAdminService` vs `LegacyWorkshopJobService`
- `WorkshopJobDtos` vs `LegacyJobDtos`
- `workshopjobs` package vs `legacyjobs`

Better: rename and migrate immediately; do not keep two names longer than necessary.

### ARB key rule

Use semantic keys grouped by feature:

```text
jobs.title
jobs.create.title
jobs.status.pendingReview
jobs.approve.cta
jobs.documents.generating
```

Never use:

```text
phase2JobBoardTitle
phase2ApproveButton
```

### API path rule

Paths are resource-oriented, never phase-based:

```text
/api/v1/workshop/jobs
/api/v1/workshop/jobs/{id}/approve
/api/v1/workshop/jobs/{id}/publish
```

Not:

```text
/api/v1/workshop/phase2/jobs
```

---

## 2. Why a Fake Admin API Exists

`test/support/fake_admin_api.dart` is a **test double**, not production code.

It exists so widget/unit tests can:

- run without a backend or database,
- run deterministically in CI,
- simulate loading, empty, error, and permission states,
- verify UI behavior quickly,
- avoid coupling UI tests to real data.

It must:

- live only under `test/support/`,
- never be imported by `lib/`,
- implement the same interface as the real API,
- return realistic fixture data for tests.

It is not a replacement for the backend. Production screens must call the real API client.

### Recommended test layers

| Layer | What it uses |
|---|---|
| Unit tests | Pure logic, no API |
| Widget tests | Fake API / test double |
| Integration tests | Real backend + real DB (H2/MySQL) |
| End-to-end tests | Real backend + deployed app |

Fakes are standard practice. Removing them would make widget tests slow and flaky.

---

## 3. Why We Still Build Backend APIs and Frontend Screens

The frontend cannot create jobs, approve inspections, publish reports, or render real data without backend endpoints.

- **Backend** is the source of truth for validation, scoring, snapshots, permissions, and persistence.
- **Frontend** is the client that calls those endpoints and renders/collects data.
- **If an endpoint is missing**, add it.
- **If a screen is missing**, build it using existing components.
- **If a UI component is missing**, extend the design system rather than duplicating it.
- **Fakes** only support tests; they do not replace real APIs.

So the work is not “fake API vs real API”. The work is:

1. Define/implement the real backend contract.
2. Integrate the real frontend client.
3. Use fakes only to test the UI in isolation.

---

## 4. Agentic Sub-Session Workflow

Use multiple agentic sub-sessions when work is independent and file ownership is clear.

### Recommended split for a phase

1. **Discovery agent** (read-only)
   - Read docs, inspect current code, produce a file/endpoint inventory and risks.

2. **Backend agent**
   - Owns `server/src/main/java/...` and `server/src/test/java/...`.
   - Implements schema, services, controllers, tests.

3. **Frontend data agent**
   - Owns `client/packages/api_client`, models, API clients, providers.
   - Does not edit UI screens.

4. **Frontend UI agent**
   - Owns `client/apps/.../features/**` and `design_system` extensions.
   - Does not edit API clients/models.

5. **Integrator / verifier**
   - Merges, resolves contract mismatches, runs backend + Flutter tests.
   - Owns final acceptance report.

### Rules to avoid conflicts

- One file has one owner at a time.
- Agree the API contract/DTOs before parallel implementation.
- Use `explore` agents for inspection, `general` agents for implementation.
- Do not let two agents edit the same file.
- The integrator runs the final verification; sub-agents do not claim completion.
- If a sub-agent is blocked, it reports the blocker instead of editing another agent’s files.

### Why use sub-sessions

- Parallelizes independent backend/frontend/test work.
- Keeps context smaller per agent.
- Allows focused verification per area.
- Faster delivery on large phases.

### Why not use them blindly

- High risk of merge conflicts if file ownership is unclear.
- Contract drift if backend/frontend agents don’t agree first.
- Duplicate work if discovery is skipped.
- Tests can pass in isolation but fail when integrated.

Always use a contract-first, file-ownership, integrator-gated workflow.

---

## 5. Phase 2 Cleanup Requirement

Before Phase 3, rename Phase 2 production artifacts to domain names:

- `features/phase2/` → `features/jobs/` (or the appropriate feature folder).
- `phase2_models.dart` → `workshop_job_models.dart`.
- `phase2_providers.dart` → `workshop_job_providers.dart`.
- `WorkshopAdminPhase2Service` → `WorkshopJobAdminService`.
- `WorkshopAdminPhase2Controller` → `WorkshopJobAdminController`.
- `WorkshopPhase2Dtos` → `WorkshopJobDtos`.
- `WorkshopAdminPhase2IT` → `WorkshopJobAdminIT`.
- All `phase2...` ARB keys → semantic feature keys.
- Keep `FakeAdminApi` under `test/support/` only.

No production code, public API path, database table, or ARB key should contain `phase2`.
