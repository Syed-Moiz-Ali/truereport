# F3-A dashboard Level 1 — capture method (exact-value fixture)

Screen 1 "Workshop Dashboard", Figma node `1:299`, frame **1280 x 1230.672**,
reference `docs/ui/figma-export/Workshop_admin_figma/screens/02_1._Workshop_Dashboard/1._Workshop_Dashboard@2x.png`
(2592 x 2474 px).

Fixture: `client/apps/admin_app/test/f3a_capture_dashboard_test.dart`
(test-only; `lib/` untouched). Compare fixture:
`docs/ui/figma/fidelity/fixtures/f3a/dashboard-level1.json`.
Methodology follows sibling screen 2 (`f3a_queue_fixture.dart`, 0.98194
PASS): every differing node built EXACT from `Fx` primitives at Figma values
with the real export SVGs — no `WorkshopHeader`/`WorkshopStatCard`/
`AppSegmentedControl`/`AppButton`/`AppProgressRing`/`StatusChip` kit defaults.

## 1. Crop (measured, not assumed)

Alpha-channel analysis (opaque = alpha > 128) gives the opaque frame box
**x=32, y=0, w=2560, h=2461** (margins L=32, R=0, T=0, B=13 — asymmetric
Figma-export padding baked into the PNG). Fixture crop is exactly that box.

