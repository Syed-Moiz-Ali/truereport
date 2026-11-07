# F3-0 Screen 5 — Staff Management (Workshop Admin)

- Export folder: `docs/ui/figma-export/Workshop_admin_figma/screens/05_5._Workshop_Staff_Management`
- Figma node: `1:1026` ("5. Workshop Staff Management"), 281 serialized nodes
- Frame (JSON `developerSummary.screen`): **1280×1048**, VERTICAL, bg `#FFFFFF`
- PNG: `5._Workshop_Staff_Management@2x.png` 2592×2096 px (≈1296×1048 @1x; +16 px bleed vs 1280 frame — export padding, per O3 use **1280** as drawn)
- Prior spec read (not edited): `docs/ui/figma/specs/workshop_admin/05-workshop-staff-management.md`
- C0 model: `docs/ui/figma/c0-admin-accounts-slot-sheet.md`
- Viewed PNG as image: yes

## 1. Node-level layout

- Root `1:1026` 1280×1048. Children: `Background 1:1027` 1280×1048 (left pad 96 for rail) → `Main 1:1028` 1184 wide at x=96 (padding 80/40/48/40) → `Content 1:1029` 1104×920, gap 32.
- `Header 1:1265` 1184×80 overlay at x=96 (`#FFFFFFE5` + shadow): `BAY ACTIVE · Shop Floor #04` pill, search pill `Search VIN, tech, job ticket...` (299×34), user `Marcus Vance / Lead Inspector` + avatar 32.
- `Aside 1:1288` 96×1030: logo 48, three 56×56 nav tiles, settings tile; active tile = Settings (emerald) — same shell as screens 6–8.
- Header row `1:1030` 1104×76: title `Workshop Staff` 32/800 + `LIVE ROSTER` pill + subtitle left; `+ Add Staff` 149.5×56 emerald right.
- Filter chips `1:1044` 1104×44, gap 12: `All Staff 8` (selected white) / `Technicians 5` / `Admins 3` / `Active Shift 6`.
- Metrics `1:1071` 1104×132, 3× 352×132 cards gap 24 pad 24 r24: Bay Utilization 87.5% / Shift Compliance 100% / EV Specialists 3 Leads, each 48×48 icon tile.
- Staff grid `1:1111` 1104×364: 3 cols × 2 rows, card w 346.7, col-gap 32, row-gap 8; card pad 28 r24; heights 190 (David, 2-line role) / 172 others. Per card: 56×56 lilac avatar tile + 16 px status dot, name 18/700, role 13/400, 32×32 toggle, bottom row skill chip(s) + logged-hours text. Elena card opacity 0.9.
- Banner `1:1247` 1104×112 (margin-top 16, tonal `#F4F3F8`, r24): icon 48 + `Auto-Shift NFC Badging Active` + terminal sentence + `Download Roster PDF` / `Shift Rules` buttons.

## 2. Components

| Figma pattern | Design-system map (`client/packages/design_system/lib/src/components/`) |
|---|---|
| Floating header / rail | `admin_chrome.dart` + `navigation.dart` (`AppBar`, `NavigationRail`); no BAY ACTIVE context chip |
| Filter chips w/ counts | `chips.dart` (`AppSelectableText`/`StatusChip`); count badge is new |
| Metric card | No equivalent (new `MetricCard` if approved) |
| Staff card + avatar + dot + toggle | `cards.dart` + `lists.dart` (`Card`+`AppListTile`); 32 px toggle + status dot are new |
| Skill tag | `chips.dart` (`Chip`/`StatusChip`) |
| Banner + roster/shift buttons | `states.dart` tonal card + `buttons.dart` (`AppButton` tonal/text) |

## 3. Assets

- `assets/manifest.json`: **27 assets — 25 individual SVGs + 2 composed** (`Nav-1_1294`, `Aside-1_1288`), **0 rasters**. Six staff "avatars" = same person-glyph vector on lilac tile (no photos). Rest 9–23 px icons.

## 4. Element → data mapping (EVERY visible string)

Source strings extracted from node `characters`; server/app paths cited, nothing invented.

