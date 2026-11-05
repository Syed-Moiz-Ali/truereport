# 05. Consent & Signatures

- App: Technician
- Figma node: 1:7531
- Frame: 390x972 px (mobile phone; 390 pt logical width)
- Export folder: `screens/05_5._Consent_&_Signatures`
- Sources read: `5._Consent_&_Signatures.json`, `5._Consent_&_Signatures@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html`
- Confidence: medium — layout and text are readable, but the consent semantics, signature provenance and flow position are ambiguous; the PNG also shows clipped text.

## 1. Purpose

A consent/authorisation screen with three switches, a customer signature pad labelled "required", an inspector/customer context card, and a primary "Save Consent" action. It is presented as "STEP 4 OF 4 • FINAL SIGN-OFF".

## 2. Layout structure

- Root `1:7531`: VERTICAL, FIXED width / HUG height, 390x972, `#FFFFFF`.
- `1:7532` `Main`: VERTICAL, padding `0/64/0/0`; `1:7533` content 390x908, VERTICAL, bottom padding 32.
- Visual order:
  - `1:7534` header block 390x144 at y0, padding `20/12/20/24`, gap 4: step label 350x28; `Authorizations` 350x32; description 350x40.
  - `1:7546` list 390x732 at y144, padding `20/0/20/0`, gap 16:
    - `1:7547` PDF sharing card 350x80, radius 32, padding 20.
    - `1:7559` road-test consent card 350x80.
    - `1:7571` data-storage card 350x80.
    - `1:7583` signature section margin 350x256 (inner fixed 350x240): heading row 350x18, hint; 350x176 signature pad; timestamp/clear row 350x34.
    - `1:7614` inspector/customer context card 350x72, radius 32, padding 16.
    - `1:7626` CTA block 350x80: 350x56 pill button.
- Header `1:7632` 390x64 at y0, absolute, `#FFFFFFCC` + 48 px background blur; back 44x44, title, 32x32 profile circle.
- FILL width, fixed heights. No breakpoint/tablet variant, no scroll container. The fixed 972 px frame plus fixed signature card does not accommodate text scaling or keyboard.
- Three consent rows are 350x80 with a 52x32 switch pinned right; text blocks are 252.9/256.1/256.8 wide, and the PNG visibly clips the longer titles/subtitles at the switch edge.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

| Hex | Usage | Approx. count |
|---|---|---|
| `#1A1B1F` | headings, card titles, signature ink | 15 |
| `#FFFFFF` | cards, switch thumb, badge background | 12 |
| `#5E5D69` | descriptions, timestamp, hint | 10 |
| `#10B981` | active switches, "Required", check icon | 6 |
| `#F4F3F8` | icon tiles, signature-pad fill | 3 |
| `#10B98126` | signature "Recorded" icon tint | 2 |
| `#00422B` | avatar initials `AL` | 1 |
| `#006C49` | profile circle | 1 |
| `#10B9811A` | "Required" chip | 1 |
| `#BBCABF` | muted outline/divider | 1 |
| `#E3E1EF` | signature baseline | 1 |
| `#E9E7ED` | off switch track | 1 |
| `#F4F3F899` | signature pad fill | 1 |
| `#FFFFFFCC` / `#FFFFFFE5` | header / badge or sticky | 1 each |

`#10B981` text on white = 2.54:1 — the 11 px "Required" label on a pale green chip is below AA. The off switch track `#E9E7ED` on white is ~1.2:1, below the 3:1 non-text UI target.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)

| Text / node | Family / weight | Size / line-height | Tracking | Alignment | Usage |
|---|---|---|---|---|---|
| `STEP 4 OF 4 • FINAL SIGN-OFF` 1:7541 | Plus Jakarta Sans / 600 | 12 / 16 | +0.30 px, uppercase | left | Step label |
| `Authorizations` 1:7543 | Plus Jakarta Sans / 800 | 26 / 32 | -0.65 px | left | Title |
| Description 1:7545 | Plus Jakarta Sans / 500 | 14 / 20 | -0.07 px | left | Intro |
| `Allow PDF sharing` 1:7554 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Card title |
| `Send detailed diagnostic report via email` 1:7556 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Card detail |
| `Customer road test consent` 1:7566 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Card title |
| `Authorize certified technician dynamic evaluation` 1:7568 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Card detail |
| `Data storage authorization` 1:7578 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Card title |
| `Encrypt telemetry logs and secure fleet cloud backups` 1:7580 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Card detail |
| `Digital Signature` 1:7589 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | left | Section |
| `Required` 1:7591 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Constraint chip |
| `Sign with finger or stylus` 1:7593 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Hint |
| `Timestamp: Today, 14:38 EST` 1:7596 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Timestamp |
| `Clear` 1:7601 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | centre | Action |
| `Sign Above Line` 1:7605 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Pad hint |
| `Recorded` 1:7613 | Plus Jakarta Sans / 600 | 11 / 14 | -0.275 px | left | Badge |
| `Alex Lindqvist` 1:7621 | Plus Jakarta Sans / 700 | 16 / 22 | -0.16 px | left | Representative |
| `Authorized Representative • VIN 4782` 1:7623 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Context |
| `Save Consent` 1:7631 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | centre | CTA |

