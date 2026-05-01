#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/opt/project-max}"
DAYS="${1:-30}"

cd "$PROJECT_ROOT"

npm run prune:queue -- "$DAYS"
