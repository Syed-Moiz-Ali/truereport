# Decisions Log

This file records product/technical decisions made during the dynamic-report work. Each decision is binding unless superseded by a later entry.

---

## D-001 â€” Prompt scoring wins over the old â€œcoverage, not condition scoreâ€ rule

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** Older Phase 1/6 decisions say the public report must not use a single condition score as the primary summary. The new prompt requires a weighted overall score and A/B/C/D grade.

**Decision:** The new prompt wins. The public report will show a weighted overall score and grade as the primary result. Coverage counts remain visible as supporting information.

**Consequences:**
- `docs/phase-1/06-public-report-design.md`, `docs/phase-1/07-database-design.md`, and related ADRs are superseded where they conflict.
- Scoring must be server-authoritative and snapshot-based.
- The report must explain score, grade, and any applied safety cap.

---

## D-002 â€” Additive job review/publication workflow

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** Existing jobs use `DRAFT â†’ SCHEDULED â†’ ASSIGNED â†’ IN_PROGRESS â†’ READY_TO_FINALIZE â†’ FINALIZED`. The prompt requires `DRAFT â†’ IN_PROGRESS â†’ PENDING_REVIEW â†’ APPROVED â†’ PUBLISHED`.

**Decision:** Keep the existing inspection statuses and add separate review/publication state fields. New APIs expose the requested five-stage workflow.

**Consequences:**
- Existing tests/UI continue to work.
- New `review_status` (`NOT_SUBMITTED`, `PENDING_REVIEW`, `APPROVED`, `RETURNED`) and `publication_status` (`UNPUBLISHED`, `PUBLISHED`).
- Existing `FINALIZED` maps to `PENDING_REVIEW` in the new workflow view.
- Document the mapping in `MIGRATION.md`.

---

## D-003 â€” Platform-Admin global templates

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** Existing templates are workshop-scoped. The prompt requires Platform Admin to define named templates that Workshop Admin selects.

**Decision:** Add versioned global master templates (`master_templates`, `master_template_versions`, `master_template_items`). Keep existing workshop templates for backward compatibility.

**Consequences:**
- Workshop Admin job creation can select either a global template or an existing workshop template during the transition.
- Global templates pin master item versions and are immutable once published.
- Existing jobs keep their pinned versions.

---

## D-004 â€” Video thumbnails: client poster + optional server ffmpeg

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** ffmpeg is not installed in the local environment.

**Decision:** Accept a client-captured poster/thumbnail for video evidence. If ffmpeg is available on the server, generate a thumbnail asynchronously. If not, use the client poster or a first-frame fallback on the public page.

**Consequences:**
- Video upload must support an optional poster image.
- Public report has a media fallback when no thumbnail exists.
- Document the ffmpeg optional dependency in ops docs.

---

## D-005 â€” Spec copied into the repository

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The authoritative 6-category / 30-item spec is stored at `docs/truereport-spec.md`.

**Consequences:**
- The seed and tests reference stable item codes from this document.
- Changes to the spec require a new seed version and a decision entry.

---

## D-006 â€” Platform-first implementation order

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Implement in this order:
1. Platform Admin
2. Workshop Admin
3. Technician
4. Public website

**Rationale:** Workshop and Technician consume Platform-Admin configuration, so the source of truth must exist first.

---

## D-007 â€” Structured, Platform-defined issue capture

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

## D-008 â€” Fully configurable issue form per item

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Each item version defines its own issue-field schema: field codes, labels EN/AR, input types, option sets, required rules, min/max, units, dependencies, multi-value behavior, and free-text allowance.

**Consequences:**
- Technician UI renders fields dynamically from the checklist response.
- Server validates every submitted field against the itemâ€™s schema.
- Seed data includes per-item schemas for all 30 items.

---

## D-009 â€” Status and score auto-suggested from measurement bands

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** When a numeric measurement is entered, the server maps it to a Platform-Admin-defined measurement band and suggests the result and score. The technician may adjust the score only within the suggested band.

**Consequences:**
- `item_measurement_bands` table and validation.
- Cross-band scores are rejected with a structured error.
- Multi-point items derive status from the worst measurement (configurable).

---

## D-010 â€” Free-text notes optional and item-controlled

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Free-text notes are disabled by default. A note field appears only when the item version sets `allow_free_text_note = true`. Selection and measurement fields remain mandatory.

**Consequences:**
- Technician cannot submit arbitrary notes unless enabled.
- Note-length rules apply only when a note is required by the evidence rule.
- Public report displays notes only when present.

---

## D-011 â€” Seed via migration + idempotent endpoint

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The default checklist seed runs automatically through Flyway and can also be re-run through `POST /api/v1/platform/seed/default-checklist`.

**Consequences:**
- Seed is idempotent by stable code/version.
- Existing user edits are never overwritten.
- Seed returns created/skipped/error counts.

---

## D-012 â€” Global templates are versioned and immutable

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Global Platform-Admin templates use draft/published versions, consistent with existing template versioning (ADR-0016).

**Consequences:**
- Published template versions and their items are immutable.
- Jobs pin a template version at creation.
- Editing a template creates a new draft version.

---

## D-013 â€” Canonical result code names

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

## D-014 â€” Report document types are data

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The five supplementary documents are stored as configurable `report_document_types`, not hardcoded HTML cards.

**Consequences:**
- Platform Admin can add/deactivate/reorder document types.
- Workshop Admin uploads or generates a file per document type.
- Public report renders only documents present for the report version and links to their actual files.

---

## D-015 â€” Public report keeps SSR but adds a JSON API

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Keep the existing server-rendered Thymeleaf page for compatibility, but add `GET /public/reports/{token}` JSON. Both use the same snapshot payload builder, so there is one source of truth.

