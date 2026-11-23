# PROJECT_MAP.md — TrueReport Audit

## Apps (Flutter, Melos workspace in client/)
- technician_app — technician inspection app (port 5303)
- workshop_admin_app — workshop admin (port 5302)
- platform_admin_app — platform admin (port 5301)
- ui_gallery — design gallery

## Shared packages
- core, design_system, l10n, api_client, reference_data, domain, auth, offline_sync

## Backend
- Spring Boot 4.1.2, Java 25, Maven, MySQL 8.4, Flyway, port 8080
- Controllers: Auth, PlatformHierarchy, Staff, Workshop, Platform, WorkshopJob, WorkshopJobAdmin, TechnicianInspection, WorkshopTemplate, WorkshopMaster, PlatformTemplate, PlatformMasterConfig, PlatformOptionSet, MasterContent, PlatformGovernance, PlatformDocumentType, Reference, I18n/PlatformLanguage/PlatformContentTranslation/PlatformOverview/PlatformWorkshop/TranslationGlossary, UiMessage, VehiclePhoto, PublicReport, WorkshopReport, Delivery*, PlatformSeed, DeliveryChannels/Webhook

## Routing
- Platform: /signin, /dashboard, /workshops*, /checklist/*, /configuration/*, /reports/document-types, /settings*, /audit-log, /master-library*, /data-catalogues
- Workshop: /signin, /workshop (shell), jobs, staff, templates, reports, settings
- Technician: /signin, /jobs (queue), inspection hub, checklist, evidence

## State management
- Riverpod providers; go_router navigation; semantics enabled for web.

## Data
- REST JSON; JWT bearer; tenant scoping server-side.

## Cross-app flows
- Workshop creates job -> technician sees assigned job.
- Technician finalizes -> workshop report/delivery.
- Platform manages master content -> workshops consume pinned versions.
