# Fonts and licences — Figma design vs. shipped product

**Status:** research report, no product decisions.
**Date:** 2026-11-05
**Scope:** font families observed in the four Figma exports; fonts actually bundled or served by this repository; licence and glyph-coverage verification from official sources; gaps and risks.
**Not in scope:** visual redesign, font purchasing, legal advice.

---

## 1. Method and official sources

### 1.1 Local evidence

Figma exports:

- `figma/technision_figma` — 16 screen JSONs
- `figma/Workshop_admin_figma` — 12 screen JSONs
- `figma/platform_admin_figma` — 10 screen JSONs
- `figma/public_report_figma` — 7 screen JSONs

Total: **45 screen JSONs**, **1,876 text nodes**. The aggregation excluded `package-manifest.json` and each screen's `assets/manifest.json`; it traversed `nodes[].children[]` and read `text.fontName.family`, `text.fontName.style`, `text.fontWeight`, `text.fontSize`, `text.letterSpacing`, `text.characters`. Counts are text-node counts, not distinct text styles.

Product evidence:

- `client/apps/technician_app/pubspec.yaml`, `client/apps/admin_app/pubspec.yaml`, `client/pubspec.yaml`
- `client/packages/design_system/lib/src/tokens.dart` and the other package sources
- `server/src/main/resources/public-report/fonts/` and `report.css`
- `server/src/main/java/com/truereport/reports/ReportFonts.java`, `PublicReportAssetsConfig.java`
- `docs/ui/DESIGN.md`, `docs/ui/apex_vehicle_inspection_ecosystem_product_prd.md`, `docs/phase-1/10-design-system.md`, `master.md`

Font metadata and coverage were read from the actual binaries with **Python `fontTools` 4.63.0** (`TTFont.getBestCmap()` and the `name` table). File sizes were read with PowerShell. No application, server, config, or existing documentation was modified; only this file was written.

The official Plus Jakarta Sans variable binary (`PlusJakartaSans[wght].ttf`, v2.071) and the URW `NimbusSans-Regular.otf` (v1.00) were downloaded to a temporary directory for independent `cmap` checks. The server fonts were checked in place.

### 1.2 Official sources consulted (all accessed 2026-11-05)

- Google Fonts — Plus Jakarta Sans specimen: https://fonts.google.com/specimen/Plus+Jakarta+Sans
- Google Fonts repository — Plus Jakarta Sans metadata: https://github.com/google/fonts/blob/main/ofl/plusjakartasans/METADATA.pb
- Google Fonts repository — Plus Jakarta Sans OFL: https://github.com/google/fonts/blob/main/ofl/plusjakartasans/OFL.txt
- Upstream Plus Jakarta Sans project: https://github.com/tokotype/PlusJakartaSans
- SIL Open Font License 1.1 official text: https://openfontlicense.org/ and https://scripts.sil.org/OFL
- Noto project dashboard / script list: https://notofonts.github.io/
- Noto fonts repository and licence: https://github.com/notofonts/noto-fonts ; https://github.com/notofonts/noto-fonts/blob/main/LICENSE
- Noto Arabic repository: https://github.com/notofonts/arabic
- Noto CJK repository: https://github.com/notofonts/noto-cjk
- URW base 35 fonts (Nimbus Sans): https://github.com/ArtifexSoftware/urw-base35-fonts ; licence: https://github.com/ArtifexSoftware/urw-base35-fonts/blob/master/LICENSE
- GNU FreeFont licence: https://www.gnu.org/software/freefont/license.html
- GNU FreeFont coverage table: https://www.gnu.org/software/freefont/coverage.html
- Liberation Fonts project and licence: https://github.com/liberationfonts/liberation-fonts ; https://github.com/liberationfonts/liberation-fonts/blob/main/LICENSE

Where this report says “verified”, it means either the binary's `name`/`cmap` tables were read directly, or the statement is quoted from the official source above. Where a font file was never present in the repository (design-only families), “unverified” means the exact file, version, and provenance could not be established.

---

## 2. Families observed in the Figma exports

### 2.1 Totals by application

| App | Screens | Text nodes | Plus Jakarta Sans | Nimbus Sans | FreeSerif | Liberation Mono |
|---|---:|---:|---:|---:|---:|---:|
| technision_figma | 16 | 362 | 358 | 3 | 1 | 0 |
| Workshop_admin_figma | 12 | 681 | 671 | 0 | 0 | 10 |
| platform_admin_figma | 10 | 565 | 558 | 0 | 1 | 6 |
| public_report_figma | 7 | 268 | 262 | 0 | 1 | 5 |
| **Total** | **45** | **1,876** | **1,849** | **3** | **3** | **21** |

