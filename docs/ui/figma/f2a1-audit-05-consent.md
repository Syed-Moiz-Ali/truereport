# F2A1 Fidelity Audit — Screen 5: Consent & Signatures

Sources: `docs/ui/figma/f2a1-nodes/05-consent.txt` (node dump, primary), `consent_view.dart`, `job_detail_page.dart`, `design_system` tokens/components, `consent_en_1.0x.png`.
Legend: PJS = Plus Jakarta Sans. `absent` = no equivalent in the current ConsentView. `—` = node has no style property in the dump. Boxes are the dump's absolute `x,y w×h` at 390 wide.
Current view is rendered inside `showAppBottomSheet` (16px side padding, drag handle, max width 390), not as the Figma full page.

| Node id | Name | Figma box | Figma style | Current Flutter value | Delta | Required fix |
|---|---|---|---|---|---|---|
| 1:7531 | 5. Consent & Signatures | 0,0 390×972 | fill #FFFFFF, VERTICAL, gap 0, pad 0 | Bottom-sheet surface (#FFFFFF), not a 390×972 page | Sheet, not page | Confirm sheet is intended; otherwise full-screen route |
| 1:7532 | Main | 0,0 390×972 | fill #FFFFFF, VERTICAL, gap 0, pad 64,0,0,0 | Sheet body, no 64 top offset | Top offset/header missing | Add page header/top inset if full page |
| 1:7533 | Container | 0,64 390×908 | VERTICAL, gap 0, pad 0,0,32,0 | Sheet scroll content; bottom pad 24 | Bottom 24 vs 32 | Set bottom padding 32 |
| 1:7534 | Container (intro block) | 0,64 390×144 | VERTICAL, gap 4, pad 12,20,24,20 | Column block; side pad 16 | Side 16 vs 20; pad-top 0 vs 12; gaps 8/24 | Use 20 side padding and 12 top |
| 1:7535 | Margin | 20,76 350×28 | VERTICAL, gap 0, pad 0,0,4,0 | absent | Missing step row | Add STEP row block |
| 1:7536 | Container | 20,76 350×24 | HORIZONTAL, gap 8 | absent | Missing | Add step row |
| 1:7537 | Overlay | 20,76 24×24 | r 9999, fill #10B98126 (15% emerald) | absent | Missing | Add 24px circular check overlay |
| 1:7538 | Container | 27,81.75 10×12.5 | VERTICAL, gap 0 | absent | Missing | Add icon slot |
| 1:7539 | Icon | 27,81.75 10×12.5 | VECTOR, fill #10B981 | absent | Missing; glyph unverifiable | Add 10×12.5 emerald check glyph |
| 1:7540 | Container | 52,80 185.48×16 | VERTICAL, gap 0 | absent | Missing | Add step-label slot |
| 1:7541 | Text | 52,80 185.48×16 | “STEP 4 OF 4 • FINAL SIGN-OFF”, PJS SemiBold 12/600, lh 16, ls 0.3, #5E5D69 | absent | Missing (labelSm style exists) | Add label with labelSm style; copy is a slot |
| 1:7542 | Heading 2 | 20,108 350×32 | VERTICAL, gap 0 | Heading present | Container matches conceptually | — |
| 1:7543 | Authorizations | 20,108 350×32 | PJS ExtraBold 26/800, lh 32, ls −0.65, #1A1B1F | Text “Consent”, displayMedium → 26/32/800/−0.65, onSurface | Style matches; copy and 20/16 x differ | Change copy to “Authorizations”; use 20px side inset |
| 1:7544 | Container | 20,144 350×40 | VERTICAL, gap 0 | Intro Text present | — | — |
| 1:7545 | Text | 20,144 350×40 | “Review compliance permissions and provide\ncustomer digital sign-off.”, PJS Medium 14/500, lh 20, ls −0.07, #5E5D69 | bodyMedium 14/20/500/−0.07, onSurfaceVariant; copy = “Choose each consent separately…” | Style matches; copy differs | Replace with Figma copy (slot) |
| 1:7546 | Container (cards+signature) | 0,208 390×732 | VERTICAL, gap 16, pad 0,20,0,20 | Column, card gap 12, no signature block | Gap 12 vs 16; signature missing | Set card gap 16 and add signature block |
| 1:7547 | Card 1: PDF Sharing | 20,208 350×80 | r 32, fill #FFFFFF, shadow 8/0,2 + 40/0,14, HORIZONTAL, pad 20 | AppCard raised, r 32, #FFFFFF, `shadows.card` (8@0,2 + 40@0,14), pad 20 | Geometry/fill/shadow match; content differs | Keep shell; fix content |
| 1:7548 | Container (card row) | 40,228 252.86×40 | HORIZONTAL, gap 14, pad 0,12,0,0 | Row gap 12, no 12 top pad | Gap −2; pad missing | Use gap 14 and top pad 12 |
| 1:7549 | Background (icon tile) | 40,228 40×40 | r 9999 (circle), fill #F4F3F8 | 32×32, r 12, fill surfaceContainer #F4F3F8 | −8 size; r12 vs circle | 40×40, r 9999 |
| 1:7550 | Container (icon) | 51.67,239.67 16.67×16.67 | VERTICAL, gap 0 | Icon box 20×20 | +3.33 | 16.67×16.67 |
| 1:7551 | Icon | 51.67,239.67 16.67×16.67 | VECTOR, fill #1A1B1F | `Icons.fact_check_outlined`, 20, brand.ink #006C49 | Size +3.33; color wrong; glyph unknown | Size 16.67, color onSurface; verify glyph |
| 1:7552 | Container (text) | 94,228 186.86×40 | VERTICAL, gap 0 | Expanded Column | Flex differs from fixed 186.86 | Acceptable flex, or constrain width |
| 1:7553 | Container (title) | 94,228 186.86×22 | VERTICAL, gap 0 | Title Text | — | — |
| 1:7554 | Text “Allow PDF sharing” | 94,228 135.36×22 | PJS Bold 16/700, lh 22, ls −0.16, #1A1B1F | titleLarge 16/22/700/−0.16, onSurface; copy “Processing consent” | Style matches; copy slot | Apply product copy for PROCESSING |
| 1:7555 | Container (body) | 94,250 186.86×18 | VERTICAL, gap 0 | Body Text | — | — |
| 1:7556 | Body | 94,250 186.86×18 | PJS Regular 13/400, lh 18, ls 0, #5E5D69 | bodyMedium 14/20/500/−0.07, onSurfaceVariant | Size +1, weight 500 vs 400, lh 20 vs 18 | Add/use 13/400 lh18 (no exact token) |
| 1:7557 | Switch | 298,232 52×32 | r 9999, fill #10B981, pad 4,4,4,24 | Radio icon 24, selected brand.ink | 24 icon vs 52×32 switch | Replace radio with 52×32 switch |
| 1:7558 | Knob | 322,236 24×24 | r 9999, #FFFFFF, shadow 6/0,2 | absent (radio glyph) | Missing knob | Add 24px white knob + shadow |
| 1:7559 | Card 2: Road Test Consent | 20,304 350×80 | r 32, #FFFFFF, shadow 8/0,2 + 40/0,14, pad 20 | AppCard raised, same shell | Shell matches; content differs | Keep shell; fix content |
| 1:7560 | Container | 40,324 256.13×40 | HORIZONTAL, gap 14, pad 0,12,0,0 | Row gap 12, no top pad | Gap −2; pad missing | gap 14, top pad 12 |
| 1:7561 | Background | 40,324 40×40 | r 9999, #F4F3F8 | 32×32, r 12, #F4F3F8 | −8; r12 vs circle | 40×40, r 9999 |
| 1:7562 | Container | 52.5,337.33 15×13.33 | VERTICAL, gap 0 | 20×20 icon box | Size | 15×13.33 |
| 1:7563 | Icon | 52.5,337.33 15×13.33 | VECTOR, fill #1A1B1F | `Icons.link`, 20, #006C49 | Size/color; glyph unknown | 15×13.33, onSurface |
| 1:7564 | Container | 94,324 190.13×40 | VERTICAL, gap 0 | Expanded Column | Flex vs fixed | Accept or constrain |
| 1:7565 | Container (title) | 94,324 190.13×22 | VERTICAL, gap 0 | Title Text | — | — |
| 1:7566 | Text “Customer road test consent” | 94,324 183.02×22 | PJS 16/700, lh 22, ls −0.16, #1A1B1F | titleLarge 16/22/700/−0.16; copy “Public-link consent” | Style matches; copy slot | Copy for PUBLIC_LINK |
| 1:7567 | Container (body) | 94,346 190.13×18 | VERTICAL, gap 0 | Body Text | — | — |
| 1:7568 | Body | 94,346 190.13×18 | PJS 13/400, lh 18, ls 0, #5E5D69 | 14/20/500/−0.07 | Size/weight/lh | 13/400 lh18 |
| 1:7569 | Switch | 298,328 52×32 | r 9999, #10B981, pad 4,4,4,24 | Radio 24, selected brand.ink | switch vs radio | 52×32 switch |
| 1:7570 | Knob | 322,332 24×24 | r 9999, #FFFFFF, shadow 6/0,2 | absent | Missing | 24px knob + shadow |
| 1:7571 | Card 3: Data Storage Authorization | 20,400 350×80 | r 32, #FFFFFF, shadow 8/0,2 + 40/0,14, pad 20 | absent | Third card missing | Add third card or map/replace per product |
| 1:7572 | Container | 40,420 256.77×40 | HORIZONTAL, gap 14, pad 0,12,0,0 | absent | Missing | gap 14, top pad 12 |
| 1:7573 | Background | 40,420 40×40 | r 9999, #F4F3F8 | absent | Missing | 40×40 circle |
| 1:7574 | Container | 51.67,433.33 16.67×13.33 | VERTICAL, gap 0 | absent | Missing | 16.67×13.33 |
| 1:7575 | Icon | 51.67,433.33 16.67×13.33 | VECTOR, fill #1A1B1F | absent | Missing; glyph unknown | Add onSurface glyph |
| 1:7576 | Container | 94,420 190.77×40 | VERTICAL, gap 0 | absent | Missing | Add text column |
| 1:7577 | Container (title) | 94,420 190.77×22 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7578 | Text “Data storage authorization” | 94,420 190.66×22 | PJS 16/700, lh 22, ls −0.16, #1A1B1F | absent | Missing | Add title (or product copy) |
| 1:7579 | Container (body) | 94,442 190.77×18 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7580 | Body | 94,442 190.77×18 | PJS 13/400, lh 18, ls 0, #5E5D69 | absent | Missing | Add 13/400 body |
| 1:7581 | Switch (off) | 298,424 52×32 | r 9999, fill #E9E7ED, pad 4 | absent | Missing | Add off-state switch 52×32 |
| 1:7582 | Knob (off) | 302,428 24×24 | r 9999, #FFFFFF, shadow 6/0,2 | absent | Missing | Add 24px knob |
| 1:7583 | Digital Signature Section:margin | 20,496 350×256 | VERTICAL, gap 0, pad 16,0,0,0 | absent | Section missing | Add 16 top margin + section |
| 1:7584 | Digital Signature Section | 20,512 350×240 | no fill/radius listed | absent | Missing | Add section |
| 1:7585 | Margin (header) | 20,512 350×30 | VERTICAL, gap 0, pad 0,0,12,0 | absent | Missing | Add header + 12 bottom |
| 1:7586 | Container (header row) | 20,512 350×18 | HORIZONTAL, gap 11.63, pad 0,4,0,4 | absent | Missing | Add header row |
| 1:7587 | Container | 24,512 183.67×18 | HORIZONTAL, gap 6 | absent | Missing | — |
| 1:7588 | Container (title) | 24,512 109.94×18 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7589 | Text “Digital Signature” | 24,512 109.94×18 | PJS Bold 14/700, lh 18, ls −0.14, #1A1B1F | absent | Missing (labelLg matches) | Add labelLg title |
| 1:7590 | Overlay “Required” | 139.94,512 67.73×18 | r 9999, fill #10B9811A (10%), pad 2,8 | absent | Missing | Add 10% emerald badge |
| 1:7591 | Text “Required” | 147.94,514 51.73×14 | PJS SemiBold 11/600, lh 14, ls 0.44, #10B981 | absent | Missing (no 11px token) | Add 11/600 lh14 |
| 1:7592 | Container (hint) | 219.3,512 146.7×18 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7593 | Text “Sign with finger or stylus” | 219.3,512 146.7×18 | PJS Regular 13/400, lh 18, ls 0, #5E5D69 | absent | Missing | Add 13/400 hint |
| 1:7594 | Container (timestamp row) | 20,718 350×34 | HORIZONTAL, gap 98.57, pad 10,4,0,4 | absent | Missing | Add footer row |
| 1:7595 | Container | 24,731 175.38×18 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7596 | Text “Timestamp: Today, 14:38 EST” | 24,731 175.38×18 | PJS Regular 13/400, lh 18, ls 0, #5E5D69 | absent | Missing; sample time is slot | Add 13/400 dynamic timestamp |
| 1:7597 | Button “Clear” | 303.28,728 62.72×24 | HORIZONTAL, gap 4, pad 4,8 | absent | Missing | Add clear action |
| 1:7598 | Container (clear icon) | 311.28,733.85 10.67×12.3 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7599 | Icon (clear) | 311.28,733.85 10.67×12.3 | VECTOR, fill #5E5D69 | absent | Missing; glyph unknown | Add onSurfaceVariant icon |
| 1:7600 | Container (clear label) | 325.95,732 32.05×16 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7601 | Text “Clear” | 325.95,732 32.05×16 | PJS SemiBold 12/600, lh 16, ls 0.24, CENTER, #5E5D69 | absent | Missing (labelMd close: ls 0.24) | Add labelMd clear label |
| 1:7602 | Signature canvas | 20,542 350×176 | r 32, fill #F4F3F899 (60% #F4F3F8), shadow 8/0,2 + 40/0,14 | absent | Missing | Add 350×176 r32 canvas + shadow |
| 1:7603 | Baseline Guide | 52,677 286×1 | RECTANGLE, fill #E3E1EF | absent | Missing | Add 1px baseline (secondaryContainer) |
| 1:7604 | Container | 52,688 90.47×14 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7605 | Text “Sign Above Line” | 52,688 90.47×14 | PJS SemiBold 11/600, lh 14, ls 0.44, #1A1B1F | absent | Missing | Add 11/600 label |
| 1:7606 | Cursive Sample SVG Stroke (Interactive simulation) | 20,542 350×176 | FRAME overlay | absent | Missing; placeholder art | Implement real signature pad, not sample |
| 1:7607 | Vector (stroke) | 78.33,610.19 233.33×46.06 | stroke #1A1B1F, width 2.4306 | absent | Sample only | Replace with captured strokes |
| 1:7608 | Vector (stroke) | 141.53,643.14 77.78×3.39 | stroke #1A1B1F, width 1.9444 | absent | Sample only | Replace with captured strokes |
| 1:7609 | Verification Watermark Badge | 272.98,554 85.02×22 | r 9999, fill #FFFFFFE5 (90%), shadow 2/0,1 + background blur 8, pad 4,10 | absent | Missing | Add frosted “Recorded” badge |
| 1:7610 | Container (badge icon) | 282.98,560.13 10.29×9.75 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7611 | Icon (badge) | 282.98,560.13 10.29×9.75 | VECTOR, fill #10B981 | absent | Missing; glyph unknown | Add emerald icon |
| 1:7612 | Container (badge label) | 297.27,558 50.73×14 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7613 | Text “Recorded” | 297.27,558 50.73×14 | PJS SemiBold 11/600, lh 14, ls −0.275, #1A1B1F | absent | Missing; state slot | Add 11/600 recorded label |
| 1:7614 | Inspector & Customer Context Card:margin | 20,768 350×76 | VERTICAL, gap 0, pad 4,0,0,0 | absent | Missing | Add 4 top margin |
| 1:7615 | Inspector & Customer Context Card | 20,772 350×72 | r 32, #FFFFFF, shadow 8/0,2 + 40/0,14, pad 16 | absent | Missing | Add 350×72 r32 card |
| 1:7616 | Container (row) | 36,788 280.97×40 | HORIZONTAL, gap 12 | absent | Missing | Add avatar+text row |
| 1:7617 | Overlay (avatar) | 36,788 40×40 | r 9999, fill #10B98126, pad 8.5,0,9.5,0 | absent | Missing | Add 40px 15% emerald avatar |
| 1:7618 | Text “AL” | 46.11,796.5 19.77×22 | PJS Bold 16/700, lh 22, ls −0.16, #00422B, CENTER | absent | Missing; sample initials | Add onContainer initials from data |
| 1:7619 | Container (person) | 88,788 228.97×40 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7620 | Container (name) | 88,788 228.97×22 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7621 | Text “Alex Lindqvist” | 88,788 106.23×22 | PJS Bold 16/700, lh 22, ls −0.16, #1A1B1F | absent | Missing; sample person | Add name from job/customer |
| 1:7622 | Container (role) | 88,810 228.97×18 | VERTICAL, gap 0 | absent | Missing | — |
| 1:7623 | Text “Authorized Representative • VIN 4782” | 88,810 228.97×18 | PJS Regular 13/400, lh 18, ls 0, #5E5D69 | absent | Missing; sample role/VIN | Add role + VIN from job data |
| 1:7624 | Container (chevron) | 337.33,799.67 16.67×16.67 | VERTICAL, gap 0 | absent | Missing | Add chevron slot |
| 1:7625 | Icon (chevron) | 337.33,799.67 16.67×16.67 | VECTOR, fill #BBCABF | absent | Missing; glyph/color not tokenized | Add #BBCABF chevron |
| 1:7626 | Primary Action Button wrapper | 20,860 350×80 | VERTICAL, gap 0, pad 16,0,8,0 | AppButton directly in Column with 24 top gap | Wrapper/padding differs | Use 16 top / 8 bottom wrapper |
| 1:7627 | Button | 20,876 350×56 | r 9999, fill #10B981, shadow 25/0,10, HORIZONTAL, gap 8 | AppButton large+expand, height 56, pill, fill #059669 (`brand.largeFill`), `buttonSubtle` shadow; grey #E9E7ED when disabled | Fill, shadow, disabled state differ | Use #10B981 and emerald 25/0,10 shadow; enable when valid |
| 1:7628 | Container (btn icon) | 136.61,895.67 16.67×16.67 | VERTICAL, gap 0 | Icon box 24 | +7.33 | 16.67 |
| 1:7629 | Icon (btn) | 136.61,895.67 16.67×16.67 | VECTOR, fill #FFFFFF | `Icons.save_outlined`, 24, #FFFFFF | Size +7.33; glyph unknown | 16.67 icon; verify glyph |
| 1:7630 | Container (btn label) | 161.28,895 92.11×18 | VERTICAL, gap 0 | Label Flexible | — | — |
| 1:7631 | Text “Save Consent” | 161.28,895 92.11×18 | PJS Bold 14/700, lh 18, ls −0.14, #FFFFFF, CENTER | largeButton 19/24/700/−0.19, #FFFFFF | Size +5, lh +6 | Use labelLg 14/700 |
| 1:7632 | Header | 0,0 390×64 | fill #FFFFFFCC, shadow 8/0,1 + background blur 48 | Not in ConsentView; page `TechnicianAppBar` height 64 | Sheet has no header; page bar is opaque | Decide shell; if page, use 80% white + blur |
| 1:7633 | Container (header) | 0,0 390×64 | HORIZONTAL, gap 17.53, pad 0,16,0,16 | `TechnicianAppBar` titleSpacing 20 | Pad 20 vs 16 | Use 16 side padding |
| 1:7634 | Container (left group) | 16,10 308.47×44 | HORIZONTAL, gap 4 | BackButton + title | Approx only | Verify 44px group |
| 1:7635 | Button - Go back | 16,10 44×44 | r 9999 | BackButton | Size/radius unverified | 44×44 pill hit target |
| 1:7636 | Container (back icon) | 32.11,22 11.77×20 | VERTICAL, gap 0 | BackButton icon | Glyph/size differ | 11.77×20 back glyph |
| 1:7637 | Icon (back) | 32.11,22 11.77×20 | VECTOR, fill #1A1B1F | BackButton icon (onSurface) | Color matches; size unverified | Verify glyph size |
| 1:7638 | Heading 1 | 64,20 260.47×24 | VERTICAL, gap 0, pad 0,0,0,4 | AppBar title | Position differs | Align title after 44px button |
| 1:7639 | Text “Vehicle Walkaround Inspection” | 68,20 256.47×24 | PJS Bold 18/700, lh 24, ls −0.45, #1A1B1F | “Job intake”, headlineMedium 18/24/700/−0.27 | Copy + ls differ | Use Figma title/copy and ls −0.45 |
| 1:7640 | Background (avatar) | 342,16 32×32 | r 9999, fill #006C49 | absent (`job_detail_page` passes no profile) | Missing | Add 32px #006C49 avatar |
| 1:7641 | Container (avatar icon) | 352,26 12×12 | VERTICAL, gap 0 | absent | Missing | 12×12 |
| 1:7642 | Icon (avatar) | 352,26 12×12 | VECTOR, fill #FFFFFF | absent | Missing; glyph unknown | Add white 12px glyph |

