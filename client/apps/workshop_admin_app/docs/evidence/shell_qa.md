# App shell rebuild — proof sheet (Gate 6)

Component: `packages/design_system/lib/src/components/workshop_shell.dart`
Host: `apps/workshop_admin_app/lib/src/features/home/workshop_admin_home.dart`
Spec: `docs/ui_brief.md` · Direction: C "The dock" (`docs/shell_directions.md`)
Brief: `docs/briefs/brief-4-shell-mini.md`

## Commands (raw logs committed)

```
docs/evidence/logs/analyze.txt              flutter analyze --fatal-infos
                                            No issues found!
docs/evidence/logs/test.txt                 flutter test (app)     +555: All tests passed!
docs/evidence/logs/design_system_test.txt   flutter test (design_system) +136: All tests passed!
```

`dart run tool/baseline_check.dart` → tests green · format 0 new · analyzer clean.

App baseline before this wave: 546 tests. After: **555** (shell gallery +8, one
behaviour test rewritten). DS baseline: 136 (two drifted assertions corrected).

## Edit vs replace

| Clause | Evidence |
|---|---|
| Rewritten implementation | `workshop_shell.dart` **-1 010 lines / +100** (1 200 → 150) |
| New files per region | `components/shell/shell_destination.dart`, `shell_identity_strip.dart`, `shell_dock.dart` |
| Kill list executed | `_Sidebar`, `_SidebarItem`, `_Rail`, `_RailItem`, `_TopBar`, `_MobileTopBar`, `_BottomBar`, `_BottomItem`, `_NavSurface`, `_AccountMenu`, `showWorkshopMoreSheet`, and the three duplicated branches — all deleted |
| Visibly different at 1440 / 1024 / 390 | `docs/evidence/shell_after/dashboard_{1440,1024,390}.png` |

## Acceptance checklist (`docs/ui_brief.md` §9)

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Rewritten + region files + kill list | PASS | diff stat above |
| 2 | `WorkshopAppShell` API still compiles for the host | PASS | host diff is the lazy-tab host only; `shell_test` constructs it |
| 3 | Six destinations + keys at every width; notifications works | PASS | `shell_test`: 1280 and 390 |
| 4 | Dock never overlays content | PASS | `shell_test` "content can never be trapped" |
| 5 | Selected item announced; focus ring | PASS | `Semantics(selected:)`, 2 px focus border in `_DockItem` |
| 6 | Language visible without a menu | PASS | `shell_strip_ltr/rtl/narrow`, `shell_test` |
| 7 | No More sheet / `navMore` | PASS | `shell_test` asserts `workshop-tab-more` absent |
| 8 | RTL mirrors; no clipped labels | PASS | `shell_dock_rtl`, `shell_strip_rtl`, `dashboard_1280_ar` |
| 9 | 1.5×/2× no overflow | PASS | `shell_dock_scale2`; `ui_matrix_test` (all widths × 1.5/2) |
| 10 | All screens / widths / AR; checks clean | PASS | `docs/evidence/shell_after/` (8), logs |

## States captured

| State | File |
|---|---|
| Dock default (Overview) | `gallery/shell_dock_default.png` |
| Dock, another section | `gallery/shell_dock_staff.png` |
| Dock narrow (390) | `gallery/shell_dock_narrow.png` |
| Dock 2× text | `gallery/shell_dock_scale2.png` |
| Dock RTL | `gallery/shell_dock_rtl.png` |
| Strip LTR / RTL / narrow | `gallery/shell_strip_{ltr,rtl,narrow}.png` |
| Six screens in the shell | `shell_after/dashboard_{1440,1024,768,390,360}`, `dashboard_1280_ar`, `staff_1440`, `jobs_390` |

The account popup is **not** captured: it renders in the root overlay, outside the
repaint boundary. It is covered behaviourally by `workshop_kit_test` (menu items,
sign-out callback) — recorded here rather than hidden.

## Integration changes that came with the shell

1. **Lazy sections.** `IndexedStack` → `_SectionHost`: a section mounts on first
   visit and stays alive. All six provider families no longer fetch on open
   (audit S4). `dashboard_test` and `ui_matrix_test` still pass.
2. **No double naming.** The dashboard's own workshop eyebrow is removed; the
   strip names the workshop once. A test asserts `find.text('Marina Workshop')`
   finds exactly one widget.
3. **Two drifted DS assertions corrected** (`pageGutter` 24→32, content width
   1120→1200). The tokens were always 32/1200; the tests had drifted.

## Known limitations

1. Dark theme waived (W-LIGHT).
2. The dock overlays the last ~84 px of the window by design; the shell reserves
   that band, so screens need no padding — but a screen that adds its own
   full-height `SizedBox` will look 84 px shorter.
3. Arabic labels in the gallery are the app's existing ARB copy; native review is
   still a standing hand-off item.
