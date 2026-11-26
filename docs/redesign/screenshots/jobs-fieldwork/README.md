# Jobs queue · Fieldwork — proof set

Captured from the production `JobsBoard` with realistic sample data. The
throwaway `lib/preview_jobs` harness has been removed.

| State | 1440 | 1024 | 390 EN | 390 RTL | Dark |
|---|---|---|---|---|---|
| Shift board | `jobs-1440.png` | `jobs-1024.png` | `jobs-390.png` | `jobs-390-rtl.png` | `jobs-1440-dark.png` |
| Empty day | — | `jobs-1024-empty.png` | `jobs-390-empty.png` | — | — |
| Offline | — | — | `jobs-390-offline.png` | — | — |
| No search results | — | — | `jobs-390-no-results.png` | — | — |

The 1440 layout is a 760 shift agenda + 340 NOW rail; 1024 stacks NOW above the
agenda; 390 stacks the NOW card, shift summary, tabs, filters and agenda. The
right rail keeps the current job visible while the agenda scrolls.

**Dark caveat:** the app theme is light-only; the dark image is a proof-only
`ColorScheme` wrapping the same production widgets.

**Known follow-up:** at 1440 with a short day, the rail ends after the shift
summary and leaves canvas below. A “Next up” mini-list would fill it; the board
is top-aligned today.
