# Phase 0 Research Findings

**Project:** TrueReport / Partner-Workshop Vehicle Inspection and Public Report Platform  
**Document:** 01-research-findings.md  
**Research date:** 3 November 2026  
**Status:** Phase 0 deliverable for product-owner review. This document does not approve scope and does not authorise code.

---

## 1. Purpose and reading guide

This document records what was actually observed during Phase 0 research. It deliberately separates:

- **[VERIFIED]** — confirmed in a source that was opened or read; the source is cited.
- **[COMPARISON]** — an observation about another product, not a requirement for TrueReport.
- **[RECOMMENDATION]** — our proposal, not yet approved.
- **[ASSUMPTION]** — something we had to assume; it needs product-owner confirmation.

Source IDs such as **[S2]** refer to the Source Register in section 10.

The companion documents are:

- `02-confirmed-scope.md` — plain-English scope and exclusions.
- `03-roles-and-permissions.md` — role and permission matrix.
- `04-workflows.md` — workflows, statuses and Mermaid diagrams.
- `05-version-lock-table.md` — preliminary current versions and licences.
- `06-assumptions-and-open-questions.md` — decisions needed.
- `07-risk-register.md` — initial risk register.
- `08-roadmap-and-gates.md` — phases, gates, tests.
- `09-spike-plan.md` — plan only for the Arabic PDF and public-report spikes.
- `10-consistency-check.md` — contradictions and gaps against `master.md`.

---

## 2. Method and limitations

### 2.1 What was done

- Read `master.md` completely.
- Inspected the project folder without changing or deleting existing files.
- Tried to open the supplied AutoHub report URL and public AutoHub pages.
- Inspected the local `Inspection.pdf`.
- Opened official documentation and registries for Flutter, Dart, Melos, Spring Boot, Spring Modulith, MySQL, Flyway, JobRunr, MinIO, WhatsApp and the W3C.
- Queried pub.dev and Maven Central for current versions and licences.
- Opened UAE and India official legal starting points.

### 2.2 Limitations that affect confidence

- Web pages were read as HTML/text. **No visual rendering, screenshot comparison, mobile emulation or screen-reader run was performed.** Layout observations are therefore limited.
- Some JavaScript-rendered tab content is not present in the fetched HTML. We do not infer hidden content.
- The AutoHub page was reachable, but Meta’s WhatsApp developer pages returned HTTP 400 errors to this environment. WhatsApp findings rely on the public WhatsApp Business Policy and a Meta documentation page captured through search.
- The local PDF’s Arabic text extraction is garbled. That is an extraction artefact and does not prove the PDF looks wrong. No visual PDF inspection was performed.
- Version numbers are live values on 3 November 2026. They will change. They are **not** the final Phase 2 lock.
- Legal findings are starting points only. They are not legal advice and do not claim compliance.

---

## 3. Access result: the AutoHub reference report

### 3.1 Did the page open?

**[VERIFIED]** The exact URL `https://autohub.ae/reports/inspections/M7V3bvKE3J1g` returned HTTP 200 and approximately 97 KB of HTML on 3 November 2026 [S2]. The page title is “AutoHub - Purchase with confidence”.

The first attempt through a PowerShell web request failed with a transport-level EOF error. A direct HTTP fetch then succeeded. This is recorded because access reliability may matter if the link is opened from a messaging app or a restrictive network.

### 3.2 What was directly observed on the exact report page

**[VERIFIED]** The fetched page contains:

| Observed item | Observation |
|---|---|
| Page language | `<html lang="en">`; no Arabic interface was observed in the fetched HTML. |
| Indexing | `<meta name="robots" content="noindex">` and `<meta name="googlebot" content="noindex">`. |
| Link previews | No `og:` or `twitter:` metadata was found in the fetched HTML. |
| Report heading | A report reference number and an inspection date were displayed. |
| Navigation | Tabs or section links: Summary, Photos, Reports, Specs, Checklist, Damage. |
| Summary | Vehicle specification summary, odometer, gearbox, fuel, drivetrain, report reference, emirate, chassis number, model year, engine size, keys, exterior/interior colour, wheels, steering side, doors/seats, warranty and service-history text. |
| Inspector summary | Grouped comments under Body and Mechanical, plus recommendations and a defect note. |
| Contact | “Call Now” and “WhatsApp” actions with an AutoHub operations phone number and opening hours. |
| Photo gallery | Counts by group: Exterior, Interior, Tires, Mechanical, Damages. On the exact page the counts were 56, 30, 8, 39 and 1. |
| Photo delivery | Gallery images were served from an S3-compatible bucket using time-limited signed URLs (`X-Amz-Expires=3600` was visible). |
| Actions | Print and share controls were present. The share control uses the browser Web Share API or copies the URL. |
| Print export | The page’s client script checks for a `pdf_export` query parameter and hides a coupon section; print CSS and a print button are present. |

