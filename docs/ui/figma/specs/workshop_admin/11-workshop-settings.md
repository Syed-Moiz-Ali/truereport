# 11. Workshop Settings

- App: Workshop Admin
- Figma node: `1:2645`
- Frame: 1280x1674 px (desktop web form, >=1200 per `AppBreakpoints.desktop`)
- Export folder: `screens/11_11._Workshop_Settings`
- Sources read: `11._Workshop_Settings.json`, `11._Workshop_Settings@2x.png`, `assets/manifest.json`
- Export-order note: package index **11** equals Figma screen **11**. The inversion is at package index **07** = screen **6** and package index **06** = screen **7**; this file is otherwise aligned.
- Confidence: medium. Layout and visual tokens are precise; the screen is largely new product surface because no workshop settings route/API/model exists for contact, address, licences, auto-send or telemetry.

## 1. Purpose
A long-form workshop configuration page for business identity, contact/address, default template, automated PDF dispatch and a mandatory-photo policy, with three operational metric cards and a save bar.

## 2. Layout structure
Root is a fixed 1280x1674 `VERTICAL` frame (`FIXED/HUG`), white.

- `Background` (`1:2646`) fills width with 96 left padding.
- `Main` (`1:2647`) 1184x1674 at x=96, padding 80/80/48/80.
- Content (`1:2648`) 1024x1546, centered, vertical gap 48.
- Header block (`1:2649`) 1024x111, `SPACE_BETWEEN`: left badge `CONFIGURATION ENGINE`, H1 32/38, 16/24 subtitle; right 151.6x75 `Quick Facility Snapshot Pill` (32px icon, `Sync Status`, `Shop Net Synchronized`).
- Metrics row (`1:2669`) 1024x96, gap 24: three 325.3x96 cards, radius 24, padding 24 (`08 / 08 Operational`, `< 140 ms`, `99.94%`).
- Form stack (`1:2697`) 1024x1059, vertical gap 40:
  - `Business Profile` (`1:2698`) 1024x479, radius 24, padding 40, gap 32. Header 72 with 48px icon, H2 22/28, 13/18 subtitle, `LEGAL ENTITY` pill. Grid (`1:2711`) 944x208: workshop name full width 944x88; contact phone and address 456x88 each. Badges row (`1:2739`) 944x55: region chip and DOT chip.
  - `Preferences` (`1:2750`) 1024x540, radius 24, padding 40, gap 32. Header 72 + `Standard Flow` pill. Default template selector (`1:2764`) 944x104 (78px card). Toggles (`1:2779`) 944x220: two 90px rows, 24 gap, each with 40px icon, 16/22 title, 13/18 description and a 56x32 emerald switch.
- Bottom actions (`1:2804`) 1024x136, `SPACE_BETWEEN`: helper text `All changes sync to shop fleet nodes instantly with zero downtime.` and `Save Settings` 199.8x56.
- Shell `Header` (`1:2815`) 1184x80 overlay and `Aside` (`1:2838`) 96x800; Settings is active.
- Scroll: content grows to 1674; no scrollbar. The save bar sits at the bottom of the form, not fixed.
- Responsiveness: fixed 1024 content and two-column 456 fields; no phone/tablet or RTL variant. `Main` side padding 80 is wider than the rest of the set (40).

## 3. Visual tokens observed
### Colours (exact hex, usage, approx count)
| Hex | Usage | Count |
|---|---|---:|
| `#5E5D69` | Secondary text, labels, helper copy | 30 |
| `#FFFFFF` | Cards, inputs, save row | 23 |
| `#1A1B1F` | Primary text/headings | 19 |
| `#F4F3F8` | Tonal chips, icon tiles, badges, inputs | 19 |
| `#10B981` | Toggles, icons, save button, status dots | 14 |
| `#006C49` | Small positive text | 2 |
| `#10B9811A` | Default-template icon tint | 1 |
| `#3C4A42` | `BAY ACTIVE` text | 1 |
| `#FFFFFFE5` | Sticky header tint | 1 |

