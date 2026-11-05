# 07. Add Staff / Create Account

- App: Workshop Admin
- Figma node: `1:1642`
- Frame: 1280x1024 px (desktop web, >=1200 per `AppBreakpoints.desktop`)
- Export folder: `screens/07_6._Add_Staff_-_Create_Account`
- Sources read: `6._Add_Staff_-_Create_Account.json`, `6._Add_Staff_-_Create_Account@2x.png`, `assets/manifest.json`
- Export-order note: package index **07** contains Figma screen **6**; package index **06** contains screen **7**. Indexes 08-12 match screens 8-12. This file follows the package index, not the screen number.
- Confidence: medium. Geometry and token counts are high confidence from JSON; product correspondence is medium because the drawer describes account creation, stations and a magic-link invite that do not exist in the current client, model or API.

## 1. Purpose
Provision a new workshop staff account from a right-hand slide-out while the existing staff roster stays visible but blurred behind it. The drawer collects name, email, temporary password, role, station and an invite method, then confirms with `Create Account`.

## 2. Layout structure
Root is a fixed-width `VERTICAL` frame, 1280x1024, `FIXED/HUG`; page background is `#FFFFFF`.

- `Background` (`1:1643`), 1280x1024, `FILL/HUG`, left padding 96 for the rail.
- `Main` (`1:1644`), 1184x1024 at x=96, padding 80/40/418/40. Its content is 1104x526, which leaves most of the page empty below the roster.
- Blurred roster `Blurred Background Staff Management View` (`1:1646`), 1104x526, vertical gap 32, layer blur radius 12. This is a backdrop, not a separate interactive screen.
- Roster top bar (`1:1647`) 1104x56, `SPACE_BETWEEN`: left breadcrumb `ADMINISTRATION · Personnel Roster`, H1 32/38; right `18 Active Technicians` pill (198x40) and `Add Staff Member` CTA (189x48, emerald).
- Three metric cards (`1:1669`, `1:1677`, `1:1685`), each 352x104, 24 gap, radius 16, padding 24: `4 / 4`, `99.4%`, `3 Admins`.
- Roster card (`1:1693`) 1104x302, radius 16, padding 24; three rows 74 high, radius 48, 16 gap; row = initials circle 40, name 14/18 bold, email 13/18, bay pill 11/14, 12px status dot.
- `Header` (`1:1732`) 1184x80 at x=96, padding 0/40, `#FFFFFFE5` with one shadow, `SPACE_BETWEEN`: `BAY ACTIVE · Shop Floor #04`, search pill (299x34), user identity and 32px avatar.
- `Aside` (`1:1755`) 96x1024, padding 32/0: logo 48x48, three 56x56 nav tiles with 24 gap, settings tile at y=952. Dashboard and Jobs are neutral; Settings is the active emerald tile. This is the shell used by screens 07-12.
- `Right Slide-out Panel` (`1:1774`) 480x1024 at x=800, white, shadow, corners TL/BL 40 and TR/BR 0. It is `VERTICAL`, `SPACE_BETWEEN`.
  - Form body (`1:1775`) 480x865, padding 40. Order: close/onboarding row, heading block, then fields.
  - Onboarding row: `ONBOARDING` pill + 44x44 close button.
  - Heading: `Create Staff Account`, 32/40 ExtraBold, then 13/18 helper copy.
  - Fields group (`1:1791`) 400 wide, vertical gap 24: Full Name (label 11/14 upper, 52px input), Email Address, Temporary Password (52px input with eye toggle), Assign Role (56px segmented container with two 40px buttons), Station Allocation (4 x 92.5x64 cards, 10 gap), then a 71px magic-link row with 48x28 switch.
  - Bottom action anchor (`1:1873`) 480x136, padding 40, `#FFFFFFE5` with shadow; `Cancel` 50px-high text button and `Create Account` 289x56 emerald button.
- Scroll: no scroll is shown. The form body and footer exactly fill 1024; if validation adds height, the footer must be pinned or the sheet must scroll.
- Responsiveness: only a fixed 1280 desktop frame is designed. At `bp.tablet` or phone widths the 480px side sheet and 3-up roster have no fallback. No RTL/Arabic frame exists.

## 3. Visual tokens observed
### Colours (exact hex, usage, approx count)
Counts are occurrences in exported fill/stroke data.

