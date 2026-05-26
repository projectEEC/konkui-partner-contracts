#!/usr/bin/env bash
# POST /webhook/chat/inbound — konkui → SC, signed with InboundSecret + X-Api-Secret
# Requires: SC_BASE_URL, API_SECRET, INBOUND_SECRET
set -euo pipefail

PAYLOAD_FILE="${1:-$(dirname "$0")/../payloads/inbound-request.json}"
: "${SC_BASE_URL:?set SC_BASE_URL}"
: "${API_SECRET:?set API_SECRET}"
: "${INBOUND_SECRET:?set INBOUND_SECRET}"

if [[ ! -f "${PAYLOAD_FILE}" ]]; then
  echo "payload file not found: ${PAYLOAD_FILE}" >&2
  exit 1
fi

BODY=$(cat "${PAYLOAD_FILE}")
TS=$(date +%s)
CANONICAL="${TS}.${BODY}"
SIG=$(printf '%s' "${CANONICAL}" | openssl dgst -sha256 -hmac "${INBOUND_SECRET}" -hex | awk '{print $NF}')

curl -sS \
  -H "Content-Type: application/json" \
  -H "X-Api-Secret: ${API_SECRET}" \
  -H "X-Timestamp: ${TS}" \
  -H "X-Signature: ${SIG}" \
  -d "${BODY}" \
  "${SC_BASE_URL}/webhook/chat/inbound" \
  | jq .
