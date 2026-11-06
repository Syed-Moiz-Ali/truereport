# F2A1 Audit — Screen 3: Empty State Dashboard

Source of truth: `docs/ui/figma/f2a1-nodes/03-empty-state.txt` (boxes exactly as printed, px). Frame `1:7287` is `390x883.75`; current render `docs/ui/figma/f2a-screenshots/empty-state_en_1.0x.png` is `390x884`. Current values are read from `assigned_jobs_view.dart`, `technician_shell.dart`, `navigation.dart`, `chips.dart`, `buttons.dart`, `cards.dart`, `tokens.g.dart` (no pixel measurement performed). Slot-sheet status is inferred from the brief; no slot-sheet document exists in the paths given.

## Node-by-node

| Node | Name | Figma box | Figma style | Current Flutter value | Delta | Required fix |
|---|---|---|---|---|---|---|
| 1:7287 | Frame "3. Empty State Dashboard" | @0,0 390x883.75 | fill #FFFFFF | Scaffold 390x884, surface #FFFFFF | 0.25px height rounding | Accept; verify at 390 logical width |
| 1:7288 | Main | @0,0 390x883.75 | fill #FFFFFF, VERTICAL gap0 pad 64,20,112,20 | Body: SingleChildScrollView pad 20 all, no 64 top/112 bottom | Top/bottom padding wrong; no reserved header band | Content must start below 64 header; bottom content above dock |
| 1:7289 | Container | @20,64 350x707.75 | no fill/shadow | n/a (no equivalent 707.75 column) | Missing 707.75 content column | Compose shift + welcome + empty + summary in 350-wide column |
| 1:7290 | Shift Container | @20,64 350x72 | HORIZONTAL gap 91.5 pad 8,0,16,0 | absent | Entire 72px shift row missing | Add shift/status row, 350x72 |
| 1:7291 | Shift left group | @20,72 172.48x48 | gap 8 | absent | — | Add avatar + SHIFT ACTIVE pill group |
| 1:7292 | Overlay+Shadow (avatar) | @20,72 48x48 | r9999 fill #10B98126, DROP_SHADOW(16 0,4) | TechnicianAvatar 48, circle, no halo/shadow | Fill/halo/shadow missing; 48 box matches | Emerald 15% 48 halo + blur16/y4 shadow |
| 1:7293 | Avatar Background | @24,76 40x40 | r9999 fill #10B981 | Avatar fill brand.container #D9FBE8, full 48 | 48 vs 40; #D9FBE8 vs #10B981 | Inner 40 solid emerald |
| 1:7294 | Avatar Text container | @32.95,85 22.11x22 | — | centered Text | — | Center DV in 40 inner |
| 1:7295 | "DV" | @32.95,85 22.11x22 | 16/800 lh22 ls−0.4 #FFFFFF | 14/800 lh18 ls−0.14 #00422B | size 16→14, lh22→18, ls−0.4→−0.14, color | White 16/800 lh22 ls−0.4 |
| 1:7296 | SHIFT ACTIVE pill | @76,85 116.48x22 | r9999 fill #F4F3F8 gap6 pad4,12,4,12 | absent | Missing pill | Add 22px pill on #F4F3F8 |
| 1:7297 | Shift dot | @88,92 8x8 | r9999 fill #10B981 | absent | Missing 8px status dot | Add emerald dot |
| 1:7298 | Shift text container | @102,89 78.48x14 | — | absent | — | — |
| 1:7299 | "SHIFT ACTIVE" | @102,89 78.48x14 | 11/700 lh14 ls0.55 #3C4A42 | absent | Missing label (slot-sheet) | Add uppercase 11/700 lh14 ls0.55 #3C4A42 |
| 1:7300 | Bay 04 pill | @285.31,83 84.69x26 | r9999 fill #F4F3F8 gap6 pad6,12,6,12 | absent | Missing right pill | Add 26px right-aligned Bay pill |
| 1:7301 | Bay icon container | @297.31,89 14.67x14 | — | absent | — | — |
| 1:7302 | Bay icon | @297.31,89 14.67x14 | fill #006C49 | absent | Missing 14.67px icon | Add bay/badge icon #006C49 |
| 1:7303 | Bay text container | @317.98,89 40.02x14 | — | absent | — | — |
| 1:7304 | "Bay 04" | @317.98,89 40.02x14 | 11/700 lh14 ls0.44 #1A1B1F | absent | Missing label (slot-sheet) | Add "Bay 04" 11/700 lh14 ls0.44 |
| 1:7305 | Welcome Margin | @20,136 350x66 | pad 8,0,0,0 | 20px scroll top before welcome | Missing 8px top pad + shift-row offset | Place block at y136–202 |
| 1:7306 | Welcome container | @20,144 350x58 | VERTICAL gap0 | _WelcomeRow Row (avatar + column) | Extra inline avatar; wrong width/height | Remove avatar from welcome; full-width 350 block |
| 1:7307 | "Welcome back," container | @20,144 350x24 | — | Text | — | — |
| 1:7308 | "Welcome back," | @20,144 350x24 | 16/500 lh24 ls−0.4 #5E5D69 | bodyMedium 14/500 lh20 ls−0.07, w600, #5E5D69 | size −2, weight 500→600, lh24→20, ls−0.4→−0.07 | 16/500 lh24 ls−0.4 #5E5D69, full width |
| 1:7309 | Heading margin | @20,168 350x34 | pad 2,0,0,0 | second Text | Missing 2px gap | Add 2px top pad |
| 1:7310 | Heading 1 | @20,170 350x32 | — | Text maxLines 2 ellipsis | — | Single-line 350x32 |
| 1:7311 | "David Vance" | @20,170 350x32 | 26/800 lh32 ls−0.65 #1A1B1F | displayMedium 26/800 lh32 ls−0.65 #1A1B1F | Matches; width 290 vs 350 | Remove ellipsis; full 350 width |
| 1:7312 | Empty content Container | @20,202 350x497.75 | no fill, no shadow | AppCard raised: fill #FFFFFF, r32, pad32, shadows.card | Adds card fill/radius/padding/shadow not in dump | Remove card chrome; transparent 350 column |
| 1:7313 | Empty top Margin | @55,378 280x149.57 | pad 32,0,0,0 | 32 gap welcome→card + 32 card pad (64 total) | 64 vs 48 (art top 250) | Art 48 below y202 |
| 1:7314 | Empty column | @55,410 280x117.57 | gap −0.4 | Column, positive 12/8 gaps | Gap values differ | Use 280 content width and Figma gaps |
| 1:7315 | Queue pill margin | @141.23,410 107.54x34 | pad 0,0,12,0 | spacing.md 12 after pill | 12 bottom pad matches | Keep 12 but reduce pill height |
| 1:7316 | "0 IN QUEUE" pill | @141.23,410 107.54x22 | r9999 fill #10B9811A gap5.99 pad4,12,4,12 | TechnicianMetaPill: 32 min-height, fill #F4F3F8, pad h12/v4 | height 32→22, fill wrong, no icon | Pill 107.54x22 #10B9811A |
| 1:7317 | Queue icon container | @153.23,415.17 11.67x11.67 | — | absent | Missing icon | — |
| 1:7318 | Queue icon | @153.23,415.17 11.67x11.67 | fill #10B981 | absent | Missing 11.67px check icon | Add #10B981 icon |
| 1:7319 | Queue text container | @170.89,414 65.88x14 | — | Text | — | — |
| 1:7320 | "0 IN QUEUE" | @170.89,414 65.88x14 | 11/700 lh14 ls0.44 #10B981 CENTER | labelMedium 12/700 lh16 ls0.24 #5E5D69, "0 in queue" | size/lh/ls/color/case differ | Uppercase 11/700 lh14 ls0.44 #10B981 |
| 1:7321 | "You are all caught up!" | @87,443.6 216x31 | 22/800 lh30.25 ls−0.55 #1A1B1F CENTER | headlineLarge 22/800 lh28 ls−0.44, "You are all caught up" (no `!`), width 286 | lh −2.25, ls −0.11, missing `!`, 216 width | Add `!`, lh30.25, ls−0.55, max width 216 |
| 1:7322 | Body margin | @55,474.2 280x53.38 | pad 7.375,0,0,0 | spacing.sm 8 | 7.375 vs 8 | Use 7.375 |
| 1:7323 | Body container | @55,481.57 280x46 | pad 0,5.23,0,5.22 | Text no pad | Missing 5.23 vertical pad | Add vertical padding |
| 1:7324 | Empty body copy | @60.22,481.57 269.55x46 | 14/500 lh22.75 ls−0.07 #5E5D69 CENTER, 2 explicit lines | bodyMedium 14/500 lh20, "No pending inspections are assigned to you." width 286 | copy differs; lh20→22.75; 2.75 shorter; width 269.55 | Use Figma copy, lh22.75, 269.55 width, explicit break |
| 1:7325 | Button margin | @107.47,527.75 168.39x80 | pad 32,0,0,0 | spacing.xl 24 | 24 vs 32 | 32 top gap before button |
| 1:7326 | "Refresh Queue" button | @107.47,559.75 168.39x48 | r9999 fill #F4F3F8, DROP_SHADOW(8 0,2), gap8 pad14,24,14,24 | AppButton tonal, expand, 56h, fill #D9FBE8, no shadow, pad 12/24 | fill, 56→48, full vs 168.39, shadow missing | Centered 168.39x48 #F4F3F8 pill + 0 2 8 shadow |
| 1:7327 | Refresh icon container | @131.47,577.08 13.33x13.33 | — | Icons.refresh 24 | 24 vs 13.33 | — |
| 1:7328 | Refresh icon | @131.47,577.08 13.33x13.33 | fill #5E5D69 | size 24, #00422B | size + color wrong | 13.33px #5E5D69 |
| 1:7329 | Refresh text container | @152.8,574.75 99.06x18 | — | Text | — | — |
| 1:7330 | "Refresh Queue" | @152.8,574.75 99.06x18 | 14/700 lh18 ls−0.14 #1A1B1F CENTER | labelLarge 14/700 lh18 ls−0.14 #00422B | color #00422B vs #1A1B1F | Text #1A1B1F |
| 1:7331 | Art container | @131,250 128x128 | — | Container 128x128 | size matches | — |
| 1:7332 | Art Background+Shadow | @131,250 128x128 | r24 fill #FFFFFF, DROP_SHADOW(8 0,2)+DROP_SHADOW(40 0,14) | fill #F4F3F8, r32, no shadow | fill/radius/shadow wrong | White r24 tile + card shadows |
| 1:7333 | Art inner Background | @155,274 80x80 | r16 fill #F4F3F8 | absent | Missing 80x80 inset tile | Add inset r16 #F4F3F8 tile |
| 1:7334 | Art icon container | @178.5,297.5 33x33 | — | Icon centered | — | — |
| 1:7335 | Art icon | @178.5,297.5 33x33 | fill #62616D | Icons.inbox_outlined 48, #006C49 | size 48→33, color green→grey | 33px #62616D |
| 1:7336 | Art bars container | @182,238 26x16 | HORIZONTAL gap4 | absent | Missing 3 decorative bars | Add above tile |
| 1:7337/8/9 | Art bars | @182,240 6x12; @192,238 6x16; @202,241 6x10 | r9999 #5E5D694D/#5E5D6966/#5E5D6933, LAYER_BLUR(1) | absent | Missing | 3 pill bars with blur |
| 1:7340 | Sync pill margin | @68.42,607.75 251.74x42 | pad 16,0,0,0 | spacing.sm 8 after refresh | 8 vs 16 | 16 top gap |
| 1:7341 | Sync Background pill | @68.42,623.75 251.74x26 | r9999 fill #EEEDF3 gap6 pad6,16,6,16 | absent (plain Text) | Missing pill | Add 251.74x26 #EEEDF3 pill |
| 1:7342 | Sync icon container | @84.42,632.74 14.6x8.02 | — | absent | — | — |
| 1:7343 | Sync icon | @84.42,632.74 14.6x8.02 | fill #10B981 | absent | Missing icon | 14.6x8.02 #10B981 check |
| 1:7344 | Sync text container | @105.02,629.75 199.14x14 | — | Text | — | — |
| 1:7345 | Sync copy | @105.02,629.75 199.14x14 | 11/600 lh14 ls0.44 #3C4A42 CENTER, "Queue is current • Synced just now" | labelMedium 12/600 lh16 ls0.24 #5E5D69, "No changes waiting to sync"/"Changes saved on this phone" | copy, size, lh, ls, color, no pill (slot-sheet) | Add exact copy + 11/600 lh14 ls0.44 #3C4A42 |
| 1:7346 | Summary Background | @20,699.75 350x72 | r16 fill #F4F3F8 gap36.48 pad16 | absent | Entire summary card missing (slot-sheet) | Add 350x72 r16 card |
| 1:7347 | Summary left group | @36,715.75 163.8x40 | gap12 | absent | Missing | — |
| 1:7348 | Summary icon pill | @36,715.75 40x40 | r48 fill #FFFFFF, DROP_SHADOW(2 0,1) | absent | Missing white 40 circle/shadow | Add 40px white circle |
| 1:7349 | Summary icon container | @47.75,726.58 16.5x18.33 | — | absent | — | — |
| 1:7350 | Summary icon | @47.75,726.58 16.5x18.33 | fill #10B981 | absent | Missing calendar icon | 16.5x18.33 #10B981 |
| 1:7351 | Summary text column | @88,717.75 111.8x36 | gap0 | absent | Missing | — |
| 1:7352 | Summary label row | @88,717.75 111.8x14 | — | absent | — | — |
| 1:7353 | "TODAY'S SUMMARY" | @88,717.75 111.8x14 | 11/600 lh14 ls0.44 #5E5D69 | absent | Missing (slot-sheet) | Add 11/600 lh14 ls0.44 |
| 1:7354 | Summary value row | @88,731.75 111.8x22 | — | absent | — | — |
| 1:7355 | "14 Completed" | @88,731.75 106.94x22 | 16/700 lh22 ls−0.16 #1A1B1F | absent | Missing (slot-sheet) | Add 16/700 lh22 ls−0.16 |
| 1:7356 | Summary right group | @239.28,727.75 114.72x16 | gap4 | absent | Missing | — |
| 1:7357 | Pass rate row | @239.28,727.75 95.72x16 | — | absent | — | — |
| 1:7358 | "100% Pass Rate" | @239.28,727.75 95.72x16 | 12/700 lh16 ls0.24 #006C49 | absent | Forbidden score; do not ship as-is | Replace with non-score metric or omit per slot-sheet |
| 1:7359 | Pass arrow container | @339,731.25 15x9 | — | absent | — | — |
| 1:7360 | Pass arrow icon | @339,731.25 15x9 | fill #006C49 | absent | Missing 15x9 arrow | Add only if score metric approved |
| 1:7361 | Header | @0,0 390x64 | fill #FFFFFFE5, DROP_SHADOW(8 0,1)+BACKGROUND_BLUR(48) | AppBar 64, #FFFFFF opaque, elevation 0, no blur/shadow | fill alpha, blur, shadow missing | Translucent header + 0 1 8 + blur48 |
| 1:7362 | Header container | @0,0 390x64 | pad 0,18.75,0,20 | toolbar pad, titleSpacing 20 | Vertical pad differs | — |
| 1:7363 | Header left group | @20,21 160x22 | gap8 | leading brand mark 32 + title | Figma has no logo; title x20 vs ~64 | Remove brand mark from leading; title at x20 |
| 1:7365 | Title container | @20,21 160x22 | pad 0,4.15,0,0 | title Text | — | — |
| 1:7366 | "Inspection Queue" | @20,21 82.38x22 | 16/700 lh22 ls−0.4 #1A1B1F | headlineMedium 18/700 lh24 ls−0.27, "Assigned jobs" | copy, size 18→16, lh24→22, ls−0.27→−0.4 | Use "Inspection Queue" 16/700 lh22 ls−0.4 |
| 1:7367 | Header right group | @253.5,10 117.75x44 | gap8 | avatar only | Missing LIVE SYNC pill | Add pill + photo avatar |
| 1:7368 | LIVE SYNC pill | @253.5,14 65.75x36 | r9999 fill #F4F3F8 gap6 pad4,10,4,10 | absent | Missing pill | Add 65.75x36 #F4F3F8 pill |
| 1:7369 | Live dot | @263.5,28 4.81x8 | r9999 fill #10B981 | absent | Missing 4.81x8 bar | Add emerald bar |
| 1:7370 | LIVE text container | @274.31,18 34.94x28 | pad 0,3.19,0,0 | absent | — | — |
| 1:7371 | "LIVE\nSYNC" | @274.31,18 31.75x28 | 11/600 lh14 ls0.275 #3C4A42 | absent | Missing label | Add 2-line 11/600 lh14 ls0.275 |
| 1:7372 | Profile Button | @327.25,10 44x44 | r9999 pad6 | IconButton default 48 | 48 vs 44 | 44x44 hit target |
| 1:7373 | Profile photo | @333.25,16 32x32 | r9999 fill IMAGE | TechnicianAvatar 40 initials, mint | 40→32, no photo (slot-sheet) | 32px photo avatar per slot-sheet |
| 1:7374 | Nav container | @0,804 390x80 | pad 0,20,16,20 | bottomNavigationBar | — | Bottom band 80 with 20/16 pads |
| 1:7375 | Nav dock | @20,804 350x64 | r9999 fill #FFFFFFF2, SHADOW(12 0,4)+(50 0,18)+BLUR(48), gap39.5 pad0,8,0,8 | 64h, #FFFFFF opaque, floating shadow, no blur, 3 items | alpha/blur missing; 3 vs 4 items; gap differs | 4-item translucent blurred dock |
| 1:7376 | Intake Link | @47.75,814 44x44 | pad2,4.14,2,4.14 | Jobs item | Label/icon differ | Intake item per Figma |
| 1:7377 | Intake icon box | @60.75,818 18x20 | — | Icon 24 | 24 vs 18x20 | 18x20 icon |
| 1:7378 | Intake icon | @60.75,818 18x20 | fill #1A1B1F | Icons.work, 24, #1A1B1F | Size 24→18x20 | 18x20 intake icon |
| 1:7379 | Intake label margin | @51.89,838 35.72x16 | pad2,0,0,0 | label | — | — |
| 1:7380 | "Intake" | @51.89,840 35.72x14 | 11/600 lh14 ls0.44 #1A1B1F | labelSmall 12/600 lh16 ls0.3, "Jobs" | copy, size, lh, ls | "Intake" 11/600 lh14 ls0.44 |
| 1:7381 | Fleet Link | @131.25,814 44x44 | pad2,7.37,2,7.36 | absent | Missing item | Add Fleet item |
| 1:7382 | Fleet icon box | @144.24,820 18x16 | — | absent | — | — |
| 1:7383 | Fleet icon | @144.24,820 18x16 | fill #5E5D69 | absent | Missing 18x16 icon | Add #5E5D69 fleet icon |
| 1:7384 | Fleet label margin | @138.61,836 29.27x16 | pad2,0,0,0 | absent | — | — |
| 1:7385 | "Fleet" | @138.61,838 29.27x14 | 11/600 lh14 ls0.44 #5E5D69 | absent | Missing label | Add "Fleet" 11/600 lh14 ls0.44 |
| 1:7386 | Sync Link | @214.75,814 44x44 | pad2,7.87,2,7.88 | Sync item | — | — |
| 1:7387 | Sync icon box | @225.76,819 22x18 | — | Icon 24 | 24 vs 22x18 | 22x18 icon |
| 1:7388 | Sync icon | @225.76,819 22x18 | fill #5E5D69 | Icons.sync_outlined 24, #5E5D69 | Size 24→22x18 | 22x18 sync icon |
| 1:7389 | Sync label margin | @222.63,837 28.25x16 | pad2,0,0,0 | label | — | — |
| 1:7390 | "Sync" | @222.63,839 28.25x14 | 11/600 lh14 ls0.44 #5E5D69 | labelSmall 12/600 lh16 ls0.3 | size/lh/ls | 11/600 lh14 ls0.44 |
| 1:7391 | Profile Link | @298.25,814 44x44 | pad2,3.19,2,3.17 | Profile item | — | — |
| 1:7392 | Profile icon box | @310.24,818 20x20 | — | Icon 24 | 24 vs 20x20 | 20x20 icon |
| 1:7393 | Profile icon | @310.24,818 20x20 | fill #5E5D69 | Icons.person_outline 24, #5E5D69 | Size 24→20x20 | 20x20 profile icon |
| 1:7394 | Profile label margin | @301.42,838 37.64x16 | pad2,0,0,0 | label | — | — |
| 1:7395 | "Profile" | @301.42,840 37.64x14 | 11/600 lh14 ls0.44 #5E5D69 | labelSmall 12/600 lh16 ls0.3 | size/lh/ls | 11/600 lh14 ls0.44 |
| — | Selected dot (current) | not in Figma | — | 4x4 brand ink dot above selected icon | Extra element | Remove dot |

