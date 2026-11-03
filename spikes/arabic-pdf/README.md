# Arabic PDF Spike

**Status:** Isolated experiment. Do not import into production.

**Full write-up:** `docs/phase-1/12-spike-results.md` §2.

## What it does

- `generate.mjs` writes `report.html`: 120 inspection rows, 10 categories, 20 placeholder photos, long Arabic, mixed Arabic/English/numbers/VIN, Russian and Chinese names, tables, lists, gallery, disclaimer.
- `render.mjs` renders `report.html` with Playwright Chromium to `chromium.pdf`, extracts text with pdfjs, and rasterises selected pages to `shots/`.
- `openhtmltopdf/` is a Java 17 Maven project that renders the same HTML with OpenHTMLtoPDF 1.0.10 + `openhtmltopdf-rtl-support`.
- `render-other.mjs` extracts/rasterises an existing PDF.

## Commands

```powershell
node generate.mjs
node render.mjs
cd openhtmltopdf
mvn -q exec:java "-Dexec.args=../report.html ../openhtmltopdf.pdf"
node ../render-other.mjs ../openhtmltopdf.pdf openhtmltopdf
```

## Result

- Chromium: 18 pages, 1.50 MB, median total 1,745 ms, correct Arabic/RTL/mixed text in reviewed pages.
- OpenHTMLtoPDF: 19 pages, 0.76 MB, median 1,603 ms, Arabic shaping/bidi visibly broken, `unicode-bidi` not implemented.
- Recommendation: **headless Chromium**, pending Linux/Java 25 and native Arabic review.

## Caveats

Windows, Node Playwright 1.56.1, Java 17.0.12, 18–19 pages, no 30-page variant, no native Arabic sign-off, no production container. See `docs/phase-1/12-spike-results.md` for measurements and limitations.
