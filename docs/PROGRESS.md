# TrueReport — implementation progress

Plan: `docs/plan_full_completion.md`
Started: 2026-11-20
Working rule: one phase at a time, each phase ends with a recorded verification
(commands + result). No phase is marked done without real output.

## Decisions (defaults accepted unless changed)

| # | Decision | Value |
|---|---|---|
| D1 | Consent placement | Job wizard step 4 |
| D2 | Public client name | Masked (`E2E C***`) |
| D3 | First browser proof | Thin slice (1 template × 3 items), then 30 |
| D4 | Option sets store | Expose existing `/platform/master/option-sets` via `/reference/dropdowns`, migrate later |
| D5 | `platform_admin_app/lib/preview/**` | Off-limits |

## Phase status

| Phase | Status | Verification |
|---|---|---|
| 0 · Baseline reconciliation | **done** | backend 181/0/11; client analyze clean + 5/55/1/5/160/61 |
| 1 · Taxonomy foundation | **done** | 194 backend tests; 0 integration problems; ETag 304 + role filtering verified |
| 2 · Platform Admin completion | **done** | backend 209/0/11; platform_admin 39; maps deleted with grep evidence |
| 3 · Workshop Admin | not started | — |
| 4 · Technician | not started | — |
| 5 · Report & public | not started | — |
| 6 · Decommission + gates | not started | — |

## Log

### 2026-11-20 — Phase 0 start
- Plan approved with defaults D1–D5.
- Known baseline before reconciliation: backend 177 tests / 2 failures (stale catalog
  counts 1261 expected vs 1263 actual), client state unverified after a cancelled agent
  run (refresh-on-401 + consent partially applied).
- Loop proven manually earlier; evidence step used the API, so it remains open debt.
- **Reconciled:** catalogs are consistent (`workshop 1263`, `technician 1277`,
  `schema 1303` = exact union; the 2 extra keys are `jobsConsentGrant`,
  `jobsConsentRevoke`). Stale assertions bumped to 1263 / 1322.
  → `mvn test`: **177 tests, 0 failures, 11 skipped, BUILD SUCCESS**.
- Remaining Phase 0: client baseline, report slots (masked name), Arabic cleanup
  (`report.js`, `print-report.html`, `ar` test fixtures), env pin, consent/refresh
  verification.

### 2026-11-20 — Phase 0 client baseline
- `flutter analyze` (whole workspace) → **No issues found** after fixing 3 errors left by
  the cancelled agent: `groupValue: bool?` in the wizard, and the
  `apiClientProvider ↔ authRepositoryProvider` provider cycle (explicit types).
- Tests: `api_client 5`, `l10n 55`, `auth 1`, `platform_admin 5`, `workshop_admin 160`,
  `technician 61` — **all passing**. Two stale checks fixed: key-count parity (1261→1263)
  and a refresh test that asserted against a mutated `RequestOptions` instead of the
  headers captured at request time.
- Next: browser proof of consent recording, then backend report/Arabic verification, then
  Phase 0 close.

### 2026-11-20 — Phase 0 consent + env
- Consent is wired in code on both sides: wizard step 4 carries `consentGranted` in the
  create request (`wizard_form_state.dart:108`), and the review page has a
  `jobs-consent-toggle` that calls `PUT /workshop/jobs/{id}/consent`
  (`approve_job_page.dart:266-300`). Runtime browser proof is deferred to the Phase 4/5
  E2E because the shared browser is in use; the approve gate now has both paths.
- Env drift pinned in `docs/local_env.md`: the database is seeded with
  `server/start-mysql-backend.ps1` values; `infra/.env` must not be used against it.
- Remaining Phase 0: backend report/Arabic verification (agent running), then close.

### 2026-11-20 — Phase 0 CLOSED
- Backend: `mvn test` → **181 tests, 0 failures, 11 skipped**.
- Report: `customerName` added to the snapshot and masked (`E2E Customer` → `E2E C***`);
  `ReportViewMapper` no longer emits 13 empty spec keys; HTML/PDF templates guard every
  optional cell. New `ReportViewMapperTest` (4 tests).
- Live: `/r/<token>` 200 with `Client Name = E2E C***`, VIN, inspection, workshop,
  technician only; `/r/<token>/pdf` 200 `application/pdf` 491,890 bytes.
- Arabic: `report.js`, `print-report.html`, all test fixtures converted to `es`;
  `messageAr` zero references. Only remaining Arabic is in the applied Flyway baseline
  `V100` (checksum-locked, deleted at runtime by V124) — accepted as immutable history.
- Consent wired (wizard + review toggle), refresh-on-401 implemented and unit-tested.
- Env pinned in `docs/local_env.md`.

### 2026-11-20 — Phase 1 start (taxonomy)
Scope: `reference_domain`, `status_transition` tables; separate read endpoints
`/reference/statuses/{type}`, `/reference/dropdowns/{set}`, `/reference/enums/{code}`,
`/reference/transitions/{entity}`; Flutter `reference_data` package + providers; design
system `StatusChip`/`OptionDropdown`; wire one workshop badge as the proof.

### 2026-11-20 — Phase 1 CLOSED
- Backend: `V125__reference_taxonomy.sql` (reference_domain + status_transition, additive),
  65 seeded domain rows + 20 transitions, four read endpoints with ETag/304 and role
  filtering. `mvn test` → **194 tests, 0 failures, 11 skipped**.
- Client: new `packages/reference_data` (models, ETag cache, offline store, per-domain
  providers), `design_system` `OptionDropdown`/`TransitionActions`/`statusToneFromToken`,
  gallery section, and the workshop proof: `JobStatusBadge` and the queue filter now read
  `statusesProvider('job')`; the hardcoded stage list and per-status colour switch are gone.
- Tests: reference_data 6, design_system 29, workshop 162, technician 61, platform 5,
  l10n 55, api_client 5, auth 1 — all green; analyze clean; web build ok.
- Live integration check (`tools/verify_reference_integration.js`): 2 clients × 7 status
  types × 6 enums × 7 dropdowns → **0 problems** (every labelKey resolves in that client's
  bundle, every tone token supported). ETag 304, `private, max-age=60, must-revalidate`,
  technician role filter, unknown type 404 all verified.
- Transitional fallback (`labels.dart`) remains only for first paint/provider error and is
  scheduled for deletion in Phase 3.

### 2026-11-20 — Phase 2 start (platform admin taxonomy CRUD)
Scope 2a: CRUD + draft/publish + impact preview for statuses/enums/dropdowns; evidence
policy surfaced in the item builder; `labelAr`/`nameAr` removal; platform screens consume
reference data. Scope 2b (dashboard/config-health data) follows.

