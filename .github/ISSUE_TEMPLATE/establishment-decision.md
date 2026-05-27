---
name: "Decision — Conversation establishment & ownership"
about: "CA specifies how a LINE user becomes a konkui conversation on the shared OA (the gating decision)."
title: "[Decision] Conversation establishment & ownership model"
labels: ["ca-team", "open-decision", "gating"]
---

> Read `examples/centralapi/STANDARDS-addendum.md` → **"Conversation establishment"** first.
> This is the one piece konkui cannot infer on a shared OA — **you design the mechanism**, konkui
> only states what it needs. Nothing else can go live without this.

## What konkui needs (the requirement — not a prescribed how)

A deterministic, documented mechanism that satisfies rules **1–5** in the addendum. Please
describe the mechanism you'll build and answer each:

1. **Becoming a konkui conversation** — how does a LINE user on the shared OA become *konkui's*?
   Is it customer-initiated (e.g. via a konkui-provided entry point) or CA-initiated? Which, and how?

2. **Routing** — once established, how do you ensure `message` / `postback` for that user reach
   konkui's webhook, and events for users that are *not* konkui's (teachers, chatbots, others) do not?

3. **Ownership signal (establish / release)** — how does konkui tell you it owns a user, and release
   on close? (A `claim`/`connect` call, a routing table keyed on your entry-point attribution, an
   invite-token exchange — your choice.)

4. **Involuntary release (rule 5)** — when *you* end konkui's ownership (teacher takeover, reassign,
   admin close), how is konkui notified so it stops sending? (`released` event, callback, …?)

5. **follow / unfollow** — confirm these always fan out to konkui regardless of establishment.

## Next step

Propose the concrete endpoint(s)/shapes by opening a **PR** that adds them to
`examples/centralapi/api/ca-side-v1.yaml`, so konkui can implement against it.

> ⚠️ Never put real keys / tokens / base URLs in this issue — exchange those out-of-band.
