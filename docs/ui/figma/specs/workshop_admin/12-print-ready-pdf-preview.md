# 12. Print-Ready PDF Preview

- App: Workshop Admin
- Figma node: `1:2857`
- Frame: 1280x1227.584 px (desktop web print preview, >=1200 per `AppBreakpoints.desktop`)
- Export folder: `screens/12_12._Print-Ready_PDF_Preview`
- Sources read: `12._Print-Ready_PDF_Preview.json`, `12._Print-Ready_PDF_Preview@2x.png`, `assets/manifest.json`
- Export-order note: package index **12** equals Figma screen **12**. The inversion is at package index **07** = screen **6** and package index **06** = screen **7**; this file is otherwise aligned.
- Confidence: medium. Geometry, typography and assets are precise; correspondence is medium (not high) because the visible PDF is a "certificate" with invented licences, measurements and a signature, while the actual product PDF is a bilingual report that uses a masked VIN and states "Not an official certificate."

## 1. Purpose
A desktop print-preparation workspace: document metadata and delivery actions on the left; a floating A4 paper preview with a certificate-style header, vehicle summary, coverage metrics, two evidence photos, a compliance stamp and an inspector signature on the right; print controls allow orientation, high-resolution evidence, a physical seal and direct printing.

## 2. Layout structure
Root is a fixed 1280x1227.584 `VERTICAL` frame (`FIXED/HUG`), white.

- `Background` (`1:2858`) fills width with 96 left padding.
- `Main` (`1:2859`) 1184x1227.6 at x=96, padding 80/40/48/40.
- Content (`1:2860`) 1104x1099.6, `HORIZONTAL`, gap 32: 320px left sidebar + 752px preview.
- Left sidebar (`1:2861`) fixed 320 wide, `VERTICAL` gap 24:
  - Document overview card (`1:2862`) 320x494, radius 32, padding 24, shadow. Order: 32px back link, status pill (`PDF Ready (v2.1)` + `AUDITED`) 272x46 radius 48, metadata list 272x164, two 56-high CTAs (`Send Email to Client` emerald; `Download PDF` tonal).
  - Print settings module (`1:2910`) 320x302, radius 32, padding 24: `PRINT ORIENTATION` + `A4 Standard`, 272x40 segmented Portrait/Landscape, two toggle rows (`Include High-Res Evidence`, `Stamp Physical Seal`) 48x28 switches, `Direct System Print` 272x40 tonal button.
  - Recipients card (`1:2947`) 320x120, radius 32, padding 20: `ASSIGNED DISTRIBUTION`, 280x54 recipient row with 32px avatar, `Apex Logistics Fleet Ops`, full email.
- Right preview pane (`1:2959`) 752x1099.6, radius 48, padding 48, `#F4F3F8`, centered:
  - Floating toolbar (`1:2960`) 400x52, radius 9999, white: zoom out, `100%`, zoom in, `Page 1 of 1`, green dot `Prepress Verified`.
  - A4 paper (`1:2979`) 656x927.6, radius 48, white, large shadow. Aspect 656/927.6 = 0.707, matching A4 portrait. Inside document (`1:2980`) 560x723 at 48px inset:
    - Header 560x82: 32px black brand tile + `TECHINSPECT`, `AUTOMOTIVE PRECISION SYSTEMS`, `CERTIFICATE #1042`, `Issue Date: Oct 24, 2024`.
    - Certificate headline 560x115: `VEHICLE INSPECTION & COMPLIANCE CERTIFICATE` 22/27.5 ExtraBold, plus `Official technical record conforming to Department of Transportation & Fleet Safety Directive 44B.`
    - Vehicle summary bar 560x122, radius 48, `#F4F3F8`: subject vehicle, VIN, odometer, license plate.
    - Metrics 560x92: three 178.7x72 pills (`104 Checks Passed`, `2 Flagged Defects`, `Marcus Vance / Lead Inspector`).
    - Evidence header 560x60 + 2-photo grid 560x252, each photo 272x252, radius 48: image 272x176 with overlay chips (`Pass: 6.2 mm`, `Defect #01: Scuff`, filenames) and caption card 272x76.
    - Footer 560x203: 95x96 circular `APPROVED` stamp with `ISO 17020`, `BAY #04`; `TechInspect Certified Facility`, `Licence #DOT-CA-994012`, audit code; 192x82 signature line with SVG signature and `Marcus Vance / Master Inspector ASE #40921`.
