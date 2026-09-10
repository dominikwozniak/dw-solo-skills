---
name: dw-next
description: >-
  Continue the change you are in the middle of, from where the last session had to leave it: catch
  up on where it stands and what is left, then build every unticked task, one commit each. Its
  state is read back from the doc, never from the conversation, so it survives a `/clear`.
argument-hint: "bare builds every remaining task · status reports and stops · go builds one"
---

# dw-next — where we are, and the next slice

**Everything comes from disk.** Never reconstruct state from the conversation: a `/clear`, a closed
laptop or a week away must change nothing about the answer.

## What it reads and writes

Reads `.ai/work/<date>-<slug>/CHANGE.md` (written by `dw-shape`), a `HANDOFF.md` beside it when a
session left one, any sibling file its `## References` names, `CONTEXT.md` for the project's terms,
and the frontmatter of `docs/decisions/` for the records binding the files a task edits — the
frontmatter, never the folder. Writes code, ticks the checklist,
appends to Notes, and commits. Find the active change by branch, never by guessing:

```
grep -l "^branch: $(git rev-parse --abbrev-ref HEAD)$" .ai/work/*/CHANGE.md 2>/dev/null
```

One match — that's it. Several — list them and ask. **None — there is no change on this branch:**
point at `dw-shape` and stop; never invent a task list to have
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
- **Two fixes on one premise means the premise is the suspect** — a second fix refused by the same
  gate as the first, resting on the same assumption, is evidence about the assumption. Write the
  premise down as one sentence and list every case that gate refused before writing a third fix. The
  premise stays the suspect until one of those cases refutes it — the gate refused it and the
  premise did not hold there — and the list is the evidence either way.
- **No drive-by edits** — outside the task and its absorbed fixes, touch nothing.
- **Test the way the project does** — failing test first where the task has a real assertion; say
  so where it genuinely doesn't, instead of fabricating one. A test that also passes against the
  unfixed code is not a test: `docs/decisions/0013` set the bar at confirming each case by mutating
  the code back to the broken behaviour and watching exactly that case fail.
- **Follow the anchors, use the project's words** — patterns from the doc, names from `CONTEXT.md`.
- **Nominate a decision, never promote one** — a call worth a record becomes one line in the doc's
  `## Decisions` in this task's commit: the call, why, `(nominated)`. `dw-land` judges it, because
  leg one — hard to reverse — is unanswerable from inside task two of six. A term is different:
  `CONTEXT.md` has no bar to clear, so write it now.
- **Read the decisions binding the file you are about to edit** — where `## Decisions` doesn't
  already carry them, read the records' **frontmatter first**, never the whole folder:
  `status: active` plus a `touches:` matching the path, then act on that record's `rule:`
  **verbatim**. A record predating those fields is found by its slug, and its norm is the first
  sentence of its `## Decision` — the one case where you open the record itself. A norm you would
  have to soften to proceed is a reason to stop, not to proceed carefully. **No `docs/decisions/`
  is no layer, not an empty answer**: say which it was.
- **Leave it green** — run the tests; lint and typecheck are hook-owned in this lane.

### 4. Tick, note, commit

**Run the task's `proof:` first, then flip the box** — the tick and skip convention lives in the
`CHANGE.md` template, and there a tick means the named check ran, not that the code got written.
What ran goes in the commit body, named in the prose — never a pasted log. A check something blocks leaves the box open with
one Notes line naming the blocker. A check only the push can run leaves it open too, with a Notes
line saying so — that box is not work left pending, it is the result `dw-land` already carves out
as pending on the push, and it never holds up the hand-off. A task whose line names no check gets one now,
before the tick, since a box nobody can check is the thing this convention exists to refuse. Set
`status: building` on the first tick. `**skip:**` is for a task that stopped being necessary,
never for one that is merely hard. Append to Notes only what a future session needs, one line per
finding — the diff holds the detail. `git rm` a consumed `HANDOFF.md` in the same commit. Commit
per `## Git conventions`: one task, one commit, staged by name.

### 5. Next task, or stop

In `go`, stop after one slice. Bare keeps going until the list is done or a human decision is
genuinely needed — ask at an irreversible step (migration, data deletion, force-push, deploy) or
real ambiguity, and never for confirmations like "ready to commit?".

**Next:** `dw-check` for a fast look mid-way, or `dw-land` once nothing is pending.

$ARGUMENTS
