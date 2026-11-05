# 01. 3. Create / Schedule Job

- App: Workshop Admin
- Figma node: `1:2`
- Frame: 1280x1058 px (desktop web; >=1200 breakpoint)
- Export folder: `screens/01_3._Create_-_Schedule_Job`
- Sources read: `3._Create_-_Schedule_Job.json` (developerSummary, nodes), `3._Create_-_Schedule_Job@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html` header, `package-manifest.json`
- Export/screen-number mismatch: this is export slot **01** but Figma screen **3** ("Create / Schedule Job"); order on the Figma page is not the same as the screen numbering. Screen 6 (Add Staff) is exported in slot 07 and is outside this task.
- Confidence: high for geometry/type/colour (measured from nodes); medium for product mapping (the bay, protocol-tier and telematics data shown do not exist in the current model).

## 1. Purpose

Schedule a new intake job from the live job queue. The screen is a right-hand 420 px slide-out drawer over a defocused, non-interactive Live Job Queue, not a standalone page. It captures customer name, vehicle make/model, date/bay and a protocol tier, then creates the job.

## 2. Layout structure

Root `1:2` is a fixed 1280x1058 vertical frame. One 96 px icon rail spans the left (`1:191`, 96x1024); the work area starts at x=96 (`1:3` padding-left 96) with a 1184 px main column (`1:4`, padding 80/40/336/40).

Order, back to front:
1. **Underlying queue screen** `1:6` (1104x642 at y=80), intentionally defocused: page heading "Live Job Queue", 2 stat pills, three 352x288 job cards (`1:30`, `1:56`, `1:82`, gap 24, radius 16) and an 8-bay allocation strip (`1:108`, 1104x196, radius 16).
2. **Full-frame frosted scrim** `1:167` (1280x1058, `#FFFFFF99`, background blur 24). The queue is not operable behind it.
3. **Header** `1:168` (1184x80 at x=96): status pill, search, user chip, over `#FFFFFFE5` + blur 48.
4. **Drawer** `1:210` at x=860, 420x1058: top-left/bottom-left radius 32, right corners 0, shadow 25/70. It is split into a scrollable body `1:211` (420x920, padding 40/32/24/32) and a fixed footer `1:292` (420x138, padding 16/32/40/32), so the CTA stays visible while the body scrolls.
5. **Footer CTA** `1:293` 356x56, radius 16, emerald; helper line below.

Drawer body order: eyebrow ("BAY INTAKE") + 22 px title + 2-line subtitle + close button; then a 356 px form column with 24 px gaps: Customer Name, Vehicle Make & Model, Select Date & Bay, Inspection Protocol Tier (2 options, gap 10), Auto-assign callout. Inputs are 356x48, radius 16, white, icon + placeholder. Tier options are 356x72 and 356x90 cards. The drawer is fixed-width; no breakpoint or mobile behaviour is shown.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx fill count)

| Hex | Count | Usage |
|---|---:|---|
| `#5E5D69` | 48 | Secondary text, labels, icons |
| `#FFFFFF` | 24 | Page, drawer, cards, input surfaces |
| `#1A1B1F` | 19 | Titles, values, icon strokes |
| `#F4F3F8` | 19 | Tonal pills, bay tiles, callout, close button |
| `#006C49` | 9 | Deep-green labels ("Occupied", "Comprehensive…", selected radio text) |
| `#10B981` | 9 | Primary CTA, selected radio, progress bar, active nav tile |
| `#B91A24` | 4 | Hold / pre-purchase status text and track |
| `#5E5D6999` | 3 | Input placeholders |
| `#E3E2E7` | 2 | Unselected radio, neutral bay dot |
| `#6FFBBE4D` / `#6FFBBE66` | 1 each | Bay-status tint / 30m duration chip |
| `#FFDAD74D` | 1 | Hold bay tint |
| `#FFFFFF99` | 1 | Frosted scrim |
| `#FFFFFFE5` | 1 | Blurred header surface |

All node `fillStyleId`/`textStyleId` and `boundVariables` inspected are empty, so these are raw Figma fills, not linked styles or variables.

### Typography

Plus Jakarta Sans only. 71 text nodes: SemiBold 600 x29, Bold 700 x27, Regular 400 x9, ExtraBold 800 x3, Medium 500 x3.
Sizes: 11 x29, 12 x18, 13 x9, 16 x5, 14 x4, 18 x4, 22 x1, 32 x1.

