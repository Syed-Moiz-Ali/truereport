# Screen 4 — Assign Technician (Workshop Admin)

- Figma screen 4 "Assign Technician", node `1:821`.
- Export folder (offset note): `docs/ui/figma-export/Workshop_admin_figma/screens/04_4._Assign_Technician/` — folder `04_4` = screen 4 (only screen where slot = number).
- Frame: **1280 × 1120 px** (width 1280 confirmed; desktop web, ≥1200 breakpoint). Background `#FFFFFF`.
- Sources read: `4._Assign_Technician.json` (developerSummary, nodes), `4._Assign_Technician@2x.png` (viewed as image; centred modal sharp, dispatch board defocused behind), `assets/manifest.json` (19 assets), existing spec `docs/ui/figma/specs/workshop_admin/04-assign-technician.md` (measurements reused), `f1-token-api.md`, `tokens.md`.
- Owner rules: O3 (1280 modal as drawn; <600 px derived sheet, no claim), O6 (no review/approve wording — none in modal; "certified specialist" handled as certification-claim conflict below).

## 1. Node-level layout

- Root `1:821` 1280×1120. Rail `1:911` 96×1072; main `1:823` 1184×1120, padding 80/40/786/40. Behind modal: defocused dispatch board — title "Service Bay Diagnostics" with shift/bay pills (`1:825`), three 352×166 repair-order cards, 24 gap (`1:836`).
- Modal layer:
  - Scrim `1:930` 1280×1072, `#FFFFFFB2`, blur 24 (48 px shorter than the 1120 frame — export artefact, build full-cover barrier).
  - Card `1:931` **512×660 at (384, 206)**, radius 24, shadow `0 24 64 rgba(0,0,0,.08)`.
  - Header `1:932` 512×144 (padding 36/32/12/32): ticket pill "REPAIR TICKET #1042" + "Stage 01", 22 px title "Assign Technician for Job #1042" (`1:942`, 22/28 w700), 2-line subtitle (`1:945`, 14/20 w500), 40×40 close (`1:947`).
  - Vehicle strip `1:950` 512×88 (inner 448×64, radius 16): 36 px icon + two text lines ("Transit 350 High Roof / 3.5L EcoBoost • Brake System Recall") + white pill "Est. 2.5h".
  - Tech list `1:963` 512×304 (padding 12/32, 14 gap): three cards 448×80/80/92, radius 16; selected = translucent emerald overlay `#10B9811A` + 28 px filled radio + check; avatar 48 circle + skill chip + two-line meta.
  - Actions `1:1018` 512×116 (padding 24/32/36/32): text Cancel 94.9×50 + primary Confirm 337.1×56, 16 gap.
- Centred fixed-width modal, not a bottom sheet; base blurred/inert.

## 2. Colours, type, shadow, spacing (observed)

- Colours: `#5E5D69` 26, `#FFFFFF` 19, `#F4F3F8` 18, `#1A1B1F` 12, `#10B981` 8 (radio, Confirm, overlay base), `#006C49` 5, `#E1DEEC` 4 (avatar bg), `#1B1B25` 3 (avatar glyph), `#EEEDF3` 3, `#002113` 2 (text on mint chip), `#3C4A42` 2, `#6FFBBE` 2 (skill chip bg), `#DAD9DF` 2 (inactive radio), `#10B9811A` 1, `#62616D` 1 (ticket pill), `#BA1A1A` 1 ("Unassigned"), `#FFFFFFB2` scrim, `#FFFFFFE5` header. Raw fills. AA: white "Confirm Assignment" on `#10B981` ≈ 2.5:1 (A2: ink label on emerald, or deep-green + white). Radios 28×28 and close 40×40 below 44/48 (B2/I3: keep visuals, enlarge hit areas). Skill chip 11 px → ship ≥12 (B1).
- Type: Plus Jakarta Sans only. 39 text nodes: SemiBold 600 ×18, Bold 700 ×11, Regular 400 ×7, Medium 500 ×2, ExtraBold 800 ×1. Sizes 11 ×15 (ticket/stage/skill — ship 12), 13 ×8 (meta), 16 ×6 (names/vehicle), 12 ×4, 14 ×4 (subtitle/buttons 14/18 w700 CENTER), 22 ×1, 32 ×1 (base title).
- Radii: 24 (modal), 16 (strip/cards/buttons), 48 (vehicle icon), 9999 (avatars/radios/chips). Selection = tint + filled radio + check (good: not colour-alone). Spacing dominants 16/24/12/8/2/32; list gap 14; modal padding 32.

