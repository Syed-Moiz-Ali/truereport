# Localization and RTL Rules

**Project:** TrueReport  
**Document:** 03-localization-and-rtl-rules.md  
**Status:** Phase 1 implementation rules. These are specific enough for Flutter, HTML and PDF developers to implement without guessing.

---

## 1. Non-negotiable model: three separate settings

| Setting | What it controls | Stored where | Example |
|---|---|---|---|
| **App language** | Menus, buttons, labels, validation messages | User preference / device | Technician uses English UI |
| **Entry language / direction** | Direction and alignment of one input field | Per field value / user override | Customer name is Arabic; VIN is LTR |
| **Report language** | Languages rendered in the report and PDF | Report snapshot | English + Arabic PDF; customer name preserved as entered |

A technician may use an English app, enter an Arabic name, a Russian note and a Chinese name, and generate an English–Arabic report. **Never transliterate a name.** Preserve the exact entered text (after Unicode normalisation only for matching, not for display).

Supported codes:

- `en` — English
- `ar` — Arabic
- `ru` — Russian (data entry and future UI)
- `zh-Hans` — Simplified Chinese (data entry and future UI; D10 pending)

---

## 2. Direction rules

### 2.1 Layout

1. Use **logical** properties only:
   - Flutter: `Directionality`, `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`, `TextAlign.start/end`.
   - HTML: `dir="rtl"` / `dir="ltr"`, `margin-inline`, `padding-inline`, `inset-inline`, `text-align: start`.
2. **Ban** hardcoded `left`, `right`, `EdgeInsets.only(left:)`, `Alignment.centerLeft`, `TextAlign.left` in feature code. Lint review catches these; allowed only inside the design-system direction helper.
3. Mirror directional icons in RTL: back/forward arrows, chevrons, “next” arrows, progress direction. Do **not** mirror:
   - the VIN/technical identifier,
   - clocks, media play/pause, camera shutter,
   - brand logos,
   - checkmarks (checkmarks are not directional).
4. Progress bars fill from the logical start. In RTL, the start is the right edge.
5. Tables:
   - First logical column is on the right in RTL.
   - Numeric columns keep LTR digits but align consistently (usually end).
   - Header order follows the document direction; never reverse only the header.
6. Modals, drawers and bottom sheets slide from the logical side. Back gestures remain OS-standard.
7. Scrollbars and swipe actions mirror; destructive swipe direction must be tested in both directions.

### 2.2 Base direction by content type

| Content | Base direction | Rule |
|---|---|---|
| App shell in Arabic | RTL | `Directionality.rtl`; `MaterialApp` locale `ar`. |
| App shell in English | LTR | `Directionality.ltr`. |
| Report page in Arabic | RTL | `<html lang="ar" dir="rtl">`. |
| Report page in English | LTR | `<html lang="en" dir="ltr">`. |
| Mixed paragraph | Paragraph direction from the dominant language | Wrap technical tokens in LTR isolates. |
| Customer name field | Detected or user-selected | Default to first strong character; manual toggle always available. |
| Note field | Detected or user-selected | Same as name; preserve line breaks. |
| VIN / plate / phone / email / report ID / date-time token | LTR | Explicit LTR wrapper, always. |
| Numbers in prose | Follow paragraph direction | Use Western digits by default (see §3). |

---

## 3. Numerals, dates and units

### 3.1 Numerals

**Phase 1 default (pending product-owner confirmation): use Western Arabic numerals `0–9` for all technical fields and report identifiers.**

- VIN, plate, phone, odometer, report ID, version, dates, measurements, currency-like values: `0–9` only.
- Arabic UI prose may use Arabic-Indic digits later, but not for identifiers or measurements until a specific decision is made.
- Reason: mixed Arabic-Indic and Western digits inside VIN/phone/table cells create ambiguity and bidi bugs.
- If Arabic-Indic digits are enabled later, they must never be used for VIN, phone, report ID or machine-readable values.

### 3.2 Dates and times

- Store all timestamps in **UTC**.
- Display in the workshop/report time zone; UAE default is **Asia/Dubai (UTC+4, GST)**.
- Technical audit and API values use ISO 8601 with offset: `2026-11-03T14:30:00+04:00`.
- Human UI uses locale formatting (`intl`), but the report footer/header uses a stable format so the PDF and web match.
- Never infer the time zone from the device alone for a stored report; use the workshop time zone and store the offset used.

### 3.3 Units

- Store odometer with an explicit unit (`km` or `mi`); do not infer.
- Display the unit next to the value, LTR: `82,902 km`.
- Tyre pressure, tread depth, paint thickness: value + unit, LTR, in a technical isolate.
- Do not convert units silently. If conversion is added later, show both.

