# F2-B.3 Part 2 — Screen 16 Post-Finalization Success, Level 1 METHOD

## What was built

- Fixture widget: `client/apps/technician_app/test/support/f2b3_success_fixture.dart`
  (new file; test-only, Figma-exact tree — never the production `SuccessView`).
- Capture: `client/apps/technician_app/test/f2b3_capture_success_test.dart`
  (new file; mirrors `test/f2b_fidelity_capture_test.dart`: `enableFidelityShadows`
  + restore, 390 logical px, DPR 2, `RepaintBoundary` → `toImage`, writes
  `render.png`, `geometry.json`, `strings.json`).
- Fixture: `docs/ui/figma/fidelity/fixtures/f2b3/success-level1.json`
  (schema per `tools/figma_fidelity/compare.mjs` + `tools/figma_fidelity/README.md`).
- Output dir: `docs/ui/figma/fidelity/f2b3/success/`
  (`figma.png`, `render.png`, `side-by-side.png`, `diff.png`, `metrics.json`,
  `REPORT.md`, this file).

The fixture widget is a test-only, Figma-exact tree for Figma screen 16
(`1:8931`, export folder `16_16._Post-Finalization_Success`). It does NOT reuse
the production `SuccessView`. Structure mirrors
`docs/ui/figma/specs/technician_app/16-post-finalization-success.md` §2 and
`docs/ui/figma/f2b-nodes/16-success.txt` node-for-node (sizes, positions,
fills, radii, shadows, type). Shared-kit usage: `Fx.*`/`F2b.*` tokens
(`figma_screen_kit.dart`), `FxButton` (primary CTA), `FxCard` (delivery card),
`FxIconTile` (channel icons), `FxIcon` (CTA arrow, success check),
`f2bHost` with `figmaStrings: true`. Text is the exact Figma copy (Level 1
fidelity requires it, including the unsafe "Locked & Signed" / "Fleet Portal"
wording — this copy must never ship; it lives only in `test/`).

Two Figma-exact structural facts the fixture reproduces literally:

1. `1:8941 Center Content Core` has layout `NONE` — its four children are at
   absolute offsets, so the fixture uses a `Stack` with `Positioned`
   (badge `(103, 24)`, typography `(23.89, 200)`, delivery `(0, 292)`,
   metadata `(0, 437)`), including the 24 px slack at the core bottom
   (children end at 515 of 539). `Clip.none` throughout so the badge shadow
   paints exactly as exported.
2. `1:8973` metadata strip content is centered (`(350 − 32 − 296.76) / 2 =
   10.62` leading/trailing vs Figma 10.6 — 0.02 px, unmeasurable), built as a
   centered `Row` with the exact 21.2 gaps and exact cell/divider widths.

## Crop values (re-derived, not copied)

Reference: `docs/ui/figma-export/technision_figma/screens/16_16._Post-Finalization_Success/16._Post-Finalization_Success@2x.png`
is **860 × 1768 px**. Probe of the decoded pixels (repo `png.mjs` decoder):

- Columns 0–39 and 820–859 are transparent canvas (alpha 0); columns 40–819
  are the opaque frame (alpha 255, white at row 0 and row 1767).
- No transparent rows: the frame spans the full 1768 height (row 0 and row
  1767 are opaque white at x = 400).

So the frame is exactly **780 × 1768 px = 390 × 884 @2x** at offset:

```json
{ "x": 40, "y": 0, "width": 780, "height": 1768 }
```

This matches the pre-existing `f2b` figma-text crop and was re-verified pixel
by pixel for this screen (not assumed). The render is a fixed 390 × 884 box at
DPR 2, so both images are compared 1:1 with no scaling.

## Status-bar treatment

The export contains **no status-bar furniture**: the side margins are
transparent export canvas and the Figma frame itself starts at the page
background (row 0 is opaque white; there is no status-bar strip — the screen
has no app bar, `1:8931` starts at the context row). The render likewise
starts at the frame origin and draws no status bar. Masking is therefore
identical on both sides: crop the transparent canvas columns on the
reference; draw no chrome on the render. Nothing is hidden or painted over.

## Raster sources

**None decoded.** Per the spec (§5) this screen exports 4 individual SVGs and
**no photo/avatar/vehicle raster**. All 4 icons (`1_8953` WhatsApp/message,
`1_8965` Fleet/cloud-check, `1_8995` large success check, `1_9005` CTA
arrow) render through `FxIcon`/`FxIconTile`, backed by the export SVGs
registered into `FxSvgCache` by `loadF2AFonts()` (same vector source as
`assets/svg`). All four kit SVGs were verified byte-identical to the screen
export (`Compare-Object` of each pair: no differences). No `.png` string
appears in `test/support/` (release guard stays green); no asset was added
to any pubspec; `lib/` was not touched.

