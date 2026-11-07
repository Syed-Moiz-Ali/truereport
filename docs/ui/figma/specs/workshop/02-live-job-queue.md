# Screen 2 — Live Job Queue (Workshop Admin)

- Figma screen 2 "Live Job Queue", node `1:529`.
- Export folder (offset note): `docs/ui/figma-export/Workshop_admin_figma/screens/03_2._Live_Job_Queue/` — folder `03_2` = screen 2.
- Frame: **1280 × 1125 px** (width 1280 confirmed; desktop web, ≥1200 breakpoint). Background `#FFFFFF`.
- Sources read: `2._Live_Job_Queue.json` (developerSummary, nodes), `2._Live_Job_Queue@2x.png` (viewed as image), `assets/manifest.json` (25 assets), existing spec `docs/ui/figma/specs/workshop_admin/03-live-job-queue.md` (measurements reused), `docs/ui/figma/f1-token-api.md`, `docs/ui/figma/tokens.md`.
- Owner rules: O3 (1280 as drawn; tablet/phone derived, no fidelity claim), O6 (no "pending review / approve / sign off" wording — replacements below use raw statuses mapped to plain wording).

## 1. Node-level layout

- Root `1:529` fixed 1280×1125, VERTICAL. Rail `1:802` 96×1101 at x=0; main `1:531` 1184 px at x=96, padding 80/40/48/40; floating header `1:779` 1184×80 with blur (`#FFFFFFE5`, blur 48).
- Content `1:532` 1104×997:
  1. Title/header row (`1:533`–`1:561`, 1104×107, 40 bottom margin): eyebrow pill "REAL-TIME DISPATCH" + 32 px title "Live Job Queue" (`32/38 w800 -0.8`) + subtitle; right: stat card 279.9×64 (two metrics split by 1 px divider: "ACTIVE BAYS 06/08", "AVG TURNAROUND 42m") + primary "+ New Job" button 157.1×56.
  2. Filter/sort row (`1:563`, 1104×48, 32 bottom margin): segmented pill "All (12) / In Progress (4) / Pending Review (3) / Completed (5)" + right-aligned "Bay Order" tonal pill (`1:574`) + 40×40 filter icon button (`1:579`).
  3. Job list (`1:582`, 1104×672, 24 gap): four article cards (`1:583`, `1:629`, `1:674`, `1:720`), each 1104×150, radius 24, padding 32. Row order: 80×80 rounded vehicle image (`1:587`) | title/status/VIN/customer block | initials avatar 40×40 + tech name + bay | progress-or-review-or-slot block | 48×48 chevron button. Only 4 rows drawn though filter says "All (12)" — list clipped/scrollable, no scroll indicator visible.
  4. Status/footer strip (`1:767`, 1104×50, radius 16, `#F4F3F899`): live-sync dot + "Live sync active. Updated 4 seconds ago." left; "Export Daily Log", "Batch Reassign", "Bay Schedule Matrix →" right (48 top margin).
- Fixed desktop widths; no mobile variant in export.

## 2. Colours, type, shadow, spacing (observed)

- Colours: `#5E5D69` 42, `#1A1B1F` 27, `#F4F3F8` 22, `#FFFFFF` 16, `#10B981` 10 (progress fill, "+ New Job", initials), `#E9E7ED` 4 (bullet separators), `#006C49` 2, `#B45309` 2 ("In Progress" on `#FFFBEB`), `#EEEDF3` 2, `#FFFBEB` 2, `#3C4A42` 1, `#BA1A1A` 1 (review flag dot), `#C2410C` 1 ("Pending Review" on `#FFF7ED`), `#FFF7ED` 1, `#FFFFFFE5`/`#F4F3F899` overlays. No linked styles/variables. AA notes: white on `#10B981` ≈ 2.5:1 (fail — A2: emerald fill takes ink label, not white); initials in `#10B981` on tonal ≈ 2.3:1 (fail at 12 px).
- Type: Plus Jakarta Sans only. 66 text nodes: SemiBold 600 ×35, Bold 700 ×14, Regular 400 ×10, Medium 500 ×5, ExtraBold 800 ×1, SemiBold Italic 600 ×1. Sizes 11 ×24, 12 ×18, 13 ×14, 22 ×4 (job titles 22/28 w700), 16 ×3, 14 ×2, 32 ×1 (page title). Status chips 11/14 w600 (B1: ship ≥12). VIN in normal sans, not mono/LTR-marked. No Arabic sample.
- Radii: 24 (article cards), 16 (thumbs, footer, primary button, sort pills), 9999 (filter pills, avatars, chevrons, progress). Card shadow `0 2 8 rgba(0,0,0,.016)` + `0 14 40 rgba(0,0,0,.043)` (shared two-layer token); filter track inner shadow `0 2 4 rgba(0,0,0,.05)`. No card strokes. Spacing dominants 12/24/32/4/6/16/8; 24 between cards.

