# Claiming — when the branch grep comes back empty

Reached only when no `CHANGE.md` records the branch you are on, which on an ordinary resume never
happens. **Try to claim before pointing anywhere.** In order:

1. Strip an optional `worktree-` prefix from the branch (the `claude -w` spelling); if the
   remainder equals or contains the slug of a change whose `branch:` is `unclaimed`, offer that
   one — this is how a `claude -w <slug>` session picks up its change without `dw-start`.
2. Else if exactly **one** unclaimed change exists, offer it — including right here on the
   default branch, for small serial work that never needed a worktree.
3. Else list the unclaimed changes newest-first and ask — or point at `dw-shape` when there are none.

Claiming = flip `branch: unclaimed` to the verbatim `git rev-parse --abbrev-ref HEAD` and commit
that one edit before building — an uncommitted claim is invisible to every other session. If no
unclaimed change fits but exactly one change sits on another branch, say so and offer it — you
may simply be on the wrong branch.
