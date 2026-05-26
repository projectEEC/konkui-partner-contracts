#!/usr/bin/env bash
# GET /api/chat/external/attachment/{attachmentId}
# Requires: SC_BASE_URL, API_SECRET
set -euo pipefail

ATTACH_ID="${1:?usage: $0 <attachmentId> [outfile]}"
OUTFILE="${2:-/tmp/sc-attachment-${ATTACH_ID}}"
: "${SC_BASE_URL:?set SC_BASE_URL}"
: "${API_SECRET:?set API_SECRET}"

curl -sS -D - -o "${OUTFILE}" \
  -H "X-Api-Secret: ${API_SECRET}" \
  "${SC_BASE_URL}/api/chat/external/attachment/${ATTACH_ID}"

echo
echo "Saved to: ${OUTFILE}"
file "${OUTFILE}" 2>/dev/null || true
