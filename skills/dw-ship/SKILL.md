---
name: dw-ship
description: >-
  Merge the landed change and leave nothing behind: settle the PR's checks, squash-merge it, tear
  down the worktree and branch, and pull the default branch. Explicit-invoke only.
disable-model-invocation: true
---

# dw-ship — merge, clean up, sync

One decision — the squash — and it takes no arguments. Everything before it happened at `dw-land`;
everything after is teardown.

## What it reads

The branch state, the PR's checks, and `## Git conventions`, which every git mechanic here
follows. It writes no `.ai/` artifact: its output is a merged PR and a clean tree.

## Workflow

### 1. Preconditions

- Clean tree (`git status --porcelain`) — leftover work gets committed per `## Git conventions`, or
  deliberately stashed; never shipped around.
- **Landed first, and that is a refusal.** A `CHANGE.md` still matching this branch (the same grep
  `dw-next` uses) means the change isn't closed: say so, say `/dw-land`, and **stop**.

### 2. Pick the path

- Already on the default branch (the one `## Git conventions` names) and it isn't protected → **fast
  path**: plain `git push` is the whole ship — and this change's first CI, so watch any result
  `dw-land` left pending on the push.
- Any other branch → the merge below.
- No `origin` at all → offer the local ending: switch to the default branch, merge, delete the
  branch. Never pretend to have pushed.

### 3. Merge the PR

1. **Read the checks first**: `gh pr checks` — a pending or failing check is a reason to wait and
   say so, not a footnote under the go.
2. `gh pr merge --squash --subject "<the PR title>"` — `--subject`, not `--title` (which
   `gh pr merge` doesn't have), so the squash lands under the conventional subject. **Not
   `--delete-branch`**: with the branch checked out in a worktree its local half fails and the
   remote half never runs — step 4 deletes the remote branch instead.
3. No PR on the branch → `dw-land` never ran or its PR was closed; stop and say which.

### 4. Clean up

Leave the worktree first (the ExitWorktree tool where the session offers it, else `cd` to the main
tree), then:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" remove <slug>
```

For a plain branch with no worktree: `git switch <default-branch>`, `git branch -D <branch>`. Then
the remote branch, now that nothing holds it locally:

```bash
gh api --method DELETE "repos/{owner}/{repo}/git/refs/heads/<branch>"
```

A **404 is success** — automatic head-branch deletion got there first. The API spelling works from
any tree and past the guard that refuses `git push origin --delete`.

### 5. Sync, and one safety check

`git pull` on the default branch. Then look once: a `.ai/work/` folder or `.ai/backlog/` entry
here whose bare slug (`slugify.sh undate` both sides) has an `.ai/archive/` twin reading `landed:`
or `rejected:` is residue a replayed local-only commit brought back after the squash — `git rm -r`
it, commit and push. With change docs shaped only on feature branches this almost always finds
nothing.

### 6. Report

What merged and where, what was torn down. Follow-ups parked in `.ai/backlog/` are where the next
`dw-shape` starts — that's the loop closing.

**Next:** `dw-shape` for the next change — the backlog is where it starts.
