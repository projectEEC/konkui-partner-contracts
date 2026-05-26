#!/usr/bin/env bash
# GET /api/advisors/{externalUserId}/students
# Requires: SC_BASE_URL, API_SECRET
set -euo pipefail

EXT_USER_ID="${1:-T67001}"
ACADEMIC_YEAR="${2:-}"
: "${SC_BASE_URL:?set SC_BASE_URL}"
: "${API_SECRET:?set API_SECRET}"

QS="page=1&size=50"
if [[ -n "${ACADEMIC_YEAR}" ]]; then
  QS="${QS}&academicYear=${ACADEMIC_YEAR}"
fi

curl -sS \
  -H "X-Api-Secret: ${API_SECRET}" \
  -H "Accept: application/json" \
  "${SC_BASE_URL}/api/advisors/${EXT_USER_ID}/students?${QS}" \
  | jq .