**Consequences:**
- No duplicated mapping.
- The page can progressively move to client-side rendering later without changing the API.
- Public report tests cover both HTML and JSON.

---

## D-016 â€” Media URLs are token-scoped capability URLs

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Public media is served through token-scoped URLs (`/r/{token}/photo/...`, `/r/{token}/video/...`, `/r/{token}/document/...`). The report token acts as the capability. No separate signed-expiry scheme in V1.

**Consequences:**
- Token rotation/revocation invalidates media access.
- No public bucket access.
- Cache headers must be `no-store` or `private` for media.

---

## D-017 â€” Platform Admin scope includes catalogues/equipment cleanup

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** The Platform phase includes making master library, option sets, templates, scoring, document types, data catalogues, equipment, and audit API-backed. Production mock data is removed. The hierarchy layout is kept but hardcoded fallbacks are removed.

**Consequences:**
- Platform app CI coverage is added.
- Mock sample providers are deleted from production paths.

---

## D-018 â€” Melos/shared package deviation

**Date:** 2026-11-11  
**Status:** Accepted

**Context:** The prompt suggests new `truereport_models`, `truereport_api`, and `truereport_ui` packages. The repo already has `domain`, `api_client`, and `design_system`.

**Decision:** Extend the existing packages instead of creating duplicate packages.

**Consequences:**
- Shared inspection/report models go into `domain` or the relevant app until a dedicated package is justified.
- `api_client` remains the single typed HTTP client.
- `design_system` gains score/status/media components.

---

## D-019 â€” No commits without explicit request

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Changes are made in small reviewable batches but are not committed unless the user explicitly asks.

---

## D-020 â€” Maker-checker for Platform Admin scoring and safety changes

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Scoring rules, grade boundaries, safety-critical flags, hard-fail caps, and template publication require a second Platform Admin approval before taking effect.

**Consequences:**
- Add a `PENDING_APPROVAL` state for changes to scoring/safety configuration.
- The proposer cannot approve their own change.
- Approval and rejection are audited with actor, reason, timestamp, and field-level diff.
- Other master content edits may publish directly unless they alter scoring/safety behaviour.

---

## D-021 â€” No correction workflow

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** There is no correction/return-for-correction flow. Workshop Admin either approves or rejects a completed inspection. A rejected inspection is closed; a new inspection job is required to try again.

**Consequences:**
- No editing of finalized assessments, findings, or evidence.
- No `RETURNED` review state.
- Rejection requires a reason code and is audited.
- A new inspection creates a new job, snapshot, report version, and token.

---

## D-022 â€” Approval is performed by Workshop Admin, never the technician

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Only a `WORKSHOP_ADMIN` approves and publishes a job. The approver must not be the assigned technician, even if the user holds both roles.

**Consequences:**
- Server checks role, workshop scope, and `approver_user_id != technician_id`.
- Publish requires an approval record with actor, timestamp, and reason.

---

## D-023 â€” Every item requires photo and video evidence

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** By default every inspection item requires at least **1 photo and 1 video** for **all** results, including `NO_ISSUE_OBSERVED`. `ATTENTION_RECOMMENDED` requires at least 1 photo and 1 video; `DEFECT_FOUND` requires at least 2 photos and 1 video. Platform Admin can increase but not weaken these defaults per item.

**Consequences:**
- `item_evidence_rules` seeds PASS with photo=1, video=1.
- Save/complete validation enforces photo and video evidence for every assessed item.
- Video upload, storage, thumbnails/posters, and public video rendering are required in the Technician and Public phases.
- Storage sizing and upload UX must account for video on every item.

---

## D-024 â€” Supplementary documents are generated after publish

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

## D-025 â€” No post-publish corrections; new inspection only

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** Published reports are permanently immutable. There is no correction, amendment, or versioning of a published report. Any re-inspection is a brand-new inspection job with a new job ID, snapshot, report, and token.

**Consequences:**
- Old tokens remain valid for the old report version unless revoked.
- No report revision API/UI.
- Audit clearly links a re-inspection to the previous job if desired, but does not mutate the old one.

---

## D-026 â€” Offline conflict policy: server wins, block until revalidated

**Date:** 2026-11-11  
**Status:** Accepted

**Decision:** When an offline assessment conflicts with a newer server revision, the server version wins. The technician app shows a field-level diff and requires the technician to review and re-save before the item can be completed. The app does not auto-merge and does not silently discard the technicianâ€™s change.

**Consequences:**
- Every mutation carries `baseVersion`/`clientRevision`.
- On conflict, the server returns `409 CONFLICT` with the current server state and conflicting fields.
- Completion/finalization is blocked until all conflicts are resolved.
- Evidence uploads are idempotent by hash; duplicate queued items are skipped.

---

# Flow Freeze â€” Approved 2026-11-11

The following flows were reviewed and approved by the product owner. They are binding for V1 implementation.

## D-027 â€” Platform Admin flow decisions

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

## D-028 â€” Workshop Admin flow decisions

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

## D-029 â€” Technician flow decisions

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
| T10 | Video evidence is 15â€“30 seconds, maximum 50 MB, compressed before upload. |
| T11 | The technician can see customer PII while the job is active; access is audited. |

## D-030 â€” Public report flow decisions

**Status:** Approved

| # | Decision |
|---|---|
| R1 | Show customer name only. Never expose phone or email. |
| R2 | Do not show the technicianâ€™s name publicly. Show the workshop only. |
| R3 | VIN is masked (last 4 characters only). |
| R4 | Plate number is masked or omitted publicly. |
| R5 | PDF download is disabled by default; Workshop Admin can enable it. |
| R6 | Empty sections are hidden. The findings section shows an explicit â€œNo issues foundâ€ state. |
| R7 | English is the default language; EN/AR toggle with full RTL. |
| R8 | The report shows score, grade, counts, and the reason for any applied safety cap. |
| R9 | Documents show a â€œGeneratingâ€¦â€ state until ready, then actual links. |
| R10 | Unknown, expired, revoked, and unpublished tokens all return the same neutral 404 page. |

