# Tooling — the test runner, the docs gate, CI

`pnpm test` is `node --test`, run from the repo root. `pnpm agents:check` runs
`scripts/check-agents-docs.mjs`, which guards this corpus: the root budget, the Task Router, and the
word ratchet recorded in `docs/agents/corpus.baseline.json`.

CI runs both on every push.

## Gotchas

- **Never let a `pnpm` script swallow a non-zero exit** — a `|| true` tail turns a red suite green and
  CI has no other signal; see `docs/decisions/README.md`.
