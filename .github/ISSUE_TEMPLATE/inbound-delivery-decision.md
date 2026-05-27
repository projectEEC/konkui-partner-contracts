---
name: "Decision — Inbound delivery shape"
about: "CA chooses who maps LINE→envelope and enriches the profile."
title: "[Decision] Inbound delivery shape (mapping + profile enrichment)"
labels: ["ca-team", "open-decision", "gating"]
---

> Read `examples/centralapi/README.md` → **"Open decisions" → the inbound-delivery shape**.
> konkui's aggregator consumes the [envelope](../../envelope/skeleton.md) either way — the
> question is **who maps LINE → that envelope and enriches the profile**. Your call; pick what's
> easier for CA.

## Choose one

- [ ] **(a) CA maps + enriches before forwarding** — CA already holds the raw LINE objects + the
  channel token, so konkui receives a clean envelope.
- [ ] **(b) CA forwards raw LINE; konkui maps it at ingest** — less work for CA.

**Why this choice?** (anything about your side that makes one easier?)
<!-- your answer -->

## Fixed regardless of choice

Anything needing the LINE token — **profile refresh, media bytes** — comes from **CA's gateway**,
because konkui has no direct LINE access. So even option (b) relies on your gateway for
profile/content; it only moves the JSON reshaping to konkui.

- [ ] Confirm CA's gateway will expose profile (`GET …/profile`) and inbound media content.

## Related: profile-enrich failure path

If LINE `GET /profile` fails (non-follower / blocked), what should happen — forward with
`displayName`/`pictureUrl` null, drop, or retry?
<!-- your answer -->

> ⚠️ Never put real keys / tokens / base URLs in this issue — exchange those out-of-band.
