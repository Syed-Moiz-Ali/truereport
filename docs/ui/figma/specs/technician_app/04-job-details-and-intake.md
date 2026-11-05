# 04. Job Details & Intake

- App: Technician
- Figma node: 1:7396
- Frame: 390x1128 px (mobile phone; 390 pt logical width)
- Export folder: `screens/04_4._Job_Details_&_Intake`
- Sources read: `4._Job_Details_&_Intake.json`, `4._Job_Details_&_Intake@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html`
- Confidence: high — complete tree, clear PNG, and asset metadata; only the data provenance of the sample fields is unverifiable.

## 1. Purpose

Job/intake overview: vehicle hero image, structured vehicle identification, customer contact card, a pre-inspection readiness strip, and a sticky "Start Inspection" CTA. It combines T04 (job detail), T05 (customer intake) and T06 (vehicle identification) into one read-only screen.

## 2. Layout structure

- Root `1:7396`: VERTICAL, FIXED width / HUG height, 390x1128, `#FFFFFF`.
- `1:7397` `Main`: VERTICAL, padding `0/64/0/0`; `1:7398` content 390x1064 is **not Auto Layout** (absolute children).
- Visual order and positions (content coordinates):
  - `1:7399` metadata/progress header 350x54 at y0: padding `0/8/0/24`; `INTAKE PHASE` pill, `Ready for Check` chip, `10:42 AM • Bay 3` at the end.
  - `1:7501` hero banner margin 350x200 at y54; `1:7502` 350x176 radius 32, image FILL/FILL; gradient overlay 350x176; plate chip `REG: LV71 XZP`; white vehicle title.
  - `1:7409` vehicle card margin 350x310 at y254; `1:7410` 350x290, radius 32, padding 24, gap 20. Contains a 40 px heading row, a 302x96 two-column **GRID** (`Make/Model`, `Year/Odometer`), and a 302x66 VIN row with copy button.
  - `1:7451` customer card margin 350x296 at y564; `1:7452` 350x276, radius 32, padding 24, gap 20. Contains a heading row with `Primary Owner` chip, name, phone + call/message buttons, and service package.
  - `1:7489` readiness strip 350x76 at y860: radius 32, padding 20, `Pre-Inspection Ready`, `Keys received • Fuel at 70%`, `Step 1 of 4`.
- Header `1:7520` 390x64 at y0, absolute, `#FFFFFFCC` + 48 px background blur; back button 44x44, title 18/24, 32x32 profile circle.
- Sticky CTA `1:7514` 390x80 at y1048, absolute, `#FFFFFFE5` + blur + upward shadow; 350x56 pill button.
- FILL width, fixed heights. No breakpoints/tablet variant, no scroll container; the 1128 px frame exceeds a normal phone viewport and is clipped by the sticky CTA in a real viewport.
- The 2x2 vehicle grid relies on a fixed 302x96 container; no wrapping or large-text strategy is encoded.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

| Hex | Usage | Approx. count |
|---|---|---|
| `#5E5D69` | labels, metadata, secondary text | 14 |
| `#1B1B25` | values, card headings | 12 |
| `#FFFFFF` | card surfaces, CTA label, vehicle title | 11 |
| `#F4F3F8` | icon tiles, VIN row, call/message buttons | 8 |
| `#10B981` | CTA, icons, step text, service check | 7 |
| `#1A1B1F` | header title, service name | 5 |
| `#FFFFFFE5` | sticky bar | 3 |
| `#00422B` | "Ready for Check" text | 1 |
| `#006C49` | profile circle | 1 |
| `#6FFBBE33` | readiness icon tint | 1 |
| `#6FFBBE4D` | readiness overlay | 1 |
| `#FFFFFFCC` | header | 1 |

`#10B981` text on white = 2.54:1 ("Step 1 of 4" 12 px fails); `#5E5D69` = 6.47:1; `#00422B` on the pale green chip is high contrast.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)

