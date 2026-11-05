# 05. 5. Workshop Staff Management

- App: Workshop Admin
- Figma node: `1:1026`
- Frame: 1280x1048 px (desktop web; >=1200 breakpoint)
- Export folder: `screens/05_5._Workshop_Staff_Management`
- Sources read: `5._Workshop_Staff_Management.json` (developerSummary, nodes), `5._Workshop_Staff_Management@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html` header, `package-manifest.json`
- Export/screen-number mismatch: this is export slot **05** and also Figma screen **5**; the overall export order still differs from screen numbering (slot 01 = screen 3, slot 02 = screen 1, slot 03 = screen 2, slot 06 = screen 7).
- Confidence: medium — geometry/typography are exact, but almost every operational field on the cards (skills, certifications, shift, hours, bay, workload) is absent from `StaffMember` and from the server contract.

## 1. Purpose

Roster of active workshop technicians and administrators. It shows staff count filters, three workshop metrics, six staff cards with availability toggles and skill tags, and an NFC/shift banner. Only Elena is off shift.

## 2. Layout structure

Root `1:1026` 1280x1048; rail `1:1288` 96x1030; main `1:1028` 1184 px with padding 80/40/48/40.

Content `1:1029` 1104x920 (vertical, 32 px gap, 48 px bottom padding):
1. **Header** `1:1030` 1104x76, padding-top 8: title (32 px) + "LIVE ROSTER" pill + subtitle on the left; 149.5x56 "Add Staff" button on the right.
2. **Filter chips** `1:1044` 1104x44: "All Staff 8" (selected white), "Technicians 5", "Admins 3", "Active Shift 6"; 12 px gaps, 36 px height, pill.
3. **Metrics** `1:1071` 1104x132, three 352x132 cards with 24 px gaps and 24 px padding, radius 24: Bay Utilization 87.5%, Shift Compliance 100%, EV Specialists 3 Leads, each with an icon tile 48x48 and a two-line caption.
4. **Staff grid** `1:1111` 1104x364: 3 columns x 2 rows, card width 346.7, 32 px column gap, 8 px row gap. Card heights 190 (David, two-line role) and 172 (others). Padding 28, radius 24. Each card: 56x56 lilac avatar tile with a person glyph and a 16 px status dot; name 18 px; role/line 13 px; 32x32 on/off toggle; then a bottom row with skill chip(s) and "Logged 6h 12m" (or "Off Shift / Returns 08:00 AM"). Elena's card is 0.9 opacity.
5. **Quick-info banner** `1:1247` (1104x112, margin-top 16): icon 48, "Auto-Shift NFC Badging Active" + terminal sentence, "Download Roster PDF" and "Shift Rules" buttons.

Fixed desktop grid; no mobile reflow.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx fill count)

| Hex | Count | Usage |
|---|---:|---|
| `#5E5D69` | 36 | Secondary text, role lines, labels |
| `#FFFFFF` | 33 | Page, cards, metric cards, selected chip, banner buttons |
| `#006C49` | 24 | Deep-green icon/tag text, active labels |
| `#F4F3F8` | 21 | Chips, tags, banner, icon tiles |
| `#1A1B1F` | 16 | Names, numbers, titles |
| `#10B981` | 15 | Toggles, status dots, active nav; some icons |
| `#E1DEEC` | 6 | Avatar tiles |
| `#3C4A42` | 1 | "BAY ACTIVE" |
| `#E3E2E7` | 1 | Off-shift dot |
| `#E9E7ED` | 1 | Off-shift toggle track |
| `#FFFFFFE5` | 1 | Blurred header |

### Typography

Plus Jakarta Sans only. 55 text nodes: SemiBold 600 x29, Bold 700 x13, Regular 400 x9, Medium 500 x3, ExtraBold 800 x1.
Sizes: 11 x23, 13 x11, 12 x7, 18 x6, 22 x3, 14 x2, 16 x2, 32 x1.

| Role | Style | Example |
|---|---|---|
| Page title | 32 / 38, 800, -0.8 px | `1:1034` "Workshop Staff" |
| Metric number | 22 / 28, 700, -0.44 px | `1:1078` "87.5%" |
| Staff name | 18 / 24, 700, -0.27 px | `1:1121` "David Vance" |
| Banner title | 16 / 22, 700 | `1:1255` |
| Subtitle/role | 13 / 18, 400; 16 / 24, 500 | `1:1038`, `1:1124` |
| Chip/tag | 11 / 14, 600, +0.44 px / 12 / 16, 600 | `1:1132`, `1:1048` |
| Eyebrow | 11 / 14, 600, +0.55 px, UPPER | `1:1036` "LIVE ROSTER" |

### Radii, shadows/elevation, strokes, spacing

