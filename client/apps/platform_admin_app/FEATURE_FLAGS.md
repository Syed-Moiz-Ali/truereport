# Platform Admin feature flags

Localization (UI strings and content translations) is backend-driven, so the
translation review desk is part of the product and always visible. Only the
expert workflow editor is gated.

| Flag | Screen | Default |
|---|---|---|
| `TRUEREPORT_WORKFLOW_EDITING` | Configuration → Transitions (`/configuration/transitions`) | off |

## What "off" means

- The Settings ledger row is hidden.
- Both “Transitions” shortcuts (status taxonomy and option sets) are hidden.
- A direct visit to `/configuration/transitions` redirects to `/settings`.

This screen edits the real job/review/publication state machine, so it is
gated; a wrong edit changes which actions a workshop admin is allowed to take.

## Enabling

```powershell
flutter run --dart-define=TRUEREPORT_WORKFLOW_EDITING=true
```

Release builds take the same define:

```powershell
flutter build web --release --dart-define=TRUEREPORT_WORKFLOW_EDITING=true
```

The flag is read once at compile time in `lib/src/platform_features.dart`.
