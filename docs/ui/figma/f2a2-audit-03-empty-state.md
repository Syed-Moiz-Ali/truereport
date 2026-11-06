# F2-A.2 audit — Screen 3 Empty State (region fidelity)

Read-only audit. Inputs: `docs/ui/figma/f2a1-nodes/03-empty-state.txt`;
`docs/ui/figma/fidelity/f2a1/empty-state/{figma-text,product-copy}/`; render
path `client/apps/technician_app/lib/src/screens/f2a/assigned_jobs_view.dart`
(`EmptyJobsView`); kit `client/packages/design_system/lib/src/components/figma_screen_kit.dart`.
Latest gate: figma-text SSIM 0.84534 / product-copy 0.84596; both FAIL 0.98.

Classes: **L** layout, **F** font/copy, **S** shadow/fill, **I** icon, **M** image,
**A** approved slot replacement.

## Key finding — one harness defect dominates

The render is vertically correct against the node dump: every render row band
equals `node y × 2` (header, top row, welcome, art, pills, body, summary, dock).
`figma.png` is uniformly **45 device px (22.5 logical) higher** than the node /
render. Cross-correlation returns **−45 px for every region**; best horizontal
shift is **0 px** in all regions. The fixture crop `y: 59` starts ~45 px too low
inside the @2x reference; content appears shifted up. Re-crop at
`crop.y ≈ 14` (x stays 60) and regenerate `figma.png`. Until then, all 20 boxes
are position-amplified and the SSIM result is not a valid screen score.

## Diff boxes — figma-text (all 20), product-copy deltas

| # | Box x,y,w,h (logical) | Region | Class | Likely cause | Concrete fix | product-copy |
|---:|---|---|---|---|---|---|
| 1 | 141.5,410 114×35.5 | queue pill + heading top | L | render pill at y410; ref pill at y387.5 (−22.5) | re-crop reference; no widget move | same |
| 2 | 19.5,49.5 61.5×70.5 | avatar/halo | S,L | 22.5px offset + halo `#10B98126`/shadow missing; glow is mint 22% | outer 48 `Fx.emerald` α0.149 + blur16/0,4 shadow | 72.5×70.5 (QUEUE EMPTY pill width) A |
| 3 | 141.5,387.5 107×22 | queue pill (ref) | L,I | ref-only position + leading icon uses `1_7335` cup, node `1_7318` check | re-crop; queue icon id `1_7318` | same |
| 4 | 178.5,275 33×48.5 | art icon | L | ref icon at y275, render at y297.5 | re-crop reference | same |
| 5 | 332,0 32×48 | profile avatar | M,L | photo (IMAGE `1:7373`) vs `DV` initials; ref clipped at top | test-only Figma avatar asset (J7), keep 32px | area 4229 (LH) A |
| 6 | 20,150.5 47.5×24.5 | "David Vance" glyphs (ref) | F,L | ref glyph row 147.5–179.5; render 170–202 | re-crop; keep 26/800 lh32 ls−0.65 | same (Layla) |
| 7 | 130.5,715 54×15.5 | "TODAY'S SUMMARY" | F,L | render label only; ref label 22.5 higher | re-crop; text style already 11/600 lh14 ls0.44 | same |
| 8 | 111.5,150.5 29×24.5 | "David Vance" glyphs (ref) | F,L | same glyph/offset cluster | re-crop; font residual accepted | same |
| 9 | 68,154 22.5×21 | "David Vance" glyphs (ref) | F,L | same glyph/offset cluster | re-crop; font residual accepted | same |
| 10 | 195.5,488.5 42×14 | body line 1 | F,L | figma-text uses product copy + different wrap; plus offset | figmaText copy `No pending vehicle inspections assigned\nto you today.` | same (product copy approved A) |
| 11 | 56,817.5 24×20.5 | Intake dock icon | I,L | `FxIcon` forced 20×20; node 18×20; + offset | per-item 18×20, id `1_7378` | same |
| 12 | 148.5,488.5 45.5×14 | body line 1 | F,L | product copy/wrap + offset | as #10 | same (approved A) |
| 13 | 94,150.5 18.5×24 | "David Vance" glyphs (ref) | F,L | same glyph/offset cluster | re-crop | same |
| 14 | 139.5,818 23.5×18.5 | Fleet dock icon | I,L | `FxIcon` 20×20; node 18×16; + offset | per-item 18×16, id `1_7383` | 144.5,818 17.5×18.5 |
| 15 | 21,177.5 17×19.5 | "David Vance" render glyphs | F,L | render-only row; ref glyphs 22.5 higher | re-crop; font residual accepted | 21,177.5 26×20 (Layla) |
| 16 | 234,455 17.5×21.5 | heading tail | F,L | no `!` in `technicianAllCaughtUp`; ref has `You are all caught up!` | figmaText string with `!`, width 216 | 89,177.5 16×19.5 (Layla) |
| 17 | 223.5,819 26.5×14.5 | Sync dock icon | I,L | `FxIcon` 20×20; node 22×18; + offset | per-item 22×18, id `1_7388` | same |
| 18 | 309.5,818 20.5×19.5 | Profile dock icon | I,L | 20×20 matches node, but screen-2 asset id + offset | id `1_7393`; 20×20 | same |
| 19 | 74,177.5 15.5×20 | "David Vance" render glyphs | F,L | render-only row; ref 22.5 higher | re-crop | 89,177.5 (see #16) |
| 20 | 310,795.5 20.5×20 | Profile dock icon (ref) | L,I | ref-only position; same icon region as #18 | re-crop | same |

Product-copy boxes are identical except #2, #5, #14, #15, #16, #19 (name/status
copy widths) and #14/#20 icon-box placement. Those deltas and the `LH` avatar are
**approved slot replacements**, not defects.

