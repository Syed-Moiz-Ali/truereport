# F1 token API contract

**Purpose:** the exact interface shared by the token generator, the design-system components, the gallery, the tests and the harness. Only the integration lead edits `tokens.dart`; builders code against this contract.

---

## 1. Source of truth

- Canonical JSON: `client/packages/design_system/tokens/tokens.json`
- Generator: `tools/design_tokens/generate.mjs`
- Dart output: `client/packages/design_system/lib/src/generated/tokens.g.dart`
- CSS output: `server/src/main/resources/public-report/tokens.g.css`
- Print/PDF marked block: `server/src/main/resources/templates/report/print-report.html`
- Sync check: `node tools/design_tokens/generate.mjs --check`

Generated files are checked in. No hand edits; the check fails on drift.

---

## 2. Context API (the only way widgets read tokens)

```dart
context.colors        // ColorScheme
context.texts         // TextTheme
context.spacing       // AppSpacingTokens
context.radii         // AppRadiiTokens
context.shadows       // AppShadowTokens
context.brand         // AppBrandColors
context.statusColors  // AppStatusColors
context.severityColors// AppSeverityColors
context.sizing        // AppSizingTokens
context.motion        // AppMotionTokens
context.isArabic      // bool
```

Additional helpers:
```dart
AppTheme.light
AppTheme.dark
AppTheme.build({
  Brightness brightness = Brightness.light,
  AppColorStrategy colorStrategy = AppColorStrategy.emeraldFill,
  AppArabicFont arabicFont = AppArabicFont.notoSansArabic,
  bool isArabic = false,
})
```

Enums:
```dart
enum AppColorStrategy { emeraldFill, deepGreenFill }
enum AppArabicFont { notoSansArabic, ibmPlexSansArabic }
enum StatusTone { neutral, info, success, warning, danger, critical }
enum AppSeverity { minor, moderate, major, safetyCritical }
enum InspectionResult {
  noIssueObserved,
  attentionRecommended,
  defectFound,
  notChecked,
  notApplicable,
  couldNotVerify,
}
```

`InspectionResult` maps to a `StatusTone` and an icon:
| Result | Tone | Icon |
|---|---|---|
| `noIssueObserved` | `neutral` | `Icons.check_circle_outline` |
| `attentionRecommended` | `warning` | `Icons.info_outline` |
| `defectFound` | `danger` | `Icons.warning_amber_rounded` |
| `notChecked` | `neutral` | `Icons.remove_circle_outline` |
| `notApplicable` | `neutral` | `Icons.block` |
| `couldNotVerify` | `warning` | `Icons.help_outline` |

Labels are provided by the caller (l10n); the component must never hardcode English.

---

## 3. Colour tokens

All values are exact; the generator owns them.

### 3.1 Light base

| Token | Value |
|---|---|
| `surface` | `#FAF9FE` |
| `surfaceLowest` | `#FFFFFF` |
| `surfaceLow` | `#F7F6FB` |
| `surfaceContainer` | `#F4F3F8` |
| `surfaceHigh` | `#EEEDF3` |
| `surfaceHighest` | `#E9E7ED` |
| `onSurface` | `#1A1B1F` |
| `onSurfaceVariant` | `#5E5D69` |
| `outline` | `#6C7A71` |
| `outlineVariant` | `#DAD9DF` |
| `secondary` | `#3C4A42` |
| `onSecondary` | `#FFFFFF` |
| `secondaryContainer` | `#E3E1EF` |
| `onSecondaryContainer` | `#464651` |
| `error` | `#A3231F` |
| `onError` | `#FFFFFF` |
| `errorContainer` | `#FBE9E7` |
| `onErrorContainer` | `#7F1D1D` |
| `focus` | `#0B63CE` |
| `overlay` | `#1A1B1F66` |
| `scrim` | `#00000066` |
| `inverseSurface` | `#2F3034` |
| `onInverseSurface` | `#F1F0F5` |

### 3.2 Dark base

| Token | Value |
|---|---|
| `surface` | `#121114` |
| `surfaceLowest` | `#0C0B0E` |
| `surfaceLow` | `#1A191E` |
| `surfaceContainer` | `#232128` |
| `surfaceHigh` | `#2A282F` |
| `surfaceHighest` | `#323036` |
| `onSurface` | `#F1F0F5` |
| `onSurfaceVariant` | `#C7C5D3` |
| `outline` | `#9A98A6` |
| `outlineVariant` | `#4A4854` |
| `secondary` | `#C7C5D3` |
| `onSecondary` | `#1B1B25` |
| `secondaryContainer` | `#464651` |
| `onSecondaryContainer` | `#E3E1EF` |
| `error` | `#FFB4AB` |
| `onError` | `#690005` |
| `errorContainer` | `#93000A` |
| `onErrorContainer` | `#FFDAD6` |
| `focus` | `#9CCBFF` |
| `overlay` | `#00000099` |
| `scrim` | `#000000B3` |
| `inverseSurface` | `#E9E7ED` |
| `onInverseSurface` | `#1A1B1F` |

