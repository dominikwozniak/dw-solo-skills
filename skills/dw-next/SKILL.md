---
name: dw-next
description: >-
  The solo lane's build step and its resume point in one skill. Bare, it reports where the active
  `.ai/work/<slug>/CHANGE.md` stands and what the next unchecked task is — read from disk, so it
  survives a `/clear`. With `go` it builds that task and commits. Use when picking work back up or
  moving it forward, or when someone says "what's next", "where were we", "build the next task",
  "keep going". Prefer this over re-deriving state from scrollback.
argument-hint: "bare to report status · go to build the next task · all to keep going"
---

# dw-next — where we are, and the next slice

Two jobs that are really one, which is why they're one skill: at 4–6 hours a week the question "what
was I doing" and the question "do the next bit" arrive in the same breath. Splitting them would cost
you an extra invocation to learn nothing.

Everything comes from disk. Never reconstruct state from the conversation — the whole point is that a
`/clear`, a closed laptop or a week away changes nothing about the answer.

## What it reads and writes

Reads `.ai/work/<slug>/CHANGE.md` (written by `dw-shape`), plus a `HANDOFF.md` beside it when a
session ended mid-task and left one. Writes code, ticks that file's checkboxes, appends to its Notes,
clears a handoff it has consumed, and commits — plus a file in `.ai/backlog/` for an idea that
belongs to a different change. `.ai/` is tracked in git. Also reads `CONTEXT.md` if the project has
one, for the terms the code being written should be named in.

Find the active change by branch, not by guessing:

```
grep -l "^branch: $(git rev-parse --abbrev-ref HEAD)$" .ai/work/*/CHANGE.md 2>/dev/null
```

- **One match** — that's it.
- **Several** — list them and ask.
- **None — try to claim before pointing anywhere.** In order:
  1. Strip an optional `worktree-` prefix from the branch (the `claude -w` spelling); if the
     remainder equals or contains the slug of a change whose `branch:` is `unclaimed`, offer that
     one — this is how a `claude -w <slug>` session picks up its change without `dw-start`.
  2. Else if exactly **one** unclaimed change exists, offer it — including right here on the
     default branch, for small serial work that never needed a worktree.
  3. Else list the unclaimed changes newest-first and ask — or point at `dw-shape` when there are
     none. **Never claim silently, and never invent a task list** to have something to do.

  Claiming = flip `branch: unclaimed` to the verbatim `git rev-parse --abbrev-ref HEAD` and commit
  that one edit before building — an uncommitted claim is invisible to every other session. If no
  unclaimed change fits but exactly one change sits on another branch, say so and offer it — you
  may simply be on the wrong branch.

- **Detached HEAD** (the branch resolves to the literal `HEAD`) — say so, list every `CHANGE.md`
  under `.ai/work/` with its recorded `branch:`, and ask which one to build. Stop; don't guess.

## Workflow

### 1. Report, always

Whatever the mode, start by stating from the file: the **goal** in one line, which tasks are done,
what the **next unchecked task** is, and anything in Notes that changes how to approach it.

When a `HANDOFF.md` sits beside it, read that one **first** and lead the report with it: a previous
session stopped in the middle of a task, and the approaches it ruled out are exactly the work you
would otherwise repeat. Having no such file is the ordinary case and needs no comment.

If called bare, stop here. That is the whole resume path, and it is deliberately cheap.

### 2. Confirm the task is still the right one

Before writing code, sanity-check the next task against the repo as it is now. A week of gap, or the
two tasks before it, may have made it wrong, redundant, or already done. If it no longer fits, say so
and propose the amendment rather than building the stale thing.

Order is a hint. If a later task is clearly takeable now and this one is blocked on something outside
your control, take the later one and say why.

### 3. Build one task — thin, end to end

One task per invocation unless the mode says otherwise.

- **Narrow and complete.** A vertical slice through whatever layers it needs, not a whole layer.
  Resist widening scope mid-task; a second task is free, a sprawling commit is not. An idea that
  belongs to a **different change** isn't a task here at all — it's one small file in
  `.ai/backlog/` (an H1 plus `created:`), which is how you drop it without losing it. Two things
  are never that file:
  - **A gap in this change's `## Goal`.** The goal is what this change is for; parking a piece of it
    is abandonment wearing a queue entry's clothes, and `dw-land` will refuse to close over it
    anyway. It is a new task in this `CHANGE.md` — or a `## Goal` the user amends to say what the
    change now claims. Never your call alone to shrink it.
  - **Something cheaper to do than to describe.** If doing it costs less than describing it, do it
    now: a fix that fits in a file this task already touched, or that is smaller than the entry
    describing it, is a commit here. The backlog is for work that genuinely waits.
- **Test the way the project does.** Read the test command from `CLAUDE.md` / `CLAUDE.local.md` /
  `AGENTS.md`, else the manifests. Where the project has a real test suite and the task has a
  meaningful assertion, write the failing test first and make it pass — where it genuinely doesn't
  (a config change, a copy edit), say so instead of fabricating a test to look rigorous.
- **Follow the anchors.** The patterns `dw-shape` recorded are the local convention; match them
  rather than importing a generic shape.
- **Use the project's words.** When naming anything a reader will meet — a function, a type, a
  route, a column — take the term from `CONTEXT.md` if it is defined there. A synonym invented at
  the keyboard is a second name for one thing, and it costs a translation on every later read. When
  the task genuinely introduces a term the glossary doesn't have, use it and put it in Notes below —
  that is the line `dw-land` reads to promote it at the end.
- **Leave it green — run the tests, and only the tests.** Lint and typecheck are **hook-owned** in this
  lane: `lint-on-edit` fires on every Write/Edit, `typecheck-on-stop` at the end of the turn. Re-running
  them here would repeat a full pass per task for nothing. The test suite has no hook, so that one is
  yours. If something unrelated was already failing, say so and don't pretend to have fixed it.

### 4. Tick, note, commit

- Flip the task's `- [ ]` to `- [x]` in `CHANGE.md`, and set frontmatter `status: building` if it's
  still `shaping`.
- Append to Notes only what a future session would actually need: a surprise, a dead end, a decision
  taken while building, a term this task had to coin. Not a narration of what the diff already shows.
- **Clear a `HANDOFF.md` you consumed** — `git rm` it in this same commit. It described the middle of
  the task you just finished, so leaving it behind strands the next session on a state that is gone.
  Anything in it worth keeping goes to Notes first.
- Commit it the way `dw-git` does — the conventions live there, this skill doesn't restate them.
  Stage by name, never `git add -A`. One task, one commit; a `.ai/backlog/` file added while
  building ships in that same commit.

### 5. Report and stop

Say what shipped, what's left, and the next task. Then **stop** — a human deciding whether to
continue is a feature at this cadence, not friction.

## Modes

The mode is read from `$ARGUMENTS`. Empty means bare — reporting is always safe, so that is the
default.

- **bare** — report only. The resume path. Writes nothing.
- **`go`** — report, then build exactly one task.
- **`all`** — keep going task by task until the list is done or something needs a decision. Still
  one commit per task, and still **stop** before anything irreversible: a migration, a destructive
  data change, a force-push, a deploy, a published release, a deletion you can't undo from git.
  Ask first, every time, even here.

**Next:** `dw-next` again for the following task, `dw-check` for a fast look mid-way, or `dw-land` once the boxes are all ticked.
