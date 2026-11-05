# 11. 11. Dense Mechanical List

- App: Technician
- Figma node: `1:8220`
- Frame: 390 x 1080 px (phone; mobile portrait)
- Export folder: `screens/11_11._Dense_Mechanical_List`
- Sources read: `11._Dense_Mechanical_List.json` (developerSummary, assetIndex, full node tree), `11._Dense_Mechanical_List@2x.png`, `assets/manifest.json`
- Confidence: high for layout/typography; medium for interaction (inline expansion vs separate page); low for RTL and for rule-driven states (validation/errors/offline) because none are exported

## 1. Purpose

A single scrollable "Diagnostic Checklist" of mechanical checkpoints for one inspection zone. It mixes three card densities: a completed row, an expanded in-place capture card (segmented fluid level, note, photo, barcode), and compact rows with a 3-way Pass/Marginal/Fail selector. A fixed bottom CTA confirms the fluid levels.

## 2. Layout structure

Root `1:8220`: 390x1080, VERTICAL, fill `#FFFFFF`, FIXED/HUG.

1. `1:8221` "Main" — 390x1080, VERTICAL, padding `64/0/0/0`.
   - `1:8222` container — 390x1016, VERTICAL, bottom padding `128` (for the fixed CTA).
     - `1:8223` zone header — 390x58, padding `16/20/8/20`; H row 350x34: `INSPECTION ZONE 04` (12/16 SemiBold `#6C7A71`), `3 of 6 checkpoints logged` (13/18 Regular), right "Live Bay #2" pill 104.42x26.
     - `1:8234` list margin — 390x830, padding top 12.
       - `1:8235` list — 390x818, VERTICAL, **gap `20`**, padding `0/20/0/20`.
         - `1:8236` card 1 (complete) — 350x100, **radius 32**, padding 20, one shadow pair.
         - `1:8250` card 2 (expanded) — 350x312, radius 32, padding 20, **gap 16**.
         - `1:8283` card 3 (status selector) — 350x138, radius 32, padding 20, gap 14.
         - `1:8304` card 4 (collapsed, chevron) — 350x100.
         - `1:8318` card 5 (complete) — 350x88.
2. `1:8332` Fixed Bottom CTA Dock — 390x96, padding 20, `GRADIENT_LINEAR` background; 350x56 pill primary button.

No scroll component in the JSON; the list visually overflows 1080 and is clearly intended to scroll under the fixed dock. Card 2 is "expanded" in place, so accordion behaviour is implied.

## 3. Visual tokens observed

### Colours

| Hex | Usage | ~Count |
|---|---|---|
| `#1A1B1F` | titles, icons | 16 |
| `#FFFFFF` | card/button surfaces | 13 |
| `#F4F3F8` | icon circles, selected rows, inputs | 12 |
| `#5E5D69` | subtitles/secondary | 11 |
| `#10B981` | primary CTA, success, selected | 5 |
| `#6C7A71` | zone label, placeholder | 3 |
| `#10B98126` (15%) | success icon circles | 2 |
| `#3C4A42` | ACTIVE chip text | 1 |
| `#E9E7ED` | ACTIVE chip surface | 1 |
| `#FFFFFFCC` (80%) | sticky header | 1 |

### Typography

- Family **Plus Jakarta Sans**; weights 400/500/600/700.
- 18 / 24 / Bold 700 / -0.45 — card titles.
- 14 / 18 / Bold 700 / -0.14 — Take Photo / Confirm Fluid Levels.
- 13 / 18 / Regular 400 — descriptions.
- 12 / 16 / SemiBold 600 — zone kicker, segmented labels.
- 11 / 14 / SemiBold 600 (+0.44) — bay pill, ACTIVE.
- 14 / 20 / Medium 500 — textarea placeholder.
- All left-aligned apart from segment/CTA labels (centred) and right-aligned pills.

### Radii, shadows, strokes, spacing

