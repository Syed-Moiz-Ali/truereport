# Phase 1 — Platform Admin

**Goal:** Build the clean backend foundation and the Platform Admin configuration surface that Workshop Admin and Technician depend on.

**Prerequisites:** Approved flow freeze (`docs/DECISIONS.md`), backend rebuild plan, adaptive frontend rules.

---

## 1. Scope

### Backend
- New clean schema baseline and Flyway migrations.
- Identity/tenancy primitives required by this phase.
- Localization module and common language API.
- Master data configuration.
- Dynamic issue configuration.
- Global templates.
- Scoring rules, grade boundaries, safety caps.
- Report document types.
- Config release lifecycle, impact analysis, health dashboard.
- Seed 6 categories / 30 items / bands / rules / default template / 5 document types / grades.
- Platform Admin APIs with role enforcement and structured errors.

### Frontend
- Reuse the existing Platform Admin app and components.
- Replace mock providers/sample data with API calls.
- Add missing configuration screens using existing design-system components.
- Apply adaptive layout rules.
- Add EN/AR strings to ARB.

### Out of scope
- Workshop jobs, technician inspections, public report.
- Technician qualification, tool calibration, QC sampling (removed, D-046).
- LLM auto-translation (deferred, D-041).

---

## 2. Backend Deliverables

### 2.1 Foundation

- New package structure per `docs/BACKEND_REBUILD_PLAN.md`.
- New schema baseline:
  - identity/tenancy minimal tables.
  - localization tables.
  - master data, templates, scoring, document types.
  - outbox, audit, idempotency.
- Flyway clean baseline + seed migration.
- Shared error contract, idempotency, optimistic concurrency, audit.
- Outbox and observability scaffolding.

### 2.2 Localization

- `languages` table.
- `GET /api/v1/i18n/languages`
- `GET /api/v1/i18n/me`
- `PUT /api/v1/i18n/me`
- Platform CRUD `/api/v1/platform/i18n/languages`.
- Coverage endpoint `/api/v1/platform/i18n/coverage`.
- `MessageSource` + `messages_en/ar.properties`.
- `Accept-Language` + `?lang` resolver.
- Localized `ProblemDetail` errors with `messageEn`/`messageAr`.
- EN/AR required for publish.

### 2.3 Master data

- Categories: code, EN/AR names, weight, order, active.
- Items: code, category, EN/AR label/instruction, unit, sensor/tool, standard spec EN/AR, safety flag, multi-point, max tyre age, free-text flag, order.
- Item versions with immutable published versions.
- Score bands: PASS/ATTENTION/FAIL, min/max/default, criteria EN/AR.
- Evidence rules per status: min photos, min videos, min notes chars, required evidence type.
- Option sets/values (manual EN/AR).
- Item issue fields: input type, option set, required rules, min/max, unit set, dependency, multi-value, free-text, order.
- Per-item option subsets.
- Measurement bands: contiguous ranges, direction, result, default score, labels.
- Reorder endpoints.
- Deactivate/retire instead of delete.

### 2.4 Global templates

- `master_templates`, `master_template_versions`, `master_template_items`.
- Draft → Published → Retired.
- Add/remove/reorder items.
- Category weight preview and re-normalization.
- Publish immutability + maker-checker.
- Jobs will pin template versions in Phase 2.

### 2.5 Scoring & grades

- Scoring rules (weights mode, safety cap).
- Grade boundaries A/B/C/D with labels.
- Validation: coverage 0–100, no gaps/overlaps.
- Maker-checker for scoring/safety changes.
- Preview of effective grades.

### 2.6 Document types

- Code, EN/AR names, active, required, order.
- Seed 5 document types.

### 2.7 Governance

- Config release lifecycle: Draft → Review → Approved → Published → Deprecated.
- Impact analysis endpoint.
- Config health dashboard endpoint.
- Field-level audit.

### 2.8 Seed

- `V20` seed: 6 categories, 30 items, bands, evidence rules, option sets, issue fields, measurement bands, default template, document types, grade boundaries.
- Idempotent `POST /api/v1/platform/seed/default-checklist`.
- EN/AR completeness validation.

---

## 3. Backend API Surface

### Common
- `GET /api/v1/i18n/languages`
- `GET /api/v1/i18n/me`
- `PUT /api/v1/i18n/me`

