# Questions asked (bounded to one batch)

Total questions: **1** (of a maximum 5 including Step 0 corrections).

## Q1 — Audit scope

- **Evidence:** 4 workspace apps (`platform_admin_app`, `workshop_admin_app`, `technician_app`, `ui_gallery`), a
  server-rendered public report, a Spring Boot backend in this repo, and no target supplied by the request.
- **Ambiguity:** audit every module vs a single module vs only the core flow.
- **Options:** all modules + executed vertical slice (recommended) · full CRUD for every module · core slice only ·
  one named module.
- **Answer:** **All modules, vertical slice executed** (user selection, 2026-11-20).
- **Consequences:** full matrix and gap sweep for all modules; browser execution focused on the core vertical slice;
  modules that cannot be automated are recorded UNVERIFIED with reasons; fixes prioritise the blockers that stop the
  slice.

## Step 0 corrections

None required. The only conflict found was documentation drift (README describes `admin_app` / "Phase 5A" while the
repo contains `workshop_admin_app`, `platform_admin_app` and later modules). Code was treated as authoritative and the
drift is recorded as MIN-06, not as a question.

## Not asked (answered by code)

- Customer app/portal: absent; public report is the only anonymous surface.
- `ui_gallery`: design gallery, no router/product data; excluded.
- Backend presence: in this repo; no UNKNOWN backend columns needed.
- Environment: the installed MySQL rejected the repo credentials, so the audit used a disposable MySQL 8.0 on port
  3307. This is a fixture detail, not a product decision.
