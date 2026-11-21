# TrueReport — implementation progress

Plan: `docs/plan_full_completion.md` · Started 2026-11-20 · Owner-approved defaults D1–D5.

## Decisions

| # | Decision | Value |
|---|---|---|
| D1 | Consent placement | Job wizard step 4 |
| D2 | Public client name | Masked (`E2E C***`) |
| D3 | First browser proof | Thin slice, then full |
| D4 | Option sets | Exposed via `/reference/dropdowns` |
| D5 | `platform_admin_app/lib/preview/**` | Off-limits |

Localization/content decisions (2026-11-21): English canonical; DB store for content
translations; JSON only as reviewed registry + export; LibreTranslate async behind a
provider SPI; safety-critical copy requires review; languages driven by `i18n/languages.json`.

## Status

| Phase | State | Evidence |
|---|---|---|
| 0 · Baseline reconciliation | done | backend + client green; loop fixes |
| 1 · Taxonomy foundation | done | 194 tests, 0 integration problems |
| 2 · Platform Admin completion | done | 209→224 tests; maps deleted |
| 3 · Workshop Admin | done | 174 tests; `labels.dart` deleted |
| 4 · Technician evidence | done | 106 tests; real capture + queue |
| 5 · Report & public | done | 220 tests; HTML/PDF parity |
| 6 · Decommission + gates | done | 203 tests; 6 controllers deleted; gaps 0 |
| 7 · Localization removal | done | 0 `AppLocalizations`, 0 `l10n.` |
| C-i18n A · content resolver | done | 228 tests; es/fr live proof |
| C-i18n B · jobs + SPI | done | 233 tests; reverse authoring proven |
| C-i18n C · LibreTranslate | done | 250 tests; stub proof |
| C-i18n D · review + gates | done | queue + 409 issue dialogs + server gate |
| C-i18n E · report language | done (server + client) | snapshot language, es/fr bundles, HTML+PDF |

## Chronology

### Phase 0 — baseline
- Catalog reconciliation (workshop 1263 / technician 1277 / schema 1303 at the time).
- Consent control wired (wizard + review toggle), refresh-on-401 with single-flight retry,
  report slots masked + optional fields omitted, Arabic removed from code/API/templates.
- Env drift pinned in `docs/local_env.md`.

### Phase 1 — taxonomy
- `V125` reference_domain + status_transition; 65 domain rows, 20 transitions.
- `/reference/statuses|enums|transitions|dropdowns` with ETag/304, role filtering.
- Client `packages/reference_data` (ETag cache, offline store, providers), design-system
  `StatusChip`/`OptionDropdown`/`TransitionActions`; workshop badge + queue filter wired.
- Live integration: 2 clients × 7 status types × 6 enums × 7 dropdowns → 0 problems.

### Phase 2 — Platform Admin
- Lifecycle UI (create/edit/publish/retire/reorder, impact dialog, real 409, transitions).
- `metricCards` + `localizedAlerts` + keyed config-health; evidence durations.
- Deleted `workshop_status` / `checklist_status` / `checklist_health_labels` /
  `platform_chips` maps; dashboard no longer computes numbers.
- Test stability: removed pinned catalog counts; derived invariants instead.

### Phase 3 — Workshop Admin
- `labels.dart` deleted (0 imports, 0 status→label/tone switches).
- Actions from `allowedActions` (`status_transition` + role + guards), 19 call sites.
- Report reads server `summary`; delivery/consent/publication from reference domains.
- Backend: `content.summary`, delivery/consent domains, `/jobs/{id}/report` 404 fixed.

### Phase 4 — Technician
- `image_picker` capture, server-mirrored validation, upload queue (retry/cancel/progress),
  offline replay, per-item state machine, blocker-gated submit.
- Physical camera proof deferred (no device); later unblocked by file-source evidence.

### Phase 5 — Report & public
- Three profiles (pass/attention/safety-critical) with masked name and no empty cells.
- HTML/PDF parity test found `printPage` shipping empty tyre/damage/showcase sections; fixed.

### Phase 6 — Decommission + gates
- Six legacy technician controllers deleted; `GET /workshop/legacy/jobs` retained (archive).
- `gate_no_literals` + `gate_no_status_switch` wired as `npm run gate` in CI; caught 4
  literals + 75 maps; all fixed.

### Phase 7 — localization removal
- Technician: `UiStrings.call(key,[args])` + `UiStringsScope`; 0/0; 119→122 tests.
- Workshop + `packages/auth` (sign-in keys) converted; 0/0; 177→180 tests.
- Blank first paint on API failure fixed (gate above router, error + Refresh).
- Generated `AppLocalizations` + generator deleted repo-wide; `schema.json` retained as the
  key-union guard; `l10n` pubspec drops unused `intl`/`flutter_localizations`.