**[COMPARISON] Privacy observation:** the exact page displayed a customer name and a full chassis number in the public HTML. Those values are deliberately **not reproduced in this document**. A sample page on the same site masked the chassis number as `**********` [S3]. This shows that the public/private boundary can differ by report or configuration. TrueReport’s requirement is stricter: no customer name, email, phone, precise location, full VIN or registration details by default.

**[COMPARISON] Content note:** the page shows a consumer-facing contact call to action. That is a different business model from TrueReport, where the partner workshop owns the customer relationship and the report should not become a lead-generation portal.

### 3.3 What could not be verified on AutoHub

The following were **not** verified and must not be presented as facts:

- The visual layout on mobile and desktop.
- Whether the Checklist, Reports, Specs and Damage tabs render correctly for this report. The fetched HTML contained Summary and Gallery sections only; the tab links point to sections that were not present in the server response.
- The full checklist wording, number of checks, pass/fail logic, severity model and “not checked” reasons for this report.
- Whether the PDF was available for this exact report.
- Whether an Arabic version or language switch exists. No switch was observed in the fetched HTML.
- Whether a consent record or public-link consent was captured.
- Whether the link can be revoked, when it expires, or whether an earlier version existed.
- Whether the page is actually excluded from search engines beyond the observed `noindex` meta tag.
- Whether photos are watermarked, resized or stripped of EXIF before public display.
- Whether the page works inside WhatsApp, Instagram or other in-app browsers.

**Evidence needed:** screenshots of the report on a phone and desktop, screenshots of each tab, the report PDF, an Arabic version if it exists, and a short screen recording of opening the link from WhatsApp. These should come from the product owner or a person with authorised access.

### 3.4 AutoHub service-page claims

**[VERIFIED]** AutoHub’s public inspection service page states [S4]:

- A “248-point” pre-purchase inspection.
- Mechanical, electrical and OBD diagnostics; suspension, steering and chassis; brakes, tyres and wheels; interior and exterior; photos and videos; underbody and structural checks; engine, gearbox and cooling; road test when the seller approves; vehicle specifications and a condition report; report explanation and expert support.
- “100+ photos & videos”.
- Inspection duration of 45 to 75 minutes depending on the vehicle.
- Report delivery within 4 to 6 hours in the FAQ.
- A PDF version “can be provided upon request”.
- A complimentary VIN check for UAE-registered vehicles; official accident history is only available through the RTA paid service.

**[COMPARISON]** This is a consumer pre-purchase inspection product. It is useful as a benchmark for evidence volume, report clarity and disclosure, but it is not the same operating model as TrueReport. TrueReport is a B2B tool used by partner workshops, with no customer app, no customer booking portal and no in-platform payment.

### 3.5 AutoHub sample report

**[COMPARISON]** The public sample page `https://autohub.ae/reports/sample/inspection` [S3] showed a Maserati GranTurismo sample with:

- A masked chassis number.
- A vehicle valuation certificate block.
- Before-test-drive and after-test-drive OBD reports, battery report and tyre report with download links.
- A photo gallery with group counts.
- In a search-provider text extraction of the same page, checklist groups with pass counts (for example “Safety 11/11 Passed”) and a vehicle damage assessment map with a legend.
- A detailed limitations and disclaimer section in the text extraction.

**Limitation:** the live fetched HTML for the sample also contained only Summary and Gallery sections. The checklist and damage content came from a search-provider extraction, not from a visually confirmed live tab. We therefore treat the detailed checklist as a **comparison observation**, not as verified live behaviour.

---

## 4. Local reference PDF: `Inspection.pdf`

### 4.1 What the file is

**[VERIFIED] Local file observation.** `Inspection.pdf` (about 3.87 MB) is **not** an AutoHub report. It is an “AutoScore” “Premium Inspection Report” for a Honda e:NS1, dated 18 April 2024, with Jordan contact details [S49].

Metadata observed:

| Field | Value |
|---|---|
| PDF pages | 18 |
| Footer page numbering | Up to “20 of 20” |
| Creator | `wkhtmltopdf 0.12.4` |
| Producer | `PDFsharp 1.50.4845` (original Qt 4.8.7) |
| Creation date | 18 April 2024 |
| Title / language metadata | Empty / null |

**[COMPARISON]** The document demonstrates one possible bilingual report pattern:

- Arabic and English labels side by side.
- A condition chart with Good / Average / Bad counts by system.
- Car information, records, road test and agreement pages.
- Numbered photo galleries for body, chassis, brakes, powertrain, electrical, suspension, AC and other systems.
- A final agreement/terms page in Arabic.

**[VERIFIED] Technical caution:** extracting Arabic text from the PDF produced disconnected and garbled characters. This is a font/encoding extraction artefact, not proof that the visible PDF is broken. No visual PDF inspection was performed. The file must not be used as evidence that Arabic shaping is correct.