## D-031 â€” Cross-cutting flow decisions

**Status:** Approved

| # | Decision |
|---|---|
| C1 | In-app notifications only for V1. Email/SMS later. |
| C2 | Audit records include actor, action, entity, before/after, reason, timestamp, and IP. |
| C3 | Idempotency is required on job create, assessment save, evidence upload, approve, and publish. |
| C4 | Optimistic concurrency is required on every mutation. |
| C5 | Public media uses token-scoped capability URLs; no public bucket access. |
| C6 | Seed data contains master configuration only; no fake reports or jobs. |

## D-032 â€” Implementation gate

**Status:** Approved

**Decision:** No application or migration code starts until the product owner explicitly approves the start of the Platform phase.

**Consequences:**
- Documentation and flow decisions may be updated.
- Code, migrations, seeders, and tests wait for approval.

---

# Language & Localization Decisions â€” Approved 2026-11-11

## D-033 â€” Common language API for all platforms

**Status:** Approved

**Decision:** All platforms use one common language API:
- `GET /api/v1/i18n/languages`
- `GET /api/v1/i18n/me`
- `PUT /api/v1/i18n/me`

**Consequences:**
- Platform Admin, Workshop Admin, Technician, and public pages share the same language registry and preference model.
- No per-app language APIs.
- Public pages additionally support `?lang=en|ar`.

## D-034 â€” Hybrid translation source

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

## D-035 â€” Platform-Admin-only language registry CRUD

**Status:** Approved

**Decision:** Only Platform Admin can create, update, activate, deactivate, reorder, or set the default language.

**Consequences:**
- Workshop Admin and Technician can only read the language list and change their own current language.
- The default language cannot be deactivated.
- A language used by a job/customer preference cannot be deactivated without a replacement.

## D-036 â€” Server-side language preference with local cache

**Status:** Approved

**Decision:** Store the user's preferred language on the server and cache it locally on the device.

**Consequences:**
- Preference follows the user across devices.
- Offline/instant switching uses the local cache.
- `ApiClient` sends `Accept-Language` on every request.

## D-037 â€” Separate EN and AR generated PDFs

**Status:** Approved

**Decision:** Generate separate English and Arabic PDFs for each generated report document type after publish.

**Consequences:**
- Public report links the current language version.
- Both artifacts are stored and linked to the published report version.
- If one language fails, fall back to the other and surface retry status.
- No manual document upload gate.

## D-038 â€” Public report defaults to job preferred language

**Status:** Approved

**Decision:** The public report defaults to `inspection_jobs.preferred_language`. A `?lang=en|ar` URL parameter overrides it. Fallback is the default language, then English.

**Consequences:**
- HTML/PDF sets `dir="rtl"` for Arabic.
- JSON always includes both languages.
- Customer/job language is stored on the job.

## D-039 â€” EN/AR mandatory and translation completeness enforced

**Status:** Approved

**Decision:** All user-facing master content and system messages must have EN and AR. CI verifies properties/ARB key parity. Platform Admin publish validation requires EN + AR. A coverage endpoint/dashboard reports missing translations.

**Consequences:**
- RU/ZH-Hans are optional and fall back to English.
- Publishing fails with `TRANSLATION_REQUIRED` when EN or AR is missing.
- Seed data is validated for EN/AR completeness.

## D-040 â€” Western digits in both languages

**Status:** Approved

**Decision:** Use Western digits in both English and Arabic, consistent with ADR-0012.

**Consequences:**
- Dates, measurements, odometer, and scores use Western digits.
- Arabic text remains RTL; only numerals are Western.
- Flutter formatting remains locale-aware but does not convert digits to Arabic-Indic.

---

## D-041 â€” Manual bilingual entry now; LLM auto-translation deferred

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

# Professional Flow Decisions â€” Approved 2026-11-11

## D-042 â€” V1 professional core pack

**Status:** Approved

**Decision:** Include the following in V1:
1. Configuration release lifecycle: Draft â†’ Review â†’ Approved â†’ Published â†’ Deprecated.
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

## D-043 â€” Configurable report validity/expiry

**Status:** Approved

**Decision:** Report validity is configurable (default e.g. 90 days). The published snapshot stores `valid_until`. The public report shows validity and handles expired reports explicitly.

**Consequences:**
- Expired reports are not treated as unknown; they show a clear expired state or a neutral read-only page.
- Revoked and unknown tokens remain indistinguishable.
- Validity is snapshotted so later config changes do not alter old reports.

## D-044 â€” Technician certification and tool calibration (removed)

**Status:** Removed by D-046

**Decision:** Previously approved, now removed from scope. No technician certification matrix, tool register, calibration checks, or related schema/APIs are added.

## D-045 â€” QC sampling (removed)

**Status:** Removed by D-046

**Decision:** Previously approved as deferred, now removed from scope. No QC sampling or re-inspection design, schema, screens, or APIs are added.

---

## D-046 â€” Technician qualification, tool calibration, and QC sampling removed

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
- The professional core pack is limited to D-042 items 1â€“9.

---

## D-047 â€” Backend full rebuild

**Status:** Approved

**Decision:** The backend is rebuilt cleanly instead of continuing to patch the existing implementation. The current backend is a reference only.

