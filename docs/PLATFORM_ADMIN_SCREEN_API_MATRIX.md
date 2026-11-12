# Platform Admin Screen -> API Matrix

Verified against the running backend (`http://localhost:8080`, local MySQL,
`dev` profile) and the Flutter Platform Admin app. Status values:

- **Wired** - screen loads from and writes through the real API.
- **Fixed** - was missing or incomplete during this pass; now wired.
- **Verified** - exercised through the UI against the live backend.

| Screen | UI actions | API endpoints | Table(s) | Status |
|---|---|---|---|---|
| Checklist › Items (`/checklist/items`) | list/search/filter/seed | `GET /api/v1/platform/master/items`, `GET /api/v1/platform/master/categories`, `POST /api/v1/platform/seed/default-checklist` | `platform_items`, `platform_categories` | Verified |
| Checklist › Categories (`/checklist/categories`) | list/create/edit/reorder/retire | `GET/POST /api/v1/platform/master/categories`, `PUT /categories/{id}`, `PUT /categories/reorder`, `POST /categories/{id}/retire` | `platform_categories` | Verified (no weights) |
| Items | list/search/filter/create/edit/draft/publish/retire/reorder | `GET/POST /items`, `GET /items/{id}`, `POST /items/{id}/versions`, `PUT .../translations/{locale}`, `PUT .../metadata`, `POST .../publish`, `POST /items/{id}/retire`, `PUT /items/reorder` | `platform_items`, `platform_item_versions` | Verified |
| Evidence Rules | per status photo/video/note/type | `GET/PUT /items/{id}/versions/{versionId}/evidence-rules` | `platform_evidence_rules` | Verified |
| Issue Fields | add/edit/reorder fields, dependency, option subset, required-for-status | `GET/PUT .../issue-fields` | `platform_issue_fields`, `platform_issue_field_options` | Verified |
| Measurement Bands | field/unit/direction/range/result | `GET/PUT .../measurement-bands` | `platform_measurement_bands` | Verified |
| Checklist › Issue Options (`/checklist/option-sets`) | set/value create/edit/reorder/retire | `/api/v1/platform/master/option-sets` CRUD, values, reorder, retire | `platform_option_sets`, `platform_option_values`, `platform_issue_field_options` | Verified |
| Checklist › Inspection Templates (`/checklist/templates`, builder `/checklist/templates/:id`) | list/create/rename/draft/categories/items/reorder/publish/approve/reject/retire | `/api/v1/platform/master/templates`, `GET /{id}`, `GET /{id}/versions/{versionId}`, `PUT .../categories`, `PUT .../items`, `POST .../publish`, `POST .../approve`, `POST .../reject`, `POST /{id}/retire` | `platform_templates`, `platform_template_versions`, `platform_template_categories`, `platform_template_items` | Fixed + Verified (category-first) |
| Reports › Report Documents (`/reports/document-types`) | list/create/edit/reorder/retire | `/api/v1/platform/document-types` | `platform_document_types` | Wired |
| Settings › Languages (`/settings/languages`) | list/create/edit/activate/deactivate/reorder/default/coverage | `GET /api/v1/i18n/languages`, `/api/v1/platform/i18n/languages` CRUD/reorder/default, `/coverage` | `platform_languages` | Wired |
| Checklist › Health (`/checklist/health`) incl. Impact / Releases | health dashboard, impact dialog, release lifecycle | `/api/v1/platform/config-health`, `/master/{entityType}/{id}/impact`, `/releases` + transitions | `platform_releases` | Wired |
| Audit Log | list audit events | `/api/v1/platform/audit-events` | `platform_audit_events` | Verified |
| Workshops (`/workshops`, create `/workshops/new`, detail `/workshops/:id`) | list/search/filter/add/edit/deactivate/reactivate | `GET /api/v1/platform/workshops`, `POST .../workshops` (register), `PUT /api/v1/platform/workshops/{id}` `{name?,location?,contactEmail?}`, `POST .../{id}/deactivate` `{reason?}`, `POST .../{id}/reactivate` `{reason?}` → workshop JSON | `workshops` | Wired |
| Dashboard (`/dashboard`) | read-only overview KPIs, activity, alerts | `GET /api/v1/platform/overview` → `{workshops,staff,jobs,reports,checklist,languages,recentActivity[≤8],alerts}` (counts only, defensive, never 500) | all `platform_*` + `platform_audit_events` | Wired |
| Settings › Languages (`/settings/languages`) | list/create/status/activate/deactivate/reorder/default/coverage | `GET /api/v1/i18n/languages` (public, LIVE only), `/api/v1/platform/i18n/languages` CRUD + `POST /languages/{code}/status` `{status}` (DRAFT → TRANSLATING → REVIEW → LIVE → RETIRED; forward-only + any → RETIRED + RETIRED → DRAFT reopen) | `platform_languages` (`status`; create forces DRAFT + inactive; upsert auto-moves DRAFT → TRANSLATING; `setMyLanguage` + public list expose LIVE only) | Wired |
| Settings › Languages › Translations (`/settings/languages/{code}/translations`) | translation work queue, inline edit, publish | `PUT /api/v1/platform/i18n/translations` `{entityType,entityId,field,language,text,status?}` → `{entityType,entityId,entityCode,field,defaultText,text,status}`; `GET /api/v1/platform/i18n/languages/{code}/backlog` → `{language,totalRequired,approvedCount,coveragePercent,groups[]}` (LIVE content only); `GET /api/v1/platform/i18n/coverage?language={code}` → `{language,totalRequired,approvedCount,coveragePercent,byEntity}`; `POST /api/v1/platform/i18n/languages/{code}/publish` → `{code,status,coveragePercent}` (422 `TRANSLATION_REQUIRED` below 100% APPROVED) | `platform_translations` overlay (entity types: CATEGORY, ITEM, OPTION_SET, OPTION_VALUE, TEMPLATE, DOCUMENT_TYPE, ISSUE_FIELD; translation statuses DRAFT, TRANSLATING, REVIEWED, APPROVED; MISSING computed, never stored) | Wired |
| Legacy redirects (no screens) | `/` → `/dashboard`; `/workshops/add-staff` → `/workshops`; `/workshops/register` → `/workshops/new`; `/workshops/details?id=X` → `/workshops/X`; `/master-library*` → `/checklist/*`; `/templates*` → `/checklist/templates*`; `/config-health` → `/checklist/health`; `/document-types` → `/reports/document-types`; `/languages` → `/settings/languages`; `/data-catalogues` → `/checklist/option-sets`; `/equipment` → `/checklist/items` | — | — | Wired |