| Hex | Usage | Count |
|---|---|---:|
| `#5E5D69` | Secondary text, labels, placeholders, inactive chips | 32 |
| `#FFFFFF` | Drawer, cards, input surfaces | 27 |
| `#1A1B1F` | Primary text and headings | 24 |
| `#F4F3F8` | Tonal surfaces, pills, chips, icon tiles | 15 |
| `#006C49` | Active/positive icons and small text | 11 |
| `#10B981` | Primary CTA fill, status dots, switch | 10 |
| `#EEEDF3` | Avatar/row chip backgrounds | 6 |
| `#FFFFFFE5` | Sticky header/footer tint | 2 |
| `#3C4A42` | `BAY ACTIVE` text | 1 |
| `#FFFFFF80` | Frost overlay behind sheet | 1 |
| `#FFFFFF01` | Toggle thumb overlay | 1 |

`#10B981` with white text measures about **2.54:1** (below WCAG 2.2 AA 4.5:1, and below 3:1 for UI boundaries). Example: `Add Staff Member` (`1:1663`) and `Create Account` (`1:1877`). `#006C49` on white is about 6.48:1 and is the safer action/text colour.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)
Family is `Plus Jakarta Sans` for all UI text; no Arabic family is shown.

| Role | Weight | Size/line | Tracking | Usage |
|---|---|---|---|---|
| Page/panel H1 | 800 | 32/38-40 | -0.80 to -0.96 | `Staff Directory & Access`, `Create Staff Account` |
| Metric value | 700 | 22/27.5 | -0.44 | `4 / 4`, `99.4%`, `3 Admins` |
| Row name/CTA | 700 | 14/18 | -0.14 | Names, `Add Staff Member`, buttons |
| Body | 400-500 | 13/18, 14/20 | 0 to -0.07 | Helper copy, emails, placeholders |
| Labels | 600 | 11/14 | +0.44 to +1.10 | Uppercase field labels, `BAY ACTIVE`, `ONBOARDING` |
| Micro | 600 | 12/16 | +0.24 | Pills, initials, role labels |

Alignment is start/left throughout; only avatar initials, role labels and CTA labels are centered. Arabic RTL, bidi isolation and direction toggle are not designed.

### Radii, shadows/elevation, strokes, spacing
- Radii: 16 for cards/inputs/metric tiles; 48 for roster rows and role segments; 9999 for pills; 40 only on the sheet's left corners; 24/32 on the 44px close button and 40px avatars.
- Shadows: card `0 2 8 rgba(0,0,0,0.016)` + `0 14 40 rgba(0,0,0,0.043)`; primary CTA `0 10 25 rgba(16,185,129,0.30)`; sheet two-layer shadow; header/footer `#FFFFFFE5` plus one shadow.
- Strokes: cards and inputs are borderless; no visible borders except the switch track/thumb.
- Spacing candidates: 4/8/12/16/24/32/40/48 dominate; off-grid 10 (station gap), 14, 20 and 35 appear. Main page padding 80 top/40 sides is outside the 4/8/12/16/24/32/48 token set.

Token drift: the current design system uses `#0B3B4A` primary, `#0F6B6F` secondary, `AppRadiiTokens` 4/8/12/16/pill and a type scale topping at `type.h1` 24/30 (`docs/phase-1/10-design-system.md`). This frame uses `#006C49`/`#10B981`, 32px headings and radii 24/32/40/48. These must be mapped through tokens, not copied as hex.

## 4. Components
| Figma pattern / node | Map to current design system | Notes |
|---|---|---|
| Right slide-out `1:1774` | No equivalent | `showAppBottomSheet` is a modal bottom sheet, not a side sheet; no side-sheet component exists. |
| `AppTextField` inputs `1:1795`-`1:1813` | `AppTextField` | Current inputs are filled/borderless; the Figma inputs are white cards with shadows. |
| Buttons `1:1663`, `1:1825`, `1:1877` | `AppButton` primary/tonal/text | No destructive variant; no loading state shown. |
| Role segmented buttons `1:1825`, `1:1830` | `AppSelectableText` | Current component supports selected/unselected, not a 2-up segmented control. |
| Station cards `1:1842`-`1:1857` | `AppSelectableText` or Material `ChoiceChip` | No station/bay component or data. |
| Magic-link switch `1:1870` | Material `Switch` | No dedicated switch token/component. |
| Staff rows `1:1695`-`1:1719` | `AppListTile` / `AppCard` / `StatusChip` | Current `staff_tab.dart` is read-only and does not show full email or bay. |
| Metric cards `1:1669`-`1:1685` | `AppCard` / `SectionHeader` | No metric-pod component. |
| Header/aside `1:1732`, `1:1755` | `AppBar` + `NavigationRail` | Current `workshop_admin_home.dart` has Jobs/Staff/Templates tabs, not Dashboard/Jobs/Settings. |

