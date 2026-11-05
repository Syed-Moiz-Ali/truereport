# 7. Limitations & Disclaimer Footer (Desktop Web)

- App: Public Report
- Figma node: 1:6923
- Frame: 1280x1188 px (desktop)
- Export folder: `screens/07_7._Limitations_&_Disclaimer_Footer_(Desktop_Web)`
- Sources read: `7._Limitations_&_Disclaimer_Footer_(Desktop_Web).json`, `7._Limitations_&_Disclaimer_Footer_(Desktop_Web)@2x.png`, `assets/manifest.json`
- Confidence: high for layout/tokens; high for conflicts (certification, consent-status and PDF copy are explicit).

## 1. Purpose

Desktop "Compliance & Scope" tab / closing section: a "Checks Not Completed" header with an excluded/completed toggle, three exemption cards (underbody, road test, emissions dyno) with protocol IDs and status flags, a legal/compliance statement box, a language-switch link and hash, a "Download Official Certificate PDF" CTA, and the site footer with accreditation claims.

## 2. Layout structure

Root `1:6923` VERTICAL, 1280x1188. Siblings: Main `1:6924` 1280x1106 (pad 80/0/**179.75**/0), Footer `1:7030` 1280x82, Header `1:7044` 1280x80 (overlay at y=0).

| Order | Node | Geometry | Notes |
|---|---|---|---|
| 1 | Main `1:6924` | 1280x1106 | VERTICAL, pad 80/0/179.75/0 |
| 1.1 | Section `1:6925` | 1280x844.25 | VERTICAL, pad 32/20/32/20 |
| 1.1.1 | Container `1:6926` | 1240x780.25 | VERTICAL, gap 32 |
| 1.1.1.1 | Section header `1:6927` | 1240x86 | HORIZONTAL, gap 497.11; left 511.59, right toggle 231.3x32 |
| 1.1.1.2 | Exemption grid `1:6943` | 1240x300 | HORIZONTAL, gap 24; three cards 397.33x300 |
| 1.1.1.3 | Legal box `1:7004` | 1240x176.25 | VERTICAL, radius 32, pad 32, fill `#F4F3F8` |
| 1.1.1.4 | Metadata `1:7011` | 1240x122 | VERTICAL, pad 16/0/0/0, gap 24 |
| 2 | Footer `1:7030` | 1280x82 | pad 32/0/32/0, top shadow |
| 3 | Header `1:7044` | 1280x80 | translucent, blur 48, overlays Main |

Section header: eyebrow row 16 px high (16.5x14.25 warning triangle `#B91A24` + "SECTION 04 • PROTOCOL EXEMPTIONS" 12/16 600 +0.6); H2 32/38 800; deck 16/24 500. Toggle 231.3x32 (`#F4F3F8`, 4 px padding): active white "3 Excluded" 97.91x24 with shadow, inactive "97 Completed" 117.39x24.

Exemption card (`1:6944`, `1:6964`, `1:6984`): 397.33x300, radius 32, pad 32, gap 22.5. Top row 40 px: tag 113.42x22 (`#F4F3F8`, 11/14 600 +0.28 "Exemption Tag"/"Bypass Reason") and 40 px icon circle. Middle: "PROTOCOL ID: EXP-0n" 11/14 600 +1.1, title 22/28 700, body 14/22.75 500 (two lines). Footer 31 px with 11/14 600 status + trailing 12x15 icon.

Legal box: 36 px white circle + shield-check; text 768 wide, 14/22.75 500, centered, 3 lines.

Metadata: row 627.35x18, gap 32: "Switch Language to Arabic (عربي)" link 235.08x18 (15 globe + 14/18 700 `#10B981`), 4x4 divider `#C7C5D3`, "Cryptographically Verified Snapshot (SHA-256: 89c41f)" 324.27x15.75 (12x15.75 lock + 11/14 600 +0.28). Then CTA wrapper 384x64 (pad 8 top) with button 384x56, radius 9999, `#10B981`, 13.33x16.67 download icon + "Download Official Certificate PDF" 14/18 700.

Footer/header identical to screens 5/6 (reference, ISO 9001:2015, Tamper-Proof Audit Vault, © 2025; nav "Compliance & Scope" active).

Responsiveness: fixed 1280; three cards are a single horizontal row (397.33+397.33+397.33+48 gap = 1240); no wrap/collapse defined. Header overlays Main at y=0. Large deliberate whitespace below the CTA (Main bottom padding 179.75 + 82 footer).

## 3. Visual tokens observed

### Colours (exact hex, usage, approx count)

| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 20 | Body/tag/status text |
| `#FFFFFF` | 16 | Cards, active toggle, icons |
| `#10B981` | 9 | Check/globe/lock icons, language link, CTA |
| `#F4F3F8` | 9 | Tags, icon circles, toggle trough, legal box |
| `#1A1B1F` | 7 | Headings, active toggle |
| `#3C4A42` | 7 | Nav, footer text |
| `#006C49` | 2 | Footer seal, avatar |
| `#B91A24` | 2 | Warning triangle, lockout icon |
| `#C7C5D3` | 1 | Language/hash divider |
| `#FFFFFFE5` | 1 | Translucent header |

### Typography

| Size / line-height / weight / tracking | Usage |
|---|---|
| 32/38, 800, -0.8 | "Checks Not Completed" (`1:6935`) |
| 22/28, 700, -0.44 | Exemption card titles (`1:6956`, `1:6976`, `1:6996`) |
| 16/24, 500, -0.16 | Deck (`1:6937`), nav active (`1:7062`) |
| 14/22.75, 500, -0.07 | Card body (`1:6958`), legal box (`1:7010`) |
| 14/18, 700, -0.14 | Language link (`1:7017`), CTA (`1:7029`) |
| 12/16, 600, +0.6 | "SECTION 04 • PROTOCOL EXEMPTIONS" (`1:6933`) |
| 12/16, 600, +0.24 | Toggle labels (`1:6940`, `1:6942`) |
| 11/14, 600, +1.1 | "PROTOCOL ID: EXP-0n" (`1:6954`) |
| 11/14, 600, +0.28 | Tags (`1:6948`, `1:6988`), hash (`1:7023`) |
| 11/14, 600, +0.44 | Status labels, footer claims (`1:6961`, `1:6981`, `1:7001`, `1:7039`) |
| 13/18, 400 | Footer reference (`1:7036`) |

### Radii, shadows/elevation, strokes, spacing

- Radii: `9999` x18; `32` x4 (3 cards + legal box).
- Shadows: cards `8 @ 0,2` + `40 @ 0,14`; legal box `40 @ 0,14` (large downward); toggle active `8 @ 0,2`; CTA `25 @ 0,10`; footer up-shadow `40 @ 0,-14`.
- Strokes: none.
- Spacing: 4, 4.22, 7.25, 8, 16, 20, 22.5, 24, 32, 80, 179.75; card padding 32; grid gap 24; legal padding 32.

## 4. Components

No `COMPONENT`/`INSTANCE` nodes (FRAME 99, TEXT 34, VECTOR 15, RECTANGLE 1).

| Pattern | Node(s) | HTML/CSS equivalent |
|---|---|---|
| Exemption/limitation card | `1:6944` | `.card` (current limitation list is one card with `<ul>`) |
| Segmented toggle | `1:6938` | none |
| Tag/pill | `1:6947` | `.badge` |
| Legal statement box | `1:7004` | `.disclaimer` (current is amber warning, not lavender) |
| Language link | `1:7013` | `.language-switch` link |
| PDF CTA | `1:7025` | gated header button, not a body CTA |
| App bar/footer | `1:7044`, `1:7030` | header/footer (different content) |

## 5. Assets

Manifest: 15 assets — 15 SVG icons, 0 raster, 0 composed.

| Asset | Node | Role | Bytes | Notes |
|---|---|---|---|---|
| `Icon-1_6931.svg` | `1:6931` | Warning triangle (`#B91A24`) | 611 | Yes |
| `Icon-1_6951.svg` | `1:6951` | Truck/lift | 1,755 | Yes |
| `Icon-1_6971.svg` | `1:6971` | Road/test track | 1,738 | Yes |
| `Icon-1_6983.svg` | `1:6983` | Check | 1,688 | Yes |
| `Icon-1_6991.svg` | `1:6991` | Lightning/EV | 404 | Yes |
| `Icon-1_7003.svg` | `1:7003` | Leaf/EV | 1,518 | Yes |
| `Icon-1_7008.svg` | `1:7008` | Shield-check | 1,775 | Verification claim semantics |
| `Icon-1_7015.svg` | `1:7015` | Globe | 3,073 | Yes |
| `Icon-1_7021.svg` | `1:7021` | Padlock | 1,331 | Crypto claim semantics |
| `Icon-1_7027.svg` | `1:7027` | Download | 749 | PDF control |
| `Icon-1_7034.svg` | `1:7034` | Seal | 895 | Certification concern |
| `Icon-1_7050.svg` | `1:7050` | Seal (white) | 2,242 | Certification concern |
| `Icon-1_7066.svg` | `1:7066` | Download | 439 | PDF control |
| `Icon-1_7071.svg` | `1:7071` | Account glyph | 1,494 | Portal cue |

