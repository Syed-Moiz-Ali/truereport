# Phase 8 Version and Licence Additions

**Date:** 4 November 2026  
**Status:** Additions for Phase 8. Re-verify at deployment.

| Item | Version | Licence / note | Use |
|---|---|---|---|
| AWS SDK for Java v2 S3 | **2.57.8** | Apache-2.0 | Optional S3 adapter; **unused/disabled** after Phase 8.1 |
| Micrometer Prometheus registry | Boot-managed | Apache-2.0 | Metrics |
| SeaweedFS | **4.52** | Apache-2.0 (official LICENSE) | Optional local S3 test only; not used by production |\n| Self-hosted filesystem | JDK NIO | No new dependency | Production D6 storage |
| Nginx | **1.31.8-alpine3.24** | BSD-2-Clause | Production reverse proxy example |
| Prometheus | **v3.15.1** | Apache-2.0 | Monitoring example |
| Grafana | **13.2.5** | AGPL-3.0 | Local monitoring example only; review distribution/use terms |
| Gitleaks CLI | **v8.30.1** | MIT | Secret scan |

No cloud provider, KMS, email/WhatsApp/SMS provider or legal wording is selected by this table.
