# METHOD — F3-A Step 4 screen 4 Assign Technician Level 1

Fixture: `client/apps/admin_app/test/support/f3a_assign_fixture.dart`
(rendered by `client/apps/admin_app/test/f3a_capture_assign_test.dart`).
Config: `docs/ui/figma/fidelity/fixtures/f3a/assign-level1.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/04_4._Assign_Technician/4._Assign_Technician@2x.png`
(748685 bytes, 2592 x 2240 px).

## Reference crop

`{"x":32,"y":0,"width":2560,"height":2240}` → 1280 x 1120 logical @ DPR 2.
The export PNG carries a 32 px fully-transparent left strip (alpha 0,
x 0-31; content starts at x 32; right edge is exactly content, 32+2560=2592;
same artefact as the screen 2 export). Top/bottom need no crop (content at
y 0 and y 2239). Verified by sampling alpha per column/row. The harness
composites both sides over white and normalises to 2560 x 2240 before
measuring.

## Text sources

All 39 Figma TEXT nodes hardcoded verbatim in the fixture (`test/` only):
ticket/stage 11 px, title 22/28 w700, subtitle 14/20 w500, strip 12/15 w600
+ 13/18 w400, chips/meta 11/14 w600 + 13/18, names 16/22 w700, card-3 sub
13/18 w600, actions 14/18 w700, plus the background board texts (eyebrow
11/14 w600, title 32/38 w800, pills 12/16 w600, card 11/14 w600 + 16/22 w700
+ 13/18 w400, header 11/14 w600 + 12/16 w700 + 14/17.5 w700). Fonts: bundled
design-system Plus Jakarta Sans TTFs
(Regular/Medium/SemiBold/Bold/ExtraBold) loaded test-only the same way as
`technician_app/test/support/f2a_test_fonts.dart`; no pubspec change.
`Fx.text` carries the exact Figma size/line-height/weight/letter-spacing.

## Raster sources

None. The export manifest lists 19 assets — 17 individual SVGs + 2 composed
— and **0 rasters**. The three "avatars" are 48 px circular icon
placeholders (person glyph on `#E1DEEC`), not photos, so no decoding was
needed. All 17 icons (3 board vehicle glyphs, logo, 3 nav glyphs, help,
search, header avatar, close, strip vehicle, 3 tech avatars, check, confirm
arrow) are the export `assets/svg/Icon-*.svg` files read by absolute path
and passed as strings to the fixture, rendered with `SvgPicture.string` at
the exact Figma vector boxes (11.67 close … 25.67 board glyphs). No
`.png`/asset reference in `lib/` or any pubspec.

## Geometry

Every frame uses the exact Figma node sizes/positions/paddings/gaps/radii
from the export JSON (root `1:821` 1280 x 1120; rail 96 x 1072; header
1184 x 80, pad 0/40; board title 1104 x 56 + 32 gap + 3 x 352 x 166 cards,
pad 24; scrim `1:930` 1280 x 1072 `#FFFFFFB2` + blur 24; modal `1:931`
512 x 660 at (384, 206), r24, shadow 0/24/64 @ 8 %; header 512 x 144 pad
36/32/12/32; strip 512 x 88, inner 448 x 64 r16 pad 14; list 512 x 304 pad
12/32 gap 14, cards 448 x 80/80/92 r16 pad 16, radios 28; actions 512 x 116
pad 24/32/36/32 gap 16, Cancel 94.89 x 50 + Confirm 337.11 x 56 r16).
Shared-kit matches used verbatim: `Fx` colors/type (`ink #1A1B1F`,
`container #F4F3F8`, `emerald #10B981`, `pillRadius`, `label12Bold`,
`label14`, …), `Fx.cardShadow` (identical to the Figma 8-blur 1.6 % +
40-blur 4.3 % card shadow), `Fx.ctaShadow` (identical to the emerald button
and active-rail-tile shadow). `showAppConfirmDialog`/product dialog,
`WorkshopHeader`, `AppButton`, `StatusChip` were evaluated and do NOT
reproduce Level-1 geometry (kit gaps below).

Two Figma-exact behaviours with no kit equivalent, inlined test-only:
the dimmed board group sits under `Opacity` 0.4 + `ImageFiltered` blur 12
(`1:824` layer blur 12 + 40 % opacity) with the rail/header/scrim outside
that group; the scrim is a `BackdropFilter` blur 24 over tint `#B2FFFFFF`
(`1:930` background blur 24). The header keeps its own `BackdropFilter`
blur 48 under `#E5FFFFFF` (same pattern as the queue fixture).