- Option values key-addressed: `V128 label_key`, 95/95 keyed, `labelKey` on checklist and
  option-set payloads, 95 keys + 30 Spanish entries in `common`, `CommonKeys` 59→154.

### Content i18n — A (resolver)
- `V129 content_translation` + `translatable_field`; `LanguageCatalog` reads the manifest
  only (fr added as proof); request context `Accept-Language` → preference → default.
- Resolver (exact → default → English, stale by hash, cached, batched); manual write/delete
  + coverage endpoints; master + checklist reads wired additively.
- Live: `es` label renders Spanish; `fr` falls back; coverage `ITEM.label 31/1/30`,
  `instruction 31/0/31 safetyCritical`.

### Content i18n — B (jobs)
- `V130 content_translation_job`; provider SPI + fake; change detection enqueues one job per
  enabled language, stale marking, dedupe, delete cleanup.
- Worker: skip-locked claim, batches of 25, retries/backoff, idempotent by hash.
- Reverse authoring: `Content-Language: es` stores authored text and derives English via
  `TO_CANONICAL`; `translationStatus` additive.
- Live: `Sistema de frenos` authored in `es` → English derived (MACHINE/PENDING_REVIEW).

### Content i18n — C (LibreTranslate adapter)
- Worker boundary: claim tx → provider outside tx → persist tx; stale lease recovery.
- `LibreTranslateProvider` array-first with per-text fallback, retry/`Retry-After`, clear
  unknown-language failure, bean wiring guard.
- `ContentProtector` (placeholders, VIN/plate/URL/email, units, ranges, custom patterns) with
  `PLACEHOLDER_LOST` on loss.
- `translation_glossary` (V131) + en→es automotive seed + CRUD.
- Compose profile `libretranslate` (en,es,fr only, healthcheck) + run docs.
- Live stub: protected fragments intact through `es`/`fr`.

### Content i18n — D/E client half
- **Wizard language** (`wizard_technician_step.dart`): the preferred-language chips now come from
  `languageSelectionProvider(adminUiMessageClient).manifest.languages`, showing `displayName`
  (`nativeName`), defaulting to the workshop's active UI language (or `en`). `preferredLanguage`
  still rides `NewCleanJob.preferredLanguage` to the server.
- **Review queue** `/configuration/translations`: language dropdown from
  `/platform/i18n/languages`, pending/reviewed/stale filters, summary pills (pending,
  reviewed, stale, safety-critical pending/blocked), rows with entity/field/lang, source,
  machine output, provider and safety badge; Approve / Edit (inline body) / Reject (note)
  post the Phase D API and invalidate queue + summary, so every decision reconciles with the
  server. Linked from Settings and from the 409 dialog.
- **Publish gate**: `TranslationIssue` parses the ProblemDetails `errors` array once
  (`api_client`). Workshop template publish, workshop job publish and platform master-item
  publish open a dialog listing entity/entityId/field/lang/reason; the platform variant links
  into the review queue at the blocking language. No more "Action failed" swallowing.
- Keys: platform_admin 871→912, workshop_admin 1293→1300, schema 1364→1371; CommonKeys 154.
- Tests: workshop **183** (+3: wizard languages + request code, 409 dialog), platform **53**
  (+6: approve/edit/reject endpoint calls, summary refetch, issue parsing, 409 dialog).
- Runtime (stub): the queue renders Español / Pending / 3 rows with the safety badge; approving
  the first row removes it from the refetched list.


### Content i18n — E (report snapshot, HTML and PDF)
- **Snapshot language**: `WorkshopJobAdminService.reportLanguage(job)` reads
  `job.preferredLanguage` (fallback: catalog default) and writes `language` into the
  snapshot at approval. `?lang=` on `/r/{token}` no longer overrides a published snapshot.
- **Localized content**: item `label`/`instruction`/`standardSpec` and category `label`
  resolve through `ContentTranslationService` (English fallback) with the English source
  kept in `labelEn`/`instructionEn`/`standardSpecEn`.
- **Publish gate**: job publish runs `assertJobPublish(job items, reportLanguage)` and returns
  `409 TRANSLATION_REVIEW_REQUIRED` (issues capped at 50) for missing/stale/unreviewed
  safety-critical copy; `gate=safety_critical|all|off`.
