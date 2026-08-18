---
name: dw-land
description: >-
  Close out a change: one thin verdict over the diff — correct, fits the repo, blast radius, ticked
  boxes actually proven — then, on approval, promote the durable residue to `docs/decisions/`,
  `CONTEXT.md`, `## Gotchas` and the backlog, archive the change doc, and push the branch and open
  its PR. Use when a change is finished, or when someone says "land this", "wrap this up", "is this
  ready to merge", "close this out". Prefer this over merging and letting the change doc rot.
argument-hint: "bare for the verdict — your go closes it and opens the PR · close to trust the diff and close at once · reject to archive a turned-down idea with its reason"
---

# dw-land — one thin verdict, then keep what's worth keeping

Two phases with an explicit gate between them: a verdict, then — on your word — promotion, the
archive move, and the PR that carries them. The report ends with a link; `dw-ship` merges it.

## What it reads and writes

Reads the diff against the default branch, and `.ai/work/<slug>/CHANGE.md` (found by branch, the same
way `dw-next` finds it — by land time the change is always claimed). Writes to four **tracked,
durable** places — `docs/decisions/<NNNN>-<slug>.md`, `CONTEXT.md`, wherever this repo keeps its
gotchas (below), and `.ai/backlog/` (one file per follow-up) — and then moves the `CHANGE.md` scaffolding to
`.ai/archive/<slug>/`, flipping its `status:` to `landed`. `.ai/` is tracked in git; this is the one
skill that takes something out of `work/` on purpose. Then it pushes the branch and opens the PR the
way `dw-git` does — untracked output, and the last thing it reports.

## Workflow

### 1. Establish what actually changed

- `git diff <base>...HEAD` plus `git log --oneline <base>..HEAD`, where `<base>` is the default branch
  **and the ref of it** resolved the way `dw-git` does — never `origin/` by reflex. Picking the wrong
  one of the two moves the merge-base off your branch point, and the diff swallows commits you didn't
  write.
- Read the `CHANGE.md`: the goal, the ticked tasks, the Notes.
- Read `CONTEXT.md` and `docs/decisions/` if present, so the verdict is against this project's
  established choices rather than a generic standard.

### 2. The verdict — one pass, four questions

One thin pass, all four together, every finding at a real `file:line` you opened — **if you can't
ground it, don't report it.**

**Read the diff yourself; never delegate this pass.** It is a last look, not a review pipeline —
mid-build scrutiny is `dw-check`'s job, and giving the verdict its own reviewer is the one thing this
step must not grow. It is also **not a toll gate**: when you already trust the diff, say so and go
straight to closing.

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

**The completion gate.** Read the `## Goal` as a list of observable results and check each against
the **diff, not the checklist** — every box can be ticked with a result still unmet. An undelivered
result is **not ready**, never _ready with follow-ups_: parking it is how a change sheds the thing it
existed to do. Two ways out, both the user's call — finish it, or amend the `## Goal` and re-run the
verdict against what the change now claims.

**One carve-out, and it is not an escape hatch.** A result the working tree cannot show — "CI is
green", where the project's workflows only run on a pull request or a push to the default branch — is
not _undelivered_ at land time; it is _unobservable_ at land time, and the closing order (this skill
before `dw-ship`) is what makes it so. Record it in the verdict as **pending on the push**, name the
task that carries it, and hand it to `dw-ship`, which reads the checks on the PR step 4 opens. Such a
change closes **ready to merge** with that line attached — nothing is undelivered — and never _ready
with follow-ups_, which would park the very thing step 4 is about to set running. Anything you could
have run yourself gets no such pass — the bar is that the evidence does not exist yet, never that
gathering it is inconvenient.

Then **stop.** You've graded the work; the user decides what happens next.

### 3. Close — only on explicit approval

When the user approves — an unambiguous affirmative like "close" or "go", not a hedged "looks
fine, I guess"; wait for a plain one — and only then:

**Promotion replaces; it does not append.** For each target below, read what is already there before
writing, and delete what this change supersedes in the same edit. A durable layer that only ever grows
stops being read, which costs you the promotion step entirely — and where a cap exists, appending is
what makes the build fail.