**Consequences:**
- New module structure and clean schema baseline.
- New services, controllers, validation, scoring, snapshots, and tests.
- Explicit data migration for any real existing data.
- Breaking API changes documented in `docs/MIGRATION.md`.
- See `docs/BACKEND_REBUILD_PLAN.md`.

## D-048 â€” Frontend reuse and adaptive layout rules

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

## D-049 â€” Phase 1 clean baseline uses additive `platform_*` tables

**Date:** 2026-11-11
**Status:** Accepted

**Context:** The rebuilt backend must have a clean schema baseline that does not build on V1â€“V18, while the existing reference application (identity, jobs, reports) must remain bootable during the phased rebuild.

**Decision:** Phase 1 configuration tables are introduced in a clean additive migration `V100__platform_admin_clean_baseline.sql` using a `platform_*` prefix. Legacy V1â€“V18 tables remain untouched and are treated as reference-only. Categories/items continue to use the approved legacy `master_categories` / `master_inspection_items` / `master_item_versions` tables, extended by side tables (`platform_category_config`, `platform_item_metadata`, `platform_score_bands`, `platform_evidence_rules`, `platform_issue_fields`, `platform_issue_field_options`, `platform_measurement_bands`) keyed by string UUIDs.

**Consequences:**
- New modules never read or write legacy report/job tables except for impact-count scaffolding.
- No legacy migration is modified; the old schema remains available for data comparison.
- A future cutover can archive V1â€“V18 once Workshop/Technician/Public phases no longer depend on the reference tables.
- The full physical migration of legacy migrations to `db/archive` is deferred to the cutover runbook because moving them now would break the existing reference application and its tests.

## D-050 â€” Common i18n endpoints require authentication

**Date:** 2026-11-11
**Status:** Accepted

**Context:** `GET /api/v1/i18n/languages` is shared by all authenticated apps. The security inventory test requires every non-public API endpoint to reject anonymous access and every handler to declare explicit authorization.

**Decision:** All `/api/v1/i18n/**` endpoints require an authenticated user (`@PreAuthorize("isAuthenticated()")`). Language discovery for sign-in screens continues to use bundled Flutter ARB resources; no pre-auth API call is required.

**Consequences:**
- Anonymous language discovery is not exposed.
- Platform Admin language registry CRUD remains PLATFORM_ADMIN-only under `/api/v1/platform/i18n/**`.
- `Accept-Language` and `?lang` resolution are unaffected.

## D-051 â€” Maker-checker is represented by pending states

**Date:** 2026-11-11
**Status:** Accepted

**Context:** Scoring, grade boundary, safety-cap and template changes require a second Platform Admin approval (D-020).

**Decision:** Proposals are applied in a pending state (`platform_scoring_rules.pending_approval`, `platform_grade_boundaries.approved = false`, `platform_template_versions.status = PENDING_APPROVAL`). `platform_change_requests` records the proposer and action. Approval is rejected when the acting user is the proposer (`MAKER_CHECKER_SELF_APPROVAL`). Template versions move to `PUBLISHED` only after approval.

**Consequences:**
- UI shows a pending badge and an approve action.
- Scoring/grade changes are not treated as effective until approved.
- Audit and outbox events record both proposal and approval.

## D-052 â€” Seed is idempotent and never overwrites existing codes

**Date:** 2026-11-11
**Status:** Accepted

**Decision:** `POST /api/v1/platform/seed/default-checklist` seeds 10 option sets, 6 categories with weights 25/18/20/17/10/10, 30 items with score bands/evidence rules/measurement bands/issue fields, 5 document types, the GCC scoring rule with grade boundaries, and `TPL-30-GCC` with all 30 items. Existing category slugs, item codes, option sets, document types, scoring rules and templates are skipped, never overwritten.

**Consequences:**
- Re-running the endpoint returns `created = 0` after a complete seed.
- Seed data contains no jobs, customers, vehicles or reports (P9).
- User edits to seeded rows are preserved.

## D-053 â€” Pre-existing report test failures are out of Phase 1 scope

**Date:** 2026-11-11
**Status:** Accepted (blocker recorded)

**Context:** The working tree already contained uncommitted changes to `server/src/main/java/com/truereport/reports/PublicReportService.java` and `server/src/main/resources/templates/report/print-report.html`. `ReportDeliveryBundleParityTest` and `ReportIT` fail because the uncommitted `print-report.html` contains literal user-facing text and a different report title/brand string. Rule 11 explicitly forbids touching these files in Phase 1.

**Decision:** Do not modify the uncommitted report files or their tests in Phase 1. Record the two failures as a pre-existing blocker for the Public Report phase.

**Consequences:**
- Backend Phase 1 tests pass except the two pre-existing report tests.
- The Public Report phase must either complete or revert the uncommitted report work before the full suite can be green.

---

## D-054 â€” Anonymous GET for the common language list (supersedes D-050)

**Date:** 2026-11-11
**Status:** Accepted. D-050 is superseded.

**Decision:** `GET /api/v1/i18n/languages` is public and anonymous. `GET /api/v1/i18n/me` and `PUT /api/v1/i18n/me` remain authenticated. Platform language registry CRUD remains `PLATFORM_ADMIN` only under `/api/v1/platform/i18n/**`.

**Consequences:**
- Public and pre-auth surfaces can discover active languages.
- User preference reads/writes still require a session.
- `SecurityEndpointInventoryIT` treats the language list as a public prefix.

## D-055 â€” Platform Admin content lives fully in clean platform_* tables

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

## D-056 â€” Platform Admin responsive verification is mandatory

**Date:** 2026-11-11
**Status:** Accepted.

**Decision:** Platform Admin screens are verified at 360, 600, 768, 1024 and 1440 px in EN and Arabic/RTL. Layout containers do not use fixed widths/heights; fixed values are limited to icon/avatar sizes, hit targets, spacing tokens and intrinsic media ratios.