**Relevance to TrueReport:** it shows that an HTML-to-PDF pipeline (`wkhtmltopdf`) has been used for a bilingual vehicle report. It does **not** prove that the current version of that pipeline, or any particular library, meets TrueReport’s Arabic, font fallback or multi-page requirements. That is why the Arabic PDF spike in `09-spike-plan.md` is mandatory.

---

## 5. Competitor and comparable-product observations

All rows in this section are **[COMPARISON]** unless marked otherwise. They describe what the cited source says; they do not define TrueReport requirements.

| Product / service | What the source confirms | Relevance to TrueReport |
|---|---|---|
| **AutoHub** (UAE) | 248-point pre-purchase inspection; 100+ photos/videos; OBD before/after; damage map; report in 4–6 hours; PDF on request; public report page with noindex, photo gallery and contact CTA; sample report masks VIN but the exact report displayed a customer name and full chassis number [S2][S3][S4]. | Strong benchmark for evidence volume, report navigation and public presentation. Its consumer lead-generation model and its public display of customer/VIN data are deliberately not copied. |
| **dubizzle cars inspection** (UAE) | Two packages: QualityAssist 120-point and QualityAssist Pro 240-point; AED 299 and AED 499 excluding 5% tax; online booking and payment; report “within minutes”; mobile or service-centre inspection; public sample report shows a 8.8/10 score and percentage scores by system [S6][S7]. | Benchmark for package naming and coverage. TrueReport explicitly avoids a single unexplained condition score as the primary summary. Its consumer booking/payment flow is out of scope. |
| **dubizzle public report** | The public report page had `<html lang="en" dir="ltr">`, a visible English/Arabic language choice, full VIN, engine number and plate number in the public HTML, percentage scores and a “do not solely rely” disclaimer [S7]. | Shows a different privacy posture and a score-led presentation. TrueReport requires public-field minimisation and coverage/findings rather than a headline score. |
| **Tasjeel / RTA** (Dubai) | RTA’s vehicle inspection is a mandatory roadworthiness inspection for registration, renewal or export; output is a Vehicle Technical Inspection Certificate valid for 30 days; appointment booking is mandatory at most centres; expected inspection time for a light vehicle is 32 minutes [S8]. Tasjeel also offers a “Comprehensive Vehicle Test” for buyers and sellers, including a detailed inspection and road test, but it is not a digital B2B report product [S9]. | Important boundary: TrueReport is **not** an official RTA/Tasjeel certificate and must never imply that it is. The report must say it records a vehicle at a point in time within a defined scope. |
| **AutoLeap** (digital vehicle inspection software) | Digital checklists; photos, video and notes; VIN scan; colour-coded statuses; customer approval links by text or email; recommendations; repair orders and invoices; AI-generated notes and voice capture [S10]. | Benchmark for technician workflow and evidence capture. Customer approvals, payments, repair orders and AI are out of scope for TrueReport V1. |
| **Shopmonkey** (shop management + DVI) | Inspection templates; attach inspections to repair orders; mobile app; photos/videos/notes; send inspection links to customers; customer e-signatures; repair-order and payment workflow [S11]. | Benchmark for template reuse and mobile capture. The integrated shop-management, approval and payment model is out of scope. |

### 5.1 What the comparison suggests

**[RECOMMENDATION]**

- The market treats photo evidence, a clear category structure, OBD/diagnostic attachments and a shareable link as normal expectations.
- TrueReport’s differentiator is not “more photos” by itself. It is the combination of partner-workshop ownership, a controlled master library, immutable finalized findings, genuine English/Arabic output, and a public report that does not leak customer identity.
- The 100+ point minimum in `master.md` is below the 240–248 point claims of UAE consumer inspection products. That is acceptable for V1 only if an automotive specialist confirms the library is credible for the intended service. This is an open question, not a scope change.
- A “condition score” is common in the market but conflicts with `master.md` §10. TrueReport should show coverage, findings and limitations, not a headline score.

---

## 6. Technical research

Version numbers in this section are a snapshot for Phase 0. `05-version-lock-table.md` contains the full table. Phase 2 must re-check every version and pin it.

### 6.1 Flutter and Dart

**[VERIFIED]** The current stable Flutter release on the official release feed is **Flutter 3.47.9**, with **Dart 3.13.7**, released 29 October 2026 [S12].

**[VERIFIED]** Flutter’s official internationalisation guidance uses `flutter_localizations` plus `intl`, ARB files and generated localisations. It supports locale resolution, plurals/selects, and script variants such as `zh_Hans` through `Locale.fromSubtags` [S13].

