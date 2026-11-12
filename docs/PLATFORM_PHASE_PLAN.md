# Platform Admin Phase Plan

**Goal:** Make Platform Admin the single source of truth for all inspection configuration, scoring, templates, dynamic issue options, measurement bands, and report document types. Workshop Admin and Technician may only read and use this configuration.

**Sequence:** Platform Admin → Workshop Admin → Technician → Public website.

> Approved flow decisions: see `docs/DECISIONS.md` D-027 through D-071 and `docs/PROFESSIONAL_FLOWS.md`. No code starts until the product owner approves the Platform phase start.
>
> **Correction (D-071):** Platform Admin does **not** configure category/item weights, scoring rules, grade boundaries, weight previews, or item score bands. Templates are category-first; scoring is dynamic and equal-weight after the template is built in Workshop Admin. Sections below that mention weights/scoring are superseded by D-071.

---

## 1. Scope

### In scope

- Master categories with weights, order, active/retired state.
- Master items with EN/AR content, unit, sensor/tool, standard spec, safety-critical flag, order, active state.
- Item score bands (PASS/ATTENTION/FAIL).
- Item evidence rules per status (photos, videos, notes chars, document evidence).
- Dynamic issue option sets (issue type, location, component, condition, severity, action, urgency, cause, units).
- Per-item dynamic issue-field schema with cascading dependencies.
- Per-item measurement bands with auto-suggested status/score.
- Global Platform-Admin templates (versioned) with item selection, ordering, and weight preview.
- Scoring rules (category weights, safety caps) and grade boundaries.
- Report document types.
- Idempotent 30-item seed and seed endpoint.
- Flutter Platform Admin screens for all the above.
- API-backed data catalogues/equipment/audit; removal of production mock data.

### Out of scope for this phase

- Workshop job creation and approval screens.
- Technician inspection screens.
- Public report API/page.
- Payment, billing, delivery providers.
- Full hierarchy redesign.

---

## 2. Permissions

| Action | Platform Admin | Workshop Admin | Technician |
|---|---|---|---|
| Manage categories/items/bands/rules | WRITE | READ (published only) | READ (pinned snapshot) |
| Manage option sets / issue fields | WRITE | READ | READ |
| Manage global templates | WRITE | READ (select for job) | READ (pinned snapshot) |
| Manage scoring rules / grades | WRITE | READ | READ |
| Manage document types | WRITE | READ | READ |
| Load seed | WRITE | NO | NO |
| View audit | WRITE/READ | NO | NO |

All write APIs use `@PreAuthorize("hasRole('PLATFORM_ADMIN')")` and path prefix `/api/v1/platform/**`.

### Language endpoints (shared)

- `GET /api/v1/i18n/languages`
- `GET /api/v1/i18n/me`
- `PUT /api/v1/i18n/me`
- Platform CRUD: `/api/v1/platform/i18n/languages`
- Coverage: `/api/v1/platform/i18n/coverage`

See `docs/I18N_PLAN.md` for the full design and `docs/DECISIONS.md` D-033 to D-041.

**V1 language authoring:** Platform Admin manually enters EN and AR for every user-facing field. No LLM or machine translation in V1. Publish requires both languages (D-041). Every editor screen must expose both language inputs side by side.

---

## 3. Database Changes

### 3.1 Extend existing tables

**`master_categories`**
- `code VARCHAR(50) NOT NULL UNIQUE` (e.g. `CAT-ENG`)
- `weight_percentage DECIMAL(5,2) NOT NULL DEFAULT 0`
- keep `slug`, `status`, `sort_order`
- check: `weight_percentage BETWEEN 0 AND 100`

**`master_inspection_items`**
- `sort_order INT NOT NULL DEFAULT 0`
- `measurement_unit VARCHAR(30) NULL`
- `sensor_tool VARCHAR(150) NULL`
- `standard_spec_en TEXT NULL`
- `standard_spec_ar TEXT NULL`
- `is_safety_critical BOOLEAN NOT NULL DEFAULT FALSE`
- `max_tyre_age_years INT NULL`
- `allow_free_text_note BOOLEAN NOT NULL DEFAULT FALSE`
- `is_multi_point BOOLEAN NOT NULL DEFAULT FALSE`

