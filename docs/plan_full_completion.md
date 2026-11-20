# TrueReport — full completion plan (backend + frontend)

Date: 2026-11-20
Status: draft for approval
Owners: Platform Admin (taxonomy), Workshop Admin (composition), Technician (execution)
Scope: the entire workshop → template → job → inspection → publish → public report loop,
plus the platform-owned taxonomy that drives every status, chip, dropdown and enum.

---

## 0. Objective

Make TrueReport a single connected product where:

1. **Platform Admin decides the taxonomy** — statuses, transitions, enums, roles,
   severities, results, grades, units, dropdown option sets — through APIs and UI.
2. **Workshop Admin only composes** — creates templates from platform-owned items,
   creates jobs, assigns technicians, records consent, reviews, publishes.
3. **Technician only executes** — inspects every checklist item according to the
   template, selecting from server-provided options, capturing the required photo(s)
   and video(s), recording measurements, signing, submitting.
4. **Every screen renders backend data** — no static text, chips, cards or numbers.
5. **The whole loop is provable in the browser** with no curl, SQL or manual token.

---

## 1. Ownership model

```
PLATFORM ADMIN
  defines taxonomy + master library
  statuses · transitions · enums · roles · severities · results · grades · units
  dropdown option sets · document types · scoring rules · master items
  master items carry: result options, score bands, measurement bands,
                      evidence rules, issue fields/options
        │ read-only
        ▼
WORKSHOP ADMIN
  composes: template version (items + weights) → job (customer, vehicle, template,
  schedule, technician, preferred language, public-link consent) → review → publish
        │ read-only
        ▼
TECHNICIAN
  executes: per item → result (from options) → severity/issue/location/action/urgency
  (from dropdowns) → measurement (from unit) → photo + video (per evidence rule)
  → notes → save → summary → signature → submit
        │ server projection
        ▼
PUBLIC
  /r/{token} (HTML) and /r/{token}/pdf — snapshot only, no empty labelled fields
```

Rule: Workshop Admin and Technician never create a value. Their pickers are closed
lists served by the platform. The server re-validates every submitted value.

---

## 2. Current state — what exists

### 2.1 Backend (Spring Boot 4, MySQL, Flyway)