**[VERIFIED]** Flutter web renders the UI through CanvasKit or Skwasm, using WebGL/WebGPU, rather than producing a normal document DOM. Flutter’s own documentation says that text-rich, flow-based, static content such as blog articles benefits from the document-centric web model rather than Flutter’s app-centric model [S14]. This is directly relevant to the public report decision.

**[VERIFIED]** Flutter web accessibility is **opt-in for performance reasons**. The semantics tree is exposed through a special DOM layer, and users must activate an “Enable accessibility” control unless the app calls `SemanticsBinding.instance.ensureSemantics()` [S15]. This is a significant consideration for a public report that a customer may open with a screen reader.

**[VERIFIED]** Path-based URLs (`/r/abc` rather than `/#/r/abc`) require `usePathUrlStrategy` and server-side rewrite of unknown paths to `index.html` [S16].

**[VERIFIED]** Flutter web initialisation can fall back to downloading fonts from `https://fonts.gstatic.com/s/` when bundled fonts lack glyphs; this is configurable through `fontFallbackBaseUrl` [S17]. For a workshop with poor connectivity and a public report opened from WhatsApp, bundling the required fonts and avoiding runtime font downloads is important.

**[VERIFIED]** Flutter’s legacy service worker is deprecated; the documentation tells developers to remove legacy service-worker registration [S17]. Caching and first-load behaviour must therefore be designed deliberately rather than assumed.

**[RECOMMENDATION]** Keep Flutter for the technician and admin apps. Treat the public report as a separate delivery decision (Flutter Web versus server-rendered HTML) and run the spike in `09-spike-plan.md`. Do not assume Flutter Web is the automatic winner just because the rest of the client is Flutter.

**[ASSUMPTION]** Flutter has no supported API that forces the operating system to switch its keyboard language. The app can set `keyboardType`, `textDirection` and field alignment, and can show a help hint, but the final keyboard language is controlled by Android/iOS. This must be tested on real devices in Phase 5.

### 6.2 Melos and repository tooling

**[VERIFIED]** Current Melos is **8.10.0** (Apache-2.0) [S18][S19]. Melos 8 uses Dart pub workspaces: the root `pubspec.yaml` declares `workspace:` and each package declares `resolution: workspace`. The old `melos.yaml` file no longer exists in Melos 7/8. Melos 8 requires Dart SDK 3.9.0 or newer [S18].

**[RECOMMENDATION]** Update the repository layout described in `master.md` §13A.2: use a root `pubspec.yaml` with a `workspace:` list instead of `melos.yaml`. This is a documentation correction, not a scope change.

### 6.3 Flutter packages

The full list is in `05-version-lock-table.md`. Key findings:

- `go_router` is **18.1.2** (BSD-3-Clause) [S19].
- `flutter_animate` is **4.5.2** (BSD-3-Clause), last published in November 2024. It still works, but it is not actively releasing. Keep it for subtle effects and respect reduced-motion settings.
- `flutter_riverpod` is **3.4.3** (MIT); the annotation/generator packages are on 4.x. The major numbers differ by design, but the version constraints must be resolved together and tested.
- `drift` is **2.35.3** (MIT). Drift’s current setup documentation recommends `drift_flutter` **0.3.1** or `sqlite3` **3.8.0**, not `sqlite3_flutter_libs` [S20].
- `sqlite3_flutter_libs` is now **0.6.0+eol** and its own page says it is obsolete and should be removed after upgrading to `package:sqlite3` 3.x [S21]. `master.md` §13A.3.7 must be updated.
- `golden_toolkit` is **0.15.0**, last published in 2023; `alchemist` is **0.14.1** and is the better-maintained option. `master.md` already lists alchemist first.
- `photo_view` is **0.15.0** (2024); the built-in `InteractiveViewer` may be sufficient and removes a dependency.
- `exif` is **3.3.0** (2023) and `intl_phone_field` is **3.2.0** (2023). Prefer `phone_form_field` **12.0.1** for phone input and treat `exif` as a targeted, low-level dependency whose maintenance must be checked again.

### 6.4 Java, Spring and the database

**[VERIFIED]**

- Current Java LTS is **Java 25** (September 2025); Java 21 remains supported, and Java 29 is the next planned LTS [S25].
- Current stable Spring Boot is **4.1.2**; Spring Boot 4.1.2 requires at least Java 17 and is compatible with Java up to and including Java 27 [S22][S23].
- Current stable Spring Modulith is **2.1.2** [S24].
- Current stable MySQL 8.x LTS is **8.4.13** at the snapshot date. MySQL 8.4 is supported through Premier Support to April 2029 and Extended Support to April 2032 [S26][S27].
- **MySQL 8.0 reached End of Life in April 2026** [S27]. “MySQL 8.x” must therefore mean **8.4 LTS**, not 8.0.
- Current Flyway is **13.12.0**. Flyway Community supports MySQL core migration commands, and the separate `flyway-mysql` module is required [S28][S29].
- JobRunr’s current OSS release is **9.0.3**, dual-licensed **LGPL-3.0 or commercial**. The free OSS tier is limited to about 100 recurring jobs and a simple dashboard; priority queues, batches, workflow, transaction plugins and advanced dashboard features are paid Pro features [S33][S34].
- MinIO’s original open-source edition is **AGPL-3.0, archived, source-only, and no longer maintained**; MinIO says it has no new features, bug fixes or security patches. The current **AIStor Free** tier is proprietary, single-node only, and does not permit encryption at rest; distributed deployment and encryption require paid editions [S30][S31][S32].
- The MySQL Connector/J Community driver is **GPLv2 with the Universal FOSS Exception**, not a permissive licence. Oracle’s own OEM licensing page says commercial distributors that do not want GPL obligations need a commercial licence [S46][S47].

