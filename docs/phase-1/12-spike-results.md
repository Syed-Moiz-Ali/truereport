# Spike Results

**Project:** TrueReport  
**Document:** 12-spike-results.md  
**Date:** 3 November 2026  
**Status:** Measured results from isolated spikes under `spikes/`. These are experiments, not production code.

---

## 1. Summary

| Spike | Question | Result | Recommendation | Decision status |
|---|---|---|---|---|
| **A** | Arabic-capable PDF engine | Chromium rendered Arabic, mixed text, Russian and Chinese correctly; OpenHTMLtoPDF produced broken Arabic shaping/bidi | **Headless Chromium** (Playwright for Java) | D5 Pending product-owner approval |
| **B** | Public report: Flutter Web vs server-rendered HTML | SSR delivered a small, no-JS, semantic document; Flutter Web required a large canvas runtime and failed text/document/accessibility checks in this harness | **Server-rendered HTML** | D4 Pending product-owner approval |
| **C** | Production object storage | MinIO OSS cannot be used in production; several S3-compatible options exist with different residency/licence/ops trade-offs | **Managed S3-compatible storage in the UAE shortlist (AWS S3 `me-central-1` or OCI UAE); MinIO local-only** | D6 Pending product-owner approval |

**Important:** these spikes used fake data. No real customer data was processed. No production dependency, migration or code was added.

---

## 2. Spike A — Arabic PDF engine

### 2.1 Question

Which engine produces a correct, maintainable bilingual English–Arabic report PDF at an acceptable runtime cost?

### 2.2 Candidates

| Option | Engine | Result |
|---|---|---|
| A | Headless Chromium via Playwright (Node used for the spike) + print HTML/CSS | **Recommended** |
| B | OpenHTMLtoPDF 1.0.10 + `openhtmltopdf-rtl-support` + PDFBox | **Rejected for V1** — Arabic shaping/bidi visibly broken |
| C | Dart/Flutter PDF package | Not tested; rejected for the server in Phase 0 |

### 2.3 Environment (recorded honestly)

| Item | Value |
|---|---|
| OS | Windows (development workstation), not the target Linux container |
| Node | v24.11.1 |
| Playwright | 1.56.1 (Chromium bundled by Playwright) |
| PDF text extraction / raster | `pdfjs-dist` 4.10.38, `@napi-rs/canvas` 0.1.80 |
| Java | **17.0.12**, not Java 25 |
| Maven | 3.9.16 |
| OpenHTMLtoPDF | 1.0.10 + `openhtmltopdf-rtl-support` 1.0.10 |
| Fonts | Bundled `NotoNaskhArabic-Regular.ttf` (178,388 bytes); Arial and STSong from the Windows host for the OpenHTMLtoPDF run |
| Network | None required during rendering; local files only |

**The spike did not run on the intended Java 25 / Linux production class.** The PDF engine recommendation is about visual correctness and operational shape; it must be re-run in the production-like container before Phase 6.

### 2.4 Corpus

- 120 inspection rows across 10 categories.
- 20 evidence photos (placeholder images).
- Long Arabic paragraphs; Arabic + English + digits; VIN, plate, phone, date, odometer; parentheses; lists; Arabic table headers.
- Russian name (`Иван Петров`) and Simplified Chinese name (`张伟`).
- Cover, summary/coverage, detail table, gallery, limitations.
- 18 pages (Chromium) / 19 pages (OpenHTMLtoPDF).
- No 10-page or 30-page variant; no missing-image test; no 30-photo test. These remain follow-ups.

### 2.5 Method

1. `spikes/arabic-pdf/generate.mjs` writes `report.html` with the corpus.
2. `spikes/arabic-pdf/render.mjs` renders it with Playwright Chromium to `chromium.pdf`, extracts text with pdfjs, and rasterises selected pages at 2× to `shots/`.
3. `spikes/arabic-pdf/openhtmltopdf/` builds a small Java 17 Maven project and renders the same HTML to `openhtmltopdf.pdf` with `openhtmltopdf-rtl-support`.
4. Selected pages were visually reviewed as PNGs. Text extraction was recorded but **not** used as the primary correctness test.

### 2.6 Measurements

Chromium (3 runs, same machine, local file):

