# Phase 3 Prompt — Technician + Naming Cleanup

You are continuing the TrueReport rebuild in:

`E:\syed_moiz_ali\bitlogix\truereport`

Phase 2 (Workshop Admin + path URLs) is delivered. Phase 3 is Technician.

## Read First

1. `docs/IMPLEMENTATION_PLAN.md`
2. `docs/BACKEND_REBUILD_PLAN.md`
3. `docs/FRONTEND_ADAPTIVE_RULES.md`
4. `docs/phase-plans/03-TECHNICIAN.md`
5. `docs/DYNAMIC_ISSUE_CONFIG.md`
6. `docs/I18N_PLAN.md`
7. `docs/PROFESSIONAL_FLOWS.md`
8. `docs/NAMING_AND_TESTING_RULES.md`
9. `docs/DECISIONS.md` (D-001 to D-062)
10. `docs/MIGRATION.md`

## Prerequisite Cleanup — Remove Phase 2 Naming

Phase numbers must not appear in production code, API paths, DB tables, or ARB keys.

Before or during Phase 3:

- `client/apps/workshop_admin_app/lib/src/features/phase2/` → `features/jobs/` (or correct feature folders).
- `phase2_models.dart` → `workshop_job_models.dart`.
- `phase2_providers.dart` → `workshop_job_providers.dart`.
- `WorkshopAdminPhase2Service` → `WorkshopJobAdminService`.
- `WorkshopAdminPhase2Controller` → `WorkshopJobAdminController`.
- `WorkshopPhase2Dtos` → `WorkshopJobDtos`.
- `WorkshopAdminPhase2IT` → `WorkshopJobAdminIT`.
- All `phase2...` ARB keys → semantic keys like `jobBoardTitle`, `approveAndIssueCertificate`.
- Keep `FakeAdminApi` under `test/support/` only.
- Update imports, routes, tests, and generated l10n.
- Verify no `phase2` remains in production paths or ARB keys.

Reason: phase labels are temporary planning artifacts and become permanent debt. See `docs/NAMING_AND_TESTING_RULES.md`.

## Agentic Sub-Session Workflow (Required)

Use multiple sub-sessions because the phase is large and has independent workstreams.

### 1. Discovery agent (read-only)
- Inspect current Technician app/backend and produce a file/endpoint inventory.
- Identify reusable components, duplicate models, and missing pieces.
- Do not edit files.

### 2. Backend agent
- Owns `server/src/main/java/com/truereport/...` and backend tests.
- Implements technician APIs, validation, evidence, scoring integration, signatures, offline sync.
- Does not edit Flutter files.

### 3. Frontend data agent
- Owns `client/packages/api_client`, Technician models, API clients, providers.
- Does not edit UI screens.

### 4. Frontend UI agent
- Owns `client/apps/technician_app/lib/src/features/**`.
- Reuses existing components/design system.
- Does not edit API/models/providers.

### 5. Integrator/verifier
- Merges, resolves contract mismatches, runs `mvn test`, `flutter analyze`, `flutter test`.
- Produces the final report.

Rules:
- One file has one owner at a time.
- Agree API contracts/DTOs before parallel implementation.
- No two agents edit the same file.
- Sub-agents report blockers instead of editing another owner’s files.
- Only the integrator claims completion after verification.

Why: parallel speed and smaller context, with contract-first integration to avoid merge conflicts and drift.

## Non-Negotiable Rules

1. Backend full rebuild: Technician flows use clean `platform_*` tables; do not build new behavior on legacy job/assessment/evidence tables.
2. Frontend UI is reused; no redesign. Adapt data wiring, state, responsive layout.
3. No fixed layout widths/heights; adaptive at 360/600/768/1024/1440.
4. Server is the source of truth for validation, status, score, evidence rules, and completion.
5. No hardcoded categories/items/bands/options/evidence rules/measurements.
6. EN/AR only; manual translations; no LLM.
7. No technician qualification, tool calibration, or QC sampling.
8. No post-publish correction flow.
9. No commits unless explicitly asked.
10. Do not touch the uncommitted `PublicReportService.java` / `print-report.html`.
11. Fakes stay in `test/support/` only; production uses real APIs.
12. Ask only when blocked; record decisions in `docs/DECISIONS.md`.

## Part A — Backend

### Clean schema (V106+)

Tables:
- `platform_technician_jobs` or extend `platform_jobs` with technician fields if appropriate.
- `platform_assessments`
- `platform_assessment_issue_values`
- `platform_assessment_measurements`
- `platform_evidence_assets`
- `platform_evidence_derivatives`
- `platform_job_signatures`
- `platform_sync_conflicts` (if needed)
- Reuse `platform_job_status_history`, `platform_notifications`, `platform_outbox_events`.

Fields must support:
- result code, score, measurement, unit
- dynamic issue values (field code, option code, numeric, unit, value index, optional text)
- multi-point values
- note EN/AR only when item allows free text
- evidence type PHOTO/VIDEO/DOCUMENT
- captions EN/AR, duration, poster/thumbnail, size, hash
- signature (name, timestamp, device, hash)
- optimistic version/client revision

