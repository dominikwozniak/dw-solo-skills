#!/usr/bin/env bash
# worktree.sh — create and remove the per-change git worktrees the solo loop builds in.
#
# One change, one worktree, one branch: `create <slug>` puts a worktree at
# .claude/worktrees/<slug> on a new branch <slug> — the same parent dir `claude --worktree`
# uses, already gitignored by the managed block. `remove <slug>` tears the pair down after
# the change shipped. Mechanics only: which change to build and whether the branch
# is merged are the calling skill's judgment, not this script's.
#
# Subcommands:
#   worktree.sh create <slug> [base]   worktree + branch <slug> at [base] (default HEAD);
#                                      copies the .worktreeinclude matches in, reports what
#                                      still needs installing or copying by hand; prints the
#                                      worktree's absolute path on stdout
#   worktree.sh remove <slug>          remove the worktree, delete its branch, prune
#
# Everything create does past `git worktree add` is best-effort and speaks only on stderr, so
# stdout stays the path and nothing else — dw-start parses it.
#
# remove uses `git branch -D`: after a squash-merge the branch tip is never an ancestor of
# the default branch, so `-d` would always refuse. On the worktree itself `--force` is reached for
# in exactly one case — git refuses outright once a submodule is checked out there — and only after
# remove_worktree has checked cleanliness itself, because that flag waives the dirty check too.
# A dirty worktree must still refuse; surfacing git's own error is the feature.
set -euo pipefail
# The include matching below sorts two file lists and intersects them with `comm`; all three have to
# agree on collation. Every other script here that compares text pins it the same way.
export LC_ALL=C

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

  # Refusals first, so the volume warning below counts what will actually be copied. Warning about
  # 395 files and then copying 1 of them teaches you to ignore the warning.
  local keep="" refused=0 rel
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    case "$rel" in
      node_modules/* | */node_modules/* | .claude/worktrees/* | .git/*)
        refused=$((refused + 1))
        continue
        ;;
    esac
    keep="$keep$rel
"
    # Fed by heredoc, not a pipe: a pipe would run the loop in a subshell and the counters would
    # come back zero.
  done <<EOF
$candidates
EOF

  local total
  total="$(printf '%s' "$keep" | grep -c . || true)"
  if [ "$total" -gt "$WORKTREE_INCLUDE_WARN_AT" ]; then
    echo "worktree.sh: .worktreeinclude names $total files to copy — that looks like a directory tree, not local config. Copying anyway; narrow the patterns if this is wrong." >&2
  fi

  local copied=0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ -f "$src_root/$rel" ] || continue
    if mkdir -p "$dst_root/$(dirname "$rel")" 2>/dev/null &&
      cp -p "$src_root/$rel" "$dst_root/$rel" 2>/dev/null; then
      copied=$((copied + 1))
    else
      echo "worktree.sh: could not copy $rel into the worktree — continuing without it" >&2
    fi
  done <<EOF
$keep
EOF

  [ "$refused" -eq 0 ] ||
    echo "worktree.sh: refused $refused path(s) matched by .worktreeinclude — node_modules/, .claude/worktrees/ and .git are never copied" >&2
  [ "$copied" -eq 0 ] ||
    echo "worktree.sh: copied $copied file(s) named by .worktreeinclude" >&2
}

# The one copy-class file the loop cannot self-serve: an env file is gitignored — never checked
# out — and the block-env-access guard keeps the agent from copying it, so the only mover is the
# human. Report-only, like everything else past `git worktree add`. Example/sample/template
# basenames are the secret-free allowlist and stay out of the warning.
report_missing_env() {
  local src_root="$1" dst_root="$2" missing="" rel
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ -e "$dst_root/$rel" ] && continue
    missing="$missing
  - $rel"
  done < <(git -C "$src_root" -c core.quotePath=false ls-files -o -i --exclude-standard 2>/dev/null |
    grep -E '(^|/)\.env(\.[^/]+)?$|(^|/)\.envrc$' | grep -vE '\.(example|sample|template)$' || true)
  [ -n "$missing" ] || return 0
  echo "worktree.sh: env file(s) in the main tree but not in this worktree:$missing
  Gitignored, so never checked out, and the env guard stops the agent from copying them: copy by hand, or list them in .worktreeinclude." >&2
}

# THE LINK CLASS IS GONE, and this note is what is left of it. Personal agent memory used to be a
# gitignored `CLAUDE.local.md`, which `git worktree add` never checks out — so it was carried in as a
# symlink rather than a copy: one source of truth, so an edit in either tree was visible in both.
# Decision 0007 moved memory into tracked `AGENTS.md`, which git checks out unaided, and that left the
# link class with no member. It survived a while longer for repos scaffolded before the move, guarded
# by a `-f` test that made it inert everywhere else — which is to say it was a code path that did
# nothing, in a lane whose whole argument is that unused machinery costs more than it saves.
#
# What NOT to conclude from this: the `AGENTS.md`-first, `CLAUDE.local.md`-second resolution in
# `lint-on-edit` and `typecheck-on-commit` is a different thing and stays. A legacy repo still reads its
# own file; nothing carries it into a worktree any more, because nothing needs to.
#
# Name what the worktree still hasn't got. Copy is handled above; the other class —
# installed dependencies and the tooling generated from them — must be *regenerated*, never copied,
# so the only honest thing this script can do is say so.
#
# The husky line is the one that matters. `core.hooksPath` is repo-level config shared with every
# worktree, but husky generates `.husky/_/` and gitignores it, so a fresh worktree has the hook
# scripts and no directory for git to find. Git then runs no hooks at all and says nothing: commits
# silently skip formatting, linting and whatever else the pre-commit gate was holding. That is worse
# than a failed build, because it produces bad commits instead of errors.
#
# Detection is from what the repo declares, never a hardcoded stack, and this reports only — a
# worktree that exists and warns beats one that refused to finish.
# Newline-delimited string rather than an array: macOS ships bash 3.2, where expanding an empty
# array under `set -u` is an error, and the rest of this script stays 3.2-safe too.

# The repo's own word for "make this checkout buildable": a declared
# `- **Bootstrap command**: \`cmd\`` bullet, resolved AGENTS.md-first / CLAUDE.local.md-second like
# the hooks' Lint and Typecheck bullets. Prints `none` for a declared none — the caller then reports
# nothing, since the repo has said the checkout needs no bootstrap. A template placeholder or a blank
# value resolve to nothing at all, and the lockfile guess takes over.
#
# AGENTS.md is read in the new worktree (tracked, so it is checked out); CLAUDE.local.md in the main
# tree, because it is gitignored and a fresh worktree never has one.
resolve_bootstrap_cmd() {
  local dst_root="$1" src_root="$2" md line rest value
  for md in "$dst_root/AGENTS.md" "$src_root/CLAUDE.local.md"; do
    [ -f "$md" ] || continue
    line="$(grep -E '^[[:space:]]*[-*]?[[:space:]]*\*{0,2}Bootstrap command\*{0,2}:' "$md" | head -n1)" || true
    [ -n "$line" ] || continue
    rest="$(printf '%s\n' "$line" | sed -e 's/.*Bootstrap command[*]*://' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    case "$rest" in
      none | None | NONE | none[!A-Za-z0-9]* | None[!A-Za-z0-9]* | NONE[!A-Za-z0-9]*)
        printf 'none\n'
        return 0
        ;;
    esac
    value="$(printf '%s\n' "$line" | sed -n 's/.*Bootstrap command[*]*:[^`]*`\([^`]*\)`.*/\1/p')"
    [ -z "$value" ] && value="$rest"
    value="$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [ -n "$value" ] && [ "$value" != "{{BOOTSTRAP_COMMAND}}" ]; then
      printf '%s\n' "$value"
      return 0
    fi
  done
}

