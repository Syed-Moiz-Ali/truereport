# F2-B.3 Level 1 — Offline Sync Queue (screen 15) — Method

## Fixture
- Test: `client/apps/technician_app/test/f2b3_capture_offline_sync_test.dart` (new file only; models `f2b_fidelity_capture_test.dart`).
- Widget: test-only `F2b3OfflineSyncFixture` in `client/apps/technician_app/test/support/f2b3_offline_sync_fixture.dart` (390 x 1362, DPR 2, `RepaintBoundary` → `toImage`).
- Uses `Fx*` (`figma_screen_kit.dart`) + F2-B primitives (`f2b_kit.dart`) only; never reuses the production `OfflineSyncView`; never touches `lib/`; no pubspec changes.
- Text: pumped via `f2bHost(..., figmaStrings: true)`; Figma sample copy is hardcoded test-only literals (invented versions, metrics, Fleet nav). No `.png` string added to `test/support/f2b_views.dart`.
- Shadows: `enableFidelityShadows()` + `restoreFidelityShadows()`; 390 logical px, DPR 2.

## Reference crop (re-derived)
- Reference: `docs/ui/figma-export/technision_figma/screens/14_15._Offline_Sync_Queue/15._Offline_Sync_Queue@2x.png`
- Raw decode (Node PNG decoder): 900 x 2841 px. Expected frame: 390 x 1361.94 @2x = 780 x 2723.88 → 780 x 2724.
- Crop used: `x=60, y=14, width=780, height=2724` (identical to the existing `f2b/offline-sync-figma-text.json` crop; re-derived, not copied).
- Margins removed: left 60, right 60 (900-60-780), top 14, bottom 103 (2841-14-2724). Verified pixel probes: ref `(0..59, *)` and `(840..899, *)` transparent (alpha 0); opaque range at y=500 is x 60..839 (width 780); opaque range at x=450 is y 14..2737 (height 2724); row 13 transparent canvas, row 14 frame top edge (alpha 255), rows 2738+ transparent.
- Figma status-bar furniture: this export contains none (no iOS/Android chrome; the top 64 px is the app header `1:8776`). Both sides composite identically: `compare.mjs` composites the cropped reference over white and the render root is opaque white (`ColoredBox` white + 390 x 1362 white fixture), so there is no furniture to mask and zero differential from the crop on either side.

## Raster sources
- **None decoded.** Per the spec (§5) this screen exports 16 individual SVGs and **no photo/avatar/vehicle raster**. All 16 icons (`1_8640`, `1_8648`, `1_8672`, `1_8682`, `1_8700`, `1_8720`, `1_8730`, `1_8740`, `1_8755`, `1_8770`, `1_8781`, `1_8786`, `1_8791`, `1_8796`, `1_8801`, `1_8806`) render through `FxIcon`, backed by the export SVGs registered into `FxSvgCache` by `loadF2AFonts()` (same vector source as `assets/svg`). No `loadFigmaTestImage` needed; no raster decoded at 1:1.
- No `.png` string appears in `test/support/` (release guard stays green); no asset was added to any pubspec; `lib/` was not touched.
- Non-square vectors (e.g. `1_8672` 13.5x12, `1_8682` 14.25x15.75, nav `1_8791` 18.33x20.17) use `FxIcon(size: max(w,h))` inside a tight `w x h` box: the SVG `contain` padding absorbs the square overflow so the vector edges land exactly on the Figma box (verified by construction; residual is rasterisation only).

