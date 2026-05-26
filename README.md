# konkui partner contracts

How to connect a system to **konkui's agent**. Same idea as integrating with
Meta / TikTok: they publish how you talk to them, and you build to it. This repo is
konkui's version of that — published rules for talking to konkui, which you build to.

konkui is a pure aggregator. It does **not** control how your platform is built. It
defines only its own side and states what it needs from yours:

| Surface | Who defines it |
|---------|----------------|
| **Webhook you push events INTO konkui** (envelope shape, auth, retry) | **konkui** — firm. It is konkui's endpoint; push events in this shape. |
| **Shared rules** (auth formula, error shape, versioning) | **konkui** — firm. |
| **The API konkui calls on your platform** (own/claim, profile, media, send, reply) | **you** — konkui states the *capabilities* it needs; you design the actual endpoints, methods, and shapes. konkui adapts to your design. |
| **Your internal logic** (routing, when to enrich, follow/unfollow handling) | **you** — entirely yours. konkui never dictates it. |

If your platform does not yet expose what konkui needs, this repo tells you **what** to
build (not how). konkui holds no partner-specific business hacks.

## What you must hand back

konkui does not care **how** you design your side — but you must **document** it so konkui
can build against it. In your `partners/<name>/` folder, provide:

- **Your API docs** — the real endpoints konkui calls (your design): `api/<name>-side-*.yaml`
  or a link to your own published doc.
- **Your concrete webhook payloads** — exactly what you push into konkui's webhook: which
  event types, which message subtypes, your `source` fields — i.e. your concrete fill-in
  of `envelope/skeleton.md`, in `payloads/`.

No docs = no integration. konkui builds its module against these, not against guesses.

## Layout

```
konkui-partner-contracts/
├── STANDARDS.md            # cross-partner rulebook — non-negotiable, applies to ALL partners
├── envelope/
│   └── skeleton.md         # shared inbound event-envelope shape every partner extends
├── conformance/            # shared conformance checks a partner runs before connecting
├── partners/
│   ├── studentcare/        # SC — proxied StudentCare backend
│   └── centralapi/         # CA — proxied LINE OA (shared college channel)
└── .github/CODEOWNERS      # Phanu gates every change
```

## Two classes of platform

| Class | Examples | How konkui talks to it |
|-------|----------|------------------------|
| **Partner (proxied)** | StudentCare (SC), Central API (CA) | Partner wraps a real backend behind its own team's API. **This repo governs these.** Partner conforms to the shared envelope + STANDARDS; konkui needs no per-partner adapter logic beyond a thin API client. |
| **Direct** | Facebook, Instagram, TikTok | konkui talks to the vendor directly via a konkui-owned adapter. Not governed here — the vendor's format is fixed and konkui adapts to it. |

> If you can make the upstream system conform, it is a **partner** and belongs here.
> If you must adapt to a fixed external vendor, it is **direct** and lives in konkui's adapter layer.

## Adding a new partner

1. Copy an existing partner folder (e.g. `partners/studentcare/`) to `partners/<name>/`.
2. Inherit `STANDARDS.md` and `envelope/skeleton.md` **as-is** — do not copy them.
3. Fill in only what is platform-specific:
   - `partners/<name>/STANDARDS-addendum.md` — media limits, scope / data-ownership, the capabilities konkui needs.
   - `partners/<name>/api/konkui-side-v1.yaml` — **firm**: the webhook konkui exposes; you push events here in the envelope shape.
   - `partners/<name>/api/<name>-side-v1.yaml` — **reference, non-binding**: an example shape of the API konkui calls. You design the real one; konkui adapts.
   - `partners/<name>/payloads/` — concrete envelope examples for this platform.
4. Implement your side, then point konkui at your staging endpoints to verify end-to-end.
5. Open a PR. Phanu (CODEOWNERS) reviews against `STANDARDS.md`.

What stays shared (never duplicated into a partner folder): the auth formula, error
shape, idempotency, versioning, SLA, logging rules, and the envelope top-level shape.
Change those once, here, and every partner inherits it.

## Status

| Partner | State | Notes |
|---------|-------|-------|
| `studentcare` | live | already on the target pattern; this repo is its new home (migrated from `studentcare-konkui-contract`) |
| `centralapi` | design → contract | replaces raw-LINE-passthrough; P0 = ownership + profile-enriched envelope + inbound content |

Design narrative for CA: see konkui state `plans/centralapi-konkui-redesign.md`.

## License

Proprietary — internal EEC use only. See [LICENSE](./LICENSE).
