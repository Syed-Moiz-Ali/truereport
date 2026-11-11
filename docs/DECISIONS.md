# Decisions Log

This file records product/technical decisions made during the dynamic-report work. Each decision is binding unless superseded by a later entry.

---

## D-001 — Prompt scoring wins over the old “coverage, not condition score” rule

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** Older Phase 1/6 decisions say the public report must not use a single condition score as the primary summary. The new prompt requires a weighted overall score and A/B/C/D grade.

**Decision:** The new prompt wins. The public report will show a weighted overall score and grade as the primary result. Coverage counts remain visible as supporting information.

**Consequences:**
- `docs/phase-1/06-public-report-design.md`, `docs/phase-1/07-database-design.md`, and related ADRs are superseded where they conflict.
- Scoring must be server-authoritative and snapshot-based.
- The report must explain score, grade, and any applied safety cap.

---

## D-002 — Additive job review/publication workflow

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** Existing jobs use `DRAFT → SCHEDULED → ASSIGNED → IN_PROGRESS → READY_TO_FINALIZE → FINALIZED`. The prompt requires `DRAFT → IN_PROGRESS → PENDING_REVIEW → APPROVED → PUBLISHED`.

**Decision:** Keep the existing inspection statuses and add separate review/publication state fields. New APIs expose the requested five-stage workflow.

**Consequences:**
- Existing tests/UI continue to work.
- New `review_status` (`NOT_SUBMITTED`, `PENDING_REVIEW`, `APPROVED`, `RETURNED`) and `publication_status` (`UNPUBLISHED`, `PUBLISHED`).
- Existing `FINALIZED` maps to `PENDING_REVIEW` in the new workflow view.
- Document the mapping in `MIGRATION.md`.

---

## D-003 — Platform-Admin global templates

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** Existing templates are workshop-scoped. The prompt requires Platform Admin to define named templates that Workshop Admin selects.

**Decision:** Add versioned global master templates (`master_templates`, `master_template_versions`, `master_template_items`). Keep existing workshop templates for backward compatibility.

**Consequences:**
- Workshop Admin job creation can select either a global template or an existing workshop template during the transition.
- Global templates pin master item versions and are immutable once published.
- Existing jobs keep their pinned versions.

---

## D-004 — Video thumbnails: client poster + optional server ffmpeg

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** ffmpeg is not installed in the local environment.

**Decision:** Accept a client-captured poster/thumbnail for video evidence. If ffmpeg is available on the server, generate a thumbnail asynchronously. If not, use the client poster or a first-frame fallback on the public page.

**Consequences:**
- Video upload must support an optional poster image.
- Public report has a media fallback when no thumbnail exists.
- Document the ffmpeg optional dependency in ops docs.

---

## D-005 — Spec copied into the repository

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The authoritative 6-category / 30-item spec is stored at `docs/truereport-spec.md`.

**Consequences:**
- The seed and tests reference stable item codes from this document.
- Changes to the spec require a new seed version and a decision entry.

---

## D-006 — Platform-first implementation order

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Implement in this order:
1. Platform Admin
2. Workshop Admin
3. Technician
4. Public website

**Rationale:** Workshop and Technician consume Platform-Admin configuration, so the source of truth must exist first.

---

## D-007 — Structured, Platform-defined issue capture

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** Free-text comments are inconsistent, hard to validate, and hard to translate for the public report.

**Decision:** Issue description is captured through Platform-Admin-defined option sets and per-item issue fields. Workshop Admin and Technician can only select predefined values; they cannot create or change configuration.

**Consequences:**
- New tables for option sets, issue fields, per-item option subsets, and assessment issue values.
- Free-text `reasonText` is no longer the primary issue description.
- Public report renders structured fields with EN/AR labels.
- Only Platform Admin write endpoints mutate configuration.

---

## D-008 — Fully configurable issue form per item

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Each item version defines its own issue-field schema: field codes, labels EN/AR, input types, option sets, required rules, min/max, units, dependencies, multi-value behavior, and free-text allowance.

