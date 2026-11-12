# Platform Admin UX v2 + Dynamic Language Architecture — Prompt

You are fixing the Platform Admin UX and multi-language architecture in:

`E:\syed_moiz_ali\bitlogix\truereport`

The current implementation is functional but the UX is not acceptable. Do not add more panels to the existing structure. Restructure the product around the actual jobs-to-be-done.

## Read First

1. `docs/DECISIONS.md` (D-046, D-071, D-072, D-073, D-074)
2. `docs/I18N_PLAN.md`
3. `docs/FRONTEND_ADAPTIVE_RULES.md`
4. `docs/NAMING_AND_TESTING_RULES.md`
5. `docs/PLATFORM_ADMIN_SCREEN_API_MATRIX.md`
6. Current nav/routes:
   - `client/apps/platform_admin_app/lib/src/components/platform_nav.dart`
   - `client/apps/platform_admin_app/lib/src/platform_router.dart`
7. Current screens:
   - `client/apps/platform_admin_app/lib/src/features/**`
8. Current localization backend:
   - `server/src/main/java/com/truereport/localization/**`
   - `server/src/main/java/com/truereport/masterdata/config/**`

## Core Problems

1. **Hierarchy is unnecessary.** Remove the hierarchy tree concept entirely.
2. **Workshops needs a real Dashboard + Workshops CRUD.** Not a tree, not a split board.
3. **Checklist Items look like plain text.** They must look and feel like actual checklist rows/cards.
4. **Category chips are unusable at 30–40 categories.** They wrap into 5–6 rows. Replace with a scalable filter.
5. **Templates are created via a dialog and are not explained.** Templates need a full-screen builder and guided UX.
6. **Add Item / Add Option dialogs are not usable.** Replace with proper screens/drawers and progressive disclosure.
7. **“Load default” button is confusing.** Remove it from the main UI.
8. **Language support is hardcoded to EN/AR.** Future languages (Chinese, Russian, etc.) must be addable without code changes.

## Target Navigation

Exactly 6 primary items:

1. **Dashboard**
2. **Workshops**
3. **Checklist**
4. **Reports**
5. **Audit Log**
6. **Settings**

Remove:
- Hierarchy
- Master Library (rename to Checklist)
- Templates as a primary item
- Data Catalogues
- Equipment
- Config Health as a primary item
- Document Types as a primary item
- Languages as a primary item

## 0. Dashboard vs Workshops Must Be Separate

These are two different tabs with different jobs:

- **Dashboard** = read-only overview and analytics. No workshop CRUD tables, no edit forms.
- **Workshops** = operational CRUD. No dashboard KPI cards/charts.

Do not mix them. Do not put workshop list/edit inside Dashboard. Do not put analytics cards inside Workshops.

## 1. Dashboard

Build a real Platform Admin dashboard, fully data-driven, read-only, and advanced.

Sections:
- KPI cards: total workshops, active workshops, total technicians, active jobs, published reports, pending reviews, checklist health, languages live/translating.
- Charts/visual summaries: jobs by status, reports by month, checklist coverage, workshop activity trend.
- Recent activity: audit events.
- Alerts: checklist health issues, unpublished reports, failed report generation, languages with incomplete translations.
- Quick actions: add workshop, add checklist item, create template, manage languages — these navigate to the respective tabs, they do not open CRUD forms inside Dashboard.
- Filters: date range, workshop, status.
- Drill-down: clicking a KPI/chart navigates to the relevant filtered tab.

Rules:
- No fake/hardcoded metrics.
- Loading/empty/error states.
- Each KPI links to the relevant page.
- API-driven; add dashboard aggregation endpoints if needed.
- Dashboard must remain useful with zero data (empty state explains what to do first).
- No CRUD tables/forms on Dashboard.

## 2. Workshops

Replace hierarchy with a proper Workshops list + detail CRUD. No dashboard analytics on this tab.

