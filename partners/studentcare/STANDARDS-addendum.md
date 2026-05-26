# StudentCare (SC) — Standards Addendum

Platform-specific rules for SC. Inherits everything in the root `STANDARDS.md` and
`envelope/skeleton.md`. This file declares only what is SC-specific.

SC fronts the **StudentCare backend** (a dedicated upstream, not a shared channel). SC
is already on the target pattern; this addendum documents its established behavior.

## Media handling — inline base64 (standing waiver vs root §12)

- **Max attachment size:** 25 MB (`MaxAttachmentSizeBytes` = 26214400 bytes).
- **Max attachments per message:** 5.
- **konkui → SC inbound:** base64 in payload `attachments[].base64Data`.
- **SC → konkui webhook:** base64 in `message.base64Data` for non-text types.
- **konkui consumes SC attachment** via `GET /api/chat/external/attachment/{attachmentId}` (binary stream, `Content-Disposition` SHOULD be set).

> Waiver: root contract prefers metadata + on-demand fetch. SC inlines base64 because its
> attachments cap at 25 MB — inline is simplest and the payload stays small. Documented,
> accepted, no expiry (intrinsic to SC's size cap).

## Scope — role + data ownership (binding)

| Side | Role | Responsibility |
|------|------|----------------|
| **SC** | **Source of truth** | Owns all master data (students, parents, teachers, mapping, conversations, messages, attachments). Resolves lookups by the keys konkui sends. Stores agent replies. Emits inbound webhooks. |
| **konkui** | **Display + transport client** | Sends keys (`stdNo`, `externalUserId`, `threadId`, message bodies) to SC. Receives payloads. Renders to agents. **Nothing more.** |

**konkui MUST NOT:**
- Resolve / derive / cache teacher↔student mapping locally.
- Resolve / store / sync student or parent master data locally.
- Compute domain logic against SC-owned data (e.g., "is this student in this teacher's class") — ask SC.
- Hold its own copy of any field SC is authoritative for, beyond a single render's lifetime.

**konkui MAY:**
- Hold konkui-internal data: agent identity, agent assignment, unread counts, UI feature flags, conversation analytics, render-time caches.
- Echo opaque keys back to SC unchanged (e.g., `threadId`).

If konkui needs data not retrievable via the contract, the fix is **a new SC endpoint** —
never a local konkui table mirroring SC state.

### Data ownership

| Data | Owner | Other side's view |
|------|-------|-------------------|
| Conversation `threadId` (`SC-{int}` / `th_{int}` string) | SC | konkui treats as opaque |
| `message.id`, message body, attachments | SC | konkui dedups on `message.id`, displays |
| `stdNo`, student PII | SC | konkui receives as a key — never resolves to identity |
| Advisor reply text / agent identity | konkui | SC stores, attributes to `advisorId` / `advisorName` only |
| **teacher (advisor) ↔ student (`stdNo`) mapping** | **SC** | konkui sends advisor's `externalUserId` (teacher code), SC resolves to roster. konkui does NOT maintain this mapping. |
| Agent assignment, unread counts, reply approval workflow | konkui | not visible to SC |
| Conversation analytics, response-time metrics | konkui | computed locally |
| Auth of the human reading konkui UI | konkui | JWT not crossed — only HMAC + X-Api-Secret across boundary |

### Implications

- konkui's role is **display only**: send identifiers, receive payloads, render.
- Advisor page in konkui calls `GET /api/advisors/{externalUserId}/students` — SC returns roster + parent info for that teacher.
- Webhook routing inside konkui uses `stdNo` as the conversation key.
- "konkui UI shows no data" troubleshooting: check SC response payload for that key (`stdNo` / `externalUserId`); empty → SC master data; konkui ignores non-empty payload → konkui rendering bug.

### Out-of-scope examples (do NOT add to contract)

- Agent assignment rules.
- Reply moderation / approval workflow before forwarding to SC.
- Notification channel routing (Telegram, web push) on the agent side.
- Localization / time-zone formatting in the agent UI.

## SC-specific envelope leaves

Concrete shapes in `payloads/envelope-schemas.md`. SC-specific notes:

- `source.stdNo` (string, required) — student number; konkui's conversation key.
- `source.senderRole` — open enum `"student" | "parent" | other`; konkui coerces unknown → `"other"` (WARN-logged).
- `replyInfo.threadId` (string, required) — inbound reply context.
- `message.id` is a **string** here (e.g. `"sc-msg-1001"`) even though SC's own
  `GET messages` returns a numeric `id`. Don't confuse the two.

## Event types SC emits

`message` only, today. No `postback` / `follow` / `unfollow` (dedicated backend, no
shared-channel lifecycle). New types = additive contract change.
