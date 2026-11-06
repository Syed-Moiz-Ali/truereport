# F2-B.3 Part 2 — Screen 13 Final Review (Missing Items), Level 1 METHOD

## What was built

- Fixture widget + capture: `client/apps/technician_app/test/f2b3_capture_final_review_test.dart`
  (new file; mirrors `test/f2b_fidelity_capture_test.dart`: `enableFidelityShadows`
  + restore, 390 logical px, DPR 2, `RepaintBoundary` → `toImage`, writes
  `render.png`, `geometry.json`, `strings.json`).
- Fixture: `docs/ui/figma/fidelity/fixtures/f2b3/final-review-level1.json`
  (schema per `tools/figma_fidelity/compare.mjs` + `tools/figma_fidelity/README.md`).
- Output dir: `docs/ui/figma/fidelity/f2b3/final-review/`
  (`figma.png`, `render.png`, `side-by-side.png`, `diff.png`, `metrics.json`,
  `REPORT.md`, this file).

The fixture widget is a test-only, Figma-exact tree for Figma screen 13
(`1:8349`, export folder `12_13._Final_Review_(Missing_Items)`). It does NOT reuse
the production `FinalReviewView`. Structure mirrors
`docs/ui/figma/specs/technician_app/12-final-review-missing-items.md` §2 and
`docs/ui/figma/f2b-nodes/13-final-review.txt` node-for-node (sizes, positions,
fills, radii, shadows, type). Shared-kit usage: `Fx.*`/`F2b.*` tokens
(`figma_screen_kit.dart`), `FxIcon`, `Fx.text`, `F2bStatusPill` (top red chip),
`f2bHost` with `figmaStrings: true`. Text is the exact Figma copy (Level 1
fidelity requires it, including the unsafe compliance/sign-off wording — this
copy must never ship; it lives only in `test/`).

## Crop values (re-derived, not copied)

Reference: `docs/ui/figma-export/technision_figma/screens/12_13._Final_Review_(Missing_Items)/13._Final_Review_(Missing_Items)@2x.png`
is **860 × 2030 px**. Probe of the decoded pixels (node `png.mjs` decoder):

- Columns 0–39 and 820–859 are transparent canvas (alpha ≤ 4); columns 40–819
  are the opaque frame (alpha 254–255, corner AA at the very edge).
- Rows 0–13 are transparent canvas; row 14 is the frame top edge (alpha 254 at
  x = 40, corner AA); rows 14–2029 are the frame (14 + 2016 = 2030, exact).

So the frame is exactly **780 × 2016 px = 390 × 1008 @2x** at offset:

```json
{ "x": 40, "y": 14, "width": 780, "height": 2016 }
```

This matches the pre-existing `f2b` figma-text crop and was re-verified pixel by
pixel for this screen (not assumed). The render is a fixed 390 × 1008 box at
DPR 2, so both images are compared 1:1 with no scaling.

## Status-bar treatment

The export contains **no status-bar furniture**: the 14 px above the frame and
the 40 px side margins are transparent export canvas, and the Figma frame
itself starts at the header (`1:8468` @0,0 390×64). The render likewise starts
at the frame origin (header at y = 0) and draws no status bar. Masking is
therefore identical on both sides: crop the transparent canvas on the
reference; draw no chrome on the render. Nothing is hidden or painted over.

## Raster sources

**None decoded.** Per the spec (§5) this screen exports 14 individual SVGs + 3
composed SVGs and **no photo/avatar/vehicle raster**. All 14 icons
(`1_8367`, `1_8394`, `1_8406`, `1_8408`, `1_8413`, `1_8425`, `1_8427`,
`1_8432`, `1_8444`, `1_8446`, `1_8452`, `1_8463`, `1_8473`, `1_8478`) render
through `FxIcon`, backed by the export SVGs registered into `FxSvgCache` by
`loadF2AFonts()` (same vector source as `assets/svg` + `assets/composed/svg`).
No `.png` string appears in `test/support/` (release guard stays green); no
asset was added to any pubspec; `lib/` was not touched.

