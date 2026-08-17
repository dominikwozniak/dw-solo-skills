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
- [ ] 4. `evals/cases/dw-next.json`: "what's next / where were we" prompts still route — the description keeps the resume story via `status`; corpus baseline only on net growth (aim for a shrink); bump `plugins/dw-solo` + `marketplace.json`.

## Anchors

- `skills/dw-next/SKILL.md:118` — the mode selector being rewritten
- `skills/dw-start/SKILL.md:36` — the prose taken-check to shrink
- `scripts/runtime/worktree.sh:244` — the local-only `show-ref` the absorbed entry names

## Notes

Wave-1 sibling of land-opens-the-pr-and-ship-only-merges and check-delegates-to-codex-by-default;
`marketplace.json` and the corpus baseline conflict across the three, so land sequentially.