- **API**: `preferredLanguage` on create/update now accepts every language declared in
  `i18n/languages.json` (`LanguageCatalog`), instead of an English-only allow-list.
- **Bundles**: `report_es.properties` covers every `report_en.properties` key (guarded by
  test); `report_fr.properties` ships partial on purpose to prove per-key English fallback;
  `ReportMessages` is locale-driven. `delivery_es.properties` follows the same pattern.
- **Templates**: `public-report.html` and `print-report.html` render the snapshot language
  (`<html lang="es" dir="ltr">`); item specs are no longer blanked in the view mapper, and
  the PDF's structural labels come from the bundle.
- Live: `es` job → Spanish HTML/PDF (`Informe de inspección`, `Año`, `Transmisión`, `Emitido`,
  `Total de comprobaciones`), localised item/category labels and `data-standard`; `en` job
  unchanged; rejecting one `es` instruction → publish `409`, re-approve → `200`.

### Content i18n — F (explicit backfill)
- `POST /api/v1/platform/i18n/content/backfill` (platform admin) scans the enabled
  `translatable_field` registry and enqueues `FROM_CANONICAL` jobs for canonical text that has
  no translation row, a blank body, `STALE`, or a hash that no longer matches the source.
- Current `REVIEWED`/`PENDING_REVIEW` rows and already `PENDING`/`RUNNING` jobs are skipped;
  `AUTHORED` rows are never replaced by machine output (counted as skipped).
- Optional `languages` (default: every non-canonical language in `i18n/languages.json`),
  `entityTypes` (default: every entity in `translatable_field`), `dryRun` (counts only).
  Unknown language → `422 LANGUAGE_UNKNOWN`, canonical language → `422 LANGUAGE_DEFAULT`,
  unknown entity type → `422 ENTITY_TYPE_UNKNOWN`.
- Idempotent through `uq_content_translation_job`; only jobs that actually became pending are
  counted. The provider is never called inline — the worker drains the queue.
- One log line: `backfill enqueued=… skipped=… languages=… entityTypes=… dryRun=…`.

### Content i18n — G (LibreTranslate hardening)
- **Per-text placeholder tokens**: `ContentProtector` now emits globally unique numeric tokens
  (`#1000123#`), so a provider batch can never share/merge restore maps. Plain digits are used
  because LibreTranslate preserves `#123#` but mangles longer random bodies and `[[…]]`
  wrappers. Restore stays per text; a missing token fails that job only. An altered wrapper
  (`#123#` → `#123`, spacing) fails with `PLACEHOLDER_LOST: #123# (wrapper altered)` instead of
  corrupting copy.
- **NO_CHANGE**: FROM_CANONICAL output that only differs by trim/whitespace/case is not stored;
  the previous row is deleted, the job is `FAILED` with `NO_CHANGE` (no retry loop) and
  coverage counts the field as missing. Product names inside a real translation are kept.
- **Post-edit ordering**: glossary post-edit now runs on the tokenized text *before* restore,
  so it can never rewrite a restored URL/VIN/measurement. Whole-word matching unchanged.
- **Provider-hostile symbols**: `&`, `<`, `>` are protected as tokens too — LibreTranslate turns
  `&` into a quote and drops `<`/`>` with the value after them (`Temperature >50 C` →
  `Temperatura C`).
- **Glossary V133**: locks en→es `urgency/severity/component/inspection/chassis/subframe/
  floor pan/rail/hose/worn out` and promotes `coolant/tyre/rim/brake pad/brake disc/worn`
  from V131 to locked; the protector swaps them before the provider call.
- Live: `libretranslate` en→es backfill drained with 0 `PLACEHOLDER_LOST`, `NO_CHANGE` jobs
  separated from real translations.

### Content i18n — H (language query + content-loss guard)
- **`?lang=` resolution**: `RequestLanguageContext` now checks `?lang` first (supported code wins
  over `Accept-Language`), then the header, saved preference, default. An unsupported value logs
  at debug and falls back — never a 5xx. This covers every read that resolves through the
  context (workshop master items/categories/item detail, option sets/values, reasons, equipment,
  dropdowns, document types, technician checklist). `MasterContentService` now validates an
  explicit `lang` through the same resolver, so platform-admin master reads share the rule.
  `authoringLanguage()` deliberately ignores `?lang`.
- **`&` normalization**: before the provider call the worker rewrites a textual `&` to `and`
  (URLs/codes/VINs are already placeholders, so their `&` is untouched). This stops LT from
  dropping the word after `&` or turning it into a quote.
