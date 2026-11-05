# 02. Assigned Jobs Dashboard

- App: Technician
- Figma node: 1:7131
- Frame: 390x1002 px (mobile phone; 390 pt logical width)
- Export folder: `screens/02_2._Assigned_Jobs_Dashboard`
- Sources read: `2._Assigned_Jobs_Dashboard.json`, `2._Assigned_Jobs_Dashboard@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html`
- Confidence: medium — the tree and PNG are complete, but the frame is taller than a normal phone viewport, no scroll is modelled, and the status/priority semantics are ambiguous.

## 1. Purpose

Technician home/queue: greeting, two snapshot metrics, three assigned jobs, a "Scan New VIN Tag" primary action, and a four-item floating bottom navigation. It is a dashboard variant of the assigned-jobs list, not the existing list-only screen.

## 2. Layout structure

- Root `1:7131`: VERTICAL, FIXED width / HUG height, 390x1002, `#FFFFFF`.
- `1:7132` `Main`: VERTICAL, padding `20/64/20/112`, content 350 px wide; the 64 px top and 112 px bottom padding reserve space for the fixed header and nav.
- `1:7133` content 350x826, VERTICAL:
  - `1:7134` top bar 350x88: HORIZONTAL, `SPACE_BETWEEN`; 56x56 avatar stack (44x44 emerald circle + 16 px presence dot) and a 132.8x26 "SHIFT 1 • BAY A" pill.
  - `1:7146` welcome block 350x90: 18/24 "Welcome back," + 26/32 "David Vance", 32 px bottom gap.
  - `1:7153` snapshot row 350x104: two 169x72 pills with 12 px gap; each radius 16, padding 16, icon tile 40x40; 32 px bottom gap.
  - `1:7173` section title 350x34: "ASSIGNED TODAY" + "3 In Queue" pill.
  - `1:7179` job cards 350x422: VERTICAL, gap 16; three 350x130 cards, radius 24, padding 20, internal gap 16. Each card has a 310x44 title row and a 310x30 meta row.
  - `1:7246` CTA block 350x88: 24 px top margin, 350x56 pill CTA, 8 px below.
- Fixed header `1:7252` 390x64 at y0, absolute, background `#FFFFFFE5` with 48 px background blur + 5% shadow.
- Fixed nav `1:7265` 390x80 at y922, absolute; inner `Nav` 350x64, radius 9999, background `#FFFFFFF2` with blur; four `Link` items 44x44 and labels 11/14.
- All sections are FILL width; cards and CTAs are fixed height. No tablet/desktop variant, no min/max widths.
- The frame is 1002 px tall while common phone viewports are ~844 px; there is no scroll container node. Scrolling is implied, not verified.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

| Hex | Usage | Approx. count |
|---|---|---|
| `#1A1B1F` | titles, values, active nav icon/label | 15 |
| `#5E5D69` | secondary text, labels, inactive nav | 17 |
| `#FFFFFF` | cards, nav, avatar ring | 11 |
| `#10B981` | primary CTA, avatar, active/positive dots, check icons | 8 |
| `#F4F3F8` | chips, avatar/clock tiles, live pill | 8 |
| `#10B9811A` | translucent emerald chevron button | 4 |
| `#006C49` | "3 In Queue" text and shift icon | 3 |
| `#3C4A42` | shift text | 2 |
| `#10B98126` | avatar halo | 1 |
| `#6FFBBE4D` | icon-tile tint | 1 |
| `#BBCABF` | third job's grey dot | 1 |
| `#E1DEEC66` | clock icon tile tint | 1 |
| `#FF7A73` | second job's red dot | 1 |
| `#FFFFFFE5` / `#FFFFFFF2` | header / nav translucency | 1 each |

Measured contrast: red dot `#FF7A73` on white = 2.54:1 and `#BBCABF` = 1.71:1; these 8 px dots are colour-only indicators and fail the 3:1 non-text contrast target. The "3 In Queue" `#006C49` text is 6.48:1 (pass).

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)

| Text / node | Family / weight | Size / line-height | Tracking | Alignment | Usage |
|---|---|---|---|---|---|
| `David Vance` 1:7152 | Plus Jakarta Sans / 800 | 26 / 32 | -0.65 px | left | Greeting |
| `Welcome back,` 1:7149 | Plus Jakarta Sans / 600 | 18 / 24 | 0 | left | Greeting lead |
| `3 Tasks` / `45 min` 1:7161 / 1:7170 | Plus Jakarta Sans / 800 | 16 / 20 | -0.16 px | left | Snapshot value |
| `Pending check` / `Avg. turnover` 1:7163 / 1:7172 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Snapshot label |
| `ASSIGNED TODAY` 1:7176 | Plus Jakarta Sans / 700 | 14 / 18 | +0.70 px, uppercase | left | Section label |
| `Renault Megan 3` 1:7188 etc. | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Card title |
| `ABC 123 • Bay 4` 1:7191 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Card meta |
| `Full Pre-Delivery Inspection` 1:7199 | Plus Jakarta Sans / 500 | 11 / 14 | +0.44 px | left | Service/template |
| `Ready` / `High Priority` / `Scheduled` 1:7201 etc. | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Status chip |
| `Scan New VIN Tag` 1:7251 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | centre | CTA |
| `Inspection Queue` 1:7257 | Plus Jakarta Sans / 700 | 16 / 22 | -0.40 px | left | Header |
| `LIVE\nSYNC` 1:7262 | Plus Jakarta Sans / 600 | 11 / 14 | +0.275 px, uppercase | left | Sync badge |
| Nav labels 1:7271–1:7286 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Bottom nav |