Observed families are **Plus Jakarta Sans**, **Nimbus Sans**, **FreeSerif**, and **Liberation Mono**. No other family appears in `text.fontName` across the 45 exports.

### 2.2 Exact family / style / weight counts

| Family | Style as recorded | Weight | Count | Apps | Typical use in the exports |
|---|---|---:|---:|---|---|
| Plus Jakarta Sans | Regular | 400 | 296 | all four | body copy, descriptions, metadata, helper text, VIN labels |
| Plus Jakarta Sans | Medium | 500 | 180 | all four | form labels, secondary headings, language-switch copy, table text |
| Plus Jakarta Sans | SemiBold | 600 | 738 | all four | buttons, badges, table headers, eyebrow/status labels |
| Plus Jakarta Sans | SemiBold Italic | 600 | 1 | Workshop | the single “Unassigned” status |
| Plus Jakarta Sans | Bold | 700 | 564 | all four | headings, values, primary CTAs, card titles |
| Plus Jakarta Sans | ExtraBold | 800 | 70 | all four | wordmarks, screen titles, large numerals |
| Nimbus Sans | Bold | 700 | 3 | Technision | step numbers “1”, “2”, “3” on Final Review (Missing Items) |
| FreeSerif | Bold | 600 | 3 | Technision, Platform, Public | Arabic labels: “عربي” (Technision login, Public report footer) and “مطلوب” (Platform Admin translation editor) |
| Liberation Mono | Regular | 400 | 3 | Workshop | image filenames (`IMG_3091_R_FRONT`, `IMG_3092_DOOR_SCRATCH`) |
| Liberation Mono | Bold | 600 | 15 | Workshop, Platform, Public | VINs, URNs, SHA-256 strings, item IDs, check ratios |
| Liberation Mono | Bold | 700 | 3 | Workshop, Public | VIN / plate at larger size |
| **Total** | | | **1,876** | | |

Metadata oddities worth recording:

- `FreeSerif` is named **Bold** in the style field but carries `fontWeight: 600`.
- `Liberation Mono` appears with **Bold** at both `600` and `700` in different nodes.
- `Nimbus Sans` and `FreeSerif` are one-off fallback/substitute families, not part of the design system's normal type scale.

### 2.3 Important Arabic finding in Figma

The export metadata contains **11 nodes with Arabic characters**:

- **3 nodes use `FreeSerif` Bold**: the two “عربي” language labels and the “مطلوب” badge.
- **8 nodes use `Plus Jakarta Sans`**: the Platform Admin “Master Item Content & Translation Editor” screen (Arabic heading, label, instructions, body, verification note, and the mixed “عربي (Arabic)” heading) plus the Public Report footer’s “Switch Language to Arabic (عربي)”.

**Plus Jakarta Sans has no Arabic glyphs** (verified below). Therefore the Arabic text tagged as Plus Jakarta Sans in those 8 nodes must have been rendered by an implicit Figma fallback, not by the recorded family. The JSON records the designer's assigned family, not the substituted raster font. The actual fallback face cannot be identified from the export.

---

## 3. Fonts actually bundled or served by the product

### 3.1 Server / public report / PDF

| File | Family and version (verified from `name` table) | Size | Script coverage (verified from `cmap`) | Licence | Where used |
|---|---|---|---:|---|---|
| `server/src/main/resources/public-report/fonts/NotoSans-Regular.ttf` | **Noto Sans Regular**, `Version 2.008; ttfautohint (v1.8) ...`, unique `2.008;GOOG;NotoSans-Regular` | 569,208 bytes (555.9 KiB) | Latin 95/95; Latin-ext 128/128; Cyrillic 256/256; **no Arabic**; **no CJK** | SIL OFL 1.1 | HTML body via `--font-body` / `TR Sans`; PDF via base64 `@font-face` in `ReportFonts.java` |
| `server/src/main/resources/public-report/fonts/NotoNaskhArabic-Regular.ttf` | **Noto Naskh Arabic Regular**, `Version 2.012; ttfautohint (v1.8) ...`, unique `2.012;GOOG;NotoNaskhArabic-Regular` | 178,388 bytes (174.2 KiB) | Arabic 253/256; Arabic Supplement 48; Presentation Forms-A 611; Presentation Forms-B 141; Arabic-Indic digits 0x0660–0x0669 present; Latin only 15 characters (space, `!`, `,`, `.`, `0`–`9`, `:`); **no Cyrillic**; **no CJK** | SIL OFL 1.1 | HTML `[lang="ar"]` / `[dir="rtl"]` as `TR Arabic`; PDF `TR Arabic` |
| `server/src/main/resources/public-report/fonts/NotoSansSC-Regular.otf` | **Noto Sans CJK SC Regular**, `Version 2.004; hotconv 1.0.118; makeotfexe 2.5.65603`, unique `2.004;GOOG;NotoSansCJKsc-Regular;ADOBE` | 16,437,364 bytes (15.68 MiB) | CJK Unified 20,976 tested glyphs; Latin 95/95; Latin-ext 30/128; Cyrillic 66/256; **no Arabic** | SIL OFL 1.1 | HTML `[lang="zh-Hans"]` as `TR CJK`; PDF `TR CJK`; last fallback in the body stack |
| `server/src/main/resources/public-report/fonts/OFL.txt` | SIL OFL 1.1 text; copyright line: “Copyright 2018 The Noto Project Authors (github.com/googlei18n/noto-fonts)” | 4,377 bytes | n/a | SIL OFL 1.1 | Licence notice in server resources. **Not confirmed** that it is served with the public report or attached to downloaded PDFs. |

