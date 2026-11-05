# 6. Detailed Findings Grid (Desktop Web)

- App: Public Report
- Figma node: 1:6578
- Frame: 1280x1687 px (desktop)
- Export folder: `screens/06_6._Detailed_Findings_Grid_(Desktop_Web)`
- Sources read: `6._Detailed_Findings_Grid_(Desktop_Web).json`, `6._Detailed_Findings_Grid_(Desktop_Web)@2x.png`, `assets/manifest.json`
- Confidence: high for layout/tokens; high for conflicts (explicit coordinates, VIN-adjacent identity and certification copy).

## 1. Purpose

Desktop "Detailed Findings" tab: a dossier/title area with status filter pills; a 12-column bento grid containing an 8-column exterior-damage hero card (schematic + coordinates + macro photo + recommended protocol), a 4-column tyre/braking card, and three 4-column cards (engine/fluids, battery/telemetry, underbody); then a full-width technician certification/sign-off card with "Audit Trail Log" and "Approve & Finalize Report".

## 2. Layout structure

Root `1:6578` VERTICAL, 1280x1687. Siblings: Main `1:6579` 1280x1605 (pad 80/0/0/0), Footer `1:6881` 1280x82, Header `1:6895` 1280x80 (overlay at y=0).

| Order | Node | Geometry | Notes |
|---|---|---|---|
| 1 | Main `1:6579` | 1280x1605 | VERTICAL, pad 80/0/0/0 |
| 1.1 | Container `1:6580` | 1280x1525 | VERTICAL, pad 32/20/32/20, gap 32 |
| 1.1.1 | Title area `1:6581` | 1240x127 | HORIZONTAL, gap 183.92; left 658.77, right filter 384.08x32 |
| 1.1.2 | Bento grid `1:6598` | 1240x1142 | **GRID** (12-col: 816 + 392 = 1208 + 32 gap; row 2 = 392x3 + 2x32) |
| 1.1.3 | Sign-off `1:6863` | 1240x128 | HORIZONTAL, radius 32, pad 32 |
| 2 | Footer `1:6881` | 1280x82 | pad 32/0/32/0, top shadow |
| 3 | Header `1:6895` | 1280x80 | translucent `#FFFFFFE5`, blur 48, overlays Main |

Title area: dossier chip 360.03x22 (`#F4F3F8`, 8 px dot, 11/14 600 +0.55) with **vehicle model in the chip**; H1 32/38; deck 16/26. Filter pills 384.08x32 (`#F4F3F8`) with active "All Diagnostics (48)" 147.8x24 white + shadow, "Action Items (2)" 126.19, "Passed (46)" 102.09.

Bento row 1:
- Hero card `1:6599` 816x634, radius 32, pad 32, gap 89.75. Header 752x48 (48 icon, 22/28 title, 13/18 subtitle, "Point Marker #01" chip 141.16x22 `#E1DEEC`). Split body `1:6614` 752x318.25, gap 32: left schematic `1:6615` 360x300, pad 45.59/24; right notes `1:6643` 360 px with severity chips, a 360x86.25 note block, and a 360x176 macro photo with a glass caption bar. Bottom status bar `1:6662` 752x58 `#F4F3F8` (protocol text 13/18 + "Est. Labor: 0.75 hrs" 12/16).
- Tyre/braking card `1:6670` 392x636, pad 32: header 328x42; chassis block 328x292 `#F4F3F8` (296 px label rows, 192x224 SVG, 68.45x22 tooltip); alert metric 328x104 (title row + 12 px chip, 328x8 progress, 328x54 note); advisory callout 328x86.

Bento row 2 (three 392 px cards, gaps 32):
- Engine & Fluids `1:6725` 392x470: header 328x42 + "100% Nominal" chip 98.69x22; three fluid rows 328x90/72/72 `#F4F3F8`; OBD row 328x50.
- Battery & Telemetry `1:6784` 392x474: header 328x42 + "HEALTH 98%" 11/14; gauge 328x168 `#F4F3F8` with 12.78 V (32/38), CCA line, 280x48 sparkline; two rows 328x18; last-service bar 328x46.
- Underbody & Struct `1:6824` 392x474: header 328x42 + shield check 18.33; 4-row list 328x34 each; underbody thumbnail 328x96 with "Laser Geometry Verified" overlay.

