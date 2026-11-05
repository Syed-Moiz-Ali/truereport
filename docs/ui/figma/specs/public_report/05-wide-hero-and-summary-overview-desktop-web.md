# 5. Wide Hero & Summary Overview (Desktop Web)

- App: Public Report
- Figma node: 1:6311
- Frame: 1280x1190 px (desktop)
- Export folder: `screens/05_5._Wide_Hero_&_Summary_Overview_(Desktop_Web)`
- Sources read: `5._Wide_Hero_&_Summary_Overview_(Desktop_Web).json`, `5._Wide_Hero_&_Summary_Overview_(Desktop_Web)@2x.png`, `assets/manifest.json`
- Confidence: high for layout/tokens; high for conflicts (explicit copy and exposed VIN).

## 1. Purpose

Desktop overview of the report: sticky app bar with brand, three section tabs, "Download PDF" and an account avatar; a hero header with fleet/technician chips, title, "Verified Session" timestamp, print/share/audit-tag controls; a 2-column body with a telemetry image card and inspector dossier on the left, and a compliance summary, sub-system verification matrix and cryptographic lock on the right; a footer with reference and accreditation claims.

## 2. Layout structure

Root `1:6311` VERTICAL, width FIXED 1280, height HUG 1190, fill `#FFFFFF`. Three sibling frames:

| Order | Node | Geometry | Notes |
|---|---|---|---|
| 1 | Main `1:6312` | 1280x1108 | VERTICAL, padding 80/0/82/0 |
| 1.1 | Container `1:6313` | 1280x946 | VERTICAL, padding 32/20/32/20, gap 32 |
| 1.1.1 | Hero header `1:6314` | 1240x98 | HORIZONTAL, gap 573.97 |
| 1.1.2 | Body grid `1:6341` | 1240x752 | **GRID**; left col `1:6342` 498 wide, right col `1:6394` 710 wide (32 px gutter) |
| 2 | Footer `1:6536` | 1280x82 | VERTICAL, padding 32/0/32/0, top shadow `40 @ 0,-14` |
| 3 | Header `1:6550` | 1280x80 | VERTICAL, fill `#FFFFFFE5`, blurs 48, drop shadow `8 @ 0,2` + `40 @ 0,14`; **overlays** Main at y=0 (sticky/translucent bar) |

Header (`1:6551`, 1280x80, pad 0/20): logo cluster 239.63x40 (40 px emerald circle + 16/20 brand + 11/14 "CERTIFIED INSPECTION DIVISION"); nav pill 495.57x48 with 4 px padding and three links: "Report Overview" active 159.05x40 (`#F4F3F8`, 16/24), "Detailed Findings" 147.55x34, "Compliance & Scope" 172.97x34 (14/18 700); right cluster 214.66x48 with "Download PDF" 166.66x48 and 32x32 account circle.

Hero header: left 420.64x98 with two chips (24 px high, radius 9999, `#F4F3F8`, 8 px dot/person icon, 12/16 600) "Commercial Fleet Standard", "Lead Tech: Marcus Vance"; H1 32/38 800; subtitle 14/20. Right 241.08x48: 48x48 print, 48x48 share, 129.08x48 "Audit Tag" (15 px audit icon).

Left column `1:6342` gap 24:
- Telemetry card `1:6343` 498x436, radius 32, no padding; label row `1:6344` 450x14 (pad 0/24 implied by 450 width in 498), "ORTHOGRAPHIC TELEMETRY" + "18 HD Optical Scans"; view row `1:6352` 450x52 (pills "Front 45°", "Profile", "Undercarriage", rotate 36x36); image `1:6364` 450x288 with 450x245.2 raster and a glass label `1:6366` 186.27x26.
- Inspector card `1:6370` 498x178, radius 32, pad 24, gap 16: 36 px icon circle, title 16/22, "Certification ID: #APX-4401" 13/18, shield 16x20; two tiles 221x70 (`#F4F3F899`) "Diagnostic Station: Bay 04 (Hydraulic)" / "Sensor Calibration: Class A Zeroed" (emerald value).