**Consequences:**
- Technician UI renders fields dynamically from the checklist response.
- Server validates every submitted field against the item’s schema.
- Seed data includes per-item schemas for all 30 items.

---

## D-009 — Status and score auto-suggested from measurement bands

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** When a numeric measurement is entered, the server maps it to a Platform-Admin-defined measurement band and suggests the result and score. The technician may adjust the score only within the suggested band.

**Consequences:**
- `item_measurement_bands` table and validation.
- Cross-band scores are rejected with a structured error.
- Multi-point items derive status from the worst measurement (configurable).

---

## D-010 — Free-text notes optional and item-controlled

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Free-text notes are disabled by default. A note field appears only when the item version sets `allow_free_text_note = true`. Selection and measurement fields remain mandatory.

**Consequences:**
- Technician cannot submit arbitrary notes unless enabled.
- Note-length rules apply only when a note is required by the evidence rule.
- Public report displays notes only when present.

---

## D-011 — Seed via migration + idempotent endpoint

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The default checklist seed runs automatically through Flyway and can also be re-run through `POST /api/v1/platform/seed/default-checklist`.

**Consequences:**
- Seed is idempotent by stable code/version.
- Existing user edits are never overwritten.
- Seed returns created/skipped/error counts.

---

## D-012 — Global templates are versioned and immutable

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Global Platform-Admin templates use draft/published versions, consistent with existing template versioning (ADR-0016).

**Consequences:**
- Published template versions and their items are immutable.
- Jobs pin a template version at creation.
- Editing a template creates a new draft version.

---

## D-013 — Canonical result code names

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Use these stored values everywhere:
- `NO_ISSUE_OBSERVED`
- `ATTENTION_RECOMMENDED`
- `DEFECT_FOUND`
- `NOT_CHECKED`
- `NOT_APPLICABLE`
- `COULD_NOT_VERIFY`

Display labels:
- PASS / ATTENTION / FAIL

**Consequences:**
- Flutter, Java, seed, HTML/JS, and API payloads use the stored values.
- Public report displays localized labels, not raw codes.

---

## D-014 — Report document types are data

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The five supplementary documents are stored as configurable `report_document_types`, not hardcoded HTML cards.

**Consequences:**
- Platform Admin can add/deactivate/reorder document types.
- Workshop Admin uploads or generates a file per document type.
- Public report renders only documents present for the report version and links to their actual files.

---

## D-015 — Public report keeps SSR but adds a JSON API

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Keep the existing server-rendered Thymeleaf page for compatibility, but add `GET /public/reports/{token}` JSON. Both use the same snapshot payload builder, so there is one source of truth.

**Consequences:**
- No duplicated mapping.
- The page can progressively move to client-side rendering later without changing the API.
- Public report tests cover both HTML and JSON.

---

## D-016 — Media URLs are token-scoped capability URLs

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Public media is served through token-scoped URLs (`/r/{token}/photo/...`, `/r/{token}/video/...`, `/r/{token}/document/...`). The report token acts as the capability. No separate signed-expiry scheme in V1.

**Consequences:**
- Token rotation/revocation invalidates media access.
- No public bucket access.
- Cache headers must be `no-store` or `private` for media.

---

## D-017 — Platform Admin scope includes catalogues/equipment cleanup

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The Platform phase includes making master library, option sets, templates, scoring, document types, data catalogues, equipment, and audit API-backed. Production mock data is removed. The hierarchy layout is kept but hardcoded fallbacks are removed.

**Consequences:**
- Platform app CI coverage is added.
- Mock sample providers are deleted from production paths.

---

## D-018 — Melos/shared package deviation

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** The prompt suggests new `truereport_models`, `truereport_api`, and `truereport_ui` packages. The repo already has `domain`, `api_client`, and `design_system`.

**Decision:** Extend the existing packages instead of creating duplicate packages.

**Consequences:**
- Shared inspection/report models go into `domain` or the relevant app until a dedicated package is justified.
- `api_client` remains the single typed HTTP client.
- `design_system` gains score/status/media components.

