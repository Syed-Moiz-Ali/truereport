# TrueReport Dynamic Report Audit

**Date:** 2026-11-11  
**Scope:** Java backend, Flutter (Melos) workspace, public report HTML/CSS/JS.  
**Purpose:** Gap analysis for making the public report fully dynamic and Platform-Admin-driven.

> Source spec: `docs/truereport-spec.md` (copied from the authoritative 6-category / 30-item checklist specification).

---

## 1. Executive Summary

The repository already has a strong foundation: Spring Boot + MySQL/Flyway, JWT roles, versioned master content, workshop templates, jobs, technician assessments, evidence upload, report snapshots, and a server-rendered public report.

However, the public report is **not yet data-driven end-to-end**:

- Large parts of the report are fabricated in `ReportViewMapper.java` (vehicle specs, visual inspections, 38 showcase photos, tyres, damage zones, videos, document cards).
- Scoring does not exist as a service. Item scores and grade thresholds are hardcoded in the mapper, the HTML, the print template, and `report.js`, with conflicting values.
- There is **no public JSON API** (`GET /public/reports/{token}`).
- Master data lacks category weights, unit/sensor/spec fields, safety flags, score bands, evidence rules, scoring rules, grade boundaries, global templates, and report document types.
- Evidence supports images only; no video, documents, captions, duration, or thumbnails.
- The technician app hardcodes result vocabularies, category icons, evidence minimums, and has no dynamic issue form or score/measurement bands.
- Platform Admin master screens are in-memory mocks with hardcoded sample data.
- The 6-category / 30-item seed does not exist in the repo.

---

## 2. Stack and Environment

| Area | Finding |
|---|---|
| Backend | Spring Boot 4.1.2, Java 25, Maven, Spring Modulith, JPA, Security, Flyway, Thymeleaf |
| Database | MySQL 8.4 LTS in production config; H2 in MySQL mode for tests |
| Migrations | `server/src/main/resources/db/migration` (V1–V18), MySQL-specific in `migration-mysql`, H2-specific in test resources |
| Auth | Stateless JWT, Argon2, refresh rotation, TOTP; roles `PLATFORM_ADMIN`, `WORKSHOP_ADMIN`, `TECHNICIAN` |
| Tenant scoping | Manual `workshop_id` filtering in services |
| Flutter | Flutter 3.47.9, Dart 3.13.7, Riverpod, go_router, gen_l10n, Drift offline store |
| Melos | Config embedded in `client/pubspec.yaml`; no `melos.yaml` |
| Local tooling | Java 25 available via Maven; Docker and ffmpeg are **not installed** |

---

## 3. Backend Gap Analysis

### 3.1 Master data

| Requirement | Status | Evidence / gap |
|---|---|---|
| Categories with EN/AR | EXISTS | `master_categories`, `localized_content`; `V4__master_content.sql` |
| Category weight | MISSING | No weight column |
| Category active flag | PARTIAL | `status ACTIVE/RETIRED` |
| Category reorder | EXISTS | `sort_order` |
| Items with stable code, category | EXISTS | `master_inspection_items` |
| Item EN/AR label + instruction | EXISTS | `localized_content`; publish requires EN + AR |
| Measurement unit | MISSING | Only job odometer unit exists |
| Sensor/tool | PARTIAL | Generic `equipment` catalog only |
| Standard spec text | MISSING | Hardcoded in `ReportViewMapper` |
| `is_safety_critical` | MISSING | Only assessment severity can be `SAFETY_CRITICAL` |
| Item sort order | MISSING | Items ordered by `stable_code` |
| Active flag | PARTIAL | `DRAFT/PUBLISHED/RETIRED` |
| Score bands | MISSING | Hardcoded 100/70/40 in mapper |
| Evidence rules | PARTIAL | `note_requirement`, `evidence_requirement`, `min_photos`; no videos, notes chars, per-status rules, document evidence |
| Per-item weight | MISSING | — |
| Versioning / immutability | EXISTS | `master_item_versions`; MySQL triggers `V6` |
| Reorder items | MISSING | — |

