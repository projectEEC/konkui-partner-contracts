# Central API (CA) — Standards Addendum

Platform-specific rules for CA. Inherits everything in the root `STANDARDS.md` and
`envelope/skeleton.md`. This file declares only what is CA-specific.

CA fronts a **shared** LINE OA. How CA decides which conversations reach konkui is CA's
design (see "What konkui needs" below).

## Auth cutover

The current single static `X-Api-Key` is **replaced** by the shared scheme: HMAC
(`X-Signature` + `X-Timestamp`) + `X-Api-Secret`, per root §2. Hard
cutover coordinated in one window — konkui accepts both until CA confirms HMAC live, then
drops `X-Api-Key`. Secrets: `WebhookSecret` (CA signs webhook), `InboundSecret` (konkui
signs state-changing POST), `ApiSecret` (every konkui → CA call). See `auth/`.

## Media handling — metadata-only + on-demand fetch (standing waiver vs root §12)

- The webhook envelope carries media **metadata + `message.id`** but **no binary**.
- konkui downloads bytes via `GET /v1/line/messages/{messageId}/content` when an agent opens the conversation.
- Outbound media: konkui hosts files on its own public host and passes HTTPS URLs (`https://{konkui-media-host}/files/...`); CA relays the URL to LINE. These URLs are **publicly fetchable over HTTPS without auth** — LINE's servers fetch `originalContentUrl` / `previewImageUrl` directly, so they must not require a token.

> Waiver: root contract / SC inline base64. CA cannot — LINE media is up to **200 MB**
> (video); inlining base64 in a webhook is unworkable at that size. Metadata + fetch is
> mandatory. No expiry (intrinsic to LINE's media size).

## What konkui needs (you design how)

CA owns its customers (the LINE users). CA decides which of them get connected to a konkui
agent and sends konkui the events for those conversations — the same arrangement as SC
connecting students to konkui agents. konkui provides the agent + the chat surface;
**konkui's own data does not flow into CA.** Who gets connected, and any PII / consent
handling for CA's users, is **CA's responsibility — not konkui's to specify or police.**

To run the agent-side chat, konkui needs CA to expose (shape + method are yours):

- Display info (name, picture) for a connected conversation, so the agent sees who they
  are talking to.
- Inbound messages + media for that conversation (delivered via the webhook envelope;
  media fetched on demand).
- A way to send / reply messages + media back to that customer.
- (nice-to-have) typing indicator, push quota.

Whatever filtering decides which conversations reach konkui is CA's design — but the
*establishment + routing* it keys on must be specified (next section).

## Conversation establishment (CA must specify — the one piece konkui cannot infer)

This is the platform-design piece konkui needs from you, the same way Meta or TikTok define
how an app starts receiving a conversation. On a **shared** OA, konkui cannot guess which LINE
users are its customers — so CA must define, completely, how a LINE user becomes a *konkui*
conversation and how that user's events then reach konkui.

**The requirement (the "space" konkui needs you to fill).** A deterministic, documented
mechanism such that:

1. A LINE user can become *konkui's* conversation on the shared OA, so a konkui agent can chat
   with them. The trigger may be customer-initiated (e.g. the customer reaches the OA through a
   konkui-provided entry point) or CA-initiated — **CA decides which, and documents it.**
2. Once established, `message` / `postback` events for that user **reach konkui's webhook**, and
   events for users that are *not* konkui's (teachers, chatbots, other consumers of the shared
   OA) **do not**.
3. konkui has a way to **signal ownership** for a user when establishment begins on konkui's
   side (e.g. a customer used konkui's entry point), and to **release** it when konkui closes
   the relationship — so your routing has an authoritative source of "this user is konkui's".
4. `follow` / `unfollow` may always fan out to konkui (per `envelope/skeleton.md`); it is the
   rule-2 `message` / `postback` routing that depends on establishment.

**You design the mechanism** — a `connect` / `claim` call konkui makes, a routing table keyed
on your own entry-point attribution, an invite-token exchange, etc. — as long as it satisfies
rules 1–4. Add it to your `api/` spec so konkui can implement against it. (A claim-style call
is the obvious shape; it was left out of the reference `api/ca-side-v1.yaml` precisely because
the choice is yours.)

**What konkui guarantees on its side:** it calls your establish / release signal at the right
moments, dedups inbound on `message.id` / `webhookEventId`, and never treats a user as konkui's
unless your routing says so.

> Why this is the gating item: without it, a shared-OA follower can't be attributed (wrong
> customer gets created), or konkui's own invited customers' messages never reach konkui. It is
> the single piece that blocks a working agent ↔ customer chat — everything else in this folder
> is buildable without further input.

## Error cases konkui needs to tell apart

konkui needs to distinguish these failures to show a useful message instead of a generic
error. Provide a stable `responseMesg` code per case — the names below are a suggestion;
your own naming is fine as long as it's stable:

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

- CA owns: LINE channel token, the LINE webhook URL, and whatever it uses to decide which conversations reach konkui.
- konkui owns: contact identity, conversation state, agent assignment, outbound file hosting.
- No `file` outbound type — LINE push has no file message; files are inbound-only.