**[RECOMMENDATION]**

- Pin **Java 25 LTS**, **Spring Boot 4.1.2**, **Spring Modulith 2.1.2**, **MySQL 8.4 LTS**, and **Flyway 13.12.0** as the Phase 1/2 starting point, subject to re-verification at the Phase 2 version-lock task.
- Use the Spring Boot dependency management (BOM) for transitive versions. Do not override Hibernate, Flyway, Jackson or the MySQL driver to “latest” without a compatibility test.
- **Do not rely on MinIO for production.** It can remain a local development convenience with a pinned image, clearly marked “development only”. Production object storage must be an S3-compatible service with a maintained security posture and a clear licence. This is a change from the assumption in `master.md` §13A.9 and must be decided before Phase 2.
- Obtain legal advice on MySQL Connector/J distribution. If the server is hosted by us and never distributed, the analysis differs from shipping a Docker image to workshops. If a permissive driver is required, evaluate the MariaDB Connector/J (LGPL) or a commercial MySQL licence. Do not treat this as settled.

### 6.5 PDF generation for Arabic

**[VERIFIED]**

- **OpenHTMLtoPDF 1.0.10** (released September 2021) is LGPL-2.1-or-later. Its own README says it has **limited support for RTL and bi-directional documents**, **no support for OpenType fonts**, and was tested with OpenJDK 8, 11 and 17 [S39]. It is built on PDFBox 2.x, while current PDFBox is 3.0.8.
- **Playwright for Java 1.64.0** is Apache-2.0 and supports Chromium, Firefox and WebKit in headless mode; it requires Java 8 or later [S40]. A headless Chromium print-to-PDF path uses the browser’s own Unicode bidi and Arabic shaping stack.
- Current **Apache PDFBox** is 3.0.8 (Apache-2.0) [S19 registry data].
- The local AutoScore PDF was produced with `wkhtmltopdf 0.12.4` and `PDFsharp 1.50.4845` [S49]. That shows an HTML-to-PDF path was used, but it does not prove current Arabic quality.

**[RECOMMENDATION]**

- Treat **headless Chromium (Playwright for Java) as the default candidate** for the bilingual PDF. It is the least risky path for Arabic shaping, bidi and font fallback, at the cost of a heavier runtime.
- Keep **OpenHTMLtoPDF** as the lighter alternative only if the spike proves correct Arabic shaping, bidi and font fallback with the exact fonts and Java 25 runtime. Its 2021 release date, limited RTL statement, lack of OpenType support and PDFBox 2.x dependency are serious concerns.
- Do not choose a Dart/Flutter PDF package for the server-side report. `master.md` already rejects it for good reasons.
- The spike must use real Arabic paragraphs, mixed Arabic/English/numbers/VIN, Russian and Chinese names, long tables and many photos. It must measure visual correctness and generation cost.

### 6.6 Public report: Flutter Web versus server-rendered HTML

**[VERIFIED]** Flutter web is canvas-based, has a larger runtime and an opt-in accessibility layer [S14][S15]. Flutter’s own docs say text-rich static content is not the ideal Flutter web use case [S14].

**[RECOMMENDATION]** Run the public-report spike before committing to Flutter Web for `public_report_web`. A server-rendered HTML report is likely to be better for:

- First load from a WhatsApp link on a poor connection.
- Search-engine and link-preview control.
- Text selection, browser find, print and screen readers.
- Graceful behaviour if JavaScript fails.
- A small attack surface with no admin code.

Flutter Web may still win on shared design and code reuse. The spike must decide with measurements, not preference.

### 6.7 WhatsApp and delivery

**[VERIFIED]** WhatsApp’s Business Policy says a business may contact a person only if it has the person’s phone number/username and has received opt-in permission for subsequent messages. Outside a 24-hour customer-service window, only approved message templates may be used. The business is responsible for the opt-in method and for complying with applicable law [S35]. Meta’s documentation repeats that service messages are limited to the 24-hour window and that template messages are required outside it [S36].

**[RECOMMENDATION]**