**`master_item_versions`**
- keep versioning/immutability
- no new scoring columns; bands/rules live in child tables so they are versioned with the item version

### 3.2 New tables

**`item_score_bands`**
- `id BINARY(16) PK`
- `item_version_id BINARY(16) FK -> master_item_versions`
- `result_code VARCHAR(40)` (`NO_ISSUE_OBSERVED`, `ATTENTION_RECOMMENDED`, `DEFECT_FOUND`)
- `min_score INT`, `max_score INT`
- `default_score INT`
- `criteria_en TEXT`, `criteria_ar TEXT`
- unique `(item_version_id, result_code)`
- check `0 <= min_score <= default_score <= max_score <= 100`

**`item_evidence_rules`**
- `id BINARY(16) PK`
- `item_version_id BINARY(16) FK`
- `result_code VARCHAR(40)`
- `min_photos INT NOT NULL DEFAULT 0`
- `min_videos INT NOT NULL DEFAULT 0`
- `min_notes_chars INT NOT NULL DEFAULT 0`
- `required_evidence_type VARCHAR(20) NULL` (`PHOTO`, `VIDEO`, `DOCUMENT`)
- unique `(item_version_id, result_code)`

**`master_option_sets`** (reuse or extend `master_dropdowns`)
- `id BINARY(16) PK`
- `code VARCHAR(60) UNIQUE`
- `name_en`, `name_ar`
- `status ACTIVE/RETIRED`
- `sort_order`

**`master_option_values`** (reuse or extend `master_dropdown_values`)
- `id BINARY(16) PK`
- `option_set_id BINARY(16) FK`
- `code VARCHAR(60)`
- `label_en`, `label_ar`
- `status ACTIVE/RETIRED`
- `sort_order`
- `metadata_json TEXT NULL` (default severity, default result, numeric bounds, icon key)
- unique `(option_set_id, code)`

**`item_issue_fields`**
- `id BINARY(16) PK`
- `item_version_id BINARY(16) FK`
- `field_code VARCHAR(60)` (e.g. `ISSUE_TYPE`, `LOCATION`, `COMPONENT`, `MEASUREMENT`, `SEVERITY`, `ACTION`, `URGENCY`)
- `label_en`, `label_ar`
- `input_type VARCHAR(20)` (`SELECT`, `MULTI_SELECT`, `NUMBER`, `BOOLEAN`)
- `option_set_id BINARY(16) NULL`
- `unit_set_id BINARY(16) NULL`
- `required BOOLEAN NOT NULL DEFAULT FALSE`
- `required_for_statuses_json TEXT NULL` (default `["ATTENTION_RECOMMENDED","DEFECT_FOUND"]`)
- `min_value DECIMAL(12,3) NULL`
- `max_value DECIMAL(12,3) NULL`
- `decimal_places INT NOT NULL DEFAULT 0`
- `depends_on_field_code VARCHAR(60) NULL`
- `depends_on_value_code VARCHAR(60) NULL`
- `allow_multiple BOOLEAN NOT NULL DEFAULT FALSE`
- `allow_free_text BOOLEAN NOT NULL DEFAULT FALSE`
- `sort_order INT NOT NULL DEFAULT 0`
- unique `(item_version_id, field_code)`

**`item_issue_field_options`** (optional subset per item)
- `id BINARY(16) PK`
- `item_issue_field_id BINARY(16) FK`
- `option_value_id BINARY(16) FK`
- unique `(item_issue_field_id, option_value_id)`
- if no rows exist for a field, all active values of its option set are allowed

**`item_measurement_bands`**
- `id BINARY(16) PK`
- `item_version_id BINARY(16) FK`
- `field_code VARCHAR(60)` (usually `MEASUREMENT`)
- `unit_code VARCHAR(30)`
- `min_value DECIMAL(12,3)`, `max_value DECIMAL(12,3)`
- `result_code VARCHAR(40)`
- `default_score INT`
- `label_en`, `label_ar`
- `sort_order INT`
- check `min_value < max_value`
- validation: bands contiguous and non-overlapping per item/field/unit

**`assessment_issue_values`**
- `id BINARY(16) PK`
- `assessment_id BINARY(16) FK`
- `field_code VARCHAR(60)`
- `option_value_code VARCHAR(60) NULL`
- `numeric_value DECIMAL(12,3) NULL`
- `unit_code VARCHAR(30) NULL`
- `text_value TEXT NULL` (only when field allows free text)
- `value_index VARCHAR(20) NULL` (e.g. `FL`, `FR`, `RL`, `RR`)
- `sort_order INT`
- unique `(assessment_id, field_code, value_index)`

