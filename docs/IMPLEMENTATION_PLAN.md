# TrueReport Implementation Plan

**Status:** Approved flow freeze — implementation gated until product owner says “start platform”.  
**Order:** Platform Admin → Workshop Admin → Technician → Public Report.  
**Backend:** full rebuild.  
**Frontend:** reuse existing UI/components; adapt data wiring and layout responsiveness only.

---

## 1. Non-Negotiable Rules

1. **Backend is rebuilt cleanly.** Do not keep layering fixes on the current clumsy backend. New package structure, new schema baseline, new services, new tests.
2. **Server is the source of truth** for validation, scoring, grading, snapshots, and public payloads.
3. **Frontend UI is not redesigned.** Existing screens, components, visual style, and Figma-based look are reused.
4. **Frontend layout is adaptive.** No fixed widths/heights for containers. Use constraints, flex, breakpoints, aspect ratios, and wrapping.
5. **Every user-facing text is EN/AR** with stored translations; no runtime machine translation.
6. **Snapshots are immutable** after finalize/publish.
7. **All writes are idempotent and optimistic-concurrency safe.**
8. **Role and workshop scoping is enforced server-side** and tested.
9. **No hardcoded categories/items/weights/bands/grades/options/report text.**
10. **No commits unless explicitly requested.**

---

## 2. Backend Rebuild Strategy

See `docs/BACKEND_REBUILD_PLAN.md`.

Summary:
- Clean modular monolith.
- New schema baseline; archive old schema for reference.
- New modules: `identity`, `tenancy`, `localization`, `masterdata`, `templates`, `jobs`, `inspections`, `evidence`, `scoring`, `reports`, `publicreport`, `documents`, `delivery`, `audit`, `shared`.
- Reuse proven libraries (Spring Boot, Flyway, Security, JPA/JDBC) but not the current tangled service code.
- One consistent error contract, idempotency, concurrency, audit, outbox, observability.
- Provide data migration for any real existing data.
- Document every breaking API change in `docs/MIGRATION.md`.

---

## 3. Frontend Reuse & Adaptive Rules

See `docs/FRONTEND_ADAPTIVE_RULES.md`.

## 3.1 Naming, Test Doubles, and Agentic Workflow

See `docs/NAMING_AND_TESTING_RULES.md`.

Key rules:
- No phase numbers in production code, API paths, DB tables, or ARB keys.
- Fake API clients live only under `test/support/`; production uses real APIs.
- Use agentic sub-sessions with contract-first DTOs, one owner per file, and a single integrator/verifier.

Summary:
- Keep existing screens/components/design system.
- Replace mocks/hardcoded data with API-backed providers.
- Adapt layouts to available space; no fixed container sizes.
- Use design tokens for spacing/typography/radii.
- Test phone/tablet/desktop, portrait/landscape, EN/AR/RTL.

---

## 4. Phase Overview

| Phase | Backend | Frontend | Exit criteria |
|---|---|---|---|
| **1. Platform Admin** | Clean foundation + language + master config + scoring + templates + health/impact + seed | Reuse Platform UI; wire APIs; add missing config screens; adaptive layout | 7th category/item/template/scoring/doc type can be created via UI; seed works; tests green |
| **2. Workshop Admin** | Jobs, assignment, review/approve/publish, documents, QR, consent, notifications | Reuse dashboard/jobs/reports; add approve/publish/docs/QR | Job created → technician assigned → approved → published with token/QR |
| **3. Technician** | Dynamic checklist, issue values, measurement bands, evidence photo/video/doc, score, signature, offline sync | Reuse inspection UI; dynamic tabs/forms; camera/video/signature/offline | Full inspection completed with evidence; server validates; finalize |
| **4. Public Report** | Public JSON API, snapshot payload, media, documents, verification, expiry, caching | Reuse HTML/CSS/JS; remove hardcoded content; states/RTL/a11y/print | Page renders entirely from API; no hardcoded content; EN/AR; 404/expired |

---

## 5. Phase 1 — Platform Admin

**Detailed plan:** `docs/phase-plans/01-PLATFORM_ADMIN.md`

Deliverables:
- New backend foundation and schema.
- Common language API and localized errors.
- Master categories/items/bands/evidence rules/issue fields/option sets.
- Global templates (versioned).
- Scoring rules, grade boundaries, safety caps.
- Report document types.
- Config release lifecycle, impact analysis, health dashboard.
- Seed 6 categories / 30 items / default template / 5 doc types / grades.
- Platform Admin Flutter screens wired to APIs.
- Tests + analyze.

---

## 6. Phase 2 — Workshop Admin

**Detailed plan:** `docs/phase-plans/02-WORKSHOP_ADMIN.md`

Deliverables:
- Customer/vehicle/job creation, list/filter, reassignment.
- Template selection and pinning.
- Review queue and approval checklist.
- Approve → scoring snapshot → publish → token/QR.
- Auto-generate EN/AR report documents after publish.
- Consent, publish/unpublish/revoke, notifications.
- Workshop Admin Flutter screens wired to APIs.
- Tests + analyze.

---

## 7. Phase 3 — Technician

**Detailed plan:** `docs/phase-plans/03-TECHNICIAN.md`

Deliverables:
- Technician job list/detail with full dynamic checklist.
- Dynamic issue form from Platform Admin configuration.
- Measurement input + unit + band-based status/score.
- Photo/video/document evidence with camera-only capture and quality gates.
- Multi-point items and worst-case derivation.
- Autosave, offline queue, conflict handling.
- Signature and complete → pending review.
- Technician Flutter screens wired to APIs.
- Tests + analyze.

---

## 8. Phase 4 — Public Report

**Detailed plan:** `docs/phase-plans/04-PUBLIC_REPORT.md`

Deliverables:
- `GET /public/reports/{token}` JSON.
- Snapshot-driven SSR/HTML and JS.
- All hardcoded report content removed.
- Findings/categories/photos/videos/documents from data.
- Verification hash, validity/expiry, QR verification.
- EN/AR/RTL, accessibility, print, PDF.
- 404/expired states, broken media fallback, rate limiting, caching.
- Tests: redaction, unpublished 404, EN/AR, no internal IDs.

---

## 9. Cross-Cutting Deliverables (each phase)

- Structured API errors with EN/AR.
- Idempotency and optimistic concurrency.
- Audit events.
- Outbox for async jobs.
- Observability metrics/logs/alerts.
- Migration and decision updates.
- Tests: unit, integration, role isolation, i18n parity.
- Frontend `flutter analyze` + tests.
- Backend `mvn test`.

---

## 10. Definition of Done (per phase)

1. Backend builds and tests pass.
2. Frontend analyzes clean and tests pass.
3. Role/tenant isolation tests pass.
4. EN/AR completeness checks pass.
5. No mock/hardcoded production data remains in that phase’s surface.
6. API changes documented in `docs/MIGRATION.md`.
7. Decisions documented in `docs/DECISIONS.md`.
8. Product owner reviews and approves before moving to the next phase.