## 3. Components used (Figma → design_system)

| Figma pattern (node) | design_system cover | Verdict |
|---|---|---|
| Centred modal dialog (`1:931`) | `showAppConfirmDialog`/`showDialog` (`overlays.dart`); current assign uses `showAppBottomSheet` (`jobs_tab.dart:268`) | Covered (switch sheet → dialog on wide; keep sheet as O3 derived mobile) |
| Scrim + blur (`1:930`) | Dialog barrier (no blur) | Covered |
| Close icon button (`1:947`) | `AppIconButton` | Covered |
| Vehicle snapshot strip (`1:951`) | No equivalent | NEW composition |
| Selectable radio card (`1:964`) | `FigmaResultOption` closest; `AppListTile` + `Radio` compose | NEW composition (workshop tech card) |
| Avatar w/ icon glyph (`1:968`) | `FxAvatar`/`TechnicianAvatar` / `CircleAvatar` | Covered |
| Skill chip (`1:975`) | `StatusChip` / `AppFilterChip` (`chips.dart`) | Covered (neutral mapping; skill data gap) |
| Primary/text actions (`1:1019`, `1:1021`) | `AppButton` primary/text | Covered |
| Background repair-order cards (`1:837`) | `AppCard` + `AppListTile` | Covered |

## 4. Assets

- Manifest: 19 assets — 17 individual SVGs + 2 composed (`Nav-1_917`, `Aside-1_911`). **0 rasters.** Three "avatars" are 48 px circular icon placeholders (person glyph), not photos. Vehicle icon 36 px; rest 9–25 px icons. No vehicle photo/plate/VIN image; no licence question.

## 5. States

- Shown: one preselected card ("selected by default" layer name) with tint + green check; unselected/busy/available cards; inactive radios; base "Unassigned" job.
- NOT shown: no active technicians, disabled/transferred tech, already-assigned/finalized job, loading staff, error, submitting/disabled buttons, success confirmation, reason entry, long names, 200 % text, RTL/Arabic, dark theme (light-only), mobile sheet, keyboard focus. Current `_assign` passes `reason=null` (`jobs_tab.dart:315`); A06 spec wants a reason field — modal shows none (audit-completeness gap, add optional reason input in same style).

## 6. Element → data mapping

Existing: `POST /api/v1/workshop/jobs/{id}/assign` (`WorkshopJobController.assign`), `AssignJobRequest(technicianId, reason?)`; server enforces active TECH role, same workshop, rejects finalized/cancelled, records `JobAssignment` history (`GET …/assignments`). Client: `JobsTab._assign` (`jobs_tab.dart:266-315`) opens bottom sheet, filters ACTIVE TECHNICIANs, shows `displayName` + `emailMasked`, calls `assignJob(job.id, selected, null)`. `StaffMember` = userId/displayName/emailMasked/role/status only (`models.dart:465`). `WorkshopJob` carries `assignedTechnicianId/Name`, `reference` (`JOB-XXXXXXXX`), vehicle fields.

