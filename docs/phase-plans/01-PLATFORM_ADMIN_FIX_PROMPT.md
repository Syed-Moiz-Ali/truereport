# Phase 1 Remediation Prompt — True Clean Baseline + Adaptive Audit

You are continuing the TrueReport rebuild in:

`E:\syed_moiz_ali\bitlogix\truereport`

## Context

Phase 1 (Platform Admin) was delivered functionally, but it is **not accepted** because it does not meet the approved architecture and frontend rules.

Verified:
- Targeted backend tests passed (19 tests).
- `flutter analyze --fatal-infos` passed.
- Platform Admin Flutter tests passed (49).
- Seed has 6 categories / 30 items.

But:
1. The backend is a **hybrid**, not a true clean baseline.
2. The common language API is not usable by anonymous/public surfaces.
3. The frontend adaptive/visual-regression pass was not done.

## Read First

Read these before changing code:

1. `docs/IMPLEMENTATION_PLAN.md`
2. `docs/BACKEND_REBUILD_PLAN.md`
3. `docs/FRONTEND_ADAPTIVE_RULES.md`
4. `docs/PLATFORM_PHASE_PLAN.md`
5. `docs/phase-plans/01-PLATFORM_ADMIN.md`
6. `docs/DYNAMIC_ISSUE_CONFIG.md`
7. `docs/I18N_PLAN.md`
8. `docs/PROFESSIONAL_FLOWS.md`
9. `docs/DECISIONS.md` (especially D-047, D-048, D-049, D-050)
10. `docs/MIGRATION.md`

## Problems to Fix

### Problem 1 — Backend is not a true clean baseline

Current `V100__platform_admin_clean_baseline.sql` creates `platform_*` side tables, but categories/items/versions still live in legacy tables:

- `master_categories`
- `master_inspection_items`
- `master_item_versions`

The following still read/write legacy master tables or side tables:

- `MasterContentService.java`
- `PlatformCategoryService.java`
- `PlatformItemService.java`
- `DefaultChecklistSeeder.java`
- `GovernanceService.java`
- `TemplateRepository.java` (reads `platform_category_config`, `platform_item_metadata`)

Also:
- Mixed ID types: `VARCHAR(36)` in `platform_*`, `BINARY(16)` in legacy.
- No foreign keys on new tables.
- Duplicate audit systems: legacy `audit_events` + `platform_audit_events`.
- Side tables `platform_category_config` and `platform_item_metadata` duplicate data that should live on clean parent tables.

**Goal:** Platform Admin configuration must be fully self-contained in clean `platform_*` tables. New code must not depend on legacy master tables.

**Required schema (clean):**

- `platform_categories`
  - id, code, name_en, name_ar, weight_percentage, status, sort_order, created_at, updated_at, version
- `platform_items`
  - id, stable_code, category_id FK -> platform_categories, status, current_published_version_id, sample_data, sort_order, created_at, updated_at, version
- `platform_item_versions`
  - id, item_id FK -> platform_items, version_no, status
  - label_en, label_ar, instruction_en, instruction_ar
  - measurement_unit, sensor_tool, standard_spec_en, standard_spec_ar
  - safety_critical, multi_point, max_tyre_age_years, allow_free_text_note
  - result_options_json, severity_policy_json, applicability_json, reason_codes_json
  - note_requirement, evidence_requirement, min_photos
  - equipment_ids_json, guide_image_id
  - published_at, published_by, created_at, updated_at, version
- Child tables with FKs to `platform_item_versions`:
  - `platform_score_bands`
  - `platform_evidence_rules`
  - `platform_issue_fields`
  - `platform_issue_field_options`
  - `platform_measurement_bands`
- Keep:
  - `platform_option_sets`
  - `platform_option_values`
  - `platform_templates`
  - `platform_template_versions`
  - `platform_template_items`
  - `platform_scoring_rules`
  - `platform_grade_boundaries`
  - `platform_document_types`
  - `platform_releases`
  - `platform_change_requests`
  - `platform_outbox_events`
  - `platform_idempotency_keys`
  - `platform_audit_events`
  - `platform_languages`
  - `platform_user_language_preferences`
- Remove or migrate away from:
  - `platform_category_config`
  - `platform_item_metadata`
- Add indexes and FKs.
- Add `platform_guide_images` **or** explicitly document why guide image storage remains shared infrastructure. Prefer a clean `platform_guide_images` table and update guide image endpoints if practical.

**Data migration:**
- If any existing platform/legacy data matters, migrate it into the new tables.
- Seed must be idempotent.
- Legacy tables remain for the reference app but must not be read by Platform Admin code.

### Problem 2 — Common language API is not common to anonymous/public surfaces

