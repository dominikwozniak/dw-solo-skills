---
name: dw-land
description: >-
  You are done with a change: wrap it up and decide whether it is ready to merge. One last thin
  verdict over the whole finished branch, then on your go promote what is worth keeping — the
  decision records, the glossary, the gotchas — file the leftovers, archive the change doc, push
  the branch and open its pull request.
argument-hint: "bare for the verdict — your go closes it and opens the PR · close to trust the diff and close at once · reject to archive a turned-down idea with its reason"
---

# dw-land — one thin verdict, then keep what's worth keeping

Two phases, and the gate between them is your word.

## What it reads and writes

The diff against the default branch — the ref `bash "${CLAUDE_PLUGIN_ROOT}/scripts/base-ref.sh"` prints — plus
the branch's `.ai/work/<date>-<slug>/CHANGE.md` (found by the same grep `dw-next` uses), `CONTEXT.md`
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

`dw-next` promoted terms and gotchas as they happened; **decisions it only nominated**, and this is
the one step that judges them. Each target is read first — **replace, don't append**, deleting what
this change made untrue or made mechanical:

- **Decisions** — the only gate. Every `(nominated)` line, plus anything the diff decided and
  nobody nominated, is judged against `references/decision-record.md`'s three legs **out loud, one
  candidate at a time**; the whole diff is here, which is why this is where leg one can be answered.
  - With `dw-decisions` installed and a candidate in hand, give it the candidate, **the three legs
    verbatim**, and the diff hunks the candidate turns on — it has no shell and cannot see a diff,
    so a leg whose evidence lives in the change is unanswerable unless you pass it. No candidate:
    don't call it. Not installed: judge alone and say so.
  - Every candidate ends in exactly one of four states, and each has a destination:
    - **clears the bar** → a record with `rule:` and `touches:`. Most changes add zero, and that is
      correct.
    - **supersedes an active record** → the new record carries `supersedes:`, and the old one is
      flipped in the same pass.
    - **already decided, nothing changed** → no record. Say which record covers it, in the report.
    - **fails, or cannot be settled on what the change shows** → the line stays in the doc, and
      rides into the archive so the third arrival of the same idea reads as a pattern instead of a
      fresh question. `(nominated)` becomes `(rejected: <leg>)` where a leg actually failed, and
      `(unsettled: <what would settle it>)` where none did — **never a leg you did not establish**.
- **Vocabulary** — new or sharpened terms into `CONTEXT.md`, one bullet of at most two lines saying
  what the word means and nothing about why; rewrite a line, never add a second definition beside it.
- **Gotchas** — a trap that cost real time goes to the routed topic file covering it (the root file
  only where it already keeps a `## Gotchas`) as **one undated bullet of at most two lines** — do or
  never X, one clause of why, a pointer — with what happened and when left in the commit and the
  archived doc. Where a mechanism (hook, lint rule, check) could refuse the trap outright, build or
  backlog that instead of writing prose, and delete the prose it replaces, leaving its name.
- **Stale references** — a `## References` entry the diff made untrue is rewritten where it lives;
  that edits a file the change never touched, so name the exact line and get a yes first.
- **Follow-ups** — do the ones cheaper to do than to file; report-open is the default; a
  `.ai/backlog/<date>-<slug>.md` file (frontmatter `created:`, `source:`, `why-not-now:`,
  `effort:`) only for work that genuinely exceeds the session. `git rm` any entry the diff
  completed.
- **Archive** — `git rm` every sibling still beside the doc — a leftover `HANDOFF.md`, a shape-time
  `research.md` — once anything durable in it has been promoted; the receipt is `CHANGE.md` alone.
  Then `git mv .ai/work/<shaped date>-<slug>/ .ai/archive/<today>-<slug>/`; flip to
  `status: landed` with `landed: YYYY-MM-DD`. Trim the doc to a receipt: delete Goal, Out of scope,
  Anchors and References, and Decisions **except its `(rejected:)` and `(unsettled:)` lines** — keep
  the frontmatter, the H1, the task list as `dw-next` left it, the Notes no target took, and those
  two. A turned-down decision is residue no durable target would take, which is the same reason
  Notes survive the trim.

One commit carries all of it — including a `docs/agents/corpus.baseline.json` re-record where the
repo keeps one, since a promotion that grows the corpus is what the ratchet asks to be shown.

### 3. Open the PR — under the same go

`git push -u origin <branch>`, then `gh pr create`, both per `## Git conventions`; fill the archived
doc's `pr:` as a one-line follow-up commit. Don't wait on CI — opening the PR is what starts it, and
`dw-ship` reads the checks. On the default branch there is no PR — the close was the whole step. No
`origin` at all — say so and stop at the close commit.

The body is `.github/PULL_REQUEST_TEMPLATE.md`, read and filled — `--body` bypasses it, so a body
composed without opening the file is the one that drifts. Its guidance comments come out; phase 1's
report-open follow-ups go under `## What changes`, what phase 1 ran under `## Test plan`.

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
