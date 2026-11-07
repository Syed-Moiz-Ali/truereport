# F3-0 Screen 6 — Add Staff / Create Account (Workshop Admin)

- Export folder: `docs/ui/figma-export/Workshop_admin_figma/screens/07_6._Add_Staff_-_Create_Account`
- Figma node: `1:1642` ("6. Add Staff / Create Account"), 240 serialized nodes
- Frame (JSON `developerSummary.screen`): **1280×1024**, VERTICAL, bg `#FFFFFF`
- PNG: `6._Add_Staff_-_Create_Account@2x.png` 2712×2288 px (≈1356×1144 @1x; bleed from blur/sheet shadow — per O3 use **1280×1024** as drawn)
- Prior spec read (not edited): `docs/ui/figma/specs/workshop_admin/07-add-staff-create-account.md`
- C0 model (binding): `docs/ui/figma/c0-admin-accounts-slot-sheet.md`
- Viewed PNG as image: yes

## 1. Node-level layout

- Root 1280×1024 FIXED/HUG. `Background 1:1643` 1280×1024 (left pad 96) → `Main 1:1644` 1184×1024 at x=96 (padding 80/40/418/40).
- Blurred roster backdrop `1:1646` 1104×526 (layer blur 12, not interactive): top bar (breadcrumb `ADMINISTRATION · Personnel Roster`, H1 `Staff Directory & Access`, `18 Active Technicians` pill, `Add Staff Member` CTA), 3 metric cards 352×104 r16 (`4/4`, `99.4%`, `3 Admins`), roster card 1104×302 r16 with three 74-high rows (40 initials circle, name 14/700, email 13, bay pill, 12 px dot).
- `Header 1:1732` 1184×80 + `Aside 1:1755` 96×1024 shell (Dashboard/Jobs neutral, Settings active emerald).
- `Right Slide-out Panel 1:1774` **480×1024** at x=800, white, TL/BL 40, shadow, VERTICAL SPACE_BETWEEN:
  - Body `1:1775` 480×865 pad 40: `ONBOARDING` pill + 44 close → `Create Staff Account` 32/800 + helper → fields group 400 wide gap 24: Full Name (52 input), Email, Temporary Password (52 + eye), Assign Role segmented 56 container (2× 40 buttons), Station Allocation 4× 92.5×64 cards gap 10, magic-link row 71 + 48×28 switch.
  - Footer `1:1873` 480×136 pad 40 `#FFFFFFE5`: `Cancel` text + `Create Account` 289×56 emerald.
- No scroll drawn; footer pinned. Fixed 1280 only; no tablet/phone/RTL frame.

## 2. Components

| Figma pattern | Design-system map |
|---|---|
| Right slide-out 480 panel | NO equivalent — `overlays.dart` `showAppBottomSheet` is bottom sheet, not side sheet → new `SideSheet`/`RightDrawer` |
| Text inputs w/ card shadow | `inputs.dart` (`AppTextField`); shadow-card style is new |
| Role segmented 2-up | `chips.dart` `AppSelectableText` (not segmented) → new segmented control |
| Station cards STN 01–04 | No station component → new (only if station model approved; currently gap) |
| Magic-link switch | Material `Switch` (no token) → new if flow approved (currently gap) |
| Staff rows / metric cards | `lists.dart` `AppListTile`, `cards.dart` `AppCard`, `chips.dart` `StatusChip` |
| Buttons | `buttons.dart` (`AppButton` primary/tonal/text) |

## 3. Assets

- `assets/manifest.json`: **22 assets — 20 individual SVGs + 2 composed** (`Nav`, `Aside`), **0 rasters**. Initials `MV/AL/RK` are text, not images.

## 4. Element → data mapping (EVERY visible string)

Per O5: Add Staff = Create Technician in own workshop; C0: no invitations, no pending, admin-set password, reset/disable; certifications/shifts/stations/extra roles are gaps.

