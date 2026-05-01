#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/opt/project-max}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"
cd "$PROJECT_ROOT"

npm run backup:db -- "$BACKUP_DIR/project-max-$STAMP.sqlite"
