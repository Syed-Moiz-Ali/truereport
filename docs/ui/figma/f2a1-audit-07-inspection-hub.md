# F2A-07 Main Inspection Hub — node audit

Read-only audit. Figma values are copied from `docs/ui/figma/f2a1-nodes/07-inspection-hub.txt` (node `1:7742`, 390x1130 frame). Current values are code-derived from `inspection_hub_view.dart` plus the design-system tokens/components and the 390x1130 render `inspection-hub_en_1.0x.png`. `PJS` = Plus Jakarta Sans. Shadow notation = blur / offset. `—` = node has a box but no text/fill/shadow/radius style. “Content” = no fixed height in Flutter.

| Node id | Name | Figma box | Figma style | Current Flutter value | Delta | Required fix |
|---|---|---|---|---|---|---|
| 1:7742 | 7. Main Inspection Hub | @0,0 390x1130 | fill #FFFFFF, vertical, gap 0, pad 0 | AppScaffold + scrollable ListView, 390 wide | Fixed 1130 vs scrollable; screenshot is 390x1130 | Accept scroll; do not hard-code 1130 |
| 1:7743 | Main | @0,0 390x1130 | fill #FFFFFF, vertical, pad 64,0,112,0 | appBar 64 + body; dock is bottomNavigationBar | No 112 bottom content pad | Add content bottom inset above dock or document dock overlap |
| 1:7744 | Container | @0,64 390x954 | — | ListView body | Content-driven | — |
| 1:7745 | Status Badge & Micro Greeting:margin | @20,80 350x42 | vertical, pad 0,0,16,0 | ListView top pad gutter 20 (y=84) | y +4; bottom gap 16 exists via SizedBox lg | Set top pad 16 |
| 1:7746 | Status Badge & Micro Greeting | @20,80 350x26 | horizontal, gap 35.36 | `Wrap` spacing 8, runSpacing 4, 350 wide | No fixed 26 row; wraps to 2 rows | Single row: status pill left, Bay text right |
| 1:7747 | Background+Shadow | @20,80 195.59x26 | r9999, fill #F4F3F8, fx 8/0,2, gap 8, pad 6,12,6,12 | `StatusChip` info: pad 12/4, r999, fill #E5F0F8, no shadow | Height ~24 vs 26; fill wrong; no shadow; pad v 4 vs 6 | Neutral #F4F3F8 chip, 6 v pad, card shadow |
| 1:7748 | Background (dot) | @32,89 8x8 | r9999, fill #10B981 | info icon 20 #1D5C8A | Icon vs 8 dot; wrong colour/size | 8x8 green dot |
| 1:7749 | Container | @48,86 155.59x14 | vertical | text inside chip | — | — |
| 1:7750 | Text | @48,86 155.59x14 | #1A1B1F PJS 700 11/14 +0.55, uppercase | “In progress” PJS 600 12/16 +0.24, #1D5C8A | Case, 12 vs 11, 600 vs 700, lh 16 vs 14, +0.24 vs +0.55, colour | Uppercase status copy + PJS 700 11/14 +0.55 #1A1B1F |
| 1:7751 | Container | @250.95,85 119.05x16 | vertical | absent | Missing right slot | Add right-aligned context slot |
| 1:7752 | Text | @250.95,85 119.05x16 | #5E5D69 PJS 600 12/16 +0.24 | absent | Missing “Bay #04 • VIN 8492” | Data slot: bay + masked identifier, only if modelled |
| 1:7753 | Vehicle Reference Strip:margin | @20,426 350x104 | vertical, pad 0,0,24,0 | `SizedBox(lg)` 16 before vehicle strip | Bottom gap 16 vs 24 | Use 24 |
| 1:7754 | Vehicle Reference Strip | @20,426 350x80 | fill #FFFFFF, fx 8/0,2 + 40/0,14, horizontal gap 50.44, pad 16 | `AppCard` raised, r32, pad 16, card shadow; height 80 by tokens | Shadow/radius/pad match; gap flexible (Expanded) not fixed 50.44 | Keep responsive spacer; if pixel match, pin 50.44 |
| 1:7755 | Container | @36,442 235.56x48 | horizontal, gap 12 | Row: 48 avatar + SizedBox 12 + Expanded column | Match on gap 12 | — |
| 1:7756 | Background | @36,442 48x48 | r9999, fill #EEEDF3 | 48x48 circle, fill surfaceContainer #F4F3F8 | Fill #F4F3F8 vs #EEEDF3 | Use surfaceHigh #EEEDF3 |
| 1:7757 | Vehicle image | @36,442 48x48 | fill IMAGE | `directions_car_outlined` 24 #006C49 on circle | Photo missing; icon instead | Real/generic vehicle image with privacy crop, or approved silhouette |
| 1:7758 | Container | @96,446 175.56x40 | vertical | Expanded text column | Content-driven | — |
| 1:7759 | Heading 2 | @96,446 175.56x22 | vertical | title Text | — | — |
| 1:7760 | Text | @96,446 142.16x22 | #1A1B1F PJS 700 16/22 -0.16 | `titleLarge` 16/22 700 -0.16, “Renault Megane 3” | Style matches; sample data differs | Keep make/model data-driven |
| 1:7761 | Container | @96,468 175.56x18 | vertical | meta Text | — | — |
| 1:7762 | Text | @96,468 175.56x18 | #5E5D69 PJS 400 13/18, ls 0 | `bodySmall` 12/18 400 ls 0; “JOB-5A0001 • 34,180 MI” | 12 vs 13; reference vs plate/VIN; unit case | 13/18 body style; slot plate/VIN + odometer, not job ref |
| 1:7763 | Background (chevron) | @322,450 32x32 | r9999, fill #F4F3F8 | No container behind chevron | Missing 32 circle | Add 32x32 #F4F3F8 circle |
| 1:7764 | Container | @335.23,461.5 5.55x9 | vertical | `Icons.chevron_right` 24 | Glyph box 24 vs 5.55x9 | Use ~10x16 chevron inside 32 circle |
| 1:7765 | Icon | @335.23,461.5 5.55x9 | fill #5E5D69 | `chevron_right` #5E5D69 24 | Size only | Match glyph size |
| 1:7766 | Section Header:margin | @20,530 350x34 | vertical, pad 0,0,12,0 | section title + `SizedBox(md)` 12 | Bottom gap matches | — |
| 1:7767 | Section Header | @20,530 350x22 | horizontal, gap 114.66, pad 0,4,0,4 | Row, Expanded title, trailing; no v pad | Missing 4 v pad; flexible gap | Add 4 v pad; gap is content-driven |
| 1:7768 | Heading 3 | @24,530 150x22 | vertical | Expanded title | — | — |
| 1:7769 | Text | @24,530 150x22 | #1A1B1F PJS 700 16/22 -0.16 | “Inspection modules” `titleLarge` 16/22 700 -0.16 | Case: lowercase “modules” vs title case | Title-case copy “Inspection Modules” or accept locale |
| 1:7770 | Container | @288.66,533 77.34x16 | vertical | `TechnicianMetaPill` | Pill wrapper vs plain text | Remove pill background |
| 1:7771 | Text | @288.66,533 77.34x16 | #5E5D69 PJS 600 12/16 +0.24 | “4 categories” 12/16 600 +0.24 in pill (minHeight 32, pad 12/4) | Case; extra #F4F3F8 pill, 32 high vs 16 | Plain text, title case, no pill |
| 1:7772 | Hero Circular Progress Card:margin | @20,122 350x302 | vertical, pad 0,0,24,0 | AppCard + `SizedBox(lg)` 16 | Bottom gap 16 vs 24; y driven by status | Use 24 gap |
| 1:7773 | Hero Circular Progress Card | @20,122 350x278 | r32, fill #FFFFFF, fx 8/0,2 + 40/0,14, vertical, pad 24 | AppCard r32, pad 24, card shadow; content-driven height | Height not fixed 278; 3 chips wrap | Keep 3 product chips or constrain card; do not fake 278 |
| 1:7774 | Margin | @107,146 176x192 | vertical, pad 8,0,8,0 | ring + gap 16 + chips; no 8 v pad | Missing 8 top/bottom pad | Add 8 v pad if matching |
| 1:7775 | Container | @107,154 176x176 | horizontal | `TechnicianCoverageRing(size:176)` | 176 matches | — |
| 1:7776 | SVG Progress Ring (45% filled) | @107,154 176x176 | fixed composed asset | CustomPaint 176x176, fraction 45/110 = 40.9% | Fixed “45%” vs dynamic 40.9% | Keep dynamic; never hard-code 45% |
| 1:7777 | Vector (track) | @122.4,169.4 145.2x145.2 | stroke #EEEDF3 @13.2 | circle diameter 164 (r=82), stroke 12, #E9E7ED | Track colour #E9E7ED vs #EEEDF3; stroke 12 vs 13.2; diameter 164 vs path 145.2 (outer 158.4) | Use #EEEDF3, stroke 13.2, inset/path diameter 145.2 |
| 1:7778 | Vector (arc) | @195,169.4 72.61x141.77 | stroke #10B981 @13.2 | arc #10B981, fraction 0.409, stroke 12 | Colour matches; stroke 12 vs 13.2; sweep dynamic vs fixed asset | Stroke 13.2; derive sweep from completed/total |
| 1:7779 | Centered Progress Details | @107,154 176x176 | vertical | Stack centered | — | — |
| 1:7780 | Paragraph | @165.58,218 58.83x32 | — | Column | — | — |
| 1:7781 | Text “45” | @165.58,217.5 31.89x32 | #1A1B1F PJS 800 26/32 -0.65, centre | `displayMedium` 26/32 800 -0.65 but `height:1` | Line height 26 vs 32 | Remove height:1 or set 32 |
| 1:7782 | Text “/110” | @197.47,228 26.94x20 | #5E5D69 PJS 500 14/20 -0.07, centre | “of 110” `bodyMedium` 14/20 500 -0.07 | Copy “of 110” vs “/110”; style matches | Keep product “of 110” or match slash slot |
| 1:7783 | Margin | @151.69,250 86.63x16 | vertical, pad 2,0,0,0 | `SizedBox(xs)` 4 | Top gap 4 vs 2 | Use 2 |
| 1:7784 | Container | @151.69,252 86.63x14 | vertical | label Text | — | — |
| 1:7785 | Text “CHECKS DONE” | @151.69,252 86.63x14 | #5E5D69 PJS 700 11/14 +0.55, uppercase, centre | “checks done” PJS 700 12/16 +0.24, not uppercase | Case, 12 vs 11, lh 16 vs 14, tracking | Uppercase 11/14 +0.55 |
| 1:7786 | Quick Stat Pills:margin | @44,338 302x38 | vertical, pad 12,0,0,0 | `SizedBox(lg)` 16 | Top gap 16 vs 12 | Use 12 |
| 1:7787 | Quick Stat Pills | @44,350 302x26 | horizontal, gap 8 | `Wrap` spacing 8, run 4, 3 chips | 3 vs 2 chips; wraps; no fixed 26 row | Approved taxonomy; if Figma parity, 2 chips one row |
| 1:7788 | Background (passed pill) | @77.96,350 101.36x26 | r9999, fill #F4F3F8, gap 6, pad 6,12,6,12 | `StatusChip` success: fill #E6F3EC, pad 12/4, r999 | Fill/height/pad differ | Neutral #F4F3F8 pill, 26 high, 6 v pad |
| 1:7789 | Container (passed icon) | @89.96,356.33 13.33x13.33 | vertical | Icon 20 | 20 vs 13.33 | 13.33 icon box |
| 1:7790 | Icon (passed) | @89.96,356.33 13.33x13.33 | fill #10B981 | `check_circle_outline` 20 #1F6B45 | Size, colour, glyph | Green check 13.33 #10B981 |
| 1:7791 | Container | @109.29,356 58.03x14 | vertical | Text | — | — |
| 1:7792 | Text “42 Passed” | @109.29,356 58.03x14 | #1A1B1F PJS 600 11/14 +0.44, centre | “42 No issue observed” 12/16 600 +0.24 #1F6B45 | Forbidden “Passed” avoided; 12 vs 11; lh 16 vs 14; +0.24 vs +0.44; colour | Keep approved “No issue observed”; style 11/14 +0.44 #1A1B1F |
| 1:7793 | Background (action pill) | @187.32,350 124.72x26 | r9999, fill #F4F3F8, gap 6, pad 6,12,6,12 | warning chip fill #FFF4D6, pad 12/4 | Fill/height/pad | Neutral pill; keep warning semantics only if needed |
| 1:7794 | Container (action icon) | @199.32,356.33 13.33x13.33 | vertical | Icon 20 | 20 vs 13.33 | 13.33 |
| 1:7795 | Icon (action) | @199.32,356.33 13.33x13.33 | fill #B91A24 | warning icon #8A5A00 20 | Colour/size/glyph | 13.33 #B91A24 alert glyph |
| 1:7796 | Container | @218.65,356 81.39x14 | vertical | Text | — | — |
| 1:7797 | Text “3 Action Items” | @218.65,356 81.39x14 | #1A1B1F PJS 600 11/14 +0.44, centre | “3 Attention recommended” 12/16 600 +0.24 #8A5A00 | Copy, 12 vs 11, lh, tracking, colour | Map to approved result label; style 11/14 +0.44 |
| 1:7798 | 2-Column Grid:margin | @20,564 350x374 | vertical, pad 0,0,24,0 | Wrap + `SizedBox(xl)` 24 | Bottom gap matches | — |
| 1:7799 | 2-Column Grid | @20,564 350x350 | GRID gap 0 (positions give 16 gutter) | Wrap spacing 16, run 16, 2 cols, 167 wide | Fixed 170/167 uncaptured; height content-driven | Fixed 167x167 cards, 16 gutters |
| 1:7800 | Card 1 Exterior | @20,564 167x167 | r32, fill #FFFFFF, fx 8/0,2 + 40/0,14, vertical gap 45, pad 20 | `TechnicianModuleCard`/AppCard r32, pad 20, card shadow, content height | Height content-driven; internal gap 45 vs token stack; check pin absent | Fixed 167; add top status pin; match vertical rhythm |
| 1:7801 | Container | @40,584 127x40 | horizontal, gap 59 | No 40-high top row | Structural | Add top row: icon tile + status pin/count |
| 1:7802 | Background (icon tile) | @40,584 40x40 | r9999, fill #F4F3F8 | 40x40, fill #F4F3F8, radius lg 12 | Radius 12 vs circle | Use circle |
| 1:7803 | Container | @51.75,596.67 16.5x14.67 | vertical | Icon 20 | 20 vs 16.5x14.67 | Match icon size |
| 1:7804 | Icon (exterior) | @51.75,596.67 16.5x14.67 | fill #1A1B1F | car icon 20 #006C49 | Size, colour, glyph | 16.5x14.67 #1A1B1F |
| 1:7805 | Active Checkmark Pin | @139,590 28x28 | r9999, fill #10B981, fx 24/0,8 | absent | Missing completed pin | Add 28x28 green check pin |
| 1:7806 | Container | @146.89,599.49 12.23x9.02 | vertical | absent | Missing | — |
| 1:7807 | Icon (check) | @146.89,599.49 12.23x9.02 | fill #FFFFFF | absent | Missing white check | 12.23x9.02 white check |
| 1:7808 | Container | @40,669 127x42 | vertical, gap 4 | text column | — | — |
| 1:7809 | Heading 4 | @40,669 127x24 | vertical | title | — | — |
| 1:7810 | Text “Exterior” | @40,669 127x24 | #1A1B1F PJS 800 18/24 -0.27 | `titleLarge` 16/22 700 -0.16 | 16/22/700 vs 18/24/800 | PJS 800 18/24 -0.27 |
| 1:7811 | Container | @40,697 127x14 | horizontal, gap 53.47 | count and state stacked | Missing same-row layout | Put count + status dot on one row |
| 1:7812 | Container | @40,697 67.53x14 | vertical | count Text | — | — |
| 1:7813 | Text “28/28 Done” | @40,697 67.53x14 | #10B981 PJS 700 11/14 +0.44 | “28/28 checks” 12/18 400 #5E5D69 + “Done” 12/16 700 | Copy, colour, size/weight, split lines | “28/28 Done” green 11/14 700, or approved copy |
| 1:7814 | Background (dot) | @161,701 6x6 | r9999, fill #10B981 | absent | Missing green dot | Add 6x6 green dot |
| 1:7815 | Card 2 Interior | @203,564 167x167 | r32, white, fx 8/0,2 + 40/0,14, gap 41, pad 20 | same module card | Height/gap; count pill, progress bar absent | Fixed 167; add 17/32 pill + 40x6 progress |
| 1:7816 | Container | @223,584 127x40 | horizontal, gap 39.36 | no top row | Structural | Add top row |
| 1:7817 | Background (icon tile) | @223,584 40x40 | r9999, #F4F3F8 | 40x40, #F4F3F8, r12 | Radius | Circle |
| 1:7818 | Container | @234.64,594.83 16.73x18.33 | vertical | Icon 20 | Size | Match |
| 1:7819 | Icon (interior) | @234.64,594.83 16.73x18.33 | fill #1A1B1F | chair icon 20 #006C49 | Size/colour | 16.73x18.33 #1A1B1F |
| 1:7820 | Background (count pill) | @302.36,590 47.64x28 | r9999, #F4F3F8, pad 6.5,8,7.5,8 | absent | Missing top-right “17/32” pill | Add 47.64x28 pill |
| 1:7821 | Text “17/32” | @310.36,596.5 31.64x14 | #5E5D69 PJS 700 11/14 +0.44 | “17/32 checks” 12/18 400 in lower block | Position and style | 11/14 700 +0.44 in pill |
| 1:7822 | Container | @223,665 127x46 | vertical, gap 4 | text column | — | — |
| 1:7823 | Heading 4 | @223,665 127x24 | vertical | title | — | — |
| 1:7824 | Text “Interior” | @223,665 127x24 | #1A1B1F 800 18/24 -0.27 | 16/22 700 | Size/weight | 18/24 800 |
| 1:7825 | Container | @223,693 127x18 | horizontal, gap 22.75 | count and state stacked | Missing same row | Row: state + progress bar |
| 1:7826 | Container | @223,693 64.25x18 | vertical | state text | — | — |
| 1:7827 | Text “Active Bay” | @223,693 64.25x18 | #5E5D69 PJS 400 13/18, ls 0 | “In progress” 12/16 700 | Copy, 13 vs 12, 400 vs 700, lh 18 vs 16 | Slot active state; approved “In progress” is safer |
| 1:7828 | Background (progress track) | @310,699 40x6 | r9999, #EEEDF3 | absent | Missing progress track | Add 40x6 #EEEDF3 |
| 1:7829 | Background (progress fill) | @310,699 20x6 | r9999, #10B981 | absent | Missing fill | Fill from 17/32 (53.1%), not fixed 50% |
| 1:7830 | Card 3 Engine | @20,747 167x167 | r32, white, fx 8/0,2 + 40/0,14, gap 41, pad 20 | same module card | Height/gap; pending dot absent | Fixed 167; add pending dot |
| 1:7831 | Container | @40,767 127x40 | horizontal, gap 79 | no top row | Structural | Add top row |
| 1:7832 | Background (icon tile) | @40,767 40x40 | r9999, #F4F3F8 | 40x40, #F4F3F8, r12 | Radius | Circle |
| 1:7833 | Container | @52.67,777.83 14.67x18.33 | vertical | Icon 20 | Size | Match |
| 1:7834 | Icon (engine) | @52.67,777.83 14.67x18.33 | fill #5E5D69 | settings icon 20 #006C49 | Size/colour | 14.67x18.33 #5E5D69 |
| 1:7835 | Background (pending dot) | @159,783 8x8 | r9999, #E9E7ED | absent | Missing pending dot | Add 8x8 #E9E7ED |
| 1:7836 | Container | @40,848 127x46 | vertical, gap 4 | text column | — | — |
| 1:7837 | Heading 4 | @40,848 127x24 | vertical | title | — | — |
| 1:7838 | Text “Engine” | @40,848 127x24 | #1A1B1F 800 18/24 -0.27 | 16/22 700 | Size/weight | 18/24 800 |
| 1:7839 | Container | @40,876 127x18 | horizontal, gap 0.64 | count and state stacked | Missing row | Row |
| 1:7840 | Container | @40,876 80.31x18 | vertical | count text | — | — |
| 1:7841 | Text “0/24 Checks” | @40,876 80.31x18 | #5E5D69 PJS 400 13/18 | “0/24 checks” 12/18 400 | 12 vs 13; case | 13/18; copy “Checks” |
| 1:7842 | Container | @120.95,878 46.05x14 | vertical | state text | — | — |
| 1:7843 | Text “Queued” | @120.95,878 46.05x14 | #5E5D69 PJS 600 11/14 +0.44 | “Not started” 12/16 700 | Copy, 12 vs 11, lh 16 vs 14, 700 vs 600 | “Queued” 11/14 600 or approved state |
| 1:7844 | Card 4 Underbody | @203,747 167x167 | r32, white, fx 8/0,2 + 40/0,14, gap 41, pad 20 | same module card | Height/gap; pending dot absent | Fixed 167; add pending dot |
| 1:7845 | Container | @223,767 127x40 | horizontal, gap 79 | no top row | Structural | Add top row |
| 1:7846 | Background (icon tile) | @223,767 40x40 | r9999, #F4F3F8 | 40x40, #F4F3F8, r12 | Radius | Circle |
| 1:7847 | Container | @235.67,778.29 14.67x17.42 | vertical | Icon 20 | Size | Match |
| 1:7848 | Icon (underbody) | @235.67,778.29 14.67x17.42 | fill #5E5D69 | build icon 20 #006C49 | Size/colour | 14.67x17.42 #5E5D69 |
| 1:7849 | Background (pending dot) | @342,783 8x8 | r9999, #E9E7ED | absent | Missing pending dot | Add 8x8 #E9E7ED |
| 1:7850 | Container | @223,848 127x46 | vertical, gap 4 | text column | — | — |
| 1:7851 | Heading 4 | @223,848 127x24 | vertical | title | — | — |
| 1:7852 | Text “Underbody” | @223,848 127x24 | #1A1B1F 800 18/24 -0.27 | 16/22 700 | Size/weight | 18/24 800 |
| 1:7853 | Container | @223,876 127x18 | horizontal, gap 0.93 | count and state stacked | Missing row | Row |
| 1:7854 | Container | @223,876 80.02x18 | vertical | count text | — | — |
| 1:7855 | Text “0/26 Checks” | @223,876 80.02x18 | #5E5D69 PJS 400 13/18 | “0/26 checks” 12/18 400 | 12 vs 13; case | 13/18; copy “Checks” |
| 1:7856 | Container | @303.95,878 46.05x14 | vertical | state text | — | — |
| 1:7857 | Text “Queued” | @303.95,878 46.05x14 | #5E5D69 PJS 600 11/14 +0.44 | “Not started” 12/16 700 | Copy, size, weight | “Queued” 11/14 600 or approved state |
| 1:7858 | Floating Sticky Action:margin | @20,938 350x64 | vertical, pad 8,0,0,0 | CTA inline in ListView; `SizedBox(xl)` 24 before | Not sticky; top gap 24 vs 8 | Pin above dock or use 8 top pad; keep scroll inset |
| 1:7859 | Floating Sticky Action button | @20,946 350x56 | r9999, fill #10B981, fx 25/0,10, horizontal gap 8 | AppButton large: fill brand.largeFill #059669, r999, h56, buttonSubtle shadow | Fill #059669 vs #10B981; shadow grey vs emerald; padding 24 | Use #10B981 + emerald 25/0,10; label/style |
| 1:7860 | Container (icon) | @97.53,968.17 9.17x11.67 | vertical | `arrow_forward` 24 | Icon/size | Play glyph 9.17x11.67 |
| 1:7861 | Icon | @97.53,968.17 9.17x11.67 | fill #FFFFFF | arrow_forward 24 #FFFFFF | Size/glyph | White play glyph |
| 1:7862 | Text | @114.7,965 177.77x18 | #FFFFFF PJS 700 14/18 -0.14, centre | “Continue checklist • Interior” PJS 700 19/24 -0.19 | 19 vs 14, lh 24 vs 18, -0.19 vs -0.14, copy order | 14/18 700 -0.14; “Continue {category} Checklist” |
| 1:7863 | Header | @0,0 390x64 | fill #FFFFFFCC, fx 8/0,1 + blur 48, vertical | AppBar 64, fill #FFFFFF opaque, elevation 0 | No translucency/blur/shadow | Translucent blurred bar or document deviation |
| 1:7864 | Container | @0,0 390x64 | horizontal, gap 160.7, pad 0,20,0,20 | AppBar titleSpacing 20, actions | — | — |
| 1:7865 | Container | @20,14 157.3x36 | horizontal, gap 12 | title only; avatar separate | Missing 36 leading tile + 12 gap | Add 36x36 hub icon tile; title x=68 |
| 1:7866 | Background | @20,14 36x36 | r9999, #F4F3F8 | absent | Missing leading tile | Add 36x36 #F4F3F8 |
| 1:7867 | Container | @28.83,23.25 18.33x17.5 | vertical | absent | Missing | — |
| 1:7868 | Icon | @28.83,23.25 18.33x17.5 | fill #006C49 | absent | Missing hub icon | 18.33x17.5 #006C49 |
| 1:7869 | Heading 1 | @68,18 109.3x28 | vertical | AppBar title at x20 | x offset -48 | Add leading block |
| 1:7870 | Text “Intake Hub” | @68,18 109.3x28 | #1A1B1F PJS 700 22/28 -0.55 | “Inspection hub” 22/28 700 -0.44 | Copy; tracking -0.44 vs -0.55 | Product title or “Intake Hub”; tracking -0.55 |
| 1:7871 | Background (profile) | @338,16 32x32 | r9999, fill #006C49 | `TechnicianAvatar` 40x40, fill #D9FBE8 | 40 vs 32; container green vs deep green | 32x32 #006C49 |
| 1:7872 | Container | @348,26 12x12 | vertical | initials “DV” 14px | Text vs 12x12 icon | 12x12 icon box |
| 1:7873 | Icon (profile) | @348,26 12x12 | fill #FFFFFF | initials #00422B | Icon vs text; colour | 12x12 white person glyph |
| 1:7874 | Nav | @0,1050 390x80 | vertical, pad 0,20,16,20 | bottomNavigationBar dock; SafeArea; start/end 24, bottom 8 | Horizontal 24 vs 20; bottom 8 vs 16; total height content | Match 20/16 insets |
| 1:7875 | Background+Shadow | @20,1050 350x64 | r9999, #FFFFFF, fx 12/0,4 + 50/0,18, gap 23.5, pad 0,16 | AppBottomNavDock: 342 wide, r999, #FFFFFF, floating shadow, pad 4 | Width 342 vs 350; pad 4 vs 16; gap flexible | 350 wide, pad 16, gap 23.5 |
| 1:7876 | Link (Intake) | @47.75,1060 56x44 | vertical, gap 2, pad 3,10.14,3,10.14 | Expanded nav item, min 48, pad 4 | Size/pad differ | 56x44 item, 3/10.14 pad |
| 1:7877 | Container | @66.58,1063.92 18.33x20.17 | vertical | Icon 24 | 24 vs 18.33x20.17 | Match icon box |
| 1:7878 | Icon (Intake) | @66.58,1063.92 18.33x20.17 | fill #1A1B1F | `work_outline`/`work` 24 selected | Wrong icon; size | Intake icon 18.33x20.17 |
| 1:7879 | Container | @57.89,1086.08 35.72x14 | vertical | label Text | — | — |
| 1:7880 | Text “Intake” | @57.89,1086.08 35.72x14 | #1A1B1F PJS 600 11/14 +0.44 | “Jobs” 12/16 600/700 +0.3 | Copy, 12 vs 11, lh, +0.3 vs +0.44 | “Intake” 11/14 600 +0.44, or approved “Jobs” style |
| 1:7881 | Link (Fleet) | @127.25,1060 56x44 | vertical, gap 2, pad 3,13.37 | absent (3-item dock) | Missing Fleet item | Remove (out of scope) or add 4th item |
| 1:7882 | Container | @147,1066.67 16.5x14.67 | vertical | absent | Missing | — |
| 1:7883 | Icon (Fleet) | @147,1066.67 16.5x14.67 | fill #5E5D69 | absent | Missing | — |
| 1:7884 | Container | @140.61,1083.33 29.27x14 | vertical | absent | Missing | — |
| 1:7885 | Text “Fleet” | @140.61,1083.33 29.27x14 | #5E5D69 PJS 600 11/14 +0.44 | absent | Missing | — |
| 1:7886 | Link (Sync) | @206.75,1060 56x44 | vertical, gap 2, pad 3,13.87 | Expanded index 1; min 48 | Position/size/pad | 56x44 at index 2 |
| 1:7887 | Container | @227.42,1066.67 14.67x14.67 | vertical | Icon 24 | 24 vs 14.67 | Match |
| 1:7888 | Icon (Sync) | @227.42,1066.67 14.67x14.67 | fill #5E5D69 | `sync_outlined` 24 #5E5D69 | Size only | 14.67 box |
| 1:7889 | Container | @220.63,1083.33 28.25x14 | vertical | label | — | — |
| 1:7890 | Text “Sync” | @220.63,1083.33 28.25x14 | #5E5D69 PJS 600 11/14 +0.44 | “Sync” 12/16 600 +0.3 | 12 vs 11; lh; tracking | 11/14 +0.44 |
| 1:7891 | Link (Profile) | @286.25,1060 56x44 | vertical, gap 2, pad 3,9.19 | Expanded index 2; min 48 | Position/size/pad | 56x44 at index 3 |
| 1:7892 | Container | @305.14,1066.21 18.2x15.58 | vertical | Icon 24 | 24 vs 18.2x15.58 | Match |
| 1:7893 | Icon (Profile) | @305.14,1066.21 18.2x15.58 | fill #5E5D69 | `person_outline` 24 #5E5D69 | Size | 18.2x15.58 |
| 1:7894 | Container | @295.42,1083.79 37.64x14 | vertical | label | — | — |
| 1:7895 | Text “Profile” | @295.42,1083.79 37.64x14 | #5E5D69 PJS 600 11/14 +0.44 | “Profile” 12/16 600 +0.3 | 12 vs 11; lh; tracking | 11/14 +0.44 |

