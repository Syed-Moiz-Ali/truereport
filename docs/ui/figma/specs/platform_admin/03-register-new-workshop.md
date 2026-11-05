# 03. 3. Register New Workshop

- App: Platform Admin
- Figma node: `1:3798`
- Frame: 1280x1202 px (desktop web)
- Export folder: `screens/03_3._Register_New_Workshop`
- Sources read: `3._Register_New_Workshop.json`, `3._Register_New_Workshop@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: high — complete one-column form, measured geometry, readable labels.

## 1. Purpose
Onboarding form for a new workshop “node”: business name, location/region, primary contact email, an initial template suite, and an automatic master-catalogue sync switch.

## 2. Layout structure
Root `1:3798` vertical, 1280x1202, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:3799` 1024x1202, padding 64/64/32/64, fill `#FFFFFF`; inner `Container` `1:3800` 896 wide, padding 24/0/96/0.
- `Breadcrumb & Page Identification` `1:3801` 896x140 (`margin` bottom 32): breadcrumb 896x18, 32/800 H1 896x38, 576x40 subtitle.
- `Massive Centered Pure White Card` `1:3819` 896x846, radius 32, padding 48, fill `#FFFFFF`.
- `Form` `1:3820` 800x750, gap 32:
  - `Entity Information Group` `1:3821` 800x392, gap 28: three 800x112 fields (label row 22, 80 px input, 22 px help).
  - `Initial Inspection Template Assignment` `1:3864` 800x102, padding-top 8, gap 8: label 800x22 + 800x64 dropdown.
  - `Node Configuration Pill Selector` `1:3878` 800x80, padding 20, gap 198, fill `#F4F3F8`: copy 498x40 + 56x32 toggle.
  - `Submission Row` `1:3889` 800x80, padding-top 24: text link left, 207x56 emerald pill right.
- `Header` `1:3900` 1024x64 glass; `Aside` `1:3925` 256x800 with nav.

One column, fixed 896 card on a 1024 content area (64 px gutters). No scroll, stepper, or responsive variant is exported. Long forms would need vertical scrolling.

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 25 | Labels, help text, body |
| `#FFFFFF` | 13 | Card/fields |
| `#10B981` | 10 | CTA, toggle, required, breadcrumb current |
| `#1B1B25` | 7 | Headings/values |
| `#F4F3F8` | 7 | Toggle row |
| `#3C4A42` | 5 | Inactive nav |
| `#5E5D6966` | 5 | Breadcrumb separators |
| `#1A1B1F` | 3 | Search/chrome |
| `#5E5D6999` | 3 | Placeholder |
| `#006C49` | 1 | Avatar |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans`. H1 32/800 LH38 -0.80; subtitle 14/500 LH20 `#5E5D69`; field labels 16/700 LH22 `#1B1B25`; “REQUIRED” 11/600 uppercase +1.10 `#10B981`; inputs 16/500; help 13/400 LH18; toggle title 16/700 + body 13/400; CTA 14/700 white.

### Radii, shadows, strokes, spacing
- Radii: card 32; pills/pills-toggle 9999; fields appear 0–8 px (no visible rounded field edge).
- Shadows: field `0 1 3 .02`, card `0 4 16 .04`, buttons `0 2 6 .15`/`0 4 16 .04`; no heavy elevation.
- Strokes: none.
- Spacing: form gap 32; field gap 8; group gap 28; card padding 48; page gutters 64; section bottom 96.

## 4. Components
Flattened export. Patterns: breadcrumb, page title/subtitle, large form card, labeled text field with leading icon, required tag, dropdown, toggle row, text link, 56 px primary pill CTA.
Mapping: `AppTextField`, `DropdownButtonFormField`, Material `Switch`, `AppButton` — all exist in some form; breadcrumb, required tag, toggle-row card, and 896 px form card are not design-system components.

