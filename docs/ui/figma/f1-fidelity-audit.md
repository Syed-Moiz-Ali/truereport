# F1 fidelity audit vs the Figma export

**Project:** TrueReport
**Phase:** F1.1 (fidelity-first rework)
**Date:** 5 November 2026
**Method:** every value below is read from the exported JSON
(`docs/ui/figma-export/**`) and the `@2x` previews, or measured by the harness.
No value is estimated from memory or from a design tool.

**Source of truth:** Figma look and component structure. Product rules still win
where a Figma value breaks a locked rule (content/privacy, measured contrast,
language coverage). Every approved deviation is in `deviations.md`.

---

## 1. Summary

| Area | Differences found | Reverted/added to exact Figma | Kept as approved deviation | Not changed (decision required) |
|---|---:|---:|---:|---:|
| Colour tokens | 1 | 1 | 0 | 0 |
| Shadow tokens | 5 | 5 | 0 | 0 |
| Radii tokens | 1 | 1 | 0 | 0 |
| Spacing tokens | 1 | 1 | 0 | 0 |
| Type tokens | 10 | 8 | 2 (B1) | 0 |
| Primary button | 5 | 4 | 1 (A2 label) | 0 (final colour choice is a separate decision) |
| Delivery card | 6 | 6 | 0 | 0 |
| Result selector | 7 | 5 | 2 (vocabulary, extra results) | 0 |
| Text field | 1 | 1 | 0 | 0 (contrast acceptance is a separate decision) |
| Chips/segments | 2 | 2 | 0 | 0 |
| Admin chrome | 4 | 3 | 0 | 1 (80 px Workshop header) |
| Data table | 2 | 2 | 0 | 0 |
| Offline banner | 1 | 1 | 0 | 0 |
| **Total** | **46** | **40** | **5** | **1** |

- **Components measured:** 3 (primary button, delivery card, result selector).
- **Figma-exact samples passing SSIM 0.98:** 3 of 3.
- **Unexplained geometry differences > 4 px:** 0. All remaining diff boxes are
  glyph/icon rasterisation inside the expected text areas (section 5).
- **Separate decisions that do not change a counted value:** the final primary
  button colour, whether to accept the Figma borderless text field, and the
  one-vs-two admin app choice.

---

## 2. Token differences and actions

### 2.1 Colour

| Token | Figma value | F1 value | Action |
|---|---|---|---|
| `color.light.surface` | `#FFFFFF` (all four screen roots) | `#FAF9FE` | **Reverted** to `#FFFFFF`. The 5-unit tint was not in any Figma frame. |
| `color.light.surfaceContainer` | `#F4F3F8` | `#F4F3F8` | Match. |
| `color.light.surfaceHigh` | `#EEEDF3` | `#EEEDF3` | Match. |
| `color.light.surfaceHighest` | `#E9E7ED` | `#E9E7ED` | Match. |
| `onSurface` | `#1A1B1F` (dominant) | `#1A1B1F` | Match. The delivery card uses `#1B1B25`; the exact card uses that value locally (see 4.2). |
| `onSurfaceVariant` | `#5E5D69` | `#5E5D69` | Match. |
| brand fill | `#10B981` | `#10B981` | Match. |
| brand ink | `#006C49` | `#006C49` | Match. |
| brand container | Figma tinted fills use `#10B9811A` / `#10B98126` | `#D9FBE8` | **Kept**; the tinted container is a product token, not a Figma component fill. No exact component uses it. Listed in `deviations.md` as not-approved and therefore not used by the exact variants. |

### 2.2 Shadows (reverted exactly)

| Token | F1 value | Figma `effects` | Action |
|---|---|---|---|
| `card` layer 1 | `0 2 8 0 #1A1B1F08` | `0 2 8 0 rgba(0,0,0,0.016)` | **Reverted** to `#00000004`. |
| `card` layer 2 | `0 14 40 0 #1A1B1F0F` | `0 14 40 0 rgba(0,0,0,0.043)` | **Reverted** to `#0000000B`. |
| `floating` layer 1 | `0 4 12 0 #1A1B1F0A` | `0 4 12 0 rgba(0,0,0,0.03)` | **Reverted** to `#00000008`. |
| `floating` layer 2 | `0 18 50 0 #1A1B1F14` | `0 18 50 0 rgba(0,0,0,0.08)` | **Reverted** to `#00000014`. |
| `button` (CTA) | `0 10 25 0 #10B9814D` | `0 10 25 0 rgba(16,185,129,0.30)` (SAVE button) | Match. |
| sign-in button | no token | `0 2 4 -2 rgba(0,0,0,0.10)` + `0 4 6 -1 rgba(0,0,0,0.10)` | **Added** `buttonSubtle`; applied to `AppButton` primary and the Figma-exact button. |

