---
created: 2026-08-12
source: loop-prose-disagrees-with-the-bodies
---

# `CLAUDE.local.md`'s pre-push gate names `pnpm validate:evals`, which no longer exists

The script was added in 7eb684c and deleted in 1182f7f (`de-ratchet-the-solo-lane`); the gate line in
`## Project specifics` still lists it, so running the documented gate ends in
`Command "validate:evals" not found` and reads as a broken repo. The real gate is the six scripts in
`package.json`. Tracked `AGENTS.md` is right — it points at that block instead of restating it, for
exactly this reason (`.ai/archive/contributing-pre-push-gate-list-is-stale/`). Fix in the main tree: a
worktree cannot write `CLAUDE.local.md`. `.ai/work/own-root-under-budget-and-router/` task 3 already
migrates those bullets into `AGENTS.md` and could absorb this.
