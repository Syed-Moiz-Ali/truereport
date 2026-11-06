# F2-A.1 report - identical-first correction of technician screens 1-7

**Project:** TrueReport
**Phase:** F2-A.1
**Date:** 6 November 2026
**Status:** implementation complete for review. **Visual gate not met** (measured,
not lowered). No commit was made. Stop for owner approval.

## 1. What was fixed

The F2-A render was structurally different from the Figma. F2-A.1 replaced it with
a Figma-first rebuild rather than restyling the old widgets:

- **Shared kit (`Fx*`):** exact Figma colours (`#10B981`, `#1A1B1F`, `#5E5D69`,
  `#006C49`, `#F4F3F8`, `#EEEDF3`, `#E9E7ED`), type styles at the Figma sizes,
  weights, line heights and tracking, the Figma card/button/pill/nav/header
  shadows, a white shadowed field card, the white language switch, the 4-slot
  dock, the 176 px coverage ring, and the exported Figma SVGs for every icon.
- **Login:** Figma layout restored — language pill top-right, 80 px logo slot with
  the blurred green glow, 26/32 wordmark, 13/18 tagline, 48 px white fields with
  the icons/placeholders inside, 56 px `#10B981` “Sign In” with the arrow on the
  right and emerald glow, and the footer rows. `Forgot password?`, the access row
  and the security line are present in the same slots with neutral product text.
- **Jobs / empty:** Figma header, live-status pill, 56 px glowing avatar, shift
  pill, welcome block, two white snapshot cards, section title and pill, 130 px
  job cards with the car pill and 44 px chevron, the primary CTA and the 4-slot
  dock. The empty state uses the Figma art card, queue pill, headline, refresh
  button and summary strip.
- **Job intake:** Figma header, metadata row, 176 px hero with plate/model slots,
  the 290 px vehicle card (2×2 grid + VIN strip + copy action), the 276 px
  customer card, the 76 px readiness card and the 56 px sticky action.
- **Consent:** full-page Figma layout — step badge, 26/32 title, three 80 px
  consent cards with 52×32 switches, the 176 px decision/signature slot, timestamp
  row, signer card and 56 px save button.
- **Equipment:** full screen 6 layout, using the API IDs and an explicit “name
  unavailable” line; no invented names, specs, calibration or verification.
- **Hub:** Figma header with the logo tile, status pill, 278 px ring card with
  coverage + result pills, vehicle strip, 2×2 module cards with the Figma pins /
  pills / progress bars, the 56 px CTA and the 56 px dock.

## 2. Visual fidelity (measured, not estimated)

Reference: the Figma `@2x` exports, cropped to the actual 390-wide frame (the
export adds a shadow margin). Render: 390 logical px, DPR 2, bundled fonts,
test-only SVG cache. Fixture (a) uses Figma text; fixture (b) uses product copy.
The harness is `tools/figma_fidelity/compare.mjs`; the threshold was **not**
lowered.

| Screen | SSIM (a) Figma text | SSIM (b) product copy | RMSE (a) | Gate 0.98 |
|---|---|---|---|---|
| 01 Login | **0.97210** | 0.95233 | 18.98 | Not met |
| 02 Assigned jobs | 0.79111 | 0.79974 | 55.46 | Not met |
| 03 Empty state | 0.84140 | 0.84202 | 45.52 | Not met |
| 04 Job intake | 0.80267 | 0.80741 | 49.62 | Not met |
| 05 Consent | 0.80815 | 0.80194 | 43.87 | Not met |
| 06 Equipment | 0.82759 | 0.81890 | 39.89 | Not met |
| 07 Inspection hub | 0.81949 | 0.82169 | 53.46 | Not met |

Each folder `docs/ui/figma/fidelity/f2a1/<screen>/<variant>/` contains `figma.png`,
`render.png`, `side-by-side.png`, `diff.png`, `metrics.json`, `REPORT.md`,
`strings.json` and `geometry.json`. Residual causes are listed per screen in
`deviations.md` (section F2-A.1) and in each `REPORT.md`.

**Honest conclusion:** the screenshots are visually close (icons, geometry,
structure and type now match), but the 0.98 gate is not met. The main measured
residuals are the neutral replacements of sample photos/people/plates, the
different data copy, the 4-slot dock mapping, the consent signature slot, the
equipment data gap, and font rasterisation differences between Figma and Flutter.
No claim of “pixel-perfect” is made.

## 3. Geometry test

`client/apps/technician_app/test/f2a1_geometry_test.dart` renders each screen at
390 logical px and compares key nodes with the Figma `absoluteBoundingBox` from
`docs/ui/figma/f2a1-nodes/` using a **1 logical px** tolerance.

- **7/7 screen cases pass.**
- **55 key nodes** are asserted (language switch, fields, buttons, headers, cards,
  hero, ring, docks, titles, pills).
- Text nodes are compared for position and line box; their intrinsic width is
  font-metric dependent and is not asserted as a hard box. Three card-height
  checks whose Finder includes the parent 16 px gap are asserted for position
  only. These exceptions are stated in the test and in `deviations.md`.
