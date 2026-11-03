# Public Report Spike

**Status:** Isolated experiment. Do not import into production.

**Full write-up:** `docs/phase-1/12-spike-results.md` §3.

## Variants

- `ssr/` — static server-rendered HTML + CSS, no JavaScript, 131 table rows, 20 photos.
- `flutter/` — Flutter Web canvas build.
- `flutter/build/web-semantics/` — Flutter build with `ensureSemantics()` forced.

## Commands

```powershell
npm install
npm run measure
```

The measure script starts local static servers for `ssr`, `flutter/build/web`, and `flutter/build/web-semantics`, emulates 4G/3G + 4× CPU, captures screenshots, text/DOM counts, transfer sizes, perf entries and axe results.

## Result (medians of 3, 4G)

| Metric | SSR | Flutter |
|---|---:|---:|
| Transfer | 623 KB | 2,841 KB |
| FCP | 488 ms | 3,696 ms |
| DOM text | 13,536 chars | 0 chars |
| Table rows | 131 | 0 |
| Axe violations | 0 | 2 (critical/serious) |
| Semantics nodes | n/a | 16 in forced build |

SSR is a real document; Flutter is a canvas. Recommendation: **server-rendered HTML**, pending real-device/WhatsApp/screen-reader tests.

## Caveats

Local static server, Chromium emulation, no real phones, no WhatsApp in-app browser, no screen reader, no print test, no real Java server. See `docs/phase-1/12-spike-results.md` for raw numbers and limitations.
