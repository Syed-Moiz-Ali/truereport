# Figma design intake — inventory (Phase F0)

**Project:** TrueReport
**Date:** 5 November 2026
**Scope:** identify, inspect and report only. No application code, server, config, data or existing design doc was changed.
**Status:** read-only intake. This inventory does not choose a visual direction.

---

## 1. What was provided

Source folder: `figma/`

| Item | Type | Size | Notes |
|---|---|---:|---|
| `technision_figma/` | folder | 19,587,667 B / 554 files | Technician app export |
| `Workshop_admin_figma/` | folder | 35,397,225 B / 724 files | Workshop Admin export |
| `platform_admin_figma/` | folder | 27,847,759 B / 614 files | Platform Admin export |
| `public_report_figma/` | folder | 13,710,381 B / 282 files | Public report export |
| `technision_figma.zip` | archive | 19,705,487 B | Original archive, left untouched |
| `Workshop_admin_figma.zip` | archive | 35,547,069 B | Original archive, left untouched |
| `platform_admin_figma.zip` | archive | 27,984,195 B | Original archive, left untouched |
| `public_report_figma.zip` | archive | 13,782,113 B | Original archive, left untouched |

All four archives were extracted to `docs/ui/figma-export/<name>/` and the originals were left untouched. The extracted copies match the already-present `figma/` folders on file count and total byte size (verified below); a per-file SHA-256 comparison across all 993 assets was not run, so "byte-identical" is not claimed file-by-file.

| App | Extracted files | Extracted bytes |
|---|---:|---:|
| `figma-export/technision_figma` | 554 | 19,587,667 |
| `figma-export/Workshop_admin_figma` | 724 | 35,397,225 |
| `figma-export/platform_admin_figma` | 614 | 27,847,759 |
| `figma-export/public_report_figma` | 282 | 13,710,381 |

Each export uses the Dev Export for Figma multi-screen package (`schema: dev-export-multiscreen-package`, `schemaVersion: 1.0.0`) with:
- `package-manifest.json`
- `IMPLEMENTATION_GUIDE.txt`
- `screens/<NN_screen-name>/<screen-name>.json`
- `screens/<NN_screen-name>/<screen-name>@2x.png`
- `screens/<NN_screen-name>/assets/manifest.json`
- `screens/<NN_screen-name>/assets/ASSET_CATALOG.html`
- `screens/<NN_screen-name>/assets/svg/*.svg`, `assets/composed/svg/*.svg`, `assets/png/*.png`, `assets/images/*`

### 1.1 Source metadata

All four manifests report the same Figma source:

- `editorType`: `figma`
- `fileName`: **"Untitled"**
- `page`: `Page 1` (`0:1`)
- `generatedAt`: 2026-11-05 between 06:39 and 06:43 UTC
- ordering: "top-to-bottom, then left-to-right by their position on the Figma page"

**Consequence:** export order is page position, not screen numbering. Several exports are out of numeric order (see §5). There is no Figma file ID, version, branch or library provenance in the package.

---

## 2. Apps present and missing

| Product surface | Export present? | Screens | Frame sizes | Verdict |
|---|---|---:|---|---|
| Field Technician mobile app | Yes — `technision_figma` | 16 | 390 × 858–1361.94 | Present |
| Workshop Admin (tablet/desktop) | Yes — `Workshop_admin_figma` | 12 | 1280 × 1024–1680.75 | Present |
| Platform Admin (desktop) | Yes — `platform_admin_figma` | 10 | 1280 × 1024–1293 | Present, **one screen short** |
| Public report (server-rendered web) | Yes — `public_report_figma` | 7 | 4 × 390 (mobile), 3 × 1280 (desktop) | Present as slices |
| Customer app / customer portal | **No** | 0 | — | Correctly absent; locked out of scope |
| Admin 2FA / TOTP challenge screen | **No** | 0 | — | Missing from Platform Admin export (PRD lists 11 screens; only 10 exported) |