- **Content-loss guard**: after translation, an output with fewer than 60 % of the source words,
  or ending in a dangling `&`, `and`, `y`, `,`, `;` or `-`, is rejected: previous row deleted,
  job `FAILED` with non-retryable `TRUNCATED`. Legitimately short translations (`Radiator` →
  `Radiador`) pass.
- Tests: language matrix (`?lang`, header, query+conflicting header, unsupported fallback) for
  items/categories/checklist/platform; `&` normalization incl. URL; truncated/dangling
  rejection; legitimate short translation.


## Current numbers

```
backend                    334 tests · 0 failures · 12 skipped
l10n 58 · api_client 5 · auth 1 · reference_data 9 · design_system 29
ui_gallery 5 · platform_admin 107 · workshop 201 · technician 133
flutter analyze            clean
npm run gate               0
playwright e2e             33 tests · 32 passed · 1 skipped (es public report needs a reviewed job)
content es                 388/388 catalogue units · 0 missing · 348 pending review (55 safety)
ui catalogs es             common 154/154 · workshop 1300/1300 · technician 1332/1332
                           platform_admin 0/984 (English-only by design)
```

### Live LibreTranslate run (no Docker)
- Installed in a Python 3.12 venv (`%TEMP%\lt-venv`); first start failed on Windows cp1252
  (`→` in the model updater) → fixed with `PYTHONUTF8=1`, `PYTHONIOENCODING=utf-8`.
- Running on `127.0.0.1:5000` with `--load-only en,es,fr`, models cached in
  `%USERPROFILE%\.local\share\argos-translate\packages` (~550 MB; subsequent starts are
  instant). Documented in `docs/local_env.md`.
- API wired with `I18N_TRANSLATION_PROVIDER=libretranslate`; backfill `es`:
  `enqueued=394 skipped=15` (human rows untouched) → **349 DONE · 45 FAILED (NO_CHANGE)**,
  0 `PLACEHOLDER_LOST`, 0 `TRUNCATED`, 349 machine rows, 0 dangling endings, 0 token leaks.
- Bug found by the real engine and fixed: token wrapper (`[[…]]`) corrupted by Argos → now
  globally unique numeric tokens `#1000123#` with per-text restore.
- Bug found by the real engine and fixed: `&` dropped the following word → textual `&`
  normalized to `and` before translation + content-loss guard (<60 % words or dangling
  conjunction → `TRUNCATED`, not stored).
- Bug found by API verification: `?lang=` was ignored on master reads → query parameter now
  wins over `Accept-Language`; unsupported codes fall back with a debug log.
- Translation quality is machine-grade and needs review: 349 rows sit in
  `PENDING_REVIEW`; 45 fields are `NO_CHANGE` (the model echoes technical English) and need
  human copy or glossary additions.

### Content i18n - J (manual entry)
- Machine translation is optional. `GET /platform/i18n/content/units?lang=es` lists every
  enabled canonical field (source text + current translation/status/origin + safetyCritical),
  including fields with no row; `filter=missing|all`, `query`, `page/size` (cap 200).
- Platform Admin → Settings → Languages → `<language>` → **Add translations manually**
  (`/settings/languages/:code/manual`): search, entity-type filter, All/Missing, paging,
  inline edit. Saves use the existing `PUT .../content/{type}/{id}/{field}?lang=es`, stored as
  `AUTHORED / REVIEWED` — never machine translated, never queued.
- Works for a freshly added manifest language with zero rows (`fr` case covered in tests).
- Tests: `ContentUnitsIT` (7); backend total 298.

### Content i18n - K (admin-managed languages)
- `POST /platform/i18n/languages` creates (`201`) or reactivates (`200`) a language;
  `DELETE /platform/i18n/languages/{code}` soft-retires it (translations kept, re-add works).
  Guards: `409 LANGUAGE_EXISTS`, `422 LANGUAGE_INVALID / LANGUAGE_DEFAULT`, `403` non-platform.
- The hardcoded English-only registry is gone: `activeLanguages/allLanguages/me/setMyLanguage`
  are DB-driven, and `ContentLanguageService` uses registry metadata.
- `StaticLanguageSync` seeds **every manifest language** (en/es/fr) into `platform_languages`
  at startup, leaves runtime-added languages alone, and registers all live codes in
  `LanguageCatalog` so `?lang=de` works on content endpoints **without a restart**.
- Platform Admin: **Add language** dialog (code / native name / LTR-RTL) in `/settings/languages`
  → lands in the new workspace; **Retire language** in the workspace header.
- Tests: `LanguageAdminIT` (4), updated `StaticLanguageSyncTest`/registry tests; 303 backend,
  82 platform admin.

