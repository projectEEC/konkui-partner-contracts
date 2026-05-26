# Conformance (planned)

Automated checks a partner runs to prove its integration satisfies the standard, so
"conformant?" is answered by a runnable tool, not by manual review.

**Status:** not built yet. Add when partner #3 appears or breaking-change cadence makes
manual review costly (YAGNI until then).

Planned pieces:

- **Spectral ruleset** (`.spectral.yaml`) — lints any partner's `konkui-side-v1.yaml` +
  payloads against the firm rules in `../STANDARDS.md` and `../envelope/skeleton.md`
  (camelCase, error shape, required envelope fields, auth headers, versioned paths).
- **HMAC test vector check** — verifies the partner's webhook signing matches
  `hex(HMAC-SHA256(secret, "{ts}.{rawBody}"))` lowercase (see partner `auth/`).
- **(optional) Pact** — consumer-driven contract tests for the capabilities konkui calls,
  if/when a partner wants runtime verification of their reference API.

Scope note: conformance covers only what konkui defines (the inbound webhook + shared
rules). It does NOT test the partner's own API design — that is the partner's to verify.
