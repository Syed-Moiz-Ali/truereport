# METHOD — F3-B Step 3 screen 8 Template Builder Level 1

Fixture: `client/apps/admin_app/test/support/f3b_builder_fixture.dart`
(rendered by `client/apps/admin_app/test/f3b_capture_builder_test.dart`).
Config: `docs/ui/figma/fidelity/fixtures/f3b/builder-level1.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/08_8._Template_Builder/8._Template_Builder@2x.png`
(821690 bytes, 2592 x 2515 px).

## Reference crop

`{"x":32,"y":0,"width":2560,"height":2503}` → 1280 x 1251.5 logical @ DPR 2.
The export PNG carries a 32 px transparent/black left strip (columns 0-31,
same convention as the sibling F3-B screens: staff `x:32`, create-staff
`x:32`); the rail active tile (Figma x 20-76) lands at PNG x 72-184,
confirming `x:32`. Vertically the frame starts at PNG y 0 (white) and the
last opaque row is y 2502, so `y:0, height:2503` with no resample stretch
(grid 2560 x 2503). The harness composites both sides over white and
normalises to 2560 x 2503 before measuring. Key boxes confirm zero offset
(topbar/pod-1/card-1/seq-1/drop/qa all delta 0).

## Text sources

All 67 Figma TEXT nodes hardcoded verbatim in the fixture (`test/` only),
including the U+2022 `•` separators (verified codepoints from the export
JSON), the ASCII `...` ellipses, the hyphen in `ISO-9001`, the bracket range
`[0.0 - 8.5L]`, and the explicit `\n` line breaks in `ACTIVE\nPOLICY` and the
QA note (`...validation on\nsave.`).
Fonts: bundled design-system Plus Jakarta Sans TTFs
(Regular/Medium/SemiBold/Bold/ExtraBold) loaded test-only the same way as
the F3-A/F3-B captures; no pubspec change. `Fx.text` carries the exact Figma
size/line-height/weight/letter-spacing (32/38 w800 titles/values,
22/28 w700 headings, 18/24 w700 sequence titles, 16/22 titles,
14/17.5 user name, 14/18 button text, 13/18 captions/notes,
13/16 AUTO search hints rendered at 16, 12/16 buttons, 11/14 labels/pills).
Wrapped nodes use softWrap at the exact Figma widths (QA note 2 lines,
ACTIVE POLICY 2 lines); all single-line nodes use clip at exact boxes.

## Raster sources (test-only, absolute paths, never bundled)

- 0 rasters (manifest confirms 0; all 50 assets are vectors: 42 individual
  SVGs + 8 composed groups which are NOT used — the fixture renders the 42
  individual icon boxes instead).
