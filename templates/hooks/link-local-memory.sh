#!/usr/bin/env bash
# SessionStart hook — makes CLAUDE.local.md reachable inside a git worktree.
#
# CLAUDE.local.md is gitignored on purpose (personal memory), so a `git worktree`
# checkout never receives it — only tracked files land there. That silently costs
# the agent this repo's `## Git conventions` block, which dw-git reads for the
# commit format, the trailer policy and the "don't touch SSH signing" rule; the
# lint and typecheck hooks grep the same file for their commands. The visible
# symptom is a worktree commit carrying a trailer the main tree forbids.
#
# Fix: symlink — not copy, so there stays one source of truth and edits made in
# either tree propagate — the main tree's CLAUDE.local.md into the worktree.
# No-op in the main tree, outside a git repo, and when there's nothing to link.
#
# Worktree detection is `--git-dir` vs `--git-common-dir`, NOT a path compare:
# in the main tree --git-common-dir returns a relative ".git", so comparing its
# dirname against --show-toplevel would report a false "I'm in a worktree".
#
# The echo is load-bearing: nothing guarantees the symlink exists before the
# harness loads memory files, so without it the conventions would only reach
# context in the *next* session — not the one that needs them. SessionStart
# stdout is added to the session context.

set -uo pipefail

gd="$(git rev-parse --git-dir 2>/dev/null)"
gcd="$(git rev-parse --git-common-dir 2>/dev/null)"

# Equal in the main tree; both empty outside a git repo. Either way, nothing to do.
[[ "$gd" == "$gcd" ]] && exit 0

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

# -e, not -f: a symlink left by an earlier session must count as already present.
[[ -e "CLAUDE.local.md" ]] && exit 0

main="$(cd "$(dirname "$gcd")" && pwd -P)" || exit 0
[[ -f "$main/CLAUDE.local.md" ]] || exit 0

ln -s "$main/CLAUDE.local.md" CLAUDE.local.md 2>/dev/null || exit 0

echo "Worktree detected: linked CLAUDE.local.md from the main tree ($main). Read it — it carries this repo's ## Git conventions (commit format, trailer policy, signing) and the lint/typecheck commands."

exit 0