**Consequences:**
- `test/adaptive_layout_test.dart` pumps every Platform Admin configuration screen at all five widths plus Arabic RTL.
- Sidebar width is derived from the available width and clamped; header/search heights come from content with min/max constraints.

## D-057 â€” Platform Admin writes platform audit; audit endpoint merges legacy identity events

**Date:** 2026-11-11
**Status:** Accepted.

**Decision:** Platform Admin configuration writes only `platform_audit_events` (via `FieldAuditService`). Legacy identity/account actions continue to write `audit_events` for the reference app. `GET /api/v1/platform/audit-events` merges both sources and returns the newest events, so existing account-lifecycle audit tests remain valid without duplicating configuration writes.

**Consequences:**
- No Platform Admin configuration write touches the legacy audit table.
- Audit history remains complete during the phased rebuild.
- The legacy audit dependency can be removed once identity is rebuilt in a later phase.

---

## D-058 â€” Phase 2 uses clean `platform_*` job tables and preserves additive review/publication state

**Date:** 2026-11-12
**Status:** Accepted

**Context:** The rebuilt backend must not build new Workshop Admin flows on the legacy `inspection_jobs`, `job_assignments`, `reports` or `public_share_links` tables. The legacy reference application and its tests still need those tables and endpoints during the phased rebuild.

**Decision:** Phase 2 introduces clean tables in `V105__workshop_admin_phase2.sql`:
`platform_jobs`, `platform_job_assignments`, `platform_job_status_history`,
`platform_job_results`, `platform_job_approvals`, `platform_report_versions`,
`platform_public_links`, `platform_report_documents` and `platform_notifications`.

Jobs keep a single lifecycle `status` (`DRAFT`, `SCHEDULED`, `ASSIGNED`, `IN_PROGRESS`, `PENDING_REVIEW`, `APPROVED`, `PUBLISHED`, `REJECTED`, `CANCELLED`) plus additive `review_status` and `publication_status`, so the approved workflow is explicit without losing the previous additive model (D-002).

**Consequences:**
- New Workshop Admin APIs read/write only the clean tables above and published Platform Admin configuration (`platform_templates`, `platform_template_versions`, `platform_template_items`, `platform_scoring_rules`, `platform_grade_boundaries`, `platform_document_types`).
- Legacy job endpoints remain available for the reference app under `/api/v1/workshop/legacy/jobs`. They are not used by the new Workshop Admin flows.
- Legacy report/delivery routes under `/api/v1/workshop/jobs/{jobId}/report` and `/deliveries` are unchanged.
- Customer/vehicle PII in `platform_jobs` is encrypted at rest with the existing `PiiCipher`.

## D-059 â€” Phase 2 template-version routes are namespaced to avoid legacy collisions

**Date:** 2026-11-12
**Status:** Accepted

**Context:** The legacy Workshop template controller owns `/api/v1/workshop/templates/{id}`. The Phase 2 job wizard needs to fetch a pinned Platform template version by its version id.

**Decision:** Phase 2 template selection uses:
- `GET /api/v1/workshop/template-versions/available`
- `GET /api/v1/workshop/template-versions/{versionId}`

**Consequences:**
- The legacy template routes and their tests remain unchanged.
- Jobs pin the returned `versionId` at creation.
- The Flutter `ApiEndpoints` and Workshop Admin models use the namespaced routes.

## D-060 â€” Approval score, grade and safety cap are server-computed

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Workshop Admin never submits a score or grade. The server computes a weighted score from `platform_job_results`, resolves the grade from the active Platform scoring rule's approved boundaries, and applies the configuration's hard-fail safety cap. A safety-critical `DEFECT_FOUND` requires a written safety-cap explanation.

**Consequences:**
- `POST /jobs/{id}/approve` rejects incomplete checklists with `APPROVAL_CHECKLIST_INCOMPLETE`.
- Evidence defaults are enforced even if configuration is weaker: every result needs at least 1 photo and 1 video; `DEFECT_FOUND` needs at least 2 photos and 1 video.
- The approver must be a Workshop Admin and must not be the assigned technician (`APPROVER_IS_TECHNICIAN`).
- Rejection sets `REJECTED` and closes the job. There is no correction/return flow.

## D-061 â€” EN/AR documents are generated immediately after publish and retried through the outbox

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Publishing creates the public token and QR, records report-version artifacts, and generates separate EN and AR PDF rows for every active document type. Generation is attempted immediately; failures are stored as `FAILED`, emit outbox events, and can be retried with `POST /jobs/{id}/documents/{type}/retry`. Documents are never a pre-publish gate (D-024).

**Consequences:**
- `platform_report_documents` stores `language`, storage key, mime, bytes, status, timestamp and error.
- Phase 2 emits dependency-free PDF artifacts linked to the published report version; richer report rendering belongs to the Public Report phase.
- The public link token is stored hashed for lookup and encrypted for authorised re-display of the link and QR.

## D-062 â€” Flutter web apps use path URLs and require an index.html rewrite

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Platform Admin and Workshop Admin web builds call `usePathUrlStrategy()` before `runApp`. Deployment must rewrite unknown paths to `index.html`; see `docs/WEB_URL_STRATEGY.md` for Nginx, Firebase Hosting, Netlify and Apache examples.

**Consequences:**
- `/#/workshops` becomes `/workshops`; `/#/workshop` becomes `/workshop`.
- Without the server rewrite, deep links and refreshes return 404.
- Technician app adoption is deferred to its own phase.

## D-063 â€” No phase-based naming in production code

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Do not use phase numbers in production class names, file names, package names, API paths, DB tables, or ARB keys.