`#10B981` is used as text for `Standard Flow` (11px), as icons and as toggle/button fill. White on `#10B981` is ~2.54:1, and `#10B981` on white is ~2.54:1, both below WCAG AA for text and non-text UI.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)
All `Plus Jakarta Sans`; no Arabic family or RTL text.

| Role | Weight | Size/line | Tracking | Usage |
|---|---|---|---|---|
| H1 | 800 | 32/38 | -0.80 | `Workshop Settings` |
| H2 | 700 | 22/28 | -0.44 | `Business Profile`, `Preferences` |
| Metric | 700 | 22/28 | -0.44 | `08 / 08`, `< 140 ms`, `99.94%` |
| Field value | 700 | 16/22 | -0.16 | Workshop name, phone, address, template |
| Body/title | 500-700 | 16/24, 16/22 | -0.16 | Subtitle, toggle titles |
| Field label | 600 | 12/16 | +0.24 | `Workshop Name`, `Contact Phone`, `Address` |
| Micro | 600 | 11/14, 12/12, 11/11 | +0.24 to +0.44 | Badges, `Sync Status`, helper copy |
| Toggle body | 400 | 13/18 | 0 | Auto-send/photo descriptions |

Left-aligned; save label centered. `Shop Net Synchronized` wraps to three lines in a 67.6px column, indicating an overflow/width defect that must be handled for Arabic and 200% text.

### Radii, shadows/elevation, strokes, spacing
- Radii: 24 for metric cards and form cards; 16 for inputs, icon tiles, toggle rows and save button; 48/9999 for badges, chips, switches and pills.
- Shadows: cards use the standard two-layer shadow; save button and green toggles use the emerald CTA shadow; header one shadow.
- Strokes: cards/inputs borderless; `DOT Certified` and region chips are tinted fills, not borders.
- Spacing: 24 (29), 12 (25), 8 (20), 4 (18), 16 (18), 40 (13), 20 (8), 32 (8), 48 (4), 80 (3), 96 (1). Main padding 80 and card padding 40 are off the core token scale.

Token drift: current `AppTheme` primary is `#0B3B4A`, secondary `#0F6B6F`, and danger/success use different pairs; `AppRadiiTokens` max 16 before pill. This frame uses `#006C49`/`#10B981` and 24/48 radii.

## 4. Components
| Figma pattern / node | Map to current design system | Notes |
|---|---|---|
| Form cards `1:2698`, `1:2750` | `AppCard` / `SectionHeader` | Current cards are tonal; these are white elevated cards. |
| Text inputs `1:2715`, `1:2724`, `1:2733` | `AppTextField` | Filled/borderless theme; these are white cards with icon prefix. |
| Default template selector `1:2767` | `DropdownButtonFormField` / `AppListTile` | Current builder uses a dropdown; this is a rich selector row. |
| Toggles `1:2790`, `1:2802` | Material `Switch` | No dedicated switch component/token. |
| `Save Settings` `1:2810` | `AppButton` primary | No settings endpoint. |
| Metric cards `1:2670`-`1:2688` | `AppCard` | No metric-pod component. |
| `Sync Status` pill `1:2659` | `StatusChip` | No sync state/data. |
| `.LEGAL ENTITY` / `DOT Certified` chips | `StatusChip` | Certification chip needs a real licence field. |
| Header/aside | `AppBar` + `NavigationRail` | Current shell has Jobs/Staff/Templates tabs, no Settings. |

## 5. Assets
`assets/manifest.json` reports **26** assets: 24 individual SVGs (icons) and 2 composed SVGs (`Nav` 96x600, `Aside` 96x800). **0 raster** assets; no photos, avatars or vehicle images. All non-shell graphics are small icons (16-20px).

