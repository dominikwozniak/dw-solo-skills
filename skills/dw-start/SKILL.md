---
name: dw-start
description: >-
  Open a change in its own worktree and build it: create the worktree and branch, shape the change
  there — from a backlog entry or a fresh description — install, then hand straight to `dw-next`.
  Explicit-invoke only.
argument-hint: "bare lists the backlog · <slug> opens that entry in a worktree · a description shapes it fresh there"
disable-model-invocation: true
---

# dw-start — a worktree per change

Mechanics, then straight into the loop: the change gets its own worktree and branch, is shaped
there, and `dw-next` takes over.

## What it reads and writes

Reads `.ai/backlog/` for the queued ideas. Writes nothing itself — the worktree script does the
mechanics, and `dw-shape` writes the change doc inside the worktree.

## Workflow

### 1. Pick the change

- `$ARGUMENTS` names a backlog entry (matched on the bare slug — `slugify.sh undate`) → that entry
  seeds the change.
- A description with nothing queued behind it → shaped fresh in the worktree.
- Bare → list `.ai/backlog/` newest-first and ask.

### 2. Create and enter

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" create <slug>
```

The bare slug, no date — only the lanes carry dates. Run it from the main tree while it sits on
the default branch. The script refuses every start it can see (a branch or worktree already
existing, locally or on origin) — a refusal means report and stop, never retry. Its stdout is the
worktree's absolute path; **everything it says on stderr is for you to act on**. Enter the
worktree (the EnterWorktree tool where the session offers it, else `cd` to the printed path).

### 3. Install, then shape

**Run the project's install command before anything else** — a fresh worktree has no generated
git-hook dir (husky's `.husky/_/` is gitignored), so committing before installing silently skips
the pre-commit gate. Then shape: `dw-shape` in this worktree `git mv`s the backlog entry in and
expands it, or writes the change doc fresh from the description.

### 4. Build — and the parallel recipe

More queued work? Print the recipe per entry: **new terminal → `claude -w <slug>`**, run while the
main tree is on the default branch — `dw-shape` in that session shapes onto its own branch. Then
invoke `dw-next` bare here and let it run.

**Next:** `dw-check` for a look at what got built, or `dw-land` once nothing is pending.

$ARGUMENTS
