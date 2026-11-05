# 06. Equipment Checklist

- App: Technician
- Figma node: 1:7643
- Frame: 390x910 px (mobile phone; 390 pt logical width)
- Export folder: `screens/06_6._Equipment_Checklist`
- Sources read: `6._Equipment_Checklist.json`, `6._Equipment_Checklist@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html`
- Confidence: high for layout/text; medium for the verification/pairing semantics, which are not modelled anywhere in the app.

## 1. Purpose

Pre-inspection equipment check: four tools with a verified/unverified circle, a "Fleet Station Standards" reassurance card, and a "Proceed" CTA. It is titled "Diagnostic Checklist" in the header but its content is the required-equipment list (T08).

## 2. Layout structure

- Root `1:7643`: VERTICAL, FIXED width / HUG height, 390x910, `#FFFFFF`.
- `1:7644` `Main`: VERTICAL, padding `0/64/0/0`; `1:7645` content 390x846, padding `20/0/20/40`.
- Visual order:
  - `1:7646` status/progress 350x60: margin with padding `0/12/0/24`; `01` badge, `PRE-INSPECTION SETUP`, `1 of 4 Verified` pill 98.2x22.
  - `1:7655` header 350x108: margin bottom 32; `Required Equipment` 26/32; description 350x40 (2 lines).
  - `1:7661` hardware stack 350x450: margin bottom 40; inner 350x410, VERTICAL, gap 16. Four cards: 350x88, 350x98, 350x88, 350x88; radius 32; padding 20; HORIZONTAL. Each has a 48x48 icon tile, text block (185–197 px), and a 32x32 status circle pinned right.
  - `1:7715` standards card 350x124: margin bottom 32; 350x92, radius 32, fill `#F4F3F8`, padding 20; 40x40 shield tile, title, two-line description.
  - `1:7725` CTA 350x64: 8 px top pad; 350x56 pill button.
- Header `1:7731` 390x64 at y0, absolute, `#FFFFFFCC` + 48 px background blur; back 44x44, title 18/24, profile 32x32.
- FILL width, fixed heights. No breakpoints/tablet variant, no scroll container. The 910 px frame will clip on shorter screens; no large-text strategy.
- The header title ("Diagnostic Checklist") and the page heading ("Required Equipment") name different things.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

| Hex | Usage | Approx. count |
|---|---|---|
| `#FFFFFF` | cards, icon tiles, CTA text | 11 |
| `#5E5D69` | descriptions, labels, unverified icons | 10 |
| `#1B1B25` | card titles, heading | 7 |
| `#F4F3F8` | icon tiles, standards card, progress pill | 6 |
| `#10B981` | check circle, "Verified" text, CTA | 5 |
| `#E9E7ED` | three unverified status circles | 3 |
| `#1A1B1F` | title/step text | 2 |
| `#006C49` | profile circle | 1 |
| `#E3E1EF` | badge/outline | 1 |
| `#FFFFFFCC` | header | 1 |

`#10B981` text on white = 2.54:1 ("1 of 4 Verified" 11 px fails). Unverified `#E9E7ED` circles on white are ~1.2:1, well below the 3:1 non-text UI target.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)

| Text / node | Family / weight | Size / line-height | Tracking | Alignment | Usage |
|---|---|---|---|---|---|
| Header title 1:7738 | Plus Jakarta Sans / 700 | 18 / 24 | -0.45 px | left | Screen title |
| `01` 1:7650 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | centre | Step number |
| `PRE-INSPECTION SETUP` 1:7652 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | left | Step label |
| `1 of 4 Verified` 1:7654 | Plus Jakarta Sans / 600 | 11 / 14 | +0.275 px | left | Progress |
| `Required Equipment` 1:7658 | Plus Jakarta Sans / 800 | 26 / 32 | -0.65 px | left | Page title |
| Description 1:7660 | Plus Jakarta Sans / 500 | 14 / 20 | -0.07 px | left | Intro |
| `Tire Depth Gauge` 1:7670 etc. | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Item title |
| `Digital laser calibration • Ready` 1:7672 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Item detail |
| `Bluetooth module v4.2 • Tap to\nverify` 1:7685 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Item detail |
| `Preset 120-140 Nm • Mechanical` 1:7698 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Item detail |
| `Fe / NFe substrate probe` 1:7711 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Item detail |
| `Fleet Station Standards` 1:7722 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | left | Standards title |
| `ISO-9001 certified diagnostic\nrequirements` 1:7724 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Standards detail |
| `Proceed` 1:7728 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | centre | CTA |

### Radii, shadows/elevation, strokes, spacing values

- Radii: 9999 ×14; 32 ×5 (four equipment cards + standards card).
- Card shadow `r=8 off=0,2` 1.6% + `r=40 off=0,14` 4.3%; CTA `r=25` emerald 30%; header 5% + blur.
- No strokes. Spacing: 20 page margin/card padding; 16 stack gap; 24/32/40 section spacing; 48 px icon tiles.
- Status circles are 32x32, below the 44 px target; the CTA is 56 high.

## 4. Components

| Figma pattern / node | Instances | Map to our design system |
|---|---|---|
| Equipment row 1:7663 etc. | 4 | `Card` + `AppListTile`; Figma has a dedicated 48 px icon tile and a 32 px status circle |
| Verification circle 1:7673 / 7686 / 7699 / 7712 | 4 | no equivalent; `StatusChip` is text, not a toggle |
| Standards card 1:7716 | 1 | `AppCard` (tonal) is close |
| Progress pill 1:7653 | 1 | `StatusChip`; no "verified" state |
| Primary CTA 1:7726 | 1 | `AppButton(primary, expand)` |
| Header 1:7731 | 1 | `AppBar` |

