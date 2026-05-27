# Changelog

All notable changes to the standard and to the example integrations.
Format: shared changes under **Standard**, example changes under **examples/<name>**.

## [Unreleased]

### Standard
- **Uniform konkui-side webhook response contract (hoisted from the studentcare example).**
  `STANDARDS.md` §4 now requires a machine-readable `errorCode` on every non-2xx and forbids
  returning `2xx` for a failed request. `envelope/skeleton.md` rule 5 spells out the
  success / partial (`failures[]`) / whole-request-failure cases, and adds a shared base
  `errorCode` set so every partner parses konkui's failures the same way. Fixes a divergence
  where the studentcare example mandated never-200 + an error enum while centralapi + the
  skeleton still permitted 200-on-error.
- **Clarified `destination`** in `envelope/skeleton.md` — it is the *source* channel / instance
  id konkui routes on, not the literal target "konkui".
- **Blessed optional event-level leaves** (e.g. `replyToken`, `replyInfo`/`threadId`) in the
  skeleton's "what a partner extends" table — they were already used in examples but had no slot.
- Initial monorepo extraction. Root `STANDARDS.md` + `envelope/skeleton.md` promoted as
  the neutral rulebook, genericized from the first integration (auth, payload, error,
  idempotency, versioning, SLA, logging, forbidden, waiver).
- Added `envelope/skeleton.md` — shared inbound event-envelope shape all integrations fill in.
- Added `conformance/.spectral.yaml` — Spectral ruleset linting a spec against the standard.
- Reframed scope: konkui defines its inbound webhook + envelope + shared rules and STATES
  the capabilities it needs; the integrating system designs its own API + internal
  routing/ownership/follow logic.
- **Made the core neutral** — `STANDARDS.md`, `envelope/skeleton.md`, `conformance/` name
  no specific system; concrete integrations moved under `examples/` (renamed from
  `partners/`) as illustrations only.

### examples/studentcare
- Migrated from standalone `studentcare-konkui-contract` repo (copy, no wire change),
  then re-synced to its v1.3.0 state. System-specific media (25 MB inline) + scope/
  data-ownership in `STANDARDS-addendum.md`.

### examples/centralapi
- Authored from a redesign as a worked example. Replaces a raw-LINE passthrough.
  Firm webhook (`konkui-side-v1.yaml`) + reference API (`ca-side-v1.yaml`, non-binding),
  media waiver (200 MB metadata+fetch), what-konkui-needs requirements, error cases,
  auth cutover. The integrating system designs its own API + routing/ownership.
- Brought `konkui-side-v1.yaml` up to the uniform response contract: `errorCode` +
  `KonKuiErrorCode` base enum, `failures[]` / `accepted` / `deduplicated`, `500`/`503`
  responses, explicit never-200-on-error rule.
- Added open decisions surfaced in design review (ownership revocation, profile-enrich
  failure path, outbound media URL lifetime/privacy, dual-auth cutover precedence) +
  establishment rule 5 (CA notifies konkui on involuntary release).
