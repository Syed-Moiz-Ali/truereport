# 04. 4. Assign Technician

- App: Workshop Admin
- Figma node: `1:821`
- Frame: 1280x1120 px (desktop web; >=1200 breakpoint)
- Export folder: `screens/04_4._Assign_Technician`
- Sources read: `4._Assign_Technician.json` (developerSummary, nodes), `4._Assign_Technician@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html` header, `package-manifest.json`
- Export/screen-number mismatch: this is export slot **04** and also Figma screen **4**. Export order still differs from the screen numbering sequence (slot 01 = screen 3; slot 02 = screen 1; slot 03 = screen 2; slot 06 = screen 7).
- Confidence: high for modal geometry/text; medium for product mapping because skill, availability, bay and job-count data are absent from `StaffMember`.

## 1. Purpose

Assign an available technician to one intake job (#1042, 2024 Ford Transit) from a centred modal. It shows the job's vehicle/spec, up to three technicians with skill tags and workload, a single selected state, and Cancel/Confirm actions.

## 2. Layout structure

Root `1:821` 1280x1120. Rail `1:911` 96x1072; main `1:823` 1184x1120 with padding 80/40/786/40. Behind the modal is a defocused dispatch board: title "Service Bay Diagnostics" with shift/bay pills (`1:825`), and three 352x166 repair-order cards with 24 px gap (`1:836`).

The modal layer:
- Scrim `1:930` 1280x1072, `#FFFFFFB2`, blur 24. It covers the full width but is 48 px shorter than the 1120 frame.
- Card `1:931` 512x660 at (384, 206), radius 24, shadow `0 24 64 rgba(0,0,0,.08)`.
- Header `1:932` 512x144, padding 36/32/12/32: ticket pill + "Stage 01", 22 px title, 2-line subtitle, 40x40 close.
- Vehicle strip `1:950` 512x88: inner 448x64, radius 16, icon 36, two text lines, "Est. 2.5h" white pill.
- Technician list `1:963` 512x304, padding 12/32, 14 px gap: three cards 448x80/80/92, radius 16; the selected card uses a translucent emerald overlay `#10B9811A`; avatar 48 circle, skill chip, two-line meta, 28 px radio.
- Action area `1:1018` 512x116, padding 24/32/36/32: text Cancel 94.9x50 and primary Confirm 337.1x56; 16 px gap.

The modal is fixed width, centred horizontally, and not a bottom sheet. The base screen is blurred/inert.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx fill count)

| Hex | Count | Usage |
|---|---:|---|
| `#5E5D69` | 26 | Secondary text, subtitle, meta |
| `#FFFFFF` | 19 | Modal, cards, header, unselected radio knob |
| `#F4F3F8` | 18 | Close, avatar? (base), chips, tonal controls |
| `#1A1B1F` | 12 | Titles, selected name, icons |
| `#10B981` | 8 | Active radio, Confirm button, selected overlay base |
| `#006C49` | 5 | Green icons/labels |
| `#E1DEEC` | 4 | Circular avatar background |
| `#1B1B25` | 3 | Avatar glyph |
| `#EEEDF3` | 3 | Shimmer/neutral surfaces |
| `#002113` | 2 | Text on mint skill chip |
| `#3C4A42` | 2 | "BAY ACTIVE"/"Stage 01" |
| `#6FFBBE` | 2 | Skill chip background |
| `#DAD9DF` | 2 | Inactive radio dot |
| `#10B9811A` | 1 | Selected card overlay |
| `#62616D` | 1 | "#1042 • Intake" pill text |
| `#BA1A1A` | 1 | "Unassigned" |
| `#FFFFFFB2` | 1 | Scrim |
| `#FFFFFFE5` | 1 | Blurred header |

### Typography

Plus Jakarta Sans only. 39 text nodes: SemiBold 600 x18, Bold 700 x11, Regular 400 x7, Medium 500 x2, ExtraBold 800 x1.
Sizes: 11 x15, 13 x8, 16 x6, 12 x4, 14 x4, 22 x1, 32 x1.