## Structural fixes

- Add the missing header leading block: 36x36 #F4F3F8 circle + 18.33x17.5 #006C49 hub icon; move title from x20 to x68 (`1:7865-1:7869`).
- Replace the 40x40 initial avatar with a 32x32 #006C49 profile circle containing a 12x12 white person icon (`1:7871-1:7873`).
- Rebuild the status row as one 350x26 row: neutral 26-high status pill left, right-aligned bay/VIN text at x250.95; remove the stacked “Versions 1” pill from this row (`1:7746-1:7752`).
- Make the hero card a 350x278 fixed card with a 176 ring and a single 26-high stat row; the current 3-chip `Wrap` wraps to multiple rows (`1:7772-1:7797`).
- Put the CTA in the floating/sticky position above the dock (8 px top margin, 350x56) instead of inline after the grid (`1:7858-1:7859`).
- Restore the 4-item dock geometry (350x64, 16 pad, 23.5 gap, 56x44 links) or explicitly keep the 3-item product dock; the current dock is 342 wide (`1:7874-1:7895`).
- Module cards: add the top 40-high row (icon tile + completed pin / count pill / pending dot) and the Interior 40x6 progress bar; current cards only stack icon, title, count, state (`1:7800-1:7857`).

## Type / fill / shadow fixes