Right column `1:6394` gap 24:
- Compliance card `1:6395` 710x278, radius 32, pad 24, gap 24: eyebrow 11/14 "OVERALL COMPLIANCE"; heading 22/28 "104 of 110 Checks Completed"; 95% chip 139.23x44 (`#F4F3F8`); progress 662x14; counts row (104 Passed / 4 Minor Advisory / 2 Pending); four KPI tiles 159.5x94 (`#F4F3F8B2`): Target Model (Renault Megan 3 / dCi 110 Eco2), Odometer (45,000 KM / • Verified Cluster), VIN Reference (VF1KZ040647 / EU Matched), Inspection Bay (Bay 04 / Full Lift Spec).
- Matrix `1:6442` 710x320: header 16/22 + "Updated Real-Time" 11/14; 2x2 GRID `1:6448` with four 347 px cards (130–144 high, radius 32, pad 24): Powertrain & OBD ("Pass", "Rail Pressure: 1,600 bar", 32/32 Passed), Braking Assemblies ("Pass", "Front: 8.8mm • Rear: 9.1mm", 16/16 Passed), 12V & Auxiliary Loom ("Pass", "Alternator Peak 14.4V", "State of Health: 98%", 24/24 Passed), Tread & Alignment ("Advisory", "Advisory on Rear Right / Camber", "Tread Depth: 5.4mm Avg", 32/38 Checked).
- Crypto card `1:6521` 710x106, radius 32, pad 24, gap 16: 46 px icon, "Cryptographic Verification Lock" 16/22, "SHA-256: 4f98...d71a • Immutable record generated" 13/18, primary "Sign & Release Fleet Certificate" 276.94x48.

Footer: left seal + "Official Inspection Dossier • Reference #APX-88294-FL" 13/18; right three 11/14 600 claims: "ISO 9001:2015 Accredited", "Tamper-Proof Audit Vault", "© 2025 Apex Vehicle Diagnostic Systems".

Responsiveness: one fixed desktop composition only. 1240 px content on 1280 px viewport; no tablet/mobile rule. Header/Main/Footer overlap at y=0, so the header is fixed/sticky.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx count)

| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 30 | Secondary text/labels |
| `#FFFFFF` | 23 | Cards, text, pills |
| `#1A1B1F` | 21 | Primary ink |
| `#10B981` | 19 | Brand, progress, CTA, pass labels |
| `#3C4A42` | 17 | Body ink, nav |
| `#F4F3F8` | 17 | Chips, tiles, icon circles |
| `#F4F3F8B2` | 4 | KPI tiles |
| `#006C49` | 3 | Verified seal, status green |
| `#F4F3F899` | 2 | Inspector tiles |
| `#FFFFFFE5` | 2 | Glass labels |

### Typography

| Size / line-height / weight / tracking | Usage |
|---|---|
| 32/38, 800, -0.8 | H1 "Inspection Report" (`1:6326`) |
| 22/28, 700, -0.44 | "104 of 110 Checks Completed" (`1:6399`), "95%" (`1:6401`) |
| 16/22, 700, -0.16 | Card/matrix titles, values (`1:6378`, `1:6445`, `1:6457`, `1:6528`) |
| 16/20, 700, -0.16 | Header brand (`1:6559`) |
| 16/24, 400 | Active nav link (`1:6564`) |
| 14/20, 500, -0.07 | Subtitle (`1:6328`) |
| 14/18, 700, -0.14 | Nav inactive, "Audit Tag", CTA (`1:6340`, `1:6566`, `1:6535`) |
| 13/18, 400 | Secondary values, footer reference (`1:6380`, `1:6420`, `1:6542`) |
| 12/16, 600, +0.24 | Fleet/technician chips (`1:6319`, `1:6323`) |
| 11/14, 600, +0.55 | Eyebrows, "CERTIFIED INSPECTION DIVISION" (`1:6346`, `1:6398`, `1:6561`) |
| 11/14, 600, +0.44 | Matrix counts, pill labels, footer claims (`1:6408`, `1:6466`, `1:6545`) |
| 11/14, 600, +0.28 | Small chip text (nav helper) |
| **Liberation Mono** 16/22, 700, -0.8 | VIN (`1:6432`) |
| **Liberation Mono** 11/14, 700, +0.44 | Passed counts (`1:6466`, `1:6484`, `1:6502`, `1:6520`) |

### Radii, shadows/elevation, strokes, spacing

