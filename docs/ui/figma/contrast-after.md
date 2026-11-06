# F1 token contrast audit (measured, light-only)

- **Status:** generated from `client/packages/design_system/tokens/tokens.json` (light theme only; C0 Workstream B removed the dark theme).
- **Date:** 6 November 2026.
- **F2-B.2 note (6 November 2026):** white on `#10B981` (~2.3:1) remains the owner-accepted **I1** risk (F2-A.1 I1 carried over). Deeper-green pairings pass. No new token pairs added by F2-B.2.
- **Method:** WCAG 2.x relative luminance in sRGB, measured by `tools/design_tokens/contrast.mjs`; no value is inferred from a design tool.
- **Thresholds:** normal text `4.5:1`, large text `3:1`, UI components and graphics `3:1`.
- **Reproduce:** `node tools/design_tokens/generate.mjs --write` then read this file; `node tools/design_tokens/generate.mjs --check` verifies all generated outputs are current.

## Summary

| Section | Pairs | Pass | Fail |
|---|---:|---:|---:|
| Base text / UI — light | 29 | 29 | 0 |
| A2 brand strategies | 20 | 18 | 2 |
| Status and severity — light | 6 | 6 | 0 |
| Focus and borders — light | 12 | 6 | 6 |
| Public report — light | 10 | 10 | 0 |
| F2-A technician screens - light | 18 | 17 | 1 |
| **Total audited token pairs** | **95** | **86** | **9** |

**Result: 86 pass, 9 fail.** Every failing pair is listed below with its usage or exception.

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

## Status and severity — light

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Status neutral | neutral.foreground | #3F4A54 | neutral.background | #EDF1F3 | 7.97:1 | 4.5:1 | PASS | Status chip text on neutral background; severity minor uses this pair. |
| Status info | info.foreground | #1D5C8A | info.background | #E5F0F8 | 6.15:1 | 4.5:1 | PASS | Status chip text on info background. |
| Status success | success.foreground | #1F6B45 | success.background | #E6F3EC | 5.67:1 | 4.5:1 | PASS | Status chip text on success background. |
| Status warning | warning.foreground | #8A5A00 | warning.background | #FFF4D6 | 5.41:1 | 4.5:1 | PASS | Status chip text on warning background; severity moderate uses this pair. |
| Status danger | danger.foreground | #A3231F | danger.background | #FBE9E7 | 6.36:1 | 4.5:1 | PASS | Status chip text on danger background; severity major uses this pair. |
| Status critical | critical.foreground | #7F1D1D | critical.background | #F7DADA | 7.63:1 | 4.5:1 | PASS | Status chip text on critical background; severity safetyCritical uses this pair. |

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

## F2-A technician screens - light

| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |
|---|---|---|---|---:|---:|---:|---|---|
| Body text | onSurface | #1A1B1F | surface | #FFFFFF | 17.21:1 | 4.5:1 | PASS | F2-A screen body text. |
| Muted text | onSurfaceVariant | #5E5D69 | surface | #FFFFFF | 6.47:1 | 4.5:1 | PASS | F2-A labels and secondary text. |
| Muted text on field fill | onSurfaceVariant | #5E5D69 | surfaceContainer | #F4F3F8 | 5.86:1 | 4.5:1 | PASS | F2-A field labels/hints on the filled input. |
| Muted text on nav surface | onSurfaceVariant | #5E5D69 | surfaceLowest | #FFFFFF | 6.47:1 | 4.5:1 | PASS | F2-A dock unselected label. |
| Brand ink text/icon | emeraldFill.ink | #006C49 | surface | #FFFFFF | 6.48:1 | 4.5:1 | PASS | F2-A icons and links on white. |
| Brand container text | emeraldFill.onContainer | #00422B | emeraldFill.container | #D9FBE8 | 10.43:1 | 4.5:1 | PASS | F2-A selected chip and icon tile label. |
| Primary small label | emeraldFill.onFill | #1A1B1F | emeraldFill.fill | #10B981 | 6.78:1 | 4.5:1 | PASS | P1 option 3: smaller emerald buttons use the ink label. |
| Primary large label | onPrimaryLarge | #FFFFFF | primaryLarge | #059669 | 3.77:1 | 3.0:1 | PASS | P1 option 2: 19 px bold large CTA label. EXCEPTION: Owner-approved large-text pair (3.77:1 light) with a 19 px bold label. |
| Primary large fill boundary | primaryLarge | #059669 | surface | #FFFFFF | 3.77:1 | 3.0:1 | PASS | P1 option 2 button boundary on the page. |
| Field fill boundary | surfaceContainer | #F4F3F8 | surface | #FFFFFF | 1.10:1 | 3.0:1 | FAIL | Borderless filled field boundary. EXCEPTION: Accepted accessibility risk P2: visible label above and F1 focus ring carry the affordance. |
| Focus ring | focus | #0B63CE | surface | #FFFFFF | 5.69:1 | 3.0:1 | PASS | F2-A focus ring around fields and actions. |
| Error text | error | #A3231F | surface | #FFFFFF | 7.45:1 | 4.5:1 | PASS | F2-A validation text. |
| Neutral status | status.neutral.fg | #3F4A54 | status.neutral.bg | #EDF1F3 | 7.97:1 | 4.5:1 | PASS | F2-A status/result chip. |
| Info status | status.info.fg | #1D5C8A | status.info.bg | #E5F0F8 | 6.15:1 | 4.5:1 | PASS | F2-A in-progress status chip. |
| Success status | status.success.fg | #1F6B45 | status.success.bg | #E6F3EC | 5.67:1 | 4.5:1 | PASS | F2-A no-issue-observed count chip. |
| Warning status | status.warning.fg | #8A5A00 | status.warning.bg | #FFF4D6 | 5.41:1 | 4.5:1 | PASS | F2-A attention count chip. |
| Danger status | status.danger.fg | #A3231F | status.danger.bg | #FBE9E7 | 6.36:1 | 4.5:1 | PASS | F2-A defect count chip. |
| Critical status | status.critical.fg | #7F1D1D | status.critical.bg | #F7DADA | 7.63:1 | 4.5:1 | PASS | F2-A critical severity chip. |

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

## Severity mapping check (light-only)

| Severity | Tone | Measured pair | Light ratio | Result |
|---|---|---|---:|---|
| minor | neutral | neutral.foreground on neutral.background | 7.97:1 | PASS |
| moderate | warning | warning.foreground on warning.background | 5.41:1 | PASS |
| major | danger | danger.foreground on danger.background | 6.36:1 | PASS |
| safetyCritical | critical | critical.foreground on critical.background | 7.63:1 | PASS |

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
