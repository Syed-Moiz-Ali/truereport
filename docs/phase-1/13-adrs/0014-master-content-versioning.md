# ADR-0014: Master content versioning

- **Status:** Accepted for Phase 3
- **Date:** 3 November 2026
- **Owner:** Backend lead / product owner

## Context

Platform Admin owns shared inspection categories and items. Workshop Admins will later build templates from these items. A published edit must not silently change an existing template, inspection or report.

## Options

1. Edit master items in place and rely on templates to copy text. Rejected: old templates/reports could drift.
2. Version only the template. Rejected: the master wording itself still changes.
3. Version the master item and have templates reference immutable versions. Chosen.

## Decision

- `master_inspection_items` has a stable identity and a `current_published_version_id`.
- `master_item_versions` is append-only for published rows. A draft can be edited; publishing freezes it.
- Creating a new version copies the latest translations and rules into a new draft.
- Templates (Phase 4) must reference a `master_item_version_id`, never “the latest item”.
- Finalized reports will snapshot the exact item version text and rules (Phase 6).
- Retiring an item sets item status `RETIRED`; it never deletes versions and never changes old versions.
- The API has no endpoint that edits a published version.

## Consequences

- Content changes are additive versions.
- Storage grows with versions, which is acceptable.
- The Phase 4 template model must reference versions; the database design already expects this.
- Old versions must remain readable indefinitely for audit.

## Follow-ups

- Phase 4 must test that templates keep the exact version.
- Phase 6 must snapshot master wording in the report.
- Add database triggers/permissions for published version content if not already enforceable by service-only rules.

## What was not proven

No template/report model exists in Phase 3, so the cross-version effect is verified only at the master-version level. A DB trigger preventing direct published-version edits is not implemented; the service rejects edits and tests cover the API path.