- Radii: `9999` x33; `32` x8 (all cards).
- Shadows: cards `8 @ 0,2` + `40 @ 0,14`; floating buttons `8 @ 0,2` + `40 @ 0,14`; CTA `25 @ 0,10`; image `60 @ 0,22`; header blur 48; footer cross-shadow `40 @ 0,-14`.
- Strokes: none (borderless cards).
- Spacing: 4, 6, 8, 12, 16, 20, 24, 30, 32, 80, 82; content gutter 20; column gap 32; card padding 24; matrix card padding 24.

## 4. Components

No `COMPONENT`/`INSTANCE` nodes (FRAME 175, TEXT 71, VECTOR 18, RECTANGLE 3).

| Pattern | Node(s) | HTML/CSS equivalent |
|---|---|---|
| App bar with tabs + avatar | `1:6550` | `header.report-header` (no tabs, no avatar) |
| Chip (status/tech) | `1:6317`, `1:6320` | `.badge` |
| KPI tile | `1:6414`–`1:6435` | `.card`/`.detail-grid` cells |
| Progress + pass-rate chip | `1:6400`–`1:6412` | none |
| 2x2 matrix cards | `1:6448` | none (category tables only) |
| Crypto/verification card | `1:6521` | report-details hash row |
| Icon button (print/share) | `1:6330`, `1:6333` | none |
| Primary pill CTA | `1:6531`, `1:6570` | `.button.primary` |

## 5. Assets

Manifest: 19 assets — 18 SVG icons, 1 raster, 0 composed.

| Asset | Node | Role | Size / bytes | Safe? |
|---|---|---|---|---|
| `Icon-1_6322.svg` | `1:6322` | Person (tech chip) | 5,094 B | Yes |
| `Icon-1_6332.svg` | `1:6332` | Printer | 1,480 B | Yes |
| `Icon-1_6335.svg` | `1:6335` | Share | 2,903 B | Sharing the token URL is a privacy risk; no control in current report |
| `Icon-1_6338.svg` | `1:6338` | Audit tag/seal | 853 B | "Audit" data is internal |
| **`image-1-5926056ac5.jpg`** | `1:6365` | Raster vehicle photo 512x279 | 21,359 B | **No** — generic/stock vehicle photo presented as the report's vehicle; licence and identity concerns |
| `Icon-1_6375.svg` | `1:6375` | Inspector/badge | 2,282 B | Yes |
| `Icon-1_6382.svg` | `1:6382` | Verified shield | 614 B | Claim concern |
| `Icon-1_6454..6577` | matrix/actions | OBD, brake, battery, tyre, crypto, download, account | 439–2,300 B | Mostly yes; certification/verification semantics flagged |
| `Icon-1_6540.svg` | `1:6540` | Footer seal | 895 B | Claim concern |

No avatar image (account is a solid `#006C49` circle with glyph).

## 6. Content and data

