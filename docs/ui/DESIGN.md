---
name: Field Technician Inspection System
colors:
  surface: '#faf9fe'
  surface-dim: '#dad9df'
  surface-bright: '#faf9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f8'
  surface-container: '#eeedf3'
  surface-container-high: '#e9e7ed'
  surface-container-highest: '#e3e2e7'
  on-surface: '#1a1b1f'
  on-surface-variant: '#3c4a42'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f1f0f5'
  outline: '#6c7a71'
  outline-variant: '#bbcabf'
  surface-tint: '#006c49'
  primary: '#006c49'
  on-primary: '#ffffff'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#4edea3'
  secondary: '#5e5d69'
  on-secondary: '#ffffff'
  secondary-container: '#e1deec'
  on-secondary-container: '#62616d'
  tertiary: '#b91a24'
  on-tertiary: '#ffffff'
  tertiary-container: '#ff7a73'
  on-tertiary-container: '#79000e'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#e3e1ef'
  secondary-fixed-dim: '#c7c5d3'
  on-secondary-fixed: '#1b1b25'
  on-secondary-fixed-variant: '#464651'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ad'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930013'
  background: '#faf9fe'
  on-background: '#1a1b1f'
  surface-variant: '#e3e2e7'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '800'
    lineHeight: 32px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 22px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: -0.005em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
    letterSpacing: -0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system is engineered for field automotive technicians, service advisors, and fleet inspectors who require surgical precision, rapid one-handed data entry, and zero cognitive friction under bright shop lights or harsh outdoor daylight.

The design philosophy combines Swiss modernism with Apple-caliber ergonomic minimalism:
- **Purity & Reduction:** Pure `#FFFFFF` surfaces throughout. Traditional stacked app bars, heavy divider lines, and dark mode states are eliminated. Hierarchy is established exclusively through scale, spatial isolation, and featherlight ambient elevation.
- **Utilitarian Elegance:** High-visibility contrast between deep ink-navy titles and vibrant emerald green actions ensures illegibility is impossible, even when viewing screens at arm's length or in direct glare.
- **Tactile Softness:** Generous micro-radii, pillow-soft ambient drop shadows, and oversized touch targets (minimum 48pt) accommodate gloved or moving thumbs without precision penalties.
- **Zero Decorative Noise:** Eliminates arbitrary gradients, neon glows, and ornamental cards. Every pixel serves validation, asset verification, or progression.

## Colors

The palette is strictly restricted to an authentic light-only execution. Pure white serves as both base canvas and component substrate, separated only by diffuse atmospheric shadows.

- **Primary (`#10B981` — Emerald Green):** The unified affirmative anchor. Used for primary operational CTAs, passed inspection states, active toggles, verified checkmarks, and progress rings. Hover/pressed states deepen to `#059669`. Light green tint (`#ECFDF5`) is reserved exclusively for pass chip backgrounds.
- **Secondary (`#1A1A24` — Deep Ink Navy):** The structural reading color. Replaces pure black to deliver maximum contrast without harsh digital clipping. Applied to headlines, key value indicators, active navigation glyphs, and primary card titles.
- **Tertiary (`#EF4444` — Precision Red):** Used strictly for failed inspection line items, critical damage callout pins, and severe safety warnings. Paired with a soft warning amber (`#F59E0B`) for advisory/marginal items.
- **Neutral (`#8E8E93` / `#6B7280` — Slate & Cool Gray):** Subordinate metadata, inactive tab items, unit metrics, placeholder fields, and inspection step breadcrumbs.
- **Canvas Base (`#FFFFFF` — Absolute White):** Applied uniformly to view backgrounds, modal sheets, and card faces. No off-white or gray body backgrounds.

## Typography

The type system is powered by **Plus Jakarta Sans**, selected for its wide counters, sturdy geometric terminals, and balanced legibility across high-density vehicle spec data and field forms.

- **Headlines & Titles:** Set with heavy weights (`700` and `800`) in Deep Ink Navy (`#1A1A24`) with tight tracking (`-0.02em` to `-0.03em`). This delivers a muscular, confident visual structure that commands immediate visual anchor points without relying on dividing rules or background bands.
- **Body Text:** Kept crisp and legible in weights `400` and `500`. Neutral tinting (`#6B7280`) is used for descriptive instructions and diagnostic notes to preserve clear hierarchical separation from titles.
- **Labels & Micro-copy:** Rendered with deliberate uppercase or tightened semibold tracks (`+0.02em` to `+0.04em`) at `11px` to `12px` for VIN numbers, tire pressure readings (PSI), sensor tolerances, and timestamp tags.

## Layout & Spacing

The layout embraces high-ratio negative space, isolating critical vehicle inspection zones into discrete, touchable cards that float seamlessly over the white viewport.

