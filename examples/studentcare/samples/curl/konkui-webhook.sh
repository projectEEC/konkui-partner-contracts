#!/usr/bin/env bash
# POST /webhooks/studentcare/webhook — SC → konkui, signed with WebhookSecret
# Requires: KONKUI_BASE_URL, WEBHOOK_SECRET
set -euo pipefail

PAYLOAD_FILE="${1:-$(dirname "$0")/../payloads/webhook-envelope-text.json}"
: "${KONKUI_BASE_URL:?set KONKUI_BASE_URL}"
: "${WEBHOOK_SECRET:?set WEBHOOK_SECRET}"

if [[ ! -f "${PAYLOAD_FILE}" ]]; then
  echo "payload file not found: ${PAYLOAD_FILE}" >&2
  exit 1
fi

BODY=$(cat "${PAYLOAD_FILE}")
TS=$(date +%s)
CANONICAL="${TS}.${BODY}"
SIG=$(printf '%s' "${CANONICAL}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" -hex | awk '{print $NF}')

curl -sS \
  -H "Content-Type: application/json" \
  -H "X-Timestamp: ${TS}" \
  -H "X-Signature: ${SIG}" \
  -d "${BODY}" \
  "${KONKUI_BASE_URL}/webhooks/studentcare/webhook" \
  | jq .
