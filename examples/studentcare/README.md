# Partner: StudentCare (SC)

SC proxies the **StudentCare backend** (student/parent/teacher messaging) to konkui.
Dedicated upstream — not a shared channel. This folder is SC's home inside the
partner-contract monorepo (migrated from the standalone `studentcare-konkui-contract`
repo, no wire change). SC's existing integration already matches this contract, so it
served as the reference the baseline was drawn from.

## The integration model (think Meta / TikTok)

This contract is a **shared development guideline**, not a top-down mandate — it exists so
our two systems interoperate, and it evolves by agreement (PRs), not decree.

The shape is the same one konkui uses with Facebook, Instagram, or TikTok: **you are the
platform; konkui is the app.** konkui hosts a webhook you deliver to, calls your API to act,
and reads your spec — it does not reach into your internals, and your data does not flow into
konkui. You own the customers (students/parents/teachers) and the API surface; you design it.

The **only** parts konkui keeps firm across every platform are the wire baseline
(`../../STANDARDS.md`) + the webhook envelope (`../../envelope/skeleton.md`) — kept minimal on
purpose, so konkui's aggregator has one parser. Everything about *your* API (`api/sc-side-v1.yaml`
is what we have today, and it changes with your system) is yours. Unlike CA, SC is a dedicated
channel, so there's **no shared-OA establishment / ownership handshake** — every event on the
upstream is already SC's, routed to konkui directly.

Coordinate changes here: anything that touches the wire → open a PR so konkui can keep its
parser in sync; we agree before it ships. See root `CONTRIBUTING.md`.

## Topology

```
[konkui]
   │                       ▲
   │ konkui → SC           │ SC → konkui webhook
   │ (X-Api-Secret /       │ (HMAC WebhookSecret,
   │  HMAC InboundSecret)  │  enriched envelope)
   ▼                       │
[StudentCare backend]
```

## Surfaces

| Direction | Surface | Spec |
|-----------|---------|------|
| SC → konkui | webhook `POST /webhooks/studentcare/webhook` (enriched envelope) | `api/konkui-side-v1.yaml` |
| konkui → SC | read API — v1.3 advisor-keyed (`/api/chat/advisors/{teacherNo}/threads` + `/students/{stdNo}/messages`), `admin/threads`, attachment, legacy roster | `api/sc-side-v1.yaml` |
| konkui → SC | inbound reply `POST /webhook/chat/inbound` | `api/sc-side-v1.yaml` |

## Files

- `STANDARDS-addendum.md` — media (25 MB inline), scope / data-ownership, SC envelope leaves.
- `auth/` — `hmac.md`, `api-secret.md` (concrete secret names + flow).
- `api/` — OpenAPI both directions.
- `payloads/envelope-schemas.md` — flat narrative of every JSON shape on the wire.
- `samples/curl/` + `samples/payloads/` — runnable requests + sample bodies.

## Inherits (do not duplicate)

- `../../STANDARDS.md` — auth formula, error shape, idempotency, versioning, SLA, logging.
- `../../envelope/skeleton.md` — inbound event envelope top-level shape.

## Key facts

- SC = source of truth for all master data. konkui = display + transport only.
- konkui dedups inbound on `message.id`; SC keeps it stable across retries.
- Conversation key inside konkui = `stdNo`.
- `senderRole` open enum; konkui coerces unknown → `"other"`.
- Migration note: original `studentcare-konkui-contract` repo (remote +
  tag `v1.0`) stays live until the SC team is cut over to this monorepo path.