**`master_templates`**
- `id BINARY(16) PK`
- `code VARCHAR(60) UNIQUE`
- `name_en`, `name_ar`
- `description_en`, `description_ar`
- `status ACTIVE/RETIRED`
- `current_published_version_id BINARY(16) NULL`
- `created_by`, `created_at`, `updated_at`, `version`

**`master_template_versions`**
- `id BINARY(16) PK`
- `template_id BINARY(16) FK`
- `version_no INT`
- `status DRAFT/PUBLISHED/RETIRED`
- `published_at`, `published_by`
- unique `(template_id, version_no)`

**`master_template_items`**
- `id BINARY(16) PK`
- `template_version_id BINARY(16) FK`
- `item_version_id BINARY(16) FK`
- `sort_order INT`
- `included BOOLEAN`
- `item_weight DECIMAL(6,3) NULL` (null = equal weight)
- unique `(template_version_id, item_version_id)`

**`scoring_rules`**
- `id BINARY(16) PK`
- `code VARCHAR(60) UNIQUE`
- `name_en`, `name_ar`
- `active BOOLEAN`
- `category_weight_mode VARCHAR(20)` (`CONFIGURED`, `EQUAL`)
- `hard_fail_cap_enabled BOOLEAN`
- `hard_fail_cap_grade VARCHAR(5)` (e.g. `B`)
- `version INT`
- only one active rule at a time

**`grade_boundaries`**
- `id BINARY(16) PK`
- `scoring_rule_id BINARY(16) FK`
- `grade VARCHAR(5)` (`A`, `B`, `C`, `D`)
- `min_score INT`, `max_score INT`
- `label_en`, `label_ar`
- `sort_order`
- unique `(scoring_rule_id, grade)`
- validation: contiguous and cover 0–100

**`report_document_types`**
- `id BINARY(16) PK`
- `code VARCHAR(60) UNIQUE`
- `name_en`, `name_ar`
- `status ACTIVE/RETIRED`
- `sort_order`
- `required BOOLEAN` (whether mandatory before publish)

**`job_snapshots`** (created in a later phase, but schema reserved now)
- `id`, `job_id`, `snapshot_json`, `snapshot_hash`, `created_at`
- unique `job_id`

---

## 4. Seed Data

Source: `docs/truereport-spec.md`.

### 4.1 Categories (weights)

| Code | EN | AR | Weight | Order |
|---|---|---|---|---|
| CAT-ENG | Powertrain & Mechanical | مجموعة الحركة والميكانيكا | 25 | 1 |
| CAT-SUS | Suspension, Steering & Underbody | التعليق والتوجيه وأسفل الهيكل | 18 | 2 |
| CAT-BRK | Braking Systems & Tyres | أنظمة الفرامل والإطارات | 20 | 3 |
| CAT-ELE | Electrical, Battery & Diagnostics | الكهرباء والبطارية والتشخيص | 17 | 4 |
| CAT-BOD | Body, Glass & Interior | الهيكل والزجاج والمقصورة | 10 | 5 |
| CAT-ROA | Road Test & Dynamic Performance | اختبار الطريق والأداء الديناميكي | 10 | 6 |

### 4.2 Items

All 30 item codes from the spec, with:
- EN/AR label and instruction
- category
- measurement unit
- sensor/tool
- standard spec EN/AR
- `is_safety_critical`
- `sort_order`
- `max_tyre_age_years` for `TYRE-CND-01` = 2 (configurable, strict GCC value)
- `is_multi_point` for `BRK-PAD-01`, `TYRE-SET-01`, and location-based items

### 4.3 Bands (corrected contiguous ranges)

For every item:
- `DEFECT_FOUND`: 0–59, default 0 or the spec’s fail default
- `ATTENTION_RECOMMENDED`: 60–84, default from spec
- `NO_ISSUE_OBSERVED`: 85–100, default from spec

The spec’s item-specific defaults are preserved where valid; gaps/overlaps are corrected.

### 4.4 Measurement bands

