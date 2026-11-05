# 14. 15. Offline Sync Queue

- App: Technician
- Figma node: `1:8633`
- Frame: 390 x 1361.94 px (phone; mobile portrait, tall scroll)
- Export folder: `screens/14_15._Offline_Sync_Queue`
- Sources read: `15._Offline_Sync_Queue.json` (developerSummary, assetIndex, full node tree), `15._Offline_Sync_Queue@2x.png`, `assets/manifest.json`
- Confidence: high for layout/typography; medium for the live metrics (they are static samples); low for state transitions and RTL (only the offline/paused state is exported)

> **Ordering note:** this folder is manifest index **14** but the Figma screen is named **"15. Offline Sync Queue"**. The file name above uses the manifest index as the NN prefix. Screens 12–15 are numbered differently in Figma than in the export order.

## 1. Purpose

A detailed offline/sync dashboard: it explains that the device is working offline and saving locally, shows cache size and the pending batch, and lists the upload queue with one active upload plus queued jobs. "Retry Sync Now" forces a sync and a note says the device retries every 60 seconds.

## 2. Layout structure

Root `1:8633`: 390x1361.94, VERTICAL, fill `#FFFFFF`, FIXED/HUG.

1. `1:8634` "Main" — 390x1361.94, VERTICAL, padding `64/0/112/0` (bottom space for the floating nav).
   - `1:8635` content — 390x1185.94, VERTICAL, padding `8/20/8/20`.
     - `1:8636` sub-nav/header — 350x64, HORIZONTAL; 41.81x44 back button, `Sync Status` 26/32 ExtraBold, `Local Engine v4.2 • Background sync` 11/14, `No Signal` chip 94.78x40.
     - `1:8651` offline banner margin — 350x196.19, top padding 24; banner 350x172.19, **radius 32**, padding 20, fill `#FFF5EB`, shadow.
       - 12x12 `#F59E0B` dot + 40% halo.
       - `Working Offline — Saving Locally` 16/22 Bold; `Store Active` chip 73.34x32 (`#FDE68A@0.5`, text `#B45309`); body 282x85, 13/18, line-height 21.13.
     - `1:8665` stats margin — 350x169.75, top padding 24; two 169-wide cards, **radius 32**, padding 16, shadow.
       - `BUFFERED CACHE` + icon; `148.6` 22/28 Bold; `MB Local` 11/14.
       - `PENDING BATCH` + icon; `3` 22/28 Bold; `Inspections` 22/28 Bold; `Awaiting link` 11/14.
     - `1:8688` upload queue margin — 350x510, top padding 24; section 350x486, gap 12.
       - header: `Upload Queue` 18/24 Bold + `Auto-retry paused` 11/14.
       - active card 350x222, **radius 32**, padding 20, gap 16, shadow; 30.16x40 icon pill; `Uploading Evidence Photos (4/12)` 16/22 Bold; `Job #IN-88912 • 2024 Ford F-150 Lightning` 13/18; `Standby` chip 68.3x22; 310x6 progress (103.22 fill, 33%); `33% completed` / `8 items remaining` 11/14; `Transfer Speed` 0.0 KB/s; `Pending Jobs` 2 in Line.
       - two queued rows 350x98, **radius 32**, padding 20, shadow; icon, 16/22 title, 13/18 job meta, right `Queued` 11 + size 13.
     - `1:8766` retry margin — 350x126, top padding 24; 350x56 pill `Retry Sync Now` + 13/18 note.
2. `1:8776` Header — 390x64, `#FFFFFF@0.8` + blur + shadow; back? (icon 36x36 `#F4F3F8` shield), `Sync Queue` 22/28 Bold, 32x32 emerald avatar.
3. `1:8787` Nav — 390x80, padding `0/20/16/20`; floating 350x64 pill white, shadow; four 56x44 links: **Intake, Fleet, Sync (active), Profile**.

There is no explicit scroll view; content height 1361.94 exceeds the viewport, so the page is intended to scroll. Bottom nav floats above content. No tablet layout.

## 3. Visual tokens observed

### Colours

| Hex | Usage | ~Count |
|---|---|---|
| `#5E5D69` | secondary text/icons | 28 |
| `#1A1B1F` | primary text/icons | 18 |
| `#FFFFFF` | cards/nav | 12 |
| `#EEEDF3` | chips, track, dividers | 6 |
| `#006C49` | emerald icons/avatar | 5 |
| `#F4F3F8` | icon circles | 4 |
| `#10B981` | progress fill, dots | 2 |
| `#3C4A42` | banner body | 1 |
| `#B45309` | "Store Active" text | 1 |
| `#F59E0B` | offline dot | 1 |
| `#F59E0B66` (40%) | dot halo | 1 |
| `#FDE68A80` (50%) | "Store Active" chip | 1 |
| `#FFF5EB` | offline banner | 1 |

