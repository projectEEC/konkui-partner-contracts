# konkui partner contracts

Single source of truth for how **partner platforms** integrate with konkui.

konkui is a pure aggregator. Every partner platform that wants konkui to ingest its
events and accept commands conforms to **one shared rulebook** + a **shared event
envelope skeleton**, then declares only its platform-specific leaves in its own folder.

This repo is that rulebook. A partner team reads it, implements to it, runs the
conformance checks, and is certified to connect. konkui holds no partner-specific
business hacks.

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

1. Copy `partners/_template/` (or an existing partner folder) to `partners/<name>/`.
2. Inherit `STANDARDS.md` and `envelope/skeleton.md` **as-is** — do not copy them.
3. Fill in only what is platform-specific:
   - `partners/<name>/STANDARDS-addendum.md` — media limits, scope / data-ownership, capability matrix.
   - `partners/<name>/api/<name>-side-v1.yaml` — endpoints the partner exposes (command/data gateway).
   - `partners/<name>/api/konkui-side-v1.yaml` — webhook konkui exposes (event-router target).
   - `partners/<name>/payloads/` — concrete envelope examples for this platform.
4. Run `conformance/` against the partner's staging endpoints. Green = ready.
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