### 3.2 Templates

| Requirement | Status | Evidence / gap |
|---|---|---|
| Platform Admin global templates | MISSING | Templates are workshop-scoped (`V5`) |
| Named template sets | MISSING | No master template tables |
| Template versioning | EXISTS (workshop only) | `template_versions`, pinned master versions |
| Template item add/remove/reorder | EXISTS (workshop) | `template_items` |
| Template weight re-normalization | MISSING | No weights at all |
| Workshop selects template for job | EXISTS | Job pins `template_version_id` |

### 3.3 Scoring / grades

| Requirement | Status | Evidence / gap |
|---|---|---|
| Scoring service | MISSING | — |
| Category weights | MISSING | — |
| Overall weighted score | MISSING | Mapper uses pass-rate counts |
| Grade boundaries | MISSING | Hardcoded in three places with conflicting values |
| Safety hard-fail caps | MISSING | — |
| Counts passed/attention/defects | PARTIAL | Mapper counts result codes |
| Applied-cap explanation | MISSING | — |

### 3.4 Jobs / workflow

| Requirement | Status | Evidence / gap |
|---|---|---|
| Job create/update/assign | EXISTS | `WorkshopJobService`, `WorkshopJobController` |
| Status flow | PARTIAL | Actual: `DRAFT → SCHEDULED → ASSIGNED → IN_PROGRESS → READY_TO_FINALIZE → FINALIZED`; no `PENDING_REVIEW/APPROVED/PUBLISHED` |
| Workshop approval | MISSING | Finalization is technician-driven |
| Publish/unpublish/rotate token | PARTIAL | Link activate/revoke; no publish endpoint or rotation |
| Technician signature | MISSING | No field/table/endpoint |
| Snapshot at approval/publish | PARTIAL | Report snapshot created at finalization |
| Scope by workshop/technician | EXISTS | Manual service guards |
| Supplementary documents | PARTIAL | Hardcoded 5 HTML cards, all pointing to one PDF |
| Report document types | MISSING | — |

### 3.5 Assessments / evidence

| Requirement | Status | Evidence / gap |
|---|---|---|
| Result code required | EXISTS | `InspectionService` validation |
| Score 0–100 | MISSING | No score field |
| Diagnostic metric / sensor | MISSING | No fields |
| Bilingual notes EN/AR | PARTIAL | Single `note_text` + `note_language` |
| Sub-measurements | MISSING | — |
| Structured issue options | MISSING | Free-text `reason_text`; item `reason_codes_json` unused by UI |
| Photo evidence | EXISTS | JPEG/HEIC/HEIF, 8 MB, single PUT |
| Video evidence | MISSING | — |
| Document evidence | MISSING | — |
| Captions EN/AR | MISSING | Generic i18n caption only |
| Duration / thumbnail | MISSING | `PUBLIC_THUMB` purpose never created |
| Chunked/multipart upload | MISSING | Single octet-stream PUT |
| Evidence rules per status | MISSING | Only global `min_photos` |
| Notes min chars | MISSING | — |
| Multi-point worst-case | MISSING | — |
| Offline queue | EXISTS (technician) | Drift queue and sync service |

### 3.6 Reports / public delivery

| Requirement | Status | Evidence / gap |
|---|---|---|
| Report snapshot | EXISTS | `ReportSnapshot`, `ReportSnapshotBuilder` |
| Snapshot immutability | EXISTS | MySQL triggers `V11`; service guards |
| Public HTML page | EXISTS | Thymeleaf `public-report.html` |
| Public JSON API | MISSING | Only HTML + photo/PDF |
| Data-driven report content | PARTIAL | Core items from snapshot; huge hardcoded blocks in `ReportViewMapper` |
| Grade from data | MISSING | Grade `A` hardcoded in HTML |
| Public scoring explanation | MISSING | Hardcoded grade bands in HTML |
| Documents list from data | MISSING | 5 hardcoded cards |
| Videos from evidence | MISSING | Hardcoded video URLs; no video assets exist |
| Photos from evidence | PARTIAL | Derivatives exist; showcase is hardcoded |
| Damage map from data | MISSING | Hotspots hardcoded |
| Tyres from measurements | MISSING | Hardcoded 4 wheels |
| 404 for unknown/unpublished | EXISTS | Same unavailable page |
| Cache/rate limit | PARTIAL | `no-store`; in-memory unbounded rate limiter |
| Media URL model | PARTIAL | Token-scoped photo endpoint |
| PII redaction | PARTIAL | Snapshot builder sanitizes notes, masks VIN |

