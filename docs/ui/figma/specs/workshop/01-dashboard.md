# Screen 1 — Dashboard (Workshop Admin)

- Figma screen 1 "Workshop Dashboard", node `1:299`.
- Export folder (offset note): `docs/ui/figma-export/Workshop_admin_figma/screens/02_1._Workshop_Dashboard/` — folder `02_1` = screen 1 (export order follows page position, not screen numbers; screen 3 is in folder `01_3`).
- Frame: **1280 × 1230.672 px** (width 1280 confirmed; desktop web, ≥1200 breakpoint). Background `#FFFFFF`.
- Sources read: `1._Workshop_Dashboard.json` (developerSummary, nodes), `1._Workshop_Dashboard@2x.png` (viewed as image), `assets/manifest.json`, existing spec `docs/ui/figma/specs/workshop_admin/02-workshop-dashboard.md` (geometry/colour/type measurements reused, not re-measured), `docs/ui/figma/f1-token-api.md`, `docs/ui/figma/tokens.md`.
- Owner rules applied: O3 (build 1280 as drawn; tablet/phone derived, labelled "derived, pending designer review", no fidelity claim), O4 (dashboard numbers only from existing data), O6 (no "pending review / approve / sign off / review-queue" wording — neutral replacements used below).

## 1. Node-level layout

- Root `1:299` fixed 1280×1230.672, VERTICAL, HUG height.
- Icon rail `1:510` 96×800 absolute at x=0 (does NOT span the 1230.7 viewport height). Composed asset `Aside-1_510`; nav group `1:516` 96×600 composed as `Nav-1_516`.
- Main column `1:301` 1184×1230.672 at x=96, padding 80/40/48/40.
- Floating header `1:487` 1184×80 at x=96 y=0, fill `#FFFFFFE5` + background blur 48. Contains bay-status pill ("BAY ACTIVE Shop Floor #04"), search field ("Search VIN, tech, job ticket…"), user chip ("Marcus Vance / Lead Inspector" + person icon).
- Content `1:302` 1104 px column:
  1. Title block + actions (`1:303`–`1:324`, 1104×84, 40 bottom margin): eyebrow "TELEMETRICS • REAL-TIME" + 32 px title "Overview" (`1:311`, 32/38, w800, -0.8) + subtitle (`1:313`, 16/24, w500); right side segmented pill "Shift A (Current) / Past 24h" (`1:315`) + primary "Dispatch Bay" button (`1:320`).
  2. Three KPI cards (`1:327`, `1:345`, `1:363`): each 346.7×346.7, radius 24, padding 32, 32 gap. Each = 48×48 icon tile (radius 16) + status pill + 32 px number (`1:338` "12", `1:356` "4", `1:374` "8"; 32/32 w800 -1.6) + caption (14/20 w500) + 6 px progress track. Content bottom-weighted (`1:335` margin-top 143.7); large internal negative space.
  3. Lower split (`1:381`, 1104×568, 32 gap): activity card `1:382` 725.3×476 (padding 40) + telemetry card `1:448` 346.7×566 (padding 32). Activity rows `1:394`, `1:412`, `1:430` (645.3×88/100, radius 16, 16 gap). Telemetry: 160×160 donut (`1:457`, composed SVG `SVG-1_457`) + 3 key/value rows (`1:466`–`1:480`) + full-width tonal button (`1:482` "View Detailed Floor Map").
  4. Rail footer settings button `1:526` 40×40.
- Fixed desktop composition: 3-column KPI row, 2-column lower row, no wrap, no mobile variant in export.

## 2. Colours, type, shadow, spacing (observed, raw Figma fills)

- Colours: `#5E5D69` 31 (secondary text), `#F4F3F8` 29 (tiles/pills/tracks), `#1A1B1F` 23 (titles/numbers), `#FFFFFF` 17, `#10B981` 9 (dots/fills/ring/active nav), `#006C49` 7, `#F59E0B` 3 (warning), `#3C4A42` 1, `#D97706` 1 ("Awaiting Review" text), `#FFFFFFE5` 1. All `fillStyleId`/`textStyleId`/variables empty — raw fills, not linked styles. Token mapping per `f1-token-api.md`: surfaceContainer `#F4F3F8`, onSurface `#1A1B1F`, onSurfaceVariant `#5E5D69` agree; brand emerald `#10B981` is fill-only (never text on light); `#D97706`-on-tonal and `#10B981` accents fail AA as drawn (see §7).
- Type: Plus Jakarta Sans only. 51 text nodes: SemiBold 600 ×21, Bold 700 ×14, Regular 400 ×8, ExtraBold 800 ×4, Medium 500 ×4. Sizes 11 ×15, 12 ×12, 13 ×8, 14 ×5, 16 ×5, 32 ×4, 18 ×1, 22 ×1. Page title 32/38 w800 -0.8; KPI number 32/32 w800 -1.6; section heading 18/24 w700; micro labels 11/14 w600 +0.44/+0.55 (B1: ship at ≥12 px). No Arabic/RTL sample.
- Radii: 24 (major cards), 16 (icon tiles, activity rows), 48 (icon circles), 9999 (pills/dots/bars). Card shadow single `0 16 40 rgba(0,0,0,.035)` — differs from shared two-layer card shadow (`0 2 8 .016` + `0 14 40 .043`) used on screens 2–4; see `tokens.md` §5.2. No strokes; dividers 1 px tonal. Spacing dominants 8/32/12/20/6/16; section gaps 40/64; card padding 32/40.