| Visible text / label | Sample value | Real data field? | Notes |
|---|---|---|---|
| "Commercial Fleet Standard" | chip | no | Scope/service type claim; `inspection.scope` exists |
| "Lead Tech: Marcus Vance" | staff name | `technician.displayName` (Pending) | Full name; display name Pending approval |
| "Inspection Report" | title | static | Fine |
| "Verified Session • October 24, 2024 • 14:32 EST" | date | `inspection.dateTime` | Wrong timezone (should be GST); "Verified Session" claim |
| "ORTHOGRAPHIC TELEMETRY" / "18 HD Optical Scans" | media claim | no | Overstates method/asset count |
| "Front 45° / Profile / Undercarriage" | view tabs | no | New UI/state |
| "Exterior Chassis: Optimal" | aggregate | no | Condition judgement, not a field |
| "Inspector Dossier" / "Certification ID: #APX-4401" | inspector | no | Internal ID; staff certification claim |
| "Diagnostic Station: Bay 04 (Hydraulic)" | bay | no | Internal operational detail |
| "Sensor Calibration: Class A Zeroed" | claim | no | Invented calibration standard |
| "OVERALL COMPLIANCE" | heading | no | Compliance claim |
| "104 of 110 Checks Completed" | counts | `coverage.completed/applicable` | Matches model |
| "95%" / "Pass Rate" | percentage | derived | "Pass Rate" is a condition score by another name |
| "104 Passed / 4 Minor Advisory / 2 Pending" | counts | results/severity (partial) | "Passed"/"Pending" are not product result labels |
| "Target Model: Renault Megan 3 / dCi 110 Eco2" | model/trim | `vehicle.make/model`; trim Pending | Variant only if approved |
| "Odometer: 45,000 KM" | odometer | Pending field | Approval required |
| "VIN Reference: VF1KZ040647" / "EU Matched" | VIN | **no** (`vinMasked` only) | Full/partial VIN leak; "EU Matched" invented |
| "Inspection Bay: Bay 04 / Full Lift Spec" | bay | no | Internal |
| "Sub-System Verification Matrix" / "Updated Real-Time" | status | no | Live-state claim contradicts frozen snapshot |
| "Powertrain & OBD / ECU Zero Fault Codes / 32/32 Passed / Rail Pressure: 1,600 bar" | matrix | no | Invented measurements/results |
| "Braking Assemblies / Rotor Pad Depths > 8.2mm / 8.8mm / 9.1mm / 16/16" | matrix | no | Invented measurements |
| "12V & Auxiliary Loom / Alternator Peak 14.4V / State of Health: 98% / 24/24" | matrix | no | Invented |
| "Tread & Alignment / Advisory on Rear Right / Camber / 5.4mm Avg / 32/38 Checked" | matrix | no | Invented; conflicts with screen 2 (2.4 mm) |
| "Cryptographic Verification Lock / SHA-256: 4f98...d71a" | hash | `verificationHash` | Optional; conflicts with screens 4/7 hashes |
| "Sign & Release Fleet Certificate" | CTA | no | Write action + certificate claim |
| "Official Inspection Dossier • Reference #APX-88294-FL" | reference | `reportNumber` (format differs) | "Official" claim |
| "ISO 9001:2015 Accredited" | claim | no | Accreditation claim |
| "Tamper-Proof Audit Vault" | claim | no | Infrastructure claim |
| "© 2025 Apex Vehicle Diagnostic Systems" | brand | workshop name | Year 2025 despite 2024 dates |

No customer name/phone/email. A VIN is exposed. No precise location/token.

## 7. States shown / not shown

Shown: active "Report Overview", Verified Session, Pass/Advisory, 95%, PDF available, signed-out/account icon.

Not shown: Arabic/RTL/mirrored two-column, no PDF, PDF disabled, no data/empty, missing vehicle image, long model/trim, error/offline, invalid/revoked link, loading, focus/hover/pressed, 200% zoom, dark mode, tablet breakpoint, screen-reader order.

## 8. Implied interactions

- Nav tabs switch views (Report Overview / Detailed Findings / Compliance & Scope) — requires routes/state and a customer portal.
- "Download PDF" downloads the report.
- Account avatar opens an account menu/login.
- Print invokes print; share invokes OS share (leaks token outside the page).
- "Audit Tag" opens audit detail (internal data).
- View pills (Front 45°/Profile/Undercarriage) switch the vehicle image.
- Rotate icon rotates the vehicle view.
- "Sign & Release Fleet Certificate" signs/releases/sends.
- Matrix/tiles may be static.

## 9. Correspondence to current product

