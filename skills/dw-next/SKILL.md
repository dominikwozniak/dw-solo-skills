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

Reads `.ai/work/<date>-<slug>/CHANGE.md` (written by `dw-shape`), plus a `HANDOFF.md` beside it when a
session ended mid-task and left one. Writes code, ticks that file's checkboxes, appends to its Notes,
clears a handoff it has consumed, and commits — plus, rarely, a file in `.ai/backlog/` for work that
genuinely exceeds the session (step 3's absorb rule makes doing it now the default). `.ai/` is
tracked in git. Also reads `CONTEXT.md` if the project has
one, for the terms the code being written should be named in.

Find the active change by branch, not by guessing:

```
grep -l "^branch: $(git rev-parse --abbrev-ref HEAD)$" .ai/work/*/CHANGE.md 2>/dev/null
```

- **One match** — that's it.
- **Several** — list them and ask.
- **None** — a change may still be claimable; `references/claiming.md` has the ladder and the rule
  that a claim is committed before any building starts. Read it before pointing anywhere —
  **never claim silently, and never invent a task list** to have something to do.
- **Detached HEAD** (the branch resolves to the literal `HEAD`) — say so, list every `CHANGE.md`
  under `.ai/work/` with its recorded `branch:`, and ask which one to build. Stop; don't guess.

## Workflow

### 1. Report, always

Whatever the mode, start by stating from the file: the **goal** in one line, which tasks are done,
what the **next unchecked task** is, and anything in Notes that changes how to approach it. Where
the file has a `## References` section, list its entries and say which you have read — read the
ones the next task leans on **before** building, and name any you are skipping and why. Those
pointers were given at grill or shape time; a session that ignores them rebuilds that knowledge
from nothing or, worse, without it.

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
  Resist widening scope mid-task; a second task is free, a sprawling commit is not.
- **Absorb what you find; deferring it is the failure mode.** A discovery that is reversible,
  related, and session-sized — a wrong string, a missing guard, a lint rule this bug just earned —
  is **fixed now, as its own commit**, never queued for a later session to rediscover. Only work
  that genuinely exceeds the session or belongs to a different goal defers, and then through
  `dw-land`'s two tiers: a one-line open item in Notes for the land report to carry, or — above
  that bar only — a `.ai/backlog/` file paying the full format `dw-land` states (`why-not-now:` +
  `effort:`). But **never park a gap in this change's `## Goal`**: that is
  abandonment wearing a queue entry's clothes, the completion gate refuses to close over it, and
  shrinking the goal is never your call alone. It is a new task here, or a `## Goal` the user amends.
- **No drive-by edits.** An absorbed fix is a commit with your name on the reason; a hunk smuggled
  into the current task's commit — an opportunistic doc touch-up, a backlog rewrite, a copy tweak
  "while you're in there" — is scope leak the diff reader pays for. Outside the task and the
  absorbed-fix commits, touch nothing.
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
- **A task you decided not to build keeps its box and gains a reason.** Leave the `- [ ]` and append a
  bolded `**skip:** <reason>` clause to its line; from then on every invocation reads that task as not
  remaining — and where this lane says a change is ready "once the boxes are all ticked", a skipped box
  counts as not remaining, so one marker never strands a finished change. This is the on-disk form of
  step 2's amendment, and dropping the task silently is what it replaces — the archive cannot otherwise
  tell a task considered and refused from one no session reached.
- **The marker is for a task that stopped being necessary, never for one that is merely hard.**
  Redundant, already done, or overtaken by an earlier task: those skip. A task standing between the diff
  and this change's `## Goal` does not — step 3 already refuses to park a gap there, and `dw-land`'s
  completion gate reads the **diff, not the checklist**, so a marker buys no close either way. That one
  stays open, or the `## Goal` is something the user amends.
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

## References

- `references/claiming.md` — the ladder for when the branch grep finds no change, and what
  claiming one commits. Read it only in that case; the one-match resume never needs it.

**Next:** `dw-next` again to resume after a stop — or for the next task in `go`, `dw-check` for a fast look mid-way, or `dw-land` once the boxes are all ticked.
