# 3. Exterior Condition & Evidence (Mobile Web)

- App: Public Report
- Figma node: 1:6161
- Frame: 390x939.375 px (mobile)
- Export folder: `screens/03_3._Exterior_Condition_&_Evidence_(Mobile_Web)`
- Sources read: `3._Exterior_Condition_&_Evidence_(Mobile_Web).json`, `3._Exterior_Condition_&_Evidence_(Mobile_Web)@2x.png`, `assets/manifest.json`
- Confidence: high for layout/tokens; medium for the third-photo behaviour (the row is wider than its parent and is clipped in the PNG).

## 1. Purpose

Mobile exterior-condition detail: a generic vehicle side-profile schematic with a single damage pin, a photographic evidence strip (3 captures), a defect description with a severity chip, two attribute tiles (severity level and remediation) and an "Acknowledge & Validate Defect" action.

## 2. Layout structure

Root `1:6161` VERTICAL, width FIXED 390, height HUG 939.38, fill `#FFFFFF`.

| Order | Node | Geometry | Auto Layout / notes |
|---|---|---|---|
| 1 | Header `1:6162` | 390x64 | VERTICAL; inner `1:6163` HORIZONTAL pad 16/20/16/20, gap 91.87 |
| 2 | Main `1:6175` | 390x875.38 | VERTICAL, padding 0/20/0/20 |
| 2.1 | Inner `1:6176` | 350x875.38 | VERTICAL, padding 0/0/40/0 |
| 2.1.1 | Title margin `1:6177` | 350x84 | VERTICAL, pad 4/0/24/0; title block 350x56 |
| 2.1.2 | Primary card `1:6184` | 350x751.38 | VERTICAL, radius 32, pad 24, gap 24, drop shadow |
| 2.1.2.1 | Vehicle schematic `1:6185` | 302x176 | HORIZONTAL, radius 48, fill `#F4F3F899`, pad 0/16 |
| 2.1.2.2 | Defect visual log `1:6205` | 302x190 | VERTICAL, gap 12 |
| 2.1.2.3 | Description `1:6228` | 302x85.38 | VERTICAL, pad 8/0/0/0, gap 7.38 |
| 2.1.2.4 | Attributes `1:6236` | 302x92 | HORIZONTAL, pad 8/0/0/0, gap 12 |
| 2.1.2.5 | Action margin `1:6249` | 302x64 | VERTICAL, pad 8/0/0/0; button 302x56 |

Schematic: composed SVG `1:6186` 270x128 (FILL, grow 1) inside 302x176; pin `1:6199` 28x28 with 32x32 halo `1:6200` (`#10B98140`) and 28x28 solid `#10B981` core with 10x10 white centre; glass label `1:6203` 130.08x32, radius 9999, fill `#FFFFFFE5`, `DROP_SHADOW 8 @ 0,2` + `BACKGROUND_BLUR 8`.

Evidence strip: header row `1:6206` 302x16; body margin `1:6211` 302x162 contains a fixed child `1:6212` **318 px wide** inside a 302 px parent, i.e. 16 px of horizontal overflow. Three 176x150 cards (`1:6213`, `1:6218`, `1:6223`) with 176x128 image frames at radius 48, gap 8 to a caption. The PNG shows only two cards; the third is clipped. This implies a horizontal scroller/carousel with no visible affordance.

Attributes: two 145x84 tiles, radius 48, fill `#F4F3F8B2`, label 11/14 on top of a two-line 16/22 value.

No sticky header, no syntax for responsive widths; 390 px only.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx count)

| Hex | Count | Usage |
|---|---|---|
| `#C7C5D3` | 12 | Car schematic strokes |
| `#5E5D69` | 9 | Body/labels/captions |
| `#FFFFFF` | 7 | Card, pin core, chips |
| `#1A1B1F` | 5 | Titles/values |
| `#006C49` | 3 | "3 Captures", trusted green |
| `#F4F3F8` | 3 | Attribute tile base |
| `#10B981` | 2 | Pin, CTA |
| `#F4F3F8B2` | 2 | Attribute tiles |
| `#10B98133` | 1 | Header badge |
| `#10B98140` | 1 | Pin halo |
| `#3C4A42` | 1 | Secondary ink |
| `#6FFBBE4D` | 1 | Verified pill |
| `#92400E` | 1 | "Minor Scratch" text |
| `#F4F3F899` | 1 | Schematic background |
| `#FEF3C7B2` | 1 | "Minor Scratch" pill |
| `#FFFFFFE5` | 1 | Glass label |

### Typography (Plus Jakarta Sans)

