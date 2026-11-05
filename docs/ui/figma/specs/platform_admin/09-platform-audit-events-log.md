# 09. 10. Platform Audit Events Log

- App: Platform Admin
- Figma node: `1:5346`
- Frame: 1280x1171 px (desktop web)
- Export folder: `screens/09_10._Platform_Audit_Events_Log`
- Sources read: `10._Platform_Audit_Events_Log.json`, `10._Platform_Audit_Events_Log@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: high — four event cards, badges, labels, and geometry are explicit and readable.

> **Export-order note:** this file is manifest index **09**, but the Figma screen is numbered **10** and lives in `screens/09_10._Platform_Audit_Events_Log/`. The next file (`10-global-platform-settings.md`) is export index **10** but screen number **9**. The package orders screens by page position, not by screen label, so 09/10 are reversed.

## 1. Purpose
Read-only investigation view of sensitive platform activity: permission changes, deactivations, access grants, node provisioning, and master-content changes, with export/verify actions and a “ledger integrity” footer.

## 2. Layout structure
Root `1:5346` vertical, 1280x1171, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:5347` 1024x1171, padding 64/32/32/32.
- `Container` `1:5348` 960x1075, gap 32:
  - Header `1:5349` 960x129, padding-top 8, gap 122: title block 274x121 + actions 250x36 (Export CSV 117x36, Verify Nodes 125x36).
  - Filter bar `1:5373` 960x56, radius 16, padding 8, gap 201: segmented tabs 503x40 (All Events, Permission Changes, Deactivations, Access Grants) + search 240x34.
  - Event list `1:5389` 960x592, gap 24: four 960x130 cards, radius 16, padding 28; each has a 48x48 icon tile, event title/meta block, status badge, and 36x36 chevron button.
  - `Ledger Integrity Seal` footer `1:5527` 960x122, radius 16, padding 32: icon, seal copy, “SHOWING 4 OF 241 EVENTS”, “Load Previous Block”.
- `Header` `1:5542` 1024x64 glass; `Aside` `1:5567` 256x1058.