### Typography

- Family **Plus Jakarta Sans**; weights 400/500/600/700/800.
- 26 / 32 / ExtraBold 800 / -0.65 — `Sync Status`.
- 22 / 28 / Bold 700 — `Sync Queue`, big metrics.
- 18 / 24 / Bold 700 — `Upload Queue`.
- 16 / 22 / Bold 700 — banner title, job titles.
- 13 / 18 / Regular — job meta, body; line-height 21.13 for the banner body.
- 11 / 14 / SemiBold 600 (+0.44) — labels/chips/notes.
- 12 / 16 SemiBold — metadata values.
- Left-aligned; the retry note is centered.

### Radii, shadows, strokes, spacing

- Radii: `9999` x17, `32` x6. Cards 32; nav/chips/buttons full pill.
- Shadows: banner, both stat cards, active upload card, queued cards, retry CTA, floating nav; header uses blur + shadow.
- Strokes: no borders; dividers are 1px `#EEEDF3` rectangles.
- Spacing: 20 dominant (22), 16, 12, 8, 3, 2, 4, 6, 24, 10. Page margin 20; card padding 20; 20 is not a current spacing token.

## 4. Components

Figma patterns:
- Sub-page header with large 26px title, tiny version line, and a 40px offline chip.
- Soft amber offline banner with status chip and multiline explanation.
- Two large KPI cards (cache MB, pending inspections).
- Section header with an inline paused-state label.
- Active upload card with progress bar, percentages, and two metrics separated by a vertical divider.
- Queued job cards with icon, title, job/vehicle meta, `Queued` state and size.
- Full-width retry CTA + retry cadence note.
- Floating 4-item bottom navigation.

Mapping:
- `OfflineBanner` — closest match, but ours is a one-line banner with a message; no amber card, no chip, no cache metrics.
- `StatusChip` — `No Signal`, `Standby`, `Queued`, `Store Active`.
- `Card`/`AppCard` + `AppListTile` — queued job rows, active upload shell.
- `LoadingSkeleton` — no skeleton shown.
- `AppButton` — Retry Sync Now.
- `LinearProgressIndicator` — progress bar exists in Flutter, but the design's labelled 6px bar is custom.
- KPI stat cards — no equivalent.
- Transfer-speed/two-metric row — no equivalent.
- Floating bottom nav — **no equivalent** in `technician_router.dart` (routes are pushed pages; no shell/nav bar).

## 5. Assets

16 assets, all individual SVGs; no composed SVG, no raster (export warning confirms no composed groups).
- Icons: back, no-signal/offline, cache/database, pending/clock, upload, transfer speed, pending jobs, retry/sync, shield (header), avatar, and nav icons (intake/document, fleet/van, sync/refresh, profile/person).
- **No photo/avatar/vehicle raster.**

## 6. Content and data

| Visible text/label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Title | `Sync Status` | No | Current page title is "Sync queue" |
| Version line | `Local Engine v4.2 • Background sync` | No | **Invented software version**; forbidden to invent versions |
| Connectivity | `No Signal` | Partly: `offlineBanner` exists | No connectivity enum exposed |
| Banner title | `Working Offline — Saving Locally` | Close: `l10n.offlineBanner` | New copy |
| Store chip | `Store Active` | No | Not a real state; "local store" is implicit |
| Banner body | `All high-res vehicle capture tags and inspection checkpoints are safely cached...` | No | **"high-res ... tags" claim**; photo/annotation tags do not exist |
| Cache | `BUFFERED CACHE`, `148.6 MB Local` | No | No storage-size provider; **invented value** |
| Pending | `PENDING BATCH`, `3 Inspections`, `Awaiting link` | Partly: pending count exists | "Inspections" vs pending operations mismatch |
| Section | `Upload Queue`, `Auto-retry paused` | Partly: sync queue exists | Current sync auto-runs; "paused" is a new state |
| Active item | `Uploading Evidence Photos (4/12)` | Partly: evidence queue exists | No batch/photo-count aggregate |
| Job ref/vehicle | `Job #IN-88912 • 2024 Ford F-150 Lightning` | Partly: job reference/vehicle exist | Sample PII-free but invented |
| State | `Standby` | No | Current states: pending/conflict |
| Progress | `33% completed`, `8 items remaining` | No | No aggregate progress |
| Speed | `Transfer Speed 0.0 KB/s` | No | No transfer telemetry |
| Pending jobs | `Pending Jobs 2 in Line` | No | No job-level queue metric |
| Queued rows | `Telemetry Telematics & Checkpoints`, `18.4 MB`; `Body Schematics Pin Markups`, `6.2 MB` | No | **Invented job titles and sizes**; features (telematics, pin markups) do not exist |
| Retry | `Retry Sync Now` | Close: `l10n.syncNow` | — |
| Retry note | `Device will ping master servers every 60 seconds` | No | **Fixed retry interval claim**; current retry is exponential backoff (offline design §11) |
| Nav | `Intake`, `Fleet`, `Sync`, `Profile` | No | Current product nav is Jobs/Sync/Settings; no Fleet or Profile |

