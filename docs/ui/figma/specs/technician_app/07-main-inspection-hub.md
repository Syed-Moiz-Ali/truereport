# 07. Main Inspection Hub

- App: Technician
- Figma node: 1:7742
- Frame: 390x1130 px (mobile phone; 390 pt logical width)
- Export folder: `screens/07_7._Main_Inspection_Hub`
- Sources read: `7._Main_Inspection_Hub.json`, `7._Main_Inspection_Hub@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html`
- Confidence: medium — clear visuals and complete tree, but the parent container has no Auto Layout (absolute visual order), and the coverage/“Passed” semantics are ambiguous.

## 1. Purpose

In-progress inspection hub: overall checks-done ring, passed/action counts, a vehicle reference strip, four category cards (Exterior, Interior, Engine, Underbody), a "Continue Interior Checklist" action, and the bottom nav. It is a dashboard alternative to the flat checklist grouped list.

## 2. Layout structure

- Root `1:7742`: VERTICAL, FIXED width / HUG height, 390x1130, `#FFFFFF`.
- `1:7743` `Main`: VERTICAL, padding `20/64/20/112`; `1:7744` content 390x954 is **layoutMode NONE** (absolute children), so the visual order below comes from y positions, not tree order.
- Visual order/positions:
  - `1:7745` status row 350x42 at y16: 195.6x26 pill `INSPECTION IN PROGRESS`; right `Bay #04 • VIN 8492` 119.1x16.
  - `1:7772` hero ring card 350x302 at y58: 350x278, radius 32, padding 24; 176x176 ring; `45` 26/32 + `/110` 14/20 + `CHECKS DONE`; 302x26 stat row under the ring (`42 Passed`, `3 Action Items`).
  - `1:7753` vehicle strip 350x104 at y362: 350x80, white, shadow, padding 16; 48x48 circular vehicle photo; `Porsche Taycan 4S`; `WA1-VAA-Y7890 • 12,480 mi`; 32x32 chevron.
  - `1:7766` section header 350x34 at y466: `Inspection Modules`; `4 Categories`.
  - `1:7798` grid 350x374 at y500: 350x350 **GRID**, two 167 px columns and two 167 px rows with 16 px gutters; cards radius 32, padding 20; Exterior (verified), Interior (in progress), Engine (queued), Underbody (queued).
  - `1:7858` CTA 350x64 at y874: 350x56 pill `Continue Interior Checklist`.
- Header `1:7863` 390x64 at y0, absolute, `#FFFFFFCC` + 48 px blur; 36x36 hub icon + title `Intake Hub`; 32x32 profile circle.
- Nav `1:7874` 390x80 at y1050, absolute; 350x64 pill; four links 56x44, active `Intake`.
- FILL width, fixed heights. No breakpoints, no scroll container. The 1130 px frame exceeds a normal phone viewport; the fixed nav covers the last 80 px.
- The visual order in the PNG is status → ring → vehicle → modules → grid; the JSON tree order is status → vehicle → modules → ring → grid. This is an absolute-layout artifact, not a responsive flex column.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

| Hex | Usage | Approx. count |
|---|---|---|
| `#5E5D69` | labels, meta, inactive nav, queued text | 20 |
| `#1A1B1F` | titles, values, active nav | 15 |
| `#FFFFFF` | cards, nav, ring centre | 13 |
| `#F4F3F8` | chips, icon tiles, chevron tiles | 10 |
| `#10B981` | ring arc, verified check, CTA, progress bar | 8 |
| `#EEEDF3` | ring track, category icon tile | 3 |
| `#006C49` | hub icon/profile accent | 2 |
| `#E9E7ED` | pending dots | 2 |
| `#B91A24` | action-item alert icon | 1 |
| `#FFFFFFCC` | header | 1 |

`#10B981` text on white = 2.54:1 (`28/28 Done` 11 px, "Active Bay" is grey). `#B91A24` on white = 6.49:1 (pass). `#5E5D69` = 6.47:1. The 13.2 px ring arc `#10B981` and track `#EEEDF3` are decorative/non-text but the ring is the primary data encoding; the numeric `45/110` is the accessible fallback.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)

