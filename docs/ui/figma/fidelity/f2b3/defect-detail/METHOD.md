# F2-B.3 Level 1 — Defect Detail & Evidence (screen 09) — Method

## Fixture
- Test: `client/apps/technician_app/test/f2b3_capture_defect_detail_test.dart` (new file only; models `f2b_fidelity_capture_test.dart`).
- Widget: test-only `F2b3DefectDetailFixture` in `client/apps/technician_app/test/support/f2b3_defect_detail_fixture.dart` (390 x 1031.67, DPR 2, `RepaintBoundary` → `toImage`).
- Uses `Fx*` (`figma_screen_kit.dart`) + F2-B primitives (`f2b_kit.dart`) only; never reuses the production `DefectDetailView`; never touches `lib/`; no pubspec changes.
- Text: pumped via `f2bHost(..., figmaStrings: true)` (`F2bFigmaTestLocalizations`); section/segment/evidence/CTA copy travels through `AppLocalizations` (e.g. `SAVE DEFECT` is `l10n.saveAnswer.toUpperCase()`); Figma data copy (`BAY 04 • IN PROGRESS`, `PIN #03`, `Dent / Crease`, `1 of 4 Required`, …) is hardcoded test-only literals. No `.png` string added to `test/support/f2b_views.dart`.
- Shadows: `enableFidelityShadows()` + `restoreFidelityShadows()`; 390 logical px, DPR 2.

## Reference crop (re-derived)
- Reference: `docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/9._Defect_Detail_&_Evidence@2x.png`
- Raw decode: 1020 x 2148 px (Node PNG decoder). Expected frame: 390 x 1031.67 @2x = 780 x 2063.34 → 780 x 2063.
- Crop used: `x=120, y=0, width=780, height=2063` (identical to the existing `f2b/defect-detail-figma-text.json` crop; re-derived, not copied).
- Margins removed: left 120, right 120 (1020-120-780), top 0, bottom 85 (2148-2063). Verified pixel probes: ref `(0.., ..)` is transparent outside x 120..899; top row at y=0 is opaque white app content (no OS status bar in this export); bottom rows 2063..2147 fade from sheet-shadow grey to transparent.
- Figma status-bar furniture: this export contains none (no iOS/Android chrome; the top 56 px is the app action bar `1:8023`). Both sides composite identically: `compare.mjs` composites the cropped reference over white and the render root is opaque white (`ColoredBox` + 390 x 1031.67 white fixture), so there is no furniture to mask and zero differential from the crop on either side.

## Raster sources
- Wireframe backdrop: `assets/composed/png/Blur-1_8036@2x.png` (712 x 512 px). Displayed 1:1 via `RawImage(scale: 2)` (356 x 256 logical) center-clipped by the 350 x 256 frame `Stack` — exactly the export's own ±6 px blur-bleed crop (verified: center 700 x 512 vs reference region SSIM 0.9845 before pin overlay).
- Evidence photo: `assets/images/rendered_png/…-1_8104@2x.png` (334 x 334 px, the Figma `CROP`-transform center crop of the 512 x 279 JPEG, `imageTransform [[0.544921875,0,0.2275390625],[0,1,0]]`). Displayed 1:1 via `RawImage(scale: 2)` (167 x 167 logical); tile/row edges match the reference exactly (top row, bottom row, left column byte-identical).
- Both decoded at capture time by absolute path via `loadFigmaTestImage` (same pattern as the F2-A capture). Nothing added to any pubspec; `lib/` untouched.
- Icons (`1_8026`, `1_8033`, `1_8052`, `1_8070`, `1_8090`, `1_8107`, `1_8115`, `1_8122`, `1_8128`, `1_8134`) via `FxIcon` + `FxSvgCache` registered by `loadF2AFonts()` from `client/packages/design_system/assets/icons/figma`.

