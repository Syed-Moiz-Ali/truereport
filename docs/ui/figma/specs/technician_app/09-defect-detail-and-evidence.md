# 09. 9. Defect Detail & Evidence

- App: Technician
- Figma node: `1:8021`
- Frame: 390 x 1031.67 px (phone; mobile portrait)
- Export folder: `screens/09_9._Defect_Detail_&_Evidence`
- Sources read: `9._Defect_Detail_&_Evidence.json` (developerSummary, assetIndex, full node tree), `9._Defect_Detail_&_Evidence@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html` referenced but not opened
- Confidence: high for layout/text/colour (JSON geometry and PNG agree); medium for product semantics because the screen invents a defect taxonomy and a fixed evidence count; low for RTL/Arabic and dynamic states (none exported)

## 1. Purpose

A bottom-sheet detail view for one exterior defect pin. It shows the pinned location on a defocused vehicle wireframe, lets the technician set an inspection status (Pass/Minor/Major), pick a defect type, attach an evidence photo and a note, then "SAVE DEFECT".

## 2. Layout structure

Root `1:8021`: `layoutMode=VERTICAL`, 390x1031.67, fill `#FFFFFF`, no padding/gap, `layoutSizingHorizontal=FIXED`, `layoutSizingVertical=HUG`. Two fixed-height bands:

1. `1:8022` "Top Half: Context Wireframe Inspection Backdrop" — 390x320, VERTICAL, padding `0/20/0/20`, no gap.
   - `1:8023` top action bar — 350x56, HORIZONTAL, gap `37.9`, padding top 8; 48x48 close button, status pill (178.13x22), 48x48 help button.
   - `1:8034` ambient wireframe block — 350x264, padding `4/0/4/0`; blurred 350x256 wireframe with a 40x40 pin and "PIN #03" label.
2. `1:8057` "Bottom Half: Thick Pure White Slide-Up Inspection Bottom Sheet" — 390x711.67, VERTICAL, gap `24`, padding `16/20/24/20`, **top corners only `48`** (`rTL=48`, `cornerRadius=__MIXED__`), two drop shadows.
   - `1:8058` grab handle 350x10 (44x6 bar).
   - `1:8060` header 350x50 (H, gap `126.83`): category label + 26px title + 40x40 car icon chip.
   - `1:8071` status toggle 350x70.
   - `1:8081` defect classification 350x88.
   - `1:8096` evidence grid 350x185.
   - `1:8120` note input 350x56.67.
   - `1:8129` save CTA 350x68 (56px button).

No scroll container: the sheet is one static column whose height (711.67) is designed to fit the frame. Responsiveness is not expressed (fixed 390 width, HUG height). There is no tablet layout.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

| Hex | Usage | ~Count |
|---|---|---|
| `#FFFFFF` | sheet, buttons, pill surfaces | 10 |
| `#1A1B1F` | primary ink text, selected chip text, icons | 10 |
| `#5E5D69` | section labels, secondary text, unselected | 14 |
| `#F4F3F8` | muted control surfaces / chips | 6 |
| `#10B981` | primary CTA, selected-count text, camera icon | 4 |
| `#F59E0B` | defect pin, category dot, selected "Minor" dot | 4 |
| `#BBCABF` | blurred wireframe strokes | 9 |
| `#FFFFFFE5` (90%) | floating pill/overlay surfaces | 3 |
| `#10B9811A` (10%) | camera icon circle | 1 |
| `#E3E2E7` | grab handle | 1 |
| `#EEEDF3` | selected defect chip surface | 1 |
| `#FBBF2433` (20%) | pin halo | 1 |
| `#FED7AA` | selected severity pill | 1 |

### Typography

Family is **Plus Jakarta Sans** throughout (no fallback shown). Observed sizes: 11, 12, 13, 26.
- Section labels: 11 / line-height 14 / SemiBold 600 / letter-spacing +0.55 (`INSPECTION STATUS`, `DEFECT CLASSIFICATION`, `PHOTOGRAPHIC EVIDENCE`). Uppercase.
- Title: 26 / 32 / ExtraBold 800 / -0.65 tracking (`Front Left Door`).
- Status/segment labels: 12 / 16 / SemiBold 600 (+0.24 letterspacing); selected 12 / Bold 700.
- Chips: 11 / 14 / SemiBold 600 (+0.44).
- Button: 14 / 18 / Bold 700 / +0.7 (`SAVE DEFECT`).
- Note placeholder: 13 / auto / Regular 400 / 0.
- All `textAlignHorizontal=LEFT` except segment/button labels `CENTER`.