- Shell `Header` (`1:3129`) 1184x80 overlay and `Aside` (`1:3152`) 96x800; Settings active.
- Scroll: content HUG to 1227.6; no scrollbar. The A4 paper is static; the toolbar suggests zoom/page navigation.
- Responsiveness: fixed 320 + 32 + 752; no tablet/phone or RTL variant. The A4 preview itself is fixed 656x927.6, which cannot shrink without a new layout.

## 3. Visual tokens observed
### Colours (exact hex, usage, approx count)
| Hex | Usage | Count |
|---|---|---:|
| `#5E5D69` | Secondary text, labels, metadata | 42 |
| `#1A1B1F` | Primary text, VIN/plate, brand | 37 |
| `#FFFFFF` | Sidebar cards, paper, buttons | 25 |
| `#F4F3F8` | Preview pane, tonal cards, stat pills | 15 |
| `#006C49` | Positive/audit text, stamp border | 12 |
| `#10B981` | Primary CTA, toggle, status dots | 9 |
| `#BA1A1A` | Defect dot/badge, proof border | 3 |
| `#EEEDF3` | Neutral chips, print button | 3 |
| `#F4F3F899` | Translucent stat pills | 3 |
| `#1A1B1FD9` | Filename overlay | 2 |
| `#E3E2E7` | Dividers | 2 |
| `#FFFFFFF2` | Evidence chip overlay | 2 |
| `#3C4A42` | Audit code | 1 |
| `#93000A` | Defect icon | 1 |
| `#BA1A1A1A` | Defect pin fill | 1 |
| `#FFDAD6` | Defect icon tile | 1 |
| `#FFFFFFE5` | Header tint | 1 |

White on `#10B981` is ~2.54:1; `#10B981` text/icons on white are ~2.54:1. The black `#1A1B1F` and `#006C49` text pairs pass normal-text contrast. The paper itself is mostly high-contrast.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)
UI uses `Plus Jakarta Sans`; technical identifiers use `Liberation Mono`. The paper is English-only.

| Role | Weight | Size/line | Tracking | Usage |
|---|---|---|---|---|
| Certificate H1 | 800 | 22/27.5 | -0.55 | `VEHICLE INSPECTION & COMPLIANCE CERTIFICATE` |
| Document H2 | 700 | 18/24 | -0.27 | `TECHINSPECT`, delivery name |
| Card title | 700 | 16/22 | -0.16 | `Digital Certification Seal`, action rows |
| Body | 400 | 13/18 | 0 | Metadata, captions, disclaimer-like copy |
| UI value | 700 | 12/16 | +0.24 | Metadata values, filenames, audit code |
| UI label | 600 | 11/14 | +0.44 to +1.10 | Uppercase section labels, `A4 Standard`, chips |
| Micro | 700-800 | 10/15, 9/9, 8/12, 7/10.5 | mixed | Filenames, stamp text, `ISO 17020`, `BAY #04` |

The stamp uses 7-9px text, which is below normal body size and cannot scale to 200% on the fixed paper. No Arabic font, RTL alignment or bilingual columns are present, even though the actual PDF is bilingual.

### Radii, shadows/elevation, strokes, spacing
- Radii: 48 for the preview pane, paper and photo cards; 32 for sidebar cards and status pill; 16 for inputs/chips; 9999 for pills, toolbar and toggle.
- Shadows: paper and cards use the standard two-layer shadow; primary CTA uses the emerald CTA shadow; the paper adds a large ambient shadow.
- Strokes: stamp has a `#006C49` ring; defect pin has `#BA1A1A` border; dividers `#E3E2E7`; most cards are borderless.
- Spacing: 4 (39), 8 (25), 12 (23), 16 (19), 10 (16), 24 (13), 20 (8), 32 (6), 48 (6), 40 (4), 56 (1). The paper uses 48/24/20/16 insets; the 48px paper radius is a screen-only treatment, not a print property.

Token drift: current `AppTheme` primary is `#0B3B4A`; PDF print CSS uses `#17212b`, `#0b3b4a`, `#0f6b6f`, `3mm/2mm` radii and 8-22pt type. This frame uses `#006C49`/`#10B981`, 32/48 radius and `Plus Jakarta Sans`, which is licence-pending.

