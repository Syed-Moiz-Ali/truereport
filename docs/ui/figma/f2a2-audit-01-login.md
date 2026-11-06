# F2-A.2 region fidelity audit — screen 1 (Login)

- **Sample:** `f2a1-login-figma-text` · 390×858 @ DPR 2 · crop 780×1716
- **Capture:** `2026-11-06T03:31:18Z`, `debugDisableShadows=false` (real shadows)
- **Gate:** FAIL — SSIM 0.97559 (≥0.98) · min 64px tile 0.56743 · RMSE 18.787 · ΔE2000 mean 1.029 / max 83.864
- **Diff area:** 57,998 px². Boxes 1+3 (button CTA halo) = 37,707 (65%); box 2 (logo slot) = 15,326 (26%); all text/icon boxes = 4,965 (9%).
- **Geometry sanity:** button emerald bbox is identical in both images (24,472)–(365.5,527.5); brand/tagline/footer ink bboxes agree within 0.5–1 px. **No box indicates a general size error.**
- **Caveat:** this capture still contains `TR` and `ISO 27001…`, so it predates J6 and does not exercise J3. J3/J6 boxes below are projected, not yet re-captured.

## Diff boxes (logical x/y/w/h, largest first)

| # | box x,y,w,h | likely cause | evidence | fix | allowed residual? |
|---:|---|---|---|---|---|
| 1 | 14.5,473.5,361,77.5 | shadow/glow | Render has an emerald halo ~40 px below/around the CTA: (24,528)=rgb(201,239,227), (24,544)=(231,248,242); Figma is pure white from y536. `FxButtonTone.primary` uses `Fx.ctaShadow` = `0x4D10B981`, blur 25, offset (0,10) (`figma_screen_kit.dart:290, :122-124`). Figma 1:7114 is `DROP_SHADOW(4 0,2 s-2)+DROP_SHADOW(6 0,4 s-1)` with no colour (default neutral black). | Replace primary CTA shadow with the Figma neutral pair (small blur, low black alpha); remove the green tint. | No |
| 2 | 163,104,64,64 | approved slot replacement (J6) / image | Figma 1:7089 is only `#6FFBBE4D` LAYER_BLUR(48); `figma.png` centre is (217,254,237), no tile. Render centre-left/top are `Fx.emerald` (16,185,129) — the solid `_BrandMark` tile (`sign_in_view.dart:456-476`, `_M.markSize=64`, `:493`). Exactly the J6 delta. | Apply J6: drop the emerald tile and keep the blurred glow only (`_M.glowBlur=24` ≈ Figma blur 48). | Yes — approved slot replacement; residual soft-glow blur only |
| 3 | 44.5,469,301,3.5 | shadow/glow | Render is already green-tinted above the CTA (y468–471 = 243–238 R vs 255 in Figma). Same `Fx.ctaShadow` as box 1. | Same fix as box 1. | No |
| 4 | 91.5,369,45.5,11.5 | layout offset (field hint) | Password hint ink: Figma 66.5→129.0, render 74.0→136.5 (width 62.5 both) → translated **+7.5 px**. `FxTextField` padds 16 + `FxIcon(size:17)` + 12 gap (`figma_screen_kit.dart:502-507`); Figma 1:7101 lock is 13.33 wide. | Use intrinsic per-field icon widths (email 16.67, password 13.33) and remove the field's extra hint inset. | Partial (then ≤1 px raster) |
| 5 | 319.5,368,26.5,12 | icon + layout offset | Reveal eye: Figma 329.5→345.5; render 319.5→336.0 → **10 px left**. Code uses a 44 px hit box with `Icons.visibility_outlined` (`sign_in_view.dart:403-410`); Figma 1:7105 is a 24.5 px button with exported icon 1:7107. | Shrink/re-anchor the reveal hit box to Figma's 24.5 px end slot and paint `FxIcon('1_7107')`. | No |
| 6 | 40,365,14.5,18 | icon | Password lock: Figma 40→53 (13.33×17.5, node 1:7101); render 42→54, slightly flatter/rounder. Code forces `FxIcon(size:17)` for every icon. | Paint 1:7101 at its intrinsic 13.33×17.5 (or per-node size). | Partial (small icon raster) |
| 7 | 69.5,305,17.5,11 | layout offset (field hint) | Email hint ink: Figma 69.5→103.0, render 74.0→107.5 (width 33.5 both) → translated **+4.5 px**. Plain `Text` elsewhere aligns ≤1 px, so the inset is inside `FxTextField`, not font metrics. | Zero the ~4.5 px inner hint inset in `FxTextField` (or place the hint as a fixed-origin Text). | No |
| 8 | 66.5,369,15,11.5 | layout offset (field hint) | Same password translation as box 4 (Figma 66.5 vs render 74.0). | Same fix as box 4. | No |
| 9 | 219.5,628.5,16.5,9 | text rasterisation | Security string identical and style matches (`Fx.caption` 11/14 w600 ls0.44 = Figma 1:7130); full ink bbox 91→297.5 vs 92→298.5 (~1 px). Glyph anti-alias only. | None. | Yes |
| 10 | 88.5,308,13,8.5 | layout offset (field hint) | Continuation of the `Email` run shifted as in box 7. | Same fix as box 7. | Partial |
| 11 | 287,629.5,12,10 | text rasterisation | Tail of security string; same ≤1 px subpixel shift. | None. | Yes |
| 12 | 91,628,8,10 | icon | Security shield (Figma 1:7128, 8×10): render starts ~92 vs Figma 91, ~1 px. Code `FxIcon('1_7128', size:8)` (`sign_in_view.dart:348-352`). | None beyond re-capture; verify SVG aspect fit. | Yes (small icon raster) |
| 13 | 259.5,201.5,10,18 | text rasterisation | Last glyph of brand; whole brand bbox 120→269 vs 120.5→269 (~0.5 px). `Fx.display26` = Figma 1:7083 (26/32 w800 ls-0.65). | None. | Yes |
| 14 | 202,631,10.5,6.5 | text rasterisation | Security glyph; see box 9. | None. | Yes |
| 15 | 258.5,631,11,6.5 | text rasterisation | Security glyph; see box 9. | None. | Yes |
| 16 | 269.5,631,9.5,6.5 | text rasterisation | Security glyph; see box 9. | None. | Yes |
| 17 | 279.5,631,7,6 | text rasterisation | Security glyph; see box 9. | None. | Yes |
| 18 | 251,628.5,7,9 | text rasterisation | Security glyph; see box 9. | None. | Yes |
| 19 | 281.5,423,6,8.5 | layout offset (vertical) | Forgot label ink: Figma y420.5→431, render y411→420.5 → **~10 px high**. Code uses `SizedBox(height:34)` + `Align(centerEnd)` (`sign_in_view.dart:246-257`); Figma 1:7108 pads top 16, text at 418. | Bottom-align the label (or add ~10 px top offset) to land at y418–432. | No |
| 20 | 281.5,413,6,8 | layout offset (vertical) | Same forgot-label translation as box 19. | Same fix as box 19. | No |