### Workshops list
- Table on desktop, cards on compact.
- Search by name/branch/status.
- Filters: status, region/branch.
- Columns/card fields: name, branch, status, staff count, technician count, created date, actions.
- Primary action: Add workshop.
- Actions: view, edit, deactivate/reactivate.
- Empty/loading/error states.

### Workshop detail
- Header: workshop name, status, branch, edit/deactivate.
- Tabs:
  - Overview (details, capacity, contact)
  - Staff (admins/technicians list, add staff)
  - Templates (workshop-visible templates)
  - Activity (audit events)
- No hierarchy tree, no split-board node navigator.

### Remove hierarchy
- Remove hierarchy routes, nav, screens, widgets, tests, and related breadcrumb copy.
- Remove hierarchy-specific APIs from the UI if no longer used.
- Keep workshop CRUD/API and staff APIs.

## 3. Checklist

Structure:

```text
Checklist
[Categories] [Items] [Templates] [Issue Options] [Health]
```

### Items tab — must look like checklist items

Do not render plain text rows.

Each item row/card must show:
- item code (monospace/secondary)
- EN label + AR label (resolved label primary)
- category badge
- unit
- safety-critical badge
- evidence summary (photos/videos/notes)
- status badge (Draft/Published/Retired)
- updated date
- actions (edit, draft, publish, retire)

Visual treatment:
- Card/table row with icon, labels, metadata pills, actions.
- Desktop: table-like rows with strong information hierarchy.
- Compact: cards.
- Use `PlatformSectionCard` and shared chips.

### Category filter — no chip wall

Replace the 30–40 chips with:
- A single category dropdown/combobox with search.
- Optional “All categories” default.
- Selected category shown as one removable chip.
- Result count.
- Optional secondary quick filters (status, safety) as dropdowns.
- Never wrap dozens of category chips into multiple rows.

### Add Item — full screen, not a giant dialog

Use a guided full-screen page/stepper:

1. Basics (code, category, unit, sensor/tool, sort order, safety, multi-point, max tyre age, free-text)
2. Content (language tabs, see dynamic language section)
3. Issue Options (fields/options/dependencies)
4. Evidence Rules
5. Measurement Bands (status mapping only, no scores)
6. Review & Publish

Rules:
- Explain each step briefly.
- Inline validation.
- Save draft at any step.
- No scoring/weight fields.

## 4. Templates

### Templates list
- Name, code, version, status, category count, item count, updated.
- Actions: open builder, duplicate, retire.
- Primary action: Create template.

### Create template — full-screen builder, not a dialog

Replace the modal dialog with a dedicated screen:

1. Template details (code, names, description)
2. Add categories from Checklist
3. Add items inside each category
4. Order categories and items
5. Review & Save Draft / Publish

Builder UX:
- Category sections with nested item checklists (D-071).
- Add category: searchable picker, not a wall of chips.
- Add item: searchable picker inside the category.
- Explain: “A template is a reusable set of checklist categories and items. Workshop Admin selects it when creating a job.”
- Empty state with clear CTA.
- Inline help/tooltips.
- Progress summary: categories, items.
- No weights, no scoring, no weight preview.

## 5. Issue Options

Improve the current good-but-basic screen:
- Master-detail: option set list on left, values table on right.
- Search and counts.
- Add option set: full screen/drawer with code, names, description.
- Add value: inline row editor with EN/AR/other language tabs, metadata, reorder.
- Retire-in-use with replacement mapping.
- Empty states and helper text explaining where options are used.

## 6. Remove “Load default” button

- Remove the seed/load-default button from the main Checklist UI.
- Seed remains available through CLI/migration or an advanced Settings/Dev section only.
- Never expose a destructive/large seed action as a normal primary button.

## 7. Dynamic Language Architecture (critical)

Current UI assumes EN/AR labels everywhere. Future languages must be addable without code changes.

### 7.1 Language lifecycle

A language is not “live” just because it was added to the registry.

```text
DRAFT → TRANSLATING → REVIEW → LIVE → RETIRED
```