## 4. Components
| Figma pattern / node | Map to current design system | Notes |
|---|---|---|
| A4 paper preview `1:2979` | No equivalent | No paper/canvas renderer in the Flutter design system; PDF is a server-side Chromium template. |
| Floating toolbar `1:2961` | No equivalent | Zoom/page/print toolbar only for this preview. |
| Metadata card `1:2862` | `AppCard` + `AppListTile` rows | Could be composed, but no document-metadata component. |
| Print settings module `1:2910` | `AppCard` / `AppButton` / `Switch` / segmented control | No print-settings component. |
| Recipient card `1:2947` | `AppListTile` / delivery card | Current delivery card shows `recipientMasked`; design shows full email. |
| Compliance stamp `1:3095` | No equivalent | Circular vector stamp; not a report component. |
| Signature line `1:3119` | No equivalent | SVG signature + label; no signature capture/display component. |
| Evidence cards `1:3060`, `1:3074` | `AppCard` | Evidence grid exists in the public report HTML/PDF, not as a Flutter component. |
| Header/aside | `AppBar` + `NavigationRail` | Current shell has Jobs/Staff/Templates; Settings is active here. |

## 5. Assets
`assets/manifest.json` reports **26** assets: 22 individual SVGs (21 icons + 1 signature `Vector` 130.5x21.4), 2 composed SVGs (`Nav` 96x600, `Aside` 96x800) and **2 raster** images: `Tire Tread Depth Examination` 512x279 and `Rear Sliding Door Scratch Markup` 512x279. Both rasters are evidence-like photos, not guide images; the second includes a red annotation ring. No avatar photo; the recipient avatar is a vector icon.

## 6. Content and data
| Visible text / label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Back link | `Return to Inspection Jobs` | Jobs route | Navigation only. |
| Status | `PDF Ready (v2.1)` | `ReportAdminDto.pdfReady`, `version` | Report version is an `int`; `v2.1` is not the current format. |
| Status | `AUDITED` | Audit event exists | No "audited" field/state. |
| Metadata | `Generated Oct 24, 2024 • 14:32` | `finalizedAt`/generation timestamp | No year on screen 09; date format inconsistent. |
| Metadata | `File Size 2.4 MB (Vector HQ)` | No | Invented size/format. |
| Metadata | `Security Hash SHA-256 #89c4...` | `snapshotHash` | Truncated; current hash is full hex. |
| Metadata | `Sign-off Status Cryptographically Signed` | No | No cryptographic signature; only a snapshot hash. |
| CTA | `Send Email to Client` | Delivery send endpoint | Requires email consent and a recipient; no consent shown. |
| CTA | `Download PDF` | Admin PDF endpoint | Public PDF is disabled by default; design shows it unconditionally. |
| Print orientation | `PRINT ORIENTATION`, `A4 Standard`, `Portrait`, `Landscape` | No | Actual print template is fixed A4 (`@page { size: A4; }`); no orientation setting exists. |
| Toggle | `Include High-Res Evidence`, `Attach raw macro photos` | No | Would conflict with derivative-only evidence and attachment limits. |
| Toggle | `Stamp Physical Seal`, `ISO 17020 shop compliance mark` | No | Prohibited certification/licence claim. |
| Button | `Direct System Print` | No | No print endpoint; browser print is not wired here. |
| Recipients | `ASSIGNED DISTRIBUTION`, `Apex Logistics Fleet Ops`, `fleet-compliance@apex.io` | `DeliveryDto.recipientMasked` | Full email is PII; should be masked. |
| Toolbar | `100%`, `Page 1 of 1`, `Prepress Verified` | No page count/prepress state | `Page 1 of 1` contradicts a multi-photo, potentially multi-page report; `Prepress Verified` is invented. |
| Paper brand | `TECHINSPECT`, `AUTOMOTIVE PRECISION SYSTEMS` | Product brand is TrueReport | Different brand and tagline; not the product. |
| Paper header | `CERTIFICATE #1042`, `Issue Date: Oct 24, 2024` | `reportNumber`, `finalizedAt` | "Certificate" is prohibited; number/date are sample. |
| Paper title | `VEHICLE INSPECTION & COMPLIANCE CERTIFICATE` | Report title | Prohibited certificate/compliance claim. |
| Paper subtitle | `Official technical record conforming to Department of Transportation & Fleet Safety Directive 44B.` | No | Invented official/regulatory claim. |
| Vehicle | `2024 Ford Transit 350` | `Vehicle.make/model/year` | Real fields; screen 09 says `350 High Roof`, screen 12 says `350`. |
| VIN | `1FTBR1Y85RKB92104` | `vinMasked` only | Full VIN on a customer-facing PDF violates the public allowlist; current print template uses `vinMasked`. |
| Odometer | `14,820 mi` | `odometerValue/unit` | Real field but inconsistent with screen 09 (`24,812 mi`) for the same VIN. |
| Plate | `7XYZ994 (CA)` | No | Plate is never public; `ReportSnapshot` has no plate. |
| Metrics | `104 Checks Passed`, `2 Flagged Defects` | Coverage/result counts | "Passed" is prohibited wording; counts not in current DTO. |
| Technician | `Marcus Vance`, `Lead Inspector` | `technician.displayName` | `Lead Inspector` is a title, not a role. |
| Evidence header | `DIAGNOSTIC EVIDENCE PHOTO GRID`, `• Macro 4K captures`, `2 Findings Captured` | `evidenceIds`; no 4K claim | "4K" is invented. |
| Photo 1 | `Pass: 6.2 mm`, `IMG_3091_R_FRONT`, `Front Right Tire Tread Profile`, `Inner/Outer wear patterns uniform within 0.3mm tolerance.` | No measurement fields | Invented measurement/result; screen 09 shows 8.2/8.5 mm front steer. |
| Photo 2 | `Defect #01: Scuff`, `IMG_3092_DOOR_SCRATCH`, `Passenger Sliding Door Clear-Coat`, `Surface paint abrasion: 42mm. Primer unbreached.` | No measurement fields | Invented measurement; filename is not a safe caption. |
| Stamp | `APPROVED`, `ISO 17020`, `BAY #04` | No | Prohibited approval/certification and invented bay. |
| Footer | `TechInspect Certified Facility`, `Licence #DOT-CA-994012`, `Audit verification code: TI-24-OCT-1042` | No licence fields | Invented licence/facility claim. |
| Signature | `Marcus Vance`, `Master Inspector ASE #40921` | `technician.displayName` only | Invented certification number and signature. |
| Disclaimer | none | `disclaimer`/`notCertified` exist | Actual print template says "Not an official certificate." It is missing here. |