Current `GET /api/v1/i18n/languages` requires authentication (`@PreAuthorize("isAuthenticated()")`).

**Fix:**
- Allow anonymous `GET /api/v1/i18n/languages`.
- Keep `GET /api/v1/i18n/me` and `PUT /api/v1/i18n/me` authenticated.
- Keep platform language CRUD `PLATFORM_ADMIN` only.
- Update `SecurityEndpointInventoryIT` accordingly.
- Document in `docs/DECISIONS.md` (supersede D-050 if needed).

### Problem 3 — Adaptive/visual regression pass not done

The rule is: **reuse UI/components, no fixed layout width/height, adaptive at all sizes**.

Current Platform Admin code still has:
- sidebar `width: 256`
- many fixed dimensions
- large rewrites without visual regression checks

**Fix:**
- Do not redesign the UI.
- Audit every Platform Admin screen at 360, 600, 768, 1024, 1440 px.
- Remove fixed widths/heights from layout containers.
- Keep fixed sizes only for icons, avatars, spacing tokens, hit targets, and intrinsic media ratios.
- Use `LayoutBuilder`, `MediaQuery`, `Flexible`, `Expanded`, `Wrap`, `AspectRatio`, `ConstrainedBox`, breakpoints.
- Verify EN/AR/RTL and long labels.
- Add widget tests for compact/medium/expanded.
- Compare against existing Figma screenshots; do not change visual identity.

## Non-Negotiable Rules

1. Backend full rebuild: Platform Admin code must use only clean `platform_*` tables.
2. Frontend UI must not be redesigned; reuse existing components and design system.
3. No fixed page/card widths or heights; adaptive layout only.
4. No Workshop Admin, Technician, or Public Report implementation in this phase.
5. No LLM/auto-translation.
6. No technician qualification, tool calibration, or QC sampling.
7. No commits unless explicitly asked.
8. Do not touch the pre-existing uncommitted `PublicReportService.java` / `print-report.html` report changes.
9. Do not delete legacy tables; keep them for the reference app. New code must not depend on them.
10. Ask only when blocked; otherwise record decisions in `docs/DECISIONS.md`.

## Implementation Order

1. Read docs and inspect current Phase 1 code.
2. Rewrite `V100` (or add a clean follow-up migration) to create the full clean platform tables, FKs, indexes.
3. Create/rewrite platform repositories/services for categories, items, versions.
4. Rewrite Platform Admin seed to write only `platform_*` tables.
5. Rewrite Governance/Template category-weight reads to use clean tables.
6. Remove use of `platform_category_config` and `platform_item_metadata` (migrate/drop).
7. Update Platform Admin APIs/tests to use clean tables.
8. Make `GET /api/v1/i18n/languages` anonymous.
9. Frontend adaptive audit + fixes + tests.
10. Update `docs/DECISIONS.md` and `docs/MIGRATION.md`.
11. Run verification and report.

## Verification

Backend:

```powershell
cd server
mvn "-Dtest=PlatformAdminPhase1IT,ConfigValidatorsTest,ArchitectureTest,SecurityEndpointInventoryIT,FlywayMigrationTest" test
```

Full backend (expected: only the two known pre-existing report failures remain):

```powershell
mvn test
```

Frontend:

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

Also run new adaptive tests at 360/600/768/1024/1440.

## Acceptance Criteria

1. Platform Admin code and seed read/write only `platform_*` tables for categories/items/versions.
2. No Platform Admin service, seed, governance, or template code reads `master_categories`, `master_inspection_items`, `master_item_versions`, `platform_category_config`, or `platform_item_metadata`.
3. Clean tables have FKs and consistent ID types.
4. `platform_category_config` and `platform_item_metadata` are removed or fully migrated; no code references them.
5. Seed remains idempotent: 6 categories, 30 items, bands, rules, issue fields, measurement bands, template, 5 docs, grades.
6. `GET /api/v1/i18n/languages` works anonymously; `/me` remains authenticated.
7. Platform Admin UI is reused, not redesigned.
8. No fixed layout container widths/heights; adaptive tests at 360/600/768/1024/1440 pass.
9. EN/AR/RTL tests pass.
10. Backend targeted tests pass; full suite only has the known pre-existing report failures.
11. `flutter analyze --fatal-infos` and Platform Admin tests pass.
12. `docs/DECISIONS.md` and `docs/MIGRATION.md` updated.

## Output Format

Report:
- Files created/changed.
- Schema changes and data migration behavior.
- Commands run and results.
- Decisions recorded.
- Remaining blockers (especially the two pre-existing report test failures).

Do not claim completion unless the acceptance criteria are verified.