## Node mapping (exact)
- Root `1:8021` 390 x 1031.67 white `Column`: top `1:8022` 390 x 320 (pad 0/20/20/0) + sheet `1:8057` 711.67 (pad 16/20/24/20, gap 24, top radius 48 = `F2b.radiusLarge`, `Fx.upShadow` single-shadow approx of Figma's double shadow).
- Action bar `1:8023` 350 x 56 pad-top 8: `F2bIconButton` 48 close/help (`1_8026` 14, `1_8033` 18.33) + exact status pill 22 (pad 16/4, dot 8 emerald, text 11/600 ls 0.55 ink on `whiteE5` + `DROP_SHADOW(16 0,4)` approx; kit `F2bStatusPill` fixes pad 10 / dot 6, so composed exact and documented).
- Wireframe block `1:8034` 350 x 264 pad-vertical 4; blur frame `1:8035` 350 x 256 (`RawImage` scale 2, i.e. exact 1:1 dest, center-clipped) + pin `1:8047` at rel (139.86, 90) 70.28 x 76: white 40 circle + amber 32 (`F2b.amber`) + `1_8052` 13.5 white + halo 48 `#33FBBF24` inlined (no token) drawn AFTER the white button per node order `1:8049`→`1:8053` (a plain 48-child would be clamped to the tight 40 Stack box, so `Positioned` carries it); `PIN #03` pill 70.28 x 32 pad 12/8.5/12/9.5 text 11/600 ls 0.275 ink. Verified: pin-circle interior and halo-ring pixels now match the reference exactly; ring residual is edge-AA only.
- Header `1:8060` 350 x 50: amber 10 dot + `EXTERIOR BODYWORK` 11/600 ls 0.55 muted, `Front Left Door` `Fx.display26` (26/32/800/-0.65 exact), car chip 40 container circle + `1_8069/70` area `1_8070` 15 muted.
- Status `1:8071` 350 x 70 (label 14 + gap 4): exact segmented track 350 x 52 pad 6 gap 6, options 108.67 x 40 pad 12/8, labels via l10n, text 12 ls 0.24 (600 muted / 700 ink selected), selected `Minor` fill `#FED7AA` exact + `DROP_SHADOW(12 0,4)` approx; kit `F2bSegmented` fixes selected fill to `surfaceHigh`, so composed exact and documented. Verified: option fill pixels byte-identical to reference.
- Classification `1:8081` 350 x 88: header row (`F2bSectionLabel` severity + `1 Selected` 11/700 ls 0.44 emerald) + chips at Figma absolute offsets (0,0)/(140.61,0)/(0,40) — container `1:8087` has no auto-layout: `Dent / Crease` selected (`F2bChip`, amber dot) + `Surface Scratch` (`F2bChip`) + `Paint Chip` manual 30 tall (kit `F2bChip` fixes 32, would bleed 2 px into the gap). Chip/segment text boxes match Figma containers to ≤0.05 px.
- Evidence `1:8096` 350 x 185 (label 14 + gap 4 + row 167): header (`F2bSectionLabel` attachments + `1 of 4 Required` 11/600 ls 0.44 muted); tiles composed from kit tokens (square — reference corners probed square): filled tile = photo 1:1 + pencil chip 28 (whiteE5 + `BACKGROUND_BLUR(24)` → `BackdropFilter` sigma 24 + `Fx.pillShadow` + `1_8107` 12 ink) + `Tagged` pill 18 (dot 6 amber + 11/600 ls 0.44 ink); empty tile = white + `Fx.cardShadow` (= Figma 8/0,2 + 40/0,14) + 56 `tintEmerald` circle + `1_8115` 25 emerald + `Take a photo` 14/700 ls -0.35 ink + `Tap to capture` caption.
- Note `1:8120` 350 x 56.67 square container fill: mic slot 12.83 x 17.42 (tight box — a square `FxIcon` would push text +4.6 px) + gap 16 + hint (`l10n.note`, `Fx.body13` 13/18/400) + gap 16 + plus slot 16.67 x 24.67 (`1_8128` 16.67 top + 8 bottom pad). Hint ink extents now 65.0..319.0 = Figma 65..319.
- Save `1:8129` 350 x 68 (pad 4/0/8/0): exact 56 button — emerald pill + `Fx.ctaShadow` (emerald glow verified against reference) + `SAVE DEFECT` at Figma-exact ls 0.7 (ink extents 134.0..250.0 = Figma; kit `FxButton` fixes ls −0.14 → 90.99 wide, so composed exact and documented) + check `1_8134` 13.58 white gap 8. Geometry keys (`segmented`, `save`) are `ValueKey`s on the exact containers; expected rects unchanged, delta 0.

## Kit gaps (lead only, not edited) — all expressed exact in-fixture
Per the Level 1 convention (fixture proves reproduction with Figma values; product screens untouched), every node below is composed exact from `Fx`/`F2b` tokens + the Figma value inlined test-only. Costs are patch-simulation SSIM deltas (reference pixels spliced into `render.png`).
- Segmented selected fill: kit `F2bSegmented` fixes `surfaceHigh #EEEDF3`; Figma `Minor` is `#FED7AA` + `DROP_SHADOW(12 0,4)`. Fixture composes the track exact (fill pixels now byte-identical). Residual cost of the old default: +0.0004 (flat fills barely move SSIM).
- Save tracking: kit `FxButton`/`Fx.label14` fixes ls −0.14; Figma save copy is ls 0.7 (100.22 wide). Fixture composes exact (ink extents 134.0..250.0 = Figma). Residual cost of the old default: +0.0029; worst 64-px tiles sat on this row (0.58 → now 0.77).
- Status pill: kit `F2bStatusPill` fixes pad 10 / dot 6 / no shadow; Figma is pad 16 / dot 8 / `DROP_SHADOW(16 0,4)`. Fixture composes exact (pill ink extents = Figma). Residual cost of the old default: +0.0009.
- `F2bChip` fixes 32 height vs Figma 30 on `Paint Chip` (+2 px bleed): fixture uses a manual 30-tall chip with identical tokens.
- Sheet shadow: kit `Fx.upShadow` single (30/0,-10 a0.08) vs Figma double (16/0,-4 + 60/0,-18): band matches within Δ≤3 (mean 1.72); kept kit.
- Tile-1/pin/pin-pill shadows: Figma null-color approximated with kit-soft black (tile-1 tuned 8%→5% after probe showed render 6–7 darker than reference); halo `#FBBF2433` and shadow alphas have no token — inlined test-only.
- No wireframe/pin primitives exist in the kits (raster + composed nodes above; `RawImage` scale 2 = exact 1:1 dest, no resample); no `Tagged`/count/defect-taxonomy copy in `AppLocalizations` (test-only literals used).
- All 10 export SVGs used are byte-identical between `design_system/assets/icons/figma` and the screen export (`diff` clean), so icon residuals are rasterizer phase, not asset mismatch.

## Residual (measured, not claimed)
- Gate: SSIM **0.97362** < 0.98 — **NOT MET** (up from 0.97061 with kit defaults); RMSE 10.974; MAE ~2.47; ΔE2000 mean ~0.87, p95 ~2.17; ΔE>5 2.15%. Text 20/20 PASS; forbidden-terms PASS; key boxes 2/2 within 2 px PASS (both delta 0).
- Geometry audit (temp probe, removed): close/help/segmented/save/pill/pin/tag/`PIN #03`/title/category/evidence texts all at Figma coords (≤0.05 px; chip/segment text widths match to 0.02 px; save/pill/hint extents now exact). Positions are exact; what differs is rasterisation.
- Per-zone SSIM cost table (patch-simulation on the final render, base 0.97362; zones overlap slightly so costs are not fully additive; ALL-zones-perfect = 0.99693):

  | Zone (logical rect) | +SSIM if pixel-perfect | Nature |
  |---|---|---|
  | title + category text (20,370,183,50) | 0.00235 | glyph AA/phase |
  | all other 11px labels (status pill, pin pill, headers, tag, counts) | 0.00412 | glyph AA/phase |
  | segment labels (3 x 108.67x40) | 0.00039 | glyph AA/phase |
  | chip labels (3 chips) | 0.00256 | glyph AA/phase |
  | note hint line | 0.00151 | glyph AA/phase |
  | save text + evidence captions | 0.00304 | glyph AA/phase (white-on-emerald dominates) |
  | photo tile1 interior (20,668,167,167) | 0.00346 | dual-pipeline resample noise (edges byte-identical) |
  | empty tile2 (icon + captions) | 0.00219 | icon/text raster |
  | wireframe blur (excl. pin) | 0.00204 | stroke phase/pipeline noise |
  | top-bar icons + sheet/save shadows + button edges | ~0.003 | icon raster + shadow approx |
  | pin zone | 0.00030 | halo/shadow edge (done) |
  | status pill alone (subset) | 0.00069 | glyph/dot edge |

  Text raster sums to ~0.014; raster/pipeline/approx noise to ~0.009; total 0.0233 = ALL-zones delta exactly. Nothing above is reachable from the fixture side: positions/extents/fills are exact, SVGs are byte-identical, rasters are 1:1.
- Patch-simulation ceiling: splicing ALL text zones with reference pixels → 0.98652. So non-text (fills, shadows, icons, rasters, pin) accounts for ~0.0135 and text zones for ~0.0159 of the 0.0294 deficit. Of the text share, the old save-tracking default was ~0.003 (now fixed in-fixture); the rest (~0.013) is glyph rasterisation: per-row ink profiles show glyph rows vertically aligned with redistributed edge ink — same font file (TextPainter measures the hint at 256.06 = Figma 256.06), different rasterizer AA/phase. A global ±0.5 px resample test confirms subpixel phase (shift +0.5 y → 0.97769), which is pipeline phase, not layout error — not applied.
- Photo/wireframe interior noise: edges are byte-identical 1:1, but interiors carry dual-pipeline resample differences (screen-export resampler vs composed/rendered-png export resampler; e.g. `imageTransform` crop origin 116.5). Irreducible from the fixture side; placement is exact.
- Diff boxes (ΔE>5, area≥16): 20 boxes. Largest is now small (former peach box is gone — fill is byte-identical). Remainder: save/caption text rows (raster), tile shadow 1-px edges, title/category/chip/hint glyph edges (raster), help/car/pencil icons (SVG raster phase). No unexplained diff >4 px: every box maps to a raster edge or a documented shadow approximation.
- Worst 64x64 tile 0.76533 on the save-text row (was 0.57937 with the tracking gap); next-worst on tile-2 captions — all text rows.

## What this proves / needs from the lead
- The fixture reproduces the Figma geometry exactly (all audited nodes ≤0.05 px; key boxes delta 0), every fill (peach option pixels byte-identical), and every tracking value.
- To ship this screen the lead owns: peach selected-state API for segmented/chips, per-copy button tracking (save 0.7 vs kit −0.14), status-pill pad/dot/shadow params, shadow-token coverage for null-color Figma shadows, wireframe/pin primitives (or a raster-slot policy), and product decisions already flagged in the screen spec (Pass wording, invented `2.5cm` measure, hardcoded `1 of 4` count, defect taxonomy).
- Even with every node exact, the measured floor is 0.9736: remaining 0.0233 splits into ~0.014 glyph rasterisation + ~0.009 pipeline/shadow/icon residuals (table above), none reachable from the fixture side. The gate budget does not fit a 20-string screen under two different text rasterizers. Recommend screening the threshold per text density or accepting a documented raster residual for text-dense screens.
