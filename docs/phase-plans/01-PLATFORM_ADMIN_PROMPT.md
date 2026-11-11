# Phase 1 Prompt — Platform Admin (Start in New Session)

You are a senior full-stack engineer working in the TrueReport monorepo:

- Repo: `E:\syed_moiz_ali\bitlogix\truereport`
- Backend: Java / Spring Boot (rebuild cleanly)
- Frontend: Flutter (Melos workspace)
- First phase: **Platform Admin only**
- Do not implement Workshop Admin, Technician, or Public Report code in this phase.

## Read First (Required)

Read these docs before changing code:

1. `docs/IMPLEMENTATION_PLAN.md`
2. `docs/BACKEND_REBUILD_PLAN.md`
3. `docs/FRONTEND_ADAPTIVE_RULES.md`
4. `docs/PLATFORM_PHASE_PLAN.md`
5. `docs/phase-plans/01-PLATFORM_ADMIN.md`
6. `docs/DYNAMIC_ISSUE_CONFIG.md`
7. `docs/I18N_PLAN.md`
8. `docs/PROFESSIONAL_FLOWS.md`
9. `docs/DECISIONS.md` (D-001 to D-048)
10. `docs/AUDIT.md`
11. `docs/truereport-spec.md`

If any doc conflicts with this prompt, this prompt wins only where it is more specific. Otherwise follow the docs.

## Non-Negotiable Rules

1. **Backend full rebuild.** Do not keep patching the existing clumsy backend. Treat the current backend as reference only. Build a clean module structure, clean schema baseline, and new services/tests.
2. **Frontend UI must not be redesigned.** Reuse existing screens, components, design system, theme, and Figma-based visual identity. Only adapt data wiring, state, and responsive behaviour.
3. **No fixed width/height for layout containers.** Use adaptive layout: `LayoutBuilder`, `MediaQuery`, `Flexible`, `Expanded`, `Wrap`, `AspectRatio`, `ConstrainedBox`, breakpoints, design tokens. No fixed page/card widths copied from Figma.
4. **Server is the source of truth** for validation, scoring, grading, snapshots, and public payloads.
5. **No hardcoded categories/items/weights/bands/grades/options/report text.** Everything comes from Platform Admin data.
6. **EN/AR only for V1.** No LLM or machine translation. Platform Admin manually enters both languages for every user-facing field. Publish requires both.
7. **No technician qualification, tool calibration, or QC sampling.** Removed from scope (D-046).
8. **No post-publish corrections.** No correction flow. Rejection requires a new inspection.
9. **Role enforcement:** all Platform Admin write APIs are `PLATFORM_ADMIN` only.
10. **No commits unless explicitly asked.**
11. **Do not touch** existing uncommitted `PublicReportService.java`, `print-report.html`, `scratch/`, `seed_report.sql`, or other untracked files unless required by this phase.
12. **Ask only when blocked.** Otherwise pick the conservative default, record it in `docs/DECISIONS.md`, and continue.

## Phase Scope

### Backend

Build the clean foundation and Platform Admin configuration:

1. New backend package structure:
   `identity`, `tenancy`, `localization`, `masterdata`, `templates`, `jobs` (minimal), `audit`, `shared`, plus outbox/observability scaffolding.
2. New clean Flyway schema baseline for the rebuilt backend. Do not build on V1–V18. Archive old migrations for reference.
3. Shared infrastructure:
   - RFC 9457 error contract with `code`, `messageKey`, `messageEn`, `messageAr`, `detail`, `traceId`, field errors.
   - Idempotency keys.
   - Optimistic concurrency (`version`/ETag).
   - Audit events.
   - Transactional outbox table/scaffolding.
   - Structured logging and basic metrics hooks.
4. Localization:
   - `languages` table.
   - `GET /api/v1/i18n/languages`, `GET /api/v1/i18n/me`, `PUT /api/v1/i18n/me`.
   - Platform CRUD `/api/v1/platform/i18n/languages`.
   - `GET /api/v1/platform/i18n/coverage`.
   - Spring `MessageSource` + `messages_en.properties` / `messages_ar.properties`.
   - `Accept-Language` and `?lang` resolution.
   - Localized `ProblemDetail` errors.
5. Master data:
   - Categories: code, EN/AR names, weight, order, active.
   - Items: code, category, EN/AR label/instruction, unit, sensor/tool, standard spec EN/AR, safety flag, multi-point, max tyre age, free-text flag, order.
   - Item versions with immutable published versions.
   - Score bands: PASS/ATTENTION/FAIL, min/max/default, criteria EN/AR.
   - Evidence rules: min photos/videos/notes chars, required evidence type per status.
   - Option sets/values (manual EN/AR).
   - Item issue fields: input type, option set, required rules, min/max, unit set, dependency, multi-value, free-text, order.
   - Per-item option subsets.
   - Measurement bands: contiguous ranges, direction, result, default score, labels.
   - Reorder endpoints.
   - Deactivate/retire instead of delete.
6. Global templates:
   - `master_templates`, `master_template_versions`, `master_template_items`.
   - Draft → Published → Retired.
   - Add/remove/reorder items.
   - Weight preview and re-normalization.
   - Publish immutability + maker-checker.