---

## 4. Technical identifiers

### 4.1 VIN

- 17 characters.
- Display uppercase, LTR, monospace or a tabular font, no inserted spaces or hyphens.
- Accept lowercase input and normalise to uppercase for storage/display.
- Reject or warn on `I`, `O`, `Q` (not valid in North American VINs); treat as a hint, not a hard client-only rule. Server is authoritative.
- Never translate, reverse, mirror or apply Arabic shaping to a VIN.
- In Arabic text, wrap as an LTR isolate: `<span dir="ltr" class="ltr-run">WUAZZZGY4NA901440</span>` / Flutter LTR `Directionality`.
- Public report: **omit full VIN by default** (allowlist). Internal screens may show it; logs must redact it.

### 4.2 Plate, registration, engine number

- LTR, uppercase where the jurisdiction uses Latin; preserve Arabic plate text if entered.
- Public report: omit by default.
- Do not assume a plate format; UAE plates can be Arabic + digits + code. Validate as free text with a length limit, not a rigid mask.

### 4.3 Phone numbers

- Store E.164 (`+971501234567`) plus the original display form if needed.
- Input uses an international phone field with country selector; default UAE `+971`.
- Display LTR: `+971 50 123 4567`.
- Never put a phone number in a URL, public page, log, link preview or analytics event.

### 4.4 Email

- Store lowercase for matching, preserve display case if needed.
- LTR. Never public.
- Validate with a permissive Unicode-aware rule; do not reject valid international addresses.

### 4.5 Report ID and version

- LTR, stable, no bidi. Example: `TR-2026-0001 · v1`.
- Printed in the footer of every PDF page and in the public report header.
- Never derive the public token from the report ID.

---

## 5. Mixed-direction text

### 5.1 The rule

Do not rely on the paragraph direction to place a technical token. **Isolate** every LTR run inside RTL text and every RTL run inside LTR text.

- HTML: `<bdi>` or `<span dir="ltr" style="unicode-bidi:isolate">…</span>`.
- Flutter: wrap with `Directionality(textDirection: TextDirection.ltr, child: Text(...))` for a whole widget; for inline mixed text, insert Unicode isolates around the token in the string (`U+2066` LRI … `U+2069` PDI), or render with `Text.rich` and direction-aware spans where supported.
- PDF: use `<span dir="ltr">` / `<span dir="rtl">` with `unicode-bidi: isolate`; do not use deprecated `bidi-override` unless there is a tested reason.

Avoid these traps:

- Arabic sentence + VIN: the VIN must read left-to-right and stay in one piece.
- Parentheses around an LTR token in RTL: the opening parenthesis must appear on the left of the token.
- A date range `2026-11-03 – 2026-11-04` must not flip.
- A percentage `12%` and a measurement `32 PSI` must keep the number before the unit in LTR.
- A negative number `-1.5 mm` must keep the minus sign on the left.
- Slash-separated values `EN/AR` must not reorder.

### 5.2 Examples

| Context | Correct rendering intent | Implementation |
|---|---|---|
| Arabic sentence with VIN | `رقم الهيكل WUAZZZGY4NA901440 محفوظ.` — VIN LTR, one run | `<span dir="ltr">WUAZZZGY4NA901440</span>` |
| Arabic sentence with phone | `الهاتف +971 50 123 4567` — phone LTR | `<span dir="ltr">+971 50 123 4567</span>` |
| English sentence with Arabic note | `Note: تم فحص المركبة بالكامل` — Arabic run RTL | `<span dir="rtl">…</span>` |
| Arabic list | Bullets on the right, text right-aligned | `dir="rtl"` on the list |
| Arabic table header | Header starts on the right | `dir="rtl"` on the table |
| Russian name | `Иван Петров` — Cyrillic LTR | Normal LTR text; no transliteration |
| Chinese name | `张伟` — CJK LTR | Normal LTR text; ensure CJK font coverage |

### 5.3 User-entered names and notes

- Store the **exact string** as entered, including mixed scripts and line breaks.
- Do not uppercase, transliterate, strip diacritics, or “fix” the name.
- For search only, create a normalised copy:
  - Arabic: fold alef forms (`أ إ آ` → `ا`), remove tatweel and optional tashkeel, normalise `ى`/`ي` and `ة`/`ه` for matching only.
  - Latin/Cyrillic: case-fold.
  - Chinese: exact match in V1; no pinyin search.
