# Phase 8 - Security Hardening, Production Readiness and Pilot Preparation

**Status:** Implementation and evidence are complete for the items listed. Real-customer pilot is **NO-GO** until the open gates are closed.

| Document | Purpose |
|---|---|
| [00-decisions.md](00-decisions.md) | Phase 8 decisions, D6/PII/2FA/retention/production guard |
| [risk-register-consolidated.md](risk-register-consolidated.md) | Single unique-ID risk register + legacy ID mapping |
| [security-review.md](security-review.md) | ASVS L2/API Top 10 review, findings, fixes, gaps |
| [openapi-endpoints.md](openapi-endpoints.md) | 99-operation inventory generated from `/v3/api-docs` |
| [ops-runbook.md](ops-runbook.md) | Deploy, rollback, migration, backup/restore, rotation, on-call placeholders |
| [production-readiness.md](production-readiness.md) | Compose/Nginx/guard/monitoring/backup controls and RPO/RTO assumptions |\n| [server-deployment.md](server-deployment.md) | Self-hosted filesystem, one-domain DNS/TLS/firewall and server hardening |
| [incident-response.md](incident-response.md) | Exposure, wrong link, compromised account, provider/DB incidents |
| [pilot-plan.md](pilot-plan.md) | Scope, metrics, hard gates, rollback, go/no-go |
| [real-device-test-plan.md](real-device-test-plan.md) | Android/iPhone/offline/camera/RTL/PDF checklist; all NOT RUN |
| [accessibility-review.md](accessibility-review.md) | Axe result and WCAG 2.2 AA manual gaps |
| [data-protection-worksheet.md](data-protection-worksheet.md) | Counsel worksheet; no legal conclusions |
| [test-report.md](test-report.md) | Baseline, final tests, scans, restore and load results |
| [version-lock-update.md](version-lock-update.md) | New dependency/image pins and licences |\n| ADR-0020 | Self-hosted filesystem storage supersedes cloud storage |\n| ADR-0021 | Admin TOTP configurable and off by default |
