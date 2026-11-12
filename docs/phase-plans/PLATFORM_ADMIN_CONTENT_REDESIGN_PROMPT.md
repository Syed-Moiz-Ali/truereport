# Platform Admin Page Content / Cards Redesign — Prompt

You are redesigning the **Platform Admin page content system** in:

`E:\syed_moiz_ali\bitlogix\truereport`

Sidebar, header/top bar, and context bar are already redesigned. Do not redesign them again.

This task is about the **pages inside the shell**: page headers, toolbars, filters, cards, tables, forms, empty/loading/error states, and dialogs.

## Read First

1. Figma screen previews:
   - `docs/ui/figma-export/platform_admin_figma/screens/05_5._Shared_Master_Inspection-Item_Library/5._Shared_Master_Inspection-Item_Library@2x.png`
   - `docs/ui/figma-export/platform_admin_figma/screens/06_6._Master_Item_Content_&_Translation_Editor/6._Master_Item_Content_&_Translation_Editor@2x.png`
   - `docs/ui/figma-export/platform_admin_figma/screens/07_7._Master_Dropdowns_&_Data_Catalogues/7._Master_Dropdowns_&_Data_Catalogues@2x.png`
   - `docs/ui/figma-export/platform_admin_figma/screens/08_8._Global_Equipment_Library/8._Global_Equipment_Library@2x.png`
   - `docs/ui/figma-export/platform_admin_figma/screens/09_10._Platform_Audit_Events_Log/10._Platform_Audit_Events_Log@2x.png`
   - `docs/ui/figma-export/platform_admin_figma/screens/10_9._Global_Platform_Settings/9._Global_Platform_Settings@2x.png`
2. Figma implementation guide:
   `docs/ui/figma-export/platform_admin_figma/IMPLEMENTATION_GUIDE.txt`
3. Current shell/components:
   - `client/apps/platform_admin_app/lib/src/components/platform_shell.dart`
   - `client/apps/platform_admin_app/lib/src/components/platform_header.dart`
   - `client/apps/platform_admin_app/lib/src/components/platform_sidebar.dart`
   - `client/apps/platform_admin_app/lib/src/components/platform_nav.dart`
   - `client/apps/platform_admin_app/lib/src/components/platform_context_bar.dart`
4. Current pages:
   - `client/apps/platform_admin_app/lib/src/features/master_library/**`
   - `client/apps/platform_admin_app/lib/src/features/templates/**`
   - `client/apps/platform_admin_app/lib/src/features/documents/**`
   - `client/apps/platform_admin_app/lib/src/features/languages/**`
   - `client/apps/platform_admin_app/lib/src/features/governance/**`
   - `client/apps/platform_admin_app/lib/src/features/catalogues/**`
   - `client/apps/platform_admin_app/lib/src/features/equipment/**`
   - `client/apps/platform_admin_app/lib/src/features/audit/**`
   - `client/apps/platform_admin_app/lib/src/features/settings/**`
5. `docs/FRONTEND_ADAPTIVE_RULES.md`
6. `docs/NAMING_AND_TESTING_RULES.md`
7. `docs/DECISIONS.md` (D-048, D-056, D-071, D-072, D-073)
8. `docs/PLATFORM_ADMIN_SCREEN_API_MATRIX.md`

## Important Domain Rules

- Templates are **category-first**: ordered categories, each containing ordered checklist items.
- Platform Admin has **no weights, scoring rules, grade boundaries, score bands, weight previews, or scoring UI** (D-071/D-072).
- No scoring screen or nav item exists.
- Do not reintroduce weight/score UI in any page.
- Do not redesign sidebar/header/context bar; only use them.

## Goal

Make every Platform Admin page look like a coherent enterprise product based on the Figma screens, not improvised layouts.

The pages must share:

- one page frame
- one page header pattern
- one toolbar/filter pattern
- one card/table pattern
- one form-control pattern
- one dialog pattern
- one empty/loading/error state pattern
- one typography/spacing rhythm

Work one screen at a time. Do not attempt all pages in one massive edit without verification.

## Shared Page System

Build or standardize reusable components:

### `PlatformPage`
- Top-aligned content.
- Max width ~1240.
- Desktop padding 28–32px; compact 16px.
- Consistent bottom padding.
- No vertical centering.

### `PlatformPageHeader`
- Title: 24px, w800, ink, tracking -0.4.
- Subtitle: 13px, w400, muted, max 2–3 lines.
- Actions: primary filled button first, secondary outlined/text buttons next.
- Compact: stack title and actions; actions wrap.

### `PlatformToolbar`
- Search field, filter chips/dropdowns, count summary, primary action.
- Sticky or normal based on page; keep consistent.
- Compact: wrap controls, search full width.
- No fixed-width controls.

### `PlatformSectionCard`
- White, radius 14, border `PtTheme.border`, subtle shadow.
- Padding 20–24.
- Section title 16px w700.
- Optional header action.

### `PlatformDataTable` / `PlatformCardList`
- Desktop: table with header row, row hover, actions at end.
- Compact: cards instead of horizontal overflow where practical.
- Sticky header optional.
- Empty state inside the same card frame.
- Row density consistent; no random heights.

### `PlatformDialog`
- Use the global dialog theme.
- Title 18px w800.
- Content padding consistent.
- Actions: Cancel (text/outlined), Primary (filled).
- Max width 560 for forms; wider only for complex editors.
- Scrollable content.
- No raw `AlertDialog` styling scattered across pages; use a shared wrapper.

### States
- Loading: skeleton/spinner inside the content frame, not a centered full-screen jump.
- Empty: icon + title + body + optional action.
- Error: inline card with retry.
- Disabled actions explain why.
- No layout shift between states.

## Screen Order and Work

### 1. Master Library list (Figma screen 05)

- Page header: title, subtitle, primary “Add item”, optional seed/import action.
- Toolbar: search, category filter chips, status filter, result count.
- Content: item list as cards or table matching Figma.
- Row/card: code, EN/AR labels, category, unit, safety badge, status, updated date, actions.
- Actions: edit, draft, publish, retire, reorder.
- Empty/loading/error states.
- Compact: cards, filters wrap.
- Do not add weights/scores.

### 2. Master Item Editor (Figma screen 06)

- Page header with item code/name and publish/draft status.
- Sections:
  - Basics: code, category, unit, sensor/tool, sort order, safety, multi-point, max tyre age, free-text.
  - English content.
  - Arabic content.
  - Dynamic issue fields with allowed values/dependencies.
  - Evidence rules.
  - Measurement bands (status mapping only, no score fields).
  - Guide image.
- No score bands / weights / scoring.
- Sticky footer or header actions: Cancel, Save draft, Publish.
- Inline validation errors from server.
- Compact: single column, sections stack.

### 3. Categories + Option Sets

- Categories: table/cards, add/edit/reorder/retire, item count, active state.
- Option Sets: master-detail layout, set list + values table, add/edit/reorder/retire.
- No weight fields.
- Confirm before retire-in-use.
- Empty states for no categories/sets/values.

### 4. Templates + Template Builder

- Templates list: name, code, version, status, category count, item count, actions.
- Builder:
  - Category sections in order.
  - Nested item checklists.
  - Add/remove/reorder categories and items.
  - Item count per category; no weight preview.
  - Draft/publish/approve/reject actions.
  - Empty category state.
- No flat selected-item list as primary UI.
- No weight/score UI.

### 5. Document Types

- Table/cards: code, EN/AR name, required, active, order.
- Add/edit/reorder/retire.
- Consistent empty/loading/error states.

### 6. Languages + Coverage

- Language registry table/cards.
- Add/edit, activate/deactivate, default, reorder.
- Coverage section as a clear table/cards.
- No fixed widths; compact cards.

### 7. Config Health

- Health summary cards.
- Issue list grouped by severity/entity.
- Release lifecycle panel.
- Impact dialog with consistent `PlatformDialog`.
- Not a wall of raw text.

### 8. Data Catalogues / Equipment / Audit / Settings (Figma screens 07–10)