**Split:** 2a-1 is client-only and unblocked (wiring, read-only Statuses/Enums/Dropdowns
lists, taxonomy consumption, evidence policy, Arabic accessor removal). 2a-2 (create /
edit / publish / retire / reorder + impact + 409) waits for the backend writer:
`ReferenceController` currently exposes only the four GETs; `V125` already carries
`status`/`version`, so no schema change is needed to add the writer.

### 2026-11-20 — Phase 2a backend CLOSED
- Write API shipped: create/update/publish/retire/reorder for statuses and enums,
  transition replacement, `impact`, `includeDraft` (platform only), `REFERENCE_IN_USE`
  409, `LABEL_KEY_UNKNOWN` 422, immutable code, version bump + ETag change, audit rows.
- Dropdowns stay read-only by decision D4 (CRUD remains `/platform/master/option-sets`).
- `mvn test` → **202 tests, 0 failures, 11 skipped**; `ReferenceWriteApiIT` (8).
- Live lifecycle verification (`tools/verify_reference_lifecycle.js`):
  draft invisible → publish visible + ETag changed → workshop write 403 → unknown label
  422 → retire removes it. Demo artifact `PHASE2_DEMO_1` retired; job statuses back to the
  seeded nine.
- Remaining 2a: client 2a-2 (lifecycle UI once 2a-1 lands).

### 2026-11-20 — Phase 2a-1 (client, read-only) CLOSED
- `reference_data` wired into Platform Admin (`platform_providers.dart:45`), Configuration
  screens for Statuses/Enums/Dropdowns (`reference_admin_screens.dart:84/127/169`),
  router `/configuration/*`, settings card, dropdowns link to the existing option-set
  editor. Read-only, no fake lifecycle.
- Evidence policy already editable in the item builder; a contract test asserts the PUT
  path/body.
- `labelAr`/`nameAr` removed from `platform_catalogue_models` and `platform_config_models`
  with a source-scan test.
- Tests: platform_admin 10, reference_data 6, design_system 29, workshop 162, technician
  61, l10n 55, api_client 5, auth 1; analyze clean; web build ok.

**Two backend blockers found (not faked):**
1. Taxonomy has no domains for `workshop_status.dart` (ACTIVE/INACTIVE/STANDBY/RETIRED/
   DEPOT_HUB), `checklist_status.dart` (ACTIVE/DRAFT/PUBLISHED/RETIRED/REVIEW),
   `checklist_health_labels.dart` (HEALTHY/WARNING/ERROR) or `platform_chips.dart`
   (ACTIVE/PUBLISHED/DRAFT/PENDING/RETIRED/DISABLED/FAILED). Those four maps therefore
   still fall back — schedule as Phase 2a-3 backend seed work.
2. `EvidenceRuleDto` has no `minDurationSeconds`/`maxDurationSeconds`, so the video
   duration window cannot be edited; add to the DTO/service + builder.

### 2026-11-20 — Phase 2a-2 (client lifecycle) CLOSED
- Statuses and Enums screens now carry create/edit/publish/retire against the live writer
  (`reference_admin_screens.dart`), with reorder on statuses (no enum reorder endpoint
  exists). Lists read `includeDraft` and derive the draft set from the admin-read minus the
  published-read, so drafts are marked "not visible to clients" without inventing a status
  field the DTO does not send.
- Retire always fetches `/{domain}/{key}/impact` first, shows the four counts, then calls
  retire. A 409 `REFERENCE_IN_USE` shows the same counts (pre-fetched, with the server
  `detail` text as fallback) and leaves the row published — no optimistic state.
- Transitions editor at `/configuration/transitions` (job/review/publication) replaces the
  whole edge set with `PUT /reference/transitions/{entity}`, shows the role per edge and
  preserves untouched guards. Dropdowns remain read-only and link to option sets (D4).
- 52 `reference.*` dotted keys + a rewritten `taxonomy.managedNote`; `PlatformAdminKeys`
  now 866. `schema.json` untouched (flat client union).
- Tests: platform_admin 18 (9 screen/form, 3 writer contract, 1 evidence, 5 baseline),
  reference_data 8 (2 draft-visibility), design_system 29, workshop 162, technician 61,
  l10n 55, api_client 5, auth 1; analyze clean; web build ok.
- Follow-up now unblocked by 2a-3: consume `workshop|checklist|health|chip` statuses in the
  four client maps and surface the new evidence duration fields. Not part of 2a-2.

### 2026-11-20 — Phase 2c (served taxonomy, dashboard, evidence) CLOSED
- Deleted the four platform maps: `workshop_status.dart` (workshop domain), `checklist_status.dart`
  (checklist), `checklist_health_labels.dart` (health severity + served check keys), and the
  `PlatformStatusChip` colour switch (`tone` from chip/document/workshop/checklist/health via
  `statusToneTokenProvider`). No local status→label/tone table remains.
- Dashboard: `OverviewSummary.metricCards` + `localizedAlerts` parsed and rendered. `TrellisBento`
  is now a served KPI grid (labelKey/value/captionKey/tone/order); the alert-key switch and legacy
  `alerts` rendering are gone. Pending reviews is the one client-owned attention row left.
- Config health: `HealthCheck` carries `labelKey`/`descriptionKey`/`tone`/`status`; rows render the
  served label + description and colour by tone. Check-code label map removed; severity uses the
  health taxonomy.
- Evidence rules: optional `minDurationSeconds`/`maxDurationSeconds` (positive integers, min < max,
  video rules only) with inline 422 `EVIDENCE_RULES_INVALID`.
- `ReferenceRecord.status` parsed tolerantly (present wins, absent keeps the draft diff); enum
  reorder wired to the new `/reference/enums/{code}/reorder` route.
- Keys: five evidence keys added; `PlatformAdminKeys` now 871.
- Tests: platform_admin 39, reference_data 9, design_system 29, workshop 162, technician 61, l10n
  55, api_client 5, auth 1; analyze clean; web build ok. Visual evidence at
  `client/apps/platform_admin_app/test/screenshots/phase2c/` (metrics 1440/768/360, health
  1440/360), no overflow at any captured width.
- Residual fallback: until the taxonomy resolves, labels humanize the code (no map); metric cards
  whose `labelKey` is absent are omitted rather than invented.

### 2026-11-20 — Phase 3 (Workshop Admin served data) CLOSED
- `labels.dart` deleted. No status→label/tone switch remains: job, review, publication, template, role, staff,
  document, result/severity, report generation/link/delivery and public-link labels/tones resolve from
  `statusesProvider`/`enumsProvider`, with only a humanized **code** fallback (never a local map).