### Content i18n - L (Spanish content complete)
- All **45 missing canonical fields** were authored in Spanish through the new manual API —
  every one non-safety-critical (option values, one item label, DTC code/count, two test
  categories/templates already authored in Spanish). Result at the time: **409/409 translated,
  0 missing**; after the taxonomy merge the catalogue-only total is **388** (locked sets
  excluded), still 0 missing.
- `common/es.json` completed from 30 → **154/154** keys: 65 `option.*` labels (actions, causes,
  components, conditions, units, urgency, yes/no) plus the 59 shared shell keys (buttons,
  errors, filters, roles, statuses, validation). Served immediately in bundles; no rebuild.
- App catalogs completed: `workshop_admin` 62 → **1300/1300**, `technician` 62 → **1332/1332**
  (placeholders/ICU/newlines audited; 31/30 values intentionally identical to English —
  brands, units, grades). Platform Admin stays English-only (0/965) by design.
  Glossary: trabajo · inspección · lista de comprobación · evidencia · hallazgo · borrador ·
  pendiente de revisión · consentimiento · matrícula · kilometraje.
- Mobile visual check at 390×844 after switching to Español (Workshop overview + settings):
  all shell/status/nav copy Spanish, no overflow.
- `PlatformUiMessagesIT` updated: Spanish now covers every key, so the old
  "`twoFactorLabel` falls back to English" assertion was removed; per-key fallback stays
  covered by `UiMessageLanguageAdditionTest` with a deliberately partial catalog.
- The 348 machine rows still need review approval (55 safety-critical); authoring did not
  change their status.

### Option sets - M (taxonomy merged in)
- **One store:** `platform_option_sets` + `platform_option_values`. `V134` adds `set_kind`
  (`CHECKLIST|STATUS|ENUM`), `domain_key`, `code_locked`, copies every `reference_domain`
  row into sets/values (tones/icons/visibility in `metadata_json`) and **drops
  `reference_domain`**. `status_transition` stays for the state machine.
- 32 sets: 10 checklist + 15 statuses + 7 enums. `/reference/statuses|enums|transitions`
  keep their exact response shapes, now backed by option sets.
- **Backend-defined sets:** create/retire set → `422 OPTION_SET_BACKEND_DEFINED`.
  **Hybrid values:** catalogue sets (ISSUE_TYPE, COMPONENT, LOCATION, CONDITION, CAUSE,
  ACTION, URGENCY) accept new values; locked sets (all statuses/enums + SEVERITY, UNIT,
  YES_NO) → `422 OPTION_SET_CODES_LOCKED`. Labels/order stay editable.
- Platform Admin: **one screen, three tabs** — Checklist / Statuses / Enums; locked values
  show a “Backend-defined” badge and no add/retire. `/configuration/statuses|enums|dropdowns`
  redirect into the matching tab; Transitions remains.
- **Content i18n scope:** locked sets are excluded from units/coverage/backfill
  (`ContentSourceCatalog` requires `code_locked = FALSE`), because their labels are UI
  catalog `label_key`s. Result: **388 catalogue units, 0 missing** (was 533/124 after the
  raw merge). Statuses/enums stay out of the translation queue.
- Tests: 307 backend · 99 platform_admin · gate 0.
- **Migration risk:** V134 is destructive (`DROP TABLE reference_domain`). Take a database
  snapshot before deploying. Rollback = restore snapshot + previous binary.

### Auth - session expiry
- 401 on an authenticated call now **leaves protected screens immediately**:
  `AuthController.signOut()` clears the access token and sets `AsyncData(null)` before the
  logout round-trip, then clears the store even if logout fails. `/api/v1/auth/logout` is an
  anonymous path so a 401 there cannot recurse.
- Regression E2E: a forced 401 on `/platform/i18n/languages` from `/checklist/categories`
  lands on `/signin` (previously the page could stay if the logout call stalled).
- Stale-tab note: Flutter web ships a service worker; after a rebuild an already-open tab can
  keep the old bundle. Hard reload (Ctrl+Shift+R) or unregister the service worker once.

### Full lifecycle verification (fresh job, 2026-11-21)
- Created `JOB-89211E61` from scratch, assigned Technician A, completed the 3-item
  `E2E Quick Check` template with photo evidence, added the drawn signature, completed the
  inspection (`PENDING_REVIEW`, score 100, grade A), approved, published (`ACTIVE`) and got a
  public link.
- Browser-verified in Chromium:
  - Workshop Admin: job card opens, **Review & publication**, Published.
  - Technician: completed job opens, **3/3**, every item `No issue observed`.
  - Public: `200`, job reference, `Toyota Land Cruiser`, `100%`.