- Radii: `9999` x25, `32` x5. Cards = 32; segmented control/inputs = pill/soft.
- Shadows: card pairs (`DROP_SHADOW` x2); icon circles and the bottom CTA also carry shadows.
- Strokes: none visible (borderless cards).
- Spacing: **20** is the dominant value (29 uses), then 4, 8, 6, 14, 12, 16, 10, 34, 64. Gap between cards is 20; card padding is 20; 20 is not in `AppSpacingTokens`; it matches only the DESIGN.md 1.25rem margin.

## 4. Components

Figma patterns:
- Zone header with kicker + count + live-bay status pill.
- Large elevated checklist card with 48px icon circle, 18px title, 13px description, trailing 36px state icon.
- Accordion/expanded card with:
  - status chip (`ACTIVE`),
  - 3-way segmented level selector (40px track),
  - 68px filled textarea with placeholder,
  - 48px primary "Take Photo" + 48x48 barcode icon button.
- Compact 3-way Pass/Marginal/Fail selector (36px track).
- Fixed gradient CTA dock with 56px pill.

Mapping:
- `AppListTile` + `AppCard` — card rows and expanded card shell.
- `StatusChip` — "ACTIVE", "Live Bay #2".
- `AppSelectableText` — segmented selector (ours is text chips; Figma is a pill track).
- `AppTextField` — textarea (ours is filled/borderless, close).
- `AppButton` primary/tonal — Take Photo, Confirm Fluid Levels, barcode icon button (no icon-only variant).
- `LoadingSkeleton`/`ErrorState` — no equivalent shown.
- Barcode/diagnostic attachment — **no equivalent**.
- Inline accordion expansion — **not implemented**; current checklist navigates to `AssessmentPage`.

## 5. Assets

14 assets, all individual SVGs; **no raster and no composed SVG** (export warning confirms no composed groups).
- Icons: engine/oil (16.5), coolant/fan (18.3), brake (14.7x17.4), transmission/gear (18.4), washer droplet (14.7x18.3), camera (16.7x15), barcode (16.7), success check (16.7), chevron (6.2x10), back (11.8x20), avatar (12x12), confirm/check (20.2x19.2).
- No photos, avatars or vehicle images.

## 6. Content and data

| Visible text/label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Zone | `INSPECTION ZONE 04` | No | No zone entity; categories exist |
| Progress | `3 of 6 checkpoints logged` | Partly: completed/total exist | Counts must be computed, not hardcoded |
| Bay | `Live Bay #2` | No | No bay field |
| Item 1 | `Engine Oil Level` | Yes: `labelEn` | Category label is "Engine Oil Level" sample |
| Description | `Dipstick at optimal line • 5W-30 synthetic` | No | **Invented oil grade/measurement-style copy**; no description field of this kind |
| Item 2 | `Coolant` / `Expansion reservoir inspection` | Item label yes; description no | Descriptions are master instruction text, not sample values |
| State | `ACTIVE` | UI state | No such server state |
| Level | `Normal`, `Low`, `Critical` | No | Not a product result vocabulary |
| Note | `Enter fluid level / notes` | Yes: `note` | Placeholder only |
| Actions | `Take Photo` | Yes: evidence capture | No inline capture currently |
| Item 3 | `Brake Fluid Level`, `DOT 4 standard • Reservoir visual` | Label yes; "DOT 4" no | "DOT 4" is a **specification claim** and must not be invented |
| Result | `Pass`, `Marginal`, `Fail` | No | Product result codes are `NO_ISSUE_OBSERVED`, `ATTENTION_RECOMMENDED`, `DEFECT_FOUND`, `NOT_CHECKED`, `NOT_APPLICABLE`, `COULD_NOT_VERIFY` |
| Item 4 | `Transmission Fluid`, `Sealed system • Check overflow valve` | Label yes; copy no | Spec/instruction must come from master |
| Item 5 | `Washer Fluid`, `Topped to max reservoir line` | Label yes; copy no | Implied completed state |
| CTA | `Confirm Fluid Levels` | No | No zone-level confirm endpoint; save is per item |
| Title | `Diagnostic Checklist` | Close: `l10n.checklist` | Current AppBar title |