No customer name/phone is shown, but a full email, full VIN and plate are. The PDF would be delivered to a customer, so these are direct public-facing exposures.

## 7. States shown / not shown
Shown: PDF ready, one page, 100% zoom, portrait A4, both print toggles on, recipient assigned, signature/stamp present.

Not shown: PDF generating, generation failed, PDF disabled by public policy, no evidence, missing derivative, no recipient, consent missing, revoked link, loading, error, offline, print/export failure, page count >1, Arabic/English bilingual preview, 200% text, RTL, phone/tablet.

## 8. Implied interactions
Send email, download PDF, toggle portrait/landscape, toggle high-res evidence, toggle physical seal, direct print, zoom in/out, page navigation, open/close preview. No consent, recipient selection, confirmation, loading, disabled or error interaction is shown. `Send Email to Client` and `Direct System Print` look immediate.

## 9. Correspondence to current product
- **Existing PDF:** `server/src/main/resources/templates/report/print-report.html` is an A4 (`@page { size: A4; margin: 16mm 13mm 20mm; }`) **bilingual** template (`EN` + `AR` grids), rendered by `ChromiumPdfRenderer`/`ReportPdfService`. It uses `r.vehicle.vinMasked`, not full VIN, has no plate, includes disclaimers and `Not an official certificate.` (`th:text="${r.en.notCertified}"`), and prints `verificationHash`.
- **Existing admin actions:** `report_page.dart` downloads `GET /api/v1/workshop/jobs/{jobId}/report/pdf` and toggles `PUT .../report/pdf-download`; public `/r/{token}/pdf` exists only if `pdfDownloadEnabled` (`docs/phase-1/06-public-report-design.md` §10 says download is disabled by default).
- **Delivery:** `POST /api/v1/workshop/jobs/{jobId}/deliveries` requires channel/language and consent; `Email` with PDF requires `EMAIL` consent (`docs/phase-7/00-decisions.md` §2). The design's `Send Email to Client` does not show consent or a recipient.
- **Data gap:** `ReportAdminDto` has `pdfReady`, `pdfDownloadEnabled`, `reportNumber`, `version`, `snapshotHash`; no file size, page count, signature, licence, stamp, plate or print orientation. `ReportSnapshot` has `vinMasked`, no plate.
- **UI gap:** there is no print-preview/canvas component, no print-settings persistence, no print endpoint. This is a **new screen/feature** requiring server/PDF-template/model changes; it cannot be delivered as a UI-only change without dropping the certificate claims and print controls.