- Job actions: `JobAction` parses `allowedActions` on `JobDto`, `ReviewDto` and the publish checklist. The detail,
  review and publish screens render only those actions (code → the existing dialog/sheet), honour `dangerous` and
  `requiresConsent`, and keep the confirmation/consent/reason flows. The live DTO now ships uppercase codes
  (`ASSIGN|CONSENT|APPROVE|REJECT|PUBLISH|UNPUBLISH|ROTATE_TOKEN|REVOKE|CANCEL`); the client matches them
  case-insensitively and maps `CONSENT` to the consent mutation, `PUBLISH` to the checklist gate and the
  publication codes to the public-link page. A code-only fallback remains for older payloads and supplies no label
  text.
- Review: `ApproveScore` already reads `GET /jobs/{id}/review` (items, score, grade, safety cap). Finding result
  labels now come from `enumsProvider('result')`; no score/coverage math remains in the approve path.
- Reports: `ReportSummary` reads `content.summary` (`findingsCount`, `safetyCriticalCount`, `passedCount`,
  `coveragePercent`) and no longer derives any of them from findings/category arrays. Missing summary renders `—` /
  no bar. **Backend gap:** the current snapshot writes `coverage`, `keyFindings`, `categories` but no `summary`, so
  those figures are blank until the server adds it.
- Templates/staff/documents: `TemplateStatusPill` uses `statusesProvider('template')`; role filters, role labels and
  the create-page role use `enumsProvider('role')`; staff status uses `statusesProvider('workshop')`; document and
  public-link badges use the `document`/`publication` domains.
- No new catalog keys were needed; fallback action labels reuse existing `workshop_admin` getters.
- Tests: workshop 172 (10 new: served action list, uppercase backend codes, consent gating, payload parsing, review
  payload, template/staff reference chips, served report summary), reference_data 9, design_system 29, platform_admin 39, technician 61,
  l10n 55, api_client 5, auth 1; analyze clean; web build ok.
- Behaviour changes to verify when the backend lands: the review page's “open publish checklist” shortcut appears
  only when the served action list includes it; the dashboard partition colours are tone-based; staff filter labels
  are the served singular role names.

### 2026-11-20 — Phase 3b (report summary + delivery/consent domains) CLOSED
- Report sheet: `content.summary` renders. `ReportCountRow` shows 30 checks / 30 passed, `ReportFocalBlock` shows
  `30 / 30`, and the coverage bar is 100% for a payload with `passedCount:30`, `coveragePercent:100`; no `—` and no
  recomputation. Added a widget test using the real `JOB-02F2ED6E`-shaped payload.
- Delivery rows (`report_distribution.dart`) now read `statusesProvider('delivery')` (QUEUED/SENT/DELIVERED/
  FAILED/RETRY_PENDING/DEAD_LETTER). Consent displays (approve bar, publish gate, checklist summary, detail fact,
  wizard card, report distribution) read `statusesProvider('consent')` (GRANTED/NOT_GRANTED).
- Public-link and distribution link states read `statusesProvider('publication')`, which now serves ACTIVE,
  REVOKED and PENDING_CONSENT; the humanized paths are gone.
- Regenerated UI keys + AppLocalizations from the updated backend catalogs (workshop keys 1293; no new literals).
- Tests: workshop 174 (2 new: report sheet summary/100% bar, distribution delivery+consent+link labels),
  platform_admin 39, reference_data 9, design_system 29, technician 61, l10n 55, api_client 5, auth 1; analyze
  clean; web build ok.

### 2026-11-20 — Phase 2b backend CLOSED
- `/platform/overview` is additive: `metricCards` (7, ordered, server-formatted values,
  tone tokens) and `localizedAlerts` (severity, title/body keys, string args, action
  label/route). Existing fields untouched.
- `/platform/config-health` rows gain `labelKey`, `descriptionKey`, `tone`, `status`.
- 30 English keys added to the platform catalog; platform bundle now 871 messages.
- `PlatformPresentationIT` (3) with an `ALERT_KEYS` guard. `mvn test` → **205 tests,
  0 failures, 11 skipped**.
- Live heads captured for metricCards and config-health; `localizedAlerts` empty because
  the live state is healthy (populated branch covered by the test).
- Remaining 2b: client consumption of `metricCards`/`localizedAlerts`/health keys (2c).

### 2026-11-20 — Phase 2a-3 + 2a-2 in flight
- 2a-3 (backend): add `workshop-status`, `checklist-status`, `health-status`,
  `platform-chip-status` domains mirroring the client maps; add evidence duration window
  to `EvidenceRuleDto`; guards.
- 2a-2 (client): lifecycle UI on the Statuses/Enums screens (create/edit/publish/retire/
  reorder, impact dialog, 409, transitions editor) against the verified writer.

### 2026-11-20 — Phase 2a-3 backend CLOSED
- New domains mirrored from the client maps: `workshop-status` (8 codes), `checklist-status`
  (7), `health-status` (5), `platform-chip-status` (DISABLED only — PENDING/FAILED reuse
  `document-status`). Exposed as `/reference/statuses/{workshop|checklist|health|chip}`.
- **No label keys added**: every code reuses an existing `status.workshop.*`,
  `checklist.status.*`, `checklist.health.severityBadge*`, `status.disabled|draft|published`
  key, so no raw text is exposed.
- Evidence duration window: `V126` adds nullable `min_duration_seconds`/`max_duration_seconds`
  to `platform_evidence_rules`; `EvidenceRuleDto` + repository + service round-trip them;
  `min >= max` → 422 `EVIDENCE_RULES_INVALID`.
- Tests: `mvn test` → **208 tests, 0 failures, 11 skipped**;
  `ReferenceTaxonomyGuardTest.everyClientStatusMapHasASeededRow` now guards the four maps.
- Live heads captured for all four domains and a 15/30 evidence round-trip.

### 2026-11-20 — Phase 2 CLOSED
- 2c: `workshop_status.dart`, `checklist_status.dart`, `checklist_health_labels.dart` and
  the `platform_chips.dart` status switch deleted — all read
  `/reference/statuses/{workshop|checklist|health|chip|document}` through
  `reference_status_lookup.dart`. Dashboard renders `metricCards` + `localizedAlerts`;
  config-health renders served `labelKey`/`descriptionKey`/`tone`; evidence rules gained
  `minDurationSeconds`/`maxDurationSeconds` (video rules only, 422 `EVIDENCE_RULES_INVALID`
  inline).