### Radii, shadows/elevation, strokes, spacing values

- Radii: 9999 ×16; 32 ×5 (three consent cards, signature pad, context card).
- Shadows: card `r=8 off=0,2` 1.6% + `r=40 off=0,14` 4.3%; CTA `r=25` emerald 30%; badge `r=2/8` with 8 px background blur; header 5% + 48 px blur.
- Signature pad fill `#F4F3F899`; 1 px baseline `#E3E1EF` at 60%; signature strokes `#1A1B1F` at 2.43 and 1.94 px.
- Spacing: 16 between cards; 20 card padding; signature block 16 top margin; 24/32 bottom spacing.
- Switch is 52x32 (32 px high) and "Clear" is 62.7x24; both are below the 44 px target. The 3 consent cards themselves are not tappable on the text area — only the 52x32 switch is.

## 4. Components

| Figma pattern / node | Instances | Map to our design system |
|---|---|---|
| Consent card + switch 1:7547 / 7559 / 7571 | 3 | no switch component in `components.dart`; Material `Switch` is used directly today. No `ConsentCard` component |
| Signature pad 1:7602 | 1 | **no equivalent**; no signature capture/storage component or endpoint |
| "Recorded" badge 1:7609 | 1 | `StatusChip` closest; but it is a verification watermark, not a sync/result status |
| Context card 1:7615 | 1 | `Card` + avatar/identity row; no equivalent |
| Primary CTA 1:7627 | 1 | `AppButton(primary, expand)`; current radius 12 vs Figma pill |
| Header 1:7632 | 1 | `AppBar` |

No component instances/variants; the "Switch" frames are manually drawn (not Material). The signature sample is a flattened composed SVG, so it cannot become a real drawing surface.

## 5. Assets

- Manifest count: **13** (10 individual SVGs, **2 vectors**, **1 composed**).
- Icons: PDF 1:7539, car/road-test 1:7551, data/storage 1:7563, lock/data 1:7575, clear/refresh 1:7599, check/badge 1:7611, representative/document 1:7625/1:7629, back 1:7637, profile 1:7642.
- Composed: `composed-1_7606` "Subtle Cursive Sample SVG Stroke (Interactive simulation)" 350x176, with two child vectors 1:7607 (233.3x46.1) and 1:7608 (77.8x3.4), stroke `#1A1B1F`.
- No raster/photo/avatar/vehicle image.
- The signature is explicitly named a **sample**; it is not a real customer signature and has no captured metadata (signer, device, hash, time source).

## 6. Content and data

| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| `STEP 4 OF 4 • FINAL SIGN-OFF` | step 4 of 4 | No | Conflicts with screen 04 "Step 1 of 4"; consent normally precedes inspection |
| `Authorizations` | title | No | Current label is `l10n.consent` ("Consent") |
| `Review compliance permissions and provide customer digital sign-off.` | intro | No | "Compliance" claim; no wording version |
| `Allow PDF sharing` / `Send detailed diagnostic report via email` | toggle ON | Partly | PDF download/email consent should be separate; no email channel/address shown |
| `Customer road test consent` / `Authorize certified technician dynamic evaluation` | toggle ON | No | "Certified technician" claim; road-test consent is not in the current consent model |
| `Data storage authorization` / `Encrypt telemetry logs and secure fleet cloud backups` | toggle OFF | No | Encryption/telemetry/cloud-backup claims; no telemetry feature |
| `Digital Signature` / `Required` / `Sign with finger or stylus` | signature present | No signature model | "Required" is not enforced anywhere in the screen |
| Signature stroke | cursive sample | No | A prefilled sample, not a captured signature |
| `Recorded` | badge | No | Falsely implies the sample was captured/verified |
| `Timestamp: Today, 14:38 EST` | time/timezone | No | `EST` is wrong for a UAE workshop; "Today" is invented |
| `Clear` | action | No | Clears the sample, not a real capture buffer |
| `Alex Lindqvist` / `Authorized Representative • VIN 4782` | signer | Partly (`customerName`) | Different customer from screen 04 (`Arthur Pendelton`); `VIN 4782` is a 4-digit fragment, not a VIN |
| `Save Consent` | action | Yes (`technicianConsent`) | Current endpoint records consent type/status/wording/channel, but has no signature payload |

