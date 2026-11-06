# F2-A1 fidelity audit — Screen 6, Equipment Checklist

Source of truth: `docs/ui/figma/f2a1-nodes/06-equipment.txt` (node ids below). Preview: `docs/ui/figma-export/technision_figma/screens/06_6._Equipment_Checklist/6._Equipment_Checklist@2x.png`.

Refs: `JD` = `client/apps/technician_app/lib/src/pages/job_detail_page.dart`; `API` = `technician_api.dart`; `M` = `models.dart`; `OV` = `client/packages/design_system/lib/src/components/overlays.dart`; `LT` = `.../components/lists.dart`. `JD:354-394` is the only equipment UI today: a modal bottom sheet, not screen 6. All Flutter values below are current, not proposed.

| Node id | Name | Figma box | Figma style | Current Flutter value | Delta | Required fix |
|---|---|---|---|---|---|---|
| 1:7643 | FRAME 6. Equipment Checklist | 0,0 390x910 | #FFFFFF, V, gap 0 | No screen/route; equipment is a sheet (`JD:354`) | Root is a sheet, not a 390x910 page | Build screen 6 (or an approved full-screen route) |
| 1:7644 | FRAME Main | 0,0 390x910 | #FFFFFF, V, gap 0, pad 64,0,0,0 | Not implemented | Missing full-height main column | Build page scaffold |
| 1:7645 | FRAME Container | 0,64 390x846 | V, gap 0, pad 0,20,40,20 | Not implemented | Missing page padding/column | Build content container |
| 1:7646 | Status & Progress:margin | 20,64 350x60 | V, pad 12,0,24,0 | Not implemented | No step/progress strip | Add strip; 60 high, 24 bottom |
| 1:7647 | Status & Progress | 20,76 350x24 | H, gap 72.34 | Not implemented | Missing row | Add 24-high row |
| 1:7648 | Container | 20,76 179.41x24 | H, gap 8 | Not implemented | Missing badge+label group | Add row, gap 8 |
| 1:7649 | Background | 20,76 24x24 | r 9999, #E3E1EF, pad 4.5,0,5.5,0 | Not implemented | Missing step badge | Add 24px pill, `#E3E1EF` |
| 1:7650 | Text "01" | 25.46,80.5 13.08x14 | PJS SemiBold 11/600, lh 14, ls 0.44, #1B1B25, center | Not implemented | Missing step number | Render "01" at 11/600 |
| 1:7651 | Container | 52,80 147.41x16 | V, gap 0 | Not implemented | Missing label box | Add label container |
| 1:7652 | Text "PRE-INSPECTION SETUP" | 52,80 147.41x16 | PJS SemiBold 12/600, lh 16, ls 0.24, #5E5D69 | Not implemented | Missing step label | Bind localized step label; 12/600 |
| 1:7653 | Background | 271.75,77 98.25x22 | r 9999, #F4F3F8, pad 4,12,4,12 | Not implemented | Missing status pill | Add right-aligned pill |
| 1:7654 | Text "1 of 4 Verified" | 283.75,81 74.25x14 | PJS SemiBold 11/600, lh 14, ls 0.275, #10B981 | Not implemented; "Verified" is deny-listed (`f2a-report.md:124`) | Missing status AND wording is forbidden | Use neutral count copy e.g. "1 of 4 checked", not "Verified" |
| 1:7655 | Header margin | 20,124 350x108 | V, pad 0,0,32,0 | Not implemented | Missing header spacing | Add 32 bottom |
| 1:7656 | Header Section | 20,124 350x76 | V, gap 4 | Not implemented | Missing title/subtitle group | Add gap-4 block |
| 1:7657 | Heading 2 | 20,124 350x32 | V, gap 0 | Not implemented | Missing heading container | Add heading box |
| 1:7658 | Text "Required Equipment" | 20,124 350x32 | PJS ExtraBold 26/800, lh 32, ls -0.65, #1B1B25 | Sheet uses `TechnicianSectionTitle` `titleLarge` w700 (`JD:370`) | Wrong component/scale/copy | Use 26/800 display heading; bind copy |
| 1:7659 | Container | 20,160 350x40 | V, gap 0 | Not implemented | Missing description box | Add description container |
| 1:7660 | Text description | 20,160 350x40 | PJS Medium 14/500, lh 20, ls -0.07, #5E5D69 | Not implemented | Missing subtitle | Add 14/500 muted copy; verify "calibrated/paired" claim |
| 1:7661 | Stack margin | 20,232 350x450 | V, pad 0,0,40,0 | Not implemented | Missing list spacing | Add 40 bottom |
| 1:7662 | Hardware Checklist Stack | 20,232 350x410 | V, gap 16 | Raw `AppListTile` list, no gap (`JD:382-387`) | Wrong list structure | Use 16-gap card stack |
| 1:7663 | Item 1: Checked / Verified | 20,232 350x88 | r 32, #FFFFFF, drop 8/2 + 40/14, H, gap 16.19, pad 20 | Replaced by `AppListTile` (`LT:71`) | Wrong height/radius/shadow/padding | Build 350x88 card, r32, pad20 |
| 1:7664 | Container | 40,252 261.81x48 | H, gap 16, pad 0,12,0,0 | Not implemented | Missing icon+text row | Add row, gap16, 12 top |
| 1:7665 | Background | 40,252 48x48 | r 9999, #F4F3F8 | `AppListTile` leading icon only (`JD:385`) | Missing 48px icon circle | Add 48px circle |
| 1:7666 | Container | 54,270 20x12 | V, gap 0 | Not implemented | Missing icon box | Add icon box |
| 1:7667 | VECTOR Icon | 54,270 20x12 | fill #10B981 | `Icons.handyman_outlined` (`JD:385`) | Wrong icon/size/colour | Use equipment icon; verify vector |
| 1:7668 | Container | 104,256 185.81x40 | V, gap 0 | Not implemented | Missing text column | Add name+detail column |
| 1:7669 | Container | 104,256 185.81x22 | V, gap 0 | Not implemented | Missing name row | Add name row |
| 1:7670 | Text "Tire Depth Gauge" | 104,256 131.86x22 | PJS Bold 16/700, lh 22, ls -0.16, #1B1B25 | Raw equipment UUID in title (`JD:383`) | Wrong content; no name | Bind `labelEn`/`labelAr` |
| 1:7671 | Container | 104,278 185.81x18 | V, gap 0 | Not implemented | Missing detail row | Add detail row |
| 1:7672 | Text detail | 104,278 185.81x18 | PJS Regular 13/400, lh 18, #5E5D69 | Not implemented | No spec/status text | Add spec field or omit; no invented copy |
| 1:7673 | Background+Shadow | 318,260 32x32 | r 9999, #10B981, drop 12/4 | Not implemented | Missing verified badge | Add 32px status badge |
| 1:7674 | Container | 327.89,271.49 12.23x9.02 | V, gap 0 | Not implemented | Missing check glyph | Add check glyph |
| 1:7675 | VECTOR Icon | 327.89,271.49 12.23x9.02 | fill #FFFFFF | Not implemented | Missing white check | Add check; bind verification state |
| 1:7676 | Item 2: OBD Scanner | 20,336 350x98 | r 32, #FFFFFF, drop 8/2 + 40/14, H, gap 0, pad 20 | `AppListTile` (`JD:382-387`) | Wrong height/radius/shadow | Build 350x98 card |
| 1:7677 | Container | 40,356 261.5x58 | H, gap 16, pad 0,12,0,0 | Not implemented | Missing icon+text row | Add row, gap16 |
| 1:7678 | Background | 40,361 48x48 | r 9999, #F4F3F8 | `AppListTile` leading icon | Missing 48px circle | Add 48px circle |
| 1:7679 | Container | 53,374 22x22 | V, gap 0 | Not implemented | Missing icon box | Add 22px icon box |
| 1:7680 | VECTOR Icon | 53,374 22x22 | fill #5E5D69 | `Icons.handyman_outlined` | Wrong icon/size/colour | Use OBD icon; verify vector |
| 1:7681 | Container | 104,356 185.5x58 | V, gap 0 | Not implemented | Missing text column | Add name+detail column |
| 1:7682 | Container | 104,356 185.5x22 | V, gap 0 | Not implemented | Missing name row | Add name row |
| 1:7683 | Text "OBD Scanner" | 104,356 102.11x22 | PJS Bold 16/700, lh 22, ls -0.16, #1B1B25 | Raw UUID | Wrong content; no name | Bind `labelEn`/`labelAr` |
| 1:7684 | Container | 104,378 185.5x36 | V, gap 0 | Not implemented | Missing 2-line detail | Add 36-high detail row |
| 1:7685 | Text detail | 104,378 185.5x36 | PJS Regular 13/400, lh 18, #5E5D69 | Not implemented | No spec/pairing text | Add spec/pairing field or omit |
| 1:7686 | Background | 318,369 32x32 | r 9999, #E9E7ED | Not implemented | Missing unverified badge | Add neutral 32px badge |
| 1:7687 | Container | 327.89,380.49 12.23x9.02 | V, gap 0 | Not implemented | Missing badge glyph | Add glyph box |
| 1:7688 | VECTOR Icon | 327.89,380.49 12.23x9.02 | no fill listed | Not implemented | Missing glyph | Verify vector; bind state |
| 1:7689 | Item 3: Torque Wrench | 20,450 350x88 | r 32, #FFFFFF, drop 8/2 + 40/14, H, gap 5.06, pad 20 | `AppListTile` | Wrong height/radius/shadow | Build 350x88 card |
| 1:7690 | Container | 40,470 272.94x48 | H, gap 16, pad 0,12,0,0 | Not implemented | Missing icon+text row | Add row, gap16 |
| 1:7691 | Background | 40,470 48x48 | r 9999, #F4F3F8 | `AppListTile` leading icon | Missing 48px circle | Add 48px circle |
| 1:7692 | Container | 55,485 18x18 | V, gap 0 | Not implemented | Missing icon box | Add 18px icon box |
| 1:7693 | VECTOR Icon | 55,485 18x18 | fill #5E5D69 | `Icons.handyman_outlined` | Wrong icon/size/colour | Use wrench icon; verify vector |
| 1:7694 | Container | 104,474 196.94x40 | V, gap 0 | Not implemented | Missing text column | Add name+detail column |
| 1:7695 | Container | 104,474 196.94x22 | V, gap 0 | Not implemented | Missing name row | Add name row |
| 1:7696 | Text "Torque Wrench" | 104,474 114.94x22 | PJS Bold 16/700, lh 22, ls -0.16, #1B1B25 | Raw UUID | Wrong content; no name | Bind `labelEn`/`labelAr` |
| 1:7697 | Container | 104,496 196.94x18 | V, gap 0 | Not implemented | Missing detail row | Add detail row |
| 1:7698 | Text detail | 104,496 196.94x18 | PJS Regular 13/400, lh 18, #5E5D69 | Not implemented | No spec text | Add spec field or omit |
| 1:7699 | Background | 318,478 32x32 | r 9999, #E9E7ED | Not implemented | Missing unverified badge | Add neutral 32px badge |
| 1:7700 | Container | 327.89,489.49 12.23x9.02 | V, gap 0 | Not implemented | Missing badge glyph | Add glyph box |
| 1:7701 | VECTOR Icon | 327.89,489.49 12.23x9.02 | no fill listed | Not implemented | Missing glyph | Verify vector; bind state |
| 1:7702 | Item 4: Paint Depth Gauge | 20,554 350x88 | r 32, #FFFFFF, drop 8/2 + 40/14, H, gap 50.31, pad 20 | `AppListTile` | Wrong height/radius/shadow | Build 350x88 card |
| 1:7703 | Container | 40,574 227.69x48 | H, gap 16, pad 0,12,0,0 | Not implemented | Missing icon+text row | Add row, gap16 |
| 1:7704 | Background | 40,574 48x48 | r 9999, #F4F3F8 | `AppListTile` leading icon | Missing 48px circle | Add 48px circle |
| 1:7705 | Container | 56,588.5 16x19 | V, gap 0 | Not implemented | Missing icon box | Add 16x19 icon box |
| 1:7706 | VECTOR Icon | 56,588.5 16x19 | fill #5E5D69 | `Icons.handyman_outlined` | Wrong icon/size/colour | Use paint-gauge icon; verify vector |
| 1:7707 | Container | 104,578 151.69x40 | V, gap 0 | Not implemented | Missing text column | Add name+detail column |
| 1:7708 | Container | 104,578 151.69x22 | V, gap 0 | Not implemented | Missing name row | Add name row |
| 1:7709 | Text "Paint Depth Gauge" | 104,578 142.48x22 | PJS Bold 16/700, lh 22, ls -0.16, #1B1B25 | Raw UUID | Wrong content; no name | Bind `labelEn`/`labelAr` |
| 1:7710 | Container | 104,600 151.69x18 | V, gap 0 | Not implemented | Missing detail row | Add detail row |
| 1:7711 | Text detail | 104,600 151.69x18 | PJS Regular 13/400, lh 18, #5E5D69 | Not implemented | No spec text | Add spec field or omit |
| 1:7712 | Background | 318,582 32x32 | r 9999, #E9E7ED | Not implemented | Missing unverified badge | Add neutral 32px badge |
| 1:7713 | Container | 327.89,593.49 12.23x9.02 | V, gap 0 | Not implemented | Missing badge glyph | Add glyph box |
| 1:7714 | VECTOR Icon | 327.89,593.49 12.23x9.02 | no fill listed | Not implemented | Missing glyph | Verify vector; bind state |
| 1:7715 | Ambient Kit margin | 20,682 350x124 | V, pad 0,0,32,0 | Not implemented | Missing 32 bottom | Add spacing |
| 1:7716 | Ambient Kit Validation Card | 20,682 350x92 | r 32, #F4F3F8, H, gap 16, pad 20 | Not implemented | Missing standards card | Build 350x92 card |
| 1:7717 | Background+Shadow | 40,708 40x40 | r 9999, #FFFFFF, drop 2/1 | Not implemented | Missing 40px icon circle | Add 40px white circle |
| 1:7718 | Container | 53.33,719.67 13.33x16.67 | V, gap 0 | Not implemented | Missing shield box | Add shield box |
| 1:7719 | VECTOR Icon | 53.33,719.67 13.33x16.67 | fill #10B981 | Not implemented | Missing shield icon | Verify vector; bind approval |
| 1:7720 | Container | 96,702 184.19x52 | V, gap 0 | Not implemented | Missing text column | Add title+body column |
| 1:7721 | Container | 96,702 184.19x16 | V, gap 0 | Not implemented | Missing title row | Add title row |
| 1:7722 | Text "Fleet Station Standards" | 96,702 141.33x16 | PJS SemiBold 12/600, lh 16, ls 0.24, #1B1B25 | Not implemented; "Fleet" is deny-listed (`f2a-report.md:50`) | Missing title AND forbidden wording | Use neutral standards title; no "Fleet" claim |
| 1:7723 | Container | 96,718 184.19x36 | V, gap 0 | Not implemented | Missing 2-line body | Add 36-high body |
| 1:7724 | Text "ISO-9001 certified diagnostic requirements" | 96,718 184.19x36 | PJS Regular 13/400, lh 18, #5E5D69 | Not implemented; certification wording is deny-listed (`f2a-report.md:124`) | Missing body AND unbacked ISO claim | Do not render without compliance approval/source |
| 1:7725 | Bottom CTA Fixed Floating Bar | 20,806 350x64 | V, pad 8,0,0,0 | Not implemented | Missing fixed CTA region | Add 64-high fixed bar |
| 1:7726 | Button | 20,814 350x56 | r 9999, #10B981, drop 25/10, H, gap 8 | No CTA in sheet | Missing primary action | Add 350x56 pill |
| 1:7727 | Container | 155.57,833 57.52x18 | V, gap 0 | Not implemented | Missing label box | Add label box |
| 1:7728 | Text "Proceed" | 155.57,833 57.52x18 | PJS Bold 14/700, lh 18, ls -0.14, #FFFFFF, center | Not implemented; product P1 is 19/700 on #059669 (`f2a-report.md:22`) | Missing label; P1 known deviation | Use approved P1 label/colour |
| 1:7729 | Container | 221.09,835.33 13.33x13.33 | V, gap 0 | Not implemented | Missing arrow box | Add arrow box |
| 1:7730 | VECTOR Icon | 221.09,835.33 13.33x13.33 | fill #FFFFFF | Not implemented | Missing arrow | Verify vector; mirror in RTL |
| 1:7731 | Header | 0,0 390x64 | #FFFFFFCC, drop 8/1, blur 48, V | No app bar on sheet; drag handle only (`OV:68-91`) | Missing 64-high translucent header | Build 64-high header |
| 1:7732 | Container | 0,0 390x64 | H, gap 102.47, pad 0,16,0,16 | Not implemented | Missing header row | Add 16 horizontal padding |
| 1:7733 | Container | 16,10 223.53x44 | H, gap 4 | Not implemented | Missing back+title group | Add gap-4 group |
| 1:7734 | Button - Go back | 16,10 44x44 | r 9999, H | Not implemented | Missing 44px back target | Add 44x44 target |
| 1:7735 | Container | 32.11,22 11.77x20 | V, gap 0 | Not implemented | Missing chevron box | Add chevron box |
| 1:7736 | VECTOR Icon | 32.11,22 11.77x20 | fill #1A1B1F | Not implemented | Missing back chevron | Verify vector; mirror in RTL |
| 1:7737 | Heading 1 | 64,20 175.53x24 | V, pad 0,0,0,4 | Not implemented | Missing title box | Add title box |
| 1:7738 | Text "Diagnostic Checklist" | 68,20 171.53x24 | PJS Bold 18/700, lh 24, ls -0.45, #1A1B1F | Not implemented | Missing app-bar title | Render 18/700 |
| 1:7739 | Background | 342,16 32x32 | r 9999, #006C49 | Not implemented | Missing profile avatar | Add 32px avatar |
| 1:7740 | Container | 352,26 12x12 | V, gap 0 | Not implemented | Missing avatar glyph box | Add 12px box |
| 1:7741 | VECTOR Icon | 352,26 12x12 | fill #FFFFFF | Not implemented | Missing profile glyph | Verify vector |