| Run | Load | PDF | Total | Pages | Bytes | Node RSS |
|---|---:|---:|---:|---:|---:|---:|
| 1 (cold) | 2,051 ms | 984 ms | 3,035 ms | 18 | 1,500,353 | 209 MB |
| 2 | 928 ms | 817 ms | 1,745 ms | 18 | 1,500,353 | 202 MB |
| 3 | 872 ms | 754 ms | 1,626 ms | 18 | 1,500,353 | 203 MB |
| **Median** | — | **817 ms** | **1,745 ms** | **18** | **1.50 MB** | **203 MB** |

OpenHTMLtoPDF (3 runs, Java 17, `useFastMode()`):

| Run | Render | Pages | Bytes | Used heap |
|---|---:|---:|---:|---:|
| 1 | 1,713 ms | 19 | 758,486 | 88 MB |
| 2 | 1,603 ms | 19 | 758,486 | 88 MB |
| 3 | 1,601 ms | 19 | 758,486 | 91 MB |
| **Median** | **1,603 ms** | **19** | **0.76 MB** | **~88 MB** |

**Caveats:**

- Chromium “Node RSS” is the Node process, not the separate Chromium browser process. It understates total PDF rendering memory.
- OpenHTMLtoPDF “used heap” is the JVM used heap, not peak RSS.
- Times are single local renders, not concurrent load, not a Linux container, not Java 25.
- The corpus is 18–19 pages, not the 30-page upper bound.

### 2.7 Visual findings

#### Chromium (recommended)

- Arabic is shaped and joined correctly; lam-alef and common joins look correct in the reviewed pages.
- RTL page flow is correct: headings, tables, lists and photo captions flow right-to-left.
- Mixed Arabic + English + numbers + VIN + phone + date stay in the correct order; VINs are LTR and unbroken.
- Russian (`Иван Петров`) and Simplified Chinese (`张伟`) render without tofu in the reviewed summary page.
- Long notes wrap; table header repeats; rows do not split unreadably; footer shows `TR-2026-0001 · v1` and page numbers.
- Photo gallery renders 20 images in a 4-column grid; captions show Arabic + English.
- Text extraction from the Chromium PDF shows spaced/disconnected glyphs. **This is an extraction artefact, not a visual defect.** The rasterised page image is the evidence used for the recommendation.

#### OpenHTMLtoPDF (rejected)

- Arabic letters are disconnected and, in places, visually reversed/mirrored; words such as `تقرير فحص مركبة` do not read correctly.
- The footer order is wrong (`19 of 18TR-2026-0001 | v1 | Page`), confirming bidi/ordering problems.
- Table headers and mixed-direction paragraphs are unreliable.
- The run logs explicitly report:
  - `unicode-bidi is not implemented` (multiple declarations ignored),
  - `object-fit is an unrecognized CSS property`.
- The `openhtmltopdf-rtl-support` module was present, but the output still fails the core Arabic requirement.
- Russian/Chinese glyphs may render, but that does not rescue the Arabic failure.

**Specific evidence:** `spikes/arabic-pdf/shots/chromium-page-01.png`, `chromium-page-02.png`, `chromium-page-08.png`, `chromium-page-16.png`, `chromium-page-17.png` versus `openhtmltopdf-page-01.png`, `openhtmltopdf-page-02.png`, `openhtmltopdf-page-18.png`.

### 2.8 Pass/fail against the Phase 0 criteria

| Criterion | Chromium | OpenHTMLtoPDF |
|---|---|---|
| Zero visible Arabic shaping/joining/bidi/number-order errors (visual, not native review) | Pass in reviewed pages | **Fail** |
| VIN/phone/date LTR and correct order | Pass | Unreliable |
| Russian and Chinese without missing glyphs | Pass in reviewed page | Partial; not the blocker |
| Report ID/version on every page | Pass | Broken order in footer |
| Tables with long text do not clip | Pass in reviewed pages | Partial |
| Page breaks readable | Pass in reviewed pages | Not fully verified |
| Fonts embedded, no runtime fetch | Pass (bundled font; verify all glyphs) | Partially; host fonts |
| Deterministic output | Same bytes for repeated runs in this corpus | Same bytes for repeated runs |
| Licence acceptable | Playwright Apache-2.0; Chromium licences; font licence to verify | LGPL-2.1+; acceptable, but quality fails |
| Operable on target server | Must be proven on Linux/Java 25 | Lighter, but quality fails |

### 2.9 Recommendation

**Use headless Chromium (Playwright for Java) for the bilingual PDF in V1**, behind a `PdfRenderer` interface so it can be replaced if operations fail.

