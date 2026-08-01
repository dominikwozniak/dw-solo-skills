#!/usr/bin/env bash
# worktree.sh — create and remove the per-change git worktrees the solo loop builds in.
#
# One change, one worktree, one branch: `create <slug>` puts a worktree at
# .claude/worktrees/<slug> on a new branch <slug> — the same parent dir `claude --worktree`
# uses, already gitignored by the managed block. `remove <slug>` tears the pair down after
# the change shipped. Mechanics only: which change to build, claiming it in CHANGE.md, and
# whether the branch is merged are the calling skill's judgment, not this script's.
#
# Subcommands:
#   worktree.sh create <slug> [base]   worktree + branch <slug> at [base] (default HEAD);
#                                      prints the worktree's absolute path on stdout
#   worktree.sh remove <slug>          remove the worktree, delete its branch, prune
#
# remove uses `git branch -D`: after a squash-merge the branch tip is never an ancestor of
# the default branch, so `-d` would always refuse. Never `--force` on the worktree itself —
# a dirty worktree must refuse, and surfacing git's own error is the feature.
set -euo pipefail

usage() { echo "usage: worktree.sh {create|remove} <slug> [base]" >&2; }

# In a linked worktree --git-dir is .git/worktrees/<name> while --git-common-dir stays the
# main .git — the only reliable tell (path comparison breaks on symlinked tmpdirs).
in_linked_worktree() {
  [ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ]
}

# The main tree's root, regardless of where we're invoked from.
main_root() {
  local common
  common="$(git rev-parse --git-common-dir)"
  (cd "$common/.." && pwd -P)
}

cmd="${1:-}"
slug="${2:-}"
case "$cmd" in
  create)
    [ -n "$slug" ] || { usage; exit 1; }
    base="${3:-HEAD}"
    if in_linked_worktree; then
      echo "worktree.sh: refusing to create from inside a linked worktree — run from the main tree (never nest)" >&2
      exit 1
    fi
    root="$(git rev-parse --show-toplevel)"
    path="$root/.claude/worktrees/$slug"
    if git show-ref --verify --quiet "refs/heads/$slug"; then
      echo "worktree.sh: branch '$slug' already exists — this change looks already started" >&2
      exit 1
    fi
    if [ -e "$path" ]; then
      echo "worktree.sh: $path already exists — this change looks already started" >&2
      exit 1
    fi
    # git's own chatter goes to stderr so stdout stays machine-usable: the path, nothing else.
    git worktree add -b "$slug" "$path" "$base" 1>&2
    printf '%s\n' "$path"
    ;;
  remove)
    [ -n "$slug" ] || { usage; exit 1; }
    root="$(main_root)"
    path="$root/.claude/worktrees/$slug"
    target="$(cd "$path" 2>/dev/null && pwd -P || true)"
    if [ -z "$target" ]; then
      echo "worktree.sh: no worktree at $path" >&2
      exit 1
    fi
    here="$(pwd -P)"
    case "$here" in
      "$target" | "$target"/*)
        echo "worktree.sh: refusing to remove the worktree we're standing in — cd to the main tree first" >&2
        exit 1
        ;;
    esac
    # The branch is whatever the worktree actually has checked out — resolved from porcelain,
    # so a `claude --worktree` worktree (branch worktree-<slug>) tears down just as cleanly.
    branch=""
    current=""
    while IFS= read -r line; do
      case "$line" in
        worktree\ *)
          wt="${line#worktree }"
          current="$(cd "$wt" 2>/dev/null && pwd -P || echo "$wt")"
          ;;
        branch\ refs/heads/*)
          [ "$current" = "$target" ] && branch="${line#branch refs/heads/}"
          ;;
      esac
    done < <(git worktree list --porcelain)
    git worktree remove "$path"
    if [ -n "$branch" ]; then
      git branch -D "$branch" 1>&2
    else
      echo "worktree.sh: $path had a detached HEAD — no branch to delete" >&2
    fi
    git worktree prune
    echo "removed worktree $path${branch:+ and branch $branch}"
    ;;
  "" | -h | --help | help)
    usage
    [ "$cmd" = "" ] && exit 1 || exit 0
    ;;
  *)
    echo "worktree.sh: unknown subcommand '$cmd'" >&2
    usage
    exit 1
    ;;
esac