The shadow token is now verified by `client/packages/design_system/test/shadow_tokens_test.dart`,
which reads the Figma node `effects` and compares offset, blur, spread, colour
and alpha per layer.

**Blur verification:** Flutter `BoxShadow.blurRadius` and Figma/CSS `blur` are
both Gaussian sigma expressed as a radius; the harness crops the reference and
the render at the same DPR (2) and measured the residual. The delivery card
(blur 8/40) and the sign-in button (blur 4/6) both pass with the exact values;
no multiplier or correction factor was applied. Visual check: the card
`side-by-side.png` shows the same softness at the 32 px corners; the button
`side-by-side.png` shows the same 2-3 px falloff.

> **Correction, F2-A.2 (6 November 2026):** the visual check above was performed
> while `debugDisableShadows` was true, so the blurred shadows were solid blocks.
> The claim that the blur visually matched is withdrawn. F2-A.2 re-measured with
> real shadows and the corrected reference crop: primary button 0.99520→0.99622,
> delivery card 0.99198→0.99261, result selector 0.98340→0.98756. The token
> values were already exact; the residual is Flutter-vs-Figma shadow
> rasterisation. See `f2a2-report.md` and `deviations.md`.

### 2.3 Radii

| Token | Figma | F1 | Action |
|---|---|---|---|
| `sm/md/lg/xl/card/cardLarge` | 4/8/12/16/24/32 | same | Match. |
| large sheets/cards | **48** | absent | **Added** `radii.sheet = 48`. |
| pill | 9999 | 999 | Equivalent for all rendered sizes; `999` is used so Flutter clamps to a pill. |

### 2.4 Spacing

| Token | Figma | F1 | Action |
|---|---|---|---|
| scale | 2/4/6/8/12/16/20/24/32/40/48/64 | 2/4/8/12/16/20/24/32/40/48/64 | **Added** `spacing.micro = 6`; 6 is the most common Figma item gap (95 occurrences). |
| divider | 1 px `#F4F3F8` (Figma `HorizontalBorder`) | 1.5 px `#DAD9DF` | **Reverted**; `sizing.dividerWidth = 1`, data-table separators use `surfaceContainer` (`#F4F3F8`). The delivery-card divider stays `#EEEDF3` as drawn. |

### 2.5 Type

| Style | F1 | Figma (measured) | Action |
|---|---|---|---|
| display | 32/38 w800 -0.8 | 32/38 w800 -0.8 | Match. |
| headlineXl | 26/32 w800 -0.6 | 26/32 w800 -0.65 | **Reverted** -0.65. |
| headlineLg | 22/28 w700 -0.4 | 22/28 w700 -0.44 | **Reverted** -0.44. |
| headlineMd | 18/24 w700 -0.3 | 18/24 w700 -0.27 | **Reverted** -0.27. |
| titleLg | 16/22 w700 -0.2 | 16/22 w700 -0.16 | **Reverted** -0.16. |
| bodyLg | 16/24 w500 -0.1 | 16/24 w500 -0.16 | **Reverted** -0.16. |
| bodyMd | 14/20 w500 0 | 14/20 w500 -0.07 | **Reverted** -0.07. |
| labelLg | 14/18 w700 0 | 14/18 w700 -0.14 | **Reverted** -0.14. |
| labelMd | 12/16 w600 0.2 | 12/16 w600 0.24 | **Reverted** 0.24. |
| **11 px captions** | not allowed (B1) | 11/14 w600 0.44/0.55 (371 + 91 occurrences) | **Deviation B1** (owner-approved): product text stays >= 12 px. Figma-exact variants use `FigmaType.caption` (11/14) so the measured sample is exact. |
| **13 px body** | not in product scale | 13/18 w400 (289 occurrences) | **Deviation B1** for product copy; exact variants use `FigmaType.body` (13/18). |

The product token scale therefore equals Figma for every style it exposes; the
two Figma sizes below the product minimum live only in `FigmaType` and are used
only by test-only exact variants. See `deviations.md`.

### 2.6 Motion

The Figma JSON export contains no motion values (no prototype timing,
duration or easing). **Not verifiable from the export.** F1 motion
(120/220/320 ms, 0.98 press scale, ease-out/in cubic) is unchanged and is
listed as unverified, not as Figma-exact.

