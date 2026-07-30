---
name: dw-land
description: >-
  Close out a change: one verdict pass over the diff — correctness, fit with the repo's patterns,
  blast radius, and whether the ticked boxes are actually proven — then, on approval, promote the
  durable residue to `docs/decisions/` and `CONTEXT.md`. Use when a change is finished, or when
  someone says "land this", "wrap this up", "is this ready to merge", "close this out". One gated
  pass instead of a multi-artifact audit pipeline.
argument-hint: "bare for the verdict · close to promote and clean up"
---

# dw-land — one verdict, then keep what's worth keeping

A shared-repo workflow splits quality across several read-only auditors and a separate writer, because
a reviewer who can also patch is tempted to under-report what it couldn't fix. Here, with you reading
every finding before anything happens, that separation buys process and costs sessions — so this is
one skill with two phases and an explicit gate between them. The gate does the work the skill boundary
did: nothing mutates until you say so.

The second phase is the reason this skill exists at all. Without it a private repo accumulates stale
change docs _and_ loses the decisions worth keeping — and when you come back after a week, that
durable layer is the only thing working for you.

## What it reads and writes

Reads the diff against the default branch, and `.ai/work/<slug>/CHANGE.md` (found by branch, the same
way `dw-next` finds it). Writes to four **tracked, durable** places — `docs/decisions/<NNNN>-<slug>.md`,
`CONTEXT.md`, the `## Gotchas` section of `CLAUDE.md`, and `.ai/BACKLOG.md` — and then deletes the
`CHANGE.md` scaffolding. `.ai/` is tracked in git; this is the one skill that takes something out of it
on purpose.

## Workflow

### 1. Establish what actually changed

- `git diff <default-branch>...HEAD` plus `git log --oneline <default-branch>..HEAD`. Read the default
  branch from `## Git conventions`, don't assume `main`. Prefer `origin/<default-branch>` when it
  exists, falling back to the local ref: a local default branch that has fallen behind makes the
  merge-base older than your branch point, so the diff swallows commits you didn't write — and
  `git log <default-branch>..HEAD` lists them outright.
- Read the `CHANGE.md`: the goal, the ticked tasks, the Notes.
- Read `CONTEXT.md` and `docs/decisions/` if present, so the verdict is against this project's
  established choices rather than a generic standard.

### 2. The verdict — one pass, four questions

Weigh all four in a single pass and report them together. Every finding must point at a real
`file:line` you opened — **if you can't ground it, don't report it.** A speculative finding costs
more attention than it saves.

- **Correct?** Does it do what the goal said? Edge cases, error paths, the case where the input is
  empty or the network is down. Anything actually broken.
- **Does it fit?** Compare against the neighbouring code, not against best practice in the abstract.
  A pattern used once elsewhere in this repo beats a better pattern used nowhere in it.
- **What's the blast radius?** What else reaches this code. And specifically the **one-way doors**:
  migrations, data deletions, renamed public APIs, changed env vars or secrets, anything a released
  build depends on. Name each one explicitly as irreversible.
- **Is "done" proven?** For each ticked task, is there evidence — a test that runs, output you saw,
  a check you executed? A box ticked because the code "looks right" is unproven; say so plainly rather
  than ratifying it. Where a cheap check would settle it, run the project's own command and report the
  real output.

Close with one line: **ready to merge**, **ready with follow-ups**, or **not ready** and why. If it is
_ready with follow-ups_, **name them** — each one is a line phase 3 parks in `.ai/BACKLOG.md`, and a
follow-up you don't name is one that dies with the `CHANGE.md` you're about to delete. Then **stop.** Do
not promote, delete, or open a PR yet — you've just graded the work; the user decides what happens next.
If the verdict is _not ready_, the honest next step is `dw-next` or a fix, not this skill.

### 3. Close — only on explicit approval

When the user approves, and only then:

- **Promote the decisions.** Anything from Decisions or Notes that a future session would need and
  couldn't re-derive from the code becomes `docs/decisions/<NNNN>-<slug>.md`, numbered next in
  sequence, from the shape in `references/decision-record.md`. Be strict: a decision earns a record
  only if it was **hard to reverse, surprising, or had a real trade-off**. Three records per change is
  a sign you're logging activity, not decisions. Often the answer is zero, and that's fine.
- **Promote the vocabulary.** Any new domain term this change introduced or sharpened goes into
  `CONTEXT.md` as a glossary line. Terms only — no implementation detail. Create the file if it
  doesn't exist.
- **Promote the gotchas.** A trap that cost real time, or that you hit here having hit it before, becomes
  one dated line under `## Gotchas` in `CLAUDE.md`, newest first — the local trap, and what to do
  instead. This is the section the next session reads without being asked, which is the whole reason it
  lives in an auto-loaded file. Apply the same bar as decision records: **not every surprise.** It has
  to have repeated, or have cost real time. A gotchas list that logs every small confusion teaches you
  to stop reading it, and that is the only way this fails.
- **Promote the follow-ups.** Every follow-up you named in the verdict, plus anything in Decisions or
  Notes recorded as deliberately left out, becomes one dated line in `.ai/BACKLOG.md` — newest first,
  in the form `- [YYYY-MM-DD] what it is and why it matters`. `dw-init` seeds that file, but a repo
  scaffolded before it existed won't have one: create it with a `# Backlog` heading, one line stating
  the one-month bar below, then the entries — and nothing else. This is the sink the other three don't
  cover: a follow-up is usually neither a hard-to-reverse decision, nor a term, nor a trap, so without
  this step it is deleted along with the `CHANGE.md` two bullets down. Apply the same bar as gotchas —
  **if you wouldn't pick it up within a month, don't write it** — and **zero is a normal answer**.
  Don't write a placeholder or an empty section to show the step ran.
- **Drop the scaffolding.** Delete `.ai/work/<slug>/` (`git rm -r`). It was working state; the durable
  part now lives in the four files above and in the commit history. If anything in it still feels too
  valuable to delete, that is the signal it belonged in a decision record, a gotcha, or the backlog —
  promote it first, then delete.
- **Commit** the promotion and the deletion together, by the project's `## Git conventions`.

### 4. Hand off the PR

Report what was promoted, what was parked in the backlog, and what was removed. Then stop: this skill
deliberately does not push or open anything — shipping is a decision, not a step. Merging, or opening a
PR with `gh pr create` if this project uses them, is the user's call.

**Next:** `dw-git` to commit and push what's left, or `dw-shape` for the next change.

## Modes

The mode is read from `$ARGUMENTS`. Empty means bare — the verdict never mutates anything, so that is
the default.

- **bare** — the verdict only. Reads and reports; changes nothing.
- **`close`** — assumes the verdict has already been given and approved in this session, and runs
  phase 3. If no verdict has been given yet, give one first — never close blind.

## References

- `references/decision-record.md` — the shape for `docs/decisions/<NNNN>-<slug>.md`, plus the test
  for whether a decision deserves a record at all. Read it before promoting.
