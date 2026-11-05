# 13. 12. Tire Condition Capture

- App: Technician
- Figma node: `1:8479`
- Frame: 390 x 1085.5 px (phone; mobile portrait)
- Export folder: `screens/13_12._Tire_Condition_Capture`
- Sources read: `12._Tire_Condition_Capture.json` (developerSummary, assetIndex, full node tree), `12._Tire_Condition_Capture@2x.png`, `assets/manifest.json`
- Confidence: high for layout/typography; medium for the wheel-selection semantics (only one active pin is shown); low for rule provenance (tread thresholds/legal minimum) and for RTL/offline states (not exported)

> **Ordering note:** this folder is manifest index **13** but the Figma screen is named **"12. Tire Condition Capture"**. The file name above uses the manifest index as the NN prefix. Screens 12–15 are numbered differently in Figma than in the export order.

## 1. Purpose

A dedicated tyre/wheel condition step (step 6 of 8). The technician taps a wheel position on a top-down chassis diagram, then records physical wear ("As New" vs "Part Worn"), a measured groove depth in mm, cold pressure in PSI, and sidewall condition, then saves.

## 2. Layout structure

Root `1:8479`: 390x1085.5, VERTICAL, fill `#FFFFFF`.

1. `1:8480` "Main" — 390x1085.5, VERTICAL, padding `64/0/0/0`.
   - `1:8481` content — 390x1021.5, VERTICAL, padding `0/20/40/20`.
     - `1:8482` progress header margin — 350x180, padding `16/0/24/0`; header 350x140, gap 4.
       - row 350x14: `INSPECTION SEQUENCE` 11/14 SemiBold (+1.1) + `6 of 8 Completed` `#10B981` 11/14 Bold.
       - progress track 350x6, pill; fill 262.5x6 `#10B981` (75%, while 6/8 = 75%).
       - heading 350x64: `Step 6: Set condition for each tyre` 26/32 ExtraBold, -0.65.
       - body 350x36: 13/18 Regular.
     - `1:8496` chassis block — 350x312, bottom padding 24; card 350x288, **radius 32**, padding 16, two shadows.
       - radial-gradient background rectangle 350x288.
       - composed chassis SVG 176x256 (strokes `#C7C5D3` 1.6–3.2; two wheel fills `#EEEDF3`; one wheel `#FFFFFF` + `#10B981` 3.2 stroke).
       - pins: FL/FR/RR 28x28 white circles with 11px labels; RLT active pin 36x36 `#10B981` + 12x12 white dot + 34.56x19 "RLT" label; "Active Zone" legend 99.5x28.5.
     - `1:8536` detail card — 350x489.5, **radius 32**, padding 24, gap 16, two shadows.
       - header 302x40: 40x40 tinted icon, `RLT — Rear Left Tyre` 16/22 Bold, `Axle 2 • Michelin Pilot Sport 4S` 13/18, `Verified` chip 65.52x22.
       - wear selector 302x117 — label 12/16 SemiBold + two 147x93 buttons (selected emerald, unselected `#F4F3F8`), each with icon, 14/18 Bold label, 11px helper.
       - tread 302x92 — label + "Legal Minimum: 1.6 mm" (11/14 Bold `#10B981`); 302x68 filled field with 15x9 icon, "Tread Depth (mm)" 14/20 SemiBold, 32x32 minus, 64x30 value "7.2" 16/22 Bold, 32x32 plus.
       - snapshot 302x60.5 — two 147x56.5 `#F4F3F8` cards: `Cold Pressure` 11 + `34.5 PSI (Norm)` 12/16 Bold; `Sidewall` + `No Gouges / Flaws`.
       - `SAVE` 302x56 pill `#10B981`.
2. `1:8622` Header — 390x64, `#FFFFFF@0.8` + blur + shadow; back 44x44, `Vehicle Walkaround Inspection` 18/24 Bold, 32x32 `#006C49` avatar.

The whole page scrolls; the SAVE button is inside the detail card, not a fixed dock. No tablet layout.

## 3. Visual tokens observed

### Colours