- No overflow at 360/390/600/900 and 1.0×/1.5×/2.0× text; the responsive test
  passes for every screen.

## 4. Slot sheet summary and owner decisions

Full table: `docs/ui/figma/f2a1-slot-sheet.md`. The default (Option A: same slot,
neutral text, same style) is implemented. Decisions needed:

1. **I4 dock mapping:** second slot maps to **Finalized** jobs. Approve or change
   it; the product build uses the `Finalized` label, while the test-only Figma
   fixture uses `Fleet`.
2. **Forgot password / Request ID:** keep the neutral “Password help” / “Contact
   Admin” text, or fund the real flows.
3. **Security footer:** keep “Secure report delivery” or supply an evidence-backed
   claim.
4. **Signature:** confirm signature capture remains out of scope; the signature
   slot now holds the explicit Granted/Refused decision.
5. **Equipment API:** add `labelEn`, `labelAr`, `code`, `status`, `sortOrder`
   (proposed in `f2a1-audit-06-equipment.md`) or accept IDs only.
6. **Logo:** supply the final TrueReport mark if the TR monogram should change.

## 5. Contrast and I1

| Pair | Ratio | Result |
|---|---|---|
| White `#FFFFFF` on emerald `#10B981` (Figma CTA) | **2.54:1** | **FAIL**; owner-accepted under I1 |
| Ink `#1A1B1F` on `#10B981` (alternative, switch off) | 6.78:1 | Pass |
| White on `#059669` (alternative) | 3.77:1 | Pass for ≥18.66 px bold only |
| White on `#006C49` (alternative) | 6.48:1 | Pass |
| White field card on white page (I2) | No visible boundary; 1.00:1 | **FAIL**; owner-accepted under I2 |

No other F2-A.1 pair newly fails. The accessible button/field tokens remain
available behind one switch that is off.

## 6. Tests and builds

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos` (technician, design_system, admin) | Clean |
| Technician app tests | **111 passed** |
| Design system tests | **136 passed** |
| Admin app tests (including source scan) | **83 passed** |
| F2-A.1 geometry tests | **7/7 passed** |
| Fidelity capture (7 screens × 2 fixtures) | 14 passed; artifacts written |
| Goldens EN/AR light + EN dark (7 screens) | Updated and passing |
| Screenshots EN/AR at 1×/2× (7 screens) | Written to `docs/ui/figma/f2a-screenshots/` |
| `flutter build web` | Passed (`build/web`) |
| `flutter build apk --debug` | Passed (`build/app/outputs/flutter-apk/app-debug.apk`) |
| Server tests | **Not run** — Maven is not installed in this environment |

No business logic, API contract, model, validation, permission, state management
or server change was made. Consent switches start unticked and no record is
created until save.

## 7. Subagents

The seven read-only `fidelity-auditor` runs completed in parallel and wrote
`docs/ui/figma/f2a1-audit-01-login.md` … `f2a1-audit-07-inspection-hub.md`.
Because the screen rebuilds depended on one shared Figma kit and exact shared
geometry, the `screen-builder`, `geometry-test-engineer`, `a11y-i18n-reviewer` and
`privacy-reviewer` roles were performed by the lead rather than separate agents.
No subagent edits conflicted; no subagent run was cancelled.

## 8. What could not be verified

- **Real devices:** no iOS/Android phone or tablet was used. The APK builds, but
  real-device camera, keyboard, Arabic shaping, sunlight and one-hand reach were
  not tested.
- **Arabic native review:** the Arabic strings come from the existing ARB files;
  the RTL layout is derived from the same tokens and mirrors correctly in tests,
  but a native reviewer has not approved it.
- **Photo assets:** the Figma sample people, vehicles and plates are not real and
  were not used.
- **Server tests:** Maven is not available here, so the server suite was not run.
- **Font rasterisation:** Figma and Flutter anti-alias text differently; this is a
  measurable residual on every screen even when the style metrics match.

## 9. What the owner should check on a real phone

Compare each screen against its Figma image, in English and Arabic:

1. Login: the glow/logo slot, the white fields, the button colour/glow and the
   footer wording.
2. Jobs/empty: the 4-slot dock (Finalized vs Fleet), the avatar/status pills, the
   snapshot labels and the card shadows.
3. Job intake: the hero placeholder, the VIN copy action, the customer actions and
   the sticky button.
4. Consent: the three cards, the Granted/Refused decision and the disabled data
   storage card.
5. Equipment: the ID-only rows and the missing names/specs.
6. Hub: the ring, the result pills and the module progress states.
7. Large text (1.5×/2.0×), sunlight, one-hand reach, and Arabic RTL.

**Stop for approval.** No further F2-B work was started.


> **F2-A.2 correction (6 November 2026):** the F2-A.1 fidelity numbers in this
> report were measured with `debugDisableShadows = true` (solid shadow blocks) and
> with a reference crop offset of ~45 device px. They are superseded by
> `f2a2-report.md` and `deviations.md` (F2-A.2 section). The F2-A.1 shadow claims
> are withdrawn. The gate was not met then and is not met now.
