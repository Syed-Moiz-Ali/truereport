# 1. Customer Summary Hero (Mobile Web)

- App: Public Report
- Figma node: 1:5938
- Frame: 390x1016 px (mobile)
- Export folder: `screens/01_1._Customer_Summary_Hero_(Mobile_Web)`
- Sources read: `1._Customer_Summary_Hero_(Mobile_Web).json`, `1._Customer_Summary_Hero_(Mobile_Web)@2x.png`, `assets/manifest.json`
- Confidence: high — all layout/token values are read from measured nodes; one inference (hero raster is a stock vehicle photo, not customer evidence) is marked below.

## 1. Purpose

Mobile cover/summary screen for a public inspection report. It presents workshop identity, report type, inspection timestamp, a hero vehicle image, vehicle profile (model, plate, odometer), a coverage card, a "Mechanical Health" row and a primary "View Detailed Checkpoints" button.

The screen is one 390 px column with no browser chrome, no breakpoints and no scroll container; the frame is HUG vertically (390x1016).

## 2. Layout structure

Root `1:5938` is VERTICAL, width FIXED 390, height HUG 1016, fill `#FFFFFF`, padding 0.

| Order | Node | Geometry | Auto Layout / notes |
|---|---|---|---|
| 1 | Header `1:5939` | 390x64 | VERTICAL; inner `1:5940` HORIZONTAL, padding 16/20/16/20, gap 91.87 |
| 2 | Main `1:5952` | 390x952 | VERTICAL; padding 0/20/0/20; inner container `1:5953` 350 wide, 952 high |
| 2.1 | Partner strip `1:5954` | 350x48 | VERTICAL, padding 0/0/16/0; row `1:5955` 350x32 HORIZONTAL, padding 8/0/8/0, gap 4 |
| 2.2 | Title block `1:5959` | 350x96 | VERTICAL, padding 16/0/24/0; H1 `1:5961` 217.92x32 (HUG); date row `1:5962` padding 4/0/0/0 |
| 2.3 | Hero media `1:5965` | 350x212 | VERTICAL, padding 16/0/16/0; inner `1:5966` 350x180; row `1:5967` fixed 320x180 |
| 2.4 | Cards stack `1:5970` | 350x556 | VERTICAL, gap 24 |
| 2.4.1 | Vehicle profile card `1:5971` | 350x178 | VERTICAL, radius 32, padding 24, gap 16 |
| 2.4.2 | Status scope card `1:5995` | 350x146 | VERTICAL, radius 32, padding 24, gap 16 |
| 2.4.3 | Mechanical health row `1:6015` | 350x96 | HORIZONTAL, radius 32, padding 24, gap 38.85 |
| 2.5 | CTA margin `1:6028` | 350x64 | VERTICAL, padding 8/0/0/0; button 350x56, radius 9999 |

Hero media detail: `1:5966` contains a fixed 320x180 row (`1:5967`) with a 240x16 decorative rectangle (`1:5968`, radius 9999, fill `#1A1B1F0D`, `LAYER_BLUR` 24) layered over the raster frame `1:5969` (320x180, FILL/FILL, grow 1). The image is cropped by the 320x180 frame, not by a CSS border radius (no radius on `1:5969`).

Scroll: none inside the frame; the page would scroll as one document. No sticky/fixed elements. No responsive rules are expressed — 390 px is the only width.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx count)

| Hex | Count | Usage (observed) |
|---|---|---|
| `#5E5D69` | 11 | Secondary text, eyebrow labels, chevron |
| `#FFFFFF` | 8 | Cards, header, button text |
| `#1A1B1F` | 7 | Primary text, ink |
| `#10B981` | 5 | Brand/progress/dot/CTA |
| `#FFFFFF01` | 4 | Shadow carrier fills (near-transparent white) |
| `#006C49` | 3 | Icon foreground on mint tint, "Verified" text |
| `#F4F3F8B2` | 2 | Plate/odometer tiles (70% lavender) |
| `#10B98133` | 1 | 32 px header badge circle (20% emerald) |
| `#1A1B1F0D` | 1 | 5% ink blur bar over hero |
| `#3C4A42` | 1 | Brand sub-label |
| `#6FFBBE4D` | 1 | "Verified" pill fill |
| `#6FFBBE66` | 1 | 48 px mechanical icon circle |
| `#E9E7ED` | 1 | Progress track |
| `#F4F3F8` | 1 | Vehicle icon circle |