Sign-off: 64 px icon circle; title 18/24; 14/20 text; right 435.21x56 with "Audit Trail Log" 156.75x56 and "Approve & Finalize Report" 262.46x56 primary.

Header nav: "Detailed Findings" active (163.84x40), plus Report Overview and Compliance & Scope; Download PDF and account avatar. Footer identical to screen 5.

Responsiveness: fixed 1280; the bento reflows only by hand (no auto-layout grid). At narrower widths the 816/392 and 392x3 compositions have no defined collapse; header would overlap the title because it overlays Main.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx count)

| Hex | Count | Usage |
|---|---|---|
| `#3C4A42` | 36 | Body, sub-labels, footer |
| `#1A1B1F` | 28 | Titles/values |
| `#F4F3F8` | 26 | Tiles, pills, callouts |
| `#FFFFFF` | 23 | Cards |
| `#006C49` | 16 | Positive labels/icons |
| `#10B981` | 16 | Brand, checks, CTA |
| `#3C4A4266` | 7 | Car line art (40% ink) |
| `#E3E2E7` | 6 | Diagram guides |
| `#B91A24` | 5 | Tyre alert, dots |
| `#10B98133` | 4 | Check circles, pin halo |
| `#00422B` | 3 | Check glyphs |
| `#FFDAD6` | 3 | Alert chip fills |
| `#93000A` | 2 | Alert chip text |
| `#FFFFFFE5` | 2 | Glass overlays |
| `#62616D` | 1 | Point marker text |
| `#BA1A1A` | 1 | Alert tyre stroke |
| `#E1DEEC` | 1 | Point-marker chip |
| `#E9E7ED` | 1 | Progress track |
| `#FF7A73` | 1 | Point-marker dot |

### Typography

| Size / line-height / weight / tracking | Usage |
|---|---|
| 32/38, 800, -0.8 | H1 "Inspection Findings" (`1:6588`) |
| 32/38, 800, -0.8 | "12.78" battery value (`1:6799`) |
| 22/28, 700, -0.44 | Hero card title (`1:6608`), exemption titles in screen 7 |
| 18/24, 700, -0.27 | Card titles (`1:6679`, `1:6734`, `1:6793`, `1:6833`), sign-off (`1:6870`) |
| 16/26, 500, -0.16 | Deck (`1:6590`) |
| 16/22, 700, -0.16 | Sub-heads, values, "Engines" rows (`1:6747`, `1:6812`) |
| 14/22.75, 500, -0.07 | Long notes/callouts (`1:6653`, `1:6718`, `1:6724`) |
| 14/20, 500, -0.07 | Sign-off text (`1:6872`), metric labels |
| 14/18, 700, -0.14 | Buttons (`1:6880`), values |
| 13/18, 400 | Table/list/body (`1:6610`, `1:6781`, `1:6867`) |
| 12/16, 600, +0.24 | Filter pills, chips (`1:6593`, `1:6646`) |
| 11/14, 600/700, +0.44/+0.55/+0.6 | Eyebrows, labels, counts, severity, photo captions, coordinates (`1:6637`, `1:6651`, `1:6802`) |

### Radii, shadows/elevation, strokes, spacing

- Radii: `9999` x38; `32` x6 (all cards).
- Shadows: cards `8 @ 0,2` + `40 @ 0,14`; pin `24 @ 0,8`; macro photo caption `12 @ 0,4` + blur 24; CTA `25 @ 0,10`.
- Strokes: car line art 1.17–2.34 px `#3C4A4266`; chassis guides `#E3E2E7` 2.8–3.73 px; alert tyre 2.8 px `#BA1A1A`; no card borders.
- Spacing: 3, 3.25, 4, 8, 16, 20, 24, 32, 45.59, 89.75, 109.89; card padding 32; grid gap 32; chips 9999.

## 4. Components

No `COMPONENT`/`INSTANCE` nodes (FRAME 219, TEXT 83, VECTOR 36, RECTANGLE 7).

| Pattern | Node(s) | HTML/CSS equivalent |
|---|---|---|
| Bento card | `1:6599`, `1:6670`, `1:6725`, `1:6784`, `1:6824` | `.card` (current has no grid) |
| Filter pills | `1:6591` | none |
| Severity/status chip | `1:6645`, `1:6647`, `1:6713`, `1:6737`, `1:6795` | `.badge` |
| Camera/photo specimen | `1:6654` | `.photos figure` |
| Data list row | `1:6838`–`1:6857` | category `<table>` |
| Sign-off card + actions | `1:6863` | none |
| App bar | `1:6895` | `header.report-header` (different) |

