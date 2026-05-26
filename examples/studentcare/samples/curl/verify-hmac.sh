#!/usr/bin/env bash
# Self-test: compute HMAC locally and print canonical + signature.
# Use this to verify your implementation produces matching signatures.
set -euo pipefail

SECRET="${1:-test-secret-key}"
BODY="${2:-{\"hello\":\"world\"\}}"
TS="${3:-1747008300}"

CANONICAL="${TS}.${BODY}"
SIG=$(printf '%s' "${CANONICAL}" | openssl dgst -sha256 -hmac "${SECRET}" -hex | awk '{print $NF}')

echo "secret    : ${SECRET}"
echo "timestamp : ${TS}"
echo "body      : ${BODY}"
echo "canonical : ${CANONICAL}"
echo "signature : ${SIG}"
