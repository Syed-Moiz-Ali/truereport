# ADR-0005: Headless Chromium for the bilingual PDF

- **Status:** **Accepted** — approved by product owner 3 November 2026
- **Date:** 3 November 2026
- **Owner:** Backend/PDF lead
- **Evidence:** `docs/phase-1/12-spike-results.md` §2

## Context

The PDF must render Arabic shaping, bidi, mixed Arabic/English/numbers/VIN, Russian and Chinese names, long tables and 20+ photos. Phase 0 found OpenHTMLtoPDF old and RTL-limited; Chromium was the default candidate but unproven.

## Options

1. Headless Chromium (Playwright for Java) rendering print HTML/CSS.
2. OpenHTMLtoPDF 1.0.10 + PDFBox.
3. Dart/Flutter PDF package (rejected for server).

## Decision

Use **headless Chromium** behind a `PdfRenderer` interface. Render a dedicated print HTML template from the report snapshot. Bundle fonts; no runtime network fetch. Queue PDF generation in the worker; never block finalization on PDF success.

## Evidence

Spike A, 120 rows / 20 photos / 18 pages:

- Chromium: median total 1,745 ms (PDF-only median 817 ms), 1.50 MB, 18 pages, Arabic/RTL and mixed text visually correct, Russian/Chinese visible, footers and repeated table headers correct.
- OpenHTMLtoPDF: median 1,603 ms, 0.76 MB, 19 pages, but Arabic letters disconnected/reversed, footer order broken, and logs reported `unicode-bidi is not implemented`. It fails the core Arabic criterion.

Environment caveat: Windows, Java 17, Node Playwright; not the target Linux/Java 25 production class. No native Arabic reviewer sign-off yet.

## Consequences

- Correct Arabic and bidi with the browser’s Unicode stack.
- Heavier runtime: Chromium binary, OS dependencies, memory, security updates, container size.
- Need a browser process pool/queue and health checks.
- Need deterministic output or an accepted hash strategy.
- Fonts must be bundled and licensed.

## Follow-ups

- Approve D5.
- Run on Linux + Java 25 in the production-like container.
- Test 10/20/30 pages, 20/30 photos, missing image, long notes, concurrency.
- Native Arabic review of the full corpus.
- Tagged PDF/accessibility if required.
- Chromium update/patching process.
- Fallback plan if Chromium operations fail (do not silently switch to a broken Arabic engine).

## What was not proven

Linux/Java 25 behavior, memory at concurrency, 30-page variant, native Arabic sign-off, font licences, PDF/A or tagged PDF.


---

## Phase 6 implementation note (4 November 2026)

Implemented with Chromium supplied by the Playwright Java 1.64.0 image (Chrome for Testing 156.0.8078.4) and a dedicated print template. Final server image is ~1.88 GB; Chromium memory under concurrency is not yet measured. See `docs/phase-6/00-decisions.md`.