For every item with a numeric measurement, define contiguous metric ranges per unit, e.g.:
- `BRK-PAD-01`: 0–2.99 FAIL, 3.0–5.49 ATTENTION, 5.5–99 PASS (using the corrected spec ranges)
- `TYRE-SET-01`: 0–1.99 FAIL, 2.0–5.49 ATTENTION, 5.5–99 PASS
- `ELE-BAT-01` SOH %: 0–59 FAIL, 60–84 ATTENTION, 85–100 PASS
- `INT-AC-01` °C: >16 FAIL, 9–16 ATTENTION, ≤9 PASS (inverted range handled by direction flag)
- Add `direction` (`HIGHER_IS_BETTER`, `LOWER_IS_BETTER`) to measurement bands if needed.

### 4.5 Evidence rules

Every item requires photo and video evidence for every result (D-023):

- `NO_ISSUE_OBSERVED`: ≥1 photo, ≥1 video, notes 0
- `ATTENTION_RECOMMENDED`: ≥1 photo, ≥1 video, notes ≥15 chars
- `DEFECT_FOUND`: ≥2 photos, ≥1 video, notes ≥15 chars
- `OBD-SCN-01`: `DOCUMENT` required for ATTENTION/FAIL
- Safety-critical items: Platform Admin may increase the evidence requirements but cannot weaken them
- Platform Admin can configure per-item overrides; defaults above are the minimum
- Video evidence: 15–30 seconds, max 50 MB, compressed before upload (D-029/T10)
- Evidence must be captured live via camera; gallery selection is blocked (D-029/T4)

### 4.6 Option sets to seed

| Code | Values (examples) |
|---|---|
| `ISSUE_TYPE` | WORN, CRACKED, LEAKING, BENT, LOOSE, CORRODED, MISSING, NOISY, CONTAMINATED, DAMAGED, SEIZED, MISALIGNED, WORN_OUT |
| `LOCATION` | FRONT_LEFT, FRONT_RIGHT, REAR_LEFT, REAR_RIGHT, FRONT, REAR, LEFT, RIGHT, UNDERBODY, ENGINE_BAY, CABIN, EXTERIOR, WHEEL_ARCH |
| `COMPONENT` | PAD, ROTOR, CALIPER, HOSE, FLUID, BUSHING, BALL_JOINT, STRUT, SPRING, BELT, PULLEY, BATTERY, ALTERNATOR, SENSOR, LAMP, FILTER, GLASS, SEAL |
| `CONDITION` | INNER, OUTER, UPPER, LOWER, SURFACE, STRUCTURAL, ELECTRICAL, MECHANICAL |
| `SEVERITY` | MINOR, MODERATE, MAJOR, SAFETY_CRITICAL |
| `ACTION` | REPLACE, REPAIR, MONITOR, ADJUST, CLEAN, FLUSH, RECHARGE, ALIGN, CALIBRATE |
| `URGENCY` | IMMEDIATE, WITHIN_7_DAYS, NEXT_SERVICE, MONITOR |
| `CAUSE` | WEAR, IMPACT, CORROSION, LEAK, ELECTRICAL_FAULT, IMPROPER_REPAIR, AGE, CONTAMINATION |
| `UNIT` | MM, UM, V, PSI, DEG_C, PERCENT, A, CCA, RPM, NM, BAR, KM |
| `YES_NO` | YES, NO |

### 4.7 Item issue schemas

Seed per-item schemas based on the item type:
- Measurement items: `ISSUE_TYPE`, `LOCATION`, `COMPONENT`, `MEASUREMENT`, `SEVERITY`, `ACTION`, `URGENCY`
- Visual items: `ISSUE_TYPE`, `LOCATION`, `SEVERITY`, `ACTION`
- Multi-point items: `LOCATION` with `allow_multiple=true` and `value_index=FL/FR/RL/RR`
- OBD: `ISSUE_TYPE`, `DTC_CODE` (if configured), `DOCUMENT` evidence
- Dependent fields: `COMPONENT` depends on `LOCATION`; `ACTION`/`URGENCY` depend on `SEVERITY`

### 4.8 Default template

`TPL-30-GCC`: “Comprehensive 30-Point GCC Standard”
- Includes all 30 items
- Category weights: 25/18/20/17/10/10
- Published version 1

### 4.9 Document types

