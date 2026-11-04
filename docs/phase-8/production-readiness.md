# Phase 8 Production Readiness Checklist

**Status:** Configuration exists; production deployment is **NOT RUN**. Provider, TLS, secrets and legal gates remain open.

---

## 1. Configuration files

| Concern | File |
|---|---|
| Production Compose | `infra/docker-compose.prod.yml` |
| Production environment template | `infra/env/production.env.example` |
| Nginx TLS/rate/header proxy | `infra/nginx/nginx.conf` |
| Server production profile | `server/src/main/resources/application-prod.yml` |
| Production startup guard | `server/src/main/java/com/truereport/shared/config/ProductionSafetyGuard.java` |
| Filesystem storage | `server/src/main/java/com/truereport/shared/storage/FileSystemObjectStorage.java` |
| Optional unused S3 adapter | `server/src/main/java/com/truereport/shared/storage/S3ObjectStorage.java` |
| Server deployment | `docs/phase-8/server-deployment.md` |
| Monitoring | `infra/monitoring/`, `infra/docker-compose.monitoring.yml` |
| Backup/restore | `infra/scripts/backup-mysql.sh`, `restore-mysql.sh` |
| Ops/incident | `docs/phase-8/ops-runbook.md`, `incident-response.md` |

---

## 2. Controls present

- Non-root server container (UID 10001).
- Read-only server root filesystem with writable `/tmp` and cache tmpfs.
- MySQL/server health checks; server `stop_grace_period: 30s`; Spring graceful shutdown.
- Nginx HTTP?HTTPS redirect, HSTS, CSP-adjacent headers, `server_tokens off`, request/body limits and rate-limit zones.
- Production profile disables Swagger/seed users; guard requires filesystem storage on a writable persistent volume outside web/static roots, and rejects local storage, fake delivery, disabled real recipients and exposed API docs.
- Secrets supplied by an env file from a secret manager; no secret is committed.\n- Admin TOTP is off by default (`ADMIN_TOTP_REQUIRED=false`), an owner-accepted residual risk; re-enable the flag before real customers if approved.
- Filesystem storage on a persistent volume, atomic writes, SHA-256 sidecars, path-traversal checks, quotas, free-space reserve, restrictive permissions. No storage static route.
- S3 adapter retained only as an optional, disabled, unused alternative.
- Prometheus endpoint and alert rules; local scrape demo passed.
- Encrypted MySQL backup script; plain and encrypted restore drill passed.
- Resource limits: MySQL 1 GB, server 2 GB/2 CPUs, Nginx 128 MB, Prometheus/Grafana 512 MB each.
- PDF worker is currently single-threaded; concurrency 1/2/4 memory is **not measured**.

---

## 3. RPO/RTO assumptions

| Item | Proposed assumption | Status |
|---|---|---|
| Database RPO | <= 24 hours with daily backups | Proposed, not approved |
| Database RTO | ? 4 hours including restore/verification | Proposed, not approved |
| Storage RPO | Daily encrypted database+storage bundle, off-site target required | Off-site target not configured |
| Storage RTO | Restore database+storage and verify hashes | Local drill PASS |
| Backup retention | C2 legal decision | Pending |
| Restore verification | Row counts, report/evidence/PDF SHA-256 comparisons | Database+storage PASS |

These are planning assumptions, not commitments. Counsel/ops must approve them.

---

## 4. Multi-instance blockers

- Public and delivery rate limits are in-memory; replicas do not share counters. Nginx edge limits help but are not per-account.
- Report generation and delivery workers are DB-polled and have no leader election or `SKIP LOCKED` queue; duplicate workers can contend, and Chromium memory per replica is unmeasured.
- Token-family revocations and lockout counters are DB-backed, but there is no shared cache/session store.
- Chromium/PDF concurrency and peak memory at 1/2/4 workers are unmeasured.

Run one server instance until these are addressed and measured.

---

## 5. Deployment gates

- D6 self-hosted storage volume, full-disk/volume encryption and off-site destination.
- TLS certificate/domain and DNS.
- Secret manager and key custody.
- D8 provider contracts/templates/sender IDs/email authentication.
- C2 legal wording/retention/DPIA.
- Independent penetration test.
- Dependency vulnerability scan completed.
- Monitoring/alerts/paging live.
- Encrypted database+storage restore tested; off-site and host/volume encryption pending.
- Real-device/native Arabic/specialist sign-off.

Until these close, production is **NO-GO**.
