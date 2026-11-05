# 02. 1. Workshop Dashboard

- App: Workshop Admin
- Figma node: `1:299`
- Frame: 1280x1230.672 px (desktop web; >=1200 breakpoint)
- Export folder: `screens/02_1._Workshop_Dashboard`
- Sources read: `1._Workshop_Dashboard.json` (developerSummary, nodes), `1._Workshop_Dashboard@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html` header, `package-manifest.json`
- Export/screen-number mismatch: this is export slot **02** but Figma screen **1** ("Workshop Dashboard"). The export order follows page position (top-to-bottom, left-to-right), not screen numbers; screen 3 is exported in slot 01.
- Confidence: medium — layout, type and colour are measured, but every headline metric (capacity, accuracy, throughput) has no current data source and its definition is not shown.

## 1. Purpose

Daily overview of one workshop: active jobs vs bays, queue/finalization backlog, reports sent, a live activity stream, and floor telemetry. It is the intended landing screen after Workshop Admin sign-in.

## 2. Layout structure

Root `1:299` is fixed 1280x1230.672, vertical, HUG height. A 96 px icon rail `1:510` (96x800) is absolute at x=0; the main column `1:301` (1184x1230.672 at x=96) uses padding 80/40/48/40. A floating header `1:487` (1184x80 at x=96, y=0) overlays the main column with `#FFFFFFE5` + 48 px background blur.

Content `1:302` is a 1104 px column, top-to-bottom:
1. **Title block + actions** (`1:303`–`1:324`, 1104x84, bottom margin 40): eyebrow + 32 px title + subtitle on the left; segmented "Shift A (Current)/Past 24h" pill and "Dispatch Bay" primary button on the right.
2. **Three KPI cards** (`1:327`, `1:345`, `1:363`): each 346.7x346.7, radius 24, padding 32, 32 px gap. Each has an icon tile 48x48 (radius 16), a status pill, a large number, a label, and a 6 px progress track. The cards are equal-height with large internal negative space; the content block is bottom-weighted (`1:335` margin-top 143.7).
3. **Lower split** (`1:381`, grid 1104x568): a 725.3x476 activity card (`1:382`, padding 40) and a 346.7x566 telemetry card (`1:448`, padding 32), 32 px gap. The activity card contains 3 rows (`1:394`, `1:412`, `1:430`), 645.3x88/100, radius 16, 16 px gap; the telemetry card contains a 160x160 donut, 3 key/value rows, and a full-width tonal button.
4. **Rail footer** settings button (`1:526`, 40x40).

The layout is a fixed desktop composition: 3-column KPI row, 2-column lower row, no wrap, no mobile variant. The rail is only 800 px tall while the page is 1230.7, so the rail column does not span the viewport.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx fill count)

| Hex | Count | Usage |
|---|---:|---|
| `#5E5D69` | 31 | Secondary text, labels, inactive icons |
| `#F4F3F8` | 29 | Icon tiles, pills, tracks, tonal button |
| `#1A1B1F` | 23 | Titles, KPI numbers, icon strokes |
| `#FFFFFF` | 17 | Cards, page, header |
| `#10B981` | 9 | Success dots, progress fill, ring, active nav |
| `#006C49` | 7 | Deep-green icons/labels, positive value |
| `#F59E0B` | 3 | Warning dot/icon, queue progress |
| `#3C4A42` | 1 | "BAY ACTIVE" label |
| `#D97706` | 1 | "Awaiting Review" status text |
| `#FFFFFFE5` | 1 | Blurred header fill |

No linked styles: inspected `fillStyleId`/`textStyleId` and variables are empty.

### Typography

Plus Jakarta Sans only. 51 text nodes: SemiBold 600 x21, Bold 700 x14, Regular 400 x8, ExtraBold 800 x4, Medium 500 x4.
Sizes: 11 x15, 12 x12, 13 x8, 14 x5, 16 x5, 32 x4, 18 x1, 22 x1.

| Role | Style | Example |
|---|---|---|
| Page title | 32 / 38, 800, -0.8 px | `1:311` "Overview" |
| App subtitle/body | 16 / 24, 500, -0.16 px | `1:313` |
| KPI number | 32 / 32, 800, -1.6 px | `1:338` "12", `1:356` "4", `1:374` "8" |
| Card title | 16 / 22, 700, -0.16 px | `1:402` "Porsche Taycan 4S" |
| Section heading | 18 / 24, 700, -0.27 px | `1:386` "Live Workshop Activity" |
| Key/value label | 13 / 18, 400 | `1:468` |
| Micro label | 11 / 14, 600, +0.44/+0.55 px | `1:392` "FEED SYNCED" |
| KPI caption | 14 / 20, 500, -0.07 px | `1:341` "Active Jobs" |

