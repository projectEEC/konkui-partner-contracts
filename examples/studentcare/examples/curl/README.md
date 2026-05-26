# curl smoke tests

Runnable scripts to exercise the contract end-to-end.

## Setup

```bash
# Load secrets from your local env (do NOT commit these)
export SC_BASE_URL="https://dsv.eeccollege.com"
export KONKUI_BASE_URL="https://testservice.eeccollege.com"
export API_SECRET="<from 1Password>"
export WEBHOOK_SECRET="<from 1Password>"      # SC → konkui signs with this
export INBOUND_SECRET="<from 1Password>"       # konkui → SC inbound signs with this
```

## Scripts

| Script | Direction | What it tests |
|--------|-----------|---------------|
| `sc-list-advisor-students.sh` | konkui → SC | GET /api/advisors/{externalUserId}/students — advisor roster + parents |
| `sc-list-threads.sh` | konkui → SC | GET /api/chat/threads — basic auth |
| `sc-list-messages.sh` | konkui → SC | GET /api/chat/threads/{id}/messages |
| `sc-get-attachment.sh` | konkui → SC | GET /api/chat/external/attachment/{id} (binary) |
| `sc-send-inbound.sh` | konkui → SC | POST /webhook/chat/inbound (HMAC + ApiSecret) |
| `konkui-webhook.sh` | SC → konkui | POST /webhooks/studentcare/webhook (HMAC only) |
| `verify-hmac.sh` | self | Compute HMAC locally and compare to expected |

## Running

```bash
chmod +x *.sh
./sc-list-advisor-students.sh T67001 2568
./sc-list-threads.sh 67100001
./konkui-webhook.sh   # uses examples/payloads/webhook-envelope-text.json
```

## Expectations

- `sc-list-*` → `200` + JSON body matching `payloads/envelope-schemas.md`.
- `sc-send-inbound` → `200` + `responseCode: "200"` + `receivedMessageId` populated.
- `konkui-webhook` → `200` + `{"responseCode":"200","responseMesg":"OK"}`.
- Any `401` → check `X-Timestamp` clock skew + `X-Signature` formula + secret value.
