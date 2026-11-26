# Inspection · Fieldwork — proof set

Captured from the production `FieldworkWorkspace` / `FieldworkItemScreen` /
`PhotoMarkupPage` widgets with realistic sample data. The throwaway
`lib/preview` and `lib/preview_prod` harnesses have been removed.

| Screen | 1440 | 1024 | 390 EN | 390 RTL | Dark proof |
|---|---|---|---|---|---|
| Inspection hub | `hub-1440.png` | `hub-1024.png` | `hub-390.png` | `hub-390-rtl.png` | `hub-1440-dark.png` |
| Item assessment | `item-1440.png` | `item-1024.png` | `item-390.png` | `item-390-rtl.png` | `item-390-dark.png` |
| Photo editor | `markup-1440.png` | — | `markup-390.png` | — | the editor is dark by design |

Additional states:

- `item-390-mark.png` — defect result with the **Mark photo?** callout.
- `item-390-notes.png` — the conditional notes state (`allowFreeTextNote` + `minNotesChars > 0`); the default item screen does not render notes.

**Dark caveat:** the shipped app theme is light-only (the design system asserts
this). `hub-1440-dark.png` and `item-390-dark.png` are a proof-only dark
`ColorScheme` wrapping the same production widgets. No shipped dark theme was
added.
