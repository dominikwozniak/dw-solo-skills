---
name: dw-land
description: >-
  You are done with a change: wrap it up and decide whether it is ready to merge. One last thin
  verdict over the whole finished branch, then on your go close it: promote what you name — the
  decision records, the glossary, the gotchas — report the leftovers, archive the change doc, push
  the branch and open its pull request.
argument-hint: "bare for the verdict — your go closes it and opens the PR · close to trust the diff and close at once · reject to archive a turned-down idea with its reason"
---

# dw-land — one thin verdict, then keep what you name

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
  "ran it" is spoken aloud, never written up as settled. Read the rung off the boxes rather than
  deriving it again: a ticked task names in its `proof:` what was run against it, and a box ticked
  with nothing run, or carrying no check to run, is `said so` however finished the code looks.

**The completion gate:** read the `## Goal` against the **diff, not the checklist** — an
undelivered result is **not ready**, never "ready with follow-ups"; finish it, or the user amends
the goal. One carve-out: a result only CI can show is **pending on the push**, handed to `dw-ship`.

Close with one line — **ready to merge**, **ready with follow-ups**, or **not ready** and why —
and sort each follow-up: **done now** (inside the goal; phase 2 starts by doing it) ·
**report-open** (outside it; a line in the report and PR body). List every candidate for a new
durable entry — a backlog entry, a decision record, a gotcha, a term — one line each. Then **stop**:
a go writes only the candidates the user names, and a plain go writes none.

### 2. Close — on an explicit go

`dw-next` nominated decisions and terms rather than writing them, and this is the one step that
judges them: **a new record, term or gotcha is written only where the user named it** at the verdict.
Each target is read first — **replace, don't append**, deleting what this change made untrue or made
mechanical, which needs no name:

- **Decisions** — the only gate. Every candidate the user named — a `(nominated)` line, or a call
  the diff made that nobody nominated — is judged against `references/decision-record.md`'s three
  legs **out loud, one at a time**, and a named call that fails them is still not written; the
  whole diff is here, which is why this is where leg one can be answered.
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
    - **fails, or cannot be settled on what the change shows** → no record; one report line names
      the leg that failed, or what would settle it — **never a leg you did not establish**.
- **Vocabulary** — a named term into `CONTEXT.md`, one bullet of at most two lines saying what the
  word means and nothing about why; a term the diff sharpened is rewritten in place, never a second
  definition beside it.
- **Gotchas** — a named trap goes to the routed topic file covering it (the root file only where it
  already keeps a `## Gotchas`) as **one undated bullet of at most two lines** — do or never X, one
  clause of why, a pointer — with what happened and when left in the commit. Where a case added to
  an existing hook, lint rule or check would refuse the trap, add it in this change instead — named
  or not — and delete the prose it replaces, leaving its name. A new hook, script or harness is
  never that cheap: the report names it in one line, never a backlog entry. Cite a mechanism and the diff holds it, or it was prose after all.
- **Stale references** — a `## References` entry the diff made untrue is rewritten where it lives;
  that edits a file the change never touched, so name the exact line and get a yes first.
- **Follow-ups** — the done-now ones are built first; the rest are report lines. A
  `.ai/backlog/<date>-<slug>.md` file (frontmatter `created:`, `source:`, `why-not-now:`,
  `effort:`) only for one the user named. `git rm` any entry the diff completed.
- **Archive** — `git rm` every sibling still beside the doc — a leftover `HANDOFF.md`, a shape-time
  `research.md` — once anything durable in it has been promoted; the receipt is `CHANGE.md` alone.
  Then `git mv .ai/work/<shaped date>-<slug>/ .ai/archive/<today>-<slug>/`; flip to
  `status: landed` with `landed: YYYY-MM-DD`. Trim the doc to a receipt: **the frontmatter, the H1
  and the report's `You get:` line, nothing else** — the worked state lives in the PR `pr:` names.

One commit carries all of it — including a `docs/agents/corpus.baseline.json` re-record where the
repo keeps one, since a promotion that grows the corpus is what the ratchet asks to be shown.

### 3. Open the PR — under the same go

`git push -u origin <branch>`, then `gh pr create`, both per `## Git conventions`; fill the archived
doc's `pr:` as a one-line follow-up commit. Don't wait on CI — opening the PR is what starts it, and
`dw-ship` reads the checks. On the default branch there is no PR — the close was the whole step. No
`origin` at all — say so and stop at the close commit.

The body is `.github/PULL_REQUEST_TEMPLATE.md`, read and filled — `--body` bypasses it, so a body
composed without opening the file is the one that drifts. Its guidance comments come out and its caps
hold; phase 1's report-open follow-ups go under `## What changes`, what phase 1 ran under
`## Test plan`. `## How it flows` is optional — drop the heading with it.

### 4. Report

What was promoted and archived, and each report-open line. Then two lines: **`You get:`** — each
`## Goal` result as what a user can now do — and
**`Backlog +N/−M (now K) · decisions +N · docs +N/−M`**, the entries, records and gotcha or term
bullets the close added and removed. The PR link last. This skill never merges; the squash is
`dw-ship`'s one-way door.

## Modes

- **bare** — the verdict, then stop. A plain "go" or "close" in the conversation runs phases 2–3
  in this same invocation; a hedged reply is not a go.
- **`close`** — the trust shortcut: one-line verdict, then close at once — unless it comes out
  **not ready**, which always stops. Nothing was named, so it writes no new durable entry.
- **`reject`** — the idea was turned down or the work abandoned: skip the verdict, promote what the
  user names, archive with `status: rejected`, `rejected: YYYY-MM-DD` and a
  `## Why rejected` naming what was tried and what killed it — refuse to write one without a
  reason. The archive trim spares that section. Commit it somewhere that survives the branch — a
  short branch off the default one and a PR.

## References

- `references/decision-record.md` — the bar a decision record must clear, and its shape. Read it
  before writing any record.

**Next:** `dw-ship` to merge the PR and clean up, or `dw-shape` for the next change.

$ARGUMENTS
