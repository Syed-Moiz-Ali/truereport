# Profile · Fieldwork — proof set

Captured from the production `ProfileBoard` with realistic sample data. The
throwaway `lib/preview_profile` harness has been removed.

| State | 1440 | 1024 | 390 EN | 390 RTL | Dark |
|---|---|---|---|---|---|
| Signed in / synced | `profile-1440.png` | `profile-1024.png` | `profile-390.png` | `profile-390-rtl.png` | `profile-1440-dark.png` |
| Conflict | — | — | `profile-390-conflicts.png` | — | — |
| Offline | — | — | `profile-390-offline.png` | — | — |

- The identity pass is the only dark surface; actions are one light surface with
  hairlines; sign-out is separated and destructive.
- `unknown` sync is shown as neutral (no invented count), not “all synced”.
- The pass foreground follows the fill: white on the dark light-theme ink, dark
  on the bright dark-proof mint (contrast fix).
- The sign-out is now directly after the actions (no viewport-bottom gap); the
  footer follows. The shell dock sits below in the app.

**Dark caveat:** the app theme is light-only; the dark image is a proof-only
`ColorScheme` wrapping the same production widgets.

**Known l10n gap:** the served conflict count copy is not pluralized (`1
conflicts`), matching the shared key.