## 5. Assets

Manifest: 42 assets — 36 SVG (icons + diagram vectors), 4 composed SVG, 2 raster.

| Asset | Node | Role | Size / bytes | Safe? |
|---|---|---|---|---|
| `Icon-1_6605.svg` | `1:6605` | Exterior icon | 582 B | Yes |
| `Vector-1_6619..6628` | `1:6618` | Car line art | 207–1,116 B | Yes (generic) |
| `Sleek SVG Line Art Car Profile-1_6617.svg` | `1:6617` | Composed car profile | 4,705 B | Yes |
| `Sleek SVG Line Art Car Profile-margin-1_6616.svg` | `1:6616` | Composed car profile + margin | 4,723 B | Yes |
| `SVG-1_6618.svg` | `1:6618` | Generic SVG | 3,521 B | Yes |
| `image-1-96fe1d6167.jpg` | `1:6655` | Macro paint/depth-gauge evidence | 512x279, 24,719 B | Allowed derivative; verify no plate/face |
| `Icon-1_6665..6790` | matrix/icons | Tyre, engine, battery, underbody, seals | 256–3,980 B | Mostly yes; seals imply certification |
| `SVG-1_6697.svg` | `1:6697` | 4-wheel chassis | 1,744 B | Yes |
| `Vector-1_6698..6704` | `1:6696` | Chassis/tyre vectors | 207–443 B | Yes |
| `image-2-e9a5952732.jpg` | `1:6859` | Underbody photo 512x279 | 51,430 B | Allowed derivative, but the thumbnail appears to include a person/legs and workshop floor; verify no face/plate |

No avatars or hero stock car; the two photos are evidence-style, not a vehicle glamour shot.

## 6. Content and data

| Visible text / label | Sample value | Real data field? | Notes |
|---|---|---|---|
| "DOSSIER #APX-88294 • PORSCHE MACAN GTS (2023)" | dossier + vehicle | `reportNumber` + make/model/year | Vehicle model is placed in the title/meta area (rule against model in title metadata); dossier format differs from screen 5 |
| "Inspection Findings" / "Comprehensive breakdown..." | title/deck | static | Fine |
| "All Diagnostics (48) / Action Items (2) / Passed (46)" | filters | counts partial | "Passed" not a product label; counts disagree (48 vs 46+2; screen 5 says 110 checks) |
| "Exterior Damage & Visual Evidence" / "Calibrated optical scanning • Zone B-4 (Driver Side Mid-Panel)" | section | no | "Calibrated"/"Zone B-4" claims/internal zone |
| "Point Marker #01" | marker | no | Internal |
| "LAT 52.88 / LON 14.02 • Surface Depth Vector" | coordinates | **no** | **Precise location**; no such field |
| "Elevation: 680mm from floor" | measurement | no | Invented |
| "Area: Left Front Door" | area | note text only | No structured field |
| "MODERATE SCRATCH" / "Non-Structural" | severity/type | severity code exists; "Scratch"/"Non-Structural" do not | New taxonomy |
| "MECHANIC OBSERVATION LOG" | label | no | Internal log wording |
| "paint depth measured at 112µm (baseline 124µm)" | measurement | no | Invented; note text only |
| "Visual Specimen 01-A" / "100% Optical Zoom" | photo captions | no | New metadata |
| "Recommended Protocol: Stage 2 Rotary Polishing & Micro-Clear Application" | recommendation | recommendation (if snapshot) | New structured recommendation |
| "Est. Labor: 0.75 hrs" | estimate | no | Invented labour estimate |
| "Tyre & Braking Health / Wheel Hubs & Friction Linings" | card | category label partial | Category naming inconsistent with screens 2/3 |
| "Front Axle / 32.0 PSI Avg / Rear Axle / Asymmetric Tread" | diagram | no | New fields |
| "2.4mm (Wear Alert)" / "Legal limit is 1.6mm" / "Brake pad lining remaining: 7.2mm" | measurements | no | Invented values |
| "ADVISORY / Immediate tire rotation & 4-wheel dynamic alignment strongly advised." | advice | no | New copy; safety advice must come from approved content |
| "Engine & Fluids / 100% Nominal" | card | no | Aggregate |
| "Engine Oil Level / Viscosity: 0W-40 / Synthetic / Optimal (Max)" | fluids | no | Invented |
| "Coolant Specific Gravity / Freeze Protection to -35°C / Verified" | fluids | no | Invented |
| "Brake Fluid Moisture / DOT 4 • Boiling Pt 248°C / < 1% (Clean)" | fluids | no | Invented |
| "OBD-II ECU Interrogation / 0 Faults Logged" | diagnostics | no | Invented |
| "Battery & Telemetry / 12V AGM System Health / HEALTH 98%" | card | no | Invented |
| "12.78 Volts / Cold Cranking Amps: 840 CCA (Rated 850)" | measurement | no | Invented |
| "Alternator Output under Load 14.3V (Pass) / Parasitic Draw (Sleep Mode) 18mA (Nominal)" | measurements | no | Invented |
| "Last Physical Battery Service 14,200 km ago" | service | no | Invented |
| "Underbody & Struct / Hydraulic & Bushing Clearances" | card | no | Category naming |
| "Front Control Arm Bushings Tight (<0.5mm play)" | measurement | no | Invented |
| "Tie Rod Ends & Ball Joints Zero Deflection" / "Exhaust Flanges & Catalytic Clean / Undamaged" / "Driveshaft CV Boots Intact (No grease leak)" | results | no | Invented |
| "Laser Geometry Verified" | claim | no | Invented method |
| "Technician Certification & Signature" / "Marcus Vance (ASE Master Tech #48102-L)" / "VDA 6.3 standards" | staff/certification | `technician.displayName` (Pending) | Full name, certification number, standard claim |
| "Audit Trail Log" / "Approve & Finalize Report" | actions | no | Internal audit + write action |
| "Reference #APX-88294-FL" / ISO/footer claims | footer | report number partial | "Official"/"ISO"/"Tamper-Proof" claims |

