---
created: 2026-08-30
source: slim-the-spine
why-not-now: the spine cut should run in anger for a week first, so the second pass inherits what the consumer repo learns
effort: one sitting — same editing rules, six files
---

# Slim the off-loop skills the way the spine was slimmed

`dw-init` (252 lines), `dw-doctor`, `dw-grain`, `dw-handoff`, `dw-prune`, `dw-unslop` still carry
the pre-slim prose density. Apply the same rules: rationale ≤1 sentence per rule, edge cases the
model handles anyway cut, no mandatory references — mechanics unchanged. Re-record the corpus
baseline after.

Fold in while there: `dw-init` should tell the scaffold to prune `guard-plugin-canon.sh` from the
consumer's settings — outside a repo with symlinked `plugins/` it can never fire, yet the wired
entry pays two jq spawns on every edit forever (its own SKILL.md already admits this at 84-87).