## Structural fixes

- Screen 6 is not built. Today `JD:75` opens `_equipment` (`JD:354-394`) as a modal sheet; there is no `/jobs/:id/equipment` page/route. The Figma root is a 390x910 screen with fixed header (1:7731) and bottom CTA (1:7725).
- Replace the `TechnicianSectionTitle` + raw-ID `AppListTile` list with the Figma structure: 60-high status strip (1:7646), 108-high header block (1:7655), 410-high 16-gap card stack (1:7662), 92-high ambient card (1:7716), 64-high CTA (1:7725), 64-high app bar (1:7731).
- Cards are 350 wide, 88/98 high, radius 32, 20 padding, 48px icon circle, 32px state badge, name 16/700, detail 13/400. Current `AppListTile` uses `titleMedium`, `spacing.md/sm`, `radii.lg`, min 48 target (`LT:102-168`).
- Figma CTA is 14/700 white on `#10B981`; product P1 is 19/700 on `#059669` (`f2a-report.md:22`). Keep P1 unless the owner changes the design decision.
- Figma app bar title is 18/700 `#1A1B1F`; avatar is 32px `#006C49`. The current sheet has no app bar, only `showDragHandle` (`OV:76`) and `surfaceContainerLowest` (`OV:78`).
- The sheet is not the same surface: `showAppBottomSheet` pads with `spacing.lg` and uses `useSafeArea` (`OV:68-91`). A full screen must use the technician shell/app bar instead.
- Do not copy the Figma "Verified", "Fleet" or "ISO-9001 certified" strings; they are deny-listed (`f2a-report.md:50,124`).