No component instances/variants. The equipment rows are plain frames, not instances of one row component, though their structure is repetitive.

## 5. Assets

- Manifest count: **9** (9 individual SVGs, 0 composed, 0 raster).
- Icons: tire/measure 1:7667 (20x12), check 1:7675 (12.2x9), OBD scanner 1:7680 (22x22), torque wrench 1:7693 (18x18), paint depth gauge 1:7706 (16x19), shield 1:7719 (13.3x16.7), check/small 1:7730 (13.3x13.3), back 1:7736 (11.8x20), profile 1:7741 (12x12).
- No photo/avatar/vehicle image, no composed assets.
- Icons are generic line icons; no equipment photograph or brand mark is supplied.

## 6. Content and data

| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| `Diagnostic Checklist` | header | No | Current screen title is "Equipment" (`l10n.equipment`) |
| `01` / `PRE-INSPECTION SETUP` | step 01 | No | Step model is not defined; conflicts with screen 04/05 numbering |
| `1 of 4 Verified` | progress | No | No verification state in the equipment API |
| `Required Equipment` | heading | Partly | Equipment is template-pinned, but not necessarily "required" |
| `Ensure all diagnostic hardware is calibrated and paired before launching bay intake.` | instruction | No | Calibration/pairing is not a product capability |
| `Tire Depth Gauge` / `Digital laser calibration • Ready` | tool + status | Partly | Name may come from master equipment; "calibrated/Ready" is not returned today |
| `OBD Scanner` / `Bluetooth module v4.2 • Tap to verify` | tool + spec | No | Bluetooth version, pairing/verify action and status are invented |
| `Torque Wrench` / `Preset 120-140 Nm • Mechanical` | tool + spec | No | Preset range/mechanical state is invented |
| `Paint Depth Gauge` / `Fe / NFe substrate probe` | tool + spec | No | Substrate detail is invented |
| `Fleet Station Standards` / `ISO-9001 certified diagnostic requirements` | standards | No | ISO-9001 certification claim |
| `Proceed` | action | Yes | Will likely call checklist/start; no destination encoded |

No personal data, VIN, plate, score or photo appears on this screen.

## 7. States shown / not shown

Shown: one verified tool, three unverified tools, enabled Proceed, "1 of 4 Verified".

Not shown: all-verified; any unavailable/missing tool; limitation note; required vs optional; empty equipment list; verification failure; loading; offline; server error; disabled Proceed; Arabic/RTL.

## 8. Implied interactions

- Tap a 32 px status circle to verify/unverify a tool (the OBD subtitle says "Tap to verify").
- `Proceed` continues to the checklist/intake.
- Back/profile.
- No prototype reactions; verify/Proceed destinations are inferred.

## 9. Correspondence to current product

- Matches T08 Equipment (`/jobs/:jobId/equipment`). Current implementation is a bottom sheet in `job_detail_page.dart` showing `equipment(jobId)`; the API (`technicianEquipment`) returns only `{equipmentIds: [...]}`, and the UI lists raw IDs with a handyman icon.
- Figma adds human names, descriptions, hardware specs, per-tool verification state and a standards card. None of these are in the current endpoint/model. The current screen also has no "mark unavailable" or "add limitation note" action required by T08.
- A UI-only build can list equipment IDs, but the verified/ready/pairing states and the ISO/standards content need data or removal.
- `Proceed` maps to the checklist route (`/jobs/:jobId/checklist`) but no such action is encoded.

## 10. Locked-rule conflicts / unsafe-to-ship content

- **"no certification/'verified by'/compliance claims"** and **"Never invent versions/licences"**: `ISO-9001 certified diagnostic requirements` (1:7724) is a certification claim; `Bluetooth module v4.2` (1:7685) is an invented hardware version.
- **"Never invent … measurements/results"**: `Preset 120-140 Nm`, `Fe / NFe`, "Digital laser calibration", "calibrated and paired", "Ready" are presented as measured/verified facts with no data source.
- **Hardware integration is not in scope**: Bluetooth pairing/verification, calibration status and OBD device checks imply device/API work that the UI layer cannot provide.
- **"no forced unsafe work" / T08**: `Proceed` is enabled while only 1 of 4 tools is verified. The screen should block or explain, and expose "unavailable/limitation" per T08.
- **WCAG 2.2 AA**: 32x32 status circles are below 44 px; the 11 px `#10B981` "1 of 4 Verified" is 2.54:1; the 1.2:1 unverified circles fail non-text contrast; state is colour/shape only with no text for the three unverified items.
- **"colour + icon + text"**: the three grey circles have no text label; the only state label is "Tap to verify" in one subtitle.
- **RTL**: no Arabic layout.
- **Step numbering**: "01 PRE-INSPECTION SETUP" conflicts with screen 04 "Step 1 of 4", screen 05 "STEP 4 OF 4", and screen 08 "Step 2".

## 11. Open questions / could not verify

- Is equipment *verification* or *pairing* actually in scope? Current API returns only IDs.
- Are "Digital laser calibration", "Bluetooth v4.2", "120–140 Nm" and "Fe/NFe" real master-data specifications or invented copy?
- Is "ISO-9001 certified" approved by legal/compliance? What is the certificate scope?
- Should Proceed be disabled until all required equipment is verified? What is required vs optional?
- Where does "Fleet Station Standards" come from? Is it workshop-specific or platform content?
- Are the tool names sourced from `equipmentIds` (which are raw IDs today), or from a new catalogue endpoint?
- Is there a limitation-note/unavailable flow, as T08 requires? Not shown.
- No prototype reactions; the verify/Proceed behaviour cannot be verified.