Wiring:

- `PublicReportAssetsConfig.java` maps `/r/assets/**` to `classpath:/public-report/`, so `report.css` can load `/r/assets/fonts/...`.
- `ReportFonts.java` inlines all three fonts as base64 `@font-face` rules for the PDF HTML. The PDF engine is headless Chromium (per `master.md`), so Arabic shaping is handled by Chromium's text stack, not by OpenHTMLtoPDF.
- `report.css` declares:
  - `--font-body: "TR Sans", "TR Arabic", "TR CJK", system-ui, sans-serif;`
  - `--font-arabic: "TR Arabic", "TR Sans", "TR CJK", sans-serif;`
  - `--font-cjk: "TR CJK", "TR Sans", sans-serif;`
  - `[lang="ar"], [dir="rtl"] { font-family: var(--font-arabic); }`
  - `[dir="rtl"] { text-align: right; }`
  - `[lang="zh-Hans"] { font-family: var(--font-cjk); }`

### 3.2 Flutter applications

**The Flutter apps bundle no fonts at all.**

- Neither `client/apps/technician_app/pubspec.yaml` nor `client/apps/admin_app/pubspec.yaml` has a `flutter: fonts:` section or any `assets` entry for fonts.
- No `.ttf`, `.otf`, `.woff`, or `.woff2` file exists under `client/` outside build artefacts / `.dart_tool`.
- No `fontFamily`, `fontFamilyFallback`, `GoogleFonts`, or `google_fonts` usage exists in `client/packages/design_system/lib` or the app `lib/` sources. `AppTheme.build` uses `base.textTheme` and only changes weights and letter spacing.
- Neither app depends on `google_fonts`; `client/pubspec.yaml` does not either.

Consequently, the Flutter UI currently renders in the **platform default font**:

- Android: typically Roboto / Noto fallback selected by the OS.
- iOS: San Francisco / system fallback.
- Web/desktop: browser or OS default.

The design's Plus Jakarta Sans is **not implemented in Flutter**, and no Arabic, Cyrillic, or CJK font is bundled in the app. Arabic RTL direction is still provided by Flutter's localizations (`MaterialApp` with `locale`, `supportedLocales`, `flutter_localizations`), but the glyphs come from the device, not from a product-controlled font. Some strings explicitly force `TextDirection.ltr` (VIN/plate fields), which is appropriate for identifiers.

---

## 4. Per-family licence detail

The OFL 1.1 text permits use, study, copying, merging, embedding, modification, redistribution, and sale of modified or unmodified copies, provided that:

1. the font is not sold by itself;
2. each copy contains the copyright notice and the licence;
3. modified versions do not use a declared Reserved Font Name without written permission;
4. copyright-holder/author names are not used to promote modified versions without permission;
5. the font software remains under the OFL.

The OFL does **not** require UI attribution. It does require the notice and licence to travel with the font software. Embedding in documents (including PDFs) is expressly permitted, and documents made with the font are not themselves covered by the OFL.

