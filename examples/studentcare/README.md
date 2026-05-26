# Partner: StudentCare (SC)

SC proxies the **StudentCare backend** (student/parent/teacher messaging) to konkui.
Dedicated upstream — not a shared channel. Already on the target pattern; this folder is
SC's home inside the partner-contract monorepo (migrated from the standalone
`studentcare-konkui-contract` repo, no wire change).

## Topology

```
[konkui apps/web — agent UI]
        │  REST + SignalR
[konkui "advisor" platform module]
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
