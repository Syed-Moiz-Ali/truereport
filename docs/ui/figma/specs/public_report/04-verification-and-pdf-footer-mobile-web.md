# 4. Verification & PDF Footer (Mobile Web)

- App: Public Report
- Figma node: 1:6255
- Frame: 390x901.69 px (mobile)
- Export folder: `screens/04_4._Verification_&_PDF_Footer_(Mobile_Web)`
- Sources read: `4._Verification_&_PDF_Footer_(Mobile_Web).json`, `4._Verification_&_PDF_Footer_(Mobile_Web)@2x.png`, `assets/manifest.json`
- Confidence: high for layout/tokens; high for conflicts (the copy is explicit).

## 1. Purpose

Mobile end-of-report block: a compliance/verification paragraph, a "Verified Snapshot" card with a truncated SHA-256 and "TAMPER-EVIDENT LEDGER" label, an English/عربي segmented language switch, and a large "Download PDF Report" button. The frame is mostly empty below the button.

## 2. Layout structure

Root `1:6255` VERTICAL, width FIXED 390, height 901.69, **bottom padding 373.5** (deliberate empty space), fill `#FFFFFF`.

| Order | Node | Geometry | Auto Layout / notes |
|---|---|---|---|
| 1 | Header `1:6256` | 390x64 | VERTICAL; inner `1:6257` HORIZONTAL pad 16/20/16/20, gap 91.87; brand + Verified |
| 2 | Main `1:6269` | 390x464.19 | VERTICAL, padding 0/20/0/20 |
| 2.1 | Inner `1:6270` | 350x464.19 | VERTICAL, padding 0/0/32/0 |
| 2.1.1 | Compliance text `1:6271` | 350x140.19 | VERTICAL, padding 23.19/8/32/8; text 334x85 centered |
| 2.1.2 | Snapshot margin `1:6274` | 350x160 | VERTICAL, pad 0/0/24/0; card 350x136 HORIZONTAL, radius 32, pad 24, gap 16 |
| 2.1.3 | Language margin `1:6294` | 350x76 | VERTICAL, pad 0/0/32/0; segmented control 350x44 |
| 2.1.4 | PDF button `1:6305` | 350x56 | HORIZONTAL, radius 9999, `#10B981`, shadow |

The snapshot card contains a 48x48 circle (`1:6277`, fill `#10B9811A`) with a 16x21 lock icon, a 238 px text column (title 16/22, hash line 13/18, ledger row 11/14 + 8x8 dot) and a 12x15 shield-check icon at the right.

The language switch is a nested segmented control: 350 px outer 44 px row, inner 168.67x44 `#F4F3F8` pill with 4 px padding, active white 80.33x36 (English, 12/16 700) and inactive 91.09x36 ("عربي", 12/16 700, **FreeSerif**).

No scroll container. There is no footer, report ID, version, finalized date or workshop identity in this frame. The bottom 373.5 px is empty.

## 3. Visual tokens observed

### Colours (exact hex, usage, approx count)

| Hex | Count | Usage |
|---|---|---|
| `#FFFFFF` | 7 | Card, active segment, button text |
| `#10B981` | 4 | Lock, dot, shield check, CTA |
| `#1A1B1F` | 3 | Title, English segment |
| `#5E5D69` | 3 | Body, inactive Arabic |
| `#FFFFFF01` | 3 | Shadow carriers |
| `#006C49` | 2 | Verified text, brand sub-label |
| `#3C4A42` | 2 | Ledger label, brand sub-label |
| `#10B9811A` | 1 | Lock circle (10% emerald) |
| `#10B98133` | 1 | Header badge |
| `#6FFBBE4D` | 1 | Verified pill |
| `#F4F3F8` | 1 | Language switch trough |

### Typography

| Node | Size / line-height / weight / tracking | Alignment | Usage |
|---|---|---|---|
| `1:6273` | 13/21.13, 400, auto | CENTER | ISO compliance paragraph |
| `1:6283` | 16/22, 800, -0.4 px | LEFT | "Verified Snapshot" |
| `1:6288` | 13/18, 400 | LEFT | "SHA-256: 9b2d...f4e1 • Bay #04 Certified" |
| `1:6293` | 11/14, 600, +0.55 px | LEFT | "TAMPER-EVIDENT LEDGER" |
| `1:6301` | 12/16, 700, +0.24 px | CENTER | "English" (active) |
| `1:6304` | 12/16, 700, +0.24 px, **FreeSerif** | CENTER | "عربي" |
| `1:6310` | 14/18, 700, -0.14 px | CENTER | "Download PDF Report" |