| Text / node | Family / weight | Size / line-height | Tracking | Alignment | Usage |
|---|---|---|---|---|---|
| `Intake Hub` 1:7870 | Plus Jakarta Sans / 700 | 22 / 28 | -0.55 px | left | Header |
| `INSPECTION IN PROGRESS` 1:7750 | Plus Jakarta Sans / 700 | 11 / 14 | +0.55 px, uppercase | left | Status |
| `Bay #04 • VIN 8492` 1:7752 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | right | Context |
| `45` 1:7781 | Plus Jakarta Sans / 800 | 26 / 32 | -0.65 px | centre | Ring value |
| `/110` 1:7782 | Plus Jakarta Sans / 500 | 14 / 20 | -0.07 px | centre | Ring total |
| `CHECKS DONE` 1:7785 | Plus Jakarta Sans / 700 | 11 / 14 | +0.55 px, uppercase | centre | Ring label |
| `42 Passed` / `3 Action Items` 1:7792 / 1:7797 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | centre | Stat chips |
| `Porsche Taycan 4S` 1:7760 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Vehicle |
| `WA1-VAA-Y7890 • 12,480 mi` 1:7762 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Vehicle meta |
| `Inspection Modules` 1:7769 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Section |
| `4 Categories` 1:7771 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | right | Section meta |
| `Exterior` / `Interior` / `Engine` / `Underbody` | Plus Jakarta Sans / 800 | 18 / 24 | -0.27 px | left | Module name |
| `28/28 Done` / `17/32` / `0/24 Checks` / `0/26 Checks` | Plus Jakarta Sans / 700 or 400 | 11 / 14 or 13 / 18 | +0.44 px / 0 | left | Module count |
| `Active Bay` / `Queued` | Plus Jakarta Sans / 400 or 600 | 13 / 18 or 11 / 14 | 0 / +0.44 px | left | Module state |
| `Continue Interior Checklist` 1:7862 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | centre | CTA |
| Nav labels | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Bottom nav |

### Radii, shadows/elevation, strokes, spacing values

- Radii: 9999 ×21; 32 ×5 (ring card, module cards); 176/2 ring (circle).
- Card shadow `r=8 off=0,2` 1.6% + `r=40 off=0,14` 4.3%; CTA `r=25` emerald 30%; header 5% + blur; nav `r=12/50`.
- No strokes. Spacing: 20 page margin; 24 card padding; 16 grid gutter; 24 section gaps; 167 px cards.
- Ring 176x176 is fixed; the composed asset is named "45% filled" while the text is `45/110` (40.9%). The ring is not dynamically generated in the export.
- Ring stat pills are 26 px high; the chevron is 32x32 — below 44 px.

## 4. Components

| Figma pattern / node | Instances | Map to our design system |
|---|---|---|
| Status pill 1:7747 | 1 | `StatusChip`; `IN_PROGRESS` is a real status |
| Hero circular progress 1:7773 | 1 | no equivalent; current `LinearProgressIndicator` in `checklist_page.dart` |
| Ring stat chips 1:7788 / 1:7793 | 2 | `StatusChip`; no pass/action counts today |
| Vehicle strip 1:7754 | 1 | `AppListTile`/`Card`; image thumbnail + chevron |
| Module card 1:7800 etc. | 4 | `Card`; no category-summary component |
| CTA 1:7859 | 1 | `AppButton(primary, expand)` |
| Bottom nav 1:7875 | 1 | no current route shell |
| Hub header 1:7865 | 1 | `AppBar` with a leading icon instead of back |

No component instances/variants. The 2-column grid is a fixed GRID with 167 px cards; it has no 1-column fallback for narrow/large-text layouts.

## 5. Assets

- Manifest count: **20** (15 individual SVGs, **2 vectors**, **2 composed**, **1 raster**).
- Composed: `composed-1_7776` = `SVG Progress Ring (45% filled)` 176x176 (track + arc vectors 1:7777/1:7778); `composed-1_7801` = `Container` 127x40 (the `28/28 Done` + dot block).
- Raster: `raster-1-acb2a73648` = `assets/images/original/image-1-acb2a73648.jpg`, **176x96 JPEG**, displayed as a **48x48 circular vehicle photo** (`Porsche Taycan` thumbnail).
- The 15 icons are module/nav/alert/check icons; generic names, no provenance.
- A vehicle photo is present (not an avatar); it may contain a plate or identifying detail. Public-report photo rules would require cropping/blurring/removal.

## 6. Content and data

| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| `INSPECTION IN PROGRESS` | status | Yes (`IN_PROGRESS`) | One of the model statuses |
| `Bay #04 • VIN 8492` | bay + VIN | Partly | No bay field; `VIN 8492` is a 4-digit fragment, not a valid VIN |
| `Porsche Taycan 4S` | vehicle | Yes (`vehicleMake`/`vehicleModel`/`vehicleType`) | Sample |
| `WA1-VAA-Y7890 • 12,480 mi` | identifier + odometer | Partly | Looks like a plate/VIN hybrid; `12,480 mi` is sample mileage (product supports KM) |
| `45` / `/110` / `CHECKS DONE` | coverage count | Yes (`completed`/`total`) | Coverage, not a condition score; label is acceptable if explained |
| `42 Passed` | pass count | Derivable from `resultCode` | **"Passed" is a forbidden label**; should be "No issue observed" |
| `3 Action Items` | defect count | Derivable | "Action items" is not a product result/severity label |
| `Exterior` / `28/28 Done` | category count | Derivable (`categoryLabelEn`/assessments) | Sample category; template-driven in reality |
| `Interior` / `17/32` / `Active Bay` | category count + state | Counts derivable; state not | No "active category/bay" field |
| `Engine` / `0/24 Checks` / `Queued` | category count + state | Counts derivable; state not | "Queued" is not a result state |
| `Underbody` / `0/26 Checks` / `Queued` | category count + state | Counts derivable; state not | Same |
| `Continue Interior Checklist` | CTA | Yes (navigation) | Route not encoded |
| `Intake Hub` | title | No | Current screen title is "Checklist" |
| `Intake` / `Fleet` / `Sync` / `Profile` | nav | Sync only | No `/fleet` or `/profile` route |

