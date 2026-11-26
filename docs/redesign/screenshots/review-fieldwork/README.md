# Review · Fieldwork — proof set

Captured from the production `SummaryGateView`, `SignatureView` and
`CompletedView` widgets with realistic sample data. The throwaway
`lib/preview_review` harness has been removed.

| Screen | 1440 | 1024 | 390 EN | 390 RTL | Dark proof |
|---|---|---|---|---|---|
| Sign-off gate — blocked | `summary-1440.png` | `summary-1024.png` | `summary-390.png` | `summary-390-rtl.png` | `summary-1440-dark.png` |
| Sign-off gate — ready | `summary-1440-ready.png` | `summary-1024-ready.png` | `summary-390-ready.png` | — | — |
| Customer signature | `signature-1440.png` | `signature-1024.png` | `signature-390.png` | `signature-390-rtl.png` | `signature-1440-dark.png` |
| Completed handover | `completed-1440.png` | `completed-1024.png` | `completed-390.png` | `completed-390-rtl.png` | `completed-1440-dark.png` |

The blocked sample shows two item blockers, a signature blocker and a sync
conflict; the primary gate action is “Review 2 items” because item blockers are
resolved before sync conflicts. The capped score sample is **Grade B**, matching
its “caps the grade at B” note.

**Dark caveat:** the app theme is light-only. The dark images are a proof-only
`ColorScheme` wrapping the same production widgets; no shipped dark theme was
added.

**Radius note:** the reused inspection `ConflictPanel` paints at 24; the rest of
the review surfaces use 16/14/999. It is the single radius outlier.