- Radii: 24 (metrics/cards/banner), 16 (avatar tile, icon tile, toggle? no, toggle is 9999), 9999 (chips, toggles, status dots). Candidate counts: 9999 x40, 16 x14, 24 x10.
- Shadows: metric/card shadow `0 2 8 rgba(0,0,0,.016)` + `0 14 40 rgba(0,0,0,.043)`; banner is flat tonal; no strokes.
- Spacing: 4 x33, 28 x24, 12 x21, 24 x21, 8 x16, 10 x15, 2 x13, 16 x12, 20 x12, 32 x11; card padding 28.
- Toggle is a 32x32 pill with a 24x24 white knob; status dots are 16 px.

## 4. Components

| Figma pattern | Node | Our design-system equivalent |
|---|---|---|
| Floating header | `1:1265` | No equivalent / `AppBar` |
| Icon rail (active item is Settings) | `1:1294` | `NavigationRail` |
| Filter chips with counts | `1:1045`–`1:1064` | `AppSelectableText`/`StatusChip` |
| Metric card | `1:1072` | No equivalent |
| Staff card with avatar, dot, toggle | `1:1112` | `AppListTile` + `Card` (current), no toggle/metrics |
| Skill tag | `1:1129` | `Chip`/`StatusChip` |
| Availability toggle | `1:1125` | `Switch` (but 32 px custom) |
| Quick-info banner | `1:1248` | `OfflineBanner`/tonal card |
| Roster/shift buttons | `1:1259`, `1:1261` | `AppButton` tonal/text |

Current `StaffTab` uses `SectionHeader("Staff accounts")`, `AppListTile` with initial avatar, masked email/role, and a status chip. It is explicitly read-only.

## 5. Assets

27 assets: 25 individual SVGs, 2 composed SVGs (`Nav-1_1294`, `Aside-1_1288`), **0 rasters**. The six staff "avatars" are the same person-in-circle vector glyph on a lilac `#E1DEEC` tile — **no staff photographs**. Remaining assets are 9–23 px icons. No customer/vehicle images.

## 6. Content and data

| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Title/subtitle | "Workshop Staff", "Active diagnostic technicians and shop floor administrators" | Yes (staff list) | "Active" is wrong: one member is off shift |
| Add Staff | primary button | No | Current product: Platform Admin creates all accounts; Workshop Admin read-only |
| Filters | "All Staff 8", "Technicians 5", "Admins 3", "Active Shift 6" | Partly (role/status) | `StaffMember` has role/status; counts 8/5/3/6 not in payload; "shift" absent |
| Bay Utilization | "87.5%", "4 of 5 active bays staffed" | No | No bay/utilisation model |
| Shift Compliance | "100%", "All tickets logged & verified" | No | No shift or compliance calculation; "verified" claim |
| EV Specialists | "3 Leads", "High-voltage ready" | No | No qualification/EV field |
| David Vance | "Senior Technician • Bay 02", "EV Certified", "Level 4", "Logged 6h 12m" | Name/role only | Skills, level, bay, hours not modelled |
| Marcus Vance | "Lead Inspector • Bay 04", "Lead Master", "Logged 7h 45m" | Name/role only | "Lead Master" is a level/certification not in roles |
| Sarah Jenkins | "Diagnostic Tech • Bay 01", "OBD-II Specialist", "Logged 5h 20m" | Name/role only | Hardware/qualification claim |
| Arthur Pendelton | "Workshop Admin • Front Desk", "Shop Ops", "Logged 8h 00m" | Name/role only | "Front Desk"/"Shop Ops" not modelled |
| Liam O'Connor | "Chassis Specialist • Bay 03", "Suspension", "Logged 4h 10m" | Name/role only | Skill/bay/hours absent |
| Elena Rostova | "Shop Floor Supervisor", "Off Shift", "Returns 08:00 AM" | Name/role only | "Supervisor" is a manager-like role; shift schedule absent; card opacity 0.9 |
| Banner | "Auto-Shift NFC Badging Active", "Terminal 3 logged 14 seamless shop floor entries in the last hour", "Download Roster PDF", "Shift Rules" | No | NFC hardware, terminal IDs, roster export, shift rules are all new |

No customer contact data. Staff names, roles and possibly hours are internal PII. The counts are also internally inconsistent: "All Staff 8" vs six cards drawn, "Active Shift 6" vs five green dots/one off shift, and "Technicians 5 / Admins 3" vs four technician cards and two admin/supervisor cards.

## 7. States shown / not shown