- **Promote the decisions.** Anything from Decisions or Notes that a future session would need and
  couldn't re-derive from the code becomes `docs/decisions/<NNNN>-<slug>.md`, numbered next in
  sequence, from the shape in `references/decision-record.md`. Be strict: a decision earns a record
  only if it was **hard to reverse, surprising, and a real trade-off** — all three, not any one of
  them. Most changes produce **zero** records, and that's the correct number. When a record here
  replaces an older one, flip that one to `status: superseded` with `superseded-by:` in the same
  pass — the reference says how, and nothing else in the loop does it. Take the next number from the
  highest on disk and **never renumber an existing record**: its number is what every
  `superseded-by:` pointer is made of. This is the one target where replacing is a link rather than a
  deletion — a superseded record stays, because why a settled choice was reopened is the most useful
  thing in the folder.
- **Promote the vocabulary.** Any new domain term this change introduced or sharpened goes into
  `CONTEXT.md` as a glossary line. Terms only — no implementation detail. Create the file if it
  doesn't exist. **If the change sharpened a term already defined there, rewrite that line** — two
  definitions of one word is worse than none, and a term the change retired comes out.
- **Promote the gotchas.** A trap that cost real time, or repeated, becomes one entry — the local
  trap, and what to do instead. Same bar as decision records: **not every surprise.** A gotchas list
  that logs every small confusion teaches you to stop reading it.

  **Where it goes, in this order.** An existing `## Gotchas` section — in `AGENTS.md` or `CLAUDE.md`,
  wherever the repo already keeps one — stays the home; newest first. Otherwise the home is the
  **routed topic file** whose subject covers the trap: find the `## Task Router` row that matches and
  append there. **No matching row means creating both halves in the same commit** — the topic file
  under `docs/agents/` and its router row — because a topic file nothing routes to is a file nothing
  reads, and the shipped `agents:check` fails on one.

  Never the root file by default. It is loaded in full every session under a declared budget, so a
  growing list of traps there is the one thing guaranteed to push a real rule out; a routed file is
  read when its subject comes up, which is exactly when a trap about it matters. Two things before you
  write:
  - **Delete what this trap replaces.** A gotcha the change made untrue — the tool is gone, the hook
    is fixed, the flag now defaults the other way — comes out in this edit. Leaving it beside its
    replacement is how the list stops being trustworthy: the reader can no longer tell which half is
    current.
  - **Look for the cousin.** If an existing entry has the same root cause, make this a sub-bullet of
    it rather than another sibling. Where the repo caps the list, a merge is the only way to add to a
    full one, and appending fails the build.

- **Promote the follow-ups.** Every follow-up named in the verdict, plus anything deliberately left
  out, becomes one file `.ai/backlog/<slug>.md` — slug from
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.sh" slug "<the follow-up>"`, frontmatter
  `created: YYYY-MM-DD` plus `source: <this change's slug>`, an H1 saying what-and-why in one
  line, at most ~3 lines of context. Findings go by pointer to `.ai/archive/<slug>` — never
  inlined. If `.ai/backlog/<slug>.md` already exists, merge into it or re-slug with a more
  specific description — **never overwrite it silently**; the existing entry is queued work.
  Create the dir with its `README.md` if the repo predates the scaffold. Two bars, and an entry
  clears both. **Will you ever?** — if you would not pick it up within a month, don't write it.
  **Should it have been done now?** — **nothing blocks it and doing it costs less than describing it
  → the current change, now**, not a file here. That is the default, not a judgement to weigh: a fix
  that fits in a file the change already touched, or that is smaller than the entry describing it, is
  a commit in that change. Only genuinely blocked work — waiting on a decision, a dependency, or a
  change not yet made — earns an entry. Zero is a normal answer. **Then clear what this change
  closed**: an entry whose work the diff just did, or which the change made moot, is `git rm`'d in
  this same commit — and one that survives with fewer bullets than it had gets rewritten to what is
  left. A queue holding finished work reads as a backlog you have stopped believing.
