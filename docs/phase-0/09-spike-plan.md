# Spike Plan (Plan Only)

**Project:** TrueReport  
**Document:** 09-spike-plan.md  
**Status:** Plan only. No spike code has been written. These spikes are Phase 1 work and require Phase 0 approval.

---

## 1. Purpose

Two technical questions can change the architecture and the customer experience. They must be answered with evidence before Phase 2 builds the wrong thing:

- **Spike A:** Which Arabic-capable PDF engine should generate the bilingual report?
- **Spike B:** Should the public report be Flutter Web or server-rendered HTML?

Both spikes are **throwaway experiments**. They do not become production code. They produce measurements, sample artefacts and a written recommendation (ADR).

---

## 2. Guardrails

1. Use **fake customer and vehicle data** only. No real customer data.
2. Do not add production dependencies or migrations from a spike.
3. Keep spike code in an isolated folder/branch that will not be merged into the product.
4. Do not copy AutoHub, dubizzle, AutoScore or any competitor assets, code or branding.
5. Do not buy providers or sign contracts during the spike unless the product owner approves.
6. Record negative results. A failed spike is a successful risk reduction.
7. Timebox each spike. If the timebox expires, write down what was learned and escalate; do not quietly extend.
8. The product owner reviews the outputs and records the decision.

---

## 3. Spike A — Arabic PDF engine comparison

### 3.1 Question

Which engine produces a correct, maintainable, bilingual English–Arabic report PDF for TrueReport at an acceptable runtime cost?

### 3.2 Options

| Option | Engine | Why consider it | Main concern |
|---|---|---|---|
| **A** | Headless Chromium via Playwright for Java, rendering a dedicated print HTML template | Browser-grade Unicode bidi, Arabic shaping, font fallback and CSS layout; one design can be shared with the public web report | Heavier runtime; browser binary and OS dependencies; memory; security updates |
| **B** | OpenHTMLtoPDF 1.0.10 with PDFBox | Pure Java, lighter deployment | Last release 2021; README says limited RTL/bidi; no OpenType fonts; PDFBox 2.x; Java 25 compatibility unproven |
| **C** | Dart/Flutter PDF package | Shared Dart skills | Rejected for server-side PDF; weaker Arabic shaping and server integration |

**Default candidate:** Option A, subject to the spike.

### 3.3 Test corpus

The corpus must be realistic, not a “hello world”. It should include:

#### Text and direction

- Long Arabic paragraphs (at least 300 words) with normal punctuation.
- Mixed Arabic + English + digits in one paragraph.
- Arabic text containing a VIN, plate number, phone number and date that must remain LTR and correctly ordered.
- Arabic-Indic digits and Western digits in separate samples.
- Parentheses, quotation marks, hyphens, slashes and commas in mixed text.
- Lam-alef ligatures and common Arabic letter joins.
- Arabic with diacritics (harakat) in at least one sample.
- Justified Arabic text and right-aligned text.
- Arabic lists (bulleted and numbered) and RTL table headers.
- Russian customer name and notes in Cyrillic.
- Simplified Chinese customer name and notes.
- A mixed line such as: Arabic sentence + “VIN WUAZZZ…” + “2022” + Arabic continuation.
- A customer name entered in Latin script with an Arabic note, and vice versa.

#### Report structure

- Cover page with report ID, version, date, workshop and vehicle summary.
- 100+ checklist rows across at least 8 categories.
- Category headers, item labels, result, severity, note, recommendation and “not checked” reason.
- A table with long notes that must wrap across lines and pages.
- Repeated table headers and page footers with report ID and version.
- Page numbers.
- A summary/coverage section.
- A limitations/disclaimer section.
- A photo gallery with at least 20 photos, captions and item links.
- A mixed-language appendix.

#### Volume and edge cases

- 10, 20 and 30-page variants.
- At least one table that breaks across a page boundary.
- A long unbroken token (VIN or URL) that must not overflow.
- Missing optional fields.
- A note with line breaks.
- A very long defect description.
- A photo with a portrait and a landscape orientation.
- A missing image (fallback behaviour).
- Arabic text at the start and end of a page.

### 3.4 Measurements

| Dimension | What to measure |
|---|---|
| Arabic correctness | Count of visible shaping, joining, ligature, bidi, punctuation and number-order errors, reviewed by a native Arabic reader. |
| Font coverage | Missing glyphs/tofu for Arabic, Cyrillic and Chinese; whether fonts are embedded. |
| Layout | Overflow, clipped text, orphan headers, broken tables, page-break quality, repeated headers/footers. |
| Text integrity | Can text be selected, copied and searched? Is the extracted text in logical order? |
| Metadata | PDF title, author, language, report ID/version. |
| Performance | Generation time p50/p95 for 10/20/30 pages; peak memory; concurrent renders (1, 2, 4). |
| Output | File size; page count; image quality; deterministic repeat render. |
| Operations | Install size; OS dependencies; container image size; startup time; health checks; security update process. |
| Licence | LGPL/Apache/proprietary obligations; font licences. |
| Accessibility (optional) | Tagged PDF / reading order, if the business requires accessible PDFs. |