| Family | Upstream owner | Licence (verified) | Version / URL | Reserved Font Name | Redistribution / embedding / PDF | Modification / subsetting | Attribution obligation | Current use |
|---|---|---|---|---|---|---|---|---|
| **Plus Jakarta Sans** | Tokotype / The Plus Jakarta Sans Project Authors (designed by Gumpita Rahayu) | **SIL OFL 1.1** | OFL text; https://github.com/google/fonts/blob/main/ofl/plusjakartasans/OFL.txt | **No Reserved Font Name is declared** in the official OFL file | Permitted; PDF embedding explicitly allowed by OFL | Permitted; modified/subsetted versions cannot use an RFN (none declared here) | Include copyright notice + OFL with the font software; no UI credit required | **Design-only.** It is not bundled in Flutter or on the server, so no distribution obligation is triggered by this repository today. If implemented, the OFL and notice must be shipped. |
| **Noto Sans** (Regular) | The Noto Project Authors / Google | **SIL OFL 1.1** | Noto Sans `Version 2.008`; local `OFL.txt`; https://github.com/notofonts/noto-fonts/blob/main/LICENSE | **No Reserved Font Name is declared** in the bundled `OFL.txt` | Permitted; PDF embedding explicitly allowed by OFL | Permitted; subsetting permitted; preserve notice | Include copyright + OFL; no UI credit required | **Bundled and served** (HTML + PDF). `OFL.txt` is present in resources. Compliant if the licence is distributed with the font/report; that distribution link is not verified. |
| **Noto Naskh Arabic** (Regular) | The Noto Project Authors / Google | **SIL OFL 1.1** | `Version 2.012`; local `OFL.txt`; https://github.com/notofonts/arabic | **No RFN declared** in the bundled `OFL.txt` | Permitted; PDF embedding permitted | Permitted; preserve notice | Include copyright + OFL; no UI credit required | **Bundled and served** (Arabic HTML + PDF). Same notice-distribution caveat. |
| **Noto Sans CJK SC** (Noto Sans SC) | The Noto Project Authors / Adobe + Google | **SIL OFL 1.1** | `Version 2.004` (Noto Sans CJK SC); https://github.com/notofonts/noto-cjk | **No RFN declared** in the bundled `OFL.txt` | Permitted; PDF embedding permitted | Permitted; subsetting allowed; preserve notice | Include copyright + OFL; no UI credit required | **Bundled and served** (CJK HTML + PDF). Same notice-distribution caveat. File is very large; subsetting is a technical option but must preserve the licence notice. |
| **Nimbus Sans** | URW++ / Artifex `urw-base35-fonts` (for the free release); a commercial Monotype version may also exist | **AGPL-3.0** with a special exception for embedding in PostScript/PDF documents, **for the URW base35 release** | URW file checked: `Version 1.00`; https://github.com/ArtifexSoftware/urw-base35-fonts/blob/master/LICENSE | No OFL RFN concept; AGPL applies | The URW licence permits embedding the font programs in PostScript/PDF documents; **shipping the font software itself with an app would trigger AGPL source/notice obligations** | AGPL terms apply to modified font software | AGPL notices/source obligations for distribution of the font software | **Design-only, not shipped.** The exact Figma source is **unverified** (could be URW AGPL, a Monotype licence, or an OS substitute). Do not assume it is safe to bundle. |
| **FreeSerif** | GNU FreeFont project | **GNU GPL v3 or later**, with a special exception for embedding the unmodified font in documents | https://www.gnu.org/software/freefont/license.html ; coverage https://www.gnu.org/software/freefont/coverage.html | GPL has no OFL Reserved Font Name mechanism | Embedding the **unmodified** font in a document is exempt from GPL; distributing the font software itself is not covered by the document exception and requires GPL compliance | Modified versions must comply with the GPL; the exception may optionally be carried forward | GPL notices/source obligations when distributing the font software | **Design-only, not shipped.** Exact FreeSerif file/version in the design is **unverified**. If it were bundled, GPL analysis would be required; the document-embedding exception does not by its terms authorize bundling the font as an app asset. |
| **Liberation Mono** | Red Hat / Google (Liberation Fonts) | **SIL OFL 1.1** | https://github.com/liberationfonts/liberation-fonts/blob/main/LICENSE | **Reserved Font Names**: `Liberation`, and (from the Google digitized data) `Arimo`, `Tinos`, `Cousine` | Permitted; PDF embedding permitted | Permitted, but modified versions must not use the RFNs without permission | Include copyright + OFL; no UI credit required | **Design-only, not shipped.** Exact file/version is **unverified**; Figma may use a locally installed copy. |

### 4.1 Compliance summary

| Family | Licence status | Compliant today? |
|---|---|---|
| Plus Jakarta Sans | Verified OFL 1.1; no RFN declared | Design artifact only; no distribution. If bundled, add OFL + notice. |
| Noto Sans / Noto Naskh Arabic / Noto Sans SC | Verified OFL 1.1; no RFN declared in bundled `OFL.txt` | Bundled server-side; OFL text exists. **Conditional**: confirm the OFL notice is actually delivered with public reports/PDFs. |
| Nimbus Sans | **Unverified provenance**; official URW base35 file is AGPL-3.0 + PDF exception | Not shipped; no current distribution. Do not bundle without resolving licence/provenance. |
| FreeSerif | Verified GNU FreeFont GPLv3+ + document embedding exception; exact file unverified | Not shipped; no current distribution. Bundling would require GPL compliance review. |
| Liberation Mono | Verified OFL 1.1 with RFNs; exact file unverified | Not shipped; no current distribution. |

