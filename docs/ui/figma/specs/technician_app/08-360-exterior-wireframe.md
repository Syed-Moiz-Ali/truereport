# 08. 360 Exterior Wireframe

- App: Technician
- Figma node: 1:7896
- Frame: 390x906.25 px (mobile phone; 390 pt logical width)
- Export folder: `screens/08_8._360_Exterior_Wireframe`
- Sources read: `8._360_Exterior_Wireframe.json`, `8._360_Exterior_Wireframe@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html`
- Confidence: medium — the drawing and text are clear, but the pin/colour semantics, the "360" capability, and the damage model are not defined anywhere in the current product.

## 1. Purpose

Exterior damage capture on a vehicle wireframe: tap a panel/pin, see the active damage callout, switch perspective (Front/Driver/Passenger/Rear), confirm the markup, or mark the panel "No Damage Found". It is an interactive 2D panel/damage screen, not a photo-capture screen.

## 2. Layout structure

- Root `1:7896`: VERTICAL, FIXED width / HUG height, 390x906.25, `#FFFFFF`.
- `1:7897` `Main`: VERTICAL, padding `0/64/0/0`; `1:7898` content 390x842.2 is **layoutMode NONE** (absolute children); visual order below comes from y positions.
- Visual order/positions:
  - `1:7899` progress header 350x158 at y0: padding `0/8/0/20`, gap 4; top row 350x22 with `EXTERIOR INSPECTION` and `1 Detected` pill 95.8x22; 350x64 two-line heading; 350x36 two-line description.
  - `1:7951` interactive canvas card 350x379.8 at y158, radius 32, fixed size. Inside: `Perspective Badge & Reset` 310x32 at y20 (badge 143.7x22 `DRIVER SIDE VIEW`, 32x32 fullscreen/reset button); `Car Schematic Container` 310x201.8 at y60 (the 310x177.8 car line-art); `Active Damage Callout Card` 310x86 at y261.8 (absolute y419.8).
  - `1:7911` perspective grid 350x143.8 at y537.8: margin `0/24/0/24`; label row 350x16 (`ANGLE PERSPECTIVE`, `Tap to rotate 360°`); 350x69.8 button row, four 82.5-ish buttons with 12 px gaps; `Driver` selected.
  - `1:7943` actions 350x112 at y690.2: 350x56 primary CTA at y8; 350x36 "No Damage Found on this Panel" text button at y76; 12 px gap.
- Header `1:8010` 390x64 at y0, absolute, `#FFFFFFCC` + 48 px blur; back 44x44, title `Vehicle Walkaround Inspection`, 32x32 profile circle.
- No bottom nav (pushed route). No scroll container; 906.25 px frame with fixed card and fixed CTA.
- The canvas is fixed 350x379.8; the car is 310x177.8; five pin buttons are absolutely positioned at 28x28 (four) and 33.6x32 (selected). There is no responsive reflow or large-text strategy.
- Tree order inside the canvas is badge → callout → car, while the PNG visual order is badge → car → callout. This matters because the container is absolute, not Auto Layout.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

| Hex | Usage | Approx. count |
|---|---|---|
| `#FFFFFF` | card, pin cores, pill backgrounds | 19 |
| `#F59E0B` | car wireframe strokes (amber/orange) | 18 |
| `#10B981` | damage pins, selected pin, confirm CTA, check | 14 |
| `#5E5D69` | labels, meta, description | 8 |
| `#1A1B1F` | heading, badge text, nav | 6 |
| `#1B1B25` | damage title | 5 |
| `#F4F3F8` | badge, reset button, callout card | 4 |
| `#6C7A71` | section eyebrow, "Tap to rotate" | 2 |
| `#006C49` | profile circle | 1 |
| `#10B98126` | camera icon tile | 1 |
| `#10B9814D` | selected-pin halo | 1 |
| `#FFFFFFCC` | header | 1 |

Measured contrast: `#F59E0B` on white = 2.15:1 (the car drawing is meaningful non-text content; below 3:1); `#10B981` on white = 2.54:1 (pin boundary and 14 px CTA label); white on `#10B981` = 2.54:1; `#5E5D69` = 6.47:1. The green damage pin does **not** read as a warning at these contrast levels.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)

