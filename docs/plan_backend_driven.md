# TrueReport — backend-driven completion plan

Status: proposed. Owner: product + engineering. Scope: Platform Admin, Workshop Admin,
Technician, public report, backend.
Goal: every screen is a rendering of backend data — text, chips, statuses, enums,
options, counts, cards, report slots — and the workshop → template → inspection →
review → publish → public report loop is complete and enforced end to end.

---

## 1. Where the product actually stands (audited)

Verified by running the full loop on 2026-11-20 and by code inventory.

### Works
- Auth (JWT + refresh token + Argon2 users), tenant scoping, roles.
- Job lifecycle: wizard → assign → technician checklist → assessments → evidence →
  signature → complete → review → approve → publish → public link + PDF.
- Inspection item contract is already dynamic: per item the server sends
  `resultOptions`, `scoreBands`, `evidenceRules`, `issueFields` + options,
  `measurementBands`, `multiPointIndexes`. Nothing about an item is hardcoded client-side.
- UI text is backend-served (`/api/v1/i18n/ui-messages/{client}/bundle`), 1,301 keys,
  no ARB in the client, typed key files generated.
- Public report renders LTR English from a stored snapshot; PDF served with
  `application/pdf`.

### Gaps found in the live run
| # | Gap | Evidence |
|---|---|---|
| 1 | Public-link consent cannot be recorded in the UI, so approve/publish is blocked for real users | `422 APPROVAL_CHECKLIST_INCOMPLETE / CONSENT_GRANTED`; wizard says "cannot be recorded in this version"; backend `PUT /jobs/{id}/consent` exists and works |
| 2 | Access token `PT15M`, refresh `P30D`, but 401 signs out instead of refreshing | publish returned 401 after ~15 min, session cleared, `/signin` |
| 3 | Public report shows empty labelled boxes | `ReportViewMapper:242 clientName=""`, `230 drivetrain=""`, `233 engineSize=""` |
| 4 | Arabic still leaks | `messageAr` in every error payload; Arabic literals in `TechnicianInspectionService` |
| 5 | Two parallel API generations (`/legacy/...` and clean) for jobs/inspection/report | `ApiEndpoints` keeps both; `TechnicianInspectionController` registered twice |
| 6 | Status/role/chip labels and tones duplicated in client code | `labels.dart`, `job_status_badge.dart`, `platform_chips.dart`, `workshop_status.dart`, `checklist_status.dart`, `checklist_health_labels.dart` |
| 7 | Derived numbers computed client-side | `report_metrics.dart`, `approve_score.dart`, `dashboard_data.dart` recompute what the server already returns |
| 8 | Technician evidence is enforced server-side but the UI cannot satisfy it end to end in the E2E | item needs 1 photo + 1 video (camera-only); 30 items = 60 captures |

---

## 2. Target architecture

### 2.1 One contract, one generation
- Retire every `/api/v1/{role}/legacy/...` route. Keep the clean routes already used:
  `/workshop/jobs`, `/technician/jobs`, `/workshop/templates`, `/workshop/master`,
  `/platform/...`.
- Deprecation rule: mobile clients ship with the app, so the clean route must be
  complete before the legacy controller is deleted; delete in the same release that
  ships the client.

### 2.2 Reference data service (the missing backbone)
One read model that every selector, chip, enum and status uses. Platform Admin writes;
Workshop Admin and Technician read only.

**Separate endpoints per concern — no aggregated bundle.** Each domain is its own API
so a screen fetches only what it needs and caching/versioning stays per domain:

```
GET /api/v1/reference/statuses/{statusType}      # job, review, publication, evidence, sync, document, template
GET /api/v1/reference/dropdowns/{setCode}        # ISSUE_TYPE, LOCATION, COMPONENT, ACTION, URGENCY, REASON, UNIT
GET /api/v1/reference/enums/{enumCode}           # role, severity, result, grade, language, evidence-type
GET /api/v1/reference/options/{itemCode}/{fieldCode}   # item-scoped options (already partly in /checklist)
```

Domains: `job-status`, `review-status`, `publication-status`, `role`, `severity`,
`result`, `issue-type`, `location`, `component`, `action`, `urgency`, `reason`,
`measurement-unit`, `evidence-type`, `document-type`, `grade`, `dashboard-metric`,
`queue-filter`.

Every record:

