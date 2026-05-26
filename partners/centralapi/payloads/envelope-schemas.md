# CA Payload Schemas Reference

Every JSON shape on the CA ↔ konkui wire. Authoritative source = `api/*.yaml`. This file
is a flat narrative for humans. Inherits the envelope top-level shape from
`../../../envelope/skeleton.md`; below fills in the LINE-specific leaves.

## 1. CA → konkui webhook `POST /webhooks/central-api` → envelope

Path unchanged (CA already posts here). Only the **body** changes from raw LINE
passthrough to the enriched envelope below.

```jsonc
{
  "destination": "line-oa-main",        // OA identifier. Future multi-OA: oaKey
  "events": [
    {
      "type": "message",                 // message | postback | follow | unfollow
      "timestamp": 1747008300000,        // unix MILLISECONDS (LINE native)
      "webhookEventId": "01H...",        // LINE event id; dedup key for non-message events
      "replyToken": "abc...",            // string|null — message/postback only, ~1 min validity
      "source": {
        "type": "user",                  // user only (group/room NOT forwarded)
        "userId": "U5992...",            // LINE userId — konkui routing key
        "displayName": "สมชาย ใจดี",      // ★ CA ENRICHES via LINE GET /profile
        "pictureUrl": "https://...",      // ★ CA ENRICHES
        "statusMessage": "...",          // string|null — optional enrich
        "language": "th"                 // string|null — optional enrich
      },
      "message": {                       // present when type=message
        "id": "line-msg-123",            // ★ dedup key; CA MUST keep stable across retries
        "type": "text",                  // text|image|video|audio|file|sticker|location
        "text": "สวัสดี",                 // string|null (text)
        "fileName": "photo.jpg",         // string|null (file/image)
        "contentType": "image/jpeg",     // string|null (media)
        "fileSize": 12345,               // long|null (file)
        "duration": 5000,                // int|null — ms (video/audio)
        "packageId": "11537",            // string|null (sticker)
        "stickerId": "52002745",         // string|null (sticker)
        "keywords": ["happy"],           // string[]|null (sticker)
        "title": "EEC College",          // string|null (location)
        "address": "...",                // string|null (location)
        "latitude": 13.7,                // double|null (location)
        "longitude": 100.5               // double|null (location)
      },
      "postback": {                      // present when type=postback
        "data": "show:menu",
        "params": { "date": null, "time": null, "datetime": null }
      }
    }
  ]
}
```

**Media is metadata-only** — no binary in the envelope. konkui fetches bytes via §3 content
endpoint on demand. (Deviation from SC's inline base64 — see addendum waiver.)

Response from konkui: `{ "responseCode": "200", "responseMesg": "OK" }`.

Routing: see addendum "Ownership routing". Dedup: `message.id` (message), `webhookEventId`
(non-message). Batch: `events.length ≥ 1`; per-event failure logged + skipped, batch still
200 if any event valid.

## 2. konkui → CA Gateway `/v1/line/...`

All paths versioned `/v1`. All carry `X-Api-Secret`; state-changing POST also HMAC
(`X-Signature`/`X-Timestamp`, `InboundSecret`). Errors → `{responseCode, responseMesg}`
with the domain code enum (addendum).

### P0 — ownership + profile + inbound content

```
POST   /v1/line/users/{userId}/claim       body: { "ownerSystem": "konkui", "claimedAt": "ISO8601" }   idempotent
DELETE /v1/line/users/{userId}/claim       release ownership (on contact hard-delete; NOT on unfollow)
GET    /v1/line/users/{userId}/claim       → { "claimed": true, "ownerSystem": "konkui" }
GET    /v1/line/users/{userId}/profile     → { "displayName", "pictureUrl", "statusMessage", "language" }
GET    /v1/line/messages/{messageId}/content   → binary stream (Content-Type real, Content-Disposition set)
```

> CA already enriches `displayName`/`pictureUrl` in the webhook (§1), so konkui has the
> profile on the **first** event. `/profile` GET is for refresh + reconciliation.

### P1 — unified outbound send (parity with FB/IG)

```
POST /v1/line/users/{userId}/messages   body: { "messages": [ <LineMessageObject>, ... max 5 ] }   counts as 1 push-quota
POST /v1/line/reply                      body: { "replyToken": "...", "messages": [...] }   free, ≤1 min, one use
```

`LineMessageObject` (discriminated by `type`):

```jsonc
{ "type": "text",     "text": "สวัสดีครับ" }
{ "type": "image",    "originalContentUrl": "https://service.eeccollege.com/files/abc.jpg",
                      "previewImageUrl": "https://service.eeccollege.com/files/abc_preview.jpg" }
{ "type": "video",    "originalContentUrl": "...", "previewImageUrl": "...", "trackingId": null }
{ "type": "audio",    "originalContentUrl": "...", "duration": 5000 }
{ "type": "sticker",  "packageId": "11537", "stickerId": "52002745" }
{ "type": "location", "title": "...", "address": "...", "latitude": 13.7, "longitude": 100.5 }
{ "type": "flex",     "altText": "...", "contents": { /* LINE Flex bubble/carousel JSON */ } }
```

- konkui hosts outbound media (HTTPS URLs); CA relays to LINE.
- **No outbound `file` type** — LINE push has none; files are inbound-only.
- konkui falls back to push when `replyToken` expired.

### P2 — UX + insight

```
POST /v1/line/users/{userId}/loading    body: { "durationSec": 20 }   typing indicator
GET  /v1/line/quota                       → { "type": "limited", "value": 10000 }
GET  /v1/line/quota/consumption           → { "totalUsage": 4213 }
```

### P3 — broadcast (defer until a real consumer)

```
POST /v1/line/multicast    body: { "userIds": [...max 500], "messages": [...] }
POST /v1/line/broadcast    body: { "messages": [...] }
```

Rich-menu, audience/narrowcast, beacon, insights stats: **out of scope** (YAGNI; additive
later if a real consumer appears).

## 3. Error response (universal — root §4)

```jsonc
{ "responseCode": "403", "responseMesg": "BLOCKED_BY_USER" }
```

`responseMesg` carries the domain code enum (addendum) for mappable errors; otherwise a
short human reason. No stack traces, no PII.
