---
name: dw-shape
description: >-
  Turn a request or a finished `dw-grill` conversation into a durable `CHANGE.md` under `.ai/work/` —
  goal, decisions taken, a task checklist, anchors in real files; one per goal, never per shippable
  piece. Depth scales with size: a small change gets two checkboxes, not a spec. Read back by
  `dw-next status` after a `/clear`.
  Use when starting work on a private project, or when someone says "shape this", "write this up",
  "let's plan this out". Prefer this over a multi-file spec-and-plan ceremony.
argument-hint: "What change are we shaping?"
---

# dw-shape — one file, then build

**This skill synthesises; it does not interview.** If the idea is still fuzzy, run `dw-grill` first
and come back — mixing the two produces a document arguing with itself.

## Output location

Write to `.ai/work/<slug>/CHANGE.md` — tracked, so it survives a `/clear`, and **working scaffolding
rather than a deliverable**: `dw-land` archives it at merge, after promoting anything durable out.

1. **Resolve the branch first — it is the key every other solo skill uses.**
   `git rev-parse --abbrev-ref HEAD`, resolving the default branch the way `dw-git` does.
   - On the **default branch**: write `branch: unclaimed` — the literal sentinel. The change is
     shaped but not yet owned; `dw-start` or `dw-next` claims it later by flipping this field.
     Shaping several unclaimed changes in one sitting is the plan-session pattern.
   - On any **other branch**: record the value **verbatim** — shaping on a feature branch is
     shaping and claiming in one step. `dw-next` and `dw-land` find this file by grepping for it,
     so a placeholder left in place orphans the change.
   - **Detached HEAD** — it resolves to the literal `HEAD` (a `git worktree add` without `-b`, a
     bisect, a tag checkout): **say so and ask which branch to record.** Never write `HEAD`.
2. **Don't start a second change on the same claimed branch.** Look for an existing one first:
   `grep -l "^branch: $(git rev-parse --abbrev-ref HEAD)\$" .ai/work/*/CHANGE.md 2>/dev/null`. If one
   turns up, **continue that file** — only open a new change for genuinely separate work. Several
   `unclaimed` changes side by side are normal: that's the queue, not a conflict. When unsure, ask.
3. **Derive the slug, don't invent it:**
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.sh" slug "<short description>"`, so casing never
   drifts. A slug already in `.ai/work/` **or `.ai/archive/`** is taken — the land-time `git mv` would
   nest into the existing archive folder — so sharpen the description and re-derive. **Unless the
   archived doc reads `status: rejected`**: this idea was already tried and dropped, so **stop**,
   report what its `## Why rejected` found and what would justify revisiting, and shape only if the
   user says that has changed. Re-deriving a slug around a rejection is how the work gets done twice.
   A split derives several slugs at once — check those against each other as well as against disk,
   since a sibling isn't written yet to be found.

## Workflow

### 1. Read the project, don't assume it

- The request (it may arrive as `$ARGUMENTS`) plus anything settled in the conversation.
- `CLAUDE.md` / `CLAUDE.local.md` / `AGENTS.md` for the test, lint and typecheck commands and the git
  conventions. If none are declared, read the manifests (`package.json` scripts, `Makefile`,
  `pyproject.toml`, …) — their presence is what detects the stack. Never name a command you haven't
  seen.
- `CONTEXT.md` and `docs/decisions/` if the project has them — a term already defined or a decision
  already taken is not up for re-litigation, and reusing the established word is free.
- `.ai/backlog/` if the project has one — `dw-land` and step 5 below park follow-ups there, one file
  per idea. An entry that matches this request is **prior context, not a fresh idea**: read it before
  shaping, and mention it if the request is narrower than what was parked. Neighbouring entries are
  also candidates, but only offer them; never widen the change on your own.
- The **real sibling patterns** this change should follow. Confirm each with Read or grep; these
  become the anchors.

### 2. Size it, match the depth, then count the scopes

Judge the change honestly, then write accordingly — this is the step that keeps the lane light:

- **Small** (one file, one obvious edit, no new concept): a goal and one or two checkboxes. Skip
  Decisions and Anchors entirely. Do not manufacture ceremony for a rename.
- **Normal** (a few files, one seam): a goal, the decisions actually taken, three to six tasks,
  the anchors.
