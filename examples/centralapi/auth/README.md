# CA Auth

The HMAC formula, timestamp rules, replay window, and constant-time compare are **shared**
— see root `../../../STANDARDS.md` §2. Do not re-document them here. This file declares
only what is CA-specific.

## Secrets (per-environment, exchanged out-of-band, never committed)

| Secret | Signer | Use |
|--------|--------|-----|
| `WebhookSecret` | CA | CA → konkui webhook (`X-Signature`) |
| `InboundSecret` | konkui | konkui → CA state-changing POST (`X-Signature`) |
| `ApiSecret` (`X-Api-Secret`) | shared | every konkui → CA call |

## Cutover from legacy `X-Api-Key`

The legacy integration used a single static `X-Api-Key`. It is replaced by HMAC +
`X-Api-Secret`.

Hard cutover, coordinated in one window:

1. CA implements HMAC signing on the webhook + accepts `X-Api-Secret` on the gateway.
2. konkui **accepts both** legacy `X-Api-Key` and new HMAC on `/webhooks/central-api`
   during the transition (version-detect on header presence).
3. CA confirms HMAC live in dev → konkui drops `X-Api-Key` acceptance.

No dual-auth window longer than necessary — secrets rotate to the new scheme once dev is green.