Two deliberate substitutions (shared-kit limits, lead-owned):

1. Banner shadow uses `Fx.cardShadow` (extra ≈1.6 % blur-8 layer; main layer
   4.3 % vs Figma 3.5 % blur-40) — Figma draws a single 3.5 % layer. Sub-JND;
   no diff box attributable.
2. Header shadow uses `Fx.headerShadow` (6.3 % vs Figma 3 % blur-8) + shared
   48 px backdrop blur. Sub-JND; no diff box attributable.

## Residual (font rasterisation only)

Gate: **PASS — global SSIM 0.98209 ≥ 0.98** (min 64×64 tile 0.81097, RMSE
10.991, MAE 3.149, ΔE2000 mean 0.834 / median 0 / p95 2.291 / max 85.576,
ΔE > 5: 2.30 %, ΔE > 10: 1.45 %). Text 26/26 present, key boxes 3/3 within
2 px (all delta 0.0), forbidden terms 0.

20 diff boxes (ΔE2000 > 5, min area 16 px), total area **2564 px = 0.16 %** of
1 572 480 compared pixels; every box maps to a glyph or vector-glyph edge:

| Area | Location (logical) | Cause |
|---|---|---|
| badges y ≈ 321.5 (3 boxes, incl. worst tile 0.811 at (128, 320)) | numerals `1 2 3` | Figma uses **Nimbus Sans Bold 11** (spec §10.7 outlier); harness ships only Plus Jakarta Sans, so `Fx.text` Jakarta Bold stands in |
| title y ≈ 109–129 (7 boxes) | `Review Findings` 26 px ExtraBold | Skia vs Figma glyph AA/hinting |
| chip y ≈ 79 (1 box) | `3 Action Items` | same |
| row title/chip tails (2 boxes) | `Tread Photo` / `Front Left` | same |
| metadata y ≈ 756–769 (4 boxes) | `28 Verified Data Points` | same |
| camera medallions (2 boxes: (308.5, 453), (310, 554.5)) | red action-circle glyphs | shared-kit SVG vector rasterisation, same class of residual |

No box exceeds 14 × 19.5 logical px (max area 201 px); no box indicates a
layout, colour, radius, spacing, or copy error. Worst 64×64 tiles are all text
areas: (128, 320) badges 0.811, (160, 544) row-2 title/chip 0.845,
(96, 320) badges/helper 0.857, (160, 736) metadata title 0.861,
(64, 96) page title 0.886–0.894.

## Kit gaps needing the lead (fixture workarounds, not product changes)

1. **Badge numerals**: no kit equivalent for the Nimbus Sans Bold outlier —
   fixture substitutes Jakarta Bold (spec §10.7 says normalise; lead to confirm).
2. **Disabled CTA** (`1:8461`): transparent fill at node opacity 0.8
   (measured glyph blend `#D2D1DC` on white ⇒ `Opacity(0.8)` over `#C7C5D3`;
   verified by pixel probe) — no `FxButton` equivalent; built from primitives.
3. **Row category chips** (rows 1–2): transparent, 18 px tall, pad 2/8 —
   `F2bStatusPill` is fixed 22 px; fixture builds exact chips (only the top
   `3 Action Items` chip uses `F2bStatusPill`).
4. **Header**: `FxHeader` uses a Material back glyph and −0.27 tracking; Figma
   needs vector `1_8473` and −0.45 tracking — fixture builds the header from
   `Fx` primitives at the exact node positions.

## What could not be verified

- Figma text shaping beyond rendered SSIM (no access to Figma's text engine);
  residual glyph AA is measured, not modelled.
- Nimbus numeral advancement (font absent from the repo) — residual bounded by
  the three badge boxes above (≤ 200 px each).
- Anything outside this screen (other F2-B.3 screens are out of scope).
