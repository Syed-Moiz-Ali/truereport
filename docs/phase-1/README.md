# Phase 1 — UX, Domain and Architecture

**Project:** TrueReport  
**Status:** Delivered for product-owner review. Phase 2 foundation and Phase 3 Platform Admin work have since been delivered; Phase 4 has not started.

## Read in this order

1. `00-decisions.md` — what is Approved vs Pending, with safe defaults.
2. `01-navigation-maps.md` — technician, admin, Platform Admin and public report maps.
3. `02-screen-inventory.md` — every screen and its states.
4. `03-localization-and-rtl-rules.md` — English/Arabic, RTL, mixed text, VINs, numerals, keyboard limits, Russian/Chinese entry.
5. `04-platform-admin-hierarchy.md` — tree, accounts, audit, privacy.
6. `05-master-library-and-templates.md` — versioning and the “cannot weaken safety” rule.
7. `06-public-report-design.md` — allowlist, consent gate, revoked/invalid states.
8. `07-database-design.md` — MySQL 8.4, tenancy, UUIDv7, snapshots, triggers, grants, indexes.
9. `08-api-design.md` — `/api/v1`, errors, idempotency, conflicts, permission matrix.
10. `09-offline-and-upload-design.md` — local-first sync, evidence upload, conflicts, receipt gate.
11. `10-design-system.md` — tokens, status/severity, accessibility.
12. `11-security-and-privacy-design.md` — threat model, controls, data protection.
13. `12-spike-results.md` — Arabic PDF, public report and object-storage evidence.
14. `13-adrs/` — decision records.
15. `14-risk-register-update.md` — updated scores and new risks.
16. `15-phase-2-plan.md` — foundation plan and acceptance criteria.
17. `16-master-v0.3-proposals.md` — proposed `master.md` changes; **master.md was not edited**.

## Spike artifacts

- `spikes/arabic-pdf/` — sample PDFs, text extracts, page PNGs, README.
- `spikes/public-report/` — SSR and Flutter variants, measurements, screenshots, README.
- `spikes/object-storage/` — desk research and shortlist, README.

## What is not here

- No Flutter or Java production project.
- No database migration.
- No API implementation.
- No correction feature.
- No customer app/portal.
- No payments.
- No claim of legal compliance or official inspection certification.
