# Screen 12 — Print-Ready PDF Preview (F3-0 group C)

- Figma source: `docs/ui/figma-export/Workshop_admin_figma/screens/12_12._Print-Ready_PDF_Preview/12._Print-Ready_PDF_Preview.json` (node `1:2857`, `serializedNodeCount: 314`), visual ref `12._Print-Ready_PDF_Preview@2x.png`
- Prior spec (read, not edited): `docs/ui/figma/specs/workshop_admin/12-print-ready-pdf-preview.md`
- Frame: **1280 × 1227.584**, `VERTICAL`, white — width 1280 confirmed as drawn (O3).
- Root children: `Background` (`1:2858`, 1280×1227.6, left pad 96) → `Header` (`1:3129`, 1184×80) → `Aside` (`1:3152`, 96 wide).

## Node-level layout (as drawn)
- `Main` 1184×1227.6 at x=96, padding 80/40/48/40; content 1104 wide, `HORIZONTAL`, gap 32: left sidebar 320 + right preview 752.
- Sidebar: back link `Return to Inspection Jobs`; overview card (320×494, radius 32): status pill `PDF Ready (v2.1)` + `AUDITED`; metadata rows `Generated Oct 24, 2024 • 14:32`, `File Size 2.4 MB (Vector HQ)`, `Security Hash SHA-256 #89c4…`, `Sign-off Status Cryptographically Signed`; CTAs `Send Email to Client` (emerald) + `Download PDF` (tonal). Print module (320×302): `PRINT ORIENTATION`, `A4 Standard`, segmented `Portrait/Landscape`, toggles `Include High-Res Evidence` (`Attach raw macro photos`) and `Stamp Physical Seal` (`ISO 17020 shop compliance mark`), `Direct System Print`. Recipient card (320×120): `ASSIGNED DISTRIBUTION`, `Apex Logistics Fleet Ops`, full email `fleet-compliance@apex.io`.
- Preview pane (752×1099.6, radius 48, `#F4F3F8`): floating toolbar (400×52, pill) with zoom controls, `100%`, `Page 1 of 1`, `Prepress Verified`; A4 paper 656×927.6 (aspect 0.707 = A4 portrait) with header (`TECHINSPECT / AUTOMOTIVE PRECISION SYSTEMS`, `CERTIFICATE #1042`, `Issue Date: Oct 24, 2024`), H1 `VEHICLE INSPECTION & COMPLIANCE CERTIFICATE` + `Official technical record conforming to Department of Transportation & Fleet Safety Directive 44B.`, vehicle bar (`2024 Ford Transit 350`, full VIN `1FTBR1Y85RKB92104`, `14,820 mi`, plate `7XYZ994 (CA)`), metric pills (`104 Checks Passed`, `2 Flagged Defects`, `Marcus Vance / Lead Inspector`), `DIAGNOSTIC EVIDENCE PHOTO GRID • Macro 4K captures` with 2 photo cards (`Pass: 6.2 mm`, `IMG_3091_R_FRONT`; `Defect #01: Scuff`, `IMG_3092_DOOR_SCRATCH`, `Surface paint abrasion: 42mm. Primer unbreached.`), footer with circular `APPROVED / ISO 17020 / BAY #04` stamp, `TechInspect Certified Facility`, `Licence #DOT-CA-994012`, `Audit verification code: TI-24-OCT-1042`, and ink signature `Marcus Vance / Master Inspector ASE #40921`.

## Components → `design_system`
- Sidebar cards/rows → `AppCard` + `AppListTile`; orientation segmented control, toggles, print button → `AppButton`/`Switch` compositions. All buildable as generic UI.
- A4 paper renderer, floating zoom/page toolbar, compliance stamp, signature line, evidence-photo grid with overlays → **no equivalent** (PDF is a server-side Chromium template, not a Flutter canvas). No print-settings or print-job component exists.

## Assets
- 26 assets per JSON: 22 single SVGs (21 icons + 1 signature `Vector` 130.5×21.4) + 2 composed (`Nav`, `Aside`) + **2 rasters** 512×279 each: `Tire Tread Depth Examination` and `Rear Sliding Door Scratch Markup` (second has a red annotation ring). Evidence-like photos, not guide images. No avatar photo.

## States shown / not shown
- Shown: PDF ready, 1 page, 100% zoom, portrait, both toggles on, recipient assigned, stamp + signature present.
- Not shown: generating / failed, PDF disabled by policy, no evidence / missing derivative, no recipient, consent missing, revoked link, loading / error / offline / print-export failure, page count ≠ 1, bilingual preview, 200% text, RTL, phone/tablet.