## 6. Content and data
| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Badge | `CONFIGURATION ENGINE` | No | New label. |
| Title | `Workshop Settings` | Route target only | No `/settings/workshop` route in the client. |
| Subtitle | `Configure shop telemetry, compliance protocols, and customer dispatch.` | No | Claims telemetry/compliance features that do not exist. |
| Sync | `Sync Status`, `Shop Net Synchronized` | No | No sync state in the admin app. |
| Metric | `ACTIVE INSPECTION BAYS`, `08 / 08 Operational` | No | No bay model. |
| Metric | `AUTO-DISPATCH LATENCY`, `< 140 ms` | No | No dispatch/latency telemetry. |
| Metric | `OPTICAL AI INTEGRITY`, `99.94%` | No | No optical AI. |
| Card | `Business Profile`; `Public credentials stamped on certified vehicle inspection slips` | `Workshop.name`, `branchName` for identity | "Certified vehicle inspection slips" is a claim. |
| Chip | `LEGAL ENTITY` | No | New label. |
| Field | `Workshop Name`, `Apex Fleet Hub — Bay District` | `Workshop.name` / `branchName` | Could map to existing name/branch. |
| Field | `Contact Phone`, `+1 (555) 382-9011` | No | No phone field on `Workshop`; US number in a UAE-default product. |
| Field | `Address`, `4200 Industrial Parkway, Suite 4B` | No | No address field; US address sample. |
| Chip | `Region: Northern Cal/Pacific Sector` | No | No region field; wrong market. |
| Chip | `DOT Certified #99401-AF` | No | Prohibited certification/licence claim; no field. |
| Card | `Preferences`; `Inspection routines, optical validation, and distribution rules` | No | New settings surface. |
| Chip | `Standard Flow` | No | No stored setting. |
| Field | `Default Template`, `100-Point Standard Check v2.0` | `TemplateSummary.name/currentVersion` could be used | "100-Point" is an invented count; `v2.0` is not the integer version format. |
| Claim | `Compliant with ANSI Tier-4 EV & Combustion Fleet standards` | No | Prohibited compliance claim; no field. |
| Toggle | `Auto-Send PDF to Customers`; `Immediately deliver cryptographic-stamped PDF summaries via SMS & email upon technician sign-off.` | Delivery send exists manually | Auto-send, cryptographic stamp and automatic SMS+email are not implemented; requires consent per channel. |
| Toggle | `Mandatory Optical Photo Verification`; `Forces technicians to capture at least 4 high-resolution angle photos before clearing safety critical faults.` | `TemplateItemView.evidenceRequirement/minPhotos` per item | A workshop-wide setting would need server validation against master locks; "clearing safety critical faults" is unsafe wording. |
| Helper | `All changes sync to shop fleet nodes instantly with zero downtime.` | No | False operational claim. |
| Action | `Save Settings` | No | No endpoint. |

The screen shows a workshop phone and address (business contact data), not customer PII, but both are absent from the current model. The licences, standards, latency, AI percentage and bay counts are sample/invented and must not ship.

## 7. States shown / not shown
Shown: populated defaults, both toggles on, selected default template, green sync status.

Not shown: loading, empty/no default template, validation errors, save in progress, save success, save failure/conflict, disabled workshop, read-only/Platform-Admin-only fields, offline, unsaved changes, 200% text, RTL/Arabic, phone/tablet.

## 8. Implied interactions
Edit workshop name, phone and address; open the default-template selector; toggle auto-send; toggle mandatory photos; save. There is no cancel/reset, no unsaved-change warning, no confirmation for automatic delivery, no licence upload/verification and no permission indication for which fields only Platform Admin can change.