### 3.5 Pass/fail criteria

**A candidate passes only if all of the following are true:**

1. A native Arabic reviewer finds **zero visible shaping, joining, ligature, bidi or number-order errors** in the core corpus.
2. VINs, phone numbers and dates inside Arabic text are rendered LTR and in the correct order.
3. Russian and Chinese names/notes render without missing glyphs.
4. Report ID and version appear on every page.
5. Tables with long text do not clip or overflow.
6. Page breaks do not split a row in a way that makes it unreadable.
7. Fonts are embedded; no runtime network font fetch is required.
8. Generation is deterministic for the same input.
9. The licence is acceptable for commercial use.
10. The runtime can be operated on the chosen server (memory, concurrency, restart, monitoring).

**Recommended targets (to be confirmed after baseline):**

- 20-page report with 20 photos: p95 generation under 15 seconds on the target server class.
- Peak memory under the server’s safe worker budget.
- No external network calls during rendering.
- Output file size suitable for email or a download link; exact limit decided after measuring.

If Option B fails any of criteria 1–3, it is rejected for V1. If Option A fails operations or cost criteria, the team must escalate rather than ship a broken Arabic report.

### 3.6 Environment

- Java 25 runtime.
- Isolated Linux container matching the intended production class.
- Bundled fonts (candidate families verified for licence and coverage).
- Fake data only.
- Playwright 1.64.0 + Chromium for Option A.
- OpenHTMLtoPDF 1.0.10 + PDFBox for Option B.
- No production database or customer data.

### 3.7 Timebox and roles

**Timebox:** 3–5 working days.

| Role | Responsibility |
|---|---|
| Technical lead | Owns the spike, environment and ADR. |
| Java developer | Builds the two render paths and measurement harness. |
| Designer | Provides the print HTML/CSS template and checks layout. |
| Native Arabic reviewer | Reviews the outputs and logs defects. |
| Operations/security | Reviews runtime, container, patching and licence. |
| Product owner | Reviews samples and accepts the recommendation. |

### 3.8 Artefacts

- Sample PDFs from both engines for 10/20/30-page variants.
- Screenshots of the worst defects.
- A defect log with severity and page references.
- A measurement sheet (time, memory, size, concurrency).
- A licence note for the engine and fonts.
- A one-page recommendation and an ADR.
- A list of what the spike did **not** prove.

### 3.9 Risks

- Arabic review may be subjective; use a written checklist and two reviewers if possible.
- Font licensing may block a preferred font.
- Chromium may be heavy for the target server.
- OpenHTMLtoPDF may fail on Java 25 or PDFBox 3 classpath.
- A 20-page report with photos may be slower than the target; adjust the photo policy, not the correctness bar.
- The spike may reveal that the report design needs to change (for example, fewer photos per page).

### 3.10 Decision

At the end of the spike, record one of:

- **A selected:** headless Chromium.
- **B selected:** OpenHTMLtoPDF, with evidence that Arabic is correct.
- **Neither selected:** escalate; do not ship a report with broken Arabic.

Write the decision as an ADR and update D5.

---

## 4. Spike B — Flutter Web versus server-rendered HTML for the public report

### 4.1 Question

Which delivery approach gives the best first load, reliability, accessibility and link behaviour for a customer who opens a report link from WhatsApp, SMS or email?

### 4.2 Options

| Option | Approach | Why consider it | Main concern |
|---|---|---|---|
| **A** | Flutter Web public report | Shared Flutter design system and code; one client stack | Canvas-based rendering; larger first load; opt-in accessibility; weaker text selection/find/SEO; link previews need a server shell |
| **B** | Server-rendered HTML report from the Java server, with minimal JavaScript | Small first load; document semantics; text selectable/findable; works without JS; easy neutral metadata and caching | A second UI implementation; design consistency must be maintained |
| **C** | Hybrid: server-rendered shell + Flutter island | Could combine benefits | Complexity; not recommended for V1 unless A and B both fail |

**Default candidate:** Option B for the public report, unless the spike shows Flutter Web meets all critical criteria at acceptable cost. The rest of the product remains Flutter.

### 4.3 Test scenarios

#### Devices and browsers

- Low-end Android phone (representative workshop/customer device).
- Mid-range Android.
- iPhone (current and one older model).
- Desktop Chrome, Safari and Edge.

#### Entry paths

- Direct link from WhatsApp.
- WhatsApp in-app browser.
- Instagram/Facebook in-app browser, if accessible.
- SMS link.
- Email link.
- Copied link pasted into a browser.
- Link with an invalid token.
- Link with a revoked token.

#### Network

- Wi-Fi.
- 4G.
- Throttled 3G / high latency.
- Slow or blocked font CDN.
- JavaScript blocked or failed.
- CDN cache hit and miss.

#### Content

- A realistic 20-page report with 100+ rows and 20+ photos.
- Long Arabic and English text.
- Mixed Arabic/English/numbers/VIN.
- Russian and Chinese names.
- A large photo gallery.
- A report with missing optional fields.
- A report with “not checked” reasons.

#### Accessibility and document behaviour

