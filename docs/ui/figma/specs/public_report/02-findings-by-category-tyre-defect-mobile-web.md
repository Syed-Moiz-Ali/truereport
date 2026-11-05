# 2. Findings by Category: Tyre Defect (Mobile Web)

- App: Public Report
- Figma node: 1:6035
- Frame: 390x1326.75 px (mobile)
- Export folder: `screens/02_2._Findings_by_Category-_Tyre_Defect_(Mobile_Web)`
- Sources read: `2._Findings_by_Category-_Tyre_Defect_(Mobile_Web).json`, `2._Findings_by_Category-_Tyre_Defect_(Mobile_Web)@2x.png`, `assets/manifest.json`
- Confidence: high for layout/tokens; medium for intent (the screen mixes reading and transaction/acknowledgement actions).

## 1. Purpose

Mobile category-detail screen for one tyre defect. It shows category filter pills, an axle/tyre diagram with the rear-left tyre flagged, a defect callout, a technician note, two measurement tiles, two evidence photos, a primary "Request Tyre Replacement Quote" CTA and a secondary "Acknowledge and Continue to Brakes" action.

## 2. Layout structure

Root `1:6035` is VERTICAL, width FIXED 390, height HUG 1326.75, fill `#FFFFFF`, padding 0.

| Order | Node | Geometry | Auto Layout / notes |
|---|---|---|---|
| 1 | Header `1:6036` | 390x64 | VERTICAL; inner `1:6037` HORIZONTAL pad 16/20/16/20, gap 91.87; same brand + "Verified" block as screen 1 |
| 2 | Main `1:6049` | 390x1262.75 | VERTICAL; padding 0/20/0/20 |
| 2.1 | Inner container `1:6050` | 350x1262.75 | VERTICAL; padding 0/0/40/0 |
| 2.1.1 | Title unit `1:6051` | 350x96 | VERTICAL, pad 16/0/24/0, gap 4 |
| 2.1.2 | Filter margin `1:6056` | 350x68 | VERTICAL, pad 0/0/24/0; filter bar 350x44 (no layout mode on children) |
| 2.1.3 | Main card `1:6068` | 350x692 | VERTICAL, radius 32, pad 24, gap 24, drop shadow |
| 2.1.4 | Evidence margin `1:6133` | 350x218.75 | VERTICAL, pad 24/0/0/0; card 350x194.75 |
| 2.1.5 | Action module margin `1:6149` | 350x148 | VERTICAL, pad 32/0/0/0; 350x116 VERTICAL gap 12 |

Filter bar: active "Tyres" `1:6058` 83.78x36 (HORIZONTAL, pad 10/20, gap 6, radius 9999, `#1A1B1F`, 2 px shadow) with a 6x6 `#FF7A73` dot; "Brakes" 81.22x36, "Suspension" 109.73x36, "Fluids" 75.55x36 (all `#F4F3F8`). Sum of widths + implicit spacing exceeds 350 px, so the right pill is clipped (visible in the PNG: "Fluids" is cut at the frame edge). No wrapping and no horizontal scroll container.

Main card section order: header (`1:6069`, 302x38) → axle diagram (`1:6081`, 302x256, pad 16/0/16/0) → callout margin (`1:6110`, 302x36) → mechanic notes (`1:6115`, 302x136, gap 8) → technical specs grid (`1:6120`, 302x82, pad top 8, gap 12).

Evidence card: heading row 302x22 → two-up photo row `1:6140` 302x108.75, gap 12.

Action module: primary 350x56 (`1:6151`, radius 9999, `#10B981`, shadow 25 @ 0,10) → secondary 350x48 text button.

No scroll container, no sticky elements. 390 px only; no desktop treatment.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx count)

| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 12 | Secondary text, inactive pills, captions |
| `#FFFFFF` | 12 | Cards, active pill text, tyre shapes |
| `#1A1B1F` | 8 | Headings, values, active pill |
| `#F4F3F8` | 6 | Inactive pills, icon circle, spec tiles |
| `#D1D5DB` | 5 | Tyre outlines |
| `#10B981` | 4 | Healthy tyre markers, CTA |
| `#E5E7EB` | 4 | Chassis/wheel geometry |
| `#6B7280` | 3 | FL/FR/RR labels |
| `#B91A24` | 3 | Defect dot, "1 Attention" text, RL tyre |
| `#BA1A1A` | 3 | RL tyre stroke/label, "PSI (Low)" |
| `#006C49` | 2 | Verified text, "3 Captures" (screen 3) |
| `#2F3034BF` | 2 | Photo chip scrim (75% ink) |
| `#3C4A42` | 2 | Secondary ink |
| `#EEEDF3` | 2 | Photo tile background |
| `#F1F0F5` | 2 | Photo chip text |
| `#FFDAD7` | 1 | "1 Attention" pill |
| `#FFDAD666` | 1 | Defect callout fill |
| `#93000A` | 1 | Defect callout text |
| `#FFF5F5` | 1 | RL tyre fill |
| `#BA1A1A40` | 1 | RL dashed ring |
| `#FF7A73` | 1 | Active filter dot |
| `#10B98133` / `#6FFBBE4D` | 1 / 1 | Header badge / Verified pill |
| `#FAFAFC` | 1 | Chassis fill |

### Typography (Plus Jakarta Sans)

| Node | Size / line-height / weight / tracking | Alignment | Usage |
|---|---|---|---|
| `1:6053` | 26/32, 800, -0.65 px | LEFT | "Inspection Findings" |
| `1:6055` | 14/20, 500, -0.07 px | LEFT | "Detailed mechanical and safety breakdown" |
| `1:6060` | 12/16, 600, +0.24 px | CENTER | "Tyres" (active) |
| `1:6063`, `1:6065`, `1:6067` | 12/16, 600, +0.24 px | CENTER | "Brakes", "Suspension", "Fluids" |
| `1:6076` | 18/24, 700, -0.27 px | LEFT | "Tyres" card title |
| `1:6078` | 11/14, 600, +0.44 px | LEFT | "Axle Assessment" |
| `1:6080` | 11/14, 700, -0.28 px | LEFT | "1 Attention" |
| `1:6092`, `1:6097`, `1:6103`, `1:6108` | 7.47 px, 700/800 | LEFT | FL / FR / RL / RR axle labels |
| `1:6114` | 12/16, 600, +0.24 px | LEFT | "Moderate Defect: Rear Left Tyre" |
| `1:6117` | 11/14, 600, +0.55 px | LEFT | "TECHNICIAN ASSESSMENT" |
| `1:6119` | 14/22.75, 500, -0.07 px | LEFT | 5-line tread note |
| `1:6123`, `1:6129` | 11/14, 600, +0.44 px | LEFT | "Cold Pressure", "Groove Depth" |
| `1:6125`, `1:6131` | 18/24, 700, -0.27 px | LEFT | "31.0", "2.4" |
| `1:6126` | 12/16, 700, +0.24 px | LEFT | "PSI (Low)" (`#B91A24`) |
| `1:6132` | 12/16, 600, +0.24 px | LEFT | "mm" |
| `1:6137` | 16/22, 700, -0.16 px | LEFT | "Captured Inspection Evidence" |
| `1:6139` | 11/14, 600, +0.44 px | LEFT | "2 Photos" |
| `1:6144`, `1:6148` | 11/14, 600, +0.44 px | LEFT | Photo chips |
| `1:6155` | 14/18, 700, -0.14 px | CENTER | "Request Tyre Replacement Quote" |
| `1:6158` | 12/16, 600, +0.24 px | CENTER | "Acknowledge and Continue to Brakes" |

### Radii, shadows/elevation, strokes, spacing

- Radii: `9999` x15; `32` x2 (main card, evidence card).
- Shadows: cards `DROP_SHADOW 8 @ 0,2` + `40 @ 0,14`; active pill `2 @ 0,1`; CTA `25 @ 0,10`.
- Strokes: tyre outlines 1.87 px `#D1D5DB`; RL tyre 2.33 px `#BA1A1A`; dashed defect ring 1.4 px `#BA1A1A40`; chassis 1.4–2.33 px `#E5E7EB`.
- Spacing: 4, 8, 10, 12, 16, 20, 24, 32, 40; inner card gap 24; spec tile gap 12; gutter 20.

## 4. Components

No `COMPONENT`/`INSTANCE` nodes (FRAME 70, TEXT 31, VECTOR 19, GROUP 4, RECTANGLE 2).

