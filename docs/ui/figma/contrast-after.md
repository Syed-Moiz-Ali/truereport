# F1 token contrast audit (measured)

- **Status:** generated from `client/packages/design_system/tokens/tokens.json`.
- **Date:** 5 November 2026.
- **Method:** WCAG 2.x relative luminance in sRGB, measured by `tools/design_tokens/contrast.mjs`; no value is inferred from a design tool.
- **Thresholds:** normal text `4.5:1`, large text `3:1`, UI components and graphics `3:1`.
- **Reproduce:** `node tools/design_tokens/generate.mjs --write` then read this file; `node tools/design_tokens/generate.mjs --check` verifies all generated outputs are current.

## Summary

| Section | Pairs | Pass | Fail |
|---|---:|---:|---:|
| Base text / UI — light | 29 | 29 | 0 |
| Base text / UI — dark | 29 | 29 | 0 |
| A2 brand strategies | 40 | 38 | 2 |
| Status and severity — light | 6 | 6 | 0 |
| Status and severity — dark | 6 | 6 | 0 |
| Focus and borders — light | 12 | 6 | 6 |
| Focus and borders — dark | 12 | 6 | 6 |
| Public report — light | 10 | 10 | 0 |
| Public report — dark | 10 | 10 | 0 |
| **Total audited token pairs** | **154** | **140** | **14** |

**Result: 140 pass, 14 fail.** Every failing pair is listed below with its usage or exception.

The four prohibited raw `#10B981` text/icon pairs are listed separately at the end and are **not** counted as token pairs because the generator never emits `#10B981` as a text or icon token.

## Notes on scope

- `overlay` and `scrim` are translucent layers, not text backgrounds; no text/background pair is defined on them in the contract, so no pair is claimed.
- Shadow colours are decorative and are not text or UI boundaries; they are not contrast pairs.
- `disabled` has no dedicated colour token in `f1-token-api.md`; no disabled pair is claimed. `onSurfaceVariant` is audited above as the placeholder/hint token.
- Large-text rows use the same measured ratio; a `3:1` allowance would only be applied by the consuming component, never by lowering a normal-text row.
- **F1.1 usage:** the 12 `outlineVariant` divider pairs are no longer used as the sole boundary of an interactive control; decorative dividers were removed or reverted to the Figma `#F4F3F8` separator. They remain token pairs only.
- **F1.1 primary button:** the two emerald fill-boundary failures are the Figma fill vs a light surface. The product default carries a 6.78:1 ink label; option 1 (white) is 2.54:1 and is still an open owner decision. See the primary-button section below.

