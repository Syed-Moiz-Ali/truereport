# Phase 0-lite audit — app shell (read-only, 2026-11-18)

Scope: the navigation chrome that wraps every screen —
`packages/design_system/lib/src/components/workshop_shell.dart` (the implementation),
`apps/workshop_admin_app/lib/src/features/home/workshop_admin_home.dart` (the host),
`apps/workshop_admin_app/lib/src/admin_router.dart` (the route into it).
Path: **LITE** (one component). Read-only: nothing was edited to produce this file.

## R. Hard blocker — all three files are write-locked

```
workshop_admin_home.dart                        DENY Sanjay\sanja Write, Delete
admin_router.dart                               DENY Sanjay\sanja Write, Delete
workshop_shell.dart (design_system)             DENY Sanjay\sanja Write, Delete
```

Probed with an append + revert: **`WRITE BLOCKED`**, file length unchanged
(32 667 bytes). A shell rebuild that cannot rewrite `workshop_shell.dart` would be
a restyle by definition, so this wave **cannot start** until the lock is lifted by
the owner. The lock is not something the agent should lift for itself.

Unlock (owner only, one line per file):

```powershell
icacls "client\apps\workshop_admin_app\lib\src\features\home\workshop_admin_home.dart" /remove:d "Sanjay\sanja"
icacls "client\apps\workshop_admin_app\lib\src\admin_router.dart" /remove:d "Sanjay\sanja"
icacls "client\packages\design_system\lib\src\components\workshop_shell.dart" /remove:d "Sanjay\sanja"
```

`admin_providers.dart`, `app.dart` and `main.dart` are **not** locked, but none of
them can swap the home page: `app.dart` reads `adminRouterProvider`, and the
router (locked) builds `const WorkshopAdminHomePage()`.

## 1. What the shell does today

| Breakpoint | Composition |
|---|---|
| ≥1000 | 256 px sidebar (brand block, 6 nav items, account footer) + 60 px top bar (breadcrumb, bell, avatar) + content |
| 680–999 | 72 px icon rail + the same top bar + content |
| <680 | mobile top bar (workshop name, bell, avatar) + content + bottom bar (4 items + "More" sheet) |

`WorkshopAppShell` is a 1 200-line file: three near-identical branches, each
passing 15 props into `_Sidebar`/`_Rail`/`_TopBar`, plus `_NavSurface`,
`_AccountMenu`, `showWorkshopMoreSheet`. It depends on nothing but the workshop
tokens and `workshop_ui.dart`.

## 2. Findings (structural, not cosmetic)

| # | Finding | Evidence | Consequence |
|---|---|---|---|
| **S1** | The workshop is named **twice above the fold**: the sidebar brand block ("TrueReport" + workshop name) and the top bar breadcrumb (`"$workshopName / $sectionLabel"`) | `workshop_shell.dart:311-321`, `:647` | Wastes the most valuable strip of the screen; the only new information in the top bar is the section label |
| **S2** | The same chrome is instantiated twice with identical 15-prop lists (sidebar branch and rail branch) | `:89-121` vs `:133-165` | Every shell change is a three-place edit; drift is inevitable |
| **S3** | Navigation labels cannot distinguish "Jobs" from "Job board" — both are work queues in the user's mind | `workshop_admin_home.dart:80-103`; Wave-2 finding D3 | Users must learn two objects with disjoint vocabularies |
| **S4** | `IndexedStack` mounts all six tabs at once | `workshop_admin_home.dart:138-148`; audit D6 | Six provider families fetch on app open; only the visible tab uses them |
| **S5** | Language switching is only inside the account menu (desktop) or the More sheet (phone) | `_AccountMenu`, `showWorkshopMoreSheet` | An Arabic-speaking admin needs two taps to read their own app |
| **S6** | The 60 px top bar carries one muted breadcrumb and two icon buttons — no global way to find a job or a customer | `_TopBar` | The shell offers no affordance for the most common task ("where is JOB-10482?") |
| **S7** | The phone shows 4 of 6 destinations plus "More", and "More" also contains language + sign-out | `_BottomBar`, `showWorkshopMoreSheet` | The two least-used items (language, sign-out) share a sheet with two primary destinations |
| **S8** | No landmarks or skip affordance; nav items are icon + label only, the selected state is a soft pill | `_SidebarItem`, `_NavSurface` | Screen-reader users get no "navigation" landmark; the selected item is not announced as current |