All text is left-aligned (the user name is right-aligned). No Arabic/RTL sample.

### Radii, shadows/elevation, strokes, spacing

- Radii: 24 (major cards), 16 (icon tiles, activity rows), 48 (48 px icon circles), 9999 (pills, dots, progress).
- Card shadow: single `0 16 40 rgba(0,0,0,.035)` on the five major cards — different from the three-part surface shadow used on screens 03–06.
- No strokes. Dividers are 1 px `#EEEDF3`/tonal rows.
- Spacing: 8 x27, 32 x22, 12 x18, 20 x16, 6 x15, 16 x12; section gaps 40/64; card padding 32 or 40.
- The narrow 8–10 px status dots and 6 px bars are decorative/status, not touch targets.

## 4. Components

| Figma pattern | Node | Our design-system equivalent |
|---|---|---|
| Floating header with bay status, search, user chip | `1:487` | No equivalent; `AppBar` is simpler |
| Icon-only rail | `1:516` | `NavigationRail` |
| Segmented shift control | `1:315` | `AppSelectableText` (not a segmented control) |
| Primary pill CTA | `1:320` | `AppButton` primary |
| KPI/stat card | `1:327` | No equivalent |
| Activity row (icon, title, VIN chip, status, time) | `1:394` | `AppListTile` / `StatusChip` as closest; custom card needed |
| Donut gauge | `1:457` (composed SVG `SVG-1_457`) | No equivalent |
| Key/value table rows | `1:466`–`1:480` | No equivalent |
| Tonal full-width button | `1:482` | `AppButton` tonal |
| Avatar/status dot | `1:507` | `CircleAvatar` in current code; Figma uses icon |

## 5. Assets

22 assets: 18 individual SVGs, 4 composed SVGs (`Container-1_364`, `SVG-1_457` 160x160 chart, `Nav-1_516`, `Aside-1_510`), **0 rasters**. No photos, avatars or vehicle images; the donut and icons are vector. The chart is exported as a composed SVG, so its colours are fixed rather than token-driven.

## 6. Content and data

| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Eyebrow/title/subtitle | "TELEMETRICS • REAL-TIME", "Overview", "Fleet throughput and active inspection velocity today" | No | "Real-time" is not evidenced by an API/stream |
| Shift toggle | "Shift A (Current)" / "Past 24h" | No | No shift entity/config |
| Primary action | "Dispatch Bay" | No | No dispatch/bay feature |
| KPI 1 | "12 / 14 BAYS", "Active Jobs", "+2 incoming" | Partly (`jobs` list) | 12 jobs vs 14 bays; bay count absent; +2 incoming not stored |
| KPI 2 | "4 QUEUE", "Pending Finalization", "Requires Action" | Partly (`READY_TO_FINALIZE`) | "Queue"/"Requires Action" are new labels; no priority flag |
| KPI 3 | "8 REPORTS SENT", "100% ACCURACY" | Partly (`FINALIZED` jobs) | "Reports sent" needs delivery data; "100% ACCURACY" is an unsupported claim |
| Activity | "Porsche Taycan 4S", "VIN • 9J18", "Bay 04 • Full diagnostic pass complete (48/48 points checked)", "Passed", "2m ago" | Partly | Vehicle, VIN fragment, points and elapsed time: only vehicle exists; bay/points/elapsed need sources |
| Activity | "Ford Transit Custom", "VIN • 3E41", "Secondary structural markup awaiting lead inspector review", "Awaiting Review", "14m ago" | No | Implies a second-person review step |
| Activity | "Renault Mégane E-Tech", "VIN • 7K89", "Sign-off certificate compiled and dispatched to fleet lead", "Signed Off", "42m ago" | No | "Certificate" claim and delivery event absent |
| Telemetry | "76% CAPACITY", "Bays 01-08" | No | 12/14 = 85.7%, not 76%; definition inconsistent |
| Telemetry rows | "Turnaround Target 45 mins / car", "Median Flow Rate 38 mins", "Inspection Compliance 99.4%" | No | No targets, turnaround or compliance calculation |
| Footer action | "View Detailed Floor Map" | No | No floor map/bay model |

No customer name, phone, email, plate or full VIN is displayed (VIN is a 4-character hint). "Marcus Vance / Lead Inspector" is staff PII in the header.