| Pattern | Node(s) | HTML/CSS equivalent |
|---|---|---|
| Filter chip row | `1:6057` | none (current report has no filters) |
| Category card | `1:6068` | `.item` / category `<table>`; not a card |
| Severity pill | `1:6079`, `1:6111` | `.badge.warning`/`.badge.danger` |
| Axle diagram | `1:6081` (4 groups) | no equivalent (SVG only) |
| Metric tile | `1:6121`, `1:6127` | none (table cells only) |
| Evidence thumbnails | `1:6140` | `.photos figure` |
| Full-width CTA | `1:6151` | `.button.primary` (not full width/pill) |
| Secondary text button | `1:6156` | none |

## 5. Assets

Manifest: 21 assets — 19 SVG (icons + tyre/geometry vectors), 2 raster, 0 composed.

| Asset | Node | Role | Size / bytes | Safe? |
|---|---|---|---|---|
| `Icon-1_6041.svg` | `1:6041` | Verified seal | 895 B | Same certification concern as screen 1 |
| `Icon-1_6073.svg` | `1:6073` | Tyre glyph | 3,219 B | Yes |
| `Vector-1_6083..6088`, `6090..6109` | diagram | Chassis/tyre/dot vectors | 191 B–1,913 B | Yes |
| `image-1-30f4a447ab.jpg` | `1:6142` | Evidence: depth gauge on tyre | 399x218, 12,405 B | Evidence derivative is allowed; verify no plate/face (none visible in PNG) |
| `image-2-48b6858055.jpg` | `1:6146` | Evidence: inner shoulder | 399x218, 9,536 B | Allowed derivative; no PII visible |
| `Icon-1_6153.svg` | `1:6153` | Wrench in CTA | 1,417 B | Yes |
| `Icon-1_6160.svg` | `1:6160` | Chevron | 231 B | Yes |

No avatar, no vehicle hero image on this screen. Both photos are close crops; the first may include a workshop reflection/legs but no face is identifiable in the PNG.

## 6. Content and data

| Visible text / label | Sample value | Real data field? | Notes |
|---|---|---|---|
| "Inspection Findings" | title | static | Fine |
| "Detailed mechanical and safety breakdown" | subtitle | static | Fine |
| "Tyres / Brakes / Suspension / Fluids" | filters | `category.labelEn/Ar` | Category names exist; filter wiring does not |
| "Tyres" / "Axle Assessment" | category + sub-label | category label exists; "Axle Assessment" does not | New copy/section label |
| "1 Attention" | count | computed from items (possible) | New aggregate, not in snapshot |
| "FL / FR / RL / RR" | positions | not in schema | New diagram data |
| "Moderate Defect: Rear Left Tyre" | defect title | `item.labelEn/Ar` + severity | Label exists; "Rear Left" is item text, severity code is `MODERATE` |
| Tread depth note ("2.4mm", "1,000 miles") | measurement | note text only | Measurements/recommendation must come from approved note; not a structured field |
| "Cold Pressure" / "31.0" / "PSI (Low)" | measurement | not in schema | Invented/typed value; "Low" is an assessment |
| "Groove Depth" / "2.4" / "mm" | measurement | not in schema | Invented/typed value |
| "Captured Inspection Evidence" / "2 Photos" | evidence | derivative count (possible) | Caption is allowed |
| "Depth Gauge" / "Inner Shoulder" | photo captions | no such captions in mapper (current: "Evidence") | New caption source |
| "Request Tyre Replacement Quote" | CTA | none | Commercial quote flow |
| "Acknowledge and Continue to Brakes" | CTA | none | Write/acknowledgement state |

No customer PII, no VIN/plate, no location, no token/hash.

## 7. States shown / not shown

Shown: one defect, active "Tyres" filter, 2 photos, "Moderate" severity, low-pressure state.

Not shown: no findings/passed categories, many defects (list overflow), no evidence, missing derivative, long note overflow, Arabic/RTL (mirrored diagram/order), filter results for Brakes/Suspension/Fluids, focus/hover/pressed, error/offline, page-level load, PDF state, invalid/revoked link.

## 8. Implied interactions

- Filter chips switch category content (client state or links).
- "Request Tyre Replacement Quote" starts a quote/booking flow.
- "Acknowledge and Continue to Brakes" records acknowledgement and advances to the next category.
- Evidence photos appear tappable (lightbox/zoom) though no overlay state is exported.
- "Verified" badge is static.

## 9. Correspondence to current product

