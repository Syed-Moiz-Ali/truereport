# Phase 2 — Project Foundation

**Status:** Delivered for review. Phase 3 has since been delivered; Phase 4 has not started.

## Documents

- `version-lock.md` — exact pinned versions, licences and unresolved licence concerns.
- `master-v0.3-changes.md` — exactly which approved decisions were applied to `master.md`.
- `test-report.md` — commands, results, skipped checks and CI negative-control proof.

## Code

- `server/` — Spring Boot 4.1.2 modular monolith, Java 25, MySQL 8.4/Flyway, JWT auth, refresh rotation, roles, tenancy, audit, OpenAPI, `/r/unavailable`.
- `client/` — Flutter 3.47.9 pub workspace with Melos 8.10.0, technician/admin apps, design system, ARB localization, Riverpod, go_router, flutter_animate/reduce-motion and sign-in/role-home shells.
- `infra/` — MySQL 8.4.13, MinIO (local only), Mailpit and server Compose.
- `.github/workflows/ci.yml` — Flutter analyze/test, Java tests, Testcontainers, Modulith/ArchUnit and gitleaks.

## Boundary

No Phase 3+ features: no checklist, template builder, master content, PDF, public report content, delivery, customer app/portal, manager/review queue, correction UI/API or payments.
