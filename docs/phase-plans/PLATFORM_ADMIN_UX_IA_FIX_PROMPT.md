# Platform Admin UX / Information Architecture Fix — Prompt

You are fixing the **Platform Admin information architecture and UX** in:

`E:\syed_moiz_ali\bitlogix\truereport`

The implementation is functional, but the navigation and page structure are confusing. Master Library, Templates, Data Catalogues, Equipment, Config Health, Document Types, and Languages are presented as unrelated modules. They are not.

Do not redesign the sidebar/header visuals again. This is about **structure, labels, grouping, and page UX**.

## Read First

1. `docs/DECISIONS.md` (D-046, D-071, D-072, D-073)
2. `docs/PLATFORM_ADMIN_SCREEN_API_MATRIX.md`
3. `docs/FRONTEND_ADAPTIVE_RULES.md`
4. `docs/NAMING_AND_TESTING_RULES.md`
5. Current nav:
   `client/apps/platform_admin_app/lib/src/components/platform_nav.dart`
6. Current routes:
   `client/apps/platform_admin_app/lib/src/platform_router.dart`
7. Current screens:
   `client/apps/platform_admin_app/lib/src/features/**`

## Core Domain Understanding

- **Checklist Library** = the global catalog:
  - categories
  - checklist items
  - option sets
  - dynamic issue fields
  - evidence rules
  - measurement bands (status mapping only)
- **Template** = a named, ordered selection of categories and items from the Checklist Library.
  Example: “Comprehensive 30-Point GCC Standard”.
  Workshop Admin selects a template when creating a job.
- A template is built **from** the Checklist Library, so Templates should live **inside** the Checklist section, not as a separate top-level module.
- **Equipment** is not needed. Tool calibration/qualification was removed (D-046). The item’s `sensor/tool` is just descriptive text.
- **Data Catalogues** should not be a top-level module. Any still-needed reasons/option values belong under Checklist → Option Sets.
- **Config Health** is not a separate product area. It is a health/status view of the Checklist Library.
- **Document Types** belong under Reports.
- **Languages** belong under Settings.

## Target Navigation (Recommended)

Replace the current 10-item sidebar with 5 clear primary items:

1. **Workshops**
   - workshop hierarchy, staff/accounts
2. **Checklist**
   - Categories
   - Items
   - Templates
   - Option Sets
   - Health
3. **Reports**
   - Document Types
   - future report settings
4. **Audit Log**
5. **Settings**
   - General platform settings
   - Languages & Coverage

No `Master Library`, `Data Catalogues`, `Equipment`, `Config Health`, `Templates`, `Document Types`, or `Languages` as separate primary nav items.

### Route mapping

| Old route | New route / behavior |
|---|---|
| `/master-library` | `/checklist/items` |
| `/master-library/categories` | `/checklist/categories` |
| `/master-library/option-sets` | `/checklist/option-sets` |
| `/templates` | `/checklist/templates` |
| `/config-health` | `/checklist/health` |
| `/document-types` | `/reports/document-types` |
| `/languages` | `/settings/languages` |
| `/data-catalogues` | `/checklist/option-sets` or redirect |
| `/equipment` | redirect to `/checklist/items` (or remove) |

Add redirects from old routes so deep links don’t 404.

## Labels and Copy

Replace internal/technical labels with plain language:

- `Master Library` → `Checklist`
- `Master Items` → `Checklist Items`
- `Templates` → `Inspection Templates`
- `Option Sets` → `Issue Options`
- `Data Catalogues` → remove from nav
- `Equipment` → remove from nav
- `Config Health` → `Checklist Health`
- `Document Types` → `Report Documents`
- `Languages` → `Languages & Coverage`

Add short helper text on the Checklist page:

> The Checklist is the reusable master catalog. Templates are named sets of checklist categories and items that workshops select when creating jobs.

Add helper text on the Templates tab:

> A template is a reusable set of categories and items from the Checklist. Workshop Admin selects it when creating a job.

## Page Structure

### Checklist landing

A single page with tabs/segmented navigation:

```text
Checklist
[Categories] [Items] [Templates] [Issue Options] [Health]
```

- Default tab: Items.
- Tab state persists in the URL.
- Each tab uses the same page frame/header/toolbar.
- Health issues show as a banner on the Checklist landing page, not a separate module.

### Categories tab

- Cards/table: code, EN/AR name, item count, active state.
- Add/edit/reorder/retire.
- Clear empty state.

### Items tab

- Search, category filter, status filter, add item.
- Table/cards: code, EN/AR label, category, unit, safety badge, status, updated.
- Actions: edit, draft, publish, retire.
- No scoring/weight columns.

### Templates tab

- List: template name, code, version, status, category count, item count.
- Builder: category-first nested item checklists.
- No weights, no scoring, no weight preview.

### Issue Options tab

- Option sets and values.
- Add/edit/reorder/retire.
- Replace the old “Data Catalogues” concept.

### Health tab

- Checklist health checks (missing EN/AR, band gaps, retired references).
- Release lifecycle panel.
- Impact dialogs.
- Not a separate primary nav item.

