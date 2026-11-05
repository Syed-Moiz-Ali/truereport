# 09. Completed Report Viewer

- App: Workshop Admin
- Figma node: `1:2236`
- Frame: 1280x1680.75 px (desktop web document view, >=1200 per `AppBreakpoints.desktop`)
- Export folder: `screens/09_9._Completed_Report_Viewer`
- Sources read: `9._Completed_Report_Viewer.json`, `9._Completed_Report_Viewer@2x.png`, `assets/manifest.json`
- Export-order note: package index **09** equals Figma screen **9**. The inversion is at package index **07** = screen **6** and package index **06** = screen **7**; this file is otherwise aligned.
- Confidence: medium. Layout and visual tokens are precise; the correspondence is medium because the viewer adds certification, scoring, signature, telemetry and delivery data that the current `ReportSnapshot`/`ReportAdminDto` do not contain.

## 1. Purpose
A read-only, scrollable completed-report page for the workshop: finalized status, vehicle identity, coverage/completeness, findings cards, observed action items, a certification/signature block and a delivery recipient, with resend and PDF actions at the top.

## 2. Layout structure
Root is a fixed 1280x1680.75 `VERTICAL` frame (`FIXED/HUG`), white; the long height is the document scroll.

- `Background` (`1:2237`) fills width with 96 left padding for the rail.
- `Main` (`1:2238`) 1184 wide at x=96, padding 80/40/48/40.
- Content (`1:2239`) 1104x1552.8.
- Header block (`1:2240`) 1104x141, bottom padding 40. Left 456.9 wide: `AUDIT SEALED & LOCKED` pill + truncated hash row, H1 32/38 `Report #1042 — Finalized`, 14/20 inspector line. Right: three 56-high buttons, 12 gap: `Resend WhatsApp` (201, emerald), `Resend SMS` (160.9, white), `Download PDF` (173.3, white).
- Document card (`1:2269`) 1104x1333.8, radius 48, padding 56, vertical gap 48. It is a white paper-like container with a large shadow.
  - Hero grid (`1:2270`) 992x243.8: left 562 text (`FLEET COMMERCIAL` pill + `Passed Certification Stage`, 32/38 vehicle title, 18/24 subtitle, VIN/odometer/service row); right 390x243.8 vehicle image with a `HD Scans Attached (18)` overlay.
  - Diagnostic completeness band (`1:2305`) 992x174, radius 16, padding 32: coverage counts, two chips (`102 Cleared`, `2 Defects Found`), 12px progress bar, `98.1% Specification Compliance` and `Target Fleet Threshold: >95.0%`.
  - Two finding cards (`1:2331`) 992x342, 24 gap, 484 wide each, radius 16: `Tire Condition: Verified` and `Engine Diagnostics: Passed`; each has a status chip, description, two 212x98 metric pills and a check line.
  - Action items band (`1:2392`) 992x112, radius 16: severity icon, `Observed Fleet Action Items (2)` + `MINOR`, note, `Logged in Bay Ledger` / `Scheduled at Next Cycle`.
  - Seal/delivery grid (`1:2411`) 992x158: `Digital Certification Seal` card (650.7 wide) with QR-like 60x60 SVG, signature text and URN; `AUTHORIZED DELIVERY CHANNEL` card (309.3 wide) with recipient name/email and `Read Receipt Confirmed`.
- Footer (`1:2454`) 1104x78: `Automotive Telematics Protocol v4.8 • ISO/IEC 27001 Authenticated` and `Report Storage: Immutable Record Active`.
- Shell `Header` (`1:2460`) 1184x80 overlay and `Aside` (`1:2483`) 96x800. Note the aside is only 800 high while the frame is 1680.75; it appears to be a fixed viewport shell, not a full-page rail.
- Scroll: vertical content; no scrollbar. No sticky table of contents, no print controls.
- Responsiveness: fixed 1280 desktop; the hero 562/390 split and 2-up findings do not collapse. No tablet/phone or RTL/Arabic composition.

