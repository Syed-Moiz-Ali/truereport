# F2-B.3 Part 2 — Screen 14 Finalize & Approval (Swipe), Level 1 METHOD

## What was built

- Fixture widget: `client/apps/technician_app/test/support/f2b3_finalize_fixture.dart`
  (new file; test-only, exact Figma structure from `Fx*` + `F2b*` shared kits
  plus the two Figma export rasters; never the production `FinalizeView`).
- Capture: `client/apps/technician_app/test/f2b3_capture_finalize_test.dart`
  (new file; mirrors `test/f2b_fidelity_capture_test.dart`:
  `enableFidelityShadows` + restore, 390 logical px, DPR 2,
  `RepaintBoundary` → `toImage`, writes `render.png`, `geometry.json`,
  `strings.json`).
- Fixture: `docs/ui/figma/fidelity/fixtures/f2b3/finalize-level1.json`
  (schema per `tools/figma_fidelity/compare.mjs` + `tools/figma_fidelity/README.md`).
- Output dir: `docs/ui/figma/fidelity/f2b3/finalize/`
  (`figma.png`, `render.png`, `side-by-side.png`, `diff.png`, `metrics.json`,
  `REPORT.md`, this file).

The fixture widget is a test-only, Figma-exact tree for Figma screen 14
(`1:8809`, export folder `15_14._Finalize_&_Approval_(Swipe)`). It does NOT
reuse the production `FinalizeView`. Structure mirrors
`docs/ui/figma/specs/technician_app/15-finalize-and-approval-swipe.md` §2 and
`docs/ui/figma/f2b-nodes/14-finalize.txt` node-for-node (sizes, positions,
fills, radii, shadows, type). Shared-kit usage: `Fx.*`/`F2b.*` tokens
(`figma_screen_kit.dart`), `FxIcon` (all 10 vectors, `size` = the vector's
max dimension so `BoxFit.contain` reproduces the node box exactly),
`f2bHost` with `figmaStrings: true`. Text is the exact Figma copy (Level 1
fidelity requires it, including the unsafe fleet/compliance/signature/GPS/
ledger wording — this copy must never ship; it lives only in `test/`).

Visual-order note: the card `1:8823` children render top-to-bottom as
vehicle header (230), vehicle photo (298), stat tiles (466), technician row
(642) — the `.txt` tree lists photo (1:8873) after the stats/tech rows, but
the absolute y positions and the reference crop both put the photo second.
The fixture follows positions (verified against the reference bands).

## Crop values (re-derived, not copied)

Reference: `docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/14._Finalize_&_Approval_(Swipe)@2x.png`
is **932 × 2602 px**. Probe of the decoded pixels (proper PNG filter
reconstruction — a naive scan without unfiltering misreads the frame):

- Pixels with alpha > 128 sit in exactly **x 76–855, y 14–2476**:
  780 × 2463 px = 390 × 1231.5 @2x. Every one of the 1 921 140 pixels in
  that box has alpha > 128.
- Pixels with alpha > 4 extend to x 36–895 / y 14–2566: ±40 px side bleed
  from the card/header shadows and ~90 px bottom bleed from the dock drop
  shadow (`DROP_SHADOW(50 0,25 s-12 a25 %)` on `1:8911`).

So the frame is exactly:

```json
{ "x": 76, "y": 14, "width": 780, "height": 2463 }
```

This matches the pre-existing `f2b` figma-text crop and was re-verified
pixel by pixel for this screen (not assumed). The render is a fixed
390 × 1231.5 box at DPR 2 (physical 780 × 2463, integers), so both images
are compared 1:1 with no scaling. The bottom 0.25 px (Figma frame height
1231.25 vs 1231.5 crop) is white on both sides.

## Status-bar treatment

The export contains **no status-bar furniture**: rows 0–13 are transparent
canvas (alpha ≤ 4) and the side margins (x 0–75, 856–931) are transparent
except shadow bleed. The Figma frame itself starts at the header
(`1:8920` @0,0 390×64). The render likewise starts at the frame origin
(header at y = 0) and draws no status bar. The below-frame dock-shadow
bleed is cropped on the reference side and clipped by the `RepaintBoundary`
on the render side. Masking is therefore identical on both sides: crop the
transparent canvas on the reference; draw no chrome on the render. Nothing
is hidden or painted over.

## Raster sources

Two rasters decoded by absolute path via `loadFigmaTestImage`
(`test/support/f2a_test_images.dart` pattern), drawn 1:1 with
`RawImage(image:, scale: 2)` so no resampling occurs:

- Avatar `assets/images/rendered_png/…-1_8859@2x.png` (70 × 80 px) into the
  34.94 × 40 node (`1:8859`): 70/2 = 35 logical px wide, clipped 0.06 px in
  the 34.94 stadium clip — subpixel, no resample.
- Vehicle `assets/images/rendered_png/…-1_8874@2x.png` (604 × 288 px) into
  the 302 × 144 node (`1:8874`): exactly 302 × 144 logical px.

No `.png` string appears in `test/support/f2b_views.dart` (release guard
stays green); no asset was added to any pubspec; `lib/` was not touched.

## Deliberate substitutions (shared-kit limits, lead-owned)

Kit defaults that differ from the Figma node values are NOT used; the
fixture builds those nodes exact from primitives (test-only inlines):