---

## D-019 — No commits without explicit request

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Changes are made in small reviewable batches but are not committed unless the user explicitly asks.

---

## D-020 — Maker-checker for Platform Admin scoring and safety changes

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Scoring rules, grade boundaries, safety-critical flags, hard-fail caps, and template publication require a second Platform Admin approval before taking effect.

**Consequences:**
- Add a `PENDING_APPROVAL` state for changes to scoring/safety configuration.
- The proposer cannot approve their own change.
- Approval and rejection are audited with actor, reason, timestamp, and field-level diff.
- Other master content edits may publish directly unless they alter scoring/safety behaviour.

---

## D-021 — No correction workflow

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** There is no correction/return-for-correction flow. Workshop Admin either approves or rejects a completed inspection. A rejected inspection is closed; a new inspection job is required to try again.

**Consequences:**
- No editing of finalized assessments, findings, or evidence.
- No `RETURNED` review state.
- Rejection requires a reason code and is audited.
- A new inspection creates a new job, snapshot, report version, and token.

---

## D-022 — Approval is performed by Workshop Admin, never the technician

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Only a `WORKSHOP_ADMIN` approves and publishes a job. The approver must not be the assigned technician, even if the user holds both roles.

**Consequences:**
- Server checks role, workshop scope, and `approver_user_id != technician_id`.
- Publish requires an approval record with actor, timestamp, and reason.

---

## D-023 — Every item requires photo and video evidence

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** By default every inspection item requires at least **1 photo and 1 video** for **all** results, including `NO_ISSUE_OBSERVED`. `ATTENTION_RECOMMENDED` requires at least 1 photo and 1 video; `DEFECT_FOUND` requires at least 2 photos and 1 video. Platform Admin can increase but not weaken these defaults per item.

**Consequences:**
- `item_evidence_rules` seeds PASS with photo=1, video=1.
- Save/complete validation enforces photo and video evidence for every assessed item.
- Video upload, storage, thumbnails/posters, and public video rendering are required in the Technician and Public phases.
- Storage sizing and upload UX must account for video on every item.

---

## D-024 — Supplementary documents are generated after publish

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The configured report document types are generated automatically by the backend after a report is published and stored in the database/object storage. They are not a pre-publish gate. Workshop Admin does not have to upload them manually.

**Consequences:**
- Publish triggers document generation for active document types.
- Generated documents are linked to the published report version and are immutable.
- The public report lists the generated documents with their actual URLs.
- Generation failures are retried and surfaced to Platform/Workshop Admin.
- Manual upload may be added later as an override, but is not required in V1.

---

## D-025 — No post-publish corrections; new inspection only

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Published reports are permanently immutable. There is no correction, amendment, or versioning of a published report. Any re-inspection is a brand-new inspection job with a new job ID, snapshot, report, and token.

**Consequences:**
- Old tokens remain valid for the old report version unless revoked.
- No report revision API/UI.
- Audit clearly links a re-inspection to the previous job if desired, but does not mutate the old one.

---

## D-026 — Offline conflict policy: server wins, block until revalidated

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** When an offline assessment conflicts with a newer server revision, the server version wins. The technician app shows a field-level diff and requires the technician to review and re-save before the item can be completed. The app does not auto-merge and does not silently discard the technician’s change.

**Consequences:**
- Every mutation carries `baseVersion`/`clientRevision`.
- On conflict, the server returns `409 CONFLICT` with the current server state and conflicting fields.
- Completion/finalization is blocked until all conflicts are resolved.
- Evidence uploads are idempotent by hash; duplicate queued items are skipped.

---

# Flow Freeze — Approved 2026-11-11

The following flows were reviewed and approved by the product owner. They are binding for V1 implementation.

## D-027 — Platform Admin flow decisions

**Status:** Approved