## Structural fixes

1. Insert the missing 72px shift/status row between the 64px header and the welcome block: 48px avatar (with emerald halo) + SHIFT ACTIVE pill + right-aligned Bay 04 pill (`1:7290`–`1:7304`). Current `EmptyJobsView` jumps straight to `_WelcomeRow`.
2. Put the welcome block at y136–202 with an 8px top pad; remove the inline `TechnicianAvatar` from `_WelcomeRow` (`1:7305`–`1:7311`). Current avatar is the only one and sits inline with the greeting.
3. Remove the raised `AppCard` wrapper around `_EmptyPanel` (`1:7312` dump has no fill/shadow; only the 128px art tile carries a shadow). Current adds a white 32-radius card with `shadows.card` and 32px padding.
4. Rebuild the 128px art as white r24 card + 0 2 8 / 0 14 40 shadows, inset 80x80 r16 tile, 33px grey icon, and the 3 blurred bars above (`1:7331`–`1:7339`).
5. Center the Refresh Queue button at 168.39x48; remove `expand: true` (`1:7325`–`1:7330`).
6. Delete the Walk-in job text button and the standalone sync `Text`; replace the latter with the 251.74x26 pill (`1:7340`–`1:7345`). Walk-in has no Figma node in this dump.
7. Add the 350x72 TODAY'S SUMMARY card at y699.75 (`1:7346`–`1:7360`).
8. Header: drop the compact TR brand mark, move the title to x20, and add the LIVE SYNC pill plus 32px profile photo (`1:7361`–`1:7373`). The current app bar shows TR + "Assigned jobs" + initials avatar.
9. Dock: render 4 items Intake / Fleet / Sync / Profile (the current product dock is deliberately 3 items per `technician_shell.dart:198`); restore Figma spacing/labels or document the product exception (`1:7374`–`1:7395`).
10. Vertical rhythm: shift 64–136, welcome 136–202, empty 202–699.75, summary 699.75–771.75, dock 804–868. The current scroll body starts at ~84 and has no summary band.

