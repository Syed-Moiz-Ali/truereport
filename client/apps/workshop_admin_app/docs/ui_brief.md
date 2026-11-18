# UI brief — Workshop app shell, direction C "The dock"

Chosen at Gate 3 (user, 2026-11-18) from `docs/shell_directions.md`.
Build contract for `packages/design_system/lib/src/components/workshop_shell.dart`
and the host `apps/workshop_admin_app/lib/src/features/home/workshop_admin_home.dart`.
The dashboard brief is archived at `docs/ui_brief_dashboard.md`.

---

## 1. Product feeling

The chrome disappears; the work stays. One thin strip at the top says whose
workshop this is and who you are. Everything else is content. The six sections
live in a single floating dock at the bottom, and the dock shows one name — the
one you are in.

**Signature idea (committed):** *the dock is the only navigation, and it names
only the place you are.*

## 2. Anti-goals

- No 256 px text sidebar and no second identity above the fold.
- No breadcrumb duplicating the workshop name.
- No "More" sheet: six destinations, always present, never hidden behind one.
- No notification badge — there is no count in the API (inventory row 10).
- No global search in this wave (the chosen direction has none; a dead control
  would be worse than no control).
- No dark chrome (W-LIGHT). No new routes. No change to the six indices or keys.
- No shadow-elevated dock: hairline border + surface, per the token rules.

## 3. The hero moment

The dock's active item is a filled pill that carries the section name; the other
five are icons. Moving sections animates the pill's width once (220 ms), so the
name travels to the new section instead of blinking.

## 4. Information architecture (unchanged contract)

```
Identity strip (44 px)
  brand mark (TR) · workshop name · [language toggle] · [notifications] · avatar ▾
Content
  the selected screen, full width of the area minus its own gutters
Dock (floating, bottom centre)
  6 items, fixed order: Overview · Jobs · Staff · Templates · Board · Settings
```

**Flows**

| Flow | Steps | Notes |
|---|---|---|
| Change section | 1 tap/click on the dock | `WorkshopNavigationScope.select` unchanged |
| Switch language | 1 tap on `EN | ع` in the strip | visible at every width (was 2 taps, inside the account menu) |
| Sign out / settings | avatar → menu | the account menu keeps both |
| Read where you are | the dock's expanded item | no breadcrumb to parse |
| Open notifications | bell in the strip | unchanged route |

## 5. Layout per breakpoint

| Content width | Composition |
|---|---|
| **≥900** | 44 px strip: brand + workshop name left; language, bell, avatar right. Dock centred, 5 px inset, items **44 px** tall (the design system's `touchTarget`), active item expanded (icon + label), **88 px** reserved at the bottom of the content. |
| **680–899** | same strip; dock centred, full label for the active item, **78 px** reserved. |
| **<680** | 44 px strip: brand mark only + workshop name (ellipsis) + language + bell + avatar; dock inset 10 px, full width, active item flex 3 (2 below 384 px), others flex 1, icon-only. 78 px reserved. **Below 384 px the active item shows its label instead of its icon**, because an icon plus a word does not fit at 360. |

The dock never overlays content: the content area reserves the dock's height, so
every list can scroll clear of it.

## 6. States

| State | Behaviour |
|---|---|
| Default | five icons + one expanded pill |
| Hover (pointer) | item background `ws.canvas`, label appears on the hovered item if space allows |
| Focus | 2 px focus ring (`ws.focus`) inside the pill, keyboard reachable in order |
| Pressed | background `ws.accentHover` |
| Selected | accent fill, `onAccent` icon + label, `Semantics(selected: true)` |
| Account menu open | popup anchored to the avatar (settings, language, sign out) |
| No session | workshop name falls back to `workshopAdminTitle`; avatar shows initials or the role label |
| Long workshop name | one line, ellipsis, never wraps the strip |
| RTL | strip mirrors; dock order mirrors (Overview on the right); the icon set stays directional-neutral |
| Text scale 1.5 / 2 | dock items keep icons; the active label truncates with ellipsis rather than pushing the dock off-screen; strip text scales, name ellipsizes |
| Narrow (<360) | not supported below 360; 360 is the floor |

## 7. Microcopy

No new strings. The dock uses `dashboardTab`, `jobsTab`, `staffTab`,
`templatesTab`, `jobsBoardTab`, `settings`; the strip uses `workshopAdminTitle`
(fallback), `roleWorkshopAdmin`, `languageEnglish` / `languageArabic`,
`jobsNotificationsTab`, `navMore` is no longer used by the shell.

## 8. Structural departures (enforced at Gate 6)

1. The sidebar, the rail branch and the desktop top bar are **deleted**.
2. The mobile top bar and the bottom bar with "More" are **deleted**.
3. The breadcrumb `"$workshopName / $sectionLabel"` is **deleted**.
4. The workshop name appears **once** on screen.
5. Navigation moves from the left edge to the bottom edge at **all** widths.
6. `showWorkshopMoreSheet` and its four-item overflow are **deleted**.
7. The language control leaves the account menu and becomes visible in the strip.
8. The shell keeps a 44 px identity strip and a floating dock; the content's
   bottom reserve is explicit.

Kill list: `_Sidebar`, `_SidebarItem`, `_Rail`, `_RailItem`, `_TopBar`,
`_MobileTopBar`, `_BottomBar`, `_BottomItem`, `_NavSurface`, `_AccountMenu`,
`showWorkshopMoreSheet`, and the three duplicated layout branches.

## 9. Acceptance checklist (Gate 6)

1. `workshop_shell.dart` rewritten to a thin public widget over new files under
   `components/shell/`; kill list empty of survivors.
2. `WorkshopAppShell`'s constructor signature unchanged (host compiles untouched).
3. Six destinations, keys `workshop-tab-*` present and tappable at every width;
   `workshop-notifications` still works.
4. Dock never overlays content: the last row of a long screen can scroll clear.
5. Selected item is announced (`Semantics(selected: true)`) and focus order is
   logical.
6. Language toggle visible at 1440, 1024, 768, 390 without opening a menu.
7. No "More" sheet and no `navMore` text on screen.
8. RTL mirrors the dock and the strip; no clipped labels at 1280 AR.
9. 1.5× / 2× text at 390 and 1280: no overflow, the active label ellipsizes.
10. Every screen still renders: dashboard, jobs, staff, templates, board,
    settings at 1440/1024/768/390 EN + 1280 AR; `flutter analyze`, `flutter test`,
    `baseline_check` clean; no test deleted.

## 10. Build notes

- The dock reserves space in the content area — do not rely on every screen
  adding its own bottom padding.
- `IndexedStack` in the host keeps six tabs mounted. The host is now unlocked; a
  lazy "build after first visit, keep alive after" is in scope **only** if the tab
  switching tests stay green.
- Keep the account menu's language entry as well (two paths are harmless) but the
  strip control is the primary one.
