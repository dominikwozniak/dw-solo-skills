---
name: dw-shape
description: >-
  Turn a request or a finished `dw-grill` conversation into one durable `CHANGE.md` under
  `.ai/work/` — goal, decisions taken, a task checklist, anchors in real files. Depth scales with
  size: a small change gets two checkboxes, not a spec. Read back by `dw-next` after a `/clear`.
  Use when starting work on a private project, or when someone says "shape this", "write this up",
  "let's plan this out". Prefer this over a multi-file spec-and-plan ceremony.
argument-hint: "What change are we shaping?"
---

# dw-shape — one file, then build

The solo lane's whole planning step. It writes **one** `CHANGE.md`: enough to survive a week away
from the project and a `/clear`, and no more. There is no separate spec, no separate plan, no status
table with commit SHAs — those earn their keep when other people read them, and here nobody does.

This skill does **not** interview you. If the idea is still fuzzy, run `dw-grill` first and come back
— synthesis and interrogation are different jobs, and mixing them produces a document arguing with
itself.

## Output location

Write to `.ai/work/<slug>/CHANGE.md`. `.ai/` is tracked in git, so the file survives a `/clear` and a
week-long gap between sessions — but this one is **working scaffolding, not a deliverable**:
`dw-land` archives it to `.ai/archive/<slug>/` at merge after promoting anything durable out of it.
That split is deliberate;
decisions belong in `docs/decisions/`, not in a spec nobody will reopen.

1. **Resolve the branch first — it is the key every other solo skill uses.**
   `git rev-parse --abbrev-ref HEAD`, the primitive the rest of the catalog uses.
   - On the **default branch** (from `## Git conventions`, else
     `git symbolic-ref --short refs/remotes/origin/HEAD`, else `main`): write
     `branch: unclaimed` — the literal sentinel. The change is shaped but not yet owned by a
     branch; `dw-start` or `dw-next` claims it later by flipping this field. Shaping several
     unclaimed changes in one sitting is the plan-session pattern — each gets built later in its
     own worktree and session.
   - On any **other branch**: record the value **verbatim** — shaping on a feature branch is
     shaping and claiming in one step. `dw-next` and `dw-land` find this file by grepping for it,
     so a placeholder left in place orphans the change.
   - **Detached HEAD** — it resolves to the literal `HEAD` (a `git worktree add` without `-b`, a
     bisect, a tag checkout): **say so and ask which branch to record.** Never write `HEAD`.
2. **Don't start a second change on the same claimed branch.** Look for an existing one first:
   `grep -l "^branch: $(git rev-parse --abbrev-ref HEAD)\$" .ai/work/*/CHANGE.md 2>/dev/null`. If one
   turns up, **continue that file** — only open a new change for
   genuinely separate work. Several `unclaimed` changes side by side are normal: that's the queue,
   not a conflict. When unsure, ask.
3. **Derive the slug, don't invent it:**
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.sh" slug "<short description>"`. Same script the
   whole catalog uses, so casing never drifts. (`${CLAUDE_PLUGIN_ROOT}` is the env var Claude Code
   substitutes to this plugin's install dir.) A slug already present in `.ai/work/` **or
   `.ai/archive/`** is taken — the land-time `git mv` would nest into the existing archive folder —
   so make the description more specific and re-derive.

## Workflow

### 1. Read the project, don't assume it

- The request (it may arrive as `$ARGUMENTS`) plus anything settled in the conversation.
- `CLAUDE.md` / `CLAUDE.local.md` / `AGENTS.md` for the test, lint and typecheck commands and the git
  conventions. If none are declared, read the manifests (`package.json` scripts, `Makefile`,
  `pyproject.toml`, …) — their presence is what detects the stack. Never name a command you haven't
  seen.
- `CONTEXT.md` and `docs/decisions/` if the project has them — a term already defined or a decision
  already taken is not up for re-litigation, and reusing the established word is free.
- `.ai/backlog/` if the project has one — `dw-land` parks follow-ups there, one file per idea. An
  entry that matches this request is **prior context, not a fresh idea**: read it before shaping, and
  mention it if the request is narrower than what was parked. Neighbouring entries are also
  candidates, but only offer them; never widen the change on your own.
- The **real sibling patterns** this change should follow. Confirm each with Read or grep; these
  become the anchors.

### 2. Size it, then match the depth to the size

Judge the change honestly, then write accordingly — this is the step that keeps the lane light:

- **Small** (one file, one obvious edit, no new concept): a goal and one or two checkboxes. Skip
  Decisions and Anchors entirely. Do not manufacture ceremony for a rename.
- **Normal** (a few files, one seam): a goal, the decisions actually taken, three to six tasks,
  the anchors.
- **Large** (touches several layers, or you can't see the end): still one file — but say plainly that
  it's large and offer to cut it down to the first genuinely shippable piece, or to split it into
  two shaped changes that can land separately. A change you can't finish is worse than a smaller
  one you can.

### 3. Cut the tasks as thin vertical slices

Each task is a **complete narrow path**, not a layer. "Add the column, the query and the read path
for one field" is a task; "add all the migrations" is not. Each one should be independently
committable, leave the project green, and be small enough that a fresh session could do it alone.

Order them so each builds on the last — but treat that order as a **hint, not a gate**. If task 3 is
obviously doable before task 2, do it. Dependencies here are there to help you pick, never to refuse.

### 4. Write the file, check it back, commit it

Write `CHANGE.md` from the shape in `references/CHANGE.md`. If this change takes an entry from
`.ai/backlog/`, create the folder first (`mkdir -p .ai/work/<slug>` — `git mv` won't), then
**`git mv` the file to `.ai/work/<slug>/CHANGE.md`** and expand it in place — the entry is the
seed, and live work must not also sit in the backlog, or the next `dw-shape` offers you what
you're already building; keep its slug unless the change outgrew it. Then read the goal and the task list back to the
user in a few lines and ask whether the breakdown is right — wrong granularity is much cheaper to fix
now than after two commits. **Wait for that confirmation before anything else.**

On confirmation, **commit the file** — the way `dw-git` does, staged by name, the backlog-file move
in the same commit. This is load-bearing, not hygiene: a worktree checks out committed state
only, so an uncommitted `CHANGE.md` never reaches the session that would build it.

For anything beyond small, prefer a **fresh session per change** — the file you just committed is
the handoff, and a build that starts clean reads it from disk instead of inheriting this
conversation's assumptions.

## The CHANGE shape

`references/CHANGE.md` is the exact shape to copy — frontmatter (`change / branch / created /
status`) plus Goal · Decisions · Tasks · Anchors · Notes. Keep it lean: this is a note to your
future self, not documentation. Anything that is genuinely durable knowledge belongs in
`docs/decisions/` or `CONTEXT.md`, which is what `dw-land` promotes it to.

**Next:** `dw-start` to open the change in its own worktree, `dw-next` to build it right here, or `dw-grill` if the read-back exposed something still undecided.
