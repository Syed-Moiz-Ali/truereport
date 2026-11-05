# 10. Share-Link Deactivation

- App: Workshop Admin
- Figma node: `1:2502`
- Frame: 1280x1024 px (desktop web, >=1200 per `AppBreakpoints.desktop`)
- Export folder: `screens/10_10._Share-Link_Deactivation`
- Sources read: `10._Share-Link_Deactivation.json`, `10._Share-Link_Deactivation@2x.png`, `assets/manifest.json`
- Export-order note: package index **10** equals Figma screen **10**. The inversion is at package index **07** = screen **6** and package index **06** = screen **7**; this file is otherwise aligned.
- Confidence: medium. The modal geometry is precise; the correspondence is medium because the background viewer, link URL, access log, IP/device data and free-text-only reason do not match the current API or data model.

## 1. Purpose
A destructive confirmation modal for deactivating a public report link. It overlays a blurred report viewer, states that customer access will stop, requires a reason and confirms with a red action; an audit note sits under the buttons.

## 2. Layout structure
Root is a fixed 1280x1024 `VERTICAL` frame (`FIXED/HUG`), white.

- `Background` (`1:2503`) fills width with 96 left padding.
- `Main` (`1:2504`) 1184x1024 at x=96, padding 80/40/368/40.
- Background viewer (`1:2505`) 1104x576, vertical gap 32, layer blur radius 24. It is context only, not interactive.
  - Vehicle summary strip (`1:2506`) 1104x128, radius 32, padding 32: vehicle icon 64, `2023 Porsche Taycan GTS`, `Live Shared` pill, `VIN: WP0AA2Y15PSA90412 • RO #8829-FLT • Bay 04`, `Viewed 14 mins ago` pill and the public URL pill.
  - Grid (`1:2531`) 1104x416, gap 32: schematic card 725.3 (radius 32, padding 32; header + 661.3x288 vehicle image) and activity card 346.7 (radius 32, padding 32; `Client Activity Log` and two events). The `Revoke Access` control is a 282.7x48 pill at the bottom of the activity card.
- Shell `Header` (`1:2567`) 1184x80 overlay: `BAY ACTIVE · Shop Floor #04`, search, user.
- `Aside` (`1:2590`) 96x1024; Jobs is active.
- Scrim + modal (`1:2609`) 1184x944 at x=96,y=80, padding 24, fill `#FFFFFFB2`, centered. The dialog (`1:2610`) is 448x576.1, radius 24, padding 40, vertical gap 28.
  - Top: 56x56 red icon tile, `Deactivate Public Link` 32/32 ExtraBold, 14/19.25 body copy.
  - Warning box (`1:2620`) 368x76, radius 16, `#FFDAD666` fill: 36px red icon + `This will instantly block customer access`.
  - Reason field (`1:2626`) 368x76: `REASON FOR DEACTIVATION (REQUIRED)` 11/14 uppercase, 52px white input with placeholder.
  - Actions (`1:2632`) 368x66: `Cancel` text button 86.9x42 and `Confirm Deactivation` 265.1x50 red `#BA1A1A`.
  - Audit stamp (`1:2640`) 368x18: small shield icon + `Action logged to Shop Audit Trail (ID #ACT-9902)`.
- Scroll: modal fits within 944; background viewer is fixed. No scroll or sticky header.
- Responsiveness: only fixed 1280 desktop; a 448px dialog is centered; no phone/tablet or RTL variant.

## 3. Visual tokens observed
### Colours (exact hex, usage, approx count)
| Hex | Usage | Count |
|---|---|---:|
| `#5E5D69` | Secondary text, placeholder, event metadata | 20 |
| `#FFFFFF` | Dialog, cards, header | 13 |
| `#1A1B1F` | Primary text, link URL | 10 |
| `#F4F3F8` | Pills, icon tiles, surfaces | 9 |
| `#006C49` | Positive icons/dots | 4 |
| `#BA1A1A` | Destructive icon/button | 3 |
| `#10B981` | Status dot, active nav | 2 |
| `#EEEDF3` | Neutral pills, URL pill | 2 |
| `#002113` | `Live Shared` text | 1 |
| `#3C4A42` | Search text | 1 |
| `#5E5D69B2` | Placeholder opacity | 1 |
| `#6FFBBE` | `Live Shared` pill background | 1 |
| `#93000A` | Warning box text | 1 |
| `#FFDAD6` | Warning icon background | 1 |
| `#FFDAD666` | Warning box fill | 1 |
| `#FFDAD699` | Modal icon overlay | 1 |
| `#FFFFFFB2` | Scrim | 1 |
| `#FFFFFFE5` | Header tint | 1 |

