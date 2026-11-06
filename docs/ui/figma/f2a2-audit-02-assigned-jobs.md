# F2-A.2 Region Fidelity Audit — Screen 2 (Assigned Jobs)

Read-only audit of the `figma-text` render (real shadows, `debugDisableShadows = false`) and the `product-copy` variant against the Figma node dump and reference crop. No app/test/server code was changed; this is the only file written.

- Sample: `f2a1-assigned-jobs-figma-text`, 390×1002 @ DPR 2, comparative grid 780×2004.
- SSIM: 0.80044 (gate <0.98) · worst 64×64 tile 0.12976 · RMSE 54.98 · ΔE2000 mean 5.99, p95 33.78.
- Product variant: SSIM 0.80768 · RMSE 64.59 · ΔE2000 mean 7.60.
- Node dump: `docs/ui/figma/f2a1-nodes/02-assigned-jobs.txt` (+ `.json`); source effects read from `docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/2._Assigned_Jobs_Dashboard.json`.
- Code: `client/apps/technician_app/lib/src/screens/f2a/assigned_jobs_view.dart`, `client/packages/design_system/lib/src/components/figma_screen_kit.dart`.

## Global finding (root cause of most boxes)

The body/dock in `figma.png` sits **22.5 logical px (45 device px) higher** than in `render.png`. Card titles/chevrons and the CTA confirm it: e.g. Figma node CTA 826–882 matches render 825.5–882, while `figma.png` shows 803–859.5; node `Inspection Queue` title is clipped at `figma.png` y=0. The render matches the node coordinates, so the reference crop origin (`crop.y = 59`) appears ~45 device px too low. This offset alone explains the paired boxes (Figma y vs render y+22.5) and dominates SSIM/ΔE.

Separately, the **card bottom row is 6 logical px too high** inside every card (dot/service/status pill); top row and card height are correct.

## Diff boxes (logical coords, figma-text, all 20)

| # | Box x,y,w,h | Region | Likely cause | Concrete fix |
|---:|---|---|---|---|
| 1 | 11, 843, 368, 62.5 | CTA button lower half + glow | Global +22.5 offset (`figma.png` CTA 803–859.5 vs render 825.5–882); CTA shadow itself is already exact | Re-crop reference; keep `Fx.ctaShadow` (emerald 30%, blur 25, y10) |
| 2 | 17, 803.5, 356.5, 39 | CTA upper half / gap above | Same global offset + CTA top glow | Re-crop reference; no code change |
| 3 | 17, 55.5, 61.5, 72.5 | Body DV avatar | Offset + glow mismatch: Figma 56 px `#10B98126` (emerald 15%) + shadow emerald 18% blur16 y4; code mint `#6FFBBE` @22% and no shadow (`figma_screen_kit.dart:813-838`) | Use emerald 15% fill + `BoxShadow(emerald .18, blur16, y4)` |
| 4 | 195, 346, 77, 18 | Render “3 In Queue” pill | Pill is centred, not end-aligned: `Expanded` + `Flexible` split the row (`assigned_jobs_view.dart:267-303`) | Remove `Flexible` from pill (keep `Expanded` on label); expected x≈289 |
| 5 | 289, 323.5, 77, 18 | Figma “3 In Queue” pill | Same flex bug + 22.5 y offset | Same as #4 |
| 6 | 332, 0, 32, 48 | Header profile avatar | Figma is a 32×32 IMAGE/photo; render is green “DV” initials (`FxProfileButton`). J7 permits exported photo **only in test-only fixtures** | In figma-text fixture only, render `assets/images/rendered_png/Profile-1_7264@2x.png`; keep initials in product |
| 7 | 304, 669.5, 47.5, 36.5 | Card 3 chevron (Figma pos) | 22.5 offset + shadow: Figma emerald 15% blur14 y4; code black 8% blur16 y4 (`Fx.softShadow`) | Give chevron emerald shadow blur14 y4 |
| 8 | 304, 523.5, 47.5, 36.5 | Card 2 chevron (Figma pos) | Same | Same as #7 |
| 9 | 304, 377.5, 47.5, 36.5 | Card 1 chevron (Figma pos) | Same | Same as #7 |
| 10 | 36, 235.5, 40, 31 | Snapshot card 1 icon tile (Figma pos) | 22.5 offset; icon vector 18.33 vs code 18 | Re-crop; size icon 18.33 |
| 11 | 36, 267, 40, 31 | Snapshot card 1 icon tile (render pos) | Same offset; tile fill matches (`#6FFBBE4D`) | Same as #10 |
| 12 | 306, 562, 44, 28 | Card 2 chevron (render pos) | 22.5 offset + black shadow instead of green | Same as #7 |
| 13 | 306, 708, 44, 28 | Card 3 chevron (render pos) | Same | Same as #7 |
| 14 | 306, 416, 44, 28 | Card 1 chevron (render pos) | Same | Same as #7 |
| 15 | 92.5, 157.5, 48, 25.5 | “Welcome back,” (“back,”) | 22.5 offset + Plus Jakarta Sans raster metrics | Re-crop; accept font-raster residual |
| 16 | 108, 552.5, 50.5, 12.5 | Card 2 reference line | Copy: Figma `XYZ 882 • Bay 2`; render hardcodes `ABC 123 · Bay 4` (`assigned_jobs_view.dart:904-906`) | Use per-card reference/plate and `•` (U+2022) |
| 17 | 53, 161, 22, 21.5 | “Welcome back,” glyphs | Offset + text raster | Re-crop; accept raster residual |
| 18 | 20, 157.5, 18.5, 25 | “W” in “Welcome” | Offset + text raster | Re-crop; accept raster residual |
| 19 | 74, 161, 17.5, 22 | “e/c” glyphs | Offset + text raster | Re-crop; accept raster residual |
| 20 | 56, 936, 24, 20 | Dock “Intake” label | 22.5 offset + label raster; dock blur/alpha also differ (below) | Re-crop; fix dock blur/alpha |

