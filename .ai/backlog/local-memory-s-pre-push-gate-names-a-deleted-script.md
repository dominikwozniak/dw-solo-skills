---
created: 2026-08-12
source: loop-prose-disagrees-with-the-bodies
---

# `CLAUDE.local.md`'s `## Project specifics` names three commands, two of which are gone

Both live on the same two lines, so one pass fixes both — and the fix is the same in each case: stop
restating a list that drifts, and point at `package.json`'s `scripts` block the way tracked `AGENTS.md`
already does (`.ai/archive/contributing-pre-push-gate-list-is-stale/`).

- **`pnpm validate:evals`** — added in 7eb684c, deleted in 1182f7f (`de-ratchet-the-solo-lane`). It is
  named twice: in the routing-evals bullet and in the full pre-push gate, so running the documented
  gate ends in `Command "validate:evals" not found` and reads as a broken repo.
- **`node evals/trigger.ts`** — the paid by-hand tier. The file is gone too; `evals/` holds only
  `cases/`, `README.md` and `routing.ts`. Verified while checking the first one, so **fix the whole
  bullet, not just the one command** — that is how a stale list survives a fix.

Fix in the main tree: a worktree cannot write `CLAUDE.local.md` (the harness refuses the write as
leaving the tree, and it is gitignored so no commit delivers it either).
`.ai/work/own-root-under-budget-and-router/` task 3 migrates these bullets into `AGENTS.md` and should
absorb this — doing it before then means doing it twice.

A second bullet lived here — the Typecheck command line resolving to `evals/*.ts` instead of `none`,
because the hooks took the first backticked span on the line. That is **fixed at the source** in
`setup-lives-in-tracked-agents-md`: `none` is now tested before any backtick extraction, so the line
resolves correctly as written and nothing has to change when it moves.