### Typography (Plus Jakarta Sans throughout)

| Node | Size / line-height / weight / tracking | Alignment | Usage |
|---|---|---|---|
| `1:5947` | 12/16, 600, +0.6 px | LEFT | "APEX AUTO CARE" (uppercase) |
| `1:5949` | 11/14, 600, +0.44 px | LEFT | "Certified Inspection Report" |
| `1:5951` | 11/14, 700, +0.44 px | LEFT | "Verified" pill |
| `1:5958` | 12/16, 600, +0.3 px | LEFT | "APEX FLEET HUB PARTNER" |
| `1:5961` | 26/32, 800, -0.65 px | CENTER | "Inspection Report" |
| `1:5964` | 14/20, 500, -0.07 px | CENTER | "October 24, 2024 • 14:32 EST" |
| `1:5976`, `1:6000` | 11/14, 600, +0.55 px | LEFT | "VEHICLE PROFILE", "STATUS SCOPE" |
| `1:5978`, `1:6002` | 18/24, 700, -0.27 px | LEFT | "Renault Megan 3", "Coverage" |
| `1:5985`, `1:5991` | 11/14, 600, +0.44 px | LEFT | "License Plate", "Odometer" |
| `1:5988`, `1:5994` | 16/22, 700 (plate +0.4 px, odometer -0.16 px) | LEFT | "LV71 XZP", "34,180 mi" |
| `1:6004` | 18/24, 700, -0.27 px | LEFT | "95%" (`#10B981`) |
| `1:6012` | 13/18, 400 | LEFT | "104 of 110 Checks Completed" |
| `1:6014` | 11/14, 600, +0.44 px | LEFT | "6 Remaining" |
| `1:6023` | 16/22, 700, -0.16 px | LEFT | "Mechanical Health" |
| `1:6025` | 13/18, 400 | LEFT | "Zero Critical Faults Detected" |
| `1:6032` | 14/18, 700, -0.14 px | CENTER | "View Detailed Checkpoints" |

### Radii, shadows/elevation, strokes, spacing

- Radii: `9999` x10 (badge, pills, progress, icon circles, button); `32` x6 (all three cards, radius 32).
- Shadows: cards `1:5972`, `1:5996`, `1:6016` = `DROP_SHADOW 10 @ 0,8` + `DROP_SHADOW 25 @ 0,20` on transparent `#FFFFFF01` carriers; button shadow `1:6030` = `10 @ 0,8` + `25 @ 0,20`; hero uses `LAYER_BLUR` 24 on a 240x16 5% ink bar.
- Strokes: none in this screen.
- Spacing: 2, 4, 8, 16, 20, 24 px; screen gutter 20 px (not the 16 px `bp.phone` token); card padding 24; card gap 24; label→value 4; two-column tile gap 16.
- Off-grid values: 91.87 header gap, 38.85, 122.56, 174.2, 30.59 (fixed gaps produced by Figma constraints; should become `space-between`/`gap` in CSS, not literal).

## 4. Components

No `COMPONENT`/`INSTANCE` nodes are present in the export (node types: FRAME 64, TEXT 20, RECTANGLE 7, VECTOR 6). The following are pattern-level components:

| Pattern | Node(s) | HTML/CSS equivalent |
|---|---|---|
| Report header (brand + badge) | `1:5939` | `header.report-header` + `.brand`; **no** "Certified"/"Verified" equivalent |
| Pill badge | `1:5950` | `.badge` (but semantic "verified" has no equivalent) |
| Stat card | `1:5971`, `1:5995`, `1:6015` | `.card`; `.stat` exists in `report.css` |
| Progress bar | `1:6005`/`1:6006` | none (no progress component) |
| Full-width pill CTA | `1:6029` | `.button.primary` but not full width/pill |
| Two-up info tile | `1:5983`, `1:5989` | none (vehicle fields are a grid, not tiles) |

## 5. Assets

Manifest: 7 assets (6 SVG icons, 1 raster, 0 composed).