| # | Decision |
|---|---|
| P1 | Any other active Platform Admin can approve a maker-checker change. The proposer cannot approve their own change. |
| P2 | Maker-checker applies to scoring rules, grade boundaries, safety flags, hard-fail caps, and template publication. Normal category/item text edits publish directly. |
| P3 | Categories/items in use cannot be deleted. They are retired/deactivated and show a usage count. |
| P4 | Active category weights must sum to 100. Templates re-normalize weights across only the categories present in the template. |
| P5 | Option values cannot be deleted. They are retired, optionally with a replacement mapping. |
| P6 | JSON/CSV bulk import is included, with dry-run validation and an error report. Import always creates new versions. |
| P7 | A configuration health dashboard is included: missing EN/AR, weight gaps, band gaps/overlaps, retired options in use, safety items missing evidence rules. |
| P8 | Draft simulation/preview is included: preview the technician form and public report card before publishing. |
| P9 | Seed contains master configuration only. No fake jobs, customers, vehicles, or reports. |

## D-028 — Workshop Admin flow decisions

**Status:** Approved

| # | Decision |
|---|---|
| W1 | Customer name and phone are required; email is optional. |
| W2 | VIN, make, model, year, plate, odometer, transmission, and fuel type are required. |
| W3 | Customer/vehicle edits are allowed only before finalization. Every edit is audited. No edits after finalization. |
| W4 | A rejected job is closed as `REJECTED`. A new inspection job is required. |
| W5 | Workshop Admin can unpublish/revoke with a reason. The token becomes unavailable. |
| W6 | Report documents generate asynchronously after publish. The public page shows a generating state until they are ready; failures retry and are surfaced. |
| W7 | QR codes are generated by the server; the app displays/downloads them. |
| W8 | Public-link consent is required before token activation. |
| W9 | Technician workload is a warning, not a hard block. |
| W10 | The approver must be a Workshop Admin and must not be the assigned technician. |

## D-029 — Technician flow decisions

**Status:** Approved

| # | Decision |
|---|---|
| T1 | Numeric items cannot be saved without a measurement. |
| T2 | When a measurement is entered, status is derived from the measurement band. The technician cannot choose a contradictory status. |
| T3 | Score is editable only inside the suggested band. |
| T4 | Evidence must be captured live via camera. Gallery selection is blocked for evidence. |
| T5 | Items can only be skipped as `NOT_APPLICABLE` with a predefined reason. No free text. |
| T6 | Finalization is not allowed offline. All queued items must sync first. |
| T7 | Signature is required at completion: name, timestamp, device identifier, and hash. |
| T8 | The technician can see a live score, clearly marked as draft until Workshop Admin approval. |
| T9 | Multi-point items use the worst corner for item status and score. |
| T10 | Video evidence is 15–30 seconds, maximum 50 MB, compressed before upload. |
| T11 | The technician can see customer PII while the job is active; access is audited. |

## D-030 — Public report flow decisions

**Status:** Approved

| # | Decision |
|---|---|
| R1 | Show customer name only. Never expose phone or email. |
| R2 | Do not show the technician’s name publicly. Show the workshop only. |
| R3 | VIN is masked (last 4 characters only). |
| R4 | Plate number is masked or omitted publicly. |
| R5 | PDF download is disabled by default; Workshop Admin can enable it. |
| R6 | Empty sections are hidden. The findings section shows an explicit “No issues found” state. |
| R7 | English is the default language; EN/AR toggle with full RTL. |
| R8 | The report shows score, grade, counts, and the reason for any applied safety cap. |
| R9 | Documents show a “Generating…” state until ready, then actual links. |
| R10 | Unknown, expired, revoked, and unpublished tokens all return the same neutral 404 page. |

## D-031 — Cross-cutting flow decisions

**Status:** Approved

| # | Decision |
|---|---|
| C1 | In-app notifications only for V1. Email/SMS later. |
| C2 | Audit records include actor, action, entity, before/after, reason, timestamp, and IP. |
| C3 | Idempotency is required on job create, assessment save, evidence upload, approve, and publish. |
| C4 | Optimistic concurrency is required on every mutation. |
| C5 | Public media uses token-scoped capability URLs; no public bucket access. |
| C6 | Seed data contains master configuration only; no fake reports or jobs. |