| Node | Size / line-height / weight / tracking | Alignment | Usage |
|---|---|---|---|
| `1:6180` | 26/32, 800, -0.65 px | LEFT | "Exterior Condition" |
| `1:6183` | 14/20, 500, -0.07 px | LEFT | "Optical scan and surface defect log" |
| `1:6204` | 11/14, 600, +0.55 px | LEFT | "LATERAL EXTERIOR" |
| `1:6208` | 12/16, 600, +0.6 px | LEFT | "PHOTOGRAPHIC EVIDENCE" |
| `1:6210` | 11/14, 700, +0.44 px | LEFT | "3 Captures" |
| `1:6217`, `1:6222`, `1:6227` | 11/14, 600, +0.44 px | LEFT | Photo captions |
| `1:6231` | 18/24, 700, -0.27 px | LEFT | "Front Left Door" |
| `1:6233` | 12/16, 600, +0.24 px | LEFT | "Minor Scratch" |
| `1:6235` | 14/22.75, 500, -0.07 px | LEFT | 2-line defect description |
| `1:6239`, `1:6245` | 11/14, 600, +0.44 px | LEFT | "Estimated Severity", "Remediation" |
| `1:6242`, `1:6248` | 16/22, 700, -0.16 px | LEFT | "Level 1 (Cosmetic)", "Rotary Polishing" |
| `1:6254` | 14/18, 700, -0.14 px | CENTER | "Acknowledge & Validate Defect" |

### Radii, shadows/elevation, strokes, spacing

- Radii: `9999` x8; **`48` x6** (schematic viewport, 3 photo frames, 2 attribute tiles); `32` x1 (card).
- Shadows: card `8 @ 0,2` + `40 @ 0,14`; photo frames `14 @ 0,4`; pin `24 @ 0,8`; glass label `8 @ 0,2` + blur 8; CTA `25 @ 0,10`.
- Strokes: schematic `#C7C5D3` at 0.88–1.47 px; no card borders.
- Spacing: 2, 4, 7.38, 7.5, 8, 10, 10.5, 12, 16, 20, 24, 40; card gap 24; gutter 20.

## 4. Components

No `COMPONENT`/`INSTANCE` nodes (FRAME 59, TEXT 19, VECTOR 14, RECTANGLE 2).

| Pattern | Node(s) | HTML/CSS equivalent |
|---|---|---|
| Damage-pin schematic | `1:6185` | none; new generic SVG + absolute pin |
| Photo card with caption | `1:6213` | `.photos figure` + figcaption (current is 120 px high, radius 8) |
| Severity chip | `1:6232` | `.badge.warning` (colour differs) |
| Attribute tile | `1:6237`, `1:6243` | none |
| Full-width CTA | `1:6250` | `.button.primary` (not full width/pill) |
| Portal header | `1:6162` | `header.report-header` (different content) |

## 5. Assets

Manifest: 18 assets — 14 SVG icons/vectors, 1 composed SVG, 3 raster.

| Asset | Node | Role | Size / bytes | Safe? |
|---|---|---|---|---|
| `Icon-1_6167.svg` | `1:6167` | Verified seal | 895 B | Certification concern |
| `Vector-1_6187..6198` | schematic | Car outline/glass/wheels | 215–2,567 B | Yes (generic vehicle) |
| `SVG_-_Minimalist_2D_Vector_Car_Profile-1_6186.svg` | `1:6186` | Composed car profile | 2,567 B | Yes |
| `image-1-7c45b77732.jpg` | `1:6215` | Evidence: macro scratch | 470x256, 3,251 B | Allowed derivative; no plate/face in PNG |
| `image-2-074ad6c830.jpg` | `1:6220` | Evidence: door handle | 352x263, 7,072 B | Allowed derivative; no plate/face; handle may identify model |
| `image-3-b97c8c4381.jpg` | `1:6225` | Evidence: depth gauge | 470x256, 9,640 B | Allowed derivative; clipped/third item |
| `Icon-1_6252.svg` | `1:6252` | Check in CTA | 236 B | Yes |

No avatar, no hero vehicle photo.

## 6. Content and data

| Visible text / label | Sample value | Real data field? | Notes |
|---|---|---|---|
| "Exterior Condition" | title | static/category label | Fine |
| "Optical scan and surface defect log" | subtitle | no | "Optical scan" overstates the visual inspection method |
| "LATERAL EXTERIOR" | view label | no | New view vocabulary |
| "PHOTOGRAPHIC EVIDENCE" / "3 Captures" | gallery | photos count (possible) | Caption allowed |
| "Macro Surface Detail" / "Handle Orientation" / "Depth Calibration" | captions | no | New caption source, not item labels |
| "Front Left Door" | area | item label/reason text only | No structured area field |
| "Minor Scratch" | defect type | severity `MINOR` exists; "Scratch" does not | New taxonomy |
| "Surface clear-coat abrasion (approx 42mm). Primer unbreached; no bare metal exposed." | note | `item.note` (free text) | Only if snapshot text; "42mm" is a measurement |
| "Estimated Severity" / "Level 1 (Cosmetic)" | grade | `severityCode` gives Minor/Moderate/Major/Safety-critical | "Level 1" is an invented 1–N grade |
| "Remediation" / "Rotary Polishing" | action | recommendation (allowed if in snapshot) | New structured field otherwise |
| "Acknowledge & Validate Defect" | CTA | none | Write action |

