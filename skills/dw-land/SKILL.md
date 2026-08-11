---
name: dw-land
description: >-
  Close out a change: one thin verdict over the diff — correct, fits the repo, blast radius, ticked
  boxes actually proven — then, on approval, promote the durable residue to `docs/decisions/`,
  `CONTEXT.md`, `## Gotchas` and the backlog, and archive the change doc. Use when a change is
  finished, or when someone says "land this", "wrap this up", "is this ready to merge", "close this
  out". Prefer this over merging and letting the change doc rot.
argument-hint: "bare for the verdict — your go closes it · close to trust the diff and close at once · reject to archive a turned-down idea with its reason"
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
ready** and why.

**A `## Goal` result that isn't delivered is not ready.** Read the goal as a list of observable
results and check each one against the diff. An undelivered result is **not ready** — never **ready
with follow-ups**, because parking it is how a change sheds the thing it existed to do, and the
backlog is where that becomes invisible. **Ticked boxes do not settle this**: every box can be
ticked while a goal result is still unmet, so check the goal against the diff, not against the
checklist. Two ways out, both the user's call: finish it, or amend the `## Goal` to state what the
change now claims and why the rest is gone — then re-run the verdict against the amended goal.

Then **stop.** You've graded the work; the user decides what happens next.

### 3. Close — only on explicit approval

When the user approves — an unambiguous affirmative like "close" or "go", not a hedged "looks
fine, I guess"; wait for a plain one — and only then:

- **Promote the decisions.** Anything from Decisions or Notes that a future session would need and
  couldn't re-derive from the code becomes `docs/decisions/<NNNN>-<slug>.md`, numbered next in
  sequence, from the shape in `references/decision-record.md`. Be strict: a decision earns a record
  only if it was **hard to reverse, surprising, and a real trade-off** — all three, not any one of
  them. Most changes produce **zero** records, and that's the correct number. When a record here
  replaces an older one, flip that one to `status: superseded` with `superseded-by:` in the same
  pass — the reference says how, and nothing else in the loop does it. Take the next number from the
  highest on disk and **never renumber an existing record**: its number is what every
  `superseded-by:` pointer is made of.
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
  inlined. If `.ai/backlog/<slug>.md` already exists, merge into it or re-slug with a more
  specific description — **never overwrite it silently**; the existing entry is queued work.
  Create the dir with its `README.md` if the repo predates the scaffold. Two bars, and an entry
  clears both. **Will you ever?** — if you would not pick it up within a month, don't write it.
  **Should it have been done now?** — if doing it costs less than describing it, do it now: a fix
  that fits in a file the change already touched, or that is smaller than the entry describing it,
  is a commit in that change, not a file here. Zero is a normal answer.
- **Archive the scaffolding.** `git rm` a leftover `HANDOFF.md` first — it described the middle of
  a task, and post-merge it is noise — then `git mv .ai/work/<slug>/ .ai/archive/<slug>/` and, in
  the moved `CHANGE.md`, flip `status:` to `landed` and add `landed: YYYY-MM-DD` plus `pr: "#<n>"`
  when there is one. `reject` moves the same way but stamps `status: rejected` and
  `rejected: YYYY-MM-DD`, `pr:` naming the **closed, unmerged** PR, and the doc must carry a
  `## Why rejected` — what was tried, what killed it, what would justify revisiting. An idea turned
  down before it was ever shaped has nothing to move: write `.ai/archive/<slug>/CHANGE.md` directly,
  slug derived the way `dw-shape` does so a re-shape collides with it. If `.ai/archive/<slug>/`
  already exists, stop and pick a suffixed destination (`<slug>-2`) — `git mv` into an existing
  directory silently nests the folder inside it. `.ai/archive/README.md` states the convention;
  create it from that one line if the repo predates the scaffold. If something in the doc still
  feels too valuable to bury, that is the signal it belonged in a record, a gotcha, or the
  backlog — promote it first, then archive.
- **Commit** the promotion and the archive move together, the way `dw-git` does — **on the branch you
  are on.** In a worktree that means the feature branch: the promotion rides the PR, the
  squash-merge carries it to the default branch, and post-merge `main` is already clean.
  **`reject` is the exception**, because nothing will be merged: a record committed to the rejected
  branch dies with it, and the only way to save it would be shipping the code it rejects. Commit the
  archive and the promotion on a **short branch off the default one** instead, and open a PR for
  that — the rejected branch is then deleted without taking the reasoning with it.

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
- **`reject`** — the idea was turned down. Skip the verdict; there is no diff worth judging. Promote
  as usual — a rejection still leaves follow-ups worth keeping — then archive as `rejected`. **Refuse
  to write the doc without a reason**: an empty `## Why rejected` costs a folder and teaches nothing,
  which is the whole failure this mode exists to prevent.

## References

- `references/decision-record.md` — the shape for `docs/decisions/<NNNN>-<slug>.md`, the test for
  whether a decision deserves a record at all, and how a record is superseded rather than rewritten.
  Read it before promoting.

**Next:** `dw-ship` to push and merge, or `dw-shape` for the next change.