## Top 5 fixes

1. **CTA shadow (boxes 1+3, 65% of diff area).** Primary `FxButton` must not use the emerald `Fx.ctaShadow` (`0x4D10B981`, blur 25, y+10). Use the Figma stack `DROP_SHADOW(4 0,2 s-2)+DROP_SHADOW(6 0,4 s-1)` (1:7114, default neutral). This is the single largest fidelity win and only became visible when `debugDisableShadows` was turned off.
2. **Apply J6 to `_BrandMark` (box 2, 26%).** Keep the `#6FFBBE4D` blurred glow and delete the 64 px emerald `TR` tile (`sign_in_view.dart:456-476`). Then re-capture to confirm the slot matches.
3. **Pin `FxTextField` hint origin (boxes 4,7,8,10).** Both hints render at x=74 while the declared origin is ≈69; Figma is 69.5 (email) and 66.5 (password). Remove the ~4.5 px inner inset and use per-node icon widths (16.67 email / 13.33 lock) so the password run shifts left by the extra ~3 px.
4. **Fix forgot-password vertical alignment (boxes 19,20).** The label is ~10 px too high; bottom-align or add the 10 px top offset so ink lands at y420.5–431.
5. **Fix password reveal slot (box 5).** Use the 24.5 px Figma button geometry and the exported 1:7107 SVG instead of the 44 px Material `visibility_outlined` hit box, which sits 10 px too far left.

## Approved residuals

- **Text rasterisation:** boxes 9, 11, 13, 14–18 (security line + brand tail). Strings and styles match exactly; shifts are ≤1 px and come from glyph anti-aliasing/subpixel positioning. `Fx.caption` = 11/14 w600 ls0.44 and `Fx.display26` = 26/32 w800 ls-0.65 already match nodes 1:7130/1:7083.
- **Security shield (box 12):** 8×10 vector at a ~1 px offset; acceptable icon raster after re-capture.
- **J3 copy slot:** the security line becomes “Authorised workshop staff only”; its width/ink will differ from the Figma string. The `product-copy` sample already shows the copy-driven footer deltas (REPORT boxes at y628), so these are approved copy, not layout.
- **J6 logo glow:** after tile removal a small blur/opacity delta may remain (`ImageFilter.blur` sigma 24 vs Figma LAYER_BLUR 48); acceptable slot effect.
- **Language chip:** the top tiles dip to SSIM ~0.88–0.99 but produce no ΔE>5 box. Figma Arabic is `FreeSerif Bold 12` (1:7080) vs the platform Arabic fallback; accepted font-fallback residual.

## What could not be verified

- The `figma-text` capture predates J6 (still shows `TR`) and does not exercise J3 (it passes the Figma ISO string). **A fresh capture with both decisions applied is required** to confirm boxes 2 and the J3 copy slot.
- The exact source of the ~4.5 px hint inset (Flutter `InputDecorator`/hint layout vs font metrics) cannot be isolated from raster images alone; every non-field `Text` aligns ≤1 px, so it is field-local. Needs a widget-tree/golden probe.
- Whether the reveal glyph is the exported 1:7107 SVG or a Material icon cannot be proven from pixels; the source (`sign_in_view.dart:408`) shows `Icons.visibility_outlined`, which is the likely cause of the 10 px geometry delta.
- The CTA halo could partly be engine shadow rasterisation (Impeller); re-run on a second renderer to separate token error from engine effect.
- `keyBoxes` is empty, so no field/button region geometry is machine-asserted; all positions above are inferred from the node dump plus pixel scans.
- The `product-copy` variant was used only for copy cross-check; its render also predates J3.