## Base text / UI — light

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Body text | onSurface | #1A1B1F | surface | #FFFFFF | 17.21:1 | 4.5:1 | PASS | Normal text on surface. |
| Muted / placeholder text | onSurfaceVariant | #5E5D69 | surface | #FFFFFF | 6.47:1 | 4.5:1 | PASS | Secondary text and input placeholder on surface. |
| Border / outline | outline | #6C7A71 | surface | #FFFFFF | 4.51:1 | 3.0:1 | PASS | UI boundary on surface; not normal text. |
| Body text | onSurface | #1A1B1F | surfaceLowest | #FFFFFF | 17.21:1 | 4.5:1 | PASS | Normal text on surfaceLowest. |
| Muted / placeholder text | onSurfaceVariant | #5E5D69 | surfaceLowest | #FFFFFF | 6.47:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceLowest. |
| Border / outline | outline | #6C7A71 | surfaceLowest | #FFFFFF | 4.51:1 | 3.0:1 | PASS | UI boundary on surfaceLowest; not normal text. |
| Body text | onSurface | #1A1B1F | surfaceLow | #F7F6FB | 16.00:1 | 4.5:1 | PASS | Normal text on surfaceLow. |
| Muted / placeholder text | onSurfaceVariant | #5E5D69 | surfaceLow | #F7F6FB | 6.02:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceLow. |
| Border / outline | outline | #6C7A71 | surfaceLow | #F7F6FB | 4.19:1 | 3.0:1 | PASS | UI boundary on surfaceLow; not normal text. |
| Body text | onSurface | #1A1B1F | surfaceContainer | #F4F3F8 | 15.59:1 | 4.5:1 | PASS | Normal text on surfaceContainer. |
| Muted / placeholder text | onSurfaceVariant | #5E5D69 | surfaceContainer | #F4F3F8 | 5.86:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceContainer. |
| Border / outline | outline | #6C7A71 | surfaceContainer | #F4F3F8 | 4.08:1 | 3.0:1 | PASS | UI boundary on surfaceContainer; not normal text. |
| Body text | onSurface | #1A1B1F | surfaceHigh | #EEEDF3 | 14.78:1 | 4.5:1 | PASS | Normal text on surfaceHigh. |
| Muted / placeholder text | onSurfaceVariant | #5E5D69 | surfaceHigh | #EEEDF3 | 5.56:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceHigh. |
| Border / outline | outline | #6C7A71 | surfaceHigh | #EEEDF3 | 3.87:1 | 3.0:1 | PASS | UI boundary on surfaceHigh; not normal text. |
| Body text | onSurface | #1A1B1F | surfaceHighest | #E9E7ED | 14.03:1 | 4.5:1 | PASS | Normal text on surfaceHighest. |
| Muted / placeholder text | onSurfaceVariant | #5E5D69 | surfaceHighest | #E9E7ED | 5.27:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceHighest. |
| Border / outline | outline | #6C7A71 | surfaceHighest | #E9E7ED | 3.67:1 | 3.0:1 | PASS | UI boundary on surfaceHighest; not normal text. |
| Secondary accent text | secondary | #3C4A42 | surface | #FFFFFF | 9.33:1 | 4.5:1 | PASS | Links and secondary labels on surface. |
| Error text | error | #A3231F | surface | #FFFFFF | 7.45:1 | 4.5:1 | PASS | Error text on surface. |
| Secondary accent text | secondary | #3C4A42 | surfaceLowest | #FFFFFF | 9.33:1 | 4.5:1 | PASS | Links and secondary labels on surfaceLowest. |
| Error text | error | #A3231F | surfaceLowest | #FFFFFF | 7.45:1 | 4.5:1 | PASS | Error text on surfaceLowest. |
| Secondary accent text | secondary | #3C4A42 | surfaceContainer | #F4F3F8 | 8.45:1 | 4.5:1 | PASS | Links and secondary labels on surfaceContainer. |
| Error text | error | #A3231F | surfaceContainer | #F4F3F8 | 6.75:1 | 4.5:1 | PASS | Error text on surfaceContainer. |
| Error label | onError | #FFFFFF | error | #A3231F | 7.45:1 | 4.5:1 | PASS | Text/icon on an error fill. |
| Error container text | onErrorContainer | #7F1D1D | errorContainer | #FBE9E7 | 8.55:1 | 4.5:1 | PASS | Text/icon on an error container. |
| Secondary label | onSecondary | #FFFFFF | secondary | #3C4A42 | 9.33:1 | 4.5:1 | PASS | Text/icon on a secondary fill. |
| Secondary container text | onSecondaryContainer | #464651 | secondaryContainer | #E3E1EF | 7.22:1 | 4.5:1 | PASS | Text/icon on a secondary container. |
| Inverse text | onInverseSurface | #F1F0F5 | inverseSurface | #2F3034 | 11.63:1 | 4.5:1 | PASS | Snackbar/inverse surface text. |

