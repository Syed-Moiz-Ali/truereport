# TEST_PLAN.md — TrueReport Audit

## Platform Admin App (port 5301)
- [x] /signin
- [x] /dashboard
- [x] /workshops
- [x] /workshops/new
- [x] /workshops/details
- [x] /workshops/{id}
- [x] /checklist/items
- [x] /checklist/items/{id}/edit
- [x] /checklist/items/new
- [x] /checklist/categories
- [x] /checklist/option-sets
- [x] /checklist/health
- [x] /configuration
- [x] /configuration/statuses
- [x] /configuration/enums
- [x] /configuration/dropdowns
- [x] /configuration/transitions
- [x] /configuration/translations
- [x] /reports/document-types
- [x] /settings
- [x] /settings/languages
- [x] /settings/languages/{code}
- [x] /settings/languages/{code}/translations
- [x] /settings/languages/{code}/manual
- [x] /audit-log
- [x] /master-library/categories
- [x] /master-library/option-sets
- [x] /master-library/{id}/edit
- [x] /master-library/new
- [x] /data-catalogues
- [x] narrow viewport (768px) all routes
- [x] module flow: workshops + master library
- [x] module flow: language add/retire + manual translations
- [x] module flow: content review + option sets + item editor
- [x] module flow: 401 redirect
- [x] module flow: legacy taxonomy redirects
- [x] module flow: Spanish content invariants
- [x] module flow: manual translations edit/restore
- [x] visual: master library + option sets

## Workshop Admin App (port 5302)
- [x] /signin
- [x] shell sections @1280
- [x] mobile viewport @390
- [x] job queue + detail
- [x] job create wizard
- [x] job archive
- [x] staff roster
- [x] templates
- [x] reports + delivery
- [x] settings
- [x] language dynamic (es)
- [x] module flow: job visibility + consent
- [x] module flow: report + delivery surface
- [x] cross-app: job reaches technician
- [x] auth flow (sign in, wrong password, reload)

## Technician App (port 5303)
- [x] /signin
- [x] all routes @phone
- [x] tablet width
- [x] assigned job + checklist
- [x] queue scoping
- [x] vehicle photo gate
- [x] evidence capture
- [x] auth flow
- [x] cross-app job visibility

## Backend (port 8080)
- [x] actuator/health
- [x] /v3/api-docs
- [x] /swagger-ui
- [x] auth login/refresh/2fa/me
- [x] all controllers via API sweep (95 GETs, 0 5xx)
- [x] mvn test (350 tests)

## Public Report
- [x] unknown token -> neutral 404
- [ ] active report renders real data (skipped: no E2E_PUBLIC_REPORT_TOKEN)
- [ ] published snapshot language (skipped: no token/lang)
