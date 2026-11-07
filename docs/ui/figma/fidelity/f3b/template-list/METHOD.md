# METHOD — F3-B Step 3 screen 7 Workshop Template List Level 1

Fixture: `client/apps/admin_app/test/support/f3b_templates_fixture.dart`
(rendered by `client/apps/admin_app/test/f3b_capture_templates_test.dart`).
Config: `docs/ui/figma/fidelity/fixtures/f3b/templates-level1.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/06_7._Workshop_Template_List/7._Workshop_Template_List@2x.png`
(1029174 bytes, 2592 x 3172 px).

## Reference crop

`{"x":32,"y":0,"width":2560,"height":3172}` → 1280 x 1586 logical @ DPR 2.
The export PNG is 1296 x 1586 @1x: 16 logical px of transparent padding on
the left (columns 0-31 fully transparent, first opaque at x 32, last opaque
at x 2591, full-height rows 0-3171 opaque white frame background). No vertical
bleed (frame height matches exactly: 3172/2 = 1586). The harness composites
both sides over white and normalises to 2560 x 3172 before measuring.
Key boxes confirm zero offset (card-1/metric-1/add/banner all delta 0).

## Text sources

All 75 Figma TEXT nodes hardcoded verbatim in the fixture (`test/` only),
including the `•` (U+2022) separators in the five version lines and the
3-line `\n` descriptions. The five `Edit` labels are five separate Figma
nodes and appear five times in `expectedStrings` (presence check only).
Fonts: bundled design-system Plus Jakarta Sans TTFs
(Regular/Medium/SemiBold/Bold/ExtraBold) loaded test-only the same way as
the F3-A captures; no pubspec change. `Fx.text` carries the exact Figma
size/line-height/weight/letter-spacing (32/38 w800 ls -0.8 title,
22/28 w700 values, 18/24 w700 card titles, 16/24 w500 subtitle,
16/22 + 16/24 titles, 14/17.5 + 14/18 user/button text, 13/18 roles/captions,
13/21.13 descriptions/centered architect copy, 13/16 AUTO search hint
rendered at 16, 12/16 chips/buttons/tags/values, 11/14 w600 labels/counts).
Wrapped nodes use softWrap at the exact Figma widths (descriptions 3 lines,
architect copy 3 lines centered, all breaks verified identical to the
reference). `Lead Inspector` is right-aligned in its 93.39 box (Figma RIGHT).

## Raster sources (test-only, absolute paths, never bundled)

