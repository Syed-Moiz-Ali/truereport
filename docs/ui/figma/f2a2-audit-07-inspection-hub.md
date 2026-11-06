# F2-A.2 region audit — screen 7 Inspection Hub

Read-only audit of `figma-text` and `product-copy` captures against node dump 07.
No app/test/server code was changed. Renderer: Flutter, 390×1130 @ DPR2.
Gate: **FAIL**. figma-text SSIM 0.82651 (worst tile 0.19508), ΔE2000>5 12.81%,
RMSE 52.963; product-copy SSIM 0.82873. `debugDisableShadows` is now `false`.

## Headline: reference crop is misregistered (harness, not app)

The fixture crops the @2x reference at `y=59` px, but the exported frame content
starts at `y=14` px (profile chip: reference `y=46..109` px vs node `y=16..48`
logical). The crop therefore removes 45 px (22.5 logical) too much from the top,
shifting every reference element ~22.5 logical px up. Evidence: node
"Inspection Modules" dark core is `y≈536..548`; reference core is
`y516.5..525.0`; render core is `y539..547.5` (node-aligned). After adding 22.5,
reference and render match. **This one crop error explains most of the 20 boxes**
and inflates both fixtures that share this reference/crop. Correct crop `y≈14`
px, then re-measure before attributing remaining boxes to app code.

## Diff boxes (logical coords, ΔE2000 > 5)

| # | Region | x | y | w | h | Likely cause | Concrete fix |
|---:|---|---:|---:|---:|---:|---|---|
| 1 | CTA button + glow tail | 11.5 | 963 | 367 | 62 | Crop -22.5 px; CTA shadow tail below button | Fix crop; then verify `Fx.ctaShadow` 25/10 alpha |
| 2 | Gap above CTA | 16.5 | 923 | 357.5 | 39.5 | Same crop offset; grid-card shadow in 24 px gap | Fix crop; re-check card shadow alpha |
| 3 | Hero ring, right/bottom arc | 210 | 198.5 | 73 | 119 | Ring radius too large: painter uses `(176-13.2)/2=81.4` vs node path 145.2 (r≈72.6); fraction 0.409 vs "45% filled" | Use exported ring SVG or radius≈72.6, stroke 13.2; figmaText fraction 0.45 |
| 4 | Hero ring, top-right arc | 188 | 140 | 83.5 | 63.5 | Same ring radius; arc end length differs | Same as #3 |
| 5 | Vehicle strip photo | 36 | 427 | 48 | 49.5 | Avatar renders 24 px `FxIcon 1_7804`, node 1:7757 is raster vehicle photo | figmaText: raster photo (J7 test-only); product: keep icon |
| 6 | Exterior done pin | 133.5 | 567.5 | 38.5 | 50.5 | Crop + pin shadow `softShadow` 16/4 vs node 24/8 | Fix crop; pin shadow blur 24, dy 8 |
| 7 | Header profile button | 338 | 0 | 32 | 48 | Shows `DV` text; node 1:7873 is 12 px white person vector. Crop clips top | figmaText: `FxIcon 1_7873` size 12 white; header fill `0xCCFFFFFF` |
| 8 | Hero "45 /110" | 161.5 | 202.5 | 69 | 41 | `FxCoverageRing` forces `height:1` on 26/32 display style (26 px line box); `/110` baseline; crop | Remove `height:1`, use lh 32 for "45", lh 20 for "/110" |
| 9 | Underbody heading | 274 | 853.5 | 47 | 17.5 | Crop (render node-aligned; reference ~22.5 higher) | Fix crop |
| 10 | Vehicle title "Taycan 4S" | 169 | 449.5 | 45.5 | 18 | Crop | Fix crop |
| 11 | Engine heading | 41 | 853.5 | 30.5 | 17.5 | Crop | Fix crop |
| 12 | Exterior heading | 40.5 | 670.5 | 27 | 16.5 | Crop + card-1 gap 45/footer 14 vs uniform gap 41/footer 18 (title 4 px high) | Per-state gap/footer: done 45/14, in-progress & pending 41/18 |
| 13 | Underbody heading | 246.5 | 853.5 | 29 | 14.5 | Crop | Fix crop |
| 14 | Dock Fleet icon | 141.5 | 1063.5 | 23.5 | 19 | All dock glyphs forced to 20×20; node Fleet is 16.5×14.67 | Per-item icon size/box from nodes |
| 15 | Vehicle title | 129.5 | 449.5 | 30.5 | 14.5 | Crop | Fix crop |
| 16 | Exterior heading (reference half) | 41 | 652 | 26.5 | 14 | Crop (reference title core ~647..671) | Fix crop |
| 17 | Underbody heading | 223.5 | 853.5 | 22.5 | 15.5 | Crop | Fix crop |
| 18 | Engine heading | 73 | 857 | 25 | 11 | Crop | Fix crop |
| 19 | Interior heading | 238.5 | 672 | 24.5 | 13 | Crop | Fix crop |
| 20 | Interior heading | 264 | 674 | 23 | 13.5 | Crop | Fix crop |