## Bottom-nav note (brief deviation: reproduction, not omission)

The task brief mentions a bottom nav (Intake/Fleet/Sync/Profile) on this
screen. The export contains **none**: nodes end at the CTA (`1:9000`, bottom
788 abs), the frame bottom pad (64) is pure white, and a pixel scan of the
cropped frame finds zero non-white pixels below y = 812 logical (CTA shadow
tail ends at 812). No nav was built — adding one would destroy SSIM. If a
nav variant of this screen exists, it was not exported.

## Residual (font + vector rasterisation only)

Gate: **PASS — global SSIM 0.99075 ≥ 0.98** (min 64×64 tile 0.81279 at
`(384, 384)` px = logical `(192, 192)` 32×32, inside the success-check
vector), RMSE 7.123, MAE 0.932, ΔE2000 mean 0.319 / median 0 / p95 1.242 /
max 85.209, ΔE > 2: 2.04 %, ΔE > 5: 1.09 %, ΔE > 10: 0.75 %. Text 15/15
present, key boxes 3/3 within 2 px (all delta 0.0), forbidden terms 0.

20 diff boxes (ΔE2000 > 5, min area 16 px), total area **2142 px = 0.16 %** of
1 378 640 compared pixels; every box maps to a glyph or vector-glyph edge:

| Area | Location (logical) | Cause |
|---|---|---|
| badge check `(173.5, 179.5)` 49×51.5 + `(179.5, 197)` 30.5×19.5 (worst tile 0.813) | success-check vector `1_8995` | kit SVG is byte-identical to the export; Skia vs Figma vector AA/coverage |
| CTA arrow `(243.5, 753.5)` 13.5×13 | arrow vector `1_9005` | same class (vector AA) |
| WhatsApp icon `(49.5, 429.5)`; fleet icon `(49, 506.5)` | channel icons | same class (vector AA) |
| `SERVICE SESSION #1042` y ≈ 22.5 (9 boxes, worst 129 px) | session label 11 px SemiBold ls 1.1 | Skia vs Figma glyph AA/hinting |
| `Inspection Finalized` y ≈ 320 (3 boxes) | heading 26 px ExtraBold | same |
| `WhatsApp` tail `(149, 435.5)`; `ITEMS VERIFIED` `(231.5, 575)` | channel/metadata glyphs | same |

No box exceeds 49 × 51.5 logical px; the only box above 30 px wide is the
check-vector body itself (418 px = 0.03 % of compared pixels). No box
indicates a layout, colour, radius, spacing, shadow, or copy error.

## Kit gaps needing the lead (fixture workarounds, not product changes)

1. **Status chips** (`Locked & Signed` 120.56×22 pad 4/12; `Sent` 67.98×28,
   `Synced` 85.73×28 pad 6/12 + 8 dot + 8 gap): `F2bStatusPill` is fixed
   22 tall with 10/4 padding — fixture builds exact chips from `Fx`
   primitives. (Chip body text is `#1B1B25` inkStrong, not muted.)
2. **Badge shadow** (16-blur @2 % + 50-blur @6 %): no kit equivalent
   (`Fx.softShadow` is 8 % blur-16) — fixture inlines the two Figma-exact
   layers (test-only).
3. **Core absolute layout**: kit has no absolute-position container idiom —
   fixture uses `Stack`/`Positioned` at the Figma offsets (lead to confirm
   whether a shared `F2bAbsolute` helper is wanted; not needed for product).
4. **Session label tracking** (11 px SemiBold ls 1.1): `F2bSectionLabel` uses
   0.55 — fixture uses the exact value (same class as sibling screens'
   tracking workarounds).

`FxButton` primary, `FxCard` (+`Fx.cardShadow`, verified exact: 8-blur 1.6 %
+ 40-blur 4.3 %), `FxIconTile`, `F2b.radiusLarge` (48), `Fx.cardRadius` (32)
all matched the Figma nodes with zero workaround.

## What could not be verified

- Figma text shaping beyond rendered SSIM (no access to Figma's text engine);
  residual glyph AA is measured, not modelled.
- Whether the brief's bottom nav belongs to a different (unexported) variant
  of this screen — the exported frame verifiably has none.
- Anything outside this screen (other F2-B.3 screens are out of scope).
