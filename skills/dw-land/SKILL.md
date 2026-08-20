---
name: dw-land
description: >-
  Close out a finished change and decide whether it is ready to merge: one thin verdict over the
  diff, then on your go promote the durable residue to `docs/decisions/`, `CONTEXT.md`, `##
  Gotchas` and the backlog, archive the change doc, and push the branch and open its PR.
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

**Name the rung each proof reached** — for that question and for blast radius both. Five, weakest
first: you said so · you pointed at the line · you showed the bad case cannot happen · **you ran it** ·
you reproduced it in the artifact a user gets rather than the tree you edited. Push each safety claim
as far down as is cheap, then **say where it stopped**: a claim short of "you ran it" is spoken aloud,
never written up as settled. Where the repo records how to drive itself — a `VERIFY.md`, or whatever it
keeps — the bottom two rungs cost a read instead of a re-derivation; where it records nothing, that
ceiling is itself part of the answer.

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

When the user approves — an unambiguous affirmative like "close" or "go", not a hedged "looks fine,
I guess"; wait for a plain one — and only then promote, in this order: the **decisions** to
`docs/decisions/`, the **vocabulary** to `CONTEXT.md`, the **gotchas** to wherever this repo keeps
them, the **follow-ups** to `.ai/backlog/`, the **scaffolding** to `.ai/archive/<slug>/` — then one
commit carrying all of it.

`references/promote.md` is that procedure: the bar each target holds to, where a gotcha goes when the
repo has no `## Gotchas` section, and what each target deletes rather than appends. Read it before
writing any of them.

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

- `references/promote.md` — phase 3's procedure: the five targets in order, the bar each one holds
  to, and what each deletes rather than appends. Read it when the go arrives.
- `references/decision-record.md` — the shape for `docs/decisions/<NNNN>-<slug>.md`, the test for
  whether a decision deserves a record at all, and how a record is superseded rather than rewritten.
  Read it before promoting.

**Next:** `dw-ship` to merge the PR and clean up, or `dw-shape` for the next change.
