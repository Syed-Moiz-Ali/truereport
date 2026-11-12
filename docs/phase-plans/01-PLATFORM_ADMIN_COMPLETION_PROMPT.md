# Phase 1 Completion Prompt — Platform Admin End-to-End

You are completing the TrueReport Platform Admin phase in:

`E:\syed_moiz_ali\bitlogix\truereport`

**Do not start Workshop Admin, Technician, or Public Report.** Phase 1 is not complete until every Platform Admin feature is connected from UI → API → database and verified by using the UI, not just by passing API tests.

## Read First

1. `docs/IMPLEMENTATION_PLAN.md`
2. `docs/BACKEND_REBUILD_PLAN.md`
3. `docs/FRONTEND_ADAPTIVE_RULES.md`
4. `docs/PLATFORM_PHASE_PLAN.md`
5. `docs/phase-plans/01-PLATFORM_ADMIN.md`
6. `docs/phase-plans/01-PLATFORM_ADMIN_FIX_PROMPT.md`
7. `docs/DYNAMIC_ISSUE_CONFIG.md`
8. `docs/I18N_PLAN.md`
9. `docs/PROFESSIONAL_FLOWS.md`
10. `docs/NAMING_AND_TESTING_RULES.md`
11. `docs/DECISIONS.md` (D-001 to D-065)
12. `docs/MIGRATION.md`
13. `docs/truereport-spec.md`

## Current Problem

The Platform Admin backend and screens exist, but the phase was declared complete without proving the full integration:

- Some screens may still rely on mocks/fixtures.
- Some API endpoints may not be wired to the UI.
- Some create/update/publish/reorder/retire actions may not be exercised from the UI.
- There is no end-to-end evidence that a new category/item/template/scoring rule created in the UI persists and appears in downstream APIs.
- Widget tests with fakes are not a substitute for real UI → API → DB verification.

## Goal

Prove and complete Platform Admin end-to-end:

1. Every Platform Admin screen calls the real backend.
2. Every create/update/reorder/publish/retire/approve/reject action works from the UI.
3. Every change is persisted and visible through the API and downstream configuration.
4. No production mock data remains.
5. End-to-end evidence is captured.

## Agentic Sub-Session Workflow (Required)

Use sub-sessions because inventory, backend gaps, frontend wiring, and verification are independent.

### 1. Discovery / inventory agent (read-only)
- Map every Platform Admin screen to its API endpoint(s), service, and table.
- List missing endpoints, unwired buttons, mock providers, and broken flows.
- Produce `docs/PLATFORM_ADMIN_SCREEN_API_MATRIX.md`.
- Do not edit files.

### 2. Backend gap-fix agent
- Owns `server/src/main/java/...` and backend tests.
- Implements missing endpoints/services/validation.
- Does not edit Flutter files.

### 3. Frontend data/integration agent
- Owns `client/packages/api_client`, Platform Admin models/API/providers.
- Removes mock providers from production paths.
- Does not edit UI screens.

### 4. Frontend UI/flow agent
- Owns `client/apps/platform_admin_app/lib/src/features/**` and screen tests.
- Wires every action to the real API/providers.
- Does not edit backend or API client.

### 5. Integrator / verifier
- Runs the backend locally, runs the Flutter app against it, executes the end-to-end flow.
- Runs all tests and produces the final report.
- Only the integrator claims completion.

Rules:
- One file has one owner at a time.
- Contract-first: agree endpoint/DTO changes before parallel implementation.
- No two agents edit the same file.
- Sub-agents report blockers; they do not edit another owner’s files.

## Non-Negotiable Rules

1. Platform Admin only. No Workshop/Technician/Public work.
2. Every production screen uses the real backend; fakes only under `test/support/`.
3. No hardcoded/sample master data in production paths.
4. No phase numbers in production code, API paths, tables, or ARB keys.
5. No fixed layout widths/heights; adaptive at 360/600/768/1024/1440.
6. EN/AR only; manual translations; no LLM.
7. Server is the source of truth for validation, scoring, snapshots, and permissions.
8. No commits unless explicitly asked.
9. Do not touch the uncommitted `PublicReportService.java` / `print-report.html`.
10. Do not claim completion without UI → API → DB evidence.

## Required Screen → API Coverage

