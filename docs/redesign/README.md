# TrueReport · technician app — Fieldwork redesign

The operational technician app now uses the **A · Fieldwork** language:
one clear focus, a run sheet/gate, rows for homogeneous work, cards only for
composite moments, one pinned primary in the thumb zone.

## Modules and proof sets

| Module | Screens | Proof set |
|---|---|---|
| Inspection | hub, item assessment, photo editor | `screenshots/inspection-fieldwork/` |
| Review | sign-off gate, signature, completed | `screenshots/review-fieldwork/` |
| Jobs | shift board | `screenshots/jobs-fieldwork/` |
| Sync | outbox, conflict detail | `screenshots/sync-fieldwork/` |
| Profile | technician pass | `screenshots/profile-fieldwork/` |
| Shell | rail / bottom dock | `screenshots/shell-fieldwork/` |
| Sign-in | Bay Door (brand exception, audited) | `screenshots/auth-baydoor/` |

Each folder has its own README with the state matrix and the dark caveat.

## Shared rules

- Tokens/geometry from `lib/src/features/inspection/fieldwork/fieldwork_ui.dart`
  (cards 16, controls 14, pills 999, sheets 24); buttons 14/48–56.
- No raw hex in feature code except the documented photo-lightbox palette;
  status is always dot + label, never colour alone.
- Numbers are tabular and isolated LTR in RTL; identities wrap, they never
  truncate.
- Loading skeletons shaped like the content; empty, error, offline, read-only,
  RTL and dark-proof states are captured for every module.
- The shipped app is **light-only**. Dark images are a proof-only `ColorScheme`
  wrapping the same production widgets; no dark theme was added.
- Sign-in is the one intentional brand exception: the existing Bay Door
  photograph + glass sheet, audited and fixed, not restyled.

## API

No endpoint, DTO, mapper, OpenAPI, or route change. See `_api_changes.md`.