- Record channel-specific consent, not a single generic “contact me” checkbox.
- Use a WhatsApp utility template for the report-link message, with neutral wording and no customer data in the template variables beyond what is necessary.
- Treat message delivery as a separate state machine. A delivery failure must never alter or delete the report.
- Plan a manual resend fallback and an auditable delivery log.
- Do not put full VIN, phone numbers or private findings in link previews or logs.

**[ASSUMPTION]** WhatsApp template approval, business verification and phone-number onboarding will take calendar time and must be started well before the Phase 7 pilot. The exact provider (Meta Cloud API directly or a business solution provider) is still open.

### 6.8 Arabic layout and bidirectional text

**[VERIFIED]** W3C’s Arabic & Persian Layout Requirements state that Arabic script is written right-to-left, numbers are written left-to-right, and page/document structure is also right-to-left when Arabic is the main script [S37]. W3C’s bidi tutorial recommends setting the base direction on the document, using `dir` on block elements only where needed, using `dir="auto"` for user-generated fields, and letting the Unicode Bidirectional Algorithm handle the ordering [S38].

**[RECOMMENDATION]** Apply the same principles in Flutter, HTML and PDF:

- Use logical `start/end`, not hardcoded left/right.
- Set an explicit base direction for the report and for user-entered fields.
- Keep VINs, phone numbers and other technical identifiers in an explicit LTR wrapper when they appear inside Arabic text.
- Test mixed Arabic + English + digits, parentheses and punctuation.
- Do not rely on CSS or Unicode control codes where markup/field direction is available.

### 6.9 Fonts

**[ASSUMPTION]** Candidate font families (for example IBM Plex Sans Arabic, Noto Sans Arabic and Noto Sans SC) must have their licences, glyph coverage, file size and embedding permissions verified before bundling. CJK fonts are large; the app should not ship a full CJK font to every user unless the size impact is accepted.

---

## 7. Legal and privacy starting points

**These are starting points only. They are not legal advice, and nothing in this project should claim compliance until qualified UAE counsel has reviewed the actual processing, consent wording, retention, cross-border transfers, hosting location and public-link design.**

### 7.1 UAE

**[VERIFIED]** Federal Decree-Law No. 45 of 2021 concerning the Protection of Personal Data (PDPL) was issued on 20 September 2021 and came into force on 2 January 2022 [S41]. The UAE Government portal states that it applies to processing of personal data inside or outside the country, prohibits processing without the owner’s consent except in specified cases, gives rights to correction, restriction or stopping of processing, and sets requirements for cross-border transfer and sharing [S42].

**[VERIFIED - secondary sources]** As of 2026, multiple secondary legal/compliance sources state that the PDPL Executive Regulations have not been published, and that the detailed rules on breach notification timing, cross-border transfer mechanisms and DPO thresholds are therefore not fixed. Other sources make conflicting claims. This must be verified with UAE counsel against the Official Gazette; do not rely on a blog or on a Cabinet Decision number found in a search result. [S50]

**[RECOMMENDATION]**

- Build to the PDPL’s principles now: lawful basis, specific consent, data minimisation, purpose limitation, accuracy, security, retention limits and data-subject rights.
- Record consent version, timestamp, channel, wording and who captured it.
- Treat the public report link as a disclosure of personal data. Capture specific consent for creating a publicly accessible link, separate from consent to send a message.
- Do not claim “PDPL compliant” in marketing or product text.
- Get a written legal review before real customer data is stored.

### 7.2 India

**[VERIFIED]** The Digital Personal Data Protection Act, 2023 (No. 22 of 2023) received assent on 11 August 2023 [S43]. The Digital Personal Data Protection Rules, 2025 were notified in the Gazette on 13/14 November 2025, with a phased commencement: some rules from publication, Rule 4 after one year, and Rules 3, 5–16, 22–23 after eighteen months [S44][S45].

**[RECOMMENDATION]** India is a later market. Do not design India-specific features now beyond keeping the data model and localisation flexible. Before any India pilot, obtain local legal review, verify the commencement status of each rule, and review language, inspection and operational requirements.

### 7.3 Other legal boundaries

- TrueReport is **not** an official government inspection, roadworthiness certificate or certification body. Do not use RTA, Tasjeel or “certified” language unless the workshop is authorised and the claim is factually and legally supportable.
- Do not describe the report as “independently reviewed” or “manager approved”. The technician self-finalizes.
- Do not store payment-card data anywhere. The workshop handles payment outside the platform.
- Keep original evidence private; publish only safe derivatives.
- Do not put customer phone numbers, full VINs or private report details in logs or link previews.

---

## 8. What could not be verified, and what evidence is needed