- 0 rasters (manifest confirms 0; no template thumbnails).
- 37 icons: the export `assets/svg/Icon-*.svg` files read by absolute path
  and passed as strings to the fixture, rendered with `SvgPicture.string`
  at the exact Figma vector boxes (11.67 plus, 13.5 grid toggle, 15x12 list
  toggle, 12 clocks, 13.5 edits, 15-23.83 card/req icons, 21.67 rail logo,
  18/20 rail links, 12 avatar, 15 search, 16.5 footnote shield). All fills
  are baked in the SVGs and match the Figma fills (#1A1B1F / #5E5D69 /
  #006C49 / white / #1B1B25); verified by file scan.
- No `.png`/asset reference in `lib/` or any pubspec.

## Geometry

Every frame uses the exact Figma node sizes/positions/paddings/gaps/radii
from the export JSON (root 1:1307 1280 x 1586; rail 96 x 800; main
1184 x 1586 pad 40/80/40; title row 1104 x 84; blueprints pill 260.39 x 32
+ New Template 190.56 x 56 gap 16; 4 metric cards 258 wide (h130/135.25/
134.33/134.24) pad 24 r16 gap 24 with per-card label/icon/value/caption
tops (24/24.09/54/86, 26.63/24/59.25/91.25, 26.17/24/58.33/90.33,
26.12/24/58.24/90.24); filter bar 531.9 x 44 pad 6 r9999 + Layout row;
grid 3 x 346.67 gap 32, rows y471.25 (h437.13/437.13/437.79) /
y944.63 (h437.78/437.11/439.14); card pad 32 r24; requirement pill
282.67 x 56/56.67 with per-card icon/label/value tops (24.5/25/24,
25.33/25/24, 24/25.33/24.33, 24/25.33/24.33, 27/25/24); footer
282.67 x 64 at cardH-96 with clock+14 at +34/+33 and Edit 99.52 x 48
r16 pad 28; create card 346.67 x 439.14 with 64 circle + centered copy;
footnote margin 64 + 1104 x 88 tonal #F4F3F8 r16 pad 24;
header 1184 x 80 white 90 % + blur 48; rail tiles 48/56/56/56 + 40 help).
Shared-kit matches used verbatim: `Fx` colors (`ink #1A1B1F`,
`inkStrong #1B1B25`, `muted #5E5D69`, `secondaryInk #3C4A42`,
`container #F4F3F8`, `surfaceHigh #EEEDF3`, `surfaceHighest #E9E7ED`,
`baseline #E3E1EF`, `emerald #10B981`, `deepGreen #006C49`, `whiteE5`),
`Fx.cardShadow` (= Figma dual shadow 0,2,8 @ 1.6 % + 0,14,40 @ 4.3 %),
`Fx.ctaShadow` (top CTA + active rail tile), small/pill shadows
(6 % filter chip, 25 % Edit, 5 % footnote pills/create circle).
`WorkshopHeader`/`WorkshopMetric`/`WorkshopTemplateCard` were evaluated and
do NOT reproduce Level-1 geometry (header paddings/blur/user slots, metric
3-line stack + per-card fractional tops, template tag/requirement/footer
geometry, 32 px toggles, create card); the deltas are kit gaps below.
Figma-exact values with no kit token are inlined test-only (mint
`#10B981 @15 %` tag fill `0x2610B981`, overlay `#F4F3F8 @40 %`
`0x66F4F3F8`, 9999 pill radii, Edit/CTA tinted shadows, 2 px white avatar
ring is header-only and not on this screen).

## Paint-level raster alignment (measured, test-only)

Ink-centroid convention from siblings: 11 px −1, 32 px +1, 13/18 + 16/24 +
18/24 −1 (fixture `_dy`); 12/13-AUTO/14/16/22/28 need none. Applied to all
text boxes; 13/21.13 descriptions need none (verified 0). Metric labels carry
their Figma fractional tops plus the sibling `_o` nudge (2.63/2.17/2.12).
All text spans match within ~1 px; remaining deltas are glyph-shape
rasterizer differences at identical box geometry, not layout.

## Iteration log (global SSIM, threshold 0.98)

1. 0.96444 — first render; two systematic issues: (a) footer origin used
   `cardH-96+32` (32 px too low; Figma footer is at `cardH-96`), fixed to
   `cardH-96` with clock/text at +34/+33 and Edit at +16; (b) metric
   value/caption rows used a single top for all four cards (up to 5 px high
   on cards 2-4) and requirement pills were vertically centred instead of
   Figma-exact tops — fixed with per-card tops from the export JSON.
2. 0.98608 — **Gate PASS.**

## Final numbers (from `metrics.json` / `REPORT.md`)

- SSIM global 0.98608, worst 64×64 tile 0.60528.
- RMSE 9.422, MAE 1.322 (RGB 0–255).
- ΔE2000 mean 0.401, median 0, p95 0.802, max 85.576.
- ΔE2000 > 2: 2.13 %, > 5: 1.49 %, > 10: 1.03 % of pixels.
- Top diff boxes (logical px, all ≤ 18 x 24): (183,519.5,18,15.5) card-1
  icon-tile vector edge; (300,106,18,24) + (137.5,106,6,24) 32 px title
  glyph edges; fifteen 6-9 x 10.5-11.5 boxes at y240.5-241.5 (11 px metric
  label glyph edges across all four cards); (1208.5,236,7.5,18) metric
  icon vector edge. Key boxes 4/4 within 0 logical px; expected strings
  75/75 (actual 79 with 5× Edit + duplicates captured); forbidden 0.
- No unexplained diff: every box sits on a text/vector glyph edge at
  verified-exact geometry (spans/centroids ≤ ~1 px); largest box is the
  card icon vector rasterization (18 x 15.5), not layout.

Residuals are font/icon rasterizer edges only.
No pixel-perfect claim — see REPORT.md.

## Kit gaps needing the lead (shared-kit changes are lead-only)

1. `WorkshopHeader` cannot reproduce the Figma header: fixed 40 px rail
   padding, bay-pill + search-pill + right-aligned user slots, 14/17.5 user
   title, 11 px eyebrow pills, blur 48 (kit uses 24).
2. `WorkshopMetric` cannot reproduce the KPI card: label 11/14 +
   value 22/28 + caption 13/18 three-line stack with per-card fractional
   tops, right icon tile (13.82-19.25), pad 24, r16, gap 24.
3. `WorkshopTemplateCard` cannot reproduce the template card: 48 px icon
   tile + tag pill (mint/grey/baseline fills), 18/24 title + 13/18 version
   + 13/21.13 3-line description, 56 px requirement pill with per-card
   tops, footer (clock + Updated + 99.52×48 Edit) at cardH-96, 346.67 wide.
4. No filter-chip-with-count variant (selected white + 6 % shadow vs tonal,
   4 chips h32/44 bar), no grid/list 32 px toggle variant, no dashed/solid
   create-card variant, no tonal footnote banner variant (88 px #F4F3F8
   r16, 32 px #EEEDF3 icon tile, dual white pills).
5. No overlay/tag alpha tokens (`0x2610B981`, `0x66F4F3F8`) and no per-card
   fractional-top slots; card/CTA shadows exist in `Fx` and match.
6. Product data gaps per spec §4/§6 (custom tags, descriptions, photo-gate/
   cycle/PPE counts, bay binding, completion/compliance/audit metrics,
   list/grid preference, JSON schema export) and the locked-rule copy
   conflicts (DOT/ISO/certification/compliance claims, `Master Inspector`
   sign-off, semver versions, hardware claims) are out of scope for this
   structure proof — the fixture reproduces the Figma nodes verbatim
   test-only.

## Could not verify

- Flutter sigma vs Figma blur-radius mapping (assumed 1:1, passed gate).
- Definition/source of "bays bound", checkpoint sums, completion/compliance/
  audit metrics (no server fields found).
- Why rail active = Settings on a Templates screen; why "100-Point" vs 110.
- Semver source (integer `versionNo` cannot yield 1.4/2.2).
- Legal basis for DOT/ISO/Certification/Class-00 claims (assume remove).
- List-view design (toggle decorative?); Edit-on-published labeling (must
  open new draft/version, never mutate).
- Live data, states (loading/error/empty), text scaling, RTL/Arabic, dark
  theme, breakpoints below 1280 (light-only 1280 capture).