**Consequences:**
- Phase 2 artifacts must be renamed to domain names before Phase 3:
  - `features/phase2/` â†’ `features/jobs/`
  - `phase2_models.dart` â†’ `workshop_job_models.dart`
  - `phase2_providers.dart` â†’ `workshop_job_providers.dart`
  - `WorkshopAdminPhase2Service` â†’ `WorkshopJobAdminService`
  - `WorkshopAdminPhase2Controller` â†’ `WorkshopJobAdminController`
  - `WorkshopPhase2Dtos` â†’ `WorkshopJobDtos`
  - `WorkshopAdminPhase2IT` â†’ `WorkshopJobAdminIT`
  - `phase2...` ARB keys â†’ semantic keys
- No production code, API path, DB table, or ARB key may contain `phase2`.
- See `docs/NAMING_AND_TESTING_RULES.md`.

## D-064 â€” Fake APIs are test doubles only

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Fake API clients exist only under `test/support/` to make widget/unit tests fast and deterministic. They are not production dependencies and must never be imported from `lib/`.

**Consequences:**
- Production screens use the real API client and backend.
- Unit tests use pure logic; widget tests use fakes; integration tests use the real backend.
- A missing backend endpoint is implemented, not mocked in production.

## D-065 â€” Agentic sub-sessions require contract-first ownership

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Use parallel agentic sub-sessions for large phases, with a contract-first workflow, clear file ownership, and a single integrator/verifier.

**Consequences:**
- Split work into discovery, backend, frontend data, frontend UI, and integration/verification.
- One file has one owner at a time.
- Agree DTOs/endpoints before parallel implementation.
- Only the integrator runs final verification and claims completion.
- See `docs/NAMING_AND_TESTING_RULES.md`.

## D-066 - Category retire is blocked while it still has items

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** `POST /api/v1/platform/master/categories/{id}/retire` returns
`409 CATEGORY_IN_USE` while `platform_items` still reference the category.
Platform Admin must retire or move the items first.

**Consequences:**
- UI retire confirmation surfaces the structured error.
- Retirement is a soft state change (`status = RETIRED`), never a delete.
- Category weight totals may be temporarily non-100 while configuration is
  being assembled; `GET /categories/weight-check` reports the invalid total
  and the UI blocks nothing until the operator completes the weights.

## D-067 - Platform Admin UI end-to-end verification uses a live Flutter test

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** The end-to-end proof for Platform Admin is
`client/apps/platform_admin_app/test/e2e/platform_admin_live_e2e_test.dart`.
It is skipped unless `LIVE_E2E=1`, uses `LiveTestWidgetsFlutterBinding` with
real HTTP/MySQL, drives the real screens (seed, category, option set, item,
bands, evidence rules, issue fields, publish, template, weight preview,
publish and maker-checker approval), and writes screenshots plus API data to
`docs/evidence/platform_admin/`.

**Consequences:**
- Fake-backed widget tests remain the fast CI layer; the live test is the
  acceptance evidence layer.
- The live test requires a running backend on `http://localhost:8080` with
  `platform@truereport.test` and a second platform admin
  (`admin.b@truereport.test` promoted to platform admin in the dev DB).
- `flutter analyze --fatal-infos` includes the test file, so it stays clean.

## D-068 - Release lifecycle is governed from the Config Health screen

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Config releases are created and transitioned from the same
Config Health console (`DRAFT -> REVIEW -> APPROVED -> PUBLISHED ->
DEPRECATED`) using the existing release endpoints. No separate release screen
is introduced.

**Consequences:**
- Operators see health, impact and release state in one place.
- Transitions persist in `platform_releases` and are audited.

## D-069 - Dialog controllers are disposed after the route transition

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Screens that create `TextEditingController`s for inline dialogs
(categories, option sets/values) defer `dispose()` until the dialog route's
exit animation has completed.

**Consequences:**
- Avoids `TextEditingController used after being disposed` during route
  finalization.
- The live end-to-end test exercises these dialogs and guards the fix.
## D-070 - No production demo authentication

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Production login screens must never create a fake authenticated
session. Authentication failures show an error and remain on the login page.
Demo quick-fill, demo session creation and the “Explore Platform Admin (Demo)”
bypass were removed from Platform Admin and Workshop Admin.

**Consequences:**
- `setDemoSession` no longer exists in the production auth package.
- `AdminSignInView` has no demo fill control.
- Fakes remain test-only under `test/support/`.
- The live E2E test reads credentials from `LIVE_E2E_EMAIL` and
  `LIVE_E2E_PASSWORD`; it fails clearly if they are missing.

## D-071 — Remove weighting/scoring configuration from Platform Admin

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Platform Admin configures **categories and checklist items only**. It does not configure category weights, item weights, scoring rules, grade boundaries, weight previews, or item score bands.

Scoring is derived dynamically after the template is built:

```text
includedCategories = categories with at least one included item
categoryWeight     = 100 / includedCategories
itemWeight         = categoryWeight / includedItemsInCategory

categoryScore = sum(itemScore * itemWeight)
overallScore  = sum(categoryScore * categoryWeight)
```

All categories are equal; all items inside a category are equal. The PASS/ATTENTION/FAIL to numeric score mapping is decided in the Workshop Admin phase, not Platform Admin.

