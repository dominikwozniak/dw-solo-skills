---
name: dw-start
description: >-
  Open a shaped change for building: create its worktree and branch, enter it, and claim the change
  by writing the branch into its `CHANGE.md`. Bare lists what's unclaimed. Explicit-invoke only —
  creating branch topology is your call, never the model's.
argument-hint: "which change — a slug from .ai/work/, or bare to list the unclaimed ones"
disable-model-invocation: true
---

# dw-start — a worktree per change, claimed before building

Building in the main tree serializes you: the second change waits for the first to merge. This skill
opens a shaped change in its own worktree and branch, so several changes run at once — each in its
own session, each reading its own `CHANGE.md` from disk.

It is mechanics plus one field write. The thinking already happened in `dw-shape`; the building
happens in `dw-next`.

## What it reads and writes

Reads `.ai/work/*/CHANGE.md` (written by `dw-shape`) to find the unclaimed changes. Writes exactly
one thing: the chosen change's `branch:` flips from `unclaimed` to the new branch — the **claim** —
committed immediately. `.ai/` is tracked in git, and an uncommitted claim is invisible to every
other session, which is the race this protocol closes.

## Workflow

### 1. Pick the change

- `$ARGUMENTS` names a slug → that change.
- Bare → list every `CHANGE.md` with `branch: unclaimed`, newest first, and ask.
- A description with no shaped change behind it → shape first: offer `dw-shape` here in the main
  tree, then come back.

### 2. Check it isn't taken

Taken means any of: its `branch:` is no longer `unclaimed`; a branch named `<slug>` or
`worktree-<slug>` already exists (`git branch --list`); a worktree already sits at
`.claude/worktrees/<slug>` (`git worktree list`). If taken, say which branch owns it and **stop** —
stealing a change is the user's edit to make, never yours.

Then confirm the doc is committed: `git status --porcelain .ai/work/<slug>/`. A worktree checks out
committed state only — if `dw-shape`'s commit step was skipped, do it now, the way `dw-git` does.

### 3. Create and enter

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" create <slug>
```

prints the new worktree's absolute path: `.claude/worktrees/<slug>`, branch `<slug>`, based on the
main tree's current HEAD — so run it while the main tree sits on the default branch. Enter the
worktree (the EnterWorktree tool where the session offers it, else `cd` to the printed path). The
`link-local-memory` hook, when installed, symlinks `CLAUDE.local.md` in at session start.

### 4. Claim, then settle in

- In the worktree, flip the change's `branch: unclaimed` to the verbatim output of
  `git rev-parse --abbrev-ref HEAD`, change nothing else, and commit that one edit — the way
  `dw-git` does.
- A fresh worktree has no `node_modules/` — offer the project's install command before building.

### 5. Report, and the parallel recipe

Say which change is open where, and what its first task is. For each change still unclaimed, print
the recipe: **new terminal → `claude -w <slug>`**, run while the main tree is on the default branch
(the branch will be `worktree-<slug>`, a spelling the loop's claim matching strips) — then
`dw-next` in that session offers the claim.
