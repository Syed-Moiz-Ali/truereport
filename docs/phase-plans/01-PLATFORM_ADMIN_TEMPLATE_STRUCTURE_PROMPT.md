# Platform Admin Template Structure + Remove Weighting/Scoring — Prompt

You are fixing the Platform Admin template model and UI in:

`E:\syed_moiz_ali\bitlogix\truereport`

## Two Required Corrections

### 1. Template structure is category-first

A template is **not** a flat list of items.

```text
Template
 ├── Category A (order)
 │    ├── Item 1
 │    ├── Item 2
 │    └── Item 3
 ├── Category B (order)
 │    ├── Item 4
 │    └── Item 5
 └── Category C (order)
      └── Item 6
```

- A template has multiple categories.
- Each category contains its checklist items.
- A template may include a subset of master categories.
- A template may include a subset of items inside each category.
- Categories with zero included items are excluded.
- Items must belong to the category they are grouped under.

### 2. Remove weighting and scoring from Platform Admin completely

Platform Admin must **not** configure:

- Category weights
- Item weights
- Scoring rules
- Grade boundaries
- Weight previews
- Weight validation
- Item score bands / default scores
- Any scoring screen, route, nav item, API, table, seed data, or test

Scoring becomes dynamic **after the template is built in Workshop Admin**.

Default dynamic rule (document it, implement in the later Workshop/Public phases):

```text
includedCategories = count of categories with at least one included item
categoryWeight     = 100 / includedCategories
itemWeight         = categoryWeight / includedItemsInCategory

categoryScore = sum(itemScore * itemWeight)
overallScore  = sum(categoryScore * categoryWeight)
```

- All categories are equal.
- All items inside a category are equal.
- No Platform Admin weight or score configuration exists.
- The numerical score mapping from PASS/ATTENTION/FAIL can be decided in the Workshop Admin phase.
- Do not reintroduce weights/scoring into Platform Admin later.

## Read First

1. `docs/IMPLEMENTATION_PLAN.md`
2. `docs/BACKEND_REBUILD_PLAN.md`
3. `docs/PLATFORM_PHASE_PLAN.md`
4. `docs/DYNAMIC_ISSUE_CONFIG.md`
5. `docs/NAMING_AND_TESTING_RULES.md`
6. `docs/DECISIONS.md` (D-001 to D-071)
7. `docs/MIGRATION.md`
8. `docs/FRONTEND_ADAPTIVE_RULES.md`

## Non-Negotiable Rules

1. Platform Admin only. Do not start Workshop/Technician/Public work.
2. Reuse existing Platform Admin UI/components/design system. Do not redesign.
3. No phase numbers in production code, API paths, tables, or ARB keys.
4. Fakes stay in `test/support/`; production uses real APIs.
5. Server is the source of truth for template structure and validation.
6. No commits unless explicitly asked.
7. Do not touch the uncommitted `PublicReportService.java` / `print-report.html`.
8. Ask only when blocked; record decisions in `docs/DECISIONS.md`.

## Agentic Sub-Sessions

1. **Discovery agent**
   - Inspect current template backend/frontend.
   - Produce a gap list: flat list, weights, scoring, grade boundaries, weight preview.
   - Do not edit files.

2. **Backend agent**
   - Owns `server/src/main/java/...` and backend tests.
   - Adds template-category grouping.
   - Removes weights, scoring rules, grade boundaries, score bands, weight previews.
   - Does not edit Flutter.

3. **Frontend data agent**
   - Owns `client/packages/api_client`, Platform Admin template models/API/providers.
   - Adds grouped template DTOs.
   - Removes weight/score fields and scoring APIs.
   - Does not edit UI screens.

4. **Frontend UI agent**
   - Owns `client/apps/platform_admin_app/lib/src/features/templates/**`.
   - Builds category sections with nested item checklists.
   - Removes scoring screens/routes/nav, category weight fields, weight previews.
   - Does not edit backend or API client.