Shown: filter "All Staff" selected; five active staff (green dot/toggle) and one off shift (grey dot, toggle on `#E9E7ED`, 0.9 opacity); two-line role wrap; active nav Settings.
Not shown: empty roster, loading/error, disabled/transferred account, pending invitation, permission-denied, add-staff form, toggle saving/disabled, shift-changed confirmation, long names, 200% text, RTL/Arabic, dark theme, mobile/tablet layout, keyboard focus.

## 8. Implied interactions

Filter by role/shift; Add Staff; toggle availability per card; download roster PDF; shift rules; nav/search/user menu. The toggles imply immediate server mutation with no confirmation; no "unsaved" or error state is shown. Current product is read-only, so all mutations are new.

## 9. Correspondence to current product

- Spec: A07 Workshop staff `/staff` (`docs/phase-1/02-screen-inventory.md:67`) — staff list, role, status, current jobs; **"account creation hidden by default (RQ3)"**; read-only cached list.
- Current UI: `StaffTab` (`staff_tab.dart`) shows `SectionHeader("Staff accounts")` + `staffReadOnlyBody`: "Platform Admin creates workshop accounts. Workshop Admins can review staff and assign jobs." Each row is name, masked email, role, status chip. No metrics/toggles/actions.
- Model: `StaffMember` has only `userId`, `displayName`, `emailMasked`, `role`, `status` (`models.dart:465`).
- API: `GET /api/v1/workshop/staff` exists. There is **no** workshop staff invitation endpoint in `api_endpoints.dart`; docs list `POST /workshop/staff/invitations` as "No by default (RQ3 pending)" (`08-api-design.md:299`). No shift/NFC/roster/qualification endpoints.
- Verdict: **existing screen**, major redesign; Add Staff, toggles, metrics, roster PDF, shift rules and NFC **need new model/server features** and role decisions. Active nav points to Settings, not a dedicated Staff item.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"Platform Admin creates all accounts. Workshop Admin assigns and reassigns work."** (approved RQ3) and A07 "account creation hidden by default". Evidence: primary "Add Staff" button and a staff-card management screen that looks like full administration.
2. **"No manager role, second-person review, approval queue."** Evidence: "Shop Floor Supervisor", "Lead Inspector", "Lead Master", "Senior Technician" hierarchy. Some may be skill labels, but "Supervisor"/"Lead" reads as a manager layer; roles are only Technician/Workshop Admin/Platform Admin.
3. **"No certification/'verified by'/compliance claims."** Evidence: "EV Certified", "Level 4", "Lead Master", "OBD-II Specialist", "Shift Compliance 100%", "All tickets logged & verified", "High-voltage ready".
4. **"Never invent measurements/results."** Evidence: 87.5%, 4 of 5 bays, 100%, 3 Leads, 6h 12m/7h 45m/5h 20m/8h 00m/4h 10m, "14 seamless entries in the last hour", "Returns 08:00 AM". No source or definition.
5. **"UI layer only; no business logic/API/model/permission/state change."** Availability toggles, shift rules, NFC badging, hours logging and roster PDF are new features and features/permissions, not presentation.
6. **"Finalized reports immutable"** is not directly touched, but staff "Logged 8h 00m" and compliance metrics imply auditable time records that do not exist.
7. **Tokens.** Raw hex; emerald/mint/lilac palette not in current tokens; radii 24/48 absent; toggle/status-dot patterns are one-off.
8. **WCAG 2.2 AA.** "Add Staff" white on `#10B981` approx 2.5:1; 32x32 toggles are below the project's 44/48 minimum; 11 px tags; status is conveyed by dot colour + toggle, but the off-shift state also uses "Off Shift" text (good).
9. **Arabic RTL.** No Arabic; staff names in Latin only; role lines and the left rail need mirroring; no handling of Arabic names or mixed-direction text.
10. **Hardware.** "NFC Badging", "Terminal 3", "OBD-II" are hardware/integration claims with no stated device support.

## 11. Open questions / could not verify

- Is "Add Staff" allowed for Workshop Admin? If yes, this overrides approved RQ3 and needs a new audited invitation permission/endpoint.
- Are "Senior Technician", "Lead Inspector", "Lead Master", "Shop Floor Supervisor" approved role names or free-text job titles? If approved, they conflict with the three-role model.
- Where do certifications/levels/skills come from, who verifies them, and do they expire (e.g. EV/high-voltage, OBD-II)?
- What defines "active shift", "bay utilization", "shift compliance", "logged hours", and "EV specialist"? The server has none of these fields.
- Is existence of "Bay 01/02/03/04" tied to a real bay entity? Why are 4 of 5 bays staffed but 6 staff cards?
- Does toggling availability change assignment eligibility or only UI state? What audit event is written?
- Is "Download Roster PDF" an approved export? Large exports are async/audited per API design.
- Is NFC badging real hardware, and is terminal identity data stored?
- Why is the nav's active item Settings on a staff screen?