| Item | Status | Evidence needed |
|---|---|---|
| AutoHub visual layout on mobile/desktop | Not verified | Screenshots or screen recording from the product owner. |
| AutoHub Checklist/Damage/Specs tabs | Not verified in fetched HTML | Screenshots of each tab or a recording of the live page. |
| AutoHub Arabic interface/report | Not observed | Arabic report URL or screenshots; language selector behaviour. |
| AutoHub PDF for the exact report | Not downloaded | The PDF file, or confirmation that it is not available. |
| AutoHub consent/revocation/expiry behaviour | Not verified | Product walkthrough or documentation. |
| AutoScore PDF visual Arabic quality | Not verified | Rendered pages or a visual review by an Arabic reader. |
| WhatsApp template approval and onboarding details | Partly verified | Meta/provider documentation and a test business account. |
| UAE PDPL Executive Regulations status | Disputed / not verified | Counsel’s check of the Official Gazette and current guidance. |
| MinIO AIStor production cost and licence | Not verified | Quote and contract terms. |
| Flutter Web link previews and in-app browser behaviour | Not verified | Spike on real devices and messaging apps. |
| Keyboard language switching | Not verified | Real Android and iOS device tests. |
| Current package versions | Verified on 3 Nov 2026 only | Re-check at Phase 2 version lock. |

---

## 9. Key findings summary

1. **[VERIFIED]** The AutoHub reference report was reachable, and useful observations were collected, but the live tab content and visual behaviour were not fully verifiable from HTML alone.
2. **[COMPARISON]** AutoHub and dubizzle both publish more vehicle/customer detail than TrueReport allows by default. TrueReport must be deliberately stricter.
3. **[COMPARISON]** The market uses 120–248 point checklists and heavy photo evidence. TrueReport’s 100+ minimum is viable only with specialist validation.
4. **[VERIFIED]** Flutter 3.47.9 / Dart 3.13.7 are current stable; Melos 8 uses pub workspaces and no `melos.yaml`; `sqlite3_flutter_libs` is obsolete.
5. **[VERIFIED]** Spring Boot 4.1.2, Spring Modulith 2.1.2, Java 25 LTS, MySQL 8.4.13 LTS and Flyway 13.12.0 are the current starting points. MySQL 8.0 is EOL.
6. **[VERIFIED]** MinIO’s OSS edition is no longer maintained; production storage must be re-decided.
7. **[VERIFIED]** OpenHTMLtoPDF has limited RTL support and is old; headless Chromium is the default PDF candidate pending the spike.
8. **[VERIFIED]** Flutter Web is canvas-based with opt-in accessibility and weaker static-document characteristics; the public-report spike is justified.
9. **[VERIFIED]** WhatsApp requires opt-in and approved templates outside the 24-hour service window.
10. **[VERIFIED]** UAE PDPL is in force; India’s DPDP Act and 2025 Rules exist with phased commencement. Legal review is mandatory before real customer data.

---

## 10. Source register

All URLs were accessed on 3 November 2026 unless stated otherwise. Source IDs are reused in the other Phase 0 documents.

