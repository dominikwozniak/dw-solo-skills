---
name: dw-land
description: >-
  Close out a change: one thin verdict over the diff — correct, fits the repo, blast radius, ticked
  boxes actually proven — then, on approval, promote the durable residue to `docs/decisions/`,
  `CONTEXT.md`, `## Gotchas` and the backlog, and delete the change doc. Use when a change is
  finished, or when someone says "land this", "wrap this up", "is this ready to merge", "close this
  out". Prefer this over merging and letting the change doc rot.
argument-hint: "bare for the verdict · close to promote and clean up"
---

# dw-land — one thin verdict, then keep what's worth keeping

Two phases with an explicit gate between them. The verdict is deliberately thin — a last look, not
a review pipeline; if the change deserved scrutiny mid-build, `dw-check` already gave it — and it
is **not a toll gate**: when you already trust the diff, say so and go straight to closing.

The second phase is the reason this skill exists at all. Without it a private repo accumulates stale
change docs _and_ loses the decisions worth keeping — and when you come back after a week, that
durable layer is the only thing working for you.

## What it reads and writes

Reads the diff against the default branch, and `.ai/work/<slug>/CHANGE.md` (found by branch, the same
way `dw-next` finds it — by land time the change is always claimed). Writes to four **tracked,
durable** places — `docs/decisions/<NNNN>-<slug>.md`, `CONTEXT.md`, the `## Gotchas` section of
`CLAUDE.md`, and `.ai/BACKLOG.md` — and then deletes the `CHANGE.md` scaffolding. `.ai/` is tracked
in git; this is the one skill that takes something out of it on purpose.

## Workflow

### 1. Establish what actually changed

- `git diff <default-branch>...HEAD` plus `git log --oneline <default-branch>..HEAD`. Read the default
  branch from `## Git conventions`, don't assume `main`. Prefer `origin/<default-branch>` when it
  exists, falling back to the local ref: a local default branch that has fallen behind makes the
  merge-base older than your branch point, so the diff swallows commits you didn't write.
- Read the `CHANGE.md`: the goal, the ticked tasks, the Notes.
- Read `CONTEXT.md` and `docs/decisions/` if present, so the verdict is against this project's
  established choices rather than a generic standard.

### 2. The verdict — one pass, four questions

One thin pass, all four together, every finding at a real `file:line` you opened — **if you can't
ground it, don't report it.**

- **Correct?** Does it do what the goal said — including the edge case, the error path, the empty
  input?
- **Does it fit?** A pattern used once elsewhere in this repo beats a better pattern used nowhere
  in it.
- **Blast radius?** What else reaches this code — and name every **one-way door** (migration, data
  deletion, renamed public API, changed env var) explicitly as irreversible.
- **Is "done" proven?** A box ticked because the code "looks right" is unproven — say so rather
  than ratifying it; where a cheap check settles it, run the project's own command.

Close with one line — **ready to merge**, **ready with follow-ups** (name them; each becomes a
backlog line in phase 3, and an unnamed follow-up dies with the doc), or **not ready** and why —
then **stop.** You've graded the work; the user decides what happens next.

### 3. Close — only on explicit approval

When the user approves, and only then:

- **Promote the decisions.** Anything from Decisions or Notes that a future session would need and
  couldn't re-derive from the code becomes `docs/decisions/<NNNN>-<slug>.md`, numbered next in
  sequence, from the shape in `references/decision-record.md`. Be strict: a decision earns a record
  only if it was **hard to reverse, surprising, or had a real trade-off**. Most changes produce
  **zero** records, and that's the correct number.
- **Promote the vocabulary.** Any new domain term this change introduced or sharpened goes into
  `CONTEXT.md` as a glossary line. Terms only — no implementation detail. Create the file if it
  doesn't exist.
- **Promote the gotchas.** A trap that cost real time, or repeated, becomes one dated line under
  `## Gotchas` in `CLAUDE.md`, newest first — the local trap, and what to do instead. Same bar as
  decision records: **not every surprise.** A gotchas list that logs every small confusion teaches
  you to stop reading it.
- **Promote the follow-ups.** Every follow-up named in the verdict, plus anything deliberately left
  out, becomes one dated line in `.ai/BACKLOG.md` — newest first, `- [YYYY-MM-DD] what and why`.
  Create the file with a bare `# Backlog` heading if the repo predates the scaffold. Same bar as
  gotchas — **if you wouldn't pick it up within a month, don't write it** — and zero is a normal
  answer.
- **Drop the scaffolding.** Delete `.ai/work/<slug>/` (`git rm -r`). If anything in it still feels
  too valuable to delete, that is the signal it belonged in a record, a gotcha, or the backlog —
  promote it first, then delete.
- **Commit** the promotion and the deletion together, the way `dw-git` does — **on the branch you
  are on.** In a worktree that means the feature branch: the promotion rides the PR, the
  squash-merge carries it to the default branch, and post-merge `main` is already clean.

Then report what was promoted, what was parked, and what was removed — and stop. This skill
deliberately does not push or open anything: shipping is a decision, and it belongs to `dw-ship`.

## Modes

The mode is read from `$ARGUMENTS`. Empty means bare — the verdict never mutates anything, so that is
the default.

- **bare** — the verdict only. Reads and reports; changes nothing.
- **`close`** — assumes the verdict has already been given and approved in this session, and runs
  phase 3. If no verdict has been given yet, give one first — never close blind.

## References

- `references/decision-record.md` — the shape for `docs/decisions/<NNNN>-<slug>.md`, plus the test
  for whether a decision deserves a record at all. Read it before promoting.

**Next:** `dw-ship` to push and merge, or `dw-shape` for the next change.