---

## 5. Glyph / script coverage matrix

Legend: **Yes** = verified presence; **No** = verified absence; **Partial** = only part of the range is present; **Unverified** = no binary available / not independently checked. Counts are codepoints found in the font's best `cmap`.

| Family | Latin | Latin-ext | Arabic | Cyrillic | Simplified Chinese | Verification source |
|---|---|---|---|---|---|---|
| **Plus Jakarta Sans** | Yes (95/95 basic) | Yes (126/128 Latin Ext-A; `Ł` present) | **No** (0/256 Arabic block; 0 presentation forms) | **No** (0/256 basic; 0/208 Cyrillic-ext) | **No** (0/20,992 CJK Unified) | `cmap` of official Google Fonts v2.071 variable TTF; also upstream static v2.071 (721 glyphs) |
| **Nimbus Sans** | Yes (95/95) | Yes (128/128) | No (0/256) | Partial (144/256) | No (0/20,992) | `cmap` of URW base35 `NimbusSans-Regular.otf`, v1.00 |
| **FreeSerif** | Yes | Yes | Yes (300 Arabic + supplement) | Yes (408 Cyrillic incl. supplements) | No | GNU FreeFont official coverage table; exact design file not available |
| **Liberation Mono** | Yes for the ASCII strings actually used | Unverified | Unverified | Unverified | Unverified | Font not present in repo; Figma only uses ASCII VIN/hash/code strings |
| **Noto Sans Regular** | Yes (95/95) | Yes (128/128) | **No** (0/256) | **Yes** (256/256) | **No** (0/20,992) | `cmap` of bundled `NotoSans-Regular.ttf` v2.008 |
| **Noto Naskh Arabic Regular** | Partial (15 basic characters: digits/punctuation only) | No (0) | **Yes** (253/256 + supplement/presentation forms; Arabic-Indic digits present) | No (0) | No (0) | `cmap` of bundled `NotoNaskhArabic-Regular.ttf` v2.012 |
| **Noto Sans CJK SC Regular** | Yes (95/95) | Partial (30/128) | **No** (0/256) | Partial (66/256) | **Yes** (20,976/20,992 tested) | `cmap` of bundled `NotoSansSC-Regular.otf` v2.004 |

### 5.1 Official-source caveat on Plus Jakarta Sans

Google Fonts' `METADATA.pb` lists `subsets: "cyrillic-ext"`, and the Google Fonts CSS API emits a `cyrillic-ext` `@font-face` block for Plus Jakarta Sans. **The official v2.071 binary does not contain any Cyrillic codepoints** (verified: 0/256 basic Cyrillic and 0/208 Cyrillic-ext; the upstream v2.071 static Regular also has 0 Cyrillic glyphs). This report therefore treats Plus Jakarta Sans as **not Cyrillic-capable**, despite the metadata/CSS listing. The discrepancy is flagged, not resolved; do not use the CSS `unicode-range` as proof of glyph coverage.

### 5.2 The coverage gap against the product requirement

`master.md` requires:

- English + Arabic UI, genuine RTL, bilingual English–Arabic PDF;
- entering Arabic, Russian (Cyrillic), and Chinese customer names/notes;
- bundled fonts in apps and PDFs, not runtime `google_fonts`;
- fonts that display all required characters (`master.md` §13A.3.9, §Typed information and fonts).

The design's single-family choice is **Plus Jakarta Sans**. Verified coverage:

- Plus Jakarta Sans covers Latin and Latin-ext only among the required scripts. It does **not** cover Arabic, Cyrillic, or Simplified Chinese.
- Therefore Plus Jakarta Sans alone cannot render the Arabic UI, Russian names, or Chinese names. A fallback family is mandatory for each script.
- The server PDF/HTML already has that fallback chain: Noto Sans (Latin/Cyrillic) + Noto Naskh Arabic (Arabic) + Noto Sans CJK SC (Chinese).
- The Flutter apps do **not** have a product-controlled fallback chain; they use whatever the OS supplies. That is not the same guarantee as the PDF path.

`docs/phase-1/10-design-system.md` already says font families are “Pending licence verification” and “do not bundle until licences and coverage are checked”; `docs/ui/DESIGN.md` and the PRD name Plus Jakarta Sans without a multilingual fallback. The design documentation and the product requirement are therefore inconsistent.