## Type/fill/shadow fixes

- "Welcome back,": 14/600 → 16/500, lh20 → 24, ls −0.07 → −0.4 (`1:7308`).
- "0 IN QUEUE" pill: height 32 → 22; fill #F4F3F8 → #10B9811A; text 12/700 lh16 ls0.24 → 11/700 lh14 ls0.44; colour #5E5D69 → #10B981; uppercase + add 11.67px icon (`1:7316`–`1:7320`).
- Headline: add the exclamation mark; lh28 → 30.25; ls −0.44 → −0.55; width 286 → 216 (`1:7321`).
- Body: copy → "No pending vehicle inspections assigned\nto you today."; lh20 → 22.75; width 286 → 269.55; explicit line break (`1:7324`).
- Refresh: fill #D9FBE8 → #F4F3F8; fg #00422B → #1A1B1F; 56 → 48 height; full width → 168.39; icon 24 → 13.33px #5E5D69; add 0 2 8 shadow (`1:7326`–`1:7330`).
- Art: icon 48 → 33 and #006C49 → #62616D; tile #F4F3F8/r32 → #FFFFFF/r24 with card shadows; add 80px r16 inset tile (`1:7332`–`1:7335`).
- Avatar: 48 mint/14/800 dark → 48 halo #10B98126 + 40 #10B981 + DV 16/800 lh22 ls−0.4 white (`1:7292`–`1:7295`).
- Sync strip: add #EEEDF3 pill, 11/600 lh14 ls0.44 #3C4A42, 14.6x8.02 emerald icon (`1:7341`–`1:7345`).
- Summary: label 11/600 lh14 ls0.44 #5E5D69; value 16/700 lh22 ls−0.16 #1A1B1F; metric 12/700 lh16 ls0.24 #006C49 (`1:7353`–`1:7358`).
- Header: fill #FFFFFF → #FFFFFFE5 + blur48 + 0 1 8 shadow; title 18/700 lh24 ls−0.27 → 16/700 lh22 ls−0.4 (`1:7361`, `1:7366`).
- LIVE SYNC: 11/600 lh14 ls0.275 #3C4A42 on #F4F3F8 65.75x36 r9999; 4.81x8 #10B981 bar (`1:7368`–`1:7371`).
- Dock: fill #FFFFFF → #FFFFFFF2 + blur48; labels 12/600 lh16 ls0.3 → 11/600 lh14 ls0.44; icons 24 → 18x20 / 18x16 / 22x18 / 20x20; remove selected dot (`1:7375`–`1:7395`).

