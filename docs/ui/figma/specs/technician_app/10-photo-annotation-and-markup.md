# 10. 10. Photo Annotation & Markup

- App: Technician
- Figma node: `1:8135`
- Frame: 390 x 884 px (phone; mobile portrait)
- Export folder: `screens/10_10._Photo_Annotation_&_Markup`
- Sources read: `10._Photo_Annotation_&_Markup.json` (developerSummary, assetIndex, full node tree), `10._Photo_Annotation_&_Markup@2x.png`, `assets/manifest.json`
- Confidence: high for layout/text/colour; medium for interaction semantics (annotation persistence is not expressed); low for RTL/Arabic and for error/offline states (none shown)

## 1. Purpose

A full-screen "Damage Markup Studio" for one evidence photo. The technician sees the photo, draws a circular/pen annotation over a damage, reviews a callout count and an estimated scuff size, picks a tool (Draw/Undo/Crop), and saves the annotated photo back to the inspection item.

## 2. Layout structure

Root `1:8135`: 390x884, VERTICAL, fill `#FFFFFF`, FIXED/HUG. It stacks:

1. `1:8136` "Main" — 390x884, VERTICAL, padding `64/0/22/0` (64 top safe area), fill white.
   - `1:8137` content container 390x797.5.
     - `1:8138` context bar — 390x48, HORIZONTAL, gap `48.26`, padding `8/20/12/20`; left icon (28x28 tinted circle) + "Front Bumper Inspection"; right transparent pill "Markup Active".
     - `1:8149` photo block — 390x453.5, padding `0/20/16/20`; 350x437.5 photo card with **`cornerRadius 32`**, two shadows.
       - Photo image fills the card; a gradient overlay sits on top.
       - Top overlay row: file chip (143.88x26) + 36x36 zoom button.
       - Annotation SVG layer 350x437.5: 128.1x109.48 freehand circle, stroke `#10B981`, 4.81px; 22.75px white handle + 9.63px emerald dot.
       - Bottom overlay row: "1 Defect Callout" chip + "0.8 mm Scuff" chip.
     - `1:8175` tools block — 390x296, padding `4/20/32/20`.
       - `1:8176` card 350x260, **radius 32**, padding 20, gap 20, shadow.
         - header 310x44: "Annotation Tools" 16/22 Bold + subtitle 13/18 Regular + "4.0 pt" size chip 71.76x22.
         - toolbar 310x80, H gap 12: three 95.33x80 buttons with **radius 32**; Draw selected (`#10B981`), Undo/Crop `#F4F3F8`.
         - "Save Photo" 310x56 pill.
2. `1:8209` Header — 390x64, FIXED/HUG, fill `#FFFFFF@0.8` with `BACKGROUND_BLUR` + shadow; H gap `78.52`, padding `0/16/0/16`; 44x44 back button, title "Damage Markup Studio" 18/24 Bold, 32x32 `#006C49` avatar circle.

No scroll container; the photo card is fixed at 350x437.5 and the tools card at 350x260. No tablet/landscape layout is expressed.

## 3. Visual tokens observed

### Colours

| Hex | Usage | ~Count |
|---|---|---|
| `#FFFFFF` | card and control surfaces | 9 |
| `#1A1B1F` | primary text/icons | 8 |
| `#5E5D69` | secondary text/icons | 7 |
| `#10B981` | primary actions, annotation stroke, dots | 6 |
| `#006C49` | deep emerald for icons/avatar | 4 |
| `#F4F3F8` | muted button surfaces | 3 |
| `#FFFFFF01` | transparent shadow containers | 2 |
| `#FFFFFFE5` (90%) / `#FFFFFFF2` (95%) | floating overlay chips | 2 / 2 |
| `#10B98126` (15%) | context icon circle | 1 |
| `#FFFFFFCC` (80%) | sticky header | 1 |

### Typography

- Family: **Plus Jakarta Sans**.
- 18 / 24 / Bold 700 / -0.45 (`Damage Markup Studio`).
- 16 / 22 / Bold 700 / -0.16 (`Annotation Tools`).
- 14 / 18 / Bold 700 (`Save Photo`); 14 for file size chips.
- 13 / 18 / Regular 400 (`Tap draw to circle surface damages`).
- 12 / 16 / SemiBold 600 (`Front Bumper Inspection`, `Draw`, `Undo`, `Crop`).
- 11 / 14 / SemiBold 600 (+0.44) (`Markup Active`, `IMG_0842.HEIC`, `1 Defect Callout`, `0.8 mm Scuff`, `4.0 pt`).
- Centred labels on tool buttons; everything else left-aligned.

### Radii, shadows, strokes, spacing

- Radii: `9999` x12, `32` x5. Photo card and tool buttons use 32; overlay chips/pills use full pill.
- Shadows: two stacked drop shadows on the photo card; single drop shadows on the Draw button, Save Photo, zoom, file chip, and size chip. Overlay chips use `BACKGROUND_BLUR`.
- Strokes: `#10B981` annotation stroke 4.81px; no other strokes.
- Spacing candidates: 4, 6, 8, 12, 14, 16, 20, 22.5, 31.4–32.4, 64. The 20px page margin and 32px card radius are not in `AppSpacingTokens`/`AppRadiiTokens`.

## 4. Components

Figma patterns:
- Glass/blurred app bar with 44px back target and 32px circular avatar.
- Photo canvas card with top file/zoom chips and bottom metric chips.
- Freehand annotation group (vector stroke + draggable handle).
- 3-up tool tile row (95.33x80, 32 radius) with a selected emerald tile.
- Small "size" chip with pen icon.
- Full-width pill save CTA.