| Role | Style | Example |
|---|---|---|
| Base page title | 32 / 38, 800, -0.96 px | `1:830` |
| Modal title | 22 / 28, 700, -0.55 px | `1:942` |
| Tech name / vehicle | 16 / 22, 700, -0.16 px | `1:974`, `1:958` is 12/15 |
| Modal subtitle | 14 / 20, 500, -0.07 px | `1:945` |
| Meta | 13 / 18, 400 | `1:979` |
| Skill chip | 11 / 14, 600, +0.44 px | `1:976` "Brakes L2" |
| Ticket/stage | 11 / 14, 600/500 | `1:937`, `1:940` |
| Buttons | 14 / 18, 700, -0.14 px, CENTER | `1:1020`, `1:1023` |

### Radii, shadows/elevation, strokes, spacing

- Radii: 24 (modal), 16 (vehicle strip, tech cards, buttons), 48 (vehicle icon circle), 9999 (avatars/radios/chips).
- Shadows: modal `0 24 64 rgba(0,0,0,.08)`; selected card overlay is flat; base cards use the 2/14 px shadow pair.
- No borders; selection is a tint + filled radio + check.
- Spacing: 16 x25, 24 x22, 12 x18, 8 x17, 2 x11, 32 x11; list gap 14; modal padding 32.

## 4. Components

| Figma pattern | Node | Our design-system equivalent |
|---|---|---|
| Centred modal dialog | `1:931` | `ConfirmDialog`/`showDialog` (current assign is a bottom sheet) |
| Scrim + blur | `1:930` | Dialog barrier (no blur) |
| Close icon button | `1:947` | IconButton |
| Vehicle snapshot strip | `1:951` | No equivalent |
| Selectable radio card | `1:964` | No equivalent; `AppListTile` + `Radio` would need composition |
| Avatar with icon glyph | `1:968` | `CircleAvatar` (current) |
| Skill chip | `1:975` | `StatusChip`/Chip |
| Primary/tonal actions | `1:1019`, `1:1021` | `AppButton` text/primary |
| Repair-order cards (background) | `1:837` | `AppListTile`/Card |

## 5. Assets

19 assets: 17 individual SVGs, 2 composed SVGs (`Nav-1_917`, `Aside-1_911`), **0 rasters**. Three "avatars" are 48 px circular icon placeholders with a person glyph, not photos. Vehicle icon 36 px; everything else 9–25 px icons. No vehicle photo, plate or VIN image.

## 6. Content and data

| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Base header | "ACTIVE DISPATCH BOARD", "Service Bay Diagnostics", "Shift A • Morning Inflow", "12 Bays Operational" | No | Shift/bay operational state not modelled |
| Base cards | "#1040 • Express / In Progress / Audi e-tron GT / VIN: 9AU4810294J"; "#1041 • Heavy / Inspection / Freightliner M2"; "#1042 • Intake / Unassigned / 2024 Ford Transit / VIN: 1FTBR1Y80RKA391" | Partly | Job/vehicle/VIN exist; bay, stage, express/heavy tags, "12 Bays Operational" do not |
| Modal ticket | "REPAIR TICKET #1042", "Stage 01" | No | Current `reference` is `JOB-XXXXXXXX`, not a repair-ticket number; no stage |
| Modal title/subtitle | "Assign Technician for Job #1042"; "Select an available certified specialist for 2024 Ford Transit" | Partly | Assignment exists; "certified specialist" is a claim |
| Vehicle strip | "Transit 350 High Roof", "3.5L EcoBoost • Brake System Recall", "Est. 2.5h" | No | Trim/engine/recall/estimate are not fields; recall is an authoritative claim |
| Tech 1 | "David Vance", "Brakes L2", "1 Active Job • Bay 02", selected | Partly | Name/role/status exist; skill, job count, bay do not |
| Tech 2 | "Marcus Vance", "Lead Tech", "3 Active Jobs • Bay 04" | Partly | Same gaps; "busy" is implied by 3 active jobs but not stated |
| Tech 3 | "Sarah Jenkins", "Powertrain", "0 Active Jobs • Bay 01 (Available)" | Partly | Same gaps; availability is derived from job count, not a field |
| Actions | "Cancel", "Confirm Assignment" | Yes (assign) | No reason field though A06/assign API accept one |

Names are staff PII; no customer name/contact is shown in the modal. VINs are partial (11–16 characters).

## 7. States shown / not shown

