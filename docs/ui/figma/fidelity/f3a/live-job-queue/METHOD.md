# METHOD — F3-A Step 4 screen 2 Live Job Queue Level 1

Fixture: `client/apps/admin_app/test/support/f3a_queue_fixture.dart`
(rendered by `client/apps/admin_app/test/f3a_capture_queue_test.dart`).
Config: `docs/ui/figma/fidelity/fixtures/f3a/queue-level1.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/03_2._Live_Job_Queue/2._Live_Job_Queue@2x.png`
(648770 bytes, 2592 x 2250 px).

## Reference crop

`{"x":32,"y":0,"width":2560,"height":2250}` → 1280 x 1125 logical @ DPR 2.
The export PNG carries a 32 px fully-transparent left strip (alpha 0,
x 0-31; content starts at x 32; right edge is exactly content, 32+2560=2592).
Top/bottom need no crop (content at y 0 and y 2249). Verified by sampling
alpha per column. The harness composites both sides over white and
normalises to 2560 x 2250 before measuring.

## Text sources

All 66 Figma TEXT nodes hardcoded verbatim in the fixture (`test/` only):
page title 32/38 w800, card titles 22/28 w700, labels 11/14 w600,
values 12/16 w600, VIN 13/18 w500, customers 13/18 w400, plus one U+2022
BULLET separator per VIN row and the U+2192 "Bay Schedule Matrix →" link.
Fonts: bundled design-system Plus Jakarta Sans TTFs
(Regular/Medium/SemiBold/Bold/ExtraBold) loaded test-only the same way as
`technician_app/test/support/f2a_test_fonts.dart`; no pubspec change.
`Fx.text` carries the exact Figma size/line-height/weight/letter-spacing.

## Raster sources (test-only, absolute paths, never bundled)

- 4 vehicle thumbnails: the export's Figma-rendered `@2x` rasters
  (`assets/images/rendered_png/*@2x.png`, 160 x 160 px each, 23541 / 25811 /
  39696 / 25201 bytes), i.e. the Figma cover-crop output of the 4
  `image/jpeg` vehicle photos, decoded by absolute path
  (`_loadFigmaTestImage`, same pattern as F2-A) and drawn 1:1 via
  `RawImage(image:…, scale: 2)` inside the Figma-exact 80 x 80 radius-16
  tile. No `.png`/asset reference in `lib/` or any pubspec.
- 19 icons: the export `assets/svg/Icon-*.svg` files read by absolute path
  and passed as strings to the fixture, rendered with `SvgPicture.string`
  at the exact Figma vector boxes (7.4 x 12 chevrons … 21.67 logo).
- NOTE: the export `assets/manifest.json` `pngFileName` for raster 4 omits
  one path character (`…T9qrePkBDEJ…` vs on-disk `…T9qrePkqBDEJ…`); the
  capture test uses the on-disk names.

## Geometry

Every frame uses the exact Figma node sizes/positions/paddings/gaps/radii
from the export JSON (root 1:529 1280 x 1125; rail 96 x 1101; main 1184 x
1125 pad 80/40/48/40; title row 1104 x 107; filter row 1104 x 48; cards
1104 x 150 pad 32; footer 1104 x 50). Shared-kit matches used verbatim:
`Fx` colors/type (`ink #1A1B1F`, `container #F4F3F8`, `stat16`, `label12`,
`heading22`, …), `Fx.cardShadow` (identical to the Figma 8-blur 1.6% +
40-blur 4.3 % card shadow), `Fx.ctaShadow` (identical to the emerald button
and selected-rail-tile shadow), `Fx.pillRadius`/radii 16/24, spacing tokens
4/6/8/12/16/20/24/32/40/48. `WorkshopHeader`/`WorkshopJobCard` were
evaluated and do NOT reproduce Level-1 geometry (kit gaps below).