No score appears. Customer name + VIN fragment + signature-like data are sensitive.

## 7. States shown / not shown

Shown: default state with PDF-sharing ON, road-test ON, data-storage OFF, a "Recorded" sample signature, timestamp, enabled Save.

Not shown: unsigned/empty pad; refused consent; partially granted; different consent types (processing, public link, WhatsApp, SMS, email, PDF download); wording version/full wording; validation error ("signature required"); clear/reset confirmation; saving/loading; offline/local-only; save error/conflict; Arabic/RTL.

## 8. Implied interactions

- Toggle each switch; draw/clear signature; Save Consent.
- No prototype reactions; whether the switches are the actual consent values or a summary is inferred.

## 9. Correspondence to current product

- Matches T07 Consent (`/jobs/:jobId/consent`). Current implementation is a bottom sheet in `job_detail_page.dart` with two consent types (`PROCESSING`, `PUBLIC_LINK`), granted/refused selection, fixed `wordingVersion: 'v1'`, `channel: 'IN_PERSON'`, and `technicianConsent`.
- Current code initialises `granted = true`; the Figma also shows two switches ON. Both pre-select consent, which conflicts with the T07 requirement "never pre-ticked".
- The Figma adds a signature, `PDF sharing`, `road test`, and `data storage` consents that are not in the current model; it **drops** the public-link consent, which is the critical one for report sharing.
- Signature capture/storage, per-channel consent and wording display would require new data/API/storage — not a UI-only change.

## 10. Locked-rule conflicts / unsafe-to-ship content

- **"no certification/'verified by'/compliance claims"**: `Authorize certified technician dynamic evaluation` (1:7568) uses "certified technician"; the intro says "compliance permissions". No certification evidence exists.
- **"Never invent versions/licences/measurements/results" / security claims**: "Encrypt telemetry logs and secure fleet cloud backups" (1:7580) asserts encryption, telemetry and cloud backup behaviour that is not evidenced in the export; "Allow PDF sharing" asserts a PDF workflow with no server status.
- **Consent must be explicit and separate; "never pre-ticked"** (T07): two switches are ON by default (1:7557, 1:7569 with `#10B981` fill). This is a consent anti-pattern and unsafe.
- **Separate consent types**: the product requires separate consent for processing, public link, each delivery channel and PDF download. The screen has three generic switches and no public-link/WhatsApp/SMS/email consent.
- **Fake signature / fabricated evidence**: the pad ships with a sample cursive stroke, a "Recorded" badge and "Timestamp: Today, 14:38 EST". Shipping this as a recorded signature is fabricated evidence; it also violates "finalized evidence immutable" if it is editable afterwards.
- **"no approval/certification"**: "FINAL SIGN-OFF" and "Authorized Representative" are customer-consent wording, not a manager approval, but the combination with "Authorized" and "Recorded" overstates verification. Copy should be reviewed so it does not imply certification.
- **WCAG 2.2 AA**: switches are 32 px high, "Clear" is 24 px high; on/off is colour-only with no visible state label; `Required` green text is 2.54:1; longer consent titles visibly clip in the PNG.
- **RTL**: no Arabic layout; signature/name/date are LTR only.
- **Timezone/locale**: `EST` is not a UAE timezone; time/date must come from a locale-aware source, not a fixed string.
- **Identity mismatch**: screen 04 shows customer `Arthur Pendelton`; this screen shows signer `Alex Lindqvist`. The same flow cannot be traced across screens.

## 11. Open questions / could not verify

- Which exact consent types are required (processing, public link, WhatsApp, SMS, email, PDF download), and which are legal blockers? The screen's three switches do not match T07.
- Is the signature required by product/legal? Who signs — the customer or the technician? The "Authorized Representative" label is ambiguous.
- Is the cursive stroke a placeholder or a designed "signed" state? If it is a placeholder, it must never be saved as evidence.
- Is `VIN 4782` a masked VIN, a job suffix, or a typo? It is not a valid 17-character VIN.
- Is `EST` intentional? What time source/locale should timestamps use?
- Should "Allow PDF sharing" be a consent, or is it a delivery setting owned by Workshop Admin?
- Why are two consents pre-selected, and is the current `granted = true` default also a bug?
- Are the text blocks intentionally clipped, or is this a frame-width/auto-resize error? The PNG shows truncation of three consent strings.
- No prototype reactions; switch/save behaviour cannot be verified.