**Consequences:**
- Remove category/item weight fields, weight validation, weight preview, scoring rules, grade boundaries, and scoring screens/routes/nav from Platform Admin.
- Remove or stop using `platform_categories.weight_percentage`, `platform_template_categories.weight_override`, `platform_template_items.item_weight`, `platform_score_bands`, `platform_scoring_rules`, and `platform_grade_boundaries`.
- Templates are category-first: ordered categories, each containing ordered checklist items.
- Template items store `category_id`, `item_version_id`, `sort_order`, and `included`; no item weight.
- The default `TPL-30-GCC` seed groups 6 categories and 30 items with no weights/scores.
- Public score/grade remain part of the final report, but are computed later from the template structure and item results.
- Supersedes the weight/scoring-configuration portions of D-027 and D-042. D-001 (score/grade as primary report result) still applies.
## D-071 - Templates are category-first

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** A global template version owns an ordered list of categories, and
each category owns its ordered checklist items. A template may include a subset
of master categories and a subset of items inside each category. Categories with
zero included items are excluded.

**Consequences:**
- `platform_template_categories` stores ordered categories per template version.
- `platform_template_items` stores `category_id`; the server validates that it
  matches the item version's master category.
- `GET /api/v1/platform/master/templates/{id}` returns `categories[]`, each with
  its nested `items[]`.
- `PUT .../versions/{versionId}/categories` and `PUT .../items` replace the
  ordered structure for a draft version.
- Published template versions remain immutable.
- No duplicate categories or item versions are allowed in one template version.

## D-072 - Platform Admin does not configure scoring or weights

**Date:** 2026-11-12
**Status:** Accepted

**Decision:** Platform Admin does not configure category weights, item weights,
score bands, scoring rules, grade boundaries, or weight previews. Those surfaces
were removed from the Platform Admin API, UI, seed and tests.

**Consequences:**
- Category create/update no longer accepts a weight.
- Item configuration no longer exposes score bands or default scores.
- The scoring and grade-boundary endpoints and the template weight-preview
  endpoint are removed.
- Legacy scoring/weight tables/columns are retained only for the later
  Workshop/Public phases; Platform Admin does not read or write them.
- Scoring becomes dynamic after the template is built. The documented contract:
  - `includedCategories` = categories with at least one included item
  - `categoryWeight` = `100 / includedCategories`
  - `itemWeight` = `categoryWeight / includedItemsInCategory`
  - `categoryScore` = sum(itemScore * itemWeight)
  - `overallScore` = sum(categoryScore * categoryWeight)
  - All categories are equal and all items inside a category are equal.
  - PASS/ATTENTION/FAIL numeric mapping is decided in the Workshop Admin phase.

## D-073 - Platform Admin navigation structure and configuration grouping

**Date:** 2026-11-12
**Status:** Accepted

**Decision:**
Redesign the Platform Admin sidebar to visually match the Figma source of truth (width ~260px clamped between 248–272px, white background with 1px right border, circular emerald brand icon with CoreOS title and Platform Admin subtitle, 40px nav items with 8px radius, canvas active state with emerald icon, and pinned bottom GRID V4.2 ONLINE status capsule).

Option A (Configuration group) is adopted for navigation structure:
1. The Figma 6 primary navigation items remain the contiguous primary group:
   - Workshops (`/workshops`)
   - Master Library (`/master-library`)
   - Data Catalogues (`/data-catalogues`)
   - Equipment (`/equipment`)
   - Settings (`/settings`)
   - Audit Log (`/audit-log`)
2. Supplementary configuration views are grouped under an explicit uppercase `CONFIGURATION` section separated by 20px spacing and a subtle section label:
   - Templates (`/templates`)
   - Document Types (`/document-types`)
   - Languages (`/languages`)
   - Config Health (`/config-health`)
3. A single shared navigation model (`PlatformNavData` / `PlatformNavEntry`) and shared navigation item component (`PlatformNavItem`) are used by both the desktop sidebar and the compact mobile navigation sheet, ensuring complete behavioral and visual parity between desktop and compact viewports without duplicated nav definitions.

## D-074 — Platform Admin UX v2 and dynamic language architecture

**Date:** 2026-11-12
**Status:** Accepted
**Supersedes:** D-073 navigation structure (the visual sidebar redesign remains).

**Decision:**

1. **Remove hierarchy entirely.**
   - Delete hierarchy tree/split-board screens, routes, widgets, and tests.
   - Replace with a real Dashboard + Workshops CRUD.

2. **Primary navigation becomes 6 items:**
   - Dashboard
   - Workshops
   - Checklist
   - Reports
   - Audit Log
   - Settings

3. **Workshops** gets:
   - list/table/cards with search, filters, add/edit/deactivate
   - workshop detail with Overview, Staff, Templates, Activity tabs
   - no hierarchy tree.

4. **Checklist** is one section with tabs:
   - Categories
   - Items
   - Templates
   - Issue Options
   - Health

5. **Items UX:**
   - checklist rows/cards with code, labels, category badge, unit, safety, evidence summary, status, actions
   - category filter is a searchable dropdown/combobox, never a wall of 30–40 chips
   - Add Item is a full-screen guided stepper, not a giant dialog.

6. **Templates:**
   - full-screen guided builder, not a dialog
   - category-first nested items
   - inline explanation of what a template is
   - no weights/scoring.

7. **Issue Options:**
   - master-detail layout, add set/value screens/drawers, search, counts, retire-in-use.

8. **Remove Equipment and Data Catalogues from Platform Admin nav/UI.**
   - Equipment is unnecessary after D-046.
   - Any still-needed option values live under Checklist → Issue Options.

9. **Remove the “Load default” button from the main Checklist UI.**
   - Seeding stays in migrations/CLI or an advanced Settings/Dev area.

10. **Dynamic language architecture:**
    - The language registry drives available content languages.
    - Content is stored as translations keyed by language code.
    - APIs return a `translations` map plus a resolved `label`/`labelLocale`/`fallbackLocale`.
    - Flutter models and forms must not hardcode EN/AR fields.
    - Content forms render one tab/field per active language.
    - Adding `zh-Hans` later must require only:
      1. Platform Admin adds the language,
      2. Admin fills Chinese translations,
      3. publish — no code changes.
    - Publish validation requires the default language plus platform-required languages; other active languages fall back.
    - Coverage dashboard computes missing translations for all active languages.

