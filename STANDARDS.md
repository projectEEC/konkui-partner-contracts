# Contract Standards — Non-Negotiable

These rules apply to **every** system that integrates with konkui. They are
enforced by Phanu via PR review. Any deviation requires an explicit waiver in the PR
description with rationale + Phanu sign-off (see §12).

System-specific rules (media limits, scope / data-ownership, the capabilities konkui needs)
do **not** live here — they live in that integration's `STANDARDS-addendum.md` (see
`examples/`). This file is only what is true for all integrations, and names no specific system.

Throughout, **partner** = any proxied system that integrates with konkui. konkui is the aggregator.

## 1. Transport

- **Protocol:** HTTPS only. No plain HTTP at any environment.
- **TLS:** ≥ 1.2.
- **Method:** Per OpenAPI spec — no overloading (e.g., GET with body).
- **Charset:** UTF-8 for all text payloads.

## 2. Authentication

All requests crossing the partner ↔ konkui boundary MUST carry:

| Direction | HMAC secret | API secret |
|-----------|-------------|------------|
| konkui → partner (read / query API) | — | `X-Api-Secret` |
| konkui → partner (state-changing POST) | `X-Signature` + `X-Timestamp` (signed with `InboundSecret`) | `X-Api-Secret` |
| partner → konkui (webhook) | `X-Signature` + `X-Timestamp` (signed with `WebhookSecret`) | — |

- **HMAC formula:** `hex(HMAC-SHA256(secret, timestamp + "." + rawBody))`, lowercase.
- **Timestamp:** Unix **seconds**, integer string (the `X-Timestamp` header).
- **Replay window:** 300 seconds. Requests outside window rejected `401`.
- **Constant-time compare** required server-side. No `==` on signatures.

Secrets are per-environment, exchanged out-of-band, never committed:

| Secret | Signer | Use |
|--------|--------|-----|
| `WebhookSecret` | partner | partner → konkui webhook |
| `InboundSecret` | konkui | konkui → partner state-changing POST |
| `ApiSecret` (`X-Api-Secret`) | shared | every konkui → partner call |

See that integration's `auth/` for its concrete secret names + rotation.

## 3. Payload

- **Format:** JSON. `Content-Type: application/json`.
- **Field naming:** `camelCase`. No `snake_case` / `PascalCase`.
- **Null vs missing:** Producers SHOULD omit optional fields when null. Consumers MUST treat missing == null.
- **Timestamps:** ISO 8601 UTC with `Z` suffix (e.g., `"2026-05-11T13:45:00Z"`). **Exception:** the webhook envelope `timestamp` field = unix **milliseconds** (legacy quirk, shared across partners — see `envelope/skeleton.md`).
- **IDs:** String unless OpenAPI says otherwise. Don't assume numeric.
- **Enums:** Use literal strings; document allowed values in OpenAPI `enum`. Open enums (consumer coerces unknown to a fallback) MUST say so explicitly.
- **Unknown fields:** Consumers MUST ignore (forward compatibility).

## 4. Error response

All 4xx and 5xx responses:

```json
{
  "responseCode": "401",
  "responseMesg": "human-readable reason"
}
```

- `responseCode` = HTTP status as string.
- `responseMesg` = short reason. No stack traces. No internal paths.
- `responseMesg` (not `responseMessage`) — legacy spelling. Keep stable.

Status semantics:

| Status | Meaning | Client retry? |
|--------|---------|---------------|
| 200 / 201 | Success | — |
| 400 | Bad request — payload invalid | No |
| 401 | Auth failed — HMAC / X-Api-Secret | No |
| 403 | Forbidden — auth OK but not permitted | No |
| 404 | Resource not found | No |
| 409 | Conflict (e.g., duplicate idempotency key) | No |
| 410 | Gone — resource expired / no longer available (e.g. media content) | No |
| 422 | Validation failed — shape OK, business rule failed | No |
| 429 | Rate limited | Yes, with `Retry-After` |
| 5xx | Server error | Yes, exponential backoff |

