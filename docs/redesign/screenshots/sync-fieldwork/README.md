# Sync · Fieldwork — proof set

Captured from the production `SyncBoard` and `ConflictBoard` with realistic
sample data. The throwaway `lib/preview_sync` harness has been removed.

| Screen | 1440 | 1024 | 390 EN | 390 RTL | Dark |
|---|---|---|---|---|---|
| Outbox | `sync-1440.png` | `sync-1024.png` | `sync-390.png` | `sync-390-rtl.png` | `sync-1440-dark.png` |
| Outbox + conflicts | `sync-1440-conflicts.png` | — | — | — | — |
| Empty | — | — | `sync-390-empty.png` | — | — |
| Offline | — | — | `sync-390-offline.png` | — | — |
| Conflict detail | `conflict-1440.png` | `conflict-1024.png` | `conflict-390.png` | `conflict-390-rtl.png` | `conflict-1440-dark.png` |

- One primary per viewport: **Sync now** in the hero from 1000 px up; the pinned
  footer carries it below 1000.
- Job ids are shown as `Job #10485`, never `job-10485`.
- Measurement-like conflict values stay LTR in RTL (`4.1 mm`, not `mm 4.1`).
- The conflict detail keeps the server-only resolution as the single action and
  the two notes; the diff table hides equal fields when a field differs.

**Dark caveat:** the app theme is light-only; the dark images are a proof-only
`ColorScheme` wrapping the same production widgets.
