# METHOD — F3-A Level 2 screen 4 Assign Technician dialog (product copy)

Capture: `client/apps/admin_app/test/f3a_capture_assign_product_test.dart`
(pumps the REAL `WorkshopAssignDialog.show` dialog).
Config: `docs/ui/figma/fidelity/fixtures/f3a/assign-level2.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/04_4._Assign_Technician/4._Assign_Technician@2x.png`
(same `@2x` export + same crop as Level 1).
Deny list: `docs/ui/figma/fidelity/forbidden-terms-admin-product.json` (new;
mirrors the unit-test banned terms for rows 46-47).

## Capture config

1280 x 1120 logical @ DPR 2 (`tester.view.physicalSize` 2560x2240,
`devicePixelRatio` 2, `TextScaler.noScaling`, locale en, light theme,
`enableFidelityShadows` + restore, bundled design-system fonts test-only —
same pattern as the Level 1 capture). The `RepaintBoundary` sits OUTSIDE
`MaterialApp` so the dialog route (Navigator overlay entry) is inside the
captured pixels. The board is a plain neutral fill (`#E9E8F0`); dimming comes
from the product scrim itself (`WorkshopDialog.show` barrier). Fake data:
two ACTIVE technicians (`Technician A/B` + masked emails, same-workshop
`staff()` semantics) and an `ASSIGNED` job carrying existing fields only
(`JOB-TEST0007`, `Toyota Camry`, `Full inspection` template + scope).

## Reference crop

`{"x":32,"y":0,"width":2560,"height":2240}` → 1280 x 1120 logical @ DPR 2
(identical to Level 1; the 32 px transparent left strip artefact, see Level 1
METHOD.md). Both sides composited over white and normalised to 2560 x 2240.

## Text sources

All strings are product copy from `lib/` + `l10n` (`app_en.arb`):
`assignTechnicianTitle`, `assignTechnicianSubtitle`, vehicle strip
(`vehicleMake/Model` + `reference · templateName · scope`), per-tech
`displayName` + `emailMasked`, `assignReasonOptional` (+ `reason` hint),
`cancel`, `confirm`. Text gate: 12/12 present. Forbidden: 0 matches.

## Geometry vs Figma slot (measured, not declared)

No `keyBoxes` are declared in this fixture (OPTIONAL per Level 2 rules), but
`geometry.json` records the modal root: measured
`(384, 326.75, 512, 466.5)` vs Figma modal slot `(384, 206, 512, 660)` —
x/w exact (delta 0), y +120.75, h −193.5. The product dialog is
content-sized and vertically centred (title + strip + 2 tech cards + reason
+ actions) where Figma draws a fixed 660 px modal with 3 tech cards and a
337 px CTA row. The offset is honest layout difference, not measurement
error; every remaining difference is slot-replacement content (rows 46-47),
which is why SSIM fails by design.

## Difference list vs slot sheet (every difference, with numeric effect)

Global effect of all rows below, measured: SSIM 0.82957 (min 64x64 tile
0.06811), RMSE 104.378 (MAE 96.375), ΔE2000 mean 25.471 / median 29.453 /
p95 29.453 / max 86.617; ΔE2000 > 2: 93.96 %, > 5: 87.54 %, > 10: 84.92 %.
Level 1 same-crop baseline was SSIM 0.99135 / RMSE 6.972 / ΔE>5 0.64 % —
the Level 2 delta (ΔSSIM −0.16178) is the slot-replacement cost. 20 diff
boxes (ΔE2000 > 5); box #1 is the backdrop, boxes #2-#20 are dialog content.

