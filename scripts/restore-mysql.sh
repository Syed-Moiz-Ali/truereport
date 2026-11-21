#!/usr/bin/env bash
#
# Restore an encrypted backup into a MySQL container.
#
# Intended for the restore drill (docs/phase-8/ops-runbook.md section 5) and
# for recovery into a FRESH container. It never restores in place silently:
# you must name the target container and set CONFIRM_RESTORE=yes.
#
# Usage:
#   export BACKUP_PASSPHRASE='from-secret-manager'
#   MYSQL_CONTAINER=truereport-drill-mysql CONFIRM_RESTORE=yes \
#     ./scripts/restore-mysql.sh infra/backups/truereport-20261122T000000Z.sql.enc
#
set -euo pipefail

FILE="${1:-}"
die() { echo "restore-mysql: $*" >&2; exit 1; }

[[ -n "$FILE" ]] || die "usage: restore-mysql.sh <backup.sql.enc>"
[[ -f "$FILE" ]] || die "missing backup: $FILE"
[[ -n "${BACKUP_PASSPHRASE:-}" ]] || die "set BACKUP_PASSPHRASE"
[[ "${CONFIRM_RESTORE:-}" == "yes" ]] || die "set CONFIRM_RESTORE=yes to acknowledge the target will be overwritten"
[[ -n "${MYSQL_CONTAINER:-}" ]] || die "set MYSQL_CONTAINER to the target container name"
command -v docker >/dev/null 2>&1 || die "docker is required"
command -v openssl >/dev/null 2>&1 || die "openssl is required"

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$@"
  else
    shasum -a 256 "$@"
  fi
}

CHECK="$FILE.sha256"
[[ -f "$CHECK" ]] || die "missing checksum sidecar: $CHECK"
(cd "$(dirname "$FILE")" && sha256 -c "$(basename "$CHECK")") \
  || die "checksum verification failed"

PLAIN="$(mktemp "${TMPDIR:-/tmp}/truereport-restore.XXXXXX.sql")"
cleanup() { rm -f "$PLAIN"; }
trap cleanup EXIT

echo "restore-mysql: decrypting"
openssl enc -d -aes-256-cbc -pbkdf2 \
  -pass env:BACKUP_PASSPHRASE -in "$FILE" -out "$PLAIN"
[[ -s "$PLAIN" ]] || die "decrypted dump is empty"
grep -q 'CREATE DATABASE' "$PLAIN" || die "dump does not contain CREATE DATABASE"

echo "restore-mysql: importing into $MYSQL_CONTAINER"
docker exec -i "$MYSQL_CONTAINER" sh -c \
  'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=utf8mb4' \
  <"$PLAIN"

echo "restore-mysql: done"
echo "Verify row counts and hashes per docs/phase-8/ops-runbook.md section 5 (restore drill)."