| Text / node | Family / weight | Size / line-height | Tracking | Alignment | Usage |
|---|---|---|---|---|---|
| Header title 1:7527 | Plus Jakarta Sans / 700 | 18 / 24 | -0.45 px | left | Screen title |
| `INTAKE PHASE` 1:7403 | Plus Jakarta Sans / 600 | 11 / 14 | +0.275 px | left | Phase chip |
| `Ready for Check` 1:7406 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Status chip |
| `10:42 AM • Bay 3` 1:7408 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | right | Metadata |
| `Vehicle Info` 1:7417 | Plus Jakarta Sans / 700 | 18 / 24 | -0.27 px | left | Card heading |
| Labels `Make`, `Model`, `Year`, `Odometer` | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Field label |
| Values `Renault`, `Megane 3`, `2021`, `34,180 mi` | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Field value |
| `VIN / Chassis` 1:7445 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | VIN label |
| `VF1KZ040647192831` 1:7447 | Plus Jakarta Sans / 600 | 13 / 18 | +0.65 px | left | VIN value |
| `Customer Info` 1:7459 | Plus Jakarta Sans / 700 | 18 / 24 | -0.27 px | left | Card heading |
| `Primary Owner` 1:7461 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Customer chip |
| `Arthur Pendelton` 1:7467 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Customer name |
| `+44 7700 900077` 1:7473 | Plus Jakarta Sans / 600 | 16 / 24 | -0.40 px | left | Phone |
| `Comprehensive Fleet Tier-1 Multi-Point` 1:7486 | Plus Jakarta Sans / 500 | 14 / 20 | -0.07 px | left | Service package |
| `Pre-Inspection Ready` 1:7496 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | left | Readiness |
| `Keys received • Fuel at 70%` 1:7498 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Readiness detail |
| `Step 1 of 4` 1:7500 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | left | Progress |
| `REG: LV71 XZP` 1:7508 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Plate overlay |
| `Renault Megane 3` 1:7510 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Vehicle title |
| `Start Inspection` 1:7517 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | centre | CTA |

### Radii, shadows/elevation, strokes, spacing values

- Radii: 9999 ×16; 32 ×4 (hero banner, both cards, readiness strip). The VIN row is a square `#F4F3F8` block inside the 32 px card.
- Card shadow `r=8 off=0,2` 1.6% + `r=40 off=0,14` 4.3%; sticky bar upward `r=30 off=0,-10` 3%; CTA `r=25` emerald 30%; header 5% + blur.
- No strokes. Spacing: page margin 20; card padding 24; card gap 20; field label/value gap 4; VIN row padding 14/16/14/14; 24 px between sections.
- Touch targets: copy VIN 36x36, call/message 40x40, profile 32x32 — all below the 44 px minimum. Back is 44x44; CTA 56 high.

## 4. Components

| Figma pattern / node | Instances | Map to our design system |
|---|---|---|
| Fixed translucent header 1:7520 | 1 | `AppBar`; current job detail uses a plain app bar with title only |
| Metadata chips 1:7401 | 1 row | `StatusChip`; no phase/bay model |
| Vehicle hero banner 1:7502 | 1 | no equivalent (image + gradient + plate chip) |
| Info card 1:7410 / 1:7452 | 2 | `Card` + custom label/value columns; `AppCard` padding is 16, not 24 |
| VIN copy row 1:7442 | 1 | no equivalent (copy-to-clipboard affordance) |
| Call/message buttons 1:7474 | 1 composed pair | no equivalent; requires device integration |
| Readiness strip 1:7489 | 1 | no equivalent |
| Sticky CTA 1:7515 | 1 | `AppButton(primary, expand)` inside a bottom bar |
| Readiness/service icons 1:7488/1:7493 | 2 | Material icons |

No component instances/variants; the composed 88x40 `Container-1_7474` is only a phone icon + message icon pair, not a decorative graphic.

## 5. Assets

- Manifest count: **14** (12 individual SVGs, **1 composed** 88x40, **1 raster**).
- Composed: `composed-1_7474` = phone + message icon pair (child vectors 1:7477, 1:7480); should be built as two icon buttons, not a flattened SVG.
- Raster: `raster-1-65acd06481` = `assets/images/original/image-1-65acd06481.jpg`, **512x279 JPEG**, 22,378 bytes, displayed 350x176. It is a **vehicle photo** (blue Renault hatchback) with a gradient overlay. A front plate area is visible in the composition; provenance, licence and plate blurring are unverified.
- Other icons: back, car, copy, phone, message, shield, arrow, check/readiness, service check.
- The image file has a long opaque original name, not a semantic asset name.

## 6. Content and data

| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| `Vehicle Walkaround Inspection` | header | No | Current screen title is "Job details" / `l10n.jobDetails` |
| `INTAKE PHASE` | phase | No | No phase field |
| `Ready for Check` | status | No | Not one of `DRAFT/ASSIGNED/IN_PROGRESS/READY_TO_FINALIZE/FINALIZED/CANCELLED` |
| `10:42 AM • Bay 3` | time/bay | Partly | `scheduledAt` exists; bay/time formatting and bay field do not |
| `Renault` / `Megane 3` / `2021` | make/model/year | Yes | `vehicleMake`, `vehicleModel`, `vehicleYear` |
| `34,180 mi` | odometer | Yes (`odometerValue`/`odometerUnit`) | Sample uses miles; product supports `KM`; unit is inconsistent with the UAE context and not verified |
| `VF1KZ040647192831` | VIN | Yes (`vehicleVin`) | Full 17-character VIN is exposed; must not appear in a public report |
| `Arthur Pendelton` | customer name | Yes (`customerName`) | Sample PII; preserve exact script in real use |
| `Primary Owner` | relationship | No | No owner/relationship field |
| `+44 7700 900077` | phone | Yes (`customerPhone`) | Sample PII; UK-format number |
| `Comprehensive Fleet Tier-1 Multi-Point` | service package | Partly (`templateName`/`scope`) | "Tier-1" is an invented product claim/level |
| `Pre-Inspection Ready` | readiness | No | No field |
| `Keys received • Fuel at 70%` | checklist values | No | Fuel percentage is an invented measurement; no fuel field |
| `Step 1 of 4` | progress | No | No step model; conflicts with screen 05 "STEP 4 OF 4" |
| `REG: LV71 XZP` | plate | Yes (`vehiclePlate`) | Full plate exposed; must not appear publicly |
| `Renault Megane 3` | vehicle title | Yes | Misspelling "Megane" vs "Megan" on screen 02 |
| `Start Inspection` | action | Yes | `technicianStart` (`/api/v1/technician/jobs/{id}/start`) |