- **Archive the scaffolding.** `git rm` a leftover `HANDOFF.md` first — it described the middle of a
  task, and post-merge it is noise — then `git mv .ai/work/<slug>/ .ai/archive/<slug>/` and, in the
  moved `CHANGE.md`, flip `status:` to `landed` with `landed: YYYY-MM-DD` plus `pr: "#<n>"` where the
  branch already has one (`gh pr view --json number`) — otherwise step 4 fills it, since on the usual
  path the PR does not exist yet. `.ai/archive/README.md` states the convention; create it from that
  one line if the repo predates the scaffold. If `.ai/archive/<slug>/` already exists, stop and pick a
  suffixed destination (`<slug>-2`): `git mv` into an existing directory silently nests the folder
  inside it. If something in the doc still feels too valuable to bury, that is the signal it belonged
  in a record, a gotcha or the backlog — promote it first, then archive.
- **Commit** the promotion and the archive move together, the way `dw-git` does — **on the branch you
  are on.** In a worktree that means the feature branch: the promotion rides the PR, the squash-merge
  carries it to the default branch, and post-merge `main` is already clean.

### 4. Open the PR — under the same go

The go that closed the change opens its PR: nothing here is irreversible — a pushed branch is
deletable, an open PR closeable, the squash `dw-ship`'s — and CI and a second pair of eyes have
nothing to look at until the PR exists. Where the change skipped `dw-check`, the link is the moment to
say so and offer `/codex:review --wait`; the window before the merge is what it is for.

- **On the default branch there is no PR**, so closing the artifacts was the whole step. Point at
  `dw-ship`, whose fast path is the plain `git push` — irreversible, which is why it stays a separate
  command, and the run it starts is the change's first CI.
- **No `origin` at all** → say so and stop at the close commit. Never pretend to have pushed, and don't
  reach for a remote that isn't there: `dw-ship` still owns the local ending (switch, merge, delete).
- Otherwise, both the way `dw-git` does them: `git push -u origin <branch>`, then `gh pr create`.
- **Then record the number**, which step 3 could not know: fill `pr:` in the archived doc and push that
  one-line commit on top, which the squash folds back into the close commit.
- **Don't wait on CI.** **Opening the PR** is what starts the run — the workflows of a repo like this
  one trigger on `pull_request` and on a push to the default branch, so pushing the branch alone
  triggers nothing. `dw-ship` reads the checks; a result the verdict left **pending on the push** is
  named in the report, not watched here.

### 5. Report

What was promoted, what was parked, what was archived — and **the PR link last**, the thing acted on
next. Then stop: this skill does not merge, because the squash is the one-way door and that call is
`dw-ship`'s.

## Modes

The mode is read from `$ARGUMENTS`. Empty means bare — nothing mutates until the user's go, so that
is the default.

- **bare** — the verdict, then **stop**. An unambiguous go in the conversation — "close", "close
  it", "go" — runs steps 3 to 5 in this same invocation, PR included; never send the user back for a
  second slash command. A hedged reply is not a go.
- **`close`** — the trust shortcut: the user already trusts the diff, so state the verdict in one
  line and close — PR and all — without waiting for a go. One exception: a verdict that comes out
  **not ready** stops here too — report it and wait; closing over it takes an explicit word from a
  user who has seen it. Never close blind.
- **`reject`** — the idea was turned down, or the work was abandoned half-built; one status covers
  both. Skip the verdict; there is no diff worth judging. Promote as usual (a rejection still leaves
  follow-ups worth keeping), then archive with `status: rejected`,
  `rejected: YYYY-MM-DD` and `pr:` naming the **closed, unmerged** PR. The doc must carry a
  `## Why rejected` — what was tried, what killed it, what would justify revisiting — and **writing it
  without a reason is refused**: an empty one costs a folder and teaches nothing, which is the whole
  failure this mode exists to prevent. An idea turned down before it was ever shaped has nothing to
  move: write `.ai/archive/<slug>/CHANGE.md` directly, slug derived the way `dw-shape` does so a
  re-shape collides with it. **Commit somewhere that survives**: nothing will be merged here, so a
  record on the rejected branch dies with it — use a short branch off the default one and open a PR
  for that.

## References

- `references/decision-record.md` — the shape for `docs/decisions/<NNNN>-<slug>.md`, the test for
  whether a decision deserves a record at all, and how a record is superseded rather than rewritten.
  Read it before promoting.

**Next:** `dw-ship` to merge the PR and clean up, or `dw-shape` for the next change.