## 3. Invariants the rebuild must not break

From `docs/invariants.md` (J14, J15, J17) plus what the shell owns:

| # | Invariant | Where tested |
|---|---|---|
| K1 | Six destinations by index 0–5 (overview, jobs, staff, templates, job board, settings); `WorkshopNavigationScope.select` is the only way a screen changes section | `dashboard_test`: "tab navigation still reaches every tab" |
| K2 | Stable keys `workshop-tab-{overview,jobs,staff,templates,job-board,settings}`, `workshop-notifications` | dashboard/queue/matrix tests |
| K3 | The account menu exposes settings, language toggling and sign-out; `onSignOut` goes through `authControllerProvider` | matrix + sign-in suites |
| K4 | Light-only (W-LIGHT); no dark chrome | `ui_matrix_test` |
| K5 | RTL mirrors the whole chrome (sidebar side, chevrons, breadcrumb direction) | AR screenshots at 1280/390 |
| K6 | The content area is the only scroll owner; the shell must not add a second scroll | matrix resize test |
| K7 | The shell must accept any child without constraining its width (the dashboard now measures its own box) | dashboard LITE wave |

## 4. Baseline (measured)

```
flutter analyze --fatal-infos   No issues found
flutter test                    527 pass, 0 fail
dashboard_tab.dart coverage     93.4 %   admin_api.dart 6.3 %
font strategy                   bundled .ttf, RealFonts harness, no runtime fetch
```

The shell itself has no dedicated test file; it is covered indirectly by every
screen test (navigation, keys, AR). A shell wave should add one
(`test/shell_test.dart`) before changing the layout.

## 5. Top findings ranked, and what a rebuild would change

| Priority | Change | Why |
|---|---|---|
| 1 | **One identity strip, not two.** The sidebar owns brand + workshop; the top bar owns section + global action | S1 |
| 2 | **One chrome model, three renderings.** A single `ShellLayout` (model) with sidebar / rail / bottom renderers, no 15-prop duplication | S2 |
| 3 | **A global job search in the top bar** (the API already supports `search`) | S6 |
| 4 | **Language where it is seen**: a labelled `EN | ع` control in the chrome, not buried in the account menu | S5 |
| 5 | **Lazy tabs**: keep-alive only for the last visited section, or mount on first visit | S4 |
| 6 | **Rename the two job entries** ("Jobs" → "Work queue"; "Job board" → "Client board") — requires the host file (locked) | S3 |
| 7 | Landmarks + current-item announcement | S8 |

Items 1, 2, 4, 5, 6, 7 need `workshop_shell.dart`; item 6 additionally needs
`workshop_admin_home.dart` (the labels live there). Items 1–7 all need the ACL
lift.

## 6. Strategy (once unlocked)

**Strangler inside the design system.** Keep `WorkshopAppShell`'s public
constructor exactly as the host calls it, so `workshop_admin_home.dart` needs no
edit for the chrome rebuild; add a new `shell/` folder
(`shell_layout.dart`, `shell_sidebar.dart`, `shell_rail.dart`, `shell_bottom.dart`,
`shell_topbar.dart`, `shell_nav_item.dart`) and delete the six private widgets in
`workshop_shell.dart`. Revertible in one step (`git checkout` the file + delete
the folder).

Kill list (preliminary): `_Sidebar`, `_Rail`, `_TopBar`, `_MobileTopBar`,
`_BottomBar`, `_SidebarItem`, `_RailItem`, `_BottomItem`, `_NavSurface`,
`_AccountMenu`, `showWorkshopMoreSheet`.

## 7. Gate 0 asks

1. Approve the invariant set K1–K7 (nothing else may change).
2. Approve the direction previews at Gate 3 before any chrome is built.
3. **Lift the ACL** (or accept that this wave cannot run).