Partners SHOULD also return a stable `responseMesg` code enum for domain errors so
konkui can map to friendly UI text. The enum is partner-specific → declared in the
partner's addendum.

## 5. Idempotency

- All `POST` that create resources MUST honor `Idempotency-Key` header.
- Same key + same body → same response.
- Same key + different body → `409 Conflict`.
- Server retains keys ≥ 24h.

Inbound webhooks carry a per-event dedup key (`message.id` for message events,
`webhookEventId` for non-message events). konkui dedups on it; the partner MUST keep
it stable across retries. See `envelope/skeleton.md`.

## 6. Versioning

- Path prefix carries major version: `/v1/...`.
- Breaking change (remove field, rename, type change, semantics change) → new major version path.
- Additive change (new endpoint, new optional field, new enum value) → same version, minor bump in `CHANGELOG.md`.
- Deprecation notice: 6 months in `CHANGELOG.md` before removal.

## 7. SLA / timeouts

- **Client request timeout:** 15 seconds. Server SHOULD respond < 5s p95.
- **Webhook retry policy (partner → konkui):** partner SHOULD retry on 5xx with exponential backoff, 3 attempts. konkui dedups via the per-event key.
- **No fire-and-forget.** Every request must yield a response or an honest timeout error.

## 8. Logging

- Both sides MUST log every request/response with: timestamp, method, path, status, latency, `X-Trace-Id` (if present).
- Never log: `X-Signature`, `X-Api-Secret`, `WebhookSecret`, `InboundSecret`, raw JWT, channel tokens.
- Mask body fields containing PII or binary (base64 / inlined media, full message body) at WARN+ levels.

## 9. Scope — transport boundary only

This contract defines **only** the partner ↔ konkui transport boundary: HTTPS
endpoints, payload shapes, auth, error codes, retry semantics. Anything that lives
entirely on one side is **out of scope** and MUST be solved internally by that side.

- If konkui needs data not retrievable via the contract, the fix is **a new contract endpoint on the partner** — never a local konkui table mirroring partner state.
- If a feature appears to need cross-side coordination beyond transport, open an issue first to decide whether it belongs in the contract or is owned by one side alone. **Default: owned by one side.**

The concrete role split + data-ownership table is **integration-specific** (who owns master
data, what konkui may cache, etc.) → declared in that integration's `STANDARDS-addendum.md`.

## 10. Forbidden

- ❌ Auth via querystring.
- ❌ Custom HMAC formula (no SHA-1, no body-only signing, no JSON canonicalization).
- ❌ Skip `Idempotency-Key` on retryable POST.
- ❌ Numeric ID literal in URL when contract says string.
- ❌ Returning HTML on error.
- ❌ Different error shape per endpoint.
- ❌ Breaking change without major version bump.
- ❌ Logging secrets to disk or alert channels.

## 11. Per-integration addenda

Each integration folder carries, in addition to anything above it overrides via waiver:

- `STANDARDS-addendum.md` — media handling (size limits, inline-vs-fetch), scope / role / data-ownership, the capabilities konkui needs.
- `auth/` — concrete secret names + rotation policy for that integration.
- `api/*.yaml` — OpenAPI (firm konkui-side webhook + reference of the API konkui calls).
- `payloads/` — concrete envelope examples.

An addendum may **tighten** a shared rule but may only **loosen** one through the
§12 waiver process.

## 12. Waiver process

If a real constraint forces a deviation:

1. Open PR with deviation + a `WAIVER.md` entry stating: rule, reason, scope, expiry.
2. Phanu reviews + accepts/rejects.
3. Accepted waiver = time-boxed; must be revisited at expiry.

Each integration records its own standing waivers in its `STANDARDS-addendum.md`
(e.g. a media-handling deviation). The core standard names no specific integration.