## 3. Visual tokens observed
### Colours (exact hex, usage, approx count)
| Hex | Usage | Count |
|---|---|---:|
| `#5E5D69` | Secondary text, metadata | 38 |
| `#1A1B1F` | Primary headings/values | 33 |
| `#F4F3F8` | Cards, metric pills, tonal surfaces | 21 |
| `#FFFFFF` | Document and cards | 20 |
| `#006C49` | Verified/positive text/icons | 14 |
| `#10B981` | Primary CTA, progress bar, chips | 11 |
| `#B91A24` | Defect count, MINOR badge, defect icons | 5 |
| `#3C4A42` | `AUDIT SEALED` text/URN | 3 |
| `#FFDAD6` | Warning/defect soft backgrounds | 2 |
| `#FFFFFFE5` | Sticky header tint | 2 |
| `#E3E2E7` | Progress track | 1 |

White on `#10B981` is ~2.54:1. `#10B981` text/icons on white are also ~2.54:1. `#B91A24` on `#FFDAD6` is ~5.0:1 and passes normal-text contrast.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)
Family is `Plus Jakarta Sans`; VIN and URN use `Liberation Mono`. No Arabic family or RTL text.

| Role | Weight | Size/line | Tracking | Usage |
|---|---|---|---|---|
| H1 | 800 | 32/38 | -0.80 | Report title and vehicle title |
| H2 | 700 | 22/28 | -0.44 | Coverage value |
| H3 | 700 | 18/24 | -0.27 | Finding titles and vehicle subtitle |
| Section/card title | 700 | 16/22 | -0.16 | Action items, seal |
| Body | 400-500 | 13/18, 14/20 | 0 to -0.07 | Notes, inspector line |
| Label | 600 | 11/14 | +0.44 to +0.55 | Uppercase labels, badges |
| Micro | 600-700 | 12/16 | +0.24 | Chips, counts |
| Mono | 600 | 12/16, 11/14 | +0.44 to +0.60 | VIN, URN |

Left-aligned except chips/overlays. The `AUDIT`/`FLEET` labels and long strings use single lines; 32px titles at 562px width are tight for Arabic and 200% text.

### Radii, shadows/elevation, strokes, spacing
- Radii: 48 for the outer document, image panel and some chips; 16 for inner cards and metric pills; 32 for the VIN pill; 9999 for all pills/chips.
- Shadows: document/card `0 2 8 rgba(0,0,0,0.016)` + `0 14 40 rgba(0,0,0,0.043)`; primary CTA `0 10 25 rgba(16,185,129,0.30)`.
- Strokes: none on cards; a small red dot/badge on the defect chip; no table borders.
- Spacing: 12 (31), 24 (30), 8 (29), 4 (16), 16 (12), 32 (12), 40 (8), 56 (4), 48 (3), 80/96 (1 each). Main padding 80 top/48 bottom and card padding 56 are off the 4/8/12/16/24/32/48 scale.

Token drift: current `AppTheme` primary is `#0B3B4A`, `AppRadiiTokens` max 16 before pill, and `type.h1` is 24/30. The frame uses `#006C49`/`#10B981`, 48px document radius and 32px H1.

## 4. Components
| Figma pattern / node | Map to current design system | Notes |
|---|---|---|
| Report document card `1:2269` | No design-system component | Current `report_page.dart` is a custom `ListView`; public report is a Thymeleaf HTML document. |
| Status pills/chips | `StatusChip` | `AUDIT SEALED`, `FLEET COMMERCIAL`, `102 Cleared`, `MINOR`, `Verified`/`Passed`; some labels are not real result codes. |
| Findings cards `1:2332`, `1:2362` | `AppCard` / `SeverityBadge` | Current report content is simple list rows, not finding cards. |
| `Observed Fleet Action Items` `1:2392` | `AppCard` / `SeverityBadge` | `MINOR` is a real severity, but the copy/actions are new. |
| `Digital Certification Seal` `1:2412` | No equivalent | QR-like composed SVG + signature; no signature/QR in product. |
| Delivery card `1:2442` | `AppCard` + delivery row | Current `ReportDelivery` card shows masked recipient and status; design shows full email. |
| `Resend WhatsApp/SMS`, `Download PDF` | `AppButton` primary/tonal | Current report page has a send bottom sheet and PDF download/toggle; no direct resend. |
| Header/aside | `AppBar` + `NavigationRail` | Current shell has Jobs/Staff/Templates; this frame highlights Jobs. |

