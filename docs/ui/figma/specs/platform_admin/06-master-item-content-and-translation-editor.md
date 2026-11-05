# 06. 6. Master Item Content & Translation Editor

- App: Platform Admin
- Figma node: `1:4532`
- Frame: 1280x1544 px (desktop web)
- Export folder: `screens/06_6._Master_Item_Content_&_Translation_Editor`
- Sources read: `6._Master_Item_Content_&_Translation_Editor.json`, `6._Master_Item_Content_&_Translation_Editor@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: medium — the console rendering of the JSON garbles Arabic characters; the JSON itself contains Arabic codepoints, so Arabic wording is read from the PNG; RTL alignment is visually verified but semantic `dir`/language metadata is not in the export.

## 1. Purpose
Edit one master inspection item: metadata summary, side-by-side English/Arabic label and instruction, and guide-image upload/attachment. Intended for bilingual content authoring with RTL Arabic fields.

## 2. Layout structure
Root `1:4532` vertical, 1280x1544, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:4533` 1024x1544, padding 64/32/32/32.
- `Container` `1:4534` 960x1448, gap 32:
  - `Top Action / Context Row` `1:4535` 960x56: breadcrumb/title 562 + segmented “Dual Language View / Audit Version 4.1” 305x36.
  - `Quick Metadata Pill Strip` `1:4557` 960x104: four 228x104 cards (icon 40/41x44, label 11/600 uppercase, value 16/700).
  - `Dual Language Content Split` `1:4594` 960x534, gap 32:
    - Left English `1:4595` 464x534: header 464x24 (title, “Primary Source”, “EN-US”), card 464x486 radius 32 padding 32 gap 24: label field 400x76, instructions 400x230, helper pill 400x68.
    - Right Arabic `1:4629` 464x534: header 464x24, card 464x468 radius 32 padding 32/32/32/32, gap 24, padding-bottom 18: label 400x76, instructions 400x230, helper pill 400x50 with `paddingLeft: 52` (mirrored icon).
  - `Upload Guide Image Card` `1:4663` 960x490: header 960x24 + card 960x458 radius 32 padding 32: dropzone 896x280 (padding 48/24), preview strip 896x90 (288x90 tiles + 288x80 add tile), actions.
  - `Bottom Actions` `1:4720` 960x72: modified-by text + Cancel (118x56) + Save Changes (211x56).
- `Header` `1:4733` 1024x64 glass; `Aside` `1:4758` 256x800.

Long single page (1544 px); no sticky save bar is modelled. English and Arabic are fixed 464 px columns with 32 px gutter.

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 48 | Labels, help, meta |
| `#F4F3F8` | 21 | Field fills, helper pills, dropzone, tabs |
| `#FFFFFF` | 18 | Cards |
| `#1B1B25` | 15 | Headings/values |
| `#006C49` | 13 | Active specification, sync status, save icon? |
| `#10B981` | 6 | Save/CTA, camera badge |
| `#3C4A42` | 6 | Breadcrumb/meta |
| `#1A1B1F` | 3 | Chrome/search |
| `#EEEDF3` | 2 | Neutral fill |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans` (weights 400/500/600/700/800) plus one `FreeSerif` 600 glyph in the Arabic header. H1 32/800 LH38 -0.80; metadata values 16/700 LH22 (some 16/700/22 in `#006C49`); column titles 18/700 LH24; field values 16/700/22 and 16/500/22; Arabic body 16/500/22 right-aligned; Arabic label 14/700/18 right-aligned; labels 14/700; “Required” 11/600; meta 11/600 uppercase +0.44; helper text 13/400 LH18.
Alignment: English left; Arabic right (`RIGHT` text alignment); Arabic header uses `AR-SA (RTL)`.

