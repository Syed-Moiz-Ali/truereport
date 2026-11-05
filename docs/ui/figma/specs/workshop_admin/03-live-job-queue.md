# 03. 2. Live Job Queue

- App: Workshop Admin
- Figma node: `1:529`
- Frame: 1280x1125 px (desktop web; >=1200 breakpoint)
- Export folder: `screens/03_2._Live_Job_Queue`
- Sources read: `2._Live_Job_Queue.json` (developerSummary, nodes), `2._Live_Job_Queue@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html` header, `package-manifest.json`
- Export/screen-number mismatch: this is export slot **03** but Figma screen **2** ("Live Job Queue"). The export sequence follows page position, not screen numbering; screen 1 is exported in slot 02.
- Confidence: medium — geometry and text are measured; the status vocabulary, progress, bay and review data shown have no current model.

## 1. Purpose

Operational queue of all vehicles in bays or scheduled for inspection. It combines search/filter/sort with per-job assignment, progress, review flags and quick actions.

## 2. Layout structure

Root `1:529` fixed 1280x1125, vertical. Rail `1:802` 96x1101 at x=0; main `1:531` 1184 px at x=96 with padding 80/40/48/40; floating header `1:779` 1184x80 with blur.

Content `1:532` = 1104x997, top-to-bottom:
1. **Title/header row** (`1:533`–`1:561`, 1104x107): eyebrow pill, 32 px title, subtitle on the left; a 279.9x64 stat card (two metrics split by a 1 px divider) and a 157.1x56 primary "+ New Job" button on the right; 40 px bottom margin.
2. **Filter/sort row** (`1:563`, 1104x48): a 48 px segmented pill (All 12 / In Progress 4 / Pending Review 3 / Completed 5) and, right-aligned, a "Bay Order" tonal pill plus a 40x40 filter icon button; 32 px bottom margin.
3. **Job list** (`1:582`, 1104x672, 24 px gap): four article cards (`1:583`, `1:629`, `1:674`, `1:720`), each 1104x150, radius 24, padding 32. Row order is left-to-right: 80x80 rounded vehicle image (`1:587`), title/status/VIN/customer block, assigned-tech initials 40x40 + name + bay, progress or review/slot block, 48x48 chevron button.
4. **Status/footer strip** (`1:767`, 1104x50, radius 16, `#F4F3F899`): live-sync dot + text on the left; "Export Daily Log", "Batch Reassign", "Bay Schedule Matrix →" on the right; 48 px top margin.

Only four rows are drawn although the "All (12)" filter says 12; the frame height implies the list is clipped/scrollable but no scroll container/indicator is visible. Fixed desktop widths; no mobile variant.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx fill count)

| Hex | Count | Usage |
|---|---:|---|
| `#5E5D69` | 42 | Secondary text, metadata, icons |
| `#1A1B1F` | 27 | Titles, VIN values, chevrons |
| `#F4F3F8` | 22 | Pills, avatar circles, progress track, row buttons |
| `#FFFFFF` | 16 | Page, cards, filter pills |
| `#10B981` | 10 | Progress fill, active nav, "+ New Job", initials |
| `#E9E7ED` | 4 | Bullet separators |
| `#006C49` | 2 | Success labels |
| `#B45309` | 2 | "In Progress" text on `#FFFBEB` |
| `#EEEDF3` | 2 | Scheduled chip, stat divider |
| `#FFFBEB` | 2 | In Progress chip background |
| `#3C4A42` | 1 | "BAY ACTIVE" |
| `#BA1A1A` | 1 | Review flag dot |
| `#C2410C` | 1 | "Pending Review" text on `#FFF7ED` |
| `#F4F3F899` | 1 | Footer overlay |
| `#FFF7ED` | 1 | Pending Review chip background |
| `#FFFFFFE5` | 1 | Blurred header fill |

### Typography

Plus Jakarta Sans only. 66 text nodes: SemiBold 600 x35, Bold 700 x14, Regular 400 x10, Medium 500 x5, ExtraBold 800 x1, SemiBold Italic 600 x1.
Sizes: 11 x24, 12 x18, 13 x14, 22 x4, 16 x3, 14 x2, 32 x1.

