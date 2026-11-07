# Screen 10 — Share-Link Deactivation (F3-0 group C)

- Figma source: `docs/ui/figma-export/Workshop_admin_figma/screens/10_10._Share-Link_Deactivation/10._Share-Link_Deactivation.json` (node `1:2502`, `serializedNodeCount: 143`), visual ref `10._Share-Link_Deactivation@2x.png`
- Prior spec (read, not edited): `docs/ui/figma/specs/workshop_admin/10-share-link-deactivation.md`
- Frame: **1280 × 1024**, `VERTICAL`, white — width 1280 confirmed as drawn (O3).
- Root children: `Background` (`1:2503`, 1280×1024, left pad 96) → `Header` (`1:2567`, 1184×80 at x=96) → `Aside` (`1:2590`, 96×1024) → `Frosted Glass Scrim & Modal Container` (`1:2609`, 1184×944 at x=96,y=80).

## Node-level layout (as drawn)
- Background viewer (`1:2505`, 1104×576, opacity ~0.4, layer-blur 24 — context only, non-interactive):
  - Vehicle strip (1104×128, radius 32): `2023 Porsche Taycan GTS`, `Live Shared` pill, `VIN: WP0AA2Y15PSA90412 • RO #8829-FLT • Bay 04`, `Viewed 14 mins ago` pill, public-URL pill `share.shopflow.io/r/Taycan-8829`.
  - Grid (1104×416, gap 32): schematic card with vehicle image + `Exterior Inspection Schematics`, `3 flags recorded by Tech M. Vance`, `MULTI-ANGLE SCAN`; activity card with `Client Activity Log` (`Fleet Admin Opened Link`, `IP: 198.51.100.4 • Chrome Mobile`; `Damage Markup #02 Zoomed`, `Left rocker panel scratch`) and a `Revoke Access` pill behind the modal.
- Scrim fill `#FFFFFFB2`; centered dialog (`1:2610`) 448×576.1, radius 24, padding 40, gap 28:
  - 56×56 red icon tile; title `Deactivate Public Link`; body `Customer and fleet manager will no longer be able to view this live report.`
  - Warning box (368×76, radius 16, `#FFDAD666`): `This will instantly block customer access`.
  - `REASON FOR DEACTIVATION (REQUIRED)` label + 52px input with placeholder `e.g. Disputed damage markup or revised intake` (free text only — no code selector).
  - `Cancel` text button + `Confirm Deactivation` red button (`#BA1A1A`).
  - Audit stamp: `Action logged to Shop Audit Trail (ID #ACT-9902)`.

## Components → `design_system`
- Dialog → `ConfirmDialog` (`showAppConfirmDialog`, `components/overlays.dart`). Current helper has no red destructive variant; current revoke flow uses `showAppBottomSheet`, not a dialog.
- Reason input → `AppTextField` (`components/inputs.dart`). Product pairs it with 5 `AppSelectableText` reason codes; the design omits the codes.
- Reason codes → `AppSelectableText`; `Cancel`/`Confirm` → `AppButton` text/primary (`components/buttons.dart`). No destructive/loading/disabled state is drawn.
- Warning box → no direct component (composable from `AppCard` + status tones; do not invent a new token).
- `Client Activity Log`, schematic panel → no equivalent (new tracking surface — do not build).
- Header/aside → existing shell (`admin_chrome.dart`, `components/navigation.dart`).

## Assets
- 17 assets per JSON: 14 single SVG icons + 2 composed (`Nav`, `Aside`) + **1 raster** 512×279 schematic vehicle image (`assets/images/original/image-1-e0111f8e5f.jpg`). No avatar photo.

## States shown / not shown
- Shown: one active link (`Live Shared`), populated activity log, empty reason field with confirm visually enabled.
- Not shown: no link / already revoked / no-active-link, reason-required and note-length validation errors, loading, success, API errors (`LINK_NOT_CREATED`, `REVOCATION_REASON_INVALID` 422, `CONSENT_REQUIRED`), offline, permission denied, multiple active links, re-auth, 200% text, RTL/Arabic, phone/tablet.

