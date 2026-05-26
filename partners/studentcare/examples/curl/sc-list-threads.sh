#!/usr/bin/env bash
# GET /api/chat/threads?stdNo=...
# Requires: SC_BASE_URL, API_SECRET
set -euo pipefail

STD_NO="${1:-67100001}"
: "${SC_BASE_URL:?set SC_BASE_URL}"
: "${API_SECRET:?set API_SECRET}"

curl -sS \
  -H "X-Api-Secret: ${API_SECRET}" \
  -H "Accept: application/json" \
  "${SC_BASE_URL}/api/chat/threads?stdNo=${STD_NO}&page=1&size=20" \
  | jq .
