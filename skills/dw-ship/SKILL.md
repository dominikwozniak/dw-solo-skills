---
name: dw-ship
description: >-
  Merge the landed change and leave nothing behind: settle the PR's checks, squash-merge it, tear
  down the worktree and branch, pull the default branch, and sweep the work doc a squash-merge
  resurrects. Explicit-invoke only.
disable-model-invocation: true
---

# dw-ship — merge, clean up, sync

One decision, the squash — and it takes no arguments. Everything before it happened at `dw-land`,
everything after is teardown; the merge being the closing sequence's single one-way door is the whole
reason this is a second command.

## What it reads

The branch state, the PR's checks, and `## Git conventions` for the default branch and push rules —
every git mechanic here is done the way `dw-git` does it. This skill writes **no `.ai/` artifact**:
its output is a merged PR, a removed worktree, and a `.ai/work/` folder that stays deleted.

## Workflow

### 1. Preconditions

- Clean tree (`git status --porcelain`) — leftover work gets committed the way `dw-git` does, or
  deliberately stashed; never shipped around.
- **Landed first, and that is a refusal.** If a `CHANGE.md` still matches this branch (the same grep
  `dw-next` uses), the change isn't closed: say so, say `/dw-land`, and **stop**. Don't offer to run
  the closing pass here and don't promise to pick this up afterwards — `dw-land` ends with the PR
  this skill needs, so the next `dw-ship` starts from a state that exists.

### 2. Pick the path

- Already **on the default branch** (resolved the way `dw-git` does) and it isn't protected → **fast
  path**: plain `git push` is the whole ship — no PR, no worktree. It is **irreversible**, with
  nothing between it and the default branch, and here the push really is this change's **first CI**,
  because a push to the default branch is a trigger where a push to a feature branch is not: where
  `dw-land` left a result pending on the push, watch that run rather than calling the ship done at the
  push. If the change skipped `dw-check`, offer it first — a nudge, not a gate.
- On any other branch → the **merge** below.
- **No `origin` at all** → say so and offer the local ending instead: switch to the default branch,
  merge, delete the branch. Never pretend to have pushed.

### 3. Merge the PR

1. **Read the checks first**: `gh pr checks`. Opening the PR at `dw-land` is what started this
   change's first CI, so this is where a result the verdict recorded as **pending on the push** gets
   settled. A pending or failing check is a reason to wait and say so, not a footnote under the go.
2. `gh pr merge --squash --subject "<the PR title>"` — **`--subject`, not `--title`**, which
   `gh pr merge` does not have and dies on. Pin it either way: the squash subject is what lands on the
   default branch forever, and left to itself it comes out as whichever commit subject GitHub picks
   rather than the conventional-commits subject `dw-git` composed.

   **Not `--delete-branch`, and leaving it off is the decision** — step 4 deletes the remote branch
   instead. `gh` deletes the **local** branch first and returns on failure, so a local half that cannot
   succeed means the remote deletion never runs at all. On this loop's default path it cannot succeed:
   the branch is checked out in a worktree, so from inside that worktree gh tries to check out the base
   branch and git refuses, and from the main tree `git branch -D` refuses for the same reason. The
   squash still lands, the command exits non-zero, and the branch stays on the remote — precisely the
   outcome the flag was meant to prevent. It is also rejected outright where the base branch requires a
   merge queue. Anyone re-adding it should read step 4 first.

3. No PR on the branch → `dw-land` never ran or its PR was closed. Stop and say which, rather than
   opening one here.

### 4. Clean up

When the branch lives in a worktree, leave it first (the ExitWorktree tool where the session offers
it, else `cd` to the main tree), then:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" remove <slug>
```

removes the worktree, deletes its branch — whatever the spelling, `<slug>` or `worktree-<slug>` —
and prunes. For a plain feature branch with no worktree: `git switch <default-branch>`,
`git branch -D <branch>`.

**Then the remote branch, now that nothing holds it locally.** This is the step that keeps the remote
from filling up with merged branches, and nothing else in the loop does it:

```bash
gh api --method DELETE "repos/{owner}/{repo}/git/refs/heads/<branch>"
```

Here rather than as a flag on the merge because it works from any tree, needs no branch checked out,
and is unaffected by a merge queue. `git push origin --delete <branch>` does the same thing, where the
repo has no guardrail refusing that spelling — the `block-dangerous-commands` hook this lane ships
refuses it, so the API call is the spelling that always works. A **404 is success**: the branch is
already gone, which is what a repo with automatic head-branch deletion looks like.

### 5. Sync, then sweep what the squash brought back

`git pull` on the default branch, so the main tree sees the squash. Then look for its residue:
**a `.ai/work/<slug>/` whose twin already sits in `.ai/archive/<slug>/`.** A shaping commit still
local-only when its PR squashed is **replayed on top of the squash** by the rebase, re-creating that
change's `CHANGE.md` at its shaping-time state — `branch: unclaimed`, `status: shaping` — for a change
that landed minutes ago, which `dw-next` then offers as fresh work. Twice cleaned up by hand before
this step existed: `73e003a`, `9eef63d`.

`git rm -r` every such folder — matched on the archive twin, never on the slug just shipped, since one
shaping commit can carry several changes and the rest are live work. Commit on the default branch and
push, confirming that push the way `dw-git` does. Nothing is lost: the landed copy is in the archive,
and a sibling doc the same commit carried rides along untouched.

### 6. Report

What merged and where, what was torn down, and what the sweep removed. If landing parked follow-ups
in `.ai/backlog/`, the next `dw-shape` reads them — that's the loop closing.

**Next:** `dw-shape` for the next change — the backlog is where it starts.