---

## 6. Arabic font / fallback finding

### 6.1 What the Figma exports show

1. **Explicit fallback family:** FreeSerif is used for the Arabic language labels. FreeSerif is a GNU FreeFont family, not Plus Jakarta Sans, and it is not part of the product's font assets.
2. **Implicit fallback:** 8 Arabic-containing nodes are tagged Plus Jakarta Sans, which has no Arabic glyphs. Figma must have substituted another face when rendering. The export does not record which face was used, and the PNG rasters were not analysed for this report. The designer's intended Arabic typeface is therefore **not documented**.
3. **Letter-spacing on Arabic:**
   - FreeSerif “عربي” labels: `letterSpacing` 0.24 px; “مطلوب”: 0.44 px.
   - Plus Jakarta Sans Arabic nodes: values from -0.27 px to +0.44 px (heading -0.27 / -0.16 / -0.14; label +0.44; body -0.16; verification note 0).
   - `docs/phase-1/10-design-system.md` explicitly says: **“Do not letter-space Arabic.”** The Figma Arabic nodes violate that rule.
4. **Alignment:** The Platform Admin Arabic block is right-aligned; the language labels are centered. Direction is not consistent across all Arabic samples.

### 6.2 What the product actually does

| Surface | Arabic font | Shaping / direction | Risk |
|---|---|---|---|
| Public report HTML | Noto Naskh Arabic (`TR Arabic`) via `[lang="ar"]` / `[dir="rtl"]` | Browser shaping; `[dir="rtl"]` sets right alignment | Font is real and bundled. **However**, the global `h1` (`letter-spacing: -0.03em`) and `h2` (`-0.02em`) rules also apply to Arabic headings because there is no `[lang="ar"]` / `[dir="rtl"]` letter-spacing reset. This contradicts the design-system rule. |
| PDF (headless Chromium) | Same three fonts inlined as base64 by `ReportFonts.java` | Chromium text stack; correct `dir`/`lang` needed in the template | Shaping is likely correct because Chromium uses HarfBuzz; this was not re-tested with real Arabic in this report. The same heading letter-spacing issue can leak into PDFs if the print CSS reuses `report.css`. |
| Flutter technician/admin apps | **None bundled**; platform default | Flutter `MaterialApp` localizations supply RTL direction for `ar`; some identifier fields force LTR | Arabic may render via Android/iOS system fonts, but the product does not control the face, weight, or metrics. Device/OEM fallback differences are untested. No licence is invented by this behaviour, but it does not meet the “bundle fonts” requirement. |

### 6.3 What must change to meet “Arabic RTL must work” (without inventing a licence)

1. **Pick and document a real Arabic family** for the design and implementation. The only Arabic family already verified and bundled in this repository is **Noto Naskh Arabic Regular v2.012** under OFL 1.1. If the product wants a different Arabic face, verify its licence and Arabic coverage before use; do not keep FreeSerif as an unlicensed design fallback.
2. **Remove Arabic letter-spacing** in Figma and in CSS:
   - set Arabic text nodes to `letterSpacing: 0` in Figma;
   - add a CSS reset such as `[lang="ar"] h1, [lang="ar"] h2, [dir="rtl"] h1, [dir="rtl"] h2 { letter-spacing: normal; }` (and check other letter-spaced selectors: `.brand`, `th`, `td::before`, `.hash`).
3. **Bundle/declare the Arabic font in Flutter** if the app is to control rendering: add the font file under the app/package assets, declare it in `pubspec.yaml`, set `fontFamily` / `fontFamilyFallback`, and test Arabic shaping on Android and iOS. If the product intentionally relies on platform fonts, document that as a deliberate exception to `master.md` and test mixed Arabic/Latin/numerals on real devices.
4. **Keep the CSS fallback order correct for mixed strings:** Latin first (`TR Sans`), Arabic next (`TR Arabic`), CJK last (`TR CJK`). The current body stack does this; the `[lang="ar"]` stack puts Arabic first but falls back to `TR Sans` for Latin/digits. Verify a name like “أحمد Ali 123” and a Chinese name in the same report.
5. **Ensure the OFL notice travels with the fonts** on every surface that distributes them (HTML report, PDF, app bundle). The file exists at `server/src/main/resources/public-report/fonts/OFL.txt`, but this report did not verify that it is exposed to report consumers or embedded in the PDF package.

---

## 7. Risks and what could not be verified

