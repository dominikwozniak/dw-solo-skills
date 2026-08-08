---
created: 2026-08-08
source: backlog-audit-script
---

# The "is this change already taken?" check reads only local refs, so a fresh clone always says free

`dw-start` step 2 uses `git branch --list`, `worktree.sh:207` uses `show-ref --verify refs/heads/`,
and `dw-git`'s `branch` op checks nothing — all three miss a branch that exists only on origin, and
step 4 commits the claim in the worktree, so `main`'s `CHANGE.md` still reads `unclaimed`. Needs an
unclaimed change plus a same-named origin branch, so it only bites on a second machine; no live case
here today. `git ls-remote --heads origin <slug>` is authoritative — `branch -a` lies both ways,
since stale remote-tracking refs outlive the branch.