**Before Phase 6, prove:**

1. Java 25 + Linux container, not Windows/Java 17.
2. 10-, 20- and 30-page reports; 20 and 30 photos; a missing image; a 200-word defect note.
3. p50/p95 generation time and peak RSS under concurrency 1, 2 and 4.
4. Deterministic output (same input → same bytes/hash) or an accepted reason for non-determinism.
5. Native Arabic reviewer sign-off on the full corpus, not only selected pages.
6. Font embedding and licences for Arabic, Cyrillic and CJK.
7. Tagged PDF/accessibility if the business requires it.
8. Chromium binary update and security patching process.
9. No external network calls during rendering.

### 2.10 What Spike A did not prove

- Java 25 compatibility.
- Linux container behaviour, memory and concurrency.
- The 10-page, 30-page or 30-photo variants.
- A native Arabic reviewer’s sign-off.
- Tagged PDF/accessibility.
- Font licence for redistribution.
- PDF/A or archival compliance.
- Real evidence photo quality and file-size impact.
- The final report design.

---

## 3. Spike B — Public report: Flutter Web vs server-rendered HTML

### 3.1 Question

Which delivery approach gives the best first load, reliability, accessibility and link behaviour for a customer opening a report link from WhatsApp, SMS or email?

### 3.2 Variants

| Variant | Implementation |
|---|---|
| **SSR** | Static server-rendered HTML + CSS, no JavaScript, 20 photos, 131 table rows, Arabic/English |
| **Flutter** | Flutter Web canvas build of the same content |
| **Flutter semantics** | Flutter Web build with `ensureSemantics()` forced on |

### 3.3 Environment

| Item | Value |
|---|---|
| Playwright | 1.56.1 |
| Axe | `@axe-core/playwright` 4.10.2 |
| Browser | Chromium headless |
| Device | Pixel 6 emulation, 390×844, DPR 2, mobile/touch |
| Network | Emulated 4G (1.6 Mbps down, 150 ms) and 3G (700 kbps down, 400 ms) |
| CPU | 4× throttling |
| Server | Local static server; no CDN |
| Runs | 3 per variant/profile |

The public report is a **local static experiment**. It is not the production Java server, not a real WhatsApp in-app browser, not a real phone, and not a screen-reader run.

### 3.4 Content

- 131 table rows, 20 photos, 13,536 characters of visible text.
- Arabic and English blocks, mixed fields.
- The Flutter build includes a canvas runtime and fetches fonts from `fonts.gstatic.com`.
- This is not a full 20-page PDF; it is a long single-page report.

### 3.5 Measurements (median of 3 unless noted)

| Metric | SSR | Flutter | Flutter + semantics |
|---|---:|---:|---:|
| Wall time to report-ready (4G) | 5,403 ms | 4,272 ms | 4,324 ms |
| Wall time to report-ready (3G) | 10,270 ms (1 run) | 5,505 ms (1 run) | not run |
| Transfer (summary) | **623 KB** | **2,841 KB** | 2,841 KB |
| Decoded body | 618 KB | 7,702 KB | 7,702 KB |
| FCP (4G) | **488 ms** | **3,696 ms** | 3,536 ms |
| LCP (4G) | 488 ms | 0 ms (not reported) | 0 ms |
| DOM/text length | 13,536 chars | 0 chars | 1,216 chars |
| Table rows in DOM | **131** | **0** | **0** |
| Canvas | 0 | 1 in shadow root | 1 in shadow root |
| Semantics nodes | n/a (real HTML) | 0 | 16 |
| Axe violations | **none** | `html-has-lang` (serious), `meta-viewport` (critical) | above + `region` (moderate), `scrollable-region-focusable` (serious) |
| HTML size | 4.6 KB | 652 B shell + JS/WASM | 652 B shell + JS/WASM |
| Build output on disk | 683 KB | 29.0 MB (18 files) | 29.0 MB |

**Measurement caveats:**

- The Flutter `transferSize`/`encodedBodySize` values in the raw harness are inconsistent (the transfer counter reports 134 KB while encoded body reports 7.88 MB; the summary reports 2.84 MB). Treat the **summary median 2.84 MB** as the planning figure and the 7.9 MB decoded figure as the uncompressed payload.
- FCP/LCP values are from a headless Chromium harness, not a real phone. LCP 0 for Flutter means the observer did not report an LCP entry, not that it was instant.
- The 3G run is a single run for SSR and Flutter; not a median.
- Local server latency is lower than a real origin/CDN.