## 5. Assets
19 assets, all individual SVG icons. No raster/composed/photo. Icons: logo/nav, search/chrome, field-leading icons (building, pin, @), shield, chevron, arrow.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Breadcrumb | PLATFORM / WORKSHOPS / NEW ENTITY | — | “NEW ENTITY” is a new route |
| Title | Register New Workshop | — | No current screen |
| Subtitle | “Deploy a new operational node… localized diagnostics, and technician seat access.” | No | Build/ops metaphor |
| Workshop Business Name | e.g. Apex Fleet Central | `Workshop.name` | Required |
| Location / Region | e.g. San Francisco Bay Area | No | `Workshop` has `branchName` and `timezone`, no region |
| Region help | “Determines regional compliance standards and daylight calibration defaults.” | No | Invented compliance behaviour |
| Primary Contact Email | e.g. operations@apexfleet.com | No | No email column on `Workshop` |
| Email help | “Receives root node provisioning credentials and critical shift digests.” | No | No dispatch service |
| Initial Template | 100-Point Standard Check v2.0; “Verified fleet standard • Mechanical, OBD-II, and Body Exterior” | No | No template assigned at workshop creation |
| Auto sync | Automatic Master Catalog Sync; “Propagate centralized OEM repair schemas and torque matrices immediately” | No | No sync job or OEM schema/torque data |
| Toggle | On | No | New setting |
| Discard & Return | — | — | Cancel |
| Create Workshop | — | — | Inserts a workshop; no endpoint exists |

No customer PII/VIN/plate. “Apex Fleet Central” and `operations@apexfleet.com` are fictional sample data.

## 7. States shown / not shown
Shown: empty form, pre-filled template, toggle on, enabled CTA. Not shown: required/validation errors, duplicate workshop, long-name overflow, loading/submitting, success, permission failure, offline, disabled CTA, template-empty state, RTL, keyboard focus, 200% text.

## 8. Implied interactions
Enter name/region/email; choose a template; toggle auto-sync; discard/return; create workshop. No confirmation of region/compliance consequences before save.

## 9. Correspondence to current product
New screen/feature. There is no create-workshop UI in `admin_app`, no `createWorkshop` method in `admin_api.dart`, and no `POST /api/v1/platform/workshops` in `PlatformController` (only `GET /workshops` and `GET /{id}`). Phase-1 `08-api-design.md` and `04-platform-admin-hierarchy.md` list `POST /platform/workshops` as planned, but it is not implemented. `Workshop` (tenancy) stores only `name`, `status`, `branchName`, `timezone`. Implementing needs a server endpoint, request validation, region field, contact field, template assignment, and sync option.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “no certification/‘verified by’/compliance claims.” Evidence: “100-Point Standard Check v2.0 — Verified fleet standard” (`1:3872`–`1:3874`) and “regional compliance standards” (`1:3849`).
- Rule: “Never invent versions/licences/measurements/results.” Evidence: “v2.0”, “OEM repair schemas and torque matrices”, “daylight calibration defaults” are unsourced and not modelled.
- Rule: “no business logic/API/model/server change.” Evidence: workshop creation, contact-email ownership, template assignment and catalogue sync are all new server behaviour; the frame cannot be built as UI-only against today’s API.
- Rule: “UI layer only; no … permission change.” Evidence: “technician seat access” implies licence/seat provisioning not present in the product.
- Rule: “external delivery requires consent/policy.” Evidence: “Receives root node provisioning credentials and critical shift digests” assumes outbound email/digest delivery with no provider or consent model.
- Rule: “tokens from central tokens.” Evidence: 32 px card radius, 48 px card padding, `#10B981`, and Plus Jakarta Sans are not in the current token/theme set.

## 11. Open questions / could not verify
- Is region a free-text field, a country/timezone enum, or an actual compliance selector? No model exists.
- Should a workshop creation assign a template at all, or should templates stay Workshop Admin-owned?
- Is “Automatic Master Catalog Sync” a real product switch? Current design says master content is downloaded by clients, not pushed by workshop creation.
- Does the contact email receive anything? Invitations go to the invitee, not the workshop contact.
- No error/loading/success/RTL states.
