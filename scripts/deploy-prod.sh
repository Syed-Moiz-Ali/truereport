#!/usr/bin/env bash
#
# Production deploy with a mandatory pre-deploy backup.
#
# 1. refuses a dirty working tree,
# 2. takes and verifies an encrypted backup (scripts/backup-mysql.sh),
# 3. builds/starts the pinned compose stack,
# 4. prints the health and smoke steps.
#
# Usage:
#   export BACKUP_PASSPHRASE='from-secret-manager'
#   ./scripts/deploy-prod.sh
#
# Use DAY-2 operations (no schema change) with the same script: the backup is
# cheap and the guard is intentional. Never pass a flag to skip it.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-$ROOT/infra/docker-compose.prod.yml}"
ENV_FILE="${ENV_FILE:-$ROOT/infra/prod.env}"

die() { echo "deploy-prod: $*" >&2; exit 1; }

[[ -f "$ENV_FILE" ]] || die "missing $ENV_FILE (copy infra/env/production.env.example)"
[[ -n "${BACKUP_PASSPHRASE:-}" ]] || die "set BACKUP_PASSPHRASE"
command -v docker >/dev/null 2>&1 || die "docker is required"

if [[ -d "$ROOT/.git" ]]; then
  if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
    die "working tree is dirty; commit or stash before deploying"
  fi
  GIT_SHA="$(git -C "$ROOT" rev-parse --short HEAD)"
  echo "deploy-prod: commit $GIT_SHA"
fi

echo "== 1/3 backup =="
BACKUP_RESULT="$("$ROOT/scripts/backup-mysql.sh")"
echo "$BACKUP_RESULT"
echo "$BACKUP_RESULT" | grep -q '^verify: ok' \
  || die "backup did not verify; refusing to deploy"

echo "== 2/3 deploy =="
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --build
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps

echo "== 3/3 verify =="
cat <<'EOF'
Now run the runbook checks (docs/phase-8/ops-runbook.md section 2):
  - /actuator/health through Nginx
  - login, one read-only job, one public report
  - report generation, delivery, webhook failures and 5xx for 30 minutes
  - record the image digest, Flyway version, change ticket and operator
EOF