- Store `name_as_entered` and `name_normalised_for_search` separately. Display only the original.
- Notes have an optional language tag (`ar`, `en`, `ru`, `zh-Hans`, `und`). If a translation is added, store it separately and label it as a translation. Never present machine translation as a confirmed finding.

---

## 6. Text fields and direction controls

### 6.1 Per-field configuration

Every text field declares:

| Property | Values | Example |
|---|---|---|
| `semanticType` | `personName`, `freeNote`, `vin`, `plate`, `phone`, `email`, `identifier`, `search`, `address` | `vin` |
| `defaultDirection` | `auto`, `ltr`, `rtl` | `auto` for name, `ltr` for VIN |
| `allowDirectionToggle` | true/false | true for name/note; false for VIN/phone |
| `keyboardType` | text, phone, number, email, datetime | phone for phone |
| `textInputAction` | next, done, search | next |
| `maxLength` | grapheme-aware | 17 for VIN, 120 for name |

### 6.2 Auto direction

- For `personName` and `freeNote`, detect the first strong directional character (Unicode bidi class L or R/AL).
- If the first strong character is Arabic/Hebrew → RTL.
- Otherwise → LTR.
- If the string is only digits/punctuation/emoji, keep the app/field default and show the toggle.
- The user can override with a visible direction toggle (LTR/RTL). The override is stored with the field value for that record, not as a global app setting.
- Do not flip the whole app when a field is Arabic; only the field.

### 6.3 Validation

- Validate by Unicode code points/grapheme clusters, not bytes.
- Do not reject Arabic, Cyrillic or CJK characters in name/note fields.
- Do not apply Latin-only regex to names.
- Trim leading/trailing whitespace except where it is meaningful; preserve internal line breaks in notes.
- Phone/email/VIN validation is a hint on the client; the server is authoritative.
- Error messages are localized and appear below the field; never replace the user’s text.

### 6.4 Keyboard behaviour

- Android and iOS control the system keyboard. The app **cannot guarantee** automatic keyboard-language switching.
- The app can:
  - set `keyboardType` (phone, email, number, text),
  - set `textDirection` and `textAlign`,
  - request an input method where the platform supports it,
  - show a short help link explaining how to add/switch a keyboard in device settings.
- The app must **not** build a custom keyboard in V1.
- Do not promise “Arabic keyboard opens automatically”.
- Test on real Android and iOS devices with English, Arabic, Russian and Chinese keyboards.
- If a user types Latin letters into an Arabic-intended field, preserve what they typed and show the detected direction; do not silently convert.

---

## 7. Localization architecture

### 7.1 Fixed UI text

- Use Flutter `flutter_localizations` + `intl` + ARB files.
- One ARB file per locale: `app_en.arb`, `app_ar.arb`, later `app_ru.arb`, `app_zh_Hans.arb`.
- No concatenated sentences. Use placeholders, plurals and selects.
- No user-facing string hardcoded in a widget.
- Keep technical terms consistent across app, report and PDF (glossary).
- Arabic translations reviewed by a native Arabic reviewer with automotive knowledge.

### 7.2 Dynamic catalogue content

- Categories, item labels, instructions, result labels, severity labels, reasons, recommendations and disclaimers come from the server (`localized_content`), not ARB.
- Each translatable field has a locale row and a version.
- Fallback order: requested locale → `en` → explicit “translation missing” marker in internal/admin views.
- **Publishing a master item requires English and Arabic.** A missing required translation blocks publish. Russian/Chinese are optional until those interfaces launch.
- The report snapshot stores the exact translated strings used at finalization; later catalogue edits never change an old report.

### 7.3 Report language

- The report snapshot stores all approved translations used.
- The public page renders the selected language from the snapshot; it does not fetch live catalogue rows.
- The PDF is bilingual English–Arabic. Russian/Chinese names and notes appear as entered, with the original script preserved. Optional translations are shown separately and labelled.
- Language switch on the public page must not change the report version or content, only the presentation language.

### 7.4 Fonts

- Bundle fonts with the app and the PDF renderer. Do not fetch fonts at runtime on the public report or PDF.
- Required coverage: Latin, Arabic (including shaping and diacritics), Cyrillic, CJK (at least the characters used in names/notes).
- Candidate families must have verified embedding/redistribution licences before bundling. This is a Phase 2 gate; no font is approved by this document.
- CJK fonts are large. Options: subset, separate download only when Chinese is enabled, or a system fallback with a tested result. Do not ship a full CJK font to every app by accident.
- Flutter web: explicitly configure font fallback; do not silently use `fonts.gstatic.com`.
- Test missing-glyph behaviour: a missing name glyph must not produce tofu in a report.

---

## 8. RTL content rules

### 8.1 Arabic typography

