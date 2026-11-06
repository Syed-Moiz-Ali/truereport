# F2-B.3 Level 1 — Dense Mechanical (screen 11) — Method

## Fixture
- Test: `client/apps/technician_app/test/f2b3_capture_dense_mechanical_test.dart` (new file only)
- Widget: test-only `_DenseMechanicalLevel1` (390x1080, DPR 2, `RepaintBoundary` → `toImage`)
- Uses `Fx*` (`figma_screen_kit.dart`) + F2-B primitives (`f2b_kit.dart`) only; never reuses `DenseMechanicalView`; never touches `lib/`; no pubspec changes.
- Text: pumped via `f2bHost(..., figmaStrings: true)` (`F2bFigmaTestLocalizations`); Figma sample copy is hardcoded test-only literals (zone, items, levels, CTA). No `.png` string added to `test/support/f2b_views.dart`.
- Shadows: `enableFidelityShadows()` + `restoreFidelityShadows()`; 390 logical px, DPR 2.

## Reference crop (re-derived)
- Reference: `docs/ui/figma-export/technision_figma/screens/11_11._Dense_Mechanical_List/11._Dense_Mechanical_List@2x.png`
- Raw decode: 860x2204 px (Node PNG decoder). Expected frame: 390x1080 @2x = 780x2160.
- Crop used: `x=40, y=14, width=780, height=2160` (same as existing `f2b/dense-mechanical-figma-text.json`).
- Margins removed: left 40, right 40 (860-40-780), top 14, bottom 30 (2204-14-2160). Verified by inspecting cropped `figma.png`: no transparent speckles, no rounded device corners, opaque white edges.
- Figma status-bar furniture: this screen has no OS status bar; the top 64 px is the app header (`1:8338` 390x64 `#FFFFFFCC` + blur 48). The cropped 40/14/30 px is transparent Figma canvas padding, not OS chrome. Both sides are composited over white (`compositeOverWhite` in `compare.mjs`; render is opaque white `ColoredBox`), so the furniture is masked identically on both sides with zero differential.

## Raster sources
- Screen 11 has no raster/photo slots (spec §5: 14 assets, all individual SVGs, no raster, no composed SVG).
- Icons (14): `1_8241`, `1_8249`, `1_8255`, `1_8277`, `1_8282`, `1_8288`, `1_8296`, `1_8309`, `1_8317`, `1_8323`, `1_8331`, `1_8335`, `1_8343`, `1_8348` via `FxIcon` + `FxSvgCache` registered by `loadF2AFonts()` from `client/packages/design_system/assets/icons/figma`. No `loadFigmaTestImage` needed; no raster decoded.

## Node mapping (exact)
- Root `1:8220` 390x1080 white; `Main 1:8221` pad top 64; `Container 1:8222` 390x1016 pad bottom 128.
- Zone header `1:8223` 390x58 pad 16/20/8/20; kicker `12/600 ls0.6 #6C7A71`, sub `13/400 #5E5D69`; pill `1:8230` 104.42x26 pad 6/12/6/12 `#F4F3F8` dot 8 `#10B981` text `11/600 ls0.44 #1A1B1F`.
- List `1:8235` 390x818 pad 0/20/0/20 gap 20; cards `1:8236` 350x100, `1:8250` 350x312 gap16, `1:8283` 350x138 gap14, `1:8304` 350x100, `1:8318` 350x88; all radius 32 pad 20 shadow `Fx.cardShadow` (= Figma `DROP_SHADOW 8/0,2 + 40/0,14`).
- Card 2 segmented `1:8263` 310x40 pad 4 `#F4F3F8`; selected `Normal` white + `DROP_SHADOW 8/0,2 a0.06`; labels `12/600 ls0.24`; textarea `1:8271` 310x68 pad 14/14/34/14 `#F4F3F8` placeholder `14/500 ls-0.07 #6C7A71`; `Take Photo 1:8275` 250x48 `#10B981` + barcode `1:8280` 48x48 `#F4F3F8`.
- Card 3 toggle `1:8297` 310x36 pad 4; options 100.67x28 unselected.
- Header `1:8338` 390x64 `#FFFFFFCC` + `Fx.headerShadow` + blur 48 (`FxHeader`); back `1:8343` 11.77x20, profile `1:8346` 32x32 `#006C49` + `1_8348` 12x12 white (`FxProfileButton`).
- Dock `1:8332` 390x96 pad 20 gradient `F2b.fadeGradient` (white-on-white, zero visual delta); CTA `1:8333` 350x56 `#10B981` + `Fx.ctaShadow` (= Figma `25/0,10 a0.30`) label `14/700 ls-0.14` + `1_8335` 20.17x19.25 white (`FxButton`).

## Kit gaps (lead only, not edited)
- `F2bStatusPill` height 22 vs Figma Live Bay pill 26 (used exact 26 Container; `ACTIVE` 22 matches, used `F2bStatusPill`).
- `F2bSegmented` outer pad 6 vs Figma 4; selected color `surfaceHigh` vs Figma white; selected weight 700 vs Figma 600 (fixture builds exact 40/32 + 36/28 with white selected + 600 weight).
- `Fx.ctaShadow` (25/0,10 a0.30) vs Take Photo `20/0,8 a0.25` (fixture uses `FxButton`, closest kit shadow; delta is sub-JND).
- `Fx.heading18` ls -0.27 vs Figma card/header titles ls -0.45 (fixture uses `Fx.text(..., -0.45)` exact).
- `FxHeader` back uses Material icon; fixture passes exact `FxIcon 1_8343` leading.

## Residual (measured, not claimed)
- Gate: SSIM 0.98311 ≥ 0.98 PASS; RMSE 13.197; MAE 2.149; ΔE2000 mean 0.706, median 0, p95 1.973, max 85.576; ΔE>2 4.92%, ΔE>5 1.79%, ΔE>10 1.19%.
- Diff boxes (ΔE>5, area≥16px): 20 boxes, total 6801 px = 0.404% of 780x2160. Largest 71.5x14.5 logical (header `Diagnostic Checklist` glyphs); all others ≤38x14 logical (zone kicker, card titles, descriptions, `ACTIVE`, segment/compact labels, placeholder, `Take Photo`, trailing icons, CTA). Positions match text baselines in `diff.png`; no layout/shadow/color box >4px unexplained.
- Worst 64x64 tile 0.71534 at header text (y 0-64), typical of 1-2 px glyph rasterisation (Plus Jakarta Sans Flutter vs Figma). Only font rasterisation remains.