### Radii, shadows, strokes, spacing
- Radii: content cards 32; dropzone 0/soft; buttons 9999; pills 9999; thumbnail tiles 0/16.
- Shadows: cards `0 14 40 .04` + `0 2 8 .02`; buttons `0 8 24 .24`/`0 4 12 .20`; small `0 2 8 .01`.
- Strokes: none.
- Spacing: page 64/32; section gap 32; card padding 32; column gap 32; field gap 24; label/instruction gap 4.

## 4. Components
Flattened export. Patterns: breadcrumb + version view switch, four KPI/metadata pills, two-column locale editor with a shared card, helper/info pill, drag-and-drop guide-image dropzone, attachment thumbnails, cancel + primary save.
Mapping: `AppTextField` (multiline support exists), `Dropdown` no, `SectionHeader`, `AppButton`, `StatusChip`; no locale-pair editor, dropzone, metadata pill strip, or attachment tile component. Current `ItemFormPage` is a single long form, not side-by-side.

## 5. Assets
28 assets, all individual SVG icons (no raster/composed/photo). Despite the UI, the two guide-image thumbnails (`caliper_alignment_v2.png`, `rotor_wear_tolerance.png`) are **not** present in the asset manifest; only icons are exported. They are mock content, not exportable assets.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Breadcrumb | MASTER LIBRARY / Checkpoint #042 / Active Specification | Partly (`stableCode`) | “Checkpoint #042” invented |
| Title | Edit Master Item: Brake Pad Thickness | Yes (`labelEn`) | Truncates “& Rotor Runout” |
| View switch | Dual Language View / Audit Version 4.1 | Partly (`versions`) | Conflates audit with version |
| Subsystem | Braking & Hydraulic | Partly (`category`) | Separate subsystem field absent |
| Measurement metric | Caliper (Millimeters) | No | Not modelled |
| OEM minimum threshold | 3.00 mm Standard | No | Invented measurement/standard |
| Sync status | Live across 18 Hubs | No | No hub/sync model |
| English label | Brake Pad Thickness & Rotor Runout | Yes (`translation.en.label`) | — |
| English instructions | “Measure inner and outer friction material using digital caliper. Flag if below 3.0mm OEM spec.” | Yes (`translation.en.instruction`) | OEM spec unsourced |
| English helper | “Displays on technician rugged tablets during Step 2 of Chassis Inspection.” | No | Device/step metadata absent |
| Arabic label | سمكة تيل الفرامل وانحراف القرص | Yes (`translation.ar.label`) | Right-aligned |
| Arabic instructions | قم بقياس مادة الاحتكاك الداخلية والخارجية باستخدام الفرجار الرقمي، يتم الإبلاغ إذا كانت القراءة أقل من 3.0 ملم وفقًا لمواصفات المصنع. | Yes (`translation.ar.instruction`) | RTL |
| Arabic helper | تعليمات الفحص | No | Generic helper, not item metadata |
| Locale tags | EN-US / AR-SA (RTL) | Partly | App locales are `en`/`ar` |
| Guide image | Upload Guide Image; “Drag diagnostic diagram … (PNG, JPG up to 10MB)”; “Vector / Micro-diagrams Accepted”; “Auto-rotated for In-shop Tablets” | Partly (`POST /master/guide-images`) | Upload exists; 10MB/auto-rotate/vector claims unverified |
| Attachment 1 | caliper_alignment_v2.png · 2.4 MB · Current Master | Partly (`guideImage`) | One guide image in model |
| Attachment 2 | rotor_wear_tolerance.png · 1.8 MB · Cross-Section | No | Multiple/secondary images not modelled |
| Add tile | + Add Secondary Angle | No | Not modelled |
| Footer | Last modified 14 minutes ago by Inspector Lead Vance | Partly (audit) | “Inspector Lead” role invented |
| Actions | Cancel, Save Changes | Partly | Current flow is Save draft / Publish |

No customer PII/VIN/plate/report findings. The content is inspection guidance, not a vehicle result.