| Figma element | Current implementation | Verdict |
|---|---|---|
| Header | `header.report-header` with TrueReport, neutral title, report number, version, language switch | No nav, no avatar, no PDF by default; current header is not an app bar |
| Summary | `.summary-grid` 3 cards: coverage text, key-findings count, inspection date/scope + "Coverage is not a condition score." | Figma replaces with pass-rate, progress, 4 KPIs |
| Vehicle | `.detail-grid`: make/model/year, masked VIN, odometer, workshop, technician, template | Figma uses trim, full VIN, bay; omits workshop |
| Findings | key findings `.item` + category tables | Figma uses matrix cards with invented metrics |
| Verification | Report details hash row | Figma elevates to crypto card with "Sign & Release" |
| Footer | report number · version · workshop | Figma uses reference + accreditation claims |
| Layout | max width 960 px, single column, responsive `auto-fit` | Figma 1240 px, 2-column grid, fixed desktop |
| Tokens | teal/Noto/radius 16/light+dark | emerald/Plus Jakarta/radius 32/light only |

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **VIN exposed.** `1:6432` "VF1KZ040647" under "VIN Reference". Rule: "No ... full VIN ... by default" (hard rule 4); "Full VIN, plate, registration, engine number" are **Never public** (3.2); Phase 6 says "VIN is masked to the last four characters". This leaks a real VIN prefix and is a privacy defect.
2. **PDF control.** `1:6570` "Download PDF" in the app bar. ADR-0008 / section 10: "No download control in V1"; current header only renders it when `r.pdfDownloadEnabled` is true. The design shows no gating.
3. **Pass rate / condition score.** "95%", "Pass Rate" (`1:6401`, `1:6402`), "104 Passed" (`1:6408`), "OVERALL COMPLIANCE" (`1:6398`). Rule: "Coverage, not a single condition score" (12); "No single unexplained score" (2.2); "Do not show a headline '8.8/10' or similar score" (12); `NO_ISSUE_OBSERVED` must never be labelled "Pass" (10-design-system 3.3).
4. **"Exterior Chassis: Optimal".** `1:6369`. Aggregate condition judgement; "No false reassurance"; cannot be derived from item codes.
5. **Certification claims.** "Certification ID: #APX-4401" (`1:6380`), "Class A Zeroed" (`1:6393`), "Verified Session" (`1:6328`), "Verified Cluster" (`1:6427`), "Sign & Release Fleet Certificate" (`1:6535`), "ISO 9001:2015 Accredited" (`1:6545`), "Official Inspection Dossier" (`1:6542`). Rules: no "certified"/"official" unless factually and legally true; no certification claims; `docs/phase-8/00-decisions.md`: "Legal claim: **None**."
6. **Live state.** "Updated Real-Time" (`1:6447`) and "Sign & Release" imply mutable/ongoing state. Rule: "Finalized findings/evidence/reports immutable"; the page "renders only from the frozen report snapshot" (hard rule 1).
7. **Write actions.** "Sign & Release Fleet Certificate" (`1:6531`). No write logic in the public report; no manager/review role; no certification workflow.
8. **Portal cues.** Three nav tabs, account avatar, audit tag, print/share. Rule: "No admin code, no customer login, no other-report browsing" (hard rule 8); "not a customer portal" (section 1). Sharing also exposes the token URL.
9. **Internal identifiers/details.** Certification ID, bay, hydraulic lift spec, sensor calibration, "Audit Tag". Rule: "Customer ID, vehicle ID, job ID, internal database IDs" never public (3.2); "Internal notes, audit events ... never public."
10. **Invented measurements/results.** Rail pressure, pad depths, alternator, state of health, tread average, "18 HD Optical Scans", "32/32". Rule: "Never invent versions/licences/measurements/results" (task) and the snapshot schema has no such fields.
11. **Vehicle photo.** `1:6365` stock 512x279 vehicle image (Renault Megane). Rule: only evidence derivatives or a generic brand preview image; "If a preview image is used, it must be a generic brand image, never vehicle evidence" (6). A stock car under "Target Model" misrepresents the inspected vehicle; licence unverified.
12. **Technician PII.** "Lead Tech: Marcus Vance" (`1:6323`). Allowlist: "Technician display name — **Pending**"; "Staff personal contact details" never public. Full personal name needs approval.
13. **Timezone.** "14:32 EST" (`1:6328`). Rule: GST/UTC+4.
14. **Dark mode.** Screen is light-only; the current implementation supports `prefers-color-scheme` and Phase 8 tested it. Not a hard conflict, but a regression.
15. **Contrast.** Emerald `#10B981` text on `#FFFFFF/#F4F3F8` (≈2.5:1) for "Pass" and 95%; fails WCAG AA for normal text and is used as the sole success signal besides the word.
16. **Token existence.** None shown; the hash is a snapshot hash, not the token. No conflict.

## 11. Open questions / could not verify

- Is this screen actually the **workshop-admin** report viewer rather than the public report? Nav, avatar, audit tag, "Sign & Release" and "Approve & Finalize" (screen 6) all suggest an authenticated surface.
- Which user is "Marcus Vance" and has the technician display name been approved? Is the full legal name required?
- Is there an approved accreditation (ISO 9001/17020) and a certification body? If not, the footer and CTA must be removed.
- Is the VIN partially masked to last 4 anywhere in this design? It is not.
- Should variant "dCi 110 Eco2" be public? Allowlist says variant only if approved.
- Which measurements are real snapshot values vs. placeholder? None exist in `ReportSnapshot`.
- Why are the same title/copy shown on 3 tabs if only one report version exists? Is there a "Compliance & Scope" route?
- Should print/share exist at all for a token URL (share = token leakage)?
- Which hash is canonical (see screens 4/7)?
- Is the vehicle image licensed and approved as a generic brand image?
