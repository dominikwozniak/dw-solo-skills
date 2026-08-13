# Worktrees — what `dw-start` gives you, and what it doesn't

Worktrees live at `.claude/worktrees/<slug>` on branch `<slug>`; `scripts/runtime/worktree.sh` owns
create and remove. A `claude -w <slug>` session spells the branch `worktree-<slug>` instead, which
is why `dw-next` strips that prefix before matching a change doc.
