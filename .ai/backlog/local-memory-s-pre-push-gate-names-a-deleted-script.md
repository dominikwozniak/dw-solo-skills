---
created: 2026-08-12
source: loop-prose-disagrees-with-the-bodies
---

# Two lines in `CLAUDE.local.md`'s `## Project specifics` are wrong, and both must be fixed as they move

Bundled because they are the same section of the same file, both unwritable from a worktree, and
`.ai/work/own-root-under-budget-and-router/` task 3 migrates the whole block into `AGENTS.md` — so one
pass in the main tree fixes both, or carries both mistakes across.

- **The pre-push gate names `pnpm validate:evals`, which no longer exists.** Added in 7eb684c, deleted
  in 1182f7f (`de-ratchet-the-solo-lane`); running the documented gate ends in
  `Command "validate:evals" not found` and reads as a broken repo. The real gate is the scripts block
  in `package.json` — tracked `AGENTS.md` is right to point at it rather than restate it
  (`.ai/archive/contributing-pre-push-gate-list-is-stale/`).
- **The Typecheck command bullet resolves to `evals/*.ts`, not to `none`.** Its value is `none`
  followed by prose that happens to backtick a path, and the hooks take the **first backticked span**
  on the line — so the prose tail is what gets `eval`ed. Latent only because `typecheck-on-stop.sh` is
  not wired here. The moved bullet must carry a bare `none` with the reason somewhere else;
  `bash skills/dw-doctor/scripts/doctor.sh` now prints the resolved value, so it is one command to
  confirm.
