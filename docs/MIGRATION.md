# API & Schema Migration Notes

## Phase 1 — Platform Admin (rebuilt backend)

### Clean Platform Admin schema

New migrations:
1. `V100__platform_admin_clean_baseline.sql` — child configuration, languages, templates, scoring, document types, governance, outbox, idempotency, platform audit.
2. `V101__platform_clean_content.sql` — clean `platform_categories`, `platform_items`, `platform_item_versions`, `platform_guide_images`.
3. `V102__Migrate_platform_content.java` — copies legacy master content into the clean parent tables when present (no-op on a fresh DB).
4. `V103__platform_clean_content_constraints.sql` — adds foreign keys and drops `platform_category_config` / `platform_item_metadata`.
5. `V104__drop_legacy_template_fk` — vendor-specific H2/MySQL migration removing the legacy `template_items` FK to the old master version table. Workshop templates now pin clean UUIDs and snapshot the item rules.

Platform Admin content uses only:
- `platform_categories`
- `platform_items`
- `platform_item_versions`
- `platform_guide_images`
- child tables keyed by `item_version_id`

All Platform Admin IDs are UUIDv7 strings (`VARCHAR(36)`). Legacy BINARY(16) master IDs are converted to string UUIDs during `V102`. Legacy master tables remain only for the reference Workshop/Report application and are not read by Platform Admin configuration code.

### Data migration behavior

- If clean parent tables are empty, `V102` copies legacy categories, items, versions, labels/instructions, item metadata, weights and guide images.
- Existing child rows keep their `item_version_id` because version UUIDs are preserved as strings.
- Orphaned child rows are removed before foreign keys are added.
- On a fresh database `V102` performs no inserts; the seed endpoint populates the data.

### Seed

`POST /api/v1/platform/seed/default-checklist` is idempotent and writes only clean `platform_*` tables. It creates:
10 option sets, 6 categories (25/18/20/17/10/10), 30 items with score bands, evidence rules, measurement bands and issue fields, 5 document types, the GCC scoring rule with A/B/C/D boundaries, and `TPL-30-GCC`.

### Common language API

| Method | Path | Auth |
|---|---|---|
| GET | `/api/v1/i18n/languages` | **anonymous** |
| GET | `/api/v1/i18n/me` | authenticated |
| PUT | `/api/v1/i18n/me` | authenticated |

Platform language CRUD under `/api/v1/platform/i18n/**` remains Platform Admin only.

### Platform Admin endpoints

- Categories: CRUD, `GET /categories/weight-check`, `PUT /categories/reorder`.
- Items: list/detail/create/update, draft, metadata, bands, evidence rules, issue fields, measurement bands, publish, retire, reorder.
- Option sets and values: CRUD/reorder/retire with replacement.
- Global templates: versions, items, weight preview, publish/approve/reject/retire.
- Scoring rules, grade boundaries and approvals.
- Document types: CRUD/reorder/retire.
- Governance: config health, impact analysis, releases.
- Seed.

### Error contract

Errors include `code`, `messageKey`, `messageEn`, `messageAr`, localized `detail`, `traceId`, and `errors`/`fieldErrors`. Legacy `fieldErrors` remains for existing clients.

### Frontend

- `ApiClient` sends `Accept-Language` from the shared locale controller.
- Platform Admin screens are API-backed; production sample master data and workshop fallbacks were removed.
- Adaptive checks cover 360/600/768/1024/1440 px and Arabic RTL.