## Element → data/endpoint/state mapping
| Figma element | Maps to | Verdict |
|---|---|---|
| Paper vehicle `2024 Ford Transit 350`, tech `Marcus Vance` | `ReportSnapshot.vehicle.make/model/year`, `technician.displayName` (`ReportAdminDto.content`) | Matches existing feature (samples) |
| `PDF Ready (v2.1)`, `Generated Oct 24, 2024 • 14:32`, `SHA-256 #89c4…` | `ReportAdminDto.pdfReady/version/finalizedAt/snapshotHash` | UI work only (`v2.1` is not the int-version format; hash truncated) |
| `Download PDF` | `GET /api/v1/workshop/jobs/{jobId}/report/pdf`, gated by `pdfReady` + `pdfDownloadEnabled` (public `/r/{token}/pdf` only if enabled; download disabled by default) | Matches existing feature **only if** gated (O9); unconditional button = conflict |
| `Send Email to Client` | `POST /api/v1/workshop/jobs/{jobId}/deliveries` (channel + language + consent; `report_page.dart` `_send`; delivery card shows `recipientMasked`) | Needs consent/recipient state — no consent or recipient selector is drawn |
| `PRINT ORIENTATION`, `A4 Standard`, `Portrait/Landscape` | Fixed `@page { size: A4; }` in `server/.../templates/report/print-report.html` — no orientation setting | Needs server change — do not build (no print-studio features, O9) |
| `Include High-Res Evidence` / `Attach raw macro photos` | Public allowlist serves derivatives only, EXIF stripped | LOCKED-RULE conflict (never expose originals) |
| `Stamp Physical Seal` / `ISO 17020 shop compliance mark` | No seal/licence field | LOCKED-RULE conflict (false compliance mark) |
| `Direct System Print` | No print endpoint (browser print is not wired here) | DATA GAP — do not build |
| Full VIN `1FTBR…`, plate `7XYZ994 (CA)`, full email `fleet-compliance@apex.io` | Public allowlist: `vinMasked` only; never plate/registration/customer contact (`print-report.html` uses `vinMasked`, omits plate) | LOCKED-RULE conflict — full VIN/plate/email must be removed from any customer-facing PDF surface |
| `CERTIFICATE #1042`, `VEHICLE INSPECTION & COMPLIANCE CERTIFICATE`, `Official technical record… Directive 44B`, `TechInspect Certified Facility`, `Licence #DOT-CA-994012`, `ISO 17020`, `APPROVED`, `Cryptographically Signed`, `AUDITED`, `Prepress Verified`, `Master Inspector ASE #40921` | No certificate/licence/approval/signature fields; integrity = snapshot hash; disclaimer posture is `Not an official certificate.` | LOCKED-RULE conflict (O6/O9) — entire certificate/stamp/signature layer must be replaced by OUR bilingual report/PDF |
| `104 Checks Passed`, `2 Flagged Defects` | Coverage/result counts | LOCKED-RULE conflict on `Passed` verdict wording; counts need data work |
| `6.2 mm`, `42mm`, `4K`, `2.4 MB (Vector HQ)`, `14,820 mi` (vs 24,812 mi on screen 9, same VIN), `Page 1 of 1` | No measurement/size/page-count fields | DATA GAP + inconsistent sample (odometer mismatch across screens 9/12) |
| `TECHINSPECT / AUTOMOTIVE PRECISION SYSTEMS` brand | Product brand is TrueReport | Conflict — preview must render OUR PDF, not a white-label certificate |
| English-only paper, no Arabic column | Real `print-report.html` is bilingual EN+AR with `vinMasked` + disclaimers | Conflict — bilingual + RTL required; this preview is not a valid PDF reference |

## Classification
**Needs new data or server change + contains locked-rule conflicts — do not build as drawn.** Only the gated download, snapshot-backed metadata (report number, hash, finalized date), and masked delivery identity map to the product. Orientation/high-res/seal/direct-print controls, certificate branding, full VIN/plate/email, stamp/signature, and English-only A4-studio treatment all violate O9 or need server/template changes.

## Locked rules applied (O9)
- Preview (if any) renders OUR report/PDF through the same allowlist: masked VIN, no plate, no customer contact, derivatives only, bilingual, with the `Not an official certificate` posture — never a `TECHINSPECT` compliance certificate.
- PDF download/email follow the existing per-report `pdfReady`/`pdfDownloadEnabled` gate and the delivery consent flow; no unconditional `Download PDF` / `Send Email to Client` / `Direct System Print`.
- No print-studio features: no A4-orientation switch, no high-res-originals toggle, no physical/compliance seal stamp.

## New-component list
- None approved. Paper canvas, zoom/page toolbar, stamp, signature line, and print-settings module are **rejected**. If a preview is ever approved, it must embed the actual server-rendered bilingual PDF output, not a separate certificate design.

## Could not verify
- Which artifact this previews (customer-facing PDF vs internal print) — O9 treats any customer-sent PDF as public-allowlisted either way.
- Real page count, file size, photo derivatives, and measurement sources — none in `ReportAdminDto`/`ReportSnapshot`; verified absent only by inspection, not by rendering the PDF service.
- Recipient/consent state for `Send Email to Client` — no selector drawn; flow exists in `report_page.dart` `_send`.
- Arabic/RTL paper layout and print CSS — present in `print-report.html`, absent in Figma.