The PRD in `docs/ui/apex_vehicle_inspection_ecosystem_product_prd.md` claims 16 Technician, 12 Workshop Admin, **11 Platform Admin** and 7 Public screens. The export contains **16 / 12 / 10 / 7**. The missing Platform Admin screen is "Admin 2FA / TOTP Verification". `docs/phase-1/13-adrs/0021-admin-totp-configurable.md` records `ADMIN_TOTP_REQUIRED=false` by default and no admin TOTP UI; the missing screen is therefore consistent with the current decision, but it is still a difference from the PRD that must be acknowledged.

The four exports total **45 screens**. The PRD claims 46.

---

## 3. Totals

| App | Screens | Serialized nodes | Assets | Individual SVG | Composed SVG | Raster | Asset bytes | Preview bytes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Technician | 16 | 1,931 | 244 | 220 | 16 | 8 | 1,628,146 | 6,413,827 |
| Workshop Admin | 12 | 3,169 | 337 | 292 | 34 | 11 | 3,368,143 | 11,145,641 |
| Platform Admin | 10 | 2,692 | 286 | 278 | 4 | 4 | 690,910 | 10,155,782 |
| Public Report | 7 | 1,134 | 126 | 112 | 5 | 9 | 1,632,391 | 4,820,827 |
| **Total** | **45** | **8,926** | **993** | **902** | **59** | **32** | **7,319,590** | **32,536,077** |

Asset identity analysis (tokens report, SHA-1 of exported files): **616 unique asset files**, 68 reused across ≥2 screens, 31 reused across apps. Asset filenames are mostly generic (`Icon-1_7094.svg`), so semantic meaning is inferred from node names/positions, not filenames.

The 32 rasters are photos/avatars/illustrations, not evidence derivatives from our snapshot model. Licences and provenance are not evidenced in the packages.

---

## 4. Screen inventory

Column meanings:
- **#** = manifest index (export/page order).
- **Screen label** = the number and name inside the Figma frame. These do not always match `#`.
- **Node** = Figma node id.
- **Size** = frame width × height in logical px.
- **Assets** = manifested assets for that screen (icons + composed + raster).
- **R / C** = raster / composed SVG counts.
- **Warn** = non-fatal export warning "No composed SVG groups were detected in this screen. Individual SVG vectors are still preserved."

### 4.1 Technician — `technision_figma` (16 screens)

| # | Screen label | Node | Size (px) | Assets | R | C | Warn |
|---:|---|---|---|---:|---:|---:|---|
| 01 | 1. Login & Language Selection | `1:7073` | 390 × 858 | 5 | 0 | 0 | yes |
| 02 | 2. Assigned Jobs Dashboard | `1:7131` | 390 × 1002 | 15 | 1 | 0 | yes |
| 03 | 3. Empty State Dashboard | `1:7287` | 390 × 883.75 | 11 | 1 | 0 | yes |
| 04 | 4. Job Details & Intake | `1:7396` | 390 × 1128 | 14 | 1 | 1 | — |
| 05 | 5. Consent & Signatures | `1:7531` | 390 × 972 | 13 | 0 | 1 | — |
| 06 | 6. Equipment Checklist | `1:7643` | 390 × 910 | 9 | 0 | 0 | yes |
| 07 | 7. Main Inspection Hub | `1:7742` | 390 × 1130 | 20 | 1 | 2 | — |
| 08 | 8. 360 Exterior Wireframe | `1:7896` | 390 × 906.25 | 32 | 0 | 3 | — |
| 09 | 9. Defect Detail & Evidence | `1:8021` | 390 × 1031.6667 | 22 | 1 | 2 | — |
| 10 | 10. Photo Annotation & Markup | `1:8135` | 390 × 884 | 17 | 1 | 3 | — |
| 11 | 11. Dense Mechanical List | `1:8220` | 390 × 1080 | 14 | 0 | 0 | yes |
| 12 | **13. Final Review (Missing Items)** | `1:8349` | 390 × 1008 | 17 | 0 | 3 | — |
| 13 | **12. Tire Condition Capture** | `1:8479` | 390 × 1085.5 | 23 | 0 | 1 | — |
| 14 | **15. Offline Sync Queue** | `1:8633` | 390 × 1361.9399 | 16 | 0 | 0 | yes |
| 15 | **14. Finalize & Approval (Swipe)** | `1:8809` | 390 × 1231.25 | 12 | 2 | 0 | yes |
| 16 | 16. Post-Finalization Success | `1:8931` | 390 × 884 | 4 | 0 | 0 | yes |