## 3. Components used (Figma → design_system)

| Figma pattern (node) | design_system cover | Verdict |
|---|---|---|
| Floating header w/ bay pill + search + user chip (`1:487`) | `AdminTopBar`/`AppBar` in `lib/src/components/admin_chrome.dart` + `AppTextField` (`inputs.dart`); no user-chip / bay-pill composite | NEW composite needed |
| Icon-only rail (`1:516`) | `AdminSidebar` rail variant (`admin_chrome.dart`); `NavigationRail` used in `workshop_admin_home.dart` | Covered (restyle) |
| Segmented shift control (`1:315`) | `AppSegmentedControl` (`chips.dart`); `AppSelectableText` text-only | Covered |
| Primary CTA "Dispatch Bay" (`1:320`) | `AppButton` primary (`buttons.dart`) | Covered |
| KPI/stat card (`1:327` etc.) | `AppStatCard`/`AppCard` (`cards.dart`) closest; exact composition (icon tile + pill + number + track) | NEW composition |
| Activity row (`1:394` etc.) | `AppListTile` (`lists.dart`) + `StatusChip` (`chips.dart`) closest | NEW composition |
| Donut gauge (`1:457`) | `AppProgressRing` (`progress.dart`), `FxCoverageRing` (`figma_screen_kit.dart`, technician-scoped) | NEW (workshop telemetry donut) |
| Key/value rows (`1:466`–`1:480`) | No equivalent | NEW (or extend lists) |
| Tonal full-width button (`1:482`) | `AppButton` tonal | Covered |
| Avatar/status dot (`1:507`) | `TechnicianAvatar`/`FxAvatar` (technician shell); `CircleAvatar` in current code | Covered |

## 4. Assets

- `assets/manifest.json`: 22 assets — 18 individual SVGs (icons 7–22 px) + 4 composed SVGs (`Container-1_364`, `SVG-1_457` 160×160 donut, `Nav-1_516`, `Aside-1_510`). **0 rasters.** No photos/avatars/vehicle images. Donut + icons are vector; chart colours fixed in composed SVG, not token-driven. No licence question (no rasters).

## 5. States

- Shown: current-shift selected; three activity statuses (Passed green / "Awaiting Review" amber / "Signed Off" neutral); progress tracks 85 % / 28 % / 100 %; nav active Dashboard.
- NOT shown: loading skeletons, empty workshop ("create first job"), partial-data retry, stale/offline, failed delivery, disabled account/workshop, long text, 200 % text, RTL/Arabic, dark theme (light-only per C-B), mobile/tablet derived layouts, hover/focus, 0 or >999 values.

## 6. Element → data mapping (O4 + O6 applied)

Existing endpoints/states: `GET /api/v1/workshop/jobs?search=&status=` → `WorkshopJob` (`client/apps/admin_app/lib/src/models.dart`: id, reference `JOB-…`, status, templateName, assignedTechnicianId/Name, scheduledAt, customerName, vehicleMake/Model/Year/Vin/Plate, scope) via `WorkshopJobController.list` (`server/.../jobs/api/WorkshopJobController.java:33`); `GET workshopReport(jobId)` / deliveries (`admin_api.dart`: `report`, `deliveries`); staff via `staff()` (`StaffMember`: userId/displayName/emailMasked/role/status only). No dashboard endpoint. Current app: **no dashboard exists** — `WorkshopAdminHomePage` has Jobs/Staff/Templates tabs only (`workshop_admin_home.dart`); router exposes `/workshop` only (`admin_router.dart`).