## Translation gating (backend-only, no new screen)

- While a non-`en`/`ar` language is LIVE, publishing items/templates and creating categories/items/templates/option sets/values/document types requires approved overlay text for that language, else 422 `TRANSLATION_REQUIRED`. With only `en`/`ar` LIVE the gate is a no-op (EN+AR required as before).
- Existing `TRANSLATION_REQUIRED` publish validation for EN+AR labels/instructions is unchanged.

## Removed from Platform Admin

- Scoring screen, route and navigation entries.
- Category weights, item weights and weight validation.
- Item score bands and default scores.
- Scoring rules and grade boundaries.
- Template weight preview and overrides.
- `weight-check`, `bands`, `weight-preview` and `scoring-rules` APIs.

## Template structure

A template version owns ordered categories. Each category owns ordered items:

```
Template
  Category A (order)
    Item 1
    Item 2
  Category B (order)
    Item 3
```

- Categories with zero included items are excluded.
- Every item must belong to its category's master category.
- Duplicate categories/items are rejected.
- Published template versions are immutable.
- Maker-checker still applies to template publication.

## Authentication

- Platform login and Workshop login have no demo bypass or quick-fill control.
- Invalid credentials return `401`, show the localized error, and do not navigate.
- `setDemoSession` was removed from the production auth package.
- Live E2E reads `LIVE_E2E_EMAIL` / `LIVE_E2E_PASSWORD` (plus optional second
  admin variables); it fails clearly when they are missing.