## Paint-level raster alignment (measured, test-only)

Same measurement as the queue fixture: Flutter paints 11 px glyphs ~1
logical px lower and the 32 px glyphs ~1 logical px higher than the Figma
rasterizer inside identical line boxes; all other sizes match. The fixture
therefore applies paint-level `Transform.translate` −1 (11 px) / +1 (32 px)
inside the unchanged Figma-exact line boxes.

## Iteration log (global SSIM, threshold 0.98)

1. 0.99121 — first render; full board + scrim + modal from the export JSON.
2. 0.99135 — card-3 radio gap 121.84 (`itemSpacing`) → 137.93 (absolute
   render bounds: radio right-aligned at x 820; the `@2x` reference is
   rendered from absolute bounds). Killed the doubled-radio diff box.
   **Gate PASS.**

## Final numbers (from `metrics.json` / `REPORT.md`)

- SSIM global 0.99135, worst 64 x 64 tile 0.65239 at device (1024, 768)
  = logical (512, 384), inside the modal text zone (sharp glyph edges).
- RMSE 6.972, MAE 0.980 (RGB 0-255).
- ΔE2000 mean 0.335, median 0, p95 1.015, max 85.576.
- ΔE2000 > 2: 2.08 %, > 5: 0.64 %, > 10: 0.40 % of pixels.
- Top diff boxes (logical px): (26.5,213,44.5x45.5) + (0,212.5,5.5x40.5)
  rail emerald nav-tile glow/spill under the double blur (position verified
  identical: tile geometry exact; residual is the Flutter-vs-Figma blur
  kernel on the glow); (1211,26.5,26.5x25) header avatar under header-48 +
  scrim-24 blur (same kernel residual); the remaining 17 boxes are 6-18.5 px
  glyph/icon edge slivers (ticket row, strip, names, "(Available)", radio
  checks) at verified positions.
- Key boxes 3/3 within 0 logical px; expected strings 38/38; forbidden 0.

Residuals are font/icon/blur rasterizer edges only; no unexplained diff
> 4 px remains outside the two dimmed-backdrop blur zones (whose geometry is
exact and whose kernels no Flutter token can reproduce). No pixel-perfect
claim — see REPORT.md.

## Kit gaps needing the lead (shared-kit changes are lead-only)

1. No centred-512 dialog composite in the kit: modal r24 + 0/24/64 @ 8 %
   shadow + 512-section paddings would need a workshop dialog style
   (`showAppConfirmDialog` carries none of this geometry).
2. No vehicle snapshot strip composite (36-circle icon tile + two-line
   meta + tonal `Est.` pill).
3. No technician radio-card composite (`AppListTile` + `Radio` has different
   padding/type; skill chips `#6FFBBE`/`#002113`, `#F4F3F8`/`#5E5D69` have no
   `StatusChip` mapping; inactive radio `#F4F3F8` + 10 px `#DAD9DF` dot has
   no token).
4. No scrim-with-blur barrier token (dialog barrier has no blur; blur 24
   over a dimmed board is unmodelled).
5. No layer-blur + opacity dim group token for the defocused board.
6. 11 px type ships below the 12 px product floor; radios 28 x 28 and close
   40 x 40 are below the 44/48 hit-area floor (kept exact with no enlarged
   hit area in this test-only proof).
7. Card-3 `itemSpacing` (121.84) disagrees with its absolute render bounds
   (radio right-aligned, effective gap 137.93) — export-side inconsistency,
   worked around with the absolute value.

## Could not verify

- Source of skills/levels/availability ("certified specialist", "Brakes L2",
  "Lead Tech", "Powertrain"); why David Vance is preselected.
- Whether assignment also assigns a bay (independent or coupled).
- "Est. 2.5h"/recall lookup scope (treated out-of-scope; shown verbatim).
- Reassignment reason required or optional (A06 says included; current code
  sends null; modal shows no reason field).
- Search/filter + disabled-tech representation in the picker.
- Reference format `#1042` vs `JOB-…` (kept `#1042` verbatim for fidelity).
- Dialog vs route (`/jobs/:jobId/assign`) and <600 px behaviour (O3 derived
  sheet, not built here).
- Scrim 1072-vs-1120 48 px artefact (built full-cover 1280 x 1072 as drawn;
  bottom 48 px strip is white in both).
- Dark theme, text scaling, RTL/Arabic and narrow breakpoints (light-only
  1280 capture, mirroring the Figma frame).