---

## 3. Primary button

**Figma node:** Login screen `Button`, 342 x 56 at (24, 472), pill, fill
`#10B981`, no stroke, horizontal gap 8, label `Sign In` white 14/18 w700
`-0.14`, icon 10.67 px white, subtle black shadow.

| Difference in F1 | Recommendation | Status |
|---|---|---|
| 1.5 dp deep-green border | Remove; Figma has no stroke | **Reverted** |
| Dark ink label `#1A1B1F` | Keep only as the A2 product default until the owner chooses; the Figma-exact variant uses white | **Kept as A2 deviation** (owner-approved in `decisions.md`) |
| 24 px generic icon | Exact variant uses the exported 10.67 px arrow; the generic `AppButton` keeps 24 px for app density | Exact variant fixed; generic button listed as product-only |
| No shadow | Added the Figma `buttonSubtle` to the exact and generic primary button | **Reverted/added** |
| Label/icon structure | `Row` centered with 8 px gap, correct order | **Rebuilt** |

**Measured options (see `contrast-after.md` and the gallery):**

| Option | Fill | Label | Ratio | Normal 4.5:1 | Large 3:1 | Large-text requirement |
|---|---|---|---:|---|---|---|
| 1. Figma exact | `#10B981` | `#FFFFFF` | 2.54:1 | FAIL | FAIL | Cannot reach 3:1 at any size |
| 2. Pressed green | `#059669` | `#FFFFFF` | 3.77:1 | FAIL | PASS | **>= 18.66 px bold** (we use 19/18 w800) |
| 3. Ink label (product default) | `#10B981` | `#1A1B1F` | 6.78:1 | PASS | PASS | Any size |
| 4. Deep green | `#006C49` | `#FFFFFF` | 6.48:1 | PASS | PASS | Any size |

Option 1 is the Figma-exact sample. The product default stays option 3 until
the owner chooses; **the decision is still open.**

---

## 4. Shared components

### 4.1 Delivery status card

**Figma node:** `Delivery Status Card`, 350 x 145 at (20, 399.5), radius 32,
white, padding 20, gap 16, two rows, radius 9999 chips, divider `#EEEDF3`.

| F1 | Figma | Action |
|---|---|---|
| Radius 24 | Radius 32 | **Rebuilt** with 32 |
| Title `Delivery status` (16/22) | No title; rows start directly | **Removed** from the exact card; the product card also has no title |
| Row icon 20 px + `StatusChip` with icon and tone background | 36 px `#F4F3F8` circle with 16.67/18.33 px `#5E5D69` glyph; status pill 28 px high, `#F4F3F8`, 8 px emerald dot, 12/16 w600 | **Rebuilt** with the exact glyphs copied from the export (`delivery_report_link.svg`, `delivery_workshop_copy.svg`) |
| `StatusChip` success background | Neutral chip fill + emerald dot | **Rebuilt** as `FigmaStatusPill`; `StatusChip` kept for other screens |
| No divider | 1 px `#EEEDF3` divider | **Added** |
| 20/24 padding, 8 gap | 20 padding, 16 gap | **Rebuilt** |
| Shadow `#1A1B1F08/0F` | black 1.6%/4.3% | **Reverted** |

Product variant: same structure and data positions, copy changed to
`Report link` / `Workshop copy` and `Sent` / `Synced` (content deviation; no
portal feature). Figma sample copy (`WhatsApp`, `Fleet Portal`) is kept only in
the guarded test fixture.

### 4.2 Result selector

**Figma node:** `Severity Pill-Shaped Toggle Group`, 350 x 70 at (20, 444):
11/14 w600 `INSPECTION STATUS` (0.55), gap 4, 350 x 52 pill, fill `#F4F3F8`,
6 px padding/gap, three 108.67 x 40 options, radius 9999. Selected: fill
`#FED7AA`, label `#1A1B1F` 12/16 w700, shadow `0 4 12 rgba(251,146,60,0.18)`.

| F1 | Figma | Action |
|---|---|---|
| Six independent tiles in a `Wrap`, radius 12, icon + label | Three-way pill, no icons | **Rebuilt** |
| 48 px options, 12/8 padding | 40 px options, 12/8 padding | Exact variant uses 40; product variant uses 48 (B2 target rule) |
| 1.5 dp outline border | No border | **Removed** |
| Six-result vocabulary | Figma `Pass` / `Minor` / `Major` | Exact fixture uses Figma labels; product uses `No issue observed` / `Attention recommended` / `Defect found` |
| No secondary row | Only three results drawn | **Added** a secondary chip row for `Not checked`, `Not applicable`, `Could not verify` in the same visual language (documented deviation) |