- Harness bug found and fixed: `tools/e2e_create_job.js` selected staff by masked email and
  sent `row.id` instead of `row.userId`, so the job was created unassigned; it now picks
  `role === 'TECHNICIAN'` and assigns by `userId`.
- Boundary: creation and inspection completion were driven through the API harness (the
  browser verified each role's screens). A purely UI-clicked wizard + 30-item checklist +
  signature automation is **not** part of the suite yet.

### Taxonomy rendering audit (no static selectable lists)
- **API-driven:** statuses/enums labels, tones, order, visibility and checklist option values.
- **Removed from clients:** item-editor result/input/evidence/direction lists and required-result
  chips now come from `enumsProvider(...)`; creation payloads await the served values.
  `V135` marks `NOT_CHECKED`/`NOT_APPLICABLE`/`COULD_NOT_VERIFY` as `selectable=false`, so the
  editor keeps the three assessment results without a hardcoded list.
- **Kept as behavior (annotated `gate-allow: codes`):** technician next-up priority
  (`IN_PROGRESS` first — served `order` is display order), three item-lifecycle status filters
  (`PUBLISHED/DRAFT/RETIRED`; `CHECKLIST_STATUS` has 7 but items only use these), and result
  grouping/fallback arrays.
- **New gate:** `tools/gate_no_code_arrays.js` fails on 2+ uppercase wire-code array literals in
  app/package `lib/` (preview/tests/generated excluded), with explicit allow comments.
- Tests: backend 309 · platform 105 · gate 0 · platform/technician rebuilt.
- Rendering caveat unchanged: a value with a resolvable `labelKey` renders catalog copy, so
  editing its served `label` in the admin does not change the visible text.

### Production readiness (2026-11-22)

Four blockers were identified and three are now closed in code/config:

1. **Delivery channels were dishonest — CLOSED.** `DeliveryProviderRegistry` no longer falls back
   to the fake provider for SMS/WhatsApp. `GET /api/v1/workshop/delivery-channels` reports what is
   configured; `POST /deliveries` rejects an unconfigured channel with `422 CHANNEL_UNAVAILABLE`
   before writing a row; the workshop send sheet offers only available channels and defaults to
   the first (EMAIL today). Wiring a real SMS/WhatsApp provider is now a bean + config change.
2. **Non-English publishing gate — HUMAN TASK.** Exactly 55 safety-critical rows
   (`ITEM.instruction` 28, `ITEM.standardSpec` 27) are `PENDING_REVIEW`. They are exported to
   `docs/i18n/es-safety-critical-review.tsv` with English source, Spanish proposal and empty
   decision/reviewer columns. Bulk approve exists in the language workspace. Machine output must
   not be auto-approved (the export already shows errors such as "at most 7 C" rendered as
   "a la mayoría de 7 C").
3. **Translation worker could run the fake provider in production — CLOSED.**
   `TranslationWorkerSafety` + a `@Profile("prod")` startup guard refuse
   `worker-enabled=true` with provider `fake`; `infra/env/production.env.example` sets
   `I18N_WORKER_ENABLED=false` and documents the LibreTranslate switch.
4. **Destructive migrations had no deploy gate — CLOSED.** `scripts/backup-mysql.sh` dumps inside
   the MySQL container, refuses empty/table-less output, encrypts (AES-256-CBC/PBKDF2) and writes a
   verified SHA-256 sidecar. `scripts/deploy-prod.sh` refuses a dirty tree, takes and verifies the
   backup, then runs compose. `scripts/restore-mysql.sh` verifies the checksum and requires an
   explicit container plus `CONFIRM_RESTORE=yes`. The runbook points at all three.

Also closed: **wall-clock zones**. Both compose stacks now run MySQL with
`--default-time-zone=+04:00` and the server JVM with `TZ=Asia/Dubai`, so DB-generated and
JVM-generated stamps match the clients' Dubai rule (component-verified: MySQL `NOW()` = UTC+4,
JVM accepts `Asia/Dubai`).

### Report and delivery on the platform model (2026-11-21)

Found by browser QA: every report/delivery action returned 404 for real jobs, because those
paths were still bound to the legacy `inspection_jobs`/`reports`/`report_versions` stack while
the product uses `platform_jobs`/`platform_report_versions`/`platform_public_links`.

- **Delivery** now resolves the platform job, latest report version and active link; consent is
  the job's single `consent_granted` flag; recipients come from the encrypted platform columns.
  EMAIL attaches the report PDF when renderable and falls back to a link-only message; SMS and
  WhatsApp are link-only. Delivery language accepts **any LIVE registry language**.
