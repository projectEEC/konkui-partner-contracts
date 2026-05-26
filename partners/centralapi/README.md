# Partner: Central API (CA)

CA proxies the college's **LINE Official Account** to konkui. The LINE OA is a **shared**
channel (teachers, admins, chatbots, customers all on one OA), and LINE allows exactly
**one** webhook URL per channel — CA owns it. konkui cannot register its own LINE
webhook, so CA-as-intermediary is mandatory while we use one shared OA (fixed business
requirement).

Replaces the previous ad-hoc integration (raw LINE passthrough + `SendFlexMessage`-only
outbound + konkui-side `LINE outbound-only / drop unknown` hack). Design narrative:
konkui state `plans/centralapi-konkui-redesign.md`.

## Two roles (cleanly separated)

| Role | Direction | What |
|------|-----------|------|
| **Event Router** | LINE → CA → konkui | Receive the single LINE webhook, verify signature, **enrich** (profile), filter by ownership, fan out the shared envelope to konkui |
| **Data/Command Gateway** | konkui → CA → LINE | Expose LINE capabilities (claim, profile, content, send, reply, quota) as an API konkui calls; CA holds the channel token |

## Topology

```
[konkui apps/web — agent UI]
        │  REST + SignalR
[konkui "central" platform module]
   │                       ▲
   │ konkui → CA (HMAC)    │ CA → konkui webhook (HMAC, enriched envelope)
   ▼                       │
[Central API  buapi.eeccollege.com]
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
| konkui → CA | Gateway `/v1/line/...` (claim, profile, content, send, reply, quota) | `api/ca-side-v1.yaml` |

## Files

- `STANDARDS-addendum.md` — media (200 MB metadata + fetch), ownership-routing table, error-code enum, CA envelope leaves, event types.
- `auth/` — concrete secret names + cutover from the old `X-Api-Key`.
- `api/` — OpenAPI both directions.
- `payloads/envelope-schemas.md` — every JSON shape on the wire (envelope + gateway).
- `examples/` — runnable requests + sample bodies.

## Inherits (do not duplicate)

- `../../STANDARDS.md` — auth formula, error shape, idempotency, versioning, SLA, logging.
- `../../envelope/skeleton.md` — inbound event envelope top-level shape.

## Rollout priority

| Tier | Scope | Status |
|------|-------|--------|
| **P0** | ownership claim + profile-enriched envelope + inbound content | unblocks the profile + routing fix |
| P1 | unified outbound send + reply-token | full parity with FB/IG |
| P2 | typing indicator + quota | UX polish |
| P3 | multicast / broadcast | defer until a real consumer |

## Open decisions (confirm with CA team)

See `plans/centralapi-konkui-redesign.md` §7: channel-token rotation, multi-OA,
who-downloads-media, claim persistence, retry behavior, rate-limit tier, enrich latency.
