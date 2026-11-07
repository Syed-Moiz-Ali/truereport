# METHOD — F3-A Step 4 screen 3 Create/Schedule Job Level 1

Fixture: `client/apps/admin_app/test/support/f3a_schedule_fixture.dart`
(rendered by `client/apps/admin_app/test/f3a_capture_schedule_test.dart`).
Config: `docs/ui/figma/fidelity/fixtures/f3a/schedule-level1.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/01_3._Create_-_Schedule_Job/3._Create_-_Schedule_Job@2x.png`
(1384621 bytes, 2732 x 2396 px).

## Reference crop

`{"x":32,"y":90,"width":2560,"height":2116}` → 1280 x 1058 logical @ DPR 2.
The export PNG is the Figma render-bounds image (root `absoluteRenderBounds`
-16,-45 1366x1198 → 2732x2396 @2x, i.e. drawer/footer shadows bleed beyond the
frame). Verified by alpha sampling: rows y 0-82 fully transparent, first ink
at y 84 (5 px), full-width content from y 90; bottom frame edge at y 2206
(full rows to 2204, collapse at 2208+); left content starts exactly at x 32.
The harness composites both sides over white and normalises to 2560 x 2116
before measuring. Key boxes confirm zero offset (drawer/head/CTA all delta 0).

## Text sources

All 71 Figma TEXT nodes hardcoded verbatim in the fixture (`test/` only),
incl. the two multi-line nodes with literal `\n`
("Create an intake record and assign to technician\nbay",
"High-voltage battery, chassis &\npowertrain").
Fonts: bundled design-system Plus Jakarta Sans TTFs
(Regular/Medium/SemiBold/Bold/ExtraBold) loaded test-only the same way as
`technician_app/test/support/f2a_test_fonts.dart`; no pubspec change.
`Fx.text` carries the exact Figma size/line-height/weight/letter-spacing
(22/28 w800 ls -0.55 title, 13/21.13 subtitle, 14/18 w500 ls -0.07
placeholders with AUTO line-height rendered at 18, 11/14 w600 labels,
16/20 w700 tier titles, 12/16 labels).

## Raster sources (test-only, absolute paths, never bundled)

- 3 vehicle thumbnails: the export's Figma-rendered `@2x` rasters
  (`assets/images/rendered_png/*@2x.png`, 128 x 128 px each, 21048 / 24533 /
  26616 bytes), i.e. the Figma cover-crop output of the 3 `image/jpeg`
  vehicle photos, decoded by absolute path
  (`_loadFigmaTestImage`, same pattern as F2-A) and drawn 1:1 via
  `RawImage(image:…, scale: 2)` inside the Figma-exact 64 x 64 radius-16
  tile (card 1 tile at y +5, cards 2-3 at y +0/+9 per the export).
- 15 icons: the export `assets/svg/Icon-*.svg` files read by absolute path
  and passed as strings to the fixture, rendered with `SvgPicture.string`
  at the exact Figma vector boxes (4 x 16 kebabs … 21.67 logo, 11.67 close,
  13.33/15/15 field icons, 9 x 5.55 chevron, 13.33 x 16.67 callout,
  18.33 x 16.67 CTA).
- No `.png`/asset reference in `lib/` or any pubspec.

## Geometry

Every frame uses the exact Figma node sizes/positions/paddings/gaps/radii
from the export JSON (root 1:2 1280 x 1058; rail 96 x 1024; main 1184 x 1058
pad 40/80/40/336; banner 1104 x 94; cards 3 x 352 x 288 gap 24 radius 16;
bays 1104 x 196 radius 16 pad 32, 8 x 116 tiles gap 16 radius 48;
scrim 1280 x 1058 white 60 % + background blur 24; header 1184 x 80 white 90 %
+ blur 48; drawer 420 x 1058 at x 860, left radii 32, dual shadow
0,10,25 @ 6 % + 0,25,70 @ 12 %; body 420 x 920 pad 40/32/24/32; footer
420 x 138 pad 16/32/40/32; inputs 356 x 48 radius 16 dual shadow 0,2,6 @ 1.6 %
+ 0,8,24 @ 3.5 %; tier cards 356 x 72 / 356 x 90 radius 16; CTA 356 x 56
radius 16 emerald + tinted shadow).
Shared-kit matches used verbatim: `Fx` colors/type
(`ink #1A1B1F`, `container #F4F3F8`, pill 9999, radii 16/48, `cardShadow`,
`ctaShadow`). `WorkshopSideSheet`/`WorkshopHeader`/`WorkshopJobCard` were
evaluated and do NOT reproduce Level-1 geometry (drawer radii/shadows/
paddings, header paddings/title type, card padding 32 vs kit; kit gaps below).

Two Figma-exact behaviours with no kit equivalent, inlined test-only:
progress rows are NOT co-centered (bar top y 19, pct top y 16 — implemented
as `Stack`/`Positioned`, same convention as screen 2); header user name sits
at y -1 with role at y 17.5 inside the 31.5 box (implemented as `Stack`).