| Figma element | Current implementation | Verdict |
|---|---|---|
| Category headings | `section#categories-title` `h3` per category + table | Current uses a table per category; Figma uses one card per defect |
| Item result/severity/note | `.badge` + `td` rows with result/severity/note/reason | Figma omits result and reason; keeps severity and a long note |
| Photo evidence | `.photos figure img` + figcaption "Evidence" | Exists; Figma adds captions and an evidence card |
| Axle diagram | none | New assets + new data (tyre position/state) |
| Measurement tiles | none | New structured measurement data |
| Filter chips | none | New client state (no JS allowed) |
| Request quote | none | Out of scope (no marketplace/payments/booking) |
| Acknowledge/continue | none | Out of scope (read-only, immutable) |
| Style | teal, 12 px radii, tables, no shadows | Emerald, 32 px cards, 7.47 px labels, heavy shadows |

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **No measurement model.** "31.0 / PSI (Low)", "2.4 / mm", "2.4mm" (`1:6125`, `1:6126`, `1:6131`, `1:6119`). Rule: "Never invent versions/licences/measurements/results" (task brief). `ReportSnapshot.ItemSnapshot` has `note` only; there is no pressure/groove-depth field. Shipping these requires a model/server change, which is forbidden in the UI layer.
2. **Commercial CTA.** "Request Tyre Replacement Quote" (`1:6151`). The product "must not hold payment or billing data" and is "not a ... booking page, payment page or marketplace" (`06-public-report-design.md` 1). This is a quote/marketplace cue and has no backend in the public report.
3. **Write action / portal cue.** "Acknowledge and Continue to Brakes" (`1:6158`), plus filters. Rule: "Finalized findings/evidence/reports immutable"; the public page is "read-only" (section 1) and "No admin code, no customer login, no other-report browsing" (hard rule 8). Acknowledgement/step navigation implies a customer portal.
4. **"1 Attention" aggregate and green healthy tyres.** `1:6079`, `1:6093/6098/6109`. Rule: "No false reassurance. Never use a green 'pass' badge that implies the vehicle is perfect"; green dots on three tyres imply those corners passed, which the item model does not state. Also "Severity is not a condition score. Do not sum severities into a single number" (`10-design-system.md` 2.3).
5. **Result labels not from the six codes.** "Moderate Defect" mixes severity (`MODERATE`) with a result noun; the allowed results are `NO_ISSUE_OBSERVED / ATTENTION_RECOMMENDED / DEFECT_FOUND / NOT_CHECKED / NOT_APPLICABLE / COULD_NOT_VERIFY` and severities are `Minor/Moderate/Major/Safety-critical` (`10-design-system.md` 3.3/3.4). "1 Attention" is not a localized result.
6. **Recommendation wording.** "Replacement recommended within 1,000 miles" (`1:6119`) is service advice/estimate; the allowlist permits "Recommendation | From the approved snapshot", so it can only be shown if it is snapshot text, not designed copy.
7. **Contrast/legibility.** 7.47 px FL/FR/RL/RR labels (`1:6092` etc.) are below any practical minimum and use colour + tiny text; `#10B981` on white (≈2.5:1) is used for meaningful state. Violates WCAG 2.2 AA intent.
8. **Horizontal clipping.** Filter row and clipping at 390 px (see screen PNG). Rule: "Zoom to 200% without horizontal scrolling for text"; "RTL ... Arabic first-class".
9. **Photo captions.** "Depth Gauge"/"Inner Shoulder" are not item labels; allowlist permits "Photo caption | Item link and safe caption; no customer data". If they are not generated from the item, they are new content.
10. **PDF.** Not shown here; no conflict.

## 11. Open questions / could not verify

- Are tyre pressure/tread values real fields intended for the public snapshot, or illustrative? If real, the modelling/API change is out of F0 scope.
- Is the "quote" CTA a link-out with consent, or an in-platform marketplace? The latter contradicts the product scope.
- Should the public page support filtering at all without JavaScript (server-side category anchors only)?
- What is the "Axle Assessment" label — template section name or free copy?
- Which tyre corners are actually inspected? The diagram asserts four positions; the item model has no position field.
- Is the third/next photo reachable (the evidence row shows 2 of 2 here, but screens 3 has 3)? No gallery scroll state is exported.
- Does "1 Attention" count defects, or items, or categories? Not defined.
- The 2.4 mm / 31 PSI values disagree with screen 6 (32.0 PSI Avg, 2.4 mm wear alert, 5.4 mm Avg on another card). Which dataset is canonical?