## 9. Correspondence to current product
- **New screen/feature; needs server/model changes.** `client/apps/admin_app/lib/src/admin_router.dart` has no `/settings/workshop`; `workshop_admin_home.dart` has Jobs/Staff/Templates only. `docs/phase-1/01-navigation-maps.md` lists `/settings/workshop` as a Phase 1 target, not implemented.
- **Model gap:** `Workshop` has only `id`, `name`, `status`, `branchName`, `timezone`. `WorkshopDto` exposes `id`, `name`, `status`, `memberCount`. There is no contact phone, address, region, DOT licence, default template, auto-send or photo policy. `WorkshopController` exposes only `GET /api/v1/workshops/{workshopId}`; there is no settings GET/PUT.
- **Delivery gap:** sends are explicit `POST /api/v1/workshop/jobs/{jobId}/deliveries` with consent checks; there is no auto-send trigger on finalization. `docs/phase-7/00-decisions.md` §2 requires channel consent (WhatsApp/SMS/public link/email) before send.
- **Template gap:** a default template is a job-creation input, not a stored workshop setting in the current model.
- **Telemetry gap:** no bay, sync, latency, AI or fleet-node concepts exist in server or client.
- A UI-only change cannot deliver this screen; it needs schema, API, permissions, validation and likely delivery-automation work.

## 10. Locked-rule conflicts / unsafe-to-ship content
1. **Certification/licence claims.** The task rule forbids certification/compliance claims. The screen shows `DOT Certified #99401-AF`, `Public credentials stamped on certified vehicle inspection slips`, `Compliant with ANSI Tier-4 EV & Combustion Fleet standards` and a "compliance protocols" subtitle. No licence/standard data exists.
2. **Auto-send bypasses consent.** `docs/phase-7/00-decisions.md` §2 requires latest `WHATSAPP`/`SMS`/`EMAIL` consent and `PUBLIC_LINK` consent as applicable. `Auto-Send PDF ... upon technician sign-off` would send without a per-send consent check and is not implemented. It also conflicts with the deliberate manual send flow.
3. **Photo policy may weaken master safety rules.** `docs/phase-1/05-master-library-and-templates.md` §4.2 permits a Workshop Admin to increase, never decrease, master evidence requirements. A workshop-wide "at least 4 high-resolution angle photos before clearing safety critical faults" is a new global rule that needs server validation and could conflict with item-level masters; "clearing safety critical faults" also implies a pass/clear action that the result model avoids.
4. **Invented telemetry.** `08 / 08 Operational`, `< 140 ms`, `99.94% Optical AI Integrity`, `Shop Net Synchronized` and "zero downtime" are invented measurements/results, violating "Never invent versions/licences/measurements/results."
5. **Wrong market data.** `+1 (555)`, `4200 Industrial Parkway`, `Northern Cal/Pacific Sector` and `DOT` are US samples in a UAE-first product (`Workshop.timezone = Asia/Dubai`, `docs/phase-1/03-localization-and-rtl-rules.md` §3.2). They must not become defaults.
6. **No settings permission model.** `docs/phase-1/02-screen-inventory.md` A15 says Platform Admin controls plan-level settings; the screen gives every field to Workshop Admin with no read-only/role split.
7. **WCAG 2.2 AA.** White on `#10B981` is ~2.54:1; `#10B981` text/icons on white are ~2.54:1; 11px labels; `Shop Net Synchronized` already wraps awkwardly in a 67.6px column.
8. **Tokens/fonts/RTL.** `#006C49`/`#10B981`, 24/48 radii and `Plus Jakarta Sans` are not current tokens; no Arabic/RTL form layout, no field direction for the address/name.

## 11. Open questions / could not verify
- Which settings may a Workshop Admin edit, and which are Platform Admin-only? No permission model exists.
- Are contact phone/address real required fields? They are business data, not customer PII, but still need a schema and retention rule.
- Is `DOT Certified` a real licence field, a free-text field, or a false claim to remove? Who verifies it?
- Is auto-send approved under D8? Which channels, consent version and retry policy apply?
- Is the mandatory-photo setting global, per template, or per master item? How does it interact with `evidenceRequirement`/`minPhotos` locks?
- Where do bay count, sync status, latency and optical-AI integrity come from? None exist.
- What is `100-Point Standard Check v2.0`, and is `v2.0` a real template version?
- What are the save success/failure/conflict states and the unsaved-change behaviour?
- What are the Arabic labels and RTL layout for the two-column form?
