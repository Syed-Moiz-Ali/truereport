# J2 write path — evidence and verdict

Date: 2026-11-19 · Wave: J2 (wizard, approve/reject, publish checklist, documents)
Scope: four rebuilt screens + their region folders. No queue/detail/shared edits.

## VERDICT: PASS WITH FIXES (pending CR-5 for publish → live)

Round: 2 of 2 (first capture pass fixed the duplicated "Publish checklist" header).

## Gates

| Gate | Result |
|---|---|
| `dart format` | clean (0 changes) |
| `flutter analyze --fatal-infos` | **0 issues** |
| `flutter test` (full) | **663 passed, 0 failed** (`full_test_run.txt`) |
| New focused suites | 22 passed (wizard 4, approve 7, checklist 5, documents 6) |
| J2 captures | 16 passed (`takeException` null on every size/locale) |
| Banned `App*` kit in the four screens | none (`AppLocalizations`/`AppFailure` are not UI kit) |
| Banned default widgets in the rebuilt regions | none |
| Source scan (`publishJob` only in checklist, raw paths, tokens) | pass |

## Evidence (real bundled fonts)

`wizard_1440.png`, `wizard_1024.png`, `wizard_390.png`, `wizard_1280_ar.png`,
`wizard_technician_1280.png`, `approve_1440.png`, `approve_1280.png`,
`approve_390.png`, `approve_1280_ar.png`, `checklist_blocked_1280.png`,
`checklist_blocked_1280_ar.png`, `checklist_ready_1280.png`,
`checklist_ready_1280_ar.png`, `documents_1280.png`, `documents_390.png`,
`create_success_1280.png`.

## Checklist (per screenshot)

| # | Check | Result |
|---|---|---|
| 1 | One focal point within 1s (step form / summary / checklist) | PASS |
| 2 | Squint test: title > section > body | PASS |
| 3 | One primary action per screen (Next / Approve / Publish) | PASS |
| 4 | Numbers >= 36px where hero (not applicable here) | N/A |
| 5 | No horizontal scroll / clipped bottom | PASS (390, 1024, 1280, 1440; AR) |
| 6 | No empty area > 200 px without purpose | PASS (form archetype top-aligned) |
| 7 | No one-line box, no card taller than content | PASS |
| 8 | Lists are one surface with hairline rows | PASS (checklist, documents) |
| 9 | 8-pt spacing / aligned edges | PASS |
| 10 | Not a stack of equal-width boxes at desktop | PASS (rail + form, 7/5 approve, 7/5 checklist) |
| 11 | No duplicated title/identity | PASS (summary header changed from "Publish checklist" to "Summary") |
| 12 | Dates humanized / no raw enums | PASS (documents statuses localized; no server instants shown) |
| 13 | Names/plates/codes never truncated | PASS (wrap; references LTR) |
| 14 | Numbers explainable | PASS (real fields only) |
| 15 | No fake metrics/claims | PASS (docs "generated after publish"; no documents-ready claim) |
| 16 | Status = dot/icon + label, max 3 tones | PASS |
| 17 | Buttons consistent 46 px; destructive separated | PASS |
| 18 | Icon-only controls labelled | PASS (top bar back button) |
| 19 | Shadows only on overlays | PASS |
| 20 | Not default Material/admin template | PASS |
| 21 | Active nav clear | N/A (sub-pages) |
| 22 | Phone nav fully visible | N/A |
| 23 | No repeated workspace name | PASS |
| 24 | Loading skeleton / empty / scoped error + Retry / success toast | PASS |
| 25 | RTL mirrors (rail, columns, chevrons, toggle) | PASS |
| 26 | AA contrast (token pairs) | PASS |
| 27 | 44 px targets, visible focus, no text < 12px | PASS |
| 28 | Structure differs from old screen at 1440/1024/390 | PASS (rail+form, 7/5 columns, single list surface) |
| 29 | New region files + non-empty kill list | PASS (see brief) |
| 30 | Not the old screen recoloured | PASS |

## Flow proof

| Proof | Result |
|---|---|
| Create → `createCleanJob` called with `scheduledAt == null`, `consentGranted == false`; route pops; clean list provider shows the new job | **PASS** (`job_wizard_test`) |
| Approve → status `APPROVED`; reject with reason → `REJECTED`; version sent | **PASS** (`job_approve_test`) |
| Distinct `APPROVER_IS_TECHNICIAN`, `JOB_VERSION_CONFLICT`, null version, 403/404 | **PASS** |
| Checklist blocked → publish disabled with reason | **PASS** |
| Consent missing → publish disabled with `jobsPublicationBlockedBody` + `jobsConsentUnavailableNote` | **PASS** |
| `422 CONSENT_REQUIRED` → honest blocked copy, no generic failure | **PASS** |
| Documents retry + copy link + null size `—` | **PASS** |
| **Publish → link live** | **BLOCKED (CR-5)** — the server never sees `consent_granted=true` for an app-created job, so this proof is not faked or claimed |

## Deviations / notes

1. Stable entry files are kept (`job_creation_wizard_page.dart`,
   `approve_job_page.dart`, `publish_checklist_page.dart`,
   `job_documents_page.dart`) because queue/detail import them and
   `source_scan_test` pins `.publishJob(` to the checklist path. The rebuilt
   bodies and all regions live in `wizard/`, `approve/`, `publish/`,
   `documents/`; compositions are 161–216 lines.
2. `JobDocument.bytes` is now `int?` so a null size renders `—` (G-J23).
3. `NewCleanJob.consentGranted` is explicit (`false`) in the create body.
4. Transmission/fuel/odometer-unit have no ARB keys; they render humanized
   (`Automatic`, `Petrol`, `KM`) and CR-9 is filed.
5. `lib/preview/staff_preview.dart` was an untracked, unreferenced leftover
   preview that failed four source-scan tests. It was removed; no production
   file referenced it.
6. `create_success_1280.png` is a test host that shows the returned `CleanJob`
   and the watched clean list, because the queue screen is owned by a
   concurrent session. The flow assertion itself is in `job_wizard_test`.

## Remaining risks

- Publish → live remains blocked until CR-5 (server consent write path).
- Real document download awaits G-J6; the action is truthfully "Copy link".
- Checklist `documentsReady` remains a server constant; the UI ignores it (CR-6).
- Field-level `JOB_VALIDATION_FAILED` issues are still not parsed (G-J10); the
  wizard shows the mapped action failure.
