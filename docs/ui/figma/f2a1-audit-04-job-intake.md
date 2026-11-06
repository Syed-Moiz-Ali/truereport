# F2A1 fidelity audit 04 - Job Details & Intake

**Sources:** `docs/ui/figma/f2a1-nodes/04-job-intake.txt` (all Figma values below), preview `.../04_4._Job_Details_&_Intake@2x.png`, current view `client/apps/technician_app/lib/src/screens/f2a/job_intake_view.dart`, `models.dart`, `client/packages/design_system/lib/src/{tokens.dart,generated/tokens.g.dart,components/*}`, render `docs/ui/figma/f2a-screenshots/job-intake_en_1.0x.png`.
**Method:** Figma values are copied from the node dump. Current styles are the resolved design-system token values used by the cited widget. "Absent" means no equivalent widget exists. No measurement is estimated.

| Node id | Name | Figma box | Figma style | Current Flutter value | Delta | Required fix |
|---|---|---|---|---|---|---|
| 1:7396 | 4. Job Details & Intake | 0,0 390x1128 | fill #FFFFFF, VERTICAL gap 0 pad 0 | AppScaffold, surface #FFFFFF | height is viewport/scroll driven, not fixed 1128 | none (content height) |
| 1:7397 | Main | 0,0 390x1128 | fill #FFFFFF, VERTICAL pad 64,0,0,0 | TechnicianAppBar 64 + body Column | body scrolls; no fixed height | none |
| 1:7398 | Container | 0,64 390x1064 | no fill/radius | SafeArea body | none | none |
| 1:7399 | Metadata header margin | 20,64 350x54 | VERTICAL pad 8,0,24,0 | ScrollView pad 20 horizontal, 20 vertical | top 20 vs 8, bottom 20 vs 24 | top 8, bottom 24 |
| 1:7400 | Subtle Metadata & Progress Header | 20,72 350x22 | HORIZONTAL gap 15.91 | Wrap spacing 8, runSpacing 4; rendered height >=28 | gap 8 vs 15.91; height 28 vs 22 | Row/SpaceBetween, gap 16 |
| 1:7401 | Header left Container | 20,72 241.67x22 | HORIZONTAL gap 8 | Wrap with one "Assigned" StatusChip | missing 2 of 3 items; gap 8 matches | add INTAKE PHASE + Ready for Check |
| 1:7402 | INTAKE PHASE Background | 20,72 103.67x22 | r9999 fill #F4F3F8 pad 4,12,4,12 | Absent (StatusChip 28h, tone fill) | missing; 28 vs 22 high | add 22h neutral pill |
| 1:7403 | INTAKE PHASE Text | 32,76 79.67x14 | #5E5D69 11/600 lh14 ls .275 | Absent | missing | add 11/14 w600 .275 |
| 1:7404 | Ready for Check Overlay | 131.67,72 130x22 | r9999 fill #6FFBBE33 gap6 pad 4,12,4,12 | Absent | missing | add success pill |
| 1:7405 | Ready dot Background | 143.67,80 6x6 | r9999 fill #10B981 | Absent | missing | add 6x6 dot |
| 1:7406 | Ready for Check Text | 155.67,76 94x14 | #00422B 11/600 lh14 ls .44 | Absent | missing | add 11/14 w600 #00422B |
| 1:7407 | Time/Bay Container | 277.58,76 92.42x14 | VERTICAL | TechnicianMetaPill: 32h pill, full-width from Align | pill + full width vs plain 14h; no Bay | plain right-aligned text, no pill |
| 1:7408 | "10:42 AM · Bay 3" | 277.58,76 92.42x14 | #5E5D69 11/600 lh14 ls .44 | "10:42 UTC+4", labelMedium 12/16 w700 in pill | text, size, weight, tracking, fill; no Bay 3 | use exact copy/style; add bay slot |
| 1:7409 | Card 1 margin | 20,318 350x310 | VERTICAL pad 0,0,20,0 | SizedBox height 16 after hero | 16 vs 20 | 20 |
| 1:7410 | Card 1 Vehicle Info | 20,318 350x290 | r32 fill #FFF, shadow 8/2 + 40/14, gap20 pad24 | AppCard r32 p24; card shadow token 0 2 8 #00000004 + 0 14 40 #0000000B | gap 16 vs 20; height content-driven | gap 20; content height |
| 1:7411 | Card 1 header row | 44,342 302x40 | HORIZONTAL gap 119.19, SpaceBetween | Row; max child AppIconButton 48h | 48 vs 40 high | 40h header |
| 1:7412 | Header left cluster | 44,342 150.81x40 | HORIZONTAL gap 12 | Row = title only | missing 40 badge + 12 gap | add icon badge |
| 1:7413 | Header icon Background | 44,342 40x40 | r9999 fill #F4F3F8 | Absent | missing | add 40x40 circle |
| 1:7414 | Header icon Container | 54.83,352.83 18.33x18.33 | VERTICAL | Absent | missing | add 18.33 icon box |
| 1:7415 | Header Icon | 54.83,352.83 18.33x18.33 | VECTOR fill #10B981 | Absent | missing | add green vehicle icon |
| 1:7416 | Heading 2 | 96,350 98.81x24 | VERTICAL | TechnicianSectionTitle | no icon offset; x44 not x96 | place after badge |
| 1:7417 | "Vehicle Info" | 96,350 98.81x24 | #1B1B25 18/700 lh24 ls -0.27 | "Vehicle info" titleLarge 16/22 w700 ls -0.16, #1A1B1F | 16/22 vs 18/24; tracking; case; fill | 18/24 w700 -0.27 #1B1B25 |
| 1:7418 | Copy Button | 314,346 32x32 | r9999 fill #F4F3F8 | AppIconButton 48x48, transparent | 48 vs 32; missing fill | 32x32 filled (#F4F3F8); keep 48 hit area |
| 1:7419 | Copy icon Container | 322.5,354.5 15x15 | VERTICAL | Icon 24 | 24 vs 15 | 15 |
| 1:7420 | Copy Icon | 322.5,354.5 15x15 | VECTOR fill #5E5D69 | Icons.copy_outlined 24, #006C49 | size + fill | 15 #5E5D69 |
| 1:7421 | Spec grid Container | 44,402 302x96 | GRID | 2 Rows, 16 gap, total 96 | grid vs rows: no visual delta | none |
| 1:7422 | Make cell | 44,402 143x40 | VERTICAL gap 4 | Column gap 2 | 2 vs 4 | gap 4 |
| 1:7423 | Make label Container | 44,402 143x14 | VERTICAL | labelMedium box | line 16 vs 14 | 14 line box |
| 1:7424 | "Make" | 44,402 143x14 | #5E5D69 11/600 lh14 ls .44 | labelMedium 12/16 w600 ls .24 | 12/16 vs 11/14; tracking | 11/14 .44 (B1 exception) |
| 1:7425 | Make value Container | 44,420 143x22 | VERTICAL | value titleLarge line 22 | match | none |
| 1:7426 | "Renault" | 44,420 143x22 | #1B1B25 16/700 lh22 ls -0.16 | titleLarge 16/22 w700 -0.16, #1A1B1F | fill 1 unit | #1B1B25 |
| 1:7427 | Model cell | 203,402 143x40 | VERTICAL gap 4 | second Expanded Column gap 2 | gap 2 vs 4 | gap 4 |
| 1:7428 | Model label Container | 203,402 143x14 | VERTICAL | labelMedium box | 16 vs 14 line | 14 |
| 1:7429 | "Model" | 203,402 143x14 | #5E5D69 11/600 lh14 ls .44 | labelMedium 12/16 w600 .24 | style | 11/14 .44 (B1 exception) |
| 1:7430 | Model value Container | 203,420 143x22 | VERTICAL | titleLarge line 22 | match | none |
| 1:7431 | "Megane 3" | 203,420 143x22 | #1B1B25 16/700 lh22 -0.16 | titleLarge 16/22 w700 -0.16 #1A1B1F | fill 1 unit | #1B1B25 |
| 1:7432 | Year cell | 44,458 143x40 | VERTICAL gap 4 | Column gap 2 | gap | gap 4 |
| 1:7433 | Year label Container | 44,458 143x14 | VERTICAL | labelMedium box | 16 vs 14 line | 14 |
| 1:7434 | "Year" | 44,458 143x14 | #5E5D69 11/600 lh14 .44 | labelMedium 12/16 w600 .24 | style | 11/14 .44 (B1 exception) |
| 1:7435 | Year value Container | 44,476 143x22 | VERTICAL | titleLarge line 22 | match | none |
| 1:7436 | "2021" | 44,476 143x22 | #1B1B25 16/700 lh22 -0.16 | titleLarge 16/22 w700 -0.16 #1A1B1F | fill 1 unit | #1B1B25 |
| 1:7437 | Odometer cell | 203,458 143x40 | VERTICAL gap 4 | Column gap 2 | gap | gap 4 |
| 1:7438 | Odometer label Container | 203,458 143x14 | VERTICAL | labelMedium box | 16 vs 14 line | 14 |
| 1:7439 | "Odometer" | 203,458 143x14 | #5E5D69 11/600 lh14 .44 | labelMedium 12/16 w600 .24 | style | 11/14 .44 (B1 exception) |
| 1:7440 | Odometer value Container | 203,476 143x22 | VERTICAL | titleLarge line 22 | match | none |
| 1:7441 | "34,180 mi" | 203,476 143x22 | #1B1B25 16/700 lh22 -0.16 | "34,180 MI", titleLarge 16/22 w700 -0.16 | unit uppercased; fill | lower-case unit; #1B1B25 |
| 1:7442 | VIN Item | 44,518 302x66 | fill #F4F3F8 gap 88.83 SpaceBetween pad 16,14,14,14 | Container fill #F4F3F8, radius 12, pad 12; VIN + Plate columns | pad 12 vs 16/14; radius 12 vs 0; extra Plate; height | single VIN slot, pad 16/14, no radius |
| 1:7443 | VIN text Container | 58,535 149.17x34 | VERTICAL gap 2 pad 0,8,0,0 | TechnicianLabeledValue gap 2 | missing right pad 8 | pad right 8 |
| 1:7444 | VIN label Container | 58,535 141.17x14 | VERTICAL | labelMedium box | 16 vs 14 line | 14 |
| 1:7445 | "VIN / Chassis" | 58,535 74.44x14 | #5E5D69 11/600 lh14 .44 | "VIN" labelMedium 12/16 w600 .24 | copy + style | "VIN / Chassis", 11/14 .44 |
| 1:7446 | VIN value Container | 58,551 141.17x18 | VERTICAL | titleLarge line 22 | 22 vs 18 | 18 |
| 1:7447 | "VF1KZ040647192831" | 58,551 141.17x18 | #1B1B25 13/600 lh18 ls .65 | titleLarge 16/22 w700 -0.16, wraps to 2 lines | 16/22 vs 13/18; tracking; wrap | 13/18 w600 .65, no wrap |
| 1:7448 | Button - Copy VIN | 296,534 36x36 | r9999 fill #FFF, shadow 8/2 | header AppIconButton 48x48, transparent, no shadow | position, 48 vs 36, fill/shadow | move to VIN row; 36 white + shadow |
| 1:7449 | Copy Container | 307.63,544.5 12.75x15 | VERTICAL | Icon 24 | 24 vs 12.75x15 | 12.75x15 |
| 1:7450 | Copy Icon | 307.63,544.5 12.75x15 | VECTOR fill #5E5D69 | Icons.copy_outlined 24 #006C49 | size + fill | 12.75x15 #5E5D69 |
| 1:7451 | Card 2 margin | 20,628 350x296 | VERTICAL pad 0,0,20,0 | SizedBox height 16 | 16 vs 20 | 20 |
| 1:7452 | Card 2 Customer Info | 20,628 350x276 | r32 fill #FFF, shadow 8/2 + 40/14, gap20 pad24 | AppCard r32 p24; shadow token matches | height content-driven; missing rows; gap 12/16 | add content; gap 20 |
| 1:7453 | Card 2 header row | 44,652 302x40 | HORIZONTAL gap 24.15 SpaceBetween | title row 22h, no badge | 22 vs 40; missing badge/role | 40h header |
| 1:7454 | Header left cluster | 44,652 173.48x40 | HORIZONTAL gap 12 | Row = title only | missing badge + gap | add 40 badge + 12 |
| 1:7455 | Header icon Background | 44,652 40x40 | r9999 fill #F4F3F8 | Absent | missing | add 40x40 circle |
| 1:7456 | Header icon Container | 54.83,662.83 18.33x18.33 | VERTICAL | Absent | missing | add |
| 1:7457 | Header Icon | 54.83,662.83 18.33x18.33 | VECTOR fill #10B981 | Absent | missing | add green customer icon |
| 1:7458 | Heading 2 | 96,660 121.48x24 | VERTICAL | TechnicianSectionTitle | no badge offset | place after badge |
| 1:7459 | "Customer Info" | 96,660 121.48x24 | #1B1B25 18/700 lh24 -0.27 | "Customer info" titleLarge 16/22 w700 -0.16 | 16/22 vs 18/24; case; fill | 18/24 w700 -0.27 #1B1B25 |
| 1:7460 | Primary Owner Background | 241.62,661 104.38x22 | r9999 fill #F4F3F8 pad 4,10,4,10 | Absent | missing | add role pill |
| 1:7461 | "Primary Owner" | 251.62,665 84.38x14 | #5E5D69 11/600 lh14 .44 | Absent | missing | add 11/14 w600 |
| 1:7462 | Card 2 body Container | 44,712 302x168 | VERTICAL gap 16 | Customer Column gap 16 then 12 | 12 vs 16 | gap 16 |
| 1:7463 | Full name field | 44,712 302x40 | VERTICAL gap 4 | TechnicianLabeledValue gap 2 | 2 vs 4 | gap 4 |
| 1:7464 | Full name label Container | 44,712 302x14 | VERTICAL | labelMedium box | 16 vs 14 | 14 |
| 1:7465 | "Full Name" | 44,712 302x14 | #5E5D69 11/600 lh14 .44 | "Customer name" labelMedium 12/16 .24 | copy + style | "Full Name", 11/14 .44 |
| 1:7466 | Full name value Container | 44,730 302x22 | VERTICAL | titleLarge line 22 | match | none |
| 1:7467 | "Arthur Pendelton" | 44,730 302x22 | #1B1B25 16/700 lh22 -0.16 | emphasized titleLarge 16/22 w700 -0.16 #1A1B1F | fill 1 unit | #1B1B25 |
| 1:7468 | Phone row | 44,768 302x46 | HORIZONTAL gap 81.09 pad 4,0,0,0 | No row; label+value only | missing row + actions | add phone row |
| 1:7469 | Phone left Container | 44,772 132.91x42 | VERTICAL gap 4 | TechnicianLabeledValue, full 302 width | width + gap | constrain + gap 4 |
| 1:7470 | Phone label Container | 44,772 132.91x14 | VERTICAL | labelMedium box | 16 vs 14 | 14 |
| 1:7471 | "Phone Number" | 44,772 83.92x14 | #5E5D69 11/600 lh14 .44 | "Phone" labelMedium 12/16 .24 | copy + style | "Phone Number", 11/14 .44 |
| 1:7472 | Phone value Container | 44,790 132.91x24 | VERTICAL | bodyLarge line 24 | match height | none |
| 1:7473 | "+44 7700 900077" | 44,790 132.91x24 | #1B1B25 16/600 lh24 ls -0.4 | bodyLarge 16/24 w500 -0.16 #1A1B1F | weight, tracking, fill | 16/24 w600 -0.4 #1B1B25 |
| 1:7474 | Phone actions Container | 258,773 88x40 | HORIZONTAL gap 8 | Absent | missing | add 2 x 40 buttons, gap 8 |
| 1:7475 | Link - Call customer | 258,773 40x40 | r9999 fill #F4F3F8 | Absent | missing | add call button |
| 1:7476 | Call icon Container | 270.88,785.88 14.25x14.25 | VERTICAL | Absent | missing | add 14.25 |
| 1:7477 | Call Icon | 270.88,785.88 14.25x14.25 | VECTOR fill #1B1B25 | Absent | missing | add phone icon |
| 1:7478 | Link - Message customer | 306,773 40x40 | r9999 fill #F4F3F8 | Absent | missing | add message button |
| 1:7479 | Message icon Container | 318.08,785.08 15.83x15.83 | VERTICAL | Absent | missing | add 15.83 |
| 1:7480 | Message Icon | 318.08,785.08 15.83x15.83 | VECTOR fill #1B1B25 | Absent | missing | add message icon |
| 1:7481 | Service package Container | 44,830 302x50 | VERTICAL gap 4 pad 12,0,0,0 | Absent (separate _TemplateCard instead) | missing; extra template card | add inside Customer Info |
| 1:7482 | Service label Container | 44,842 302x14 | VERTICAL | Absent | missing | add 14 line |
| 1:7483 | "Service Package" | 44,842 302x14 | #5E5D69 11/600 lh14 .44 | Absent ("Inspection template" is separate) | missing copy/style | add 11/14 w600 |
| 1:7484 | Service value row | 44,860 302x20 | HORIZONTAL gap 24.86 | Absent | missing | add row |
| 1:7485 | Service value Container | 44,860 257.14x20 | VERTICAL | Absent | missing | add |
| 1:7486 | "Comprehensive Fleet Tier-1 Multi-Point" | 44,860 257.14x20 | #1A1B1F 14/500 lh20 -0.07 | Absent; template value is titleLarge 16/22 w700 | missing | add 14/20 w500 -0.07 |
| 1:7487 | Service icon Container | 327.67,861.25 18.33x17.5 | VERTICAL | Absent | missing | add |
| 1:7488 | Service Icon | 327.67,861.25 18.33x17.5 | VECTOR fill #10B981 | Absent | missing | add verified icon |
| 1:7489 | Intake Checklist Snapshot | 20,924 350x76 | r32 fill #FFF, shadow 8/2 + 40/14, gap37.77 pad20 | Absent | entire card missing | add card |
| 1:7490 | Snapshot left Container | 40,944 210.45x36 | HORIZONTAL gap 12 | Absent | missing | add |
| 1:7491 | Snapshot check Overlay | 40,946 32x32 | r9999 fill #6FFBBE4D | Absent | missing | add 32x32 |
| 1:7492 | Check icon Container | 48.5,956.35 15x11.31 | VERTICAL | Absent | missing | add |
| 1:7493 | Check Icon | 48.5,956.35 15x11.31 | VECTOR fill #10B981 | Absent | missing | add check icon |
| 1:7494 | Snapshot text Container | 84,944 166.45x36 | VERTICAL | Absent | missing | add |
| 1:7495 | Title Container | 84,944 166.45x18 | VERTICAL | Absent | missing | add |
| 1:7496 | "Pre-Inspection Ready" | 84,944 146.7x18 | #1B1B25 14/700 lh18 -0.14 | Absent | missing | add 14/18 w700 |
| 1:7497 | Subtitle Container | 84,962 166.45x18 | VERTICAL | Absent | missing | add |
| 1:7498 | "Keys received · Fuel at 70%" | 84,962 166.45x18 | #5E5D69 13/400 lh18 ls 0 | Absent | missing | add 13/18 w400 slot |
| 1:7499 | Step Container | 288.22,954 61.78x16 | VERTICAL | Absent | missing | add |
| 1:7500 | "Step 1 of 4" | 288.22,954 61.78x16 | #10B981 12/600 lh16 ls .24 | Absent | missing | add 12/16 w600 |
| 1:7501 | Hero margin | 20,118 350x200 | VERTICAL pad 0,0,24,0 | SizedBox height 16 after hero | 16 vs 24 | 24 |
| 1:7502 | Vehicle Visual Snippet Banner | 20,118 350x176 | r32 fill #FFF, shadow 8/2 + 40/14 | Container 350x176 r32 fill #F4F3F8, no shadow | fill + shadow | #FFF + card shadow |
| 1:7503 | Vehicle photo frame | 20,118 350x176 | fill IMAGE | TechnicianVehicleSilhouette on #F4F3F8 | no photo | add hero image slot |
| 1:7504 | Hero gradient Background | 20,118 350x176 | GRADIENT_LINEAR pad16 | Absent | missing gradient | add linear gradient overlay |
| 1:7505 | Hero bottom row | 36,231 318x47 | HORIZONTAL gap147.22 SpaceBetween | Stack, bottom-left pill only | missing left block + scan button | add row |
| 1:7506 | Hero left Container | 36,231 134.78x47 | VERTICAL gap4 pad 3,0,0,0 | One TechnicianMetaPill "Hatchback" 32h | wrong content; missing REG/model | add REG + model block |
| 1:7507 | REG Overlay | 36,234 99.69x18 | r9999 fill #FFFFFFE5 blur24 pad 2,10,2,10 | Absent | missing | add blurred white pill |
| 1:7508 | "REG: LV71 XZP" | 46,236 79.69x14 | #1A1B1F 11/600 lh14 .44 | Plate rendered in VIN strip at 16/22 | wrong location + style | add 11/14 REG slot |
| 1:7509 | Model Shadow Container | 36,256 134.78x22 | shadow 2/1 | Absent | missing | add text shadow |
| 1:7510 | "Renault Megane 3" | 36,256 134.78x22 | #FFFFFF 16/700 lh22 -0.16 | Absent | missing | add white 16/22 w700 |
| 1:7511 | Scan Overlay | 318,236.5 36x36 | r9999 fill #FFFFFFE5, shadow 2/1, blur24 | Absent | missing scan action | add 36x36 button |
| 1:7512 | Scan icon Container | 328.5,247.83 15x13.33 | VERTICAL | Absent | missing | add 15x13.33 |
| 1:7513 | Scan Icon | 328.5,247.83 15x13.33 | VECTOR fill #1A1B1F | Absent; copy icon exists elsewhere | missing scan glyph | add scan icon #1A1B1F |
| 1:7514 | Sticky bottom Container | 0,1048 390x80 | fill #FFFFFFE5, shadow 30/-10, blur48, pad 12,20,12,20 | SafeArea + Container, opaque surface, pad 12/20, no shadow | alpha/blur/shadow missing | translucent + blur + shadow |
| 1:7515 | Start Inspection Button | 20,1060 350x56 | r9999 fill #10B981, shadow 25/10 | AppButton large expand 350x56 pill, fill #059669, buttonSubtle shadow | fill + shadow | #10B981 + 0 10 25 #10B9814D |
| 1:7516 | CTA label Container | 130.81,1079 107.05x18 | VERTICAL | Row icon+label | structure close | none |
| 1:7517 | "Start Inspection" | 130.81,1079 107.05x18 | #FFFFFF 14/700 lh18 -0.14 center | "Start inspection", largeButton 19/24 w700 -0.19 | size, tracking, case | 14/18 w700 -0.14, title case |
| 1:7518 | CTA icon Container | 245.86,1081.33 13.33x13.33 | VERTICAL | Icon 24 | 24 vs 13.33 | 13.33 |
| 1:7519 | CTA Icon | 245.86,1081.33 13.33x13.33 | VECTOR fill #FFFFFF | Icons.play_arrow 24 #FFFFFF | glyph + size | arrow icon 13.33 |
| 1:7520 | Header | 0,0 390x64 | fill #FFFFFFCC, shadow 8/1, blur48 | AppBar 390x64, surface #FFFFFF opaque, elevation 0 | alpha, blur, shadow | #FFFFFFCC + blur + shadow |
| 1:7521 | Header Container | 0,0 390x64 | HORIZONTAL gap17.53 pad 0,16,0,16 SpaceBetween | AppBar titleSpacing 20, leadingWidth 64, action end 12 | horizontal padding 20 vs 16; gap | pad 16; gap 17.53 |
| 1:7522 | Leading/title Container | 16,10 308.47x44 | HORIZONTAL gap4 | leading + title | gap/leading size differ | 44 back slot, gap 4 |
| 1:7523 | Button - Go back | 16,10 44x44 | r9999, no fill | BackButton in 64-wide leading slot | not 44 pill | 44x44 back target |
| 1:7524 | Back icon Container | 32.11,22 11.77x20 | VERTICAL | BackButton icon box | size differs | 11.77x20 |
| 1:7525 | Back Icon | 32.11,22 11.77x20 | VECTOR fill #1A1B1F | Icons.arrow_back 24, #1A1B1F | glyph + size | chevron 11.77x20 |
| 1:7526 | Heading 1 | 64,20 260.47x24 | VERTICAL pad 0,0,0,4 | AppBar title Text | no 4 bottom pad | add 4 bottom pad |
| 1:7527 | "Vehicle Walkaround Inspection" | 68,20 256.47x24 | #1A1B1F 18/700 lh24 ls -0.45 | "Job intake", headlineMedium 18/24 w700 -0.27 | copy + tracking; x68 vs x64 | use exact copy/style |
| 1:7528 | Profile Background | 342,16 32x32 | r9999 fill #006C49 | TechnicianAvatar 40x40, fill #D9FBE8, initials "DV" | 40 vs 32; fill; text vs icon | 32x32 deep green profile |
| 1:7529 | Profile icon Container | 352,26 12x12 | VERTICAL | initials Text | no icon container | add 12x12 icon |
| 1:7530 | Profile Icon | 352,26 12x12 | VECTOR fill #FFFFFF | Initials text, no icon | missing icon | add white profile icon 12x12 |

