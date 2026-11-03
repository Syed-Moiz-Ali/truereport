# Phase 3 — Platform Admin Hierarchy and Master Content

**Status:** Delivered for review. Phase 4 has not started.

## Scope delivered

- Platform Admin workshop/staff hierarchy: search, active/disabled/pending filters, expandable workshop tree, account invite/create/disable/reactivate/transfer, audit events.
- Server-side Platform Admin authorization; Technician and Workshop Admin are denied Platform Admin endpoints.
- Master content: categories, versioned inspection items, EN/AR (+ optional RU/ZH-Hans) translations, result options, severity policy, applicability, note/evidence rules, equipment, reasons, dropdowns, guide images with alt text.
- Immutable published item versions; new drafts; retire without deletion; old versions readable.
- Guide images are a separate type from evidence and use the `ObjectStorage` interface; local filesystem implementation only for development/tests.
- Sample data is not seeded as final checklist content. The UI/API exposes a `sampleData` marker; any placeholder content must be labelled and requires automotive-specialist validation.
- Admin Flutter screens for hierarchy, master content, item editing, guide images and audit, in English and Arabic RTL.

## Not in Phase 3

No workshop templates, technician inspection, PDF/public report content, delivery, correction UI/API, manager/review queue, customer app/portal or payments.

## Documents

- `00-decisions.md`
- `test-report.md`
- `risk-register-update.md`
- `../phase-1/13-adrs/0014-master-content-versioning.md`
- `../phase-1/13-adrs/0015-guide-images-and-local-storage.md`