## 5. Assets
`assets/manifest.json` reports **42** assets: 37 individual SVGs, 4 composed SVGs and **1 raster**. The raster is a 512x279 Ford Transit van image (`assets/images/original/image-1-b72808d28a.jpg`), presented as a vehicle hero, not as evidence. Composed: `SVG` 60x60 (QR-like seal built from 16 vector fragments), `Background+Shadow` 80x80 decorative tile, `Nav` 96x600 and `Aside` 96x800. No avatar photo; the user avatar is a vector icon.

## 6. Content and data
| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Seal | `AUDIT SEALED & LOCKED` | No dedicated field | `FINALIZED`/immutability is real; this label is new. |
| Hash | `• SHA-256 #89c41f` | `ReportAdminDto.snapshotHash` | Truncated in UI; current hash is a full hex string. |
| Title | `Report #1042 — Finalized` | `reportNumber`, `version`, state | `#1042` is sample; format must be real. |
| Inspector line | `Inspected by Marcus Vance on Oct 24 • Verified via Bay 04 Telematics` | `technician.displayName`, `finalizedAt`; no telematics | "Verified via Bay 04 Telematics" is invented. |
| Actions | `Resend WhatsApp`, `Resend SMS`, `Download PDF` | Delivery send/retry + PDF endpoints | "Resend" implies reusing a link; ADR-0018 creates a new link per send. |
| Vehicle class | `FLEET COMMERCIAL` | `Vehicle.vehicleType` | Possible. |
| Status | `Passed Certification Stage` | No | Prohibited certification claim; no field. |
| Vehicle | `2024 Ford Transit 350 High Roof` | `Vehicle.make/model/year` | Real snapshot fields; model is consistent with 2024 Ford. |
| Subtitle | `Renault Megan 3 / Fleet Transport` | No | Contradicts the Ford title; appears to be a second vehicle or copied sample. |
| VIN | `VIN 1FTBR1Y85RKB92104` | `Vehicle.vinMasked` only | Full VIN is not in the current snapshot; internal screens may show it (`03-localization` §4.1), but this needs a new data/permission path. |
| Odometer | `24,812 mi Odometer` | `Vehicle.odometerValue/Unit` | Real field; unit mi. Screen 12 shows 14,820 mi for the same VIN. |
| In-service | `In Service: 11 Mo` | No | Invented. |
| Evidence count | `HD Scans Attached (18)` | `evidenceIds` list length could be derived | "HD Scans" and 18 are not in DTO; screen 12 shows 2 photos. |
| Coverage | `104 Checks Completed`, `of 106 Required` | `Coverage.completed/applicable` | Real coverage concept; `total`/`applicable` semantics must be verified. |
| Counts | `102 Cleared`, `2 Defects Found` | Could derive from result codes | "Cleared" is not a result label; no defect-count DTO. |
| Score | `98.1% Specification Compliance`, `Target Fleet Threshold: >95.0%` | No | Single condition score; no field. |
| Findings | `Tire Condition: Verified`, `Four-corner optical tread depth and load pressure calibration` | No | "Verified" is not one of the six result codes; optical calibration is invented. |
| Measurements | `Front Steer Tread 8.2 / 8.5 mm`, `Even Wear Profile` | No | No measurement fields in `ItemSnapshot`. |
| Measurements | `Rear Drive Tread 9.0 / 9.1 mm`, `Tire TPMS 71 PSI` | No | No TPMS/measurement fields. |
| Check line | `Sidewalls clear of structural fissures or bead abrasions` | Snapshot note text could contain this | It is free text if entered; not a field. |
| Finding | `Engine Diagnostics: Passed` | `resultCode` only | "Passed" is prohibited wording for `NO_ISSUE_OBSERVED`. |
| Finding | `Full OBD-II ECU telemetry scan & exhaust gas recirc balance` | No | OBD-II is not implemented. |
| Metrics | `Fault Codes (DTC) 0 Active / 0 Pending`, `MIL Lamp Extinguished` | No | No DTC fields. |
| Metrics | `Fluid Viscosity Index Grade 5W-30 OK`, `Coolant -35°F Safe` | No | Invented results/units. |
| Check line | `Alternator rail charging stable at 14.3V under full load` | No | Invented measurement. |
| Action items | `Observed Fleet Action Items (2)`, `MINOR` | `keyFindings`/severity list | Severity is real; total 2/`MINOR` are sample. |
| Note | `Rear cargo threshold scuff (cosmetic, non-structural) & washer reservoir low level.` | `ItemSnapshot.note` | Could be a note, but contains two findings in one string. |
| Log | `Logged in Bay Ledger`, `Scheduled at Next Cycle` | No | No bay ledger or scheduling field. |
| Seal title | `Digital Certification Seal` | No | Certification claim; no signature/QR. |
| Seal body | `Digitally cryptographically signed by Inspector Marcus Vance. Timestamp: Oct 24, 2024 at 14:38:11 UTC. Scan QR to view live cloud ledger.` | `snapshotHash` only | No digital signature, QR or cloud ledger; invents a security mechanism. |
| URN | `URN: fleet:inspect:2024:ord:1042:vance:58f7009be12` | No | Invented identifier. |
| Delivery | `Apex Logistics Fleet Ops`, `fleet-compliance@apex.io`, `Read Receipt Confirmed` | `DeliveryDto.recipientMasked` | Full email is PII; should be masked. `Read Receipt` is not implemented. |
| Footer | `Automotive Telematics Protocol v4.8 • ISO/IEC 27001 Authenticated` | No | Invented protocol and certification claim. |
| Footer | `Report Storage: Immutable Record Active` | `FINALIZED`/locked state | Wording is new but the immutability concept is real. |

