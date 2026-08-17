---
name: dw-handoff
description: >-
  Compact the live session into `.ai/work/<slug>/HANDOFF.md`: how far into the current task you are,
  what is applied but uncommitted, and which dead ends are already ruled out — so the next context
  window resumes mid-task instead of re-deriving it. Explicit-invoke only — you are the one who can
  see the session is about to end.
argument-hint: "bare saves where you are · or name what the next session should focus on"
disable-model-invocation: true
---

# dw-handoff — the middle of a task, saved

`CHANGE.md` already survives a `/clear` at **task** granularity. This skill covers the gap that
leaves — the middle of a task, where a checkbox cannot say which three approaches you already ruled
out — and holds **only** that: decisions belong in `CHANGE.md`, traps in `## Gotchas`, follow-ups in
the backlog.

## Output location

`.ai/work/<slug>/HANDOFF.md`, beside the `CHANGE.md` it describes. `.ai/` is tracked in git.

Find the change by branch, the same way the rest of the loop does:

```
grep -l "^branch: $(git rev-parse --abbrev-ref HEAD)$" .ai/work/*/CHANGE.md 2>/dev/null
```

- **One match** — write beside it.
- **Several** — list them and ask.
- **None** — **stop and write nothing.** A handoff needs a change to attach to; say so and point at
  `dw-shape`. An exploratory session with nothing shaped yet is what that skill is for.
- **Detached HEAD** (the branch resolves to the literal `HEAD`) — say so, list every `CHANGE.md`
  under `.ai/work/` with its recorded `branch:`, and ask which one this belongs to.

**One live handoff per change.** An existing `HANDOFF.md` is overwritten, never appended to — a
second handoff describes a newer moment, and keeping both leaves the next session guessing which one
is current. `dw-next` deletes it once it has ticked the task it described.

## Workflow

### 1. Name the task in flight

Take the change from the grep above and, from its checklist, the task this handoff is about — usually
the first unticked one, but confirm it against what the session actually did rather than assuming.
State it in one line before writing anything, so a wrong guess is caught here.

### 2. Gather what the change doc can't hold

Four things, each grounded in something you can point at — a `file:line`, a command you ran, an error
you saw:

- **How far into the task** you actually are.
- **What is applied but not committed** — from `git status --short` and `git diff --stat`, read, not
  recalled.
- **The dead ends already ruled out**, each with the reason it failed. This is the line that earns
  the file: it is the work the next session would otherwise repeat.
- **The single next concrete move.**

`$ARGUMENTS`, when given, is what the next session should focus on — let it shape that last one.

The goal, the decisions and the task list already live in `CHANGE.md`, so point at them rather than
restating them. Redact any secret that surfaced along the way.

### 3. Write, read back, commit

Write the file, read the four sections back in two or three lines, and **wait**. You are the only one
who knows whether it matches the session, and correcting it now is far cheaper than resuming from a
wrong one.

On confirmation, commit it the way `dw-git` does, staged by name. Committing is load-bearing, not
hygiene: `dw-land` clears a leftover `HANDOFF.md` with `git rm` before archiving the change — and
`git rm` only sweeps tracked files — while a worktree opened by `dw-start` checks out committed
state only.

### 4. Hand over

Say the file is written, then give the next session its one line: run `dw-next status` — it reports
the handoff before anything else and stops there. Bare would report it too and then build the rest of
the list, which is not what a session resuming mid-task wants to walk into.

## The `HANDOFF.md` shape

Four headings, nothing else. Prose, not a form; drop a section that has nothing in it.

```markdown
# Handoff — <slug>

_Task in flight: <the task, verbatim from CHANGE.md>_

## Where I am

## Applied, not committed

## Ruled out

## Next move
```

**Next:** `dw-next status` in the next session — it reads this file first.
