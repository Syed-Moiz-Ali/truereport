# Screen 9 — Completed Report Viewer (F3-0 group C)

- Figma source: `docs/ui/figma-export/Workshop_admin_figma/screens/09_9._Completed_Report_Viewer/9._Completed_Report_Viewer.json` (node `1:2236`, `serializedNodeCount: 266`), visual ref `9._Completed_Report_Viewer@2x.png`
- Prior spec (read, not edited): `docs/ui/figma/specs/workshop_admin/09-completed-report-viewer.md`
- Frame: **1280 × 1680.75**, `VERTICAL`, white `#FFFFFF` — width 1280 confirmed as drawn (O3). Long height = document scroll, not a viewport.
- Root children: `Background` (`1:2237`, 1280×1680.75, left pad 96) → `Header` (`1:2460`, 1184×80 at x=96) → `Aside` (`1:2483`, 96 wide; JSON height 800 vs frame 1680.75 — rail is a fixed-viewport shell, does not stretch the page).

## Node-level layout (as drawn)
- `Main` 1184 wide at x=96, padding 80/40/48/40; content column 1104 wide.
- Title block: `AUDIT SEALED & LOCKED` pill + truncated `• SHA-256 #89c41f` row; H1 `Report #1042 — Finalized`; subline `Inspected by Marcus Vance on Oct 24 • Verified via Bay 04 Telematics`.
- Action row (right of H1): `Resend WhatsApp` (emerald filled), `Resend SMS` (white), `Download PDF` (white) — ~56 high, 12 gap.
- Document card 1104 wide, radius 48, padding 56, vertical gap 48, two-layer drop shadow:
  - Hero grid: left text (`FLEET COMMERCIAL` pill, `Passed Certification Stage`, `2024 Ford Transit 350 High Roof`, `Renault Megan 3 / Fleet Transport`, VIN pill `1FTBR1Y85RKB92104`, `24,812 mi Odometer`, `In Service: 11 Mo`); right vehicle photo with `HD Scans Attached (18)` overlay.
  - `DIAGNOSTIC COMPLETENESS` band (radius 16): `104 Checks Completed` / `of 106 Required`, chips `102 Cleared` + `2 Defects Found`, progress bar, `98.1% Specification Compliance`, `Target Fleet Threshold: >95.0%`.
  - Two finding cards: `Tire Condition: Verified` (Front Steer Tread `8.2 / 8.5 mm`, Rear Drive Tread `9.0 / 9.1 mm`, `Tire TPMS 71 PSI`, sidewall check line) and `Engine Diagnostics: Passed` (DTC `0 Active / 0 Pending`, `MIL Lamp Extinguished`, `Grade 5W-30 OK`, `Coolant -35°F Safe`, alternator `14.3V` line).
  - `Observed Fleet Action Items (2)` + `MINOR` band: `Rear cargo threshold scuff (cosmetic, non-structural) & washer reservoir low level.`, `Logged in Bay Ledger` / `Scheduled at Next Cycle`.
  - Bottom grid: `Digital Certification Seal` card (QR-like 60×60 composed SVG, signature sentence, `URN: fleet:inspect:2024:ord:1042:vance:58f7009be12`) + `AUTHORIZED DELIVERY CHANNEL` card (`Acme Logistics Dispatch`, full email, `Read Receipt Confirmed`).
- Footer: `Automotive Telematics Protocol v4.8 • ISO/IEC 27001 Authenticated` / `Report Storage: Immutable Record Active`.
- Shell: `Header` (bay pill, search `Search VIN, tech, job ticket...`, `Marcus Vance / Lead Inspector`) and `Aside` nav rail (Jobs highlighted). Prior spec notes aside height 800.