No customer name/phone is shown on this screen, but a delivery email is shown in full. The vehicle is a commercial fleet sample; the VIN, measurements, dates and certifications are all sample data.

## 7. States shown / not shown
Shown: ready/finalized report with active delivery channel, complete coverage, PDF available, vehicle image and findings.

Not shown: report generating, generation failed, PDF not ready, PDF disabled, link not created, consent missing, link revoked, no delivery attempts, delivery failed/dead-letter, loading, empty/not finalized, error, offline, 200% text, RTL/Arabic, phone/tablet.

## 8. Implied interactions
Resend WhatsApp/SMS, download PDF, possibly open the QR/cloud ledger and zoom evidence. No link management (activate/revoke), delivery history, consent state or PDF-download toggle is visible even though the current report page has them.

## 9. Correspondence to current product
- **Existing screen:** `client/apps/admin_app/lib/src/pages/report_page.dart` (pushed from `jobs_tab.dart`) renders a `ReportAdmin` via `GET /api/v1/workshop/jobs/{jobId}/report`. It shows report status, finalized date, consent state, link state, PDF-enabled state, content, PDF download/toggle, public-link activate/revoke and `GET .../deliveries` history.
- **Existing snapshot:** `ReportSnapshot` contains `reportNumber`, `reportVersion`, `finalizedAt`, `Vehicle(make, model, year, vinMasked, odometerValue, odometerUnit, vehicleType)`, `Inspection`, `Workshop`, `Technician`, `Coverage`, `keyFindings`, `categories`, `notChecked`, `limitations`, `disclaimer`, `verificationHash`.
- **Gaps:** no `vin` plaintext, no certification stage/seal/signature/QR, no compliance percentage/target threshold, no telemetry/OBD/DTC/TPMS measurements, no `HD Scans` count, no `In Service`, no full delivery email/read receipt, no bay ledger/next cycle.
- **Delivery:** `DeliveryDto` exposes `recipientMasked`, `status`, `attempts`, `maxAttempts`, `linkState`, error fields; the design bypasses the masked-recipient rule and the manual send assistant.
- **PDF/link:** `ReportAdminDto` exposes `pdfReady`, `pdfDownloadEnabled`, `linkState`, `consentState`, `activeLinkCount`; the design does not show any of these state controls.
- The page is an **existing screen** but with several **new data/server features**; a UI-only implementation cannot produce the certification, scoring or telemetry content.