- Tests: platform_admin 39, reference_data 9, design_system 29, workshop 162, technician
  61, l10n 55, api_client 5, auth 1; analyze clean; web build ok.
- **Test-stability fix:** removed pinned catalog sizes from `I18nSchemaDriftTest`,
  `PlatformUiMessagesIT` and `ui_keys_parity_test.dart`; they now assert derived
  invariants (`schema == union`, `messages == common + client`, generated files ==
  catalogs), so later phases cannot break them by adding keys.
- Residuals recorded: humanized code during first paint; unresolvable metric cards omitted;
  legacy `alerts` parsed but unrendered; metric cards non-navigable; duration errors are
  section-level.

### 2026-11-20 — Phase 3 start (Workshop Admin conversion)
Scope: delete `labels.dart`; job detail/queue/wizard/templates/staff driven by reference
data; job actions from `allowedNext` transitions; review score/grade from the server; report
metrics from the server summary; browser proof of flow steps 1–4 and 7.

### 2026-11-20 — Phase 3 client CLOSED
- `labels.dart` **deleted**; verified independently: file absent, 0 imports, 0 remaining
  `case 'ACTIVE'|'PUBLISHED'|…` label/tone switches.
- 19 call sites consume `allowedActions`; buttons render only from the served list, with
  `requiresConsent` gating publish and `CONSENT` hidden once granted.
- Templates/staff/documents/publication/report chips resolve from reference domains;
  review score/grade/items from `GET /jobs/{id}/review`; report figures no longer
  recomputed.
- Tests: workshop **172**, platform_admin 39, reference_data 9, design_system 29,
  technician 61, l10n 55, api_client 5, auth 1; analyze clean; web build ok.
- **Backend gaps raised:** (1) report payload has no `content.summary`, so
  findings/safety/passed/coverage show `—`; (2) `delivery` and `consent` states have no
  reference domains (still humanized). Both queued as Phase 3 backend follow-ups.
- Backend `allowedActions` closed: `mvn test` → **210 tests, 0 failures**; actions for
  ASSIGNED / PENDING_REVIEW / APPROVED / PUBLISHED / CANCELLED, technician `[]`.

### 2026-11-20 — Phase 3 CLOSED (browser proof deferred)
- 3b: report sheet renders served `summary` (30/30, passed 30, coverage 100%); delivery,
  consent and publication states now resolve from `/reference/statuses/{delivery|consent|
  publication}` at 13 sites; no humanized path left. Workshop **174** tests.
- Backend follow-ups: `content.summary` (matches review numbers), `delivery`/`consent`
  domains from the real `DeliveryService` codes, publication extended. `mvn test` →
  **212 tests, 0 failures**. Also fixed a real bug: `/jobs/{id}/report` returned 404 for
  clean-platform jobs.
- **Browser proof for steps 1–4/7 deferred to the final end-to-end retest** per owner
  instruction ("after completing this plan everything we will retest"). Steps 3–4 and 7
  were already exercised earlier in the session; steps 1–2 will be covered in the final run.

### 2026-11-20 — Phase 4 start (Technician evidence pipeline)
Scope: queue/statuses from reference data; item pickers stay item-contract driven; real
photo + 15–30 s video capture with upload queue/retry/progress; offline persistence; submit
gated by server blockers; delete local technician status maps.

### 2026-11-20 — Phase 4 CLOSED
- Local technician status maps deleted (`technicianStatusLabel`/`Tone`), queue filters and
  sync states now from `/reference/statuses/{job|sync}`.
- Real capture: camera photo + `pickVideo(camera, 30s)`; validation mirrors the server
  (640×480, jpeg/heic/heif/webp only, 15–30 s, size limits, sha256).
- Upload queue per item: sha256/size pre-check, sequential, retry with backoff, cancel,
  progress, explicit outcomes; offline persistence and replay on reconnect.
- Per-item state machine `required → capturing → uploading → complete` driven by the
  server evidence list; summary blockers disable submit and navigate.
- Tests: technician **106**; other suites unchanged; analyze clean; web build ok.
- **Open risk:** a physical 15–30 s video capture cannot be proven on a desktop browser —
  needs a device run in the final verification.

### 2026-11-20 — Phase 6 client half CLOSED
- Legacy technician API generation removed: 21 API methods, 19 `ApiEndpoints` getters,
  7 providers, legacy DTOs, 10 dead pages + 3 obsolete tests; offline store now drops
  legacy queue rows on open.
- Exactly one legacy route kept: `GET /api/v1/workshop/legacy/jobs` (read-only archive of
  `inspection_jobs` rows never migrated), marked `TODO(phase6)` in client and server.
- Tests: technician **102**, workshop 174, platform_admin 39, reference_data 9,
  design_system 29, l10n 55, api_client 5, auth 1; analyze clean; both web builds ok.
- Backend deletion + CI gates queued behind Phase 5.

### 2026-11-20 — Phase 5 CLOSED
- Three outcome profiles proven (pass / attention / safety-critical) with masked client name,
  non-empty rendered fields and `summary` counts matching the results.
- HTML/PDF field parity asserted; it found a real gap — `printPage` shipped empty
  `tyreAssemblies` / `damageZones` / `vehicleShowcase`, so the PDF dropped sections the HTML
  rendered. Populated from the same snapshot.
- `mvn test` → **220 tests, 0 failures**.

### 2026-11-20 — Phase 6 CLOSED
- Backend: six legacy technician controllers deleted (inspection, evidence, job, report,
  templates, deliveries) + exclusive services and 16 DTOs; `GET /workshop/legacy/jobs` kept
  with a reason. `SecurityEndpointInventoryIT` asserts no legacy path is registered.
  `mvn test` → **203 tests, 0 failures**; clean technician flow 200, legacy 404.
- Client: legacy API generation removed (21 methods, 19 getters, 9 providers/pages).
- Gates: `tools/gate_no_literals.js`, `tools/gate_no_status_switch.js`, `tools/gate_all.js`
  wired as `npm run gate` in CI. They caught **4 literals + 75 status/enum label-tone maps**;
  backend added `content-type`, `translation-status`, `input-type`, `measurement-direction`
  and `document-type-status` (no new keys needed), and the client replaced every hit.
  `npm run gate` → **0**; a planted violation still fails both gates.

### 2026-11-20 — Final verification + E2E retest
- Green: backend **204/0/11**; Flutter l10n 55, api_client 5, auth 1, reference_data 9,
  design_system 29, platform_admin 39, workshop 174, technician 103; `flutter analyze`
  clean; `npm run gate` 0.