- Use a proper Arabic font with joining/shaping; never render Arabic with a Latin-only font.
- Line height must allow diacritics and descenders; do not clip.
- Do not letter-space Arabic.
- Do not justify Arabic text in a way that creates rivers; right-align is safer.
- Keep Arabic labels concise; long translations must wrap, not truncate.
- Use Arabic comma `،` and question mark `؟` in Arabic prose where appropriate; technical tokens keep ASCII punctuation.
- Lam-alef ligatures and common joins must be visually checked by a native reviewer.

### 8.2 Bilingual layouts

- **App:** one language at a time. No side-by-side labels in the technician UI; the app language controls the interface.
- **Admin master content:** side-by-side EN/AR editor with independent direction per field.
- **Public report:** one language at a time via switch. The report page may show the other language in a secondary line only where it aids trust (for example the workshop name); do not crowd the main reading flow.
- **PDF:** bilingual. Use a consistent pattern: Arabic block + English block per section, with clear language labels. Tables may use two lines per cell (AR then EN) when both are required.
- Do not mirror photos. Do not mirror the vehicle. Do not mirror maps.
- Do not place a “before/after” comparison in a mirrored order that changes meaning.

### 8.3 Tables in RTL

- Header row follows document direction.
- Numeric columns use tabular numerals and LTR values.
- Long notes wrap; never truncate a safety finding.
- Row height grows for Arabic; do not fix row height.
- Avoid icons that imply direction (arrows) in table headers unless mirrored correctly.

---

## 9. Error, validation and status text

- Error messages are localized; the machine-readable `code` is not.
- Do not build messages by concatenating translated fragments.
- Plurals use `intl` plural rules (Arabic has zero/one/two/few/many/other).
- Status labels use a consistent glossary:
  - `DRAFT` / `مسودة`
  - `SCHEDULED` / `مجدول`
  - `ASSIGNED` / `مُسند`
  - `IN_PROGRESS` / `قيد الفحص`
  - `READY_TO_FINALIZE` / `جاهز للاعتماد`
  - `FINALIZED` / `معتمد نهائياً`
  - `CANCELLED` / `ملغى`
- Do not translate `FINALIZED` as “approved by manager”; it is technician self-finalization.
- Severity labels: Minor / Moderate / Major / Safety-critical with approved Arabic equivalents. Final wording needs specialist + Arabic review.

---

## 10. Testing requirements

### 10.1 Automated

- Golden tests for every key screen in `en` and `ar`, including RTL.
- Overflow tests with long Arabic and long English strings.
- Mixed-direction unit tests for VIN, phone, date, percentage and parentheses.
- Widget tests for field direction detection and manual override.
- Tests that a VIN/phone field never accepts RTL shaping or gets mirrored.
- Tests that a missing Arabic translation blocks master-item publish (where required).

### 10.2 Manual

- Real Android and iOS devices: Arabic keyboard, English keyboard, Russian keyboard, Chinese keyboard.
- Screen reader pass in Arabic and English (TalkBack/VoiceOver).
- 200% text scale; no clipped labels or overlapping buttons.
- Public report in WhatsApp in-app browser, Chrome, Safari.
- PDF visual review by a native Arabic reader, including:
  - long Arabic paragraphs,
  - mixed Arabic/English/numbers/VIN,
  - Russian and Chinese names,
  - tables across page breaks,
  - photo gallery,
  - footers and page numbers.
- Print the public report to PDF from a browser and compare with the server PDF for content consistency.

### 10.3 Test corpus (minimum)

- Arabic paragraph of 300+ words with punctuation and diacritics.
- Arabic + English + digits in one paragraph.
- VIN, plate, phone, date and odometer inside Arabic prose.
- Parentheses, quotation marks, hyphens, slashes and commas in mixed text.
- Russian name and note in Cyrillic.
- Chinese name and note in Simplified Chinese.
- A very long unbroken VIN/URL that must not overflow.
- A note with line breaks.
- Arabic text at the start and end of a page.
- A portrait and a landscape photo with captions.

---

## 11. What not to do

- Do not translate a person’s name or transliterate it into another script.
- Do not use Arabic-Indic digits inside a VIN, phone number or report ID.
- Do not use `left`/`right` in feature code.
- Do not mirror an entire interface with a negative scale transform.
- Do not use a Latin-only font for Arabic.
- Do not fetch fonts from a CDN at report render time.
- Do not assume the OS keyboard will switch language automatically.
- Do not store a report’s English text in one field and Arabic in a concatenated string; store them as separate localized values with a locale tag.
- Do not machine-translate a safety finding and present it as confirmed.
