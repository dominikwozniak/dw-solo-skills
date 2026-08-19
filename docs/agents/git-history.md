# Git history — commits, rebases, and getting a branch back

The conventions themselves (commit format, trailer, branch naming) are in the root's
`## Git conventions`, because `dw-git` greps them there. This file is what goes wrong _around_ them.

## Gotchas

- **Three ways a branch ends up holding work you didn't write.**
  - **`git commit` commits the index, not what you staged — and the main tree's index is shared with
    every other session in it.** `git add <my-folder>` then `git commit` swept a concurrent session's
    staged rename into this change's `chore: shape …` commit. Nothing warns: `git status` was clean
    at session start and the other session staged in between. Parallel shaping in the main tree is
    the normal case here, so run `git status --porcelain` **unscoped** before committing there and
    commit with explicit pathspecs (`git commit -- <paths>`). What the fix isn't: once the commit is
    an ancestor of your branch, splitting it does **not** get the passenger out of the PR — a
    squash-merge flattens both halves into one commit anyway.
  - **Rebasing onto a squash-merged `main` resurrects the merged change's own commits** — and **you
    don't have to be the one who rebases.** No shared ancestor survives the squash, so a branch shaped
    before it replays that change's `chore: shape …` commit as a new one, re-adding a `CHANGE.md` for
    work already archived. The wider trigger: `main` is one ref shared by every worktree, so another
    session merging and rebasing it rewrites your base commit out from under you — your branch keeps
    descending from the orphan and `main..HEAD` grows their commits with no action of yours at all. It
    surfaces at land time, as a diff you cannot honestly grade. Either way, diff `main..HEAD` and drop
    what you didn't write: `git rebase --onto main <stowaway-sha> <branch>`, where the stowaway is your
    own old base. Check the version bumps in the same pass — the other change may have taken the number
    yours targets, which is exactly what `pnpm validate:versions` measures against `origin/main`'s tip;
    `git fetch` first, or it grades you against a stale base.
  - **Every way to rewind a branch is blocked by `block-dangerous-commands.sh`.** Not just
    `git reset --hard` — `git branch -f`, `git branch -D`, `git checkout .` and `git restore .` are
    all in `DANGEROUS_PATTERNS`, so an agent cannot move a branch backwards at all and must hand the
    command to you. `git rebase` is not blocked, so prefer `rebase --onto` where it reaches;
    otherwise expect to run the rewind yourself.
