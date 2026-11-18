# Change requests — foundation is frozen

Module sessions may not edit tokens, theme, `app_shell`, router root, DI root,
`pubspec.yaml`, or `packages/**`. They file here and continue with the closest
existing primitive.

Format:

```
Request: <what>
Why: <what breaks without it>
Needed by: <modules/screens>
Workaround used meanwhile: <closest existing primitive>
```

## Open

| ID | Request | Why | Needed by | Client workaround in force |
|---|---|---|---|---|
| CR-1 | Server re-checks the publish checklist inside `POST /jobs/{id}/publish` | The checklist is currently a client-only gate; any other client can publish an APPROVED job with a blocked checklist (audit F2, J9) | J3 public-link | Public-link page loses its publish action; publishing happens only from the checklist screen |
| CR-2 | Scoped counts on `GET /workshop/jobs/counts` (`status`, `search`, `from`, `to`) | The endpoint is workshop-wide with no predicate; chips cannot describe the current filter (audit F4/M9, J4) | J1 queue filters | Chips labelled **Whole workshop**; page rows are search-scoped and the footer states the visible total |
| CR-3 | Backfill `inspection_jobs` into `platform_jobs` (or expose a read-only archive endpoint) | Two disjoint UUID spaces; the legacy table is still used by technician endpoints (audit F1) | J1 archive removal | `features/jobs/archive/` read-only list keeps legacy rows visible |
| CR-4 | Make `version` mandatory for assign/cancel/publish on the server | `checkVersion` skips the guard when version is null (audit F3/M5) | J1 detail + assign | Client refuses to mutate when `job.version == null` and surfaces a distinct conflict state |

## Applied

| Date | Request | Applied by | Where |
|---|---|---|---|
| 2026-11-18 | `WorkshopDisplay` type role | dashboard wave (main) | `packages/design_system/lib/src/workshop_display.dart` |
| 2026-11-19 | shell primitives export from package barrel (components barrel is ACL-locked) | shell wave (main) | `packages/design_system/lib/design_system.dart` |
