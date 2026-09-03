---
change: retire-dw-git-and-dw-start
branch: retire-dw-git-and-dw-start
created: 2026-09-03
status: building # shaping | building | landed
---

# Change — retire `dw-git` and `dw-start`; conventions live in `AGENTS.md`, worktrees in `dw-shape`

## Goal

Two skills leave the catalog and nothing the loop relied on goes with them. `dw-git`'s rules are
where every session already reads them — `## Git conventions`, hook-enforced where a regex can
decide — and its one mechanism, the base-ref resolution, is a shipped script three skills call.
`dw-start`'s worktree glue is a fork in `dw-shape`'s step 1, fired only on the literal word
"worktree". 14 → 12 skills, the corpus smaller, the full gate and `eval:routing` green.

## Decisions

- `dw-git` goes on the argument, not a paid control run — everything it says is already in the
  always-loaded block, hook-enforced, or the base-ref snippet; the user's wiki repo already runs so.
- `dw-start` folds into `dw-shape`; `worktree.sh` stays whole — `${CLAUDE_PLUGIN_ROOT}` resolves
  only in a skill body, so a prompt cannot reach the script, and `remove` is what `dw-ship` needs
  a session later where `ExitWorktree` cannot.
- Worktrees stay opt-in, on the user's word — one reader, usually one session; every worktree pays
  an install and the six traps in `docs/agents/worktrees.md`. Same gate `EnterWorktree` uses.
- The base-ref logic becomes `scripts/runtime/base-ref.sh` beside `slugify.sh` — a mechanism kept
  in one place beats three prose copies (0006), and the review diff is where it matters.
- Root `AGENTS.md` sits at 119 of 120 lines, so it keeps _rules_ and the _procedures_ `dw-git`
  carried go to the routed `docs/agents/git-history.md` — a breach moves a topic out, never
  compresses a rule (`docs/agents/README.md`).

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
- [ ] 5. Record and version: `docs/decisions/0021-…`, `dw-solo` 0.7.0 / `dw-solo-setup` 0.2.2 /
      `dw-solo-extras` 0.1.10 in both manifests, corpus baseline re-recorded

## Anchors

- `skills/dw-git/SKILL.md:28-34` — the base-ref snippet `base-ref.sh` reproduces
- `skills/dw-shape/SKILL.md:19-25` — the branch decision the worktree fork joins
- `skills/dw-start/SKILL.md:32-53` — the glue being folded: create, enter, install, shape, recipe
- `scripts/runtime/worktree.sh:326-341` — the origin probe whose env guards `base-ref.sh` copies
- `scripts/validate-manifests.sh:47` — `RUNTIME_SCRIPTS`
- `scripts/tests/worktree.test.sh:1-40` — the throwaway-repo fixture shape for the new test
- `scripts/tests/guard-plugin-canon.test.sh:125-132` — uses `skills/dw-git/SKILL.md` as its real path
- `templates/AGENTS.md:73-84` — the shipped `## Git conventions` block
- `AGENTS.md:100-119` — this repo's block, at the budget's last line
- `docs/agents/git-history.md:1-5` — the routed topic file that takes the procedures
- `evals/README.md:188-191` — the live sentence citing `dw-git` shadowed by `dw-start`

## References

- `~/.claude/plans/zastanawaim-sie-nad-skills-dw-git-nested-patterson.md` — the approved plan this
  change executes, with the full per-file pointer list for task 3
- https://github.com/michaelshimeles/skills/blob/main/AGENTS.md#multi-agent-rules — the
  always-worktree rule this change deliberately does not adopt: it is a many-agents rule
- https://github.com/michaelshimeles/skills/blob/main/new-feature/SKILL.md — leans on the harness's
  native worktree handling; the reason `EnterWorktree` was weighed against `worktree.sh create`
- `../dominikwozniak-wiki/AGENTS.md:90` — the router row `commit, push, PR, rebase, stash → ## Git
conventions`, a repo already running without a git skill

## Notes

- Routing after the retirement: 19/27 = 70% rank-1, up from 21/31 = 68%. Removing `dw-git` (4/5)
  alone would have left 17/26 = 65%, under the floor; the recovery is `dw-shape`'s description
  gaining the words its asks actually use — "write the change doc" — which also won back the
  pre-existing miss "write up … as a change doc". Dropping "turn" from it cost a prompt at once;
  restored. Every other skill's rank-1 is identical to 2026-09-03.
- The four negatives that named `dw-git` as owner were re-owned, not deleted: a plain-git ask now
  routes to nothing, which the eval reads as blank, so each file's near-miss became the sibling
  that reads the same artifact. `dw-land`'s "push it and open the pull request" was load-bearing
  against `dw-git`; with no git skill the closing pass owning that ask is the intended answer.
