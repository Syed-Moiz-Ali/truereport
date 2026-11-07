# METHOD — F3-A Level 2 screen 3 Create/Schedule drawer (product copy)

Capture: `client/apps/admin_app/test/f3a_capture_schedule_product_test.dart`
(pumps the REAL `ScheduleJobSheet.showScheduleJobSheet` drawer).
Config: `docs/ui/figma/fidelity/fixtures/f3a/schedule-level2.json`.
Reference: `docs/ui/figma-export/Workshop_admin_figma/screens/01_3._Create_-_Schedule_Job/3._Create_-_Schedule_Job@2x.png`
(same `@2x` export + same crop as Level 1).
Deny list: `docs/ui/figma/fidelity/forbidden-terms-admin-product.json` (new;
mirrors the unit-test banned terms for rows 41-47).

## Capture config

1280 x 1058 logical @ DPR 2 (`tester.view.physicalSize` 2560x2116,
`devicePixelRatio` 2, `TextScaler.noScaling`, locale en, light theme,
`enableFidelityShadows` + restore, bundled design-system fonts test-only —
same pattern as the Level 1 capture). The `RepaintBoundary` sits OUTSIDE
`MaterialApp` so the sheet route (Navigator overlay entry) is inside the
captured pixels. The board is a plain neutral fill (`#E9E8F0`); dimming comes
from the product scrim itself (`WorkshopSideSheet.show` barrier). Fake data:
two PUBLISHED templates (`Full inspection` v1, 12 items; `Quick check` v2,
5 items) via `templateVersionOptions()` + `templates()`.

## Reference crop

`{"x":32,"y":90,"width":2560,"height":2116}` → 1280 x 1058 logical @ DPR 2
(identical to Level 1; see Level 1 METHOD.md for the alpha-sampling proof).
Both sides composited over white and normalised to 2560 x 2116.

## Text sources

All strings are product copy from `lib/` + `l10n` (`app_en.arb`):
`scheduleJobTitle`, `scheduleJobSubtitle` (title + footer helper),
`jobDetails`, `customerName/Phone/Email`, `vehicleMake/Model/Year/Vin/Plate`,
`scope`, `scheduledAt` (+ hardcoded hint `2026-11-05T09:00:00`),
`${templateName} · v${versionNo}` tier titles,
`technicianItemsCount` (`12 items`, `5 items`), `selectTemplate`, `create`.
Text gate: 20/20 present. Forbidden: 0 matches.

## Geometry vs Figma slot (measured, not declared)

No `keyBoxes` are declared in this fixture (OPTIONAL per Level 2 rules), but
`geometry.json` records the drawer root: measured
`(860, 0, 420, 1058)` vs Figma drawer slot `(860, 0, 420, 1058)` — delta 0.
The drawer chrome position/size is identical; every remaining difference is
slot-replacement content (rows 41-45), which is why SSIM fails by design.

## Difference list vs slot sheet (every difference, with numeric effect)

Global effect of all rows below, measured: SSIM 0.83559 (min 64x64 tile
0.11531), RMSE 94.948 (MAE 80.363), ΔE2000 mean 21.221 / median 29.266 /
p95 29.453 / max 85.576; ΔE2000 > 2: 87.78 %, > 5: 70.46 %, > 10: 69.90 %.
Level 1 same-crop baseline was SSIM 0.98569 / RMSE 9.876 / ΔE>5 0.91 % —
the Level 2 delta (ΔSSIM −0.15010) is the slot-replacement cost. 20 diff
boxes (ΔE2000 > 5); box #1 is the backdrop, boxes #2-#20 are drawer content.

