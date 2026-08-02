---
name: dw-land
description: >-
  Close out a change: one thin verdict over the diff — correct, fits the repo, blast radius, ticked
  boxes actually proven — then, on approval, promote the durable residue to `docs/decisions/`,
  `CONTEXT.md`, `## Gotchas` and the backlog, and archive the change doc. Use when a change is
  finished, or when someone says "land this", "wrap this up", "is this ready to merge", "close this
  out". Prefer this over merging and letting the change doc rot.
argument-hint: "bare for the verdict — your go closes it · close to trust the diff and close at once"
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
`CLAUDE.md`, and `.ai/backlog/` (one file per follow-up) — and then moves the `CHANGE.md` scaffolding to
`.ai/archive/<slug>/`, flipping its `status:` to `landed`. `.ai/` is tracked in git; this is the one
skill that takes something out of `work/` on purpose.

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
backlog file in phase 3, and an unnamed follow-up vanishes into the archive unread), or **not
ready** and why —
then **stop.** You've graded the work; the user decides what happens next.

### 3. Close — only on explicit approval

When the user approves — an unambiguous affirmative like "close" or "go", not a hedged "looks
fine, I guess"; wait for a plain one — and only then:

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
  out, becomes one file `.ai/backlog/<slug>.md` — slug from
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.sh" slug "<the follow-up>"`, frontmatter
  `created: YYYY-MM-DD` plus `source: <this change's slug>`, an H1 saying what-and-why in one
  line, at most ~3 lines of context. Findings go by pointer to `.ai/archive/<slug>` — never
  inlined. Create the dir with its `README.md` if the repo predates the scaffold. Same bar as
  gotchas — **if you wouldn't pick it up within a month, don't write it** — and zero is a normal
  answer.
- **Archive the scaffolding.** `git rm` a leftover `HANDOFF.md` first — it described the middle of
  a task, and post-merge it is noise — then `git mv .ai/work/<slug>/ .ai/archive/<slug>/` and, in
  the moved `CHANGE.md`, flip `status:` to `landed` and add `landed: YYYY-MM-DD` plus `pr: "#<n>"`
  when there is one. The archive is history, not guidance — nothing reads it to decide anything
  (`.ai/archive/README.md` says so; create it from that one line if the repo predates the
  scaffold). If something in the doc still feels too valuable to bury, that is the signal it
  belonged in a record, a gotcha, or the backlog — promote it first, then archive.
- **Commit** the promotion and the archive move together, the way `dw-git` does — **on the branch you
  are on.** In a worktree that means the feature branch: the promotion rides the PR, the
  squash-merge carries it to the default branch, and post-merge `main` is already clean.

Then report what was promoted, what was parked, and what was archived — and stop. This skill
deliberately does not push or open anything: shipping is a decision, and it belongs to `dw-ship`.

## Modes

The mode is read from `$ARGUMENTS`. Empty means bare — nothing mutates until the user's go, so that
is the default.

- **bare** — the verdict, then **stop**. An unambiguous go in the conversation — "close", "close
  it", "go" — runs phase 3 in this same invocation; never send the user back for a second slash
  command. A hedged reply is not a go.
- **`close`** — the trust shortcut: the user already trusts the diff, so state the verdict in one
  line and close without waiting for a go. One exception: a verdict that comes out **not ready**
  stops here too — report it and wait; closing over it takes an explicit word from a user who has
  seen it. Never close blind.

## References

- `references/decision-record.md` — the shape for `docs/decisions/<NNNN>-<slug>.md`, plus the test
  for whether a decision deserves a record at all. Read it before promoting.

**Next:** `dw-ship` to push and merge, or `dw-shape` for the next change.