| Asset | Node | Role | Size / bytes | Safe to publish? |
|---|---|---|---|---|
| `Icon-1_5944.svg` | `1:5944` | "verified seal with check" (16.5x15.75, `#006C49`) | 895 B | Shape is a certification seal; using it for a public report implies verification. |
| `image-1-0c99e38fa3.jpg` | `1:5969` | Raster vehicle photo | 512x279, 20,849 B | **No** — stock/generic vehicle photo, not evidence; licence unknown; also implies vehicle identity and does not match stated model. |
| `Icon-1_5981.svg` | `1:5981` | Car glyph | 1,682 B | Yes (generic). |
| `Icon-1_6010.svg` | `1:6010` | Check-circle | 1,377 B | Yes, but reads as "pass". |
| `Icon-1_6020.svg` | `1:6020` | Shield + check | 614 B | Yes as icon; the shield reinforces a "verified" claim. |
| `Icon-1_6027.svg` | `1:6027` | Chevron | 227 B | Yes. |
| `Icon-1_6034.svg` | `1:6034` | Arrow-right | 248 B | Yes. |

No avatar, no logo raster, no composed SVG.

## 6. Content and data

| Visible text / label | Sample value | Real data field? | Notes |
|---|---|---|---|
| "APEX AUTO CARE" | brand | Workshop name (allowlisted) | Conflicts with desktop brand "Apex Precision Labs"; see open questions. |
| "Certified Inspection Report" | status line | No | Certification wording; see conflicts. |
| "Verified" | badge | No | Claim/state with no public field. |
| "APEX FLEET HUB PARTNER" | programme | No | Partner/endorsement claim; not in `ReportSnapshot`. |
| "Inspection Report" | title | Static label (`labels.title` equivalent) | Fine (neutral title). |
| "October 24, 2024 • 14:32 EST" | date/time | `inspection.dateTime` | Wrong zone for this product: report uses GST/UTC+4; "EST" is invented. |
| "VEHICLE PROFILE" | section label | Static | Fine. |
| "Renault Megan 3" | make + model | `vehicle.make` + `vehicle.model` | Allowed. |
| "License Plate" / "LV71 XZP" | plate | **No** (`vehicle` has `vinMasked`, no plate) | Hard-rule violation; no field. |
| "Odometer" / "34,180 mi" | odometer | `vehicle.odometerValue/Unit` (Pending) | Unit is miles; product displays km; odometer itself is Pending approval. |
| "STATUS SCOPE" / "Coverage" / "95%" | coverage | `coverage.completed/applicable` (computed 95%) | Percentage + progress bar; no “not a condition score” note. |
| "104 of 110 Checks Completed" | counts | `coverage.completed` + `coverage.applicable` | Matches current model. |
| "6 Remaining" | remainder | `coverage.notChecked` + `couldNotVerify` | Current model reports these separately. |
| "Mechanical Health" / "Zero Critical Faults Detected" | summary | `keyFindings` (rule-based) | Absolute reassurance; not directly a field. |
| "View Detailed Checkpoints" | CTA | No | Implies interaction/portal. |

No customer name/phone/email, no full VIN, no precise location, no server/API detail.

## 7. States shown / not shown

Shown: default (English, active public link, data present), "Verified" positive state, 95% coverage.

Not shown: Arabic/RTL, empty key findings, no photos, missing vehicle image/derivative, PDF enabled/disabled, invalid/revoked/consent-missing, rate-limited, offline/slow connection, error, loading, focus/hover/pressed, 200% text zoom, dark mode (DESIGN.md says light-only).

## 8. Implied interactions

- "View Detailed Checkpoints" button → in-page anchor or navigation to findings. No destination state exported.
- Mechanical health row has a chevron → tappable drill-down. Not a link in a read-only public page unless it is a same-page anchor.
- No language switch on this screen (the only language control is on screen 4).
- Header "Verified" is static; no tooltip/definition.

## 9. Correspondence to current product

