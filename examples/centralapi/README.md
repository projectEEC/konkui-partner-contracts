# Partner: Central API (CA)

CA proxies the college's **LINE Official Account** to konkui. The LINE OA is a **shared**
channel (teachers, admins, chatbots, customers all on one OA), and LINE allows exactly
**one** webhook URL per channel — CA owns it. konkui cannot register its own LINE
webhook, so CA-as-intermediary is mandatory while we use one shared OA (fixed business
requirement).

Replaces the previous ad-hoc LINE integration with this normalized, standards-based
contract.

## Two roles (cleanly separated)

| Role | Direction | What |
|------|-----------|------|
| **Event Router** | LINE → CA → konkui | Receive the single LINE webhook, verify signature, **enrich** (profile), fan out the shared envelope to konkui. Which conversations to send = CA's design. |
| **Data/Command Gateway** | konkui → CA → LINE | Expose LINE capabilities (profile, content, send, reply, quota) as an API konkui calls; CA holds the channel token |

## Topology

```
[konkui]
   │                       ▲
   │ konkui → CA (HMAC)    │ CA → konkui webhook (HMAC, enriched envelope)
   ▼                       │
[Central API]
   │                       ▲
   │ CA → LINE             │ LINE → CA webhook (one URL, CA owns)
   │ (channel token)       │
   ▼                       │
[LINE Messaging API]
```

## Surfaces

| Direction | Surface | Spec |
|-----------|---------|------|
| CA → konkui | webhook `POST /webhooks/central-api` (enriched envelope) | `api/konkui-side-v1.yaml` |
| konkui → CA | Gateway (profile, content, send, reply, quota) — **reference, CA designs the real API** | `api/ca-side-v1.yaml` |

## Files

- `STANDARDS-addendum.md` — media (200 MB metadata + fetch), what konkui needs, error cases, CA envelope leaves, event types.
- `auth/` — concrete secret names + cutover from the old `X-Api-Key`.
- `api/` — OpenAPI: `konkui-side` (firm webhook) + `ca-side` (reference, CA designs the real one).
- `payloads/envelope-schemas.md` — every JSON shape on the wire (envelope + gateway reference).

## Inherits (do not duplicate)

- `../../STANDARDS.md` — auth formula, error shape, idempotency, versioning, SLA, logging.
- `../../envelope/skeleton.md` — inbound event envelope top-level shape.

## Rollout priority

| Tier | Scope | Status |
|------|-------|--------|
| **P0** | profile-enriched envelope + inbound content | unblocks the profile fix |
| P1 | unified outbound send + reply-token | full parity with FB/IG |
| P2 | typing indicator + quota | UX polish |
| P3 | multicast / broadcast | defer until a real consumer |

## Open decisions (confirm with CA team)

Items to confirm with the CA team: channel-token rotation, multi-OA support,
who downloads inbound media (live-proxy vs store), webhook retry behavior,
rate-limit tier + error codes, profile-enrich latency before forwarding.