## Data gap and API change

- Current endpoint: `GET /api/v1/technician/jobs/{id}/equipment` (`api_endpoints.dart:103-104`) → `EquipmentListDto` (`server/.../inspections/api/EquipmentListDto.java:6`, controller `:43-46`, service `:159-170`) returns exactly `{ "equipmentIds": [UUID, ...] }`.
- Client mirrors it: `API:248-254` reads only `equipmentIds`; `InspectionItem` also carries only `equipmentIds` (`M:186,211,236,266`). The sheet prints raw IDs plus `technicianEquipmentIdsOnly` = "Equipment names are not available from the server in this build." (`app_en.arb:365`).
- Missing from the technician payload: names (`labelEn`/`labelAr` exist on master `EquipmentDto.java:5-6` and `MasterContentService.java:354-358`, but are not returned here), specs, verification state, pairing state, calibration state/due date, and any ISO-9001 evidence.
- Master `Equipment` only stores `code`, `status`, `sortOrder` (`Equipment.java:21-28`); labels live in localized content. There is no spec/calibration/pairing field anywhere in that entity.
- Small API change (field names only, no implementation): return `equipment` as an array of objects with `equipmentId`, `code`, `labelEn`, `labelAr`, `status`, `sortOrder`. Keep `equipmentIds` for compatibility. If the Figma subtitles are required, also add `specificationEn`, `specificationAr`; for the badges/state add `verificationStatus`, `paired`, `calibrationStatus`, `calibrationDueAt`. The ISO-9001 claim needs a separately approved `standardClaimEn`/`standardClaimAr` source, or omission.