## D-032 — Implementation gate

**Status:** Approved

**Decision:** No application or migration code starts until the product owner explicitly approves the start of the Platform phase.

**Consequences:**
- Documentation and flow decisions may be updated.
- Code, migrations, seeders, and tests wait for approval.

---

# Language & Localization Decisions — Approved 2026-11-11

## D-033 — Common language API for all platforms

**Status:** Approved

**Decision:** All platforms use one common language API:
- `GET /api/v1/i18n/languages`
- `GET /api/v1/i18n/me`
- `PUT /api/v1/i18n/me`

**Consequences:**
- Platform Admin, Workshop Admin, Technician, and public pages share the same language registry and preference model.
- No per-app language APIs.
- Public pages additionally support `?lang=en|ar`.

## D-034 — Hybrid translation source

**Status:** Approved

**Decision:**
- Flutter UI chrome: ARB files.
- API errors, validation, notifications, and PDF labels: `messages_en/ar.properties`.
- Master/business content: DB `localized_content`.
- Report snapshots: both languages stored in the snapshot.

**Consequences:**
- System messages remain reliable and versioned.
- Platform Admin controls all business content translations.
- No runtime dependency on a translation table for API errors.

## D-035 — Platform-Admin-only language registry CRUD

**Status:** Approved

**Decision:** Only Platform Admin can create, update, activate, deactivate, reorder, or set the default language.

**Consequences:**
- Workshop Admin and Technician can only read the language list and change their own current language.
- The default language cannot be deactivated.
- A language used by a job/customer preference cannot be deactivated without a replacement.

## D-036 — Server-side language preference with local cache

**Status:** Approved

**Decision:** Store the user's preferred language on the server and cache it locally on the device.

**Consequences:**
- Preference follows the user across devices.
- Offline/instant switching uses the local cache.
- `ApiClient` sends `Accept-Language` on every request.

## D-037 — Separate EN and AR generated PDFs

**Status:** Approved

**Decision:** Generate separate English and Arabic PDFs for each generated report document type after publish.

**Consequences:**
- Public report links the current language version.
- Both artifacts are stored and linked to the published report version.
- If one language fails, fall back to the other and surface retry status.
- No manual document upload gate.

## D-038 — Public report defaults to job preferred language

**Status:** Approved

**Decision:** The public report defaults to `inspection_jobs.preferred_language`. A `?lang=en|ar` URL parameter overrides it. Fallback is the default language, then English.

**Consequences:**
- HTML/PDF sets `dir="rtl"` for Arabic.
- JSON always includes both languages.
- Customer/job language is stored on the job.

## D-039 — EN/AR mandatory and translation completeness enforced

**Status:** Approved

**Decision:** All user-facing master content and system messages must have EN and AR. CI verifies properties/ARB key parity. Platform Admin publish validation requires EN + AR. A coverage endpoint/dashboard reports missing translations.

**Consequences:**
- RU/ZH-Hans are optional and fall back to English.
- Publishing fails with `TRANSLATION_REQUIRED` when EN or AR is missing.
- Seed data is validated for EN/AR completeness.

## D-040 — Western digits in both languages

**Status:** Approved

**Decision:** Use Western digits in both English and Arabic, consistent with ADR-0012.

**Consequences:**
- Dates, measurements, odometer, and scores use Western digits.
- Arabic text remains RTL; only numerals are Western.
- Flutter formatting remains locale-aware but does not convert digits to Arabic-Indic.

---

## D-041 — Manual bilingual entry now; LLM auto-translation deferred

**Status:** Approved

**Decision:** For V1, Platform Admin manually enters EN and AR for every configurable field. No LLM or machine translation service is included in the Platform phase.