## 3. Components used (Figma → design_system)

| Figma pattern (node) | design_system cover | Verdict |
|---|---|---|
| Floating header (`1:779`) | `AdminTopBar`/`AppBar` (`admin_chrome.dart`) | NEW composite (same chrome as screen 1) |
| Icon rail (`1:808`) | `AdminSidebar` rail / `NavigationRail` | Covered (restyle) |
| Status filter segmented control (`1:564`) | `AppSegmentedControl` (`chips.dart`) | Covered |
| Sort pill + filter icon (`1:574`, `1:579`) | `AppButton` tonal + `AppIconButton` (`buttons.dart`) | Covered |
| Job article card (`1:583` etc.) | `AppCard` + `AppListTile` (`cards.dart`, `lists.dart`); current `JobsTab` uses Card + AppListTile without image/metrics | NEW composition (1104×150 article card) |
| Status chip (`1:593` etc.) | `StatusChip` (`chips.dart`) | Covered (add neutral/info mappings; O6 wording) |
| Initials avatar (`1:610`) | `CircleAvatar` in current code; `FxAvatar`/`TechnicianAvatar` in kit | Covered |
| Progress bar (`1:621`) | `AppCoverageBar` (`progress.dart`) | Covered |
| Chevron icon button (`1:626`, 48×48) | `AppIconButton` | Covered |
| Live-sync strip (`1:767`) | `OfflineBanner` (`states.dart`) closest, but inverse (always-online claim) | NEW (or omit — no live sync exists) |

## 4. Assets

- Manifest: 25 assets — 19 individual SVGs + 2 composed (`Nav-1_808`, `Aside-1_802`) + **4 rasters** (`image-1..4`, kind `raster`, role `image`, `image/jpeg`): 80×80 rounded **vehicle photographs** used as thumbnails. Provenance/licence not stated in export — must not bundle as app assets without a licence decision; neutral placeholder (initial/icon tile) required. All other assets 7–15 px icons.

## 5. States

- Shown: active filter "All (12)"; three status variants + Scheduled; assigned/unassigned; progress 65/30 %; review-items flag; live-sync success.
- NOT shown: empty queue, no active bays, loading skeleton, error/retry, offline, pagination/load-more (8 of 12 undrawn), long names, 200 % text, RTL/Arabic, dark theme (light-only), mobile/tablet card fallback, disabled/failed sync, zero-result filter, cancelled/finalized rows. Current `JobsTab` already has `LoadingSkeleton`/`ErrorState`/pull-to-refresh (`jobs_tab.dart:109-120`) — keep for every new state.

## 6. Element → data mapping (O6 applied)

Existing: `GET /api/v1/workshop/jobs?search=&status=` (`WorkshopJobController.list`); statuses `DRAFT/SCHEDULED/ASSIGNED/IN_PROGRESS/READY_TO_FINALIZE/FINALIZED/CANCELLED` with `jobStatusLabel`/`jobStatusTone` (`jobs_tab.dart:10-27`); `POST /workshop/jobs` (create); `POST /workshop/jobs/{id}/assign`; `WorkshopJob` fields (reference, customerName, vehicleMake/Model/Vin, assignedTechnicianId/Name, scheduledAt, templateName). Current screen: `JobsTab` — searchable list, horizontal status chips, Card + AppListTile + StatusChip, pull-to-refresh, no images/bays/progress/stats/sort/footer.

