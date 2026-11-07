# Screen 3 — Create / Schedule Job (Workshop Admin)

- Figma screen 3 "Create / Schedule Job", node `1:2`.
- Export folder (offset note): `docs/ui/figma-export/Workshop_admin_figma/screens/01_3._Create_-_Schedule_Job/` — folder `01_3` = screen 3 (slot 01 ≠ screen 1).
- Frame: **1280 × 1058 px** (width 1280 confirmed; desktop web, ≥1200 breakpoint). Background `#FFFFFF`.
- Sources read: `3._Create_-_Schedule_Job.json` (developerSummary, nodes), `3._Create_-_Schedule_Job@2x.png` (viewed as image; drawer sharp right, queue defocused behind scrim), `assets/manifest.json` (22 assets), existing spec `docs/ui/figma/specs/workshop_admin/01-create-schedule-job.md` (measurements reused), `f1-token-api.md`, `tokens.md`.
- Owner rules: O3 (1280 drawer composition as drawn; mobile behaviour derived, no claim), O6 (no review/approve wording — none in drawer; subtitle "assign to technician bay" handled below).

## 1. Node-level layout

- Root `1:2` fixed 1280×1058 VERTICAL. Rail `1:191` 96×1024 left; work area from x=96; main column `1:4` 1184 px, padding 80/40/336/40.
- Back-to-front order:
  1. Underlying queue `1:6` (1104×642 at y=80), defocused/inert: heading "Live Job Queue", 2 stat pills, three 352×288 job cards (`1:30`, `1:56`, `1:82`, gap 24, radius 16), 8-bay allocation strip (`1:108`, 1104×196, radius 16).
  2. Frosted scrim `1:167` 1280×1058, `#FFFFFF99`, background blur 24. Queue not operable behind it.
  3. Header `1:168` 1184×80 at x=96: status pill + search + user chip over `#FFFFFFE5` + blur 48.
  4. Drawer `1:210` at x=860, **420×1058**: top-left/bottom-left radius 32, right corners 0, shadow `0 10 25` + `0 25 70`. Split: scrollable body `1:211` 420×920 (padding 40/32/24/32) + fixed footer `1:292` 420×138 (padding 16/32/40/32) so CTA stays visible.
  5. Footer CTA `1:293` 356×56 radius 16 emerald + helper "Notifies floor dispatch and syncs telematics".
- Drawer body: eyebrow "BAY INTAKE" + 22 px title "Schedule New Job" (`1:218`, 22/28 w700) + 2-line subtitle + close X; 356 px form column, 24 gaps: Customer Name, Vehicle Make & Model, Select Date & Bay inputs (356×48, radius 16, white, icon + placeholder); Inspection Protocol Tier options 356×72 / 356×90 (gap 10); Auto-assign callout. Fixed width; no breakpoint/mobile shown.

## 2. Colours, type, shadow, spacing (observed)

- Colours: `#5E5D69` 48, `#FFFFFF` 24, `#1A1B1F` 19, `#F4F3F8` 19, `#006C49` 9, `#10B981` 9 (CTA, selected radio, progress, active nav), `#B91A24` 4 (Hold states), `#5E5D6999` 3 (placeholders), `#E3E2E7` 2 (unselected radio), `#6FFBBE4D`/`#6FFBBE66` 1 each, `#FFDAD74D` 1, `#FFFFFF99`/`#FFFFFFE5` scrims. Style IDs/variables empty — raw fills. AA: white on `#10B981` CTA ≈ 2.5:1 (A2: use ink label on emerald, or deep-green + white behind switch). Close 40×40 below 44/48 minimum (B2/I3: keep visual, enlarge invisible hit area).
- Type: Plus Jakarta Sans only. 71 text nodes: SemiBold 600 ×29, Bold 700 ×27, Regular 400 ×9, ExtraBold 800 ×3, Medium 500 ×3. Sizes 11 ×29 (labels/eyebrow 11/14 w600 +0.44/+1.1 — B1: ship ≥12), 12 ×18, 13 ×9, 16 ×5, 14 ×4, 18 ×4, 22 ×1 (drawer title), 32 ×1 (blurred base title). CTA 16/22 w700; helper 12/16 w400. Left-aligned; no Arabic/RTL.
- Radii: 16 (inputs/tier rows/cards), 32 (drawer left corners), 48 (bay tiles), 9999 (pills/chips/close). Shadows: cards `0 14 40 .043` + `0 2 8 .016`; drawer `0 10 25` + `0 25 70`; CTA emerald-tinted `0 10 25`. No borders; 1 px `#EEEDF3` divider. Spacing dominants 16/4/12/24/8/32; form rhythm 80 top, 40 gutters, 24 between groups.

