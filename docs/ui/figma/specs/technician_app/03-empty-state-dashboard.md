# 03. Empty State Dashboard

- App: Technician
- Figma node: 1:7287
- Frame: 390x883.75 px (mobile phone; 390 pt logical width)
- Export folder: `screens/03_3._Empty_State_Dashboard`
- Sources read: `3._Empty_State_Dashboard.json`, `3._Empty_State_Dashboard@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html`
- Confidence: medium-high — visual and text are clear; the empty-state internals use absolute positioning, and the summary metrics have no verified data source.

## 1. Purpose

Zero-jobs dashboard variant of screen 02: "You are all caught up!", a refresh action, a sync reassurance line, and a "TODAY'S SUMMARY" strip. It is the empty state of the assigned-jobs queue, not a generic no-results state.

## 2. Layout structure

- Root `1:7287`: VERTICAL, FIXED width / HUG height, 390x883.75, `#FFFFFF`.
- `1:7288` `Main`: VERTICAL, padding `20/64/20/112`; 350 px content.
- `1:7289` content 350x707.8: VERTICAL, `SPACE_BETWEEN`.
  - `1:7290` top bar 350x72: HORIZONTAL, padding `0/8/0/16`, space-between; 48x48 avatar with halo; "SHIFT ACTIVE" pill 116.5x22; "Bay 04" pill 84.7x26.
  - `1:7305` welcome 350x66: 16/24 "Welcome back,"; 26/32 "David Vance".
  - `1:7312` empty-state body 350x497.8, **layoutMode NONE** (absolute children): 128x128 white card at y176; coffee-cup icon 33x33; `0 IN QUEUE`; 22/30.25 headline; 14/22.75 body; 168.4x48 refresh pill; 199.1x14 sync line at y405.8.
  - `1:7346` summary 350x72: HORIZONTAL, radius 16, fill `#F4F3F8`, padding 16; 40x40 calendar tile, "TODAY'S SUMMARY" 11/14, "14 Completed" 16/22, "100% Pass Rate" 12/16 with a trend-arrow icon.
- Fixed header `1:7361` 390x64 at y0, absolute, `#FFFFFFE5` + 48 px background blur.
- Fixed nav `1:7374` 390x80 at y804, absolute; inner 350x64 pill with four 44x44 links.
- The central empty-state block uses absolutely positioned children inside a fixed 497.8 px height. It has no Auto Layout, so it cannot reflow at 200% text or in Arabic.
- Section order: top bar → greeting → empty-state illustration/headline/body → refresh → sync line → summary → nav.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

| Hex | Usage | Approx. count |
|---|---|---|
| `#5E5D69` | greeting, body, labels, inactive nav | 10 |
| `#1A1B1F` | name, headline, values, active nav | 8 |
| `#10B981` | avatar, queue text, check icon, filled bar | 7 |
| `#F4F3F8` | shift/bay chips, refresh button, summary card | 6 |
| `#FFFFFF` | surfaces, nav, icon tile | 5 |
| `#006C49` | pass-rate text | 3 |
| `#3C4A42` | shift/summary labels | 3 |
| `#10B9811A` | "0 IN QUEUE" pill | 1 |
| `#10B98126` | avatar halo | 1 |
| `#5E5D6933` / `#5E5D694D` / `#5E5D6966` | decorative steam bars | 1 each |
| `#62616D` | secondary label | 1 |
| `#EEEDF3` | progress track | 1 |
| `#FFFFFFE5` / `#FFFFFFF2` | header / nav translucency | 1 each |

`#10B981` text on white = 2.54:1; it is used for the 11 px "0 IN QUEUE" label and 12 px "100% Pass Rate". `#006C49` on white = 6.48:1.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)