### 3.3 Brand strategies

| Strategy | Theme | fill | onFill | ink | container | onContainer |
|---|---|---|---|---|---|---|
| `emeraldFill` | light | `#10B981` | `#1A1B1F` | `#006C49` | `#D9FBE8` | `#00422B` |
| `emeraldFill` | dark | `#4EDEA3` | `#002113` | `#6FFBBE` | `#005236` | `#B7F5D8` |
| `deepGreenFill` | light | `#006C49` | `#FFFFFF` | `#006C49` | `#D9FBE8` | `#00422B` |
| `deepGreenFill` | dark | `#6FFBBE` | `#002113` | `#6FFBBE` | `#005236` | `#B7F5D8` |

`emeraldFill` is the default. `#10B981` must never be used for text or icons on a light surface.

### 3.4 Status pairs (Phase 1, unchanged)

| Tone | Light fg / bg | Dark fg / bg |
|---|---|---|
| neutral | `#3F4A54` / `#EDF1F3` | `#C3D4DA` / `#26373C` |
| info | `#1D5C8A` / `#E5F0F8` | `#B7DCF7` / `#173247` |
| success | `#1F6B45` / `#E6F3EC` | `#B5E8C9` / `#173D2B` |
| warning | `#8A5A00` / `#FFF4D6` | `#FFDFA3` / `#463611` |
| danger | `#A3231F` / `#FBE9E7` | `#FFC4BD` / `#4A1F1C` |
| critical | `#7F1D1D` / `#F7DADA` | `#FFD0D0` / `#551C1C` |

### 3.5 Severity mapping

| Severity | Tone | Icon |
|---|---|---|
| minor | neutral | `Icons.circle_outlined` |
| moderate | warning | `Icons.warning_amber_rounded` |
| major | danger | `Icons.error_outline` |
| safetyCritical | critical | `Icons.dangerous_outlined` |

---

## 4. Typography

Families:
- Latin: `Plus Jakarta Sans`
- Arabic default: `Noto Sans Arabic`
- Arabic alternative: `IBM Plex Sans Arabic`
- Cyrillic fallback: `Noto Sans`
- CJK fallback: `Noto Sans SC`

Scale (size / line-height / weight / tracking):
| Token | Size | Height | Weight | Tracking |
|---|---:|---:|---:|---:|
| `display` | 32 | 38 | 800 | -0.8 |
| `headlineXl` | 26 | 32 | 800 | -0.6 |
| `headlineLg` | 22 | 28 | 700 | -0.4 |
| `headlineMd` | 18 | 24 | 700 | -0.3 |
| `titleLg` | 16 | 22 | 700 | -0.2 |
| `bodyLg` | 16 | 24 | 500 | -0.1 |
| `bodyMd` | 14 | 20 | 500 | 0 |
| `bodySm` | 12 | 18 | 400 | 0 |
| `labelLg` | 14 | 18 | 700 | 0 |
| `labelMd` | 12 | 16 | 600 | 0.2 |
| `labelSm` | 12 | 16 | 600 | 0.3 |

Arabic build path sets tracking to 0 for every style and uses height 1.55 for body styles. No 11 px style exists.

---

## 5. Spacing and radii

Spacing (legacy names keep their existing values so current screens do not shift):

| Token | Value | Notes |
|---|---:|---|
| `xxs` | 2 | new |
| `xs` | 4 | existing |
| `sm` | 8 | existing |
| `md` | 12 | existing |
| `lg` | 16 | existing |
| `gutter` | 20 | new |
| `xl` | 24 | existing |
| `xxl` | 32 | existing |
| `xxxl` | 40 | new |
| `huge` | 48 | existing |
| `massive` | 64 | new |

Builders use these names. The generator emits the same values. Do not renumber existing names.

Radii: `sm 4`, `md 8`, `lg 12`, `xl 16`, `card 24`, `cardLarge 32`, `pill 999`.

---

## 6. Shadows

| Token | Value |
|---|---|
| `card` | `0 2 8 #1A1B1F08`, `0 14 40 #1A1B1F0F` |
| `floating` | `0 4 12 #1A1B1F0A`, `0 18 50 #1A1B1F14` |
| `button` | `0 10 25 #10B9814D` (emerald strategy) / `0 10 25 #006C494D` (deep-green strategy) |
| `focus` | 0 blur, 2 px spread, `focus` colour |

Shadows are decorative; they never encode meaning.

---

## 7. Sizing