## Structural fixes

- ConsentView is a modal bottom sheet; Figma is a 390×972 page with a 64px sticky header. Confirm which shell is intended and align (page header vs sheet).
- Missing entire node groups: step badge (1:7535–1:7541), third card (1:7571–1:7582), Digital Signature section (1:7583–1:7613), Inspector & Customer Context Card (1:7614–1:7625).
- Current adds a “Status / Not recorded yet / Granted / Refused” block (`TechnicianSectionTitle` + two `AppSelectableText` chips) that has no Figma node; remove or relocate it.
- Consent types: only `PROCESSING` and `PUBLIC_LINK` exist (`consent_view.dart:54,63`), while Figma shows three cards. Decide whether to map two types or add a third model value.
- Cards are tappable `AppCard`s with a trailing radio (`Icons.radio_button_*`), not 52×32 switches with 24px knobs.
- Content width: sheet side padding 16 → 358 wide; Figma uses 20 → 350. Card row gap 12 vs 16; heading/intro gaps 8/24 vs 4/24.
- Save action is disabled and grey until both a type and status are chosen; Figma shows an enabled emerald button. Confirm intended gating.
- Figma card 3 starts off (#E9E7ED) while cards 1–2 are on (#10B981); current has no default switch state.

## Type/fill/shadow fixes

- Card body: Figma 13/400 lh18 ls0; current bodyMedium 14/500 lh20 ls−0.07. No exact 13px token exists — add one or use a local override.
- Icons: tile glyphs are #1A1B1F at 15–16.67px; current 20px `brand.ink` #006C49.
- Icon tile: Figma 40×40 circle (r9999); current 32×32 r12.
- Save label: Figma labelLg 14/700/−0.14; current largeButton 19/700/−0.19.
- Save fill: Figma #10B981; current `brand.largeFill` #059669 (#059669 is `TrColorLight.primaryLarge`).
- Save shadow: Figma emerald 25/0,10; current `buttonSubtle` black pair.
- Disabled save: current surfaceContainerHighest #E9E7ED + onSurfaceVariant, not in Figma.
- 11px labels (“Required”, “Sign Above Line”, “Recorded”) have no token; labelSm is 12/16/600/0.3 and does not match the 11/14 values.
- Figma uses `#BBCABF` (chevron) and `#E3E1EF` (baseline); `#E3E1EF` = `secondaryContainer`, `#BBCABF` is untokenized.
- Card fill/shadow geometry matches `surfaceContainerLowest` + `shadows.card`; shadow colours are not stated in the dump, so only offsets/blur are verified.

## Slot-sheet items

- Three consent cards vs two real types: “Allow PDF sharing” (1:7547), “Customer road test consent” (1:7559), “Data storage authorization” (1:7571) vs `PROCESSING` / `PUBLIC_LINK` only.
- Sample signature stroke 1:7606–1:7608 is explicitly labelled “Subtle Cursive Sample SVG Stroke (Interactive simulation)” — placeholder, not a captured signature.
- “Recorded” badge 1:7609–1:7613 represents a completed/verified state not modelled by ConsentView.
- “Timestamp: Today, 14:38 EST” 1:7596 is a hardcoded sample time/timezone; must come from the consent record/device.
- “Alex Lindqvist / Authorized Representative • VIN 4782” 1:7615–1:7623 is sample person/role/VIN; must come from job/customer data.
- “STEP 4 OF 4 • FINAL SIGN-OFF” 1:7541 is workflow-position copy; verify the product’s step count/name.
- “Required” badge 1:7590–1:7591 encodes a signature-requirement policy decision.
- Card 3 default-off switch 1:7581 encodes a third consent default, not present in the model.

## Could not verify

- Exact vector glyphs for all `Icon`/`Vector` nodes (1:7539, 1:7551, 1:7563, 1:7575, 1:7599, 1:7611, 1:7625, 1:7629, 1:7637, 1:7642): the dump gives no asset/component id.
- Exact drop-shadow colours: dump lists only blur/offset (e.g. `DROP_SHADOW(8 0,2)`), no colour/alpha; token colours are assumed.
- Per-node rendered geometry/text widths in Flutter at 1.0x (render is 390-wide but sheet is scrollable and Form-localized); deltas above use source tokens, not measured pixels.
- Whether the Figma header is in scope at all, since the current invocation is a bottom sheet over `job_detail_page` (`TechnicianAppBar` “Job intake”).
- Arabic/RTL rendering and dynamic type scaling for this screen.
- Real switch binding/state persistence; current selection is a nullable local `bool`.