### 3.7 Key hardcoded backend content

- Vehicle specs: `ReportViewMapper.java:226-241`
- 8 visual inspection cards: `ReportViewMapper.java:468-659`
- System summary rows: `ReportViewMapper.java:706-720`
- 38 showcase photos: `ReportViewMapper.java:737-1057`
- Diagnostic/standard specs: `ReportViewMapper.java:1060-1100`
- Tyre assemblies: `ReportViewMapper.java:1120-1237`
- Damage zones: `ReportViewMapper.java:1239-1357`
- Inspector summary: `ReportViewMapper.java:1379-1454`
- Videos: `ReportViewMapper.java:1456-1494`
- Item scores 100/70/40: `ReportViewMapper.java:369-373`
- Grade thresholds: `ReportViewMapper.java:317,373`; `public-report.html:1044-1071`; `print-report.html:1400,1479,1556`; `report.js:82,90`
- Grade `A`: `public-report.html:180`; `print-report.html:1034`
- Five document cards: `public-report.html:700-796`

---

## 4. Flutter Gap Analysis

### 4.1 Workspace

| App / package | Role | Status |
|---|---|---|
| `apps/platform_admin_app` | Platform Admin | EXISTS; master screens are mocks |
| `apps/workshop_admin_app` | Workshop Admin | EXISTS; no approve/publish/QR |
| `apps/technician_app` | Technician | EXISTS; hardcoded vocab and rules |
| `apps/ui_gallery` | Developer gallery | EXISTS; release-guarded |
| `packages/domain` | Auth/session/workshop only | PARTIAL |
| `packages/api_client` | Shared Dio client/endpoints | EXISTS |
| `packages/design_system` | Tokens/components | EXISTS |
| `packages/l10n` | EN/AR gen_l10n | EXISTS |
| `packages/offline_sync` | Interface only | PARTIAL |
| `packages/auth` | Auth/session | EXISTS |

No shared models for categories, items, bands, evidence rules, templates, assessments, report result, or scoring. Models are duplicated across apps.

### 4.2 Platform Admin

| Requirement | Status | Evidence / gap |
|---|---|---|
| Categories list/edit/weights/reorder | PARTIAL/MISSING | UI mock; no weight API |
| Items list/edit with EN/AR | PARTIAL | Mock editor, fake save |
| Bands/evidence rules editor | MISSING | Read-only canned dialog |
| Global templates builder | MISSING | No screen/API |
| Scoring rules/grades | MISSING | No model/screen/API |
| Document types | MISSING | — |
| Option sets / dynamic issue fields | MISSING | — |
| Catalogues/equipment API-backed | MISSING | Hardcoded lists |
| Settings/audit/hierarchy | PARTIAL | Some hardcoded fallbacks/sample data |
| EN/AR/RTL | PARTIAL | Own locale provider; inline strings |

Key files: `platform_models.dart:202-253` (sample items), `master_library_screen.dart:32-38`, `master_item_editor_screen.dart:58-75,104-149`, `data_catalogues_screen.dart:88-197`, `equipment_library_screen.dart:52-101`.

### 4.3 Workshop Admin

| Requirement | Status | Evidence / gap |
|---|---|---|
| Job create/assign/list | EXISTS | API-backed |
| Findings review | PARTIAL | Report page only |
| Approve & issue certificate | MISSING | No approval/publish UI |
| Supplementary documents | MISSING | Only PDF download |
| Public link/QR/share | PARTIAL | Link exists; no QR |
| Report content | PARTIAL | English-only keys; generic map |
| Template builder | EXISTS | Workshop-scoped; publish allows zero items |
| Hardcoded content | PRESENT | Delivery channels, fake template metrics, UTC+4 assumptions |