- **Large** (touches several layers, or you can't see the end): say plainly that it's large, and
  offer to cut it down to the first genuinely shippable piece. If the size comes from _more than one
  scope_ rather than one deep one, that's the split test below, not a sizing call. A change you can't
  finish is worse than a smaller one you can.

**Then count the scopes** — and the answer is **one** unless something forces it higher. Sizing is
depth; this is count, and one change is the default.

- **The test is different goals** — do the pieces answer to separate goals, or is this one goal with
  several parts? Only genuinely unrelated ideas split, and **how the request arrived decides nothing**:
  one sentence, five sentences or a bulleted list, the question is the same.
- **Not independent shippability.** That is a good _task_'s property, and it is the wrong test one
  level up: nearly every pair of edits passes it, so it splits work that shares one goal, one version
  bump and one gate run. **Not "do they touch different files"** either — nearly every change touches
  the README and the manifest, so file overlap is an ordering fact, never a merging one.
- **Both failures are real, and the goal is the only line between them.** One doc carrying two
  unrelated goals is why splitting is a rule at all; one goal cut across two docs is the failure that
  rule causes when it fires too easily. Counting files, tasks or shippable pieces catches neither.
- **At N ≥ 2, name the slugs and the one scope each owns, then ask. HARD STOP** — splitting is the
  user's call, made here and asked once; step 4's read-back confirms the result, not the decision.
- **On yes, write N × `CHANGE.md`**, each **sized on its own terms** — run the ladder above once per
  scope, because splitting is not a licence to manufacture ceremony N times. **Never a stub pointing
  at a sibling**: a change that can't be built without reading another one just failed the test.
  Branch fields: all N `unclaimed` on the default branch; on a claimed branch ask which one is being
  built here and give only that one the branch verbatim — **unless the branch already carries a
  change**, when all N stay `unclaimed`.
- **On no, it stays one change**, and the reason goes in `## Decisions` so the question isn't reopened.
- **A shared anchor is an ordering sentence in the `## Notes`** of whichever lands second — never a
  frontmatter field, which would be the status column this lane exists to avoid.

### 3. Cut the tasks as thin vertical slices

Each task is a **complete narrow path**, not a layer. "Add the column, the query and the read path
for one field" is a task; "add all the migrations" is not. Each one should be independently
committable, leave the project green, and be small enough that a fresh session could do it alone.

Order them so each builds on the last — but treat that order as a **hint, not a gate**. If task 3 is
obviously doable before task 2, do it. Dependencies here are there to help you pick, never to refuse.

### 4. Write the file and check it back

Write `CHANGE.md` from the shape in `references/CHANGE.md`. If this change takes an entry from
`.ai/backlog/`, create the folder first (`mkdir -p .ai/work/<slug>` — `git mv` won't), then **`git mv`
the file** there and expand it in place: the entry is the seed, and live work must not also sit in the
backlog, or the next `dw-shape` offers you what you're already building. Keep its slug unless the
change outgrew it. **A split still seeds one change from one entry**, not N — `git mv` it into
whichever inherits its subject and write the siblings fresh.

Then read the goal and the task list back in a few lines and ask whether the breakdown is right —
wrong granularity is far cheaper to fix now than after two commits. **Wait for that confirmation**,
reading all N back in one pass where there are several.

### 5. Give the left-out list its choice, one item at a time

Everything the shaping deliberately left out — a `dw-grill` playback's closing list, the scopes a split
declined, anything you narrowed away in step 2 — gets an explicit **three-way choice, forced per item**:

- **into this change — the default.** Nothing blocking it and cheaper to do than to describe means it
  is a task in the checklist you just read back, now,
- **into `.ai/backlog/`** — parked as a file, if it clears both bars in that folder's README: **will you
  ever?** and **should it have been done now?** Read them there; they are not restated here,
- **dropped** — said out loud and gone, which is a real answer and often the right one.

**Never file the pile wholesale.** Shape time is when the left-out list is longest and least tested, so
an automatic filer fills the folder with ideas that have survived exactly one conversation — and where
the repo caps it, spends the whole cap on them. Forcing the choice is the point: it is the same move
the land-side gate makes.

**Only the parked ones become files**, one per entry at `.ai/backlog/<slug>.md`, mirroring what `dw-land`
writes rather than inventing a second shape: slug from
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.sh" slug "<short description>"`, frontmatter `created:`
plus `source:` naming this change, an H1 saying what-and-why in one line, at most ~3 lines of context.
A slug already in the folder means bundling into that entry, not a near-duplicate beside it.

### 6. Commit

Once the breakdown is confirmed and the left-out list is resolved, **commit** the way `dw-git` does,
staged by name, with the backlog-file move, any files step 5 parked — and all N files together, since
shaping them was one act. This is load-bearing, not hygiene: a worktree checks out committed state
only, so an uncommitted `CHANGE.md` — or park — never reaches the session that would build it.

For anything beyond small, prefer a **fresh session per change** — the file you just committed is the
handoff, and a build that starts clean reads it from disk instead of inheriting this conversation's
assumptions.

## References

- `references/CHANGE.md` — the exact shape to copy: frontmatter (`change / branch / created / status`)
  plus Goal · Decisions · Tasks · Anchors · Notes. Keep it a note to your future self, not
  documentation; durable knowledge is what `dw-land` promotes to `docs/decisions/` and `CONTEXT.md`.

**Next:** `dw-start` to open the change in its own worktree, `dw-next` to build it right here, or `dw-grill` if the read-back exposed something still undecided.
