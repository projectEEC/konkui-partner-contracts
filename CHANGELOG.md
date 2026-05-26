# Changelog

All notable changes to the partner-contract standard and per-partner contracts.
Format: shared changes under **Standard**, partner changes under **partners/<name>**.

## [Unreleased]

### Standard
- Initial monorepo extraction. Root `STANDARDS.md` + `envelope/skeleton.md` promoted as
  the cross-partner rulebook, genericized from the StudentCare contract (auth, payload,
  error, idempotency, versioning, SLA, logging, forbidden, waiver).
- Added `envelope/skeleton.md` — shared inbound event-envelope shape all partners extend.
- Media handling + scope / data-ownership moved out of the shared rulebook into
  per-partner `STANDARDS-addendum.md`.

### partners/studentcare
- Migrated from standalone `studentcare-konkui-contract` repo (copy, no wire change).
  SC-specific media (25 MB inline) + scope/data-ownership extracted to
  `partners/studentcare/STANDARDS-addendum.md`. Original repo stays live until SC team cutover.

### partners/centralapi
- Authored from `centralapi-konkui-redesign.md`. Replaces raw-LINE passthrough.
  Envelope (`konkui-side-v1.yaml`), gateway P0–P3 (`ca-side-v1.yaml`), media waiver
  (200 MB metadata+fetch), ownership-routing table, domain error enum, auth cutover.
