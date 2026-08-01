---
name: dw-ship
description: >-
  Ship the landed change: push — straight to the default branch when that's where you are, else
  PR → squash-merge — then tear down the worktree and branch and pull. Runs the closing pass first
  when the change doc is still there. Explicit-invoke only — merging is your call, never the
  model's.
argument-hint: "bare ships the landed change · pr forces the PR path"
disable-model-invocation: true
---

# dw-ship — push, merge, clean up

Shipping is a decision, not a step — so it lives behind its own explicit name, and everything
before the merge is reversible right up to the HARD STOP. One command covers both endings of a
change: the small serial edit that just gets pushed, and the worktree branch that goes out through
a PR and leaves nothing behind.

## What it reads

The branch state, and `## Git conventions` for the default branch and push rules — every git
mechanic here (commit format, PR title and body, no attribution footers) is done the way `dw-git`
does it. This skill writes **no `.ai/` artifact**: its output is pushed history and a removed
worktree.

## Workflow

### 1. Preconditions

- Clean tree (`git status --porcelain`) — leftover work gets committed the way `dw-git` does, or
  deliberately stashed; never shipped around.
- **Landed first.** If a `CHANGE.md` still matches this branch (the same grep `dw-next` uses), the
  change hasn't been closed: run `dw-land` now — verdict, approval, `close` — and come back. The
  promotion commit has to ride this branch; shipping before it exists strands the durable residue.

### 2. Pick the path

- Already **on the default branch** (from `## Git conventions`, else
  `git symbolic-ref --short refs/remotes/origin/HEAD`) and it isn't protected → **fast path**:
  plain `git push`. Done — there's no worktree to clean.
- On any other branch → the **PR path** below. `pr` in `$ARGUMENTS` forces it even where a direct
  push would work.
- **No `origin` at all** → say so and offer the local ending instead: switch to the default
  branch, merge, delete the branch. Never pretend to have pushed.

### 3. The PR path

1. Push with an upstream: `git push -u origin <branch>`.
2. Open the PR with `gh pr create`, title and body built the way `dw-git` builds them.
3. **HARD STOP — the PR link is the moment to look.** Merging is irreversible in a way pushing
   isn't; wait for an explicit go.
4. On approval: `gh pr merge --squash`.

### 4. Clean up

When the branch lives in a worktree, leave it first (the ExitWorktree tool where the session offers
it, else `cd` to the main tree), then:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" remove <slug>
```

removes the worktree, deletes its branch — whatever the spelling, `<slug>` or `worktree-<slug>` —
and prunes. Then `git pull` on the default branch so the main tree sees the squash. For a plain
feature branch with no worktree: `git switch <default-branch>`, `git pull`, `git branch -D <branch>`.

### 5. Report

Say what merged and where, and what was torn down. If landing parked follow-ups in
`.ai/BACKLOG.md`, the next `dw-shape` reads them — that's the loop closing.

**Next:** `dw-shape` for the next change — the backlog is where it starts.