- **Admin report PDF** renders on demand through the same Chromium pipeline as the public PDF
  (no `report_artifacts` row required); `pdfReady` now reports the truth.
- **`POST /report/retry`, `POST /report/link`, `POST /report/link/revoke`** have platform
  branches; `PUT /report/pdf-download` was already correct.
- **V138** converts `delivery_requests.job_id / report_version_id / public_share_link_id` to
  `VARCHAR(36)` and re-points the FKs at the platform tables. It deletes pre-existing delivery
  rows (legacy binary ids cannot satisfy the new FKs) — destructive, needs a DB snapshot.
- **Report surface is reachable**: job detail → Review & publication now has Report and
  Documents actions (previously `ReportPage`, `DocumentsPage` and `ReportDistribution` had no
  caller at all).
- **Language genericity** (no en/es/ar special cases):
  - `supportedLocales` comes from the UI manifest, so Material/Cupertino copy follows the
    languages that actually ship a catalog; it always includes the active language.
  - Delivery languages, the job-creation language chips, document language labels and the
    job's preferred-language fact all read `GET /i18n/languages` (registry), not the manifest.
  - Option labels are editable only when no catalog key resolves.
  - Adding a LIVE language therefore works for jobs, content, reports and delivery. UI chrome
    stays English until a catalog file ships — the languages screen shows UI-text coverage and
    blockers, and publishing a job in an untranslated language returns `409
    TRANSLATION_REVIEW_REQUIRED` with the exact field list in the existing dialog.
- Live proof on `JOB-89211E61`: report `pdfReady=true`, `GET /report/pdf` 200 `%PDF` (372 KB),
  revoke → activate link, `POST /deliveries` EMAIL 201 with `pdfAttached=true`, SMS 201, and a
  Spanish (`es`) SMS delivery 201 → `SENT`. Unknown language `zz` → 422.
- **Technician reference** — the inspection hub and summary headers now show the internal
  `JOB-…` reference beside the plate (once, and never duplicated when the plate is absent);
  queue rows stay plate-first. E2E still identifies the seeded job by plate.

### Time contract fix (2026-11-21)

The wire rule (documented in `client/apps/workshop_admin_app/lib/src/workshop_clock.dart`; its
comment cites a `docs/api/contracts.md` quirk 3 that is not in the tree): a timestamp **with** an
offset is a real instant (convert to Asia/Dubai, UTC+4); a timestamp **without** one is already a
Dubai wall time.

- **Server** read every `DATETIME` with `rs.getTimestamp(...).toLocalDateTime()`, which renders it
  in the JVM zone: a job created with `scheduledAt=2026-11-21T12:00:00` came back as `17:30` on a
  `+05:30` host. `PlatformJobStore`, `TechnicianStore`, `TemplateRepository` and
  `TranslationJobStore` now use `rs.getObject(column, LocalDateTime.class)`, so wall-clock values
  round-trip unchanged on any host.
- **Technician app** treated naive values as UTC and added four hours again, so a 22:00 job was
  filed under tomorrow and every time rendered four hours late. One `parseWallTime` helper now
  mirrors `WorkshopClock.wallTime`; the queue, day board, row labels and intake view all use it.
  `parseInstantAsUtc` is deleted rather than left as a trap.
- E2E fixtures now send a Dubai wall-clock `scheduledAt`, so a seeded job is reachable on the
  technician board at any hour (previously UTC timestamps near midnight landed on the next Dubai
  day and vanished from the queue).

### Visual QA (2026-11-21)
- Surfaces: merged option sets (Checklist/Statuses/Enums), item editor evidence step, master
  library filters. Real-font captures at 1440/1280/1024/768/390/360, plus RTL layout for the
  option sets (Platform Admin is English-only, so RTL uses English copy).
- **Verdict: PASS WITH FIXES.**
- Fixed during QA:
  - master-library status filters were pushed off the right edge by long category pills →
    statuses now have their own always-visible row; pills stay intrinsic;
  - evidence-rule dropdown was labeled “Status” → now “Result” (`checklist.editor.evidenceResult`);
  - step-card “Save” demoted to secondary so the footer “Next” is the only primary action.
- Remaining minor: 10px field labels (global design system, below 12px), the category row is
  horizontally scrollable and clips at the right edge by design, large empty area below the
  master/detail at 1440, widget-capture fixture counts differ from live data.