## Additional visible diffs (sub-threshold / not boxed)

- **Status row:** render truncates to `INSPECTION IN PRO…`; node pill is 195.59
  wide with full `INSPECTION IN PROGRESS`. Two `Flexible` children split the row
  equally (`inspection_hub_view.dart:139-189`). Make the pill intrinsic (remove
  outer `Flexible`) or use asymmetric flex; keep trailing label ellipsized only.
- **Copy:** node 1:7771 is `4 Categories` (capital C) but render uses lowercase
  l10n; node 1:7827 Interior footer is `Active Bay` but figmaText renders
  `17/32 checks` (`inspection_hub_view.dart:322, 566-572`).
- **Header fill:** node `#FFFFFFCC` + blur 48; `FxHeader` paints opaque white.
- **Dock fill:** node opaque `#FFFFFF`; `FxDock` uses 0.95 white + blur.
- **Module card radius/shadow** match constants, but shadow color/alpha is
  guessed (`0x04`/`0x0B` black) because the node dump omits colors.

## Top 5 fixes

1. **Recalibrate the reference crop** from `y=59` to `y≈14` px (and add key
   boxes to `geometry.json`). This alone should clear #1, #2, #4, #6, #9-#13,
   #15-#20 and most of #5/#7/#8.
2. **Hero ring geometry:** replace the `CustomPainter` radius with the node path
   geometry (r≈72.6, stroke 13.2, round caps) or render the exported SVG; in
   figmaText use 45% fill to match the reference arc.
3. **Hero ring typography:** remove `height:1` at `figma_screen_kit.dart:1065`,
   use 26/32 for `45` and 14/20 baseline-aligned `/110`.
4. **Asset parity:** profile button should use vector 1:7873 (not initials);
   vehicle avatar should use the J7 raster photo in figmaText mode (not 1_7804).
5. **Module/dock polish:** done-state gap 45 + footer 14; done-pin shadow 24/8;
   per-item dock icon sizes (Fleet 16.5×14.67, Sync 14.67, Profile 18.2×15.58);
   fix status-row flex and the `Active Bay` / `4 Categories` copy.

## Approved residuals

- Test-only Figma raster vehicle photo and exported SVG icons (allowed by J7),
  provided product-copy keeps product icons/assets.
- Plus Jakarta Sans glyph rasterisation / antialiasing differences between
  Figma's rasteriser and Flutter (expected small ΔE at text edges).
- Dynamic product data in the product-copy fixture (job id, counts, statuses).
- Card/CTA/pin shadow **alpha** until Figma shadow colors are exported; blur and
  offset are matched, color is currently inferred.
- 45/110 (40.9%) vs "45% filled": product should keep the real ratio; figma-text
  may use 45% as a design-reference override.

## What could not be verified

- Exact Figma shadow colors/alphas and Flutter blur-sigma equivalence; node dump
  lists only blur/offset for card, pin, CTA, header, nav and dock shadows.
- Whether `y=14` px is the canonical frame offset or an export artifact; no key
  boxes exist in `geometry.json`, so crop alignment is inferred from pixel
  landmarks (profile chip, section header, done pin).
- Provenance/licensing of the raster vehicle photo for test-only use.
- Which source wins for the ring when 45% (design label) differs from 45/110.
- RTL/Arabic, text scaling and dark-theme behaviour (not rendered here).
