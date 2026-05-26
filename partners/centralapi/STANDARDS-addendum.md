# Central API (CA) — Standards Addendum

Platform-specific rules for CA. Inherits everything in the root `STANDARDS.md` and
`envelope/skeleton.md`. This file declares only what is CA-specific.

CA fronts a **shared** LINE OA → ownership routing is mandatory (see below).

## Auth cutover

The current single `X-Api-Key` (`eec-line-webhook-2026-...`) is **replaced** by the
shared scheme: HMAC (`X-Signature` + `X-Timestamp`) + `X-Api-Secret`, per root §2. Hard
cutover coordinated in one window — konkui accepts both until CA confirms HMAC live, then
drops `X-Api-Key`. Secrets: `WebhookSecret` (CA signs webhook), `InboundSecret` (konkui
signs state-changing POST), `ApiSecret` (every konkui → CA call). See `auth/`.

## Media handling — metadata-only + on-demand fetch (standing waiver vs root §12)

- The webhook envelope carries media **metadata + `message.id`** but **no binary**.
- konkui downloads bytes via `GET /v1/line/messages/{messageId}/content` when an agent opens the conversation.
- Outbound media: konkui hosts files on its public host (`service.eeccollege.com/files/...`, NAS-backed) and passes HTTPS URLs; CA relays the URL to LINE.

> Waiver: root contract / SC inline base64. CA cannot — LINE media is up to **200 MB**
> (video); inlining base64 in a webhook is unworkable at that size. Metadata + fetch is
> mandatory. No expiry (intrinsic to LINE's media size).

## What konkui needs (you design how)

The OA is shared org-wide. These are konkui's **requirements** — the mechanism, routing
rules, and API are CA's to design. konkui does not dictate CA's internal logic.

konkui needs:

- A way to tell CA "this user is now konkui's" and later "release this user" (an
  ownership / claim mechanism — the endpoint shape is yours).
- Message / interaction events delivered **only** for users konkui owns.
- **No profile or PII** (displayName, pictureUrl, …) for users konkui does **not** own —
  avoid over-collection / PDPA exposure on a shared OA.
- Whatever lifecycle signal CA can give so konkui can attach a follower to a pending
  invite and then claim them. (Today konkui used `follow`; the exact signal is CA's call.)
- Ownership that survives CA restarts and is **not** dropped on unfollow (a returning
  customer keeps their owner); released only when konkui explicitly asks.

Once CA can satisfy the above, konkui drops its `LINE outbound-only / drop unknown` hack —
non-customers (teachers, admins, random chatters) no longer reach konkui, fixing the
"wrong new customer" bug at the source. **How** CA achieves this is out of scope here.

## Domain error-code enum (CA returns; konkui maps to Thai UI)

CA returns a stable `responseMesg` code so konkui shows friendly errors, not generic 500:

| Code | Meaning | konkui UI |
|------|---------|-----------|
| `INVALID_USER` | userId not found / not a follower | "ลูกค้าไม่ได้เป็นเพื่อนกับ OA" |
| `BLOCKED_BY_USER` | user blocked the OA | "ลูกค้าบล็อก OA แล้ว" |
| `QUOTA_EXCEEDED` | push quota exhausted | "โควต้าข้อความเต็ม" |
| `REPLY_TOKEN_EXPIRED` | replyToken > 1 min / used | (konkui auto-falls back to push) |
| `CONTENT_EXPIRED` | media content no longer downloadable | "ไฟล์หมดอายุการดาวน์โหลด" |

## CA-specific envelope leaves

Concrete shapes in `payloads/envelope-schemas.md`. CA-specific notes:

- `destination` = OA identifier (`"line-oa-main"`). Future multi-OA: this is the `oaKey`.
- `source.userId` = LINE userId (`U....`). `displayName` + `pictureUrl` **CA enriches**
  via LINE `GET /profile` before forwarding. `statusMessage` / `language` optional enrich.
- `replyToken` (string|null) — on `message` / `postback` only, ~1 min validity.
- `webhookEventId` — LINE's event id; dedup key for non-message events.
- `message.id` — LINE message id; dedup key for message events; CA MUST keep stable across retries.
- `message.type` set: `text | image | video | audio | file | sticker | location`.
  Subtype fields (sticker `packageId`/`stickerId`, location `lat/long`, media
  `contentType`/`fileSize`/`duration`) per `payloads/`.

## Event types CA emits

`message | postback | follow | unfollow`. (Shared-channel lifecycle → `follow`/`unfollow`
exist here, unlike SC.) Group/room sources are **not** forwarded — `source.type` is
`user` only.

## Scope notes

- CA owns: LINE channel token, the LINE webhook URL, profile enrichment, the claimed-user registry.
- konkui owns: contact identity post-claim, conversation state, agent assignment, outbound file hosting.
- No `file` outbound type — LINE push has no file message; files are inbound-only.