## Base text / UI — dark

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Body text | onSurface | #F1F0F5 | surface | #121114 | 16.60:1 | 4.5:1 | PASS | Normal text on surface. |
| Muted / placeholder text | onSurfaceVariant | #C7C5D3 | surface | #121114 | 11.07:1 | 4.5:1 | PASS | Secondary text and input placeholder on surface. |
| Border / outline | outline | #9A98A6 | surface | #121114 | 6.65:1 | 3.0:1 | PASS | UI boundary on surface; not normal text. |
| Body text | onSurface | #F1F0F5 | surfaceLowest | #0C0B0E | 17.31:1 | 4.5:1 | PASS | Normal text on surfaceLowest. |
| Muted / placeholder text | onSurfaceVariant | #C7C5D3 | surfaceLowest | #0C0B0E | 11.55:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceLowest. |
| Border / outline | outline | #9A98A6 | surfaceLowest | #0C0B0E | 6.93:1 | 3.0:1 | PASS | UI boundary on surfaceLowest; not normal text. |
| Body text | onSurface | #F1F0F5 | surfaceLow | #1A191E | 15.41:1 | 4.5:1 | PASS | Normal text on surfaceLow. |
| Muted / placeholder text | onSurfaceVariant | #C7C5D3 | surfaceLow | #1A191E | 10.28:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceLow. |
| Border / outline | outline | #9A98A6 | surfaceLow | #1A191E | 6.17:1 | 3.0:1 | PASS | UI boundary on surfaceLow; not normal text. |
| Body text | onSurface | #F1F0F5 | surfaceContainer | #232128 | 14.04:1 | 4.5:1 | PASS | Normal text on surfaceContainer. |
| Muted / placeholder text | onSurfaceVariant | #C7C5D3 | surfaceContainer | #232128 | 9.36:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceContainer. |
| Border / outline | outline | #9A98A6 | surfaceContainer | #232128 | 5.62:1 | 3.0:1 | PASS | UI boundary on surfaceContainer; not normal text. |
| Body text | onSurface | #F1F0F5 | surfaceHigh | #2A282F | 12.84:1 | 4.5:1 | PASS | Normal text on surfaceHigh. |
| Muted / placeholder text | onSurfaceVariant | #C7C5D3 | surfaceHigh | #2A282F | 8.56:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceHigh. |
| Border / outline | outline | #9A98A6 | surfaceHigh | #2A282F | 5.14:1 | 3.0:1 | PASS | UI boundary on surfaceHigh; not normal text. |
| Body text | onSurface | #F1F0F5 | surfaceHighest | #323036 | 11.49:1 | 4.5:1 | PASS | Normal text on surfaceHighest. |
| Muted / placeholder text | onSurfaceVariant | #C7C5D3 | surfaceHighest | #323036 | 7.67:1 | 4.5:1 | PASS | Secondary text and input placeholder on surfaceHighest. |
| Border / outline | outline | #9A98A6 | surfaceHighest | #323036 | 4.60:1 | 3.0:1 | PASS | UI boundary on surfaceHighest; not normal text. |
| Secondary accent text | secondary | #C7C5D3 | surface | #121114 | 11.07:1 | 4.5:1 | PASS | Links and secondary labels on surface. |
| Error text | error | #FFB4AB | surface | #121114 | 11.08:1 | 4.5:1 | PASS | Error text on surface. |
| Secondary accent text | secondary | #C7C5D3 | surfaceLowest | #0C0B0E | 11.55:1 | 4.5:1 | PASS | Links and secondary labels on surfaceLowest. |
| Error text | error | #FFB4AB | surfaceLowest | #0C0B0E | 11.56:1 | 4.5:1 | PASS | Error text on surfaceLowest. |
| Secondary accent text | secondary | #C7C5D3 | surfaceContainer | #232128 | 9.36:1 | 4.5:1 | PASS | Links and secondary labels on surfaceContainer. |
| Error text | error | #FFB4AB | surfaceContainer | #232128 | 9.37:1 | 4.5:1 | PASS | Error text on surfaceContainer. |
| Error label | onError | #690005 | error | #FFB4AB | 7.72:1 | 4.5:1 | PASS | Text/icon on an error fill. |
| Error container text | onErrorContainer | #FFDAD6 | errorContainer | #93000A | 7.24:1 | 4.5:1 | PASS | Text/icon on an error container. |
| Secondary label | onSecondary | #1B1B25 | secondary | #C7C5D3 | 10.04:1 | 4.5:1 | PASS | Text/icon on a secondary fill. |
| Secondary container text | onSecondaryContainer | #E3E1EF | secondaryContainer | #464651 | 7.22:1 | 4.5:1 | PASS | Text/icon on a secondary container. |
| Inverse text | onInverseSurface | #1A1B1F | inverseSurface | #E9E7ED | 14.03:1 | 4.5:1 | PASS | Snackbar/inverse surface text. |