White on `#10B981` is ~2.54:1; white on `#BA1A1A` is high contrast and acceptable for the destructive button. `#93000A` on `#FFDAD666`-over-white is strong.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)
All `Plus Jakarta Sans`; no Arabic family or RTL text.

| Role | Weight | Size/line | Tracking | Usage |
|---|---|---|---|---|
| Dialog H2 | 800 | 32/32 | -0.80 | `Deactivate Public Link` |
| Vehicle title | 700 | 22/28 | -0.44 | `2023 Porsche Taycan GTS` |
| Card title | 700 | 16/22 | -0.16 | `Client Activity Log`, `Exterior Inspection Schematics` |
| Body | 400-500 | 14/19.25-20 | -0.07 | Dialog copy, VIN strip |
| Field/label | 600 | 11/14 | +0.44 to +0.55 | Uppercase reason label |
| Micro | 600-700 | 12/16, 12/15 | +0.24 | Buttons, URL, `Live Shared` |
| Tiny | 600 | 11/14 | +0.44 | Audit stamp, `MULTI-ANGLE SCAN` |

Left-aligned except centered buttons/audit and some pill copy. Long public URL and VIN are single-line; RTL not designed.

### Radii, shadows/elevation, strokes, spacing
- Radii: 24 on the dialog; 32 on background cards; 16 on warning box, reason input and destructive button; 48/9999 on pills and status chips.
- Shadows: dialog and cards use the standard two-layer shadow (`0 2 8 rgba(0,0,0,0.016)` + `0 14 40 rgba(0,0,0,0.043)`); destructive button has a red ambient shadow; header one shadow.
- Strokes: no card borders; warning box is a tinted fill; the small red icon is a solid fill.
- Spacing: 32 (17), 12 (16), 16 (12), 20 (12), 24 (12), 8 (9), 40 (8), 4 (4). Modal padding 40, gap 28, dialog width 448 are off the main token scale.

Token drift: current `AppTheme` has no destructive button variant and uses `#A3231F`/`#FBE9E7` for danger; this frame uses `#BA1A1A` and pastel red. `#006C49`/`#10B981` and 24/32/48 radii are also not current tokens.

## 4. Components
| Figma pattern / node | Map to current design system | Notes |
|---|---|---|
| Destructive dialog `1:2610` | `ConfirmDialog` (`showAppConfirmDialog`) | Current helper supports destructive flag but always uses `AppButtonVariant.primary`; no red destructive button. The current revoke flow uses `showAppBottomSheet`, not `ConfirmDialog`. |
| Reason input `1:2629` | `AppTextField` | Current revoke sheet has an `AppTextField` note plus reason-code selector. |
| Warning box `1:2620` | No direct component | Could be `AppCard` + status colors; no warning-box component. |
| Reason codes | `AppSelectableText` | Current code shows privacy/security/legal/customer-request/other; the design omits them. |
| Buttons `1:2633`, `1:2635` | `AppButton` text/primary | No destructive variant/loading/disabled. |
| Background vehicle strip / grid | `AppCard`, `AppListTile` | Background is decorative context, not a reusable screen. |
| Activity log `1:2543` | No equivalent | No activity timeline component or data. |
| `Revoke Access` pill `1:2565` | `AppButton` tonal | Hidden behind the modal; duplicate trigger. |

## 5. Assets
`assets/manifest.json` reports **17** assets: 14 individual SVGs (icons) and 2 composed SVGs (`Nav` 96x824, `Aside` 96x1024), plus **1 raster** 512x279 vehicle schematic image (`assets/images/original/image-1-e0111f8e5f.jpg`). No avatar photo; the user avatar is a vector icon. The background vehicle image is a wireframe/schematic preview, not evidence.