```json
{
  "code": "PENDING_REVIEW",
  "labelKey": "statusPendingReview",
  "tone": "warning",
  "icon": "clock",
  "order": 50,
  "allowedNext": ["APPROVED", "REJECTED"],
  "visibleFor": ["workshop_admin"],
  "selectable": false,
  "version": 7
}
```
- `labelKey` resolves through the existing UI-message bundle. No label text in payloads,
  no label text in Dart.
- `tone`/`icon` are design tokens; the client maps token → widget, never code → text.
- `allowedNext` drives buttons and transitions; the server still validates.
- `version` + ETag makes caching safe.

### 2.2.1 Backend-administered reference data
Platform Admin is the only writer. It publishes:
- statuses and their transitions,
- dropdown option sets (issue type, location, component, action, urgency, reason),
- enums (roles, severities, results, grades, units, document types),
- which roles may see/select each record.
Workshop Admin and Technician never create values: they render what the endpoint
returns, and their pickers are closed lists. A record marked `selectable: false` still
renders (badge/filter) but cannot be chosen for new work.

### 2.3 Statuses and enums
- Every status enum (job, review, publication, document, sync, evidence, template,
  item version, language) is served by `job-status`-style domains.
- Client code may switch on `code` only for routing/behaviour, never for label,
  colour, order or visibility.
- Selection controls are built from the served list. Workshop Admin and Technician
  cannot type a new status, severity, location or reason — they pick from the list.
- Platform Admin gets CRUD for option sets and statuses (already partially exists:
  `/platform/master/option-sets`, `/platform/document-types`, `/platform/scoring-rules`).

### 2.4 UI text
- Already backend-driven. Add a **CI gate**: a scan that fails on user-visible literals
  in `lib/` (excluding preview/tests), plus the existing generator parity tests.
- Every new string ships as: catalog entry (client scope) + schema entry + generated
  accessor. No exceptions.

### 2.5 Inspection + evidence (full loop)
- Server is already the authority: `evidenceRules` per result, `minPhotos`, `minVideos`,
  `minNotesChars`, camera-only source, 15–30 s video, sha256 de-duplication.
- Client must provide the full capture path: camera intent/`image_picker`-equivalent,
  local queue, background upload, retry, progress, offline persistence, and a submit
  button that stays disabled until the summary reports zero blockers.
- Add a per-item evidence panel state machine: `required → capturing → uploading →
  complete`, driven by server status (`GET .../evidence`), not local counters.
- Completion stays server-gated (`POST /jobs/{id}/complete` returns blockers).

### 2.6 Public report
- Report is a projection of the stored snapshot. Every slot must be either populated or
  absent — never a labelled empty box.
- Masking is a server decision (`vin`, `plate`, `clientName` policy) expressed in the
  view map, not in the template.
- Add a snapshot contract test: publish a job, fetch `/r/{token}`, assert no empty
  labelled field and that all sections with data render.

### 2.8 Target loop — UI only, no API shortcuts

This is the acceptance scenario. Every step is performed in a browser by a real user
role; nothing may require curl, SQL, or a manual token.

```
1. PLATFORM ADMIN (platform_admin_app)
   sign in → Workshops → New workshop (name, branch, status)
   → workshop appears in the list with 0 staff, 0 jobs

2. WORKSHOP ADMIN (workshop_admin_app) — new workshop's admin
   sign in → Staff → Add technician (name, email, temporary password, role)
   → technician listed with status Invited/Active
   (invitation/credential delivery must be shown in the UI, not assumed)

3. WORKSHOP ADMIN → Templates → New template
   name, category, items from the master library, per-item evidence rules
   (photos, videos, notes), result options, weights
   → publish version v1 → status Published

4. WORKSHOP ADMIN → Jobs → New job (4 steps)
   customer → vehicle (VIN required) → published template → start now,
   technician, preferred language, public-link consent recorded here
   → job status Assigned, visible in the technician queue

5. TECHNICIAN (technician_app), assigned account
   sign in → queue → open job → per item:
     · choose result from the served options (no free text)
     · set severity/issue/location/action from served dropdowns
     · capture required photo(s) via camera, record required video 15–30 s
     · add measurement where the item demands it
     · save item → evidence shows complete
   → summary shows 0 blockers → signature → submit
   → job status Pending review, appears for the workshop

6. WORKSHOP ADMIN → review
   scores/grade read from the server summary, not recomputed
   → approve → publish checklist (all server checks pass)
   → publish → public link ACTIVE

7. PUBLIC / an anonymous browser
   open /r/<token> → report renders every populated field, no empty labelled slot
   → download PDF → identical field set
```