The product API is unchanged (`InspectionResultSelector` still takes
`labelBuilder`, `selected`, `onChanged`, optional `results`, `groupLabel`).

### 4.3 Other shared components

| Component | Difference | Action |
|---|---|---|
| `AppTextField` | 1.5 dp `outline` border added in F1; Figma fields are filled and borderless | **Border reverted**. Focus ring retained. Non-text contrast of the fill against white is 1.09:1 — owner decision needed (`deviations.md`). |
| `AppFilterChip` / `AppSegmentedControl` | 1.5 dp outline borders added in F1; Figma chips are fill-only | **Borders reverted**; focus ring retained. |
| `StatusChip` | `Wrap`, 20 px icon, 4/12 padding, no fixed height | Kept as the general product chip; Figma-exact status uses `FigmaStatusPill` (28 px, dot). |
| `AppCard` | Radius 24 only; no way to request 32/48 | Added optional `radius`; default stays 24. Shadow is now the exact Figma card shadow. |
| `AdminSidebar` / `AdminTopBar` / `_AdminBottomBar` | 1.5 dp `outlineVariant` end/top/bottom borders | **Removed**; Figma uses fill separation (`#F4F3F8`) and near-invisible strokes. |
| `AdminTopBar` height | 64 default; Figma Workshop is 80 | **Open**; needs a role skin (app-structure report). |
| `AppDataTable` | 1.5 dp `outlineVariant` separators and bordered mobile cards | **Reverted** to 1 px `#F4F3F8` (`surfaceContainer`), matching the Figma `HorizontalBorder`. |
| `OfflineBanner` | 1.5 dp warning bottom border | **Removed**. |
| `AppBottomNavDock` | Floating shadow token was `#1A1B1F0A/14` | **Reverted** via the floating shadow token. |

---

## 5. Measured Figma-exact results

All comparisons use the Figma node bounding box, DPR 2, white background, and
the real Plus Jakarta Sans fonts. Artifacts:
`docs/ui/figma/fidelity/component-samples/<sample>/`.

| Sample | Crop (logical) | SSIM | RMSE | ΔE2000 > 5 | Diff boxes | Gate |
|---|---|---:|---:|---:|---:|---|
| Primary button | 342 x 56 at (24, 472) | **0.99520** | 4.714 | 0.60% | 7 | PASS |
| Delivery card | 350 x 145 at (20, 399.5) | **0.99198** | 7.572 | 1.33% | 20 | PASS |
| Result selector | 350 x 70 at (20, 444) | **0.98340** | 8.269 | 2.21% | 20 | PASS |

**Diff-box interpretation (no unexplained geometry change > 4 px):**

- Button: 7 boxes, all inside the `Sign In` glyphs and the 10.67 px arrow;
  largest 10.5 x 6 px. Glyph antialiasing only.
- Card: 20 boxes, all inside the two title texts, the two chip labels, the two
  icons and the dot. The text widths match the Figma text nodes (WhatsApp
  81.39 logical / 163 px reference vs 162 px render). Largest box 47.5 x 13 px
  is the `WhatsApp` glyph run; no edge or background difference.
- Selector: 20 boxes, all inside the uppercase label and the three option
  labels. Largest 9.5 x 9 px. Background/pill/selected fill match.

No box is caused by a moved edge, a wrong radius, a wrong fill or a missing
element. The residual is font rasterisation, which cannot be made zero across
two renderers without shipping the Figma raster. This is reported, not hidden.

---

## 6. What could not be verified

- **Motion:** the Figma export has no motion data.
- **Arabic pixel fidelity:** there is no Arabic Figma frame; Arabic exact
  variants are structural only. Native shaping/RTL review is outstanding.
- **Dark mode:** not a Figma target; derived theme, unwrapped by the exact
  comparison.
- **Other components:** only the three gate components have a Figma-exact SSIM
  sample. The other shared components were rebuilt/reverted structurally but
  are not claimed as measured at 0.98.
- **Real devices/browsers:** not tested in this session; see the final report.
- **Figma font files:** the export names Plus Jakarta Sans; the bundled TTFs are
  the OFL files from the F1 bundle. The exact samples render with them and pass,
  but the Figma renderer's hinting is not identical.