### 3.6 Observations

#### SSR

- Core report is real HTML: headings, paragraphs, table rows, images, text selectable/copyable/findable.
- No JavaScript required; the page is readable if JS fails.
- Neutral `<title>` and description; `noindex, nofollow`; `lang="ar" dir="rtl"`; viewport allows zoom.
- Axe reported no violations in this harness.
- 623 KB transfer is mostly the 20 photos; HTML is 4.6 KB.
- Wall time on 3G is dominated by photos; the text appears early (FCP 548 ms).

#### Flutter Web

- Canvas-based: `innerText` is 0, no table rows in the DOM, no headings/paragraphs.
- Axe reports critical `meta-viewport` (zoom disabled by the default Flutter shell) and serious `html-has-lang`.
- Metadata is the default Flutter project metadata (“A new Flutter project”), not neutral report metadata and no `noindex`.
- Fonts are fetched from `fonts.gstatic.com` at runtime; a blocked font CDN affects rendering.
- The semantics-forced build exposes only 16 semantics nodes for a 131-row report; text length is 1,216 chars.
- The semantics screenshots show layout degradation in the header/vehicle block (clipped/overlapping content) in this harness.
- The non-semantics screenshot is blank in the harness; this may be a headless capture limitation, but it is not evidence of a working document.
- Flutter is faster to “ready” in this local emulation because it loads a large JS/WASM bundle and paints a canvas, but it does not produce a document. The accessibility/document costs are the deciding factor, not just speed.

### 3.7 Critical criteria assessment

| Criterion | SSR | Flutter | Evidence |
|---|---|---|---|
| Opens reliably from WhatsApp on Android/iPhone | Not tested on real devices/in-app browsers | Not tested | Follow-up required for both |
| Readable on throttled connection | Yes (text early; photos lazy) | Page renders, but large runtime | 3G wall time |
| Arabic shaping/RTL correct | Yes in this render | Yes visually in semantics build | Screenshots |
| Screen reader reads content | Not tested | 16 nodes; likely inadequate | Semantics count; manual follow-up |
| Text selectable/findable | Yes | No (canvas) | DOM text |
| Print to PDF legibly | Not tested | Not tested | Follow-up |
| Link preview has no private data | Neutral metadata | Default app metadata; needs server shell | HTML/metadata |
| Invalid/revoked neutral | Not built in spike | Not built | Phase 6 |
| No admin code/private fields | Yes (static fake data) | Yes (fake data) | Code review |
| Not indexed | `noindex` present | No `noindex` | HTML |

**Conclusion:** SSR is the only variant that behaves like a document in this harness. It is not a complete production proof, but it clears the measurable document/accessibility/transfer criteria that Flutter Web fails. The remaining critical criteria need real-device and real-WhatsApp testing.

### 3.8 Recommendation

**Use server-rendered HTML for the public report in V1.** Keep Flutter for the technician and admin apps. Use a server-side template (for example Thymeleaf) with auto-escaping, the public allowlist DTO, no admin JavaScript and no external font/script dependency.

**Before Phase 6, prove:**

1. Real Android and iPhone, WhatsApp in-app browser, SMS/email.
2. Real link previews (WhatsApp/iMessage/email) with neutral metadata.
3. TalkBack/VoiceOver/NVDA reading order.
4. Text selection, find, print and 200% zoom.
5. Invalid/revoked/consent-missing neutral states.
6. Cache/revocation behaviour behind the chosen CDN/proxy.
7. Real 3G/4G and a low-end device.
8. Arabic review by a native reader.
9. No private field in the rendered HTML or metadata.
10. The actual Java server, not a static file.

### 3.9 What Spike B did not prove

- Real WhatsApp/Instagram in-app browser behavior.
- Real devices, real carriers, real CDN.
- Screen-reader reading order.
- Print-to-PDF quality.
- Link preview behavior in each messaging app.
- Invalid/revoked states (not built).
- The actual server-rendered Java implementation.
- A 20-page PDF-equivalent report.
- Flutter Web on iOS Safari.

---

## 4. Spike C — Production object storage

### 4.1 Question

Which production object storage should replace MinIO OSS after the Phase 0 finding that MinIO OSS is archived/no longer maintained?

### 4.2 Constraints