Shown: selected card (tinted + green check), unselected/busy/available cards, inactive radio; base "Unassigned" job; modal default with one preselection ("selected by default" per layer name).
Not shown: no active technicians, technician disabled/transferred, job finalized/already assigned, loading staff, error, submitting/disabled buttons, confirmation success, validation, reason entry, long names, 200% text, RTL/Arabic, dark theme, mobile sheet, keyboard focus.

## 8. Implied interactions

Select a technician (single-select); Cancel/close; Confirm Assignment; backdrop dismiss. The base cards and header are blurred and not operable. No search, no filter, no "show unavailable", no reason/audit note, no confirmation of reassignment consequences.

## 9. Correspondence to current product

- Spec: A06 Assign / reassign `/jobs/:jobId/assign` (`docs/phase-1/02-screen-inventory.md:66`) — searchable technician picker with status, current assignment, reason; assign/reassign/confirm; only own workshop.
- Current UI: `_assign` in `JobsTab` (`jobs_tab.dart:266`) opens a bottom sheet, filters ACTIVE TECHNICIANs, and shows only `displayName` + `emailMasked`. It calls `assignJob(job.id, selected, null)` — currently no reason.
- API/server: `POST /api/v1/workshop/jobs/{id}/assign`, `AssignJobRequest(technicianId, reason?)`; server enforces active TECH role in the same workshop, rejects finalized/cancelled, records `JobAssignment` history/audit.
- Verdict: **existing flow**, major visual redesign; new data needed for skills, bay, active-job counts, availability and estimate. "Certified/Lead Tech/Brakes L2/Powertrain" are not in `StaffMember`/`WorkshopMembership`.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"No certification/'verified by'/compliance claims."** Evidence: "certified specialist", "Lead Tech", "Brakes L2", "Powertrain" (skill levels presented as certifications). These are unsupported unless a verified qualification model exists.
2. **"Never invent measurements/results."** Evidence: "Est. 2.5h", "1 Active Job", "3 Active Jobs", "0 Active Jobs", "Stage 01", "12 Bays Operational", repair-ticket numbers. No source/model.
3. **"Never invent ... licences."** "Brake System Recall" is an authoritative recall claim; it must come from a verified source and be dated, not mock copy.
4. **"UI layer only; no API/model/validation/permission/state change."** Skills, bays, workload, availability, estimates and stage are new model/permission data; assignment itself already exists.
5. **A06 reason/audit gap.** The spec says the picker includes a reason; the modal has no reason field, and current code passes `null`. Reassignments are audited, but the UI cannot capture why. This is a UX/audit completeness issue.
6. **Tokens.** Raw hex; emerald/mint (`#10B981`, `#6FFBBE`, `#006C49`) not in current `AppTheme`; radii 16/24 beyond current tokens; selected-state overlay is a raw alpha fill.
7. **WCAG 2.2 AA.** White "Confirm Assignment" on `#10B981` is approx 2.5:1 (fails 4.5:1 and 3:1). 28x28 radio controls and 40x40 close are below the project's 44/48 minimum; skill chip 11 px. Selected state uses colour + check, which is good, but the check alone is small.
8. **Arabic RTL.** No Arabic; the modal is centred so mirrors less, but the vehicle icon/text order, arrows, and close position need RTL review. No long-name or bilingual name handling shown.
9. **Staff/customer data boundary.** Staff full names are shown; customer name is absent in the modal but the background shows vehicles/VINs. Admin-only, but the modal should not be reusable in the public report.

## 11. Open questions / could not verify

- Where do "certified", "Brakes L2", "Lead Tech", "Powertrain", "Lead Master" and levels come from? Are these approved qualifications or decoration?
- Is technician availability derived from active-job count, shift, or an explicit status? Why is David selected by default rather than the least-loaded/available?
- Are bay numbers real? Does assignment also assign a bay, or are they independent?
- Is "Est. 2.5h" a job estimate, a template target, or invented? Is a recall lookup in scope?
- Should reassignment require a reason (A06) and show current assignment/history?
- Should the picker search/filter, and how are disabled/transferred technicians represented?
- Are job references repairable as "#1042" or must they remain `JOB-…`?
- Is the modal a dialog or a route (`/jobs/:jobId/assign`)? What happens below 600 px?
- Why is the scrim 1072 high on a 1120 frame (48 px uncovered)?