- Live visual spec: `tests/e2e/modules/master_library_visual.spec.ts` asserts the served result
  selectability and the three item-lifecycle filters, and writes viewport captures under
  `test-results/visual-qa/<run>/`.

### Playwright E2E (browser, real builds)
- Prerequisite: `flutter build web --release --dart-define=API_BASE_URL=http://localhost:8080`.
  Without it the build points at the dev-tunnel default and every test fails on the first-paint
  error gate ("Refresh").
- Projects: auth (platform/workshop/technician), platform admin (incl. manual translations
  list → type → save → API shows `AUTHORED / REVIEWED`, add language → workspace → manual
  screen → retire, merged option sets, legacy-route redirects, 401 → sign-in), workshop jobs,
  workshop report surface (job detail → Report → Download PDF enabled → send sheet languages →
  Documents), technician, language catalog, public report, plus the live visual spec.
- Report surface spec (`tests/e2e/modules/report_surface.flow.spec.ts`) is the regression
  guard for the 404s: it fails if the admin PDF is not renderable or the send sheet stops
  offering the registry languages.
- Real defects found and fixed:
  - public report category summary was hardcoded English and its separator was
    double-encoded, so Spanish snapshots showed `Categories Passed <mojibake> 1 Category
    Needs Attention`;
    `ReportViewMapper` now uses `report_en/es` keys (`categorySummary.*`, `categoryStatus.*`)
    and the PDF template uses `cat.label` instead of `cat.labelEn`.
  - content review could not select Spanish: it listed languages from
    `/platform/i18n/languages`, the English-only UI registry → "Pending: 0". New
    `GET /platform/i18n/content/languages` + `contentLanguages()` on the client.
  - workshop and technician apps used the in-memory UI-message store, so a selected
    language reverted to English on reload; both now use the shared-preferences store.
- Harness fixes: sign-in retry (Flutter drops the first character after focus), consent copy drift
  (`Public-link consent is not recorded` — the value can sit below the fold where Flutter prunes
  semantics, so the write path is proven by the action plus the API read-back), seeded jobs now
  carry today's `scheduledAt` (the technician queue is day-scoped), and a stale
  per-navigation `localStorage.clear()` that killed the session was removed. Technician queue
  assertions use `vehiclePlate`: the app never renders the internal `JOB-` reference.
- Final: `npx playwright test` → **24 passed (15.0m)**, `E2E_PASSWORD` + the Spanish public
  token in `E2E_PUBLIC_REPORT_TOKEN` / `E2E_PUBLIC_REPORT_LANG=es`.

## Open items
1. **Provider review** — `gate=safety_critical` is the default; switch to `all` per workshop
   once every field's `es` copy is reviewed. The 409 payload lists what is missing.
2. **Content coverage** — the report/delivery bundles are fully translated; content
   (items/categories/options) is translated per entity, so the coverage endpoint reports the
   real numbers as the library is backfilled.
3. **Live provider** — done on this machine via the Python venv (no Docker); `es` backfilled
   (349 machine rows). The `infra/docker-compose.yml` profile remains the production path and
   still needs one run on a Docker host to be exercised end to end.
4. **Machine output review** - **348** `PENDING_REVIEW` rows remain (55 safety-critical);
   all canonical fields now have a Spanish translation (**0 missing**), so the remaining work
   is approval, not authoring.
5. **Pre-evidence-fix jobs** published before 2026-11-21 need one unpublish/republish to
   generate photo/video derivatives.
6. **Physical camera capture** — file-source evidence works; real camera/video remains a
   device-only check.
7. **New-language UI text** — adding a LIVE language immediately covers jobs, content, reports
   and delivery, and the app manifests only advertise languages that ship a catalog file, so no
   half-translated chrome appears. Translating the *interface* for a brand-new language still
   requires a catalog file (`server/src/main/resources/i18n/<client>/<lang>.json`) in a release;
   there is no admin authoring path for UI strings yet (the workspace shows 0/N UI coverage and
   the content backlog separately).
8. **Dead doc links** — `WorkshopClock` cited `docs/api/contracts.md` (quirk 3) and
   `docs/data/inventory.md` (T1). `docs/api/contracts.md` now exists and documents the time,
   language, error, idempotency, delivery and taxonomy rules; the code comment now cites only
   that file.
9. **Docker not exercised** — the deploy/backup/restore scripts pass `bash -n` and are wired into
   the runbook, but no Docker host is available here, so the compose stack, the encrypted
   round-trip and the restore drill have not been executed in this session. Run
   `scripts/backup-mysql.sh` → `scripts/restore-mysql.sh` against a drill container before the
   pilot.