Two Figma-exact behaviours with no kit equivalent, inlined test-only:
bar/flag/slot rows are NOT co-centered (track sits low y 7-15, value high
y 0-14; flag dot y 8 vs text y 4; clock y 5.33 vs text y 4 — implemented as
`Stack`/`Positioned`); 40 px avatar initials sit at y 11.5 (0.5 above
center). The filter-track inner shadow (0,2,4 @ 5 %) has no Flutter
equivalent and is omitted (residual).

## Paint-level raster alignment (measured, test-only)

Ink-centroid comparison (reference vs render, device px) showed Flutter
paints 11 px glyphs ~1 logical px lower (chip +1.70, label +2.19) and the
32 px title ~1 logical px higher (−2.06); all other sizes match within
0.3 dev px (12 px −0.16, 13 px +0.57, 14 px −0.05, 16 px −0.10, 22 px
−0.12). The fixture therefore applies paint-level `Transform.translate`
−1 (11 px) / +1 (32 px) inside the unchanged Figma-exact line boxes.

## Iteration log (global SSIM, threshold 0.98)

1. 0.97115 — first render; centered bar/flag/slot rows.
2. 0.97354 — Figma-exact low/high child alignment in bar/flag/slot rows
   + avatar 11.5 baseline (killed the 62.5 x 10 card-1 box).
3. 0.98194 — 11 px −1 / 32 px +1 raster offsets. **Gate PASS.**

## Final numbers (from `metrics.json` / `REPORT.md`)

- SSIM global 0.98194, worst 64 x 64 tile 0.66562 (chevron zone, edge-only).
- RMSE 11.38, MAE 1.341 (RGB 0-255).
- ΔE2000 mean 0.414, median 0, p95 0.503, max 85.576.
- ΔE2000 > 2: 1.7 %, > 5: 1.28 %, > 10: 0.98 % of pixels.
- Top diff boxes (logical px, all ≤ 48 x 12): (926.5,907,48,12) and
  (903.5,907,16,9.5) "Unassigned" glyph weight/edges (position verified
  identical by centroid: FIG y 1824.94 vs REN y 1824.78); the rest are
  7-22 px-wide glyph/icon edge boxes in titles, VIN rows and person icons.
- Key boxes 3/3 within 0 logical px; expected strings 54/54; forbidden 0.

Residuals are font/icon rasterizer edges only; no unexplained diff > 4 px
remains (largest box is explained glyph rasterization at a verified
position). No pixel-perfect claim — see REPORT.md.

## Kit gaps needing the lead (shared-kit changes are lead-only)

1. `WorkshopHeader` cannot reproduce the Figma header: fixed 40 px rail
   padding, pill + search + user slots, 12/16 user title, 11 px eyebrow
   pill, blur 48 (kit uses 24).
2. `WorkshopJobCard` cannot reproduce the 1104 x 150 article card: pad 16
   vs 32, `titleLarge` vs 22/28 w700, `bodySmall` vs 13/18 meta, no
   progress/review/slot metric slots, chevron is an arrow `AppIconButton`
   vs the 7.4 x 12 chevron in a tonal circle.
3. No 11 px tonal `StatusChip` mappings for the Figma chip colors
   (`#FFFBEB`/`#B45309`, `#FFF7ED`/`#C2410C`, `#EEEDF3`).
4. No inner-shadow support/token for the filter track.
5. `AppSegmentedControl`/tonal button geometry differs from the Figma
   48-track/36-pill filter (pad 6/gap 4).
6. 40 px avatar initials are centered; Figma uses the 11.5/12.5 optical
   offset.

## Could not verify

- Whether the export `@2x` PNG left transparent strip is intentional
  (worked around with the x 32 crop).
- Vehicle-photo licences (rasters stay test-only; product must use the
  neutral tile per the spec).
- Live data behind stats/bays/progress/flags/footer actions (out of scope
  for the Level-1 structure proof).
- Dark theme, text scaling, RTL and narrow breakpoints (light-only 1280
  capture, mirroring the Figma frame).