| Hex | Usage | ~Count |
|---|---|---|
| `#FFFFFF` | cards, wheel fill, pins | 21 |
| `#1A1B1F` | primary text/icons | 15 |
| `#5E5D69` | secondary text/icons | 14 |
| `#10B981` | selected/primary/verified | 10 |
| `#F4F3F8` | muted buttons/fields | 6 |
| `#C7C5D3` | chassis strokes, disabled | 4 |
| `#EEEDF3` | wheel fill | 3 |
| `#006C49` | header avatar | 1 |
| `#C7C5D366` (40%) / `#C7C5D380` (50%) | faint chassis guides | 1 / 1 |
| `#FFFFFFCC` / `#FFFFFFE5` | header / floating pills | 1 / 1 |

### Typography

- Family **Plus Jakarta Sans**; weights 400/600/700/800.
- 26 / 32 / ExtraBold 800 / -0.65 — step heading.
- 16 / 22 / Bold 700 / -0.4 — wheel title; 18 / 24 Bold — app bar.
- 14 / 20 / SemiBold 600 / -0.07 — field label; 14 / 18 Bold — As New/Part Worn/Save.
- 13 / 18 Regular — axle line, body copy.
- 12 / 16 SemiBold (+0.24) — wear label, pressure values.
- 11 / 14 SemiBold (+0.44) — progress, legal minimum, helpers; 10 ExtraBold (+0.5) — "RLT" pin label.

### Radii, shadows, strokes, spacing

- Radii: `9999` x19, `32` x2, `6` x1 (tread number field). Cards 32; buttons/pills full; numeric field only 6.
- Shadows: chassis card and detail card (2 each); selected wear button; pressure/sidewall cards flat.
- Strokes: chassis `#C7C5D3` at 1.07–3.2; selected wheel `#10B981` 3.2.
- Spacing: 12, 4, 16, 8, 24, 14, 10, 20 common; card padding 24; page margin 20. 20/24 are not both in `AppSpacingTokens` (24 is, 20 is not).

## 4. Components

Figma patterns:
- Progress header with kicker, count, 6px linear bar, 26px title.
- Top-down chassis diagram with tappable wheel pins, one active pin, a floating legend.
- Detail card with wheel identity + verified chip.
- Two-up large wear choice cards (icon + label + range helper).
- Numeric stepper field (minus / value / plus) with unit label and legal-minimum hint.
- Two-up read-only metric cards.
- Pill save CTA.

Mapping:
- `SectionHeader` — step/heading.
- `StatusChip` — `Verified`, `Active Zone`.
- `AppSelectableText` — wear choice could map, but ours has no icon/large-card variant.
- `AppTextField` — numeric field (ours has no stepper and no inner shadow).
- `AppButton` — SAVE (primary); stepper buttons have no icon-only equivalent.
- `AppCard`/`Card` — detail/metric cards.
- Chassis diagram + tappable wheel pins — **no equivalent**.
- Coverage/threshold helper — no equivalent.
- `LinearProgressIndicator` exists but current code does not show a labelled bar.

## 5. Assets

23 assets: 22 individual SVGs, 1 composed SVG, no raster.
- Composed: `Minimalist_SVG_Top-Down_Car_Chassis-1_8499.svg` (176x256) — the top-down vehicle chassis.
- Vectors: 6 chassis strokes/fills (`Vector-1_8500` … `_8505`, thickness 0–3.2).
- Icons: wheel/tread (20.17x17.42), check (13.58x10), dot (8x8), gauge (15x9), minus/plus (9.33), pressure (16.67x13.33), sidewall shield (13.33x16.67), save (15x15), back, avatar.
- Wheel pins use text labels (FL/FR/RLT/RR), no vehicle photo.
- **No raster, no avatar photo, no vehicle image.**

## 6. Content and data

| Visible text/label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Progress | `INSPECTION SEQUENCE`, `6 of 8 Completed`, bar 75% | Partly: checklist completed/total exists | "Step 6 of 8" and zone count are not in the current model |
| Heading | `Step 6: Set condition for each tyre` | No | No tyre step |
| Instruction | `Tap any wheel position on the chassis to log physical wear.` | No | New UX |
| Wheel positions | `FL`, `FR`, `RLT`, `RR`, `Active Zone` | No | No wheel-position model; "RLT" vs "RL" inconsistency (rest are 2-letter) |
| Wheel title | `RLT — Rear Left Tyre` | No | — |
| Axle | `Axle 2` | No | — |
| Tire brand/model | `Michelin Pilot Sport 4S` | No | **Invented product data**; no tyre catalog |
| Status | `Verified` | Partly: evidence state terminology exists | "Verified" should not be conflated with evidence verification |
| Wear class | `As New`, `Part Worn` | No | New field; ranges: `OEM Standard (>6mm)`, `Usable Wear (3-6mm)` |
| Tread depth | `Measured Groove Depth`, `Tread Depth (mm)`, `7.2` | No | **Measured value + unit**; no tread field/endpoint |
| Legal threshold | `Legal Minimum: 1.6 mm` | No | **Jurisdiction-specific legal claim**, hardcoded |
| Pressure | `Cold Pressure`, `34.5 PSI (Norm)` | No | **PSI measurement**; not collected anywhere |
| Sidewall | `Sidewall`, `No Gouges / Flaws` | No | New attribute |
| CTA | `SAVE` | No | No tyre save endpoint |

