---
name: dw-land
description: >-
  Close out a finished change and decide whether it is ready to merge: one thin verdict over the
  diff, then on your go promote the durable residue to `docs/decisions/`, `CONTEXT.md`, `##
  Gotchas` and the backlog, archive the change doc, and push the branch and open its PR.
argument-hint: "bare for the verdict — your go closes it and opens the PR · close to trust the diff and close at once · reject to archive a turned-down idea with its reason"
---

# dw-land — one thin verdict, then keep what's worth keeping

Two phases with an explicit gate: a verdict, then — on your word — the closing sweep, the archive
move, and the PR. `dw-ship` merges it.

## What it reads and writes

The diff against the default branch — base and its ref resolved the way `dw-git` does — plus the
branch's `.ai/work/<date>-<slug>/CHANGE.md` (found by the same grep `dw-next` uses), `CONTEXT.md`
and `docs/decisions/`, so the verdict judges against this project's choices. Writes the closing
checklist's targets, moves the change doc to `.ai/archive/`, then pushes and opens the PR.

## Workflow

### 1. The verdict — one pass, four questions

Read the diff yourself — never delegate this pass; mid-build scrutiny was `dw-check`'s job. Every
finding sits at a real `file:line` you opened, and when you already trust the diff, say so and go
straight to closing.

- **Correct?** — the goal's behaviour, plus the edge case, the error path, the empty input.
- **Does it fit?** — a pattern used once elsewhere in this repo beats a better one used nowhere.
- **Blast radius?** — what else reaches this code; name every one-way door (migration, data
  deletion, renamed public API) as irreversible.
- **Is "done" proven?** — name the rung each claim reached: said so · pointed at the line · showed
  the bad case impossible · ran it · reproduced it in the artifact a user gets. A claim short of
  "ran it" is spoken aloud, never written up as settled.

**The completion gate:** read the `## Goal` against the **diff, not the checklist** — an
undelivered result is **not ready**, never "ready with follow-ups"; finish it, or the user amends
the goal. One carve-out: a result only CI can show is **pending on the push**, handed to `dw-ship`.

Close with one line — **ready to merge**, **ready with follow-ups**, or **not ready** and why —
and sort each follow-up: **done now** (phase 2 starts by doing it) · **report-open** (a line in
the report and PR body) · **backlog** (genuinely exceeds the session). Then **stop**: the user
decides what happens next.

### 2. Close — on an explicit go

`dw-next` already promoted decisions and terms as they happened, so most closes only sweep. Each
target is read first — **replace, don't append**, deleting what this change made untrue:

- **Decisions** — anything unpromoted that clears `references/decision-record.md`'s bar; most
  changes add zero records, and that is correct. Flip a superseded record in the same pass.
- **Vocabulary** — new or sharpened terms into `CONTEXT.md`, one line each; rewrite a line, never
  add a second definition beside it.
- **Gotchas** — a trap that cost real time goes to the routed topic file covering it (the root
  file only where it already keeps a `## Gotchas`) — and where a mechanism (hook, lint rule,
  check) could refuse the trap outright, build or backlog that instead of writing prose.
- **Stale references** — a `## References` entry the diff made untrue is rewritten where it lives;
  that edits a file the change never touched, so name the exact line and get a yes first.
- **Follow-ups** — do the ones cheaper to do than to file; report-open is the default; a
  `.ai/backlog/<date>-<slug>.md` file (frontmatter `created:`, `source:`, `why-not-now:`,
  `effort:`) only for work that genuinely exceeds the session. `git rm` any entry the diff
  completed.
- **Archive** — `git mv .ai/work/<shaped date>-<slug>/ .ai/archive/<today>-<slug>/`; flip to
  `status: landed` with `landed: YYYY-MM-DD`. Trim the doc to a receipt: delete Goal, Decisions,
  Anchors and References — keep the frontmatter, the H1, the task list as `dw-next` left it, and
  the Notes no target took.

One commit carries all of it.

### 3. Open the PR — under the same go

`git push -u origin <branch>`, then `gh pr create`, both the way `dw-git` does; fill the archived
doc's `pr:` as a one-line follow-up commit. Don't wait on CI — opening the PR is what starts it,
and `dw-ship` reads the checks. On the default branch there is no PR — the close was the whole
step. No `origin` at all — say so and stop at the close commit.

### 4. Report

What was promoted, parked and archived — the PR link last. This skill never merges; the squash is
`dw-ship`'s one-way door.

## Modes

- **bare** — the verdict, then stop. A plain "go" or "close" in the conversation runs phases 2–3
  in this same invocation; a hedged reply is not a go.
- **`close`** — the trust shortcut: one-line verdict, then close at once — unless it comes out
  **not ready**, which always stops.
- **`reject`** — the idea was turned down or the work abandoned: skip the verdict, promote what is
  still worth keeping, archive with `status: rejected`, `rejected: YYYY-MM-DD` and a
  `## Why rejected` naming what was tried and what killed it — refuse to write one without a
  reason. The archive trim spares that section. Commit it somewhere that survives the branch — a
  short branch off the default one and a PR.

## References

- `references/decision-record.md` — the bar a decision record must clear, and its shape. Read it
  before writing any record.

**Next:** `dw-ship` to merge the PR and clean up, or `dw-shape` for the next change.

$ARGUMENTS