Cards are full-width rows, not a table. “Load Previous Block” replaces normal pagination. No scroll is modelled for longer event lists.

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 46 | Meta/timestamps/labels |
| `#F4F3F8` | 18 | Icon tiles, filter track, action pills |
| `#FFFFFF` | 14 | Cards/filter bar |
| `#10B981` | 11 | Node-provisioned icon/badge, verify CTA |
| `#DAD9DF` | 10 | Dot separators |
| `#1B1B25` | 8 | Event titles |
| `#1A1B1F` | 7 | Chrome/actor text |
| `#3C4A42` | 5 | Nav |
| `#EEEDF3` | 4 | Neutral fill |
| `#410004` | 2 | Security Action badge text |
| `#FFDAD7` | 2 | Security Action badge bg / icon tile |
| `#006C49` | 1 | Avatar |
| `#10B9811A` | 1 | Footer icon tint |
| `#6FFBBE` | 1 | Node-provisioned icon tile |
| `#B91A24` | 1 | Security/Audit icon accent |
| `#E3E1EF` | 1 | RBAC icon tile |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans`. H1 32/800 LH38 -0.80; event titles 18/700 LH24 -0.45; actor/meta 14/500 LH20; ID/hash 11/600 (monospace-like but family is Plus Jakarta Sans); badge labels 11/700; “SHOWING 4 OF 241 EVENTS” 11/600 uppercase; footer seal 16/700.

### Radii, shadows, strokes, spacing
- Radii: event cards 16; icon tiles 16; filter bar 16; buttons/pills 9999; status badges 9999.
- Shadows: cards `0 2 8 .02` + `0 14 40 .04`; primary verify `0 10 25 .25`; chevron `0 4 12 .18`; no borders.
- Strokes: none.
- Spacing: card padding 28; gap 24; icon-to-text 24; page 64/32; section gap 32.

## 4. Components
Flattened export. Patterns: audit page header with export/verify CTAs, filter tabs + search pill, event card (severity icon, hashed entity ID, actor/role, timestamp, region/metadata, status badge, chevron), integrity-seal footer with block paging.
Mapping: `AuditTab` currently uses `AppListTile` cards; `StatusChip` for badges; `AppButton`; no event card, filter tabs, hash chip, integrity footer, or block pagination component exists.

## 5. Assets
29 assets, all individual SVG icons. No raster/composed/photo. Icons: logo/nav, search/chrome, export, verify, shield/link, node, RBAC, schema, seal.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Eyebrow | TAMPER-PROOF LEDGER | No | Append-only DB, not a cryptographic ledger |
| Title | Security Audit Log | — | Current tab is “Audit” |
| Subtitle | “Cryptographic ledger of administrative operations and permission shifts across workshop tiers.” | No | No ledger/crypto |
| Export | Export CSV | No | No export endpoint; phase-1 says export is audited |
| Verify | Verify Nodes | No | No verification endpoint |
| Filters | All Events / Permission Changes / Deactivations / Access Grants | Partly (`action` data) | Server only accepts `limit` |
| Search | Filter by user or hash... | No | No hash; no server search |
| Event 1 | Public Share Link Deactivated · SHA256: 9b2d...f4e1 · Report #1042 · Marcus Vance (Lead Inspector) · Today, 14:32 EST · IP: 192.168.1.42 · Security Action | Partly (`action`, `actorRole`, `entityType`, `metadataJson`) | Link revocation is a Workshop Admin action; role/IP/EST are not modelled |
| Event 2 | Workshop Node Created: Apex Fleet Central · UUID: 8a4c...11a0 · Alex Vance (Principal Admin) · Cluster Region: US-East-1 · Node Provisioned | Partly (`action`, `entityType`) | Region not modelled; workshop creation endpoint absent |
| Event 3 | Admin Role Granted to David Vance · Policy: Role.SuperAdmin · Workshop A · Arthur Pendelton (Admin) · Dual-Factor Approved · RBAC Updated | Partly (`action`) | `SuperAdmin` role does not exist; 2FA is off by default |
| Event 4 | Master Checklist Schema Modified: Brake Wear · Rev v4.19 · Elena Rostova (Supervisor) · Tire & Chassis Specification v2 · Catalog Versioned | Partly (`action`) | In-place schema change conflicts with versioning; “Supervisor” role absent |
| Footer | Ledger Integrity Seal: 0x489F...A39E; “All entries signed with CoreOS Platform Root CA. 0 validation anomalies found across 14,802 historic blocks.” | No | Invented PKI/blockchain integrity claim |
| Count | SHOWING 4 OF 241 EVENTS | Partly | No pagination/count endpoint |
| Action | Load Previous Block | No | Block pagination not modelled |

No customer name/phone/email, full VIN, plate, or report findings. Staff IP (`192.168.1.42`), staff names, and roles are shown.

## 7. States shown / not shown
Shown: four populated events, All Events tab, status badges, export/verify, footer seal. Not shown: empty audit, loading/skeleton, error/retry, filter results, search results/no-results, event detail drawer, export confirmation/error, pagination beyond 4, integrity failure, RTL, keyboard/focus, 200% text, long metadata.

## 8. Implied interactions
Switch event filters; search by user/hash; export CSV; verify nodes; open event detail (chevron); load previous block. No delete/edit affordance is shown, which matches append-only audit.

## 9. Correspondence to current product
Partial. Existing: `audit_tab.dart` renders `auditProvider` as a read-only list of `Card`/`AppListTile`, showing `event.action`, `occurredAt`, `actorRole`, `entityType`, `reasonCode`, and `metadataJson` tooltip. `admin_api.auditEvents()` → `GET /api/v1/platform/audit-events?limit=...` (`PlatformHierarchyController`). `AuditEvent` fields: id, occurredAt, actorRole, action, entityType, entityId, reasonCode, metadataJson. Missing: filters, user/hash search, region/IP, counts/pagination, export, verify, integrity seal, event detail, and all cryptographic/hash fields. Filters/export/pagination are server changes.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “Finalized findings/evidence/reports immutable; audit is append-only.” The audit is append-only, but the frame claims much more. Evidence: “TAMPER-PROOF LEDGER” (`1:5356`), “Cryptographic ledger” (`1:5361`), “SHA256: 9b2d...f4e1” (`1:5400`), “Ledger Integrity Seal: 0x489F...A39E” (`1:5534`), “All entries signed with CoreOS Platform Root CA. 0 validation anomalies found across 14,802 historic blocks.” (`1:5536`). Phase-1 04 §6.3 defines an append-only database, not a blockchain/PKI ledger; security design explicitly says immutability “does not make data immutable against a privileged database administrator.”
- Rule: “no certification/‘verified by’/compliance claims.” Evidence: “0 validation anomalies”, “Root CA”, “Verify Nodes”, and the seal imply third-party proof that does not exist.
- Rule: “Never invent versions/licences/measurements/results.” Evidence: “14,802 historic blocks”, “241 events”, “Rev: v4.19”, “Tire & Chassis Specification v2”, “UUID: 8a4c…11a0”, “SHA256: 9b2d…f4e1”, “0x489F…A39E”, “Cluster Region: US-East-1”.
- Rule: “no manager role.” Evidence: “Marcus Vance (Lead Inspector)” (`1:5408`), “Elena Rostova (Supervisor)” (`1:5508`); roles are `Supervisor`/`Lead Inspector`, not the three-role model. Also `Policy: Role.SuperAdmin` (`1:5468`) introduces a super-admin role.
- Rule: “TOTP/security claims.” Evidence: “Dual-Factor Approved” (`1:5484`) implies TOTP enforcement, but ADR-0021 sets `ADMIN_TOTP_REQUIRED=false` by default and says “The admin app has no TOTP challenge UI.”
- Rule: “Finalized findings/reports immutable.” Evidence: “Master Checklist Schema Modified: Brake Wear” (`1:5502`) describes an in-place schema change; master content must be versioned, not modified in place.
- Rule: “no customer PII / redacted logs.” Evidence: `IP: 192.168.1.42` (`1:5416`) exposes a full IP in UI; security design says IP is stored if policy allows, masked/redacted where required.
- Rule: “timestamps UTC.” Evidence: “Today, 14:32 EST”, “Yesterday, 16:40 EST”, “Oct 23, 09:20 EST”; the audit model stores UTC, and no timezone conversion contract is shown.
- Rule: “no business logic/API/server change.” Evidence: filters, hash search, export, verify, and block paging have no endpoints.

## 11. Open questions / could not verify
- Is the “ledger” copy literal (blockchain/PKI) or marketing? The product has no such implementation.
- Should Platform Admin see Workshop Admin link-revocation events? Phase-1 04 says report link revoke/resend is a Workshop Admin action visible to Platform Admin.
- What are the real event codes/labels? The frame uses title-case prose rather than stable codes (e.g. `ACCOUNT_DISABLED`).
- Is IP/region intentionally visible, and under what policy?
- Should export be CSV, async, and audited?
- **PRD mismatch:** the PRD claims **11** Platform Admin screens (Module A lists #11 “Admin 2FA / TOTP Verification”), but this export contains only **10**. No 2FA/TOTP challenge screen is present in `screens/` or `package-manifest.json`.
- No empty/error/loading/RTL/detail states were exported.
