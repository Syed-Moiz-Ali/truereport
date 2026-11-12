# Platform Admin Sidebar Redesign — Prompt

You are redesigning **only the Platform Admin sidebar** in:

`E:\syed_moiz_ali\bitlogix\truereport`

Do not redesign other screens in this task. This is the first UI pass.

## Read First

1. Figma preview:
   `docs/ui/figma-export/platform_admin_figma/screens/01_1._Global_Hierarchy_&_Staff_Tree/1._Global_Hierarchy_&_Staff_Tree@2x.png`
2. Figma JSON:
   `docs/ui/figma-export/platform_admin_figma/screens/01_1._Global_Hierarchy_&_Staff_Tree/1._Global_Hierarchy_&_Staff_Tree.json`
3. Figma implementation guide:
   `docs/ui/figma-export/platform_admin_figma/IMPLEMENTATION_GUIDE.txt`
4. Current sidebar:
   `client/apps/platform_admin_app/lib/src/components/platform_sidebar.dart`
5. Current shell:
   `client/apps/platform_admin_app/lib/src/components/platform_shell.dart`
6. Current header/mobile nav:
   `client/apps/platform_admin_app/lib/src/components/platform_header.dart`
7. `docs/FRONTEND_ADAPTIVE_RULES.md`
8. `docs/NAMING_AND_TESTING_RULES.md`
9. `docs/DECISIONS.md` (D-048, D-056, D-070, D-071)

## Goal

Make the Platform Admin sidebar visually match the Figma source, not the current improvised version.

The current sidebar is close but wrong in structure, spacing, nav grouping, and visual hierarchy. The Figma sidebar is the source of truth.

## Figma Sidebar Reference

From the Figma screen:

- White sidebar with a 1px right border.
- Width is about **260px at the 1280px design frame**.
- Brand block at the top:
  - circular green brand icon
  - product name **CoreOS**
  - subtitle **Platform Admin**
- Primary nav items:
  - Workshops
  - Master Library
  - Data Catalogues
  - Equipment
  - Settings
  - Audit Log
- Active item:
  - light lavender/grey rounded background
  - green icon
  - darker label
- Inactive items:
  - transparent background
  - muted icon
  - dark-grey label
- Calm spacing: 4–6px between items, 16px horizontal padding.
- Bottom status capsule:
  - green dot
  - **GRID V4.2 ONLINE**
  - small bolt/status icon
  - kept at the bottom with breathing room.

Do not copy raw Figma frame nesting. Recreate the visual result with semantic Flutter widgets.

## Required Sidebar Design

### 1. Brand block

- Use the Figma SVG asset or the closest existing design-system icon.
- Icon size: ~40px.
- Product title: `CoreOS`, ~18px, bold, dark ink.
- Subtitle: `Platform Admin`, ~11px, muted.
- Left padding: 16px; top padding: 20–24px.
- No overflow at compact widths.

### 2. Navigation items

- Use one reusable nav item component for desktop sidebar and mobile sheet.
- Item height: ~40px.
- Radius: ~8px.
- Horizontal padding: 16px.
- Icon size: ~18px.
- Icon-to-label gap: ~14–16px.
- Active:
  - background: `PtTheme.canvas` or the exact Figma lavender-grey
  - icon: `PtTheme.emerald` / exact Figma green
  - label: `PtTheme.ink`, weight 600
- Inactive:
  - background: transparent
  - icon: `PtTheme.muted`
  - label: `PtTheme.darkNavText`, weight 500
- Hover/focus states for web.
- Keyboard focus ring.
- Tooltip when collapsed (if a collapsed mode is added).

### 3. Primary nav grouping

The Figma primary nav has 6 items:

1. Workshops
2. Master Library
3. Data Catalogues
4. Equipment
5. Settings
6. Audit Log

The app now also has:

- Templates
- Document Types
- Languages
- Config Health

Do **not** simply dump them into the primary list and break the Figma rhythm.

Choose one of these and document it in `docs/DECISIONS.md`:

**Option A (recommended): Configuration group**
- Keep the Figma six primary items.
- Add a small uppercase section label `CONFIGURATION` below Audit Log or below Equipment.
- Put Templates, Document Types, Languages, Config Health under it using the same nav-item component.
- Visually separate with a 16–20px gap and a subtle label.

**Option B: Sub-navigation inside Master Library**
- Keep the Figma sidebar exactly.
- Move Templates, Document Types, Languages, Config Health into Master Library tabs/sub-pages.
- Sidebar remains 6 items only.

Do not invent a third visual style.

### 4. Bottom status capsule

- Match Figma: canvas/white capsule, thin border, green dot, `GRID V4.2 ONLINE`, small icon.
- Keep it pinned to the bottom.
- Do not make it larger or bolder than Figma.
- No hardcoded fake metrics.

### 5. Responsive behavior

- Desktop `>= 900px`: show sidebar.
- Compact `< 900px`: hide sidebar; header menu opens the same nav list as a scrollable sheet.
- Sidebar width: use a token/clamp, not a random fixed number. Target ~260px, allowed range ~248–272px.
- Never let nav labels overflow; use ellipsis.
- RTL: icons/text must mirror correctly using directional padding.
- No fixed heights for the whole sidebar; it must fill available height.

## Implementation Rules

1. Reuse `PtTheme` tokens and existing design-system components where possible.
2. Extract nav data into one list/model so desktop sidebar and mobile sheet share the same source.
3. Do not duplicate nav item widgets in sidebar and header.
4. No hardcoded colors outside `PtTheme`/design tokens.
5. No phase numbers in names.
6. No redesign of page content in this task.
7. No commits unless explicitly asked.
8. Do not touch `PublicReportService.java` / `print-report.html`.

## Agentic Sub-Sessions

Use short, focused sub-sessions:

1. **Figma/current audit agent (read-only)**
   - Compare the Figma sidebar PNG/JSON to the current sidebar.
   - Produce exact deltas: width, padding, item height, colors, font sizes, nav grouping, bottom capsule.
   - Do not edit files.

2. **Sidebar implementation agent**
   - Owns `platform_sidebar.dart`, the shared nav model, and the mobile nav list in `platform_header.dart`.
   - Implements the Figma sidebar and shared nav item.
   - Does not edit page content.

3. **Verifier**
   - Runs `flutter analyze`, sidebar/widget tests, and captures screenshots/goldens at 1280 and 1440 widths plus compact and RTL.
   - Only the verifier claims completion.

## Tests

- Widget test: active nav item styling.
- Widget test: nav items render in the chosen order/group.
- Widget test: mobile sheet renders the same items and closes on navigation.
- Widget test: compact width hides sidebar.
- Widget test: RTL does not overflow.
- Golden/screenshot comparison against the Figma PNG at 1280 and 1440.
- `flutter analyze --fatal-infos`.
- Full Platform Admin test suite.

## Verification Commands

```powershell
cd client
flutter analyze --fatal-infos
cd apps\platform_admin_app
flutter test
```

Screenshots:
- Desktop 1280 / 1440
- Compact 360 / 768
- Arabic RTL

## Acceptance Criteria

1. Sidebar visually matches the Figma reference:
   - brand block
   - nav item sizing/spacing
   - active/inactive states
   - bottom status capsule
   - white background + border
2. Sidebar width is ~260px at desktop, using tokens/clamp, and adapts at compact widths.
3. Figma’s six primary items remain the primary nav.
4. Templates/Document Types/Languages/Config Health are placed via a documented group/sub-nav decision, not randomly inserted.
5. Desktop sidebar and mobile sheet use the same nav data/component.
6. No overflow at 360/600/768/1024/1440 or in Arabic RTL.
7. No hardcoded colors outside the theme.
8. `flutter analyze --fatal-infos` and Platform Admin tests pass.
9. Screenshots/goldens are attached as evidence.

## Output Format

Report:
- Files changed.
- Figma deltas fixed.
- Nav grouping decision.
- Responsive/RTL behavior.
- Commands/results.
- Screenshot evidence.
- Remaining blockers.