| Figma element | Mapping |
|---|---|
| `Workshop Staff` / subtitle `Active diagnostic technicians...` | List screen exists: `client/apps/admin_app/lib/src/pages/staff_tab.dart` (`StaffTab`), `GET /api/v1/workshop/staff` → `StaffDto` (`server/.../identity/api/StaffController.java:37`). Subtitle word "Active" inaccurate (Elena off shift) — UI copy issue |
| `LIVE ROSTER` | DATA GAP — no live/roster concept |
| `+ Add Staff` | EXISTS (C0/O5): opens create-Technician for own workshop — `showCreateTechnicianDialog` in `staff_tab.dart:183`, `POST /api/v1/workshop/technicians` (`StaffController.java:43`). Figma button styling only; action itself matches |
| `All Staff 8 / Technicians 5 / Admins 3` | PARTIAL: `StaffDto.role/status` exist; counts derivable client-side; "8" inconsistent with 6 drawn cards — DATA GAP (counts) + content inconsistency |
| `Active Shift 6` | DATA GAP — no shift model/endpoint; count inconsistent (5 green dots) |
| `BAY UTILIZATION 87.5% / 4 of 5 active bays staffed` | DATA GAP — no bay entity/endpoint; invented measurement (LOCKED-RULE: never invent measurements) |
| `SHIFT COMPLIANCE 100% / All tickets logged & verified` | DATA GAP + LOCKED-RULE conflict — no compliance model; "verified" certification claim prohibited |
| `EV SPECIALISTS 3 Leads / High-voltage ready` | DATA GAP + LOCKED-RULE conflict — no qualification/EV field; certification claim prohibited |
| `David Vance / Senior Technician • Bay 02 / EV Certified / Level 4 / Logged 6h 12m` | Name→`displayName` EXISTS; role line/skills/level/bay/hours all DATA GAP; `EV Certified`/`Level 4` = certification claim conflict |
| `Marcus Vance / Lead Inspector • Bay 04 / Lead Master / Logged 7h 45m` | Name EXISTS; `Lead Inspector`/`Lead Master` read as manager layer — LOCKED-RULE conflict (only `WORKSHOP_ADMIN`/`TECHNICIAN` per `HierarchyService.java`, C0 slot sheet); bay/hours DATA GAP |
| `Sarah Jenkins / Diagnostic Tech • Bay 01 / OBD-II Specialist / Logged 5h 20m` | Name EXISTS; hardware/qualification claim + bay/hours DATA GAP |
| `Arthur Pendelton / Workshop Admin • Front Desk / Shop Ops / Logged 8h 00m` | Name+role EXISTS; `Front Desk`/`Shop Ops`/hours DATA GAP |
| `Liam O'Connor / Chassis Specialist • Bay 03 / Suspension / Logged 4h 10m` | Name EXISTS; skill/bay/hours DATA GAP |
| `Elena Rostova / Shop Floor Supervisor / Off Shift / Returns 08:00 AM` | Name EXISTS; `Supervisor` = manager-role conflict; shift schedule DATA GAP |
| Availability toggles (5 on, 1 off) | DATA GAP — no availability/disable endpoint for workshop staff; current UI has only per-member password-reset menu (`staff_tab.dart:82`). Toggle implies mutation |
| `Auto-Shift NFC Badging Active / Terminal 3 logged 14 ... / Download Roster PDF / Shift Rules` | All DATA GAP (NFC hardware, terminal, roster export, shift rules); measurements invented |
| Shell `BAY ACTIVE · Shop Floor #04`, search, `Marcus Vance / Lead Inspector` identity | DATA GAP — no bay-context/search/identity in `workshop_admin_home.dart` (Jobs/Staff/Templates tabs) |

## 5. States shown / not shown

- Shown: `All Staff` selected; 5 active (green dot + on-toggle) / 1 off-shift (grey, 0.9 opacity); 2-line role wrap; rail active = Settings.
- Not shown: loading (`LoadingSkeleton`), error (`ErrorState` + retry), empty (`EmptyState`), disabled/transferred, pending invite (none per C0 — correctly absent), toggle-saving,retailed, long names, 200% text, RTL/Arabic, dark, mobile, focus.

## 6. Classification

**UI work only** for the roster-card restyle + filter chips (counts derivable from existing `GET /staff` payload).
**Needs new data or server change** (out of scope for F3-0 UI): shift model, bay/station entity, skills/certifications/levels, logged-hours, NFC/terminal, roster PDF export, shift rules, availability mutation, all three metric computations.
**Conflicts with locked rule**: certification/compliance claims (`EV Certified`, `Level 4`, `Lead Master`, `OBD-II Specialist`, `100% ... verified`, `High-voltage ready`), manager-layer titles (`Lead Inspector`, `Supervisor`), invented measurements (87.5%, hours, 14 entries, return time). Per O5 these are gaps/unsafe copy, not new capabilities; per O6 no review/approve wording is introduced by this screen beyond the flagged titles.

## 7. New-component list

Metric card, filter-chip-with-count, staff card (avatar tile + status dot + 32 px toggle + skill-tag row), tonal banner with dual actions. Drawer: none on this screen. Role select / drag handles / tables: none.

## 8. Could not verify

- Definition/source of "active shift", bay utilization, shift compliance, logged hours, EV specialist — no server field found.
- Whether toggle changes assignment eligibility or display only; what audit event it would write.
- Why rail active = Settings on a Staff screen; why counts (8/5/3/6) disagree with 6 cards.
- Roster-PDF approval/audit path; NFC hardware reality.