report_readiness() {
  local dst_root="$1" src_root="$2"
  local missing=""

  # A declared bootstrap beats lockfile guessing: the repo names install + codegen + submodule
  # init in one line, so the guess below stands down. A declared `none` stands it down too, and
  # says nothing — that is the repo answering "this checkout needs no bootstrap".
  local bootstrap
  bootstrap="$(resolve_bootstrap_cmd "$dst_root" "$src_root")" || true
  if [ "$bootstrap" = none ]; then
    :
  elif [ -n "$bootstrap" ]; then
    missing="$missing  - bootstrap — run: $bootstrap
"
  elif [ -f "$dst_root/package.json" ] && [ ! -d "$dst_root/node_modules" ]; then
    if [ -f "$dst_root/pnpm-lock.yaml" ]; then
      missing="$missing  - dependencies — run: pnpm install
"
    elif [ -f "$dst_root/yarn.lock" ]; then
      missing="$missing  - dependencies — run: yarn install
"
    elif [ -f "$dst_root/bun.lockb" ] || [ -f "$dst_root/bun.lock" ]; then
      missing="$missing  - dependencies — run: bun install
"
    elif [ -f "$dst_root/package-lock.json" ]; then
      missing="$missing  - dependencies — run: npm install
"
    else
      missing="$missing  - dependencies — run your project's install command
"
    fi
  fi

  # Submodules are the same regenerate class: `git worktree add` checks out tracked state, and a
  # submodule's tracked state is a gitlink, not its contents — so every reference checkout lands here
  # empty and the build fails on files that exist in the main tree. Reported, never run: a large
  # submodule turns a two-second `create` into a network round trip, and whether this worktree needs
  # its references populated is the caller's call, not this script's.
  #
  # `submodule status` prefixes an uninitialized submodule with `-`. That marker is git's own, so it
  # holds regardless of locale — unlike matching prose.
  if [ -f "$dst_root/.gitmodules" ] &&
    git -C "$dst_root" submodule status 2>/dev/null | grep -q '^-'; then
    missing="$missing  - submodules — this worktree's submodule directories are empty; run: git submodule update --init
"
  fi

  # Self-contained on purpose: the install line above is conditional, so pointing at it would
  # dangle exactly when this warning matters most.
  if [ -d "$dst_root/.husky" ] && [ ! -d "$dst_root/.husky/_" ]; then
    missing="$missing  - COMMIT HOOKS ARE INACTIVE — .husky/_/ is generated by your install command and gitignored, so git finds no hooks here and every commit skips the pre-commit gate silently. Install before you commit.
"
  fi

  [ -n "$missing" ] || return 0
  echo "worktree.sh: this worktree still needs:" >&2
  printf '%s' "$missing" >&2
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

# Remove the worktree, keeping git's dirty-worktree refusal intact.
#
# `git worktree remove` refuses outright once a submodule is checked out in the worktree —
# cleanliness does not enter into it, so the plain call can never tear that worktree down. A gitlink
# in the index alone is harmless: `worktree add` leaves submodules empty and removal still works.
# The refusal starts the moment someone runs `submodule update --init` there, which is exactly what
# a repo keeping reference checkouts as submodules needs before it can build anything.
#
# `--force` lifts that refusal, but it lifts the dirty-worktree one in the same breath, so reaching
# for it unconditionally would silently delete uncommitted work. Hence: plain call first, and
# `--force` only for the submodule refusal, gated on a cleanliness check we make ourselves.
#
# Matching git's English stderr is safe because this script exports LC_ALL=C above.
remove_worktree() {
  local path="$1" err rc
  err="$(git worktree remove "$path" 2>&1)" && return 0
  rc=$?

  case "$err" in
    *submodule*)
      if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
        echo "worktree.sh: $path has uncommitted changes — commit, stash or delete them first" >&2
        return 1
      fi
      git worktree remove --force "$path"
      ;;
    *)
      printf '%s\n' "$err" >&2
      return "$rc"
      ;;
  esac
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
    # Both spellings mean the same change is already started: `claude -w <slug>` names its branch
    # worktree-<slug>, and its worktree can be torn down while that branch lives on — so checking
    # the path alone would miss it and cut a second branch for one change.
    for started in "$slug" "worktree-$slug"; do
      if git show-ref --verify --quiet "refs/heads/$started"; then
        echo "worktree.sh: branch '$started' already exists — this change looks already started" >&2
        exit 1
      fi
    done
    if [ -e "$path" ]; then
      echo "worktree.sh: $path already exists — this change looks already started" >&2
      exit 1
    fi
    # A branch living only on origin is invisible to show-ref, so a fresh clone would happily
    # re-create it and collide with work already pushed elsewhere. Best-effort by design: no origin configured answers the
    # question with "no remote to conflict with", and an unreachable one must not block offline
    # work — it gets a warning, never a refusal.
    #
    # The env guards are what make that promise true rather than merely intended. Left to itself
    # ssh waits on an unknown host key or a passphrase with no agent, and git waits on a credential
    # helper — so an "unreachable" origin hangs the loop on a prompt nobody is watching instead of
    # failing into the warning below. BatchMode turns both into an immediate non-zero exit.
    if git config remote.origin.url >/dev/null 2>&1; then
      if remote_heads="$(
        GIT_TERMINAL_PROMPT=0 \
          GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -oBatchMode=yes -oConnectTimeout=5" \
          git ls-remote --heads origin "refs/heads/$slug" "refs/heads/worktree-$slug" 2>/dev/null
      )"; then
        if [ -n "$remote_heads" ]; then
          # Name the spelling that actually matched — either one means this change is started.
          found="$(printf '%s\n' "$remote_heads" | sed -n '1s|.*refs/heads/||p')"
          echo "worktree.sh: branch '$found' exists on origin — fetch it or pick another slug" >&2
          exit 1
        fi
      else
        echo "worktree.sh: could not reach origin to check for branch '$slug' — continuing" >&2
      fi
    fi
    # git's own chatter goes to stderr so stdout stays machine-usable: the path, nothing else.
    git worktree add -b "$slug" "$path" "$base" 1>&2
    # Everything below is best-effort and reports on stderr: the worktree already exists, and the
    # `already exists` guards above make a half-created one expensive to retry. A missing include
    # file is worth a warning, never a failure.
    copy_worktree_includes "$root" "$path" || true
    report_missing_env "$root" "$path" || true
    report_readiness "$path" "$root" || true
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
    remove_worktree "$path"
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