| Figma element | Mapping / verdict |
|---|---|
| Eyebrow "REAL-TIME DISPATCH" + subtitle | No live dispatch — copy DATA GAP; subtitle maps to existing queue concept |
| Stats "ACTIVE BAYS 06/08", "AVG TURNAROUND 42m" | DATA GAP — no bay/turnaround data; OMIT |
| "+ New Job" | Exists: `JobsTab._openCreate` → `JobFormPage` (`jobs_tab.dart:179`) / `POST /workshop/jobs` |
| Filters "All (12) / In Progress (4) / Pending Review (3) / Completed (5)" | PARTLY: counts derivable client-side from `jobs()`; "In Progress" = `IN_PROGRESS`; "Completed" = `FINALIZED` (read-only). "Pending Review" LOCKED-RULE conflict (O6) — neutral replacement: `READY_TO_FINALIZE` chip ("Ready to finalize"), same slot/style |
| Sort "Bay Order" + filter button | DATA GAP — no bay entity; no sort/filter API beyond status/search; OMIT or keep search + status chips only |
| Row 1 "Porsche 911 Carrera S / In Progress / VIN WP0AB2A91LS / Alexander Wright / Marcus Vance (Bay 04) / 65%" | PARTLY: title/VIN/customer/assignee from `WorkshopJob` + `jobs(search)`. Bay + 65 % progress DATA GAP (no progress field — OMIT progress or derive nothing; do not invent) |
| Row 2 "…Pending Review… REVIEW ITEMS 2 Flags Marked / Fleet Logistics Inc / Bay 02" | LOCKED-RULE conflict (O6 review wording + flags model absent); company-customer exists as free-text `customerName` but flags/bay/review-state DATA GAP — neutral replacement required |
| Row 3 "Renault Megan 3 E-Tech / In Progress / 30%" | PARTLY (same as row 1); typo "Megan" vs "Mégane" — use `vehicleMake/Model` verbatim, do not invent accent |
| Row 4 "BMW i4 M50 Gran Coupe / Scheduled / Unassigned / SLOT TIME 14:30 Today" | PARTLY: `SCHEDULED` + `scheduledAt` exist; bay absent; date format must use locale formatting (no hardcoded "14:30 Today") |
| Footer "Live sync active. Updated 4 seconds ago." | DATA GAP — no sync channel; OMIT (keep `OfflineBanner` offline pattern only) |
| Footer "Export Daily Log" | DATA GAP — export pending per A03 spec; OMIT |
| Footer "Batch Reassign" | DATA GAP — no batch endpoint (single `POST …/assign` only); OMIT (no multi-select affordance drawn either) |
| Footer "Bay Schedule Matrix →" | DATA GAP — OMIT |
| Vehicle photos (4 JPG) | No image field on `WorkshopJob`; licence unknown — replace with neutral tile/initials |
| Customer names + partial VINs in queue | Internal-only PII boundary: allowed in admin list from existing fields, must not leak to public report; partial VIN still identifying with name |

## 7. Classification

**Matches existing feature (JobsTab) — UI work only for the restyle subset; needs new data or server change for deltas; conflicts with locked rule as drawn (O6).** Shippable without server change: search + raw-status filter chips + job cards (reference/customer, vehicle, template, `StatusChip`, assignee, chevron → detail/assign) + "+ New Job" → existing form. Bays, progress %, flags, review states, turnaround, live sync, export, batch reassign, bay matrix, photos all need new data/server changes or omission; "Pending Review/flags" wording must be replaced (O6).

## 8. New shared components from this screen (vs already built)

1. Job article card (1104×150, image tile + 4-column row + chevron) — NEW composition (`AppCard` + `AppListTile` + `StatusChip` + `AppCoverageBar`).
2. Segmented status filter with counts — covered (`AppSegmentedControl` + existing chip row pattern).
3. Footer live-sync/action strip — OMIT (no data); no build.
4. Vehicle thumbnail — OMIT Binder (no images/licence); neutral tile instead.

## 9. Could not verify

- Whether "Pending Review" was meant as `READY_TO_FINALIZE` (then a rename fixes O6) or a new reviewer state (then banned).
- Denominator/definition of 65 %/30 %, "2 Flags Marked", 42 m average, "Updated 4 seconds ago".
- Bay entity shape/count (06/08 vs 12/14 on screen 1 — inconsistent).
- Pagination/virtualization for 12+ jobs; completed-row read-only rule (can a `FINALIZED` job be reassigned? server rejects — UI must mark read-only).
- Raster licences/sources for the 4 vehicle JPGs.
