# Inbound Event Envelope — Shared Skeleton

Every partner pushes inbound events to konkui as **this** envelope. The top-level shape
is identical across all integrations so konkui has **one** webhook parser and **one** dedup
model. Only the leaves (`source.*` enrichment, `message.*` subtypes, and optional event-level
fields a partner needs) vary per platform, and each integration documents its leaves in its
own `payloads/` (see `examples/`).

> This skeleton is the canonical target. A partner does **not** invent its own envelope
> shape — it fills this one in. If a real field has nowhere to go here, that is a
> contract change (PR against this file), not a partner-local improvisation.

## Skeleton

```jsonc
{
  "destination": "string",          // SOURCE channel / instance id (an OA key, a backend id) that
                                    //   konkui routes on. NOT the literal target "konkui".
  "events": [
    {
      "type": "message",            // message | postback | follow | unfollow | ...
                                    //   partner declares its allowed set in its addendum
      "timestamp": 1747008300000,   // unix MILLISECONDS (legacy quirk — shared, NOT seconds)
      "webhookEventId": "01H...",   // string|null — dedup key for NON-message events
      "...": "...",                 // partner-specific EVENT leaves (e.g. a replyToken, a threadId/
                                    //   conversation ref) — see "What a partner extends" below
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

1. **`events.length` ≥ 1.** Empty `events[]` is a whole-request failure → `400` + `EMPTY_EVENTS`.
2. **Per-event dedup key is mandatory.** `message` events: `message.id`. Non-message events: `webhookEventId`. A dedup-skipped or individually-failed event does **not** fail the batch — it is reported in the `200` response's `failures[]` (rule 5); the batch still succeeds if any other event is valid.
3. **`source.userId` is always present** on every event. It is konkui's routing key.
4. **`timestamp` is unix milliseconds.** Do not send seconds here. (The `X-Timestamp` HMAC header is seconds — see STANDARDS §2. Don't confuse them.)
5. **konkui-side response contract (uniform across all partners — this is konkui's own behavior, so every partner parses it the same way):**
   - **Success** → `200` `{ "responseCode": "200", "responseMesg": "OK" }`, optionally `accepted` / `deduplicated` counts.
   - **Partial** (batch accepted, ≥1 event failed/dedup-skipped) → still `200`, with a populated `failures[]` (each entry: `messageId` + `errorCode`). The partner logs them; it does **not** retry the batch.
   - **Whole-request failure** (bad JSON, empty `events`, HMAC/timestamp/replay, konkui internal / dedup-store down) → the proper 4xx/5xx + `errorCode` in the STANDARDS §4 error shape. **Never `200` on these** — a `200` tells the partner "all good, stop retrying" and silently drops the events. (This is non-negotiable; STANDARDS §4 "never 2xx for a failed request".)
6. **konkui dedups, does not reject duplicates.** Same dedup key seen again → counted in `deduplicated`, still `200` (a duplicate is success, not a failure).
7. **Unknown `type` / `source.type` / open enums** → consumer coerces to a documented fallback, never hard-rejects (forward compatibility).

## Base `errorCode` set (konkui-side webhook responses)

Shared across every partner so failures parse uniformly. A partner's addendum may **add** domain
codes (e.g. an unknown account, a media-decode failure); it may not redefine these.

| `errorCode` | When | Status |
|-------------|------|--------|
| `HMAC_INVALID` | signature mismatch / missing auth headers | 401 |
| `TIMESTAMP_SKEW` | `X-Timestamp` outside ±300s | 401 |
| `REPLAY_DETECTED` | signature seen recently | 401 |
| `INVALID_JSON` | body did not parse | 400 |
| `SCHEMA_VIOLATION` | parsed but failed required-field / type / enum | 400 |
| `EMPTY_EVENTS` | `events[]` missing or zero-length | 400 |
| `UNSUPPORTED_EVENT_TYPE` | unknown `type` and konkui chose to reject (default: ignore) | 400 |
| `DEDUP_STORE_DOWN` | cannot check duplicates — safer to fail than double-deliver | 503 |
| `INTERNAL_ERROR` | unhandled konkui error | 500 |
| `SERVICE_UNAVAILABLE` | maintenance / dependency outage (set `Retry-After`) | 503 |

## What a partner extends (and where)

| Slot | Shared? | Partner declares in |
|------|---------|---------------------|
| `destination` value | shape shared; value = partner's source-channel / instance id | addendum |
| `events[].type` allowed set | base set shared | addendum (which types it emits) |
| event-level leaves (e.g. `replyToken`, `replyInfo`/`threadId`, conversation ref) | no — optional, partner-specific | `payloads/` + its `konkui-side` OpenAPI |
| `source.*` beyond `userId/displayName/pictureUrl` | no | `payloads/` + addendum |
| `message.type` subtypes + their fields | base set shared | `payloads/` |
| media transport (inline base64 vs metadata + fetch) | no | addendum (+ STANDARDS §12 waiver) |

## Which events reach konkui = the partner's design

This skeleton defines the **shape** of events that arrive — not **which** events the
partner chooses to send. Filtering, ownership, follow/unfollow handling, and how a partner
decides a conversation belongs to konkui are entirely the partner's design. konkui parses
and records whatever arrives in this shape; it does not dictate the partner's routing.
