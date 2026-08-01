# Backlog

Follow-ups and ideas not being worked on now. Newest first, one line each. The bar: if you would not
pick it up within a month, don't write it. The closing pass parks them here; the shaping step reads
this when opening the next change and deletes the line it takes.

- [2026-08-01] Copy gitignored files (`.env*`) into fresh worktrees: seed a `.worktreeinclude`
  (gitignore syntax) via `dw-init`'s template payload, and teach `worktree.sh create` to copy
  matching files — the native file only covers `claude -w` worktrees
  (code.claude.com/docs/en/worktrees.md), not `git worktree add`. Shape it via `/dw-shape` — a good
  first real run of the loop.
- [2026-08-01] A "shared repo" placement option in `dw-init`: when two people knowingly use these
  skills in one repo, `## Git conventions` (and maybe `## Workflow`) belong in tracked `CLAUDE.md`
  rather than `CLAUDE.local.md`. Decide after real usage.
- [2026-08-01] Delta evals for the skills (the software-mansion pattern: with/without-skill runs,
  `should_trigger: false` negatives, contains/not_contains assertions) — worth wiring once the skill
  set stabilizes.