No customer name/phone/email, no plate, no VIN. Precise coordinates are present.

## 7. States shown / not shown

Shown: active "Detailed Findings", one moderate defect, one tyre wear alert, one advisory, positive results for engine/battery/underbody, sign-off pending.

Not shown: Arabic/RTL, no defects/clean report, many defects/overflow, missing photos, long notes, empty categories, PDF disabled, invalid/revoked, error/offline, loading, focus/hover/pressed, 200% zoom, dark mode, narrower desktop/tablet, audit log modal.

## 8. Implied interactions

- Filter pills switch the bento contents (All/Action/Passed).
- Photo zoom/lightbox (specimen overlay).
- "Audit Trail Log" opens internal audit events.
- "Approve & Finalize Report" approves/finalizes (write).
- Nav tabs, Download PDF, account avatar, print/share (from screen 5).
- Defect pins tooltips.
- None of these states are exported.

## 9. Correspondence to current product

| Figma element | Current implementation | Verdict |
|---|---|---|
| Key findings | `.item` cards with label/severity/note/reason/photos | Figma uses a bento hero with coordinates and protocol |
| Category findings | `#categories-title` per-category `<table>` with result/severity/note/reason | Figma replaces with 4 metric cards |
| Exterior | one category table row | New rich media block |
| Tyre | screen 2 detail | Duplicated/parallel design with conflicting values |
| Fuel/battery/underbody | categories/items in table | New measurement cards |
| Technician | `.detail-grid` "Technician: displayName" | Figma adds certification, signature and standards |
| Audit/finalize | none | New internal write actions |
| Styling | teal, tables, radius 12/16 | emerald, bento cards, radius 32, heavy shadows |

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **Precise location exposed.** `1:6637` "LAT 52.88 / LON 14.02". Rule: "No ... precise location ... by default" (hard rule 4); "Customer name, email, phone, address, precise location" are Never public (3.2). This is the single highest-risk item in the export.
2. **Vehicle model in title metadata.** `1:6586` "DOSSIER #APX-88294 • PORSCHE MACAN GTS (2023)". Rule: "Header | Neutral title, report ID, version, language switch | No customer name or vehicle model in the metadata/title" (2.2). Model belongs in the vehicle section.
3. **Internal zone/marker IDs.** "Zone B-4 (Driver Side Mid-Panel)" (`1:6610`), "Point Marker #01" (`1:6613`), "Visual Specimen 01-A" (`1:6658`). Rule: "Customer ID, vehicle ID, job ID, internal database IDs" never public; "Internal notes, audit events ... never public."
4. **Invented measurements.** LAT/LON/elevation/paint depth 112/124 µm, 32.0 PSI, 2.4 mm, 1.6 mm, 7.2 mm, 0W-40, −35 °C, 248 °C, 12.78 V, 840/850 CCA, 14.3 V, 18 mA, 14,200 km, <0.5 mm, etc. Rule: "Never invent versions/licences/measurements/results" (task); none of these exist in `ReportSnapshot`.
5. **Certification/signature.** "Technician Certification & Signature", "ASE Master Tech #48102-L", "VDA 6.3 standards" (`1:6870`, `1:6872`). Rules: no "certified" unless factually/legally true; "Staff personal contact details" never public and technician display name is Pending. A signature/certification card is an authenticity claim not in the public model.
6. **Write actions.** "Approve & Finalize Report" (`1:6876`), "Audit Trail Log" (`1:6874`). Rule: finalized reports immutable; public page read-only; no admin code; "Internal notes, audit events ... never public" (3.2).
7. **PDF/nav/account.** Header "Download PDF" + avatar + tabs. ADR-0008: no download in V1; hard rule 8: no customer login; section 1: not a portal.
8. **Condition score / pass language.** "Passed (46)", "100% Nominal", "HEALTH 98%", "Pass" counts (`1:6597`, `1:6737`, `1:6796`, `1:6812`). Rule: "Coverage, not a single condition score"; `NO_ISSUE_OBSERVED` must never be labelled "Pass" (`10-design-system.md` 3.3).
9. **False reassurance.** "Exterior Damage ... Non-Structural", "Clean / Undamaged", "Zero Deflection", "Optimal (Max)", "0 Faults Logged". Rule: "No false reassurance. Never use a green 'pass' badge that implies the vehicle is perfect" (10-design-system 1); "a clean result does not mean the vehicle is perfect."
10. **Safety advice invented.** "Immediate tire rotation & 4-wheel dynamic alignment strongly advised" (`1:6724`). Rule: severity text may include "Do not drive" only "where the master item supports it; do not invent safety advice beyond approved content" (10-design-system 3.4).
11. **"Laser Geometry Verified" / "Calibrated optical scanning".** Overstated method; inspection is visual and non-invasive.
12. **Data consistency.** "Porsche Macan GTS (2023)" vs screen 5 "Renault Megan 3"; tyre 2.4 mm vs 5.4 mm Avg; 110 checks vs 48 diagnostics; hashes differ. Rule: one immutable snapshot per version; inconsistent values cannot all be true.
13. **Photos.** The underbody thumbnail appears to include a person's legs/workshop; macro photo may include a gauge/reflection. Rule: "Do not publish a photo that clearly contains a plate, VIN plate, customer face or address unless ... approval; default is to crop/blur or omit." Verify.
14. **Contrast.** `#10B981` on white/lavender for "Pass"/"Verified"/values (≈2.4–2.6:1) fails AA for normal text; small 11 px labels in `#5E5D69` on `#F4F3F8` are borderline.
15. **"© 2025"** and "ISO 9001:2015 Accredited" / "Tamper-Proof Audit Vault" footer claims; no legal/ops evidence.
16. **Dark mode regression.** Current page supports `prefers-color-scheme`; this desktop design is light-only.

## 11. Open questions / could not verify

- Is this an authenticated **Workshop Admin** report viewer? The finalize/audit/sign actions and account avatar make that likely; the export folder says "Public Report".
- Where do LAT/LON come from, and are they vehicle-damage coordinates or customer/workshop location? Either reading is prohibited as "precise location" in a public page.
- Which vehicle is the report for? Screen 6 says Porsche Macan; screen 5 says Renault Megan 3.
- Are all the fluid/battery/underbody measurements real template item results? They have no schema; if they are, the model/API change is out of F0 scope.
- Is "VDA 6.3" or "ASE Master Tech" a real credential of the workshop/technician? No evidence in the repo.
- Is "Est. Labor: 0.75 hrs" approved and from where?
- Are the two photos compliant with the face/plate policy? The underbody image may include a person.
- What happens at narrower desktop widths? No breakpoints are defined for a 1240 px bento.
- Which hash/reference is canonical (screens 4/5/7)?
- Does "Approve & Finalize" belong to a different role/flow (D9 says no review queue/manager role)?