Verify and fix each of these end-to-end.

### 1. Master Library / Categories
UI: list categories, create, edit, reorder, weight total, retire.
API:
- `GET/POST /api/v1/platform/master/categories`
- `PUT /api/v1/platform/master/categories/{id}`
- `POST /api/v1/platform/master/categories/{id}/retire`
- `PUT /api/v1/platform/master/categories/reorder`
- `GET /api/v1/platform/master/categories/weight-check`
Verify:
- Create a 7th category with weight.
- Edit EN/AR names and weight.
- Reorder.
- Weight total updates and blocks invalid totals.
- Retire an unused category; block/confirm if in use.

### 2. Master Library / Items
UI: list, search, filter, create, edit, draft, publish, retire, reorder.
API:
- `GET/POST /api/v1/platform/master/items`
- `GET /api/v1/platform/master/items/{id}`
- `POST /api/v1/platform/master/items/{id}/versions`
- `PUT .../translations/{locale}`
- `PUT .../metadata`
- `POST .../publish`
- `POST /items/{id}/retire`
- `PUT /items/reorder`
Verify:
- Create an item in the 7th category.
- Edit EN/AR label, instruction, unit, tool, standard spec, safety flag, multi-point, max tyre age, free-text.
- Create a draft version; old published version remains immutable.
- Publish; retire.

### 3. Score Bands
UI: per item version PASS/ATTENTION/FAIL min/max/default + criteria EN/AR.
API: `GET/PUT .../versions/{versionId}/bands`.
Verify:
- Bands persist.
- Validation rejects gaps/overlaps/out-of-range.
- Published version cannot be edited.

### 4. Evidence Rules
UI: per status min photos/videos/notes chars/required type.
API: `GET/PUT .../versions/{versionId}/evidence-rules`.
Verify:
- PASS requires ≥1 photo + ≥1 video by default.
- FAIL requires ≥2 photos + ≥1 video.
- OBD item allows DOCUMENT.
- Validation rejects invalid result/evidence types.

### 5. Option Sets
UI: create/edit/reorder/retire sets and values with EN/AR.
API: `/api/v1/platform/master/option-sets` CRUD/values/reorder/retire.
Verify:
- Create an option set and values.
- Retire a value in use is blocked or requires replacement.
- Option values appear in item issue fields.

### 6. Dynamic Issue Fields
UI: per item version add/edit/reorder fields; input type; option set; required; required-for-status; min/max; dependency; multi-value; free-text.
API: `GET/PUT .../versions/{versionId}/issue-fields`.
Verify:
- Cascading dependency persists.
- Allowed option subset persists.
- Required-for-status persists.
- Item publish validation blocks invalid schemas.
- Technician checklist API (read-only check for now) returns the schema correctly.

### 7. Measurement Bands
UI: per item version field/unit/direction/min/max/result/score/labels.
API: `GET/PUT .../versions/{versionId}/measurement-bands`.
Verify:
- Contiguous/non-overlapping validation.
- Direction-aware.
- Measurement maps to result and score in the item config response.

### 8. Global Templates
UI: list, create, rename, draft version, add/remove/reorder items, weight preview, publish/approve/reject/retire.
API:
- `/api/v1/platform/master/templates` and versions/items/weight-preview/publish/approve/reject/retire.
Verify:
- Create a template with the 7th category items.
- Reorder items.
- Weight preview re-normalizes correctly.
- Maker-checker: proposer cannot approve own template.
- Published version immutable.

### 9. Scoring Rules / Grade Boundaries
UI: edit weights mode/cap, grade boundaries A/B/C/D, approve/reject.
API:
- `/api/v1/platform/scoring-rules`
- `/grade-boundaries`
- `/approve` `/reject`
Verify:
- Grade boundaries cover 0–100.
- Gaps/overlaps rejected.
- Maker-checker enforced.
- Effective configuration reflects approval state.

### 10. Document Types
UI: list/create/edit/reorder/retire EN/AR/required.
API: `/api/v1/platform/document-types`.
Verify:
- CRUD and order persist.
- Retired types are not offered for generation.

