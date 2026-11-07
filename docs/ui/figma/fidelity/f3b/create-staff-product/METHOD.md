# METHOD — F3-B Level 2 screen 6 Add Staff sheet (product copy)

Capture: `client/apps/admin_app/test/f3b_capture_create_product_test.dart`
(pumps the REAL `CreateTechnicianSheet.showCreateTechnicianSheet` sheet).
Config: `docs/ui/figma/fidelity/fixtures/f3b/create-staff-level2.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/07_6._Add_Staff_-_Create_Account/6._Add_Staff_-_Create_Account@2x.png`
(same `@2x` export + same crop as Level 1).
Deny list: `docs/ui/figma/fidelity/forbidden-terms-admin-product.json`
(allows staff/product fields incl. masked email; blocks Figma-only wording
per slot-sheet row 50 — bays, stations, magic-link, skills, recall, review,
scores, fleet, sample people).

## Capture config

1280 x 1024 logical @ DPR 2 (`tester.view.physicalSize` 2560x2048,
`devicePixelRatio` 2, `TextScaler.noScaling`, locale en, light theme,
`enableFidelityShadows` + restore, bundled design-system fonts test-only —
same pattern as the F3-A Level 2 dialog captures). The `RepaintBoundary`
sits OUTSIDE `MaterialApp` so the sheet route (Navigator overlay entry) is
inside the captured pixels. The board is a plain neutral fill (`#E9E8F0`);
dimming comes from the product scrim itself (`WorkshopSideSheet.show`
barrier). No Figma text, rasters, or export paths appear here — product
copy only. The `Open` string in `strings.json` is the board's trigger
button behind the scrim (capture construction); it is excluded from
`expectedStrings`.

## Reference crop

`{"x":32,"y":84,"width":2560,"height":2048}` → 1280 x 1024 logical @ DPR 2
(identical to Level 1). Both sides composited over white and normalised to
2560 x 2048.

## Text sources

All strings are product copy from `lib/` + `l10n` (`app_en.arb`):
`createTechnicianTitle`, `createTechnicianSubtitle`, field labels
`displayName` / `email` / `temporaryPassword`, fixed row `roleTechnician`
+ `role`, `cancel`, `create`. Text gate: 9/9 present. Forbidden: 0 matches.

## Geometry vs Figma slot (measured, not declared)

No `keyBoxes` are declared in this fixture (product layout differs by
design), but `geometry.json` records the sheet root: measured
**(860, 0, 420x1024)** vs Figma sheet slot (800, 0, 480x1024) — x +60,
w −60. The product sheet is the fixed 420-wide `WorkshopSideSheet`
(right drawer; bottom sheet below the phone breakpoint), where Figma draws
a 480 px sheet. The offset is honest layout difference, not measurement
error; every remaining difference is slot-replacement content (row 50),
which is why SSIM fails by design.

## Difference list vs slot sheet (every difference, with numeric effect)

Global effect of all rows below, measured: SSIM 0.83929 (min 64x64 tile
0.19382), RMSE 97.611 (MAE 82.404), ΔE2000 mean 21.546 / median 29.230 /
p95 29.453 / max 85.576; ΔE2000 > 2: 80.08 %, > 5: 72.25 %, > 10: 71.62 %.
20 diff boxes (ΔE2000 > 5); box #1 is the backdrop, boxes #2-#20 are sheet
content.

| # | Slot-sheet row | Figma text | Product text | Numeric effect |
|---|---|---|---|---|
| 1 | Backdrop = roster board + shell, row 50 + All rows 58-61 | `ADMINISTRATION / Personnel Roster`, `18 Active Technicians`, `4/4 Operational Diagnostic Bays`, `99.4% Accuracy`, `3 Admins Master Security`, backdrop rows (`m.vance@… / Bay 04 (Lead)`), shell (`BAY ACTIVE`, `Lead Inspector`) | Neutral flat board + product scrim (no board exists behind the dialog in this capture) | Box #1 (0, 0, 1035.5x1024) full-frame area 3,557,624 device px; dominates global SSIM/RMSE/ΔE above. Includes row 59 (sample VINs/people/emails) + row 61 (bay counts/percentages) by construction |
| 2 | Row 50 (sheet head) | `ONBOARDING / Create Staff Account / Set up permissions, station assignments, and onboarding credentials` | `Create technician / Set the name, email and initial password. The technician signs in with these credentials.` | Title-zone glyph boxes #5 (945, 124.5), #8 (895, 125), #9–#18 (876.5–1145, y≈124–131, ≤ 24 px wide) |
| 3 | Row 50 (fields) | `FULL NAME e.g. David Vance / EMAIL e.g. d.vance@… / TEMPORARY PASSWORD InspectGuard99!` | `Display name / Email / Temporary password` (empty, obscured; sample password never ships) | Sheet-mid box #3 (986.5, 384, 269.5x67, area 59283); full-email deny-list = 0, `InspectGuard…` never rendered |
| 4 | Row 50 (role picker) | `ASSIGN ROLE Technician / Admin` segmented control | Fixed `Technician / Role` row — no picker (C0: Technician own-workshop only) | Same sheet-mid box #3; `Admin`-as-role = 0 occurrences |
| 5 | Row 50 (station allocation) | `STATION ALLOCATION STN 01–04 (1 Required)` grid | Omitted (no station entity) | Box #4 (1137, 684, 112x70, area 10883, station-grid zone) |
| 6 | Row 50 (magic link) | `Send welcome magic link (ON)` + `Bypasses initial manual password reset` | Omitted (no invite flow; password is set at creation) | Part of box #4 zone; `magic` deny-list = 0 |
| 7 | Row 50 (actions) | `Cancel` + emerald `Create Account →` | `Cancel` text + `Create` (footer-pinned) | Box #2 (943, 927.5, 305x77, area 85421 — footer CTA zone) |
| 8 | Rows 58–61 (All families) | `BAY ACTIVE`, `Lead Inspector`, full emails, `99.4%`, `4/4 Bays`, bay rows | None rendered anywhere | Deny-list 42 terms = 0 matches over all 13 captured strings; emails stay label-only (never a value) |

Sheet chrome residual: measured sheet (860, 0, 420x1024) vs Figma
(800, 0, 480x1024) — the x +60 / w −60 delta is the fixed
`WorkshopSideSheet` 420 width (code comment: "Figma 420 wide"), an honest
product-vs-Figma chrome difference. Residual glyph boxes #6 (1176, 775.5),
#7 (1222.5, 0), #20 (1207, 373) are sheet-edge/font-rasterizer edges only.
No unexplained diff > 4 px remains outside backdrop box #1 (neutral board
by capture design) and sheet boxes #2-#20 (each mapped above). No
pixel-perfect claim — see REPORT.md.

## Iteration log (global SSIM, threshold 0.98)

1. 0.83929 — first and only render; REAL product sheet. **Gate FAILS on
   SSIM by design** (slot replacements above); text 9/9 pass, forbidden
   0 pass. No iteration: any "fix" would mean shipping Figma copy, which
   the slot sheet forbids.

## Could not verify

- Production board behind the sheet (real roster) vs this neutral board —
  backdrop box #1 measures the capture simplification, not a product gap.
- Phone derived bottom-sheet variant (<600 px; captured wide sheet only),
  RTL/AR, dark theme, text scaling (light-only en 1280 capture).
- Validation-error states (empty/invalid submit), EMAIL_EXISTS /
  generic-error snackbars, password eye-toggle (covered by unit tests).
- Whether station allocation or Admin creation ever ships (out of scope
  per row 50 / O5+C0).
