---
change: retire-dw-git-and-dw-start
branch: retire-dw-git-and-dw-start
created: 2026-09-03
status: landed
landed: 2026-09-03
---

# Change — retire `dw-git` and `dw-start`; conventions live in `AGENTS.md`, worktrees in `dw-shape`

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. `scripts/runtime/base-ref.sh` + `scripts/tests/base-ref.test.sh`, symlinked into
      `dw-solo` and `dw-solo-extras`, named in `RUNTIME_SCRIPTS` — additive, green alone
- [x] 2. The conventions block absorbs `dw-git`'s judgment: `templates/AGENTS.md` grows the rules
      no hook checks; root `AGENTS.md` keeps rules at ≤ 119 lines; `docs/agents/git-history.md`
      gains `## Procedures` and a wider router row; `doctor.sh` drops its two `dw-git` strings
- [x] 3. The retirement commit: delete both skills, their symlinks, `evals/cases/dw-git.json`,
      `evals/behaviour/dw-git.json`, `evals/fixtures/git-uncommitted/`, the dw-git backlog entry;
      `dw-shape` absorbs the worktree fork and the bare-lists-backlog step; every "the way `dw-git`
      does" and `dw-start` pointer across skills, README, AGENTS.md, templates, docs/agents,
      CONTEXT.md, the two tests and the loop SVG rewritten; `dw-shape` case file gains a worktree
      positive
- [x] 4. Re-measure routing: `pnpm eval:routing`, fix the live sentence at `evals/README.md:190`,
      append a dated section with the table
- [x] 5. Record and version: `docs/decisions/0021-…`, `dw-solo` 0.7.0 / `dw-solo-setup` 0.2.2 /
      `dw-solo-extras` 0.1.10 in both manifests, corpus baseline re-recorded

## Notes

- Versions: `dw-solo` 0.6.0 → 0.7.0 (two skills gone, one script added), `dw-solo-setup` 0.2.1 →
  0.2.2 (template block, doctor strings), `dw-solo-extras` 0.1.9 → 0.1.10 (four pointers, the
  `base-ref.sh` symlink). Corpus baseline 12135 → 11233 words.