### Radii, shadows/elevation, strokes, spacing

- Radii: `9999` (23 nodes) and `48` (sheet top). Chips/buttons are pills; sheet uses a 48px top radius.
- Shadows: drop shadows on floating buttons, pills, pin, sheet, note box; the sheet has two stacked drop shadows. Blur layer uses `LAYER_BLUR`; pills use `BACKGROUND_BLUR`.
- Strokes: only the wireframe vectors, `#BBCABF` at 1.5–2.5px.
- Spacing candidates: 4, 6, 8, 12, 16, 20, 24 (counts 18/6/19/8/17/4/2). 20 is not in `AppSpacingTokens`.

## 4. Components

Figma patterns:
- Floating 48x48 circular icon buttons (close/help) with ambient shadow and blur.
- Status pill (dot + uppercase label) at 22px height.
- Blurred context illustration with a 40px map pin and a separate label pill.
- Slide-up sheet with grab handle and 48px top radius.
- 3-way pill segmented control with selected pastel fill.
- Selectable chip group (single-select).
- 2-up square evidence tiles: filled thumbnail + "Tagged" badge; empty tile with 56px tinted camera circle.
- Filled note field with leading mic icon and trailing add button.
- Full-width 56px pill primary CTA.

Mapping to our design system:
- `AppScaffold` / bottom sheet (no dedicated bottom-sheet component beyond `showModalBottomSheet` helpers) — partial.
- `AppSelectableText` — maps to both the status segments and defect chips (but our component is single-select text).
- `AppTextField` — maps to the note field (our field has no mic/plus affordance).
- `StatusChip` — maps to "Tagged" / category pills.
- `AppButton` primary — maps to SAVE DEFECT.
- `SeverityBadge` — the Minor/Major segments are not severity badges; no direct equivalent.
- Blurred wireframe + map pin — no equivalent.
- Evidence 2-up tile with tag overlay — no equivalent (current evidence is a thumbnail `Wrap` in `assessment_page.dart`).

## 5. Assets

22 assets: 19 individual SVGs, 2 composed SVGs, 1 raster JPEG.
- Icons: close (14x14), help (18.3), car/category (15x13.3), alert/warning (3x13.5), camera (25x22.5), edit/pencil (12x12), mic (12.8x17.4), add/plus (16.7), checkmark (13.6x10), orange dot (9.3), badge dot.
- Composed: `SVG-1_8037` (350x192, 9 vectors) and `Blur-1_8036` (350x256, 9 vectors) — the monochrome car wireframe and its blurred duplicate.
- Raster: `image-1-a08194722a.jpg` (512x279, 16.5 KB) rendered at 167x167 — a close-up photo of the vehicle/door surface. It is a **vehicle evidence photo**, not an avatar.
- No customer avatar.

## 6. Content and data

| Visible text/label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Bay/status | `BAY 04 • IN PROGRESS` | Partly: job reference/status exist; "BAY 04" does not | Workshop/bay is not a current job field |
| Pin | `PIN #03` | No | Pin index is a UI construct; no defect-pin model |
| Category | `EXTERIOR BODYWORK` | Yes: item category labels | Current model exposes `categoryLabelEn` |
| Item | `Front Left Door` | Yes: item label | Current `labelEn` |
| Status options | `Pass`, `Minor`, `Major` | No | Product has result codes + separate severity; "Pass" is forbidden wording |
| Defect classification | `Dent / Crease`, `Surface Scratch`, `Paint Chip`; `1 Selected` | No | No defect-type taxonomy or endpoint |
| Evidence count | `1 of 4 Required` | Partly: `minPhotos` exists per item | "4" is hardcoded here; must come from template |
| Evidence tag | `Tagged` | New | No per-photo tag/annotation field |
| Evidence action | `Take a photo`, `Tap to capture` | Yes: photo capture exists | No annotation/markup |
| Note | `Add defect notes (e.g. 2.5cm door ding)...` | Yes: `note` | **"2.5cm" is an invented measurement example**; must not ship as a claim |
| CTA | `SAVE DEFECT` | Partly: item save exists | Save is per assessment, not per defect |

