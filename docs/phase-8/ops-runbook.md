# Phase 8 Operations Runbook

**Project:** TrueReport  
**Status:** Draft for pilot preparation. Replace every placeholder before production.

---

## 1. Ownership and contacts

| Role | Placeholder | Responsibility |
|---|---|---|
| Incident commander | `NAME / PHONE / EMAIL` | Declares incident, coordinates |
| Backend on-call | `NAME / PHONE / EMAIL` | API, DB, storage, provider |
| Ops/DBA | `NAME / PHONE / EMAIL` | Host, MySQL, backups, certificates |
| Security | `NAME / PHONE / EMAIL` | Exposure assessment, containment |
| Product | `NAME / PHONE / EMAIL` | Customer/workshop communication |
| Legal | `NAME / EMAIL` | Notification decisions; C2 wording |
| Arabic reviewer | `NAME / EMAIL` | Native wording sign-off |
| Automotive specialist | `NAME / EMAIL` | Checklist validation |

No on-call rotation or paging provider is configured. This is an explicit pilot gate.

---

## 2. Deploy

1. Confirm change approval, rollback owner and maintenance window.
2. Verify `infra/prod.env` is supplied from the secret manager; never commit it.
3. Confirm TLS certificate/key are mounted at `infra/nginx/tls/`.
4. Pull/build the pinned server image and start:

```powershell
$env:Path='C:\Users\sanja\AppData\Local\Programs\DockerDesktop\resources\bin;'+$env:Path
docker compose -f infra/docker-compose.prod.yml up -d --build
docker compose -f infra/docker-compose.prod.yml ps
```

5. Check `/actuator/health` through Nginx, the public report, login and one read-only job.
6. Watch report failures, delivery dead letters, webhook failures, 5xx and DB health for 30 minutes.
7. Record image digest, Flyway version, change ticket and operator.

The server runs as non-root with a read-only root filesystem and writable `/tmp`/cache tmpfs.

---

## 3. Rollback

- **Application:** redeploy the previous pinned image digest, then re-run health/smoke checks.
- **Schema:** Flyway is forward-only. Do not delete migration history or run ad-hoc destructive SQL. If the new schema is incompatible, stop traffic and restore the pre-change backup into a fresh database, then repoint the old image.
- **Filesystem storage:** do not delete the storage volume during rollback; keep the previous volume snapshot/backup available.
- **Data:** never restore over the live database in place. Restore into a fresh container/database, verify hashes, then switch.

Rollback triggers: failed health, repeated report generation failure, data integrity mismatch, security exposure, provider outage that blocks pilot.

---

## 4. Migrations

```powershell
cd server
mvn -q -DskipTests package
```

Migrations run at server startup with `validate-on-migrate=true`. Verify:

```sql
SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank DESC;
```

Current head: **V17** (PII encryption columns/data, TOTP recovery, lockout). V16 drops/recreates the finalized-job and final-snapshot update triggers around the one-time encryption update. Do not rerun the data migration manually.

---

## 5. Backup and restore

### Backup

```bash
cd infra
export BACKUP_PASSPHRASE='from-secret-manager'
./scripts/backup-mysql.sh
```

The script writes an AES-256-CBC/PBKDF2 encrypted dump and SHA-256 checksum. Store the passphrase separately from the backup. Apply the approved C2 retention period.

Schedule it with a host cron/systemd timer, for example nightly at 02:00 UTC, and alert if the file/checksum is missing. The scheduler is **not configured** in this repository.

### Restore drill

1. Start a fresh MySQL container with the same image (`mysql:8.4.13`).
2. Decrypt and restore with `scripts/restore-mysql.sh` or the equivalent approved procedure.
3. Verify:
   - Flyway history at the expected version;
   - row counts for reports/report versions;
   - SHA-256 hashes of `report_versions.snapshot_hash` and `inspection_final_snapshots.snapshot_hash`;
   - a public report and PDF after repointing a test server.
4. Record RPO/RTO result and destroy the temporary restore container.

**Tested on 4 November 2026:** a 1,302,320-byte encrypted database+storage bundle was restored into a fresh `mysql:8.4.13` container and a fresh storage directory. Source and restore each had 5 report versions; report hashes matched; a sample normalized evidence file and a sample report PDF matched their stored SHA-256 hashes. Off-site copy and host/volume encryption remain pending. No RPO/RTO is approved.

---

## 6. Monitoring

- Prometheus config: `infra/monitoring/prometheus.yml`.
- Alert rules: `infra/monitoring/alerts.yml`.
- Dashboard/alerting stack: `infra/docker-compose.monitoring.yml`.
- Metrics endpoint: `/actuator/prometheus` (restricted by Nginx to private networks).
- Alerts cover report generation failures, delivery dead letters, webhook verification failures and scrape down.
- Local demo: `prometheus-demo.yml` scraped the dev server; target health `up`, `up{job="truereport"}=1`.
- Add alerts for auth failures, upload failures, DB/disk health and certificate expiry before pilot; these are **not implemented as live alerts**.
- Sentry/error reporting is **not configured**. If added, disable request bodies and scrub tokens/PII.

---

## 7. Key and secret rotation

| Secret | Rotation |
|---|---|
| JWT signing key | New key, short overlap only if dual verification is implemented; otherwise force re-login |
| PII data keys | Add `v2` to `APP_PII_KEYS`, set active ID, re-encrypt rows, keep `v1` decrypt-only |
| DB credentials | Rotate user password, restart server, verify connections |
| Storage volume/backup key | Rotate backup passphrase/key, retain old encrypted bundles until expiry |
| SMTP/provider secrets | Rotate in provider and secret file |
| TLS certificate | Renew before expiry, reload Nginx |

Key-ID support exists for PII; an automated re-encryption runner is **not implemented**.

---

## 8. Change log process

Every production change needs: ticket, risk assessment, migration/rollback plan, test evidence, image digest, approver, deploy time and post-deploy result. Security-sensitive changes (auth, PII, storage, public links, providers) need a second reviewer.

---

## 9. Pilot stop conditions

Stop the pilot if any occur:

- cross-workshop data exposure;
- public report exposes forbidden PII;
- finalized data changes through any path;
- PII encryption or key failure;
- backup restore fails;
- repeated report/delivery failure without a workaround;
- provider compromise or abusive link sending;
- legal/security instruction to stop.