## 10. Locked-rule conflicts / unsafe-to-ship content
1. **Certification/compliance claims.** The task rule forbids certification/"verified by"/compliance claims. The screen says `Passed Certification Stage`, `Engine Diagnostics: Passed`, `Digital Certification Seal`, `ISO/IEC 27001 Authenticated`, `Verified`, and "Digitally cryptographically signed". `docs/phase-1/06-public-report-design.md` §12 says "Do not use 'certified', 'independently reviewed', 'manager approved' or 'RTA approved' unless factually and legally true."
2. **Single condition score.** The task rule forbids "no single unexplained condition score"; `docs/phase-1/06-public-report-design.md` §12 says "Do not show a headline '8.8/10' or similar score"; `docs/phase-1/10-design-system.md` §6 says "Use 'inspection coverage', not a condition score." `98.1% Specification Compliance` and `Target Fleet Threshold: >95.0%` are exactly that.
3. **"Passed" must not replace a result code.** `docs/phase-1/10-design-system.md` §3.3: "`NO_ISSUE_OBSERVED` must never be labelled 'Pass', 'Perfect' or 'Certified'." The screen uses `Passed` and `Verified` as verdicts.
4. **Recipient PII.** `docs/phase-7/00-decisions.md` §8: "The admin UI does not collect or display full customer contact details. It displays only masked recipients and status/error metadata." The screen shows `dispatch@acmelogistics.corp` (and `fleet-compliance@apex.io` in screen 12).
5. **Digital signature/QR/cloud ledger are invented.** There is no signing key, QR generation or cloud ledger in the current product; the integrity mechanism is a SHA-256 snapshot hash. Showing a "cryptographically signed" seal misrepresents the security model.
6. **Full VIN data gap.** Internal screens may show full VIN (`docs/phase-1/03-localization-and-rtl-rules.md` §4.1), but the current snapshot only has `vinMasked`; implementing this needs a new internal DTO/permission. It must never be reused on the public report/PDF.
7. **Vehicle identity inconsistency.** `2024 Ford Transit 350 High Roof` and `Renault Megan 3 / Fleet Transport` appear as the same vehicle; screen 12 also shows `14,820 mi` while this screen shows `24,812 mi` for the same VIN. This is an unsafe-to-ship data defect.
8. **Sample vehicle image may be mistaken for evidence.** The 512x279 Ford Transit image is a stock hero, not an evidence derivative; the screen labels it with a scan count, which implies evidence.
9. **WCAG 2.2 AA.** White on `#10B981` is ~2.54:1; `#10B981` text/icons on white are ~2.54:1; many 11px labels and a dense document layout have no 200% text design.
10. **Tokens/fonts/RTL.** `#006C49`/`#10B981`, 32px/48px radii and `Plus Jakarta Sans` are not the current tokens; no Arabic/RTL/`dir` variant is shown.

## 11. Open questions / could not verify
- Should the internal viewer show full VIN, or reuse the public masked VIN? If full, which role/permission and audit apply?
- Is this screen intended to render the same content as the public report, or an internal-only view with extra metadata? The current A12 says "same snapshot renderer ... plus internal metadata".
- What is `Passed Certification Stage`? No certification process exists.
- Where do `98.1%`, `Target Fleet Threshold >95.0%`, tread depths, DTC/TPMS/voltage readings and `In Service` come from? They are not in `ReportSnapshot`.
- Why are there two different vehicles in one hero?
- Should resend create a new link (ADR-0018) and show a new link? Should the UI expose the active-link count and consent state?
- Is `Read Receipt Confirmed` a real delivery status, or should it be `SENT`/`DELIVERED` only?
- Is the "Digital Certification Seal" a UI illustration only, or a planned cryptographic signature? If planned, what key custody and verification UX apply?
- What are the Arabic labels and RTL reading order for this document?
