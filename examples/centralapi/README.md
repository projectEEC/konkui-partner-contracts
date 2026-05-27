# Partner: Central API (CA)

CA proxies the college's **LINE Official Account** to konkui. The LINE OA is a **shared**
channel (teachers, admins, chatbots, customers all on one OA), and LINE allows exactly
**one** webhook URL per channel — CA owns it. konkui cannot register its own LINE
webhook, so CA-as-intermediary is mandatory while we use one shared OA (fixed business
requirement).

Replaces the previous ad-hoc LINE integration with this normalized, standards-based
contract.

## The integration model (think Meta / TikTok)

konkui integrates with you the same way it integrates with Facebook, Instagram, or TikTok:
**you are the platform; konkui is the app.** konkui registers a webhook with you, calls your
API to act, and follows your spec — it does not reach into your internals, and your data does
not flow into konkui.

So konkui needs you to publish a **complete** spec covering the *space* it uses — like a
platform's developer docs:

- the **webhook** konkui hosts and you deliver events to (firm shape — `api/konkui-side-v1.yaml`),
- the **API** konkui calls to act (you design the endpoints/shapes — `api/ca-side-v1.yaml` is a
  reference of the capabilities, not a mandate),
- the **conversation model** — how a conversation is established and routed to konkui on the
  shared OA (see `STANDARDS-addendum.md` → "Conversation establishment"),
- the **rules** konkui must follow (auth, error shape, retries — root `STANDARDS.md`).

The only thing konkui keeps uniform across all platforms is the wire baseline in
`../../STANDARDS.md` + the webhook envelope (so its aggregator has one parser). Everything
about *your* API surface and *your* conversation/ownership logic is yours to design — complete,
so konkui can just place its webhook and call your API correctly.

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

**First, the gating one:** specify the **conversation-establishment model** — how a LINE user
on the shared OA becomes a konkui conversation, and how konkui signals/releases ownership so
its events route correctly (see `STANDARDS-addendum.md` → "Conversation establishment"). Nothing
else can go live without this.

**Second, the inbound-delivery shape — your call:** konkui's aggregator consumes the
[envelope](../../envelope/skeleton.md). The open question is **who maps LINE → that envelope and
enriches the profile**:

- **(a) CA maps + enriches before forwarding** — CA already holds the raw LINE objects + the
  channel token, so this is the natural fit; konkui receives a clean envelope. *(what the addendum
  illustrates today)*, or
- **(b) CA forwards raw LINE; konkui maps it at ingest** — less work for CA.

Pick whichever is easier for CA — konkui supports both (its receiver can accept either during
the transition). One thing is fixed regardless: anything needing the LINE token (profile refresh,
media bytes) comes from **CA's gateway**, because konkui has no direct LINE access. So "(b)" still
relies on CA's gateway for profile/media; it only moves the JSON-reshaping to konkui's side.

Then confirm: channel-token rotation, multi-OA support, who downloads inbound media
(live-proxy vs store), webhook retry behavior, rate-limit tier + error codes, profile-enrich
latency before forwarding.

And these (surfaced in design review — each needs a decision before the matching feature ships):

- **Ownership revocation/notification** — when CA reassigns a user away from konkui (a teacher takes
  over, the user is re-routed), how does konkui learn so it stops sending? The current event set
  (`message`/`postback`/`follow`/`unfollow`) has no "released" signal. Part of the establishment
  design (see addendum → "Conversation establishment", rule 5).
- **Profile-enrich failure path** — if LINE `GET /profile` fails (non-follower / blocked), does CA
  forward the event with `displayName`/`pictureUrl` null, drop it, or retry? (Happy path is
  specified; this failure path is not.)
- **Outbound media URL lifetime + privacy** — konkui-hosted media URLs are publicly fetchable so
  LINE can pull them. How long must they stay live, and are they unguessable/expiring? (We won't
  relay indefinitely-public customer PII without an agreed expiry.)
- **Dual-auth cutover precedence** — during the `X-Api-Key` → HMAC transition, if both headers
  arrive, which wins; and once `X-Api-Key` is dropped, what is the reject status + `errorCode`?