| Role | Style | Example nodes |
|---|---|---|
| Page title | 32 / 38, 800, -0.8 px | `1:13` "Live Job Queue" (blurred) |
| Drawer title | 22 / 28, 700, -0.55 px | `1:218` "Schedule New Job" |
| Job card title | 18 / 24, 700, -0.27 px | `1:36`, `1:62`, `1:88` |
| Field label | 11 / 14, 600, +0.44 px | `1:229` "Customer Name" |
| Field value | 14 / unset, 500, -0.07 px | `1:235` "e.g. Arthur Pendelton" |
| Body / VIN | 13 / 18 or 21.13, 400 | `1:221`, `1:38` |
| Eyebrow | 11 / 14, 600, +1.1 px, UPPER | `1:215` "BAY INTAKE" |
| CTA / helper | 16 / 22, 700; 12 / 16, 400 | `1:296`, `1:298` |

Labels are left-aligned everywhere. Arabic/RTL type is not shown.

### Radii, shadows/elevation, strokes, spacing

- Radii: 16 (inputs, tier rows, cards), 32 (drawer left corners), 48 (bay tiles), 9999 (pills, status chips, close). Candidate counts: 9999 x22, 16 x17, 48 x12, 32 x1.
- Card shadow: `0 14 40 rgba(0,0,0,.043)` + `0 2 8 rgba(0,0,0,.016)`; drawer: `0 10 25` + `0 25 70`; CTA: `0 10 25` emerald-tinted. No visible borders (`strokes` empty); a 1 px `#EEEDF3` divider is used in the queue.
- Spacing: dominant 16 x70, 4 x28, 12 x24, 24 x18, 8 x15, 32 x12; radius/spacing scale does not match current tokens (see §10).
- Main rhythm: 80 px top, 40 px side gutters, 24 px between form groups, 32/24 px card padding.

## 4. Components

| Figma pattern | Instances / node | Our design-system equivalent |
|---|---|---|
| Right-side slide-out panel | `1:210` | No equivalent (`showAppBottomSheet` / dialog is closest) |
| Icon-only left rail | `1:197` | `NavigationRail` (wide layout) |
| Floating header + status pill + search + user chip | `1:168` | Partly `AppBar` + `AppTextField`; user chip has no equivalent |
| Text field with leading icon, white fill | `1:230` etc. | `AppTextField` (but current theme is filled tonal, not white + shadow) |
| Selectable option card + radio | `1:263`, `1:273` | No equivalent; `AppSelectableText` is text-only |
| Primary pill CTA | `1:293` | `AppButton` primary |
| Tonal icon button | `1:222` | IconButton / `AppButton` text |
| Status pill | `1:33`, `1:59`, `1:85` | `StatusChip` (colour set differs) |
| Bay tile | `1:118`–`1:166` | No equivalent |
| Progress bar | `1:52` | No equivalent |

## 5. Assets

22 assets: 17 individual SVGs, 2 composed SVGs (`Nav-1_197`, `Aside-1_191`), 3 raster JPGs. The rasters are **vehicle photographs** (`image-1..3`, used as 64x64 round customer-vehicle thumbnails in the blurred queue); they are not avatars and their licensing/provenance is not stated. Remaining assets are 11–22 px icons. No customer photos, logos or plate images are exported.

## 6. Content and data

| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Drawer eyebrow/title | "BAY INTAKE" / "Schedule New Job" | No | Figma frame name is "Create / Schedule Job"; UI says "Schedule New Job" |
| Subtitle | "Create an intake record and assign to technician bay" | No | Wording contradicts the drawer: no technician picker is present |
| Customer Name | placeholder "e.g. Arthur Pendelton" | Yes (`customerName`, required) | Customer PII, internal only |
| Vehicle Make & Model | placeholder "e.g. 2024 Porsche Taycan 4S" | Yes (`vehicleMake`, `vehicleModel`, required) | Single free-text field; current form has separate make/model/year |
| Select Date & Bay | "Today, 2:30 PM (Bay 03)" | Partly (`scheduledAt` only) | No bay field in model; no timezone/format shown |
| Inspection Protocol Tier | "Standard 60-Point" 30m; "Full Comprehensive 110-Point" 75m | No | Current job creation requires a published `templateVersionId`; no fixed 60/110 tiers |
| Tier description | "Quick triage & safety verification"; "High-voltage battery, chassis & powertrain" | No | Template names/versions are workshop-defined, not fixed |
| Auto-assign Lead Tech | "Marcus Vance assigned to Bay 03" | No | Assignment is a separate audited action; no auto-assign in server |
| Create Job | CTA + "Notifies floor dispatch and syncs telematics" | No | Telematics/floor-dispatch integration does not exist |
| Queue card data | "2023 Audi RS6 Avant", "VIN: WUA894G23PN01928", "Julian Vance", "75%" | Yes for job fields; progress not stored | Full VIN + customer name visible together (internal) |
| Bay states | "Occupied", "Available", "Hold", "Scheduled", "Service Off" | No | No bay entity/state exists |