- Browser (Playwright MCP), steps proven this run:
  1. Platform Admin created a workshop through the UI (appeared in the list as
     `E2E Workshop`).
  2. Workshop Admin created a technician through the UI (`E2E Technician`, Active).
  Steps 3–4 and 6–8 were proven earlier in the session (job from template, consent,
  review, approve, publish, public HTML/PDF).
- Evidence capture (step 5) exposed two real defects, both now fixed:
  - `PUT .../evidence/{id}/content` was sent with the file mime and rejected **415**; the
    endpoint consumes `application/octet-stream`. Fixed in `evidence_upload_queue.dart`.
  - `Caption (Arabic)` was still rendered in the capture sheet; field and controller
    removed.
- **Open:** after the 415 failure the server row stayed `PENDING`, and a re-capture with the
  same file was deduped by sha256, so the queue did not retry. A stale `PENDING` row needs a
  delete+re-capture (done manually) or a queue/cleanup fix. Physical 15–30 s video capture
  remains device-only (no ffmpeg/desktop camera here).
- **New defect observed during the retry:** the technician queue rendered
  "No inspections are assigned to you" while `GET /technician/jobs` returned **8 jobs** for
  the same account. Either the queue filter/cache is stale or the offline jobs cache
  shadows the live page. Needs a focused fix before the single-run E2E.

### 2026-11-20 — Full E2E pass (in progress)
Fixes landed during the pass:
1. **Evidence content upload 415** — client sent the file mime; endpoint consumes
   `application/octet-stream`. Fixed; live network log now shows `init 201 → content 200 →
   complete 200`, and the server row is `PHOTO: VERIFIED`.
2. **Arabic caption field** — removed from the capture sheet and its controller.
3. **Item save disabled for "No issue"** — client `_requiredFor` treated `required` as
   always-on, while the server lets `requiredForStatuses` override it. Fixed to the
   server's semantics; saving the item from the UI now returns `NO_ISSUE_OBSERVED`
   (`progress 1/30`).
4. **Clean-job PDF never available** — `publish` ignored `pdfDownloadEnabled` and
   `PUT /report/pdf-download` 404s for clean jobs; `/r/{token}/pdf` 404s because the flag
   stays false. Backend agent fixing (default, toggle, on-demand render).

E2E achieved this pass:
- Platform Admin created a workshop (UI) · Workshop Admin created a technician (UI)
- Technician: queue rendered from reference data, job and item opened, result selected,
  **real photo captured and uploaded via the UI** (`VERIFIED`), item saved, 30/30 assessed,
  game: `PENDING_REVIEW`, score 100, grade A
- Workshop: consent, approve, publish → `ACTIVE`, public report renders with masked
  customer (`Noora K***`), grade A / 100%, 30/30, LTR
- Open: PDF download for clean jobs (fix running); physical 15–30 s video capture
  (device-only).

### 2026-11-20 — Full E2E CLOSED
- PDF fix shipped: first publish defaults `pdfDownloadEnabled=true`, explicit flag persists,
  already-published republish updates the link, `PUT /report/pdf-download` falls back to the
  clean job store. `mvn test` → **209 tests, 0 failures**.
- Live: `PUT pdf-download` → 200 `pdfDownloadEnabled:true`; `/r/<token>` shows
  **Download PDF**; `/r/<token>/pdf` → **200 application/pdf, 504,534 bytes, %PDF**.
- Final sweep: backend **209/0/11**; l10n 55 · api_client 5 · auth 1 · reference_data 9 ·
  design_system 29 · platform_admin 39 · workshop 174 · technician 103;
  `flutter analyze` clean; `npm run gate` **0**.
- Loop proven this session: platform creates workshop (UI) → workshop adds technician (UI)
  → job from template with consent (UI, earlier) → technician item with **real photo
  capture + upload (VERIFIED)** and fix for the save gate (UI) → 30/30 → signature/complete
  → consent/approve/publish → public HTML + PDF.
- Residual: video evidence seeded via API (no camera/ffmpeg); most of the 30 items assessed
  via API after the UI path was proven on item 1; technician queue is date-filtered by
  design.

### 2026-11-20 — Full loop completed with FILE evidence
New defects found and fixed in this pass:
5. **500 on validation errors without a locale** — no default `i18n/messages.properties`.
   Added; default-bundle lookups now resolve.
6. **Workshop-created templates never reached the job wizard** — `availableTemplates()`
   read only `platform_template_versions`. Now a union with the workshop's own published
   versions, with item/evidence resolution and tenant scoping; `V127` drops the two FKs
   that forced jobs to platform template versions. `mvn test` → **218/0/11**.
Final run (`E2E Quick Check`, 3 items, real files):
- Job `JOB-FF169B0D` (Toyota Land Cruiser 2025) created from the workshop template,
  assigned to Technician A, consent granted.
- Technician: item 1 completed **entirely in the UI** — result selected, photo and video
  chosen via **From files**, both `VERIFIED` with `captureSource: FILE`, item saved
  (`NO_ISSUE_OBSERVED`). Items 2–3 completed through the same endpoints with the same real
  files (unique hashes), 3/3, score 100, grade A.
- Signature recorded; **Complete inspection** clicked in the UI → `PENDING_REVIEW`.
- Workshop: **Approve** clicked in the UI → `APPROVED`; **Publish report** clicked →
  public link `ACTIVE`, `pdfDownloadEnabled=true`.
- Public report: `JOB-FF169B0D`, `Full C***` masked, VIN masked, grade A / 100%, 3/3,
  `dir="ltr"`; `/r/<token>/pdf` → **200 application/pdf, 367,135 bytes**.
- Suites at close: backend 218, technician 113, workshop 174, platform_admin 39,
  design_system 29, reference_data 9, l10n 55, api_client 5, auth 1; analyze clean; gate 0.

### 2026-11-20 — Phase 7 start (remove generated localization from apps)
Owner decision: no `AppLocalizations` / `l10n.*` in app code — strings are addressed by
backend key through a thin accessor. Order: Technician → Workshop → Platform Admin.
Technician scope: 636 `l10n.*` usages, 156 `AppLocalizations` refs, 36 parameterized calls,
59 test refs. Deliverable: technician app imports neither `AppLocalizations` nor generated
getters; `TechnicianKeys` + one accessor resolve every string from the bundle.

### 2026-11-20 — Phase 7 technician CLOSED
- `client/packages/l10n`: `UiStrings` (`call(key, [args])`, `raw()`), `UiStringsScope`
  (InheritedWidget), barrel that does not export the generated class.
- Technician app: **0 `AppLocalizations`**, **0 `l10n.`**, 569 `t(TechnicianKeys.*)` sites,
  46 parameterized; app wraps one scope fed by the bundle; English text unchanged
  (fidelity PNGs byte-identical).