## Slot-sheet items

- Tire Depth Gauge — `1:7670`; detail "Digital laser calibration · Ready" `1:7672`; green check badge `1:7673-1:7675`.
- OBD Scanner — `1:7683`; detail "Bluetooth module v4.2 · Tap to verify" `1:7685`; empty neutral badge `1:7686-1:7688`.
- Torque Wrench — `1:7696`; detail "Preset 120-140 Nm · Mechanical" `1:7698`; empty neutral badge `1:7699-1:7701`.
- Paint Depth Gauge — `1:7709`; detail "Fe / NFe substrate probe" `1:7711`; empty neutral badge `1:7712-1:7714`.
- Fleet Station Standards / ambient kit — `1:7722`; body "ISO-9001 certified diagnostic requirements" `1:7724`; shield icon `1:7719`.
- Slot chrome: step "01" / "PRE-INSPECTION SETUP" / "1 of 4 Verified" (`1:7650,1:7652,1:7654`), "Required Equipment" + description (`1:7658,1:7660`), "Proceed" (`1:7728`), "Diagnostic Checklist" (`1:7738`).

## Could not verify

- Vector icon identities: the dump gives only size/fill for `VECTOR` nodes (`1:7667,1:7680,1:7693,1:7706,1:7719,1:7730,1:7736,1:7741`); the preview suggests gauge/OBD/wrench/paint-gauge/shield/arrow/back/profile, but exact assets are not named.
- Shadow colours/blur beyond the dump's `DROP_SHADOW(8 0,2)` / `(40 0,14)` / `(12 0,4)` / `(2 0,1)` / `(25 0,10)` notation.
- Actual API response for a real job, and whether any job currently has equipment rows or populated `labelEn`/`labelAr`.
- Whether any calibration/pairing/verification data exists outside the inspected entity/endpoint.
- Validity of the "ISO-9001 certified" claim; no source or compliance record was found.
- Font rasterisation (Plus Jakarta Sans in Figma vs bundled Flutter fonts) and exact optical metrics.
- Dark theme and Arabic/RTL layouts: no Figma frames for either; only derived product behaviour exists.
- Tap-to-verify interaction: the dump contains copy only, no state machine, affordance or result.