## 7. States shown / not shown

Shown: completed row (success icon), expanded editing row, selected segment, unselected segment, collapsed chevron row, disabled/empty note.
Not shown: loading, empty category, save failure, validation error, offline/local-only vs received, conflict, long text at 200%, RTL, evidence required but missing, >6 items, pull-to-refresh.

## 8. Implied interactions

- Tap card → expand in place (card 2) or navigate to entry (chevron card 4).
- Tap Normal/Low/Critical; tap Pass/Marginal/Fail.
- Tap textarea → keyboard; text saves with the item.
- Tap Take Photo → camera/gallery for this item.
- Tap barcode button → scan/attach diagnostic barcode (hardware).
- Fixed CTA confirms all fluid levels and presumably advances.
- Scrolling list under a translucent fixed header/dock.

## 9. Correspondence to current product

- Partly matches `client/apps/technician_app/lib/src/pages/checklist_page.dart`, route `/jobs/:id/checklist`, and `technicianChecklist`. Current UI groups by `categoryLabelEn`, shows a `LinearProgressIndicator` + `completed/total`, and each row opens `AssessmentPage` (`/jobs/:id/items/:itemId`).
- Partly matches `assessment_page.dart` for capture/result/note/severity/evidence.
- **New UI/state**: in-place accordion expansion, per-zone progress, level selector (`Normal/Low/Critical`), inline photo capture, barcode attach, zone-level "Confirm Fluid Levels" action.
- **New data/server needed** for: fluid level values, zone grouping/"checkpoint" counts, barcode/telemetry attachment. None exist in `InspectionItem`, `assessment_page.dart`, or the `technician*` endpoints. Current `resultOptions` come from the pinned template and must not be replaced by hardcoded Pass/Marginal/Fail.
- The per-item "Pass/Marginal/Fail" mapping is a visual-only reinterpretation of `resultOptions`, but the labels are non-compliant (see §10).

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"Pass" / "Fail" labels.** Rule: `NO_ISSUE_OBSERVED` must never be labelled "Pass" (§3.3 of `docs/phase-1/10-design-system.md`); result indicators must use the approved result vocabulary. Evidence: `Pass / Marginal / Fail` on card 3 and `Normal/Low/Critical` on card 2.
2. **Invented specifications.** `5W-30 synthetic`, `DOT 4 standard`, `Topped to max reservoir line`, and `3 of 6` are sample claims, not approved master content. The rule forbids inventing measurements/results.
3. **New hardware/BLE-adjacent feature.** The barcode button implies diagnostic device integration; BLE/hardware pairing is not implemented and must not be implied by UI alone.
4. **Zone-level confirmation vs per-item save.** The product saves each item independently and validates on write. A "Confirm Fluid Levels" bulk action could bypass per-item validation and the finalization gate.
5. **Token drift.** `#10B981` primary, 32px cards, 20px spacing are not the current token contract (`#0B3B4A`, radii 4/8/12/16, spacing 4/8/12/16/24/32/48).
6. **Data-entry density vs accessibility.** 36px segmented controls, 32px icon buttons and 28–36px trailing icons are below the 44/48px touch-target rule; 11px labels at 200% scale need re-testing.

## 11. Open questions / could not verify

- Is this one category page, a "zone", or a mixed list of fluid items? The zone/count/CTA don't map to an existing entity.
- Should expansion be accordion (one open) or multiple open? Only one expanded card is drawn; no closed/open transition is exported.
- Where do `Normal/Low/Critical` thresholds come from? Are they approved master rules or free text?
- Is "Take Photo" per item or per zone? The barcode icon's purpose and permissions are unclear.
- Does `Confirm Fluid Levels` save all items or move to the next section? No endpoint exists.
- Are `5W-30`/`DOT 4` intended as master-library sample content or hardcoded design filler?
- RTL, Arabic labels, offline/local-only indicators, and dynamic item counts could not be verified.