1. **Exact designer font versions are unknown.** Figma exports contain no font binaries. The JSON's `fontName` is a designer-assigned style name, not proof of the file used. The current official Plus Jakarta Sans is v2.071; the designer may have used another version.
2. **Nimbus Sans provenance is unresolved.** The free URW base35 release is AGPL-3.0 with a PDF/document embedding exception; a commercial Monotype Nimbus Sans licence may differ. The Figma file could also be an OS substitute. Do not bundle it on the assumption that it is free.
3. **FreeSerif provenance/version is unresolved.** GNU FreeFont is GPLv3+ with a document-embedding exception, but the design file's exact release is unknown. It is not shipped today, so there is no current distribution issue; bundling it would require GPL compliance review.
4. **Liberation Mono version is unknown.** The family is OFL 1.1 with Reserved Font Names (`Liberation`, plus `Arimo`/`Tinos`/`Cousine` from the digitized data), but the exact Figma file was not available to inspect. Its non-ASCII coverage was therefore not independently verified.
5. **The implicit Arabic fallback in Figma cannot be identified.** Eight Arabic nodes are tagged Plus Jakarta Sans, which has no Arabic glyphs. The rendered face is not recorded in the JSON; the PNGs were not analysed.
6. **Flutter device coverage is unverified.** The apps bundle no fonts and declare no family. Whether Arabic, Cyrillic, and Simplified Chinese render correctly depends on the OS/browser and OEM; this report did not run real-device tests.
7. **The OFL notice distribution path is unverified.** `OFL.txt` exists in server resources, but it is not confirmed that public report HTML exposes it, that PDFs attach it, or that the app bundles include it.
8. **Plus Jakarta Sans metadata is inconsistent with its binary.** Google Fonts `METADATA.pb` and the CSS API list `cyrillic-ext`, but the official v2.071 binary has zero Cyrillic codepoints. Any claim that Plus Jakarta Sans supports Cyrillic based on the CSS `unicode-range` would be wrong.
9. **No raster analysis was performed.** Rasters were treated as visual references only; they cannot provide reliable font-family metadata.
10. **NotoSansSC is large (15.68 MiB).** Bundling it in Flutter would materially increase app size; subsetting is permitted by OFL but the subset must retain the notice and be tested for the required Chinese characters.
11. **Noto Naskh Arabic is a Naskh (serif-like) face, not a UI sans.** It shapes Arabic correctly, but its style differs from Plus Jakarta Sans. The design has not chosen whether that contrast is acceptable.
12. **No legal advice.** Licence statements above are a reading of the official texts and repository metadata, not a legal opinion.

---

## 8. Options (not decisions)

The product owner should choose; these are the realistic paths and their costs.

### Option A — Plus Jakarta Sans for Latin + Noto Naskh Arabic + Noto Sans SC fallback

- **Design:** keep Plus Jakarta Sans for Latin UI; explicitly specify Noto Naskh Arabic for Arabic and Noto Sans SC for Chinese; remove FreeSerif.
- **Flutter:** bundle PJS weights actually used (400/500/600/700/800 + italic if needed), Noto Naskh Arabic, and either bundle or lazily load Noto Sans SC.
- **PDF/HTML:** current architecture already matches this option.
- **Pros:** preserves the design's Latin identity; all families have verified OFL 1.1 licences; offline-safe; clear fallback chain.
- **Cons:** three families and multiple weights to manage; Arabic style differs from PJS; Noto Sans SC is 15.68 MiB; Flutter font registration and asset-size work; CJK subsetting/deferred loading may be needed.

### Option B — One broad Noto family for UI + Naskh Arabic + Noto Sans SC

- Use Noto Sans (Latin/Greek/Cyrillic) as the primary UI face, Noto Naskh Arabic for Arabic, Noto Sans SC for Chinese.
- **Pros:** one sans family covers Latin and Cyrillic; consistent licence (OFL 1.1); simpler multilingual reasoning; no PJS coverage gap.
- **Cons:** loses Plus Jakarta Sans entirely; design tokens and all Figma text styles must change; Noto Sans's tone differs from the current brand direction; still three families for Arabic/CJK.

### Option C — One Latin+Arabic family + CJK fallback

- Choose a family that genuinely covers both Latin and Arabic (candidate examples only: IBM Plex Sans Arabic, Noto Sans Arabic, or another verified OFL family), plus Noto Sans SC for Chinese.
- **Pros:** fewer families; Arabic and Latin share proportions; potentially smaller than PJS + Naskh.
- **Cons:** must verify the chosen family's Arabic coverage, weights, licence, and RFN status before use; most “Latin+Arabic” families still do not cover CJK; the brand will not be Plus Jakarta Sans; needs a new design pass.

### Option D — Keep platform fonts in Flutter, bundle fonts only for the PDF/HTML