| ID | Source | URL / note |
|---|---|---|
| S1 | `master.md` (local project file) | `E:\syed_moiz_ali\bitlogix\truereport\master.md` |
| S2 | AutoHub exact reference report | https://autohub.ae/reports/inspections/M7V3bvKE3J1g |
| S3 | AutoHub public sample report | https://autohub.ae/reports/sample/inspection |
| S4 | AutoHub car inspection service page | https://autohub.ae/services/car-inspection |
| S5 | AutoHub home page | https://autohub.ae/ |
| S6 | dubizzle cars inspection | https://dubizzle.com/pro/inspection/ |
| S7 | dubizzle public inspection report example | https://dubizzle.empgautos.com/inspections/dubizzle-533a6692-48b5-4333-87aa-bb13ec76c844 |
| S8 | RTA “Apply for Vehicle Inspection” | https://www.rta.ae/wps/portal/rta/ae/home/rta-services/service-details?serviceId=454 |
| S9 | Tasjeel FAQ (Comprehensive Vehicle Test) | https://enoctasjeel.com/faq |
| S10 | AutoLeap digital vehicle inspection | https://autoleap.com/features/vehicle-inspection/ |
| S11 | Shopmonkey digital vehicle inspection | https://www.shopmonkey.io/product/digital-vehicle-inspection |
| S12 | Flutter releases feed (stable version, Dart version, date) | https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json |
| S13 | Flutter internationalisation documentation | https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization |
| S14 | Flutter web support documentation | https://docs.flutter.dev/platform-integration/web/ |
| S15 | Flutter web accessibility documentation | https://docs.flutter.dev/ui/accessibility/web-accessibility |
| S16 | Flutter web URL strategy documentation | https://docs.flutter.dev/ui/navigation/url-strategies |
| S17 | Flutter web app initialisation documentation | https://docs.flutter.dev/platform-integration/web/initialization |
| S18 | Melos getting started / pub workspaces | https://melos.invertase.dev/getting-started |
| S19 | pub.dev package API and score/licence data | `https://pub.dev/api/packages/{package}` and `https://pub.dev/api/packages/{package}/score` |
| S20 | Drift setup documentation | https://drift.simonbinder.eu/setup/ |
| S21 | `sqlite3_flutter_libs` package page (obsolete/EOL notice) | https://pub.dev/packages/sqlite3_flutter_libs |
| S22 | Spring Boot project page (version 4.1.2) | https://spring.io/projects/spring-boot |
| S23 | Spring Boot system requirements | https://docs.spring.io/spring-boot/system-requirements.html |
| S24 | Spring Modulith project page (version 2.1.2) | https://spring.io/projects/spring-modulith |
| S25 | Oracle Java SE support roadmap | https://www.oracle.com/java/technologies/java-se-support-roadmap.html |
| S26 | MySQL release models (LTS/Innovation) | https://blogs.oracle.com/mysql/mysql-release-models-lts-innovation-and-single-release |
| S27 | MySQL 8.4 reference manual: releases and support | https://dev.mysql.com/doc/refman/8.4/en/mysql-releases.html |
| S28 | Flyway supported databases and versions | https://documentation.red-gate.com/flyway/getting-started-with-flyway/system-requirements/supported-databases-and-versions |
| S29 | Flyway editions / commercial licensing FAQ | https://flywaydb.org/faq/1000 |
| S30 | MinIO pricing and licence FAQ | https://www.min.io/pricing |
| S31 | MinIO GitHub repository (archived, licence, source-only notice) | https://github.com/minio/minio |
| S32 | MinIO AIStor Free Tier Licence Agreement | https://www.min.io/legal/aistor-free-agreement |
| S33 | JobRunr licence terms | https://www.jobrunr.io/en/licensing/info/ |
| S34 | JobRunr pricing and OSS limits | https://www.jobrunr.io/en/pricing/ |
| S35 | WhatsApp Business Policy (opt-in, templates, 24-hour window) | https://whatsappbusiness.com/policy/ |
| S36 | Meta WhatsApp documentation: sending service/template messages | https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/send-messages |
| S37 | W3C Arabic & Persian Layout Requirements | https://www.w3.org/TR/alreq/ |
| S38 | W3C tutorial: creating HTML pages in Arabic and other RTL scripts | https://www.w3.org/International/tutorials/bidi-xhtml/index.en |
| S39 | OpenHTMLtoPDF repository and README | https://github.com/danfickle/openhtmltopdf |
| S40 | Playwright for Java installation documentation | https://playwright.dev/java/docs/intro |
| S41 | UAE Federal Decree-Law No. 45 of 2021 (official legislation portal) | https://www.uaelegislation.gov.ae/en/legislations/1972 |
| S42 | UAE Government data protection laws page | https://u.ae/en/about-the-uae/digital-uae/data/data-protection-laws |
| S43 | India Digital Personal Data Protection Act, 2023 (MeitY PDF) | https://www.meity.gov.in/static/uploads/2024/06/2bf1f0e9f04e6fb4f8fef35e82c42aa5.pdf |
| S44 | India Digital Personal Data Protection Rules, 2025 (MeitY) | https://www.meity.gov.in/documents/act-and-policies/digital-personal-data-protection-rules-2025-gDOxUjMtQWa |
| S45 | PIB release on DPDP Rules, 2025 | https://www.pib.gov.in/PressNoteDetails.aspx?lang=2&ModuleId=3&NoteId=156054&reg=3 |
| S46 | MySQL commercial licensing / OEM page | https://www.mysql.com/about/legal/licensing/oem/ |
| S47 | MySQL Connector/J 26.10.0 licence information | https://downloads.mysql.com/docs/licenses/connector-j-26.10-gpl-en.pdf |
| S48 | Maven Central metadata (versions and POM licences) | `https://repo1.maven.org/maven2/{group/path}/{artifact}/maven-metadata.xml` |
| S49 | Local `Inspection.pdf` (AutoScore sample) | Local file; metadata extracted with a PDF parser |
| S50 | Secondary commentary on UAE PDPL Executive Regulations status | Examples: https://arqam360.com/questions/are-the-uae-pdpl-executive-regulations-issued ; https://orentara.com/en/insights/uae-pdpl-executive-regulations-status ; https://www.businessdubai.ae/blogs/uae-pdpl-data-protection . These are secondary sources and conflict with other claims; treat as unverified and confirm with counsel against the Official Gazette. |

---

## 11. Approval status

This document is a **Phase 0 research record**. It does not approve the scope, the versions, the PDF engine, the public-report approach, the object-storage provider or any legal position. Those decisions are listed in `06-assumptions-and-open-questions.md` and `10-consistency-check.md`.

**No application code was written. No Flutter or Java project was created. Phase 1 was not started.**