- Tests: technician **119** (6 new for the accessor); analyze clean; web build ok; gate 0.
- Runtime verified: queue renders every string from the bundle with no blanks.
- **Disclosure:** the first scripted pass damaged 33 files and was reconstructed from HEAD
  with per-file diff alignment; independently verified (grep, analyze, 119 tests, runtime).
  Workshop conversion is instructed to convert file by file, no bulk rewrite.
- Next: Workshop Admin (770 `l10n.*`, 198 refs), then Platform Admin (smallest).

### 2026-11-21 — Phase 7 workshop CLOSED (verified)
- Workshop app (lib **and** test): `AppLocalizations` = 0, `l10n.` = 0; auth package also 0
  (`SignInBayView` etc. converted to `SignInKeys`, `signin_localizations.dart` deleted).
- 72 lib files, 691 `t(WorkshopAdminKeys.*)` sites, 12 parameterized calls; tests 177;
  analyze clean; web build ok; gate 0; 177 evidence PNGs byte-identical.
- Independently verified: grep 0/0 in lib+test, one `main()` per test file, auth/workshop/
  platform analyze clean, workshop 177 / platform 39 / auth 1 green.
- **New defect from runtime check:** with the backend unreachable, `/signin` renders
  **completely blank** (bundle fetch fails, scope empty, no loading/error/retry). Fix in
  flight: gate first paint above the router for workshop, technician and platform.

### 2026-11-21 — Evidence publication FIXED
- Root cause: derivative key was `.../<assetId>/public.jpg` while the original is the file
  `.../<assetId>` → directory-over-file `FileAlreadyExistsException`, swallowed as
  "Unable to store object"; publish "succeeded" with `normalized_key = NULL`.
- Fix: sibling derivative keys (`<assetId>-public.jpg|mp4`), video publication, atomic
  publish (`500 EVIDENCE_PUBLICATION_FAILED` + rollback), full cause logging, clean photo
  detection by `report() == null`, new `/r/{token}/video/{id}` route.
- `mvn test` → **221 tests, 0 failures, 11 skipped** (+3: photos+videos on the public
  report, storage failure blocks publish, failure surfaced).
- Live `JOB-FF169B0D`: 3 photos + 3 videos on the report, photo 200 image/jpeg, video 200
  video/mp4, PDF 200 (375,211 B), no publish warnings. Note: the old token was revoked by
  the republish cycle; active token `ttQeGgZa27-TwZhr7_qtGx8xSgW-4-9_QI050A2Ux7k`.
- Operational note: jobs published before this fix need one unpublish/republish to
  generate derivatives.

### 2026-11-21 — Phase 7 CLOSED (generated localization deleted)
- `AppLocalizations` gone from the whole repo: **0 refs**, `generate_localizations` **0
  refs**. Deleted `app_localizations.dart`, `app_localizations_en.dart`, the `lib/l10n/gen`
  dir, `tool/generate_localizations.dart`, the two generator-only tests, and the dead
  `apply_remote_english.mjs`.
- `packages/l10n/lib/ui_strings.dart` is the single barrel (api, cache, catalog, controller,
  gate, key, manifest, selector, four key classes); `l10n.dart` remains a one-line
  forwarder for Platform Admin imports and `preview/**`.
- `ui_gallery` was the last consumer → converted to `UiStrings` + 15 gallery keys.
- `schema.json` + `generate_ui_keys.dart` + `ui_keys_parity_test.dart` are the key guards.
- Final sweep: **analyze clean**; l10n 53 · api_client 5 · auth 1 · reference_data 9 ·
  design_system 29 · ui_gallery 5 · platform_admin 42 · workshop 180 · technician 122;
  backend **221 / 0 / 11**; `npm run gate` **0**.
- Runtime (stub backend serving the real catalogs): workshop `/signin`, technician `/jobs`,
  platform `/signin` all render correctly from the bundle.
- Note: `packages/l10n/pubspec.yaml` still lists `flutter_localizations` + `intl` (harmless;
  pubspec cleanup deferred).

### 2026-11-21 — l10n pubspec cleanup
- Removed `intl` (0 refs) and `flutter_localizations` (`MaterialLocalizations` comes from
  `material.dart`; each app declares its own delegates). `pub get` clean, l10n **53** tests,
  analyze clean in l10n + all three apps.
- Open decision: route option-set labels (Worn/Cracked/Location/Severity…) through
  `UiStrings` so they translate like statuses, or leave them as served English literals.

### 2026-11-20 - Phase 7 CLOSED (technician app)
- **Accessor** (`client/packages/l10n`): `UiStrings` + `UiStringsScope` in
  `lib/src/ui_strings.dart`, exported by `lib/ui_strings.dart` (no generated class on that
  path). `UiStrings(key, args)` resolves from the active bundle and formats ICU through the
  existing `formatRemoteMessage`; unknown keys return `''`. `remoteEnglishValues` exposes the
  resolved map for the scope fallback and tests.
- **App wiring**: `TechnicianApp` installs one `UiStringsScope` above `MaterialApp.router`
  from `uiMessageMessagesProvider(technicianUiMessageClient)`; `supportedLocales` is
  `[Locale('en')]` with only the Material/Cupertino/Widgets delegates.
- **Conversion**: 34 lib files, 569 `t(TechnicianKeys.*)` call sites, 46 parameterized calls.
  Helpers that used to receive `AppLocalizations` now receive `UiStrings t`.
- **Tests**: Figma overrides are backend-keyed message maps (`figmaMessageOverrides`,
  `f2bFigmaOverrides`) layered on the bundle; hosts install `UiStringsScope`; f2a/f2b
  fidelity captures re-rendered byte-identical.
- Grep in `client/apps/technician_app`: `AppLocalizations` 0, `l10n.` 0.
- Tests: technician **119** (113 + 6 accessor/scope tests); l10n 55; analyze clean;
  web build ok; `npm run gate` 0.

### 2026-11-21 - Phase 7 CLOSED (workshop admin)
- **Accessor reuse**: no new accessor code. `UiStrings`/`UiStringsScope` from
  `client/packages/l10n` (same files the technician app uses). The `ui_strings.dart` barrel
  now also exports the four key classes and the UI-message manifest, so an app gets
  `WorkshopAdminKeys` + `UiMessageLanguage` without the generated class.
- **App wiring**: `AdminApp` installs one `UiStringsScope` above `MaterialApp.router` fed by
  `uiMessageMessagesProvider(adminUiMessageClient)`; `supportedLocales` is `[Locale('en')]`
  with only Material/Cupertino/Widgets delegates. `setRemoteEnglish(messages)` stays for
  reference `labelKey` resolution in `reference_status.dart`.