### Platform
- Categories CRUD/reorder/retire/weight-check.
- Items CRUD/reorder/draft/translate/metadata/bands/evidence-rules/issue-fields/measurement-bands/publish/retire.
- Option sets/values CRUD/reorder/retire.
- Global templates CRUD/versions/items/weight-preview/publish/retire.
- Scoring rules/grade boundaries.
- Document types CRUD/reorder/retire.
- Config health, impact analysis, releases.
- Seed.
- Language registry CRUD + coverage.

All write endpoints: `PLATFORM_ADMIN` only.

---

## 4. Frontend Deliverables

### 4.1 Reuse
- Keep `platform_admin_app` shell, sidebar, header, theme, cards, tables, dialogs, chips, forms.
- Do not redesign screens.
- Extend existing components only where a new control is required (e.g., band row).

### 4.2 Data layer
- Replace `sampleMasterInspectionItems`, sample categories, and mock providers with API-backed Riverpod providers.
- Extend `PlatformAdminApi` + `ApiEndpoints`.
- Add models: category, item, version, band, evidence rule, option set/value, issue field, measurement band, template, scoring rule, grade boundary, document type, config health, impact, release.
- Map structured errors to inline field errors.

### 4.3 Screens
- Master library list: API categories, search/status, seed button.
- Category screen: CRUD/reorder/weight total/retire confirm.
- Item editor: basics, EN/AR, score bands, evidence rules, issue fields, measurement bands, guide image.
- Option sets manager.
- Global template list + builder (reorder, weight preview, publish).
- Scoring rules + grade boundaries.
- Document types.
- Language registry + coverage.
- Config health dashboard.
- Impact analysis dialog.
- Data catalogues/equipment/audit wired to APIs.

### 4.4 Adaptive rules
- No fixed page/card widths or heights.
- Use layout breakpoints, flex, wrap, scrolling, aspect ratios.
- Test at phone/tablet/desktop and EN/AR/RTL.
- See `docs/FRONTEND_ADAPTIVE_RULES.md`.

### 4.5 Localization
- All new UI strings in `app_en.arb` / `app_ar.arb`.
- Shared language controller; `Accept-Language` injected by `ApiClient`.
- Remove duplicate platform locale provider.

---

## 5. Tests

### Backend
- Master category/item CRUD and validation.
- Score band/evidence rule/measurement band validation.
- Option set and issue-field validation, dependencies, retire-in-use.
- Template versioning, ordering, weight preview, publish immutability.
- Grade boundary coverage.
- Maker-checker flow.
- Impact analysis and health dashboard.
- Seed idempotency and EN/AR completeness.
- Role denial for Workshop/Technician writes.
- Localized errors for `Accept-Language: ar`.
- Flyway migration on empty DB.

### Frontend
- Category weight validation.
- Item editor band/evidence/issue-field validation.
- Template builder weight preview.
- Scoring/grade validation.
- Language switch + RTL.
- Adaptive layout at compact/medium/expanded.
- Mocked API client tests.
- `flutter analyze` + `flutter test`.

---

## 6. Acceptance Criteria

1. Platform Admin can create a 7th category with weight and items via the UI.
2. Items support EN/AR, unit, sensor/tool, standard spec, safety flag, bands, evidence rules, dynamic issue fields, measurement bands.
3. Global templates can be created, reordered, previewed, and published.
4. Scoring rules, grade boundaries, safety caps, and document types are editable.
5. Seed creates 6 categories / 30 items idempotently.
6. Config health dashboard and impact analysis work.
7. Maker-checker applies to scoring/safety/template publication.
8. All writes are Platform-Admin-only.
9. EN/AR completeness is enforced; API errors localize.
10. No mock master data remains.
11. Backend tests and Flutter analyze/tests pass.
12. UI is reused and adaptive; no fixed container sizes.

---

## 7. Implementation Order

1. Backend foundation + clean schema.
2. Localization module + language APIs.
3. Master data entities/services/APIs.
4. Issue fields + measurement bands.
5. Templates + scoring + document types.
6. Governance (releases, impact, health).
7. Seed.
8. Backend tests.
9. Flutter models/API/providers.
10. Flutter screens + adaptive pass.
11. Flutter tests/analyze.
12. Review and approval before Phase 2.