### 11. Languages / Coverage
UI: list, create, edit, activate/deactivate, reorder, set default, coverage.
API:
- `GET /api/v1/i18n/languages` (anonymous)
- `/api/v1/platform/i18n/languages` CRUD
- `/coverage`
Verify:
- Anonymous language list works.
- Default cannot be deactivated.
- Coverage reports missing translations.

### 12. Config Health / Impact / Releases
UI: health dashboard, impact dialog, release states.
API:
- `/api/v1/platform/config-health`
- `/api/v1/platform/master/{entityType}/{id}/impact`
- `/api/v1/platform/releases`
Verify:
- Health detects missing EN/AR, weight gaps, band gaps, retired references.
- Impact shows templates/jobs affected.
- Release lifecycle transitions persist.

### 13. Seed
UI: seed button with confirmation and result summary.
API: `POST /api/v1/platform/seed/default-checklist`.
Verify:
- First run creates 6 categories/30 items/template/docs/grades.
- Second run creates 0 (idempotent).
- Existing edits are not overwritten.

### 14. Audit / Catalogue / Equipment
UI: audit log, data catalogues, equipment.
API: existing audit/catalogue/equipment endpoints.
Verify:
- Real data, no hardcoded lists.
- Actions performed above appear in audit.

## End-to-End Verification Procedure

1. Run the backend locally with a clean database:
   - Preferred: local MySQL.
   - If MySQL is unavailable: use the H2 test/runtime profile and document it.
2. Seed the default checklist.
3. Run Platform Admin Flutter app against the local backend (not a fake API).
4. Execute the full flow from the UI:
   - seed
   - create 7th category
   - create 2 items in it
   - add EN/AR, unit, tool, spec, safety flag
   - add score bands
   - add evidence rules
   - add issue fields with dependency
   - add measurement bands
   - create option set/value
   - create template with all categories + 7th category
   - weight preview
   - submit for approval, approve with second admin
   - edit scoring rule, submit/approve with second admin
   - add document type
   - add language and coverage check
   - run config health and impact
   - publish template
   - verify the 7th category/items appear in:
     - category list API
     - item list API
     - template detail API
     - weight preview
     - any checklist/template payload available in Phase 1
5. Capture evidence:
   - screenshots of each UI step
   - API response snippets
   - database row checks
   - audit entries

## Tests

### Backend
- Targeted tests:
  ```powershell
  cd server
  mvn "-Dtest=PlatformAdminPhase1IT,ConfigValidatorsTest,ArchitectureTest,SecurityEndpointInventoryIT,FlywayMigrationTest,PlatformContentMigrationTest" test
  ```
- Full suite:
  ```powershell
  mvn test
  ```
  Expected: only the two known pre-existing report failures remain.

Add tests for any gap found during completion.

### Flutter
```powershell
cd client
flutter pub get
cd packages\l10n
flutter gen-l10n
cd ..\..
flutter analyze --fatal-infos
cd apps\platform_admin_app
flutter test
```

Add/fix widget tests for every screen action. Fakes remain in `test/support/` only.

## Acceptance Criteria

1. Every Platform Admin screen in the matrix uses the real backend; no production mocks.
2. All listed CRUD/reorder/publish/retire/approve/reject actions work from the UI and persist.
3. A new 7th category with items/bands/rules/issue fields/measurement bands can be created and published from the UI.
4. The new configuration appears in downstream API responses (category list, item list, template detail, weight preview, checklist/template payload).
5. Maker-checker works with two Platform Admin accounts.
6. Seed is idempotent and does not overwrite edits.
7. EN/AR completeness and API localization work.
8. Adaptive layout works at 360/600/768/1024/1440 + RTL.
9. No phase2/phase3 naming in production code, API paths, tables, or ARB keys.
10. No fake API imports from `lib/`.
11. Targeted backend tests pass; full suite only has known report failures.
12. `flutter analyze --fatal-infos` and Platform Admin tests pass.
13. End-to-end evidence (screenshots/API/DB/audit) is attached to the report.
14. Docs updated (`DECISIONS.md`, `MIGRATION.md`, screen/API matrix).

## Output Format

Report:
- Screen → API matrix with status (wired / gap / fixed).
- Files changed.
- Gaps found and fixed.
- End-to-end evidence summary.
- Commands run and results.
- Decisions recorded.
- Remaining blockers.

Do not claim completion unless every screen action has been exercised from the UI against the real backend.