Exit criteria per step are asserted in the Playwright suite:
- step 1–2 prove tenant creation and staff onboarding,
- step 3–4 prove template → job wiring and consent,
- step 5 proves the evidence pipeline (photo + video + options + measurement),
- step 6 proves server-gated approval/publish,
- step 7 proves the public projection and PDF parity.


```
reference_domain(id, code, label_key, tone, icon, sort_order, visible_for_json,
                 allowed_next_json, selectable, version, status)
reference_translation(domain_id, language, label)      -- only if not using ui catalogs
job_status_transition(from_code, to_code, role, guard)
screenshot-free: no other new tables required
```
Status codes already exist as strings across tables; this adds metadata, not a new state machine.

---

## 3. Screen → data matrix

Legend: **D** already dynamic · **S** has static/duplicated data to remove · **N** missing.

### Platform Admin (routes: dashboard, workshops, checklist/{items,categories,option-sets,health},
reports/document-types, settings/languages(+translations), audit-log, master-library,
data-catalogues, config-health)
| Screen | Data source | State |
|---|---|---|
| Dashboard | `/platform/overview` + `/reference/dashboard-metric` | S (client recomputes, alert key switch) |
| Workshops list/detail | `/platform/workshops`, `/platform/hierarchy` | D |
| Checklist items/editor | `/platform/master/items`, `/versions/...` | D |
| Categories / option sets | `/platform/master/categories`, `/option-sets` | D |
| Config health | `/platform/config-health` | S (label maps in `checklist_health_labels.dart`) |
| Document types | `/platform/document-types` | D |
| Languages + translations | `/platform/i18n/*` | D |
| Audit log | `/platform/audit-events` | D |
| Master library | `/platform/master/*` | D (legacy `labelAr` residue) |

### Workshop Admin (single `/workshop` shell: dashboard, jobs, staff, templates, settings, reports)
| Screen | Data source | State |
|---|---|---|
| Dashboard | `/workshop/jobs/counts` | S |
| Jobs queue + filters | `/workshop/jobs`, `/jobs/counts` | S (status chips/tones local) |
| Job wizard (4 steps) | `/workshop/template-versions/available`, `/jobs` | S (consent missing) |
| Job detail / review / publish | `/jobs/{id}`, `/review`, `/publish-checklist`, `/approve`, `/publish`, `/public-link`, `/consent` | S (consent not wired, empty boxes, derived score) |
| Documents / deliveries | `/jobs/{id}/documents`, `/deliveries` | D |
| Staff | `/workshop/staff` | D |
| Templates | `/workshop/templates*` | D |
| Settings | `/i18n/*`, `/auth/me` | D |
| Reports | `/workshop/jobs/{id}/report*` | S (copy now backend, metrics client-side) |

### Technician (routes: jobs, job detail, items, summary, signature, completed, sync, profile)
| Screen | Data source | State |
|---|---|---|
| Queue + filters + week strip | `/technician/jobs` | S (status labels local) |
| Job / modules | `/technician/jobs/{id}`, `/checklist` | D |
| Item assessment | `/checklist` item contract + `/items/{code}` | D |
| Evidence capture | `/evidence/init|content|complete`, `/evidence` | S (UI capture incomplete) |
| Summary / review / signature / complete | `/summary`, `/review`, `/signature`, `/complete` | D |
| Sync + conflicts | `/sync`, conflicts screen | D |
| Profile | `/auth/me`, `/i18n/*` | D |

### Public report
`/r/{token}` + `/r/{token}/pdf` — all content from snapshot. **S** (empty slots).

---

## 4. Phases and exit criteria

### Phase 0 — Stop the bleeding (1–2 days)
- Consent control wired (approve/publish usable).
- Refresh-on-401 with single-flight retry; sign out only when refresh fails.
- Remove `messageAr` + all Arabic literals.
- Report: map client name (masked), drop empty labelled specs.
- Fix local env drift (`infra/.env` vs `start-mysql-backend.ps1` encryption key).
Exit: the E2E loop passes with no manual API step; `mvn test` + all app suites green.

### Phase 1 — Reference data foundation (4–6 days)
- Migrations for `reference_domain` (+ seed of statuses, roles, severity, result, units).
- Separate endpoints per concern — `/reference/statuses/{type}`, `/reference/dropdowns/{set}`,
  `/reference/enums/{code}` — each with its own ETag/version. No aggregated bundle.
- Flutter `ReferenceDataRepository` in `packages/api_client` + Riverpod providers with
  per-domain cache and typed models; one widget kit (`StatusChip`, `OptionDropdown`,
  `FilterBar`) reading only the repository.