## Node mapping (exact)
- Root `1:8633` 390 x 1361.94 white; fixture 390 x 1362 (0.06 rounding, subpixel).
- Main `1:8634` pad 64/0/112/0 (header space + nav space); Container `1:8635` 390 x 1185.94 pad 8/20/8/20 → content 350 x 1169.94 (64 + 196.19 + 169.75 + 510 + 126 + 104).
- Sub-nav `1:8636` 350 x 64 pad top 4: back `1:8638` 41.81 x 44 r9999 white + `Fx.cardShadow` (= Figma 8/0,2 + 40/0,14) with `1_8640` 13.33 ink; titles `Sync Status` `Fx.display26` (26/32/800/-0.65 exact) + `Local Engine v4.2 • Background\nsync` `Fx.caption` (11/14/600/0.44 exact); No-Signal chip 94.78 x 40 r9999 `#EEEDF3` + `Fx.pillShadow`, gap 6 pad 6/12/6/12, `1_8648` 14.67x13.2 muted + `No\nSignal` caption (kit `F2bStatusPill` is fixed 22 tall — exact 40 pill built from primitives, gap below).
- Offline banner `1:8652` 350 x 172.19 r32 `#FFF5EB` (`F2b.peachWash`) + `Fx.cardShadow` (Figma single 40/0,14; extra blur-8 layer sub-JND), pad 20 gap 16: 12 dot (`F2b.amber` + `#66F59E0B` halo overlay) + content 282 x 132.19 gap 3.19; title row 282 x 44 (centered): `Working Offline — Saving\nLocally` `Fx.title16` (16/22/700/-0.16) + Store chip 73.34 x 32 `#FDE68A80` pad 2/28.23/2/8 text `Store\nActive` 11/700 ls 0.44 `F2b.amberDeep` (kit pill is 22 tall — exact chip built here); body 282 x 85 13/400 lh 21.13 (`Fx.text(13,21.13,400,0)`, `Fx.secondaryInk`) 4 lines.
- Stats row 350 x 145.75 gap 12: card1 169 x 144 / card2 169 x 145.75 r32 white + `Fx.cardShadow` pad 16; labels `BUFFERED CACHE` / `PENDING BATCH` 11/600 ls 0.55 muted (custom — `Fx.captionWide` is 700 weight); icons `1_8672` 13.5x12 / `1_8682` 14.25x15.75 `Fx.deepGreen`; card1 paragraph Stack (big `148.6` 22/700 ls -0.44 at 0,0 + `MB Local` caption at 60.98,11.5); card2 column (`3` 28 + gap 3 + `Inspections` 28 + gap 7.5 + `Awaiting link` 14 + 5.5).
- Upload section 350 x 486 pad top 8 gap 12: header 350 x 24 pad 4 (`Upload Queue` `Fx.heading18` 18/24/700/-0.27 + `Auto-retry paused` caption); active card 350 x 222 r32 white pad 20 gap 16: top row 310 x 80 (icon pill 30.16 x 40 `#F4F3F8` + `1_8700` 13.33 deepGreen, titles `Uploading Evidence\nPhotos (4/12)` title16 + `Job #IN-88912 • 2024 Ford F-\n150 Lightning` body13, `Standby` 68.3 x 22 `#EEEDF3` pad 4/10/4/10 11/600 ls 0.44 ink — matches `F2bStatusPill` geometry, built exact); progress 310 x 26 gap 6 (track 310 x 6 `#EEEDF3` + fill 103.22 x 6 `Fx.emerald`, labels `33% completed` caption + `8 items remaining` 11/500 `Fx.captionMedium`); metrics 310 x 44 pad top 8 (121.97 + gap 37.78 + divider 1 x 32 + gap 37.77 + 111.48; icon discs 28 `#EEEDF3` + `1_8720`/`1_8730` muted, `Transfer Speed`/`Pending Jobs` captions + `0.0 KB/s`/`2 in Line` title16).
- Queued rows 350 x 98 r32 white pad 20: row2 (pill 30.39 x 40 + `1_8740` 16.67 muted, `Telemetry Telematics & Checkpoints` title16 + `Job #IN-88909 • 6 Diagnostic\nCodes` body13, right `Queued` caption + `18.4 MB` 13/600 ink); row3 (pill 36.3 x 40 + `1_8755` 15.83 muted, `Body Schematics Pin Markups` + `Job #IN-88904 • 4 Dent\nAnnotations`, `Queued` + `6.2 MB`).
- Retry margin 350 x 126 pad top 24 → zone 350 x 102 pad top 16 gap 12: `FxButton` 350 x 56 emerald + `Fx.ctaShadow` (= Figma 25/0,10) label `Retry Sync Now` `Fx.label14` (14/18/700/-0.14 exact) + `1_8770` 13.33 white (leading, `trailingIcon: false`); note `Device will ping master servers every 60 seconds` body13 centered.
- Header `1:8776` 390 x 64 `#FFFFFFCC` + `Fx.headerShadow` + blur 48, pad 20: shield 36 circle `#F4F3F8` + `1_8781` 18.33 deepGreen, `Sync Queue` `Fx.text(22,28,700,-0.55)` (kit `FxHeader` is -0.27 with Material glyph — exact header built from primitives), avatar 32 `Fx.deepGreen` + `1_8786` 12 white. Custom-built (same pattern as the final-review fixture).
- Nav `1:8787` 390 x 80 pad 0/20/16/20 → pill 350 x 64 r9999 white + `Fx.navShadow` (= Figma 12/0,4 + 50/0,18), centered row gap 23.5: links 56 x 44 (icon + gap 2 + label 11/600 ls 0.44; Intake `1_8791`, Fleet `1_8796`, Sync `1_8801` ink selected, Profile `1_8806`). `FxDock` slot/gap geometry differs (44/39.5 vs 56/23.5) — exact nav built from primitives.