- `#10B981` is the CTA/ring/check fill in Figma; current large CTA uses `brand.largeFill` `#059669` and a subtle grey shadow. Use `#10B981` and the emerald 25/0,10 shadow (`1:7859`).
- Ring track is `#EEEDF3` @13.2 stroke; current uses `#E9E7ED` @12. Use `surfaceHigh` and 13.2 (`1:7777`).
- Current result chips use tone backgrounds (`#E6F3EC`, `#FFF4D6`, `#FBE9E7`); Figma pills are neutral `#F4F3F8` with `#10B981`/`#B91A24` icons and `#1A1B1F` text (`1:7788-1:7797`).
- Module titles are PJS 800 18/24 -0.27; current `titleLarge` is 16/22 700 -0.16. Module icons are #1A1B1F/#5E5D69 at 14.67-16.73; current 20 #006C49 (`1:7810-1:7857`).
- Section meta is plain 12/16 600 +0.24 text; current wraps it in a 32-high #F4F3F8 `TechnicianMetaPill` (`1:7770-1:7771`).
- Status/ring/nav labels are PJS 700/600 11/14 +0.44/+0.55; current uses 12/16 +0.24/+0.30. Ring `45` has line-height 1 (26) vs 32 (`1:7781`).
- `45` numeral and `CHECKS DONE` need 26/32 and 11/14 uppercase; current shows 26/26 and mixed-case 12/16 (`1:7781`, `1:7785`).

