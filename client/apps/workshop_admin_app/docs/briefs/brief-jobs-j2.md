# Brief J2 — jobs write path (wizard, approve, checklist, documents)

WORKDIR: `client/apps/workshop_admin_app`
MODE: implement (UI + tests + evidence)
COMMITS: none

## OUTCOME

Four write-path screens are rebuilt on Workshop primitives (no `App*` kit):
creation wizard, approve/reject, publish checklist, documents. The stable
entry files keep their class names and paths so the concurrent queue/detail
sessions keep compiling; the screens themselves become thin compositions
(<= 220 lines) with one file per region under `wizard/`, `approve/`, `publish/`
and `documents/`.

## SCOPE (owned)

- `lib/src/features/jobs/job_creation_wizard_page.dart` (rewrite, thin)
- `lib/src/features/jobs/approve_job_page.dart` (rewrite, thin)
- `lib/src/features/jobs/publish_checklist_page.dart` (rewrite, thin; the ONLY
  `.publishJob(` call site, pinned by `source_scan_test`)
- `lib/src/features/jobs/job_documents_page.dart` (rewrite, thin)
- `lib/src/features/jobs/wizard/**`, `approve/**`, `publish/**`, `documents/**`
- `lib/src/workshop_job_models.dart` (two mapper fixes: nullable
  `JobDocument.bytes`, explicit `NewCleanJob.consentGranted`)
- Tests: `test/job_wizard_test.dart`, `test/job_approve_test.dart`,
  `test/jobs_publish_checklist_test.dart`, `test/job_documents_test.dart`,
  `test/jobs_j2_capture_test.dart`; `test/jobs_adaptive_test.dart` publish-button
  type only.
- `docs/change_requests.md` (enum-label gap), this brief, evidence.

Not touched: `queue/**`, `detail/**`, `shared/**`, `archive/**`,
`public_link_page.dart`, `packages/**`, `pubspec.yaml`, ARB, theme/tokens,
queue/detail tests.

## KILL LIST

1. `AppTextField`, `AppButton`, `AppSelectableText`, `AppScaffold`,
   `AppCard`-based `JobPanel` bodies in the four screens.
2. Wizard's 720 px single-column `SectionHeader` + `Wrap` chip composition;
   replaced by a step rail + form surface (two columns at >= 1000).
3. Approve's one-column stack of `JobPanel`s and the single generic error
   (`commonActionFailed`) that hid `APPROVER_IS_TECHNICIAN` / version conflicts.
4. Checklist's one `JobPanel` per row (nested cards) and the
   `jobsDocumentsReady` chip (G-J5 constant).
5. Documents' "Download" action that only copied a relative path (F16/G-J6)
   and its raw `READY`/`FAILED` labels and `0 B` for a null size.

## REGIONS

```
wizard/job_creation_wizard_page.dart     step rail, form surface, footer layout
wizard/wizard_step_rail.dart             vertical at >=1000, wrap below
wizard/wizard_customer_step.dart         name/phone/email (keys kept)
wizard/wizard_vehicle_step.dart          make/model/year/VIN/plate/odometer + choices
wizard/wizard_template_step.dart         availableTemplatesProvider
wizard/wizard_technician_step.dart       staffProvider + language + consent note
wizard/wizard_choice_group.dart          WorkshopFilterChip group (no raw enum look)
wizard/wizard_footer.dart                Back / Next / Create (jobs-wizard-next)
wizard/wizard_error_banner.dart          validation + create failure
approve/approve_summary.dart             identity + real score/grade/safety facts
approve/approve_score.dart               review previews + mapped findings (no CR-7 data)
approve/approve_actions.dart             reason/safety fields + approve/reject/checklist
approve/approve_states.dart              load error, version/mutation banner
publish/checklist_summary.dart           ready/consent/signature/safety + docs note
publish/checklist_items.dart             ONE surface, hairline rows
publish/publish_panel.dart               PDF toggle + publish button + blocked reasons
publish/publish_states.dart              mutation error banner
documents/document_row.dart              localized status, nullable size, copy link
```

## DATA RULES

- Wizard: no scheduled-time input (G-J11). `consentGranted` is sent `false`;
  `jobsConsentUnavailableNote` states publishing stays blocked until CR-5.
  Validation: phone required, email shape, VIN 17 when present.
- Approve: only `PENDING_REVIEW` may approve/reject; every call sends
  `job.version`; `version == null` disables both and shows `jobsNoVersion`.
  Distinct copy: `APPROVER_IS_TECHNICIAN`, `JOB_VERSION_CONFLICT`,
  403/404. Findings show label + stable code + mapped result only
  (no evidence counts / issue values / completedAt — CR-7).
- Checklist: `publishChecklistProvider` only. Never claim documents are ready;
  show `jobsDocsGeneratedAfterPublish`. Publish requires `ready` AND
  `consentGranted`; otherwise disabled with `jobsPublicationBlockedBody` +
  `jobsConsentUnavailableNote`. `422 CONSENT_REQUIRED` maps honestly.
- Documents: `Copy link` (no fake download), status labels localized,
  size `—` when `bytes == null`, server-generated time omitted (CR-8).
- No workshop id in any request (M1); publish only from the checklist (M6).

## FLOW PROOF

1. Create: wizard calls `createCleanJob` with `scheduledAt == null` and
   `consentGranted == false`; the route pops; `cleanJobsProvider` and
   `cleanJobCountsProvider` are invalidated and the new job appears in the
   watched clean list.
2. Approve -> stored status `APPROVED`; reject with a reason -> `REJECTED`.
3. Checklist blocked -> publish disabled; consent missing -> publish disabled
   with the stated reason.
4. Publish -> link live: **BLOCKED (CR-5)**. The server can never see consent
   for an app-created job, so this proof is recorded as BLOCKED, not faked.

## EVIDENCE (real fonts, takeException null)

`docs/evidence/jobs_j2/`: `wizard_{1440,1024,390}.png`, `wizard_1280_ar.png`,
`wizard_technician_1280.png`, `approve_{1440,1280,390}.png`,
`approve_1280_ar.png`, `checklist_blocked_1280.png`,
`checklist_blocked_1280_ar.png`, `checklist_ready_1280.png`,
`checklist_ready_1280_ar.png`, `documents_1280.png`, `documents_390.png`,
`create_success_1280.png`.

## COMMANDS

```
dart format lib/src/features/jobs/job_creation_wizard_page.dart lib/src/features/jobs/approve_job_page.dart lib/src/features/jobs/publish_checklist_page.dart lib/src/features/jobs/job_documents_page.dart lib/src/features/jobs/wizard lib/src/features/jobs/approve lib/src/features/jobs/publish lib/src/features/jobs/documents lib/src/workshop_job_models.dart test/job_wizard_test.dart test/job_approve_test.dart test/jobs_publish_checklist_test.dart test/job_documents_test.dart test/jobs_j2_capture_test.dart test/jobs_adaptive_test.dart
flutter analyze --fatal-infos
flutter test test/job_wizard_test.dart test/job_approve_test.dart test/jobs_publish_checklist_test.dart test/job_documents_test.dart
flutter test test/jobs_j2_capture_test.dart
flutter test
```
