# Payload Schemas Reference

Quick-reference for every JSON shape on the wire. Authoritative source = `api/*.yaml`. This file is a flat narrative for humans.

## 1. SC `GET /api/chat/threads` → `StudentCareThreadList`

```jsonc
{
  "threads": [
    {
      "threadId": "th_12345",          // string, stable per thread
      "stdNo": "67100001",             // string, student number
      "displayName": "นายสมชาย",        // string|null
      "lastMessage": "ขอบคุณค่ะ",       // string|null, preview
      "lastMessageAt": "2026-05-11T13:45:00Z",  // ISO 8601 UTC|null
      "unreadCount": 2                 // int, ≥0
    }
  ],
  "page": 1,                            // int, 1-based
  "size": 20,                           // int, page size
  "total": 47                           // int, total count across pages
}
```

## 2. SC `GET /api/chat/threads/{threadId}/messages` → `StudentCareMessageList`

```jsonc
{
  "messages": [
    {
      "id": 9001,                      // long, ascending, server-assigned
      "threadId": "th_12345",          // string, matches parent
      "body": "สวัสดีค่ะ",              // string|null, message text
      "isFromTeacher": false,          // bool, true=advisor, false=student/parent
      "senderName": "นายสมชาย",         // string|null
      "sentAt": "2026-05-11T13:45:00Z", // ISO 8601 UTC
      "attachments": [
        {
          "id": 7001,                  // long
          "fileName": "homework.pdf",  // string|null
          "contentType": "application/pdf",  // string|null
          "url": "/api/chat/external/attachment/7001"  // string|null, relative to SC base
        }
      ]
    }
  ]
}
```

Query param `sinceMessageId` (optional long): server returns only messages with `id > sinceMessageId`. Used for incremental polling.

## 3. SC `GET /api/chat/external/attachment/{attachmentId}` → binary stream

- Response body = raw file bytes.
- `Content-Type` = file's actual type (e.g., `application/pdf`).
- `Content-Disposition: attachment; filename="..."` SHOULD be set.
- Max size: 25 MB.

## 4. konkui `POST /webhook/chat/inbound` → `StudentCareInboundRequest`

konkui sends this when an advisor replies in the konkui UI. SC stores the message in the thread.

```jsonc
{
  "externalMessageId": "konkui-msg-9001",  // string|null, konkui's stable ID for dedup
  "threadId": "th_12345",                  // string, required
  "stdNo": "67100001",                     // string|null
  "advisorId": "T001",                     // string|null, teacher ID
  "advisorName": "อ.สมหญิง",                // string|null
  "body": "ตอบกลับครับ",                    // string|null
  "attachments": [
    {
      "fileName": "answer.png",            // string, required
      "contentType": "image/png",          // string, required
      "base64Data": "iVBORw0KGgo..."       // string, required, base64 of file bytes
    }
  ]
}
```

Response — `StudentCareInboundResponse`:

```jsonc
{
  "responseCode": "200",                   // string, mirrors HTTP status
  "responseMesg": "OK",                    // string|null
  "receivedMessageId": 9050                 // long|null, SC's assigned ID
}
```

Constraints:

- `attachments.length` ≤ 5.
- Each `base64Data` decoded size ≤ 25 MB.
- `externalMessageId` SHOULD be present. SC dedups on this; missing = no idempotency guarantee.

## 5. SC `POST /webhooks/studentcare/webhook` → `StudentCareWebhookEnvelope`

SC sends this to konkui when a student/parent sends a new message.