No customer name/phone/email appears, but a vehicle photo and vehicle identifier do. No overall condition score appears, though "Passed" is used at item-count level.

## 7. States shown / not shown

Shown: in-progress with mixed module states (verified, active, queued), enabled Continue, coverage ring.

Not shown: empty checklist; all categories complete; all items unanswered; error/corrupt template/version mismatch; offline/local-only; conflict; loading; review/missing-items state; item-level list/search; disabled CTA; Arabic/RTL.

## 8. Implied interactions

- Tap a module card to open that category; `Continue Interior Checklist` opens the active category; chevron on the vehicle strip; nav.
- No reactions; category/CTA destinations are inferred.

## 9. Correspondence to current product

- Matches T09 Checklist (`/jobs/:jobId/checklist`) and `checklist_page.dart`, which groups items by `categoryLabelEn` and shows `completed/total` with a `LinearProgressIndicator`.
- Data: `technicianChecklist` (`InspectionChecklist` has `items`, `completed`, `total`, each item has `categoryLabelEn`, `assessment.resultCode`). Per-category counts and pass/action counts are **derivable** without a server change.
- "Active category", "Bay", "VIN fragment", and the vehicle photo are not modelled (vehicle fields exist, but no image; no active category). The hero ring and 2x2 grid are new UI.
- `42 Passed` needs a label mapping from result codes; the product forbids "Pass". `3 Action Items` needs a definition (defect/attention?).
- The current checklist is a list; this hub is a summary layer. It can route to the existing checklist.

## 10. Locked-rule conflicts / unsafe-to-ship content

- **"NO_ISSUE_OBSERVED must never be labelled 'Pass', 'Perfect' or 'Certified'"** (design system §3.3): `42 Passed` (1:7792) violates this. Use "No issue observed" or the approved result labels.
- **"no single unexplained condition score"**: `45/110 CHECKS DONE` is coverage and could be acceptable, but it is presented as a hero ring with no explanation, and the ring asset is named 45% while the values are 45/110 (40.9%). If it is meant as coverage, label and explain it, and generate the arc from the same numbers.
- **"no certification"**: no certification text here; "Action Items" is not a certification.
- **"Never invent measurements/results"**: `12,480 mi`, `WA1-VAA-Y7890`, `VIN 8492`, `28/28`, `17/32`, `42 Passed`, `3 Action Items` are sample data. The vehicle identifier format is ambiguous and `VIN 8492` is not a VIN.
- **Privacy**: a vehicle photo and plate-like identifier are on screen; this is technician-only, but the photo may contain a plate and must not flow to the public report without crop/blur/removal.
- **"Fleet" is out of scope**; nav again invents a fleet module.
- **WCAG 2.2 AA**: 32x32 chevron, 26 px stat pills; the 11 px `#10B981` category text is 2.54:1; the ring is colour/arc encoded with the numeric fallback available; no RTL.
- **"no false reassurance"**: an all-green ring + "42 Passed" could imply the vehicle is fine despite 3 action items. Use neutral coverage language and keep defects visible.
- **Immutability**: no finalized/read-only state; the hub must not allow edits after finalization.

## 11. Open questions / could not verify

- Is the hero number inspection **coverage** or a health score? The rule permits coverage, not a condition score. Where is the explanatory label?
- Why does the composed ring say 45% while the text says 45/110 (40.9%)? Which is authoritative?
- Are `42 Passed` and `3 Action Items` approved taxonomy? What result codes map to each?
- What is "Active Bay" — an active category, a physical bay, or a UI focus state? There is no field for it.
- Is `VIN 8492` a masked VIN, a job suffix, or a typo? Is `WA1-VAA-Y7890` a VIN or a plate?
- Is the vehicle photo a real job image or stock? May it show a plate?
- Are the four categories template-driven? The screen hardcodes "4 Categories" and four names.
- Should the hub route to the existing flat checklist, or replace it? Search/next-incomplete are missing.
- No prototype reactions; category/CTA navigation cannot be verified.