5. **Integrator/verifier**
   - Runs backend tests, Flutter analyze/tests, live E2E.
   - Only the integrator claims completion.

Rules: one file owner at a time; agree DTOs before parallel work; no two agents editing the same file.

## Backend Changes

### Remove weighting/scoring

Remove or stop using:

- `platform_categories.weight_percentage`
- `platform_template_categories.weight_override`
- `platform_template_items.item_weight`
- `platform_score_bands` (and its APIs)
- `platform_scoring_rules`
- `platform_grade_boundaries`
- `/api/v1/platform/master/categories/weight-check`
- `/api/v1/platform/scoring-rules`
- `/api/v1/platform/scoring-rules/{id}/grade-boundaries`
- Template `weight-preview` endpoint
- Weight/score fields in DTOs, requests, responses, seed data, tests

If tables/columns already exist, add a migration that drops them or stops using them. Keep published template versions immutable. Document the migration in `docs/MIGRATION.md`.

### Template category grouping

Add:

- `platform_template_categories`
  - id
  - template_version_id FK -> platform_template_versions
  - category_id FK -> platform_categories
  - sort_order
  - included
  - unique (template_version_id, category_id)

- Extend `platform_template_items`
  - add `category_id` FK -> platform_categories
  - keep `item_version_id`, `sort_order`, `included`
  - remove `item_weight`
  - unique (template_version_id, item_version_id)
  - validate `category_id` matches the item version's master category

If a cleaner migration is preferable, create V106+ and migrate existing template items by deriving category from the item version.

### APIs

Template version detail must return grouped categories:

```json
{
  "id": "...",
  "templateId": "...",
  "versionNo": 1,
  "status": "PUBLISHED",
  "categories": [
    {
      "categoryId": "...",
      "categoryCode": "CAT-ENG",
      "nameEn": "Powertrain & Mechanical",
      "nameAr": "مجموعة الحركة والميكانيكا",
      "sortOrder": 1,
      "itemCount": 6,
      "includedCount": 6,
      "items": [
        {
          "id": "...",
          "itemId": "...",
          "itemVersionId": "...",
          "itemCode": "ENG-OIL-01",
          "labelEn": "...",
          "labelAr": "...",
          "sortOrder": 1,
          "included": true
        }
      ]
    }
  ]
}
```

Keep a flat `items[]` only if needed for backward compatibility, but the UI and validation must use `categories[]`.

Endpoints:
- `GET /api/v1/platform/master/templates/{id}` → grouped categories.
- `PUT /api/v1/platform/master/templates/{id}/versions/{versionId}/categories`
  - body: ordered categories with `categoryId`, `included`, `sortOrder`.
- `PUT /api/v1/platform/master/templates/{id}/versions/{versionId}/items`
  - body accepts `categoryId`, `itemVersionId`, `included`, `sortOrder`.
- Remove `weight-preview`.
- Remove scoring/grade-boundary endpoints.

### Validation

- Every template item’s `categoryId` must match the item version’s master category.
- No duplicate item versions in a template version.
- No duplicate categories in a template version.
- Categories with no included items are excluded.
- Published template versions are immutable; edits create a new draft.
- Maker-checker still applies to template publication.
- No weight/score validation exists.

### Seed

Update `TPL-30-GCC` seed:
- 6 categories in order.
- Each category contains its items.
- No weights.
- No scoring rule, grade boundaries, or score bands.
- No duplicate items.
- Idempotent.

## Frontend Changes

### Remove scoring/weighting UI

Remove:

- Scoring screen and route.
- Scoring sidebar item and mobile nav item.
- Category weight fields, weight total/footer, weight validation.
- Item weight fields.
- Template weight preview/override.
- Grade boundary screen/UI.
- Any ARB keys for weights, scoring, grades, weight preview (or keep for non-scoring UI only if still used).

### Template Builder UI

Replace the flat selected-item list with category sections:

```text
Template Builder
[Version selector] [Create draft] [Publish]

Categories: 5   Items: 25

┌ Powertrain & Mechanical  6 items ───────────────────┐
│  [x] ENG-OIL-01  Engine Oil Condition & Level       │
│  [x] ENG-FLT-01  Engine Air Filter                  │
│  [ ] ...                                            │
│  [+ Add item from this category]                    │
└─────────────────────────────────────────────────────┘

┌ Braking Systems & Tyres  5 items ───────────────────┐
│  [x] BRK-PAD-01  Brake Pad Thickness                │
│  ...                                                │
└─────────────────────────────────────────────────────┘
```

Requirements:
- Categories are ordered; drag/reorder categories.
- Items are ordered inside each category; drag/reorder items.
- Add/remove items per category.
- Show category item count and included count.
- No weight/score UI anywhere.
- Show category-level empty state if no items.
- Search items within a category or across categories.
- Do not render the flat list as the primary UI.
- Reuse existing Platform Admin components, buttons, cards, dialogs, and shell.

### Models/API

- Add `TemplateCategory` model with `categoryId`, code, names, sortOrder, items.
- Extend `TemplateItem` with `categoryId`/category metadata.
- Remove weight/score fields from template/category models and API clients.
- Update providers for category-grouped save.
- Keep backward compatibility with old `items[]` only if needed.

## Dynamic Scoring Contract (Later Phases)

Document this, but do not implement it in Platform Admin:

```text
includedCategories = categories with >=1 included item
categoryWeight     = 100 / includedCategories
itemWeight         = categoryWeight / includedItemsInCategory

categoryScore = sum(itemScore * itemWeight)
overallScore  = sum(categoryScore * categoryWeight)
```

- Equal category weights.
- Equal item weights inside a category.
- No Platform Admin configuration.
- PASS/ATTENTION/FAIL numeric mapping can be decided in Workshop Admin.

## Tests

Backend:
- Grouped template categories/items.
- Category/item ordering.
- Wrong-category rejection.
- Duplicate rejection.
- No weight/score endpoints or fields remain.
- Publish immutability.
- Seed groups 6 categories/30 items with no weights/scores.
- Migration removes/deprecates weight/scoring tables/columns.

Frontend:
- Category sections render and nest items correctly.
- Add/remove/reorder categories and items.
- Wrong-category items are not offered.
- No scoring screen/route/nav/weight UI.
- Adaptive at 360/600/768/1024/1440 + RTL.
- API client tests for grouped responses.

Live E2E:
- Create template with categories/items.
- Publish/approve.
- Verify grouped response.
- Verify no weight/scoring UI.

## Verification

```powershell
cd server
mvn "-Dtest=PlatformTemplateCategoryIT,PlatformAdminPhase1IT,ArchitectureTest,SecurityEndpointInventoryIT,FlywayMigrationTest" test
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

```powershell
$env:LIVE_E2E="1"
$env:LIVE_E2E_EMAIL="admin@truereport.test"
$env:LIVE_E2E_PASSWORD="Truereport#Local123"
flutter test test/e2e/platform_admin_live_e2e_test.dart
```

## Acceptance Criteria

1. Template API returns ordered categories, each with its items.
2. Template builder UI shows categories with nested checklist items, not a flat list.
3. Categories and items can be added, removed, and reordered.
4. An item cannot be placed in the wrong category.
5. Categories with no included items are excluded.
6. Default `TPL-30-GCC` seed has 6 categories with all 30 items correctly grouped.
7. **No category weights, item weights, scoring rules, grade boundaries, score bands, weight previews, or scoring UI/API remain in Platform Admin.**
8. Published template versions remain immutable.
9. Backend tests, Flutter analyze/tests, and live E2E pass.
10. No phase-based naming; no production fakes.
11. Docs updated (`DECISIONS.md`, `MIGRATION.md`).

## Output Format

Report:
- Files changed.
- Schema/API changes.
- Removed scoring/weighting surface.
- Grouped template model and UI behavior.
- Tests/commands/results.
- Live E2E evidence.
- Remaining blockers.