## 5. Assets
`assets/manifest.json` reports **22** assets: 20 individual SVGs (20 icons) and 2 composed SVGs (`Nav` 96x824, `Aside` 96x1024). There are **0 raster** assets. No photo, vehicle image or avatar image is used; `MV`, `AL`, `RK` are text initials in circles. The only non-icon graphics are the shell navigation compositions.

## 6. Content and data
| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Breadcrumb | `ADMINISTRATION`, `Personnel Roster` | No dedicated field | Screen labels; existing app uses l10n keys. |
| Page title | `Staff Directory & Access` | No | New title; current tab says read-only staff. |
| Count pill | `18 Active Technicians` | Derivable from `GET /workshop/staff` count | Count not shown in current UI. |
| CTA | `Add Staff Member` | No | New action. |
| Metric | `4 / 4 Operational Diagnostic Bays` | No | No bay/station model. |
| Metric | `99.4% Inspection Protocol Accuracy` | No | Invented metric; no source. |
| Metric | `3 Admins` / `Master Security Privileges` | Role counts could be derived | "Master Security Privileges" is marketing copy, not a role. |
| Roster rows | `MV · Marcus Vance · m.vance@techinspect.io · Bay 04 (Lead)` | `StaffDto.displayName`, `emailMasked`, `role`, `status` | Full email conflicts with current masked-email API. `Bay 04` has no field. |
| Roster rows | `AL · Alicia Lindqvist · a.lindqvist@techinspect.io · Bay 01` | Same | Fake `techinspect.io` domain; full email. |
| Roster rows | `RK · Rohan Kapoor · r.kapoor@techinspect.io · Bay 02` | Same | Same. |
| Shell status | `BAY ACTIVE`, `Shop Floor #04` | No | Shell context not in current app. |
| Search | `Search VIN, tech, job ticket...` | `WorkshopJob.vehicleVin` exists internally | Placeholder includes VIN; no search implementation on this screen. |
| User identity | `Marcus Vance`, `Lead Inspector` | `User.displayName`; role enum is `WORKSHOP_ADMIN`/`TECHNICIAN` | `Lead Inspector` is a display title, not a role. |
| Drawer badge | `ONBOARDING` | No | New workflow label. |
| Drawer title | `Create Staff Account` | No | New feature. |
| Drawer helper | `Set up permissions, station assignments, and onboarding credentials.` | No | Mentions permissions and stations that do not exist. |
| Field | `FULL NAME`, `e.g. David Vance` | Would map to `User.displayName` | No create-account endpoint. |
| Field | `EMAIL ADDRESS`, `e.g. d.vance@techinspect.io` | Would map to user email | No endpoint; display would need masking policy decision. |
| Field | `TEMPORARY PASSWORD`, `[sample temporary password - redacted]` | No | Hardcoded sample credential; must not ship. |
| Field | `ASSIGN ROLE (TECHNICIAN / ADMIN)`; `Technician`, `Admin` | `WORKSHOP_ADMIN` / `TECHNICIAN` | "Admin" can only mean Workshop Admin; no manager role. |
| Field | `STATION ALLOCATION`, `1 Required`, `STN 01`-`STN 04` | No | No station/bay field. |
| Toggle | `Send welcome magic link` / `Bypasses initial manual password reset` | No | New invite/auth flow; no magic-link implementation. |
| Actions | `Cancel`, `Create Account` | No | No create endpoint. |

No customer name/phone/email or vehicle VIN value is shown, but staff emails and a sample password are present. All names, domains, bay numbers and metrics are sample data and must not be treated as real.

## 7. States shown / not shown
Shown: populated roster behind a blurred scrim and a pristine blank create form; role `Technician` selected; station `STN 04` visually emphasised; magic-link switch on.