| Figma element | Mapping |
|---|---|
| Backdrop `ADMINISTRATION · Personnel Roster`, `Staff Directory & Access`, `18 Active Technicians`, `Add Staff Member` | Screen labels new; count derivable from `GET /api/v1/workshop/staff` (`StaffController.java:37`); CTA = existing `showCreateTechnicianDialog` (`staff_tab.dart:183`) |
| Backdrop metrics `4/4 Operational Diagnostic Bays`, `99.4% Inspection Protocol Accuracy`, `3 Admins / Master Security Privileges` | DATA GAP (no bay model; invented 99.4%; "Master Security Privileges" marketing copy — role counts only derivable) |
| Backdrop rows `Marcus Vance m.vance@techinspect.io Bay 04 (Lead)` / Alicia / Rohan | PARTIAL: `displayName` EXISTS; full email CONFLICTS with masked-email contract (`emailMasked`, `StaffService.maskEmail`); `Bay 0x` DATA GAP; `(Lead)` extra-role gap per O5 |
| Shell `BAY ACTIVE · Shop Floor #04`, search, `Lead Inspector` identity | DATA GAP (no bay context/search; role enum is `WORKSHOP_ADMIN`/`TECHNICIAN` per `HierarchyService.java`) |
| `ONBOARDING` badge, `Create Staff Account`, helper `Set up permissions, station assignments...` | New labels; "permissions/stations" = DATA GAP |
| `FULL NAME e.g. David Vance` | EXISTS → `displayName` in `POST /api/v1/workshop/technicians` (`StaffController.java:43`, `HierarchyService.createTechnician`) |
| `EMAIL ADDRESS e.g. d.vance@techinspect.io` | EXISTS → `email` same endpoint; server normalizes + `EMAIL_EXISTS` (per C0 sheet) |
| `TEMPORARY PASSWORD InspectGuard99!` + eye | EXISTS (field) → `initialPassword` same endpoint, `PasswordPolicy` 12–128 (per C0 sheet); hardcoded sample value MUST NOT ship — redacted |
| `ASSIGN ROLE Technician / Admin` (Technician selected) | PARTIAL: workshop dialog fixed to Technician per C0 (no picker). "Admin" may only mean Workshop Admin; workshop admin cannot create admins (strict chain A2). Segmented picker as drawn = LOCKED-RULE conflict if it enables Admin creation |
| `STATION ALLOCATION 1 Required STN 01–04` (STN 04 emphasised) | DATA GAP — no station/bay field on `User`/`WorkshopMembership`; mandatory-selection rule has no server counterpart (O5) |
| `Send welcome magic link / Bypasses initial manual password reset` (switch ON) | DATA GAP — no magic-link/invite implementation; invitation flow removed per C0 sheet; no `POST /workshop/staff/invitations` |
| `Cancel / Create Account` | EXISTS (dialog cancel/create → `createTechnician` + `accountCreated`/`actionFailed` ARB) |

## 5. States shown / not shown

- Shown: blurred populated roster behind scrim; blank pristine form; Technician selected; STN 04 emphasised; magic-link ON.
- Not shown: loading, empty roster, error/success confirmation, duplicate email, weak password (<12), missing station, invite sent/pending (correctly absent per C0), permission-denied, offline, 200% text, Arabic/RTL, phone/tablet.

## 6. Classification

**Matches existing feature**: Full Name + Email + Temporary Password + Create (Technician, own workshop, admin-set password) — already implemented as dialog in `staff_tab.dart` via `POST /api/v1/workshop/technicians`; reset/disable via `POST /technicians/{userId}/password-reset`.
**UI work only**: restyling dialog as 480 right slide-out + close/footer chrome (new `SideSheet` component, no data change).
**Needs new data or server change** (out of scope): station allocation, role picker (Admin creation), magic-link/invite flow, permissions setup, backdrop metrics/bays.
**Conflicts with locked rule**: full staff emails (PII masking), hardcoded sample password, Admin-creation picker, station/invite/permissions features (UI-layer-only rule), no review/approve wording per O6 (none present — compliant).

## 7. New-component list

Right slide-out panel (480, pinned footer), segmented role control, station-allocation cards, switch row with helper copy, card-shadow text inputs. Role selects: only the segmented control (must be fixed to Technician or removed). Drag handles / tables: none.

## 8. Could not verify

- RQ3 status for workshop-created accounts beyond Technician (code + C0 say Technician-only).
- Whether unmasked staff email is ever permitted (current API says masked).
- Station/bay entity existence; magic-link design (token/expiry/TOTP); duplicate/weak/disabled/rate-limit states.
- RTL sheet side (left vs right in Arabic); mobile drawer behavior.
- PNG @1x (1356×1144) vs JSON frame (1280×1024) delta — attributed to scrim/shadow bleed; geometry per JSON.