## 6. Content and data
| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Vehicle | `2023 Porsche Taycan GTS` | `Vehicle.make/model/year` | Internal context; sample. |
| Link state | `Live Shared` | `ReportAdminDto.linkState` (`ACTIVE`) | Label does not match API state name. |
| VIN/RO/bay | `VIN: WP0AA2Y15PSA90412 • RO #8829-FLT • Bay 04` | `vinMasked` only; no RO/bay | Full VIN internal is allowed, but RO/bay are invented. |
| View time | `Viewed 14 mins ago` | No | No last-viewed field; `PublicShareLink` has no access log. |
| Share URL | `share.shopflow.io/r/Taycan-8829` | `publicUrl` after activation | Fake domain and human-readable token; actual token is 256-bit random. |
| Schematic | `Exterior Inspection Schematics`, `3 flags recorded by Tech M. Vance`, `MULTI-ANGLE SCAN` | Findings/evidence could be counted | No flags/schematic fields. |
| Activity | `Client Activity Log` | No | New tracking feature. |
| Activity row 1 | `Fleet Admin Opened Link`, `IP: 198.51.100.4 • Chrome Mobile` | No | IP/device tracking and customer identity; no fields. |
| Activity row 2 | `Damage Markup #02 Zoomed`, `Left rocker panel scratch` | No | Client interaction tracking; no fields. |
| Background action | `Revoke Access` | `POST .../link/revoke` | Duplicate trigger; label differs from dialog. |
| Shell | `BAY ACTIVE`, `Shop Floor #04`, search, `Marcus Vance`, `Lead Inspector` | `displayName`; role enum | `Lead Inspector` is a display title. |
| Dialog title | `Deactivate Public Link` | `POST .../link/revoke` | Matches concept. |
| Dialog body | `Customer and fleet manager will no longer be able to view this live report.` | No | Mentions a fleet manager/customer role that has no portal. |
| Warning | `This will instantly block customer access` | Revocation is immediate at origin | Does not mention cached copies/screenshots/PDFs. |
| Reason | `REASON FOR DEACTIVATION (REQUIRED)` / `e.g. Disputed damage markup or revised intake` | `reasonCode` enum + `note` | Design has free text only; API requires `reasonCode` from a fixed set. |
| Actions | `Cancel`, `Confirm Deactivation` | Revoke endpoint | Red destructive action; no loading/disabled state. |
| Audit | `Action logged to Shop Audit Trail (ID #ACT-9902)` | Audit event exists | No audit ID is returned to the client; `/audit` is hidden by default (RQ4). |

The screen shows a full VIN, public URL, a customer-identifying activity log and an email-like recipient context. All of these are sample data and must not be seeded as real.

## 7. States shown / not shown
Shown: active link (`Live Shared`), populated activity log, empty reason field, enabled confirm button.

Not shown: no active link, already revoked, reason required/validation error, note length error, loading, success, API error/409, offline, permission denied, consent missing, multiple active links, "copies cannot be recalled" acknowledgement, re-authentication, 200% text, RTL/Arabic, phone/tablet.

## 8. Implied interactions
Type a reason; cancel; confirm deactivation; optionally scroll the background activity log. The modal has no reason-code selector, no optional note field, no confirmation checkbox and no loading state. `Confirm Deactivation` is visually enabled while the required field is empty.

