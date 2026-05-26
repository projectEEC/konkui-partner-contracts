# Inbound Event Envelope — Shared Skeleton

Every partner pushes inbound events to konkui as **this** envelope. The top-level shape
is identical across all integrations so konkui has **one** webhook parser and **one** dedup
model. Only the leaves (`source.*` enrichment and `message.*` subtypes) vary per platform,
and each integration documents its leaves in its own `payloads/` (see `examples/`).

> This skeleton is the canonical target. A partner does **not** invent its own envelope
> shape — it fills this one in. If a real field has nowhere to go here, that is a
> contract change (PR against this file), not a partner-local improvisation.

## Skeleton

```jsonc
{
  "destination": "string",          // target identifier (oaKey / system id). konkui routes on it.
  "events": [
    {
      "type": "message",            // message | postback | follow | unfollow | ...
                                    //   partner declares its allowed set in its addendum
      "timestamp": 1747008300000,   // unix MILLISECONDS (legacy quirk — shared, NOT seconds)
      "webhookEventId": "01H...",   // string|null — dedup key for NON-message events
      "source": {
        "type": "user",             // identity kind; "user" is the common case
        "userId": "string",         // REQUIRED — stable external user id; konkui's routing key
        "displayName": "string",    // string|null — partner SHOULD enrich
        "pictureUrl": "string",     // string|null — partner SHOULD enrich
        "...": "..."                // platform-specific identity leaves (e.g. a user/account number, a locale)
      },
      "message": {                  // present when type=message
        "id": "string",             // REQUIRED — dedup key for message events; stable across retries
        "type": "text",             // text | image | video | audio | file | sticker | location | ...
        "text": "string",           // string|null (type=text)
        "...": "..."                // partner-specific message leaves (see partner payloads/)
      },
      "postback": {                 // present when type=postback
        "data": "string",
        "...": "..."
      }
    }
  ]
}
```

## Invariant rules (all partners)

1. **`events.length` ≥ 1.** Empty array → `400`.
2. **Per-event dedup key is mandatory.** `message` events: `message.id`. Non-message events: `webhookEventId`. Missing → that event is skipped with a WARN log; the batch still returns `200` if any other event is valid.
3. **`source.userId` is always present** on every event. It is konkui's routing key.
4. **`timestamp` is unix milliseconds.** Do not send seconds here. (The `X-Timestamp` HMAC header is seconds — see STANDARDS §2. Don't confuse them.)
5. **Response is uniform:** `{ "responseCode": "200", "responseMesg": "OK" }`. Errors use the same shape (STANDARDS §4).
6. **konkui dedups, does not reject duplicates.** Same dedup key seen again → `duplicateCount++`, still `200`.
7. **Unknown `type` / `source.type` / open enums** → consumer coerces to a documented fallback, never hard-rejects (forward compatibility).

## What a partner extends (and where)

| Slot | Shared? | Partner declares in |
|------|---------|---------------------|
| `destination` semantics | shape shared, value partner-defined | addendum |
| `events[].type` allowed set | base set shared | addendum (which types it emits) |
| `source.*` beyond `userId/displayName/pictureUrl` | no | `payloads/` + addendum |
| `message.type` subtypes + their fields | base set shared | `payloads/` |
| media transport (inline base64 vs metadata + fetch) | no | addendum (+ STANDARDS §12 waiver) |

## Which events reach konkui = the partner's design

This skeleton defines the **shape** of events that arrive — not **which** events the
partner chooses to send. Filtering, ownership, follow/unfollow handling, and how a partner
decides a conversation belongs to konkui are entirely the partner's design. konkui parses
and records whatever arrives in this shape; it does not dictate the partner's routing.
