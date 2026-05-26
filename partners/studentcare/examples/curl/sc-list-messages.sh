#!/usr/bin/env bash
# GET /api/chat/threads/{threadId}/messages?sinceMessageId=...
# Requires: SC_BASE_URL, API_SECRET
set -euo pipefail

THREAD_ID="${1:?usage: $0 <threadId> [sinceMessageId]}"
SINCE="${2:-}"
: "${SC_BASE_URL:?set SC_BASE_URL}"
: "${API_SECRET:?set API_SECRET}"

URL="${SC_BASE_URL}/api/chat/threads/${THREAD_ID}/messages"
if [[ -n "${SINCE}" ]]; then
  URL="${URL}?sinceMessageId=${SINCE}"
fi

curl -sS \
  -H "X-Api-Secret: ${API_SECRET}" \
  -H "Accept: application/json" \
  "${URL}" \
  | jq .
