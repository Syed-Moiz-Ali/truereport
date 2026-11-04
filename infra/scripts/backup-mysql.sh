#!/usr/bin/env bash
set -euo pipefail
: "${BACKUP_PASSPHRASE:?set BACKUP_PASSPHRASE}"
: "${MYSQL_ROOT_PASSWORD:?set MYSQL_ROOT_PASSWORD}"
DB_NAME="${DB_NAME:-truereport}"
OUT_DIR="${BACKUP_DIR:-./backups}"
STORAGE_CONTAINER_PATH="${STORAGE_CONTAINER_PATH:-/app/.truereport-storage}"
mkdir -p "$OUT_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

docker compose exec -T -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql \
  mysqldump -uroot --single-transaction --routines --triggers --events \
  --set-gtid-purged=OFF "$DB_NAME" > "$WORK/database.sql"
MSYS_NO_PATHCONV=1 docker compose exec -T server tar -C "$STORAGE_CONTAINER_PATH" -cf - . > "$WORK/storage.tar"
cat > "$WORK/manifest.txt" <<EOF
project=truereport
created_at=$STAMP
database=$DB_NAME
storage_path=$STORAGE_CONTAINER_PATH
contains_pii=true
encrypted=true
EOF
tar -czf "$WORK/bundle.tar.gz" -C "$WORK" database.sql storage.tar manifest.txt
BUNDLE="$OUT_DIR/truereport-$STAMP.bundle.tar.gz.enc"
openssl enc -aes-256-cbc -pbkdf2 -salt -pass env:BACKUP_PASSPHRASE \
  -in "$WORK/bundle.tar.gz" -out "$BUNDLE"
sha256sum "$BUNDLE" > "$BUNDLE.sha256"
echo "Backup written: $BUNDLE"

if [ -n "${OFFSITE_COPY_COMMAND:-}" ]; then
  export BACKUP_FILE="$BUNDLE"
  export BACKUP_SHA256_FILE="$BUNDLE.sha256"
  export BACKUP_STAMP="$STAMP"
  sh -c "$OFFSITE_COPY_COMMAND"
  echo "Off-site copy command completed"
fi