### 4.2 Workshop Admin — `Workshop_admin_figma` (12 screens)

| # | Screen label | Node | Size (px) | Assets | R | C | Warn |
|---:|---|---|---|---:|---:|---:|---|
| 01 | **3. Create / Schedule Job** | `1:2` | 1280 × 1058 | 22 | 3 | 2 | — |
| 02 | **1. Workshop Dashboard** | `1:299` | 1280 × 1230.672 | 22 | 0 | 4 | — |
| 03 | **2. Live Job Queue** | `1:529` | 1280 × 1125 | 25 | 4 | 2 | — |
| 04 | 4. Assign Technician | `1:821` | 1280 × 1120 | 19 | 0 | 2 | — |
| 05 | 5. Workshop Staff Management | `1:1026` | 1280 × 1048 | 27 | 0 | 2 | — |
| 06 | **7. Workshop Template List** | `1:1307` | 1280 × 1586 | 39 | 0 | 2 | — |
| 07 | **6. Add Staff / Create Account** | `1:1642` | 1280 × 1024 | 22 | 0 | 2 | — |
| 08 | 8. Template Builder | `1:1882` | 1280 × 1251.5 | 50 | 0 | 8 | — |
| 09 | 9. Completed Report Viewer | `1:2236` | 1280 × 1680.75 | 42 | 1 | 4 | — |
| 10 | 10. Share-Link Deactivation | `1:2502` | 1280 × 1024 | 17 | 1 | 2 | — |
| 11 | 11. Workshop Settings | `1:2645` | 1280 × 1674 | 26 | 0 | 2 | — |
| 12 | 12. Print-Ready PDF Preview | `1:2857` | 1280 × 1227.584 | 26 | 2 | 2 | — |

### 4.3 Platform Admin — `platform_admin_figma` (10 screens)

| # | Screen label | Node | Size (px) | Assets | R | C | Warn |
|---:|---|---|---|---:|---:|---:|---|
| 01 | 1. Global Hierarchy & Staff Tree | `1:3172` | 1280 × 1196 | 42 | 4 | 4 | — |
| 02 | 2. Add Staff / Create Account | `1:3560` | 1280 × 1024 | 22 | 0 | 0 | yes |
| 03 | 3. Register New Workshop | `1:3798` | 1280 × 1202 | 19 | 0 | 0 | yes |
| 04 | 4. Workshop Details & Settings | `1:3976` | 1280 × 1024 | 27 | 0 | 0 | yes |
| 05 | 5. Shared Master Inspection-Item Library | `1:4214` | 1280 × 1360 | 35 | 0 | 0 | yes |
| 06 | 6. Master Item Content & Translation Editor | `1:4532` | 1280 × 1544 | 28 | 0 | 0 | yes |
| 07 | 7. Master Dropdowns & Data Catalogues | `1:4809` | 1280 × 1024 | 36 | 0 | 0 | yes |
| 08 | 8. Global Equipment Library | `1:5086` | 1280 × 1180 | 25 | 0 | 0 | yes |
| 09 | **10. Platform Audit Events Log** | `1:5346` | 1280 × 1171 | 29 | 0 | 0 | yes |
| 10 | **9. Global Platform Settings** | `1:5618` | 1280 × 1293 | 23 | 0 | 0 | yes |