## 9. Correspondence to current product
- **Existing feature:** `client/apps/admin_app/lib/src/pages/report_page.dart` `_revoke()` opens a bottom sheet with five `AppSelectableText` reason codes (`PRIVACY`, `SECURITY`, `LEGAL`, `CUSTOMER_REQUEST`, `OTHER`) plus an `AppTextField` note, then calls `POST /api/v1/workshop/jobs/{jobId}/report/link/revoke`.
- **Server contract:** `RevokeLinkRequest(reasonCode @NotBlank @Size(max=60), note @Size(max=500))`; `ReportService.REVOCATION_REASONS` accepts only `PRIVACY`, `SECURITY`, `LEGAL`, `CUSTOMER_REQUEST`, `OTHER`. The design's free-text example does not satisfy this contract.
- **Revoke scope:** `ReportService.revoke` finds all `ACTIVE` links for the report version and revokes each; ADR-0018 says revoking a report link revokes all active links. The design says "this live report" and implies one link.
- **No access log:** `PublicShareLink` stores status, PDF flag, activated/revoked timestamps and revocation reason/note; it has no view count, last-viewed time, IP, user-agent or client activity. The design's `Viewed 14 mins ago`, IP, browser and "Fleet Admin Opened Link" need new server/data changes.
- **No customer portal:** `docs/phase-1/01-navigation-maps.md` says "The customer never enters an app or portal"; "Fleet Admin Opened Link" implies a tracked customer identity that does not exist.
- **New UI state:** this is an existing flow, but the modal, activity log, link preview and free-text reason are **new** and partly require server/data changes. A UI-only change can restyle the current bottom sheet but cannot create the log or free-text-only contract.

## 10. Locked-rule conflicts / unsafe-to-ship content
1. **Reason contract mismatch.** `docs/phase-1/06-public-report-design.md` §4.3 requires a reason of "privacy, security, legal or customer request"; the server accepts only those codes plus `OTHER`. The design shows one free-text field and a placeholder that is not a valid code. A user could not submit the form as drawn (`422 REVOCATION_REASON_INVALID`).
2. **No consequence of cached copies.** `docs/phase-1/06-public-report-design.md` §4.3 says "Consent withdrawal → revoke link; explain copies cannot be recalled." The modal only says access will be blocked and omits that copies/screenshots/PDFs already shared cannot be recalled (`docs/phase-8/00-decisions.md` §5, risk TR-R033).
3. **Multiple links are hidden.** ADR-0018: "Revoke all active links for a report version when the admin revokes the report link." The design presents a single link and a single "Live Shared" state; this can mislead the admin about other delivery links.
4. **Invented access log and customer identity.** The task rule forbids new business logic/state/server changes without permission, and `docs/phase-1/11-security-and-privacy-design.md` §7.3 requires PII minimisation. Showing a customer/fleet-manager identity, IP address, browser and interaction history is a new tracking feature with privacy impact.
5. **Guessable public URL.** The sample `share.shopflow.io/r/Taycan-8829` is not a 256-bit token. `docs/phase-1/13-adrs/0010-public-token-and-allowlist.md` requires at least 32 random bytes, base64url, and token hash storage; a human-readable token is unsafe.
6. **Audit ID exposure.** `Action logged to Shop Audit Trail (ID #ACT-9902)` implies the client receives an audit ID. Current revoke returns only link state; `/audit` is hidden by default (RQ4). This needs an API/permission change.
7. **Full VIN/screenshot risk.** Internal screens may show full VIN, but placing it behind a modal that invites screenshots during a privacy action is a needless exposure. The current report viewer uses `vinMasked`.
8. **No "Fleet Admin" role/portal.** The customer/fleet manager is not a platform user; showing "Fleet Admin Opened Link" conflicts with "no customer app/portal".
9. **WCAG 2.2 AA.** White on `#10B981` is ~2.54:1; the destructive button's white-on-red is fine, but the required-field state is not indicated beyond a label, and there is no error/disabled state.
10. **Tokens/fonts/RTL.** `#006C49`/`#10B981`/`#BA1A1A` and 24/32/48 radii are not the current token set; `Plus Jakarta Sans` is licence-pending; no Arabic/RTL layout.

## 11. Open questions / could not verify
- Should the UI keep the existing reason-code selector, or is the API planned to accept free text? If free text, which code is stored and how is it audited?
- Should the dialog mention all active links and that copies cannot be recalled? Should the admin acknowledge this?
- Where would `Viewed 14 mins ago`, the client activity log, IP and browser come from? Is that tracking approved and lawful?
- Is "Fleet Admin" a real persona? No customer portal or customer login exists.
- Should the full public URL be shown here, and is that URL still retrievable after the first display? The current design stores only a token hash and shows the URL once at activation.
- Should `Confirm Deactivation` require re-authentication or typed confirmation? It is a destructive, irreversible action.
- What is the source of `ACT-9902`, and should audit IDs be user-visible?
- What are the success, already-revoked and no-active-link states?