## A2 brand strategies

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Brand fill label | emeraldFill.onFill | #1A1B1F | emeraldFill.fill | #10B981 | 6.78:1 | 4.5:1 | PASS | Normal text/icon on the emeraldFill brand fill. |
| Brand container text | emeraldFill.onContainer | #00422B | emeraldFill.container | #D9FBE8 | 10.43:1 | 4.5:1 | PASS | Normal text/icon on the emeraldFill brand container. |
| Brand ink text/icon | emeraldFill.ink | #006C49 | surface | #FFFFFF | 6.48:1 | 4.5:1 | PASS | Brand text/icon on surface. |
| Brand ink text/icon | emeraldFill.ink | #006C49 | surfaceLowest | #FFFFFF | 6.48:1 | 4.5:1 | PASS | Brand text/icon on surfaceLowest. |
| Brand ink text/icon | emeraldFill.ink | #006C49 | surfaceLow | #F7F6FB | 6.03:1 | 4.5:1 | PASS | Brand text/icon on surfaceLow. |
| Brand ink text/icon | emeraldFill.ink | #006C49 | surfaceContainer | #F4F3F8 | 5.87:1 | 4.5:1 | PASS | Brand text/icon on surfaceContainer. |
| Brand ink text/icon | emeraldFill.ink | #006C49 | surfaceHigh | #EEEDF3 | 5.57:1 | 4.5:1 | PASS | Brand text/icon on surfaceHigh. |
| Brand ink text/icon | emeraldFill.ink | #006C49 | surfaceHighest | #E9E7ED | 5.28:1 | 4.5:1 | PASS | Brand text/icon on surfaceHighest. |
| Brand fill boundary | emeraldFill.fill | #10B981 | surface | #FFFFFF | 2.54:1 | 3.0:1 | FAIL | Approved emerald fill against a light surface. Not a text/icon token; do not rely on fill alone to identify a control. EXCEPTION: Approved A2 fill; the button carries a 6.78:1 ink label and a non-colour label. Never use this fill as text/icon. |
| Brand fill boundary | emeraldFill.fill | #10B981 | surfaceLowest | #FFFFFF | 2.54:1 | 3.0:1 | FAIL | Approved emerald fill against a light surface. Not a text/icon token; do not rely on fill alone to identify a control. EXCEPTION: Approved A2 fill; the button carries a 6.78:1 ink label and a non-colour label. Never use this fill as text/icon. |
| Brand fill label | deepGreenFill.onFill | #FFFFFF | deepGreenFill.fill | #006C49 | 6.48:1 | 4.5:1 | PASS | Normal text/icon on the deepGreenFill brand fill. |
| Brand container text | deepGreenFill.onContainer | #00422B | deepGreenFill.container | #D9FBE8 | 10.43:1 | 4.5:1 | PASS | Normal text/icon on the deepGreenFill brand container. |
| Brand ink text/icon | deepGreenFill.ink | #006C49 | surface | #FFFFFF | 6.48:1 | 4.5:1 | PASS | Brand text/icon on surface. |
| Brand ink text/icon | deepGreenFill.ink | #006C49 | surfaceLowest | #FFFFFF | 6.48:1 | 4.5:1 | PASS | Brand text/icon on surfaceLowest. |
| Brand ink text/icon | deepGreenFill.ink | #006C49 | surfaceLow | #F7F6FB | 6.03:1 | 4.5:1 | PASS | Brand text/icon on surfaceLow. |
| Brand ink text/icon | deepGreenFill.ink | #006C49 | surfaceContainer | #F4F3F8 | 5.87:1 | 4.5:1 | PASS | Brand text/icon on surfaceContainer. |
| Brand ink text/icon | deepGreenFill.ink | #006C49 | surfaceHigh | #EEEDF3 | 5.57:1 | 4.5:1 | PASS | Brand text/icon on surfaceHigh. |
| Brand ink text/icon | deepGreenFill.ink | #006C49 | surfaceHighest | #E9E7ED | 5.28:1 | 4.5:1 | PASS | Brand text/icon on surfaceHighest. |
| Brand fill boundary | deepGreenFill.fill | #006C49 | surface | #FFFFFF | 6.48:1 | 3.0:1 | PASS | Brand fill boundary against surface. |
| Brand fill boundary | deepGreenFill.fill | #006C49 | surfaceLowest | #FFFFFF | 6.48:1 | 3.0:1 | PASS | Brand fill boundary against surfaceLowest. |
| Brand fill label | emeraldFill.onFill | #002113 | emeraldFill.fill | #4EDEA3 | 10.03:1 | 4.5:1 | PASS | Normal text/icon on the emeraldFill brand fill. |
| Brand container text | emeraldFill.onContainer | #B7F5D8 | emeraldFill.container | #005236 | 7.55:1 | 4.5:1 | PASS | Normal text/icon on the emeraldFill brand container. |
| Brand ink text/icon | emeraldFill.ink | #6FFBBE | surface | #121114 | 14.53:1 | 4.5:1 | PASS | Brand text/icon on surface. |
| Brand ink text/icon | emeraldFill.ink | #6FFBBE | surfaceLowest | #0C0B0E | 15.16:1 | 4.5:1 | PASS | Brand text/icon on surfaceLowest. |
| Brand ink text/icon | emeraldFill.ink | #6FFBBE | surfaceLow | #1A191E | 13.50:1 | 4.5:1 | PASS | Brand text/icon on surfaceLow. |
| Brand ink text/icon | emeraldFill.ink | #6FFBBE | surfaceContainer | #232128 | 12.29:1 | 4.5:1 | PASS | Brand text/icon on surfaceContainer. |
| Brand ink text/icon | emeraldFill.ink | #6FFBBE | surfaceHigh | #2A282F | 11.24:1 | 4.5:1 | PASS | Brand text/icon on surfaceHigh. |
| Brand ink text/icon | emeraldFill.ink | #6FFBBE | surfaceHighest | #323036 | 10.06:1 | 4.5:1 | PASS | Brand text/icon on surfaceHighest. |
| Brand fill boundary | emeraldFill.fill | #4EDEA3 | surface | #121114 | 11.02:1 | 3.0:1 | PASS | Brand fill boundary against surface. |
| Brand fill boundary | emeraldFill.fill | #4EDEA3 | surfaceLowest | #0C0B0E | 11.50:1 | 3.0:1 | PASS | Brand fill boundary against surfaceLowest. |
| Brand fill label | deepGreenFill.onFill | #002113 | deepGreenFill.fill | #6FFBBE | 13.22:1 | 4.5:1 | PASS | Normal text/icon on the deepGreenFill brand fill. |
| Brand container text | deepGreenFill.onContainer | #B7F5D8 | deepGreenFill.container | #005236 | 7.55:1 | 4.5:1 | PASS | Normal text/icon on the deepGreenFill brand container. |
| Brand ink text/icon | deepGreenFill.ink | #6FFBBE | surface | #121114 | 14.53:1 | 4.5:1 | PASS | Brand text/icon on surface. |
| Brand ink text/icon | deepGreenFill.ink | #6FFBBE | surfaceLowest | #0C0B0E | 15.16:1 | 4.5:1 | PASS | Brand text/icon on surfaceLowest. |
| Brand ink text/icon | deepGreenFill.ink | #6FFBBE | surfaceLow | #1A191E | 13.50:1 | 4.5:1 | PASS | Brand text/icon on surfaceLow. |
| Brand ink text/icon | deepGreenFill.ink | #6FFBBE | surfaceContainer | #232128 | 12.29:1 | 4.5:1 | PASS | Brand text/icon on surfaceContainer. |
| Brand ink text/icon | deepGreenFill.ink | #6FFBBE | surfaceHigh | #2A282F | 11.24:1 | 4.5:1 | PASS | Brand text/icon on surfaceHigh. |
| Brand ink text/icon | deepGreenFill.ink | #6FFBBE | surfaceHighest | #323036 | 10.06:1 | 4.5:1 | PASS | Brand text/icon on surfaceHighest. |
| Brand fill boundary | deepGreenFill.fill | #6FFBBE | surface | #121114 | 14.53:1 | 3.0:1 | PASS | Brand fill boundary against surface. |
| Brand fill boundary | deepGreenFill.fill | #6FFBBE | surfaceLowest | #0C0B0E | 15.16:1 | 3.0:1 | PASS | Brand fill boundary against surfaceLowest. |

