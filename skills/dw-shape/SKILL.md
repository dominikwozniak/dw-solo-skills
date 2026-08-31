---
name: dw-shape
description: >-
  Turn a request or a finished `dw-grill` conversation into a durable `CHANGE.md` under
  `.ai/work/` — goal, decisions taken, a task checklist, anchors in real files; one per goal,
  never per shippable piece, and depth scales with size.
argument-hint: "What change are we shaping?"
---

# dw-shape — one file, then build

**This skill synthesises; it does not interview.** A still-fuzzy idea goes to `dw-grill` first.

## Where it writes

`.ai/work/<YYYY-MM-DD>-<slug>/CHANGE.md` — tracked, and **on a feature branch only**. **Why:** a
change doc committed to the default branch is what a post-squash rebase resurrects.

1. Resolve the branch: `git rev-parse --abbrev-ref HEAD`, default branch the way `dw-git` does.
   - **On the default branch** — pick by intent: shaping one change to build now →
     `git switch -c <slug>` and shape there; a planning sitting that queues several → one
     `.ai/backlog/<date>-<slug>.md` entry per idea (frontmatter `created:`, an H1 with
     what-and-why, ≤3 lines of context) and no folder in `work/`.
   - **On a feature branch** — record it verbatim; if it already carries a change (the same grep
     `dw-next` uses), continue that file rather than opening a second one.
2. Derive the name, don't invent it:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.sh" dated "<short description>"`. Compare **bare
   slugs** (`slugify.sh undate`) against `work/` and `archive/`; taken means sharpen the
   description and re-derive. An archived twin reading `status: rejected` means **stop**: report
   its `## Why rejected` and shape only if the user says that has changed.

## Workflow

### 1. Read the project, don't assume it

The request (it may arrive as `$ARGUMENTS`); `AGENTS.md` / `CLAUDE.local.md`, else the manifests,
for the test and git conventions; `CONTEXT.md` and `docs/decisions/` where present — a settled
term or decision is not re-litigated; a matching `.ai/backlog/` entry — prior context: create the
folder, `git mv` the entry in as `CHANGE.md`, and expand it in place; the real sibling patterns,
confirmed with Read or grep — these become the anchors. Every resource the conversation pointed
at becomes a `## References` line.

### 2. Size it, then count the scopes

- **Small** — one obvious edit: a goal and one or two checkboxes, no other section.
- **Normal** — a few files, one seam: goal, the decisions taken, 3–6 tasks, anchors.
- **Large** — say so plainly and offer to cut it to the first genuinely shippable piece.

Every size writes short — goal ≤5 lines, one line per decision, task, anchor and reference;
the file is re-read on every resume.

**Scopes:** one, unless the pieces answer to genuinely separate goals — neither file overlap nor
independent shippability splits a change. At N ≥ 2 name the slugs and the one scope each owns, then
ask — **HARD STOP**. On a split, this branch keeps one scope; each sibling becomes a backlog entry.
On a no, the reason goes in `## Decisions` so the question isn't reopened.

### 3. Cut the tasks as thin vertical slices

Each task is a complete narrow path, not a layer — independently committable, leaving the project
green, small enough for a fresh session. Order is a hint, never a gate.

### 4. Write, read back, commit

Write `CHANGE.md` from the shape in `references/CHANGE.md`. Read back the goal, the task list, and
the left-out list with a proposed fate per item (into the change / a one-line backlog entry /
dropped) — **one stop**: granularity and fates are corrected in one reply. Then commit the way
`dw-git` does, everything this shaping wrote staged by name.

Beyond small, prefer a fresh session per change — the committed file is the handoff.

## References

- `references/CHANGE.md` — the exact shape to copy; the tick convention lives in the template.

**Next:** `dw-next` to build it right here, `dw-start` for a worktree instead, or `dw-grill` if the
read-back exposed something still undecided.