### 4.4 Public Report — `public_report_figma` (7 screens)

| # | Screen label | Node | Size (px) | Assets | R | C | Warn |
|---:|---|---|---|---:|---:|---:|---|
| 01 | 1. Customer Summary Hero (Mobile Web) | `1:5938` | 390 × 1016 | 7 | 1 | 0 | yes |
| 02 | 2. Findings by Category: Tyre Defect (Mobile Web) | `1:6035` | 390 × 1326.75 | 21 | 2 | 0 | yes |
| 03 | 3. Exterior Condition & Evidence (Mobile Web) | `1:6161` | 390 × 939.375 | 18 | 3 | 1 | — |
| 04 | 4. Verification & PDF Footer (Mobile Web) | `1:6255` | 390 × 901.69 | 4 | 0 | 0 | yes |
| 05 | 5. Wide Hero & Summary Overview (Desktop Web) | `1:6311` | 1280 × 1190 | 19 | 1 | 0 | yes |
| 06 | 6. Detailed Findings Grid (Desktop Web) | `1:6578` | 1280 × 1687 | 42 | 2 | 4 | — |
| 07 | 7. Limitations & Disclaimer Footer (Desktop Web) | `1:6923` | 1280 × 1188 | 15 | 0 | 0 | yes |

The seven Public screens are **slices of one report**, not seven independent pages. Four are mobile sections and three are desktop sections. They mix mobile and desktop data sets (different vehicles, check counts, tread depths and hashes), so they cannot be treated as one consistent report without choosing a canonical data set.

---

## 5. Ordering mismatches

Screen numbers in the Figma frames are the intended sequence. Export index is page position. The following mismatches are present and are stated inside the corresponding specs:

| App | Export order issue |
|---|---|
| Technician | `#12` = screen **13**, `#13` = screen **12**, `#14` = screen **15**, `#15` = screen **14**. The final-review/tire/offline/finalize sequence is shuffled. |
| Workshop Admin | `#01` = screen **3**, `#02` = **1**, `#03` = **2**, `#06` = **7**, `#07` = **6**. All others match. |
| Platform Admin | `#09` = screen **10**, `#10` = screen **9**. |
| Public Report | Sequential; no mismatch. |

---

## 6. Export quality, warnings and missing data

### 6.1 Warnings

- **22 of 45 screens** carry the non-fatal warning: *"No composed SVG groups were detected in this screen. Individual SVG vectors are still preserved."*
  - Technician: 01, 02, 03, 06, 11, 14, 15, 16 (8)
  - Platform Admin: 02–10 (9)
  - Public Report: 01, 02, 04, 05, 07 (5)
  - Workshop Admin: none
- The warning does not mean the screen is incomplete; it means the exporter found no multi-vector decorative group worth composing. The individual SVGs are present.

### 6.2 Structural limitations

- **No `COMPONENT`, `COMPONENT_SET` or `INSTANCE` nodes.** Node types are `FRAME` 5,893, `TEXT` 1,876, `VECTOR` 906, `RECTANGLE` 245, `GROUP` 6. Everything is a frame/vector tree, so there are no reusable Figma components or variants to map one-to-one. Component patterns must be recognised structurally.
- **No Figma variables or shared styles.** `variableCollections` and `variables` are empty in all 45 JSONs; every `fillStyleId`, `textStyleId`, `strokeStyleId` and `effectStyleId` is blank. All colours/type/radii are raw values. There is no token contract in the design file.
- **No prototype reactions.** All `reactions` arrays inspected are empty. Every interaction in the specs is inferred from layout and labels, not from the file.
- **No Arabic/RTL frames.** There are 20 × 390 px and 25 × 1280 px frames only. No mirrored variants, no Arabic layout, no 200% text state, no dark theme. The only Arabic strings are 11 text nodes on three screens; the technician login uses `FreeSerif` for Arabic and 8 nodes tagged Plus Jakarta Sans have no Arabic glyphs.
- **No responsive/tablet variants.** Desktop is fixed at 1280; technician is fixed at 390. No 600/900/1200 breakpoint frames, no min/max width, no scroll model for long frames. A few technician screens (03, 07, 08) use absolute positioning (`layoutMode: NONE`), so their structure cannot be translated directly to Auto Layout.
- **Some frames exceed a normal viewport.** Technician 14 is 1361.94 px tall; Workshop 09 is 1680.75; Public 06 is 1687. These are tall scroll frames, not device screens.
- **Six vector assets report width 0 in their asset manifests** (public 02 and 06, technician 08 and 13). The SVG/PNG files exist; the manifest dimension is unreliable for those. Raster `pixelSize` metadata is present where inspected.
- **The logo is missing as an asset on the technician login.** Frame `1:7090` ("TechInspect Minimal Logo") has no serialized children and no `assetIndex` entry; only the blurred green glow is exported. The wordmark is live text.