- `DRAFT`: language exists in Platform Admin only; not shown to Workshop/Technician/public.
- `TRANSLATING`: translation backlog exists for live content; admin is filling labels.
- `REVIEW`: translations complete; waiting for approval/publish.
- `LIVE`: language is fully translated and selectable in all apps.
- `RETIRED`: hidden from new selections; existing snapshots keep their text.

A language only becomes LIVE when required translations for existing live content are approved.

### 7.2 Adding a new language later (e.g. Chinese)

This is the required workflow:

1. Platform Admin adds `zh-Hans` in Settings → Languages & Coverage.
   - Status becomes `DRAFT`.
   - It is **not** shown in Technician/Workshop/public language selectors yet.
2. The system creates a translation backlog for all **live** content:
   - categories
   - checklist items
   - issue option sets and values
   - templates (including existing published templates)
   - document types
   - issue field labels/help text
   - grade labels / report labels where applicable
3. Admin fills Chinese translations for those existing entities.
   - Content forms show a Chinese tab/field automatically.
   - A translation work queue shows missing items by entity type.
4. Coverage dashboard shows:
   - translated / total per entity type
   - missing labels
   - templates missing Chinese
5. Admin reviews and approves translations.
6. Admin clicks **Publish/Activate language**.
   - Validation requires required content coverage (100% for live content, or a documented configurable threshold).
7. Status becomes `LIVE`.
8. Chinese now appears automatically:
   - Technician app language selector
   - Workshop Admin
   - Public report language toggle
   - Emails/PDF where language is supported
   - all dynamic labels

No code changes, redeploy, or app update is required to add a language.

### 7.3 What “live content” means for language activation

Language activation is blocked until the following live/published content has translations:

- all active categories
- all published items
- all active option sets/values used by published items
- all published templates (category and item labels)
- all active document types
- all active issue field labels
- required UI/report message bundles for that language

Draft/retired content does not block activation.

### 7.4 Existing templates

- Adding a language to an existing published template must not change its structure.
- Translations are added as a localized revision/overlay for the same template version.
- Existing jobs and published reports keep their original snapshot text.
- New jobs created after the language is LIVE snapshot the Chinese labels.
- If the template structure changes, create a new template version as usual.

### 7.5 Target API model

Admin APIs return all translations and their status:

```json
{
  "code": "ENG-OIL-01",
  "translations": {
    "en": { "label": "Engine Oil Condition & Level", "status": "APPROVED" },
    "ar": { "label": "حالة ومستوى زيت المحرك", "status": "APPROVED" },
    "zh-Hans": { "label": "发动机机油状况与液位", "status": "TRANSLATING" }
  },
  "label": "Engine Oil Condition & Level",
  "labelLocale": "en",
  "fallbackLocale": "en"
}
```

User-facing APIs return only LIVE languages:

```json
{
  "code": "ENG-OIL-01",
  "translations": {
    "en": { "label": "Engine Oil Condition & Level" },
    "ar": { "label": "حالة ومستوى زيت المحرك" }
  },
  "label": "Engine Oil Condition & Level",
  "labelLocale": "en",
  "fallbackLocale": "en"
}
```

- `translations` is keyed by language code.
- `label` is resolved for the request language.
- Fallback order: requested live language → default language → English.
- Flutter models must not hardcode `labelEn`/`labelAr`; use `translations` + resolved `label`.
- Flutter forms render one tab/field per language in the admin’s language registry, with translation status.
- Category, item, option set/value, template, document type, grade label, and issue field labels all use the same translations map.

### 7.6 Translation status per entity/locale

Track per-field or per-entity:

- `MISSING`
- `DRAFT`
- `TRANSLATING`
- `REVIEWED`
- `APPROVED`

Language activation requires all required fields to be `APPROVED`.

### 7.7 Backend changes

- Add translation CRUD endpoints for categories/items/options/templates/document types/issue fields.
- Add language activation/publish endpoint:
  - `POST /api/v1/platform/i18n/languages/{code}/publish` or `/activate`
  - validates coverage and required content.