## Kit gaps (lead only, not edited) with measured effect
- `F2bStatusPill` fixed 22 tall vs Figma No-Signal 40 and Store Active 32 (built exact 40/32 pills from primitives; Standby 22 matches geometry and was built exact with the same 4/10 pad).
- `FxHeader` back uses a Material glyph and -0.27 tracking; Figma needs vector `1_8781` and -0.55 tracking (header built exact from `Fx` primitives).
- `FxDock` slot 44 / gap 39.5 vs Figma links 56 / gap 23.5 (nav built exact).
- `F2b` label style: `BUFFERED CACHE`/`PENDING BATCH` need 11/600 ls 0.55 (kit `captionWide` is 700) — inlined test-only.
- Banner body needs 13/21.13 (kit `body13` is 13/18) — inlined test-only.
- `8 items remaining` needs 11/500 (kit has `captionMedium` — used).
- Banner shadow: kit `Fx.cardShadow` adds a blur-8 layer over Figma's single blur-40; header shadow `Fx.headerShadow` (6.3%) vs Figma 3% blur-8; both sub-JND (no diff box attributable).
- No `F2bStatusPill`/CTA/nav/header token covers the Figma exact sizes above; fixture builds them from `Fx` tokens at Figma geometry (positions exact, key boxes delta 0).

## Residual (measured, not claimed)
- Gate: **PASS — SSIM 0.98039 ≥ 0.98** (min 64×64 tile 0.78528; RMSE 11.657; MAE 2.405; ΔE2000 mean 0.706 / median 0 / p95 1.739 / max 85.576; ΔE >5 2.51%, ΔE >10 1.77%). Text 38/38 present; forbidden terms 0; key boxes 3/3 within 2 px (all delta 0).
- 20 diff boxes (ΔE2000 >5, area ≥16), largest 296 x 0.5 logical (button top-edge AA + emerald shadow edge), next 17.5 x 15 (stat icon `1_8682` vector raster), remainder ≤98 x 0.5: progress-fill top AA (98 x 0.5 in the fill region), stat label/icon glyph edges (372–382 rows), back/header/nav vector glyphs, queued-row glyph tails. No box exceeds 296 x 0.5 logical and no box indicates a layout, colour, radius, spacing, or copy error: every box maps to a glyph/vector edge or a 0.5-px AA edge.
- Worst 64×64 tiles are all text/icon areas: (256,352) 0.785 stat labels/icons, (320,352) 0.792, (224,352) 0.803, (288,352) 0.829, nav (128,1280) 0.849 / (288,1280) 0.854, header (96,96) 0.884 — typical 1–2 px Plus Jakarta Sans / SVG rasterisation (Flutter Skia vs Figma), not geometry.
- Iterations: initial 0.97752 (Store chip 6 px high, metric/nav icon sizes) → 0.97964 after centering the Store chip in its 44 row (largest box 73.5 x 38 removed, worst tile 0.288 → 0.785) → **0.98039** after sizing non-square vectors at `max(w,h)` (`1_8730` 12.5→11.88, `1_8755` 15→15.83, nav wide icons to max). Only font/vector rasterisation remains.

## What this proves / needs from the lead
- The shared kits reproduce the Figma geometry exactly (all audited nodes at Figma coords; key boxes delta 0) and all fills/shadows except the gaps above.
- To ship this screen the lead owns: exact pill heights/pads for 40/32 status chips, header/nav exact builds (vector back, -0.55 tracking, 56/23.5 nav geometry), label tracking/weight tokens (0.55/600 kicker, 21.13 body), and product decisions already flagged in the screen spec (invented `Local Engine v4.2`, `148.6 MB`, `3 Inspections`, `4/12`, `33%`, `0.0 KB/s`, `2 in Line`, sizes, `Standby`/`Queued` states, `Auto-retry paused`, 60 s cadence, Fleet/Profile nav).
- Residual is glyph AA/phase + SVG vector rasterisation plus 0.5-px top-edge AA on the CTA/progress; no unexplained diff >4 px.

## What could not be verified
- Figma text shaping beyond rendered SSIM (no access to Figma's text engine); residual glyph AA is measured, not modelled.
- Figma shadow colours are not exported (only offsets/blurs); kit shadows with matching geometry were used and no diff box attributes to them beyond the 0.5-px CTA edge.
- Anything outside this screen (other F2-B.3 screens are out of scope).
