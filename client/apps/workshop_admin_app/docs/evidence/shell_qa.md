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
2. The dock overlays the last ~88 px of the window by design; the shell reserves
   that band, so screens need no padding — but a screen that adds its own
   full-height `SizedBox` will look 88 px shorter.
3. Arabic labels in the gallery are the app's existing ARB copy; native review is
   still a standing hand-off item.

## Round-2 follow-ups (after the independent review's FAIL)

| Finding | Fix | Evidence |
|---|---|---|
| **BLOCKER** Job board had no capture through the shell | `workshop_real_font_screenshot_test` now captures `board` at 1440/1280/1024/768/390/360 EN + 1280 AR, and taps `workshop-tab-job-board` first | `shell_after/board_{1440,1024,768,390,360,1280_ar}.png` |
| **BLOCKER** Dock items were 40 px tall / 42 wide vs the 44 px `touchTarget` | items are 44 tall; wide layout min-width 44 (104 for the selected); the sharing split is 3:1 at ≥380 screen width, 2:1 below | `workshop_shell.dart` spec line amended to 44; `shell_test` asserts every item is ≥44×44 |
| **MAJOR** `navigationLabel` was an English default, never localized | new ARB key `navMain` (en/ar), passed by the host; the DS default remains for standalone tests | `app_en.arb`, `app_ar.arb`, `workshop_admin_home.dart` |
| **MINOR** icon-only destinations had no label on hover/long-press | `Tooltip(message: label)` on every item | `shell_dock.dart` |
| **MINOR** notifications path untested | `shell_test` taps the supplied action and asserts the callback | `test/shell_test.dart` |
| **MINOR** dead "More" fallback in the screenshot helper | removed; the helper now asserts the key exists | `workshop_real_font_screenshot_test.dart` |
| **MINOR** no disclosure caret on the account avatar | **won't fix (recorded):** the trigger is `WorkshopAccountMenu` in `workshop_ui.dart`, shared with another app's shell; adding a caret there changes chrome outside this wave. The menu is still reachable and its items are labelled. | reason recorded here |

`dart format` was also run over `lib test tool` and reformatted 17 files that were
on the baseline allowlist; they were reverted so the allowlist keeps its meaning
(`baseline_check: OK`).

## Round-3 follow-ups (after the PASS)

| Finding | Fix |
|---|---|
| At 360 px the active label truncated ("Over…", "Job b…") | Below 384 px the active item drops its **icon** and keeps its label, so "Overview" and "Job board" both read in full at 360. `dashboard_360.png`, `board_360.png`. |
| 380–383 px gave 43.75 px unselected items | Breakpoint moved to **384 px** (at 384 the 3:1 split yields 44.25 px). |
| Docs claimed 88/76 reserved while the code returned 84/74 | `WorkshopShellDock.reserve` returns **88/78** (items grew to 44), and the brief now says the same. |
| "Named once" test runs on an empty shell | Accepted: it asserts chrome naming; the Settings page repeating the workshop as *data* is not shell naming. |

Self-graded with artifacts (the shell's first wave already passed independently).