## Status and severity — light

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Status neutral | neutral.foreground | #3F4A54 | neutral.background | #EDF1F3 | 7.97:1 | 4.5:1 | PASS | Status chip text on neutral background; severity minor uses this pair. |
| Status info | info.foreground | #1D5C8A | info.background | #E5F0F8 | 6.15:1 | 4.5:1 | PASS | Status chip text on info background. |
| Status success | success.foreground | #1F6B45 | success.background | #E6F3EC | 5.67:1 | 4.5:1 | PASS | Status chip text on success background. |
| Status warning | warning.foreground | #8A5A00 | warning.background | #FFF4D6 | 5.41:1 | 4.5:1 | PASS | Status chip text on warning background; severity moderate uses this pair. |
| Status danger | danger.foreground | #A3231F | danger.background | #FBE9E7 | 6.36:1 | 4.5:1 | PASS | Status chip text on danger background; severity major uses this pair. |
| Status critical | critical.foreground | #7F1D1D | critical.background | #F7DADA | 7.63:1 | 4.5:1 | PASS | Status chip text on critical background; severity safetyCritical uses this pair. |

## Status and severity — dark

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Status neutral | neutral.foreground | #C3D4DA | neutral.background | #26373C | 8.12:1 | 4.5:1 | PASS | Status chip text on neutral background; severity minor uses this pair. |
| Status info | info.foreground | #B7DCF7 | info.background | #173247 | 9.22:1 | 4.5:1 | PASS | Status chip text on info background. |
| Status success | success.foreground | #B5E8C9 | success.background | #173D2B | 8.83:1 | 4.5:1 | PASS | Status chip text on success background. |
| Status warning | warning.foreground | #FFDFA3 | warning.background | #463611 | 9.09:1 | 4.5:1 | PASS | Status chip text on warning background; severity moderate uses this pair. |
| Status danger | danger.foreground | #FFC4BD | danger.background | #4A1F1C | 9.23:1 | 4.5:1 | PASS | Status chip text on danger background; severity major uses this pair. |
| Status critical | critical.foreground | #FFD0D0 | critical.background | #551C1C | 9.68:1 | 4.5:1 | PASS | Status chip text on critical background; severity safetyCritical uses this pair. |