- S3-compatible API preferred (AWS SDK v2; easy provider swap).
- Encryption at rest and in transit.
- Data residency: UAE first; counsel must approve any cross-border transfer.
- Private buckets; pre-signed upload/download; lifecycle; versioning; object lock desirable for evidence/report retention.
- Licence acceptable for a commercial hosted product.
- Operable by a small team; no unnecessary distributed-systems burden.
- Cost predictable at pilot volume; no invented quotes.

### 4.3 Options

| Option | S3 API | Encryption at rest | UAE data location | Licence / terms | Ops burden | Assessment |
|---|---|---|---|---|---|---|
| **AWS S3 `me-central-1`** | Native S3 | S3 SSE (S3/KMS; verify account config) | **Yes — AWS Middle East (UAE) region** | AWS service terms | Low (managed) | **Shortlist** if budget and UAE residency |
| **OCI Object Storage `me-dubai-1` / `me-abudhabi-1`** | S3 Compatibility API (subset) | OCI encryption; verify KMS/SSE details | **Yes — Dubai/Abu Dhabi** | Oracle cloud terms | Low–medium (managed) | **Shortlist**; verify S3 feature subset |
| **Cloudflare R2** | S3 API (broad coverage) | AES-256-GCM, automatic | **No UAE jurisdiction verified** — available jurisdictions are EU, US, FedRAMP; location hints are best effort | Cloudflare terms | Low (managed) | Cost/egress attractive; **requires legal approval for EU/US storage** |
| **SeaweedFS** | S3 gateway | AES-256-GCM encrypted storage | Self-hosted wherever the server is | **Apache-2.0** | High (cluster, filer, S3, backups) | Viable self-hosted; small-team ops risk |
| **Garage** | S3-compatible subset | Encryption at rest not confirmed in reviewed sources | Self-hosted | **AGPL-3.0** (network-use obligations if modified) | Medium | Good for small geo-distributed clusters; AGPL and encryption need review |
| **Ceph RGW** | S3-compatible subset | SSE-S3/SSE-KMS/SSE-C | Self-hosted | **LGPL-2.1/3.0** (mostly) | High (Ceph cluster operations) | Mature at scale; too heavy for a small V1 team unless already operated |
| **MinIO OSS** | S3 | — | Self-hosted | AGPL-3.0, archived | — | **Local development only**, pinned image; never production |
| **Backblaze B2** | S3-compatible | Provider-managed | No UAE region verified (US/EU) | B2 terms | Low | Cost reference ($6.95/TB/mo at the time); cross-border review |

### 4.4 Verified facts and sources

- **AWS S3 UAE:** AWS lists Middle East (UAE) `me-central-1` with S3 endpoints; the region is in the UAE. Source: AWS S3 endpoints and AWS Regions pages (accessed 3 Nov 2026).
- **OCI UAE:** OCI lists `me-abudhabi-1` (Abu Dhabi) and `me-dubai-1` (Dubai); Object Storage exposes an Amazon S3 Compatibility API, but not all S3 APIs are supported. Source: OCI Regions and Object Storage S3 Compatibility API docs (accessed 3 Nov 2026).
- **Cloudflare R2:** S3 API compatibility; all objects encrypted at rest with AES-256-GCM; jurisdictions available are EU, FedRAMP, US; **no UAE jurisdiction**; location hints are best effort. Source: Cloudflare R2 docs (accessed 3 Nov 2026).
- **SeaweedFS:** Apache-2.0; S3-compatible API; AES-256-GCM encrypted storage. Source: SeaweedFS GitHub README (accessed 3 Nov 2026).
- **Garage:** AGPL-3.0; S3-compatible with a defined compatibility target; self-hosted, lightweight. Source: Garage documentation (accessed 3 Nov 2026). Encryption at rest was not confirmed in the reviewed pages.
- **Ceph:** mostly LGPL-2.1/3.0; S3-compatible gateway; server-side encryption with SSE-S3/SSE-KMS/SSE-C. Source: Ceph GitHub license and Ceph Object Gateway encryption docs (accessed 3 Nov 2026).
- **Backblaze B2:** S3-compatible; pricing starts at $6.95/TB/month (published page, accessed 3 Nov 2026); no UAE region verified.
- **MinIO:** Phase 0 verified the OSS edition is archived/no longer maintained; AIStor Free is proprietary and limited. Source: Phase 0 research and MinIO project pages.

