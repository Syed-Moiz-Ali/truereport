# Phase 6 Samples

Generated 4 November 2026 with fake data.

- `bilingual-report-sample.pdf`: 9-page bilingual PDF, 20 generated evidence photos, long mixed English/Arabic text, Cyrillic and CJK note text, repeated headers and report-ID/version footer.
- `bilingual-report-sample.txt`: PDF text extraction. Arabic extraction is not a reliable shaping test; use the PNGs for visual review.
- `public-report-dark-phone.png`: rendered public report at 390 px, dark mode, English.
- `public-report-ar-dark-phone.png`: same report in Arabic, RTL, dark mode.
- `public-report-light-phone.png`: same report in light mode.
- `public-report-browser-check.json`: Playwright/Axe result (200, 0 external requests, RTL, 0 axe violations).

Visual checks performed by the operator:

- Arabic headings and RTL blocks are positioned correctly.
- Latin, Cyrillic and CJK strings are visible and do not disappear.
- Long notes wrap inside table cells instead of clipping.
- Repeated table headers and page footer remain readable on later pages.
- The footer was moved from an overlapping top position to the bottom after the first render.
- Report ID and version appear in the PDF footer.

Not done:

- Native Arabic reviewer sign-off.
- Real Adobe Acrobat / Apple Preview / mobile viewer pass.
- 30-page and 30-photo stress variants.