### 4.4 Technician

| Requirement | Status | Evidence / gap |
|---|---|---|
| Dynamic category tabs | PARTIAL | Hub derives categories, checklist is flat |
| Item instructions/spec/evidence rules | PARTIAL | Displays note/photo minimum only |
| Score bands / suggestion | MISSING | — |
| Measurement unit | MISSING | — |
| Dynamic issue options | MISSING | Hardcoded result/severity selectors |
| Photo capture | EXISTS | image_picker + compression |
| Video capture | MISSING | — |
| Document upload | MISSING | — |
| Evidence checklist | PARTIAL | Displays min photos; no enforcement |
| Autosave drafts | EXISTS | Assessment save |
| Offline queue | EXISTS | Drift queue/sync; no automatic retry loop |
| Signature | MISSING | — |
| Complete flow | EXISTS | Review/finalize, server-driven blocking |
| Client validation mirrors server | PARTIAL | Result/severity/note; no bands/evidence |

Key hardcoded files: `dense_mechanical_view.dart:45-62,643-648`, `defect_detail_view.dart:53-57,814`, `inspection_hub_view.dart:418-461`, `assessment_page.dart:166,211-229`, `finalize_view.dart:966,990,1014`.

---

## 5. Public Report Gap Analysis

### 5.1 Section-to-data mapping

| Section | Needs from API |
|---|---|
| Header/token badge | report token/report number, language, PDF capability |
| Hero vehicle card | vehicle make/model/year/VIN masked/odometer/transmission/fuel/plate (private) |
| Score ring | overall score, grade letter, grade label EN/AR, counts |
| Verdict | grade label, applied caps explanation |
| Coverage | completed/applicable |
| Key findings | item label EN/AR, result, severity, score, measurement, standard spec, issue fields, media |
| Categories | category code/name EN/AR/weight/score/status, items |
| Category items | item code/label/instruction/result/score/measurement/issue fields/media |
| Photos | all photo evidence with captions/thumbnails/URLs |
| Videos | all video evidence with duration/poster/caption/item code |
| Documents | document type code/name EN/AR/URL/status |
| Tyres | multi-point measurements (FL/FR/RL/RR) |
| Damage map | body location fields/hotspots and severity |
| Verification | report hash, workshop, published timestamp |
| Not checked | item label, result, reason |

### 5.2 Hardcoded HTML/JS content

| Location | Hardcoded value |
|---|---|
| `public-report.html:180` | Grade `A` |
| `public-report.html:263,276` | Key finding category = Braking System |
| `public-report.html:526` | Score 82, `42mm scratch`, sensor name |
| `public-report.html:707` | Documents count `5` |
| `public-report.html:718,735,752,769,786` | Fake document telemetry |
| `public-report.html:712-794` | Five document cards, all same PDF |
| `public-report.html:999,1001` | Lightbox total `38` |
| `public-report.html:1044-1071` | Grade bands |
| `public-report.html:433-467` | Damage-map hotspots |
| `public-report.html:674` | Video action has no JS handler |
| `report.js:16` | Default score 100 |
| `report.js:82,90` | Score thresholds 90/70 |
| `report.js:56-57` | Arabic literals |

### 5.3 States and security

- Present: 404 unavailable page, 503 temporary page, empty findings, rate limit 429.
- Missing: loading skeleton (SSR), broken-media fallback, empty states for photos/videos/documents/categories, video dialog handler.
- XSS posture is good: `th:text`/`textContent`, no `innerHTML`.
- CSP has `unsafe-inline` due to inline `onclick`; no `connect-src`.
- Token is path-based and never logged in JS; share copies full URL.
- Rate limiter trusts `X-Forwarded-For` and has no eviction.

---

## 6. Requirement Gap Table