- 42 icons: the export `assets/svg/Icon-*.svg` files read by absolute path
  and passed as strings to the fixture, rendered with `SvgPicture.string`
  at the exact Figma vector boxes (11.79-21.67 px; 9.17 x 14.67 drag dots,
  11.92 x 18.33 battery glyph, 20.17 x 17.42 tread glyph, 12 x 12 avatar,
  15 px search, rail 18-21.67). All fills are baked in the SVGs and match
  the Figma fills (#006C49 / #5E5D69 / #B91A24 / white); verified by file
  scan. No `.png`/asset reference in `lib/` or any pubspec.

## Geometry

Every frame uses the exact Figma node sizes/positions/paddings/gaps/radii
from the export JSON (root 1:1882 1280 x 1251.5; Main 1184 pad 80/40/48/40;
top bar 1104 x 114 pad-bottom 40: V2.4 28-pill + H1 32/800, Preview
151.91 x 44 white pill, Publish 205.24 x 46 emerald r16; 4 pods 258 wide
gap 24 pad 24 r16 h143/143/145.5/142: value 32, label 11-upper,
210 x 6 progress track on pod 1; workspace 1104 x 816 gap 40: left 404.33
— header 50, search 404.33 x 42 r9999, 5 item cards 404.33 x 84 gap 16 r16
pad 20 with 44 px icon tile + title 16/700 + meta row + drag dots, create
pill 404.33 x 48.67; right 659.67 — header 46 + autosave pill 133.7 x 26,
3 sequence cards 659.67 x 128 gap 20 r16 pad 24 with 40 px numeral disc,
title 18/700, Active (mint 40 %) / Automated (tonal) pill, rule pill,
category note, 157.17 x 40 control cluster; drop zone 659.67 x 168 r16
pad 32 with 48 px icon disc + 2 centred lines; QA card 659.67 x 106 r16
pad 24/24/24/23.99 with 38.28 x 40 icon tile + 2-line note + ACTIVE POLICY;
header 1184 x 80 white 90 % + blur 48; rail 96 x 1182 with 48/56 tiles).
Shared-kit matches used verbatim: `Fx` colors (`ink #1A1B1F`,
`container #F4F3F8`, `surfaceHigh #EEEDF3`, `sage #BBCABF`,
`dangerRed #B91A24`, `emerald #10B981`, `deepGreen #006C49`,
`secondaryInk #3C4A42`, `whiteE5`), `Fx.cardShadow` (= Figma dual shadow
0,2,8 @ 1.6 % + 0,14,40 @ 4.3 %), `Fx.ctaShadow` (publish CTA + active
settings tile). `WorkshopMetric`/`WorkshopSequenceCard`/`WorkshopLockedPill`/
`WorkshopDropZone` were evaluated and do NOT reproduce Level-1 geometry
(metric 3-line pod stack + icon slot, sequence numeral/title/chip/rule/
control row, tonal drop zone with centred lines, locked-pill has no Figma
slot here); the deltas are kit gaps below.
Figma-exact values with no kit token are inlined test-only (mint-40
`#666FFBBE` Active pill + `#002113` text, 9999 pill radii, white-button
micro-shadow 0,1,2 @ 5 %, transparent button discs, inside dot rings).

## Paint-level raster alignment (measured, test-only)

Ink-centroid convention carried over from the sibling fixtures: 11 px
glyphs −1, 32 px glyphs +1, 13/18 and 18/24 −1 (fixture `_dy`); all other
sizes (12/16, 13/16, 14/17.5, 14/18, 16/22, 22/28) match unshifted. No
per-zone remeasurement was needed: the first render passed the gate.

## Iteration log (global SSIM, threshold 0.98)

1. 0.98470 — first render. **Gate PASS.**

## Final numbers (from `metrics.json` / `REPORT.md`)

- SSIM global 0.98470, worst 64 x 64 tile 0.66119 (text tile).
- RMSE 9.943, MAE 1.298 (RGB 0-255).
- ΔE2000 mean 0.383, median 0, p95 0.409, max 85.58.
- ΔE2000 > 2: 1.92 %, > 5: 1.43 %, > 10: 1.00 % of pixels.
- Top diff boxes (logical px, 20 total, largest 9 x 46.5): (1240,103.5)
  publish-CTA right shadow falloff strip; (891,112.5) preview eye-icon
  vector edge; (220,123.5) H1 glyph edge; the remaining 17 boxes (all
  ≤ 56.5 x 11) sit on catalog meta-row 11 px glyph edges, rule-pill text
  edges and title glyph edges at verified-exact geometry.
  Key boxes 6/6 within 0 logical px; expected strings 63/63
  (actual 67 captured incl. duplicates); forbidden 0.
- No unexplained diff: every box sits on a text/vector glyph edge or the
  CTA shadow falloff at verified-exact geometry (spans/centroids ≤ ~1 px);
  total diff-box area ≈ 7236 px² ≈ 0.11 % of the 6.4 M px grid. Residuals
  are font/icon rasterizer edges plus the known Flutter-vs-Figma shadow
  falloff mapping (same class as the sibling screens' accepted residuals).

Residuals are font/icon rasterizer edges + shadow falloff only.
No pixel-perfect claim — see REPORT.md.

## Kit gaps needing the lead (shared-kit changes are lead-only)

1. `WorkshopMetric` cannot reproduce the metric pods: label 11/14 + value
   32/38 + caption/note 13/18-or-11/14 three-line stack, right/top icon
   slot, pad 24, r16, per-pod heights 142-145.5, progress track variant.
2. `WorkshopSequenceCard` cannot reproduce the sequence cards: 40 px
   numeral disc + title 18/700 + Active/Automated pill + rule pill +
   category note + 157.17 x 40 control cluster (grouped up/down + trash +
   drag handle) in a 659.67 x 128 r16 pad-24 row.
3. `WorkshopDropZone` cannot reproduce the drop zone: white r16 card (not
   dashed) with 48 px icon disc + two centred text lines (16/700 +
   13/400), 659.67 x 168 pad 32.
4. `WorkshopLockedPill` has no slot on this screen (per-item Active flag
   is a Figma gap vs the locked-indicator equivalent).
5. `WorkshopHeader` cannot reproduce the header: fixed 40 px rail padding,
   bay-pill + search-pill + user slots, 14/17.5 user title, 11 px eyebrow
   pill, blur 48 (kit uses 24).
6. Product data gaps per spec §4/§6 (semver V2.4, SOP kicker, 14-count,
   AI/telemetry/BT/OBD claims, autosave, drag-and-drop, per-item
   Active/Automated, numeric ranges, laser/integration claims, ISO-9001
   policy engine, custom-item creation) are out of scope for this
   structure proof — the fixture reproduces the Figma nodes verbatim
   test-only.

## Could not verify

- Flutter sigma vs Figma blur-radius mapping (assumed 1:1, passed gate;
  residual CTA-shadow falloff strip documented above).
- `Preview Flow` vs existing EN/AR bottom-sheet diff (assumed same).
- Autosave semantics (server draft vs local vs decorative) + conflict
  behavior; Active/Automated ownership; numeric-range authorship/storage.
- Safety-rule violation panel placement; "14 configured" source.
- Arabic/RTL editor design; loading/empty/error/unsaved/publish-disabled
  states; 200 % text; phone/tablet breakpoints (light-only 1280 capture).
