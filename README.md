# konkui partner contracts

How to connect a system to **konkui's agent**. Same idea as integrating with
Meta / TikTok: they publish how you talk to them, and you build to it. This repo is
konkui's version of that — published rules for talking to konkui, which you build to.

This is a **neutral standard**. The core (`STANDARDS.md`, `envelope/skeleton.md`,
`conformance/`) references **no specific system** — any system can read it and integrate.
Concrete integrations live under `examples/` purely as illustrations.

konkui is a pure aggregator. It does **not** control how your platform is built. It
defines only its own side and states what it needs from yours:

| Surface | Who defines it |
|---------|----------------|
| **Webhook you push events INTO konkui** (envelope shape, auth, retry) | **konkui** — firm. It is konkui's endpoint; push events in this shape. |
| **Shared rules** (auth formula, error shape, versioning) | **konkui** — firm. |
| **The API konkui calls on your platform** (profile, media, send, reply) | **you** — konkui states the *capabilities* it needs; you design the actual endpoints, methods, and shapes. konkui adapts to your design. |
| **Your internal logic** (routing, when to enrich, follow/unfollow handling) | **you** — entirely yours. konkui never dictates it. |

If your platform does not yet expose what konkui needs, this repo tells you **what** to
build (not how). konkui holds no integration-specific business hacks in its core.

## What you must hand back

konkui does not care **how** you design your side — but you must **document** it so konkui
can build against it. In your integration folder, provide:

- **Your API docs** — the real endpoints konkui calls (your design): an OpenAPI file
  or a link to your own published doc.
- **Your concrete webhook payloads** — exactly what you push into konkui's webhook: which
  event types, which message subtypes, your `source` fields — i.e. your concrete fill-in
  of `envelope/skeleton.md`.

No docs = no integration. konkui builds its module against these, not against guesses.

## Layout

```
konkui-partner-contracts/
├── STANDARDS.md            # the standard — non-negotiable, neutral, names no system
├── envelope/
│   └── skeleton.md         # shared inbound event-envelope shape every integration fills in
├── conformance/            # Spectral ruleset to lint a spec against the standard
├── examples/               # concrete integrations, for illustration only
│   ├── studentcare/        # example: a proxied backend
│   └── centralapi/         # example: a proxied shared channel
└── .github/CODEOWNERS      # Phanu gates every change
```

## Two classes of system

| Class | What | How konkui talks to it |
|-------|------|------------------------|
| **Proxied integration** | A system whose team can build to this standard (its own backend / gateway) | Conforms to the shared envelope + STANDARDS. Governed by this repo. See `examples/` for illustrations. |
| **Direct vendor** | A fixed external platform you cannot change (e.g. a social network's API) | konkui adapts to it inside its own adapter layer. **Not** governed by this repo. |

> If you can make the upstream system conform, it is a **proxied integration** and this repo applies.
> If you must adapt to a fixed external vendor, it is **direct** and lives in konkui's adapter layer.

## Adding an integration

1. Copy an existing folder under `examples/` to `examples/<name>/` as a starting point.
2. Inherit `STANDARDS.md` and `envelope/skeleton.md` **as-is** — do not copy them.
3. Fill in only what is platform-specific:
   - `STANDARDS-addendum.md` — media limits, scope / data-ownership, the capabilities konkui needs.
   - `api/konkui-side-v1.yaml` — **firm**: the webhook konkui exposes; you push events here in the envelope shape.
   - `api/<name>-side-v1.yaml` — **reference, non-binding**: an example of the API konkui calls. You design the real one; konkui adapts.
   - `payloads/` — concrete envelope examples for this platform.
4. Lint your specs: `npx @stoplight/spectral-cli lint <spec>.yaml --ruleset conformance/.spectral.yaml` → fix errors.
5. Implement your side, point konkui at your staging endpoints, verify end-to-end.
6. Open a PR. Phanu (CODEOWNERS) reviews against `STANDARDS.md`.

What stays shared (never duplicated): the auth formula, error shape, idempotency,
versioning, SLA, logging rules, and the envelope top-level shape. Change those once,
here, and every integration inherits it.

## Examples

`examples/` holds concrete integrations as **reference only** — the standard itself
references none of them. Use them as worked illustrations when building your own.

| Example | State | Notes |
|---------|-------|-------|
| `examples/studentcare` | live integration | a proxied backend; on the target pattern |
| `examples/centralapi` | draft | a proxied shared channel; pending the platform team's review |

## License

Proprietary — internal EEC use only. See [LICENSE](./LICENSE).
