# X-Api-Secret Header Specification

Defense-in-depth header on all `konkui → SC` calls. Layered on top of HMAC signing for inbound API; sole credential for read API.

## Where it applies

| Endpoint | `X-Api-Secret` | HMAC `X-Signature` |
|----------|----------------|---------------------|
| `GET  /api/chat/threads` | **required** | not required |
| `GET  /api/chat/threads/{id}/messages` | **required** | not required |
| `GET  /api/chat/external/attachment/{id}` | **required** | not required |
| `POST /webhook/chat/inbound` | **required** | **required** |
| `POST /webhooks/studentcare/webhook` (konkui side) | not applicable | required |

## Header

```
X-Api-Secret: <ApiSecret value from 1Password>
```

- 64-character hex string (32 bytes of entropy). Treat as opaque token.
- Sent verbatim — no encoding, no prefix, no `Bearer`.
- Case-sensitive match.

## Validation rules (SC side)

1. Read `X-Api-Secret` header from request.
2. Reject if missing or empty → `401`.
3. **Constant-time compare** against the stored `ApiSecret`. Mismatch → `401`.
4. Never log the value.
5. Never echo in error response (`responseMesg` must not leak it).

## Distribution

- Single shared `ApiSecret` per environment (dev / prod).
- Stored in 1Password vault `EEC-StudentCare-Integration`.
- Phanu generates + rotates. Notifies SC ≥ 48h before rotation.
- Both sides load from secret store, never hardcoded.

## Rotation

Same protocol as HMAC secrets:

1. Generate new secret.
2. Update both sides to **accept either** during 24h overlap window.
3. Switch konkui producer to new secret.
4. After 24h verify all traffic uses new secret.
5. Drop old.

## Why two layers (X-Api-Secret + HMAC)?

- `X-Api-Secret` = static shared token. Survives every request. Compromise = total bypass.
- HMAC `X-Signature` = per-request. Cannot be replayed past 300s. Cannot be forged without secret. Body-bound.
- HMAC alone would suffice cryptographically, but `X-Api-Secret` provides:
  - Cheap pre-HMAC filter at edge (LB / WAF can reject obvious unauth before doing HMAC math).
  - Distinct rotation cadence (rotate static token without re-signing client logic).
  - Audit trail of who has the token (track distribution).

## Forbidden

- ❌ Sending `X-Api-Secret` in querystring.
- ❌ Caching it in a cookie.
- ❌ Logging it (including request dumps in DEBUG).
- ❌ Echoing it in error responses.
- ❌ Comparing with `==` (timing leak).
