#!/usr/bin/env bash
set -euo pipefail
: "${BACKUP_PASSPHRASE:?set BACKUP_PASSPHRASE}"
: "${MYSQL_ROOT_PASSWORD:?set MYSQL_ROOT_PASSWORD}"
: "${BACKUP_FILE:?set BACKUP_FILE}"
: "${TARGET_CONTAINER:?set TARGET_CONTAINER}"
: "${TARGET_STORAGE_DIR:?set TARGET_STORAGE_DIR}"
DB_NAME="${DB_NAME:-truereport}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

openssl enc -d -aes-256-cbc -pbkdf2 -salt -pass env:BACKUP_PASSPHRASE \
  -in "$BACKUP_FILE" -out "$WORK/bundle.tar.gz"
tar -xzf "$WORK/bundle.tar.gz" -C "$WORK"
test -f "$WORK/database.sql"
test -f "$WORK/storage.tar"

docker exec -i -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$TARGET_CONTAINER" \
  mysql -uroot "$DB_NAME" < "$WORK/database.sql"
mkdir -p "$TARGET_STORAGE_DIR"
tar -xf "$WORK/storage.tar" -C "$TARGET_STORAGE_DIR"
echo "Restore completed: database=$TARGET_CONTAINER storage=$TARGET_STORAGE_DIR"