| Token | Value |
|---|---:|
| `targetMin` | 48 |
| `buttonHeight` | 56 |
| `technicianPrimaryHeight` | 56 |
| `inputHeight` | 56 |
| `navDockHeight` | 64 |
| `cardPadding` | 24 |
| `iconSm` | 16 |
| `iconMd` | 20 |
| `iconLg` | 24 |
| `iconXl` | 32 |
| `focusRingWidth` | 2 |
| `focusRingOffset` | 2 |
| `borderWidth` | 1.5 |
| `maxContentWidth` | 1280 |

---

## 8. Motion

`fast 120ms`, `normal 220ms`, `slow 320ms`, `pressScale 0.98`, `enterCurve easeOutCubic`, `exitCurve easeInCubic`. Reduced motion = zero duration.

---

## 9. Breakpoints

`phone 600`, `tablet 900`, `desktop 1200`.

---

## 10. CSS variable names

Generator emits both the new semantic names and the legacy aliases used by `report.css`:

```
--tr-surface, --tr-surface-lowest, --tr-surface-low, --tr-surface-container,
--tr-surface-high, --tr-surface-highest, --tr-on-surface, --tr-on-surface-variant,
--tr-outline, --tr-outline-variant, --tr-brand-fill, --tr-on-brand-fill,
--tr-brand-ink, --tr-brand-container, --tr-on-brand-container,
--tr-secondary, --tr-on-secondary, --tr-secondary-container, --tr-on-secondary-container,
--tr-error, --tr-on-error, --tr-error-container, --tr-on-error-container,
--tr-focus, --tr-overlay, --tr-scrim,
--tr-success, --tr-success-bg, --tr-warning, --tr-warning-bg,
--tr-danger, --tr-danger-bg, --tr-critical, --tr-critical-bg,
--tr-info, --tr-info-bg, --tr-neutral, --tr-neutral-bg,
--tr-space-xxs ... --tr-space-colossal,
--tr-radius-sm ... --tr-radius-pill,
--tr-font-latin, --tr-font-arabic, --tr-font-cjk,
--tr-shadow-card, --tr-shadow-floating
```

Legacy aliases: `--primary` = `--tr-brand-ink`, `--secondary` = `--tr-secondary`, `--surface` = `--tr-surface`, `--surface-low` = `--tr-surface-low`, `--surface-card` = `--tr-surface-lowest`, `--surface-high` = `--tr-surface-high`, `--on-surface` = `--tr-on-surface`, `--on-variant` = `--tr-on-surface-variant`, `--outline` = `--tr-outline`, `--success`/`--success-bg`, `--warning`/`--warning-bg`, `--danger`/`--danger-bg`, `--critical`/`--critical-bg`, `--spacing-*`, `--radius-*`, `--font-body`, `--font-arabic`, `--font-cjk`.

Dark values are emitted under `@media (prefers-color-scheme: dark)` and `[data-theme="dark"]`; print under `@media print`.

---

## 11. Contrast obligations

Measured at definition time; `contrast-after.md` must show every pair.

- Normal text ≥ 4.5:1; large text ≥ 3:1; UI components/graphics ≥ 3:1.
- The A2 default pair `#1A1B1F` on `#10B981` is 6.78:1 (pass).
- The A2 alternative `#FFFFFF` on `#006C49` is 6.48:1 (pass).
- `#006C49` on `#FFFFFF` 6.48:1, on `#FAF9FE` 6.18:1, on `#F4F3F8` 5.87:1.
- `#5E5D69` on `#FFFFFF` 6.47:1, on `#FAF9FE` 6.18:1, on `#F4F3F8` 5.86:1.
- `#6C7A71` on `#FFFFFF` 4.51:1, on `#F4F3F8` 4.08:1 (UI only).
- `#10B981` on white/light surfaces is 2.54:1 and is forbidden for text/icons.
- Any pair that fails is listed with an owner decision; it does not ship.

---

## 12. Component file ownership

| Owner | Files |
|---|---|
| integration lead | `lib/src/tokens.dart`, `lib/src/components/common.dart`, `lib/design_system.dart`, `pubspec.yaml` |
| component-builder A | `lib/src/components/buttons.dart`, `inputs.dart`, `cards.dart`, `chips.dart`, `progress.dart` |
| component-builder B | `lib/src/components/navigation.dart`, `states.dart`, `overlays.dart`, `lists.dart` |
| component-builder C | `lib/src/components/results.dart`, `data_table.dart`, `tree_view.dart`, `admin_chrome.dart` |
| gallery-builder | `client/apps/ui_gallery/**` |
| harness-engineer | `tools/figma_fidelity/**`, `client/packages/design_system/test/fidelity_capture_test.dart` |
| test-engineer | `client/packages/design_system/test/components_test.dart`, `tokens_test.dart`, `client/apps/admin_app/test/source_scan_test.dart` |

Nobody edits another owner's files. Shared changes go through the integration lead.
