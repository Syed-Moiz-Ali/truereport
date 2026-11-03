# Phase 3.5 UI/UX Decisions

**Project:** TrueReport  
**Date:** 3 November 2026  
**Scope:** Centralised UI/UX refactor of existing screens only. No business logic, API contract, model, validation, navigation, state-management, or server behaviour was changed.

---

## 1. Source direction

Read in full:

- `docs/ui/UI_promt.txt`
- `docs/ui/UI_promt2.txt`

Both require typography-first hierarchy, minimal chrome, theme-only colours and type, an 8dp rhythm, motion, responsiveness, accessibility, and preserved functionality.

---

## 2. Conflict resolution

The two prompts disagree on inputs:

| Prompt | Direction |
|---|---|
| `UI_promt.txt` | Minimal underlines or flush-aligned borderless inputs |
| `UI_promt2.txt` | Filled, borderless, tonal inputs with floating labels and inline validation |

**Decision:** use **filled, borderless inputs on tonal surfaces** everywhere.

- No outlined inputs.
- Floating labels from `InputDecorationTheme`.
- Validation appears inline.
- Error/status text uses themed colours and animated switches where the screen owns the error state.
- The same rule applies to sign-in, admin search, dialogs, category forms, item editor, guide-image metadata, and hierarchy forms.

No screen keeps a different local input look.

---

## 3. Typography and colour rules

- All text uses `Theme.of(context).textTheme`.
- Screen widgets do not set `fontSize`, `TextStyle`, `Color(...)`, `Colors.*`, or static brand colours.
- Colours come from `Theme.of(context).colorScheme` or a `ThemeExtension` read through the design system.
- `StatusChip` and `SeverityBadge` use `AppStatusColors`, not hardcoded green/amber/red.
- Dark mode is a first-class variant: `AppTheme.light` and `AppTheme.dark`.
- The system default/bundled fonts are used; no runtime font download was added.

---

## 4. Spacing, radii, and motion

Theme extensions now own:

- `AppSpacingTokens`: 4, 8, 12, 16, 24, 32, 48.
- `AppRadiiTokens`: 4, 8, 12, 16, pill.
- `AppMotionTokens`: 120ms, 220ms, 320ms with enter/exit curves.
- `AppStatusColors`: neutral, info, success, warning, danger, critical.

Widgets use `context.spacing`, `context.radii`, `context.motion`, and `context.statusColors`. No widget-level magic padding or radius values were introduced.

`ReduceMotion.duration` returns `Duration.zero` when the platform requests reduced motion. `FadeInCard`, `LoadingSkeleton`, `StatusChip`, `AppSelectableText`, and `OfflineBanner` use the helper.

---

## 5. Component rules

`client/packages/design_system` is the only visual layer. It provides:

- `AppScaffold` and `AppSliverScaffold`.
- `AppButton` with primary, tonal and text variants, plus loading/disabled states.
- `AppTextField` with filled borderless theme and inline validation.
- `AppSelectableText` for typographic filters/toggles.
- `StatusChip`, `SeverityBadge`, `SectionHeader`.
- `AppListTile`, `EmptyState`, `ErrorState`.
- `LoadingSkeleton` (animated skeleton, not a lone spinner).
- `OfflineBanner`.
- `ConfirmDialog` and bottom-sheet helpers.
- Directional layout via `EdgeInsetsDirectional` and `AlignmentDirectional`.

Reusable layout decisions:

- `AppListTile` gives the title two flex shares and caps trailing content to the remaining flexible space so long chips/status text cannot starve the title or overflow.
- `SectionHeader` stacks its action below the title on narrow widths or large text scale.
- `AppSelectableText` wraps its label instead of forcing a single-line row.
- `DropdownButtonFormField` is expanded in forms so large text and long labels do not overflow.
- `AppCard` is a tonal surface, not a bordered/elevated generic card.
- List rows use `AppListTile`; screens do not create one-off card looks.

---

## 6. Responsive and accessibility rules

Breakpoints: `600`, `900`, `1200` logical pixels.

- Sign-in content width is derived from `LayoutBuilder`; no fixed screen width.
- Role home content width is derived from available width.
- Platform Admin uses a bottom/top tab layout below `900` and a `NavigationRail` side navigation at/above `900`.
- Master content and guide-image layouts derive column count and card width from constraints.
- Interactive targets meet the 48dp minimum through theme button sizes and component constraints.
- Screen-reader semantics are present on buttons, fields, status chips, banners, list tiles and skeletons.
- Focus/keyboard behaviour comes from Material controls and InkWell/focus defaults.
- Tests cover phone, tablet, wide web, English/Arabic RTL, light/dark, and 1.5x/2.0x text scale.

---

## 7. Central API endpoints

`client/packages/api_client/lib/src/api_endpoints.dart` is the single owner of API paths, including parameterised paths for:

- Auth.
- Hierarchy and workshop detail.
- User/invitation actions.
- Categories and items.
- Item versions, translations, rules and publishing.
- Reasons, equipment, dropdowns.
- Guide-image upload/content/retirement.

`apiEndpointsProvider` is a Riverpod provider in `auth_controller.dart`; it builds from the existing flavor/config base URL. `AuthRepository` and `HttpAdminApi` receive it by constructor injection.

No screen, provider or repository contains a raw `/api/v1` path. A source-scan test fails if one reappears outside `ApiEndpoints`.

---

## 8. Preserved behaviour

The refactor deliberately kept:

- All API calls and request/response models.
- All Riverpod providers and controller state transitions.
- All validators and authentication/TOTP flow.
- All navigation routes and redirects.
- All create/edit/publish/retire/transfer logic.
- The server entirely unchanged.

The only interaction addition is a confirmation dialog before retiring an item; the underlying retire API and post-retire navigation are unchanged.

---

## 9. Verification

- `flutter analyze --fatal-infos`: clean.
- Client tests include EN/AR RTL, light/dark, phone/tablet/wide, 1.5x/2.0x text scaling, reduce-motion, endpoint scan, and colour/font scan.
- `client/apps/technician_app`: 4 tests passed.
- `client/apps/admin_app`: 53 tests passed.
- `server`: 23 tests run, 0 failures, 1 skipped (Docker unavailable).
- `flutter build web --release`: succeeded.