### Radii, shadows/elevation, strokes, spacing values

- Radii: 9999 ×21; 16 ×5 (snapshot pills); 24 ×3 (job cards); 48 ×2 (icon tiles).
- Card shadow: `DROP_SHADOW r=8 off=0,2` 1.6% + `r=40 off=0,14` 4.3%; nav shadow `r=12/50`; CTA `r=25` emerald 30%; header 5% + 48 px background blur.
- No strokes on cards; card separation is shadow only.
- Spacing: 12 (snapshot gap), 16 (card gap, internal), 20 (page margin/card padding), 24, 32, 64/112 reserved for header/nav.
- The 44x44 nav/avatar/chevron targets meet AA; the 8 px status dots and 18 px chips are not interactive but the colour-only meaning is an accessibility issue.

## 4. Components

| Figma pattern / node | Instances | Map to our design system |
|---|---|---|
| Fixed translucent header 1:7252 | 1 | `AppBar` inside `AppScaffold`; current app bar is opaque and has language/sync/sign-out actions |
| Live sync pill 1:7259 | 1 | `StatusChip` is closest, but there is no "live" state in `AppStatusColors` |
| Avatar + presence dot 1:7136 | 1 | no equivalent |
| Snapshot pill 1:7155 / 1:7164 | 2 | no equivalent (`AppCard` + custom row) |
| Job card 1:7180 etc. | 3 | `Card` + `AppListTile`; Figma is a taller 2-row card, not the current list tile |
| Status chip `Ready` etc. 1:7202 | 3 | `StatusChip`; Figma chips are text-only on tonal fill, no icon |
| Pill CTA 1:7247 | 1 | `AppButton(primary, expand)`; current radius 12 vs Figma pill |
| Floating bottom nav 1:7266 | 1 | no current route shell; Material `NavigationBar` exists but is not used by the technician app |
| Chevron open button 1:7185 | 3 | `IconButton` pressed/44x44 |

No component instances or variants are present; the repeated cards are plain frames named `Card 1`/`Card 2`/`Card 3`.

## 5. Assets

- Manifest count: **15** (14 individual SVGs, 0 composed, 1 raster).
- Icons: check-list 1:7143, clock 1:7158, car 1:7167/1:7207/1:7229, chevron 1:7194/1:7216/1:7238, badge/shift 1:7185, scan 1:7249, and four nav icons 1:7269/1:7274/1:7279/1:7284.
- Raster: `raster-1-d61ab6afa4` = **photo avatar** `assets/images/original/image-1-d61ab6afa4.jpg`, 64x64 JPEG, 1,192 bytes, rendered as a 32x32 circular profile image (`1:7264`). This is a photo of a person, not an icon.
- No vehicle image; job cars use a vector car icon.
- Asset names are generic and no licence/provenance is provided. If this is a real technician photo it needs identity/consent handling; if it is stock it needs a licence.

## 6. Content and data

| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| `DV` | technician initials | Yes, derived from name | Avatar photo is separate |
| `SHIFT 1 • BAY A` | shift/bay | Partly | No shift/bay field in `TechnicianJob`; current model has no shift |
| `Welcome back,` / `David Vance` | technician name | Yes (`assignedTechnicianName`) | On a dashboard the name is the signed-in technician, not necessarily `assignedTechnicianName` |
| `3 Tasks` / `Pending check` | count | Derivable | No dashboard endpoint; count jobs with pending status |
| `45 min` / `Avg. turnover` | duration | No | No turnaround field or definition in the model |
| `ASSIGNED TODAY` / `3 In Queue` | count | Derivable | Date filtering not in the current list API |
| `Renault Megan 3` ×3 | vehicle | Yes | Misspelling of "Megane"; repeated sample data |
| `ABC 123 • Bay 4`, `XYZ 882 • Bay 2`, `KLO 904 • Bay 6` | plate + bay | Plate yes; bay no | Plates are sample personal/vehicle identifiers |
| `Full Pre-Delivery Inspection`, `Brake Fluid & Tire Diagnostics`, `Routine 60-Point Audit` | service names | Template name (`templateName`) | "60-Point" conflicts with the 100+ item target; not verified |
| `Ready`, `High Priority`, `Scheduled` | status chips | Partly | `Ready`/`Scheduled` are not statuses in the model; `High Priority` has no field |
| `Scan New VIN Tag` | action | No | VIN scanning is deferred in the navigation map |
| `Inspection Queue` | title | No | Current screen title is "Assigned jobs" |
| `LIVE\nSYNC` | sync claim | No | No live-sync state in the client; offline-first with queued sync |
| `Intake` / `Fleet` / `Sync` / `Profile` | nav | Sync yes; others no | No `/settings` or `/fleet` route in `technician_router.dart` |

