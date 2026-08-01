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
#                                      copies the .worktreeinclude matches in;
#                                      prints the worktree's absolute path on stdout
#   worktree.sh remove <slug>          remove the worktree, delete its branch, prune
#
# remove uses `git branch -D`: after a squash-merge the branch tip is never an ancestor of
# the default branch, so `-d` would always refuse. Never `--force` on the worktree itself —
# a dirty worktree must refuse, and surfacing git's own error is the feature.
set -euo pipefail

usage() { echo "usage: worktree.sh {create|remove} <slug> [base]" >&2; }

# Warn rather than copy when a pattern sweeps in more than this many files — an include file is
# hand-written, and the difference between a config file and a dependency tree is two characters.
WORKTREE_INCLUDE_WARN_AT=50

# Carry the copy-class files a fresh checkout leaves behind.
#
# `git worktree add` checks out tracked state only. Claude Code's own .worktreeinclude handling
# covers the worktrees *it* creates — `--worktree`, subagent worktrees, desktop — and never
# `git worktree add`, so this reproduces it for the loop's own worktrees.
#
# The rule, verbatim from code.claude.com/docs/en/worktrees.md: copy a file only when it matches a
# pattern **and** is gitignored. Both halves are computed by git — two `ls-files` runs intersected —
# so the semantics cannot drift from what `claude -w` does. We never parse gitignore ourselves.
#
# The refusals below are hard and independent of what the file says, because the file is
# hand-written and the failure is destructive rather than annoying: `node_modules/` is
# regenerate-class (platform-specific, and 394 of this repo's 421 ignored files live there), and
# `.claude/worktrees/` is where worktrees live — copying it puts worktrees inside a worktree.
#
# Filenames containing a newline are not supported: `comm` has no `-z`, and the alternative is
# reimplementing the matching we deliberately delegate to git.
copy_worktree_includes() {
  local src_root="$1" dst_root="$2"
  local inc="$src_root/.worktreeinclude"
  [ -f "$inc" ] || return 0

  local candidates
  candidates="$(
    comm -12 \
      <(git -C "$src_root" -c core.quotePath=false ls-files -o -i --exclude-standard | sort) \
      <(git -C "$src_root" -c core.quotePath=false ls-files -o -i --exclude-from="$inc" | sort)
  )" || return 0
  [ -n "$candidates" ] || return 0

  local total
  total="$(printf '%s\n' "$candidates" | grep -c . || true)"
  if [ "$total" -gt "$WORKTREE_INCLUDE_WARN_AT" ]; then
    echo "worktree.sh: .worktreeinclude matches $total files — that looks like a directory tree, not local config. Copying anyway; narrow the patterns if this is wrong." >&2
  fi

  local copied=0 refused=0 rel
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    case "$rel" in
      node_modules/* | */node_modules/* | .claude/worktrees/* | .git/*)
        refused=$((refused + 1))
        continue
        ;;
    esac
    [ -f "$src_root/$rel" ] || continue
    if mkdir -p "$dst_root/$(dirname "$rel")" 2>/dev/null &&
      cp -p "$src_root/$rel" "$dst_root/$rel" 2>/dev/null; then
      copied=$((copied + 1))
    else
      echo "worktree.sh: could not copy $rel into the worktree — continuing without it" >&2
    fi
    # Fed by heredoc, not a pipe: a pipe would run the loop in a subshell and the counters below
    # would come back zero.
  done <<EOF
$candidates
EOF

  [ "$refused" -eq 0 ] ||
    echo "worktree.sh: refused $refused path(s) matched by .worktreeinclude — node_modules/, .claude/worktrees/ and .git are never copied" >&2
  [ "$copied" -eq 0 ] ||
    echo "worktree.sh: copied $copied file(s) named by .worktreeinclude" >&2
}

# Personal agent memory is link-class, not copy-class: one source of truth, so an edit in either
# tree is visible in both. That is `link-local-memory.sh`'s argument, and it stays the right one.
#
# The hook cannot cover this path, though. It runs on SessionStart, which fires for `claude -w`
# (the session starts *in* the worktree) but not for a session that enters a worktree mid-flight —
# `/dw-start`'s route. Creating the link here has no session lifecycle to miss. Both sides test for
# an existing entry first, so they compose rather than race.
#
# Absolute target, matching the hook: a relative one would break the moment the worktree moves.
link_local_memory() {
  local src_root="$1" dst_root="$2"
  local src="$src_root/CLAUDE.local.md"
  [ -f "$src" ] || return 0
  # -e, not -f: a link the hook already made counts as present.
  if [ -e "$dst_root/CLAUDE.local.md" ]; then
    return 0
  fi
  if ln -s "$src" "$dst_root/CLAUDE.local.md" 2>/dev/null; then
    echo "worktree.sh: linked CLAUDE.local.md from the main tree — it carries the git conventions and the lint/typecheck commands" >&2
  else
    echo "worktree.sh: could not link CLAUDE.local.md into the worktree — the agent will fall back to generic git conventions" >&2
  fi
}

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
    # Everything below is best-effort and reports on stderr: the worktree already exists, and the
    # `already exists` guards above make a half-created one expensive to retry. A missing include
    # file is worth a warning, never a failure.
    copy_worktree_includes "$root" "$path" || true
    link_local_memory "$root" "$path" || true
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