| Figma element | Mapping / verdict |
|---|---|
| Header bay pill "BAY ACTIVE Shop Floor #04" | DATA GAP — no bay entity/endpoint |
| Header search "Search VIN, tech, job ticket…" | Exists pattern: `JobsTab` search → `jobs(search)` (`jobs_tab.dart:37-81`). "Job ticket" has no field (reference `JOB-…` is the ticket id) |
| User chip "Marcus Vance / Lead Inspector" | Session display name exists (auth); "Lead Inspector" role label DATA GAP (roles are WORKSHOP_ADMIN/TECHNICIAN/PLATFORM_ADMIN) |
| Eyebrow "TELEMETRICS • REAL-TIME" + subtitle | DATA GAP — no telemetry/stream; copy must not claim real-time |
| Shift toggle "Shift A (Current) / Past 24h" | DATA GAP — no shift entity; OMIT (O4) |
| "Dispatch Bay" CTA | DATA GAP — no dispatch/bay feature; OMIT |
| KPI "12 /14 BAYS — Active Jobs — +2 incoming" | PARTLY: active-job count derivable client-side from `jobs()` filtered to non-final/cancelled statuses (O4-compliant: counts by status). Bay count 14, "/14 BAYS", "+2 incoming" DATA GAP |
| KPI "4 QUEUE — Pending Finalization — Requires Action" | PARTLY: count of `READY_TO_FINALIZE` from `jobs(status=READY_TO_FINALIZE)` (O4). "Requires Action" priority flag DATA GAP. O6: keep neutral "Ready to finalize" wording, no review wording |
| KPI "8 REPORTS SENT — 100% ACCURACY" | PARTLY: `FINALIZED` count from `jobs(status=FINALIZED)` (O4, "finalized today" needs client-side date filter on existing fields). "Reports sent" delivery count needs `deliveries(jobId)` per job (no aggregate endpoint — client aggregation or new endpoint). "100% ACCURACY" LOCKED-RULE conflict (vanity score; A02 "no vanity score") — OMIT |
| Activity row 1 "Porsche Taycan 4S, VIN • 9J18, Bay 04 • Full diagnostic pass complete (48/48 points checked), Passed, 2m ago" | PARTLY: vehicle/VIN-fragment from `WorkshopJob`. Bay, "48/48 points", elapsed "2m ago", "Passed" result wording DATA GAP (no per-job result/points endpoint on admin side; "Passed" reads as invented result — OMIT or map to status chip) |
| Activity row 2 "…awaiting lead inspector review / Awaiting Review" | LOCKED-RULE conflict (O6: no review-queue wording/states; locked: no second-person review). Neutral replacement required (e.g. show `READY_TO_FINALIZE` neutral chip or omit row state) |
| Activity row 3 "Sign-off certificate compiled and dispatched to fleet lead / Signed Off" | LOCKED-RULE conflict (O6 "sign off" banned; locked: no certification claims). Neutral replacement: `FINALIZED` neutral chip; "certificate/dispatched" delivery claim DATA GAP (use `deliveries()` states or omit) |
| Telemetry "76% CAPACITY, Bays 01-08" | DATA GAP + inconsistent (12/14 = 85.7 %, not 76 %) — OMIT (O4) |
| "Turnaround Target 45 mins / car", "Median Flow Rate 38 mins", "Inspection Compliance 99.4%" | DATA GAP (no targets/turnaround/compliance source); "Compliance/ACCURACY" also certification/vanity LOCKED-RULE conflict — OMIT |
| "View Detailed Floor Map" | DATA GAP (no floor-map/bay model) — OMIT |
| Nav Dashboard/Jobs/Settings | PARTLY: Jobs + Staff + Templates tabs exist; no Dashboard route, no Settings screen in admin app — new route/tab needed for dashboard |

## 7. Classification

**Needs new data or server change / conflicts with locked rule (as drawn).** O4-compliant subset (status counts: in-progress, ready-to-finalize, finalized-today + recent-jobs list, all from existing `GET /workshop/jobs` + client-side aggregation) is **UI work only** (new `/dashboard` route/tab + `AppStatCard` composition). Everything else (bays, shifts, telemetry, turnaround, compliance/accuracy, dispatch, floor map, real-time feed, points-checked, review/sign-off states, "Reports Sent" aggregate) needs new endpoints/models AND contains O6/locked-rule violations that must be replaced or omitted.

## 8. New shared components from this screen (vs already built)

1. Workshop admin chrome: 96 px icon rail + 80 px floating blurred header with status pill/search/user chip — NEW composite (restyle `AdminSidebar` rail + `AdminTopBar`; see shared list in `04-assign-technician.md` §8).
2. KPI/stat card composition — NEW (compose `AppStatCard` + `AppCoverageBar`).
3. Activity/feed row card — NEW (compose `AppListTile` + `StatusChip`).
4. Telemetry donut + key/value block — NEW (`AppProgressRing`-based).
5. Segmented shift control — covered by `AppSegmentedControl` (no build).

## 9. Could not verify

- Definitions/formulas for 76 % capacity, 100 % accuracy, 99.4 % compliance, median flow, turnaround target; why 12/14 → 76 %.
- Whether "Reports Sent" = `FINALIZED` count or delivery attempts (which delivery states).
- Whether bay/shift/dispatch/telematics/floor-map are planned entities (no server model found).
- Responsive behaviour below 1200/900 px (no Figma variant; O3 derived layouts pending designer review).
- Whether "lead inspector review" copy is workshop-internal text (still banned by O6 regardless).