**Reason:**
- The platform owner will define every field needed by Workshop Admin and Technician.
- Manual entry guarantees accurate automotive terminology and legal wording.
- It avoids adding a translation service, GPU/CPU load, and extra operational complexity before the configuration model is stable.

**Consequences:**
- Platform Admin screens must show EN/AR inputs for every user-facing text: categories, items, instructions, standard specs, option sets/values, issue fields, band criteria, grade labels, document types, and template names/descriptions.
- Publish validation requires EN + AR for all user-facing content.
- The language API still exists; users can switch EN/AR, but translations are authored manually.
- A future LLM auto-translate feature is explicitly out of scope for V1.
- When added later, it must remain a draft assistant with human approval and must not change the stored bilingual model.

---

# Professional Flow Decisions — Approved 2026-11-11

## D-042 — V1 professional core pack

**Status:** Approved

**Decision:** Include the following in V1:
1. Configuration release lifecycle: Draft → Review → Approved → Published → Deprecated.
2. Change impact analysis before publish/deactivate.
3. Configuration health dashboard.
4. Evidence quality gates.
5. Approval checklist before publish.
6. Transactional outbox for report/document/delivery/notification jobs.
7. Observability metrics, structured logs, and alerts.
8. Public verification page.
9. API standards: pagination, filtering, sorting, ETag/If-Match, idempotency, RFC 9457 errors.

**Consequences:**
- New schema for master releases, outbox events, and report validity.
- Publish/completion flows gain additional server-side gates.
- Observability is wired from the first implementation phase, not added later.
- Technician qualification, tool calibration, and QC sampling are removed from V1 (D-046).

## D-043 — Configurable report validity/expiry

**Status:** Approved

**Decision:** Report validity is configurable (default e.g. 90 days). The published snapshot stores `valid_until`. The public report shows validity and handles expired reports explicitly.

**Consequences:**
- Expired reports are not treated as unknown; they show a clear expired state or a neutral read-only page.
- Revoked and unknown tokens remain indistinguishable.
- Validity is snapshotted so later config changes do not alter old reports.

## D-044 — Technician certification and tool calibration (removed)

**Status:** Removed by D-046

**Decision:** Previously approved, now removed from scope. No technician certification matrix, tool register, calibration checks, or related schema/APIs are added.

## D-045 — QC sampling (removed)

**Status:** Removed by D-046

**Decision:** Previously approved as deferred, now removed from scope. No QC sampling or re-inspection design, schema, screens, or APIs are added.

---

## D-046 — Technician qualification, tool calibration, and QC sampling removed

**Status:** Approved

**Decision:** The following are explicitly out of scope:
- Technician qualification/certification matrix.
- Tool calibration register and blocking checks.
- Quality-control sampling/re-inspection.

**Reason:** Product owner does not want these flows.

**Consequences:**
- No certification/tool/QC tables, endpoints, or screens.
- Job assignment remains based on technician role, active status, and workshop scope only.
- Completion does not check tool calibration.
- The professional core pack is limited to D-042 items 1–9.

---

## D-047 — Backend full rebuild

**Status:** Approved

**Decision:** The backend is rebuilt cleanly instead of continuing to patch the existing implementation. The current backend is a reference only.

**Consequences:**
- New module structure and clean schema baseline.
- New services, controllers, validation, scoring, snapshots, and tests.
- Explicit data migration for any real existing data.
- Breaking API changes documented in `docs/MIGRATION.md`.
- See `docs/BACKEND_REBUILD_PLAN.md`.

## D-048 — Frontend reuse and adaptive layout rules

**Status:** Approved

**Decision:** Do not redesign the frontend. Reuse existing screens, components, design system, and visual identity. Adapt only data wiring, state, and responsive behaviour.

**Consequences:**
- No fixed container widths/heights copied from Figma.
- Use `LayoutBuilder`, `MediaQuery`, `Flexible`, `Expanded`, `Wrap`, `AspectRatio`, `ConstrainedBox`, breakpoints, and design tokens.
- Test phone/tablet/desktop, portrait/landscape, EN/AR/RTL.
- See `docs/FRONTEND_ADAPTIVE_RULES.md`.