- Add translation backlog/coverage endpoints:
  - `GET /api/v1/platform/i18n/languages/{code}/backlog`
  - `GET /api/v1/platform/i18n/coverage?language=zh-Hans`
- Remove enforcement of fixed `nameEn/nameAr` or `labelEn/labelAr` where translations map is used.
- Keep existing EN/AR columns only as compatibility/backfill; gradually migrate.
- Snapshot all LIVE languages at job/finalize/publish.
- Never expose translating languages to Workshop/Technician/public.

### 7.8 Seed

- Seed EN + AR as LIVE.
- Do not seed Chinese as live.
- Provide a test fixture for `zh-Hans` to prove the workflow without shipping it live.

### 7.9 Dedicated Translation Queue screen (required)

After adding a language, the admin must have **one separate screen** that shows everything needed to complete that language. They must not have to visit Categories, Items, Templates, etc. one by one.

Route:
- `/settings/languages/{code}/translations`

Entry points:
- Settings → Languages & Coverage → language row action **Complete translations**.
- Dashboard alert: “Chinese translation incomplete” → opens this screen.
- Coverage card → language → complete translations.
- Language activation/publish is blocked until this screen shows 100% required coverage.

Screen layout:
- Header: language code, native name, status, coverage %, required-content progress, Primary action **Publish language** (disabled until complete).
- Summary cards: Missing, Draft, Reviewed, Approved, Total required.
- Filters:
  - entity type: Categories, Items, Templates, Option Sets, Document Types, Issue Fields, Report Labels
  - category/template filter
  - search
  - show only missing / all
- Grouped list by entity type:
  - each row: entity name/code, default-language text, current translation (if any), translation status, edit action.
  - template rows expand to their categories/items.
  - option set rows expand to values.
  - issue field rows show label + help text.
- Editing:
  - inline side panel or modal with default text, translation field, status (Draft/Reviewed/Approved), save.
  - next/previous navigation through the queue.
  - no need to leave the screen.
- Bulk actions:
  - save all drafts
  - mark selected reviewed/approved
  - export missing translations to CSV/JSON (optional; no LLM)
- Completion:
  - progress bar and per-entity counts.
  - when required live content is 100% approved, **Publish language** becomes enabled.
  - publishing sets language to LIVE and makes it appear in all apps.
- New content after language is LIVE:
  - publishing new categories/items/templates/options/doc types must include translations for all LIVE languages.
  - missing translations block publish and appear in this queue.
- Empty/loading/error states.
- Compact: cards and stacked filters; no horizontal overflow.
- RTL-safe.

This screen is the **single source of truth for completing a language**; content editors can still show per-language tabs, but the queue is the primary workflow.

## UX Rules

- No walls of chips.
- No hierarchy tree.
- One primary action per page.
- Explain unfamiliar concepts inline (Template vs Checklist).
- Progressive disclosure: advanced fields hidden behind “Advanced”.
- Empty states with CTA.
- Loading skeletons, not full-page spinners.
- Confirm destructive actions.
- No dead buttons.
- No hardcoded demo data.
- No scoring/weight UI.

## Agentic Sub-Sessions

1. **IA/routing/nav agent**
   - Dashboard, Workshops, Checklist, Reports, Audit, Settings only.
   - Remove hierarchy routes/screens.
   - Add redirects.

2. **Dashboard agent**
   - Build dashboard + aggregation APIs/providers.

3. **Workshops CRUD agent**
   - Workshops list + detail tabs + staff CRUD.
   - Remove hierarchy widgets/tests.

4. **Checklist Items agent**
   - Item list/card design, category dropdown/search, add-item stepper.

5. **Templates agent**
   - Full-screen builder, guided flow, category-first nested items.

6. **Options agent**
   - Improved master-detail option UX.

7. **Dynamic language agent**
   - Backend translation model/APIs + Flutter dynamic language fields/models.
   - Implements the dedicated Translation Queue screen at `/settings/languages/{code}/translations`.
   - Highest-risk workstream; integrate last with all content screens.