No customer PII, no VIN/plate, no precise location (no coordinates), no token/hash.

## 7. States shown / not shown

Shown: single cosmetic defect, 3 captures (2 visible), severity chip, remediation, CTA.

Not shown: multiple defects, no photos, missing derivative, long description, no defect state, Arabic/RTL (the car profile and pin would need mirroring decisions), photo lightbox/zoom, carousel third-card state, hover/focus, error/offline, invalid/revoked link, PDF.

## 8. Implied interactions

- Horizontal swipe/scroll for the 3-photo strip (clipped, no scrollbar/peek).
- Evidence photos likely zoomable (lightbox), not exported.
- "Acknowledge & Validate Defect" records a customer acknowledgement and validates the defect.
- "Verified" badge is static.
- Schematic pin may be tappable (no target state).

## 9. Correspondence to current product

| Figma element | Current implementation | Verdict |
|---|---|---|
| Exterior section | category table rows with result/severity/note/reason | Figma turns one defect into a hero card |
| Severity | `.badge.warning` with localized `severity` | Figma uses "Minor Scratch" / "Level 1 (Cosmetic)" taxonomy |
| Note | `.note` block (pre-wrap, border accent) | Figma plain text under a label |
| Photos | `.photos` grid, 120 px high, radius 8, caption "Evidence" | Exists; Figma adds 48 px radius, captions, fixed 176x128 |
| Vehicle schematic | none | New generic SVG + pin + view label |
| Attribute tiles | none | New fields (level/remediation) |
| Acknowledgement CTA | none | Out of scope |
| Styling | teal, 8/12 px radii, no shadow | emerald, 32/48 px radii, ambient shadows |

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **Write action.** "Acknowledge & Validate Defect" (`1:6250`). Public report is read-only (hard rule 1/8; "Finalized findings/evidence/reports immutable"). Validation is an internal action, not a public one.
2. **Invented measurement.** "Surface clear-coat abrasion (approx 42mm)" (`1:6235`). Rule: "Never invent ... measurements/results"; only `item.note` is available, so the 42 mm must be exact approved note text.
3. **Invented severity scale.** "Level 1 (Cosmetic)" (`1:6242`) and "Minor Scratch" (`1:6233`). The approved taxonomy is `Minor/Moderate/Major/Safety-critical` (`10-design-system.md` 2.3/3.4). A "Level 1" grade is a new score-like scale and could read as a condition grade, contradicting "Coverage, not a single condition score."
4. **Remediation as structured field.** "Remediation: Rotary Polishing" (`1:6248`). Allowlist permits "Recommendation | From the approved snapshot"; there is no structured remediation field in `ReportSnapshot.ItemSnapshot`, so this needs new data/server work if it is not note text.
5. **Certification/verification header.** "Certified Inspection Report" + "Verified" (`1:6172`, `1:6174`) repeat the claim conflict (see screen 1).
6. **"Optical scan" claim.** `1:6183`. The inspection is "visual and non-invasive" and "components are not dismantled"; "optical scan"/"depth calibration" implies a metrology system that the product does not claim.
7. **Photo safety.** Evidence derivatives are allowed, but the door-handle and macro shots can identify a vehicle/model; verify no plate, VIN plate, face or address. `06-public-report-design.md` 9 requires crop/blur or omission unless approved.
8. **Contrast/colour-only state.** The severity chip uses amber text `#92400E` on `#FEF3C7B2`; `Minor` in the token system should be neutral (`#5B6570` on `#EEF1F3`). Colour plus text is present, so not colour-only, but it is a token violation.
9. **Clipped content.** Third capture is outside the 302 px parent (318 px child) with no visible affordance. Rule: "Zoom to 200% without horizontal scrolling"; no-JS/keyboard users cannot reach the hidden card.
10. **PDF.** Not shown; no conflict.

## 11. Open questions / could not verify

- Are "Level 1 (Cosmetic)" and "Minor Scratch" the intended public vocabulary, or should this map to `MINOR` + item label?
- Is "Rotary Polishing" an approved recommendation from the snapshot?
- Is the evidence carousel intended to scroll, or was the third card meant to be a 3-across grid?
- Does the public report need a damage-pin schematic at all, given "no precise location" (a generic profile is not precise, but implies mapping)?
- Is the door-handle photo safe to publish (model identification)?
- Why is there no language switch or report ID on this mobile screen?
- The card height 751.38 implies exact text wrapping; what happens with longer translated Arabic notes? No RTL variant is supplied.