---

# Implementation Gate

**Status:** Approved

**Decision:** No application or migration code starts until the product owner explicitly approves the start of the Platform phase.

**Consequences:**
- Documentation may continue to be updated.
- Code, migrations, seeders, and tests wait for explicit approval.

---

## D-049 — Phase 1 clean baseline uses additive `platform_*` tables

**Date:** 2026-11-11
**Status:** Accepted

**Context:** The rebuilt backend must have a clean schema baseline that does not build on V1–V18, while the existing reference application (identity, jobs, reports) must remain bootable during the phased rebuild.

**Decision:** Phase 1 configuration tables are introduced in a clean additive migration `V100__platform_admin_clean_baseline.sql` using a `platform_*` prefix. Legacy V1–V18 tables remain untouched and are treated as reference-only. Categories/items continue to use the approved legacy `master_categories` / `master_inspection_items` / `master_item_versions` tables, extended by side tables (`platform_category_config`, `platform_item_metadata`, `platform_score_bands`, `platform_evidence_rules`, `platform_issue_fields`, `platform_issue_field_options`, `platform_measurement_bands`) keyed by string UUIDs.

**Consequences:**
- New modules never read or write legacy report/job tables except for impact-count scaffolding.
- No legacy migration is modified; the old schema remains available for data comparison.
- A future cutover can archive V1–V18 once Workshop/Technician/Public phases no longer depend on the reference tables.
- The full physical migration of legacy migrations to `db/archive` is deferred to the cutover runbook because moving them now would break the existing reference application and its tests.

## D-050 — Common i18n endpoints require authentication

**Date:** 2026-11-11
**Status:** Accepted

**Context:** `GET /api/v1/i18n/languages` is shared by all authenticated apps. The security inventory test requires every non-public API endpoint to reject anonymous access and every handler to declare explicit authorization.

**Decision:** All `/api/v1/i18n/**` endpoints require an authenticated user (`@PreAuthorize("isAuthenticated()")`). Language discovery for sign-in screens continues to use bundled Flutter ARB resources; no pre-auth API call is required.

**Consequences:**
- Anonymous language discovery is not exposed.
- Platform Admin language registry CRUD remains PLATFORM_ADMIN-only under `/api/v1/platform/i18n/**`.
- `Accept-Language` and `?lang` resolution are unaffected.

## D-051 — Maker-checker is represented by pending states

**Date:** 2026-11-11
**Status:** Accepted

**Context:** Scoring, grade boundary, safety-cap and template changes require a second Platform Admin approval (D-020).

**Decision:** Proposals are applied in a pending state (`platform_scoring_rules.pending_approval`, `platform_grade_boundaries.approved = false`, `platform_template_versions.status = PENDING_APPROVAL`). `platform_change_requests` records the proposer and action. Approval is rejected when the acting user is the proposer (`MAKER_CHECKER_SELF_APPROVAL`). Template versions move to `PUBLISHED` only after approval.

**Consequences:**
- UI shows a pending badge and an approve action.
- Scoring/grade changes are not treated as effective until approved.
- Audit and outbox events record both proposal and approval.

## D-052 — Seed is idempotent and never overwrites existing codes

**Date:** 2026-11-11
**Status:** Accepted

**Decision:** `POST /api/v1/platform/seed/default-checklist` seeds 10 option sets, 6 categories with weights 25/18/20/17/10/10, 30 items with score bands/evidence rules/measurement bands/issue fields, 5 document types, the GCC scoring rule with grade boundaries, and `TPL-30-GCC` with all 30 items. Existing category slugs, item codes, option sets, document types, scoring rules and templates are skipped, never overwritten.

**Consequences:**
- Re-running the endpoint returns `created = 0` after a complete seed.
- Seed data contains no jobs, customers, vehicles or reports (P9).
- User edits to seeded rows are preserved.

## D-053 — Pre-existing report test failures are out of Phase 1 scope