- Bring them onto the same page system.
- Data Catalogues: tabs/sections per dropdown, inline add/edit/reorder.
- Equipment: table/cards, add/edit/retire.
- Audit: filter bar, table/cards, empty state.
- Settings: grouped setting cards with consistent controls and save bars.
- No hardcoded sample data in production.

## Visual Rules

- Use `PtTheme` tokens; no new raw colors.
- Typography hierarchy:
  - page title 24 w800
  - section title 16 w700
  - body 13 w400
  - label 12 w600
  - caption 11 w500
- Buttons: primary filled deep green, secondary outlined, destructive rose.
- Consistent 8/10/14/20/28 spacing scale.
- Cards: radius 14, border, subtle shadow.
- Chips: 9999 radius, 11–12px labels.
- Inputs: 10px radius, 44px height, consistent focus ring.
- No thin/random font weights.
- No centered page bodies.
- No fixed page/card widths or heights.
- No absolute Figma-frame nesting.

## Responsive Rules

- 360, 600, 768, 1024, 1440.
- Desktop: table + sidebar.
- Tablet: compact table/cards; filters wrap.
- Mobile: cards, stacked forms, full-width actions, scrollable dialogs.
- RTL: directional padding, mirrored layouts, no overflow.
- No fixed heights for content cards; use constraints.

## Agentic Sub-Sessions

Use one sub-session per screen or small group, plus a shared-components session.

1. **Shared components agent**
   - Owns `platform_shell.dart`, new `platform_page_header.dart`, `platform_toolbar.dart`, `platform_section_card.dart`, `platform_dialog.dart`, `platform_states.dart`.
   - Build the shared page system first.
   - Does not edit feature screens yet.

2. **Master Library + Item Editor agent**
   - Owns `features/master_library/**`.
   - Implements screens 05 and 06.

3. **Categories + Option Sets agent**
   - Owns categories/option sets screens.
   - Uses shared components.

4. **Templates agent**
   - Owns `features/templates/**`.
   - Maintains category-first model and no scoring.

5. **Secondary pages agent**
   - Owns documents, languages, governance.
   - Uses shared components.

6. **Legacy pages agent**
   - Owns catalogues, equipment, audit, settings.
   - Uses shared components; removes hardcoded sample data.

7. **Verifier**
   - Runs analyze/tests/screenshots at all sizes + RTL.
   - Only the verifier claims completion.

Rules: one file owner at a time; shared components land before page agents; no two agents editing the same file.

## Tests

- Widget tests per screen: loading, empty, error, data.
- Shared components tests: page header, toolbar, table/card list, dialog, states.
- Adaptive tests at 360/600/768/1024/1440.
- RTL tests.
- No overflow exceptions.
- No hardcoded user/content data.
- No weight/scoring UI.
- `flutter analyze --fatal-infos`.
- Full Platform Admin test suite.
- Screenshots for every redesigned screen at 1280 and 1440 + compact + RTL.

## Verification

```powershell
cd client
flutter analyze --fatal-infos
cd apps\platform_admin_app
flutter test
```

Screenshot evidence:
- Master Library
- Item Editor
- Categories
- Option Sets
- Templates + Builder
- Document Types
- Languages
- Config Health
- Data Catalogues
- Equipment
- Audit
- Settings

## Acceptance Criteria

1. Every page uses the shared page frame, header, toolbar, cards/table, dialog, and states.
2. Master Library and Item Editor match the Figma visual language.
3. Categories/options/templates/secondary/legacy pages are visually consistent.
4. Templates remain category-first with nested items and no weights/scoring.
5. No fixed page/card widths or heights.
6. 360/600/768/1024/1440 + RTL pass without overflow.
7. Empty/loading/error states exist on every data screen.
8. No hardcoded sample data in production pages.
9. No weight/scoring UI anywhere in Platform Admin.
10. `flutter analyze --fatal-infos` and Platform Admin tests pass.
11. Screenshot evidence attached.
12. Docs updated (`DECISIONS.md` if needed).

## Output Format

Report:
- Shared components created/changed.
- Screen-by-screen changes.
- Figma/visual deltas fixed.
- Responsive/RTL results.
- Commands/results.
- Screenshot evidence.
- Remaining blockers.