- **Pros:** zero app font assets; smallest app; no Flutter font registration work.
- **Cons:** directly conflicts with `master.md`'s “bundle fonts with the app and PDF” instruction; Arabic/Cyrillic/CJK rendering varies by OS/OEM; the design's PJS is not implemented; Arabic RTL may work but the face and metrics are uncontrolled; cannot be called brand-consistent.
- **Mitigation if chosen:** document the exception, add real-device tests for Arabic/Cyrillic/Chinese, and keep the PDF path as the controlled rendering surface.

### Option E — Keep PJS for LTR only and document fallbacks

- Keep PJS for Latin UI, but explicitly specify an Arabic fallback and a CJK fallback in the design system; do not pretend PJS covers those scripts.
- **Pros:** minimal change to the existing Latin design; honest coverage documentation.
- **Cons:** still requires at least two additional families for Arabic and Chinese; Flutter still needs a font strategy; the design remains a multi-family system, not the single-family system currently implied by `DESIGN.md`.

### Cross-option tasks

- Replace FreeSerif labels with the chosen Arabic family.
- Remove Arabic letter-spacing in Figma and CSS.
- Verify the chosen Arabic family against UAE Arabic text (standard Arabic, diacritics, mixed Latin/numbers) using real Chromium PDF output.
- Verify Cyrillic (Russian names) in both Flutter and PDF.
- Verify Simplified Chinese names in both Flutter and PDF, including mixed Chinese/Latin strings.
- Ship the OFL notice with every surface that distributes a font.
- Record the exact font versions and file hashes in the repository so future audits do not depend on Figma's cloud versions.

---

## Appendix A — Local verification notes

- Text-node aggregation: Node.js traversal of all 45 screen JSONs; excluded `package-manifest.json` and `assets/manifest.json`.
- Font `name` and `cmap`: Python `fontTools` 4.63.0. Counts are codepoints present in the best `cmap`; they are not a claim about shaping quality.
- File sizes: PowerShell `Get-Item.Length`.
- Official Plus Jakarta Sans binary checked: `PlusJakartaSans[wght].ttf`, v2.071, 176,288 bytes, 721 mapped codepoints. Upstream static `PlusJakartaSans-Regular.ttf` v2.071 also checked: 721 mapped codepoints, 0 Cyrillic, 0 Arabic, 0 CJK.
- URW Nimbus Sans checked: `NimbusSans-Regular.otf`, `Version 1.00`, 95/95 Latin, 128/128 Latin-ext, 144/256 Cyrillic, 0 Arabic, 0 CJK.
- Server font checks:
  - `NotoSans-Regular.ttf`: 2,840 mapped codepoints; Latin 95/95, Latin-ext 128/128, Cyrillic 256/256, Arabic 0, CJK 0.
  - `NotoNaskhArabic-Regular.ttf`: 1,123 mapped codepoints; Arabic 253/256, Arabic Supplement 48, Presentation Forms-A 611, Presentation Forms-B 141, Arabic-Indic digits present; Latin 15 (digits/punctuation); Cyrillic 0; CJK 0.
  - `NotoSansSC-Regular.otf`: 44,810 mapped codepoints; CJK 20,976/20,992 tested; Latin 95/95; Latin-ext 30/128; Cyrillic 66/256; Arabic 0.

## Appendix B — Claims reviewed in existing docs

| Document | Claim | Finding |
|---|---|---|
| `docs/ui/DESIGN.md` | Type system is powered by Plus Jakarta Sans; all listed tokens use it | True for Latin text in Figma, but the file does not state that PJS lacks Arabic/Cyrillic/CJK. The design also uses FreeSerif, Nimbus Sans, and Liberation Mono outside the token scale. |
| `docs/ui/apex_vehicle_inspection_ecosystem_product_prd.md` | “Plus Jakarta Sans font family” | Same gap: no multilingual fallback specified. |
| `docs/phase-1/10-design-system.md` | Font families “Pending licence verification”; “Do not letter-space Arabic” | Correct caution. This report verifies the shipped Noto licences and confirms the Figma Arabic nodes currently violate the no-letter-spacing rule. |
| `master.md` | Bundle fonts with app and PDF; do not rely on runtime `google_fonts`; Arabic/Cyrillic/Chinese names | Server PDF/HTML currently complies with bundled fonts; Flutter does **not** bundle fonts at all. Arabic/Cyrillic/CJK coverage in Flutter is therefore platform-dependent. |
| `master.md` | Headless Chromium PDF; OpenHTMLtoPDF rejected for Arabic shaping | Consistent with the server font setup. Chromium + bundled Noto Naskh Arabic is the right shape; test with real Arabic before sign-off. |
