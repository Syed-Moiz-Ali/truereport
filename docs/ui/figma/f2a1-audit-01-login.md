# F2A1 Audit — Screen 1: Login & Language Selection

Sources: Figma node dump `docs/ui/figma/f2a1-nodes/01-login.txt` (boxes and styles quoted exactly); implementation `client/packages/auth/lib/src/sign_in_view.dart`; design tokens `tokens.g.dart`, `tokens.dart`, `inputs.dart`, `buttons.dart`, `chips.dart`, `technician_shell.dart`. Current boxes marked **meas.** were pixel-scanned from `docs/ui/figma/f2a-screenshots/login_en_1.0x.png` (390×858) at exact-fill colours; anti-aliasing can move an edge by 1 px. No Figma pixel measurement was used for boxes; the Figma preview (780×1716) was sampled only to confirm that the field fill is `#FFFFFF`.

Conventions: Figma coordinates are frame-absolute as printed. `pad` is read as top,right,bottom,left (verified against child positions, e.g. `1:7075` pad `8,0,24,0` → pill logo at y=8; `1:7092` pad `14,16,14,16` → icon at x=40,y=303.33).

## Node-by-node

| Node id | Name | Figma box (x,y,w,h) | Figma style | Current Flutter value | Delta | Required fix |
|---|---|---|---|---|---|---|
| 1:7073 | Frame "1. Login & Language Selection" | 0,0 390×858 | fill #FFFFFF; VERTICAL; pad 0,20,202,20 | AppScaffold surface #FFFFFF; scroll pad h20, v24 (meas. content 24→~576) | top pad +24; bottom pad −178; frame box equal | pad top 0, sides 20, bottom 202 |
| 1:7074 | Container | 20,0 350×656 | VERTICAL gap0 pad0 | 350-wide column at x20; children end ≈558 | y +24; height ≈−98 | compose a 656-high column from the sections below |
| 1:7075 | Container (language) | 20,0 350×64 | HORIZONTAL gap0 pad 8,0,24,0 | language row 24→76, then 32 gap | y +24; h 52 vs 64; bottom gap 32 vs 24 | 64-high block: 8 top, 32 pill, 24 bottom |
| 1:7076 | Background+Shadow (language) | 241.58,8 128.42×32 | r9999 fill #F4F3F8; DROP_SHADOW(2 0,1); pad4 gap0 | meas. 210,24 159×52; r999; #F4F3F8; pad2; no shadow | x −31.6; w +30.6; y +16; h +20; pad 2 vs 4; shadow missing | 128.42×32 at 241.58,8; pad4; same fill + shadow |
| 1:7077 | Button "English" (selected) | 245.58,12 70.84×24 | r9999 fill #FFFFFF; DROP_SHADOW(2 0,1); pad 4,14,4,14 | meas. 212,26 90×48; fill #D9FBE8; pad 12/4; no shadow; adds check icon | x −33.6; y +14; w +19.2; h +24; fill and shadow differ; extra icon | white 24-high chip with shadow; remove check icon (or slot it) |
| 1:7078 | Text "English" | 259.58,16 42.84×16 | Plus Jakarta Sans SemiBold 12/600 lh16 ls0.24 #1A1B1F CENTER | labelLarge 14/18 w700 ls−0.14; #00422B | size +2; lh +2; weight +100; ls −0.38; colour | 12/16 w600 ls0.24 #1A1B1F |
| 1:7079 | Button "عربي" (unselected) | 316.42,12 49.58×24 | r9999; no fill; pad 4,14,4,14 | right chip ≈64×48, fill #F4F3F8, pad 12/4 (inferred: same 159×52 pill, 2 gap) | x shifted; h +24; y +14; pad differs | 49.58×24 transparent chip |
| 1:7080 | Text "عربي" | 330.42,16 21.58×16 | FreeSerif Bold 12/600 lh16 ls0.24 #5E5D69 CENTER | 14/18 w700 ls−0.14 #5E5D69; Plus Jakarta/Noto Arabic fallback | size +2; lh +2; weight +100; ls −0.38; family differs | 12/16 w600 ls0.24; Arabic family per P6 (FreeSerif not bundled) |
| 1:7081 | Container (brand) | 20,64 350×222 | no fill/shadow | brand block 108→~210 | y +44; height ≈−120 | brand block 64→286 |
| 1:7082 | Heading 1 | 120.31,192 149.38×32 | VERTICAL pad0 | title Text box 350×32 at x20, y≈156 (ink 163–187) | y −36; w +200.6 | place title box at 120.31,192, 149.38 wide |
| 1:7083 | Text "TechInspect" | 120.31,192 149.38×32 | Plus Jakarta Sans ExtraBold 26/800 lh32 ls−0.65 #1A1B1F CENTER | displayMedium 26/32 w800 ls−0.65 #1A1B1F; copy "TrueReport" (ink width 136) | type matches; copy differs (slot) | keep type; use approved product name in the Figma text box |
| 1:7084 | Margin (tagline) | 73.84,224 242.3×22 | VERTICAL pad 4,0,0,0 | xs=4 gap after title; tagline box y≈192 | y −32 | 4 top pad; tagline container at 228 |
| 1:7085 | Container (tagline) | 73.84,228 242.3×18 | VERTICAL pad0 | 350×20 at y≈192 | y −36; w +107.7; h +2 | 242.3×18 at 73.84,228 |
| 1:7086 | Text tagline | 73.84,228 242.3×18 | Plus Jakarta Sans Regular 13/400 lh18 ls0.325 #5E5D69 CENTER | bodyMedium 14/20 w500 ls−0.07 #5E5D69 (ink 197–210) | size +1; lh +2; weight +100; ls −0.395; y −31 (ink) | 13/18 w400 ls0.325; copy is slot content |
| 1:7087 | Margin (logo) | 155,96 80×96 | VERTICAL pad 0,0,16,0 | compact brand row: 32 monogram at 179,108 | box small/offset | 80×96 slot at 155,96, 16 bottom pad |
| 1:7088 | Container (logo) | 155,96 80×80 | HORIZONTAL gap0 pad0 | 32×32 monogram | −48 both axes | 80×80 logo container |
| 1:7089 | Overlay+Blur | 165,106 60×60 | r9999 fill #6FFBBE4D; LAYER_BLUR(48) | absent | whole node missing | 60×60 emerald 30% circle with 48 blur |
| 1:7090 | TechInspect Minimal Logo | 163,104 64×64 | no fill printed (asset missing) | 32×32 drawn "TR" monogram, #006C49, r12 | −32 both axes; different mark | 64×64 logo slot; artwork pending (slot-sheet) |
| 1:7091 | Container (fields) | 20,286 350×242 | VERTICAL pad 0,4,0,4 | field column ≈244→408, width 350, no 4 inset | y −42; height ≈−78 | 286→528; 4 px left/right inset |
| 1:7092 | Email Background+Shadow | 24,286 342×48 | r16 fill #FFFFFF; DROP_SHADOW(2 0,1); pad 14,16 | meas. 20,266 350×48; r16; #F4F3F8; no shadow; pad h16/v12 | x −4; w +8; y −20; fill white→grey; shadow missing | 342×48 at 24,286; white + shadow; pad 14/16 |
| 1:7093 | Margin (mail icon) | 40,303.33 28.67×13.33 | VERTICAL pad 0,12,0,0 | 48-wide prefix box (icon centred) | box +19.3 wide; position | 28.67×13.33 margin with 12 right pad |
| 1:7094 | Icon (mail) | 40,303.33 16.67×13.33 | fill #6C7A71 | Icons.mail_outline 24; #5E5D69 | size +7.33×+10.67; colour | 16.67×13.33 #6C7A71 |
| 1:7095 | Input | 68.67,300 281.33×20 | VERTICAL pad 1,0,1,0 | no in-field input area (label is above) | node absent | 281.33×20 at 68.67,300 |
| 1:7096 | Container (email) | 68.67,301 281.33×18 | VERTICAL pad0 | absent | node absent | 281.33×18 text slot |
| 1:7097 | Text "Email" | 68.67,301 281.33×18 | Plus Jakarta Sans Medium 14/500 lh− ls−0.07 #6C7A71 LEFT | labelAbove 14/18 w700 ls−0.14 #5E5D69 at x21, ink 248–258 | y −53; weight +200; ls; colour; inside vs above | in-field placeholder 14/500 ls−0.07 #6C7A71 (P2 conflict) |
| 1:7098 | Margin (password) | 24,334 342×64 | VERTICAL pad 16,0,0,0 | gap email→password 46 (314→360) | gap +30 | 16 px gap; card top at 350 |
| 1:7099 | Password Background+Shadow | 24,350 342×48 | r16 fill #FFFFFF; DROP_SHADOW(2 0,1); pad 14,16 | meas. 20,360 350×48; r16; #F4F3F8; no shadow | x −4; w +8; y +10; fill/shadow | 342×48 at 24,350; white + shadow |
| 1:7100 | Margin (lock icon) | 40,365.25 25.33×17.5 | VERTICAL pad 0,12,0,0 | 48-wide prefix box | size/position | 25.33×17.5 margin with 12 right pad |
| 1:7101 | Icon (lock) | 40,365.25 13.33×17.5 | fill #6C7A71 | Icons.lock_outline 24; #5E5D69 | size +10.67×+6.5; colour | 13.33×17.5 #6C7A71 |
| 1:7102 | Input (password) | 65.33,364 260.17×20 | VERTICAL pad 1,0,1,0 | no in-field area | node absent | 260.17×20 at 65.33,364 |
| 1:7103 | Container (password) | 65.33,365 260.17×18 | VERTICAL pad0 | absent | node absent | 260.17×18 text slot |
| 1:7104 | Text "Password" | 65.33,365 260.17×18 | Plus Jakarta Sans Medium 14/500 lh− ls−0.07 #6C7A71 LEFT | labelAbove 14/18 w700 ls−0.14 #5E5D69 at y342 | y −23; weight +200; ls; colour | in-field placeholder 14/500 #6C7A71 |
| 1:7105 | Button (eye) | 325.5,364.38 24.5×19.25 | HORIZONTAL pad4 | raw IconButton 48×48 (targetMin) | w +23.5; h +28.75; x −? | 24.5×19.25 button |
| 1:7106 | Container (eye) | 329.5,368.38 16.5×11.25 | VERTICAL pad0 | 24×24 icon centred in 48 | +7.5×+12.75 | 16.5×11.25 at 329.5,368.38 |
| 1:7107 | Icon (eye) | 329.5,368.38 16.5×11.25 | fill #6C7A71 | Icons.visibility_outlined 24; #5E5D69 | size +7.5×+12.75; colour | 16.5×11.25 #6C7A71 |
| 1:7108 | Margin (forgot) | 24,398 342×34 | VERTICAL pad 16,0,0,0 | absent | whole node missing | omit (slot) or 16 top pad + row |
| 1:7109 | Container (forgot row) | 24,414 342×18 | HORIZONTAL pad 4,0,0,0 | absent | whole node missing | 342×18 row |
| 1:7110 | Button (forgot) | 262.05,418 103.95×14 | VERTICAL pad0 | absent | whole node missing | right-aligned 103.95×14 (slot) |
| 1:7111 | Text "Forgot password?" | 262.05,418 103.95×14 | Plus Jakarta Sans SemiBold 11/600 lh14 ls0.44 #5E5D69 CENTER | absent | whole node missing | do not ship unreachable link; slot |
| 1:7112 | Margin (CTA) | 24,432 342×96 | VERTICAL pad 40,0,0,0 | password→CTA gap ≈40 (408→448) | gap matches; y −24 absolute | CTA margin 432→528 |
| 1:7113 | Button "Sign In" | 24,472 342×56 | r9999 fill #10B981; HORIZONTAL gap8 pad0 | meas. 20,448 350×56; r999; fill #059669; buttonSubtle shadow | x −4; w +8; y −24; fill #059669 vs #10B981 | 342×56 at 24,472; Figma fill (P1 says #059669, deviation) |
| 1:7114 | Button:shadow | 24,472 342×56 | r9999 fill #FFFFFF01; DROP_SHADOW(4 0,2 s-2)+DROP_SHADOW(6 0,4 s-1) | same box as current CTA; TrShadows.buttonSubtle 10% black (0,2,b4,s−2)+(0,4,b6,s−1) | box y −24; alpha/blur not proven equal | match CTA box; align shadow to dump |
| 1:7115 | Container (CTA label) | 163.79,491 43.75×18 | VERTICAL pad0 | label row centred; 19/24 text | w/position differ; text +5/+6 | 43.75×18 label box |
| 1:7116 | Text "Sign In" | 163.79,491 43.75×18 | Plus Jakarta Sans Bold 14/700 lh18 ls−0.14 #FFFFFF CENTER | largeButton 19/24 w700 ls−0.19 #FFFFFF; copy "Sign in" | size +5; lh +6; ls −0.05; case | 14/18 w700 ls−0.14 #FFFFFF |
| 1:7117 | Container (arrow) | 215.54,494.67 10.67×10.67 | VERTICAL pad0 | icon 24 before label, 8 gap | size +13.33; leading vs trailing | trailing 10.67 icon, 8 gap |
| 1:7118 | Icon (arrow) | 215.54,494.67 10.67×10.67 | fill #FFFFFF | Icons.arrow_forward 24 #FFFFFF | size +13.33; side | 10.67×10.67 trailing arrow |
| 1:7119 | Container (footer) | 20,528 350×128 | VERTICAL pad 64,0,16,0 | account note 12/18 w400 #5E5D69 at y≈537–555 | y +9; h −110; copy/structure differ | 128-high footer band 528→656 |
| 1:7120 | Container (access row) | 81.76,592 226.47×18 | HORIZONTAL gap8 pad0 | absent (product note instead) | whole node missing | restore row or slot |
| 1:7121 | Container (access text) | 81.76,592 153.53×18 | VERTICAL pad0 | absent | whole node missing | 153.53×18 |
| 1:7122 | Text "Need technician access?" | 81.76,592 153.53×18 | Plus Jakarta Sans Regular 13/400 lh18 ls0 #5E5D69 LEFT | absent; current note 12/18 w400 at y540 | copy/position; size −1 | 13/18 w400; product copy is a slot |
| 1:7123 | Button "Request ID" | 243.29,593 64.94×16 | VERTICAL pad0 | absent | whole node missing | omit unreachable link; slot |
| 1:7124 | Text "Request ID" | 243.29,593 64.94×16 | Plus Jakarta Sans SemiBold 12/600 lh16 ls0.24 #006C49 CENTER | absent | whole node missing | slot-sheet item |
| 1:7125 | Margin (ISO) | 90.93,610 208.14×30 | VERTICAL pad 16,0,0,0 | absent | whole node missing | omit (slot) |
| 1:7126 | Container (ISO row) | 90.93,626 208.14×14 | HORIZONTAL gap6 pad0 | absent | whole node missing | 208.14×14 |
| 1:7127 | Container (shield) | 90.93,628 8×10 | VERTICAL pad0 | absent | whole node missing | 8×10 |
| 1:7128 | Icon (shield) | 90.93,628 8×10 | fill #6C7A71 | absent | whole node missing | omit with claim |
| 1:7129 | Container (ISO text) | 104.93,626 194.14×14 | VERTICAL pad0 | absent | whole node missing | 194.14×14 |
| 1:7130 | Text "ISO 27001 Certified Fleet Security" | 104.93,626 194.14×14 | Plus Jakarta Sans SemiBold 11/600 lh14 ls0.44 #6C7A71 LEFT | absent | whole node missing | omit: no certification claim (slot) |