### APIs

Base: `/api/v1/technician`

- `GET /jobs`
- `GET /jobs/{id}`
- `GET /jobs/{id}/checklist`
- `PUT /jobs/{id}/items/{itemCode}` (idempotent upsert)
- `GET /jobs/{id}/summary`
- `GET /jobs/{id}/review`
- `POST /jobs/{id}/signature`
- `POST /jobs/{id}/complete`
- Evidence:
  - `POST /jobs/{id}/items/{itemCode}/evidence/init`
  - `PUT /jobs/{id}/items/{itemCode}/evidence/{evidenceId}/content`
  - `POST /jobs/{id}/items/{itemCode}/evidence/{evidenceId}/complete`
  - `GET /jobs/{id}/items/{itemCode}/evidence`
  - `DELETE /jobs/{id}/items/{itemCode}/evidence/{evidenceId}`
- Sync:
  - `POST /jobs/{id}/sync` (batch replay or documented per-mutation replay)

All technician endpoints scoped by `technician_id` and `workshop_id`.

### Business rules

- Result required.
- Numeric items require measurement.
- Status/score derived from Platform-Admin measurement bands.
- Score override only inside band.
- Dynamic issue fields validated: allowed values, dependencies, required-for-status, min/max.
- Multi-point items derive worst-corner status/score.
- Evidence rules:
  - every item requires >=1 photo + >=1 video for every result
  - FAIL >=2 photos + >=1 video
  - notes >=15 chars where required
  - OBD DOCUMENT evidence
  - camera-only metadata, duplicate hash detection, time window
- Free-text notes only when item allows.
- Complete requires all items, evidence, signature, and no unsynced conflicts.
- Offline conflict: server wins, return diff, block completion until revalidated.
- Structured EN/AR errors; return all blockers on complete.

### Tests

- Dynamic checklist delivery.
- Assessment/issue/measurement validation and band mapping.
- Score override inside/outside band.
- Multi-point worst-case.
- Evidence rules and photo/video/document upload.
- Duplicate/reuse detection.
- Signature and complete blockers.
- Offline conflict/idempotency.
- Technician/workshop isolation.
- Localized errors.

## Part B — Technician Flutter

Reuse existing Technician app. Do not redesign.

### Data layer
- Extend `ApiEndpoints`/API client.
- Add models: checklist, category, item, bands, issue fields/values, measurement, evidence, review, signature, sync conflict.
- Replace hardcoded result/severity/category/icon logic with API data.
- Offline store mapping for issue values and media.
- Error mapping to inline fields.

### UI
- Job list with sync status.
- Job detail with category tabs from API.
- Item card: instructions, standard spec, unit, tool, evidence checklist.
- Dynamic issue form: cascading dropdowns, measurement + unit, severity/action/urgency.
- Band-suggested status/score with in-band override.
- Evidence capture: photo/video/document; camera-only; poster; upload progress/retry.
- Multi-point grid FL/FR/RL/RR.
- Summary with draft score and blockers.
- Signature pad.
- Complete action.
- Offline queue/status/conflict UI.

### Adaptive/localization
- No fixed layout dimensions.
- Test 360/600/768/1024/1440.
- EN/AR/RTL and long labels.
- All new strings in ARB with semantic keys (no `phase3`).

## Verification

Backend:

```powershell
cd server
mvn "-Dtest=TechnicianPhase3IT,TechnicianInspectionIT,ArchitectureTest,SecurityEndpointInventoryIT,FlywayMigrationTest" test
mvn test
```

Expected: only the two known pre-existing report failures.

Frontend:

```powershell
cd client
flutter pub get
cd packages\l10n
flutter gen-l10n
cd ..\..
flutter analyze --fatal-infos
cd apps\technician_app
flutter test
cd ..\platform_admin_app
flutter test
cd ..\workshop_admin_app
flutter test
```

Name checks:
- No `phase2` in production code/ARB keys.
- No `phase3` in production code/ARB keys.
- No fake API imports from `lib/`.

## Acceptance Criteria

1. Phase 2 naming debt is removed from production code/ARB keys.
2. Technician sees only their jobs and pinned checklist.
3. Dynamic category tabs and issue fields come from the API.
4. Measurement drives status/score; override only inside band.
5. Evidence rules cannot be bypassed; server enforces them.
6. Photo/video/document evidence works with captions/duration/poster.
7. Multi-point worst-case works.
8. Offline sync/conflicts are safe; completion blocked until clean.
9. Signature and complete move job to pending review.
10. UI reused and adaptive; no fixed layout sizes.
11. EN/AR/RTL tests pass.
12. Targeted backend tests pass; full suite only has known report failures.
13. `flutter analyze --fatal-infos` and app tests pass.
14. Docs updated (`DECISIONS.md`, `MIGRATION.md`).

## Output Format

Report:
- Files created/changed.
- Naming cleanup performed.
- Schema/API changes.
- Agentic sub-session split and integration notes.
- Commands run/results.
- Decisions recorded.
- Remaining blockers.

Do not claim completion unless acceptance criteria are verified.