## Components → `design_system`
- Pills/chips → `StatusChip` (`components/chips.dart`). Labels such as `AUDIT SEALED`, `FLEET COMMERCIAL`, `102 Cleared`, `Verified/Passed` are **not** real result codes.
- Finding/action cards → `AppCard` + `SeverityBadge` (`components/cards.dart`, `components/results.dart`). Current report content is simple list rows (`report_page.dart` `_content`), not finding cards.
- `Resend WhatsApp / SMS`, `Download PDF` → `AppButton` primary/tonal (`components/buttons.dart`). No direct resend exists today (see mapping).
- Delivery card → `AppCard` + delivery row; design shows full email, product shows `recipientMasked`.
- Seal/QR block, document-paper container, hero photo+scan-count overlay → **no equivalent** (new components if ever built; seal must not be built per O9).
- Header/aside → `AppBar` + `NavigationRail` (`components/navigation.dart`, `admin_chrome.dart`); shell already exists.

## Assets
- 42 assets per JSON `developerSummary.assets`: 37 single SVGs (icons), 4 composed SVGs (`SVG` 60×60 QR-like seal built from 16 vector fragments; `Background+Shadow` 80×80; `Nav` 96×600; `Aside` 96×800), **1 raster** 512×279 Ford Transit van photo (`assets/images/original/image-1-b72808d28a.jpg`) used as vehicle hero, not evidence.
- No avatar photo; user avatar is a vector icon.

## States shown / not shown
- Shown: finalized report, active delivery channel, coverage complete, PDF available, findings + action items, seal + delivery cards.
- Not shown: generating / generation-failed, PDF not-ready, PDF-download disabled, link not created / revoked, consent missing, no deliveries / failed / dead-letter, loading / empty / error / offline, 200% text, RTL/Arabic, phone/tablet. No link-state control, delivery history, consent row, or PDF-download toggle (all exist in product, absent here).

## Element → data/endpoint/state mapping
| Figma element | Maps to | Verdict |
|---|---|---|
| `Report #1042 — Finalized`, finalized state | `ReportAdminDto.reportNumber/version/reportReady`, `ReportSnapshot.reportNumber/reportVersion` (`server/.../reports/api/ReportAdminDto.java`) | Matches existing feature (sample number only) |
| `• SHA-256 #89c41f` | `ReportAdminDto.snapshotHash` / `ReportSnapshot.verificationHash` | UI work only (truncate/format is new) |
| `Inspected by Marcus Vance on Oct 24` | `ReportSnapshot.technician.displayName`, `finalizedAt` | Matches existing feature (names/dates are sample) |
| `Verified via Bay 04 Telematics` | — | DATA GAP (no telematics/bay field) |
| `Resend WhatsApp` / `Resend SMS` | `POST /api/v1/workshop/jobs/{jobId}/deliveries` send/retry (`client/apps/admin_app/lib/src/pages/report_page.dart` `_send`, `_retryDelivery`); ADR-0018 creates a **new** link per send | Needs server-wording change — "Resend" misrepresents the contract; UI work only if relabelled to Send/Retry |
| `Download PDF` | `GET /api/v1/workshop/jobs/{jobId}/report/pdf` + `pdfReady` / `pdfDownloadEnabled` (`report_page.dart` `_downloadPdf`, `_togglePdf`) | Matches existing feature **only if** gated on existing per-report `pdfDownloadEnabled` (O9); as drawn (unconditional) = LOCKED-RULE conflict |
| `FLEET COMMERCIAL` | `ReportSnapshot.vehicle.vehicleType` | UI work only |
| `Passed Certification Stage` | — | LOCKED-RULE conflict (O6/O9: no certification/compliance claims) |
| `2024 Ford Transit 350 High Roof` | `ReportSnapshot.vehicle.make/model/year` | Matches existing feature (sample) |
| `Renault Megan 3 / Fleet Transport` second vehicle line | — | DATA GAP + unsafe sample (contradicts hero vehicle) |
| VIN `1FTBR1Y85RKB92104` (full) | `ReportSnapshot.vehicle.vinMasked` only; full VIN not in snapshot | DATA GAP (internal-only path needed; never public/PDF). Screen 12 shows `14,820 mi` for same VIN vs `24,812 mi` here — inconsistent sample |
| `24,812 mi Odometer` | `ReportSnapshot.vehicle.odometerValue/odometerUnit` | Matches existing feature (value is sample) |
| `In Service: 11 Mo` | — | DATA GAP |
| `HD Scans Attached (18)` | `ReportSnapshot.evidenceIds.length` derivable | Needs new data presentation (count label + stock-photo implication are new) |
| `104 Checks Completed of 106 Required`, `102 Cleared`, `2 Defects Found` | `ReportSnapshot.coverage.completed/applicable`; result-code counts derivable | Needs new data (`Cleared` is not a result label; defect-count DTO absent) |
| `98.1% Specification Compliance`, `Target Fleet Threshold: >95.0%` | — | LOCKED-RULE conflict (O9 + design-system rule: no single condition score) |
| `Tire Condition: Verified`, `Engine Diagnostics: Passed`, `Verified/Passed` chips | `ReportSnapshot` item `resultCode` only | LOCKED-RULE conflict (O6: `NO_ISSUE_OBSERVED` must never read Pass/Perfect/Certified/Verified) |
| Tread depths, TPMS `71 PSI`, DTC, viscosity, coolant, `14.3V`, optical-calibration copy | — | DATA GAP (no measurement/telemetry/OBD fields) |
| `Observed Fleet Action Items (2)`, `MINOR`, scuff+reservoir note | `ReportSnapshot.keyFindings` + severity | UI work only for list; counts/wording need data work |
| `Logged in Bay Ledger`, `Scheduled at Next Cycle` | — | DATA GAP |
| `Digital Certification Seal`, QR, `Digitally cryptographically signed… cloud ledger`, URN | `snapshotHash` only; no signing key/QR/ledger | LOCKED-RULE conflict (O6/O9: no certificate/signature claims; misrepresents integrity model) |
| `Acme Logistics Dispatch`, full email, `Read Receipt Confirmed` | `DeliveryDto.recipientMasked/status/attempts` | LOCKED-RULE conflict (masked-recipient rule; no read-receipt field) |
| `Automotive Telematics Protocol v4.8 • ISO/IEC 27001 Authenticated` | — | LOCKED-RULE conflict (invented protocol/certification) |
| `Report Storage: Immutable Record Active` | FINALIZED immutability concept | UI work only (reword to factual locked state) |
| Header search, bay pill, role title `Lead Inspector` | `admin` shell search, `displayName` | UI work only |