| Text / node | Family / weight | Size / line-height | Tracking | Alignment | Usage |
|---|---|---|---|---|---|
| `David Vance` 1:7311 | Plus Jakarta Sans / 800 | 26 / 32 | -0.65 px | left | Greeting |
| `Welcome back,` 1:7308 | Plus Jakarta Sans / 500 | 16 / 24 | -0.40 px | left | Greeting lead |
| `SHIFT ACTIVE` 1:7299 | Plus Jakarta Sans / 700 | 11 / 14 | +0.55 px, uppercase | left | Shift pill |
| `Bay 04` 1:7304 | Plus Jakarta Sans / 700 | 11 / 14 | +0.44 px | left | Bay pill |
| `0 IN QUEUE` 1:7320 | Plus Jakarta Sans / 700 | 11 / 14 | +0.44 px, uppercase | centre | Queue count |
| `You are all caught up!` 1:7321 | Plus Jakarta Sans / 800 | 22 / 30.25 | -0.55 px | centre | Empty headline |
| `No pending vehicle inspections assigned\nto you today.` 1:7324 | Plus Jakarta Sans / 500 | 14 / 22.75 | -0.07 px | centre | Empty body |
| `Refresh Queue` 1:7330 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | centre | Secondary CTA |
| `Queue is current • Synced just now` 1:7345 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | centre | Sync claim |
| `TODAY'S SUMMARY` 1:7353 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Summary label |
| `14 Completed` 1:7355 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Summary value |
| `100% Pass Rate` 1:7358 | Plus Jakarta Sans / 700 | 12 / 16 | +0.24 px | left | Metric |
| `Inspection Queue` 1:7366 | Plus Jakarta Sans / 700 | 16 / 22 | -0.40 px | left | Header |

### Radii, shadows/elevation, strokes, spacing values

- Radii: 9999 ×16; 16 ×2 (summary card, refresh); 24 ×1 (empty card); 48 ×1 (calendar tile).
- Empty card shadow `r=8 off=0,2` 1.6% + `r=40 off=0,14` 4.3%; avatar `r=16` 12%; header 5% + blur; nav `r=12/50`.
- No strokes. Spacing: 8/12/16/24/32; the empty block's vertical positions are absolute (176, 325.8, 405.8).
- Refresh 168.4x48 meets 44 px; nav links 44x44. The 11 px green "0 IN QUEUE" text is below AA contrast.

## 4. Components

| Figma pattern / node | Instances | Map to our design system |
|---|---|---|
| Avatar + halo 1:7292 | 1 | no equivalent |
| Shift/bay pills 1:7296 / 1:7300 | 2 | `StatusChip` styling is close; no bay/shift model |
| Empty state 1:7332 | 1 | `EmptyState`; current component has title, body, optional action and icon; Figma adds a large illustration card and sync line |
| Refresh button 1:7326 | 1 | `AppButton(tonal)` |
| Summary strip 1:7346 | 1 | no equivalent; `Card` + custom metric row |
| Fixed nav 1:7375 | 1 | no equivalent in current route shell |
| Coffee-cup illustration 1:7335 | 1 | Material icon could replace; not a product illustration |

No component instances/variants; decorative steam bars are unnamed rectangles.

## 5. Assets

- Manifest count: **11** (10 individual SVGs, 0 composed, 1 raster).
- Icons include calendar 1:7350, trend arrow 1:7360, coffee cup 1:7335 (33x33), check 1:7318, shield/shift 1:7302, refresh 1:7328, and four nav icons.
- Raster: same 64x64 JPEG **photo avatar** (`raster-1-d61ab6afa4`) as screen 02.
- No vehicle photo. No composed assets.
- The coffee cup is an illustration-like icon; if kept, it needs a licensed icon set, not a Figma vector copy.

## 6. Content and data

| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| `DV` | technician initials | Yes, derived | Same avatar image as 02 |
| `SHIFT ACTIVE` / `Bay 04` | shift/bay | Partly | No shift/bay field in `TechnicianJob` |
| `David Vance` | technician name | Yes | Signed-in user, not job assignee |
| `0 IN QUEUE` | count | Derivable | Empty list |
| `You are all caught up!` | headline | No | Product empty-state copy uses "No jobs assigned…" |
| `No pending vehicle inspections assigned\nto you today.` | body | No | Fixed sample copy |
| `Refresh Queue` | action | Yes (refresh) | No loading state shown |
| `Queue is current • Synced just now` | sync claim | No | No timestamp/receipt field; "just now" is invented |
| `TODAY'S SUMMARY` / `14 Completed` | count | No endpoint | No daily-completion aggregate in current API |
| `100% Pass Rate` | percentage | **No** | No pass-rate field; forbidden single condition score |
| `Inspection Queue` / `LIVE\nSYNC` | header/status | No | Static claims |
| `Intake` / `Fleet` / `Sync` / `Profile` | nav | Sync only | No `/fleet` or `/profile` route |

No VIN, plate, phone or customer name appears. The only personal data is the technician avatar/name.

## 7. States shown / not shown

Shown: empty queue, enabled refresh, summary strip, sync-just-now claim.

Not shown: populated queue (screen 02); loading/refresh spinner; refresh error; offline/no-cache; "last updated" timestamp; contact-Workshop-Admin action; walk-in action; stale-data state; Arabic/RTL.

## 8. Implied interactions

- `Refresh Queue` reloads the queue.
- Nav items switch sections; `Intake` is active.
- No prototype reactions exist; refresh behaviour and nav targets are inferred.

## 9. Correspondence to current product

- Matches T03 empty state in `technician_jobs_page.dart`: the current `EmptyState` says "No jobs assigned. Ask your Workshop Admin, or create a walk-in job." with a walk-in action; Figma says "You are all caught up!" and only offers refresh.
- Data source: `technicianJobs`; there is no completed-today or pass-rate aggregate in `TechnicianJob`/`InspectionChecklist`.
- "14 Completed" would require a new query/aggregate; "100% Pass Rate" would require a scoring concept that the product explicitly rejects.
- The nav and avatar are new UI; `Fleet`/`Profile` are not routes.

## 10. Locked-rule conflicts / unsafe-to-ship content

- **"no single unexplained condition score"** (and design-system §1 "No false reassurance… never use a green pass badge that implies the vehicle is perfect"): `100% Pass Rate` (1:7358) is exactly a single condition score, in green, with no explanation. It must not ship.
- **"NO_ISSUE_OBSERVED must never be labelled Pass/Perfect/Certified"**: "Pass Rate" uses the forbidden label at screen level.
- **"never imply data was sent" / offline-first**: `Queue is current • Synced just now` (1:7345) claims a successful sync with no actual timestamp, receipt state, or connectivity check.
- **"no invented … results"**: `14 Completed` and `100% Pass Rate` have no source field/endpoint.
- **T03 empty-state requirement**: "No jobs assigned + contact Workshop Admin" is replaced by "You are all caught up!" + refresh; there is no route to contact an admin or create a walk-in job from this screen.
- **"Fleet" is out of scope** and has no route, as on screen 02.
- **WCAG 2.2 AA**: `#10B981` 11 px text on white = 2.54:1; the empty-state block is absolutely positioned and will overlap at 200% text; no Arabic/RTL.
- **Privacy**: avatar photo again; no consent/licence metadata.

## 11. Open questions / could not verify

- Is a "Pass Rate" approved for the technician app? The product rule says no single condition score; this looks contradictory.
- What is the source/period for `14 Completed` and `100% Pass Rate`? Is it per technician, per workshop, or per shift?
- Is `Queue is current • Synced just now` a real sync status or marketing copy? What should it show when offline or pending?
- Should the empty state link to the Workshop Admin or to the walk-in job form, per T03?
- What is `Bay 04` / `SHIFT ACTIVE` sourced from? No shift/bay fields exist.
- Is the coffee-cup illustration intentional, and is it licensed?
- Is the frame scrollable? At 883.75 px with a fixed nav, a larger text scale will collide.
- No prototype reactions; refresh/nav behaviour cannot be verified.
