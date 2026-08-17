---
change: start-builds-and-next-builds-by-default
branch: start-builds-and-next-builds-by-default
created: 2026-08-17
status: building # shaping | building | landed | rejected
---

# Change — dw-start flows into the build; dw-next builds by default

## Goal

`dw-start <slug>` ends with tasks built, not with a worktree waiting for a second command: worktree →
claim → install → enter → build every task. Bare `dw-next` reports and then builds all remaining
tasks; `status` is the cheap resume; `go` builds one.

## Decisions

- No extra gate before building — the CHANGE.md approved at shape time is the single checkpoint
  (grill 2026-08-17).
- dw-start invokes dw-next (model-invocable) instead of duplicating the build loop.
- The prose taken-check shrinks to what `worktree.sh`'s own refusals don't cover; its remote-refs
  blind spot is fixed in the script (absorbs `.ai/backlog/start-branch-check-ignores-remote.md` —
  same files open, cheaper to do than to keep describing).

## Tasks

- [x] 1. `skills/dw-next/SKILL.md`: modes — bare = report, then build all remaining tasks; `status` = report and stop; `go` = one task; new argument-hint; unchanged: one commit per task, stop at a decision or an irreversible step.
- [x] 2. `skills/dw-start/SKILL.md`: after claim+install, enter the worktree and invoke dw-next; cut the taken-check prose to the cases the script can't refuse; print the `claude -w <slug>` recipe only when other unclaimed changes remain.
- [x] 3. `scripts/runtime/worktree.sh` create: also refuse when `git ls-remote --heads origin <slug>` finds the branch on origin (best-effort when origin is unreachable); closes the absorbed backlog entry.
- [x] 4. `evals/cases/dw-next.json`: "what's next / where were we" prompts still route — the description keeps the resume story via `status`; corpus baseline only on net growth (aim for a shrink); bump `plugins/dw-solo` + `marketplace.json`.

## Anchors

- `skills/dw-next/SKILL.md:118` — the mode selector being rewritten
- `skills/dw-start/SKILL.md:36` — the prose taken-check to shrink
- `scripts/runtime/worktree.sh:244` — the local-only `show-ref` the absorbed entry names

## Notes

Wave-1 sibling of land-opens-the-pr-and-ship-only-merges and check-delegates-to-codex-by-default;
`marketplace.json` and the corpus baseline conflict across the three, so land sequentially.

Task 4 changed no case file, on purpose. `dw-next` scores 2/4 rank-1 both before and after the
description rewrite — the same two prompts fail identically on `main` (`"where did we leave off on
this"` finds no discriminating term at all; `"what is still unticked…"` loses to `dw-grill` at rank
4, since no description carries "unticked"). Verified by running the eval against a `git archive` of
`main` in a scratch tree: TOTAL 20/30 on both sides. So the rewrite is routing-neutral, and the two
failures are a pre-existing corpus weakness rather than this change's to fix — worth a backlog entry
if the floor ever needs raising above 67%.

An interrupted session left this worktree with its working copy reverted to the pre-claim state while
tasks 1–2 sat in commits and task 3 sat in the index. Recovered with
`git stash push --keep-index` rather than `git restore`, which two guardrails refuse and which would
have destroyed the staged task 3; the noise is `stash@{0}`, droppable once this lands.