## Classification
**Needs new data or server change + contains locked-rule conflicts — do not build as drawn.** Shell, gated PDF download, coverage counts, key-findings list, and masked delivery status map to existing features; certification/seal/score/verdict language, full VIN, measurements, ledger/scheduling, read receipts, and resend semantics do not.

## Locked rules applied
- O6: no review/approve/sign-off wording — screen's `Passed / Verified / Certification Stage / Digitally cryptographically signed / ISO 27001` must be removed, not renamed.
- O9: viewer shows OUR report with the same allowlist as the public report/PDF (masked VIN, no plate, no certificate/compliance claims, `Not an official certificate` posture); PDF download follows existing per-report `pdfDownloadEnabled`, never unconditional; no print-studio/A4 stamp features.
- Factual integrity mechanism is the SHA-256 snapshot hash, not a seal/signature/QR/ledger.

## New-component list (only what has no equivalent)
1. Read-only completed-report document container (paper card) — buildable on `AppCard` only if restricted to allowlisted snapshot fields.
2. Coverage band with counts + progress — buildable only as inspection-coverage counts, never a compliance score.
3. Finding cards with metric pills — buildable only from real snapshot item/note fields.
4. QR/seal block, telematics/bay strip, ledger/scheduling row, read-receipt row — **do not build** (locked-rule/data-gap).

## Could not verify
- Whether this screen is meant to equal the public report or an internal view with extra metadata (prior spec §11 open question; O9 mandates same allowlist).
- Source of `98.1%`, tread/TPMS/DTC/voltage readings, `In Service`, scan counts, thresholds, URN, licences — none in `ReportSnapshot`/`ReportAdminDto`; verified absent only by field inspection, not by running the server.
- Full-VIN permission/audit path for internal screens — no endpoint found in this pass.
- Arabic/RTL labels and 200% text behaviour — not present in the export.
- Exact hex/contrast numbers beyond the JSON `designSystemObserved` counts; no independent version/licence/measurement invented here.