## 3. Components used (Figma → design_system)

| Figma pattern (node) | design_system cover | Verdict |
|---|---|---|
| Right slide-out drawer (`1:210`, 420 wide, fixed footer) | `AppScaffold.drawer` is left drawer; `showAppBottomSheet` is bottom sheet; no right-panel | NEW: `WorkshopRightDrawer` (or responsive sheet; O3 derived mobile = bottom sheet) |
| Icon rail (`1:197`) / header (`1:168`) | `AdminSidebar` rail + `AdminTopBar`/`AppBar` | Covered (same chrome as screens 1–2) |
| Text field w/ leading icon, white (`1:230` etc.) | `AppTextField` (`inputs.dart`), incl. `FxTextField` white-card 48 h r16 variant (`figma_screen_kit.dart`, technician-scoped) | Covered (white-card variant) |
| Selectable option card + radio (`1:263`, `1:273`) | `FigmaResultOption` (`figma_components.dart`) closest; `AppSelectableText` text-only | NEW composition (workshop tier card) |
| Primary CTA (`1:293`) | `AppButton` primary | Covered |
| Tonal icon (close `1:222`) | `AppIconButton` | Covered |
| Status pill / bay tile / progress (base queue) | `StatusChip`; bay tile none; `AppCoverageBar` | Bay tile NEW (omit if bays omitted) |
| Scrim + blur (`1:167`) | Dialog barrier (no blur) | Covered (barrier; blur decorative) |

## 4. Assets

- Manifest: 22 assets — 17 individual SVGs + 2 composed (`Nav-1_197`, `Aside-1_191`) + **3 raster JPGs** (`image-1..3`, role `image`): 64×64 round **vehicle photographs** in the blurred base queue (not avatars). Licence/provenance not stated — do not bundle; neutral tiles in product. Remaining assets 11–22 px icons.

## 5. States

- Shown: drawer open; tier 1 selected (green radio + tinted 30 m chip) vs tier 2 unselected; blurred inert base.
- NOT shown: empty catalogue, no published template, validation errors, duplicates, loading/submitting, success, network failure, permission/disabled-workshop, 200 % text, RTL/Arabic, dark theme (light-only), mobile widths, keyboard focus order. Current `JobFormPage` already covers loading/error/empty-template (`job_form_page.dart`) — preserve all in drawer.

## 6. Element → data mapping

Existing: `POST /api/v1/workshop/jobs` (`WorkshopJobController.create`) requires `templateVersionId`, `customerName`, `vehicleMake`, `vehicleModel`, `scope` (`JobCreateRequest.java`); optional phone/email/year/VIN/plate/`scheduledAt`. Client: `HttpAdminApi.createJob` (`admin_api.dart:761-791`); `templateVersionOptions()` for published-template dropdown; current UI `JobFormPage` full page with customer name/phone/email, make/model/year/VIN/plate, scope, `scheduledAt`, `templateVersionId` dropdown (pushed from `JobsTab._openCreate`, not a `/jobs/new` route, not a drawer).