1. `ELECTRICAL_DIAGNOSTICS` — Electrical Diagnostics Report
2. `BATTERY_HEALTH` — Battery Health & Conductance Test
3. `PRE_TEST_DRIVE` — Pre-Test Drive Inspection
4. `POST_ROAD_TEST` — Post-Road Test Performance
5. `TYRE_ALIGNMENT` — Tyre Alignment & Laser Wear Analysis

Documents are generated automatically by the backend after publish and stored in the database/object storage (D-024). They are not a pre-publish gate and do not require manual upload.

### 4.10 Grades

- A: 90–100
- B: 80–89
- C: 65–79
- D: 0–64

Safety cap: a `DEFECT_FOUND` on a safety-critical item caps the grade at `B` (configurable).

### 4.11 Seed execution

- Flyway Java migration `V20__seed_default_checklist.java` runs once.
- `POST /api/v1/platform/seed/default-checklist` re-runs idempotently by stable code/version.
- Returns `{ created, skipped, errors }`.
- Never overwrites published user edits; skips existing codes.

---

## 5. API Surface

Base: `/api/v1/platform`

### 5.1 Categories

| Method | Path | Purpose |
|---|---|---|
| GET | `/master/categories` | List categories with weights/item counts |
| POST | `/master/categories` | Create |
| PUT | `/master/categories/{id}` | Update code/name/weight/order/status |
| POST | `/master/categories/{id}/retire` | Deactivate |
| PUT | `/master/categories/reorder` | Bulk sort order |
| GET | `/master/categories/weight-check` | Validate active weights sum 100 |

### 5.2 Items

| Method | Path | Purpose |
|---|---|---|
| GET | `/master/items` | List/filter/search |
| GET | `/master/items/{id}` | Detail + versions + bands + issue schema |
| POST | `/master/items` | Create item + v1 draft |
| PUT | `/master/items/{id}` | Update metadata |
| POST | `/master/items/{id}/versions` | Create draft version |
| PUT | `/master/items/{id}/versions/{versionId}/translations/{locale}` | EN/AR/other |
| PUT | `/master/items/{id}/versions/{versionId}/metadata` | Unit/spec/sensor/safety/multi-point/free-text |
| PUT | `/master/items/{id}/versions/{versionId}/bands` | Replace score bands |
| PUT | `/master/items/{id}/versions/{versionId}/evidence-rules` | Replace evidence rules |
| PUT | `/master/items/{id}/versions/{versionId}/issue-fields` | Replace dynamic issue schema |
| PUT | `/master/items/{id}/versions/{versionId}/measurement-bands` | Replace metric bands |
| POST | `/master/items/{id}/versions/{versionId}/publish` | Publish |
| POST | `/master/items/{id}/retire` | Retire |
| PUT | `/master/items/reorder` | Bulk sort order |

### 5.3 Option sets

| Method | Path | Purpose |
|---|---|---|
| GET | `/master/option-sets` | List sets + values |
| POST | `/master/option-sets` | Create set |
| PUT | `/master/option-sets/{id}` | Update set |
| POST | `/master/option-sets/{id}/retire` | Retire set |
| POST | `/master/option-sets/{id}/values` | Add value |
| PUT | `/master/option-sets/{id}/values/{valueId}` | Update value |
| POST | `/master/option-sets/{id}/values/{valueId}/retire` | Retire value |
| PUT | `/master/option-sets/{id}/values/reorder` | Reorder values |

### 5.4 Global templates

| Method | Path | Purpose |
|---|---|---|
| GET | `/master/templates` | List |
| GET | `/master/templates/{id}` | Detail + versions |
| POST | `/master/templates` | Create + draft v1 |
| PUT | `/master/templates/{id}` | Rename/describe |
| POST | `/master/templates/{id}/versions` | Create draft |
| PUT | `/master/templates/{id}/versions/{versionId}/items` | Replace items/order/weights |
| GET | `/master/templates/{id}/versions/{versionId}/weight-preview` | Effective normalized weights |
| POST | `/master/templates/{id}/versions/{versionId}/publish` | Publish |
| POST | `/master/templates/{id}/retire` | Retire |

### 5.5 Scoring / grades / document types