## Structural fixes

1. Replace the top `Wrap` with the Figma row: `INTAKE PHASE` chip, `Ready for Check` success pill, then right-aligned `10:42 AM · Bay 3`. Remove `Assigned` / `Versions 1` from this row. Do not use `TechnicianMetaPill` here: its `Container(alignment: center)` expands to full width in the current render.
2. Rebuild the hero: photo slot (1:7503), linear gradient (1:7504), REG pill + white model title + 36 px scan button (1:7505-7513), white card fill and card shadow. Remove the `Hatchback` pill and silhouette-only treatment.
3. Vehicle Info header: add 40x40 `#F4F3F8` icon badge, 12 gap, 18/24 heading, 32x32 `#F4F3F8` copy button. Move copy into the VIN strip as a 36x36 white shadowed button; remove the `Plate` column from the VIN strip (REG belongs in the hero).
4. Customer Info header: add 40x40 badge, 18/24 heading, `Primary Owner` pill. Add phone actions row (call/message 40x40) and the Service Package row + verified icon. Remove or merge the separate `_TemplateCard`; Figma has no `Inspection template` / `Scope` card.
5. Add the `Intake Checklist Snapshot` card (1:7489-7500) between Customer Info and the sticky action.
6. Remove the non-Figma `Details` action block (edit customer / vehicle / consent / equipment and start hint) from the Figma-fidelity view, or keep it outside the audited screen.
7. Correct block gaps: header top 8 / bottom 24, hero margin bottom 24, card margins bottom 20; the current implementation uses 16 between all blocks.
8. Sticky action and header need the Figma translucent + blur + shadow treatment; profile becomes 32x32 deep green with a white glyph.

