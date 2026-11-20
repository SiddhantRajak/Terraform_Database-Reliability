#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$ROOT/backups}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
SOURCE_DB="${DB_NAME:-hotelbooking}"
RESTORE_DB="${RESTORE_DB:-hotelbooking_restore}"
export PGPASSWORD="${DB_PASSWORD:-postgres}"
if [[ $# -ge 1 ]]; then FILE="$1"; else
  FILE="$(ls -1t "$BACKUP_DIR"/${SOURCE_DB}_*.dump 2>/dev/null | head -n1 || true)"
fi
if [[ -z "${FILE:-}" || ! -f "$FILE" ]]; then
  echo "No backup found. Pass a dump path or run backup.sh first." >&2
  exit 1
fi
# Create a clean target database; terminate connections first if it already exists.
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 \
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${RESTORE_DB}' AND pid <> pg_backend_pid();" >/dev/null
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 \
  -c "DROP DATABASE IF EXISTS ${RESTORE_DB};" \
  -c "CREATE DATABASE ${RESTORE_DB};"
cat "$FILE" | docker exec -i hotel-postgres pg_restore -U "$DB_USER" -d "$RESTORE_DB" --no-owner --no-privileges
echo "Restored $FILE into $RESTORE_DB"
echo "Verify: psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $RESTORE_DB -c 'SELECT COUNT(*) FROM hotel_bookings;'"