| Method | Path | Purpose |
|---|---|---|
| GET | `/scoring-rules` | Active rule |
| PUT | `/scoring-rules/{id}` | Update weights mode/cap |
| GET | `/scoring-rules/{id}/grade-boundaries` | List |
| PUT | `/scoring-rules/{id}/grade-boundaries` | Replace/validate |
| GET | `/document-types` | List |
| POST | `/document-types` | Create |
| PUT | `/document-types/{id}` | Update |
| POST | `/document-types/{id}/retire` | Retire |
| PUT | `/document-types/reorder` | Reorder |

### 5.6 Seed

| Method | Path | Purpose |
|---|---|---|
| POST | `/seed/default-checklist` | Idempotent seed |

---

## 6. Validation Rules

- Active category weights must sum to 100; error `CATEGORY_WEIGHTS_INVALID`.
- Template weight preview re-normalizes over categories present in the template; never mutates stored master weights.
- Score bands must be contiguous, non-overlapping, and cover 0–100.
- Measurement bands must be contiguous and non-overlapping; validate `direction`.
- `required_for_statuses` must be a subset of canonical result codes.
- Option values referenced by active items cannot be retired without a replacement; error `OPTION_IN_USE`.
- Categories/items referenced by published templates/jobs cannot be deleted; deactivate only.
- Published item/template versions are immutable; edits require a new draft version.
- `is_safety_critical` items must have FAIL evidence rules and a measurement band if numeric.
- Grade boundaries must cover 0–100 with no gaps.
- Structured errors: `{ "field": "...", "code": "...", "messageEn": "...", "messageAr": "..." }`.

---

## 7. Flutter Platform Admin

### 7.1 Models

Add to `client/apps/platform_admin_app/lib/src/platform_models.dart` (or a shared `domain` package if reused later):

- `MasterCategory`
- `MasterItem`
- `MasterItemVersion`
- `ScoreBand`
- `EvidenceRule`
- `IssueField`
- `IssueFieldOption`
- `MeasurementBand`
- `OptionSet`
- `OptionValue`
- `MasterTemplate`
- `MasterTemplateVersion`
- `MasterTemplateItem`
- `ScoringRule`
- `GradeBoundary`
- `ReportDocumentType`
- `SeedResult`

### 7.2 API client

Extend `PlatformAdminApi` / `HttpPlatformAdminApi` with all endpoints in section 5 and add paths to `ApiEndpoints`.

### 7.3 Providers

Replace mock providers with:

- `categoriesProvider`
- `itemsProvider(filters)`
- `itemDetailProvider(itemId)`
- `optionSetsProvider`
- `templatesProvider`
- `templateDetailProvider(templateId)`
- `scoringRuleProvider`
- `gradeBoundariesProvider`
- `documentTypesProvider`
- Mutation notifiers/services with `AsyncValue` and inline error mapping.

Remove `sampleMasterInspectionItems`, `masterItemsListProvider` mutations, sample categories, and hardcoded catalogues.

### 7.4 Screens and routes

| Route | Screen |
|---|---|
| `/master-library` | Category tabs, item table, search/status, seed button |
| `/master-library/categories` | Categories CRUD/reorder/weight total |
| `/master-library/items/new` | Item editor (create) |
| `/master-library/items/:id/edit` | Item editor (draft/publish) |
| `/master-library/option-sets` | Option set manager |
| `/templates` | Global template list |
| `/templates/:id` | Template builder (drag/reorder, weight preview, publish) |
| `/scoring` | Scoring rules, grade boundaries, safety cap |
| `/document-types` | Document type manager |
| `/data-catalogues` | Reasons/dropdowns API-backed |
| `/equipment` | Equipment API-backed |
| `/audit-log` | API-backed audit events |

Sidebar adds: Templates, Scoring, Document Types.

### 7.5 Screens detail

**Category screen**
- Table: code, EN, AR, weight, order, item count, status.
- Add/edit drawer with EN/AR, weight, order.
- Weight total footer with red/green state.
- Deactivate confirmation; blocked if referenced.

**Item editor**
- Tabs/sections: Basics, English, Arabic, Score Bands, Evidence Rules, Issue Fields, Measurement Bands, Guide Image.
- Basics: code, category, unit, sensor/tool, standard spec EN/AR, safety-critical, multi-point, max tyre age, allow free-text note, sort order.
- Bands table: status, min, max, default, criteria EN/AR.
- Evidence table: status, min photos, min videos, min notes chars, required type.
- Issue fields builder: field code, label EN/AR, input type, option set, required, required-for-status, min/max, decimal places, dependency, allow multiple/free text, order.
- Measurement bands: unit, min, max, direction, result, score, labels.
- Inline validation errors mapped from API.