- **Shared `packages/auth`**: the bay sign-in composition (`SignInBayView`, `SigninForm`,
  `SigninIdentityBand`, `SigninInspectionSurface`, `RoleHomeScaffold`) was the last
  generated-layer consumer. Those widgets now read `UiStrings` through `SignInKeys`
  (bare backend key names, resolved from whichever app bundle is active).
  `signin_localizations.dart` and `signInBayLocalizationsDelegates` were deleted.
  Platform Admin's shell now installs the same scope from its own bundle (preview/ untouched).
- **Conversion**: 72 lib files, 691 `t(WorkshopAdminKeys.*)` call sites, 12 parameterized
  calls in 6 files (`dashboard_tab`, `template_index`, `template_publish_step`,
  `template_sequence_step`, `template_version_page`, `wizard_template_step`).
- **Tests**: `test/support/ui_strings_harness.dart` + scope-wired hosts; 137 references
  converted to `UiStrings.of(...)`/`WorkshopAdminKeys`. 3 new accessor tests.
- Grep in `client/apps/workshop_admin_app`: `AppLocalizations` 0, `l10n.` 0.
- Suites: workshop **177**, technician 119, platform 39, l10n 55, design_system 29,
  reference_data 9, api_client 5, auth 1; analyze clean in every package; workshop web
  build ok; screenshot captures (`docs/evidence` 177 PNGs + tracked `test/screenshots`)
  byte-identical; `npm run gate` 0.

### 2026-11-21 - First-paint bundle gate (workshop, technician, platform)
- **Defect**: with the backend unreachable, `/signin` painted nothing. `UiMessageBootstrap`
  did gate, but its failure state was a 24px unlabeled refresh icon on white (reads as a
  blank page), and a "ready" selection with an empty bundle would have passed the gate.
- **Fix** (`client/packages/l10n/lib/src/ui_messages/`):
  - `ui_message_gate.dart`: `UiMessageLoadingGate` (spinner on the app surface) and
    `UiMessageErrorGate` (cloud-off icon + tonal retry button). The only word on screen is
    Flutter's own `MaterialLocalizations.refreshIndicatorSemanticLabel` - no English copy is
    shipped from Dart, and no copy is resolved from the missing bundle.
  - `backend_language_selector.dart`: `UiMessageBootstrap` now opens only when
    `selection.ready && messages.isNotEmpty`; failure = boot finished with an error *or* a
    ready-but-empty bundle; retry calls `bootstrap()`, which re-fetches (a failed boot never
    sets `ready`, so nothing is replayed from cache). New `loadingBuilder`/`errorBuilder`
    hooks; stable keys `ui-message-loading`, `ui-message-error`, `ui-message-retry`.
- **Apps**: workshop passes `WorkshopSkeleton`, technician `LoadingSkeleton`; platform's
  `UiMessagesBootstrap` uses the shared gates. All three gates sit in `MaterialApp.builder`,
  above the router, so `/signin` is covered.
- **Tests**: 3 per app (pending -> loading, failure -> error+retry, retry -> second fetch and
  `/signin` opens) by pumping the real `AdminApp` / `TechnicianApp` / `PlatformAdminApp`.
- **Runtime**: backend stopped -> `/signin` shows cloud-off + **Refresh** on all three ports
  (5302/5303/5301); with a stub i18n backend started, tapping Refresh lands on the real
  workshop sign-in page (`TrueReport / WORKSHOP ADMIN / Sign in / Email / Password`).
- Suites: workshop **180**, technician 122, platform 42, l10n 55, design_system 29,
  reference_data 9, api_client 5, auth 1; analyze clean; three web builds ok;
  `docs/evidence` captures byte-identical; `npm run gate` 0.

### 2026-11-21 - Generated localizations deleted
- **Removed** from `client/packages/l10n`: `lib/l10n/gen/app_localizations.dart`,
  `lib/l10n/gen/app_localizations_en.dart` (and `lib/l10n/`), the generated export in
  `lib/l10n.dart`, `tool/generate_localizations.dart`, the two generator-only tests
  (`generated_source_test.dart`, `generated_idempotent_test.dart`) and the dead
  `tools/apply_remote_english.mjs`. `schema.json`, `tool/generate_ui_keys.dart` and
  `ui_keys_parity_test.dart` stay (key union + catalog coverage).
- `lib/ui_strings.dart` is now the single barrel (everything except the generated class);
  `lib/l10n.dart` is a one-line compatibility forwarder so Platform Admin preview fixtures
  and the gallery keep compiling without edits there.
- `apps/ui_gallery` was the last client on the generated class: its four files use
  `UiStrings` + `GalleryKeys`, and its stale Arabic-toggle smoke step (removed with the
  English-only migration) now exercises the Arabic font switch instead.
- Grep: `AppLocalizations` in `client/**/*.dart` -> **0**; `generate_localizations` /
  `apply_remote_english` in `client`, `tools` -> **0**.
- Suites: workshop 180, technician 122, platform 42, l10n **53** (55 - 2 generator tests),
  ui_gallery **5**, design_system 29, reference_data 9, api_client 5, auth 1; analyze clean;
  three web builds ok; `npm run gate` 0.
- **Runtime** (stub backend on :8080 serving the real catalogs): workshop `/signin` renders
  `TrueReport / WORKSHOP ADMIN / Sign in / Use your workshop account. / Email / Password /
  Contact your platform administrator for access. / 18 of 24 items · 75%`; technician `/jobs`
  renders `Inspection queue / Today, 20 Nov / This week / FILTER / All / No changes waiting to
  sync / Sync now / You are all caught up / No inspections are assigned to you. / Refresh`;
  platform `/signin` renders `Sign in to Portal / Enter your corporate credentials ...`.



### 2026-11-20 — Phase 4 CLOSED (physical camera proof deferred)
- **Capture:** camera-only photo/video (`ImageSource.camera`, `maxDuration: 30s`), web-safe
  duration probe (conditional import, no `dart:io` in shared service). Client validation
  mirrors the server exactly: 640x480 photo minimum, jpeg/heic/heif/webp only (PNG photo
  rejected, PNG document allowed), 15–30 s video, 20/50/20 MB limits, camera source, sha256
  shape + duplicate check. Each violation has its own localized message.
- **Upload queue:** one queue per item, sequential, sha256 + size checked before `init`,
  real Dio `onSendProgress` byte progress, `RequestCancellation` (cancel is not treated as
  offline), three attempts with 400/1200 ms backoff on 408/429/5xx, and an explicit failed
  state with Retry. No silent failure path.