- VoiceOver (iOS), TalkBack (Android), NVDA/JAWS (Windows), VoiceOver (macOS).
- Keyboard-only navigation.
- Text selection and copy.
- Browser find (Ctrl/Cmd+F).
- Zoom to 200%.
- High contrast / dark mode.
- Print to PDF.
- Screen-reader reading order.

#### Sharing and metadata

- WhatsApp link preview.
- iMessage/email preview.
- Search engine `noindex` check.
- Neutral title/description with no customer data.
- Referrer policy.

### 4.4 Measurements

| Dimension | What to measure |
|---|---|
| First load | TTFB, FCP, LCP, TBT/INP, time to interactive. |
| Transfer | Total JS/WASM, CSS, fonts, images; number of requests. |
| Reliability | Success rate in in-app browsers; blank-page rate; JS error rate. |
| Accessibility | Screen-reader completeness, keyboard access, focus order, contrast. |
| Document behaviour | Text selection, copy, find, print, zoom. |
| Link preview | What WhatsApp/email show; whether any private data leaks. |
| No-JS | Does the core report remain readable? |
| Arabic/RTL | Shaping, direction, mixed text, numerals. |
| Cache | CDN cacheability; revocation behaviour; stale content risk. |
| Cost | Server CPU/memory; CDN bandwidth; build complexity. |
| Development | Effort to build and maintain; design consistency. |

### 4.5 Pass/fail criteria

**Critical criteria (any failure rejects the option):**

1. The report opens reliably from WhatsApp on Android and iPhone.
2. The customer can read the report on a throttled connection without an unreasonable wait.
3. Arabic shaping and RTL are correct.
4. A screen reader can read the report content in a sensible order.
5. Text can be selected and found in the browser.
6. The report can be printed to PDF legibly.
7. Link previews contain no customer name, phone, VIN or findings.
8. An invalid/revoked link shows a neutral message.
9. The public page contains no admin code or private fields.
10. The page is not indexed.

**Recommended targets (to be confirmed after baseline):**

- LCP under 2.5 seconds on emulated 4G for the first report view.
- Initial transfer under 1 MB excluding lazy-loaded photos.
- No-JS core content readable for Option B (Option A is expected to fail).
- Zero critical accessibility violations in a manual + automated review.
- No private data in the HTML before authentication/consent checks.

If Flutter Web fails any critical criterion, choose server-rendered HTML. If server-rendered HTML fails a critical criterion, escalate; do not ship a report the customer cannot read.

### 4.6 Environment

- A throwaway report page with fake data.
- Real devices on real mobile networks if possible; emulation for repeatability.
- Lighthouse/WebPageTest and browser dev tools.
- Screen readers and keyboard testing.
- No production data.

### 4.7 Timebox and roles

**Timebox:** 3–5 working days.

| Role | Responsibility |
|---|---|
| Frontend lead | Builds both variants and the measurement harness. |
| Backend developer | Serves the SSR variant and neutral metadata. |
| Designer | Checks visual fidelity and RTL. |
| Accessibility reviewer | Runs screen-reader/keyboard/contrast checks. |
| Product owner | Reviews on a phone and accepts the recommendation. |
| Operations | Reviews caching, CDN and revocation. |

### 4.8 Artefacts

- Screen recordings from WhatsApp on Android and iPhone.
- Lighthouse/WebPageTest reports.
- Screenshots of the report in both variants.
- Accessibility findings and fixes.
- Link-preview screenshots.
- A measurement sheet.
- A one-page recommendation and an ADR.
- A list of what the spike did **not** prove.

### 4.9 Risks

- In-app browsers behave differently from Chrome/Safari.
- Emulated 3G is not the same as a real workshop/customer network.
- Flutter Web version changes may change results.
- SSR introduces a second UI to maintain.
- Link previews are controlled by the messaging app and may change.
- Revocation/caching can conflict.
- A spike page may not represent the final report complexity.

### 4.10 Decision

At the end of the spike, record one of:

- **A selected:** Flutter Web, with evidence that it meets all critical criteria.
- **B selected:** server-rendered HTML, with evidence of better first load/accessibility/document behaviour.
- **Hybrid selected:** only with a clear reason and an estimate of the extra complexity.
- **Neither selected:** escalate; do not ship a public report that fails the customer.

Write the decision as an ADR and update D4.

---

## 5. Shared decision-record template

For each spike, record:

| Field | Content |
|---|---|
| Decision | What was chosen. |
| Date | When. |
| Owner | Who accountable. |
| Context | The question and constraints. |
| Options considered | A/B/C and why. |
| Evidence | Measurements, samples, reviewer notes. |
| Decision | Chosen option and rationale. |
| Consequences | What becomes easier/harder; new risks. |
| Follow-ups | What must be done before production. |
| What was not proven | Limitations. |

---

## 6. What these spikes do not decide

- The final report design or content.
- The final font family.
- The production server size.
- The final object-storage provider.
- The WhatsApp/SMS/email providers.
- The legal consent wording.
- The exact photo limits.

Those remain separate decisions in `06-assumptions-and-open-questions.md`.

**No spike code has been written. Phase 1 has not started.**