**Date:** 2026-11-11
**Status:** Accepted (blocker recorded)

**Context:** The working tree already contained uncommitted changes to `server/src/main/java/com/truereport/reports/PublicReportService.java` and `server/src/main/resources/templates/report/print-report.html`. `ReportDeliveryBundleParityTest` and `ReportIT` fail because the uncommitted `print-report.html` contains literal user-facing text and a different report title/brand string. Rule 11 explicitly forbids touching these files in Phase 1.

**Decision:** Do not modify the uncommitted report files or their tests in Phase 1. Record the two failures as a pre-existing blocker for the Public Report phase.

**Consequences:**
- Backend Phase 1 tests pass except the two pre-existing report tests.
- The Public Report phase must either complete or revert the uncommitted report work before the full suite can be green.

---

## D-054 — Anonymous GET for the common language list (supersedes D-050)

**Date:** 2026-11-11
**Status:** Accepted. D-050 is superseded.

**Decision:** `GET /api/v1/i18n/languages` is public and anonymous. `GET /api/v1/i18n/me` and `PUT /api/v1/i18n/me` remain authenticated. Platform language registry CRUD remains `PLATFORM_ADMIN` only under `/api/v1/platform/i18n/**`.

**Consequences:**
- Public and pre-auth surfaces can discover active languages.
- User preference reads/writes still require a session.
- `SecurityEndpointInventoryIT` treats the language list as a public prefix.

## D-055 — Platform Admin content lives fully in clean platform_* tables

**Date:** 2026-11-11
**Status:** Accepted. Supersedes the side-table portion of D-049.

**Decision:** Categories, items, item versions, labels/instructions and item metadata are stored only in:
- `platform_categories`
- `platform_items`
- `platform_item_versions`
- `platform_guide_images`

Child configuration remains keyed by `item_version_id` with real foreign keys:
`platform_score_bands`, `platform_evidence_rules`, `platform_issue_fields`,
`platform_issue_field_options`, `platform_measurement_bands`.

`platform_category_config` and `platform_item_metadata` are migrated into the clean parent/version rows and then dropped.

**Consequences:**
- Platform Admin services, seed, governance and global templates no longer read `master_categories`, `master_inspection_items`, `master_item_versions`, `platform_category_config` or `platform_item_metadata`.
- Legacy master tables remain for the reference Workshop/Reports code but are not part of Platform Admin configuration.
- All Platform Admin IDs are VARCHAR(36) UUID strings; legacy BINARY(16) IDs are converted during migration.
- Migration `V102__Migrate_platform_content` copies legacy data when present; it is a no-op on a fresh database.
- Guide image storage is owned by `platform_guide_images`; the legacy guide-image table is kept only for the reference app.

## D-056 — Platform Admin responsive verification is mandatory

**Date:** 2026-11-11
**Status:** Accepted.

**Decision:** Platform Admin screens are verified at 360, 600, 768, 1024 and 1440 px in EN and Arabic/RTL. Layout containers do not use fixed widths/heights; fixed values are limited to icon/avatar sizes, hit targets, spacing tokens and intrinsic media ratios.

**Consequences:**
- `test/adaptive_layout_test.dart` pumps every Platform Admin configuration screen at all five widths plus Arabic RTL.
- Sidebar width is derived from the available width and clamped; header/search heights come from content with min/max constraints.

## D-057 — Platform Admin writes platform audit; audit endpoint merges legacy identity events

**Date:** 2026-11-11
**Status:** Accepted.

**Decision:** Platform Admin configuration writes only `platform_audit_events` (via `FieldAuditService`). Legacy identity/account actions continue to write `audit_events` for the reference app. `GET /api/v1/platform/audit-events` merges both sources and returns the newest events, so existing account-lifecycle audit tests remain valid without duplicating configuration writes.

**Consequences:**
- No Platform Admin configuration write touches the legacy audit table.
- Audit history remains complete during the phased rebuild.
- The legacy audit dependency can be removed once identity is rebuilt in a later phase.
