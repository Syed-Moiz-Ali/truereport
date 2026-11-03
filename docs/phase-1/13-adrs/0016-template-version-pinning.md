# ADR 0016 — Template Version Pinning and Safety-Rule Locking

**Status:** Accepted for Phase 4  
**Date:** 3 November 2026  
**Related:** ADR-0009, ADR-0014, `docs/phase-1/05-master-library-and-templates.md`, `docs/phase-1/07-database-design.md`

---

## Context

A Workshop Admin selects and orders approved master inspection-item versions into a workshop template. The platform must ensure that:

- a later master edit or retirement cannot change a published template;
- a job keeps the template version it started with;
- a crafted API request cannot weaken a locked evidence, note, result or severity rule;
- old template versions remain readable.

## Decision

1. `template_items.master_item_version_id` is the only reference to master content. There is no “latest item” reference.
2. Saving a draft snapshots the pinned version’s labels, instructions, result options, severity policy, reasons, note/evidence rules, minimum photos, equipment and guide image into `template_items.effective_rules_json`.
3. Phase 4 permits **no workshop overrides**. The master content model has no exposed overridable allowlist, so all rules are locked. The server rejects any override map or override field with `422 TEMPLATE_WEAKENS_SAFETY_RULE`.
4. Publishing freezes the draft template version. Editing a published template requires a new draft; publishing it creates a new immutable version.
5. Jobs store `template_version_id` and are never migrated when a new template version is published.
6. MySQL-only Flyway triggers in `db/migration-mysql/V6__immutability_triggers.sql` block updates/deletes of published master/template versions and published template items. The H2 test profile loads common migrations only.
7. Service/API enforcement remains the primary control. The triggers are defence in depth and are **untested locally** because Docker/MySQL is unavailable.

## Consequences

- Old templates and jobs are stable across master updates and retirement.
- Workshop Admins can select, order and publish but cannot reinterpret master content.
- A future approved override model must add explicit master `overridable` metadata and a new ADR; the default remains “none”.
- MySQL trigger correctness must be proven in CI before production acceptance.

## What was not proven

- MySQL 8.4 trigger creation/execution.
- Real MySQL testcontainer run.
- Production direct-SQL grants and separation of duties.