**Template builder**
- Item picker grouped by category with search.
- Selected items list with drag/reorder, include toggle, optional weight.
- Live weight preview and re-normalization note.
- Publish/retire with validation.

**Scoring screen**
- Category weights table (read-only from categories) + validation.
- Grade boundary editor with coverage check.
- Safety cap toggle and cap grade.
- Preview of resulting grade bands.

**Document types**
- Table with code, EN/AR, required, order, status.

**Catalogues/equipment**
- Wire existing endpoints; remove hardcoded lists; add CRUD where missing.

### 7.6 i18n / RTL

- Add all UI strings to `client/packages/l10n/lib/l10n/app_en.arb` and `app_ar.arb`.
- Use shared `localeProvider`; remove duplicate `platformLocaleProvider`.
- Ensure `Directionality`/theme is RTL for Arabic.
- API content is rendered in the selected language with EN/AR fallback.

---

## 8. Tests

### Backend

- `MasterContentIT` extensions:
  - category weights validation
  - item metadata/bands/rules persistence
  - option set CRUD and retire-in-use
  - issue-field schema validation and dependencies
  - measurement band contiguity
  - template versioning, item ordering, weight preview
  - grade boundary coverage
  - seed idempotency
  - role denial for workshop/technician writes
- New unit tests:
  - `WeightNormalizerTest`
  - `IssueFieldValidatorTest`
  - `MeasurementBandValidatorTest`
  - `GradeBoundaryValidatorTest`
- Flyway migration test on H2; MySQL Testcontainers in CI.

### Flutter

- Widget tests: category weight total, item band editor validation, issue-field builder, template builder re-normalization, scoring screen boundaries.
- API client tests with mocked responses and structured errors.
- `flutter analyze` and `flutter test` for `platform_admin_app`.
- Add `platform_admin_app` to CI.

---

## 9. Acceptance Criteria

1. Platform Admin can create/edit/deactivate categories with weights and order.
2. Platform Admin can create/edit items with EN/AR, unit, sensor/tool, standard spec, safety flag, bands, evidence rules, dynamic issue fields, and measurement bands.
3. Platform Admin can create a global template, reorder items, see re-normalized weights, and publish.
4. Platform Admin can edit grade boundaries and safety cap.
5. Platform Admin can manage document types.
6. Seed loads 6 categories and 30 items idempotently.
7. No mock master data remains in production paths.
8. All writes are Platform-Admin-only; Workshop/Technician get 403.
9. Validation errors appear inline in EN/AR.
10. The common language API is available to all platforms, and Platform Admin can manage the language registry.
11. Every user-facing text is EN/AR complete at publish; CI parity and coverage checks pass.
12. Every Platform Admin editor exposes EN and AR inputs; no LLM/auto-translation is required in V1.
13. Backend tests, `flutter analyze`, and platform app tests pass.

---

## 10. Implementation Checklist

- [ ] `docs/truereport-spec.md`, `docs/AUDIT.md`, `docs/PLATFORM_PHASE_PLAN.md`, `docs/DYNAMIC_ISSUE_CONFIG.md`, `docs/DECISIONS.md`
- [ ] `V19__platform_master_scoring.sql`
- [ ] `V20__seed_default_checklist.java` + seed JSON
- [ ] Entities/repositories for new tables
- [ ] Extend `MasterContentService`
- [ ] New platform services/controllers
- [ ] Structured validation errors
- [ ] Backend tests
- [ ] Common language API + `MessageSource` + localized errors
- [ ] Platform language registry CRUD + translation coverage
- [ ] Config release lifecycle + impact analysis + health dashboard
- [ ] Transactional outbox + observability wiring
- [ ] Flutter shared `LanguageController` + `Accept-Language` injection
- [ ] Flutter models/API/providers
- [ ] Platform screens/routes/sidebar
- [ ] Remove mock catalogues/equipment/audit
- [ ] Flutter tests + analyze
- [ ] Update `docs/DECISIONS.md` and `docs/MIGRATION.md`
