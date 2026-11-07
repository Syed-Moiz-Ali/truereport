# F3-B Create Staff (screen 6) — Level 1 fidelity METHOD

## Target

- Figma node `1:1642` ("6. Add Staff / Create Account"), 1280x1024.
- Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/07_6._Add_Staff_-_Create_Account/6._Add_Staff_-_Create_Account@2x.png` (2712x2288 = 1356x1144 @1x; the extra 76x120 px is blur/sheet-shadow bleed per the render bounds).
- Crop `{x:32, y:84, width:2560, height:2048}` (@2x px) removes the bleed (left 16, top 42, right 60, bottom 78 @1x, from `absoluteRenderBounds` vs frame) to the drawn 1280x1024.
- Fixture: `docs/ui/figma/fidelity/fixtures/f3b/create-staff-level1.json`, threshold-ssim 0.98.

## Fixture (test-only, no `lib/` or pubspec change)

- `client/apps/admin_app/test/support/f3b_create_staff_fixture.dart` — exact Figma node tree with fixed pixel geometry (Stack + Positioned at Figma local coords), Figma letter-spacing/line-height via `Fx.text`, Figma fills/shadows inline where no kit token matches.
- `client/apps/admin_app/test/f3b_capture_create_staff_test.dart` — 1280 logical px, DPR 2, `enableFidelityShadows` (restored), bundled design-system fonts, `RepaintBoundary` → `render.png` + `geometry.json` + `strings.json` in `docs/ui/figma/fidelity/f3b/create-staff/`.
- Rasters: none (0 in the export manifest). Icons are the 20 export SVGs loaded by absolute path (`SvgPicture.string`); nothing added to any pubspec.
- Sample copy (names, sample emails, `InspectGuard99!`, stations, magic-link) lives ONLY in `test/`. The compare fixture points at `forbidden-terms-empty.json`, the same convention as the F3-A Level 1 fixtures.

## Shared-kit use vs exact Figma values

Matched from the kit (`Fx`): `white`, `ink`, `muted`, `container` (#F4F3F8), `surfaceHigh` (#EEEDF3), `emerald` (#10B981), `deepGreen` (#006C49), `whiteE5`, `secondaryInk` (#3C4A42), `Fx.text`, `Fx.cardShadow` (= Figma card shadow 8/0.016/y2 + 40/0.043/y14), `Fx.ctaShadow` (= Figma emerald CTA shadow).
Inlined exact Figma values (no kit token): sheet shadow (16/0.04/y4 + 60/0.12/y18, TL/BL 40), role-selected shadow (14/emerald 0.25/y4), station-04 selected second shadow (40/emerald 0.20/y14), frost overlay (white 50% + blur 24), header/footer scrims (whiteE5 + blur 48/24), switch track/knob (48x28 emerald, 24 white knob + dual shadow), all Figma tracking/line-heights.

## Blur mapping (same as F3-A)

Figma blur radius → Flutter sigma 1:1: roster `LAYER_BLUR 12` → `ImageFiltered` sigma 12; frost `BACKGROUND_BLUR 24` → `BackdropFilter` sigma 24; header sigma 48; footer sigma 24.

## Iterations

1. First render: SSIM 0.97311, CTA box off by 23 px — the sheet is `SPACE_BETWEEN`: body (865) + 23 px gap + footer (136) = 1024. Fixed with an explicit 23 px gap.
2. Same pass: hint text used 60%-opacity muted (F3-A value) but this Figma's hints are solid `#5E5D69`; CTA arrow was right-aligned instead of Figma's symmetric 81.08 px pads (7.99 px text→icon gap); station label had a double-counted 8 px pad. Fixed all three.
3. Re-render: SSIM 0.98225 → PASS (key boxes 3/3, strings 54/54, forbidden 0 matches).

## Kit gaps for the lead (no shared-kit changes made)

- No `SideSheet`/`RightDrawer` component (480 right slide-out, TL/BL 40, dual shadow) — product uses a bottom sheet.
- No segmented role control (selected emerald + 0.25 shadow vs plain option).
- No station-allocation card component (incl. emerald-tinted selected shadow).
- No magic-link switch row component; card-shadow text inputs are product-new.
- These match the spec's component table (`06-add-staff-create-account.md` §2/§7).

## Final result and residuals

- SSIM 0.98225 (min 64x64 tile 0.60), RMSE 10.584, ΔE2000 mean 0.50 / p95 1.01, ΔE>5 0.86%, 20 diff boxes (auditor-verified values; fixtures/metrics.json is source of truth).
- Largest residual boxes are SVG icon rasters (input icons at x≈1207, metric/role/CTA icons) and glyph edges (station numerals, footer CTA) — same class as the F3-A screen 2 pass (0.98194): only font/SVG rasterisation remains, no unexplained diff > 4 px in geometry (key boxes all ≤ 2 px, all pass).
- Not claimed pixel-perfect: SSIM < 1 from rasterisation as quantified above.