## 10. Locked-rule conflicts / unsafe-to-ship content
1. **Full VIN and plate on a customer-facing PDF.** The task rule says the public report "never shows customer name/phone/email/full VIN/plate". A PDF sent to the customer is a public-facing report artifact. `docs/phase-1/06-public-report-design.md` §3.2 lists full VIN, plate and registration under "Never public". The actual `print-report.html` correctly uses `vinMasked` and omits the plate; this design shows both.
2. **Certificate/compliance/licence claims.** `CERTIFICATE #1042`, `VEHICLE INSPECTION & COMPLIANCE CERTIFICATE`, `Official technical record conforming to Department of Transportation & Fleet Safety Directive 44B`, `TechInspect Certified Facility`, `Licence #DOT-CA-994012`, `ISO 17020`, `APPROVED`, `Master Inspector ASE #40921`, `Cryptographically Signed`, `AUDITED`, `Prepress Verified`. The task rule forbids certification/"verified by"/compliance claims; `docs/phase-1/06-public-report-design.md` §12 says "Do not use 'certified', 'independently reviewed', 'manager approved' or 'RTA approved' unless factually and legally true." None of these licences exist.
3. **"Passed"/"Approved" verdict language.** `104 Checks Passed` and the `APPROVED` stamp use a verdict that `docs/phase-1/10-design-system.md` §3.3 forbids for `NO_ISSUE_OBSERVED`: "must never be labelled 'Pass', 'Perfect' or 'Certified'." Safety findings are not an approval.
4. **High-resolution originals.** `Include High-Res Evidence` / `Attach raw macro photos` conflicts with `docs/phase-1/06-public-report-design.md` §3.2 ("Original high-resolution evidence ... Never public") and §9 (derivatives only, EXIF stripped). The actual PDF uses derivatives.
5. **Physical seal toggle.** `Stamp Physical Seal` / `ISO 17020 shop compliance mark` lets the UI add a compliance mark that no licence or process supports; this is a false claim and a legal risk.
6. **Bilingual PDF.** The task context says "bilingual PDF (D5)"; `docs/phase-1/06-public-report-design.md` §8 says "The PDF is bilingual". This preview is English-only, with no Arabic column, RTL layout or Arabic labels. `print-report.html` has both.
7. **Default PDF download.** `docs/phase-1/06-public-report-design.md` §10 says PDF download is "Disabled by default" on the public page; the actual admin PDF is allowed, but the design shows `Download PDF` without any state/consent/availability. It should not be presented as always available.
8. **Full recipient email.** `docs/phase-7/00-decisions.md` §8 says the admin UI displays only masked recipients. `fleet-compliance@apex.io` is full PII.
9. **Invented measurements/versions/licences.** `v2.1`, `2.4 MB (Vector HQ)`, `4K`, `6.2 mm`, `42 mm`, `14,820 mi` (vs screen 09's 24,812 mi), `Licence #DOT-CA-994012`, `ASE #40921` and `Page 1 of 1` violate "Never invent versions/licences/measurements/results."
10. **No "Not an official certificate".** The actual print template includes `Not an official certificate.`; this design replaces it with "CERTIFICATE" and "APPROVED" claims.
11. **WCAG 2.2 AA / print accessibility.** White on `#10B981` is ~2.54:1; 7-9px stamp text cannot reach 200%; the fixed paper has no reflow for Arabic or large text.
12. **Tokens/fonts/RTL.** `#006C49`/`#10B981`/48px radii and `Plus Jakarta Sans` are not the current print/design tokens; the actual print CSS uses its own tokenised palette and bundled fonts.

## 11. Open questions / could not verify
- Is this preview intended for the **customer-facing PDF** or an internal print artifact? If customer-facing, full VIN/plate and certificate claims must be removed.
- Why is this branded `TECHINSPECT` instead of TrueReport? Is it a separate white-label template?
- Is `Send Email to Client` using the existing delivery consent flow, and which recipient/consent state is shown?
- Are `Include High-Res Evidence` and `Stamp Physical Seal` real stored settings, or client-only toggles? No model/endpoint exists.
- Is `Direct System Print` a browser print action or a server print job? No endpoint exists.
- Which page count is correct for the real report (2 photos, 18 scans, 104 checks)? `Page 1 of 1` is not credible.
- Where do `6.2 mm`, `42 mm`, `4K`, `2.4 MB`, `v2.1` and the licences come from? None are in `ReportSnapshot`/`ReportAdminDto`.
- Should the preview render the actual bilingual `print-report.html` output rather than a separate certificate design?
- What are the Arabic/RTL layout and print CSS for this preview?
