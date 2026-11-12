# Platform Admin Header / Top Bar Redesign — Prompt

You are redesigning **only the Platform Admin header/top bar system** in:

`E:\syed_moiz_ali\bitlogix\truereport`

Do not redesign page content, cards, tables, or dialogs in this task. The sidebar redesign is already accepted.

## Read First

1. Figma preview:
   `docs/ui/figma-export/platform_admin_figma/screens/01_1._Global_Hierarchy_&_Staff_Tree/1._Global_Hierarchy_&_Staff_Tree@2x.png`
2. Figma JSON:
   `docs/ui/figma-export/platform_admin_figma/screens/01_1._Global_Hierarchy_&_Staff_Tree/1._Global_Hierarchy_&_Staff_Tree.json`
3. Figma implementation guide:
   `docs/ui/figma-export/platform_admin_figma/IMPLEMENTATION_GUIDE.txt`
4. Current header:
   `client/apps/platform_admin_app/lib/src/components/platform_header.dart`
5. Current shell:
   `client/apps/platform_admin_app/lib/src/components/platform_shell.dart`
6. Current sidebar/nav:
   `client/apps/platform_admin_app/lib/src/components/platform_sidebar.dart`
   `client/apps/platform_admin_app/lib/src/components/platform_nav.dart`
7. `docs/FRONTEND_ADAPTIVE_RULES.md`
8. `docs/NAMING_AND_TESTING_RULES.md`
9. `docs/DECISIONS.md` (D-048, D-056, D-070, D-071, D-073)

## Current Problems

The current header is improvised and does not match Figma:

- Search placeholder is hardcoded English and too narrow.
- Search field has a visible border; Figma uses a soft filled pill without a heavy border.
- Notification and help actions are boxed 36×36 controls; Figma uses clean icon actions.
- Help action is missing entirely.
- Language switcher is a standalone bordered box that Figma does not have.
- User chip is hardcoded `Alex Vance` / `Principal Admin` / `AV`.
- User avatar does not match Figma’s green circular avatar treatment.
- There is no user menu, no sign-out/language/profile grouping.
- Notification and help buttons are dead controls.
- No shared breadcrumb/context bar component; `HIERARCHY ROOT / EMEA INDUSTRIAL / Active Workshops` is page-specific and partly hardcoded.
- Header spacing/height/alignment does not follow the Figma rhythm.

## Goal

Build a reusable Platform Admin header that matches Figma and works for every Platform Admin page.

Two layers:

1. **App header** — search, notifications, help, user menu.
2. **Context bar** — breadcrumb + page-level actions/view toggle, passed by each page.

Do not put page-specific breadcrumbs inside the global header widget.

## Figma Header Reference

From the Figma screen:

- White header with a 1px bottom border.
- Height around 72–80px.
- Left: wide rounded search pill:
  - soft canvas background
  - search icon
  - placeholder: `Search platform assets, specs, workshop nodes...`
  - no heavy border
- Right:
  - notification bell icon
  - help/question icon
  - user block:
    - display name
    - role
    - green circular avatar

Do not copy raw Figma nesting. Recreate the visual result with semantic Flutter widgets.

## Required Header Design

### 1. Header container

- White background.
- 1px bottom border using `PtTheme.border`.
- Height ~72–80px; use constraints, not a fixed oversized frame.
- Horizontal padding: 24px desktop, 14–16px compact.
- No hardcoded page title in the global header.

### 2. Search

- Rounded pill, height ~40px.
- Width: fluid, max ~560px on desktop.
- Background: `PtTheme.canvas`.
- Border: none or very subtle (match Figma).
- Search icon: 18px, muted.
- Placeholder from ARB:
  - EN: `Search platform assets, specs, workshop nodes...`
  - AR: localized equivalent.
- Compact: shorter placeholder or icon-only expandable search.
- Focus state: subtle emerald focus ring; no layout shift.
- Search callback must be wired to the real page/provider, not a no-op.

### 3. Right-side actions

Order (match Figma):

1. Notifications
2. Help
3. User menu

- Use plain icon buttons with tooltips, not bordered boxes.
- Notification:
  - `Icons.notifications_none_rounded`
  - tooltip `Notifications`
  - opens a notification panel/sheet or a real notification route.
  - If the notification feature is not built yet, show a clear empty-state sheet, not a dead button.
- Help:
  - `Icons.help_outline_rounded` or Figma question icon.
  - tooltip `Help`.
  - opens a help sheet/modal with support contact/docs link.
- No fake badge counts.

### 4. User menu

Replace the hardcoded user chip with real session data:

- Read `authControllerProvider` session / `MeResponse`.
- Show `displayName` and role.
- Avatar:
  - Figma-style green filled circle.
  - Use white person icon when no avatar image exists.
  - Use real avatar if the session provides one.
- Clicking the user block opens a menu with:
  - Language toggle EN/AR (moves the existing language control here).
  - Profile / account (if available, otherwise hide).
  - Sign out.
- In RTL, the user block mirrors correctly.
- If the session is unavailable, show a neutral placeholder; never hardcode a fake person.

Remove the standalone EN/AR bordered language box from the header.

### 5. Context bar (breadcrumb + page actions)

Add a reusable `PlatformContextBar` component:

- Sits directly below the app header.
- Left: breadcrumb trail.
- Right: page-level view toggle/actions (e.g. Directory View / Throughput).
- Breadcrumb items are passed by the page, not hardcoded in the header.
- Last breadcrumb item is active/dark; ancestors are muted.
- Separator: `/` or chevron using the Figma style.
- Compact: allow horizontal scroll or collapse to `…`; never overflow.
- The hierarchy page should pass:
  `HIERARCHY ROOT / EMEA INDUSTRIAL / Active Workshops`
  from real data where possible.

Do not put fake breadcrumb text into the global header.

### 6. Responsive behavior

- Desktop `>= 900px`: menu button hidden; sidebar visible; search wide; user name/role visible.
- Compact `< 900px`: menu button visible; sidebar hidden; search compact; user name/role may hide, avatar remains; user menu still accessible.
- `600–900px`: keep search usable, avoid overflow.
- `< 600px`: icon actions wrap or collapse into an overflow menu; no RenderFlex overflow.
- RTL: use `EdgeInsetsDirectional` and `AlignmentDirectional`.

## Implementation Rules

1. Reuse `PtTheme` tokens and existing design-system components.
2. Keep the header as one reusable component; do not duplicate header code in pages.
3. Do not hardcode user identity, role, initials, or breadcrumbs.
4. Move language switching into the user menu.
5. No dead icon buttons.
6. No hardcoded English placeholder strings; use ARB.
7. No phase numbers in names.
8. No commits unless explicitly asked.
9. Do not touch `PublicReportService.java` / `print-report.html`.
10. Do not redesign page content in this task.

## Agentic Sub-Sessions

1. **Figma/current audit agent (read-only)**
   - Compare Figma header/context bar to current header.
   - Produce exact deltas: height, padding, search width/height, action spacing, avatar, typography, breadcrumb.
   - Do not edit files.

2. **Header implementation agent**
   - Owns `platform_header.dart`, `platform_shell.dart`, and a new `platform_context_bar.dart`.
   - Implements the Figma header and user menu.
   - Does not edit page content.

3. **Session/actions agent**
   - Owns the user menu actions, notification sheet, help sheet, and language toggle wiring.
   - Uses the real auth/session provider.
   - Does not edit sidebar/nav.

4. **Verifier**
   - Runs analyze/tests, captures screenshots at 1280/1440/768/360 and RTL.
   - Only the verifier claims completion.

## Tests

- Header renders Figma search pill and placeholder from ARB.
- Notification opens a sheet/route and is not dead.
- Help opens a sheet/modal.
- User menu shows real display name/role.
- User menu language toggle switches EN/AR.
- User menu sign out calls the auth controller.
- No hardcoded `Alex Vance` / `Principal Admin` / `AV`.
- Context bar renders passed breadcrumbs and page actions.
- Compact width hides name/role and keeps avatar/menu.
- RTL does not overflow.
- Golden/screenshot comparison at 1280 and 1440.
- `flutter analyze --fatal-infos`.
- Full Platform Admin test suite.

## Verification

```powershell
cd client
flutter analyze --fatal-infos
cd apps\platform_admin_app
flutter test
```

Screenshots:
- Desktop 1280 / 1440
- Compact 360 / 768
- Arabic RTL 1280 / 360

## Acceptance Criteria

1. Header matches Figma’s search pill, action spacing, and user block.
2. Search placeholder is localized and correctly sized.
3. Notification and help are real actions, not dead buttons.
4. User block uses real session data; no hardcoded name/role/initials.
5. Language switch lives in the user menu; the standalone box is removed.
6. Reusable context bar renders page-provided breadcrumbs/actions.
7. Compact/RTL layouts do not overflow.
8. No hardcoded English strings in production header.
9. `flutter analyze --fatal-infos` and Platform Admin tests pass.
10. Screenshots/goldens attached as evidence.

## Output Format

Report:
- Files changed.
- Figma deltas fixed.
- User menu/session wiring.
- Context bar behavior.
- Responsive/RTL results.
- Commands/results.
- Screenshot evidence.
- Remaining blockers.