### Radii, shadows/elevation, strokes, spacing

- Radii: `9999` x11; `32` x2 (snapshot card, shadow carrier).
- Shadows: snapshot card `10 @ 0,8` + `25 @ 0,20`; segmented control `INNER_SHADOW 4 @ 0,2`; active segment `4 @ 0,2` + `6 @ 0,4`; CTA `10 @ 0,8` + `25 @ 0,20`.
- Strokes: none.
- Spacing: 2, 4, 8, 10, 12, 16, 20, 23.19, 24, 32; gutter 20.

## 4. Components

No `COMPONENT`/`INSTANCE` nodes (FRAME 38, TEXT 10, VECTOR 4, RECTANGLE 4).

| Pattern | Node(s) | HTML/CSS equivalent |
|---|---|---|
| Verification card | `1:6275` | none; current report has report-details `<p>` rows incl. hash |
| Segmented language switch | `1:6296` | `.language-switch` + `.button` (current is a single link, not a segmented control) |
| Full-width PDF CTA | `1:6305` | `.button.primary` gated by `r.pdfDownloadEnabled` in header, not a full-width body CTA |
| Compliance paragraph | `1:6273` | `.disclaimer` / limitations copy (different wording) |

## 5. Assets

Manifest: 4 assets — 4 SVG icons, 0 raster, 0 composed.

| Asset | Node | Role | Bytes | Notes |
|---|---|---|---|---|
| `Icon-1_6261.svg` | `1:6261` | Verified seal | 895 | Certification concern |
| `Icon-1_6279.svg` | `1:6279` | Padlock | 1,012 | Implies cryptographic assurance |
| `Icon-1_6285.svg` | `1:6285` | Shield + check | 435 | "Verified" claim |
| `Icon-1_6308.svg` | `1:6308` | Download arrow | 583 | PDF control |

No photos, avatars or vehicle images.

## 6. Content and data

| Visible text / label | Sample value | Real data field? | Notes |
|---|---|---|---|
| "This technical report reflects vehicle diagnostic observations recorded at the certified bay timestamp above. Conforms to ISO/IEC 17020 and fleet compliance directives." | compliance claim | no | Certification/accreditation claim; "above" is false on this screen (no timestamp above) |
| "Verified Snapshot" | card title | no | Claim; the hash alone does not verify |
| "SHA-256: 9b2d...f4e1" | truncated hash | `verificationHash` (optional) | Truncation is allowed if it cannot enable token guessing; 8 hex chars shown |
| "Bay #04 Certified" | bay | no | Facility/bay certification claim |
| "TAMPER-EVIDENT LEDGER" | label | no | Infrastructure claim |
| "English" / "عربي" | language switch | `?lang=en` / `ar` exists | "عربي" is informal; the current label is "العربية" |
| "Download PDF Report" | CTA | `pdfDownloadEnabled` (off by default) | No consent gate shown |

No customer name/phone/email, no VIN/plate, no precise location, no token.

## 7. States shown / not shown

Shown: default English, active segment, PDF enabled.

Not shown: Arabic selected/RTL, PDF disabled/absent, PDF generating, no PDF artifact, consent-missing, invalid/revoked link, download error, rate-limited, focus/hover/pressed, screen-reader order, mobile print, dark mode, no-JS.

## 8. Implied interactions

- Language switch reloads the page with `?lang=ar` (current pattern) or client-side toggle → must be a server link, no JS.
- "Download PDF Report" downloads or streams a PDF (needs consent/short-lived authorization).
- Verified snapshot card may be tappable for details (no state).
- No print/share control on this mobile screen.

## 9. Correspondence to current product