No VIN/plate/customer data on this screen.

## 7. States shown / not shown

Shown: one active wheel (RLT) with verified state; selected "As New"; a numeric value; "Normal"-range pressure.
Not shown: no wheel selected, loading, save failure, partial wheel data, out-of-range/low tread warnings, PSI units (bar/kPa), different tyre positions (spare/dual rear), RTL, offline/local-only, 200% text, disabled SAVE.

## 8. Implied interactions

- Tap FL/FR/RLT/RR to load that wheel's detail card.
- Tap As New/Part Worn.
- Tap −/+ to change tread depth, or edit the numeric field directly.
- Save persists the wheel record and returns to the sequence.
- Progress advances when all wheels are saved.
- Pressure/sidewall cards look read-only (no edit affordance shown).

## 9. Correspondence to current product

- **New screen/feature.** There is no tyre route in `technician_router.dart`, no tyre model in `models.dart`, no tyre table/endpoint in `api_endpoints.dart`, and no tyre handling in `server/src/main/java/com/truereport/inspections/*`.
- The only related capability is a generic assessment (`AssessmentRequest` with `resultCode/severityCode/note/reasonText`), which cannot store wheel position, tread mm, PSI, or tyre brand.
- Closest existing pattern: `checklist_page.dart` progress + `assessment_page.dart` evidence; the chassis interaction has no code equivalent.
- **Needs new data/server change** (wheel positions, tread depth, pressure, wear class, tyre metadata), not a UI-only change. Hardware/PSI/tread values must not be fabricated client-side.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **Invented measurements/results.** `7.2 mm`, `34.5 PSI`, `3-6mm`, `>6mm`, and `Michelin Pilot Sport 4S` are sample/fabricated values. The rule forbids inventing measurements or results. In particular, do not prefill a measurement.
2. **Legal/compliance claim.** Hardcoded `Legal Minimum: 1.6 mm` is jurisdiction-specific and must come from approved, versioned master/legal content — not the UI. This is exactly the "no certification/compliance claim" risk.
3. **Hardware/BLE implication.** "Measured Groove Depth"/`Cold Pressure` imply a digital gauge/BLE sensor. PRD mentions BLE 5.0, but hardware pairing is not implemented; do not present live device values as captured. The product rules forbid inventing hardware readings.
4. **Unit policy.** Mixed mm and PSI with no unit-switch or locale handling. Measurements need approved units, tabular numerals and locale formatting (Arabic numerals, RTL).
5. **Wheel-position naming.** `RLT` (3 letters) among `FL/FR/RR` is inconsistent; "tyre" vs "tire" spelling differs from code (`tire`/`tyre` not used at all).
6. **Token drift.** `#10B981`, 32px cards, 20/24 padding, 6px input radius are outside `tokens.dart` (primary `#0B3B4A`; radii 4/8/12/16; spacing 4/8/12/16/24/32/48).
7. **Touch targets.** 28px wheel pins, 32px stepper buttons and 36px active pin are below the 44/48px rule (the active pin is 36). Numeric field is 64x30.

## 11. Open questions / could not verify

- Is this a per-wheel capture, a per-axle capture, or one summary for all four wheels? Only one detail card is shown.
- Are tread depth and pressure measured by a paired device or typed manually? No input method is shown.
- Which wheel set applies (4-wheel, dual rear, spare)? "RLT" hints at a tri-axle/dual layout that is not explained.
- Are the wear classes and thresholds master content or hardcoded? Who approves them?
- Where do `6 of 8` and the progress derivation come from?
- Is there a legal-approved source for the 1.6mm threshold, and does it vary by region?
- RTL/Arabic, 200% text, numeric keyboard, unit switching, and offline behaviour could not be verified.