## Type / fill / shadow fixes

| Element | Figma | Current | Fix |
|---|---|---|---|
| Section heading | 18/24 w700 -0.27 #1B1B25 | 16/22 w700 -0.16 #1A1B1F | 18/24, -0.27, #1B1B25 |
| Field labels | 11/14 w600 .44 #5E5D69 | 12/16 w600 .24 | 11/14 .44; needs B1 exception |
| Card value text | 16/22 w700 -0.16 #1B1B25 | 16/22 w700 -0.16 #1A1B1F | local #1B1B25 |
| VIN value | 13/18 w600 .65 | 16/22 w700 -0.16 | 13/18 w600 .65 |
| VIN label | "VIN / Chassis" 11/14 | "VIN" 12/16 | exact copy + style |
| Phone value | 16/24 w600 -0.4 #1B1B25 | 16/24 w500 -0.16 #1A1B1F | weight, tracking, fill |
| Odometer | "34,180 mi" | "34,180 MI" | lower-case unit |
| Service package | 14/20 w500 -0.07 #1A1B1F | absent (template 16/22 w700) | add exact style |
| Snapshot subtitle | 13/18 w400 ls0 | absent | add exact style |
| App-bar title | 18/24 w700 -0.45 | 18/24 w700 -0.27 | tracking -0.45 |
| Sticky CTA label | 14/18 w700 -0.14 #FFF | 19/24 w700 -0.19 | exact label style |
| Sticky CTA fill/shadow | #10B981, 0 10 25 #10B9814D | #059669, buttonSubtle only | use emerald fill + buttonEmerald |
| Chips | 22h, 11/14 w600 | 28h, 12/16 w600 | 22h + 11/14 (B1 exception) |
| Hero/copy/sticky shadows | card 8/2 + 40/14; copy 8/2; sticky 30/-10; CTA 25/10 | card only | add missing shadows |
| Translucent chrome | header #FFFFFFCC, sticky #FFFFFFE5, blur 48 | opaque #FFFFFF, no blur | alpha + BackdropFilter |