```jsonc
{
  "destination": "konkui",                 // string, target system (always "konkui")
  "events": [
    {
      "type": "message",                   // string, event type — "message" today
      "timestamp": 1747008300000,          // long, unix MILLISECONDS (legacy quirk)
      "source": {
        "type": "user",                          // string
        "userId": "lineUserId_xyz",              // string, external user identifier
        "displayName": "นายสมชาย",                // string|null
        "stdNo": "67100001",                     // string, required
        "senderRole": "student",                 // string|null, "student"|"parent"|"advisor"|"admin"|other → coerced to "other"
        "advisorTeacherNo": "T64008",            // string|null (v1.2+) — TeacherNo of student's advisor; use this for routing
        "advisorTeacherName": "อ.สมศักดิ์ ใจดี"     // string|null (v1.2+) — display label only; NEVER route by name
      },
      "replyInfo": {
        "threadId": "th_12345"             // string, required for inbound reply context
      },
      "message": {
        "id": "sc-msg-1001",               // string, required, used for dedup
        "type": "text",                    // string, "text"|"image"|"file"|...
        "text": "สวัสดีค่ะ",                // string|null, present when type=text
        "fileName": "photo.jpg",           // string|null, present for file/image
        "contentType": "image/jpeg",       // string|null
        "base64Data": "..."                // string|null, base64 file bytes
      }
    }
  ]
}
```

Response from konkui:

```jsonc
{
  "responseCode": "200",
  "responseMesg": "OK",
  "accepted": 3,                // (v1.3+) count fully processed
  "deduplicated": 0,            // (v1.3+) count skipped due to dedup
  "failures": []                // (v1.3+) per-event failures; empty = all OK
}
```

**Partial success (v1.3+)** — batch processed, but ≥1 event failed:

```jsonc
{
  "responseCode": "200",
  "responseMesg": "OK with failures",
  "accepted": 2,
  "deduplicated": 0,
  "failures": [
    {
      "messageId": "sc-msg-1002-1",
      "errorCode": "UNKNOWN_TEACHER",
      "errorMesg": "advisorTeacherNo T99999 not in konkui directory"
    }
  ]
}
```

**Hard failure (v1.3+)** — konkui MUST return matching status. NEVER 200 on failure:

```jsonc
// 401 — HMAC fail
{ "responseCode": "401", "errorCode": "HMAC_INVALID", "responseMesg": "signature mismatch" }

// 400 — schema violation
{ "responseCode": "400", "errorCode": "SCHEMA_VIOLATION", "responseMesg": "events[0].message.id missing" }

// 500 — internal exception
{ "responseCode": "500", "errorCode": "INTERNAL_ERROR", "responseMesg": "dedup store timeout after 5s" }

// 503 — planned/dependency outage (set Retry-After header)
{ "responseCode": "503", "errorCode": "SERVICE_UNAVAILABLE", "responseMesg": "scheduled maintenance" }
```

Constraints:

- `events.length` ≥ 1. Empty array → `400 no events`.
- Each event must have non-empty `message.id`. Missing → event skipped with WARN log; whole batch still 200 if others valid.
- konkui dedups on `message.id` — same ID from previous delivery → `duplicateCount++` but still `200`.
- Unknown `senderRole` → coerced to `"other"` (WARN-logged).

## 6. Error response (universal)

```jsonc
{
  "responseCode": "401",       // string, HTTP status
  "responseMesg": "unauthorized: signature mismatch"  // string, human-readable, no PII
}
```

## Naming quirks

- `responseMesg` (not `responseMessage`) — legacy. Keep stable.
- Webhook envelope `timestamp` = **milliseconds**; `X-Timestamp` HMAC header = **seconds**. Don't confuse.
- `senderRole` enum is open — konkui coerces unknown to `"other"` instead of rejecting. Future-friendly.
- `attachments[].url` in `StudentCareMessage` may be relative; konkui resolves against `StudentCare:BaseUrl`.
- `source.advisorTeacherNo` (v1.2+) is the **routing key** for advisor delivery. May be null if SC could not resolve advisor; konkui should fall back to `stdNo`-based lookup or quarantine the message for ops triage.
- `source.advisorTeacherName` (v1.2+) is human display only. Names are not unique, may collide, and may have whitespace/honorific variations — **do not use for routing decisions**.