## Structural fixes

1. Root: top padding 0 (currently 24) and bottom padding 202 (currently 24); keep 20 px side gutter (`1:7073`).
2. Language: build a 350×64 row at y0 with an 8 px top pad and a 24 px bottom pad; the 128.42×32 pill must sit at x241.58,y8 with 4 px inner padding and two 24-high buttons (`1:7075`–`1:7080`). Remove the current 48-high chips and the check glyph.
3. Brand: replace the 32 px monogram with the 64×64 logo slot at 163,104 plus the 60×60 blurred halo at 165,106; keep the 16 px gap before the heading at y192 and the tagline at y228 (`1:7087`–`1:7090`).
4. Fields: inset the cards 4 px inside the 350 column (x24,w342); place email at y286 and password at y350 (16 px gap); remove the above-field labels and restore in-field placeholders with the Figma icon margins (28.67/25.33 wide, 12 right pad) and the 24.5×19.25 eye button (`1:7091`–`1:7107`).
5. CTA: 342×56 at x24,y472; trailing 10.67 arrow with 8 px gap (`1:7112`–`1:7118`). The current 40 px gap from the password card is correct; only the upstream shift moves it.
6. Footer: reserve 528→656 (64 top pad, 16 bottom). Either restore the access/Request-ID row at y592 and the ISO row at y626, or keep a single product note inside the 128-high band (`1:7119`–`1:7130`).
7. Keep the current responsive scroll; the Figma 858-high frame is met only at a 390×858 viewport.