| Figma element | Current implementation | Verdict |
|---|---|---|
| Language switch | `.language-switch` with one `<a class="button">` to the other language; label from `r.labels.arabic` | Figma converts to a two-segment control and uses a different Arabic label. |
| Hash | `Report details` card: "Report integrity hash" + full `verificationHash` (`.hash`, monospace, break-all) | Figma truncates and elevates it to a verification card. |
| Compliance text | `.disclaimer` (visual, non-invasive; not a warranty/official certificate) + limitations list | Figma replaces the careful disclaimer with an ISO conformity claim. |
| PDF | header button only when `r.pdfDownloadEnabled`; both server and ADR default off | Figma always shows a large PDF CTA. |
| Report identity | header shows report number + version; details section shows finalized/published | Figma shows none of these on this block. |
| Styling | teal, Noto fonts, light/dark, plain cards | emerald, Plus Jakarta Sans (FreeSerif for Arabic), light only, large shadows. |

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **ISO/IEC 17020 claim.** `1:6273`. Rule: "Do not use 'certified', 'independently reviewed', 'manager approved' or 'RTA approved' unless factually and legally true" (`06-public-report-design.md` 12). There is no accreditation record in the repo; Phase 8 states "Legal claim: **None**. This is not a compliance certification" (`docs/phase-8/00-decisions.md`). **Highest-severity conflict.**
2. **"Bay #04 Certified".** `1:6288`. Same certification rule; no bay certification model exists.
3. **PDF download control.** `1:6305`. Rule: "Disabled by default. The public page has no download button in V1 unless PDF1/RQ7 is approved" (`06-public-report-design.md` 10); ADR-0008: "PDF download from the public page is disabled by default. No download control in V1." The screen shows an unconditional CTA and no consent/authorization state.
4. **"Verified Snapshot" / "TAMPER-EVIDENT LEDGER" / shield-check.** `1:6283`, `1:6293`, `1:6285`. The allowlist permits "Report hash/verification detail — Optional; must not enable token guessing", but not a verification guarantee. "Tamper-evident" is an infrastructure claim not proven to the reader; "verified" is a certification-adjacent claim.
5. **"certified bay timestamp above".** The page has no timestamp above this text on the frame; the sentence is factually incoherent here. Rule: "must not invent ... results"; must not misstate the record.
6. **Arabic font.** `1:6304` uses **FreeSerif** for "عربي", not a bundled Arabic font. Rule: "Use a proper Arabic font with joining/shaping; never render Arabic with a Latin-only font" (`03-localization-and-rtl-rules.md` 8.1); "Do not letter-space Arabic" (the segment carries +0.24 px tracking). Current product uses Noto Naskh Arabic.
7. **Language switch as a control.** Segmented control implies client state; the public page must work without JS and the language switch must be a link. The current implementation is already a link.
8. **Dead space / missing identity.** Bottom 373.5 px empty and no report ID/version/finalized date/workshop. Rule: header and footer "Consistent with PDF" and "Report ID, version, finalized date, workshop" (`06-public-report-design.md` 2.2). Not a privacy conflict, but a contract gap.
9. **Hash inconsistency.** This screen shows `9b2d...f4e1`; screen 5 shows `4f98...d71a`; screen 7 shows `89c41f`. Only one hash can belong to one immutable version. Rule: "Finalized ... reports immutable"; conflicting hashes on the same report undermine the integrity claim.
10. **Chevron/PDF icon.** `1:6308` is a download arrow; fine semantically, but pairing it with "Report" implies a document that may not exist when PDF generation fails. Rule: "PDF failed: 200 page, no PDF — Report page without download" (state table).
11. **Conformance wording.** "fleet compliance directives" is unspecified; no such legal directive is defined in the docs.
12. **PII.** None visible. No token in the hash preview. No customer/vehicle data.

## 11. Open questions / could not verify

- Is the product actually ISO/IEC 17020 accredited or ISO 9001:2015 certified? If not, all such wording must be removed, not restyled.
- Has PDF1/RQ7 been approved since ADR-0008? If yes, where is the consent record and per-report flag shown?
- Should the public page show the hash at all, and in what format (full, truncated, with verification instructions)?
- Should the language switch be "العربية" (current) or "عربي" (Figma)?
- Is there a footer/identity block missing from this mobile frame, or is the 373.5 px gap intentional for a sticky CTA?
- Where is the "certified bay timestamp above"? The preceding screen has the date, not this one.
- Which hash is canonical: `9b2d...f4e1`, `4f98...d71a` or `89c41f`?
- Does the Arabic layout have a designed mirrored version of this screen? None was exported.
- Are the download icon and button reachable after revocation? No state is exported.