| Figma element | Current implementation | Verdict |
|---|---|---|
| Header brand/report type | `public-report.html` `header.report-header` with "TrueReport", `h1` = neutral title, report number + version | Current header is neutral and has no certification badge; Figma adds brand claims. |
| Report ID/version | Current shows `r.reportNumber` and `version` in header | Figma omits report ID/version from this screen; would lose required identity. |
| Coverage card | `section[aria-labelledby=summary-title]` + `.summary-grid` `.card` `.stat` with `coverage.text`, "checks completed", "Coverage is not a condition score." | Concept matches; Figma replaces text with 95% + progress and drops the disclaimer. |
| Vehicle card | `#vehicle-title` `.card.detail-grid`: make/model/year, masked VIN, odometer (conditional), workshop, branch, technician, template | Figma shows model/plate/odometer only; no workshop/technician/scope; adds plate. |
| Mechanical health row | `.item` key-finding cards + `.badge` | No one-line health summary; "Zero Critical Faults" is new copy. |
| Evidence photos | `.photos` figure/img only inside items/categories | Hero vehicle image has no equivalent (snapshot carries evidence IDs only). |
| CTA | none | New UI/state, not read-only. |
| Styling | `report.css`: teal `#0b3b4a/#0f6b6f`, Noto fonts, radius 4/8/12/16, light+dark | Figma: emerald `#10B981/#006C49`, Plus Jakarta Sans, radius 32/9999, light only. Central tokens differ. |

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **Plate shown.** `1:5988` renders "LV71 XZP". Rule: "No customer name, phone, email, precise location, full VIN, plate, registration or engine number by default" (`06-public-report-design.md` hard rule 4) and "Full VIN, plate, registration, engine number" under **Never public** (3.2). No plate exists in `ReportSnapshot`.
2. **Vehicle photo.** `1:5969` is a 320x180 stock vehicle image. Rule: only "Evidence photo derivative" is public, and "If a preview image is used, it must be a generic brand image, never vehicle evidence" (section 6). A generic stock car presented under a specific vehicle profile is misleading; licence is unknown.
3. **Certification claims.** "Certified Inspection Report" (`1:5949`), "Verified" (`1:5951`), seal icon (`1:5944`), "APEX FLEET HUB PARTNER" (`1:5958`). Rule: "Do not use 'certified', 'independently reviewed', 'manager approved' or 'RTA approved' unless factually and legally true" (section 12); "Never claim 'certified', 'official'..." (`10-design-system.md` 6). There is no public approval record for these claims.
4. **Unexplained 95% + progress bar.** `1:6004` + `1:6005`/`1:6006`. Rule: "No single unexplained score. Explain coverage" (2.2 Summary); "Coverage, not a single condition score" (12); "Do not show a headline '8.8/10' or similar score" (12). Current product deliberately prints "Coverage is not a condition score."
5. **"Zero Critical Faults Detected".** `1:6025`. Rule: "No false reassurance. Never use a green 'pass' badge that implies the vehicle is perfect" (`10-design-system.md` 1); "a clean result does not mean the vehicle is perfect" (Limitations). A "zero faults" headline is a stronger claim than the approved coverage summary.
6. **Timezone invented.** "EST" (`1:5964`). Rule: "Inspection date/time | Include time zone (GST/UTC+4)" (3.1); localization says stable report format. EST is not this product's zone.
7. **Odometer unit/approval.** "34,180 mi". Rule: "Odometer value + unit — Pending: include only if the product owner approves; otherwise omit" (3.1). Units should match the snapshot (km for UAE).
8. **Interactive CTA / chevron.** `1:6029`, `1:6026`. The product is a read-only server-rendered page with no portal and no JS. A button that implies a portal is out of scope; an in-page anchor is the maximum allowed.
9. **Green pass semantics.** `#10B981` check-circle (`1:6010`) and "Verified" mint pill follow the forbidden green "pass" pattern (`10-design-system.md` 3.3: `NO_ISSUE_OBSERVED` must never be labelled "Pass/Perfect/Certified").
10. **Token existence / link state.** None of the visible content reveals the token. No conflict here.
11. **PDF download.** Not present on this screen. No conflict.

## 11. Open questions / could not verify

- Is this screen intended for the **public** report or an authenticated report viewer? The badge/CTA pattern is closer to the Workshop Admin viewer.
- Which brand is authoritative: "APEX AUTO CARE" (mobile) or "Apex Precision Labs / Apex Vehicle Diagnostic Systems" (desktop)?
- Is "APEX FLEET HUB PARTNER" a real partner programme with an approved logo/claim?
- Is the hero raster an approved generic brand image? Who owns the licence? Why does it not match "Renault Megan 3"?
- Should the public report show odometer at all, and in km or mi? Product owner sign-off is Pending.
- Should a coverage percentage be shown at all, or only "104 of 110"?
- Which accessibility contour applies: the 11 px labels and 13 px body are below the `type.label 13/18`, `type.body 16/22` (or 15/22) scale in `10-design-system.md`.
- The hero blur bar (`1:5968`) has no visible purpose in the PNG; is it a loading/glass effect or noise?
