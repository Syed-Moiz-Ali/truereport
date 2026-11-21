#!/usr/bin/env bash
#
# Encrypted logical backup of the production database.
#
# Runs mysqldump inside the MySQL container so credentials never reach the
# host shell history, encrypts the dump with AES-256-CBC/PBKDF2, and writes a
# SHA-256 sidecar. Fails loudly instead of leaving a partial or empty dump.
#
# Usage:
#   export BACKUP_PASSPHRASE='from-secret-manager'
#   ./scripts/backup-mysql.sh
#
# Environment overrides:
#   COMPOSE_FILE   default infra/docker-compose.prod.yml
#   ENV_FILE       default infra/prod.env
#   OUT_DIR        default ./backups
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-$ROOT/infra/docker-compose.prod.yml}"
ENV_FILE="${ENV_FILE:-$ROOT/infra/prod.env}"
OUT_DIR="${OUT_DIR:-$ROOT/infra/backups}"

die() { echo "backup-mysql: $*" >&2; exit 1; }

[[ -n "${BACKUP_PASSPHRASE:-}" ]] || die "set BACKUP_PASSPHRASE (store it separately from the dump)"
[[ -f "$COMPOSE_FILE" ]] || die "missing compose file: $COMPOSE_FILE"
[[ -f "$ENV_FILE" ]] || die "missing env file: $ENV_FILE (copy infra/env/production.env.example)"
command -v docker >/dev/null 2>&1 || die "docker is required"
command -v openssl >/dev/null 2>&1 || die "openssl is required"

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$@"
  else
    shasum -a 256 "$@"
  fi
}

mkdir -p "$OUT_DIR"

DB_NAME="$(grep -E '^DB_NAME=' "$ENV_FILE" | tail -1 | cut -d= -f2- | tr -d '"' || true)"
DB_NAME="${DB_NAME:-truereport}"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
PLAIN="$OUT_DIR/truereport-$STAMP.sql"
ENC="$PLAIN.enc"

cleanup() { rm -f "$PLAIN"; }
trap cleanup EXIT

echo "backup-mysql: dumping '$DB_NAME' from $COMPOSE_FILE"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mysql \
  sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" \
    --single-transaction --quick --routines --triggers --events \
    --default-character-set=utf8mb4 --databases "$MYSQL_DATABASE"' \
  >"$PLAIN"

[[ -s "$PLAIN" ]] || die "mysqldump produced an empty file"
grep -q 'CREATE TABLE' "$PLAIN" || die "dump contains no tables; refusing to store it"
grep -q 'CREATE DATABASE' "$PLAIN" || die "dump has no CREATE DATABASE statement"

echo "backup-mysql: encrypting"
openssl enc -aes-256-cbc -pbkdf2 -salt \
  -pass env:BACKUP_PASSPHRASE -in "$PLAIN" -out "$ENC"

(
  cd "$OUT_DIR"
  sha256 "$(basename "$ENC")" >"$(basename "$ENC").sha256"
  sha256 -c "$(basename "$ENC").sha256" >/dev/null
)

BYTES="$(wc -c <"$ENC" | tr -d ' ')"
echo "backup: $ENC"
echo "bytes: $BYTES"
echo "verify: ok ($(cat "$ENC.sha256"))"
echo "restore: see docs/phase-8/ops-runbook.md section 5 (decrypt with openssl enc -d, then import)"