| Text / node | Family / weight | Size / line-height | Tracking | Alignment | Usage |
|---|---|---|---|---|---|
| Header title 1:8017 | Plus Jakarta Sans / 700 | 18 / 24 | -0.45 px | left | Screen title |
| `EXTERIOR INSPECTION` 1:7902 | Plus Jakarta Sans / 600 | 11 / 14 | +0.55 px | left | Eyebrow |
| `1 Detected` 1:7906 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Count chip |
| Heading 1:7908 | Plus Jakarta Sans / 800 | 26 / 32 | -0.65 px | left | Instruction |
| Description 1:7910 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Instruction detail |
| `DRIVER SIDE VIEW` 1:7958 | Plus Jakarta Sans / 700 | 11 / 14 | +0.275 px | left | View badge |
| `Front Left Door Dent` 1:7970 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Damage title |
| `2.5 cm Crease • Photo\nAttached` 1:7972 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Damage meta |
| `Edit` 1:7974 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | centre | Action |
| `Confirm Exterior Markup` 1:7946 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | centre | Primary CTA |
| `No Damage Found on this Panel` 1:7950 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | centre | Secondary decision |
| `ANGLE PERSPECTIVE` 1:7915 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | left | Section |
| `Tap to rotate 360°` 1:7917 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | right | Hint |
| `Front` / `Passenger` / `Rear` 1:7924 etc. | Plus Jakarta Sans / 600 | 12 / 16 | -0.30 px | centre | Angle |
| `Driver` 1:7930 | Plus Jakarta Sans / 700 | 12 / 16 | -0.30 px | centre | Selected angle |

### Radii, shadows/elevation, strokes, spacing values

- Radii: 9999 ×20 (pills, pins, angle buttons, CTA); 16 ×4 (small icon containers); 32 ×1 (canvas card).
- Canvas card shadow `r=8 off=0,2` 1.6% + `r=40 off=0,14` 4.3%; pins `r=12 off=0,4` 25%; selected pin `r=24 off=0,8` 45%; CTA `r=25` emerald 30%; header 5% + blur.
- Strokes: car `#F59E0B` at 1.03–1.72 px (18 vectors); unselected pins 2 px `#10B981` inside a 28x28 white circle with an 8x8 green core; selected damage 32x32 emerald with white check and a 36/48 px halo.
- Spacing: 20 card margin/padding; 12 gap between angle buttons; 24 above/below angle section; 12 between CTA and secondary action.
- Pin targets are 28x28/33.6x32, below 44x44; the canvas is tap-only.

## 4. Components

| Figma pattern / node | Instances | Map to our design system |
|---|---|---|
| Canvas card 1:7951 | 1 | **no equivalent** |
| Car schematic 1:7977 | 1 composed | no equivalent (line-art vehicle, not an image) |
| Damage pin 1:7996/7998/8006/8008 | 4 | no equivalent (28x28 white ring + green core) |
| Selected damage pin 1:8000 | 1 | no equivalent (32x32 emerald + check + halo) |
| Damage callout 1:7963 | 1 | `Card`/`AppListTile` isn't a good match; no damage-callout component |
| Perspective segmented buttons 1:7918 | 4 | `AppSelectableText` is the nearest; Figma uses large square buttons with directional icons |
| Primary CTA 1:7944 | 1 | `AppButton(primary, expand)` |
| Secondary text decision 1:7949 | 1 | `AppButton(text)` |

No component instances/variants. Pins and callout are plain frames/vectors; the car is a composed vector group, not a reusable vehicle model.

## 5. Assets

- Manifest count: **32** (29 individual SVGs, **3 composed**, 0 raster).
- Composed: `composed-1_7977` "Minimalist 2D Amber/Orange Car Profile Line-Art SVG" 310x177.8; `composed-1_7976` "Car Schematic Container" 310x193.8; `composed-1_7975` "Car Schematic Container:margin" 310x201.8.
- The 29 individual SVGs are the car's body/window/wheel strokes plus UI icons. Many are tiny or zero-width (`Vector-1_7988.svg` is 0x63.7).
- No raster, no photo, no avatar. The vehicle is a **2D side-profile line drawing**, not a photo and not a 3D/360 model.
- Only one side profile is supplied; the three composed assets are the same schematic at different container/margin levels. There are no front/rear/passenger vehicle assets.

## 6. Content and data

| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| `EXTERIOR INSPECTION` | section | Partly | Category concept exists in checklist items |
| `1 Detected` | count | No | No damage/mark model; count source unknown |
| `Step 2: Tap the area to\ncapture damage` | instruction | No | "Step 2" conflicts with screen 04 "Step 1 of 4" and screen 05 "STEP 4 OF 4" |
| `Pin scratches, dents, or paint chips directly on the\nwireframe schematic.` | instruction | No | Damage types (scratch/dent/paint chip) are not model enums |
| `DRIVER SIDE VIEW` | view | No | Only one side profile is supplied |
| `Front Left Door Dent` | damage label | No | No panel/damage entity in the current model |
| `2.5 cm Crease • Photo\nAttached` | measurement + type | No | Invented measurement/type; "Crease" vs title "Dent" |
| `Edit` | action | No current endpoint | No damage edit API |
| `Confirm Exterior Markup` | action | No | No confirm/endpoint |
| `No Damage Found on this Panel` | decision | No | Contradicts the active damage callout on the same view |
| `ANGLE PERSPECTIVE` / `Tap to rotate 360°` | view control | No | Four static buttons; one side asset; no rotate/360 interaction |
| `Front` / `Driver` / `Passenger` / `Rear` | angles | No | Only `Driver` has an asset |
| `Vehicle Walkaround Inspection` | header | No | Same header as 04/05, but this is a different step |