11. **No scoring/weight/defaultScore UI or client fields in Platform Admin.**
    - Remove hidden `defaultScore` from the frontend model/requests and unused ARB keys.
    - Backend-only compatibility fields must not be exposed or sent by Platform Admin.

**Consequences:**
- Old routes (`/master-library*`, `/templates*`, `/config-health`, `/document-types`, `/languages`, `/data-catalogues`, `/equipment`) redirect to the new structure.
- New translation CRUD endpoints and a translations map are required for categories, items, options, templates, document types, and issue fields.
- Existing EN/AR columns may remain as compatibility/backfill but must not be the only content model in the UI/API.
- The sidebar/header visual design stays; only the IA and content UX change.

## D-075 — Language activation gate and Dashboard/Workshops separation

**Date:** 2026-11-12
**Status:** Accepted
**Refines:** D-074.

**Decision:**

### Language lifecycle

A language is not live just because it was added to the registry.

```text
DRAFT → TRANSLATING → REVIEW → LIVE → RETIRED
```

- `DRAFT`: exists in Platform Admin only; hidden from Technician/Workshop/public.
- `TRANSLATING`: backlog exists for live content; translations are being filled.
- `REVIEW`: translations complete; waiting for approval/publish.
- `LIVE`: selectable in all apps; dynamic labels shown everywhere.
- `RETIRED`: hidden from new selections; existing snapshots keep their text.

### Adding a future language (e.g. zh-Hans)

1. Platform Admin adds the language as `DRAFT`.
2. System creates a translation backlog for all **live** content:
   - categories
   - checklist items
   - option sets/values
   - published templates (including existing live templates)
   - document types
   - issue field labels/help text
   - grade/report labels where applicable
3. Admin fills translations for those existing entities via language tabs.
4. Coverage dashboard shows missing translations by entity type.
5. Admin reviews/approves.
6. Admin publishes/activates the language; validation requires required live content coverage.
7. Status becomes `LIVE`; language appears in Technician/Workshop/public selectors and dynamic labels.
8. No code changes or app update are required.

- Draft/retired content does not block language activation.
- User-facing APIs return only `LIVE` languages; admin APIs return all languages with translation status.
- Existing jobs/published reports keep their original snapshot text. New jobs snapshot the new language.
- Adding a language to a published template changes translations only, not structure or existing snapshots.

### Dashboard vs Workshops

- Dashboard and Workshops are separate top-level tabs.
- Dashboard is read-only analytics/KPIs/alerts/activity/quick links. No workshop CRUD tables/forms.
- Workshops is operational CRUD: list, search/filter, add/edit/deactivate, workshop detail tabs (Overview, Staff, Templates, Activity). No dashboard KPI/chart cards.

### UX overhaul

- Remove hierarchy entirely.
- Checklist Items must render as checklist rows/cards, not plain text.
- Category filters use a searchable dropdown, never a wall of 30–40 chips.
- Add Item is a full-screen guided stepper.
- Template creation is a full-screen guided builder, category-first.
- Issue Options uses a master-detail layout with proper add/edit UX.
- Remove the “Load default” button from the main Checklist UI.

**Consequences:**
- Language activation/publish endpoints and translation backlog/coverage endpoints are required.
- Language translation status must be tracked per entity/locale.
- Technician/Workshop/public must never show non-LIVE languages.
- Existing reports remain immutable; snapshots include only languages live at publish time.
- A dedicated Translation Queue screen is required at `/settings/languages/{code}/translations`; it lists all missing translations grouped by entity type and allows inline completion without visiting each content editor.
- Publishing new live content must include translations for all LIVE languages; missing translations block publish and appear in the queue.

## D-076 — Backend-driven Platform Admin UI text + CORS preflight

**Date:** 2026-11-12
**Status:** Accepted

**Decision:**

### Backend-driven UI text

- Backend is the source of truth for all Platform Admin static UI text.
- Add a `platform_ui_messages` catalog (or equivalent) keyed by `namespace + message_key + language_code`, with translation status.
- Seed the catalog from the existing Platform Admin EN/AR ARB files once, then stop using ARB for Platform Admin text.
- Flutter loads the bundle from the backend, caches it locally, and renders text through a remote strings controller.
- Platform Admin must have zero `AppLocalizations` / `l10n.*` references after migration.
- UI messages are part of language activation coverage; the Translation Queue must include a `UI Messages` entity type.
- Adding a new language must require only backend translations, no Flutter code change or redeploy.
- Keep Flutter built-in localizations for date/time widgets and text direction.
- Workshop Admin, Technician, and Public Report static text are migrated in their own phases.

### CORS preflight

- `X-Request-Id` is not CORS-safelisted, so a preflight is expected. Do not remove the header.
- Ensure the server correctly handles `OPTIONS` preflight with the configured allowed headers/methods.
- Add integration tests for preflight on public and authenticated paths.
- The Dio warning is informational; acceptance requires verified preflight behavior, not suppressing the warning.

**Consequences:**
- New/updated endpoints for UI message bundles, CRUD, coverage, and bulk operations.
- Language publish validation includes UI message completeness.
- CI checks: no ARB usage in Platform Admin, code keys exist in the catalog, EN/AR parity.
- Startup must handle bundle loading/caching/retry before login.
- CORS tests are mandatory for `X-Request-Id`, `Accept-Language`, `Authorization`, `Idempotency-Key`, and `If-Match`.