No date, score, VIN, plate, phone or customer name is shown.

## 7. States shown / not shown

Shown: selected severity (Minor), selected defect type (Dent/Crease), one captured photo, one empty photo slot.
Not shown: loading, empty (zero photos), error/save failure, offline/local-only vs received, validation (missing severity/reason), RTL, text-scale, disabled CTA, camera permission denied, more than two photos, long labels.

## 8. Implied interactions

- Close inspector (X) dismisses the sheet back to the wireframe/inspection hub.
- Help (?) opens guidance.
- Tap a severity segment; tap a defect chip (single-select); tap the selected chip again may not deselect (not shown).
- Tap the captured photo opens markup/annotation (pencil chip).
- Tap "Take a photo" opens camera/gallery.
- Tap the note field focuses the keyboard; trailing plus may add another note/voice input.
- "SAVE DEFECT" commits the defect and returns to the previous screen.
- Pin is shown but not shown as tappable here.

## 9. Correspondence to current product

- Matches `client/apps/technician_app/lib/src/pages/assessment_page.dart`, route `/jobs/:id/items/:itemId` (`technician_router.dart`), and the `technicianAssessment` endpoint (`client/packages/api_client/lib/src/api_endpoints.dart`).
- The current page already renders: item label, instruction, evidence requirement chip, guide image, photo thumbnails, result chips from `resultOptions`, conditional severity (`MINOR/MODERATE/MAJOR/SAFETY_CRITICAL`), note, reason, and save. See `assessment_page.dart` `_Form` and `_save`.
- **New data/feature required**: defect-type classification, pin/defect identity, per-photo tag metadata, "N of M required" copy derived from `minPhotos` (currently only a boolean-ish chip).
- The Figma "Pass / Minor / Major" merges two product concepts (result vs severity) and does not match `resultOptions` from the pinned template.
- Evidence capture exists locally (`photo_service.dart`, `offline_store.queueEvidence`, `sync_service.dart`) and server-side (`EvidenceController`, `evidence/init|complete`), but the Figma 2-up "evidence grid with tag" is not implemented.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"Pass" wording.** Phase-1 rule: `NO_ISSUE_OBSERVED` must never be labelled "Pass", "Perfect" or "Certified" (`docs/phase-1/10-design-system.md` §3.3). Evidence: the status control is `Pass / Minor / Major`.
2. **No invented measurements.** Product rule: never invent measurements/results. Evidence: placeholder `e.g. 2.5cm door ding`. Must be removed or replaced with neutral help text.
3. **No single unexplained condition score.** Not applicable here (no score), but the three-state status could read as a condition score; it must be presented as result + severity with labels.
4. **Hardcoded evidence requirement `1 of 4 Required`.** Evidence counts must come from the pinned template/item rule, not design copy.
5. **Two visual tokens not in the token contract.** `#F59E0B`/`#FED7AA` marketing amber and 48px sheet radius are not in `client/packages/design_system/lib/src/tokens.dart` (`color.*` / `radii.*`); current app primary is `#0B3B4A`, not `#10B981`.

## 11. Open questions / could not verify

- Is "Front Left Door" an inspection item, a pin, or a sub-defect of the exterior category? The screen combines all three.
- Where does "BAY 04" come from? No bay field exists in `TechnicianJob`.
- Are Pass/Minor/Major meant to be the result, the severity, or both? The product keeps them separate.
- Is "1 of 4" a template `minPhotos` value or a fixed design minimum?
- How are multiple defects per panel represented (list, pins, one sheet per pin)?
- RTL/Arabic layout, 200% text scale, 48dp target compliance for the 22px pill controls, and focus order could not be verified from the export.
- The blurred wireframe is decorative; its accessibility treatment (hidden vs described) is undefined.