## Slot-sheet items

| Item | Figma | Current | Required fix |
|---|---|---|---|
| Bay #04 / VIN 8492 | `1:7752` 12/16 600 #5E5D69, right of status | Absent; no bay field; `vehicleVin` exists | Add optional bay + masked-VIN slot; do not print “VIN 8492” as a VIN |
| “42 Passed” | `1:7792` neutral pill, green check | “42 No issue observed” success chip | Keep approved label; “Passed” is forbidden |
| “3 Action Items” | `1:7797` neutral pill, #B91A24 alert icon | “3 Attention recommended” warning chip | Map to approved result/severity; define “Action Items” |
| Vehicle photo + plate/VIN | `1:7757` 48x48 image; `WA1-VAA-Y7890 • 12,480 mi` | Car icon; `JOB-5A0001 • 34,180 MI` | Use real/generic photo with privacy crop; slot plate/VIN/odometer from job |
| “Active Bay” | `1:7827` 13/18 400 | “In progress” 12/16 700 | No active-bay field; keep derived “In progress” or add/define field |
| Fixed 45%/110 ring | `1:7776` fixed 45% asset; text `45/110` (40.9%) | Dynamic 45/110, 40.9%; 176 size | Keep dynamic count; never hard-code 45%; align track/stroke |
| Sample model | `1:7760` “Porsche Taycan 4S” | “Renault Megane 3” fixture/production job | Keep make/model data-driven; never ship the sample name |

## Could not verify

- Exact shadow colours/opacities: the dump gives only `DROP_SHADOW(blur x,y)`, not colour or alpha.
- Exact vector glyph identities; only boxes and fills are in the dump (`1:7765`, `1:7804`, `1:7868`, nav icons).
- Vehicle image content, provenance, and whether the plate is visible (`1:7757`); the dump only says `IMAGE`.
- Whether the Figma arc is 45% or 40.9%; the composed asset is named 45% while the text is `45/110`.
- Runtime boxes after text scaling, font fallback, locale (Arabic/RTL), and real API data; current values are code-derived.
- Exact grid gutter: `1:7799` says `GRID gap=0` but child x positions imply 16 px; not stated in the dump.
- Header blur/translucency fidelity and whether the current AppBar shadow is visible in every platform render.
- Testing/visual regression output for dark theme; only the light 1.0x render was inspected.
