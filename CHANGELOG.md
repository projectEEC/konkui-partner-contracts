# Changelog

All notable changes to the standard and to the example integrations.
Format: shared changes under **Standard**, example changes under **examples/<name>**.

## [Unreleased]

### Standard
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
