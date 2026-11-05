# 02. 2. Add Staff / Create Account

- App: Platform Admin
- Figma node: `1:3560`
- Frame: 1280x1024 px (desktop web)
- Export folder: `screens/02_2._Add_Staff_-_Create_Account`
- Sources read: `2._Add_Staff_-_Create_Account.json`, `2._Add_Staff_-_Create_Account@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: high — explicit field list, measured drawer geometry, and a readable PNG.

## 1. Purpose
Slide-out account-provisioning panel over a dimmed hierarchy workspace. Captures full name, email, temporary password, role and workshop, then creates the account.

## 2. Layout structure
Root `1:3560` vertical, 1280x1024, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:3561` 1024x1024, padding 64/32/392/32. Its 960x568 “Dimmed & Frosted Underlying Dashboard” (`1:3563`) is only a backdrop: header, three 304x170 workshop cards, and a 960x278 staff table mock (`1:3622`); the mock table is visible only as a blur.
- `Soft Frosted Glass Backdrop Overlay` `1:3651`, 1024x960, fill `#FFFFFF99`.
- `Header` `1:3652` 1024x64, fill `#FFFFFFE5`, search 448x26 + icon buttons.
- `Aside` `1:3677` 256x1024: brand, six nav links, footer status.
- `Aside - Slide-out Creation Panel (440px)` `1:3728` x=840, 440x960, padding 32, gap 168, fill `#FFFFFF`.

Panel internals:
1. `Panel Header & Close Trigger` `1:3730` 376x74: “Create Staff Account”, subtitle, 40x40 close circle.
2. `Pure White Input Fields Group` `1:3740` 376x542, gap 24: six 376x66/68 fields (name, email, temp password, role, workshop) and a 376x68 notification banner; each label 376x14 + white 48/50 px field.
3. `Panel Footer Action CTA` `1:3792` 376x112, pushed to the bottom; full-width 376x56 pill button `1:3793`.

No scrolling is shown between form and footer; the 168 px gap absorbs the spare height. Drawer width is fixed at 440 px (~34% of 1280); below 900 px it would have to become full-screen (not exported).

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 33 | Labels, help text, placeholder |
| `#FFFFFF` | 22 | Panel/field surfaces |
| `#1A1B1F` | 19 | Ink/headings/values |
| `#F4F3F8` | 18 | Dimmed dashboard, close button, banner |
| `#10B981` | 16 | Primary CTA, logo, status dots |
| `#3C4A42` | 5 | Inactive sidebar labels |
| `#5E5D6980` | 2 | Placeholder text (50% alpha) |
| `#006C49` | 1 | Avatar fill |
| `#FFFFFF99` | 1 | Frosted overlay |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans`; drawer heading 22/700 LH28; field values 16/700 LH22 (role/workshop) and 14/500 for placeholders; labels 11/600 uppercase (+0.28 tracking) `#5E5D69`; body 13/400 LH18; CTA 14/700 white.

### Radii, shadows, strokes, spacing
- Radii: 32 (4 cards in the blur), 9999 (27 pills/buttons/close). Fields are 48–50 px tall with white fill and no visible border.
- Shadows: `0 2 8 rgba(0,0,0,0.02)`, `0 14 40 rgba(0,0,0,0.04)`; CTA emerald `0 10 25 rgba(16,185,129,0.30)`; close/fields `0 0 8` soft.
- Strokes: none.
- Spacing: 32 panel padding; 24 between fields; 4 label-to-field; 56 footer top pad; CTA height 56.

## 4. Components
Flattened export (no COMPONENT/INSTANCE). Patterns: 440 px slide-out drawer, labeled filled/white input, dropdown with leading status dot, pill close button, full-width 56 px primary pill, inline info banner, dimmed/scrimmed backdrop.
Mapping: `AppTextField` (but current theme is rectangular, tonal, no visible white field); `DropdownButtonFormField` (exists); `AppButton` primary (exists, differs in height/radius); `AppButton` tonal/text for close? no icon-button primitive; `StatusChip` not used; no drawer/bottom-sheet provisioning component.