Exit: no client file maps a status code to a label or colour; `grep` gate added.

### Phase 2 — Workshop Admin conversion (5–7 days)
- Dashboard, jobs queue/filters, job detail badges, wizard status/role/language
  selectors, templates status, staff roles → reference data.
- Consent + publish flow completed; derived score/counts read from server summary.
- Remove `labels.dart` maps and `job_status_badge` tone switch.
Exit: Playwright workshop flow (create → assign → review → approve → publish) passes
with zero local copy; no literal scan hits.

### Phase 3 — Technician conversion (5–7 days)
- Queue filters/status, item result buttons, severity/issue/location/action/urgency
  pickers from option sets, unit dropdowns from reference data.
- Evidence capture: camera-only photo + video per rule, upload queue, retry, progress,
  offline persistence, submit gated by server blockers.
- Remove local status labels and conflict copy.
Exit: a technician can complete a 30-item job entirely in the UI (photo + video per item,
offline then sync), and the server accepts it.

### Phase 4 — Platform Admin conversion (4–6 days)
- Dashboard metrics/alerts as data (no switch on alert keys), config-health labels from
  reference data, master library legacy Arabic accessors removed.
- CRUD for every reference domain (statuses, option sets, units, document types,
  scoring rules) with publish/version semantics.
Exit: adding a new status/option in Platform Admin makes it selectable in Workshop and
Technician without a rebuild.

### Phase 5 — Report completion (3–4 days)
- Snapshot mapper fills or omits every slot; masking policy server-side.
- Section-level contract tests; PDF parity with HTML.
Exit: publish 3 jobs (pass, attention, defect) → all three reports have no empty
labelled box and identical field sets between HTML and PDF.

### Phase 6 — Decommission legacy (2–3 days)
- Delete `/legacy` controllers and client methods; delete unused endpoints in
  `ApiEndpoints`.
Exit: `grep -r "/legacy"` returns nothing; all suites green.

### Phase 7 — Gates and hardening (3–4 days)
- CI: literal scan, reference-data usage scan, OpenAPI diff (backend), golden tests at
  3 breakpoints, Playwright E2E (workshop→template→inspection→report), load test.
- Observability: request ids, error budget on `/jobs/*` and `/reference/*`.
Exit: a merge fails if a new literal or a hardcoded status label is introduced.

---

## 5. Test strategy (must be real, not aspirational)

1. **Contract tests per app** (Dart): decode fixtures generated from live endpoints;
   fail on unknown/absent fields.
2. **OpenAPI**: publish `springdoc` spec in CI; fail on breaking diff.
3. **Reference data**: every selector renders exactly what the endpoint returns; empty
   state when the endpoint returns none (no hardcoded fallback list).
4. **Inspection**: server blocker tests (photo/video/notes/measurement/signature) +
   client gating tests; offline queue tests.
5. **E2E (Playwright MCP)**: the run performed manually, scripted:
   workshop login → template job → technician evidence + submit → review → consent →
   approve → publish → public HTML + PDF assertions.
6. **Report snapshot test**: no empty labelled cells for three outcome profiles.
7. **Literal gate**: `node tools/audit_hardcoded_strings.js` must report zero
   user-visible sentences outside `preview/` and tests.
8. **Reference-data gate**: a scan forbidding `switch (status)` on label/colour.

---

## 6. Definition of done

- A new workshop can register, create a job from a published template, assign a
  technician, have the technician complete every item with required photo + video
  (online or offline), review, approve, publish, and open a public HTML/PDF report —
  with no API call made outside the apps and no manual DB step.
- Every visible string resolves through the backend bundle; every chip, dropdown,
  status, enum, count and card value comes from an endpoint.
- Adding a status, option, severity, location, unit or language in Platform Admin
  appears in Workshop and Technician without a rebuild.
- No `/legacy` routes, no Arabic, no client-side label/tone maps, no empty labelled
  report slots.
- CI enforces all of the above.

---

## 7. Risks / sequencing notes

- **Evidence capture is the hardest part** (camera, video length, offline queue). It
  gates Phase 3 and therefore the definition of done; start device-side capture early.
- **Reference data is a cross-cutting refactor**: land Phase 1 before touching screens,
  otherwise each screen invents its own model again.
- **Consent is a legal/UI decision** (where it lives, what text it needs); agree the
  wording with the owner before Phase 2 ships.
- **Legacy deletion** must ship with the client release; otherwise old builds break.
- **Offline**: every reference domain used offline must be cached with a version, and
  the technician must be able to start a job without connectivity.