No photos, avatars or vehicle images. No composed SVGs.

## 6. Content and data

| Visible text / label | Sample value | Real data field? | Notes |
|---|---|---|---|
| "SECTION 04 • PROTOCOL EXEMPTIONS" | section | no | "Section 04" implies other sections not in export |
| "Checks Not Completed" | heading | `labels.notChecked` | Matches current section |
| "Items excluded due to safety protocol or customer scope exemption" | deck | no | New copy |
| "3 Excluded / 97 Completed" | counts | `coverage.notChecked` + completed | 3+97=100; disagrees with 110 (screen 5) and 48 (screen 6) |
| "Exemption Tag" / "Bypass Reason" | tag | no | Internal process vocabulary |
| "PROTOCOL ID: EXP-01 / EXP-02 / EXP-03" | IDs | no | Internal IDs |
| "Underbody Subframe / Unsafe to lift due to non-standard vehicle cargo payload during intake. / Safety Lockout Active" | reason + status | `NotChecked.reason` (allowed) | Status is internal operational state |
| "High-Speed Road Test / Customer declined optional dynamic test track evaluation. / Customer Waiver Signed" | reason + consent status | `reason` allowed; **consent status not allowed** | Reveals customer decision/waiver |
| "Emissions Dyno Run / Electric vehicle powertrain; tailpipe analysis not applicable. / EV Architecture Flag" | reason + flag | `reason`; flag internal | EV data inconsistent with other screens |
| "This technical report reflects vehicle diagnostic observations recorded at the certified bay timestamp above. Conforms to ISO/IEC 17020 and fleet compliance directives. The inspecting facility assumes responsibility solely for verified checkpoints." | legal | `disclaimer` (current text differs) | ISO claim, "certified", liability acceptance, "above" has no timestamp |
| "Switch Language to Arabic (عربي)" | language link | `?lang=ar` | Arabic parentheses/bidi needs isolates; "عربي" informal |
| "Cryptographically Verified Snapshot (SHA-256: 89c41f)" | hash | `verificationHash` optional | 6 hex chars; claim |
| "Download Official Certificate PDF" | CTA | `pdfDownloadEnabled` (off) | "Official Certificate" + PDF |
| "Official Inspection Dossier • Reference #APX-88294-FL" | footer | `reportNumber` (format differs) | "Official" |
| "ISO 9001:2015 Accredited" | footer claim | no | Accreditation claim |
| "Tamper-Proof Audit Vault" | footer claim | no | Infrastructure claim |
| "© 2025 Apex Vehicle Diagnostic Systems" | copyright | workshop | Year mismatch (2024 dates) |

No customer name/phone/email, no VIN/plate, no coordinates on this screen.

## 7. States shown / not shown

Shown: active "Compliance & Scope", "3 Excluded" selected, three exemptions with statuses, PDF enabled, English.

Not shown: "97 Completed" selected content, zero exemptions (no limitations), one exemption, many exemptions/overflow, Arabic/RTL mixed-language line, no PDF, invalid/revoked link, missing hash, error/offline, focus/hover/pressed, 200% zoom, dark mode, narrower desktop, print.

## 8. Implied interactions

- Toggle switches between excluded and completed lists.
- "Switch Language to Arabic (عربي)" reloads in Arabic (should be a server link).
- "Download Official Certificate PDF" downloads/streams a certificate.
- Nav tabs, account avatar, header "Download PDF" (same as screens 5/6).
- Cards may expand for reasons (no state).

## 9. Correspondence to current product