Mapping:
- `AppScaffold` + `AppBar` — partial; ours has no blur/avatar.
- `AppButton` (primary/tonal) — maps to Draw/Undo/Crop and Save Photo.
- `AppSelectableText` — close analogue for tool selection (ours is text-only, not icon tiles).
- `StatusChip` — maps to "Markup Active"/"1 Defect Callout"/"0.8 mm Scuff".
- `AppTextField` — no equivalent (no text input here).
- Annotation canvas, freehand stroke, crop, zoom, HEIC filename chip — **no equivalent** in `client/packages/design_system`.
- Photo capture exists in `assessment_page.dart` but no annotation editor.

## 5. Assets

17 assets: 13 individual SVGs, 3 composed SVGs, 1 raster JPEG.
- Icons: camera (16.5x15.8), expand/zoom (13.5), context badge (16.5x15.75), pen-size (12.7x12), draw (20.6x19.5), undo (17.3x16.2), crop (23.8x23.8), save/check (16.7), back (11.8x20), avatar/person (12x12).
- Composed: `annotation-group-1_8163` (128.1x118.1), `Group-1_8165` (22.8x22.8 handle marker), `SVG-1_8162` (350x437.5 annotation layer).
- Raster: `image-1-1ae665aaac.jpg` — a **vehicle photo** (white front bumper/headlight close-up), rendered full-card.
- No avatar photo; the top-right avatar is an icon on an emerald circle.

## 6. Content and data

| Visible text/label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Item/photo context | `Front Bumper Inspection` | Partly: item label exists | No photo-level title field |
| State | `Markup Active` | UI state only | Not a server state |
| File name | `IMG_0842.HEIC` | No | Hardcoded device filename; HEIC may not be supported by server MIME rules |
| Callouts | `1 Defect Callout` | No | No annotation/callout model |
| Size | `0.8 mm Scuff` | No | **Invented measurement**; must not ship |
| Tool hint | `Tap draw to circle surface damages` | UI copy | "Tap draw" is awkward/ambiguous |
| Stroke size | `4.0 pt` | No | Hardcoded tool property |
| Tools | `Draw`, `Undo`, `Crop` | No | No annotation tools in product |
| CTA | `Save Photo` | Partly: evidence save exists | Saves annotated derivative, which is unsupported |
| Title | `Damage Markup Studio` | No | No such feature/route |

## 7. States shown / not shown

Shown: annotation active, one callout, one tool selected.
Not shown: no markup yet, loading photo, load failure, save failure, offline queue, local-only vs received, undo-to-empty, crop mode, multiple callouts, zoomed state, camera permission denied, HEIC conversion failure, RTL, 200% text scale.

## 8. Implied interactions

- Back returns to the defect/assessment screen (unsaved-changes warning would be needed).
- Zoom toggles preview size.
- Draw activates freehand marking; Undo removes the last stroke; Crop enters crop mode.
- Dragging the handle reshapes the annotation; tapping the dot may finish.
- Save Photo persists the marked-up image.
- File chip is informational (not obviously tappable).

## 9. Correspondence to current product

- **New screen/feature.** There is no route for photo markup in `technician_router.dart`; no annotation model in `client/apps/technician_app/lib/src/models.dart`; no annotation storage in `offline/offline_store.dart`, `offline/offline_models.dart`, or `photo_service.dart`.
- Existing photo path: `assessment_page.dart` `_addPhoto` → `PhotoService.capture` → `offlineStore.queueEvidence` → `syncService.syncAll` → `technicianEvidenceInit`/`technicianEvidenceComplete` (`api_endpoints.dart`). `EvidenceAsset` on the server stores hash/mime/bytes/dimensions but **no annotation geometry or callout metadata**.
- To ship this screen as drawn, either (a) flatten the annotation into the uploaded raster (client-side render) and treat it as the evidence image, or (b) add an annotation model/server contract. Both are **new data/server change**, not UI-only.
- "Crop" and "zoom" can be client-only, but they change the stored derivative and must be reflected in the evidence hash flow.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **Invented measurement.** `0.8 mm Scuff` is a fabricated defect measurement; the product rule is "never invent versions/licences/measurements/results".
2. **Unsupported file type.** `IMG_0842.HEIC` implies HEIC upload; the upload contract validates MIME by content sniffing and rejects unsupported types (`docs/phase-1/09-offline-and-upload-design.md` §6.2). Do not promise HEIC preview/upload.
3. **Annotation metadata is unmodelled.** Saving a visual markup without a data record means the mark is not auditable/immutable with the finding; finalized evidence is immutable.
4. **Colour/radius drift.** `#10B981`/`#006C49`, 32px radii, 20px margins are not in `client/packages/design_system/lib/src/tokens.dart` (current primary `#0B3B4A`). UI must use tokens, not these hex values.
5. **No certification/condition claims** are present; keep it that way when adding callout labels.

## 11. Open questions / could not verify

- Is the annotation meant to be burned into the JPEG, or stored as vectors? No data model is shown.
- Is "0.8 mm Scuff" a real measurement field or sample copy? If a field, which approved measuring device/unit is used?
- What are the supported input formats? HEIC contradicts current server validation.
- Should multiple callouts on one photo be allowed? The count chip implies yes; only one is drawn.
- Are Draw/Undo/Crop available in Arabic RTL? Directional icons (undo, crop) need RTL review.
- Touch target sizes: tool tiles are 95x80 (fine), back is 44x44 (below the product's 48 preferred), chips are small text-only targets.
- Accessibility of freehand drawing (non-gesture alternative, screen-reader labeling of the image and annotations) is not defined.
