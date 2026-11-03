# Phase 4 — Workshop Admin and Templates

**Status:** Delivered for review. Phase 5A (technician online inspection/finalization) delivered; see `../phase-5/`.

## Scope delivered

- Workshop Admin job list, filters, create/schedule, technician assignment/reassignment and cancellation.
- Technician read-only job endpoint for assigned jobs and the technician's own walk-ins.
- Workshop staff list for the Workshop Admin's workshop.
- Workshop template list, builder, item picker, ordering, EN/AR preview, draft save, publish and version history.
- Template items pin `master_item_version_id` and snapshot labels, instructions and effective rules.
- Retired master items cannot be added to new templates but remain readable in old template versions.
- Cross-workshop access returns neutral 404.
- Every template and job action writes an audit event.
- 100+ item template test using placeholder sample items.

## Explicitly not in Phase 4

No technician inspection, finalization, reports, PDF/public content, delivery, correction UI/API, manager/review queue, customer app/portal or payments.

## Decisions

- Workshop Admin cannot invite/create accounts. Platform Admin creates all accounts per RQ3 (Phase 1 decision record). The staff screen is read-only.
- No template overrides are permitted in Phase 4. Only item inclusion and order are workshop-editable; all master rules are locked. The server rejects any override attempt.
- Workshop Admin job endpoints are WA-only. Platform Admin has no job/template oversight endpoint in this phase.
- Technician walk-in creation is not enabled because RQ12 requires a workshop policy that is not defined. WA-created walk-in jobs are supported.

## Documents

- `00-decisions.md`
- `test-report.md`
- `risk-register-update.md`
- `../phase-1/13-adrs/0016-template-version-pinning.md`
