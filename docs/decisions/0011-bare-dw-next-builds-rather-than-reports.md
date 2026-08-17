---
decision: 0011
status: active # active | superseded
date: 2026-08-17
---

# 0011 — Bare `dw-next` builds every remaining task; the shaped `CHANGE.md` is the only build gate

## Context

Three invocations stood between a shaped change and its first commit: `dw-start` created the worktree
and stopped, bare `dw-next` reported and stopped, `dw-next go` built one task. Each of the last two
re-asked a question the approved `CHANGE.md` had already answered minutes earlier.

`dw-next`'s own body argued for that arrangement — "reporting is always safe, so that is the default".
The claim is true and was never the constraint. The constraint is that this lane has exactly one
reader, who wrote the checklist, is the only person who could withhold approval, and had already given
it by shaping the change. A checkpoint that only ever confirms what the previous step decided is
ceremony wearing a safety label.

## Decision

The shaped `CHANGE.md` is the single checkpoint for building. Bare `dw-next` reports and then builds
every remaining task, one commit each, stopping only at a decision or an irreversible step. `status`
reports and stops — the resume path. `go` builds exactly one task. `dw-start` claims, installs, and
hands straight to bare `dw-next`, so a shaped change reaches code in one command.

## Trade-off

A safe-by-default read-only entry point was given up, and it was worth something: bare was the mode you
could type without reading the room. Two costs follow from removing it.

The default now mutates the tree, so a mistyped invocation writes commits. The irreversible-step stop
bounds that; it does not eliminate it.

And the cheap resume moved to a word you have to know. Every pointer that said "run `dw-next` bare" had
to be found and rewritten, which is a class of breakage no test in this repo can catch — nothing
asserts skill body content by design. `dw-handoff` was still handing the next session the old
spelling a full review pass after the rename, and it is the skill where the cost is highest: a session
resuming mid-task is the last place to start an unattended build.

The rejected option was an explicit confirmation before building. It would have restored the safety and
reinstated exactly the ceremony this change exists to remove.

## Revisit when

A bare invocation builds something unwanted twice — or this lane grows a second reader, at which point
the approval collapsed into the shape step has to come back out as its own gate.
