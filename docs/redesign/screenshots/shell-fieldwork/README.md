# Shell · Fieldwork — proof set

Captured from the production `TechnicianShellFrame` with a neutral sample body.
The throwaway `lib/preview_shell` harness has been removed.

| State | 1440 | 1024 | 390 EN | 390 RTL | Dark |
|---|---|---|---|---|---|
| Jobs tab | `shell-1440.png` | `shell-1024.png` | `shell-390.png` | `shell-390-rtl.png` | `shell-1440-dark.png` |
| Profile tab | — | — | `shell-390-profile.png` | — | — |

- **< 900 px:** full-width bottom dock, 64 px + safe area, two equal tabs, 64×28
  mint active indicator, 44+ targets.
- **≥ 900 px:** 88 px left rail (right in RTL), TR mark, two icon destinations
  with tooltips + semantics, 3 px start indicator and a 48×48 tonal active tile.
  No bottom dock.
- The rail leaves 812/936/1352 px at 900/1024/1440, so the 760/340 jobs board and
  the 620 profile both fit.
- Routes, `IndexedStack` state, index semantics, and Sync-as-a-profile-action are
  unchanged.

**Dark caveat:** the app theme is light-only; the dark image is a proof-only
`ColorScheme` wrapping the same production frame.