No score appears. No public-report PII appears, but the job cards expose plates and the avatar exposes a face.

## 7. States shown / not shown

Shown: populated queue with three cards; "LIVE SYNC"; enabled scan CTA; active `Intake` nav.

Not shown: loading skeleton; empty queue (screen 03); error/request-ID; offline banner; pending-sync badge; sync conflict; search; status filters; pull-to-refresh; disabled actions; rate-limited/locked account; Arabic/RTL.

## 8. Implied interactions

- Tap a job card or chevron to open the job.
- Tap `Scan New VIN Tag` to start a scan (no camera/scan screen in the eight-screen set).
- Tap avatar/profile and nav items; `Intake` is active.
- No reactions are stored on any node; navigation targets are inferred and cannot be verified.

## 9. Correspondence to current product

- Matches T03 Assigned jobs (`/jobs`) and is implemented by `client/apps/technician_app/lib/src/pages/technician_jobs_page.dart`; data comes from `technicianJobs` (`/api/v1/technician/jobs`).
- Current screen has search, status filters, pull-to-refresh, offline banner, sync badge, language toggle, sign-out and a **walk-in job** FAB. The Figma omits all of those and adds dashboard metrics, avatar, scan VIN, and a bottom nav.
- The snapshot/dashboard aggregates have no endpoint or model. `TechnicianJob` has no bay, shift, priority or turnover field. A UI-only build would need derived counts from the existing list, but "45 min Avg. turnover" and "High Priority" have no source.
- "Fleet" and "Profile" have no route; only `/jobs`, `/jobs/new`, `/sync`, and job routes exist.

## 10. Locked-rule conflicts / unsafe-to-ship content

- **"VIN OCR/scanning (deferred)"** (`docs/phase-1/01-navigation-maps.md` items intentionally absent): `Scan New VIN Tag` (1:7251) presents a scan feature as primary. It cannot be shipped without a scope/roadmap change.
- **"Fleet" is not in the technician navigation map** and there is no fleet module/role in the app. The `Fleet` tab (1:7274/1:7276) invents an out-of-scope product area.
- **"never imply data was sent" / offline-first**: `LIVE\nSYNC` (1:7262) is a static badge with no connectivity or receipt state. The product states are `LOCAL_ONLY`, `QUEUED`, `UPLOADING`, `RECEIVED`, `FAILED`, `CONFLICT`.
- **"no manager role, second-person review, approval queue"**: `Inspection Queue` + `High Priority` reads like a dispatch/review queue. It is a jobs list, but the wording should not imply a manager queue.
- **"no invented … measurements/results"**: `45 min Avg. turnover` is an invented metric; `High Priority`/`Ready` are invented states not in `TechnicianJob.status`.
- **"colour + icon + text" / WCAG 2.2 AA**: the 8 px status dots (`#10B981`, `#FF7A73`, `#BBCABF`) carry meaning by colour alone; red/grey dots are below 3:1 on white.
- **Privacy/provenance**: a photo avatar and three plates ship as sample data; the avatar is a raster photo with no provenance/consent metadata. Public-report rules do not apply to this internal screen, but these assets must not be reused in the public report or marketing.
- **RTL**: no Arabic layout; all rows are LTR.
- **Brand**: "Inspection Queue"/"Fleet" are not TrueReport terminology.

## 11. Open questions / could not verify

- Is `Ready` a job status or the technician's readiness? Is it the same as `ASSIGNED`/`IN_PROGRESS`?
- What does `High Priority` mean, and is there a priority field/API? None exists today.
- Is `45 min Avg. turnover` a real approved KPI, and over what period?
- Is the `Fleet` tab a planned module or a leftover from a different product?
- Is the avatar a real technician photo, a stock image, or a placeholder? What licence/consent applies?
- Are the plates/vehicles intentionally fictitious? The same job flow uses Renault on 02/04/08, Porsche on 07, and different VINs on 05/07.
- Is the frame meant to scroll? At 1002 px, the fixed nav header and SPA viewport conflict is not modelled.
- No prototype reactions exist; tap destinations (especially `Intake`, `Fleet`, `Profile`) cannot be verified.