| Prompt requirement | Status | Notes |
|---|---|---|
| No hardcoded categories/items/weights/thresholds/grades/report text | MISSING | Backend mapper, HTML, JS, Flutter mocks |
| Platform Admin master config | PARTIAL | Categories/items exist; weights/bands/rules/templates/scoring/docs missing |
| Dynamic option sets for issue description | MISSING | All layers |
| Score bands per item | MISSING | — |
| Evidence rules per item/status | PARTIAL | Photos only |
| Global templates + re-normalization | MISSING | — |
| Job approval/publish workflow | MISSING | — |
| Technician signature | MISSING | — |
| Snapshot immutability | EXISTS/PARTIAL | Master/report immutability exists; snapshot completeness incomplete |
| Server-authoritative scoring | MISSING | — |
| Shared validator with structured errors | PARTIAL | Hardcoded messages; no field errors |
| Public JSON API | MISSING | — |
| Dynamic public page | PARTIAL | SSR driven partly by snapshot, many hardcoded blocks |
| EN/AR + RTL | EXISTS/PARTIAL | Public + apps; some inline strings |
| Public privacy redaction | PARTIAL | VIN masked, notes sanitized; customer name still modeled |
| Role/tenant isolation | EXISTS | Manual scoping; tests exist |
| Tests for new logic | MISSING | No scoring/bands/seed/JSON tests |
| 30-item seed | MISSING | Not in repo |
| MIGRATION / DECISIONS docs | MISSING | To be created |

---

## 7. Locked Decisions (from product clarification)

1. **Prompt wins over old “coverage, not condition score” decisions** — weighted overall score and A/B/C/D grade become the primary result.
2. **Job workflow is additive**: keep existing inspection statuses; add review/publication status fields and expose the requested five-stage workflow in new APIs.
3. **Global Platform-Admin templates** are added; existing workshop templates remain for backward compatibility.
4. **Video thumbnails**: client-captured poster accepted; server-side thumbnail generation optional when ffmpeg exists.
5. **Spec is copied into the repo** at `docs/truereport-spec.md`.
6. **Platform-first sequence**: Platform Admin → Workshop Admin → Technician → Public website.
7. **Dynamic issue capture**: Platform Admin defines option sets and per-item issue fields; Workshop/Technician are read-only.
8. **Fully configurable issue form per item**, with cascading dependencies.
9. **Status and score auto-suggested from Platform-Admin measurement bands**; technician may adjust only within the band.
10. **Free-text notes are optional and item-controlled** (`allow_free_text_note`), off by default.
11. **Seed runs via migration plus an idempotent Platform Admin endpoint**.
12. **Global templates are versioned** and immutable once published.

---

## 8. Risks / Open Questions

| Risk | Impact | Mitigation |
|---|---|---|
| Old ADRs forbid condition score | Design conflict | Record supersession in `DECISIONS.md`; keep coverage metrics visible alongside score |
| No 30-item seed in repo | Blocks Phase 1 | Use `docs/truereport-spec.md` as source; seed JSON + Java migration |
| MySQL integration tests cannot run locally (no Docker) | Migration risk | Run H2 tests locally; add MySQL Testcontainers in CI |
| ffmpeg unavailable | Video thumbnails | Client poster; optional server ffmpeg |
| Snapshot completeness | Published report may still change | Snapshot all config at approval/publish; tests |
| Existing published reports have no scores | Backfill required | Data migration maps legacy result codes to documented legacy scores |
| Public page hardcoded model | Large refactor | Replace `ReportViewMapper` constants with snapshot payload; shared DTO for HTML + JSON |
| Platform Admin mock screens | Rework | Replace providers with API-backed Riverpod providers |

---

## 9. Recommended Implementation Order

1. Phase 0: spec + audit + platform plan + dynamic issue design.
2. Platform foundation: schema, seed, scoring config, dynamic issue config.
3. Platform backend APIs.
4. Platform Flutter screens.
5. Platform tests.
6. Workshop Admin backend + Flutter (approval/publish/documents/QR).
7. Technician backend + Flutter (dynamic checklist/issues/evidence/signature/offline).
8. Public JSON API + dynamic page + states/security.
9. Migration/decisions cleanup + full builds/tests.