| Role | Style | Example |
|---|---|---|
| Page title | 32 / 38, 800, -0.8 px | `1:541` |
| Job title | 22 / 28, 700, -0.55 px | `1:592` "Porsche 911 Carrera S" |
| Stat value | 16 / 22, 700 | `1:550` "06 / 08" |
| VIN value | 13 / 18, 500 | `1:600` "WP0AB2A91LS" |
| Customer/tech name | 13 / 18 or 12 / 16, 400/600 | `1:607`, `1:616` |
| Status chip | 11 / 14, 600, +0.275 px | `1:594` "In Progress" |
| Micro label/count | 11 / 14, 600, +0.44/+0.55 px, UPPER | `1:548` "ACTIVE BAYS" |
| Unassigned | 12 / 16, 600 italic | `1:753` |

Left-aligned; uppercase micro-labels; VIN uses normal sans, not a monospaced/LTR-marked style.

### Radii, shadows/elevation, strokes, spacing

- Radii: 24 (article cards), 16 (vehicle thumbs, footer, primary button, sort pills), 9999 (filter pills, avatars, chevrons, progress).
- Card shadow: `0 2 8 rgba(0,0,0,.016)` + `0 14 40 rgba(0,0,0,.043)`; filter track has an inner shadow (`0 2 4 rgba(0,0,0,.05)`).
- No card strokes; separators are bullet glyphs/dividers.
- Spacing: 12 x22, 24 x21, 32 x21, 4 x19, 6 x19, 16 x18, 8 x16; 24 px between cards.

## 4. Components

| Figma pattern | Node | Our design-system equivalent |
|---|---|---|
| Floating header | `1:779` | No equivalent / `AppBar` |
| Icon rail | `1:808` | `NavigationRail` |
| Status filter segmented control | `1:564` | `AppSelectableText` (text-only; no segmented container) |
| Sort pill + filter icon | `1:574`, `1:579` | `AppButton` tonal / IconButton |
| Job article card | `1:583` | `AppListTile` + `Card` (current list uses this, without image/metrics) |
| Status chip | `1:593`, `1:639`, `1:730` | `StatusChip` |
| Initials avatar | `1:610` | `CircleAvatar` (current code shows a letter) |
| Progress bar | `1:621` | No equivalent |
| Chevron icon button | `1:626` | IconButton |
| Live-sync strip | `1:767` | `OfflineBanner` is the closest, but this is an always-online status |

## 5. Assets

25 assets: 19 individual SVGs, 2 composed SVGs (`Nav-1_808`, `Aside-1_802`), 4 rasters. The four rasters are **vehicle photographs** (`image-1..4`, 80x80 rounded thumbnails), not avatars. All other assets are 7–15 px icons. No customer photos. Licensing/provenance of the JPGs is not stated.

## 6. Content and data

| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Eyebrow/title/subtitle | "REAL-TIME DISPATCH", "Live Job Queue", "All vehicles currently in bays or scheduled for inspection" | No | Real-time claim unsupported |
| Stats | "ACTIVE BAYS 06 / 08", "AVG TURNAROUND 42m" | No | No bay or turnaround data; 06/08 may be 6 of 8 |
| Primary action | "+ New Job" | Yes (link only) | Opens creation |
| Filters | "All (12)", "In Progress (4)", "Pending Review (3)", "Completed (5)" | Partly | Server statuses are DRAFT/SCHEDULED/ASSIGNED/IN_PROGRESS/READY_TO_FINALIZE/FINALIZED/CANCELLED; "Pending Review" and "Completed" are not statuses |
| Sort/filter | "Bay Order", sliders icon | No | No bay entity; no sort/filter API allowlist beyond status/search |
| Row 1 | "Porsche 911 Carrera S", "In Progress", "VIN WP0AB2A91LS", "Alexander Wright", "MV", "Marcus Vance (Bay 04)", "65%" | Partly | Job/vehicle/tech exist; bay, customer, progress %, initials are new |
| Row 2 | "Ford Transit 350 High Roof", "Pending Review", "VIN 1FTBR1Y88PK", "Fleet Logistics Inc", "DV", "David Vance (Bay 02)", "REVIEW ITEMS", "2 Flags Marked" | No | Review state, flags, bay and company customer are not in the model |
| Row 3 | "Renault Megan 3 E-Tech", "In Progress", "VIN VF1RCB00078", "Arthur Pendelton", "DV", "David Vance (Bay 01)", "30%" | Partly | Typo "Megan" vs "Mégane"; same model gaps |
| Row 4 | "BMW i4 M50 Gran Coupe", "Scheduled", "VIN WBA33AW05N", "Elena Rostova", "--", "Unassigned", "SLOT TIME", "14:30 Today" | Partly | `scheduledAt` exists; bay absent; date format ambiguous |
| Footer | "Live sync active. Updated 4 seconds ago."; "Export Daily Log"; "Batch Reassign"; "Bay Schedule Matrix →" | No | No live sync, export, batch reassign or bay matrix |