| # | Slot-sheet row | Figma text | Product text | Numeric effect |
|---|---|---|---|---|
| 1 | Backdrop = screen-2 board, rows 36-40 + All rows 58-61 | Blurred queue board: rail, header (`BAY ACTIVE`, search, `Marcus Vance / Lead Inspector`), `ACTIVE BAY OPERATIONS` cards with vehicle photos, bay tiles, footer strip | Neutral flat board + product scrim (no board exists behind the drawer in this capture) | Box #1 (0,0,889,1058) area 3,641,059 device px ≈ 84 % of frame; dominates global SSIM/RMSE/ΔE above. Includes rows 39 (photos→nothing), 59 (sample people/VINs), 61 (75 %/20 %/40 % progress) by construction |
| 2 | Row 41 (subtitle/dispatch) | `BAY INTAKE` eyebrow + `Schedule New Job` + `Create an intake record and assign to technician bay` | `Schedule new job` + `Create the job in this workshop — assign a technician afterwards` | Drawer-head glyph boxes #5 (944.5,55,63x31), #7 (906,56), #11 (890,58), #12 (1061,55), #14 (934,100), #15 (1021.5,69), #18 (890.5,97), #19 (1008,68.5) — all ≤ 63 px wide, text-rasterizer edges at verified positions |
| 3 | Row 41 + 45 (customer fields) | Single `Customer Name / e.g. Arthur Pendelton` | `Customer name` + `Customer phone` + `Customer email` (required set) | Field-zone glyph edges #16 (904.5,296), #20 (908,397.5); sample name `Arthur Pendelton` never ships (row 59) |
| 4 | Row 42 (split fields) | Single `Vehicle Make & Model / e.g. 2024 Porsche Taycan 4S` | `Vehicle make` / `Vehicle model` / `Vehicle year` / `VIN` / `Plate` | Same field-zone boxes; sample vehicle never ships (row 59) |
| 5 | Row 43 (bay) | `Select Date & Bay / Today, 2:30 PM (Bay 03)` | `Scheduled at` date/time picker only, no bay | Date-field zone; no bay string anywhere (deny-list `bay` = 0) |
| 6 | Row 44 (tiers) | `Standard 60-Point / 30m` + `Full Comprehensive 110-Point / 75m` cards | `Full inspection · v1 / 12 items` + `Quick check · v2 / 5 items` (real published templates) | Tier-zone boxes #3 (888,550,364x25, area 14,818), #4 (1186,515), #8 (942,510.5), #13 (904,515.5); durations `30m/75m` + `60/110-Point` never rendered (deny-list = 0) |
| 7 | Row 41 (auto-assign) | `Auto-assign Lead Tech / Marcus Vance assigned to Bay 03` callout | Absent (assign-later flow; nothing invented) | Callout-zone removal is inside drawer boxes; `auto-assign`/`lead`/`marcus` deny-list = 0 |
| 8 | Row 41 (footer copy) + 45 | `Create Job` + `Notifies floor dispatch and syncs telematics` | `Create` + subtitle helper line | Footer box #2 (882,935.5,376x82, area 64,210 — largest drawer box); `dispatch`/`telematics` deny-list = 0 |
| 9 | Row 45 (required fields) | No template/scope selector (form cannot submit as drawn) | Tier cards + `Select a template` dropdown + `Inspection scope` | Covered by tier/field boxes above; product-only additions, same slots |
| 10 | Rows 58-61 (All families) | `Shop Floor #04`, bay pills, photos, `%`/timings, hardware claims across drawer+board | None rendered anywhere | Deny-list 36 terms = 0 matches over all 22 captured strings |

Residuals are slot replacements + font rasterizer edges only. The drawer
slot itself is pixel-aligned (delta 0); no unexplained diff > 4 px remains
outside the backdrop box #1 (neutral board by capture design) and the
drawer content boxes #2-#20 (each mapped above). No pixel-perfect claim —
see REPORT.md.

## Iteration log (global SSIM, threshold 0.98)

1. 0.83559 — first and only render; REAL product drawer. **Gate FAILS on
   SSIM by design** (slot replacements above); text 20/20 pass, forbidden
   0 pass. No iteration: any "fix" would mean shipping Figma copy, which the
   slot sheet forbids.

## Could not verify

- Production board behind the drawer (real queue) vs this neutral board —
  backdrop box #1 measures the capture simplification, not a product gap.
- Drawer scroll offset/content below the fold, loading/error/empty states,
  phone-derived bottom sheet (<600 px), RTL/AR, dark theme, text scaling
  (light-only en 1280 capture).
- Flutter sigma vs Figma blur-radius mapping for the scrim (same 1:1
  assumption as Level 1).
- Live template data beyond the two faked published templates; `scheduledAt`
  locale formatting in production use.