**B1 note:** the dump uses 11 px captions and 13 px body; the product token floor is 12 px (approved deviation B1). The 11/13 px fixes above require a B1 exception or an exact-variant `FigmaType` path.

## Slot-sheet items

| Item | Figma node(s) | Figma spec | Current | Required fix |
|---|---|---|---|---|
| Vehicle hero photo | 1:7502-7504 | 350x176 image + gradient, r32, card shadow | Generic silhouette, #F4F3F8, no shadow | Add photo/gradient slot |
| REG plate | 1:7507-7508 | 99.69x18 #FFFFFFE5 blur24, "REG: LV71 XZP" 11/14 #1A1B1F | Plate shown in VIN strip 16/22; no hero REG | Add hero REG slot; remove duplicate |
| INTAKE PHASE | 1:7402-7403 | 103.67x22 #F4F3F8, 11/14 .275 #5E5D69 | Absent ("Assigned") | Add label slot |
| Ready for Check | 1:7404-7406 | 130x22 #6FFBBE33, 6 dot #10B981, 11/14 #00422B | Absent (info chip "Assigned") | Add status slot mapped from job status |
| Bay 3 | 1:7407-7408 | plain text 92.42x14, 11/14 .44 #5E5D69 | "10:42 UTC+4" full-width pill; no bay | Add bay field; plain text |
| Primary Owner | 1:7460-7461 | 104.38x22 #F4F3F8, 11/14 .44 | Absent | Add owner-role slot |
| Call/message buttons | 1:7474-7480 | 40x40 #F4F3F8, gap 8, icons 14.25/15.83 #1B1B25 | Absent | Add tel/sms actions |
| Scan icon | 1:7511-7513 | 36x36 #FFFFFFE5, blur24 + shadow, 15x13.33 #1A1B1F | Absent; copy icon is in card header | Add hero scan action |
| "Keys received · Fuel at 70%" | 1:7498 | 13/18 w400 #5E5D69 | Absent | Add keys/fuel slot in snapshot |
| "Step 1 of 4" | 1:7499-7500 | 12/16 w600 .24 #10B981 | Absent | Add progress slot |

## Could not verify

- **Shadow colours:** the dump gives only geometry (`8/2`, `40/14`, `25/10`, `30/-10`, `8/1`, `2/1`); JSON effects have `color: null` for header, cards, hero, copy, scan and CTA. Card-token colour match is from `tokens.g.dart`, not this dump.
- **Gradient:** node 1:7504 says only `GRADIENT_LINEAR`; stops, angle and colours are absent, so the exact hero fade cannot be verified.
- **Hero image:** node 1:7503 is `fill=IMAGE` with an opaque URL hash; no asset, crop or focal point is in the dump.
- **Icon glyphs:** VECTOR nodes expose only box and fill; paths/glyph names are absent. Vehicle, copy, scan, phone, message, check, shield and profile glyph identity is inferred from node names/context.
- **Slot data:** `Bay 3`, fuel 70%, step 1 of 4, Primary Owner and Service Package have no fields in `TechnicianJob`; source/formatting cannot be verified.
- **Exact card heights:** Figma fixes 290/276/176/76; current cards are content-driven and the 1.0x screenshot has different wraps (VIN, pills), so post-fix heights are not measurable here.
- **Pixel-level glyph/wrap differences:** not measured at 1.0x; no 2x current capture or SSIM harness output is provided for this screen.