| Figma element | Mapping / verdict |
|---|---|
| Eyebrow/title "BAY INTAKE / Schedule New Job" | Frame-name vs UI-title mismatch ("Create / Schedule Job" vs "Schedule New Job") — copy decision; maps to `POST /workshop/jobs` |
| Subtitle "Create an intake record and assign to technician bay" | No technician picker in drawer; assignment is separate audited action (`POST …/assign` with optional reason). "Assign to bay" DATA GAP — reword to existing flow (create now, assign later per A04 "assign later") |
| Customer Name "e.g. Arthur Pendelton" | Exists: `customerName` required |
| Vehicle Make & Model "e.g. 2024 Porsche Taycan 4S" | PARTLY: `vehicleMake` + `vehicleModel` (+`vehicleYear`) required path exist, but Figma single free-text field; current form has separate make/model/year — keep separate fields in same slot/style |
| Select Date & Bay "Today, 2:30 PM (Bay 03)" | PARTLY: `scheduledAt` exists (locale-formatted). Bay DATA GAP — omit bay, keep date/time picker |
| Inspection Protocol Tier "Standard 60-Point 30m / Full Comprehensive 110-Point 75m" | DATA GAP as drawn: creation requires published `templateVersionId`; no fixed 60/110 tiers. Neutral mapping: tier cards select existing `templateVersionOptions()` entries (template name/version + item count from `TemplateSummary.itemCount`), same slot/style; durations "30m/75m" OMIT (never invent measurements) |
| Tier descriptions "Quick triage & safety verification / High-voltage battery, chassis & powertrain" | Template names/descriptions are workshop-defined — use real `TemplateSummary.name/description`, never the mock copy |
| Auto-assign "Marcus Vance assigned to Bay 03" | DATA GAP + rule conflict: no auto-assign on server; assignment is explicit + audited. OMIT (assign-later flow) |
| CTA helper "Notifies floor dispatch and syncs telematics" | DATA GAP — no dispatch/telematics integration; OMIT/replace with neutral "Creates the job in this workshop" |
| Base queue cards (VIN + customer + 75 %/20 %/40 % progress, bay strip "Occupied/Available/Hold…") | Job fields exist; progress + bay states DATA GAP (same as screen 2) |
| Missing vs current form: phone/email/VIN/plate/scope/template selector | REQUIRED by server (`templateVersionId`, `scope`) — drawer MUST include template-version select + scope (+ keep phone/email/VIN/plate available); as drawn the form cannot submit |

## 7. Classification

**Matches existing feature (create job) — UI work only for drawer restyle + template/scope mapping; needs new data or server change for bay/tier-durations/auto-assign/telematics.** Shippable without server change: 420 px right drawer (O3 desktop) containing existing fields (customer, make/model/year, VIN/plate, phone/email, scope, `scheduledAt`, published-template dropdown from `templateVersionOptions()`), CTA → existing `createJob`, all current validation/loading/error/empty states preserved. Bay selection, fixed 60/110-point tiers with durations, lead-tech auto-assign, dispatch/telematics copy all need new models/endpoints or omission.

## 8. New shared components from this screen (vs already built)

1. Right slide-out panel 420 wide with fixed footer — NEW (shared with any future drawer; mobile derived = `showAppBottomSheet`).
2. Tier/option radio card — NEW composition (`FigmaResultOption`-style for workshop).
3. White-card 48 h r16 field variant — covered (`FxTextField` pattern; port to workshop, keep `AppTextField` API).

## 9. Could not verify

- Which template/version backs each "protocol tier" (name vs duration vs service type).
- Whether "Bay"/"Shop Floor #04" is a real entity or free-text note; timezone/format for "Today, 2:30 PM".
- Whether phone/email/VIN/plate stay in drawer or move elsewhere (server accepts optional; UX decision).
- Drawer routing: route (`/jobs/new`) vs modal vs responsive sheet; behaviour below 900 px (O3 derived).
- Telematics/floor-dispatch sentence: real integration or mock copy (treated as mock).
- Vehicle JPG licences/sources.