Blur stack (measured, test-only): base `1:6` wrapped in `ImageFiltered`
sigma 4 (Figma `LAYER_BLUR` radius 4, 1:1 convention) at opacity 0.8, then a
full-frame `BackdropFilter` sigma 24 + white 60 % scrim (`1:167`), then the
header's own `BackdropFilter` sigma 48 + white 90 % (`1:168`). Flutter sigma
is assumed 1:1 with the Figma radius (same convention as the header blur on
screens 1-2, which passed at 0.98+); see residuals.

## Paint-level raster alignment (measured, test-only)

Ink-centroid comparison (reference vs render, logical px): drawer
"Schedule New Job" 22 px title FIG (984.55, 73.84) vs REN (984.29, 73.84)
— position identical to 0.3 px (glyph-shape delta only); tier title
"Standard 60-Point" 16 px FIG y 517.56 vs REN y 516.42 (1.1 px; box geometry
exact, key boxes 0.0 — treated as rasterizer distribution, not layout).
The sibling-measured 11 px −1 / 32 px +1 `Transform.translate` corrections
are applied unchanged (11 px labels, 32 px base title).

## Iteration log (global SSIM, threshold 0.98)

1. 0.95884 — first render; tier cards 40 px too low (extra 32 gap after
   drawer head where Figma has 0, extra 8 after date field where Figma has 24)
   + tier pills 8/16 px misgapped + progress rows co-centered vs Figma top
   19/16.
2. 0.98569 — fixed drawer rhythm (head gap 0, date gap 24, tier label
   8/16/12, title/desc 2 px gap, pill gaps 55.12/29.93, progress
   `Stack` tops 19/16). **Gate PASS.**

## Final numbers (from `metrics.json` / `REPORT.md`)

- SSIM global 0.98569, worst 64 x 64 tile 0.27108 (drawer callout icon +
  text zone 960-1056 x 704-736; flat-tile SSIM sensitivity — geometry exact
  by construction, see residuals).
- RMSE 9.876, MAE 1.515 (RGB 0-255).
- ΔE2000 mean 0.487, median 0, p95 1.487, max 85.576.
- ΔE2000 > 2: 3.02 %, > 5: 0.91 %, > 10: 0.58 % of pixels.
- Top diff boxes (logical px, all ≤ 41 x 25.5): (547.5,368,41,25.5) and
  (178,373.5,30,16) base card customer/tier rows (blurred); (304,458,40,13.5),
  (173.5,458,34,12.5), (225.5,460.5,46.5,5), (271,460.5,34.5,4.5) base
  progress rows (blurred); (150,156,24,9), (174.5,158.5,23,4) base 32 px title
  glyph edges; the remaining 12 are ≤ 18.5 px-wide drawer glyph/icon edges
  (callout shield + "Auto-assign/Marcus" text, tier radio/title/desc,
  "30m/75m" chips). Key boxes 3/3 within 0 logical px; expected strings
  66/66 (fixture lists 66 entries; REPORT.md confirms 66 present);
  forbidden 0.
- Centroid check on the largest sharp-diff zone (tier title) shows ≤ 1.2 px
  distribution delta at verified-identical box geometry; no unexplained
  diff > 4 px remains except the two blurred-base boxes above (41 x 25.5,
  30 x 16 — blurred glyph washes, position verified by layout math).

Residuals are font/icon rasterizer edges (+ blurred-base washes) only.
No pixel-perfect claim — see REPORT.md.

## Kit gaps needing the lead (shared-kit changes are lead-only)

1. `WorkshopSideSheet` cannot reproduce the Figma drawer: left radii 32 +
   dual shadow (0,10,25 @ 6 % + 0,25,70 @ 12 %), body pad 40/32/24/32,
   footer 138 pad 16/32/40/32, CTA 356 x 56 radius 16 emerald + tinted shadow,
   22/28 w800 title + 13/21.13 subtitle + 40 circle close.
2. `WorkshopHeader` cannot reproduce the Figma header: fixed 40 px rail
   padding, pill + search + user slots, 14/17.5 user title, 11 px eyebrow
   pill, blur 48 (kit uses 24).
3. No white-card 48 h r16 field variant with leading icon + placeholder for
   workshop (`FxTextField` pattern is technician-scoped; port to workshop,
   keep product API).
4. No tier/option radio card composition for workshop (selected emerald dot
   + tinted duration chip vs grey dot) — `WorkshopOptionCard` geometry/API
   differs (pad 16 vs kit, `titleMedium` vs 16/20 w700).
5. No 11 px tonal pill mappings for the bay chips
   (`#6FFBBE4D`/`#006C49`, `#FFDAD74D`/`#B91A24`, `#F4F3F8`).
6. No 48-radius bay tile token; no scrim/background-blur tokens for the
   layer-blur-4 + white-60 %-blur-24 + white-90 %-blur-48 stack.
7. Product data gaps per spec §6 (bays, tier durations, auto-assign,
   telematics copy) are out of scope for this structure proof.

## Could not verify

- Flutter sigma vs Figma blur-radius mapping (assumed 1:1; passed gate).
- Vehicle-photo licences (rasters stay test-only; product uses neutral tiles).
- Live data behind stats/bays/progress/footer actions (out of scope).
- Drawer routing/modal vs page, states (loading/error/empty), text scaling,
  RTL, dark theme, breakpoints below 1280 (light-only 1280 capture).
- Whether the export `@2x` left transparent strip + shadow bleed are
  intentional (worked around with the x 32 / y 90 crop).