## Top 5 fixes

1. **Re-align the reference crop first (highest impact).** `crop.y = 59` should be ~45 device px higher (~14) or the frame origin located from the uncropped export. Evidence: render matches node y; `figma.png` is node−22.5 and clips the header. Re-run metrics before touching layout, otherwise fixes 2–5 will be mis-measured.
2. **Card bottom row: add `top: 12` padding.** Figma’s bottom container is 30 high with `pad=12,0,0,0` (`02-assigned-jobs.txt:65`), placing the dot at y477. Flutter centres the 8 px dot in 30 px, giving y471. Add a top-12 inset (or `padding` on the bottom `ConstrainedBox`) in `assigned_jobs_view.dart:986-1015`. Card height is otherwise correct: 20+44+16+30+20 = 130 = Figma.
3. **End-align the “N In Queue” pill.** Replace `Expanded(text) + Flexible(pill)` with `Expanded(text) + pill` (or `Spacer`) in `assigned_jobs_view.dart:267-303`; render pill x is 195, expected 289.
4. **Restore figma-text copy.** In figmaText mode stop hardcoding `ABC 123 · Bay 4`; use `XYZ 882 • Bay 2` / `KLO 904 • Bay 6` and `•` separator. Also prefer `templateName` (fixture already has `Full Pre-Delivery Inspection`, `Brake Fluid & Tire Diagnostics`, `Routine 60-Point Audit`) over the generic `job.scope = 'Full inspection'` (`assigned_jobs_view.dart:903-906`).
5. **Correct shadow/glow tokens.** Avatar: emerald 15% + emerald 18% blur16 y4 (not mint 22%, no shadow). Chevron: emerald 15% blur14 y4 (not black 8% blur16). Header: fill `#FFFFFFE5`, black 3% blur8 y1, blur σ≈48 (code is opaque, 6.3%, σ24). Dock: black 3% blur12 y4 + 8% blur50 y18, blur σ≈48 (code 6.3%/10.2%, σ18). Sync pill: black 2% blur8 y2 (currently none). Snapshot panel: black 3.5% blur32 y12 (code 5.1%). Optional J7 test-only header photo (box 6).

## Approved residuals

- **J1:** dock `Fleet` → `Finalized` in the product-copy render is approved; it is not a Figma miss.
- **J7:** Figma exported avatar/photo is allowed only in test-only fixtures. Production initials (`DV`/`LH`) are correct; the header-photo diff is a fixture choice, not a product regression.
- **Product-copy data variance:** 2 jobs vs Figma’s 3, `ONLINE SYNC` vs `LIVE SYNC`, `TODAY • 2 JOBS` vs `SHIFT 1 • BAY A`, and different counts. The large product-copy boxes at y≈675.5 and y≈803 are the CTA reflow caused by card count, not layout defects.
- **Text raster / SVG raster:** Plus Jakarta Sans glyph edges and vector icon antialiasing will not be pixel-identical; sub-pixel ΔE is accepted.
- **Shadows are enabled** (`debugDisableShadows = false`); no “missing shadow” residual remains from the debug flag.

## What could not be verified

- Whether the +22.5 logical offset is a harness crop error or an app inset: evidence favours crop (render matches node y; header clipped), but the uncropped reference and crop approval were not available, and no re-render was permitted.
- Exact Figma effect alpha in the node dump (`color: null`); values above are from the source export JSON. Flutter `BackdropFilter` sigma→Figma radius mapping (σ24/18 vs radius 48) was not empirically calibrated.
- Post-fix SSIM/gate: no capture/re-render was run, so the 0.98 gate cannot be confirmed; no pixel-perfect claim is made.
- Avatar-photo asset provenance/licensing for the test fixture (asset exists at `Profile-1_7264@2x.png`) and whether the harness loader registers it.
- Font binary/version, line-height rounding, and `TextScaler = 1` at runtime; text-height measurements (e.g. value blocks 22 vs 28 px) may partly be raster metrics.
- Product-copy expected copy is not declared in the fixture (`expectedStrings: []`), so only string presence, not copy correctness, was verifiable.