No condition score appears. The screen is dense with customer/vehicle PII and two invented measurements.

## 7. States shown / not shown

Shown: one "ready for check" intake state with complete sample data; enabled Start CTA; read-only info.

Not shown: loading skeleton; error/request ID; offline/saved-on-phone; reassigned; cancelled; disabled workshop; missing template; finalized/read-only; conflict; edit forms for customer/vehicle; consent/equipment entry; "not provided" values; Arabic/RTL.

## 8. Implied interactions

- Back; profile circle; copy VIN; call customer; message customer; `Start Inspection`.
- Vehicle/plate chips may be tappable but no press states exist.
- No prototype reactions; copy/call/message/start destinations are inferred.

## 9. Correspondence to current product

- Matches T04 Job detail (`/jobs/:jobId`), T05 Customer intake, T06 Vehicle identification. Code: `job_detail_page.dart`; `technicianJob`, `technicianCustomer`, `technicianVehicle`, `technicianStart`.
- The current page shows a summary plus buttons that open **edit bottom sheets** for customer and vehicle; the Figma is a read-only intake summary with phone/message actions and a single Start CTA. The current page also links to consent/equipment, which the Figma moves to screens 05/06.
- `TechnicianJob` has no bay, phase, readiness, fuel, step or owner fields. The vehicle photo and call/message actions have no data/API.
- A UI-only build can render the existing fields, but "Ready for Check", "Step 1 of 4", "Fuel at 70%", "Primary Owner", bay/time and the photo require new data or removal.

## 10. Locked-rule conflicts / unsafe-to-ship content

- **"Public report never shows customer name/phone/email/full VIN/plate"**: this is a technician-only screen, so showing them is permitted internally. However, the export contains all four plus a vehicle photo, so any reuse in the public report, PDF, marketing, or screenshots would violate the rule. The vehicle photo may contain a plate; provenance/blurring is unverified.
- **"Never invent versions/licences/measurements/results"**: `34,180 mi`, `Fuel at 70%`, `Comprehensive Fleet Tier-1 Multi-Point`, and `Step 1 of 4` are sample values presented as facts.
- **"VIN OCR/scanning (deferred)"**: the QR/scan icon in the Vehicle Info heading (1:7420) implies VIN/asset scanning; no scan flow exists.
- **"no manager role/approval queue"**: none shown; `Pre-Inspection Ready` is a technician readiness claim, not an approval.
- **"Finalized findings/evidence immutable"**: no finalized/read-only variant is shown; the screen must not be reused as an editable job view after finalization.
- **WCAG 2.2 AA**: copy 36x36, call/message 40x40, profile 32x32 are below 44 px; `Step 1 of 4` green text is 2.54:1; no RTL.
- **Step numbering**: "Step 1 of 4" here, "STEP 4 OF 4" on screen 05, "01 PRE-INSPECTION SETUP" on 06, "Step 2" on 08 — the flow cannot be reconciled from these screens.
- **Odometer unit**: the sample uses miles while the product/UAE context uses `KM`; the unit must come from the data, not a fixed suffix.

## 11. Open questions / could not verify

- Is the full VIN/plate/phone intentionally shown to the technician? Yes for internal work, but what masking policy applies on screenshots/logs?
- Are `10:42 AM`, `Bay 3`, `Ready for Check`, `Primary Owner`, `Fuel at 70%` real fields, or placeholders? None are in `TechnicianJob`.
- Is the vehicle photo a real job image, a stock render, or a master-data image? Where is it stored? May it contain a plate?
- Is "Comprehensive Fleet Tier-1 Multi-Point" an approved template name or invented marketing copy?
- Is the odometer sample meant to be miles or km? Why does the UI hardcode `mi`?
- Should the technician be able to call/message from the app? No `tel:`/SMS integration or permission model is specified.
- Is the scan icon a VIN scan entry point? VIN scanning is deferred in the navigation map.
- Does the sticky CTA overlap the readiness strip at smaller heights or 200% text? The frame is fixed 1128 px.
- No prototype reactions; copy/call/message/start cannot be verified.