| Figma element | Mapping / verdict |
|---|---|
| Base header "ACTIVE DISPATCH BOARD / Service Bay Diagnostics / Shift A • Morning Inflow / 12 Bays Operational" | DATA GAP (shift/bay operational state unmodelled) — base is inert backdrop; omit data |
| Base cards "#1040 • Express / In Progress… VIN: 9AU4810294J" etc. | PARTLY: job/vehicle/VIN from `WorkshopJob`; "Express/Heavy" tags, stage, bay DATA GAP. Reference must stay `JOB-…` (no "#1042" renumber — do not invent ticket numbers) |
| Modal ticket "REPAIR TICKET #1042 / Stage 01" | DATA GAP ("Stage 01" unmodelled) + reference-format conflict — use existing `reference` verbatim |
| Title/subtitle "Assign Technician for Job #1042 / Select an available certified specialist…" | Assignment exists. "certified specialist" LOCKED-RULE conflict (certification claim) — neutral replacement: "Select an available technician for {vehicle}" same slot/style |
| Vehicle strip "Transit 350 High Roof / 3.5L EcoBoost • Brake System Recall / Est. 2.5h" | Trim/engine/recall/estimate DATA GAP; "Brake System Recall" is an authoritative recall claim (never invent) — strip shows existing `vehicleMake/Model` (+ `scope`/template name) only; omit recall + estimate |
| Tech rows "David Vance / Brakes L2 / 1 Active Job • Bay 02" etc. | PARTLY: name/role/status from `staff()`. Skill ("Brakes L2", "Powertrain", "Lead Tech"), per-tech active-job counts, bay, availability DATA GAP — show `displayName` + `emailMasked` (current) in new card style; skill chips only if a qualification model is approved, else omit |
| "Lead Tech" levels | Certification-claim conflict (same as above) — omit unless verified qualification source exists |
| Actions Cancel / Confirm Assignment | Exist (`assignJob`); add optional reason field (A06 audit completeness) in same style |
| Staff full names in modal; vehicles/VINs behind | Admin-only boundary OK; modal must not be reused in public report |

## 7. Classification

**Matches existing feature (assign flow) — UI work only for the modal restyle; needs new data for extras.** Shippable without server change: centred 512 dialog (wide) / bottom sheet (derived <600 px) listing ACTIVE technicians (`displayName` + `emailMasked`), single-select with tint + radio + check, vehicle strip from existing job fields, Cancel/Confirm → existing `assignJob` (+ optional reason input), all loading/error/submitting/success states. Skills, bays, workload counts, availability, estimates, stages, ticket renumbering, recall claims all need new data or omission; "certified/Lead Tech/Brakes L2/Powertrain" wording must be neutralised.

## 8. New shared components from this screen (vs already built)

1. Centred 512 workshop dialog pattern — covered (`showAppConfirmDialog`/`showDialog`; add 512×r24 workshop styling).
2. Vehicle snapshot strip — NEW composition.
3. Technician radio card (avatar + chip + meta + radio) — NEW composition (`AppListTile` + `StatusChip` + `Radio`).
4. Right drawer (screen 3) + admin chrome (screens 1–2) complete the shared set: **4 new shared builds total** — (a) admin rail + floating header chrome, (b) KPI/stat card, (c) job article/activity card, (d) right drawer + centred dialog + radio/option cards + telemetry donut/strip. Everything else composes existing `AppButton/AppTextField/AppCard/StatusChip/AppSegmentedControl/AppDataTable/AppListTile/AppProgressRing-AppCoverageBar/EmptyState/ErrorState/LoadingSkeleton/OfflineBanner`.

## 9. Could not verify

- Source of skills/levels/availability ("certified", "Brakes L2", "Lead Tech", "Powertrain"); why David preselected over least-loaded.
- Whether assignment also assigns a bay (independent or coupled).
- "Est. 2.5h"/recall lookup scope (treated out-of-scope; omitted).
- Reassignment reason required or optional (A06 says included; current code sends null).
- Search/filter + disabled-tech representation in picker.
- Reference format `#1042` vs `JOB-…` (kept `JOB-…`).
- Dialog vs route (`/jobs/:jobId/assign`) and <600 px behaviour (O3 derived sheet).
- Scrim 1072-vs-1120 48 px artefact (build full-cover barrier).
