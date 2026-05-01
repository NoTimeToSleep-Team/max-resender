#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:3000}"

curl --fail --silent "$BASE_URL/health"
printf '\n'

curl --fail --silent "$BASE_URL/api/messages?limit=5"
printf '\n'

curl --fail --silent "$BASE_URL/api/push/config"
printf '\n'

if [[ -n "${ADMIN_API_TOKEN:-}" ]]; then
  curl --fail --silent -H "x-admin-token: ${ADMIN_API_TOKEN}" "$BASE_URL/api/admin/ops/summary"
  printf '\n'
fi