Customer names are shown; VINs are 10–11 characters (truncated from 17). No phone/email/plate. "Flags", "review items" and industry names are mock data.

## 7. States shown / not shown

Shown: active filter "All (12)"; three status variants + Scheduled; assigned/unassigned; progress 65/30%; review items; live-sync success.
Not shown: empty queue, no active bays, loading skeleton, error/retry, offline, pagination/load-more for the other 8 jobs, long names, 200% text, RTL/Arabic, dark theme, mobile/tablet card fallback, disabled/failed sync, filter with zero results, cancelled/finalized rows.

## 8. Implied interactions

Filter tabs; sort by bay order; filter button; New Job; open a row via chevron/card; footer export/batch reassign/bay schedule; search; nav; user menu. No row selection/multi-select affordance is visible even though "Batch Reassign" exists. No status-change action is shown.

## 9. Correspondence to current product

- Spec: A03 Job list `/jobs` (`docs/phase-1/02-screen-inventory.md:63`) — search, status, technician, date, template, pagination/cursor; data table on web, cards on mobile; **"export? (export pending)"**.
- Current UI: `JobsTab` (`jobs_tab.dart`) renders a searchable list of `Card` + `AppListTile` with reference/customer, vehicle/template, `StatusChip`; horizontal status chips; pull-to-refresh. It has no images, bay, progress, stats, sort, or footer actions.
- API: `GET /api/v1/workshop/jobs?search=&status=` → `JobDto` (`JobDto.java`). Fields exist for customer, vehicle, assigned tech, scheduledAt, template, status. There is no bay, progress, flags, review state, initials or turnaround.
- Verdict: **existing screen** with a major redesign; progress/bay/review/real-time/export/batch actions **need new data and server changes** and some (review) conflict with locked product rules.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"No manager role, second-person review, approval queue or resubmission."** Evidence: "Pending Review (3)", "REVIEW ITEMS", "2 Flags Marked", and a "Pending Review" status. `READY_TO_FINALIZE` is self-finalization for the assigned technician; it is not a review queue.
2. **"Finalized findings/reports immutable."** The queue offers "Batch Reassign" and row-level assignment but no finalization lock/read-only marker; mixing finalized "Completed" rows into the same actionable list risks implying edits after finalization.
3. **"No single unexplained condition score."** Not a vehicle score, but "65%" / "30%" progress and "2 Flags Marked" are unexplained; progress is not in `JobDto` and no denominator/definition is shown.
4. **"Never invent measurements/results."** Evidence: 42m average, 65/30%, 12 total, 2 flags, "Updated 4 seconds ago".
5. **"UI layer only; no business logic/API/model/server change."** Real-time sync, export daily log, batch reassignment and bay matrix are new features.
6. **Tokens.** Raw hex; `#10B981` is not in the current theme; radii 24 > 16 token; cards use a different shadow set than screen 02.
7. **WCAG 2.2 AA.** White "+ New Job" on `#10B981` is approx 2.5:1; initials "MV"/"DV" in `#10B981` on `#F4F3F8` are approx 2.3:1 (12 px bold, so below 4.5:1). 11 px status text is small; chevron buttons are 48x48 (ok).
8. **Arabic RTL.** No Arabic sample; VIN needs explicit LTR; the left rail, chevrons and "Bay Schedule Matrix →" must mirror. No RTL column ordering is defined.
9. **Customer PII.** Names, organisation names and partial VINs are visible in a queue; allowed internally but must not leak to the public report. Partial VIN is still identifying when combined with customer name.
10. **Vehicle photos.** The four JPGs are real vehicle images inside customer-facing job cards; provenance/licence is unknown.

## 11. Open questions / could not verify

- Does "Pending Review" mean `READY_TO_FINALIZE`, or is a new reviewer state being proposed? If the latter, it contradicts the locked no-review rule.
- What produces "2 Flags Marked"? There is no flag/blocking-item field on a job.
- Is "65%" checklist completion, category completion, or time? How is it calculated and is it allowed on a mutable job?
- Are "Bay 01–04" and "Bay Order" real entities? What are the 8 bays and their states?
- Are customer names allowed in the queue, or should only the vehicle/ref show? What is the privacy rule for workshop staff?
- Is "Live sync active" a real-time connection or a polling timestamp? What happens offline?
- Should "Completed" be `FINALIZED` and read-only? Can a finalised job be reassigned?
- Is "All (12)" the total or the filtered count, and where are pagination/virtualization controls?
- Is "Export Daily Log" approved? The spec says export is pending.
