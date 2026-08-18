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

If called with `status`, stop here. That is the whole resume path, and it is deliberately cheap.

### 2. Confirm the task is still the right one

Before writing code, sanity-check the next task against the repo as it is now. A week of gap, or the
two tasks before it, may have made it wrong, redundant, or already done. If it no longer fits, say so
and propose the amendment rather than building the stale thing.

Order is a hint. If a later task is clearly takeable now and this one is blocked on something outside
your control, take the later one and say why.

### 3. Build one task — thin, end to end

One task at a time, however many the mode allows.

- **Narrow and complete.** A vertical slice through whatever layers it needs, not a whole layer.
  Resist widening scope mid-task; a second task is free, a sprawling commit is not. An idea that
  belongs to a **different change** is one small file in `.ai/backlog/` (an H1 plus `created:`)
  against the two bars `dw-land` states — but **never park a gap in this change's `## Goal`**: that is
  abandonment wearing a queue entry's clothes, the completion gate refuses to close over it, and
  shrinking the goal is never your call alone. It is a new task here, or a `## Goal` the user amends.
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
  **One finding, one line.** You read this file on every invocation, so a note that runs to a paragraph
  is a tax on every resume — and the details are already in the diff and the commit message. If a
  finding genuinely needs more, it has outgrown Notes and belongs where `dw-land` promotes it — a
  decision record, a `CONTEXT.md` term, a gotcha in its topic file — or it is a task here.
- **Clear a `HANDOFF.md` you consumed** — `git rm` it in this same commit. It described the middle of
  the task you just finished, so leaving it behind strands the next session on a state that is gone.
  Anything in it worth keeping goes to Notes first.
- Commit it the way `dw-git` does — the conventions live there, this skill doesn't restate them.
  Stage by name, never `git add -A`. One task, one commit; a `.ai/backlog/` file added while
  building ships in that same commit.

### 5. Report — then the next task, or stop

Say what shipped, what's left, and the next task. In `go`, **stop** there — one slice was the ask.
Bare keeps going: next task, next commit, until the list is done or something needs a human
decision.

## Modes

The mode is read from `$ARGUMENTS`. Empty means bare — and **bare builds**: the shaped `CHANGE.md`
was the checkpoint, so the default finishes it rather than waiting for a second command.

- **bare** — report, then build every remaining task, one commit each, until the list is done or
  something needs a decision. Still **stop** before anything irreversible: a migration, a
  destructive data change, a force-push, a deploy, a published release, a deletion you can't undo
  from git. Ask first, every time. `all` still means the same thing.
- **`status`** — report only, write nothing. The resume path, deliberately cheap.
- **`go`** — report, then build exactly one task.

**Next:** `dw-next` again to resume after a stop — or for the next task in `go`, `dw-check` for a fast look mid-way, or `dw-land` once the boxes are all ticked.