8. **Verifier**
   - Analyze/tests/screenshots at 1280/1440/768/360 + RTL + a future-language fixture (e.g. zh-Hans).
   - Only the verifier claims completion.

## Tests

- Nav has exactly Dashboard, Workshops, Checklist, Reports, Audit Log, Settings.
- Hierarchy routes/screens removed; old routes redirect.
- Dashboard uses real API data; no fake metrics.
- Workshops CRUD works; detail tabs work.
- Items tab has scalable category filter, not chip wall.
- Add Item stepper works and validates.
- Template create is a full-screen guided builder.
- Issue Options master-detail works.
- Load default button removed from main UI.
- Dashboard and Workshops are separate tabs:
  - Dashboard has no workshop CRUD tables/forms.
  - Workshops has no dashboard KPI/chart cards.
- Dynamic language:
  - Add a test language (`zh-Hans` fixture) as `DRAFT`.
  - Language is not shown in user-facing selectors while DRAFT/TRANSLATING.
  - Backlog is created for all live categories, items, options, templates, document types, issue fields.
  - Content forms show a Chinese tab with translation status.
  - Activation is blocked until required live content is translated/approved.
  - A dedicated Translation Queue screen shows all missing translations grouped by entity type.
  - Admin can complete a language there without visiting Categories/Items/Templates individually.
  - `Publish/Activate language` makes it LIVE and visible in user-facing selectors.
  - API returns translations map; admin sees all statuses, user APIs only LIVE languages.
  - Fallback order works.
  - Coverage includes the new language.
  - Existing published reports/jobs keep old snapshot text; new jobs snapshot the new language.
  - Publishing new content while a language is LIVE requires translations for that language.
- No EN/AR hardcoding in new content models.
- No scoring/weight/defaultScore UI/API fields.
- Screenshots for every screen at all sizes + RTL + zh-Hans fixture.
- `flutter analyze --fatal-infos`.
- Full Platform Admin tests.

## Acceptance Criteria

1. 6 primary nav items only: Dashboard, Workshops, Checklist, Reports, Audit Log, Settings.
2. Hierarchy is fully removed.
3. Dashboard is advanced, data-driven, read-only, with KPIs, activity, alerts, quick actions; no workshop CRUD.
4. Workshops is a separate tab with list + detail CRUD and staff; no dashboard KPI/chart cards.
5. Checklists Items look like real checklist rows/cards, not plain text.
6. Category filter scales to 30–40+ categories without chip walls.
7. Add Item is a full-screen guided stepper.
8. Templates use a full-screen guided builder with category-first nested items.
9. Issue Options has a proper master-detail UX.
10. “Load default” is removed from the main UI.
11. Languages are dynamic:
    - add `zh-Hans` via language API as DRAFT
    - a translation backlog is created for all live categories, items, options, templates, document types, issue fields
    - content forms show a Chinese tab with translation status
    - a dedicated Translation Queue screen (`/settings/languages/{code}/translations`) lists everything missing, grouped by entity type, with inline editing
    - admin can complete the language entirely from that screen without visiting individual editors
    - language activation is blocked until required live content is translated/approved
    - publishing the language makes it LIVE and visible in Technician/Workshop/public selectors
    - admin APIs return all translations/statuses; user APIs return only LIVE languages
    - fallback/coverage work
    - existing reports keep old snapshots; new jobs include the new language
    - no code changes needed.
12. No scoring/weight/defaultScore UI/API fields in Platform Admin.
13. No hardcoded demo identity/data.
14. Screenshots attached for all screens at all sizes + RTL + zh-Hans.
15. `flutter analyze --fatal-infos` and Platform Admin tests pass.

## Output Format

Report:
- New IA/route map.
- Dashboard/Workshops/Checklist/Templates/Options changes.
- Dynamic language architecture and migration.
- Files changed.
- Removed modules.
- Commands/results.
- Screenshot evidence.
- Remaining blockers.