| # | Slot-sheet row | Figma text | Product text | Numeric effect |
|---|---|---|---|---|
| 1 | Backdrop = dispatch board, row 46 + All rows 58-61 | Blurred board: `ACTIVE DISPATCH BOARD / Shift A / 12 Bays Operational`, `#1040 Express / #1041 Heavy` cards, header (`BAY ACTIVE`, search, `Marcus Vance / Lead Inspector`) | Neutral flat board + product scrim (no board exists behind the dialog in this capture) | Box #1 (0,0,1280,1120) full-frame area 4,806,960 device px; dominates global SSIM/RMSE/ΔE above. Includes row 59 (sample VINs/people) + row 61 (bay counts) by construction |
| 2 | Row 46 (ticket/stage) | `REPAIR TICKET #1042 / Stage 01 / Assign Technician for Job #1042` | `Assign technician` (reference stays `JOB-…` verbatim in the strip, never `#1042`) | Title-zone glyph boxes #9 (575,380), #11 (438,383), #13 (519.5,380), #15 (555.5,380), #18 (495.5,382) — all ≤ 30 px wide at y≈380-395 |
| 3 | Row 47 (subtitle) | `Select an available certified specialist for 2024 Ford Transit` | `Select an available technician` | Same title-zone boxes; `certified`/`specialist` deny-list = 0 |
| 4 | Row 47 (vehicle strip) | `Transit 350 High Roof / 3.5L EcoBoost • Brake System Recall / Est. 2.5h` pill | `Toyota Camry / JOB-TEST0007 · Full inspection · Full inspection` (existing fields only) | Strip/first-card box #2 (416,433,448x100, area 144,187 — largest dialog box); `recall`/`estimate`/`Est.` deny-list = 0 |
| 5 | Row 47 (tech rows) | `David Vance / Brakes L2 / 1 Active Job • Bay 02`, `Marcus Vance / Lead Tech / 3 Active Jobs • Bay 04`, `Sarah Jenkins / Powertrain / 0 Active Jobs • Bay 01 (Available)` | `Technician A / t***@test.local`, `Technician B / u***@test.local` (ACTIVE same-workshop only) | Card-zone boxes #7 (432.5,560), #8 (468,573.5), #10 (553,569), #12 (503,661.5), #14 (571,572), #16/#17/#19/#20 (≤ 20 px glyph edges, y≈560-672); skills/bays/workload/levels + sample people never ship (rows 47 + 59) |
| 6 | Row 47 (reason) | No reason field (current code path sends null) | `Reason (optional)` input (A06 audit completeness; empty sends null) | Reason/actions-zone boxes #5 (603.5,656,79x18), #6 (772.5,713.5); product-only addition |
| 7 | Row 47 (actions) | `Cancel` + 337 px emerald `Confirm Assignment →` | `Cancel` text + `Confirm` (disabled until selection) | Actions-zone boxes #3 (770,722,102x49.5), #4 (428.5,660,51.5x48); existing `assignJob(job.id, selected, reason?)` |
| 8 | Rows 58-61 (All families) | `Express/Heavy` tiers, bay lines, full VINs, recall authority, timings | None rendered anywhere | Deny-list 36 terms = 0 matches over all 13 captured strings; emails stay masked (row 59) |

Residuals are slot replacements + font rasterizer edges only. Modal x/width
are exact; the y/h delta (+120.75/−193.5) is the measured content-sizing
difference above. No unexplained diff > 4 px remains outside backdrop box
#1 (neutral board by capture design) and dialog boxes #2-#20 (each mapped
above). No pixel-perfect claim — see REPORT.md.

## Iteration log (global SSIM, threshold 0.98)

1. 0.82957 — first and only render; REAL product dialog. **Gate FAILS on
   SSIM by design** (slot replacements above); text 12/12 pass, forbidden
   0 pass. No iteration: any "fix" would mean shipping Figma copy, which the
   slot sheet forbids.

## Could not verify

- Production board behind the dialog (real queue) vs this neutral board —
  backdrop box #1 measures the capture simplification, not a product gap.
- Reassignment-reason required-vs-optional policy (field renders optional
  per A06; Figma shows no field either way).
- Disabled/transferred-tech representation, search/filter in the picker,
  preselection rationale (nothing preselected here), rejected-job state
  (captured job is assignable; rejection covered by unit tests).
- Narrow/phone derived sheet (<600 px), RTL/AR, dark theme, text scaling
  (light-only en 1280 capture).
- Whether assignment also assigns a bay (independent or coupled) —
  out of scope per row 47.
