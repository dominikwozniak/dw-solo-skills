---
name: dw-next
description: >-
  The solo lane's build step and its resume point in one skill: report where the active
  `.ai/work/<slug>/CHANGE.md` stands — read from disk, so it survives a `/clear` — then build
  every remaining unticked task, one commit each.
argument-hint: "bare builds every remaining task · status reports and stops · go builds one"
---

# dw-next — where we are, and the next slice

**Everything comes from disk.** Never reconstruct state from the conversation: a `/clear`, a closed
laptop or a week away must change nothing about the answer.

## What it reads and writes

Reads `.ai/work/<date>-<slug>/CHANGE.md` (written by `dw-shape`), a `HANDOFF.md` beside it when a
session left one, and `CONTEXT.md` for the project's terms. Writes code, ticks the checklist,
appends to Notes, and commits. Find the active change by branch, never by guessing:

```
grep -l "^branch: $(git rev-parse --abbrev-ref HEAD)$" .ai/work/*/CHANGE.md 2>/dev/null
```

One match — that's it. Several — list them and ask. **None — there is no change on this branch:**
point at `dw-shape` (or `dw-start` for a worktree) and stop; never invent a task list to have
something to do.

## Workflow

### 1. Report, always

A fixed shape, read from the file:

- **Capsule** — the goal, plus anything in Notes that changes the approach; ≤5 bullets.
- **Tasks** — one line each, tagged `[done]` · `[skipped: <why>]` · `[pending]`; the first
  `[pending]` is the resume point.
- **References** — each entry read or skipped, one line; read what the next task leans on first.
- **Next move** — one action.

A `HANDOFF.md` is read first and leads the report — it holds what a previous session already ruled
out. With `status`, stop here; that is the whole resume path, and it is deliberately cheap.

### 2. Confirm the task still fits

Check the next task against the repo as it is now; propose an amendment rather than building a
stale task. Order is a hint — take a later task when this one is blocked, and say why.

### 3. Build one task — thin, end to end

- **Narrow and complete** — a vertical slice, never a whole layer; a second task is cheaper than a
  sprawling commit.
- **Absorb what you find** — a reversible, related, session-sized discovery is fixed now, as its
  own commit. Only work that exceeds the session or the goal defers: a one-line Notes item, or —
  above that bar — a `.ai/backlog/` file with `why-not-now:` and `effort:`. Never park a gap in
  this change's `## Goal`; shrinking the goal is the user's call.
- **No drive-by edits** — outside the task and its absorbed fixes, touch nothing.
- **Test the way the project does** — failing test first where the task has a real assertion; say
  so where it genuinely doesn't, instead of fabricating one.
- **Follow the anchors, use the project's words** — patterns from the doc, names from `CONTEXT.md`.
- **Promote as you decide** — a decision clearing the decision-record bar (`dw-land` carries it as
  a reference), or a term the glossary lacks, is written to `docs/decisions/` / `CONTEXT.md` in
  this task's commit rather than saved up for the close.
- **Leave it green** — run the tests; lint and typecheck are hook-owned in this lane.

### 4. Tick, note, commit

Flip the box — the tick and skip convention lives in the `CHANGE.md` template — and set
`status: building` on the first tick. `**skip:**` is for a task that stopped being necessary,
never for one that is merely hard. Append to Notes only what a future session needs, one line per
finding — the diff holds the detail. `git rm` a consumed `HANDOFF.md` in the same commit. Commit
the way `dw-git` does: one task, one commit, staged by name.

### 5. Next task, or stop

In `go`, stop after one slice. Bare keeps going until the list is done or a human decision is
genuinely needed — ask at an irreversible step (migration, data deletion, force-push, deploy) or
real ambiguity, and never for confirmations like "ready to commit?".

## Modes

Bare builds every remaining task. `status` reports and writes nothing. `go` builds exactly one.

**Next:** `dw-check` for a fast look mid-way, or `dw-land` once nothing is pending.
$ARGUMENTS