## 7. States shown / not shown
Shown: populated EN/AR content, both locales, guide-image dropzone with two attachments, enabled save, “Dual Language View”. Not shown: empty locale, missing-Arabic warning, validation errors, character counts, unsaved-change warning, draft vs published diff, audit list, upload progress/error, file too large, RTL full-page layout (only fields are RTL), keyboard/focus, 200% text, mobile stacking.

## 8. Implied interactions
Switch between dual-language and audit/version view; edit label/instruction in both locales; drag/drop or browse guide images; remove attachment; add secondary angle; cancel; save. Header search and nav are also interactive.

## 9. Correspondence to current product
Partial. Existing: `item_form_page.dart` uses `ItemDetail`, `ItemVersion`, `Translation` and supports labels/instructions for `en`, `ar`, `ru`, `zh-Hans`, plus result options, note/evidence requirements, min photos, severity/applicability JSON, reasons, equipment, guide image, sample flag, version list; actions create draft/save/publish/retire. `admin_api.dart` and `ApiEndpoints` provide `/master/items/{id}`, `/versions`, `/translations/{locale}`, `/rules`, `/publish`, `/retire`; `MasterContentController` implements them. The Figma EN/AR side-by-side layout, metadata pill strip, OEM/measurement fields, sync status, and multi-image dropzone are new. The current form writes a draft; the Figma “Save Changes” implies editing the current version in place, which conflicts with the versioning model.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “Never invent versions/licences/measurements/results.” Evidence: “3.00 mm Standard” (`1:4584`), “Caliper (Millimeters)”, “OEM minimum threshold”, “18 Hubs”, “2.4 MB/1.8 MB”, and “Audit Version 4.1” are invented values.
- Rule: “Finalized findings/evidence/reports immutable; versioning.” Evidence: “Save Changes” (`1:4732`) and “Audit Version 4.1” imply in-place edits; ADR-0014 requires a new draft version and an append-only published version. The editor must not offer a single “save” that overwrites published content.
- Rule: “no certification/‘verified by’/compliance claims.” Evidence: “3.0mm OEM spec” is presented as an authoritative OEM threshold with no source; “Current Master” implies canonical authority.
- Rule: “Arabic RTL must work.” Evidence: Arabic fields are right-aligned and the helper icon is mirrored, but the page/heading and the helper copy are not shown in a full RTL layout; “Auto-rotated” is a visual claim, not RTL behaviour. RTL is not “auto-reversing layout coordinates”; phase-1 requires logical order and mirrored layout, not reversed semantics.
- Rule: “no business logic/API/model/server change.” Evidence: subsystem/measurement/OEM minimum/sync status/secondary-angle images have no model or endpoint.
- Rule: “colours/text/radii/spacing from central tokens.” Evidence: 32 px card radii, lavender `#F4F3F8`, `#10B981`, `#006C49`, `FreeSerif` and Plus Jakarta Sans are not in the current token set; `AppTextField` currently uses a tonal filled field, not these white fields.
- Rule: “Never invent licences.” Evidence: guide-image upload claims “Vector / Micro-diagrams Accepted” and “Auto-rotated” without a licence/alt-text step; the current flow requires alt text and a licence note, which this frame omits.

## 11. Open questions / could not verify
- Does “Save Changes” update the draft, publish a new version, or overwrite the current one? The product requires draft/publish separation.
- Are “Subsystem”, “Measurement metric”, “OEM minimum threshold”, and “Sync status” planned fields? None exist in `ItemVersion`.
- Should RU/ZH fields (present in code) be exposed? The Figma shows only EN/AR.
- Is the second guide image allowed by the model (`guideImageId` is singular)?
- What is “Audit Version 4.1” — version history or an audit event view?
- The Arabic strings are visually legible; the JSON contains Arabic codepoints, but exact wording/tashkeel were not native-reviewed. Confirm with a native speaker.
- No error/loading/unsaved/RTL-page states.
