# Mini Brief — app shell (direction C "The dock")

Inputs, all approved: `docs/audit-shell.md` (K1–K7), `docs/shell_directions.md`
(direction C chosen at Gate 3), `docs/ui_brief.md` (the spec), the Gate 5
gallery (`docs/evidence/gallery/shell_index.html`).

**Process note, in the open:** the foundation (identity strip + dock + the shell
rewrite) was built as the Gate 5 slice and approved with the gallery. This brief
records the scope that slice covered, the integration change that followed, and
the proof obligations — it was not written in advance of the code, which is the
one place this wave deviated from the pipeline's order.

## What was delivered

| Area | Change |
|---|---|
| Shell implementation | `workshop_shell.dart` rewritten from 1 200 lines to a 150-line public widget over `components/shell/{shell_destination,shell_identity_strip,shell_dock}.dart` |
| Public API | `WorkshopAppShell` keeps every existing named parameter; `moreLabel`, `signOutLabel`, `settingsLabel` gained defaults; `navigationLabel` added (optional) |
| Kill list | `_Sidebar`, `_SidebarItem`, `_Rail`, `_RailItem`, `_TopBar`, `_MobileTopBar`, `_BottomBar`, `_BottomItem`, `_NavSurface`, `_AccountMenu`, `showWorkshopMoreSheet`, and the three duplicated layout branches — all deleted |
| Identity | 44 px strip: brand mark + "TrueReport" + workshop name (once), language control, notifications, account menu |
| Navigation | one floating dock at every width; selected item carries its label; items share the width below 600 px (3:1:1:1:1:1) so it can never overflow |
| Content contract | the shell reserves the dock's height (`WorkshopShellDock.reserve`) — screens add nothing |
| Language | visible one-tap control in the strip (still also in the account menu) |
| Host | `IndexedStack` → `_SectionHost`: a section mounts on first visit, then stays alive (audit S4) |
| Dashboard | its own workshop eyebrow removed — the strip already names the workshop (no double naming) |
| Tests | DS: `test/shell_test.dart` (8 behaviour tests) replaces the obsolete sidebar/rail/More assertions; app: `test/shell_gallery_test.dart` (9 captures) |

## Out of scope (stop and ask if it appears)

- Renaming "Jobs" / "Job board" (the labels live in ARB; a copy decision).
- A global job search (direction A's idea; not in C).
- Dark chrome (W-LIGHT).
- Any change to the six indices, to `WorkshopNavigationScope.select`, or to the
  `workshop-tab-*` keys.
- Route or auth changes in `admin_router.dart`.

## Proof obligations (executed below)

1. `dart format`, `flutter analyze --fatal-infos`, `flutter test`, the DS suite,
   `dart run tool/baseline_check.dart`.
2. Real-font captures of all six screens at 1440/1024/768/390/360 EN + 1280 AR
   (`docs/evidence/shell_after/`, from `workshop_real_font_screenshot_test`).
3. Gallery: dock × {default, other section, narrow, 2x, RTL}, strip × {LTR, RTL,
   narrow} (`docs/evidence/gallery/shell_*.png`).
4. No new `RenderFlex overflowed` at any of those widths (the suite asserts none).
5. Edit-vs-replace: rewritten shell file, three new region files, non-empty kill
   list, visibly different structure at 1440 / 1024 / 390.
6. Gate 6 by an independent reviewer who sees only the captures, the checklist and
   the spec.

## Acceptance checklist (from `docs/ui_brief.md` §9)

| # | Item | Evidence |
|---|---|---|
| 1 | Shell rewritten over new region files; kill list executed | file table above |
| 2 | Constructor unchanged for the host | host compiles; `shell_test` pumps it |
| 3 | Six destinations + keys at every width; notifications works | `shell_test` 1280 + 390 |
| 4 | Dock never overlays content | `shell_test` "content can never be trapped"; reserved band |
| 5 | Selected announced; focus order logical | `Semantics(selected:)` in `_DockItem`; focus ring |
| 6 | Language visible without opening a menu | `shell_test`; `shell_strip_*` captures |
| 7 | No More sheet, no `navMore` on screen | `shell_test` asserts `workshop-tab-more` absent |
| 8 | RTL mirrors; no clipped labels | `shell_strip_rtl`, `shell_dock_rtl`, `dashboard_1280_ar` |
| 9 | 1.5×/2× no overflow; label ellipsizes | `shell_dock_scale2`; matrix in `ui_matrix_test` |
| 10 | All screens at all widths + AR; analyze/test/baseline clean | `docs/evidence/shell_after/`; logs |
