---
created: 2026-09-06
source: a-docs-drift-reviewer-agent
why-not-now: both wait on dw-docs-drift running in anger for a week — the first only earns its cost if the Task Router turns out too weak to find a repo's doc layer, and the second is the same recommender's output, unjudged
effort: one sitting — two template files, one dw-solo-setup bump, one gate run
---

# The scaffold's doc contract, and the recommender's two unbuilt hooks

Two `templates/` changes that ship together: same plugin bump, same gate, one PR.

- **A declared doc contract in `templates/AGENTS.md`.** `dw-docs-drift` finds a repo's doc layer
  through the `## Task Router` alone. Where that proves too thin — a repo whose Router omits a file
  the docs still assert against — the scaffold grows a block naming what is doc layer and what in
  it is checkable. Do this only on evidence from a real run; a declaration nobody fills is worse
  than a Router that misses one file.
- **The `SessionStart` and `Stop` hooks.** The same
  `/claude-code-setup:claude-automation-recommender` run over `grateful-me-app-v2` that proposed
  the two subagents also proposed a `SessionStart` hook printing the active `CHANGE.md` and a
  `Stop` hook running the cached check. Both were left report-open and neither has been judged
  against what the lane already does — `dw-next` already reports the change doc from disk, so the
  first may be redundant by construction.