No customer name/phone/email/VIN/plate appears. A damage measurement, damage type, and photo attachment are asserted. The vehicle drawing is generic, not tied to a VIN.

## 7. States shown / not shown

Shown: driver-side view, one active damage, four unselected pins, one selected pin, `1 Detected`, enabled Confirm, secondary "No Damage Found".

Not shown: no-damage state (the text action exists but no resulting state); multiple damages; other angles (Front/Passenger/Rear are buttons only, no assets); add-damage flow; severity selection; note/reason; photo capture/attachment flow; delete/undo; loading/error/offline; finalized/read-only; Arabic/RTL.

## 8. Implied interactions

- Tap a pin/panel to select; tap `Edit` to change the damage; `Confirm Exterior Markup`; `No Damage Found on this Panel`; switch Front/Driver/Passenger/Rear; fullscreen/reset button.
- No prototype reactions; pin selection, angle switching, and confirm destinations are inferred.

## 9. Correspondence to current product

- **New screen/feature.** There is no 360/damage-pin screen, route, model, or endpoint in the current technician app.
- The closest current capability is T10 Item assessment (`/jobs/:jobId/items/:itemId`) and photo evidence (`technicianEvidence`), which record a result, severity, note, reason and photos per inspection item. There is no panel coordinate, damage type, measurement, or markup model.
- To build this as designed would require a new damage/mark entity, panel mapping, severity, photo linkage, and confirm API — a model/server change, not UI-only. A local-only prototype could draw pins but could not persist/confirm them.
- The PRD lists a "360° Exterior Wireframe" as a technician module; the Phase-1 navigation/screen inventory has photo capture (T11) but no 360 screen, so scope is unconfirmed.

## 10. Locked-rule conflicts / unsafe-to-ship content

- **"Never invent … measurements/results"**: `2.5 cm` (1:7972) is a precise measurement with no capture/source; `1 Detected` is a result count with no model. The damage type is `Crease` in the subtitle but `Dent` in the title — contradictory.
- **"Safety is visible"/"colour + icon + text"** (design system §3.1): damage is drawn as a **green** pin (`#10B981`) with a white check. Green is the verified/no-issue colour; a detected dent should not be the most affirmative colour. The semantic state is ambiguous and could be misread as "checked/OK".
- **Severity is missing**: the product requires Minor/Moderate/Major/Safety-critical + icon + text for defects. This screen shows no severity, no result code, no note/reason, and no safety guidance.
- **"No Damage Found on this Panel" vs `Front Left Door Dent`**: both are visible in the same driver-side view (1:7950 vs 1:7970). The two decisions contradict each other; a technician could confirm the wrong state.
- **"360" overclaim**: the UI says `Tap to rotate 360°` and the screen is titled `360 Exterior Wireframe`, but the export contains one 2D side profile and four static angle buttons; no 360 control or other views exist. Do not ship the capability claim without the full asset set/behaviour.
- **"Finalized findings/evidence immutable"**: `Edit` is available with no finalized/read-only state; if reused after finalization it would permit changing locked evidence. No audit/history is shown.
- **"UI layer only; no … model/validation/state/server change"**: the damage pin/callout/confirm flow requires a new model and server contract. It cannot be delivered as a UI-only change.
- **"Public report" media rules**: if this vehicle schematic or a captured damage photo is reused publicly, no customer/plate/VIN data may appear; the generic schematic is safer than a photo, but the callout's measurement/label must be approved.
- **WCAG 2.2 AA**: 28x28/33.6x32 pins are below 44x44; the canvas is tap-only with no keyboard/list alternative; the car stroke is 2.15:1 and green pins 2.54:1 on white; state is colour/shape only; no Arabic/RTL.
- **No certification claims** appear here, but "1 Detected" must not become a condition score.

## 11. Open questions / could not verify

- Is this a real damage model (panel + type + measurement + severity + photo), or a visual prototype over the existing per-item assessment?
- Why is a detected dent green? What do the four unselected green pins mean — tap targets, minor defects, or verified panels?
- How can `1 Detected` coexist with five rendered pins? Which pins are findings vs interactive zones?
- Is `2.5 cm` an actual measurement, an estimate, or sample data? Who enters it, and with what unit/precision?
- Is the defect a `Dent` or a `Crease`? The title and subtitle disagree.
- Should "No Damage Found on this Panel" clear the existing damage, or is it a separate per-panel result? The screen shows both states at once.
- Are Front/Passenger/Rear views designed/exported anywhere? Only the driver-side profile is in the assets.
- Is the "360" claim approved? No 3D/rotate control is present.
- Where is the photo capture/attachment step, and how is "Photo Attached" linked to this damage?
- Is editing allowed after finalization? No locked state is shown.
- No prototype reactions; pin selection, view switching and confirm cannot be verified.