1. **Summary-card shadows**: Figma is two black-10 % layers
   (`(0,8)` blur 10 spread −6 + `(0,20)` blur 25 spread −5, raw source
   `a = 0.10`). Kit `F2b.summaryShadow` uses 5.1 % / 7.8 % alphas — the
   fixture inlines the exact 10 % pair.
2. **Flagged-card shadow**: Figma is a single black-5 % layer
   (`(0,1)` blur 2). Kit `Fx.cardShadow` is a different two-layer shadow —
   the fixture inlines the exact single layer.
3. **Header shadow**: Figma is `(0,1)` blur 8 black 3 % (`a = 0.03`,
   inlined as `0x08000000`). Kit `Fx.headerShadow` is 6.3 % — the fixture
   inlines the exact 3 % layer (shared 48 px backdrop blur as the sibling).
4. **Thumb shadows**: Figma is two black-10 % layers (`(0,4)` blur 6
   spread −4 + `(0,10)` blur 15 spread −3). Kit `F2bSlideToConfirm` uses
   `Fx.softShadow` — the fixture builds the 52 px thumb exact.
5. **Step pill**: Figma pads 12 horizontal with a 12.5 px vector icon.
   Kit `F2bStatusPill` pads 10 and has no icon slot — the fixture builds
   the 180.38 × 22 pill exact (same for the `Bay #04` chip: pad 4/12,
   tracking 0.44).
6. **Slide track**: kit `F2bSlideToConfirm` centres the label differently
   and carries gesture state; the fixture positions the 189.36 × 18 label
   at the exact rel-track (100.32, 23) with tracking 0.35.
7. **Header**: kit `FxHeader` uses a Material back glyph and −0.27
   tracking; Figma needs vector `1_8925` (11.77 × 20) and −0.45 tracking —
   the fixture builds the header from `Fx` primitives at exact positions.
8. Merged-away no-ops (zero visual effect, recorded here): the `#FFFFFF01`
   overlay rects (`1:8911` over the `#FFFFFFF2` dock, `1:8917` over the
   emerald thumb) shift colour by < 1/255 and are not stacked; their
   shadows ARE reproduced exactly.

## Residual (font rasterisation only)

Gate: **PASS — global SSIM 0.98312 ≥ 0.98** (min 64×64 tile 0.85769, RMSE
10.307, MAE 1.889, ΔE2000 mean 0.533 / median 0 / p95 1.027 / max 85.576,
ΔE > 5: 2.11 %, ΔE > 10: 1.41 %). Text 27/27 present, key boxes 3/3 within
2 px (all delta 0.0), forbidden terms 0.

20 diff boxes (ΔE2000 > 5, min area 16 px), total area **2237 px = 0.12 %**
of 1 921 140 compared pixels; every box maps to a glyph or vector-glyph
edge (checked on `diff.png` — no red on photos, cards, chips, tracks,
backgrounds or shadows):

| Area | Location (logical) | Cause |
|---|---|---|
| title y ≈ 106–133 (5 boxes, largest 14 × 19.5) | `Review & Finalize` 26 px ExtraBold | Skia vs Figma glyph AA/hinting |
| step pill y ≈ 81–90 (2 boxes) | check vector + `INSPECTION…` 11 px | same |
| vehicle title/VIN y ≈ 245–258 (2 boxes) | `2024 Ford Transit 350` / VIN line | same |
| counts y ≈ 532.5 (1 box) | `104` 22 px Bold | same |
| stat medallion (1 box: (227, 491.5)) | right-tile flag vector | shared-kit SVG vector rasterisation, same class of residual |
| odometer chip (1 box) | `Odometer: 14,820 mi` | same |
| flagged medallions (2 boxes: (45.5, 845.5), (45.5, 913.5)) | alert vectors | same |
| disclaimer y ≈ 1003–1050 (2 boxes) | 13 px centred copy | same |
| slide label y ≈ 1173–1185 (4 boxes) | `Slide to Finalize…` 14 px Bold | same |

Worst 64×64 tiles are all text areas: (384, 2048) 0.858 disclaimer block,
(576, 2112) 0.881 disclaimer, (512, 2048) 0.885 disclaimer,
(320, 192) 0.899 title row.

No box exceeds 14 × 19.5 logical px; no box indicates a layout, colour,
radius, spacing, shadow, or copy error.

## Kit gaps needing the lead (fixture workarounds, not product changes)

1. `F2b.summaryShadow` alphas (5.1 %/7.8 %) do not match the Figma
   10 %/10 % pair — fixture inlines the exact pair (this screen's §10.9
   token drift, measured from the raw export).
2. `Fx.headerShadow` (6.3 %) does not match the Figma 3 % layer — fixture
   inlines the exact layer.
3. `Fx.cardShadow` has no single-layer 5 % variant for the flagged card —
   fixture inlines it.
4. No kit equivalent for the 52 px slide thumb's two-layer shadow, the
   exact label slot, the 12-padded pill/chip with vector icon, or the
   vector-back header — fixture builds all from `Fx` primitives.
5. `RawImage`-at-scale-2 is the only 1:1 raster path; there is no kit
   photo/avatar component (by design — product slots use
   silhouette/initials; see `docs/ui/figma/f2b-slot-sheet.md`).

## What could not be verified

- Figma text shaping beyond rendered SSIM (no access to Figma's text
  engine); residual glyph AA is measured, not modelled.
- The idle swipe state only is exported (no drag/submitting/success
  frames); RTL, 200 % text, reduced motion, and screen-reader behaviour
  for the slider could not be verified (spec §7).
- Anything outside this screen (other F2-B.3 screens are out of scope).
