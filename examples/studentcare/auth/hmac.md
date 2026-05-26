# HMAC-SHA256 Signing Specification

Applies to:

- `SC → konkui` webhook delivery (signed with `WebhookSecret`)
- `konkui → SC` `POST /webhook/chat/inbound` (signed with `InboundSecret`)

## Headers

| Header | Required | Format |
|--------|----------|--------|
| `X-Timestamp` | yes | Unix epoch **seconds** as decimal string. Example: `"1747008300"`. |
| `X-Signature` | yes | Lowercase hex of HMAC output. Example: `"a3f5..."` (64 hex chars). |

## Signing formula

```
canonical    = bytes(X-Timestamp) + bytes(".") + rawRequestBody
signature    = HMAC-SHA256(key = secret, data = canonical)
X-Signature  = lowercase_hex(signature)
```

Where:

- `secret` = UTF-8 bytes of the secret string (`WebhookSecret` or `InboundSecret`).
- `rawRequestBody` = exact bytes the consumer will receive. **Do not canonicalize the JSON.** Whitespace and field order are part of the signature.
- `bytes(".")` = single ASCII period (0x2E).

## Reference implementation (C#)

```csharp
public static string ComputeSignatureHex(string secret, long timestamp, ReadOnlySpan<byte> rawBody)
{
    var prefix = Encoding.UTF8.GetBytes($"{timestamp}.");
    var buffer = new byte[prefix.Length + rawBody.Length];
    prefix.CopyTo(buffer.AsSpan());
    rawBody.CopyTo(buffer.AsSpan(prefix.Length));

    using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
    return Convert.ToHexString(hmac.ComputeHash(buffer)).ToLowerInvariant();
}
```

## Reference implementation (Node.js)

```js
import crypto from "node:crypto";

function computeSignature(secret, timestamp, rawBody) {
  const canonical = Buffer.concat([
    Buffer.from(`${timestamp}.`, "utf8"),
    Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody, "utf8"),
  ]);
  return crypto
    .createHmac("sha256", secret)
    .update(canonical)
    .digest("hex");
}
```

## Reference implementation (Python)

```python
import hmac, hashlib

def compute_signature(secret: str, timestamp: int, raw_body: bytes) -> str:
    canonical = f"{timestamp}.".encode("utf-8") + raw_body
    return hmac.new(
        secret.encode("utf-8"),
        canonical,
        hashlib.sha256,
    ).hexdigest()
```

## Verification (consumer side)

1. Read `X-Timestamp` header. Reject if missing → `401 missing X-Timestamp or X-Signature`.
2. Read `X-Signature` header. Reject if missing → `401`.
3. Parse `X-Timestamp` as long. Reject non-numeric → `401 X-Timestamp not numeric`.
4. Compute `diff = abs(now_unix_seconds - X-Timestamp)`. Reject if `diff > 300` → `401 timestamp out of window`.
5. Compute expected signature from raw body using formula above.
6. Parse `X-Signature` hex → bytes. Reject malformed hex → `401 signature not hex-encoded`.
7. **Constant-time compare** expected vs provided bytes. Mismatch → `401 signature mismatch`.

**Never use `==` or `.equals()` on the signature** — this leaks timing information. Use:

- C#: `CryptographicOperations.FixedTimeEquals`
- Node: `crypto.timingSafeEqual`
- Python: `hmac.compare_digest`

## Replay protection

- Hard window: **300 seconds**. Configurable via `HmacWindowSeconds` on konkui side; SC side MUST honor the same.
- Clock skew tolerated up to the window. Both sides SHOULD use NTP.
- For extra protection against intra-window replay, the consumer deduplicates by `message.id` (webhook) or `externalMessageId` (inbound) for ≥ 24h.

## Secret rotation

- Secrets are 32-byte random, hex-encoded (64 chars). Example (placeholder, NOT a real secret): `0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`.
- Stored in 1Password vault `EEC-StudentCare-Integration`.
- Rotation: notify counterpart ≥ 48h. Run both old + new secret for 24h overlap. Then drop old.
- Never log the secret. Never echo it in error messages.

## Test vectors

Given:

- `secret = "test-secret-key"`
- `timestamp = "1747008300"`
- `rawBody = {"hello":"world"}` (15 bytes, no trailing newline)

Expected:

- `canonical = "1747008300.{\"hello\":\"world\"}"`
- `X-Signature = "4ef8d4d0692d704ca17a0cc4ebcbf6da6a05ea70b3d4c14f933013472cae6a1c"`

Verified 2026-05-11 via `samples/curl/verify-hmac.sh` (OpenSSL HMAC-SHA256) and konkui's `HmacSha256Validator.ComputeSignatureHex`. Both produce identical output.

Run `samples/curl/verify-hmac.sh` to validate your implementation produces a signature konkui accepts.