## 7. States shown / not shown

Shown: current shift selected; three activity statuses (Passed green, Awaiting Review amber, Signed Off neutral); progress tracks at 85%, 28%, 100%; nav active Dashboard.
Not shown: loading skeletons, empty workshop ("Create your first job"), partial-data retry, stale/offline data, failed delivery, disabled account/workshop, long text, 200% text, RTL/Arabic, dark theme, mobile/tablet widths, hover/focus, 0 or >999 values.

## 8. Implied interactions

Shift and 24 h toggle; Dispatch Bay; search; user menu; nav (Dashboard/Jobs/Settings); open job from activity row; View Detailed Floor Map. The activity rows look clickable (card hover not shown). No filters, date range, export or refresh control is visible.

## 9. Correspondence to current product

- Product spec: A02 Dashboard `/dashboard` (`docs/phase-1/02-screen-inventory.md:62`) — counts by status, unassigned/scheduled, finalizing, failed delivery, link issues, recent jobs; 3-column cards on web; **"no vanity score"**.
- Current UI: **no dashboard exists**. `WorkshopAdminHomePage` has only Jobs/Staff/Templates tabs (`workshop_admin_home.dart`), and `admin_router.dart` only exposes `/workshop` (+ `/platform`, `/signin`). There is no `/dashboard` route.
- API: no dashboard endpoint in `docs/phase-1/08-api-design.md` or `api_endpoints.dart`; only `GET /workshop/jobs`, staff, templates. All KPIs would need aggregation or new endpoints/models (bay, shift, delivery, telemetry).
- Verdict: **new screen/feature**; "needs new data/server change" for most metrics. Some counts could be derived client-side, but that would be new business logic.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"No vanity score" (A02).** Evidence: "100% ACCURACY", "99.4% Inspection Compliance", "76% CAPACITY", "87.5%" style operational percentages on a dashboard. They are not vehicle condition scores, but they are unexplained headline metrics; the screen shows no denominator, period or method. The 76% ring also contradicts 12/14 bays.
2. **"No manager role, no second-person review, no approval queue."** Evidence: "awaiting lead inspector review" and "Awaiting Review". This introduces a review step that the product explicitly forbids.
3. **"No certification/'verified by'/compliance claims."** Evidence: "Sign-off certificate compiled", "Inspection Compliance 99.4%", "100% ACCURACY". These read as verified/quality claims.
4. **"Finalized findings/evidence/reports immutable; no correction/review/approval."** The feed presents a "Signed Off" state with no immutable/finalized wording; "review" conflicts with the locked model.
5. **"Never invent measurements/results."** Evidence: 76%, 100%, 99.4%, 45 mins/car, 38 mins, 48/48 points, elapsed minutes — no source/definition.
6. **"UI layer only; no business logic/API/model change."** Live telemetry/streaming, bay counts, throughput and delivery status require new services.
7. **Tokens.** Raw hex; current `AppTheme` primary is `#0B3B4A`/`#0F6B6F`, not `#006C49/#10B981`. Radii 24/48 absent from `AppRadiiTokens` (4/8/12/16/pill).
8. **WCAG 2.2 AA.** "Awaiting Review" `#D97706` on `#F4F3F8` is approx 2.9:1; `#10B981` accents on light surfaces are approx 2.3:1; 11 px labels are small. The 8 px dots and 6 px bars rely on colour, though each status also has text.
9. **Arabic RTL / localization.** No Arabic, mirrored rail, or RTL table alignment is shown; directional icons (arrow) and the left rail need mirroring rules.

## 11. Open questions / could not verify

- What are the exact definitions/formulas for 76% capacity, 100% accuracy, 99.4% compliance, median flow, and turnaround target? Why does 12/14 produce 76%?
- Is "Reports Sent" the count of `FINALIZED` jobs or actual delivery attempts? Which delivery states count?
- Where do bay count (14), bay occupancy and "Bays 01-08" come from? Is a bay a first-class entity?
- Is "Shift A (Current)" a real shift schedule or decorative copy? Is there a time zone?
- Does "lead inspector review" imply a prohibited review queue, or is it workshop-internal copy that must be rewritten?
- Should the dashboard be a tab/route (`/dashboard`) and what is the responsive layout below 1200/900 px?
- Is this a real-time stream (WebSocket/SSE) or a periodic refresh? Neither exists today.
- Are "48/48 points checked", "42m ago" etc. derived from the immutable snapshot or editable job data?