## Top 5 fixes

1. **Re-crop the reference (root cause).** Set fixture `crop.y` from `59` to
   `≈14` device px, regenerate `figma.png`/`side-by-side`/`diff`/metrics. This
   should retire the offset share of every box before any code change.
2. **Fix icon selection and per-slot size.** Queue pill `1_7318` (not `1_7335`);
   Bay pill `1_7302` (not `1_7143`); dock `1_7378/1_7383/1_7388/1_7393` at
   `18×20 / 18×16 / 22×18 / 20×20` (kit currently forces 20×20); add summary
   arrow `1_7360` at 15×9 beside `100% Pass Rate`.
3. **Shadow/fill parity.** Avatar halo `#10B98126` + `d(16,0,4)` shadow; delete
   the extra `Fx.softShadow` on the 26px Bay pill; tone refresh uses node
   `d(8,0,2)` (now `Fx.pillShadow` 2/1); header fill `#FFFFFFE5` (now opaque)
   and blur 48; dock blur 48 (now 18; header currently 24 — unify the mapping).
4. **figma-text copy/data parity.** Header sync must pass `figmaText` so it shows
   `LIVE\nSYNC`; heading `!`; body copy/2 lines; `Refresh Queue` capital Q;
   fixture `completedToday: 14`; test-only Figma profile asset (J7). Product-copy
   keeps the slot-sheet strings.
5. **Re-run the gate.** After 1–4 the remaining boxes should be glyph/vector
   rasterisation only; require SSIM ≥0.98 and keep the diff-box list as a
   measured residual, not a pixel-perfect claim.

## Approved residuals

- Product-copy slot sheet: `QUEUE EMPTY`, `0 JOBS`, `ONLINE\nSYNC`, `LH`
  initials, real/zero completed count, `Coverage`, product body/heading/refresh
  copy. These boxes are A, not failures.
- 883.75 vs 884 frame rounding; Flutter vs Figma text/vector rasterisation.
- Figma sample people/data (`David Vance`, `14 Completed`) remain test fixtures;
  product uses real values.
- Shadow RGB/alpha and blurred-background sigma mapping cannot be matched from
  the node dump; only blur/offset/geometry are auditable.

## What could not be verified

- Exact source-preview crop origin; `y≈14` is inferred from uniform row
  cross-correlation, not from the export metadata.
- Vector glyph identities for `1:7302/7318/7328/7335/7343/7350/7360/7378/7383/7388/7393`;
  only size/colour/box are in the dump. Shapes are inferred from the preview.
- Profile `fill=IMAGE` (`1:7373`): no asset reference or consent record in repo;
  availability of a J7 test-only Figma avatar asset is assumed, not confirmed.
- Whether Figma `BACKGROUND_BLUR(48)` maps 1:1 or half to Flutter sigma; current
  kit uses 24 (header) and 18 (dock) for the same 48 value.
- Final SSIM/diff-box set after re-crop; product-copy deltas may renumber.
- Font rasterisation equality with the Figma renderer is not testable here.