## Focus and borders — light

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Focus ring | focus | #0B63CE | surface | #FFFFFF | 5.69:1 | 3.0:1 | PASS | Focus indicator on surface. |
| Divider / decorative outline | outlineVariant | #DAD9DF | surface | #FFFFFF | 1.40:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surface. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #0B63CE | surfaceLowest | #FFFFFF | 5.69:1 | 3.0:1 | PASS | Focus indicator on surfaceLowest. |
| Divider / decorative outline | outlineVariant | #DAD9DF | surfaceLowest | #FFFFFF | 1.40:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceLowest. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #0B63CE | surfaceLow | #F7F6FB | 5.29:1 | 3.0:1 | PASS | Focus indicator on surfaceLow. |
| Divider / decorative outline | outlineVariant | #DAD9DF | surfaceLow | #F7F6FB | 1.30:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceLow. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #0B63CE | surfaceContainer | #F4F3F8 | 5.15:1 | 3.0:1 | PASS | Focus indicator on surfaceContainer. |
| Divider / decorative outline | outlineVariant | #DAD9DF | surfaceContainer | #F4F3F8 | 1.27:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceContainer. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #0B63CE | surfaceHigh | #EEEDF3 | 4.89:1 | 3.0:1 | PASS | Focus indicator on surfaceHigh. |
| Divider / decorative outline | outlineVariant | #DAD9DF | surfaceHigh | #EEEDF3 | 1.21:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceHigh. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #0B63CE | surfaceHighest | #E9E7ED | 4.64:1 | 3.0:1 | PASS | Focus indicator on surfaceHighest. |
| Divider / decorative outline | outlineVariant | #DAD9DF | surfaceHighest | #E9E7ED | 1.14:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceHighest. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |

## Focus and borders — dark

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Focus ring | focus | #9CCBFF | surface | #121114 | 11.11:1 | 3.0:1 | PASS | Focus indicator on surface. |
| Divider / decorative outline | outlineVariant | #4A4854 | surface | #121114 | 2.10:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surface. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #9CCBFF | surfaceLowest | #0C0B0E | 11.59:1 | 3.0:1 | PASS | Focus indicator on surfaceLowest. |
| Divider / decorative outline | outlineVariant | #4A4854 | surfaceLowest | #0C0B0E | 2.19:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceLowest. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #9CCBFF | surfaceLow | #1A191E | 10.32:1 | 3.0:1 | PASS | Focus indicator on surfaceLow. |
| Divider / decorative outline | outlineVariant | #4A4854 | surfaceLow | #1A191E | 1.95:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceLow. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #9CCBFF | surfaceContainer | #232128 | 9.40:1 | 3.0:1 | PASS | Focus indicator on surfaceContainer. |
| Divider / decorative outline | outlineVariant | #4A4854 | surfaceContainer | #232128 | 1.78:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceContainer. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #9CCBFF | surfaceHigh | #2A282F | 8.59:1 | 3.0:1 | PASS | Focus indicator on surfaceHigh. |
| Divider / decorative outline | outlineVariant | #4A4854 | surfaceHigh | #2A282F | 1.63:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceHigh. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |
| Focus ring | focus | #9CCBFF | surfaceHighest | #323036 | 7.69:1 | 3.0:1 | PASS | Focus indicator on surfaceHighest. |
| Divider / decorative outline | outlineVariant | #4A4854 | surfaceHighest | #323036 | 1.46:1 | 3.0:1 | FAIL | Decorative divider or non-essential outline on surfaceHighest. EXCEPTION: Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable. |

## Public report — light

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Report body | --on-surface | #1A1B1F | --surface | #FFFFFF | 17.21:1 | 4.5:1 | PASS | report.css body text and headings. |
| Report muted text | --on-variant | #5E5D69 | --surface | #FFFFFF | 6.47:1 | 4.5:1 | PASS | report.css muted, metadata, footer and table heading text. |
| Report primary text | --primary | #006C49 | --surface-card | #FFFFFF | 6.48:1 | 4.5:1 | PASS | report.css .stat and primary text on a card. |
| Report link | --secondary | #3C4A42 | --surface | #FFFFFF | 9.33:1 | 4.5:1 | PASS | report.css links. |
| Report primary button | --surface-card | #FFFFFF | --primary | #006C49 | 6.48:1 | 4.5:1 | PASS | report.css .button.primary label on the legacy primary fill. |
| Report success badge | --success | #1F6B45 | --success-bg | #E6F3EC | 5.67:1 | 4.5:1 | PASS | report.css .badge.success. |
| Report warning badge | --warning | #8A5A00 | --warning-bg | #FFF4D6 | 5.41:1 | 4.5:1 | PASS | report.css .badge.warning. |
| Report danger badge | --danger | #A3231F | --danger-bg | #FBE9E7 | 6.36:1 | 4.5:1 | PASS | report.css .badge.danger. |
| Report critical badge | --critical | #7F1D1D | --critical-bg | #F7DADA | 7.63:1 | 4.5:1 | PASS | report.css .badge.critical. |
| Report neutral badge | --on-variant | #5E5D69 | --surface-high | #EEEDF3 | 5.56:1 | 4.5:1 | PASS | report.css .badge default. |

## Public report — dark

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Report body | --on-surface | #F1F0F5 | --surface | #121114 | 16.60:1 | 4.5:1 | PASS | report.css body text and headings. |
| Report muted text | --on-variant | #C7C5D3 | --surface | #121114 | 11.07:1 | 4.5:1 | PASS | report.css muted, metadata, footer and table heading text. |
| Report primary text | --primary | #6FFBBE | --surface-card | #0C0B0E | 15.16:1 | 4.5:1 | PASS | report.css .stat and primary text on a card. |
| Report link | --secondary | #C7C5D3 | --surface | #121114 | 11.07:1 | 4.5:1 | PASS | report.css links. |
| Report primary button | --surface-card | #0C0B0E | --primary | #6FFBBE | 15.16:1 | 4.5:1 | PASS | report.css .button.primary label on the legacy primary fill. |
| Report success badge | --success | #B5E8C9 | --success-bg | #173D2B | 8.83:1 | 4.5:1 | PASS | report.css .badge.success. |
| Report warning badge | --warning | #FFDFA3 | --warning-bg | #463611 | 9.09:1 | 4.5:1 | PASS | report.css .badge.warning. |
| Report danger badge | --danger | #FFC4BD | --danger-bg | #4A1F1C | 9.23:1 | 4.5:1 | PASS | report.css .badge.danger. |
| Report critical badge | --critical | #FFD0D0 | --critical-bg | #551C1C | 9.68:1 | 4.5:1 | PASS | report.css .badge.critical. |
| Report neutral badge | --on-variant | #C7C5D3 | --surface-high | #2A282F | 8.56:1 | 4.5:1 | PASS | report.css .badge default. |