### Reports

- `Document Types` under a Reports landing page.
- Future report settings can be added here.

### Settings

- General settings.
- Languages & Coverage.

## UX Rules

1. One primary action per page.
2. No duplicate concepts in the sidebar.
3. No developer-style module names.
4. No top-level tab for internal health/config checks.
5. Explain “Checklist vs Template” inline where needed.
6. Show human labels first; put codes in secondary/monospace text.
7. Hide technical fields behind an “Advanced” section.
8. Use tabs only for closely related content.
9. Keep URLs deep-linkable and redirect old paths.
10. Remove dead/legacy nav entries entirely.

## Removal Requirements

- Remove `Equipment` from Platform Admin nav, routes, and screens.
- Remove `Data Catalogues` from Platform Admin nav; merge any still-needed option values into Checklist → Issue Options.
- Remove `Config Health` as a top-level nav item; move it into Checklist → Health.
- Remove `Templates` as a top-level nav item; move it into Checklist → Templates.
- Remove `Document Types` as a top-level nav item; move it into Reports.
- Remove `Languages` as a top-level nav item; move it into Settings.
- Remove `Scoring` anywhere in Platform Admin (already removed; keep it removed).

Backend endpoints can remain for compatibility, but they must not appear as Platform Admin navigation or pages unless still needed.

## Remaining Fixes From Previous Review

Include these in the same pass:

1. **Remove hidden scoring fields**
   - Remove `defaultScore` from `platform_config_models.dart`.
   - Stop sending `defaultScore` from `master_item_editor_screen.dart`.
   - Remove unused `defaultScore`/`minScore`/`maxScore` ARB keys if no longer referenced.
   - If the backend still requires the field for compatibility, document it as a backend-only field and do not expose or send it from Platform Admin.

2. **Replace hardcoded demo identity**
   - Remove `Alex Vance` / `Principal Admin` from `workshop_details_screen.dart`.
   - Use real session/user data or neutral placeholders.

3. **Move hierarchy onto PlatformShell**
   - `hierarchy_screen.dart` must use `PlatformShell` instead of its own `Scaffold` + sidebar/header duplication.
   - Pass the context bar through `PlatformShell.contextBar`.
   - Ensure compact sidebar hiding and mobile nav work.

4. **Visual evidence**
   - Capture screenshots for every Platform Admin screen at 1280, 1440, 768, 360, and AR RTL.
   - Compare Checklist categories/items/templates/issue options/health against Figma screens 05–10.
   - Attach screenshots as evidence. Widget/overflow tests alone are not enough.

## Agentic Sub-Sessions

1. **IA/routing agent**
   - Owns `platform_nav.dart`, `platform_router.dart`, sidebar/nav entries.
   - Implements the 5-item navigation and redirects.
   - Removes old routes/nav.

2. **Checklist consolidation agent**
   - Owns `features/master_library/**`, templates, issue options, health.
   - Builds the tabbed Checklist page.
   - Moves/renames screens.

3. **Reports/Settings agent**
   - Owns document types, settings, languages.
   - Builds Reports and Settings landing pages.

4. **Cleanup agent**
   - Removes Equipment/Data Catalogues UI.
   - Removes `defaultScore`, hardcoded identity.
   - Moves hierarchy to `PlatformShell`.

5. **Verifier**
   - Runs analyze/tests, captures screenshots, checks redirects, RTL, compact.
   - Only the verifier claims completion.

## Tests

- Nav renders exactly 5 primary items.
- Old routes redirect to new routes.
- Checklist tabs: Categories, Items, Templates, Issue Options, Health.
- Templates live under Checklist, not primary nav.
- Equipment/Data Catalogues/Config Health/Document Types/Languages are not primary nav items.
- No scoring/weight/defaultScore UI or request fields.
- No hardcoded Alex Vance.
- Hierarchy uses PlatformShell and compact nav works.
- Screenshots at 1280/1440/768/360 + RTL for every screen.
- `flutter analyze --fatal-infos`.
- Full Platform Admin test suite.

## Acceptance Criteria

1. Sidebar has 5 clear items: Workshops, Checklist, Reports, Audit Log, Settings.
2. Checklist contains Categories, Items, Templates, Issue Options, Health.
3. Templates are clearly explained as sets built from the Checklist.
4. Equipment and Data Catalogues are gone from Platform Admin.
5. Config Health is inside Checklist, not a primary nav item.
6. Document Types are under Reports.
7. Languages are under Settings.
8. Old routes redirect; no 404s.
9. No scoring/weight/defaultScore remains in Platform Admin UI/API client.
10. No hardcoded Alex Vance.
11. Hierarchy uses PlatformShell.
12. Screenshots/goldens attached for all screens.
13. `flutter analyze --fatal-infos` and Platform Admin tests pass.

## Output Format

Report:
- New IA and route map.
- Removed/moved modules.
- Files changed.
- Remaining fixes completed.
- Responsive/RTL results.
- Commands/results.
- Screenshot evidence.
- Remaining blockers.