### 4.5 Assessment

- **If UAE residency is required (likely):** the realistic managed shortlist is **AWS S3 `me-central-1`** and **OCI Object Storage UAE**. Both are managed, have UAE regions, and expose S3 APIs. AWS has the most complete S3 feature set; OCI’s S3 Compatibility API is a subset, so verify pre-signed URLs, multipart, lifecycle, object lock and CORS before choosing.
- **If self-hosting is mandatory:** **Ceph RGW** is the mature choice but a significant operational burden; **SeaweedFS** is lighter and Apache-2.0 but still a cluster to operate; **Garage** is small-team friendly but AGPL-3.0 and its encryption-at-rest story needs verification. A small V1 team should not self-host Ceph without existing expertise.
- **Cloudflare R2** is attractive on egress cost and S3 compatibility, but its available jurisdictions are EU/US/FedRAMP and there is no UAE jurisdiction. It is not a safe default for UAE customer data until counsel approves the transfer and the contract terms.
- **MinIO stays local-only**, pinned for `docker compose`, clearly labelled development-only. Do not ship it to production.

### 4.6 Recommendation

**Pending D6:** shortlist **AWS S3 `me-central-1`** and **OCI Object Storage UAE**; run a one-day proof in Phase 2 covering:

1. Private bucket, public access blocked.
2. Pre-signed PUT/GET with short expiry.
3. Multipart upload and resume behavior.
4. Lifecycle and versioning.
5. Object Lock/retention if available.
6. Encryption at rest and key management.
7. CORS for the admin web (if direct upload).
8. Latency from the UAE server and from the workshop.
9. Cost estimate for pilot volume (storage, requests, egress).
10. Data-processing terms, residency and deletion.
11. Backup/export path.
12. Provider outage behavior.

**Local development:** MinIO pinned, dev-only. The S3 API boundary means the production provider can change without rewriting application code.

### 4.7 What Spike C did not prove

- Actual pricing/quotes or contract terms.
- Exact encryption/KMS configuration in an account.
- UAE data-residency guarantees in the contract.
- Performance/latency from the target server.
- Pre-signed URL/multipart/object-lock feature parity for OCI.
- Operational effort for self-hosted options.
- Migration effort from MinIO.
- Legal approval for any cross-border storage.

---

## 5. Reproduce

### 5.1 Arabic PDF

```powershell
# From spikes/arabic-pdf
node generate.mjs
node render.mjs              # Chromium PDF + text + shots
# OpenHTMLtoPDF (Java 17 in this environment)
cd openhtmltopdf
mvn -q exec:java "-Dexec.args=../report.html ../openhtmltopdf.pdf"
node ../render-other.mjs ../openhtmltopdf.pdf openhtmltopdf
```

Artifacts: `chromium.pdf`, `openhtmltopdf.pdf`, `chromium.txt`, `openhtmltopdf.txt`, `shots/*.png`.

### 5.2 Public report

```powershell
# From spikes/public-report
npm install
npm run measure
```

Artifacts: `results/results.json`, `results/summary.json`, `results/*.png`.

The Flutter build must exist at `spikes/public-report/flutter/build/web` and `build/web-semantics`; the measure script serves them locally.

### 5.3 Object storage

No server was deployed. The comparison is a desk research record; the Phase 2 proof is listed in §4.6.

---

## 6. Decision impact

| Decision | Phase 1 recommendation | What must be approved before implementation |
|---|---|---|
| D4 public report | SSR HTML | Product owner; then Phase 6 real-device/WhatsApp/accessibility proof |
| D5 PDF | Headless Chromium | Product owner; then Linux/Java 25/native Arabic proof |
| D6 object storage | AWS S3 UAE or OCI UAE shortlist; MinIO local-only | Product owner + counsel + one-day proof |
| D1 database | MySQL 8.4 LTS | Product owner; Phase 2 migration test |
| D9 corrections | No correction UI/API | Product + legal; Phase 6 |

---

## 7. Final limitations

- No real customer data, real devices, real WhatsApp in-app browser, real screen reader, real Linux/Java 25 container or real cloud account was used.
- No native Arabic reviewer signed off the PDF; the visual review was performed by the operator.
- No production performance, concurrency, cost or data-residency guarantee is claimed.
- Versions and provider terms change; re-verify at Phase 2 and Phase 6.
- A spike result is evidence for a decision, not a production acceptance test.