## Primary button options (A2 re-opened, measured)

Measured from the four fills the owner asked to see on the Figma primary button. WCAG large text is >= 18.66 px bold (14 pt) or >= 24 px regular; the threshold is 3:1 for large text and 4.5:1 for normal text.

| Option | Fill | Label | Measured ratio | Normal 4.5:1 | Large 3:1 | Size needed to count as large |
|---|---|---|---:|---|---|---|
| 1. Figma exact | #10B981 | #FFFFFF | 2.54:1 | FAIL | FAIL | Cannot reach 3:1 at any size |
| 2. Figma pressed green | #059669 | #FFFFFF | 3.77:1 | FAIL | PASS | >= 18.66 px bold or >= 24 px regular (current: 19/18 w800 (large)) |
| 3. Ink label (product default) | #10B981 | #1A1B1F | 6.78:1 | PASS | PASS | Any size |
| 4. Deep green | #006C49 | #FFFFFF | 6.48:1 | PASS | PASS | Any size |

Option 1 is the Figma-exact variant used only by the gallery and the fidelity harness. The product default remains option 3 until the owner chooses; option 2 is only acceptable as large text.

## Prohibited raw emerald text/icon pairs (not counted)

These pairs are measured to document why `#10B981` is fill-only. They are not emitted as text or icon tokens.

| Foreground | Background token | Background hex | Ratio | AA threshold | Result | Decision |
|---|---|---|---:|---:|---|---|
| #10B981 | surface | #FFFFFF | 2.54:1 | 4.5:1 | FAIL | Prohibited text/icon use. Emitted only as the emerald brand fill. |
| #10B981 | surfaceLowest | #FFFFFF | 2.54:1 | 4.5:1 | FAIL | Prohibited text/icon use. Emitted only as the emerald brand fill. |
| #10B981 | surfaceContainer | #F4F3F8 | 2.30:1 | 4.5:1 | FAIL | Prohibited text/icon use. Emitted only as the emerald brand fill. |
| #10B981 | surfaceHighest | #E9E7ED | 2.07:1 | 4.5:1 | FAIL | Prohibited text/icon use. Emitted only as the emerald brand fill. |

## Severity mapping check

| Severity | Tone | Measured pair | Light ratio | Dark ratio | Result |
|---|---|---|---:|---:|---|
| minor | neutral | neutral.foreground on neutral.background | 7.97:1 | 8.12:1 | PASS |
| moderate | warning | warning.foreground on warning.background | 5.41:1 | 9.09:1 | PASS |
| major | danger | danger.foreground on danger.background | 6.36:1 | 9.23:1 | PASS |
| safetyCritical | critical | critical.foreground on critical.background | 7.63:1 | 9.68:1 | PASS |

## Inspection-result mapping check

`InspectionResult` reuses the status tones above; it adds no colours, so its contrast is the measured status pair for its tone.

| Result | Tone | Icon |
|---|---|---|
| noIssueObserved | neutral | check_circle_outline |
| attentionRecommended | warning | info_outline |
| defectFound | danger | warning_amber_rounded |
| notChecked | neutral | remove_circle_outline |
| notApplicable | neutral | block |
| couldNotVerify | warning | help_outline |

## Reproduce

```powershell
node tools/design_tokens/generate.mjs --write
node tools/design_tokens/generate.mjs --check
```

The generator reads `client/packages/design_system/tokens/tokens.json` and writes `tokens.g.dart`, `tokens.g.css` and this report. It exits non-zero on stale output when `--check` is used.
