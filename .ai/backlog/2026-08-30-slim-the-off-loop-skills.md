---
created: 2026-08-30
source: slim-the-spine
why-not-now: the spine cut should run in anger for a week first, so the second pass inherits what the consumer repo learns
effort: one sitting — same editing rules, six files
---

# Slim the off-loop skills the way the spine was slimmed

`dw-init` (268 lines), `dw-doctor`, `dw-grain`, `dw-handoff`, `dw-prune`, `dw-unslop` still carry
the pre-slim prose density. Apply the same rules: rationale ≤1 sentence per rule, edge cases the
model handles anyway cut, no mandatory references — mechanics unchanged. Re-record the corpus
baseline after.

The 2026-09-05 audit named the three fattest passages, so the pass starts there rather than
reading twelve files again. `dw-init`: the `AGENTS.md` rendering and `check-agents-docs.mjs` blocks
are ~55 lines on one topic and belong in a `references/agents-file.md`, and the `VERIFY.md` bullet
describes a file shape in prose where every sibling bullet copies a template verbatim — ship
`templates/VERIFY.md` and the bullet becomes one line. `dw-grain`: the opener argues for ~160 words
why the remedy column is fixed. `dw-doctor`: `## What it reads` enumerates in 40 lines what the
script already does, and its two longest bullets are a quarter of the file.

Fold in while there: `dw-init` should tell the scaffold to prune `guard-plugin-canon.sh` from the
consumer's settings — outside a repo with symlinked `plugins/` it can never fire, yet the wired
entry pays two jq spawns on every edit forever (its own SKILL.md already admits this at 84-87).
