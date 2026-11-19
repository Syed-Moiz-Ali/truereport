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
| CR-5 | A way to record public-link consent (`consent_granted`) for a created job, or accept consent in `POST /workshop/jobs` | The only create flow writes `consent_granted=false`; `PlatformJobStore.setConsent` has no caller; `publish` returns 422 `CONSENT_REQUIRED`, so no app-created job can ever publish (G-J1/X12) | J2 wizard + publish proof | Creation screen shows the consent state as **not recorded**; publish stays disabled with the reason stated |
| CR-6 | Re-check `checklist.documentsReady` / `DOCUMENTS_QUEUED` generation | Both are constants today; the checklist claims readiness for documents that do not exist (G-J5) | J2 checklist | UI says "generated after publish"; never marks it ready from a constant |
| CR-7 | Fix `review.findings` wire shape (`evidencePhotos:int`, `issueValuesJson:string`) or the mapper | The client reads list/map, so the detail always shows 0 evidence / empty issue values (G-J3) | J1 detail | Findings render label + code only; counts are omitted until the contract is fixed |
| CR-8 | Decide the canonical server instant format (offset or UTC `Z`) | Server-generated instants are written `LocalDateTime.now(UTC)` into a tz-less column and read as Dubai → rendered 4 h late (G-J18) | J1 detail/queue times | Client uses a UTC parser for server instants (`createdAt/updatedAt/startedAt/completedAt`) and keeps Dubai for user-picked `scheduledAt` until the wire is fixed |
| CR-9 | ARB labels for the transmission, fuel-type and odometer-unit client values (`AUTOMATIC/MANUAL/CVT`, `PETROL/DIESEL/HYBRID/ELECTRIC`, `KM/MI`) | These are client conventions with no key; the wizard must not print raw upper-case codes | J2 wizard | Humanized client values (`Automatic`, `Petrol`, `KM`) via `humanizeChoice`; first-class ARB keys when the vocabulary is approved |

## Applied

| Date | Request | Applied by | Where |
|---|---|---|---|
| 2026-11-18 | `WorkshopDisplay` type role | dashboard wave (main) | `packages/design_system/lib/src/workshop_display.dart` |
| 2026-11-19 | shell primitives export from package barrel (components barrel is ACL-locked) | shell wave (main) | `packages/design_system/lib/design_system.dart` |
