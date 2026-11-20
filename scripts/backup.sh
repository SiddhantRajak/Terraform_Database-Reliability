#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$ROOT/backups}"
DB_NAME="${DB_NAME:-hotelbooking}"
DB_USER="${DB_USER:-postgres}"

mkdir -p "$BACKUP_DIR"

STAMP="$(date +%Y%m%d_%H%M%S)"
FILE="$BACKUP_DIR/${DB_NAME}_${STAMP}.dump"

docker exec hotel-postgres pg_dump \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -Fc > "$FILE"

echo "Backup created: $FILE"