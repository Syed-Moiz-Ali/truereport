# METHOD — F3-B Step 3 screen 5 Workshop Staff Management Level 1

Fixture: `client/apps/admin_app/test/support/f3b_staff_fixture.dart`
(rendered by `client/apps/admin_app/test/f3b_capture_staff_test.dart`).
Config: `docs/ui/figma/fidelity/fixtures/f3b/staff-level1.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/05_5._Workshop_Staff_Management/5._Workshop_Staff_Management@2x.png`
(607105 bytes, 2592 x 2096 px).

## Reference crop

`{"x":32,"y":0,"width":2560,"height":2096}` → 1280 x 1048 logical @ DPR 2.
The export PNG is 1296 x 1048 @1x: 16 logical px of transparent padding on
the left (columns 0-31 fully transparent, first ink at x 32, last ink at
x 2591, full-height opaque rows 0-2095 — white frame background). No vertical
bleed (frame height matches exactly: 2096/2 = 1048). The harness composites
both sides over white and normalises to 2560 x 2096 before measuring.
Key boxes confirm zero offset (card-1/metric-1/add/banner all delta 0).

## Text sources

All 55 Figma TEXT nodes hardcoded verbatim in the fixture (`test/` only),
including the `•` (U+2022) separators and the ASCII apostrophe in
"Liam O'Connor" (verified U+0027 from the export JSON).
Fonts: bundled design-system Plus Jakarta Sans TTFs
(Regular/Medium/SemiBold/Bold/ExtraBold) loaded test-only the same way as
the F3-A captures; no pubspec change. `Fx.text` carries the exact Figma
size/line-height/weight/letter-spacing (32/38 w800 ls -0.8 title,
22/28 w700 values, 18/24 w700 names, 16/22 + 16/24 titles,
14/17.5 + 14/18 user/button text, 13/18 roles/captions/terminal,
13/16 AUTO search hint rendered at 16, 12/16 chips/buttons,
11/14 w600 labels/counts/chips).
Wrapped nodes use softWrap at the exact Figma widths (role lines 2-3,
metric captions 2, all breaks verified identical to the reference).

## Raster sources (test-only, absolute paths, never bundled)

- 0 rasters (manifest confirms 0; staff "avatars" are the same person-glyph
  vector on a lilac tile, verified byte-identical across all six
  `Icon-1_11*` files).