Not shown: loading, empty roster, error, success/confirmation after create, disabled workshop, duplicate email, weak password, missing required station, invite sent/pending, invite failed, permission-denied, offline, 200% text scale, Arabic/RTL, phone/tablet layouts.

## 8. Implied interactions
Open/close drawer; type name/email/password; show/hide password; choose Technician/Admin; choose one station; toggle magic link; cancel; create account. `1 Required` implies station selection is mandatory. There is no explicit save-draft, resend-invite, expiry or confirmation state.

## 9. Correspondence to current product
- **New screen/feature; needs server/model/permission changes.** `client/apps/admin_app/lib/src/admin_router.dart` only exposes `/signin`, `/platform`, `/workshop`, `/unauthorized`; there is no create-account route.
- Current staff UI is read-only: `pages/staff_tab.dart` renders `StaffDto` with `displayName`, `emailMasked`, `role`, `status`. `StaffService.maskEmail` masks the address. `GET /api/v1/workshop/staff` is the only workshop staff endpoint.
- Account creation is currently Platform Admin-only: `POST /api/v1/platform/invitations`; `api_endpoints.dart` has no workshop create-account endpoint. `docs/phase-1/08-api-design.md` §7.3 marks `POST /workshop/staff/invitations` as **No by default (RQ3 pending)**.
- `User`/`WorkshopMembership` have no station, bay, temporary-password, magic-link or `Lead Inspector` field. `WorkshopRole` is `WORKSHOP_ADMIN`/`TECHNICIAN`.
- The shell (Dashboard/Jobs/Settings rail) does not match `workshop_admin_home.dart`, which has Jobs/Staff/Templates tabs and no Settings or Dashboard.
- Implementing this screen as drawn requires business logic, validation, permissions, email delivery and a schema change; all are outside an F0 UI-only change.

## 10. Locked-rule conflicts / unsafe-to-ship content
1. **UI layer only.** The task rule says "UI layer only; no business logic/API/model/validation/permission/state/server change." This screen requires a new create-account/invite endpoint, role/station model, password or magic-link flow and email delivery.
2. **No account creation by Workshop Admin by default.** `docs/phase-1/02-screen-inventory.md` A07 says "account creation hidden by default (RQ3)"; `docs/phase-1/08-api-design.md` §7.3 says `POST /workshop/staff/invitations` is "No by default". The drawer is a direct account-creation action.
3. **PII masking.** Current `StaffDto` exposes `emailMasked`; `docs/phase-1/08-api-design.md` §7.3 says staff list returns "Masked PII". The roster shows full emails (`m.vance@techinspect.io`, `a.lindqvist@techinspect.io`, `r.kapoor@techinspect.io`).
4. **Credentials in UI.** `[sample temporary password - redacted]` is a hardcoded sample temporary password. Shipping it as a value or default is unsafe.
5. **No manager role.** The role choice says `Technician / Admin`; only Workshop Admin and Technician exist. `Lead Inspector` and `Bay 04 (Lead)` are not roles and must not be treated as approval authority.
6. **WCAG 2.2 AA.** White text on `#10B981` is about 2.54:1; the primary CTA and switch depend on it. 11px labels are small and the sheet has no text-scaling design.
7. **Tokens/fonts.** `#006C49`, `#10B981`, 32px H1 and 24/32/40/48 radii are not the current `AppTheme`/`AppRadiiTokens` values; `Plus Jakarta Sans` is still "Pending licence verification" in `docs/phase-1/10-design-system.md` §2.4.
8. **Arabic RTL.** No Arabic frame, field direction toggle, mirrored sheet side or `lang`/`dir` treatment is shown; RTL is non-negotiable.

## 11. Open questions / could not verify
- Is RQ3 approved to let a Workshop Admin create accounts? If not, this is Platform Admin-only.
- Should a Workshop Admin ever see an unmasked staff email? Current API says no.
- Are stations/bays a real concept? No entity or endpoint was found.
- Does `Create Account` create a user directly or send an invitation? What expiry, TOTP and password policy apply?
- Does `Send welcome magic link` use the existing invitation token, and does it bypass password reset intentionally?
- What are the duplicate-email, weak-password, disabled-workshop and rate-limit states?
- Does the design intend a mobile/responsive drawer, and on which side does it open in RTL?