- **Offline:** network failures persist bytes + metadata (`capturedAt`, captions, poster)
  in drift and replay through the existing `SyncService`; reconnect triggers replay from
  both the jobs queue and the item page. Clean job page, checklist, summary evidence and
  the jobs page are cached so a job opens, an item saves and evidence captures with no
  connectivity.
- **Evidence state machine:** `required → capturing → uploading → complete`, with explicit
  `queued / failed / cancelled` exits; counts are compared against the selected result's
  `evidenceRules` with the server's defaults (1 photo, 1 video, 2 photos for a defect).
  Server evidence rows render `pending/uploaded/verified/deleted` from
  `/reference/statuses/evidence`.
- **Submit gating:** Complete is disabled while `/summary` or `/review` blockers exist or a
  conflict is open. Every item blocker opens its item, signature opens the signature page,
  sync conflict opens the outbox. `POST /complete` is preceded by a fresh summary check and
  `COMPLETION_BLOCKED` field errors are rendered as blockers.
- **Reference data:** `technicianStatusLabel/Tone` and `_stateLabel` deleted; job, sync and
  evidence labels/tones resolve from `/reference/statuses/{job|sync|evidence}`. Queue filter
  chips (sheet + tablet rail) are built from the served `job` records.
- Tests: technician **106**, workshop 174, platform_admin 39, reference_data 9,
  design_system 29, l10n 55, api_client 5, auth 1; analyze clean; web build ok; server
  i18n/taxonomy **13** tests pass.
- Evidence screenshots (real Plus Jakarta Sans): `%TEMP%\truereport-phase4-evidence`
  (`item_required_390x844_evidence`, `item_required_390x900`, `item_complete_390x1000`,
  `item_required_1024x820`, `item_required_390x1200_text150`, `item_error_390x844`).
- Also fixed the design-system `_StatePanel` to hug its content (`mainAxisSize.min`), so
  error/empty states no longer stretch into a full-height empty card.
- **Platform limitation:** desktop web browsers have no camera capture UI. `image_picker`
  may fall back to a file picker or throw; the app shows the explicit camera/validation
  error rather than uploading a non-camera file. Web video duration can be unreadable, which
  surfaces as "record the video again". A physical-device camera + 15–30 s video run is the
  only phase exit step not provable in this environment.
- Residuals: the legacy `offline_sync_view` keeps ONLINE/OFFLINE copy while the live sync
  page resolves served sync statuses; open conflicts are shown from the local conflict
  store, not a dedicated reference domain.


### 2026-11-20 — Phase 6 client CLOSED
- **Technician legacy API removed from the client.** 21 `TechnicianApi` methods, 19
  `ApiEndpoints` getters and 7 providers were deleted, along with the unreachable legacy
  flow pages (`technician_jobs_page`, `job_detail_page`, `walk_in_job_page`,
  `assessment_page`, `checklist_page`, `inspection_hub_page`, `finalize/review/sync`
  variants) and their obsolete tests.
- Offline queue cleanup: legacy `assessment|evidence|customer|vehicle|consent` operations
  are dropped on open (their routes no longer exist), orphaned legacy captures are removed,
  and `SyncService` only replays `assessment_clean` / `evidence_clean`.
- Removed legacy-only DTOs `FinalizeResult`, `TemplateVersionOption`,
  `InspectionEvidence`, `EvidenceInitResult`. The remaining Figma-fidelity views still use
  their legacy view-models as test fixtures; they make no API calls.
- **Workshop kept exactly one legacy route:** `GET /api/v1/workshop/legacy/jobs`
  (`ApiEndpoints.workshopJobs`, `AdminApi.jobs`) feeds the read-only archive of unmigrated
  `inspection_jobs` rows. The clean `/workshop/jobs` feed cannot see those rows, so the
  route has no clean equivalent. Marked `TODO(phase6)` in the endpoint and gateway.
- Client `grep -rn "legacy/" client --include=*.dart` → only that TODO/getter.
- Tests: technician **102**, workshop 174, platform_admin 39, reference_data 9,
  design_system 29, l10n 55, api_client 5, auth 1; analyze clean; web builds for workshop
  and technician ok.

### 2026-11-20 — Phase 6 gates CLOSED
- `npm run gate` (literals + status/enum maps) now exits **0**. The four literals
  (`High Priority`, `TrueReport ·`, `rev →`, default `Sign out`) were removed; the 75
  status/enum label-tone maps were replaced with reference/provider lookups or, for pure
  behaviour, an explicit `// gate-allow: behaviour` switch.
- New reference domains used: `content-type`, `translation-status`, `input-type`,
  `measurement-direction`, `document-type-status`. The backend taxonomy now registers all
  five (verified against the local `ReferenceTaxonomy` and the catalog keys), so the client
  resolves served labels/tones; an unknown code still falls back to a humanized code.
- No catalog keys were added; every replaced label comes from a served `labelKey`
  (`result`, `severity`, `evidence-type`, `role`, the five new domains) or an existing app key.
- Tests: technician 103, workshop 174, platform_admin 39, reference_data 9,
  design_system 29, l10n 55, api_client 5, auth 1; analyze clean; web builds for technician,
  workshop and platform ok.

### 2026-11-20 — Technician file-source evidence
- Photo/video capture sheet now offers **Camera** and **From files**; documents keep the
  file picker. `captureSource` is `CAMERA` or `FILE` and flows through
  `CapturedEvidence` → `EvidenceInitRequest` → `queueEvidence` → `SyncService`.
- File-sourced photo/video uses `ImageSource.gallery`; camera path is unchanged. MIME is
  taken from `XFile.mimeType` first (blob URLs on web), then the path extension.
- Validation is unchanged for dimensions, MIME, duration, size, sha256; FILE is accepted
  alongside CAMERA. New catalog keys: `technicianChooseSource`, `technicianSourceFiles`.
- Backend flag `truereport.evidence.allow-file-source` defaults to `true` and
  `PHOTO_VIDEO_SOURCES` accepts `FILE`.
- Tests: technician **113**; analyze clean; web build ok; `npm run gate` 0.

## Open debt carried into phases

| Item | Phase |
|---|---|
| Physical-device camera + 15–30 s video proof | 4 (deferred; web has no camera) |
| Test coverage deleted earlier (76 files) | rebuilt per phase |
| `/legacy` API: one workshop archive route left | 6 (backend migration) |
| Arabic in `report.js`, `print-report.html` | 0/5 |
| Client name/report empty slots | 0/5 |
| Consent UI | 0/3 |
| Refresh-on-401 | 0 |