## 7. States shown / not shown

Shown: offline with no signal, auto-retry paused, one active/standby upload, queued items, retry CTA.
Not shown: online/synced empty state, loading, error/failed item, conflict, storage-full warning, sync in progress vs paused, successful completion, all-received state, RTL, 200% text.

## 8. Implied interactions

- Back returns to the job/previous screen.
- Retry Sync Now forces a sync; the note implies a 60s automatic retry.
- Tapping the active upload or a queued row may open the job/item.
- Bottom nav switches Intake/Fleet/Sync/Profile.
- `Auto-retry paused` may be tappable to resume (not shown).
- The scroll position is independent of the fixed nav.

## 9. Correspondence to current product

- Matches `client/apps/technician_app/lib/src/pages/sync_queue_page.dart`, route `/sync`, and `pendingOperationsProvider`. Current page: `SectionHeader`, `StatusChip` per operation (CONFLICT → danger/error; otherwise pending), `EmptyState` when empty, and a single `Sync Now` button. Data comes from `offline_store.dart` (`pendingOperations`, `pendingCount`) and `sync_service.dart`.
- **New UI/data**: storage totals, pending inspection count, active upload progress, transfer speed, per-job grouping/size, paused state, 60s cadence copy.
- **New state/new data/server**: current `SyncOperation` (`offline_models.dart`) exposes type, state, jobId, lastError only. No bytes/size/speed/progress totals. Adding them is state/model change, not UI-only.
- **Bottom nav is new.** `technician_router.dart` has no `ShellRoute`/`NavigationBar`; the app uses pushed pages. "Intake/Fleet/Sync/Profile" also conflicts with the documented Jobs/Sync/Settings tabs (`docs/phase-1/01-navigation-maps.md` §2.2).
- "Auto-retry paused" contradicts `sync_service.dart`/offline design, which retries with exponential backoff and resumes on app open.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **Invented version.** `Local Engine v4.2` is a fabricated product/engine version. Never invent versions/licences.
2. **Invented metrics.** `148.6 MB`, `3 Inspections`, `4/12`, `33%`, `8 items remaining`, `0.0 KB/s`, `2 in Line`, `18.4 MB`, `6.2 MB` are all sample values. They must come from real local metrics or be removed; do not ship hardcoded numbers.
3. **False state claims.** `Auto-retry paused` and "ping master servers every 60 seconds" contradict the documented exponential-backoff design and imply guaranteed background delivery (the design explicitly says not to promise background delivery on iOS).
4. **"High-res ... tags" claim.** The banner claims capture tags are cached; there is no annotation/tag model. Do not claim data exists.
5. **Navigation mismatch.** `Intake / Fleet / Sync / Profile` introduces a Fleet/Profile surface that does not exist in the technician app and renames documented tabs (Jobs/Sync/Settings). This is a navigation/IA change, not UI-only.
6. **Colour/radius drift.** `#006C49`/`#10B981`, amber `#F59E0B`/`#B45309`, `#FFF5EB`, 32px radii, 20px spacing are not in `tokens.dart`. The offline banner should use `OfflineBanner`/status tokens, not a bespoke amber card.
7. **No "submitted" before receipt.** The screen must keep the product's distinction: `LOCAL_ONLY`, `QUEUED`, `UPLOADING`, `RECEIVED`, `FAILED`, `CONFLICT`. `Standby`/`Queued` are not enough; the final states and per-item labelling must match §3.5 of the design system.

## 11. Open questions / could not verify

- Where do cache size, transfer speed and progress come from? No provider/model exposes them today.
- Is "Auto-retry paused" a real state the technician can toggle, or decorative copy?
- Should pending be counted as inspections, items, or operations? The card says "3 Inspections" while the queue shows operation-level rows.
- Is the bottom nav intended to replace the documented Jobs/Sync/Settings tabs, or is this a different app shell?
- Are "Telemetry" and "Body Schematics Pin Markups" real job types/features? Neither exists in the current product.
- What is the actual retry policy (60s vs exponential backoff)?
- RTL, Arabic, 200% text, and conflict/failed rows were not exported and could not be verified.