## Slot-sheet items

| Slot item | Node | Status in current code | Note |
|---|---|---|---|
| SHIFT ACTIVE | 1:7299 | absent | Needs slot-sheet approval before shipping shift status. |
| Bay 04 | 1:7304 | absent | Bay number is placeholder/slot content. |
| "Queue is current • Synced just now" | 1:7345 | replaced by `technicianAllSynced` / `technicianPendingSync` text | Exact copy is slot content; current has no pill. |
| TODAY'S SUMMARY | 1:7353 | absent | Entire summary module missing. |
| 14 Completed | 1:7355 | absent | Count is placeholder/slot data. |
| 100% Pass Rate | 1:7358 | absent | **Forbidden score** — do not implement as a quality/pass score; needs product-approved non-score replacement or omission. |
| Avatar photo | 1:7373 | initials avatar (TechnicianAvatar) | Photo asset not wired; slot-sheet must confirm photo use. |

## Could not verify

- Shadow colours/alphas: the dump prints only `DROP_SHADOW(blur x, y)`; it does not expose RGB/alpha, so equivalence with `TrShadows.card` / `floating` cannot be proven.
- Vector glyph identities: `1:7302`, `1:7318`, `1:7328`, `1:7335`, `1:7343`, `1:7350`, `1:7360`, `1:7378`, `1:7383`, `1:7388`, `1:7393` are unnamed vectors; only size/colour are auditable. Exact icon semantics are inferred from the preview.
- Profile `fill=IMAGE` (`1:7373`) has no asset reference; cannot confirm an approved photo asset exists.
- No `geometry.json` was present for the current render; current boxes/positions were derived from code tokens, not measured pixels (only the PNG size 390x884 was read).
- Padding inconsistency in the dump: `1:7290` declares `pad=8,0,16,0` while its children start at x20; horizontal padding cannot be reconciled from text alone.
- No slot-sheet document was found in the provided paths; slot status is inferred from the brief.
- Figma frame is 883.75 high vs 884 render; sub-pixel rounding and font rasterisation differences are not verifiable.