7. Scoring and grades:
   - Scoring rules (weights mode, safety cap).
   - Grade boundaries A/B/C/D with labels.
   - Coverage validation (0–100, no gaps/overlaps).
   - Maker-checker for scoring/safety changes.
8. Report document types:
   - Code, EN/AR names, active, required, order.
9. Governance:
   - Config release lifecycle: Draft → Review → Approved → Published → Deprecated.
   - Impact analysis endpoint.
   - Config health dashboard endpoint.
   - Field-level audit.
10. Seed:
    - 6 categories with weights 25/18/20/17/10/10.
    - 30 items from `docs/truereport-spec.md`.
    - Score bands (contiguous 0–59 / 60–84 / 85–100).
    - Measurement bands (contiguous, direction-aware).
    - Evidence rules: every item requires ≥1 photo + ≥1 video for every result; FAIL ≥2 photos + ≥1 video; notes ≥15 chars where required; OBD DOCUMENT evidence.
    - Option sets and per-item issue schemas.
    - Default template `TPL-30-GCC`.
    - 5 document types.
    - Grade boundaries A 90–100, B 80–89, C 65–79, D 0–64.
    - Safety cap default B.
    - Idempotent `POST /api/v1/platform/seed/default-checklist`.

### Frontend (Platform Admin App)

1. Reuse the existing `client/apps/platform_admin_app` shell, sidebar, header, theme, cards, tables, dialogs, chips, forms.
2. Replace mock/sample providers with API-backed Riverpod providers.
3. Extend `PlatformAdminApi` and `ApiEndpoints`.
4. Add models for all new config objects.
5. Screens:
   - Master library list with API categories, search/status, seed button.
   - Categories CRUD/reorder/weight total/retire confirm.
   - Item editor: basics, EN/AR, score bands, evidence rules, issue fields, measurement bands, guide image.
   - Option sets manager.
   - Global template list + builder (reorder, weight preview, publish).
   - Scoring rules + grade boundaries.
   - Document types.
   - Language registry + coverage.
   - Config health dashboard.
   - Impact analysis dialog.
   - Data catalogues/equipment/audit wired to APIs.
6. Shared language controller; `ApiClient` sends `Accept-Language`.
7. All new UI strings in `app_en.arb` / `app_ar.arb`.
8. Apply `docs/FRONTEND_ADAPTIVE_RULES.md`.
9. Remove production mock data from Platform Admin paths.

## Required API Surface

### Common
- `GET /api/v1/i18n/languages`
- `GET /api/v1/i18n/me`
- `PUT /api/v1/i18n/me`

### Platform Admin
- Categories: list/create/update/retire/reorder/weight-check.
- Items: list/detail/create/update/reorder/draft/translations/metadata/bands/evidence-rules/issue-fields/measurement-bands/publish/retire.
- Option sets: list/create/update/retire; values add/update/retire/reorder.
- Global templates: list/detail/create/update/versions/items/weight-preview/publish/retire.
- Scoring rules: get/update; grade boundaries get/replace.
- Document types: list/create/update/retire/reorder.
- Config health, impact analysis, releases.
- Seed.
- Language registry CRUD + coverage.

## Validation Rules

- Active category weights sum to 100.
- Templates re-normalize over categories present.
- Score bands contiguous/non-overlapping and cover 0–100.
- Measurement bands contiguous/non-overlapping; direction-aware.
- EN + AR required for all user-facing content at publish.
- Option values in use cannot be retired without replacement.
- Referenced categories/items cannot be deleted; deactivate only.
- Published item/template versions immutable; edits create new drafts.
- Safety-critical items must have FAIL evidence rules and measurement bands when numeric.
- Grade boundaries cover 0–100 with no gaps.
- Structured errors with EN/AR.

## Implementation Order

1. Read docs and create a todo list.
2. Backend clean foundation + schema baseline.
3. Localization module + language APIs.
4. Master data entities/services/APIs.
5. Issue fields + measurement bands.
6. Templates + scoring + document types.
7. Governance (releases, impact, health).
8. Seed.
9. Backend tests.
10. Flutter models/API/providers.
11. Flutter screens + adaptive pass.
12. Flutter tests/analyze.
13. Report results and stop for approval before Phase 2.

## Verification

Run:

```powershell
cd server
mvn test
```

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

Notes:
- Docker is not available locally; use H2 tests. MySQL Testcontainers can run in CI.
- Do not run long unrelated builds.
- If a command fails, fix it or report the exact blocker.

## Acceptance Criteria

1. Platform Admin can create a 7th category with weight and items via the UI.
2. Items support EN/AR, unit, sensor/tool, standard spec, safety flag, bands, evidence rules, dynamic issue fields, measurement bands.
3. Global templates can be created, reordered, weight-previewed, and published.
4. Scoring rules, grade boundaries, safety caps, and document types are editable.
5. Seed creates 6 categories / 30 items idempotently.
6. Config health dashboard and impact analysis work.
7. Maker-checker applies to scoring/safety/template publication.
8. All writes are Platform-Admin-only.
9. EN/AR completeness enforced; API errors localize.
10. No mock master data remains.
11. Backend tests and Flutter analyze/tests pass.
12. UI is reused and adaptive; no fixed container sizes.

## Output Format

After each chunk, report:
- Files changed/created.
- Commands run and results.
- Decisions recorded.
- Blockers/open questions.

Start by reading the required docs and creating a todo list. Then begin the backend foundation.
