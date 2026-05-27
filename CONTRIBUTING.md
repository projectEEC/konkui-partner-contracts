# Coordinating on this contract

This repo is the single source of truth for integrating with konkui. Coordinate **here** —
not over email/chat — so everything stays versioned and in one place.

## How to

- **Ask a question / raise an open decision** → open a GitHub **Issue**.
- **Propose how your side will implement, or any change to the contract** → open a
  **Pull Request** editing the relevant file under `examples/<your-team>/`. konkui reviews
  in the PR; `main` requires konkui (CODEOWNERS) approval to merge.
- **Open-ended discussion** → a GitHub Discussion, or an Issue.

## Rules

- **Never put a secret in an Issue, PR, or commit.** Real keys / tokens / base URLs are
  exchanged out-of-band (see each team's `auth/`). The repo holds placeholders only.
- Follow the versioning rule in `STANDARDS.md` — additive change = minor + CHANGELOG entry;
  breaking change = new major.
- OpenAPI specs are auto-linted against `STANDARDS.md` on every PR
  (`.github/workflows/conformance.yml`): keep `https://`, the `{ responseCode, responseMesg }`
  error shape, and `camelCase` fields.

That's it — small on purpose. This is an internal integration contract, not a public program.