| Figma element | Current implementation | Verdict |
|---|---|---|
| Checks not completed | `section#not-checked-title` + table (check/result/reason) | Figma uses 3 cards with protocol IDs/status |
| Limitations | `.card` with `<ul>` of 4 approved limitations + `.disclaimer` | Figma replaces the list with exemptions and one legal box |
| Disclaimer | current text: visual/non-invasive, not a warranty/official certificate | Figma uses ISO conformity and liability wording |
| Language switch | header link (`العربية`/`English`) | Figma adds a second link in the body |
| Hash | report-details row | Figma puts a truncated hash next to the language link |
| PDF | header-only, gated, default off | Figma adds a body CTA "Download Official Certificate PDF" |
| Footer | report number · version · workshop | Figma adds reference + ISO/tamper-proof claims + © 2025 |
| Report ID/version/finalized | header + report-details | Missing from this desktop block except the footer reference |

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"Download Official Certificate PDF".** `1:7025`. Rule: "PDF download from the public page is disabled by default. No download control in V1" (ADR-0008); section 10: "Disabled by default ... no download button in V1 unless PDF1/RQ7 is approved." Also "official certificate" is a forbidden certification claim: "Do not use 'certified'... unless factually and legally true" (12); "not an official ... certificate" (section 1). **Highest conflict on this screen.**
2. **ISO/IEC 17020 conformity.** `1:7010`. Rule: no certification claims; `docs/phase-8/00-decisions.md`: "Legal claim: **None**. This is not a compliance certification." The statement also says "certified bay timestamp above", but no timestamp is above this text in the frame.
3. **Accreditation/infrastructure claims.** "ISO 9001:2015 Accredited" (`1:7039`), "Tamper-Proof Audit Vault" (`1:7041`), "Official Inspection Dossier" (`1:7036`). Same rules; no evidence in the repo.
4. **Consent/waiver data.** "Customer Waiver Signed" (`1:6981`) and "Customer declined ..." (`1:6978`). Rule: "Consent records, consent wording, capture channel/actor" are **Never public** (3.2). The reason text (free text) is allowed, but a "waiver signed" status is a consent record. "Customer scope exemption" also reveals customer decisions.
5. **Internal process identifiers.** "PROTOCOL ID: EXP-01/02/03", "Exemption Tag", "Bypass Reason", "Safety Lockout Active", "EV Architecture Flag". Rule: internal IDs/audit data not public (3.2); "Internal notes, audit events ... never public."
6. **Verified/cryptographic claims.** "Cryptographically Verified Snapshot (SHA-256: 89c41f)" (`1:7023`), shield/lock icons. Allowlist permits hash "optional", but not a verification guarantee; "tamper-evident" is an infrastructure claim.
7. **Hash inconsistency.** Only 6 hex chars here vs 8 in screens 4/5 and a different value; one immutable version cannot have three hashes.
8. **Counts inconsistent.** "3 Excluded / 97 Completed" sums to 100; screen 5 says 104 of 110; screen 6 says 48 diagnostics. Rule: report renders only from one frozen snapshot; counts must reconcile. Also "Completed" is not the same as "not checked/could not verify".
9. **Reason completeness.** The allowlist requires "Reason required for not checked/could not verify" (2.2). Two of three cards give a reason and one says "not applicable" (which is a different result code). The card label "Bypass Reason" mixes result codes (`NOT_APPLICABLE` vs `NOT_CHECKED`).
10. **Liability statement.** "The inspecting facility assumes responsibility solely for verified checkpoints" is a legal commitment not in the approved disclaimer. The public report must state it is not a warranty/official certificate, not accept liability.
11. **Arabic inline text.** "Switch Language to Arabic (عربي)" mixes RTL in a LTR sentence. Rule: isolated LTR/RTL runs, parentheses on the correct side, Arabic font/shaping (`03-localization-and-rtl-rules.md` 5/8). The export specifies no Arabic font for this run.
12. **PDF without consent gate.** Even if PDF1 were approved, ADR-0008 requires the same active link and consent policy; the design shows no disabled/consent state.
13. **Footer identity/version.** Current page requires report ID, version, finalized date and workshop in the footer. Figma footer has a reference string, claims and © only.
14. **Dark mode / contrast.** Light-only; `#10B981` link on white (≈2.5:1) fails AA for 14 px text.

## 11. Open questions / could not verify

- Is "Download Official Certificate PDF" approved, and is the workshop actually issuing a certificate? If not, both the noun and the control must be removed.
- Does the business hold ISO/IEC 17020 and ISO 9001:2015 accreditation? Which body/scope/certificate number?
- Is "Customer Waiver Signed" allowed to be shown, or only the reason text?
- Should "Checks Not Completed" be grouped by result code (`NOT_CHECKED`, `COULD_NOT_VERIFY`, `NOT_APPLICABLE`) rather than "excluded/completed"?
- Which counts are canonical: 97/100, 104/110 or 48 diagnostics?
- Which hash is canonical (4/5/7)?
- Is "SECTION 04" a real page-section numbering scheme, and are sections 01–03 exported elsewhere?
- Why is "EV Architecture Flag" present when other screens describe an ICE Renault/Porsche? Is this placeholder data?
- Is the legal/liability sentence approved by counsel? Phase 8 says no legal review was performed.
- Should the language link exist twice (header and body) and should it be "العربية" per the current product?