| Area | Endpoints | State |
|---|---|---|
| Auth | `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `GET /auth/me`, `POST /auth/2fa/verify`, password flows | ✅ |
| Platform · tenants | `GET/POST /platform/workshops`, `PUT /{id}`, `POST /{id}/deactivate|reactivate`, `GET /platform/hierarchy`, `GET /platform/workshops/{id}` | ✅ |
| Platform · people | `/platform/users`, `/platform/invitations`, password-reset, disable, reactivate, transfer | ✅ |
| Platform · taxonomy in place | `/platform/master/{categories,items,reasons,equipment,dropdowns,guide-images}`, `/platform/master/option-sets` (+values, retire, reorder) | ✅ partial |
| Platform · item config | item versions: `config`, `bands`, `evidence-rules`, `issue-fields`, `measurement-bands`, translations, publish/retire/metadata | ✅ |
| Platform · templates | `/platform/master/templates*` (versions, items, categories, weight-preview, publish, approve, reject, retire) | ✅ |
| Platform · config | `/platform/document-types`, `/platform/scoring-rules` + grade-boundaries, `/platform/config-health`, `/platform/releases`, `/platform/seed/default-checklist` | ✅ |
| Platform · overview | `GET /platform/overview` | ✅ |
| Workshop · staff | `GET /workshop/staff`, `POST /workshop/technicians`, `POST /workshop/technicians/{id}/password-reset` | ✅ |
| Workshop · master (read) | `GET /workshop/master/categories`, `/workshop/master/items`, `/workshop/master/items/{versionId}` | ✅ |
| Workshop · templates | `/workshop/templates*` (list, versions, detail, draft, publish, retire, preview), `/workshop/template-versions/available`, `/{versionId}` | ✅ |
| Workshop · jobs | `GET/POST /workshop/jobs`, `GET /jobs/counts`, `GET/PUT /jobs/{id}`, `POST /jobs/{id}/assign`, `PUT /jobs/{id}/consent`, `POST /jobs/{id}/cancel`, `GET /jobs/{id}/assignments` | ✅ |
| Workshop · review/publish | `GET /jobs/{id}/review`, `GET /jobs/{id}/publish-checklist`, `POST .../approve`, `.../reject`, `.../publish`, `.../unpublish`, `.../rotate-token`, `.../revoke`, `GET .../public-link`, `GET .../qr` | ✅ |
| Workshop · outputs | `GET /jobs/{id}/documents`, `POST .../{type}/retry`, `GET .../{documentId}/content`, `/jobs/{id}/deliveries`, `.../{deliveryId}/retry`, `/jobs/{id}/report*` | ✅ |
| Workshop · notifications | `GET /workshop/notifications`, `POST /{id}/read` | ✅ |
| Technician · jobs | `GET /technician/jobs`, `GET /jobs/{id}`, `GET /jobs/{id}/checklist`, `PUT /jobs/{id}/items/{itemCode}`, `GET .../summary`, `.../review`, `POST .../signature`, `.../complete`, `.../sync` | ✅ |
| Technician · evidence | `POST .../evidence/init`, `PUT .../evidence/{id}/content`, `POST .../evidence/{id}/complete`, `GET .../evidence`, `GET .../evidence/{id}/content`, `DELETE .../evidence/{id}` | ✅ server-enforced |
| i18n | `GET /i18n/languages`, `GET /i18n/ui-messages/{client}/manifest|bundle` | ✅ 1,301 keys |
| Public | `GET /r/{token}`, `GET /r/{token}/pdf` | ✅ |
| **Reference data** | **none** | ❌ |

Evidence rules are already server-side per item/result: `minPhotos`, `minVideos`
(15–30 s, camera source only), `minNotesChars`, `requiredEvidenceType`, sha256
de-duplication, and `POST /complete` returns blockers.

### 2.2 Frontend

| App | Screens |
|---|---|
| Platform Admin | dashboard, workshops (list, detail, new), checklist (items, item editor, categories, option sets, health), reports/document-types, settings/languages + translations, audit-log, master-library, data-catalogues, config-health |
| Workshop Admin | single `/workshop` shell: dashboard, jobs (queue, filters, wizard 4 steps, detail, review, publish checklist, documents, deliveries, report), staff, templates (list, builder, versions), settings |
| Technician | `/jobs` queue (+ week strip, filters), `/jobs/{id}`, `/jobs/{id}/items/{itemCode}`, summary, signature, completed, `/sync` + conflicts, `/profile` |
| Public | report HTML + PDF |
| ui_gallery | design-system showcase (dev only, out of scope) |

---

## 3. Gap list (what is missing or wrong)

### G1 — No taxonomy API
Nothing serves statuses, transitions, enums, roles, severities, units, grades as data.
Everything below is Dart-side today:

| Client file | What it hardcodes |
|---|---|
| `workshop_admin_app/lib/src/labels.dart` | job/status/review labels |
| `features/jobs/shared/job_status_badge.dart` | status → tone/colour |
| `platform_admin_app/lib/src/components/platform_chips.dart` | chip variants |
| `features/workshops/workshop_status.dart` | workshop status label/tone |
| `features/checklist/checklist_status.dart` | checklist status |
| `features/checklist/checklist_health_labels.dart` | health labels + messageKey switch |
| `features/dashboard/dashboard_data.dart` | alert-key switch + derived numbers |
| `features/reports/report_metrics.dart` | metrics/percentages computed client-side |
| `features/jobs/approve/approve_score.dart` | score/grade math duplicated |

### G2 — Platform Admin cannot administer most taxonomy
Exists: option sets, document types, scoring rules + grades, master items (with bands,
evidence rules, issue fields).
Missing: statuses, transitions, roles, severities, results, units, queue filters,
dashboard metrics, evidence-policy presentation.

### G3 — Loop gaps (reproduced live)
| Gap | Evidence | Owner |
|---|---|---|
| Public-link consent cannot be recorded in UI → approve/publish blocked | `422 APPROVAL_CHECKLIST_INCOMPLETE / CONSENT_GRANTED`; wizard says "cannot be recorded in this version"; backend `PUT /consent` works | Workshop |
| 15-min access token, no refresh on 401 → mid-flow logout | publish returned 401 after ~15 min, session cleared | shared auth |
| Report shows empty labelled boxes | `ReportViewMapper:230,233,242` (`drivetrain`, `engineSize`, `clientName` = `""`) | Backend/report |
| Arabic still leaks | `messageAr` in error payloads; `public-report/report.js:56-57`; `print-report.html:1367,1444,1519` | Backend |
| Two API generations | `/api/v1/*/legacy/*` controllers still registered next to clean routes | Backend + clients |
| Evidence capture unproven in UI | E2E used the API because 30 items × (photo + video) was not clickable | Technician |

### G4 — Test debt
76 test files were deleted during localization work; Platform Admin is down to 5 tests.
Current backend baseline: **177 tests, 2 failures** — both stale key-count assertions
(`1261` expected, `1263` actual, from 2 consent catalog keys added by a stopped agent).

---

## 4. Target architecture

### 4.1 Reference data — separate APIs, **no bundle**

```
GET /api/v1/reference/statuses/{statusType}
    statusType: job | review | publication | evidence | sync | document | template

GET /api/v1/reference/dropdowns/{setCode}
    setCode: ISSUE_TYPE | LOCATION | COMPONENT | ACTION | URGENCY | REASON | UNIT

GET /api/v1/reference/enums/{enumCode}
    enumCode: role | severity | result | grade | measurement-unit | evidence-type

GET /api/v1/reference/transitions/{entity}
    entity: job | review | publication
```

Record shape (all domains):

```json
{
  "code": "PENDING_REVIEW",
  "labelKey": "statusPendingReview",
  "tone": "warning",
  "icon": "clock",
  "order": 50,
  "selectable": false,
  "visibleFor": ["workshop_admin"],
  "allowedNext": ["APPROVED", "REJECTED"],
  "version": 7
}
```

- `labelKey` resolves through the existing i18n bundle (no labels in payloads or Dart).
- `tone` / `icon` are design tokens mapped to widgets, never to text.
- `selectable: false` renders as a badge/filter but cannot be chosen for new work.
- `visibleFor` filters by role; tenant filtering applies where relevant.
- ETag + `version` per domain for safe caching and technician offline use.
- Platform Admin is the only writer; Workshop/Technician are read-only.

### 4.2 Platform Admin UI additions
New **Configuration** section:
1. **Statuses** — per status type: label key, tone, icon, order, selectable, visibleFor,
   allowed transitions. Publish with impact preview.
2. **Enums** — roles, severities, results, grades, measurement units; same record shape.
3. **Dropdowns** — existing option-sets screen becomes the single source for
   ISSUE_TYPE/LOCATION/COMPONENT/ACTION/URGENCY/REASON/UNIT, with reorder + retire.
4. **Evidence policy** — per item/result: min photos, min videos, duration window,
   min notes, required evidence type; surfaced in the item builder (data already exists).
5. **Publish flow** — draft → published per domain, version bump, impact list of affected
   items/templates/jobs.

### 4.3 Client consumption
- `ReferenceDataRepository` in `packages/api_client`: one provider per domain, ETag
  cache, typed models, offline persistence for technician.
- `design_system` widget kit: `StatusChip`, `OptionDropdown`, `TransitionButton`,
  `FilterBar` — all driven by the repository.
- Rule: client code may branch on `code` for behaviour; never for label, colour, order
  or visibility.

### 4.4 Text
- Already backend-served (1,301 keys). Add a CI gate: fail on user-visible literals in
  `lib/` outside `preview/` and tests.
- Every new string: catalog entry + `schema.json` + regenerated accessor.

### 4.5 Evidence pipeline (technician)
Server is authoritative. Client must implement/verify:
- per-item state machine `required → capturing → uploading → complete` driven by
  `GET .../evidence`, not local counters;
- camera capture for photo and 15–30 s video (`image_picker`/`file_picker` already in
  `pubspec.yaml`);
- upload queue with retry + progress, offline persistence, conflict-safe re-entry;
- submit disabled while `/summary` returns blockers; blockers rendered as actions.

### 4.6 Report
- Every slot populated or absent; masking is a server decision (`vin`, `plate`,
  `clientName`); template must not render labelled empty cells.
- HTML and PDF share one snapshot contract test.

---

## 5. Data model changes (Flyway)

```sql
-- published taxonomy
reference_domain (
  id binary(16) pk,
  domain_type varchar(32),      -- STATUS | ENUM
  domain_key varchar(48),       -- job-status | severity | role ...
  code varchar(64),
  label_key varchar(120),
  tone varchar(24),
  icon varchar(48),
  sort_order int,
  selectable boolean,
  visible_for_json json,
  allowed_next_json json,
  status varchar(16),           -- DRAFT | PUBLISHED | RETIRED
  version int,
  created_by binary(16), created_at datetime(6), updated_at datetime(6),
  unique (domain_key, code)
);

reference_value (               -- dropdown option sets
  id binary(16) pk,
  set_code varchar(48),         -- ISSUE_TYPE | LOCATION | ...
  code varchar(64),
  label_key varchar(120),
  parent_code varchar(64) null, -- e.g. component under system
  sort_order int,
  selectable boolean,
  status varchar(16),
  version int,
  unique (set_code, code)
);

status_transition (
  id binary(16) pk,
  entity varchar(32),           -- job | review | publication
  from_code varchar(64),
  to_code varchar(64),
  role varchar(32),
  guard_json json,
  version int
);
```

Migration plan:
1. `V125__reference_taxonomy.sql` — tables + seed of every current status/enum code, with
   labels matching today's UI so nothing changes visually on day one.
2. `V126__reference_transitions.sql` — seed allowed transitions from current behaviour.
3. `V127__reference_dropdown_backfill.sql` — backfill `reference_value` from existing
   option sets; either keep `/platform/master/option-sets` writing to both, or switch it
   to the new table in the same release (decision D4).
4. No status-code renames; codes stay as they are in `platform_jobs` etc.

---

## 6. Flow specification (definition of done)

| # | Actor | Screen | Endpoints | Server validates |
|---|---|---|---|---|
| 1 | Platform Admin | Workshops → New | `POST /platform/workshops` | name/branch, status |
| 2 | Workshop Admin | Staff → Add technician | `POST /workshop/technicians` | email unique, role, temp password |
| 3 | Workshop Admin | Templates → New → builder | `/workshop/master/*`, `/workshop/templates*`, publish | items exist, weights, evidence rules |
| 4 | Workshop Admin | Jobs → New (customer, vehicle, template, schedule/technician/consent) | `/workshop/template-versions/available`, `POST /workshop/jobs`, `assign`, `consent` | VIN, template published, technician in workshop, consent |
| 5 | Technician | Queue → job → item | `/technician/jobs`, `/checklist`, `PUT /items/{code}`, `/evidence/*` | result in options, severity/location from lists, photo+video+notes per rule, measurement in band |
| 6 | Technician | Summary → signature → submit | `GET /summary`, `POST /signature`, `POST /complete` | all items assessed, evidence complete, signature, no blockers |
| 7 | Workshop Admin | Review → approve → publish | `GET /review`, `GET /publish-checklist`, `POST /approve`, `POST /publish` | consent, score/grade, documents, safety cap |
| 8 | Public | `/r/{token}`, `/pdf` | public routes | token active, LTR, no empty slots, PDF parity |

Acceptance is a single Playwright suite executing these eight steps with real roles and
**no API shortcuts**.

---

## 7. Screen-by-screen work matrix

Legend: **D** = already data-driven · **C** = change to reference data · **N** = new.

### Platform Admin
| Screen | Change |
|---|---|
| Dashboard | C — alert keys + metrics from `/overview` + `/reference/statuses` |
| Workshops list/detail/new | D |
| Checklist items / item editor | C — evidence policy surfaced; enums from `/reference/enums` |
| Categories | D |
| Option sets | C — becomes `reference_value` editor (D4) |
| Config health | C — labels from `/reference/statuses` |
| Document types | D |
| Languages + translations | D |
| Audit log | D |
| Master library | C — remove legacy `labelAr`/`nameAr` accessors |
| **Statuses** | N — CRUD + transitions + publish |
| **Enums** | N — roles/severities/results/grades/units |
| **Evidence policy** | N — builder surface (data exists) |

### Workshop Admin
| Screen | Change |
|---|---|
| Dashboard | C — counts from `/jobs/counts`; statuses from reference |
| Jobs queue + filters | C — chips/tones/order from `/reference/statuses/job` |
| Job wizard | C — template/technician/language lists from APIs; **consent recorded here** |
| Job detail | C — badges + allowed actions from transitions |
| Review | C — score/grade from `/review`; no client math |
| Publish checklist | D (server-provided checks) |
| Publish + public link | D |
| Documents / deliveries | D |
| Staff | C — roles from `/reference/enums/role` |
| Templates + builder | C — items/evidence rules from master; statuses from reference |
| Settings | D |
| Reports | C — metrics from server summary; copy already backend |

### Technician
| Screen | Change |
|---|---|
| Queue + filters + week strip | C — statuses/labels from reference |
| Job detail / modules | D |
| Item assessment | C — result options, severity, issue, location, component, action, urgency, unit from reference |
| Evidence capture | C — full capture/upload/offline state machine |
| Summary / review | D |
| Signature / completed | D |
| Sync + conflicts | C — status labels from reference |
| Profile | D |

### Public report
| Screen | Change |
|---|---|
| HTML | C — populated-or-absent slots, masking |
| PDF | C — parity with HTML |

---

## 8. Phases, tasks and exit criteria

### Phase 0 — Baseline reconciliation (2 days)
- Decide the 2 consent catalog keys; reconcile catalogs (1261 vs 1263).
- Verify `mvn test` and all client suites; record the numbers.
- Land: consent control, refresh-on-401, report slots, Arabic removal
  (`report.js`, `print-report.html`, `messageAr`).
- Pin one local env file (`infra/.env` vs `start-mysql-backend.ps1` encryption key).
**Exit:** backend + client suites green; the loop passes in the browser, with the
evidence shortcut explicitly logged as open debt.

### Phase 1 — Taxonomy foundation (6–8 days)
Backend: tables, migrations, `/reference/statuses|dropdowns|enums|transitions`, ETags,
role filtering, seed matching today's labels.
Frontend: `ReferenceDataRepository`, providers, widget kit, one reference screen proof.
Platform Admin: read-only lists first (CRUD in Phase 2).
**Exit:** zero status/colour maps in client code; a seeded status appears in a Workshop
badge without a rebuild.

### Phase 2 — Platform Admin completion (4–5 days)
CRUD + publish/version + impact preview for statuses/enums/dropdowns; evidence policy in
the builder; dashboard/config-health from data; remove `labelAr` residue.
**Exit:** adding a status and a dropdown value in the UI makes them selectable in
Workshop/Technician with no rebuild.

### Phase 3 — Workshop Admin (4–6 days)
Queue/filters/badges/transitions from reference; template builder with evidence rules;
wizard with consent; review/publish from server data; delete `labels.dart` maps.
**Exit:** steps 1–4 and 7 of the flow pass in the browser.

### Phase 4 — Technician (5–7 days)
Options/pickers from reference; evidence capture + upload queue + offline + submit gating.
**Exit:** steps 5–6 pass in the browser on a 30-item job with real photo + video capture,
including an offline run and sync.

### Phase 5 — Report & public (3–4 days)
Snapshot completion, masking, HTML/PDF parity, three outcome profiles.
**Exit:** step 8 passes; no labelled empty cells.

### Phase 6 — Decommission + gates (3–4 days)
Delete `/legacy` controllers + `ApiEndpoints` methods; CI gates: literal scan,
reference-data usage scan, OpenAPI diff, Playwright E2E.
**Exit:** build fails on a new hardcoded label/status.

Total: ~7–8 weeks in this order. Phase 1 must not be skipped or paralleled with screen
work, or the current duplication returns.

---

## 9. Test strategy

1. **Contract tests** per app against fixtures generated from live endpoints.
2. **OpenAPI** published in CI; fail on breaking diff.
3. **Reference data**: selectors render exactly what the endpoint returns; empty state
   when empty; no fallback list in code.
4. **Inspection**: server blocker tests (photo/video/notes/measurement/signature) and
   client gating tests; offline queue + sync conflict tests.
5. **Playwright MCP E2E**: the 8-step flow, privileged + public, real files for photo and
   video.
6. **Report snapshot**: three profiles (pass / attention / defect) — no empty slot,
   HTML ≡ PDF field set.
7. **Gates**: literal scan (`tools/audit_hardcoded_strings.js`), reference-data scan
   (no `switch` on status for label/tone), i18n parity, key-count guards.

---

## 10. Risks

| Risk | Mitigation |
|---|---|
| Evidence capture (camera, 15–30 s video, offline) is the hardest piece and gates the loop | prototype capture in Phase 3, not Phase 4 end |
| Reference-data refactor touches every screen | land Phase 1 fully before screen work |
| Legacy API removal breaks older builds | delete in the release that ships the new client |
| Consent is legal copy | agree wording before Phase 3 |
| Offline taxonomy | cache every reference domain with version; allow job start offline |
| Test debt (76 deleted files) | rebuild coverage per phase, not at the end |

---

## 11. Decisions needed

| # | Decision | Default if you don't answer |
|---|---|---|
| D1 | Consent placement: job wizard step 4 or review screen | wizard step 4 |
| D2 | Public report client name: full / masked / omitted | masked (`E2E C***`) |
| D3 | First browser proof: thin slice (1 template × 3 items) or full 30 items | thin slice, then 30 |
| D4 | Option sets: migrate into `reference_value` or keep `/platform/master/option-sets` as store and expose via `/reference/dropdowns` | expose existing store, migrate later |
| D5 | `platform_admin_app/lib/preview/**` off-limits | yes, off-limits |

---

## 12. Definition of done

- Platform Admin creates a workshop; that workshop adds a technician; the workshop
  builds a template with evidence rules; creates a job, assigns the technician, records
  consent.
- The technician completes every item with the required photo and video, selecting only
  platform-provided options, signs and submits — online and offline.
- The workshop reviews using server-computed score/grade, approves, publishes, and gets
  an active public link.
- The public report and PDF show every populated field, no empty labelled cells, LTR.
- Every status, chip, dropdown and enum on every screen came from a platform-owned API.
- No `/legacy` routes, no Arabic, no client-side label/tone maps, no client-side score math.
- CI enforces all of the above.