## 5. Assets
22 assets, all individual SVG icons. No raster, no composed SVG, no photos/avatars. Icons: logo, sidebar, search, bell, help, close, field icons, chevrons, eye.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Panel title | Create Staff Account | — | Current dialog title is “Create” |
| Subtitle | Provision platform and workshop credentials | — | Product actually invites/creates |
| FULL NAME | e.g. Marcus Vance | `displayName` | Required |
| EMAIL ADDRESS | m.vance@coreos-grid.internal | `email` | Fictional `.internal` domain |
| TEMPORARY PASSWORD | [sample temporary password - redacted] (visible) | `temporaryPassword` | Plaintext by default; eye toggle |
| ASSIGN ROLE | Workshop Admin | `role` | Only TECHNICIAN/WORKSHOP_ADMIN supported |
| ASSIGN WORKSHOP | Workshop A - Bay District | `workshopId` | Current API takes workshop id |
| Banner | “Credentials and activation token will be dispatched instantly via secure push.” | No | No secure-push distribution exists |
| CTA | Create Account | — | Current dialogs say Create/Invite |

No customer PII, VIN, plate, or report data. Staff email and temporary password are personal/secret data.

## 7. States shown / not shown
Shown: default empty fields, one filled password, one role, one workshop, CTA. Not shown: validation errors, required markers, password-strength/confirmation, email duplicate error, loading/submitting, success, invitation-token result, TOTP enrolment, permissions, disabled fields, RTL, keyboard focus, text scaling, small-screen drawer.

## 8. Implied interactions
Open from “Add Staff”; type name/email/password; show/hide password; open role dropdown; open workshop dropdown; close drawer; submit. No cancel button in the panel besides the X.

## 9. Correspondence to current product
Partial. Implemented today as modal `AlertDialog`s inside `hierarchy_tab.dart`:
- `_showCreateDialog` → `POST /api/v1/platform/users` via `admin_api.createUser(email, displayName, temporaryPassword, role, workshopId)`.
- `_showInviteDialog` → `POST /api/v1/platform/invitations` via `admin_api.invite(...)`; returns `invitationToken`, which the app displays in a follow-up dialog.
Server: `PlatformHierarchyController` `/users` and `/invitations`; `HierarchyService.createUser/invite`; request records `CreateUserRequest`, `InviteRequest`.
Differences: Figma is a 440 px drawer, not a dialog; current password field is `obscureText: true`; no “secure push”; no role beyond two; no workshop picker if invoked from a workshop card; no TOTP.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “no business logic/API/model/validation/permission/state/server change.” Evidence: “Credentials and activation token will be dispatched instantly via secure push” is not an existing API behaviour; invitation tokens are returned in the response and displayed, not pushed. Implementing the copy requires new delivery logic.
- Rule: “Never invent … licences/measurements/results.” Evidence: fictional domain `coreos-grid.internal` and the password `[sample temporary password - redacted]` are presented as real values.
- Security design: passwords must never be logged; the frame shows a temporary password in clear text by default (`1:3762`). It is not a logged secret, but default-visible credentials are unsafe for shoulder-surfing/screenshots.
- Rule: “colours/text/radii/spacing … from central tokens.” Evidence: white 48 px fields with no visible tonal fill, 32 px card radii, and `#10B981` differ from the current `AppTextField` theme and `AppRadiiTokens`.
- Rule: “no manager role.” Evidence: role list shows only “Workshop Admin” here, but the underlying mock dashboard lists “Leads” (`1:3591`: “18 Technicians • 4 Leads”), importing a lead role.
- Rule: “UI layer only.” Evidence: the workflow described (“activation token dispatched”) is an invitation flow, not a create-account flow; choosing one changes product behaviour.

## 11. Open questions / could not verify
- Is this the “invite” flow or the “create with temporary password” flow? The title says create, the banner says activation token.
- Should temporary passwords ever be visible, and must they be forced-changed on first login?
- Is a 440 px drawer required, or is the existing dialog acceptable for Phase F?
- Where does the “secure push” channel come from? No endpoint/provider exists.
- No validation, error, loading, success, or RTL state is exported.
- Contrast of the 50%-alpha placeholder on white is unverified.
