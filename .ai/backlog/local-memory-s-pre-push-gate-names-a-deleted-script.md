---
created: 2026-08-12
source: loop-prose-disagrees-with-the-bodies
---

# `CLAUDE.local.md`'s pre-push gate names `pnpm validate:evals`, which no longer exists

The script was added in 7eb684c and deleted in 1182f7f (`de-ratchet-the-solo-lane`); the gate line in
`## Project specifics` still lists it, so running the documented gate ends in
`Command "validate:evals" not found` and reads as a broken repo. The real gate is the scripts block in
`package.json` — tracked `AGENTS.md` is right to point at it rather than restate it
(`.ai/archive/contributing-pre-push-gate-list-is-stale/`). Fix in the main tree: a worktree cannot
write `CLAUDE.local.md`. `.ai/work/own-root-under-budget-and-router/` task 3 already migrates those
bullets into `AGENTS.md` and could absorb this.

A second bullet lived here — the Typecheck command line resolving to `evals/*.ts` instead of `none`,
because the hooks took the first backticked span on the line. That is **fixed at the source** in
`setup-lives-in-tracked-agents-md`: `none` is now tested before any backtick extraction, so the line
resolves correctly as written and nothing has to change when it moves.