- **Grid & Margins:** Mobile devices utilize a single-column layout flanked by a strict `1.25rem` (20px) outer edge margin. Tablet and folded screens scale up to an ergonomic two-column balanced inspection split with a `1rem` (16px) gutter.
- **Vertical Rhythm:** Structural sections are separated by `1.5rem` to `2rem` of unadulterated white space. Components never crowd one another; items rely on spacious inner padding (`space-lg` / 24px) to ensure thumb strikes do not trigger adjacent actions.
- **Safe Area Insets:** Top safe area features minimal inline status counters rather than opaque navigation bars. Bottom safe areas incorporate fixed floating pads that keep main action buttons cleanly hoisted above the system home indicator.

## Elevation & Depth

Depth is established without border outlines or tinted section backgrounds. Instead, cards and floating controls hover above the `#FFFFFF` canvas using ultra-soft, expansive ambient shadows.

- **Canvas Level (0):** The primary view base at pure `#FFFFFF`.
- **Card Ambient Elevation (1):** Applied to inspection item groups, vehicle data modules, and diagnostic panels. 
  - Token value: `0px 14px 40px rgba(0, 0, 0, 0.045), 0px 2px 8px rgba(0, 0, 0, 0.015)`
  - Cards stay completely borderless, reading as soft, clean physical paperboards hovering weightlessly above the viewport.
- **Floating Controls & Sheets (2):** Applied to the bottom navigation bar, floating CTA containers, and damage detail sheets.
  - Token value: `0px 18px 50px rgba(0, 0, 0, 0.08), 0px 4px 12px rgba(0, 0, 0, 0.03)`
- **Target Marker Elevation (3):** Applied to vehicle wireframe damage pins and photo tag markers.
  - Token value: `0px 8px 24px rgba(16, 185, 129, 0.28)` for verified items, and `0px 8px 24px rgba(239, 68, 68, 0.28)` for flagged damage pins.

## Shapes

The interface embraces oversized roundedness to convey a friendly yet rigorously calibrated Apple-grade tactile feeling.

- **Primary Cards & Containers:** Standardized on `24px` (`rounded-2xl`) and `28px` (`rounded-3xl`) corner radii, eliminating aggressive corners.
- **Interactive Controls & Toggles:** Pills and buttons utilize full circular curvature (`rounded-full` / `9999px`) for segmented switches, photo markup tools, and language pickers.
- **Input Fields & Step Markers:** Styled with `16px` to `20px` corners, maintaining uniform softness across every interaction level.

## Components

### Full-Width Primary CTA
- **Height & Radius:** Fixed 56px height with a full pill radius (`rounded-full`).
- **Colorway:** Vibrant `#10B981` background, bold white typography (`label-lg`), no border.
- **Shadow:** Floating soft emerald shadow: `0px 10px 25px rgba(16, 185, 129, 0.3)`.
- **States:** Active press reduces scale to 98% with `#059669` fill. Disabled state drops to `#F3F4F6` with `#9CA3AF` text and no shadow.

### Inspection Cards
- **Structure:** Pure white `#FFFFFF` surface, 20px interior padding, `24px` corner radius, and ambient card drop shadow.
- **Content Flow:** Prominent chunky navy headline (`headline-sm`), micro gray label (`body-sm`), followed by a 3-way status toggle: Pass (Emerald), Marginal (Amber), Fail (Red).
- **Feedback:** Selecting an outcome softly tints the internal selector pill without altering the pristine white card body.

### Pill-Shaped Segmented Toggles & Language Switches
- **Wrapper:** Ultra-clean `#F4F4F6` pill housing with 4px inner padding.
- **Segment:** The active option is an elevated pure white pill (`#FFFFFF`) with a micro ambient shadow (`0px 2px 8px rgba(0,0,0,0.06)`), rendering selected text in `#1A1A24` bold and inactive text in `#8E8E93`.

### Floating Bottom Navigation
- **Dock Position:** Suspended 16px above the home indicator, detached from screen edges with 20px horizontal margins.
- **Geometry:** Height 64px, `rounded-full`, pure `#FFFFFF` background with tier-2 ambient drop shadow.
- **Item States:** Active item displays an ink-navy icon paired with a subtle 4px emerald indicator dot; inactive items rest at neutral `#8E8E93`.

### Wireframe Damage Pins & Photo Markup Bar
- **Damage Pins:** Circular 28px markers placed directly over minimal monochrome vehicle schematics. White inner core surrounded by a solid 4px ring in `#EF4444` (Severe), `#F59E0B` (Scratch/Dent), or `#10B981` (Validated). Includes an ambient colored shadow for rapid visual location.
- **Photo Markup Bar:** Floating horizontal pill resting at the top of the photo canvas. Hosts rapid-action monochrome vector tools: Arrow, Circle, Dent Callout, and Freeform Pen, with an immediate emerald "Save Markup" commit pill.

### Form Inputs & Slider Toggles
- **Text & Numeric Inputs:** Pure `#FFFFFF` field with a very subtle background tint (`#F9FAFB`), 16px radius, bold ink-navy input typography, and an emerald ring indicator on active focus.
- **Slider Toggles:** 32px height by 52px width pill track. Inactive state is soft cool gray (`#E5E7EB`); active state transitions seamlessly to vibrant `#10B981` with an elevated pure white thumb circle.