### 6.3 Missing product material

- No Admin 2FA/TOTP screen (see §2).
- No customer app/portal (correctly absent).
- No error/empty/offline/loading state screens for the admin apps; only the technician has one empty state (screen 03) and one offline queue (screen 14).
- No Arabic or RTL screens, no dark-mode screens, no accessibility focus/zoom states.
- No design tokens/variables, no component library, no Figma file ID/version.
- No licence/provenance for the 32 rasters, the 616 unique assets, or any font.
- No information about which sample values are real. The export uses internally inconsistent sample data (different vehicles/VINs/hashes/odometers for the same report).

### 6.4 Readability

- 45 / 45 screen JSONs parsed.
- 45 / 45 `@2x.png` previews and all asset manifests were readable.
- 4 / 4 package manifests parsed.
- 993 asset files hashed by the token analyst; no file failed to parse.
- **Nothing in the package is unreadable or corrupt.** The limitations are semantic (missing metadata/variants), not file damage.

---

## 7. What each app contains (one-line summary)

| App | Screens | What the export shows |
|---|---:|---|
| Technician | 16 | Full proposed inspection flow: login/language, jobs dashboard, empty state, job intake, consent + signature, equipment/BLE checklist, inspection hub, 360 exterior wireframe, defect/evidence, photo annotation, dense checklist, tire capture, final review, offline queue, swipe finalize, success. |
| Workshop Admin | 12 | Desktop console: dashboard, live queue, create/schedule job, assign technician, staff management, add staff, template list, template builder, completed report viewer, share-link deactivation, workshop settings, print-ready PDF preview. |
| Platform Admin | 10 | Desktop console: hierarchy/staff tree, add staff, register workshop, workshop details, master item library, master item translation editor, master dropdowns, global equipment library, audit events log, global platform settings. |
| Public Report | 7 | Mobile + desktop slices of a customer-facing report: hero/summary, tyre findings, exterior/evidence, verification/PDF footer, wide hero, detailed findings grid, limitations/disclaimer. |

---

## 8. Deliverables produced from this intake

| File | Contents |
|---|---|
| `docs/ui/figma/inventory.md` | This file |
| `docs/ui/figma/specs/technician_app/*.md` | 16 per-screen specs |
| `docs/ui/figma/specs/workshop_admin/*.md` | 12 per-screen specs |
| `docs/ui/figma/specs/platform_admin/*.md` | 10 per-screen specs |
| `docs/ui/figma/specs/public_report/*.md` | 7 per-screen specs |
| `docs/ui/figma/tokens.md` | Cross-app token extraction and mapping |
| `docs/ui/figma/fonts-and-licences.md` | Font usage, licences, glyph coverage |
| `docs/ui/figma/contrast-report.md` | WCAG 2.2 contrast audit |
| `docs/ui/figma/gap-report.md` | Comparison with the product |
| `docs/ui/figma/decisions-needed.md` | Decisions for the product owner |
| `docs/ui/figma/build-plan.md` | Proposed order, batches, gates and fidelity harness |