## Element → data/endpoint/state mapping
| Figma element | Maps to | Verdict |
|---|---|---|
| `Deactivate Public Link` + `Revoke Access` | `POST /api/v1/workshop/jobs/{jobId}/link/revoke` (`server/.../reports/api/WorkshopReportController.java:51-54`, `ReportService.revoke`, `client/.../pages/report_page.dart` `_revoke`) | Matches existing feature (intent only; control style differs) |
| Reason field (free text only) | `RevokeLinkRequest(reasonCode @NotBlank @Size(max=60), note @Size(max=500))` with `REVOCATION_REASONS = PRIVACY, SECURITY, LEGAL, CUSTOMER_REQUEST, OTHER` (`ReportService.java:36-37,166-189`) | LOCKED-RULE / contract conflict — free-text-only cannot submit; mandatory `reasonCode` selector must be kept |
| `This will instantly block customer access` | Revocation is immediate at origin (all `ACTIVE` links for the version are revoked, ADR-0018) | UI work only **iff** extended with the mandatory retained wording that copies/screenshots/PDFs already shared cannot be recalled (O8) |
| `Action logged to Shop Audit Trail (ID #ACT-9902)` | `PUBLIC_LINK_REVOKED` audit event (`ReportService.revoke`); client receives no audit ID | Needs server change to expose an ID — do not show an ID; keep a generic "this action is logged" line (O8) |
| `Live Shared`, `Viewed 14 mins ago` | `ReportAdminDto.linkState` (`ACTIVE`), no last-viewed field | Label is UI work; view-time is DATA GAP |
| `share.shopflow.io/r/Taycan-8829` | `ReportAdminDto.publicUrl` / `CreatedLink.publicUrl` (shown once at activation; only a token hash is stored) | DATA GAP as drawn (fake domain + human-readable token; real token is 256-bit random) |
| `VIN: WP0AA2Y15PSA90412 • RO #8829-FLT • Bay 04` | `vinMasked` only; no RO/bay fields | DATA GAP (full VIN internal-only; RO/bay invented) |
| `Client Activity Log`, IP `198.51.100.4`, `Chrome Mobile`, `Fleet Admin Opened Link`, zoom event | `PublicShareLink` has status/timestamps/revocation reason only — no view log | DATA GAP + privacy conflict — new tracking surface, do not build |
| `Customer and fleet manager will no longer…` | No customer/fleet portal exists (`docs/phase-1/01-navigation-maps.md`: customer never enters an app) | Wording conflict — must describe link holders generally, not portal roles |
| Audit-ID `#ACT-9902`, schematic flags, bay pills, search, `Lead Inspector` title | Audit exists without client ID; rest is shell/sample | UI work only except audit ID (drop it) |

## Classification
**Matches existing feature (revoke with mandatory reason + audit) — UI work only to restyle, with mandatory corrections.** The modal pattern, single-link framing, free-text-only reason, activity log, guessable URL, and audit-ID display each need a server change or violate a locked rule and must not ship as drawn.

## Locked rules applied (O8)
- Keep the mandatory reason (reason-code selector + optional note) and the audit event. Current `_revoke` bottom sheet with the 5 codes is the contract; the Figma free-text placeholder is not a valid code.
- Dialog copy must state that deactivation blocks future link access at origin **and that copies, screenshots, downloads, or PDFs already shared cannot be recalled**. The drawn `This will instantly block customer access` alone is insufficient.
- State all affected links (revoke applies to all active links for the report version), not "this live report" singular.
- No client-viewable audit ID, no IP/device/client-identity tracking, no re-auth or new flow invented here.

## New-component list
- None approved. Destructive dialog variant, warning box, and reason-code selector already exist as `ConfirmDialog`/`showAppBottomSheet` + `AppButton` + `AppSelectableText` + `AppTextField` compositions. Activity log, schematic panel, and URL-preview card are **rejected** (data-gap/privacy).

## Could not verify
- Whether the team wants the existing bottom sheet restyled or a true centered dialog; no decision record found in this pass.
- Exact scrim/blur token and red-button token — JSON gives `#FFFFFFB2` scrim, blur 24, `#BA1A1A` button vs product `#A3231F`/`#FBE9E7`; token mapping left to the design-system owner.
- Audit-surface visibility (`/audit` hidden by default, RQ4) — cited from prior spec; not re-verified against router in this pass.
- Arabic/RTL dialog layout, validation strings, and 200% text — not in the export.