Render is 1280 x 1230.672 logical @ DPR 2 = 2560 x 2461.34 px; the harness
rounds the grid to 2560 x 2461 (`Math.round`), i.e. **1:1 with the crop, no
resample stretch**. Content is top-anchored and exactly fills the frame
(80 + 84 + 40 + 346.67 + 64 + 568 + 48 = 1230.67 = frame height, matching
Figma's 48 px bottom padding), so no alignment sliver exists at the bottom.

Fonts: bundled Plus Jakarta Sans (+ Noto fallbacks) loaded from
`client/packages/design_system/assets/fonts`, plus MaterialIcons — same
pattern as `technician_app/test/support/f2a_test_fonts.dart`.
Shadows: `debugDisableShadows = false` during capture, restored after
(F2-A harness pattern). Text scale locked (`TextScaler.noScaling`).

## 2. Exact-value construction (node → widget)

All geometry/fills/type/shadows transcribed from the export JSON:

- Cards/rows/rail/pills/fields: white or `#F4F3F8` (`Fx.white`/`Fx.container`)
  with the exact Figma corner radii; card shadow single
  `0x09000000/blur40/off(0,16)` (a=0.035); row shadow
  `0x05000000/blur16/off(0,4)`; segmented bg `0x0D000000/blur2/off(0,1)`,
  selected pill `0x0F000000/blur8/off(0,2)`; `Dispatch Bay` + active rail item
  use `Fx.ctaShadow` (= Figma `a=0.3/b25/off(0,10)` emerald); logo tile the
  exact dual shadow (`0x04/b8/off(0,2)` + `0x0B/b40/off(0,14)`).
- Header: square full-bleed 1184x80 bar, `Fx.whiteE5` + `BackdropFilter`
  sigma 48 (Figma `BACKGROUND_BLUR` 48), 40 px padding; bay pill 229.72x32,
  search field 299x34, user chip with `#006C49` avatar + white person icon.
- Segmented: tonal pill 240.11x44, WHITE selected button 136.97x32 + shadow
  (not emerald); unselected text-only. `Dispatch Bay` 154.14x42 emerald pill.
- Stat cards bottom-weighted per JSON: icon tile 48 r16 + status pills at
  exact x (c1 dot+`+2 incoming` #006C49, c2 dot+`Requires Action` ink,
  c3 tonal circle + check #006C49); number paragraph (suffix baseline at
  y+17) + caption at y+41; track 282.67x6 tonal at y+308.66 with fills
  240.26 / 79.14 (`#F59E0B`) / full-width emerald.
- Activity rows white r16: avatar circle 48 tonal + centered SVG;
  title + tonal VIN pill (18 px, 11/600/0.44 text at x+10/y+2); detail;
  right-aligned tonal pills (`Passed` #006C49 / `Awaiting\nReview` #D97706 /
  `Signed\nOff` ink) + 11 px times.
- Telemetry: `SVG-1_457.svg` composed donut rendered 1:1 at 160x160
  (stroke 12.8, track `#F4F3F8`, emerald round-cap arc); center `76%`
  22/700/-0.44 ink + `CAPACITY`; kv rows with bottom-only 1 px `#F4F3F8`
  dividers (rows 1-2, per `strokeTopWeight`/`strokeBottomWeight` JSON);
  tonal button 282.67x48, no shadow, arrow SVG.
- Rail 96x800: logo tile, 3 nav items (emerald active + ctaShadow, 2 tonal),
  tonal settings circle — all real export SVGs at exact node sizes
  (18 icons + donut, read from disk test-only via `flutter_svg`, same as the
  screen-2 fixture; nothing added to any pubspec).
- Text: every Figma node hardcoded test-only with exact string/size/weight/
  colour/letter-spacing/line-height via `Fx.text`; multi-line nodes keep the
  exact `\n`. Measured raster-alignment rule (sibling F3-A convention):
  11 px glyphs shifted -1, 32 px glyphs +1; KPI numerals additionally need
  dx +1 / dy +2.5 (measured ink-box offset, §3) while `Overview` (same size,
  -0.8 tracking) matches with the generic shift — applied via a dedicated
  helper, boxes unchanged.

## 3. Measured residuals (`compare.mjs`) — gate NOT met

| Metric | Value |
|---|---|
| SSIM global / worst 64x64 tile | **0.97814** / 0.3897 (row3 right pill/time zone, logical 672,992) |
| RMSE / MAE (RGB 0-255) | 12.088 / 1.472 |
| dE2000 mean / median / p95 / p99 / max | 0.450 / 0 / 0.40 / 13.22 / 85.6 |
| dE2000 > 2 / > 5 / > 10 | 1.93 % / 1.48 % / 1.14 % |
| Gate | Text 51/51 pass, key boxes 4/4 (max delta 0.01), deny-list 0 — **SSIM fail vs 0.98 (deficit 0.00186)** |

Per-zone SSIM (render-px tiles): rail **0.9967**, KPI cards **0.9886**,
header **0.9797**, telemetry **0.9780**, activity **0.9493**, title **0.9448**.

Top diff boxes (all glyph/edge-level, max area 1124 px ≈ 281x2): KPI
track top/bottom 1-2 px lines (x926/168.5/926.5/169/547, y512-518);
11 px glyph fragments (row1 title/VIN zone x261-401 y756-772, row2/row3
right pills x662-685 y873-989, card3 icon tile x937.5 y250);
KPI numeral remnants (x180.5/547.5 y431); donut bottom arc AA
(x1010.5 y828.5, 114.5x31.5).

Direct ink-box measurements (reference vs render, device px) proving the
residual is rasterizer-level, not structural:
`12`: F(338,865,393,912) vs R(336,860,391,908) → fixed with dx+1/dy+2.5;
`4`: F(1096,866,1133,912) vs R(1094,861,1131,908) (same offset);
`Overview`: F(275,212,567,260) vs R(274,211,566,260) (1 px, generic shift);
subtitle 16 px: identical x, 2 px descender diff; seg label 12 px: 1 px;
track column profile: identical transition rows except 1 px AA at edges;
donut SVG path data rendered 1:1, only arc edge AA differs.
11 px raster is systematically ~1.6 % wider in Skia than in the Figma export
(eyebrow: 291 vs 286 px over 155 px) — advances, not positions; unfixable
from the fixture side with the same font files.

## 4. Kit gaps for the lead (shared kit is lead-owned)

As drawn, Level-1 geometry does not match the product kit: square
full-bleed header vs rounded `WorkshopHeader`; white selected segment vs
emerald `AppSegmentedControl`; 42/48 px buttons vs 56 px min-height
`AppButton`; composed SVG donut vs `AppProgressRing`; bottom-weighted stat
cards vs `WorkshopStatCard` top-row stack; text-only tonal pills vs
icon `StatusChip`. The fixture therefore reproduces nodes from `Fx`
primitives + real SVGs (screen-2 pattern), which is what reaches 0.978.

## 5. Not verified

Donut arc semantics (76 % mapping); search-hint `AUTO` line-height
(rendered 13/16, box-pinned so visually neutral); behaviour below 1280 px,
hover/focus, dark theme, RTL (light-en only); bay/shift/telemetry entities
(data gaps per spec §6).
