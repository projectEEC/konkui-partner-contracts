# Inbound Event Envelope — Shared Skeleton

Every partner pushes inbound events to konkui as **this** envelope. The top-level shape
is identical across all partners so konkui has **one** webhook parser, **one** dedup
model, and **one** ownership/routing model. Only the leaves (`source.*` enrichment and
`message.*` subtypes) vary per platform, and each partner documents its leaves in
`partners/<name>/payloads/`.

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
        "...": "..."                // partner-specific identity leaves (e.g. SC stdNo, LINE language)
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
| ownership / routing (which events reach konkui) | model shared | addendum |

## Ownership / routing model (shared shape, partner fills the rules)

A partner that fronts a **shared** upstream channel (e.g. one LINE OA used org-wide)
MUST only forward events that belong to konkui. The mechanism is shared:

- konkui registers ownership of a `userId` via a partner **claim** endpoint at the
  moment it takes over that user.
- The partner forwards `message` / `postback` events **only** for claimed users.
- Lifecycle events (`follow` / `unfollow`) are forwarded **always** (konkui matches them
  to pending invites / updates follow state).

The exact per-event routing table is partner-specific → addendum. A partner that fronts
a **dedicated** upstream (not shared) may forward everything; it still documents that
choice in its addendum.
