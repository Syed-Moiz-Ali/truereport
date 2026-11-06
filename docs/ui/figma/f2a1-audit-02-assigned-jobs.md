# F2A-1 Audit 02 — Assigned Jobs Dashboard

Source: `docs/ui/figma/f2a1-nodes/02-assigned-jobs.txt` (all boxes below are copied from that dump). Current values are read from `assigned_jobs_view.dart`, `technician_shell.dart`, `cards.dart`, `chips.dart`, `navigation.dart`, `buttons.dart` and `generated/tokens.g.dart`. Figma font is Plus Jakarta Sans throughout. "CR" = current Flutter.

| Node id | Name | Figma box | Figma style | Current Flutter value | Delta | Required fix |
|---|---|---|---|---|---|---|
| 1:7131 | Frame "2. Assigned Jobs Dashboard" | @0,0 390x1002 | fill #FFFFFF, vertical | Scaffold #FFFFFF, capture 390x1002 | none | — |
| 1:7132 | Main | @0,0 390x1002 | vertical, pad 64,20,112,20 | AppBar 64 + ListView pad 20/20 + bottom dock 80 | bottom pad ~80 vs 112; content vertical rhythm differs | Align body gutters/top to 20 and reserve 112 bottom inset |
| 1:7133 | Container | @20,64 350x826 | vertical gap 0 | ListView children | — | — |
| 1:7134 | Top Bar / Avatar & Status Badge | @20,64 350x88 | horizontal gap 159.83, pad 8,0,24,0 | `_WelcomeRow`: avatar + welcome text, no badge | Avatar merged into welcome row; badge missing; row height not 88 | Split avatar/status row from welcome; add truthful shift/bay or omit |
| 1:7135 | Container | @20,72 56x56 | vertical | Avatar size 48 (`targetMin`) | 48 vs 56 | 56 |
| 1:7136 | Overlay+Shadow | @20,72 56x56 r9999 | fill #10B98126, shadow 16/4 | No halo/shadow | Missing mint halo + glow | 56 circle #10B98126 with 16/4 shadow |
| 1:7137 | Background | @26,78 44x44 r9999 | fill #10B981 | Avatar bg `brand.container` #D9FBE8 | Fill #D9FBE8 vs #10B981; 48 vs 44 | Solid emerald circle |
| 1:7138 | Text "DV" | @35.7,87.5 24.61x24 | 18/700 lh24 ls-0.45 #FFFFFF center | `labelLarge` 14/18 w800 #00422B | 14 vs 18; lh 18 vs 24; colour | 18/24 w700 white initials |
| 1:7139 | Background (online dot ring) | @62,114 16x16 r9999 | fill #FFFFFF | None | Missing online indicator | Add 16 white ring |
| 1:7140 | Background (dot) | @65,117 10x10 r9999 | fill #10B981 | None | Missing | 10 emerald dot |
| 1:7141 | Background+Shadow (shift pill) | @237.16,87 132.84x26 r9999 | #F4F3F8, shadow 8/2, pad 6,12,6,12 | None | Absent | Slot-sheet; see SHIFT item |
| 1:7142 | Container (shift icon) | @249.16,93 14.67x14 | vertical | None | Absent | — |
| 1:7143 | Vector "Icon" | @249.16,93 14.67x14 | #006C49 | None | Absent | If kept, 14.67 gear in #006C49 |
| 1:7144 | Container (shift text) | @269.83,93 88.17x14 | vertical | None | Absent | — |
| 1:7145 | Text "SHIFT 1 • BAY A" | @269.83,93 88.17x14 | 11/700 lh14 ls0.55 #3C4A42 | None | Absent | Slot-sheet |
| 1:7146 | Welcome Headline:margin | @20,152 350x90 | vertical, pad bottom 32 | `SizedBox` `lg`=16 before snapshot | 32 vs 16 | 32 |
| 1:7147 | Welcome Headline | @20,152 350x58 | vertical | Column | — | — |
| 1:7148 | Container | @20,152 350x24 | vertical | Text | — | — |
| 1:7149 | Text "Welcome back," | @20,152 350x24 | 18/600 lh24 ls0 #5E5D69 | `bodyMedium` 14/20 w600 #5E5D69 | 14/20 vs 18/24 | 18/24/600 |
| 1:7150 | Margin | @20,176 350x34 | pad 2,0,0,0 | Implicit line stack | Gap 2 not modelled | 2 top gap |
| 1:7151 | Container | @20,178 350x32 | vertical | Text | — | — |
| 1:7152 | Text "David Vance" | @20,178 350x32 | 26/800 lh32 ls-0.65 #1A1B1F | `displayMedium` 26/32 w800 ls-0.65 `onSurface` | Match | None |
| 1:7153 | Snapshot:margin | @20,242 350x104 | vertical, pad bottom 32 | `SizedBox` `xl`=24 before section | 32 vs 24 | 32 |
| 1:7154 | Snapshot row | @20,242 350x72 | horizontal gap 12 | Row, gap 12, two `Expanded` | Widths match | — |
| 1:7155 | Card 1 | @20,242 169x72 r16 | #FFFFFF, shadow 32/12, pad 16 | `_SnapshotPill` minH 64, pad 12, `surfaceContainer` #F4F3F8, no shadow, r16 | Fill, height, padding, shadow | White card, card shadow, pad 16, minH 72 |
| 1:7156 | Overlay (icon 1) | @36,258 40x40 r48 | #6FFBBE4D | Icon box 32x32 r12 #FFFFFF | 32 vs 40, r12 vs circle, fill | 40 circle #6FFBBE4D |
| 1:7157 | Container (icon 1) | @46.83,271.09 18.33x13.82 | vertical | `Icon` 20 | 20 vs 18.33x13.82 | 18.33x13.82 |
| 1:7158 | Vector (checklist) | @46.83,271.09 18.33x13.82 | #006C49 | `fact_check_outlined` 20 #006C49 | Glyph/size only | Keep product glyph, size 18 |
| 1:7159 | Container (card 1 text) | @88,261 84.2x34 | vertical | Column | — | — |
| 1:7160 | Container (value) | @88,261 84.2x20 | vertical | Text | — | — |
| 1:7161 | Text "3 Tasks" | @88,261 54.61x20 | 16/800 lh20 ls-0.16 #1A1B1F | `titleLarge` 16/22 w800, value "$pendingCheck" | lh 22 vs 20; value is count not "Tasks" | Height 20; retain computed count |
| 1:7162 | Container (label) | @88,281 84.2x14 | vertical | Text | — | — |
| 1:7163 | Text "Pending check" | @88,281 84.2x14 | 11/600 lh14 ls0.44 #5E5D69 | `labelMedium` 12/16 w600 ls0.24 #5E5D69 | 12/16 vs 11/14, tracking | 11/14/600/.44 |
| 1:7164 | Card 2 | @201,242 169x72 r16 | #FFFFFF, shadow 32/12, pad 16 | Same as card 1 | Same as 1:7155 | Same as 1:7155 |
| 1:7165 | Overlay (icon 2) | @217,258 40x40 r48 | #E1DEEC66 | Icon box 32x32 r12 #FFFFFF | 32 vs 40, r12 vs circle, fill | 40 circle #E1DEEC66 |
| 1:7166 | Container (icon 2) | @228.75,268.38 16.5x19.25 | vertical | `Icon` 20 | 20 vs 16.5x19.25 | 16.5x19.25 |
| 1:7167 | Vector (clock) | @228.75,268.38 16.5x19.25 | #5E5D69 | `timelapse_outlined` 20 #006C49 | Icon colour #006C49 vs #5E5D69 | #5E5D69 |
| 1:7168 | Container (card 2 text) | @269,261 76.97x34 | vertical | Column | — | — |
| 1:7169 | Container (value) | @269,261 76.97x20 | vertical | Text | — | — |
| 1:7170 | Text "45 min" | @269,261 50.95x20 | 16/800 lh20 ls-0.16 #1A1B1F | "$inProgress" (0) | False metric; lh | Slot-sheet; keep In progress |
| 1:7171 | Container (label) | @269,281 76.97x14 | vertical | Text | — | — |
| 1:7172 | Text "Avg. turnover" | @269,281 76.97x14 | 11/600 lh14 ls0.44 #5E5D69 | `statusInProgress` | False metric | Slot-sheet |
| 1:7173 | Section Title:margin | @20,346 350x34 | vertical, pad bottom 16 | `SizedBox` `md`=12 before title | 16 vs 12 | 16 |
| 1:7174 | Section Title | @20,346 350x18 | horizontal gap 133, pad 0,4,0,4 | `TechnicianSectionTitle` Row | — | — |
| 1:7175 | Container (title) | @24,346 132.16x18 | vertical | Expanded Column | — | — |
| 1:7176 | Text "ASSIGNED TODAY" | @24,346 132.16x18 | 14/700 lh18 ls0.7 #5E5D69 | `titleLarge` 16/22 w700 ls-0.16 #1A1B1F, "Assigned today" | 16/22 vs 14/18; colour; tracking; case | 14/18/700/.7, #5E5D69, uppercase |
| 1:7177 | Overlay (queue pill) | @289.2,346 76.8x18 r9999 | #10B9811A, pad 2,8,2,8 | `TechnicianMetaPill` emphasized: #D9FBE8, minH 32, pad 12/4 | Fill, height, padding | #10B9811A, h18, pad 8/2 |
| 1:7178 | Text "3 In Queue" | @297.2,348 60.8x14 | 11/700 lh14 ls0.44 #006C49 | `labelMedium` 12/16 w700 #00422B, "3 in queue" | 12/16 vs 11/14; colour; case | 11/14/700/.44 #006C49 |
| 1:7179 | Inspection Queue Cards | @20,380 350x422 | vertical gap 16 | Column, `bottom` `lg`=16 | Match | — |
| 1:7180 | Card 1 | @20,380 350x130 r24 | #FFFFFF, shadow 8/2+40/14, pad 20 | `AppCard` raised r32, pad 20, minH 130 | Radius 32 vs 24 | Use card radius 24 |
| 1:7181 | Container (top row) | @40,400 310x44 | horizontal gap 72.86 | Row with icon, texts, chevron | Structure differs (CR adds meta rows) | Rebuild as badge + title/meta + action |
| 1:7182 | Container (badge+title) | @40,401 193.14x42 | horizontal gap 16 | Row gap 12 | 16 vs 12 | 16 |
| 1:7183 | Background (car badge) | @40,412.67 52x18.67 r16 | #F4F3F8, pad 0,12 | Icon box 40x40 r12 #F4F3F8 | 40x40 vs 52x18.67; r12 vs 16 | 52x18.67 pill r16 |
| 1:7184 | Container (car icon) | @55.49,412.67 21x18.67 | vertical | `Icon` 20 | 20 vs 21x18.67 | 21x18.67 |
| 1:7185 | Vector (car) | @55.49,412.67 21x18.67 | #1A1B1F | `directions_car_outlined` 20 #006C49 | Colour, size | #1A1B1F, 21x18.67 |
| 1:7186 | Container (title/meta) | @108,401 125.14x42 | vertical | Column | — | — |
| 1:7187 | Container (title) | @108,401 125.14x22 | vertical | Text | — | — |
| 1:7188 | Text "Renault Megan 3" | @108,401 125.14x22 | 16/700 lh22 ls-0.16 #1A1B1F | `titleLarge` 16/22 w700 ls-0.16 | Match layout; Figma typo "Megan" | Use real make/model ("Megane") |
| 1:7189 | Margin (subtitle) | @108,423 125.14x20 | pad 2,0,0,0 | `SizedBox` `xs`=4 | 4 vs 2 | 2 |
| 1:7190 | Container (subtitle) | @108,425 125.14x18 | vertical | Meta rows | — | — |
| 1:7191 | Text "ABC 123 • Bay 4" | @108,425 125.14x18 | 13/400 lh18 ls0 #5E5D69 | No plate/bay; reference 14/20 w500 instead | Missing subtitle; extra reference | Slot-sheet; real plate or reference 13/18/400 |
| 1:7192 | Button "Open inspection…" | @306,400 44x44 r9999 | #10B9811A, shadow 14/4 | Plain `Icon` chevron_right 24, no container | Missing tonal circle/shadow | 44 circle #10B9811A |
| 1:7193 | Container (chevron) | @324.61,416.5 6.78x11 | vertical | `Icon` 24 | 24 vs 6.78x11 | 6.78x11 |
| 1:7194 | Vector (chevron) | @324.61,416.5 6.78x11 | #10B981 | `Icons.chevron_right` 24 #5E5D69 | Colour, size | #10B981, 6.78x11 |
| 1:7195 | Container (footer) | @40,460 310x30 | horizontal gap 83.92, pad 12,0,0,0 | Two `Wrap` rows, not one footer | Structure/spacing | One footer row with 12 top gap |
| 1:7196 | Container (status+template) | @40,474 170.33x14 | horizontal gap 6 | StatusChip + reference | Different content | 8 dot + template |
| 1:7197 | Rectangle (status dot) | @40,477 8x8 r9999 | #10B981 | `StatusChip` icon `Icons.circle` 20 | Missing 8px dot; oversized icon | 8x8 #10B981 dot |
| 1:7198 | Container (template) | @54,474 156.33x14 | vertical | Text | — | — |
| 1:7199 | Text "Full Pre-Delivery Inspection" | @54,474 156.33x14 | 11/500 lh14 ls0.44 #5E5D69 | `labelMedium` 12/16 w600 #5E5D69 | 12/16/600 vs 11/14/500 | 11/14/500/.44 |
| 1:7200 | Background (status pill) | @294.25,472 55.75x18 r9999 | #F4F3F8, pad 2,10 | `StatusChip` info #E5F0F8, ~24 high, pad 12/4 | Fill, height, padding | #F4F3F8, h18, pad 2/10 |
| 1:7201 | Text "Ready" | @304.25,474 35.75x14 | 11/600 lh14 ls0.44 #1A1B1F | `labelMedium` 12/16 w600 #1D5C8A | Size/colour/position | 11/14/600 #1A1B1F, bottom-right |
| 1:7202 | Card 2 | @20,526 350x130 r24 | #FFFFFF, shadow 8/2+40/14, pad 20 | Same as card 1 | Radius 32 vs 24 | 24 |
| 1:7203 | Container (top row) | @40,546 310x44 | horizontal gap 72.86 | Same row pattern | Structure differs | As 1:7181 |
| 1:7204 | Container (badge+title) | @40,547 193.14x42 | horizontal gap 16 | Row gap 12 | 16 vs 12 | 16 |
| 1:7205 | Background (car badge) | @40,558.67 52x18.67 r16 | #F4F3F8, pad 0,12 | 40x40 r12 #F4F3F8 | Size/radius | 52x18.67 r16 |
| 1:7206 | Container (car icon) | @55.49,558.67 21x18.67 | vertical | 20 | 20 vs 21x18.67 | 21x18.67 |
| 1:7207 | Vector (car) | @55.49,558.67 21x18.67 | #1A1B1F | 20 #006C49 | Colour/size | #1A1B1F |
| 1:7208 | Container (title/meta) | @108,547 125.14x42 | vertical | Column | — | — |
| 1:7209 | Container (title) | @108,547 125.14x22 | vertical | Text | — | — |
| 1:7210 | Text "Renault Megan 3" | @108,547 125.14x22 | 16/700 lh22 ls-0.16 #1A1B1F | 16/22 w700 ls-0.16 | Match; sample text | Real job data |
| 1:7211 | Margin (subtitle) | @108,569 125.14x20 | pad 2,0,0,0 | 4 | 4 vs 2 | 2 |
| 1:7212 | Container (subtitle) | @108,571 125.14x18 | vertical | Meta | — | — |
| 1:7213 | Text "XYZ 882 • Bay 2" | @108,571 125.14x18 | 13/400 lh18 #5E5D69 | None | Missing | Slot-sheet |
| 1:7214 | Button (open inspection) | @306,546 44x44 r9999 | #10B9811A, shadow 14/4 | Plain chevron 24 | Missing circle/shadow | As 1:7192 |
| 1:7215 | Container (chevron) | @324.61,562.5 6.78x11 | vertical | 24 | 24 vs 6.78x11 | 6.78x11 |
| 1:7216 | Vector (chevron) | @324.61,562.5 6.78x11 | #10B981 | 24 #5E5D69 | Colour/size | #10B981 |
| 1:7217 | Container (footer) | @40,606 310x30 | horizontal gap 38.83, pad 12,0,0,0 | Two wraps | Structure | One footer |
| 1:7218 | Container (status+template) | @40,620 180.75x14 | horizontal gap 6 | Status chip + ref | Content | Dot + template |
| 1:7219 | Rectangle (dot) | @40,623 8x8 r9999 | #FF7A73 | `Icons.circle` 20, info tone | Missing coral dot | 8x8 #FF7A73 |
| 1:7220 | Container (template) | @54,620 166.75x14 | vertical | Text | — | — |
| 1:7221 | Text "Brake Fluid & Tire Diagnostics" | @54,620 166.75x14 | 11/500 lh14 ls0.44 #5E5D69 | 12/16 w600 | Size/weight | 11/14/500 |
| 1:7222 | Background (pill) | @259.58,618 90.42x18 r9999 | #F4F3F8, pad 2,10 | StatusChip info ~24 high | Fill/height | #F4F3F8, h18 |
| 1:7223 | Text "High Priority" | @269.58,620 70.42x14 | 11/600 lh14 ls0.44 #1A1B1F | 12/16 w600 #1D5C8A | Size/colour | 11/14 #1A1B1F |
| 1:7224 | Card 3 | @20,672 350x130 r24 | #FFFFFF, shadow 8/2+40/14, pad 20 | Same | Radius 32 vs 24 | 24 |
| 1:7225 | Container (top row) | @40,692 310x44 | horizontal gap 72.86 | Same row pattern | Structure | As 1:7181 |
| 1:7226 | Container (badge+title) | @40,693 193.14x42 | horizontal gap 16 | Row gap 12 | 16 vs 12 | 16 |
| 1:7227 | Background (car badge) | @40,704.67 52x18.67 r16 | #F4F3F8, pad 0,12 | 40x40 r12 | Size/radius | 52x18.67 r16 |
| 1:7228 | Container (car icon) | @55.49,704.67 21x18.67 | vertical | 20 | 20 vs 21x18.67 | 21x18.67 |
| 1:7229 | Vector (car) | @55.49,704.67 21x18.67 | #1A1B1F | 20 #006C49 | Colour/size | #1A1B1F |
| 1:7230 | Container (title/meta) | @108,693 125.14x42 | vertical | Column | — | — |
| 1:7231 | Container (title) | @108,693 125.14x22 | vertical | Text | — | — |
| 1:7232 | Text "Renault Megan 3" | @108,693 125.14x22 | 16/700 lh22 ls-0.16 #1A1B1F | 16/22 w700 | Match; sample text | Real job data |
| 1:7233 | Margin (subtitle) | @108,715 125.14x20 | pad 2,0,0,0 | 4 | 4 vs 2 | 2 |
| 1:7234 | Container (subtitle) | @108,717 125.14x18 | vertical | Meta | — | — |
| 1:7235 | Text "KLO 904 • Bay 6" | @108,717 125.14x18 | 13/400 lh18 #5E5D69 | None | Missing | Slot-sheet |
| 1:7236 | Button (open inspection) | @306,692 44x44 r9999 | #10B9811A, shadow 14/4 | Plain chevron 24 | Missing | As 1:7192 |
| 1:7237 | Container (chevron) | @324.61,708.5 6.78x11 | vertical | 24 | 24 vs 6.78x11 | 6.78x11 |
| 1:7238 | Vector (chevron) | @324.61,708.5 6.78x11 | #10B981 | 24 #5E5D69 | Colour/size | #10B981 |
| 1:7239 | Container (footer) | @40,752 310x30 | horizontal gap 84.67, pad 12,0,0,0 | Two wraps | Structure | One footer |
| 1:7240 | Container (status+template) | @40,766 143.77x14 | horizontal gap 6 | Status chip + ref | Content | Dot + template |
| 1:7241 | Rectangle (dot) | @40,769 8x8 r9999 | #BBCABF | `Icons.circle` 20 neutral | Missing neutral dot | 8x8 #BBCABF |
| 1:7242 | Container (template) | @54,766 129.77x14 | vertical | Text | — | — |
| 1:7243 | Text "Routine 60-Point Audit" | @54,766 129.77x14 | 11/500 lh14 ls0.44 #5E5D69 | 12/16 w600 | Size/weight | 11/14/500 |
| 1:7244 | Background (pill) | @268.44,764 81.56x18 r9999 | #F4F3F8, pad 2,10 | StatusChip warning ~24 high | Fill/height | #F4F3F8, h18 |
| 1:7245 | Text "Scheduled" | @278.44,766 61.56x14 | 11/600 lh14 ls0.44 #1A1B1F | 12/16 w600 #8A5A00 | Size/colour | 11/14 #1A1B1F |
| 1:7246 | Floating Assist Button:margin | @20,802 350x88 | vertical, pad 24,0,8,0 | `SizedBox` `sm`=8 above, `lg`=16 below | 24/8 vs 8/16 | 24 top, 8 bottom |
| 1:7247 | Button | @20,826 350x56 r9999 | #10B981, shadow 25/10, gap 8 | `AppButton` large: fill `largeFill` #059669, shadow `buttonSubtle` | Fill #059669 vs #10B981; wrong shadow | #10B981 + emerald 25/10 glow |
| 1:7248 | Container (icon) | @123.4,845.67 16.67x16.67 | vertical | `Icon` 24 | 24 vs 16.67 | 16.67 |
| 1:7249 | Vector (scan) | @123.4,845.67 16.67x16.67 | #FFFFFF | `Icons.add` 24 white | Wrong glyph/size | Scan glyph 16.67 |
| 1:7250 | Container (text) | @148.07,845 118.53x18 | vertical | Text | — | — |
| 1:7251 | Text "Scan New VIN Tag" | @148.07,845 118.53x18 | 14/700 lh18 ls-0.14 #FFFFFF | "Walk-in job", `largeButton` 19/24 w700 ls-0.19 | Text; 19/24 vs 14/18 | Slot-sheet; keep Walk-in; 14/18 if matching |
| 1:7252 | Header | @0,0 390x64 | #FFFFFFE5, shadow 8/1, blur 48 | AppBar #FFFFFF opaque, elevation 0, no blur/shadow | Opacity/blur/shadow | 90% white + backdrop blur + 8/1 |
| 1:7253 | Container | @0,0 390x64 | horizontal, pad 18.75,20 | AppBar titleSpacing 20 | Left pad 20 vs 18.75 | Accept or 18.75 |
| 1:7254 | Container (title) | @20,21 160x22 | horizontal gap 8 | Leading `TechnicianBrandMark` 32 + title | Figma has no brand mark | Remove leading mark and keep title at x=20 |
| 1:7256 | Container (title text) | @20,21 160x22 | vertical, pad top 4.15 | Title Text | — | — |
| 1:7257 | Text "Inspection Queue" | @20,21 82.38x22 | 16/700 lh22 ls-0.4 #1A1B1F | `headlineMedium` 18/24 w700 ls-0.27, "Assigned jobs" | Text; 18/24 vs 16/22; tracking; x offset | Use 16/22/-0.4; align x=20 |
| 1:7258 | Container (actions) | @253.5,10 117.75x44 | horizontal gap 8 | Avatar only (search in production) | Missing LIVE pill; search extra in production | Truthful status only; consider removing search |
| 1:7259 | Background (LIVE pill) | @253.5,14 65.75x36 r9999 | #F4F3F8, pad 4,10 | No equivalent (pending chip only when >0) | Absent | Slot-sheet; use pending-sync chip |
| 1:7260 | Rectangle (dot) | @263.5,28 4.81x8 r9999 | #10B981 | None | Absent | — |
| 1:7261 | Container (LIVE text) | @274.31,18 34.94x28 | vertical, pad left 3.19 | None | Absent | — |
| 1:7262 | Text "LIVE\nSYNC" | @274.31,18 31.75x28 | 11/600 lh14 ls0.275 #3C4A42 | None | Absent | Slot-sheet |
| 1:7263 | Button (profile) | @327.25,10 44x44 r9999 | pad 6 | `IconButton` 44 with 40 avatar | Approx match | 44 target |
| 1:7264 | Profile | @333.25,16 32x32 r9999 | fill IMAGE | `TechnicianAvatar` 40 initials | 40 vs 32; photo vs initials | Slot-sheet; 32, keep initials |
| 1:7265 | Container (dock margin) | @0,922 390x80 | vertical, pad 0,20,16,20 | `bottomNavigationBar` + pad 24/bottom 8 | Outer padding differs | Match 20/16 |
| 1:7266 | Nav | @20,922 350x64 r9999 | #FFFFFFF2, shadow 12/4+50/18, blur 48 | `AppBottomNavDock` minH 64, #FFFFFF opaque, `floating` shadows | Opacity/blur | 95% white + blur |
| 1:7267 | Link (Intake) | @47.75,932 44x44 | vertical, pad 2,4.14 | Jobs item (work icon) | Label/content | `l10n` Jobs |
| 1:7268 | Container (Intake icon) | @60.75,936 18x20 | vertical | `Icon` 24 | 24 vs 18x20 | 18x20 |
| 1:7269 | Vector (Intake) | @60.75,936 18x20 | #1A1B1F | `work` 24 `onSurface` | Size/glyph | 18x20 |
| 1:7270 | Margin (Intake label) | @51.89,956 35.72x16 | pad 2,0,0,0 | Label | — | — |
| 1:7271 | Text "Intake" | @51.89,958 35.72x14 | 11/600 lh14 ls0.44 #1A1B1F | `labelSmall` 12/16 w700 | 12/16/700 vs 11/14/600 | 11/14/600 |
| 1:7272 | Link (Fleet) | @131.25,932 44x44 | vertical, pad 2,7.37 | None (3-item dock) | Missing Fleet item | Slot-sheet; omit |
| 1:7273 | Container (Fleet icon) | @144.24,938 18x16 | vertical | None | Missing | — |
| 1:7274 | Vector (Fleet) | @144.24,938 18x16 | #5E5D69 | None | Missing | — |
| 1:7275 | Margin (Fleet label) | @138.61,954 29.27x16 | pad 2,0,0,0 | None | Missing | — |
| 1:7276 | Text "Fleet" | @138.61,956 29.27x14 | 11/600 lh14 ls0.44 #5E5D69 | None | Missing | Slot-sheet; omit |
| 1:7277 | Link (Sync) | @214.75,932 44x44 | vertical, pad 2,7.87 | Sync item index 1 | Position differs | — |
| 1:7278 | Container (Sync icon) | @225.76,937 22x18 | vertical | `Icon` 24 | 24 vs 22x18 | 22x18 |
| 1:7279 | Vector (Sync) | @225.76,937 22x18 | #5E5D69 | `sync_outlined` 24 | Size | 22x18 |
| 1:7280 | Margin (Sync label) | @222.63,955 28.25x16 | pad 2,0,0,0 | Label | — | — |
| 1:7281 | Text "Sync" | @222.63,957 28.25x14 | 11/600 lh14 ls0.44 #5E5D69 | `labelSmall` 12/16 w600 | 12/16 vs 11/14 | 11/14 |
| 1:7282 | Link (Profile) | @298.25,932 44x44 | vertical, pad 2,3.19 | Profile item index 2 | Position differs | — |
| 1:7283 | Container (Profile icon) | @310.24,936 20x20 | vertical | `Icon` 24 | 24 vs 20 | 20x20 |
| 1:7284 | Vector (Profile) | @310.24,936 20x20 | #5E5D69 | `person_outline` 24 | Size | 20x20 |
| 1:7285 | Margin (Profile label) | @301.42,956 37.64x16 | pad 2,0,0,0 | Label | — | — |
| 1:7286 | Text "Profile" | @301.42,958 37.64x14 | 11/600 lh14 ls0.44 #5E5D69 | `labelSmall` 12/16 w600 | 12/16 vs 11/14 | 11/14 |