## Type/fill/shadow fixes

- Language labels: 14/18 w700 ls−0.14 → 12/16 w600 ls0.24; selected colour #00422B → #1A1B1F; selected fill #D9FBE8 → #FFFFFF with `DROP_SHADOW(2 0,1)`; outer pill #F4F3F8 + same shadow (`1:7076`–`1:7080`).
- Heading: type already exact (26/32 w800 ls−0.65 #1A1B1F); only placeholder/copy width is slot-driven (`1:7083`).
- Tagline: 14/20 w500 ls−0.07 → 13/18 w400 ls0.325, #5E5D69 (`1:7086`).
- Fields: #F4F3F8 + no resting shadow → #FFFFFF + `DROP_SHADOW(2 0,1)`; radius 16 already matches. This contradicts `deviations.md` O-01/P2, which records the field fill as #F4F3F8; the dump and the 780×1716 preview both give white (`1:7092`, `1:7099`).
- Placeholders: 14/18 w700 ls−0.14 #5E5D69 → 14/500 ls−0.07 #6C7A71; typed text is bodyLg 16/24 w500 vs the Figma 14/500 field text (`1:7097`, `1:7104`).
- Icons: Material 24 px `#5E5D69` → 16.67×13.33 mail, 13.33×17.5 lock, 16.5×11.25 eye, all #6C7A71 (`1:7094`, `1:7101`, `1:7107`); CTA arrow 24 → 10.67 white, moved after the label (`1:7117`–`1:7118`).
- CTA: current large style 19/24 w700 ls−0.19 → Figma 14/18 w700 ls−0.14. Fill is #059669 in the product (P1) vs #10B981 in the dump; shadow values need confirming against the literal `(4 0,2 s-2)+(6 0,4 s-1)` (`1:7113`–`1:7116`).
- Forgot/Request/ISO styles, if ever re-enabled: 11/14 w600 ls0.44 #5E5D69; 12/16 w600 ls0.24 #006C49; 11/14 w600 ls0.44 #6C7A71 (`1:7111`, `1:7124`, `1:7130`).
- Halo: #6FFBBE4D at 30% with 48 px layer blur (`1:7089`). Current implementation has no halo.

## Slot-sheet items

| Slot item | Node(s) | Current handling | Note |
|---|---|---|---|
| Brand name "TechInspect" | 1:7082–1:7083 | shows "TrueReport" | A8/decisions: product brand must not be replaced by Figma sample brand. |
| Tagline "Vehicle Condition & Fleet Diagnostics" | 1:7084–1:7086 | "Vehicle inspection reports for partner workshops." | Product copy; exact Figma wording is sample content. |
| Logo mark "TechInspect Minimal Logo" | 1:7087–1:7090 | 32 px "TR" monogram, no halo | Figma node has no artwork/fill; approved drawn monogram instead. |
| Forgot password? | 1:7108–1:7111 | absent | No password-reset endpoint; unreachable link cannot ship. |
| "Need technician access?" + "Request ID" | 1:7119–1:7124 | absent; account note instead | No request-ID endpoint; link is a slot/omission. |
| "ISO 27001 Certified Fleet Security" shield + text | 1:7125–1:7130 | absent | No certification claim allowed; do not render as drawn. |

## Could not verify

- Logo artwork (`1:7090`): the dump prints only a 64×64 box, no fill or asset; the Figma preview mark cannot be reproduced from this file.
- Shadow alpha/blur encoding: the dump prints `DROP_SHADOW(2 0,1)` / `(4 0,2 s-2)+(6 0,4 s-1)` without a colour or explicit alpha; equality with `TrShadows.buttonSubtle` is not provable from text.
- Arabic typeface: `1:7080` names FreeSerif Bold, which is not bundled; the product uses Plus Jakarta Sans with Noto Sans Arabic fallback (P6), so the glyph shape cannot match exactly.
- Field height conflict: code sets `inputHeight` 56 and `ConstrainedBox(minHeight: 56)`, but the supplied 1.0× render measures the #F4F3F8 fill at 48 px (266–313 and 360–407). The screenshot was generated after `inputs.dart`/tokens were last modified, so the 8 px discrepancy is unexplained; re-capture before accepting any field-height fix.
- Figma selected-chip fill: `1:7077` is `#FFFFFF` on a white page; the preview cannot distinguish chip from background, so only the node dump is authoritative.
- Current text ink boxes (title 163–187, tagline 197–210, labels 248–258/342–352) are glyph bounding boxes, not widget boxes; they differ from Figma text-node boxes by font rasterisation.
- Arabic render: no Arabic Figma frame exists; the Arabic screenshot is a derived RTL layout, not a fidelity target (P6/F2A-10).
- Focus, error, loading and 2FA-challenge states are not present in the Figma dump and were not audited.
