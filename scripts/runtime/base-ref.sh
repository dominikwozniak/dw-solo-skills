#!/usr/bin/env bash
# base-ref.sh — which ref of the default branch a diff is taken against.
#
# Prints exactly one ref on stdout: `origin/<branch>` when it contains the local `<branch>`, else
# the local `<branch>`. Local is the default on purpose — a local default branch that is *ahead*
# (an unpushed shape commit, say) would make `origin/` pull commits the feature branch never wrote
# into `git diff <base>...HEAD`, and a review would grade work that isn't the change's. Origin wins
# only when it is strictly the newer of the two, or when no local copy exists at all (a clone that
# checked out the feature branch and nothing else).
#
# Usage: base-ref.sh [default-branch]
#   With no argument the default branch is `git symbolic-ref --short refs/remotes/origin/HEAD`
#   minus its `origin/`, else `main`. A repo's `## Git conventions` block is the authoritative
#   declaration, so a caller that has read one passes it.
#
# The fetch is best-effort and silent: no origin, or an unreachable one, still prints a ref —
# a diff base must not stall offline work. The env guards are what keep "unreachable" from hanging
# on a host-key or credential prompt nobody is watching; worktree.sh's ls-remote wears the same ones.
#
# Exit 1 with a line on stderr only when neither `<branch>` nor `origin/<branch>` exists — there is
# no honest ref to print, and a caller diffing against a name that resolves to nothing would read
# the resulting error as an empty change.
set -euo pipefail
export LC_ALL=C

branch="${1:-}"
if [ -z "$branch" ]; then
  branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  branch="${branch#origin/}"
  [ -n "$branch" ] || branch=main
fi

if git config remote.origin.url >/dev/null 2>&1; then
  GIT_TERMINAL_PROMPT=0 \
    GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -oBatchMode=yes -oConnectTimeout=5" \
    git fetch origin --quiet >/dev/null 2>&1 || true
fi

have_local=0
git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null && have_local=1
have_remote=0
git rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null && have_remote=1

if [ "$have_local" -eq 0 ] && [ "$have_remote" -eq 0 ]; then
  echo "base-ref.sh: neither '$branch' nor 'origin/$branch' exists — pass the default branch by name" >&2
  exit 1
fi

base="$branch"
if [ "$have_remote" -eq 1 ]; then
  if [ "$have_local" -eq 0 ] || git merge-base --is-ancestor "$branch" "origin/$branch" 2>/dev/null; then
    base="origin/$branch"
  fi
fi
printf '%s\n' "$base"