## Structural fixes

- Header is missing Figma's structure: Figma = title only ("Inspection Queue") + LIVE SYNC pill + 32 px avatar photo; CR = TR brand mark + title + 40 px initials avatar (plus search in production). Remove the brand mark, keep x=20, and replace the LIVE pill with a truthful sync state.
- Figma separates the 56 px avatar/status row from "Welcome back,"; CR merges avatar into `_WelcomeRow`, so welcome copy starts at x=60 instead of x=20. Split the row.
- Snapshot cards are white raised cards in Figma (72 high, pad 16, 40 px circle icon); CR uses flat `surfaceContainer` (#F4F3F8), 64 high, pad 12, radius-12 icon box, no shadow.
- Job cards: Figma = 24 radius, top row (52x18.67 car badge + title/plate + 44 px circular chevron) and one footer row (8 px dot + template left, 18 px status pill right). CR = 32 radius, 40 px icon box, status chip beside title, then reference/time/odometer, then template, plain 24 px chevron.
- CR card footer is not one row; reference, scheduled time and odometer are product extras with no Figma node. Decide whether they belong on the card or the job detail screen.
- CTA margins: Figma 24 top / 8 bottom; CR 8 top / 16 bottom.
- Dock: Figma 4 equal links (Intake/Fleet/Sync/Profile); CR 3 (Jobs/Sync/Profile) with a selected dot that Figma does not show. Keep the product 3-item dock, but align icon sizes (18-22 px), labels (11/14) and translucent blurred surface.

## Type/fill/shadow fixes

- Welcome: "Welcome back," must be 18/24 w600 #5E5D69 (CR 14/20). Name "David Vance" already matches 26/32/800/-0.65.
- Snapshot: value 16/20/800/-0.16; label 11/14/600/0.44; card #FFFFFF with 32/12 shadow; icon circle 40 at #6FFBBE4D (card 1) and #E1DEEC66 (card 2); card 2 icon #5E5D69.
- Section: title 14/18/700/0.7 #5E5D69 uppercase; pill #10B9811A, 18 high, pad 8/2, text 11/14/700/0.44 #006C49.
- Job card radius 24 (CR 32). Card shadows already match tokens (`TrShadows.card` = 8/2 + 40/14). Title 16/22/700/-0.16 already matches.
- Car badge 52x18.67 r16 #F4F3F8 with 21x18.67 icon #1A1B1F (CR 40x40 r12, icon #006C49).
- Subtitle 13/18/400 #5E5D69; dot 8 px (#10B981/#FF7A73/#BBCABF); template 11/14/500/0.44 #5E5D69; status pill r9999 #F4F3F8 pad 2/10, text 11/14/600 #1A1B1F.
- Chevron action: 44 circle #10B9811A, shadow 14/4, chevron #10B981 at 6.78x11 (CR plain 24 #5E5D69).
- CTA: fill must be #10B981 (CR large-fill #059669) and shadow 25/10 emerald (CR `buttonSubtle`); label 14/18/700/-0.14 (CR 19/24).
- Header must be #FFFFFFE5 + blur 48 + shadow 8/1; dock #FFFFFFF2 + blur 48 (CR both opaque, no blur).
- Avatar: 56 circle, 44 emerald core, #10B98126 halo, white 18/24/700 initials, 16 white + 10 emerald online dot (CR 48, #D9FBE8, 14/18, no dot).
- Dock labels 11/14/600/0.44 (CR 12/16); icons 18-22 px (CR 24).

## Slot-sheet items

| Figma content | Why it must not be copied literally | Product-safe behaviour (current) |
|---|---|---|
| Avatar photo (1:7264 fill=IMAGE) | No photo source; identity/privacy risk | `TechnicianAvatar` initials (correct), match 32 px size |
| "LIVE SYNC" (1:7262) | Implies real-time sync that is not guaranteed | Show pending-sync count only when >0; offline banner when offline |
| "SHIFT 1 • BAY A" (1:7145) | No shift/bay model in backend | Omit, or derive from real assignment |
| "45 min / Avg. turnover" (1:7170-1:7172) | No turnover metric is modelled; fabricated KPI | Use real "In progress" count (current) or another real metric |
| "Scan New VIN Tag" (1:7249-1:7251) | VIN scanning is not implemented | Use "Walk-in job" action (current) or real intake action |
| Fleet dock slot (1:7272-1:7276) | No fleet feature for technicians | 3-item Jobs/Sync/Profile dock (current) |
| Plate/bay meta (1:7191, 1:7213, 1:7235) | Bay not modelled; plate is sensitive data and varies by market | Show real plate only if permitted, otherwise reference/VIN/odometer (current shows reference/time/odometer) |
| Sample names/jobs (1:7188, 1:7210, 1:7232; "David Vance", "3 Tasks", "3 In Queue", "Full Pre-Delivery Inspection") | Figma sample data, including typo "Megan" for "Megane" | Drive all copy from API/job model (current), never hardcode |
| "Ready", "High Priority", "Scheduled" status labels (1:7201, 1:7223, 1:7245) | Not all are real status enums; "High Priority" is a priority, not a status | Map real statuses via `technicianStatusLabel`; model priority separately if needed |
| Colored status dots (#10B981/#FF7A73/#BBCABF) | Figma mixes status/priority severity without a model | Use `technicianStatusTone` tokens, not literal Figma colours |

## Could not verify

- Exact shadow colours/opacities: the dump gives geometry only, e.g. `DROP_SHADOW(16 0,4)`, `(8 0,2)`, `(40 0,14)`, `(25 0,10)`, `(14 0,4)`, with no colour. Only token-level comparisons were possible.
- Vector glyph identity: the dump gives only size/fill for icons (gear 1:7143, car 1:7185, chevron 1:7194, scan 1:7249, dock icons 1:7269/7274/7279/7284); shape matching is unverified.
- Rendered pixel deltas: no measurement tooling was used on `assigned-jobs_en_1.0x.png`; all CR values are derived from code/tokens, not pixel probing.
- Backdrop blur (`BACKGROUND_BLUR(48)` on 1:7252/1:7266) cannot be validated because CR has no equivalent.
- Online-dot placement relative to the avatar (1:7139/1:7140) and whether the halo is clipped at the row edge.
- Production-only differences: the capture sets `showSearch:false`; production passes `onSearch`, so a search icon appears where Figma has none.
- SafeArea/status-bar inset contribution to the 64 px header, and Arabic/RTL rendering.
- Whether Plus Jakarta Sans is actually bundled/loaded in the capture host.
- Whether real production jobs ever contain plate/bay/shift data that could make the slot-sheet items truthful.