- 25 icons: the export `assets/svg/Icon-*.svg` files read by absolute path
  and passed as strings to the fixture, rendered with `SvgPicture.string`
  at the exact Figma vector boxes (9.33 x 11.67 skill icons …
  23.33 avatar glyphs, 11.67 plus, 18-21.67 rail icons, 12 user glyph,
  15 search, 13.5 shift-rules). All fills are baked in the SVGs and match
  the Figma fills (#006C49 / #5E5D69 / white); verified by file scan.
- No `.png`/asset reference in `lib/` or any pubspec.

## Geometry

Every frame uses the exact Figma node sizes/positions/paddings/gaps/radii
from the export JSON (root 1:1026 1280 x 1048; rail 96 x 1030; main
1184 x 1048 pad 40/80/40; title row 1104 x 76; 4 filter chips h36 gap 12
pad 20/10/20; 3 metric cards 352 x 132 pad 24 r24 gap 24; staff grid
3 x 346.67 gap 32, rows y428 (h190/172/172) / y626 (172 x 3) gap 8,
card pad 28 r24; banner margin 16 + 1104 x 112 tonal #F4F3F8 r24 pad 32;
header 1184 x 80 white 90 % + blur 48; rail tiles 48/56/56/56 + 40 help).
Shared-kit matches used verbatim: `Fx` colors (`ink #1A1B1F`,
`container #F4F3F8`, `emerald #10B981`, `deepGreen #006C49`,
`secondaryInk #3C4A42`, `surfaceHighest #E9E7ED`, `whiteE5`),
`Fx.cardShadow` (= Figma dual shadow 0,2,8 @ 1.6 % + 0,14,40 @ 4.3 %),
`Fx.ctaShadow` (settings tile). `WorkshopHeader`/`WorkshopMetric`/
`WorkshopStaffCard` were evaluated and do NOT reproduce Level-1 geometry
(header paddings/title slots/blur, metric 3-line stack + 48 px tile,
staff avatar/toggle/skill-row geometry); the deltas are kit gaps below.
Figma-exact values with no kit token are inlined test-only (lilac
`#E1DEEC` avatar tile, `#E3E2E7` off dot, 9999 pill radii, toggle track/knob,
chip/banner micro-shadows, tinted CTA shadow, inside 2 px white dot rings).

## Paint-level raster alignment (measured, test-only)

Ink-centroid comparison (reference vs render, logical px) per zone:
title 32 px (0.63, -0.08), names 18 px (-0.24…+0.85, +0.95…+1.0 pre-fix),
subtitle 16/24 (+0.77 pre-fix), captions/roles 13/18 (+0.77…+1.23 pre-fix),
chips 12 px (+0.21, +0.01), banner title 16/22 (-0.59, -0.15), user name
14 px (-0.57, +0.15), search 13/16 (-0.01, +0.16). Applied corrections:
11 px −1, 32 px +1 (sibling convention), plus −1 for 13/18, 16/24, 18/24
(fixture `_dy`); 12/13-AUTO/14/16/22/22/28 need none. All text spans match
within ~1 px (e.g. title lo 136.5/136.0, hi 371.5/370.5; names/roles/chips
centroids ≤ 1 px after correction); remaining deltas are glyph-shape
rasterizer differences at identical box geometry, not layout.

## Iteration log (global SSIM, threshold 0.98)

1. 0.97415 — first render; two systematic issues: (a) fractional-width
   padded Rows overflowed by ~0.01 px in tests (fixed with a
   left-anchored `Row(mainAxisSize.min)` helper that absorbs trailing
   space), (b) 13/16/18 px texts rendered ~1 px low (measured per zone).
2. 0.99093 — applied the −1 corrections + Row fix. **Gate PASS.**

## Final numbers (from `metrics.json` / `REPORT.md`)

- SSIM global 0.99093, worst 64 x 64 tile 0.81302.
- RMSE 7.186, MAE 0.887 (RGB 0-255).
- ΔE2000 mean 0.265, median 0, p95 0.416, max 85.58.
- ΔE2000 > 2: 1.45 %, > 5: 1.08 %, > 10: 0.72 % of pixels.
- Top diff boxes (logical px, all ≤ 27.5 x 24): (141.5,96,27.5,24) title
  glyph edges; (233.5/200,95.5,6,24.5) + (272,102.5,11,24) title strokes;
  avatar person-glyph vector edges (181.5,484.5)/(181.5,673.5)/
  (941,476)/(941,674)/(561.5,477)/(561.5,675) 20-23.5 px;
  skill-chip icon vector edges (554.5,754)/(934.5,557.5)/(554.5,560);
  11 px count glyph edges (228/367.5/481.5/634,205.5) 8 x 9;
  metric value glyph edge (929.5,312.5); search-hint glyph edge
  (960,35); chips-row glyph edge (238.5,574.5,17.5,9).
  Key boxes 4/4 within 0 logical px; expected strings 55/55
  (actual 55 captured); forbidden 0.
- No unexplained diff: every box sits on a text/vector glyph edge at
  verified-exact geometry (spans/centroids ≤ ~1 px); largest box is title
  glyph rasterization (27.5 x 24), not layout.

Residuals are font/icon rasterizer edges only.
No pixel-perfect claim — see REPORT.md.

## Kit gaps needing the lead (shared-kit changes are lead-only)

1. `WorkshopHeader` cannot reproduce the Figma header: fixed 40 px rail
   padding, bay-pill + search-pill + user slots, 14/17.5 user title,
   11 px eyebrow pill, blur 48 (kit uses 24).
2. `WorkshopMetric` cannot reproduce the metric card: label 11/14 +
   value 22/28 + caption 13/18 three-line stack, right 48 px icon tile,
   pad 24, r24.
3. `WorkshopStaffCard` cannot reproduce the staff card: 56 px lilac
   avatar tile + 16 px inside-ring status dot, name + 2-3-line wrapped
   role, top-aligned 32 px toggle + 24 px knob, bottom skill-chip(s) +
   right-aligned logged-hours row, card 346.67 wide.
4. No filter-chip-with-count variant (selected white + shadow vs tonal,
   dot + label + 11 px count, gap 8).
5. No tonal banner variant (112 px #F4F3F8 r24, 48 px white icon tile,
   dual white-pill actions) and no toggle/status-dot/avatar-tile tokens
   (lilac `#E1DEEC`, off grey `#E3E2E7`, knob shadow).
6. Product data gaps per spec §4/§6 (shift model, bays, skills/levels,
   logged hours, NFC/terminal, roster export, availability mutation) and
   the locked-rule copy conflicts (certification/compliance/manager
   titles, invented measurements) are out of scope for this structure
   proof — the fixture reproduces the Figma nodes verbatim test-only.

## Could not verify

- Flutter sigma vs Figma blur-radius mapping (assumed 1:1, passed gate).
- Definition/source of "active shift", bay utilization, shift compliance,
  logged hours, EV-specialist counts (no server fields found).
- Whether the availability toggle mutates anything or is display-only.
- Why rail active = Settings on a Staff screen; why counts (8/5/3/6)
  disagree with the 6 drawn cards.
- Live data, states (loading/error/empty), text scaling, RTL, dark
  theme, breakpoints below 1280 (light-only 1280 capture).