No phone, email or plate is displayed in this screen. Measurements/durations ("30m", "75m") and the "Lead Tech" identity are illustrative only.

## 7. States shown / not shown

Shown: drawer open; tier 1 selected (green radio, tinted 30m chip) vs tier 2 unselected; blurred base; hover/focus/disabled are not visually defined.
Not shown: empty catalogue, no published template, validation errors, duplicate customer/vehicle, loading/submitting, success, network failure, permission/disabled-workshop, 200% text, RTL/Arabic, dark theme, mobile widths, keyboard focus order.

## 8. Implied interactions

Text entry in three fields; date/bay picker; single-select tier; close (X); back via scrim/back gesture; primary Create Job. The CTA helper implies a post-create notification/telematics event. No cancel label, no confirmation, no error surface, no reason/audit field, and no indication of whether the drawer is a route, dialog or overlay.

## 9. Correspondence to current product

- Product spec: A04 Create / schedule job `/jobs/new` (`docs/phase-1/02-screen-inventory.md:64`), fields include customer search/create, vehicle, template, schedule, walk-in, assign later.
- Current UI: `JobFormPage` (`client/apps/admin_app/lib/src/pages/job_form_page.dart`) is pushed as a full page from `JobsTab._openCreate` (`jobs_tab.dart:179`), not a `/jobs/new` route and not a drawer.
- Current fields: customer name/phone/email, vehicle make/model/year/VIN/plate, scope, `scheduledAt`, `templateVersionId` dropdown. The Figma drawer removes phone/email/VIN/plate/scope/template and adds bay/tier/auto-assign.
- API: `POST /api/v1/workshop/jobs` via `HttpAdminApi.createJob`; server requires `templateVersionId`, `customerName`, `vehicleMake`, `vehicleModel`, `scope` (`JobCreateRequest.java`). The Figma form has no template selector, so it cannot submit as drawn.
- New/needs change: new screen presentation (drawer), new data/model for bay, shift, fixed protocol tiers, lead-tech auto-assignment, telematics dispatch, and progress. Not achievable as UI-only without decisions.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"UI layer only; no business logic/API/model/validation/permission/state/server change."** Evidence: auto-assignment ("Marcus Vance assigned to Bay 03"), bay scheduling, protocol-tier durations, "Notifies floor dispatch and syncs telematics". These are new rules/services, not presentation.
2. **"Never invent versions/licences/measurements/results."** Evidence: fixed "30m"/"75m" durations and the 60/110-point tier model; no source/version shown.
3. **"No certification/'verified by'/compliance claims."** Not directly in this drawer, but the underlying queue shows "Occupied"/"Hold" bay states and an unexplained 75%/20%/40% progress; "Comprehensive 110-Point" reads as a defined protocol despite no catalogue backing.
4. **Tokens/classes, not hardcoded.** All Figma fills are raw hex with empty style IDs; the palette (`#10B981`, `#006C49`) does not match current `AppTheme` (`#0B3B4A`, `#0F6B6F`) or `AppStatusColors`. Radii 24/32/48 do not exist in `AppRadiiTokens` (4/8/12/16/pill).
5. **WCAG 2.2 AA.** White text on the `#10B981` "Create Job" CTA is approx 2.5:1, below 4.5:1 and below 3:1 for large text. Close button is 40x40, below the project's 44/48 minimum. See §3.
6. **Arabic RTL must work.** No Arabic, mirrored layout, or RTL field behaviour is shown; the drawer is anchored to the right and VIN/date fields need explicit LTR handling.
7. **Customer data.** Full VIN + customer name are shown together in the internal queue. Admin access may be acceptable, but public-report rules (no full VIN/plate/customer contact) must not be inherited by this component.

## 11. Open questions / could not verify

- Which template/version backs each "protocol tier"? Is "Standard 60-Point" a template name, a duration, or a service type?
- Is "Bay" a real entity (number, state, capacity) or only a free-text schedule note? Is "Shop Floor #04" a workshop/branch identifier?
- Must the current required fields (template version, scope) remain, and should phone/email/VIN/plate stay available elsewhere? The drawer cannot create a job without `templateVersionId` today.
- Who is "Lead Tech", and is auto-assignment permitted without the audited assign endpoint/reason?
- Is the drawer a route (`/jobs/new`), a modal, or a responsive sheet? What is the mobile behaviour below 900 px?
- Is the telematics/floor-dispatch sentence real integration copy or decorative mock copy?
- Are the three vehicle JPGs licensed stock images or customer vehicles?
